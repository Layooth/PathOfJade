package main

import (
	"database/sql"
	"net/http"
	"strconv"
	"strings"
	"sync"
	"time"
)

// 榜单类型常量：realm（境界榜，默认）/ tower（镇魔塔榜）/ stones（灵石榜）。
const (
	lbRealm  = "realm"
	lbTower  = "tower"
	lbStones = "stones"
)

// leaderboardTTL 榜单缓存有效期，避免高频刷新压垮 SQLite。
const leaderboardTTL = 20 * time.Second

// leaderboardCacheCap 单类型缓存的行数封顶，够 limit≤100 的展示与切片使用。
const leaderboardCacheCap = 200

// stonesValueExpr 将格式化灵石文本（「1.5万」「2亿」/纯数字）折算为数值，
// 供灵石榜排序与名次计算使用；纯文本比较会把「500」误排在「1万」之前。
const stonesValueExpr = `(CASE
    WHEN cs.spirit_stones LIKE '%亿' THEN CAST(REPLACE(cs.spirit_stones, '亿', '') AS REAL) * 100000000
    WHEN cs.spirit_stones LIKE '%万' THEN CAST(REPLACE(cs.spirit_stones, '万', '') AS REAL) * 10000
    WHEN cs.spirit_stones = '' THEN 0
    ELSE CAST(cs.spirit_stones AS REAL)
END)`

// leaderboardEntry 是榜单单行，仅含公开字段。
// 严禁返回 password_hash / device_id / payload_gzip_b64 等隐私数据。
type leaderboardEntry struct {
	Rank          int64   `json:"rank"`
	UID           int64   `json:"uid"`
	Username      string  `json:"username"`
	RealmName     string  `json:"realm_name"`
	RealmOrder    int64   `json:"realm_order"`
	CultivationXP float64 `json:"cultivation_xp"`
	TowerFloor    int64   `json:"tower_floor"`
	SpiritStones  string  `json:"spirit_stones"`
	UpdatedAt     int64   `json:"updated_at"`
}

// leaderboardCache 为轻量内存缓存：按榜单类型存全量排名（不含 my_rank，后者实时查）。
type leaderboardCache struct {
	mu      sync.RWMutex
	entries map[string][]leaderboardEntry
	stamp   map[string]time.Time
}

func newLeaderboardCache() *leaderboardCache {
	return &leaderboardCache{
		entries: map[string][]leaderboardEntry{},
		stamp:   map[string]time.Time{},
	}
}

// lbCache 包级单例：随进程常驻，RWMutex 保证并发读写安全。
var lbCache = newLeaderboardCache()

// handleLeaderboard 返回指定榜单前 N 名 + 当前登录玩家的实时名次。
// 鉴权复用 a.auth（Bearer JWT）；查询参数 type / limit 均做校验与钳制。
func (a *App) handleLeaderboard(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeFail(w, http.StatusMethodNotAllowed, 4050, "仅支持 GET")
		return
	}
	lbType := strings.TrimSpace(r.URL.Query().Get("type"))
	if lbType == "" {
		lbType = lbRealm
	}
	if lbType != lbRealm && lbType != lbTower && lbType != lbStones {
		writeFail(w, http.StatusBadRequest, 4013, "type 仅支持 realm / tower / stones")
		return
	}
	limit := 50
	if raw := strings.TrimSpace(r.URL.Query().Get("limit")); raw != "" {
		if n, err := strconv.Atoi(raw); err == nil {
			limit = n
		}
	}
	if limit < 1 {
		limit = 1
	}
	if limit > 100 {
		limit = 100
	}

	uid := uidFrom(r.Context())
	a.touchLastSeen(uid, time.Now().Unix())
	all := a.leaderboardEntries(lbType)
	view := make([]leaderboardEntry, 0, limit)
	for i := 0; i < len(all) && i < limit; i++ {
		view = append(view, all[i])
	}

	writeOK(w, map[string]any{
		"type":       lbType,
		"updated_at": time.Now().Unix(),
		"entries":    view,
		"my_rank":    a.myLeaderboardRank(lbType, uid),
	})
}

// leaderboardEntries 带 TTL 缓存地取全量榜单；缓存命中直接返回，未命中重查并回填。
func (a *App) leaderboardEntries(lbType string) []leaderboardEntry {
	lbCache.mu.RLock()
	cached, ok := lbCache.entries[lbType]
	stamp := lbCache.stamp[lbType]
	lbCache.mu.RUnlock()
	if ok && time.Since(stamp) < leaderboardTTL {
		return cached
	}
	entries := a.queryLeaderboard(lbType, leaderboardCacheCap)
	lbCache.mu.Lock()
	lbCache.entries[lbType] = entries
	lbCache.stamp[lbType] = time.Now()
	lbCache.mu.Unlock()
	return entries
}

