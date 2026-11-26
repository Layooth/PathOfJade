package main

import (
	"crypto/subtle"
	"database/sql"
	_ "embed"
	"errors"
	"net/http"
	"strconv"
	"strings"
	"time"

	"golang.org/x/crypto/bcrypt"
)

//go:embed admin.html
var adminHTML []byte

type adminUserRow struct {
	UID           int64   `json:"uid"`
	Username      string  `json:"username"`
	CreatedAt     int64   `json:"created_at"`
	IsGuest       bool    `json:"is_guest"`
	HasSave       bool    `json:"has_save"`
	SaveRev       int64   `json:"save_rev"`
	RealmName     string  `json:"realm_name"`
	RealmOrder    int64   `json:"realm_order"`
	CultivationXP float64 `json:"cultivation_xp"`
	TowerFloor    int64   `json:"tower_floor"`
	SpiritStones  string  `json:"spirit_stones"`
	PlaySeconds   int64   `json:"play_seconds"`
	SaveUpdatedAt int64   `json:"save_updated_at"`
	LastSeenAt    int64   `json:"last_seen_at"`
	IsOnline      bool    `json:"is_online"`
}

// adminOverview 支撑「宗门概览」统计栏与天道补丁历史列表。
type adminOverview struct {
	TotalUsers     int          `json:"total_users"`
	UsersWithSave  int          `json:"users_with_save"`
	Active24h      int          `json:"active_24h"`
	OnlineCount    int          `json:"online_count"`
	LatestPatchRev int          `json:"latest_patch_rev"`
	Patches        []PatchEntry `json:"patches"`
}

// handleAdminOverview 返回宗门概览 4 项统计 + 已发布补丁历史（复用版本清单）。
func (a *App) handleAdminOverview(w http.ResponseWriter, r *http.Request) {
	if !a.requireAdmin(w, r) {
		return
	}
	if r.Method != http.MethodGet {
		writeFail(w, http.StatusMethodNotAllowed, 4050, "仅支持 GET")
		return
	}
	var ov adminOverview
	_ = a.db.QueryRow(`SELECT COUNT(*) FROM users`).Scan(&ov.TotalUsers)
	_ = a.db.QueryRow(`SELECT COUNT(*) FROM cloud_saves`).Scan(&ov.UsersWithSave)
	now := time.Now().Unix()
	_ = a.db.QueryRow(`SELECT COUNT(*) FROM cloud_saves WHERE updated_at >= ?`, now-86400).
		Scan(&ov.Active24h)
	ov.OnlineCount = a.onlineCount(now)
	if m, err := a.loadManifest(); err == nil {
		ov.LatestPatchRev = m.LatestPatchRev
		ov.Patches = m.Patches
	}
	if ov.Patches == nil {
		ov.Patches = []PatchEntry{}
	}
	writeOK(w, ov)
}

// requireAdmin 统一管理员鉴权：未配置密钥 503，密钥不匹配 401。
func (a *App) requireAdmin(w http.ResponseWriter, r *http.Request) bool {
	if a.adminKey == "" {
		writeFail(w, http.StatusServiceUnavailable, 5030,
			"管理接口未启用（未配置 JADE_ADMIN_KEY）")
		return false
	}
	provided := r.Header.Get("X-Admin-Key")
	if subtle.ConstantTimeCompare([]byte(provided), []byte(a.adminKey)) != 1 {
		writeFail(w, http.StatusUnauthorized, 4014, "管理员密钥不正确")
		return false
	}
	return true
}

// handleAdminPage 返回内嵌单页管理后台（无外部 CDN）。
func (a *App) handleAdminPage(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet && r.Method != http.MethodHead {
		writeFail(w, http.StatusMethodNotAllowed, 4050, "仅支持 GET")
		return
	}
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.Header().Set("Cache-Control", "no-store")
	_, _ = w.Write(adminHTML)
}

// handleAdminUsers 支持 GET 列表与 POST 创建。
func (a *App) handleAdminUsers(w http.ResponseWriter, r *http.Request) {
	if !a.requireAdmin(w, r) {
		return
	}
	switch r.Method {
	case http.MethodGet:
		a.adminListUsers(w)
	case http.MethodPost:
		a.adminCreateUser(w, r)
	default:
		writeFail(w, http.StatusMethodNotAllowed, 4050, "仅支持 GET/POST")
	}
}

