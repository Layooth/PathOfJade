# 玉简问道 · 轻量云存档 / 热更新后端

Go + 纯 Go SQLite（`modernc.org/sqlite`）单文件服务，`CGO_ENABLED=0` 静态编译，
零 glibc 依赖，可直接运行在 **CentOS 7 及以上** 的 x86_64 服务器。

- 账号：内测期**关闭玩家自助注册与游客建号**，由掌教在 `/admin` 后台发放道号与密令；客户端仅保留道号登录。
- 云存档：`base_rev` 乐观锁上传 / 下载，单档上限 512KB（gzip）。
- 热更新：`manifest.json` 增量清单 + `.pck` 静态下载 + 管理员一键发版。
- 管理后台：`/admin` 单页（`//go:embed admin.html`），支持发号、重置密令、删除账号、云篆总览与网页发版。
- 依赖：Go 1.21+（`go.mod` 已锁定 `go 1.21` 与 Go 1.21 可编译的 `modernc.org/sqlite v1.36.1`）。

---

## 1. 目录结构

```
server/
├─ main.go                  HTTP 入口、环境变量、CORS / 日志 / Panic 恢复、优雅停机
├─ db.go                    SQLite 打开、PRAGMA、users / cloud_saves 建表
├─ auth.go                  登录、JWT 中间件（游客/自助绑定已关闭，统一 403）
├─ save.go                  存档摘要 / 上传（409 乐观锁）/ 下载
├─ patch.go                 版本清单、.pck 安全下载、管理员发版
├─ admin.go                 管理员发号 / 重置密令 / 删除 / 云篆总览
├─ admin.html               单文件管理后台（go:embed，无外部 CDN）
├─ build_linux.bat          Windows 双击交叉编译（默认 linux/amd64）
├─ deploy/jade-server.service  systemd 模板
├─ go.mod / go.sum
├─ data/                    运行期自动生成：jade.db、manifest.json（已 gitignore）
├─ patches/                 运行期自动生成：*.pck（已 gitignore）
└─ dist/                    编译产物（已 gitignore）
```

> 运行目录即工作目录：默认读写 `./data` 与 `./patches`。
> 用 systemd 部署时由 `WorkingDirectory=/opt/jade-server` 固定，或显式设置
> `JADE_DATA_DIR` / `JADE_PATCH_DIR`。

---

## 2. 构建

### Windows（推荐）

双击 `build_linux.bat`，产物：`server/dist/jade-server`（linux/amd64 静态 ELF）。
也可在命令行指定架构：

```bat
build_linux.bat arm64
```

### Linux / macOS

```bash
cd server
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
  go build -trimpath -ldflags "-s -w" -o dist/jade-server .
```

> 国内网络若拉取依赖失败，先设置镜像：
> `go env -w GOPROXY=https://goproxy.cn,direct`

---

## 3. CentOS 7 部署

```bash
# 1) 建运行用户与目录
sudo useradd -r -s /sbin/nologin jade
sudo mkdir -p /opt/jade-server/{data,patches}
sudo chown -R jade:jade /opt/jade-server

# 2) 上传二进制与 systemd 模板
scp dist/jade-server root@your-server:/opt/jade-server/jade-server
scp deploy/jade-server.service root@your-server:/etc/systemd/system/jade-server.service
ssh root@your-server 'chmod +x /opt/jade-server/jade-server'

# 3) 写入生产密钥（不要提交进 Git）
sudo tee /etc/jade-server.env >/dev/null <<'EOF'
JADE_JWT_SECRET=把这里换成 openssl rand -hex 32 的输出
JADE_ADMIN_KEY=把这里换成你自己的发版密钥
EOF
sudo chmod 600 /etc/jade-server.env

# 4) 启动
sudo systemctl daemon-reload
sudo systemctl enable --now jade-server
sudo systemctl status jade-server --no-pager
```

### 防火墙

```bash
# firewalld（CentOS 7 默认）
sudo firewall-cmd --permanent --add-port=28473/tcp
sudo firewall-cmd --reload

# 若要挂 80/443，建议前置 Nginx 反向代理并只对内网开放 28473
```

### 环境变量

| 变量 | 默认值 | 说明 |
|---|---|---|
| `PORT` | 空 | **最高优先级**：纯数字按端口处理（`28473` → `:28473`），也接受 `:28473`、`127.0.0.1:28473` 原样写法 |
| `JADE_ADDR` | `:28473` | 次优先级监听地址；`PORT` 为空时才生效 |
| `JADE_DATA_DIR` | `data` | SQLite 与 `manifest.json` 所在目录 |
| `JADE_PATCH_DIR` | `patches` | `.pck` 补丁目录 |
| `JADE_JWT_SECRET` | 开发默认值 | **生产必须替换**，HS256 签名密钥 |
| `JADE_ADMIN_KEY` | 空 | 为空时所有 `/api/admin/*` 管理接口返回 503；密钥不符 401 |

---

## 4. API 契约

统一响应（`/api/health` 除外）：

```json
{ "code": 0, "data": { } }
```

失败：`{"code": 4xxx, "message": "..."}`，并带对应 HTTP 状态码。

