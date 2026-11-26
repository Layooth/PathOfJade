package main

import (
	"database/sql"
	"encoding/json"
	"errors"
	"net/http"
	"strings"
	"time"
	"unicode/utf8"
)

// onlineWindowSec 在线判定窗口：2.5 分钟内有登录 / 心跳 / 上传 / 查榜活动即在线。
const onlineWindowSec int64 = 150

type mailItem struct {
	ID    string `json:"id"`
	Count int    `json:"count"`
}

type mailRow struct {
	ID           int64      `json:"id"`
	TargetUID    int64      `json:"target_uid"`
	Title        string     `json:"title"`
	Body         string     `json:"body"`
	SpiritStones int64      `json:"spirit_stones"`
	Items        []mailItem `json:"items"`
	CreatedAt    int64      `json:"created_at"`
	ExpiresAt    int64      `json:"expires_at"`
	Claimed      bool       `json:"claimed"`
	ClaimedAt    int64      `json:"claimed_at,omitempty"`
}

type adminMailRow struct {
	ID           int64  `json:"id"`
	TargetUID    int64  `json:"target_uid"`
	TargetName   string `json:"target_name"`
	Title        string `json:"title"`
	Body         string `json:"body"`
	SpiritStones int64  `json:"spirit_stones"`
	ItemsJSON    string `json:"items_json"`
	CreatedAt    int64  `json:"created_at"`
	ExpiresAt    int64  `json:"expires_at"`
	ClaimCount   int64  `json:"claim_count"`
}

// touchLastSeen 更新最近活跃时间；心跳失败不应阻断主业务流程。
func (a *App) touchLastSeen(uid int64, now int64) {
	if uid <= 0 {
		return
	}
	_, _ = a.db.Exec(`UPDATE users SET last_seen_at = ? WHERE id = ?`, now, uid)
}

func onlineCutoff(now int64) int64 {
	return now - onlineWindowSec
}

func (a *App) onlineCount(now int64) int {
	var n int
	if err := a.db.QueryRow(`SELECT COUNT(*) FROM users WHERE last_seen_at >= ?`,
		onlineCutoff(now)).Scan(&n); err != nil {
		return 0
	}
	return n
}

// handlePing 轻量心跳：刷新在线时间并返回未读传书数。
func (a *App) handlePing(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeFail(w, http.StatusMethodNotAllowed, 4050, "仅支持 POST")
		return
	}
	uid := uidFrom(r.Context())
	now := time.Now().Unix()
	a.touchLastSeen(uid, now)
	writeOK(w, map[string]any{
		"server_time":       now,
		"unread_mail_count": a.unreadMailCount(uid, now),
	})
}

func (a *App) unreadMailCount(uid, now int64) int {
	var n int
	err := a.db.QueryRow(`
SELECT COUNT(*) FROM mails m
LEFT JOIN mail_claims c ON c.mail_id = m.id AND c.uid = ?
WHERE (m.target_uid = 0 OR m.target_uid = ?)
  AND (m.expires_at = 0 OR m.expires_at > ?)
  AND c.mail_id IS NULL`, uid, uid, now).Scan(&n)
	if err != nil {
		return 0
	}
	return n
}

// handleMailList 返回当前玩家可领传书（全服 + 指定），未领取优先、创建时间倒序。
func (a *App) handleMailList(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeFail(w, http.StatusMethodNotAllowed, 4050, "仅支持 GET")
		return
	}
	uid := uidFrom(r.Context())
	now := time.Now().Unix()
	a.touchLastSeen(uid, now)
	rows, err := a.db.Query(`
SELECT m.id, m.target_uid, m.title, m.body, m.spirit_stones, m.items_json,
       m.created_at, m.expires_at,
       CASE WHEN c.mail_id IS NULL THEN 0 ELSE 1 END AS claimed,
       COALESCE(c.claimed_at, 0)
FROM mails m
LEFT JOIN mail_claims c ON c.mail_id = m.id AND c.uid = ?
WHERE (m.target_uid = 0 OR m.target_uid = ?)
  AND (m.expires_at = 0 OR m.expires_at > ?)
ORDER BY claimed ASC, m.created_at DESC, m.id DESC
LIMIT 50`, uid, uid, now)
	if err != nil {
		writeFail(w, http.StatusInternalServerError, 5017, "读取传书失败")
		return
	}
	defer rows.Close()
	mails := make([]mailRow, 0, 16)
	for rows.Next() {
		var item mailRow
		var claimed int
		var itemsJSON string
		if err := rows.Scan(&item.ID, &item.TargetUID, &item.Title, &item.Body,
			&item.SpiritStones, &itemsJSON, &item.CreatedAt, &item.ExpiresAt,
			&claimed, &item.ClaimedAt); err != nil {
			writeFail(w, http.StatusInternalServerError, 5017, "读取传书失败")
			return
		}
		item.Claimed = claimed == 1
		item.Items = parseMailItems(itemsJSON)
		mails = append(mails, item)
	}
	writeOK(w, map[string]any{"mails": mails})
}