func (a *App) adminListUsers(w http.ResponseWriter) {
	rows, err := a.db.Query(`
SELECT u.id, u.username, u.created_at, u.is_guest, u.last_seen_at,
       CASE WHEN s.user_id IS NULL THEN 0 ELSE 1 END AS has_save,
       COALESCE(s.save_rev, 0), COALESCE(s.realm_name, ''),
       COALESCE(s.realm_order, 0), COALESCE(s.cultivation_xp, 0),
       COALESCE(s.tower_floor, 0),
       COALESCE(s.spirit_stones, ''), COALESCE(s.play_seconds, 0),
       COALESCE(s.updated_at, 0)
FROM users u
LEFT JOIN cloud_saves s ON s.user_id = u.id
ORDER BY u.id ASC`)
	if err != nil {
		writeFail(w, http.StatusInternalServerError, 5007, "读取仙籍名录失败")
		return
	}
	defer rows.Close()
	users := make([]adminUserRow, 0, 32)
	now := time.Now().Unix()
	for rows.Next() {
		var item adminUserRow
		var isGuest, hasSave int
		if err := rows.Scan(&item.UID, &item.Username, &item.CreatedAt, &isGuest,
			&item.LastSeenAt, &hasSave, &item.SaveRev, &item.RealmName, &item.RealmOrder,
			&item.CultivationXP, &item.TowerFloor, &item.SpiritStones,
			&item.PlaySeconds, &item.SaveUpdatedAt); err != nil {
			writeFail(w, http.StatusInternalServerError, 5007, "读取仙籍名录失败")
			return
		}
		item.IsGuest = isGuest == 1
		item.HasSave = hasSave == 1
		item.IsOnline = item.LastSeenAt >= onlineCutoff(now)
		users = append(users, item)
	}
	if err := rows.Err(); err != nil {
		writeFail(w, http.StatusInternalServerError, 5007, "读取仙籍名录失败")
		return
	}
	writeOK(w, map[string]any{"users": users})
}

func (a *App) adminCreateUser(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Username string `json:"username"`
		Password string `json:"password"`
	}
	if err := decodeJSON(w, r, requestJSONLimit, &req); err != nil {
		writeFail(w, http.StatusBadRequest, 4000, "请求体格式不正确")
		return
	}
	username := strings.TrimSpace(req.Username)
	if msg := validateUsername(username); msg != "" {
		writeFail(w, http.StatusBadRequest, 4002, msg)
		return
	}
	if len(req.Password) < passwordMinBytes || len(req.Password) > passwordMaxBytes {
		writeFail(w, http.StatusBadRequest, 4003, "密令长度需为 6~72 字节")
		return
	}

	var existing int64
	switch err := a.db.QueryRow(`SELECT id FROM users WHERE username = ?`, username).
		Scan(&existing); {
	case err == nil:
		writeFail(w, http.StatusConflict, 4092, "道号已被占用")
		return
	case !errors.Is(err, sql.ErrNoRows):
		writeFail(w, http.StatusInternalServerError, 5001, "查询道号失败")
		return
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		writeFail(w, http.StatusInternalServerError, 5004, "密令加密失败")
		return
	}
	now := time.Now().Unix()
	for attempt := 0; attempt < 8; attempt++ {
		// 后台建号没有真实设备号：填唯一占位值，避开 device_id UNIQUE 约束
		deviceID := "manual_" + randomHex(16)
		res, insertErr := a.db.Exec(
			`INSERT INTO users(device_id, username, password_hash, is_guest, created_at)
			 VALUES(?, ?, ?, 0, ?)`, deviceID, username, string(hash), now)
		if insertErr == nil {
			uid, _ := res.LastInsertId()
			writeOK(w, map[string]any{"uid": uid, "username": username})
			return
		}
		if !isUniqueConstraint(insertErr) {
			writeFail(w, http.StatusInternalServerError, 5002, "创建仙籍失败")
			return
		}
		var taken int64
		if e := a.db.QueryRow(`SELECT id FROM users WHERE username = ?`, username).
			Scan(&taken); e == nil {
			writeFail(w, http.StatusConflict, 4092, "道号已被占用")
			return
		}
	}
	writeFail(w, http.StatusInternalServerError, 5003, "生成仙籍失败，请重试")
}

