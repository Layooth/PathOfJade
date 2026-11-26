# AGENTS.md — 玉简问道 · PathOfJade 工程规范

> 本文件是工程上下文入口。新会话先读本文件，再按实际代码核对细节。
> 约定：代码与本文冲突时，以当前代码为准，并在同一改动内同步更新本文。

---

## 0. 置顶红线

1. **禁止手动创建、修改或删除 `.gd.uid` / `.import` 文件。**
   Godot 自动生成并维护 UID 与导入元数据；手工改动会导致场景引用或资源导入失败。

2. **禁止破坏旧存档兼容性。**
   主存档为 `user://save_data.json`（紧凑 JSON），写 `.tmp` 后原子替换。
   所有新增字段必须走 `GameState.from_dict()` 迁移或缺省兜底，`to_dict()` 结构不得无迁移变更。
   `core/systems/` 状态统一挂在 `GameState.flags` 子字典下，缺失时按默认状态恢复。

3. **移动端 60 FPS。**
   禁止 `GPUParticles2D`、禁止重型全屏后处理 Shader。动效统一使用 `_draw()` / `Tween` / 固定对象池，并在隐藏、停战、切页时 kill 旧 Tween 或回收节点。

4. **玩家文本规范。**
   面向玩家文本严禁出现 `Lv`、现代网游黑话和策划开发术语；等级统一称「重」或「阶」。
   所有文本必须走 `ThemeBuilder.apply_font_size()`，最小字号 `FONT_CAPTION 13`；所有按钮高度 ≥44px。

5. **响应式 3×3 全矩阵强制审计。**
   - 3 个分辨率断点：**COMPACT 450×800**、**MEDIUM 1024×720**、**WIDE 1440×900**。
   - 3 个字号档：**偏小 0.95**、**标准 1.05**、**偏大 1.20**。
   - 任一 UI 改动都必须覆盖 **3 分辨率 × 3 字号档 = 9 组组合**；不得用两个竖屏分辨率冒充三断点，也不得只测单一字号。
   - 自检脚本必须在**单个进程内**，或**每个分辨率仅启动 1 次、最多 3 次 Godot 进程**完成：在同一进程中循环调用 `ThemeBuilder.set_font_scale(scale)` 与 `ThemeBuilder.apply_font_scale_to_tree(root)`，等待帧刷新后连续审计 0.95 / 1.05 / 1.20 三档。**严禁为 9 组组合冷启动 9 次 Godot 进程。**
   - 重点检查右边界、裁切、重叠、底部导航遮挡、两列/三列切换、常驻侧栏与卡片均衡。高数值/满图鉴专项仍必须额外覆盖 1.20 档。

6. **问号规范。**
   页面问号只能用 `ThemeBuilder.create_help_button()`；同一可见页面最多一个 `?`，固定在标题行最右。长说明进 `BottomSheet` 或 `CodexPanel` 典籍页。

---

## 1. 项目与配置

| 项目 | 当前实际值 |
|---|---|
| 名称 | `project.godot`：`config/name="PathOfJade"`；描述为《玉简问道》；Android 包名为 `com.pathofjade.game`，应用名为「玉简问道」 |
| 规范称呼 | 玉简问道 · PathOfJade |
| 引擎 | Godot 4.7，`GL Compatibility` |
| 客户端版本 | `project.godot`：`config/version="0.0.4beta"` |
| Android 版本 | `export_presets.cfg`：`version/name="V 1.0.0"`，`version/code=1` |
| 版本一致性 | 两个版本来源当前不一致；发版时必须同步 `config/version` 与 `version/name` 并递增 `version/code` |
| 主场景 | `res://ui/BootScene.tscn` → `res://ui/LoginScene.tscn` → `res://ui/MainShell.tscn` |
| 用户目录 | `use_custom_user_dir=true`，`custom_user_dir_name="Jade Codex"`，保证旧档路径不变 |
| 视口 | 450×800，`canvas_items` + `expand`；运行时按窗口比例改写 `content_scale_size` |
| 帧率 | `run/max_fps=60`，设置页可切省电 / 流畅 / 高刷 |
| Android 导出 | 仅 Android preset，输出 `E:/桌面/PathOfJade.apk`，`immersive_mode=true`，arm64 |
| 版本控制 | 当前目录不是 git 仓库，改动前自行备份，不能依赖 `git diff` |

