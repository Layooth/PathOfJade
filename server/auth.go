package main

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
)

const (
	tokenTTL         = 30 * 24 * time.Hour
	usernameMinRunes = 2
	usernameMaxRunes = 16
	passwordMinBytes = 6
	passwordMaxBytes = 72 // bcrypt 上限
	requestJSONLimit = 1 << 20
)

type ctxKey string

const ctxUIDKey ctxKey = "jade_uid"

// Claims 为 JWT 载荷：uid 为主键，username 便于日志与客户端展示。
type Claims struct {
	UID      int64  `json:"uid"`
	Username string `json:"username"`
	jwt.RegisteredClaims
}

type userPayload struct {
	UID       int64  `json:"uid"`
	Username  string `json:"username"`
	IsGuest   bool   `json:"is_guest"`
	CreatedAt int64  `json:"created_at,omitempty"`
	Token     string `json:"token,omitempty"`
}

// ---------------------------------------------------------------- 游客 / 绑定 / 登录

const selfServiceClosedMsg = "内测期间暂未开放自行立籍，请联系掌教获取道号与密令"

// handleGuest 已关闭玩家自助游客建号；统一 403，避免绕过管理员发号。
func (a *App) handleGuest(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeFail(w, http.StatusMethodNotAllowed, 4050, "仅支持 POST")
		return
	}
	writeFail(w, http.StatusForbidden, 403, selfServiceClosedMsg)
}

// handleBind 已关闭自助立籍；统一 403（路由不再包 auth，缺 token 也返回同一提示）。
func (a *App) handleBind(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeFail(w, http.StatusMethodNotAllowed, 4050, "仅支持 POST")
		return
	}
	writeFail(w, http.StatusForbidden, 403, selfServiceClosedMsg)
}

func (a *App) handleLogin(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeFail(w, http.StatusMethodNotAllowed, 4050, "仅支持 POST")
		return
	}
	var req struct {
		Username string `json:"username"`
		Password string `json:"password"`
	}
	if err := decodeJSON(w, r, requestJSONLimit, &req); err != nil {
		writeFail(w, http.StatusBadRequest, 4000, "请求体格式不正确")
		return
	}
	username := strings.TrimSpace(req.Username)
	if username == "" || req.Password == "" {
		writeFail(w, http.StatusBadRequest, 4004, "道号与口令不能为空")
		return
	}

	var uid int64
	var storedHash string
	var isGuest int
	err := a.db.QueryRow(
		`SELECT id, password_hash, is_guest FROM users WHERE username = ?`, username).
		Scan(&uid, &storedHash, &isGuest)
	if err != nil || storedHash == "" || isGuest != 0 {
		writeFail(w, http.StatusUnauthorized, 4011, "道号或口令不符")
		return
	}
	if bcrypt.CompareHashAndPassword([]byte(storedHash), []byte(req.Password)) != nil {
		writeFail(w, http.StatusUnauthorized, 4011, "道号或口令不符")
		return
	}
	a.respondUser(w, uid, username, false, 0)
}

// respondUser 统一签发 JWT 并返回游客/绑定后的用户信息。
func (a *App) respondUser(w http.ResponseWriter, uid int64, username string, isGuest bool,
	createdAt int64) {
	a.touchLastSeen(uid, time.Now().Unix())
	token, err := a.issueToken(uid, username)
	if err != nil {
		writeFail(w, http.StatusInternalServerError, 5006, "签发凭证失败")
		return
	}
	writeOK(w, userPayload{
		UID:       uid,
		Username:  username,
		IsGuest:   isGuest,
		CreatedAt: createdAt,
		Token:     token,
	})
}

func (a *App) issueToken(uid int64, username string) (string, error) {
	now := time.Now()
	claims := Claims{
		UID:      uid,
		Username: username,
		RegisteredClaims: jwt.RegisteredClaims{
			Issuer:    "jade-codex",
			Subject:   strconv.FormatInt(uid, 10),
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(tokenTTL)),
		},
	}
	return jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString(a.jwtSecret)
}

// ---------------------------------------------------------------- 鉴权

func (a *App) auth(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		header := r.Header.Get("Authorization")
		if !strings.HasPrefix(header, "Bearer ") {
			writeFail(w, http.StatusUnauthorized, 4010, "缺少登录凭证")
			return
		}
		raw := strings.TrimSpace(strings.TrimPrefix(header, "Bearer "))
		claims := &Claims{}
		token, err := jwt.ParseWithClaims(raw, claims, func(t *jwt.Token) (any, error) {
			if t.Method.Alg() != jwt.SigningMethodHS256.Alg() {
				return nil, fmt.Errorf("unexpected signing method: %s", t.Method.Alg())
			}
			return a.jwtSecret, nil
		}, jwt.WithValidMethods([]string{"HS256"}))
		if err != nil || !token.Valid || claims.UID <= 0 {
			writeFail(w, http.StatusUnauthorized, 4012, "登录凭证无效或已过期")
			return
		}
		ctx := context.WithValue(r.Context(), ctxUIDKey, claims.UID)
		next(w, r.WithContext(ctx))
	}
}

func uidFrom(ctx context.Context) int64 {
	if v, ok := ctx.Value(ctxUIDKey).(int64); ok {
		return v
	}
	return 0
}

// ---------------------------------------------------------------- 工具

func validateUsername(name string) string {
	if name == "" {
		return "道号不能为空"
	}
	if strings.ContainsAny(name, " \t\r\n") {
		return "道号不能包含空白字符"
	}
	count := utf8.RuneCountInString(name)
	if count < usernameMinRunes || count > usernameMaxRunes {
		return "道号长度需为 2~16 个字符"
	}
	return ""
}

func randomHex(n int) string {
	buf := make([]byte, (n+1)/2)
	if _, err := rand.Read(buf); err != nil {
		return fmt.Sprintf("%d", time.Now().UnixNano())[:n]
	}
	out := hex.EncodeToString(buf)
	if len(out) > n {
		out = out[:n]
	}
	return out
}

func isUniqueConstraint(err error) bool {
	return err != nil && strings.Contains(strings.ToUpper(err.Error()), "UNIQUE")
}
