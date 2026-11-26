# GitHub 上传准备排查报告

仓库目标：`https://github.com/Layooth/PathOfJade.git`

状态：上传前清理已完成，等待创建初始提交并推送。

## 1. 敏感信息与大文件只读扫描

### 1.1 已修复的高风险项

| 文件 | 原行号 | 问题 | 处理结果 |
|---|---:|---|---|
| `server/main.go` | 65 | 硬编码 JWT 开发默认密钥字面量 | 已删除默认值，改为仅从 `JADE_JWT_SECRET` 读取；为空时打印中文提示并返回错误，以非零状态退出 |

### 1.2 其他命中但非硬编码密钥

- `server/auth.go`：JWT 校验逻辑、字段名，无明文密钥
- `server/admin.go`：字段名和字段名引用，无明文管理员密令
- `server/db.go`：`password_hash` SQL 字段，无明文密码
- `core/autoloads/CloudSaveManager.gd`、`ui/LoginScene.gd`：登录密码输入框变量名/UI 文案，无服务端密码
- `JADE_ADMIN_KEY` 仍从环境变量读取，未配置时管理接口禁用

### 1.3 `export_presets.cfg`

未发现 Android `keystore` 路径、`storePassword`、`keyPassword` 或 SSL 私钥配置。

`.gitignore` 已忽略 `export_presets.cfg`。

### 1.4 本地测试产物 / 二进制

已通过 `.gitignore` 排除，未进入暂存：

- `docs/test_save_all_unlocked.json`
- `server/dist/jade-server`
- `server/dist/jade-server.exe`
- `server/jade-codex-server.exe`

未发现 `.db`、`.sqlite`、`.key`、`.pem`、`.keystore`、`.jks`、`.apk`、`.aab`、`.pck`、`.zip`、`.log`、`.env`。

## 2. `.gitignore` 完善情况

已包含：

- Godot：`.godot/`、`*.translation`、`export_presets.cfg`、`*.tmp`
- 服务端：`*.db*`、`*.sqlite*`、`server/data/`、`server/dist/`、`server/*.exe`、`server/jade-server`、`patches/*.pck`
- 密钥：`.env`、`.env.*`、`*.key`、`*.pem`、`*.log`
- 打包：`build/`、`dist/`、`exports/`、`*.apk`、`*.aab`、`*.pck`、`*.exe`、`*.zip`
- 系统/编辑器：`.DS_Store`、`Thumbs.db`、`.vscode/`
- 本地测试：`docs/test_save_*.json`、`*_suite.out`、`*_suite.err`、`*_probe.gd`、`*_probe*.gd.uid`

保留 `.gd.uid` 与 `.import`，仅排除孤立探针 UID。

## 3. Go 编译校验

在 `server/` 目录执行：

```text
go build ./...    EXIT=0
go test ./...     EXIT=0（no test files）
```

未生成或暂存编译产物。

## 4. 孤立探针清理

已执行：

```text
git rm --cached -- _probe_icon.gd.uid
```

状态：

- `_probe_icon.gd.uid` 已从暂存区移除
- 文件仍保留在工作区，但被 `.gitignore` 的新规则 `*_probe*.gd.uid` 排除
- 未手动删除 `.gd.uid` 文件

## 5. Git 初始化与暂存状态

已完成：

- `git init`
- 默认分支：`main`
- `origin`：`https://github.com/Layooth/PathOfJade.git`
- 已执行 `git add -A`
- 已执行 `git status --short`

暂存结果：

| 项目 | 数值 |
|---|---:|
| 暂存文件 | 242 |
| 总大小 | 63.62 MB |
| 状态 | 全部为 `A`（新增暂存） |

分类：

| 分类 | 文件数 |
|---|---:|
| `assets` | 88 |
| `ui` | 77 |
| `core` | 48 |
| `server` | 14 |
| 根目录 | 8 |

主要扩展名：

| 类型 | 数量 |
|---|---:|
| `.gd.uid` | 62 |
| `.gd` | 61 |
| `.import` | 46 |
| `.ogg` | 20 |
| `.png` | 20 |
| `.go` | 8 |

## 6. 暂存安全检查

```text
FORBIDDEN_STAGED=none
PROBE_STAGED=0
GD_UID=62
IMPORT=46
EXPORT_PRESETS=0
```

确认未暂存：

- `.godot/`
- 数据库
- `.key / .pem`
- `.env / *.log`
- `.apk / .aab / .pck / .exe / .zip`
- `export_presets.cfg`
- 测试存档
- 服务端编译产物
- `_probe_icon.gd.uid`

## 7. 暂存大文件

| 文件 | 大小 |
|---|---:|
| `assets/fonts/pangmen_cushu.ttf` | 10.58 MB |
| `assets/images/splash_logo.png` | 7.77 MB |
| `logo.png` | 7.77 MB |
| `assets/fonts/ma_shan_zheng.ttf` | 5.58 MB |
| `assets/images/bg/bg_tribulation.png` | 5.07 MB |

上述均为项目运行所需资源文件。