---

## 2. 目录结构

```text
project.godot              # 12 个 AutoLoad 注册处
export_presets.cfg         # Android 导出配置
AGENTS.md                  # 本文件
assets/                    # 字体、音效、背景、图标、战斗演出 SVG、Android 启动图
core/
  autoloads/               # 12 个常驻 AutoLoad
  formulas/GameFormulas.gd # 纯静态公式库
  resources/               # 数据类、IconSvgPack 等资源定义
  systems/                 # 非 AutoLoad 系统：NatalArtifactSystem / FishingTeaSystem / FiveElementsSystem / SpiritRootSystem
ui/
  MainShell.gd / BootScene / LoginScene / ThemeBuilder / InkVfxLayer / UiMotion / SceneTransition 相关组件
  panels/                  # 全部功能面板
  components/              # 通用 UI 组件
server/                    # Go 云存档、天道榜、仙盟传书与 .pck 热更新后端
docs/                      # 文档与测试存档
```

数据规模、图标模板数、物品/动作/敌人条目数一律以 `DataRegistry.gd` 与 `IconSvgPack.gd` 的实际定义为准，不在本文档维护易变精确数字。

---

## 3. AutoLoad（12 个，按 `project.godot` 注册顺序）

| # | 名称 | 文件 | 核心职责 |
|---|---|---|---|
| 1 | `EventBus` | `core/autoloads/EventBus.gd` | 全局信号与布局缓存，含 `LayoutMode{COMPACT,MEDIUM,WIDE}` |
| 2 | `DataRegistry` | `core/autoloads/DataRegistry.gd` | 配置表 → Resource / 字典索引，图鉴、来源索引、塔怪生成 |
| 3 | `IconLibrary` | `core/autoloads/IconLibrary.gd` | `IconSvgPack` 双色 SVG 栅格化、缓存与旧 key 兼容 |
| 4 | `GameState` | `core/autoloads/GameState.gd` | 唯一运行时状态源、存档序列化、槽位与玩家属性汇总 |
| 5 | `BountyManager` | `core/autoloads/BountyManager.gd` | 仙盟悬赏生成、交付、每日限额与近期记忆 |
| 6 | `FarmManager` | `core/autoloads/FarmManager.gd` | 灵田、灵肥、催熟、收获、仙壤淬灵 |
| 7 | `ActionRunner` | `core/autoloads/ActionRunner.gd` | 三槽百艺计时、结算、耗时与双倍计算 |
| 8 | `CombatEngine` | `core/autoloads/CombatEngine.gd` | 秘境战斗、渡劫状态机、镇魔塔 |
| 9 | `AudioManager` | `core/autoloads/AudioManager.gd` | 音效、双 BGM、音量总线、震动反馈 |
| 10 | `SaveManager` | `core/autoloads/SaveManager.gd` | 本地存档、离线结算、导入导出、生命周期 |
| 11 | `CloudSaveManager` | `core/autoloads/CloudSaveManager.gd` | 仙籍、云存档、天道榜、仙盟传书、热更版本查询 |
| 12 | `SceneTransition` | `core/autoloads/SceneTransition.gd` | 全局水墨场景过渡 |

依赖方向：`UI → AutoLoad → EventBus`。禁止 AutoLoad 引用 UI 节点；Autoload 之间只允许向下调用。

---

## 4. 非 AutoLoad 系统

`core/systems/` 下系统不注册为 AutoLoad，统一由业务层调用，状态挂在 `GameState.flags`：

| 系统 | flags 子状态 | 说明 |
|---|---|---|
| `NatalArtifactSystem` | `flags.natal_artifact` | 本命法宝胚、重数、器纹 |
| `FishingTeaSystem` | `flags.fishing_tea` | 灵潭清茗、茶汤增益 |
| `FiveElementsSystem` | `flags.five_elements` | 五行法则进度与加成 |
| `SpiritRootSystem` | `flags.spirit_root` | 灵根品阶与主灵根五行亲和 |

旧档缺失这些字段时必须安全返回默认状态；禁止改存档顶层结构。

---

## 5. UI 架构

### 5.1 MainShell

