package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"path/filepath"
	"strings"
	"sync"
	"syscall"
	"time"
)

// defaultListenAddr 未配置 PORT / JADE_ADDR 时的默认监听地址。
const defaultListenAddr = ":28473"

// App 持有后端的全部运行期依赖：SQLite 句柄、签名密钥、发版密钥与两个数据目录。
type App struct {
	db         *sqlDB
	jwtSecret  []byte
	adminKey   string
	dataDir    string
	patchesDir string
	// patchMu 串行化补丁发布/撤回与 manifest 原子写回，避免并发发版互相覆盖。
	patchMu sync.Mutex
}

// apiResponse 是除 /api/health 之外的统一响应信封。
type apiResponse struct {
	Code    int    `json:"code"`
	Message string `json:"message,omitempty"`
	Data    any    `json:"data,omitempty"`
}

func main() {
	if err := run(); err != nil {
		log.Fatalf("[jade-server] 启动失败: %v", err)
	}
}

func run() error {
	addr := resolveListenAddr()
	jwtSecret := strings.TrimSpace(os.Getenv("JADE_JWT_SECRET"))
	if jwtSecret == "" {
		log.Println("[jade-server] 未设置 JADE_JWT_SECRET：请在启动前设置环境变量 JADE_JWT_SECRET；禁止使用默认密钥")
		return fmt.Errorf("JADE_JWT_SECRET 未设置，服务已停止")
	}
	dataDir := envOr("JADE_DATA_DIR", "data")
	patchesDir := envOr("JADE_PATCH_DIR", "patches")
	if err := os.MkdirAll(dataDir, 0o755); err != nil {
		return fmt.Errorf("创建数据目录: %w", err)
	}
	if err := os.MkdirAll(patchesDir, 0o755); err != nil {
		return fmt.Errorf("创建补丁目录: %w", err)
	}

	db, err := openDB(filepath.Join(dataDir, "jade.db"))
	if err != nil {
		return fmt.Errorf("初始化 SQLite: %w", err)
	}
	defer db.Close()

	app := &App{
		db:         db,
		jwtSecret:  []byte(jwtSecret),
		adminKey:   strings.TrimSpace(os.Getenv("JADE_ADMIN_KEY")),
		dataDir:    dataDir,
		patchesDir: patchesDir,
	}
	if _, err := app.loadManifest(); err != nil {
		return fmt.Errorf("初始化补丁清单: %w", err)
	}
	if app.adminKey == "" {
		log.Println("[jade-server] 未配置 JADE_ADMIN_KEY：所有管理接口已禁用（503）")
	}

	srv := &http.Server{
		Addr:              addr,
		Handler:           withCORS(withRecover(withRequestLog(app.routes()))),
		ReadHeaderTimeout: 10 * time.Second,
		ReadTimeout:       60 * time.Second,
		WriteTimeout:      120 * time.Second,
		IdleTimeout:       120 * time.Second,
	}

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	errCh := make(chan error, 1)
	go func() {
		log.Printf("[jade-server] 监听 %s，数据目录 %s，补丁目录 %s", addr, dataDir, patchesDir)
		errCh <- srv.ListenAndServe()
	}()

	select {
	case err := <-errCh:
		if err != nil && !errors.Is(err, http.ErrServerClosed) {
			return err
		}
	case <-ctx.Done():
		log.Println("[jade-server] 收到退出信号，开始优雅停机")
	}

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 8*time.Second)
	defer cancel()
	if err := srv.Shutdown(shutdownCtx); err != nil {
		return fmt.Errorf("优雅停机: %w", err)
	}
	log.Println("[jade-server] 已停止")
	return nil
}