// queryLeaderboard 按榜单类型排序查询；INNER JOIN users 取道号，仅统计已有云存档的玩家。
func (a *App) queryLeaderboard(lbType string, limit int) []leaderboardEntry {
	order := "cs.realm_order DESC, cs.cultivation_xp DESC, cs.updated_at ASC"
	switch lbType {
	case lbTower:
		order = "cs.tower_floor DESC, cs.realm_order DESC, cs.updated_at ASC"
	case lbStones:
		order = stonesValueExpr + " DESC, cs.realm_order DESC, cs.updated_at ASC"
	}
	rows, err := a.db.Query(`
SELECT cs.user_id, u.username, cs.realm_name, cs.realm_order,
       cs.cultivation_xp, cs.tower_floor, cs.spirit_stones, cs.updated_at
FROM cloud_saves cs
INNER JOIN users u ON u.id = cs.user_id
ORDER BY `+order+`
LIMIT ?`, limit)
	if err != nil {
		return []leaderboardEntry{}
	}
	defer rows.Close()
	entries := make([]leaderboardEntry, 0, 64)
	rank := int64(0)
	for rows.Next() {
		var e leaderboardEntry
		if err := rows.Scan(&e.UID, &e.Username, &e.RealmName, &e.RealmOrder,
			&e.CultivationXP, &e.TowerFloor, &e.SpiritStones, &e.UpdatedAt); err != nil {
			continue
		}
		rank++
		e.Rank = rank
		entries = append(entries, e)
	}
	return entries
}

// myLeaderboardRank 查当前玩家数据与全服实时名次；尚未上传云存档时 rank 返回 0。
func (a *App) myLeaderboardRank(lbType string, uid int64) leaderboardEntry {
	var e leaderboardEntry
	e.UID = uid
	if uid <= 0 {
		return e
	}
	var realmName, stones, username string
	var realmOrder, towerFloor, updatedAt int64
	var cultXP float64
	err := a.db.QueryRow(`
SELECT cs.realm_name, cs.realm_order, cs.cultivation_xp, cs.tower_floor,
       cs.spirit_stones, cs.updated_at
FROM cloud_saves cs WHERE cs.user_id = ?`, uid).
		Scan(&realmName, &realmOrder, &cultXP, &towerFloor, &stones, &updatedAt)
	if err == sql.ErrNoRows {
		return e // rank 0：尚未上传云存档
	}
	if err != nil {
		return e
	}
	_ = a.db.QueryRow(`SELECT username FROM users WHERE id = ?`, uid).Scan(&username)
	e.Username = username
	e.RealmName = realmName
	e.RealmOrder = realmOrder
	e.CultivationXP = cultXP
	e.TowerFloor = towerFloor
	e.SpiritStones = stones
	e.UpdatedAt = updatedAt
	e.Rank = a.calcRank(lbType, e)
	return e
}

// calcRank 统计严格优于当前玩家的行数 +1，即其全服实时名次。
// 并列时按 updated_at ASC（先达成者靠前）判定。
func (a *App) calcRank(lbType string, me leaderboardEntry) int64 {
	var count int64
	var err error
	switch lbType {
	case lbTower:
		err = a.db.QueryRow(`
SELECT COUNT(*) FROM cloud_saves cs
WHERE cs.tower_floor > ?
   OR (cs.tower_floor = ? AND cs.realm_order > ?)
   OR (cs.tower_floor = ? AND cs.realm_order = ? AND cs.updated_at < ?)`,
			me.TowerFloor, me.TowerFloor, me.RealmOrder,
			me.TowerFloor, me.RealmOrder, me.UpdatedAt).Scan(&count)
	case lbStones:
		my := parseSpiritStones(me.SpiritStones)
		err = a.db.QueryRow(`
SELECT COUNT(*) FROM cloud_saves cs
WHERE `+stonesValueExpr+` > ?
   OR (`+stonesValueExpr+` = ? AND cs.realm_order > ?)
   OR (`+stonesValueExpr+` = ? AND cs.realm_order = ? AND cs.updated_at < ?)`,
			my, my, me.RealmOrder, my, me.RealmOrder, me.UpdatedAt).Scan(&count)
	default: // realm
		err = a.db.QueryRow(`
SELECT COUNT(*) FROM cloud_saves cs
WHERE cs.realm_order > ?
   OR (cs.realm_order = ? AND cs.cultivation_xp > ?)
   OR (cs.realm_order = ? AND cs.cultivation_xp = ? AND cs.updated_at < ?)`,
			me.RealmOrder, me.RealmOrder, me.CultivationXP,
			me.RealmOrder, me.CultivationXP, me.UpdatedAt).Scan(&count)
	}
	if err != nil {
		return 0
	}
	return count + 1
}

// parseSpiritStones 把「1.5万」「2亿」或纯数字折算为 float64，供名次比较用。
func parseSpiritStones(s string) float64 {
	t := strings.TrimSpace(s)
	if t == "" {
		return 0
	}
	mult := 1.0
	if strings.HasSuffix(t, "亿") {
		mult = 100000000
		t = strings.TrimSuffix(t, "亿")
	} else if strings.HasSuffix(t, "万") {
		mult = 10000
		t = strings.TrimSuffix(t, "万")
	}
	if v, err := strconv.ParseFloat(t, 64); err == nil {
		return v * mult
	}
	return 0
}