- 纯代码构建外壳，面板通过 `_show_panel(key)` 懒创建并缓存，切页只改 `visible`。
- 左侧导航在 COMPACT 进抽屉，MEDIUM / WIDE 进常驻侧栏；WIDE 额外显示右侧 `StatusSidebar`。
- 常驻侧栏宽度：MEDIUM 240px，WIDE 256px；COMPACT 抽屉不变。
- `_panel_host.clip_contents = true` 是 450 宽最后兜底，但面板自身必须做自适应。
- 滚动容器与按钮必须兼容 `ThemeBuilder.prepare_touch()`：Button 全部 `PASS`，14px 滑动守卫防误触。
- 所有新面板必须在 `_build()` 末尾调用 `prepare_touch(root)`；动态重建后补调。

### 5.2 面板清单

`ui/panels/` 实际面板：

`SkillActionPanel`、`FarmPanel`、`CombatPanel`、`CharacterPanel`、`InventoryPanel`、`ShopPanel`、`BountyPanel`、`TechniquePanel`、`CodexPanel`、`TowerPanel`、`TribulationPanel`、`LeaderboardPanel`、`MailPanel`、`NatalArtifactPanel`、`FishingTeaPanel`、`FiveElementsPanel`、`SpiritRootPanel`、`SettingsPanel`。

页面 key 包含 7 个百艺页（`herbalism/woodcutting/mining/alchemy/forging/talisman/cultivation`）以及上述功能页对应 key。

### 5.3 功能解锁门槛

| 功能 | 门槛 |
|---|---|
| 灵田批量收获 / 播种 | 已开垦 ≥2 块田 |
| 仙盟悬赏 | `realm_order >= 2`，炼气三层 |
| 藏经阁 | `realm_order >= 5`，炼气六层 |
| 灵根洗髓 | `realm_order >= 6`，炼气七层 |
| 镇魔塔 | `realm_order >= 9`，筑基初期 |
| 仙壤淬灵 | `realm_order >= 9`，筑基初期 |
| 装备祭炼 | `realm_order >= 10`，筑基中期 |
| 第三槽「身外化身」 | `realm_order >= 12`，金丹初期 |
| 本命法宝 | `realm_order >= 15`，元婴初期 |
| 灵潭清茗 | `realm_order >= 18`，化神初期 |
| 五行法则 | `realm_order >= 24`，合体初期 |

已达标后必须清掉旧锁定文案与黄点；旧档已有等级或数据不清空，只禁止继续升级。

### 5.4 通用组件

`ui/components/` 包含 `ActionCard`、`BottomSheet`、`CombatStage`、`TribulationStage`、`PoolMilestoneBar`、`StatusSidebar`、`IconFrame`、`OfflineReportModal`、`AmbientAuraLayer`、`TooltipHelper` 等。

新增 UI 时遵守：

- `BottomSheet.show_detail()` 用三段式卡片：身份头、核心数值卡、说明/操作区。
- 并排按钮统一 `SIZE_EXPAND_FILL` + `clip_text` + 紧凑内边距，禁止硬写导致 450 宽溢出。
- 同一面板内最多一个可见 `?`。
- 颜色走 `ThemeBuilder` 常量，BBCode 十六进制走 `ThemeBuilder.hex()`。

---

## 6. 数据与公式

- 数据表集中在 `DataRegistry.gd`；公式集中在 `GameFormulas.gd`，纯静态，不引用 AutoLoad。
- 数值调整只改公式常量或数据表，禁止散落到面板。
- 大数显示统一走 `GameFormulas.format_num()`。
- 存档新增字段必须走 `GameState.to_dict/from_dict` 与迁移分支。
- 灵田施肥：近阶灵草门槛、每轮最多 3 次、固定缩时与丰产，详见 `FarmManager`。
- 仙壤淬灵：消耗随重数提高灵种阶位门槛，保留 20 枚底仓，详见 `FarmManager`。
- 悬赏：三槽配比、每日 10 单、近期记忆、解锁过滤与急令，详见 `BountyManager`。
- 非 AutoLoad 系统增益由 `GameState` 汇总时调用对应 `get_bonus()`，仍受已有硬上限约束。

---

## 7. 存档与离线

