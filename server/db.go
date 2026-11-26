package main

import (
	"database/sql"
	"fmt"
	"strings"

	_ "modernc.org/sqlite" // 纯 Go SQLite 驱动：CGO_ENABLED=0 亦可静态编译
)

// sqlDB 别名，便于 App 结构体不直接依赖 database/sql 的导入路径书写。
type sqlDB = sql.DB

// openDB 打开（必要时创建）SQLite，并完成 WAL / 同步级别 / 忙等待与建表。
// 轻量后端采用单连接串行写入，配合 busy_timeout 彻底规避 SQLITE_BUSY。
func openDB(path string) (*sql.DB, error) {
	db, err := sql.Open("sqlite", path)
	if err != nil {
		return nil, err
	}
	db.SetMaxOpenConns(1)
	db.SetMaxIdleConns(1)

	for _, pragma := range []string{
		"PRAGMA journal_mode=WAL;",
		"PRAGMA synchronous=NORMAL;",
		"PRAGMA busy_timeout=5000;",
		"PRAGMA foreign_keys=ON;",
	} {
		if _, err := db.Exec(pragma); err != nil {
			db.Close()
			return nil, fmt.Errorf("%s: %w", pragma, err)
		}
	}

	if _, err := db.Exec(`
CREATE TABLE IF NOT EXISTS users (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    device_id     TEXT UNIQUE,
    username      TEXT UNIQUE,
    password_hash TEXT NOT NULL DEFAULT '',
    is_guest      INTEGER NOT NULL DEFAULT 1,
    created_at    INTEGER NOT NULL,
    last_seen_at  INTEGER NOT NULL DEFAULT 0
);
CREATE TABLE IF NOT EXISTS cloud_saves (
    user_id       INTEGER PRIMARY KEY,
    save_rev      INTEGER NOT NULL DEFAULT 0,
    realm_name    TEXT NOT NULL DEFAULT '',
    spirit_stones TEXT NOT NULL DEFAULT '',
    play_seconds  INTEGER NOT NULL DEFAULT 0,
    payload       BLOB,
    updated_at    INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS mails (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    target_uid    INTEGER NOT NULL DEFAULT 0,
    title         TEXT NOT NULL,
    body          TEXT NOT NULL DEFAULT '',
    spirit_stones INTEGER NOT NULL DEFAULT 0,
    items_json    TEXT NOT NULL DEFAULT '[]',
    created_at    INTEGER NOT NULL,
    expires_at    INTEGER NOT NULL DEFAULT 0
);
CREATE TABLE IF NOT EXISTS mail_claims (
    mail_id   INTEGER NOT NULL,
    uid       INTEGER NOT NULL,
    claimed_at INTEGER NOT NULL,
    PRIMARY KEY (mail_id, uid)
);
CREATE INDEX IF NOT EXISTS idx_users_device ON users(device_id);
CREATE INDEX IF NOT EXISTS idx_mails_target ON mails(target_uid, created_at DESC);
`); err != nil {
		db.Close()
		return nil, fmt.Errorf("建表: %w", err)
	}

	// 旧库无损迁移：补 users.last_seen_at 与 cloud_saves 排行榜列（已存在则跳过）。
	if err := migrateDB(db); err != nil {
		db.Close()
		return nil, fmt.Errorf("迁移旧库: %w", err)
	}
	return db, nil
}

// migrateDB 演进旧库：按 PRAGMA table_info 幂等补列，再建高频索引。
// 新增列均带 NOT NULL DEFAULT，旧数据自动补 0，不影响既有云档与登录。
func migrateDB(db *sql.DB) error {
	if err := ensureColumn(db, "users", "last_seen_at",
		"ALTER TABLE users ADD COLUMN last_seen_at INTEGER NOT NULL DEFAULT 0"); err != nil {
		return err
	}
	for _, col := range []struct{ name, ddl string }{
		{"realm_order", "ALTER TABLE cloud_saves ADD COLUMN realm_order INTEGER NOT NULL DEFAULT 0"},
		{"cultivation_xp", "ALTER TABLE cloud_saves ADD COLUMN cultivation_xp REAL NOT NULL DEFAULT 0"},
		{"tower_floor", "ALTER TABLE cloud_saves ADD COLUMN tower_floor INTEGER NOT NULL DEFAULT 0"},
	} {
		if err := ensureColumn(db, "cloud_saves", col.name, col.ddl); err != nil {
			return err
		}
	}
	for _, idx := range []string{
		"CREATE INDEX IF NOT EXISTS idx_saves_rank_realm ON cloud_saves(realm_order DESC, cultivation_xp DESC, updated_at ASC)",
		"CREATE INDEX IF NOT EXISTS idx_saves_rank_tower ON cloud_saves(tower_floor DESC, realm_order DESC, updated_at ASC)",
		"CREATE INDEX IF NOT EXISTS idx_saves_rank_stones ON cloud_saves(spirit_stones DESC, realm_order DESC, updated_at ASC)",
	} {
		if _, err := db.Exec(idx); err != nil {
			return err
		}
	}
	return nil
}

// ensureColumn 查询 PRAGMA table_info，缺失指定列时才执行 ALTER TABLE ADD COLUMN。
func ensureColumn(db *sql.DB, table, column, ddl string) error {
	rows, err := db.Query("PRAGMA table_info(" + table + ")")
	if err != nil {
		return err
	}
	defer rows.Close()
	for rows.Next() {
		var cid, notnull, pk int
		var name, ctype string
		var dflt any
		if err := rows.Scan(&cid, &name, &ctype, &notnull, &dflt, &pk); err != nil {
			return err
		}
		if strings.EqualFold(name, column) {
			return nil // 列已存在，跳过
		}
	}
	if err := rows.Err(); err != nil {
		return err
	}
	_, err = db.Exec(ddl)
	return err
}