// handleMailClaim 以 INSERT OR IGNORE + RowsAffected 保证并发连点只发一次。
func (a *App) handleMailClaim(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeFail(w, http.StatusMethodNotAllowed, 4050, "仅支持 POST")
		return
	}
	uid := uidFrom(r.Context())
	var req struct {
		MailID int64 `json:"mail_id"`
	}
	if err := decodeJSON(w, r, requestJSONLimit, &req); err != nil {
		writeFail(w, http.StatusBadRequest, 4000, "请求体格式不正确")
		return
	}
	if req.MailID <= 0 {
		writeFail(w, http.StatusBadRequest, 4005, "传书编号不正确")
		return
	}

	now := time.Now().Unix()
	a.touchLastSeen(uid, now)
	tx, err := a.db.Begin()
	if err != nil {
		writeFail(w, http.StatusInternalServerError, 5018, "领取传书失败")
		return
	}
	defer func() { _ = tx.Rollback() }()

	var targetUID, stones, expiresAt int64
	var itemsJSON string
	switch err := tx.QueryRow(`
SELECT target_uid, spirit_stones, items_json, expires_at FROM mails WHERE id = ?`,
		req.MailID).Scan(&targetUID, &stones, &itemsJSON, &expiresAt); {
	case errors.Is(err, sql.ErrNoRows):
		writeFail(w, http.StatusNotFound, 4043, "传书不存在或已过期")
		return
	case err != nil:
		writeFail(w, http.StatusInternalServerError, 5018, "领取传书失败")
		return
	}
	if expiresAt > 0 && now >= expiresAt {
		writeFail(w, http.StatusNotFound, 4043, "传书不存在或已过期")
		return
	}
	if targetUID != 0 && targetUID != uid {
		writeFail(w, http.StatusForbidden, 4031, "并非发给当前道号的传书")
		return
	}

	res, err := tx.Exec(`INSERT OR IGNORE INTO mail_claims(mail_id, uid, claimed_at)
VALUES(?, ?, ?)`, req.MailID, uid, now)
	if err != nil {
		writeFail(w, http.StatusInternalServerError, 5018, "领取传书失败")
		return
	}
	affected, err := res.RowsAffected()
	if err != nil || affected != 1 {
		writeFail(w, http.StatusConflict, 4093, "该传书物资已领取")
		return
	}
	if err := tx.Commit(); err != nil {
		writeFail(w, http.StatusInternalServerError, 5018, "领取传书失败")
		return
	}
	writeOK(w, map[string]any{
		"mail_id":       req.MailID,
		"spirit_stones": stones,
		"items":         parseMailItems(itemsJSON),
	})
}

// handleAdminMails 管理端：GET 最近 30 条，POST 新建传书。
func (a *App) handleAdminMails(w http.ResponseWriter, r *http.Request) {
	if !a.requireAdmin(w, r) {
		return
	}
	switch r.Method {
	case http.MethodGet:
		a.adminListMails(w)
	case http.MethodPost:
		a.adminCreateMail(w, r)
	default:
		writeFail(w, http.StatusMethodNotAllowed, 4050, "仅支持 GET/POST")
	}
}

func (a *App) adminListMails(w http.ResponseWriter) {
	rows, err := a.db.Query(`
SELECT m.id, m.target_uid,
       CASE WHEN m.target_uid = 0 THEN '全服同道' ELSE COALESCE(u.username, '未知仙籍') END,
       m.title, m.body, m.spirit_stones, m.items_json, m.created_at, m.expires_at,
       (SELECT COUNT(*) FROM mail_claims c WHERE c.mail_id = m.id)
FROM mails m
LEFT JOIN users u ON u.id = m.target_uid
ORDER BY m.created_at DESC, m.id DESC
LIMIT 30`)
	if err != nil {
		writeFail(w, http.StatusInternalServerError, 5019, "读取传书记录失败")
		return
	}
	defer rows.Close()
	mails := make([]adminMailRow, 0, 16)
	for rows.Next() {
		var item adminMailRow
		if err := rows.Scan(&item.ID, &item.TargetUID, &item.TargetName, &item.Title,
			&item.Body, &item.SpiritStones, &item.ItemsJSON, &item.CreatedAt,
			&item.ExpiresAt, &item.ClaimCount); err != nil {
			writeFail(w, http.StatusInternalServerError, 5019, "读取传书记录失败")
			return
		}
		mails = append(mails, item)
	}
	writeOK(w, map[string]any{"mails": mails})
}

