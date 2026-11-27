extends Node
## 全局信号总线：彻底解耦逻辑层（Autoload）与表现层（UI）。
## 所有信号只在此声明，禁止 UI 反向持有逻辑节点。

# ---- 背包 / 物品 ----
signal inventory_changed
signal item_gained(item_id: String, amount: int)
signal equipment_changed
## 气血、灵石、统计等顶栏数据的通用刷新信号
signal stats_changed

# ---- 技能 / 火候 / 悟道池 ----
signal skill_xp_changed(skill_id: String, xp: float, level: int)
signal mastery_changed(action_id: String, xp: float, level: int)
signal mastery_pool_changed(skill_id: String, current: float, capacity: float)

# ---- 挂机动作 ----
signal action_started(slot: int, action_id: String)
signal action_stopped(slot: int, action_id: String)
signal action_completed(slot: int, action_id: String, gained: Dictionary)
signal action_progress(slot: int, progress: float)
signal floating_text(slot: int, text: String, color: Color)

# ---- 境界 ----
signal cultivation_changed(current: float, required: float, is_full: bool)
signal realm_changed(realm_id: String, realm_name: String)
signal dual_cultivation_unlocked

# ---- 响应式布局 ----
enum LayoutMode { COMPACT, MEDIUM, WIDE }
signal layout_changed(mode: int, viewport_size: Vector2, workspace_width: float)
## 全局字号档位切换（0.90 / 1.00 / 1.15）
signal font_scale_changed(scale: float)
## 最近一次布局状态（面板 _ready 时可直接拉取，避免首帧空档）
var current_layout: int = LayoutMode.COMPACT
var current_viewport: Vector2 = Vector2.ZERO
var workspace_width: float = 540.0
## 当前前台页面 key（由 MainShell 切页时写入；音频等 AutoLoad 只读，不反向依赖 UI）
var current_page: String = ""

# ---- 修行纪要（右侧态势栏） ----
signal activity_log_added(entry: Dictionary)

# ---- 战斗 ----
signal combat_started(enemy_id: String)
signal combat_stopped(reason: String)
signal combat_updated(payload: Dictionary)
signal combat_log(line: String)

# ---- 战斗细节演出（CombatStage 专用） ----
signal combat_player_attack(damage: int, doubled: bool)
signal combat_enemy_attack(damage: int, ward_ratio: float)
signal combat_heal(amount: int, item_name: String)
signal combat_thunder_talisman(damage: int)
signal combat_enemy_changed(enemy_id: String, first_spawn: bool)
signal combat_enemy_defeated(enemy_id: String, loot: Dictionary)
## 闪避演出：dodger 为 "player" 或 "enemy"，舞台据此播放侧移
signal combat_dodge(dodger: String)

# ---- 渡劫 ----
signal tribulation_started
signal tribulation_thunder(index: int, damage: int, warded: bool, hp: int, max_hp: int)
signal tribulation_updated(elapsed: float, duration: float, hp: int, max_hp: int, next_in: float)
signal tribulation_finished(success: bool, message: String)

# ---- 升级反馈（音效 / 震动） ----
signal skill_level_up(skill_id: String, level: int)
signal mastery_level_up(action_id: String, level: int)

# ---- 仙盟悬赏 / 藏经阁 ----
signal bounty_changed
signal technique_changed
signal technique_unlocked(technique_id: String)

# ---- 仙坊阁 / 洞府灵田 ----
signal shop_changed
signal farm_changed
signal farm_harvested(items: Dictionary)
## 面板内的快捷跳转（如「前往仙坊阁」）
signal navigate_to(page: String)
## 跳转万象玉简并直接切到「典籍」分页（设置页入口用）
signal codex_scripture_requested
## 缺料引导：跳转到材料来源（skill / combat / farm / shop）
signal navigate_to_source(source: Dictionary)

# ---- 存档 / 离线 ----
## 短切后台（5~59 秒）静默补算完成：UI 只飘一条顶部轻量提示
signal resume_settled(seconds: float)
signal offline_report_ready(report: Dictionary)
signal game_loaded
signal game_saved(path: String)
signal toast(message: String)


func emit_toast(message: String) -> void:
	toast.emit(message)
