package main

import (
	"bytes"
	"compress/gzip"
	"database/sql"
	"encoding/base64"
	"errors"
	"io"
	"net/http"
	"strconv"
	"strings"
	"time"
	"unicode/utf8"
)

const (
	maxSavePayloadBytes = 512 * 1024 // 单次云存档上限 512KB（解压前 gzip 体积）
	uploadJSONLimit     = 1 << 20    // 覆盖 base64 膨胀后的 JSON 体积
)

type saveMeta struct {
	Exists       bool   `json:"exists"`
	SaveRev      int64  `json:"save_rev"`
	RealmName    string `json:"realm_name"`
	SpiritStones string `json:"spirit_stones"`
	PlaySeconds  int64  `json:"play_seconds"`
	UpdatedAt    int64  `json:"updated_at"`
}

// rowQuerier 让元数据读取既能跑在 *sql.DB 上，也能跑在事务内（避免单连接死锁）。
type rowQuerier interface {
	QueryRow(query string, args ...any) *sql.Row
}

func (a *App) handleSaveMeta(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeFail(w, http.StatusMethodNotAllowed, 4050, "仅支持 GET")
		return
	}
	uid := uidFrom(r.Context())
	meta, err := readSaveMeta(a.db, uid)
	if err != nil && !errors.Is(err, sql.ErrNoRows) {
		writeFail(w, http.StatusInternalServerError, 5007, "读取存档摘要失败")
		return
	}
	if errors.Is(err, sql.ErrNoRows) {
		meta = saveMeta{Exists: false}
	}
	writeOK(w, meta)
}

func (a *App) handleSaveDownload(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeFail(w, http.StatusMethodNotAllowed, 4050, "仅支持 GET")
		return
	}
	uid := uidFrom(r.Context())
	var rev, updatedAt int64
	var payload []byte
	err := a.db.QueryRow(
		`SELECT save_rev, payload, updated_at FROM cloud_saves WHERE user_id = ?`, uid).
		Scan(&rev, &payload, &updatedAt)
	if errors.Is(err, sql.ErrNoRows) {
		writeFail(w, http.StatusNotFound, 4041, "云端暂无存档")
		return
	}
	if err != nil {
		writeFail(w, http.StatusInternalServerError, 5008, "读取云端存档失败")
		return
	}
	writeOK(w, map[string]any{
		"save_rev":         rev,
		"payload_gzip_b64": base64.StdEncoding.EncodeToString(payload),
		"updated_at":       updatedAt,
	})
}