| 方法 | 路径 | 鉴权 | 说明 |
|---|---|---|---|
| GET | `/api/health` | 否 | `{"status":"ok"}` |
| POST | `/api/auth/guest` | 否 | **已关闭**：403「内测期间暂未开放自行立籍…」 |
| POST | `/api/auth/bind` | 否 | **已关闭**：与 guest 相同 403 |
| POST | `/api/auth/login` | 否 | 道号 + 口令 → 新 JWT（仅管理员发放账号） |
| GET | `/api/save/meta` | Bearer | 云端摘要（`exists/save_rev/realm_name/spirit_stones/play_seconds/updated_at`） |
| GET | `/api/save/download` | Bearer | `save_rev + payload_gzip_b64 + updated_at` |
| POST | `/api/save/upload` | Bearer | `base_rev/force/payload_gzip_b64/...`；冲突返回 **409** + 云端摘要 |
| GET | `/api/version?patch_rev=N` | 否 | 仅返回 `rev > N` 的增量补丁 |
| GET | `/patches/{file}.pck` | 否 | 安全下载（拒绝 `..` 与非 `.pck`） |
| GET | `/admin` | 否 | 内嵌管理后台页面 |
| GET | `/api/admin/users` | `X-Admin-Key` | 仙籍 + 云篆总览 |
| POST | `/api/admin/users` | `X-Admin-Key` | `{"username","password"}` 发号（2~16 字 / ≥6 位） |
| POST | `/api/admin/users/reset_password` | `X-Admin-Key` | `{"uid","new_password"}` |
| DELETE | `/api/admin/users/{uid}` 或 POST `/api/admin/users/delete` | `X-Admin-Key` | 删除账号及云篆 |
| POST | `/api/admin/publish_patch` | `X-Admin-Key` | multipart：`file`(.pck) + `patch_rev` + `notes` |

### 网页管理后台

浏览器打开 `http://服务器IP:28473/admin`，输入 `JADE_ADMIN_KEY` 验证后即可：

- 发放仙籍（道号 + 初始密令，一键复制「道号 / 密令」给玩家）；
- 查看全部账号与云篆版本、境界、灵石、累计修行时长；
- 重置指定账号密令、删除账号及其云篆；
- 选择 `.pck`、填写 `patch_rev` 与 `notes`，直接发布热更（等效于下方 curl 发版）。

密钥仅保存在浏览器 `sessionStorage`，不会写进页面或服务端日志。

### 冒烟示例

```bash
# 健康
curl -s http://127.0.0.1:28473/api/health

# 掌教发号（也可直接打开 http://服务器:28473/admin）
curl -s -X POST http://127.0.0.1:28473/api/admin/users \
  -H "X-Admin-Key: $JADE_ADMIN_KEY" -H 'Content-Type: application/json' \
  -d '{"username":"青云子","password":"secret123"}'

# 道号登录
TOKEN=$(curl -s -X POST http://127.0.0.1:28473/api/auth/login \
  -H 'Content-Type: application/json' -d '{"username":"青云子","password":"secret123"}' \
  | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')

# 上传（rev 0 → 1）
curl -s -X POST http://127.0.0.1:28473/api/save/upload \
  -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d "{\"base_rev\":0,\"realm_name\":\"真仙圆满\",\"spirit_stones\":\"7774万\",\"play_seconds\":36000,\"payload_gzip_b64\":\"$(printf 'hello' | gzip -c | base64 -w0)\"}"

# 以旧 base_rev 再传 → HTTP 409
curl -i -s -X POST http://127.0.0.1:28473/api/save/upload \
  -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d "{\"base_rev\":0,\"payload_gzip_b64\":\"$(printf 'hello' | gzip -c | base64 -w0)\"}"

# 版本清单
curl -s 'http://127.0.0.1:28473/api/version?patch_rev=0'
```

---

## 5. 热更发版流程

1. Godot 侧导出增量包（只含变更资源）：
   ```bash
   godot --headless --export-pack "Android" build/patch_1.pck
   ```
2. 上传并发版（`patch_rev` 必须递增；也可用 `/admin` 网页直接上传）：
   ```bash
   curl -s -X POST http://127.0.0.1:28473/api/admin/publish_patch \
     -H "X-Admin-Key: $JADE_ADMIN_KEY" \
     -F "file=@build/patch_1.pck" \
     -F "patch_rev=1" \
     -F "notes=新增镇魔塔 120 层演出"
   ```
3. 服务端自动计算 SHA256/大小，写入 `data/manifest.json`（原子 rename），文件落在
   `patches/patch_1.pck`；客户端请求 `/api/version?patch_rev=0` 即拿到增量列表。

---

## 6. 备份与运维

```bash
# SQLite 在线备份（WAL 模式下安全）
sqlite3 /opt/jade-server/data/jade.db ".backup '/opt/jade-server/data/backup-$(date +%F).db'"

# 清单 / 补丁目录一并打包
tar czf jade-backup-$(date +%F).tgz -C /opt/jade-server data patches

# 日志
journalctl -u jade-server -f
```

- **不要**直接复制运行中的 `jade.db`（WAL 未合并会丢最近事务），请用 `.backup` 或先停服。
- `data/`、`patches/*.pck`、`dist/` 已加入根目录 `.gitignore`。
- 建议前置 Nginx 启用 HTTPS；本服务只监听内网/本机端口时最稳妥。
- JWT 有效期 30 天；更换 `JADE_JWT_SECRET` 会使全部旧 Token 失效（客户端重新游客登录即可）。