func (a *App) routes() *http.ServeMux {
	mux := http.NewServeMux()
	mux.HandleFunc("/api/health", a.handleHealth)
	mux.HandleFunc("/api/auth/guest", a.handleGuest)
	mux.HandleFunc("/api/auth/bind", a.handleBind)
	mux.HandleFunc("/api/auth/login", a.handleLogin)
	mux.HandleFunc("/api/save/meta", a.auth(a.handleSaveMeta))
	mux.HandleFunc("/api/save/download", a.auth(a.handleSaveDownload))
	mux.HandleFunc("/api/save/upload", a.auth(a.handleSaveUpload))
	mux.HandleFunc("/api/leaderboard", a.auth(a.handleLeaderboard))
	mux.HandleFunc("/api/ping", a.auth(a.handlePing))
	mux.HandleFunc("/api/mail/list", a.auth(a.handleMailList))
	mux.HandleFunc("/api/mail/claim", a.auth(a.handleMailClaim))
	mux.HandleFunc("/api/version", a.handleVersion)
	mux.HandleFunc("/patches/", a.handlePatchFile)
	mux.HandleFunc("/api/admin/publish_patch", a.handlePublishPatch)
	mux.HandleFunc("/api/admin/patches/delete", a.handleAdminPatchDelete)
	mux.HandleFunc("/api/admin/patches/", a.handleAdminPatchDeleteByPath)
	mux.HandleFunc("/api/admin/overview", a.handleAdminOverview)
	mux.HandleFunc("/api/admin/mails", a.handleAdminMails)
	mux.HandleFunc("/api/admin/mails/delete", a.handleAdminMailDelete)
	mux.HandleFunc("/api/admin/users", a.handleAdminUsers)
	mux.HandleFunc("/api/admin/users/reset_password", a.handleAdminResetPassword)
	mux.HandleFunc("/api/admin/users/delete", a.handleAdminDeleteUser)
	mux.HandleFunc("/api/admin/users/", a.handleAdminUserByPath)
	mux.HandleFunc("/admin", a.handleAdminPage)
	mux.HandleFunc("/admin/", a.handleAdminPage)
	return mux
}

// resolveListenAddr 监听地址优先级：PORT > JADE_ADDR > 默认 :28473。
// PORT 为纯数字（如 28473）时自动补全前导冒号；其余写法（":28473"、
// "127.0.0.1:28473"）原样使用，兼容容器与云平台注入的 PORT 约定。
func resolveListenAddr() string {
	if raw := strings.TrimSpace(os.Getenv("PORT")); raw != "" {
		if isDigits(raw) {
			return ":" + raw
		}
		return raw
	}
	if addr := strings.TrimSpace(os.Getenv("JADE_ADDR")); addr != "" {
		return addr
	}
	return defaultListenAddr
}

func isDigits(value string) bool {
	if value == "" {
		return false
	}
	for _, r := range value {
		if r < '0' || r > '9' {
			return false
		}
	}
	return true
}

func envOr(key, fallback string) string {
	if v := strings.TrimSpace(os.Getenv(key)); v != "" {
		return v
	}
	return fallback
}

func (a *App) handleHealth(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

// ---------------------------------------------------------------- JSON / 中间件

func writeJSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.Header().Set("Cache-Control", "no-store")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(payload)
}

func writeOK(w http.ResponseWriter, data any) {
	writeJSON(w, http.StatusOK, apiResponse{Code: 0, Data: data})
}

func writeFail(w http.ResponseWriter, status, code int, message string) {
	writeJSON(w, status, apiResponse{Code: code, Message: message})
}

// writeFailWithData 用于 409 冲突：附带云端存档摘要，客户端据此弹「二选一」。
func writeFailWithData(w http.ResponseWriter, status, code int, message string, data any) {
	writeJSON(w, status, apiResponse{Code: code, Message: message, Data: data})
}

// decodeJSON 限制请求体大小并严格解析单个 JSON 对象。
func decodeJSON(w http.ResponseWriter, r *http.Request, limit int64, dst any) error {
	r.Body = http.MaxBytesReader(w, r.Body, limit)
	dec := json.NewDecoder(r.Body)
	if err := dec.Decode(dst); err != nil {
		return err
	}
	return nil
}

type statusRecorder struct {
	http.ResponseWriter
	status int
	bytes  int
}

func (s *statusRecorder) WriteHeader(code int) {
	s.status = code
	s.ResponseWriter.WriteHeader(code)
}

func (s *statusRecorder) Write(p []byte) (int, error) {
	if s.status == 0 {
		s.status = http.StatusOK
	}
	n, err := s.ResponseWriter.Write(p)
	s.bytes += n
	return n, err
}

func withRequestLog(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		rec := &statusRecorder{ResponseWriter: w}
		next.ServeHTTP(rec, r)
		status := rec.status
		if status == 0 {
			status = http.StatusOK
		}
		log.Printf("%s %s %d %dB %s", r.Method, r.URL.RequestURI(), status, rec.bytes,
			time.Since(start).Round(time.Millisecond))
	})
}

func withRecover(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if rec := recover(); rec != nil {
				log.Printf("[jade-server] panic: %v", rec)
				writeFail(w, http.StatusInternalServerError, 5000, "服务内部异常")
			}
		}()
		next.ServeHTTP(w, r)
	})
}

func withCORS(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers",
			"Authorization, Content-Type, X-Admin-Key")
		w.Header().Set("Access-Control-Max-Age", "86400")
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		next.ServeHTTP(w, r)
	})
}