// handleSaveUpload 采用「base_rev 乐观锁」：云端版本比客户端基线新且未 force 时返回 409。
func (a *App) handleSaveUpload(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeFail(w, http.StatusMethodNotAllowed, 4050, "仅支持 POST")
		return
	}
	uid := uidFrom(r.Context())

	var req struct {
		BaseRev       int64   `json:"base_rev"`
		Force         bool    `json:"force"`
		RealmName     string  `json:"realm_name"`
		SpiritStones  string  `json:"spirit_stones"`
		PlaySeconds   int64   `json:"play_seconds"`
		RealmOrder    int     `json:"realm_order"`    // 可选：0~30 境界下标，旧客户端缺省 0
		CultivationXP float64 `json:"cultivation_xp"` // 可选：同境界修为，作并列次级排序
		TowerFloor    int     `json:"tower_floor"`    // 可选：镇魔塔历史最高层
		PayloadBase64 string  `json:"payload_gzip_b64"`
	}
	if err := decodeJSON(w, r, uploadJSONLimit, &req); err != nil {
		writeFail(w, http.StatusBadRequest, 4000, "请求体格式不正确或超过 1MB")
		return
	}
	// 基础边界钳制：旧客户端不传以下可选字段时保持 0，绝不报错
	if req.RealmOrder < 0 {
		req.RealmOrder = 0
	}
	if req.RealmOrder > 30 {
		req.RealmOrder = 30
	}
	if req.CultivationXP < 0 {
		req.CultivationXP = 0
	}
	if req.TowerFloor < 0 {
		req.TowerFloor = 0
	}
	req.SpiritStones = clampSpiritStones(req.SpiritStones)
	if req.BaseRev < 0 {
		writeFail(w, http.StatusBadRequest, 4005, "base_rev 不能为负")
		return
	}
	if req.PlaySeconds < 0 {
		writeFail(w, http.StatusBadRequest, 4006, "play_seconds 不能为负")
		return
	}
	if utf8.RuneCountInString(req.RealmName) > 64 {
		writeFail(w, http.StatusBadRequest, 4007, "realm_name 过长")
		return
	}
	if utf8.RuneCountInString(req.SpiritStones) > 32 {
		writeFail(w, http.StatusBadRequest, 4008, "spirit_stones 过长")
		return
	}
	if strings.TrimSpace(req.PayloadBase64) == "" {
		writeFail(w, http.StatusBadRequest, 4009, "存档内容不能为空")
		return
	}
	payload, err := base64.StdEncoding.DecodeString(req.PayloadBase64)
	if err != nil {
		writeFail(w, http.StatusBadRequest, 4010, "payload_gzip_b64 不是合法 Base64")
		return
	}
	if len(payload) == 0 || len(payload) > maxSavePayloadBytes {
		writeFail(w, http.StatusRequestEntityTooLarge, 4130, "存档需为 1 字节~512KB 的 gzip 数据")
		return
	}
	if err := validateGzip(payload); err != nil {
		writeFail(w, http.StatusBadRequest, 4011, "存档内容不是合法 gzip")
		return
	}

	now := time.Now().Unix()
	tx, err := a.db.Begin()
	if err != nil {
		writeFail(w, http.StatusInternalServerError, 5009, "开启事务失败")
		return
	}
	defer tx.Rollback()

	meta, err := readSaveMeta(tx, uid)
	cloudRev := int64(0)
	if err == nil {
		cloudRev = meta.SaveRev
	} else if !errors.Is(err, sql.ErrNoRows) {
		writeFail(w, http.StatusInternalServerError, 5007, "读取云端版本失败")
		return
	}

	if !req.Force && cloudRev > req.BaseRev {
		meta.Exists = true
		writeFailWithData(w, http.StatusConflict, 4091, "云端存档版本较新", meta)
		return
	}

	newRev := cloudRev + 1
	if _, err := tx.Exec(`UPDATE users SET last_seen_at = ? WHERE id = ?`, now, uid); err != nil {
		writeFail(w, http.StatusInternalServerError, 5010, "写入活跃状态失败")
		return
	}
	if _, err := tx.Exec(`
INSERT INTO cloud_saves(user_id, save_rev, realm_name, spirit_stones, play_seconds,
                        realm_order, cultivation_xp, tower_floor, payload, updated_at)
VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
ON CONFLICT(user_id) DO UPDATE SET
    save_rev = excluded.save_rev,
    realm_name = excluded.realm_name,
    spirit_stones = excluded.spirit_stones,
    play_seconds = excluded.play_seconds,
    realm_order = excluded.realm_order,
    cultivation_xp = excluded.cultivation_xp,
    tower_floor = excluded.tower_floor,
    payload = excluded.payload,
    updated_at = excluded.updated_at`,
		uid, newRev, req.RealmName, req.SpiritStones, req.PlaySeconds,
		req.RealmOrder, req.CultivationXP, req.TowerFloor, payload, now); err != nil {
		writeFail(w, http.StatusInternalServerError, 5010, "写入云端存档失败")
		return
	}
	if err := tx.Commit(); err != nil {
		writeFail(w, http.StatusInternalServerError, 5011, "提交存档事务失败")
		return
	}
	writeOK(w, map[string]any{
		"save_rev":   newRev,
		"updated_at": now,
	})
}

func readSaveMeta(q rowQuerier, uid int64) (saveMeta, error) {
	var meta saveMeta
	err := q.QueryRow(
		`SELECT save_rev, realm_name, spirit_stones, play_seconds, updated_at
		 FROM cloud_saves WHERE user_id = ?`, uid).
		Scan(&meta.SaveRev, &meta.RealmName, &meta.SpiritStones, &meta.PlaySeconds,
			&meta.UpdatedAt)
	if err != nil {
		return meta, err
	}
	meta.Exists = true
	return meta, nil
}

// clampSpiritStones 仅当可解析数值为负时归 "0"；紧凑格式文本（如「1.5万」）原样保留。
func clampSpiritStones(s string) string {
	t := strings.TrimSpace(s)
	if t == "" {
		return s
	}
	trimmed := strings.TrimRight(t, "万亿")
	if v, err := strconv.ParseFloat(trimmed, 64); err == nil && v < 0 {
		return "0"
	}
	return s
}

func validateGzip(raw []byte) error {
	if len(raw) < 2 || raw[0] != 0x1f || raw[1] != 0x8b {
		return errors.New("missing gzip magic")
	}
	zr, err := gzip.NewReader(bytes.NewReader(raw))
	if err != nil {
		return err
	}
	defer zr.Close()
	if _, err := io.Copy(io.Discard, zr); err != nil {
		return err
	}
	return nil
}