// handleAdminResetPassword 重置指定仙籍的密令。
func (a *App) handleAdminResetPassword(w http.ResponseWriter, r *http.Request) {
	if !a.requireAdmin(w, r) {
		return
	}
	if r.Method != http.MethodPost {
		writeFail(w, http.StatusMethodNotAllowed, 4050, "仅支持 POST")
		return
	}
	var req struct {
		UID         int64  `json:"uid"`
		NewPassword string `json:"new_password"`
	}
	if err := decodeJSON(w, r, requestJSONLimit, &req); err != nil {
		writeFail(w, http.StatusBadRequest, 4000, "请求体格式不正确")
		return
	}
	if req.UID <= 0 {
		writeFail(w, http.StatusBadRequest, 4005, "uid 不正确")
		return
	}
	if len(req.NewPassword) < passwordMinBytes || len(req.NewPassword) > passwordMaxBytes {
		writeFail(w, http.StatusBadRequest, 4003, "密令长度需为 6~72 字节")
		return
	}
	hash, err := bcrypt.GenerateFromPassword([]byte(req.NewPassword), bcrypt.DefaultCost)
	if err != nil {
		writeFail(w, http.StatusInternalServerError, 5004, "密令加密失败")
		return
	}
	res, err := a.db.Exec(`UPDATE users SET password_hash = ? WHERE id = ?`,
		string(hash), req.UID)
	if err != nil {
		writeFail(w, http.StatusInternalServerError, 5005, "重置密令失败")
		return
	}
	if affected, _ := res.RowsAffected(); affected == 0 {
		writeFail(w, http.StatusNotFound, 4040, "仙籍不存在")
		return
	}
	writeOK(w, map[string]any{"uid": req.UID})
}

// handleAdminDeleteUser 支持 POST /api/admin/users/delete 与 DELETE /api/admin/users/{uid}。
func (a *App) handleAdminDeleteUser(w http.ResponseWriter, r *http.Request) {
	if !a.requireAdmin(w, r) {
		return
	}
	if r.Method != http.MethodPost {
		writeFail(w, http.StatusMethodNotAllowed, 4050, "仅支持 POST")
		return
	}
	var req struct {
		UID int64 `json:"uid"`
	}
	if err := decodeJSON(w, r, requestJSONLimit, &req); err != nil {
		writeFail(w, http.StatusBadRequest, 4000, "请求体格式不正确")
		return
	}
	a.adminDeleteByUID(w, req.UID)
}

func (a *App) handleAdminUserByPath(w http.ResponseWriter, r *http.Request) {
	if !a.requireAdmin(w, r) {
		return
	}
	if r.Method != http.MethodDelete {
		writeFail(w, http.StatusMethodNotAllowed, 4050, "仅支持 DELETE")
		return
	}
	raw := strings.TrimPrefix(r.URL.Path, "/api/admin/users/")
	if raw == "" || strings.Contains(raw, "/") {
		writeFail(w, http.StatusBadRequest, 4005, "uid 不正确")
		return
	}
	uid, err := strconv.ParseInt(raw, 10, 64)
	if err != nil || uid <= 0 {
		writeFail(w, http.StatusBadRequest, 4005, "uid 不正确")
		return
	}
	a.adminDeleteByUID(w, uid)
}

func (a *App) adminDeleteByUID(w http.ResponseWriter, uid int64) {
	if uid <= 0 {
		writeFail(w, http.StatusBadRequest, 4005, "uid 不正确")
		return
	}
	tx, err := a.db.Begin()
	if err != nil {
		writeFail(w, http.StatusInternalServerError, 5006, "删除仙籍失败")
		return
	}
	defer func() { _ = tx.Rollback() }()
	if _, err := tx.Exec(`DELETE FROM cloud_saves WHERE user_id = ?`, uid); err != nil {
		writeFail(w, http.StatusInternalServerError, 5006, "删除云篆失败")
		return
	}
	res, err := tx.Exec(`DELETE FROM users WHERE id = ?`, uid)
	if err != nil {
		writeFail(w, http.StatusInternalServerError, 5006, "删除仙籍失败")
		return
	}
	if affected, _ := res.RowsAffected(); affected == 0 {
		writeFail(w, http.StatusNotFound, 4040, "仙籍不存在")
		return
	}
	if err := tx.Commit(); err != nil {
		writeFail(w, http.StatusInternalServerError, 5006, "删除仙籍失败")
		return
	}
	writeOK(w, map[string]any{"uid": uid})
}