func (a *App) adminCreateMail(w http.ResponseWriter, r *http.Request) {
	var req struct {
		TargetUID    int64      `json:"target_uid"`
		Title        string     `json:"title"`
		Body         string     `json:"body"`
		SpiritStones int64      `json:"spirit_stones"`
		Items        []mailItem `json:"items"`
		ExpireDays   int        `json:"expire_days"`
	}
	if err := decodeJSON(w, r, requestJSONLimit, &req); err != nil {
		writeFail(w, http.StatusBadRequest, 4000, "请求体格式不正确")
		return
	}
	title := strings.TrimSpace(req.Title)
	if n := utf8.RuneCountInString(title); n < 1 || n > 60 {
		writeFail(w, http.StatusBadRequest, 4015, "传书标题需为 1~60 字")
		return
	}
	if req.SpiritStones < 0 {
		writeFail(w, http.StatusBadRequest, 4016, "灵石数量不能为负")
		return
	}
	if req.ExpireDays < 0 || req.ExpireDays > 3650 {
		writeFail(w, http.StatusBadRequest, 4017, "有效期需为 0~3650 天")
		return
	}
	items, ok := normalizeMailItems(req.Items)
	if !ok {
		writeFail(w, http.StatusBadRequest, 4018, "物品编号不能为空且数量需大于 0")
		return
	}
	if req.TargetUID < 0 {
		writeFail(w, http.StatusBadRequest, 4005, "目标道号不正确")
		return
	}
	if req.TargetUID > 0 {
		var exists int64
		if err := a.db.QueryRow(`SELECT id FROM users WHERE id = ?`, req.TargetUID).
			Scan(&exists); err != nil {
			writeFail(w, http.StatusNotFound, 4040, "目标道号不存在")
			return
		}
	}
	itemsJSON, err := json.Marshal(items)
	if err != nil {
		writeFail(w, http.StatusInternalServerError, 5020, "写入传书失败")
		return
	}
	now := time.Now().Unix()
	expiresAt := int64(0)
	if req.ExpireDays > 0 {
		expiresAt = now + int64(req.ExpireDays)*86400
	}
	res, err := a.db.Exec(`
INSERT INTO mails(target_uid, title, body, spirit_stones, items_json, created_at, expires_at)
VALUES(?, ?, ?, ?, ?, ?, ?)`, req.TargetUID, title, strings.TrimSpace(req.Body),
		req.SpiritStones, string(itemsJSON), now, expiresAt)
	if err != nil {
		writeFail(w, http.StatusInternalServerError, 5020, "写入传书失败")
		return
	}
	id, _ := res.LastInsertId()
	writeOK(w, map[string]any{"id": id, "created_at": now, "expires_at": expiresAt})
}

// handleAdminMailDelete 删除传书及全部领取记录。
func (a *App) handleAdminMailDelete(w http.ResponseWriter, r *http.Request) {
	if !a.requireAdmin(w, r) {
		return
	}
	if r.Method != http.MethodPost {
		writeFail(w, http.StatusMethodNotAllowed, 4050, "仅支持 POST")
		return
	}
	var req struct {
		ID int64 `json:"id"`
	}
	if err := decodeJSON(w, r, requestJSONLimit, &req); err != nil {
		writeFail(w, http.StatusBadRequest, 4000, "请求体格式不正确")
		return
	}
	if req.ID <= 0 {
		writeFail(w, http.StatusBadRequest, 4005, "传书编号不正确")
		return
	}
	tx, err := a.db.Begin()
	if err != nil {
		writeFail(w, http.StatusInternalServerError, 5021, "删除传书失败")
		return
	}
	defer func() { _ = tx.Rollback() }()
	if _, err := tx.Exec(`DELETE FROM mail_claims WHERE mail_id = ?`, req.ID); err != nil {
		writeFail(w, http.StatusInternalServerError, 5021, "删除传书失败")
		return
	}
	res, err := tx.Exec(`DELETE FROM mails WHERE id = ?`, req.ID)
	if err != nil {
		writeFail(w, http.StatusInternalServerError, 5021, "删除传书失败")
		return
	}
	if affected, _ := res.RowsAffected(); affected == 0 {
		writeFail(w, http.StatusNotFound, 4043, "传书不存在")
		return
	}
	if err := tx.Commit(); err != nil {
		writeFail(w, http.StatusInternalServerError, 5021, "删除传书失败")
		return
	}
	writeOK(w, map[string]any{"id": req.ID})
}

func normalizeMailItems(items []mailItem) ([]mailItem, bool) {
	out := make([]mailItem, 0, len(items))
	for _, item := range items {
		id := strings.TrimSpace(item.ID)
		if id == "" || item.Count <= 0 {
			return nil, false
		}
		out = append(out, mailItem{ID: id, Count: item.Count})
	}
	return out, true
}

func parseMailItems(raw string) []mailItem {
	items := make([]mailItem, 0, 4)
	if strings.TrimSpace(raw) == "" {
		return items
	}
	var parsed []mailItem
	if err := json.Unmarshal([]byte(raw), &parsed); err != nil {
		return items
	}
	for _, item := range parsed {
		if strings.TrimSpace(item.ID) != "" && item.Count > 0 {
			items = append(items, item)
		}
	}
	return items
}