- 主档：`user://save_data.json`；备份：`user://save_data.backup.json`；临时档：`save_data.json.tmp`。
- 顶层结构：`version / exp_curve_version / saved_at / saved_at_text / state`。
- `GameState.from_dict()` 负责旧曲线迁移、字段补齐、槽位数量规范化、图鉴与塔进度修复。
- 关键迁移链：v1→v2→v3→v4；技能/火候曲线与悟道池容量必须按阶段换算。
- 离线结算依赖恢复后的 `active_slots`；加载顺序：`from_dict → 曲线迁移 → FarmManager → CombatEngine → 离线结算 → ActionRunner 清进度 → save_game(false) → game_loaded`。
- 零收益不弹「闭关收益玉简」，只按离线时长给轻提示或静默。
- 云存档凭证独立存 `user://cloud_auth.json`，不写入主存档；明文密令永不落盘。

---

## 8. 服务端与热更新现状

服务端已实装，目录为 `server/`，与 Godot 资源管线严格隔离。

- Go 1.21+，纯 Go SQLite，静态编译。
- 云存档：JWT 鉴权、`base_rev` 乐观锁、409 冲突、512KB gzip 上限。
- 天道榜：`GET /api/leaderboard`，支持境界 / 塔层 / 灵石榜。
- 仙盟传书：`/api/ping` 未读推送、`/api/mail/list`、`/api/mail/claim`，管理端可发信。
- 管理后台：`/admin`，掌教发号、重置密令、删除账号、云篆总览、传书管理与 .pck 发版。
- 生产接入：`https://allplayer.cn:28474`，由 Nginx HTTPS 反代到本地 Go 服务。
- 热更新已实装：BootScene 拉取版本清单，HTTP Range 断点续传下载全量 `.pck`，SHA256 校验后 `load_resource_pack(..., true)`。
- 热更后静态数据刷新：`DataRegistry` 用 `CACHE_MODE_REPLACE` 重读脚本并 `rebuild_registries()`；`IconLibrary.rebuild_cache()` 重读 `IconSvgPack` 常量。失败只跳过，不阻塞登录。

### 8.1 热更新安全边界

可随 `.pck` 热更新推送：

- `ui/`
- `core/formulas/GameFormulas.gd`
- `core/systems/`
- `core/autoloads/DataRegistry.gd`
- `core/resources/IconSvgPack.gd`
- `assets/`

必须重新导出 APK：

- `ui/BootScene.gd`
- 其余常驻 AutoLoad（如 `GameState.gd`、`SaveManager.gd`、`CloudSaveManager.gd`、`SceneTransition.gd` 等）

PCK 新增接口必须走 `has_signal()` / `has_method()` / `get()` 安全降级；基包缺接口时只跳过可选功能，不得中断 `_ready()` 或面板构建。

---

## 9. 验证标准

### 9.1 基本检查

每次改动至少执行：

1. Godot 导入，确认无 `SCRIPT ERROR` / `Parse Error`。
2. `read_lints` 无新增错误。
3. 玩家文案检索：无 `Lv`、开发黑话、全角括号导致的截断。
4. 确认未手动改动 `.gd.uid` / `.import`。

### 9.2 3×3 全矩阵 UI 审计

- 固定矩阵：
  - COMPACT：450×800 × 0.95 / 1.05 / 1.20
  - MEDIUM：1024×720 × 0.95 / 1.05 / 1.20
  - WIDE：1440×900 × 0.95 / 1.05 / 1.20
- 执行约束：优先单进程完成 9 组；若必须按分辨率切进程，则每个分辨率仅启动 1 次、总计最多 3 次。循环调用 `ThemeBuilder.set_font_scale(scale)` 与 `ThemeBuilder.apply_font_scale_to_tree(root)`，等待帧刷新后再测量；严禁为 9 组组合冷启动 9 次 Godot 进程。
- 检查所有相关节点的 `global_rect`、左右边界、水平居中、按钮高度 ≥44、字号 ≥`FONT_CAPTION`、是否裁切/重叠/折行孤字。
- 涉及在线/离线、锁定/解锁、空/加载/错误/成功状态逐态覆盖。
- 涉及层级/颜色/留白的改动保留至少一张最终截图人工确认。

### 9.3 测试纪律

- 所有 Godot / Go / Python / 服务进程必须有外层 `WaitForExit` 硬超时。
- 客户端测试在 `%TEMP%` 项目副本运行，不往项目内塞临时脚本。
- 测试脚本自身报错时先修探针，不得放宽或删除断言。
- 服务端改动至少跑 `go build ./...` 与 `go vet ./...`。
- 报告必须写实际退出码与失败数；未验证不得声称通过。
- 审计完成后彻底清理临时脚本、沙箱与临时用户目录。
