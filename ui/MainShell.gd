extends Control
## 移动端竖屏三段式外壳（540x960 逻辑分辨率）：
## 紧凑顶栏（☰ + 境界/修为 + 灵石 + 活跃胶囊）/ 内容区 / 底部固定导航。
## 左侧滑出式技能抽屉、安全区适配、底部说明浮层均由代码构建。

const TOPBAR_HEIGHT: float = 64.0
const BOTTOMNAV_HEIGHT: float = 72.0
## 底部导航图标统一方框：五枚水墨图标必须同尺寸、同基线
const NAV_ICON_SIZE: int = 24
## PCK 热更面板必须走 preload，不能依赖 APK 里的全局类缓存。
const CHARACTER_PANEL_SCRIPT := preload("res://ui/panels/CharacterPanel.gd")
const NATAL_ARTIFACT_PANEL_SCRIPT := preload("res://ui/panels/NatalArtifactPanel.gd")
const FISHING_TEA_PANEL_SCRIPT := preload("res://ui/panels/FishingTeaPanel.gd")
const FIVE_ELEMENTS_PANEL_SCRIPT := preload("res://ui/panels/FiveElementsPanel.gd")
const SPIRIT_ROOT_PANEL_SCRIPT := preload("res://ui/panels/SpiritRootPanel.gd")
## 竖屏逻辑画布：450 宽（原 540 的 83%），同物理宽度下整体放大 ~20%
const PORTRAIT_WIDTH: int = 450
const PORTRAIT_MIN_HEIGHT: int = 800
const DRAWER_WIDTH: float = 280.0
const CONTENT_MARGIN: float = 10.0
const SLIDE_TIME: float = 0.2
## 导航滚动：ScrollContainer 拖拽死区（像素）。小于此位移视为点击，超过则判定为滑动
const NAV_SCROLL_DEADZONE: int = 12
## 导航按钮自身的拖拽判定阈值：与滚动死区同值，保证「滑动不误触」与「轻点必响应」边界一致
const NAV_DRAG_LIMIT: float = 12.0
## 导航按钮 meta 键：按下原点 / 手指仍在按下 / 本次手势已判定为拖动
const NAV_PRESS_ORIGIN_META: String = "nav_press_origin"
const NAV_PRESS_ACTIVE_META: String = "nav_press_active"
const NAV_DRAG_GUARD_META: String = "nav_drag_guard"
## 全局产出飘字：统一从顶栏「运行状态胶囊」右下方飘出
## 起始位置距顶栏下缘的留白：保证上浮 32px 后仍完整露在顶栏之外
const FLOAT_TOP_GAP: float = 28.0
## 三档断点
const COMPACT_MAX_WIDTH: float = 680.0
const BREAK_MEDIUM: float = 840.0
const BREAK_WIDE: float = 1240.0
## 超宽带鱼屏：三栏整体最大宽度
const MAX_ULTRA_WIDE: float = 1600.0
## 左侧常驻导航 / 右侧态势栏宽度
## MEDIUM 加宽到 240、WIDE 加宽到 256，保证「采药寻灵 150/150 重」不省略
const SIDEBAR_WIDTH: float = 220.0
const SIDEBAR_WIDTH_MEDIUM: float = 240.0
const SIDEBAR_WIDTH_WIDE: float = 256.0
const STATUS_WIDTH: float = 260.0
const BG_ALPHA: float = 0.72
const BG_FADE_TIME: float = 0.35
const BG_PATHS: Dictionary = {
	"peaceful": "res://assets/images/bg/bg_peaceful.png",
	"combat": "res://assets/images/bg/bg_combat.png",
	"market": "res://assets/images/bg/bg_market.png",
	"codex": "res://assets/images/bg/bg_codex.png",
	"tribulation": "res://assets/images/bg/bg_tribulation.png",
}
const PAGE_BG: Dictionary = {
	"herbalism": "peaceful", "woodcutting": "peaceful", "mining": "peaceful",
	"alchemy": "peaceful", "forging": "peaceful", "talisman": "peaceful",
	"cultivation": "peaceful", "farm": "peaceful", "settings": "peaceful",
	"character": "peaceful", "fishing_tea": "peaceful", "spirit_root": "peaceful",
	"five_elements": "tribulation",
	"combat": "combat", "tower": "combat",
	"shop": "market", "bounty": "market", "inventory": "market", "mail": "market",
	"technique": "codex", "codex": "codex", "leaderboard": "codex",
	"natal_artifact": "codex",
	"tribulation": "tribulation",
}
## 桌面调试用：模拟刘海屏安全区（默认关闭）
const DEBUG_SIMULATE_SAFE_AREA: bool = false

const SKILL_PANEL_KEYS: Array[String] = [
	"herbalism", "woodcutting", "mining", "alchemy", "forging", "talisman", "cultivation",
]
const DRAWER_GROUPS: Array = [
	{"title": "采集三艺", "items": ["herbalism", "woodcutting", "mining"]},
	{"title": "丹器符与修行", "items": ["alchemy", "forging", "talisman", "cultivation"]},
	{"title": "道身与大道", "items": ["spirit_root", "natal_artifact", "five_elements", "tribulation"]},
	{"title": "秘境与洞府", "items": ["combat", "tower", "farm", "fishing_tea", "shop"]},
	{"title": "仙盟与道藏", "items": ["bounty", "mail", "technique", "codex", "leaderboard"]},
	{"title": "系统", "items": ["settings"]},
]
## 高阶玩法阶梯门槛：抽屉显示锁定标记，面板自身展示锁定说明卡；历史数据不清空
const FEATURE_UNLOCK_ORDER: Dictionary = {
	"bounty": 2, "technique": 5, "tower": 9, "natal_artifact": 15,
	"fishing_tea": 18, "five_elements": 24, "spirit_root": 6,
}
const FEATURE_UNLOCK_LABEL: Dictionary = {
	"bounty": "需炼气三层", "technique": "需炼气六层", "tower": "需筑基初期",
	"natal_artifact": "需元婴初期", "fishing_tea": "需化神初期",
	"five_elements": "需合体初期", "spirit_root": "需炼气七层",
}


func _is_feature_unlocked(key: String) -> bool:
	# 已有系统自身的解锁判定优先，避免边界口径漂移。
	match key:
		"spirit_root":
			return SpiritRootSystem.is_unlocked()
		"natal_artifact":
			return NatalArtifactSystem.is_unlocked()
		"fishing_tea":
			return FishingTeaSystem.is_unlocked()
		"five_elements":
			return FiveElementsSystem.is_unlocked()
	return not FEATURE_UNLOCK_ORDER.has(key) \
		or GameState.get_realm_index() >= int(FEATURE_UNLOCK_ORDER[key])


func _feature_lock_label(key: String) -> String:
	return String(FEATURE_UNLOCK_LABEL.get(key, ""))
const SKILL_LEVEL_KEYS: Array[String] = [
	"herbalism", "woodcutting", "mining", "alchemy", "forging", "talisman", "cultivation", "combat",
]
const SHORT_SKILL_NAMES: Dictionary = {
	"herbalism": "采药",
	"woodcutting": "伐木",
	"mining": "开矿",
	"alchemy": "炼丹",
	"forging": "锻造",
	"talisman": "绘符",
	"cultivation": "吐纳",
	"combat": "秘境",
}

const BOTTOM_NAV: Array = [
	{"key": "skills", "label": "百艺"},
	{"key": "farm", "label": "灵田"},
	{"key": "combat", "label": "秘境"},
	{"key": "character", "label": "道身"},
	{"key": "inventory", "label": "行囊"},
]
## 唯一权威页面图标映射：侧边栏 / 快捷切换 / 底部栏动态页签全部取此表
const PAGE_ICON_KEYS: Dictionary = {
	"skills": "nav_craft", "farm": "nav_farm", "combat": "nav_realm",
	"character": "nav_dao_bold", "inventory": "nav_bag",
	"herbalism": "skill_herbalism", "woodcutting": "skill_woodcutting",
	"mining": "skill_mining", "alchemy": "skill_alchemy",
	"forging": "skill_forging", "talisman": "skill_talisman",
	"cultivation": "skill_cultivation",
	"shop": "nav_market", "fishing_tea": "ui_tea_pot", "mail": "ui_mail_seal",
	"tower": "ui_tower", "bounty": "ui_bounty",
	"leaderboard": "ui_leaderboard_scroll",
	"spirit_root": "root_dynamic", "natal_artifact": "natal_dynamic",
	"five_elements": "ui_five_elements", "technique": "ui_technique_scroll",
	"tribulation": "ui_tribulation", "codex": "ui_codex", "settings": "gear_array",
}

## 底栏子页动态显示：进入某分组子页时，该格同步换成 2 字简称与权威图标
const NAV_DYNAMIC: Dictionary = {
	"herbalism": {"group": "skills", "caption": "采药"},
	"woodcutting": {"group": "skills", "caption": "伐木"},
	"mining": {"group": "skills", "caption": "开矿"},
	"alchemy": {"group": "skills", "caption": "炼丹"},
	"forging": {"group": "skills", "caption": "锻造"},
	"talisman": {"group": "skills", "caption": "制符"},
	"cultivation": {"group": "skills", "caption": "吐纳"},
	"shop": {"group": "farm", "caption": "坊市"},
	"fishing_tea": {"group": "farm", "caption": "灵潭"},
	"mail": {"group": "farm", "caption": "传书"},
	"tower": {"group": "combat", "caption": "镇魔"},
	"bounty": {"group": "combat", "caption": "悬赏"},
	"leaderboard": {"group": "combat", "caption": "天道"},
	"spirit_root": {"group": "character", "caption": "灵根"},
	"natal_artifact": {"group": "character", "caption": "法宝"},
	"five_elements": {"group": "character", "caption": "五行"},
	"technique": {"group": "character", "caption": "功法"},
	"tribulation": {"group": "character", "caption": "渡劫"},
	"codex": {"group": "inventory", "caption": "玉简"},
	"settings": {"group": "inventory", "caption": "设置"},
}
## 底栏二次点击快捷切换：与左侧总纲共用页面键、图标与解锁判断
## 快捷切换标题固定中文映射：禁止英文页面键回退到子卡
const QUICK_SWITCH_LABELS: Dictionary = {
	"herbalism": "采药寻灵", "woodcutting": "伐木取材", "mining": "开矿掘脉",
	"alchemy": "丹道炼制", "forging": "器道锻造", "talisman": "符箓绘制",
	"cultivation": "吐纳问道",
	"farm": "洞府灵田", "fishing_tea": "灵潭清茗", "shop": "仙坊阁",
	"mail": "仙盟传书",
	"combat": "秘境历练", "tower": "镇魔塔", "bounty": "仙盟悬赏",
	"leaderboard": "天道榜",
	"character": "修士道身", "spirit_root": "灵根洗髓",
	"natal_artifact": "本命法宝", "five_elements": "五行法则",
	"technique": "藏经阁", "tribulation": "引动天劫",
	"inventory": "储物袋", "codex": "万象玉简", "settings": "设置与仙籍",
}

const QUICK_SWITCH_GROUPS: Dictionary = {
	"skills": {
		"title": "百艺快捷切换",
		"items": ["herbalism", "woodcutting", "mining", "alchemy", "forging", "talisman", "cultivation"],
	},
	"farm": {
		"title": "洞府快捷切换",
		"items": ["farm", "fishing_tea", "shop", "mail"],
	},
	"combat": {
		"title": "历练快捷切换",
		"items": ["combat", "tower", "bounty", "leaderboard"],
	},
	"character": {
		"title": "道身快捷切换",
		"items": ["character", "spirit_root", "natal_artifact", "five_elements", "technique", "tribulation"],
	},
	"inventory": {
		"title": "行囊与道藏",
		"items": ["inventory", "codex", "settings"],
	},
}

var _safe_top: float = 0.0
var _safe_bottom: float = 0.0
var _safe_left: float = 0.0
var _safe_right: float = 0.0
var _extra_side: float = 0.0
var _content_margin: MarginContainer
var _bg_layer: Control
var _bg_back: TextureRect
var _bg_front: TextureRect
var _bg_textures: Dictionary = {}
var _bg_theme: String = ""
var _bg_tween: Tween
var _body_row: HBoxContainer
var _sidebar_slot: PanelContainer
var _sidebar_scroll: ScrollContainer
var _drawer_scroll: ScrollContainer
var _nav_content: VBoxContainer
var _status_sidebar: StatusSidebar
var _menu_button: Button
var _menu_mail_badge: PanelContainer
var _menu_attention_dot: PanelContainer
var _farm_nav_dot: PanelContainer
var _character_nav_dot: PanelContainer
var _realm_break_dot: PanelContainer
var _attention_signature: String = ""
var _drawer_close_button: Button
var _side_line_left: ColorRect
var _side_line_right: ColorRect
var _layout_mode: int = EventBus.LayoutMode.COMPACT
var _workspace_width: float = 540.0
var _layout_dirty: bool = false

var _topbar: PanelContainer
var _bottom_nav: PanelContainer
var _top_style: StyleBoxFlat
var _bottom_style: StyleBoxFlat
var _panel_host: Control
var _ink_vfx: InkVfxLayer
var _toast_layer: MarginContainer

var _realm_label: Label
var _realm_panel: PanelContainer
var _realm_seal: PanelContainer
var _realm_seal_label: Label
var _realm_style: StyleBoxFlat
var _cultivation_bar: ProgressBar
var _cultivation_pct: Label
var _pulse_tween: Tween
var _cultivation_tween: Tween
var _stone_label: Label
var _stone_tween: Tween
var _stone_pulse_tween: Tween
var _stone_value: int = 0
var _last_topbar_refresh_ms: int = -1000
var _topbar_refresh_pending: bool = false
var _stone_capsule: PanelContainer
var _top_expander: Control
var _active_capsule: Button
var _capsule_icon: TextureRect
var _capsule_label: Label
var _capsule_target: String = ""

var _drawer_legend: BoxContainer
var _nav_buttons: Dictionary = {}
var _nav_dots: Dictionary = {}
var _nav_icons: Dictionary = {}
var _nav_labels: Dictionary = {}
var _nav_active_key: String = ""
var _panels: Dictionary = {}
var _current_key: String = ""
var _last_skill_key: String = "herbalism"

var _drawer_layer: Control
var _drawer: PanelContainer
var _drawer_scrim: ColorRect
var _drawer_open: bool = false
var _drawer_tween: Tween
var _drawer_entries: Dictionary = {}

var _toast_panel: PanelContainer
var _toast_label: Label
var _toast_tween: Tween

var _settle_banner: PanelContainer
var _settle_label: Label
var _settle_tween: Tween

var _bottom_sheet: BottomSheet
## 灵动岛式三才运转浮层（懒创建，仅多槽并发时使用）
var _island: DynamicIslandPopover
var _modal: OfflineReportModal
var _cloud_dialog: CloudConflictDialog
var _boot_overlay: BootSplashOverlay
var _last_realm_id: String = ""
var _dual_notified: bool = false


func _ready() -> void:
	theme = ThemeBuilder.build_theme()
	if get_window() != null:
		get_window().title = "玉简问道 · PathOfJade"
	# 先让宣纸过渡层上屏，再构建主界面，避免首帧闪出半成品。
	# 从仙籍登录页进入时开场水墨已在 LoginScene 播过，跳过二次遮罩。
	if not _cloud_skip_boot_overlay():
		_boot_overlay = BootSplashOverlay.new()
		_boot_overlay.z_index = 100
		add_child(_boot_overlay)
	_reset_cloud_skip_boot_overlay()
	await get_tree().process_frame
	_sync_content_scale()
	_apply_safe_area()
	_build_layout()
	_build_fx_layer()
	_build_toast()
	_build_settle_banner()
	_build_drawer()
	_bottom_sheet = BottomSheet.new()
	_bottom_sheet.z_index = 40
	add_child(_bottom_sheet)
	_modal = OfflineReportModal.new()
	_modal.z_index = 50
	add_child(_modal)
	_cloud_dialog = CloudConflictDialog.new()
	_cloud_dialog.z_index = 60
	add_child(_cloud_dialog)
	# 基包 AutoLoad 可能尚未包含 PCK 新增的信号：逐个 has_signal 后再挂接，绝不让缺失接口中断首屏
	_connect_optional_signal(CloudSaveManager, "save_conflict_detected",
		_on_cloud_conflict_detected)
	_connect_optional_signal(CloudSaveManager, "new_account_choice_required",
		_on_new_account_choice_required)
	_connect_optional_signal(CloudSaveManager, "save_pull_requested",
		_on_cloud_pull_requested)
	_connect_optional_signal(CloudSaveManager, "mail_unread_changed",
		_on_mail_unread_changed)

	_connect_optional_signal(EventBus, "offline_report_ready", _on_offline_report_ready)
	_connect_optional_signal(EventBus, "resume_settled", _on_resume_settled)
	_connect_optional_signal(EventBus, "toast", _show_toast)
	_connect_optional_signal(EventBus, "floating_text", _on_floating_text)
	_connect_optional_signal(EventBus, "stats_changed", _refresh_topbar)
	_connect_optional_signal(EventBus, "stats_changed", _refresh_drawer)
	_connect_optional_signal(EventBus, "equipment_changed", _refresh_topbar)
	_connect_optional_signal(EventBus, "inventory_changed", _refresh_stones)
	_connect_optional_signal(EventBus, "inventory_changed", _on_drawer_attention_changed)
	_connect_optional_signal(EventBus, "realm_changed", _on_realm_changed)
	_connect_optional_signal(EventBus, "cultivation_changed", _on_cultivation_changed)
	_connect_optional_signal(EventBus, "game_loaded", _sync_font_scale_from_state)
	_connect_optional_signal(EventBus, "game_loaded", _refresh_all)
	_connect_optional_signal(EventBus, "font_scale_changed", _on_font_scale_changed)
	_connect_optional_signal(EventBus, "action_started", _on_action_state_changed)
	_connect_optional_signal(EventBus, "action_stopped", _on_action_state_changed)
	_connect_optional_signal(EventBus, "combat_started", _on_combat_state_changed)
	_connect_optional_signal(EventBus, "combat_stopped", _on_combat_state_changed)
	_connect_optional_signal(EventBus, "dual_cultivation_unlocked", _on_dual_unlocked)
	_connect_optional_signal(EventBus, "navigate_to", _show_panel)
	_connect_optional_signal(EventBus, "navigate_to_source", _on_navigate_to_source)
	_connect_optional_signal(EventBus, "codex_scripture_requested", _on_codex_scripture_requested)
	_connect_optional_signal(EventBus, "shop_changed", _refresh_all)
	_connect_optional_signal(EventBus, "bounty_changed", _on_drawer_attention_changed)
	_connect_optional_signal(EventBus, "technique_changed", _refresh_drawer)
	_connect_optional_signal(EventBus, "farm_changed", _on_farm_state_changed)
	_connect_optional_signal(EventBus, "combat_enemy_defeated", _on_enemy_defeated_attention)
	if get_viewport() != null:
		get_viewport().size_changed.connect(_on_viewport_resized)

	var had_save := SaveManager.has_save()
	SaveManager.load_game()
	if BountyManager != null and BountyManager.has_method("ensure_bounties"):
		BountyManager.ensure_bounties()
	_apply_orientation_lock()
	_apply_fps()
	_refresh_all()
	# 先把默认首页显示出来，再做可选云同步/角标刷新；后者异常也不会留下中心空白
	_show_panel(_last_skill_key)
	_on_mail_unread_changed(_cloud_unread_count())
	if not had_save:
		_show_toast("初入道途：先在「采药寻灵」开始运转一门功法")
	# 登录后首次进入主界面：基包若无 begin_session 则安全跳过
	if CloudSaveManager != null and CloudSaveManager.has_method("begin_session"):
		CloudSaveManager.begin_session()


func _exit_tree() -> void:
	_disconnect_optional_signal(CloudSaveManager, "mail_unread_changed",
		_on_mail_unread_changed)
	if CloudSaveManager != null and CloudSaveManager.has_method("end_session"):
		CloudSaveManager.end_session()


## 跨 AutoLoad 兼容层：基包缺少信号时只跳过，不抛错。
func _connect_optional_signal(source: Object, signal_name: String,
		target: Callable) -> bool:
	if source == null or not source.has_signal(signal_name):
		return false
	if not source.is_connected(signal_name, target):
		source.connect(signal_name, target)
	return true


func _disconnect_optional_signal(source: Object, signal_name: String,
		target: Callable) -> void:
	if source == null or not source.has_signal(signal_name):
		return
	if source.is_connected(signal_name, target):
		source.disconnect(signal_name, target)


func _cloud_skip_boot_overlay() -> bool:
	if CloudSaveManager == null:
		return false
	var value: Variant = CloudSaveManager.get("skip_boot_overlay")
	return false if value == null else bool(value)


func _reset_cloud_skip_boot_overlay() -> void:
	if CloudSaveManager == null:
		return
	if CloudSaveManager.get("skip_boot_overlay") != null:
		CloudSaveManager.set("skip_boot_overlay", false)


func _cloud_unread_count() -> int:
	if CloudSaveManager == null:
		return 0
	var value: Variant = CloudSaveManager.get("unread_mail_count")
	return 0 if value == null else maxi(0, int(value))


func _on_cloud_conflict_detected(local_summary: Dictionary,
		cloud_summary: Dictionary) -> void:
	if _cloud_dialog != null:
		_cloud_dialog.show_conflict(local_summary, cloud_summary, false)


func _on_new_account_choice_required(local_summary: Dictionary) -> void:
	if _cloud_dialog != null:
		_cloud_dialog.show_new_account(local_summary)


func _on_cloud_pull_requested(local_summary: Dictionary,
		cloud_summary: Dictionary) -> void:
	if _cloud_dialog != null:
		_cloud_dialog.show_conflict(local_summary, cloud_summary, true)


## PC：Esc 依次关闭 离线玉简 → 底部浮层 → 抽屉
func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode != KEY_ESCAPE:
		return
	var handled := true
	if _modal != null and _modal.visible:
		_modal.hide()
	elif _bottom_sheet != null and _bottom_sheet.visible:
		_bottom_sheet.hide_sheet()
	elif _drawer_layer != null and _drawer_layer.visible:
		_close_drawer()
	else:
		handled = false
	if handled:
		get_viewport().set_input_as_handled()


func _on_mail_unread_changed(count: int) -> void:
	var mail_deco: Dictionary = _drawer_entries.get("mail", {})
	if not mail_deco.is_empty():
		var right: Label = mail_deco["right"]
		right.text = "%d 封" % count if count > 0 else ""
		right.add_theme_color_override("font_color",
			ThemeBuilder.COLOR_CINNABAR if count > 0 else ThemeBuilder.COLOR_TEXT_DIM)
		var dot: Container = mail_deco["dot"]
		ThemeBuilder.set_row_dots(dot, [ThemeBuilder.COLOR_CINNABAR] if count > 0 else [])
	if _menu_mail_badge != null:
		_menu_mail_badge.visible = count > 0
		for child in _menu_mail_badge.get_children():
			if child is Label:
				(child as Label).text = str(mini(count, 99)) + ("+" if count > 99 else "")
	_refresh_attention()


func _on_drawer_attention_changed() -> void:
	_refresh_drawer()
	_refresh_attention()


func _on_enemy_defeated_attention(_enemy_id: String, _loot: Dictionary) -> void:
	_on_drawer_attention_changed()


func _on_farm_state_changed() -> void:
	_refresh_nav()
	_refresh_drawer()


# ---------------------------------------------------------------- 安全区

func _is_mobile_platform() -> bool:
	return OS.has_feature("android") or OS.has_feature("ios")


## 安全区：物理像素 → 逻辑像素精确换算（桌面端恒为 0，避免误读任务栏）
func _compute_safe_insets() -> Dictionary:
	var zero := {"top": 0.0, "bottom": 0.0, "left": 0.0, "right": 0.0}
	if not _is_mobile_platform() and not DEBUG_SIMULATE_SAFE_AREA:
		return zero

	var win_size := Vector2(DisplayServer.window_get_size())
	var vp_size := get_viewport_rect().size
	if win_size.x <= 0.0 or win_size.y <= 0.0 or vp_size.x <= 0.0 or vp_size.y <= 0.0:
		return zero
	var scale_x: float = vp_size.x / win_size.x
	var scale_y: float = vp_size.y / win_size.y

	var safe_rect := Rect2(DisplayServer.get_display_safe_area())
	if DEBUG_SIMULATE_SAFE_AREA and not _is_mobile_platform():
		# 调试：模拟 44px 刘海 + 34px 手势条
		safe_rect = Rect2(0.0, 44.0, win_size.x, win_size.y - 78.0)

	var top := clampf(float(safe_rect.position.y) * scale_y, 0.0, 96.0)
	var bottom := clampf(float(win_size.y - (safe_rect.position.y + safe_rect.size.y)) * scale_y, 0.0, 72.0)
	var left := clampf(float(safe_rect.position.x) * scale_x, 0.0, 48.0)
	var right := clampf(float(win_size.x - (safe_rect.position.x + safe_rect.size.x)) * scale_x, 0.0, 48.0)
	return {"top": top, "bottom": bottom, "left": left, "right": right}


func _apply_safe_area() -> void:
	var insets := _compute_safe_insets()
	_safe_top = float(insets["top"])
	_safe_bottom = float(insets["bottom"])
	_safe_left = float(insets["left"])
	_safe_right = float(insets["right"])

	# 断点判定与净宽
	var vp_size := get_viewport_rect().size
	var mode := _mode_for_width(vp_size.x)
	_layout_mode = mode
	_extra_side = 0.0
	var sidebar_width := _sidebar_width_for_mode(mode)
	var side_left := _safe_left
	var side_right := _safe_right
	if mode == EventBus.LayoutMode.COMPACT:
		_extra_side = maxf(0.0, (vp_size.x - COMPACT_MAX_WIDTH) * 0.5)
		side_left = maxf(side_left, _extra_side)
		side_right = maxf(side_right, _extra_side)
	elif mode == EventBus.LayoutMode.WIDE:
		var ultra := maxf(0.0, (vp_size.x - MAX_ULTRA_WIDE) * 0.5)
		side_left = maxf(side_left, ultra)
		side_right = maxf(side_right, ultra)

	match mode:
		EventBus.LayoutMode.COMPACT:
			_workspace_width = minf(vp_size.x, COMPACT_MAX_WIDTH)
		EventBus.LayoutMode.MEDIUM:
			_workspace_width = vp_size.x - sidebar_width - _safe_left - _safe_right
		_:
			_workspace_width = minf(vp_size.x, MAX_ULTRA_WIDE) - sidebar_width - STATUS_WIDTH \
				- _safe_left - _safe_right
	_workspace_width = maxf(320.0, _workspace_width)

	if _topbar == null or _bottom_nav == null:
		return
	# 顶/底栏底色条保持 100% 铺满，仅内边距收束
	_topbar.custom_minimum_size = Vector2(0, TOPBAR_HEIGHT + _safe_top)
	_top_style.content_margin_top = 6.0 + _safe_top
	_top_style.content_margin_left = 10.0 + side_left
	_top_style.content_margin_right = 10.0 + side_right
	_bottom_nav.custom_minimum_size = Vector2(0, BOTTOMNAV_HEIGHT + _safe_bottom)
	_bottom_style.content_margin_bottom = 4.0 + _safe_bottom
	_bottom_style.content_margin_left = 4.0 + side_left
	_bottom_style.content_margin_right = 4.0 + side_right
	if _content_margin != null:
		_content_margin.add_theme_constant_override("margin_left",
			int(round(side_left)) + int(CONTENT_MARGIN))
		_content_margin.add_theme_constant_override("margin_right",
			int(round(side_right)) + int(CONTENT_MARGIN))
	if _toast_layer != null:
		_toast_layer.add_theme_constant_override("margin_bottom", int(BOTTOMNAV_HEIGHT + _safe_bottom + 12.0))
		_settle_banner.offset_top = TOPBAR_HEIGHT + _safe_top + 6.0
		_settle_banner.offset_bottom = TOPBAR_HEIGHT + _safe_top + 6.0
	_update_side_lines(side_left, side_right, vp_size)
	_apply_nav_mode(mode)
	_apply_topbar_layout()
	_apply_bg_bounds(mode)
	_publish_layout(vp_size)


## 竖屏底部栏为不透明导航；背景画卷在底部栏上缘截断，避免透到栏后
func _apply_bg_bounds(mode: int) -> void:
	if _bg_layer == null:
		return
	var bottom_cut := BOTTOMNAV_HEIGHT + _safe_bottom \
		if mode == EventBus.LayoutMode.COMPACT else 0.0
	_bg_layer.offset_bottom = -bottom_cut


func _sidebar_width_for_mode(mode: int) -> float:
	match mode:
		EventBus.LayoutMode.MEDIUM:
			return SIDEBAR_WIDTH_MEDIUM
		EventBus.LayoutMode.WIDE:
			return SIDEBAR_WIDTH_WIDE
		_:
			return SIDEBAR_WIDTH


func _mode_for_width(vp_w: float) -> int:
	if vp_w >= BREAK_WIDE:
		return EventBus.LayoutMode.WIDE
	if vp_w >= BREAK_MEDIUM:
		return EventBus.LayoutMode.MEDIUM
	return EventBus.LayoutMode.COMPACT


## 导航搬家：窄屏进抽屉，宽屏进左侧常驻栏（同一棵 UI 树）
func _apply_nav_mode(mode: int) -> void:
	var compact := mode == EventBus.LayoutMode.COMPACT
	if _nav_content != null:
		var target: Node = _drawer_scroll if compact else _sidebar_scroll
		if target != null and _nav_content.get_parent() != target:
			_nav_content.reparent(target, false)
	# reparent 只搬节点、不改属性；两种承载容器都重新武装一次，
	# 保证死区 / 禁横向滚动 / follow_focus 在档位切换后来回都有效
	_configure_nav_scroll(_drawer_scroll)
	_configure_nav_scroll(_sidebar_scroll)
	if _drawer_layer != null:
		_close_drawer()
	if _menu_button != null:
		_menu_button.visible = compact
	if _drawer_close_button != null:
		_drawer_close_button.visible = compact
	if _bottom_nav != null:
		_bottom_nav.visible = compact
	if _sidebar_slot != null:
		_sidebar_slot.custom_minimum_size.x = _sidebar_width_for_mode(mode)
		_sidebar_slot.visible = not compact
	if _status_sidebar != null:
		_status_sidebar.visible = mode == EventBus.LayoutMode.WIDE


func _publish_layout(vp_size: Vector2) -> void:
	EventBus.current_layout = _layout_mode
	EventBus.current_viewport = vp_size
	EventBus.workspace_width = _workspace_width
	EventBus.layout_changed.emit(_layout_mode, vp_size, _workspace_width)


func _make_side_line() -> ColorRect:
	var line := ColorRect.new()
	line.color = Color(ThemeBuilder.COLOR_CHROME_LINE, 0.9)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(line)
	return line


## 宽屏居中时在内容区两侧画 1px 玉灰竖分隔线（仅 extra_side >= 20 显示）
func _update_side_lines(side_left: float, side_right: float, vp_size: Vector2) -> void:
	var show_lines := _layout_mode == EventBus.LayoutMode.COMPACT and _extra_side >= 20.0
	if _side_line_left == null:
		_side_line_left = _make_side_line()
		_side_line_right = _make_side_line()
	_side_line_left.visible = show_lines
	_side_line_right.visible = show_lines
	if not show_lines:
		return
	var top_y := TOPBAR_HEIGHT + _safe_top
	var bottom_h := BOTTOMNAV_HEIGHT + _safe_bottom
	var line_height := maxf(0.0, vp_size.y - top_y - bottom_h)
	_side_line_left.position = Vector2(round(side_left) - 1.0, top_y)
	_side_line_left.size = Vector2(1.0, line_height)
	_side_line_right.position = Vector2(vp_size.x - round(side_right), top_y)
	_side_line_right.size = Vector2(1.0, line_height)


func _on_viewport_resized() -> void:
	_sync_content_scale()
	call_deferred("_apply_safe_area")


## 竖屏逻辑宽度固定 450，高度按窗口宽高比推导：物理显示比原 540 基准放大约 20%；
## 横屏 / PC 保留实际窗口宽高比（封顶 1600×等比），确保 1440×900 能进入 WIDE 三列断点。
## 值判等防递归。
func _sync_content_scale() -> void:
	var win := DisplayServer.window_get_size()
	if win.x <= 0 or win.y <= 0:
		return
	if get_window() == null:
		return
	var target := Vector2i(1024, 720)
	if win.x < win.y:
		var aspect := float(win.y) / float(maxi(1, win.x))
		target = Vector2i(PORTRAIT_WIDTH,
			maxi(PORTRAIT_MIN_HEIGHT, int(round(float(PORTRAIT_WIDTH) * aspect))))
	elif win.x > 1024:
		var cap_scale := minf(1.0, float(MAX_ULTRA_WIDE) / float(win.x))
		target = Vector2i(
			clampi(int(round(float(win.x) * cap_scale)), 1024, int(MAX_ULTRA_WIDE)),
			maxi(720, int(round(float(win.y) * cap_scale))))
	if get_window().content_scale_size != target:
		get_window().content_scale_size = target


## 存档里的「锁定竖屏」仅对移动端生效
func _apply_orientation_lock() -> void:
	if not (OS.has_feature("android") or OS.has_feature("ios")):
		return
	DisplayServer.screen_set_orientation(
		DisplayServer.SCREEN_PORTRAIT if GameState.lock_portrait else DisplayServer.SCREEN_SENSOR)


func _apply_fps() -> void:
	# 0 = 30 / 1 = 60 / 2 = 高刷（对齐设备屏幕最高刷新率）；统一由 GameState 落地
	var mode := int(GameState.flags.get("fps_mode", -1))
	if mode < 0:
		mode = 1 if GameState.is_flag("fps60", false) else 0
	GameState.apply_fps_mode(mode)


# ---------------------------------------------------------------- 全局字号

## 读档 / 导入存档后同步字号档位（旧档 0.90/1.00/1.15 就地迁移到 0.95/1.05/1.20）
func _sync_font_scale_from_state() -> void:
	var raw := float(GameState.flags.get("font_scale", ThemeBuilder.FONT_SCALE_STANDARD))
	var normalized := ThemeBuilder.normalize_font_scale(raw)
	if not is_equal_approx(raw, normalized):
		GameState.flags["font_scale"] = normalized
	_apply_font_scale(normalized)


## 设置页切换字号：立即重建主题并重算整棵 UI 树
func _on_font_scale_changed(scale: float) -> void:
	_apply_font_scale(scale, true)


func _apply_font_scale(scale: float, force: bool = false) -> void:
	scale = ThemeBuilder.normalize_font_scale(
		clampf(scale, ThemeBuilder.FONT_SCALE_COMPACT, ThemeBuilder.FONT_SCALE_LARGE))
	if not force and is_equal_approx(ThemeBuilder.font_scale, scale):
		return
	ThemeBuilder.set_font_scale(scale)
	theme = ThemeBuilder.build_theme()
	ThemeBuilder.apply_font_scale_to_tree(self)
	# 字号变化会改变最小尺寸，下一帧重新套用安全区与断点
	call_deferred("_apply_safe_area")


# ---------------------------------------------------------------- 一页一景背景

func _build_background() -> void:
	_bg_layer = Control.new()
	_bg_layer.name = "BackgroundLayer"
	_bg_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_bg_layer)
	_bg_back = _make_bg_rect()
	_bg_front = _make_bg_rect()
	_bg_layer.add_child(_bg_back)
	_bg_layer.add_child(_bg_front)
	for theme_key in BG_PATHS.keys():
		var path := String(BG_PATHS[theme_key])
		if ResourceLoader.exists(path):
			var resource := load(path)
			if resource is Texture2D:
				_bg_textures[theme_key] = resource as Texture2D
	var initial := _bg_textures.get("peaceful", null) as Texture2D
	if initial != null:
		_bg_back.texture = initial
		_bg_back.modulate.a = BG_ALPHA
		_bg_theme = "peaceful"


func _make_bg_rect() -> TextureRect:
	var rect := TextureRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.modulate.a = 0.0
	return rect


func _switch_bg(theme_key: String) -> void:
	if _bg_layer == null or theme_key == _bg_theme:
		return
	var texture := _bg_textures.get(theme_key, _bg_textures.get("peaceful", null)) as Texture2D
	if texture == null:
		return
	_bg_theme = theme_key
	if _bg_tween != null and _bg_tween.is_valid():
		_bg_tween.kill()
	_bg_front.texture = texture
	_bg_front.modulate.a = 0.0
	_bg_tween = create_tween()
	_bg_tween.set_parallel(true)
	_bg_tween.tween_property(_bg_front, "modulate:a", BG_ALPHA, BG_FADE_TIME) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_bg_tween.tween_property(_bg_back, "modulate:a", 0.0, BG_FADE_TIME) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_bg_tween.chain().tween_callback(_finish_bg_fade)


func _finish_bg_fade() -> void:
	if _bg_front == null or _bg_back == null:
		return
	_bg_back.texture = _bg_front.texture
	_bg_back.modulate.a = BG_ALPHA
	_bg_front.texture = null
	_bg_front.modulate.a = 0.0


# ---------------------------------------------------------------- 布局

func _build_layout() -> void:
	var bg := ColorRect.new()
	bg.color = ThemeBuilder.COLOR_BG
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_background()

	var aura := AmbientAuraLayer.new()
	add_child(aura)

	var root := VBoxContainer.new()
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)

	_topbar = _build_topbar()
	root.add_child(_topbar)

	var content := MarginContainer.new()
	_content_margin = content
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("margin_left", int(CONTENT_MARGIN))
	content.add_theme_constant_override("margin_right", int(CONTENT_MARGIN))
	content.add_theme_constant_override("margin_top", 8)
	content.add_theme_constant_override("margin_bottom", 8)
	root.add_child(content)

	# 三栏之间留 12px：否则中栏卡片右上的水印会与右栏标题贴在一起
	_body_row = ThemeBuilder.hbox(12)
	_body_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(_body_row)

	# 左侧常驻导航槽（MEDIUM / WIDE）
	_sidebar_slot = PanelContainer.new()
	_sidebar_slot.custom_minimum_size = Vector2(SIDEBAR_WIDTH, 0)
	_sidebar_slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# 常驻侧栏始终压在 InkVfxLayer(12) 之上，宽屏也不会被水墨笔触穿透
	_sidebar_slot.z_index = 20
	var side_style := ThemeBuilder.panel_box(ThemeBuilder.COLOR_CHROME,
		ThemeBuilder.COLOR_BORDER, 0, 0, 8)
	side_style.set_border_width_all(0)
	side_style.border_width_right = 1
	side_style.bg_color = Color(0, 0, 0, 0)
	side_style.content_margin_top = 8
	side_style.content_margin_bottom = 8
	_sidebar_slot.add_theme_stylebox_override("panel", side_style)
	_sidebar_slot.visible = false
	_body_row.add_child(_sidebar_slot)
	_sidebar_scroll = ThemeBuilder.scroll_container()
	_configure_nav_scroll(_sidebar_scroll)
	_sidebar_slot.add_child(_sidebar_scroll)

	_panel_host = Control.new()
	_panel_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_panel_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# 顶层宽度锁：任何单个子面板把最小宽撑大时，超出内容区的部分在此硬裁，
	# 绝不允许把 450 竖屏视口顶宽（面板自身仍须做自适应，裁切只作最后兜底）
	_panel_host.clip_contents = true
	_body_row.add_child(_panel_host)

	# 右侧「洞府态势栏」（仅 WIDE）
	_status_sidebar = StatusSidebar.new()
	_status_sidebar.z_index = 20
	_status_sidebar.request_panel.connect(_show_panel)
	_status_sidebar.visible = false
	_body_row.add_child(_status_sidebar)

	_bottom_nav = _build_bottom_nav()
	root.add_child(_bottom_nav)

	# 控件就绪后立即套用安全区 / 断点布局
	_apply_safe_area()


func _build_topbar() -> PanelContainer:
	var bar := PanelContainer.new()
	# 顶栏必须压在产出飘字之上，飘字只在其下缘之外出现
	bar.z_index = 10
	# 顶栏内部极端长文本不向外顶宽：仍有面板级自适应，这里只做硬裁兜底
	bar.clip_contents = true
	bar.custom_minimum_size = Vector2(0, TOPBAR_HEIGHT + _safe_top)
	_top_style = ThemeBuilder.panel_box(ThemeBuilder.COLOR_CHROME,
		ThemeBuilder.COLOR_CHROME_LINE, 0, 0, 0)
	_top_style.set_border_width_all(0)
	_top_style.border_width_bottom = 1
	_top_style.border_color = ThemeBuilder.COLOR_CHROME_LINE
	_top_style.content_margin_left = 10
	_top_style.content_margin_right = 10
	_top_style.content_margin_top = 6 + _safe_top
	_top_style.content_margin_bottom = 6
	bar.add_theme_stylebox_override("panel", _top_style)

	# 6px 间距：1.20 大字档下 450 宽顶栏刚好容纳「菜单 + 境界印 + 灵石 + 状态胶囊」
	var row := ThemeBuilder.hbox(5)
	bar.add_child(row)

	_menu_button = ThemeBuilder.icon_button("☰", ThemeBuilder.TOUCH_MIN)
	_menu_button.pressed.connect(_toggle_drawer)
	ThemeBuilder.silence_button_click(_menu_button)
	TooltipHelper.attach(_menu_button, "打开技能抽屉")
	row.add_child(_menu_button)
	# 仙盟传书未读角标：贴菜单按钮右上角，轻量朱砂印章，不占额外行宽
	_menu_mail_badge = ThemeBuilder.create_seal_badge("", "cinnabar")
	_menu_mail_badge.name = "MenuMailBadge"
	_menu_mail_badge.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_menu_mail_badge.offset_left = -24
	_menu_mail_badge.offset_right = 2
	_menu_mail_badge.offset_top = -4
	_menu_mail_badge.offset_bottom = 18
	_menu_mail_badge.visible = false
	for child in _menu_mail_badge.get_children():
		if child is Label:
			ThemeBuilder.apply_font_size(child as Label, ThemeBuilder.FONT_CAPTION)
	_menu_button.add_child(_menu_mail_badge)
	# 聚合待办圆点：无未读数时以 8×8 小点提示悬赏 / 俸禄 / 渡劫等待办
	_menu_attention_dot = ThemeBuilder.color_dot(ThemeBuilder.COLOR_TEXT_DANGER, 8.0)
	_menu_attention_dot.name = "MenuAttentionDot"
	_menu_attention_dot.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_menu_attention_dot.offset_left = -10
	_menu_attention_dot.offset_right = -2
	_menu_attention_dot.offset_top = -2
	_menu_attention_dot.offset_bottom = 6
	_menu_attention_dot.visible = false
	_menu_button.add_child(_menu_attention_dot)

	# 境界 + 修为条（可点击直达吐纳 / 渡劫）
	_realm_panel = PanelContainer.new()
	_realm_panel.custom_minimum_size = Vector2(150, 0)
	_realm_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_realm_style = ThemeBuilder.panel_box(ThemeBuilder.COLOR_CARD,
		ThemeBuilder.COLOR_BORDER, 9, 1, 8)
	_realm_style.content_margin_top = 3
	_realm_style.content_margin_bottom = 3
	_realm_panel.add_theme_stylebox_override("panel", _realm_style)
	_realm_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_realm_panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_realm_panel.tooltip_text = "轻触前往吐纳；修为圆满时可引动天劫"
	_realm_panel.gui_input.connect(_on_realm_gui_input)
	row.add_child(_realm_panel)

	# 顶栏只保留全局状态：境界印 + 小境界 + 修为条（页面标题交给页面自身）
	var title_col := ThemeBuilder.vbox(1)
	title_col.alignment = BoxContainer.ALIGNMENT_CENTER
	_realm_panel.add_child(title_col)
	var realm_row := ThemeBuilder.hbox(4)
	title_col.add_child(realm_row)
	_realm_seal = ThemeBuilder.create_seal_badge("炼气", "cinnabar")
	_realm_seal_label = _realm_seal.get_child(0) as Label
	ThemeBuilder.apply_font_size(_realm_seal_label, ThemeBuilder.FONT_BODY_SUB)
	# 境界印与层数统一用清晰加粗无衬线：手机小字号下「一层」~「九层」不糊成一团
	ThemeBuilder.apply_realm_font(_realm_seal_label)
	realm_row.add_child(_realm_seal)
	_realm_label = ThemeBuilder.label("炼气一层", ThemeBuilder.FONT_BODY, ThemeBuilder.COLOR_TEXT)
	ThemeBuilder.apply_realm_font(_realm_label)
	realm_row.add_child(_realm_label)
	realm_row.add_child(ThemeBuilder.expander())
	_cultivation_pct = ThemeBuilder.label("0%", ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT)
	_cultivation_pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	realm_row.add_child(_cultivation_pct)
	_cultivation_bar = ThemeBuilder.progress_bar(ThemeBuilder.COLOR_JADE, 4)
	_cultivation_bar.add_theme_stylebox_override("background",
		ThemeBuilder.panel_box(Color("#E4DDD0"), Color(0, 0, 0, 0), 2, 0, 0))
	title_col.add_child(_cultivation_bar)
	# 渡劫金点浮在境界胶囊右缘，不参与 HBox 最小宽度计算，绝不计入 450 宽布局
	var realm_badge_layer := HBoxContainer.new()
	realm_badge_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	realm_badge_layer.alignment = BoxContainer.ALIGNMENT_END
	realm_badge_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	realm_badge_layer.z_index = 1
	_realm_panel.add_child(realm_badge_layer)
	_realm_break_dot = ThemeBuilder.color_dot(ThemeBuilder.COLOR_TEXT_GOLD, 8.0)
	_realm_break_dot.name = "RealmBreakDot"
	_realm_break_dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_realm_break_dot.visible = false
	realm_badge_layer.add_child(_realm_break_dot)

	# 灵石：图标 + 紧凑数值
	_stone_capsule = PanelContainer.new()
	var stone_style := ThemeBuilder.panel_box(ThemeBuilder.COLOR_SUBTLE,
		ThemeBuilder.COLOR_CHROME_LINE, 10, 1, 8)
	stone_style.content_margin_top = 3
	stone_style.content_margin_bottom = 3
	_stone_capsule.add_theme_stylebox_override("panel", stone_style)
	_stone_capsule.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_stone_capsule.mouse_filter = Control.MOUSE_FILTER_STOP
	_stone_capsule.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_stone_capsule.tooltip_text = "前往仙坊阁"
	_stone_capsule.gui_input.connect(_on_stone_gui_input)
	row.add_child(_stone_capsule)
	var stone_box := ThemeBuilder.hbox(4)
	_stone_capsule.add_child(stone_box)
	stone_box.add_child(ThemeBuilder.icon_rect(
		IconLibrary.get_item_icon(DataRegistry.SPIRIT_STONE), 16))
	_stone_label = ThemeBuilder.label("0", 14, ThemeBuilder.COLOR_AMBER)
	stone_box.add_child(_stone_label)
	if _stone_label.get_theme_font("font") != null:
		var bold := FontVariation.new()
		bold.base_font = _stone_label.get_theme_font("font")
		bold.variation_embolden = 0.55
		_stone_label.add_theme_font_override("font", bold)
	_top_expander = ThemeBuilder.expander()
	row.add_child(_top_expander)

	_active_capsule = ThemeBuilder.small_button("")
	_active_capsule.custom_minimum_size = Vector2(96, 30)
	ThemeBuilder.apply_font_size(_active_capsule, ThemeBuilder.FONT_BODY_SUB)
	_active_capsule.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_active_capsule.pressed.connect(_on_capsule_pressed)
	row.add_child(_active_capsule)
	var capsule_row := ThemeBuilder.hbox(5)
	capsule_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	capsule_row.offset_left = 10.0
	capsule_row.offset_right = -10.0
	capsule_row.alignment = BoxContainer.ALIGNMENT_CENTER
	capsule_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_active_capsule.add_child(capsule_row)
	_capsule_icon = ThemeBuilder.icon_rect(IconLibrary.get_skill_icon("cultivation"), 16)
	_capsule_icon.modulate = Color(1, 1, 1, 0.55)
	capsule_row.add_child(_capsule_icon)
	_capsule_label = ThemeBuilder.label("静修", 12, ThemeBuilder.COLOR_TEXT_DIM)
	_capsule_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capsule_row.add_child(_capsule_label)

	_apply_topbar_layout()
	return bar


func _apply_topbar_layout() -> void:
	if _realm_panel == null:
		return
	var wide := _layout_mode == EventBus.LayoutMode.WIDE
	_realm_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN if wide else Control.SIZE_EXPAND_FILL
	# 竖屏压缩到 132：境界印 + 短境名 + 百分比仍排得下，给灵石与状态胶囊让出宽度
	_realm_panel.custom_minimum_size = Vector2(280.0 if wide else 132.0, 0.0)
	if _top_expander != null:
		_top_expander.visible = wide
	call_deferred("_sync_topbar_chip_heights")


func _build_bottom_nav() -> PanelContainer:
	var bar := PanelContainer.new()
	bar.custom_minimum_size = Vector2(0, BOTTOMNAV_HEIGHT + _safe_bottom)
	_bottom_style = ThemeBuilder.panel_box(ThemeBuilder.COLOR_CARD,
		ThemeBuilder.COLOR_CHROME_LINE, 0, 0, 0)
	_bottom_style.set_border_width_all(0)
	_bottom_style.border_width_top = 1
	_bottom_style.border_color = ThemeBuilder.COLOR_CHROME_LINE
	_bottom_style.content_margin_left = 4
	_bottom_style.content_margin_right = 4
	_bottom_style.content_margin_top = 4
	_bottom_style.content_margin_bottom = 4 + _safe_bottom
	bar.add_theme_stylebox_override("panel", _bottom_style)

	var row := ThemeBuilder.hbox(4)
	bar.add_child(row)
	for entry in BOTTOM_NAV:
		var item: Dictionary = entry
		var key := String(item["key"])
		var button := ThemeBuilder.button("")
		# 上下各 4px 内边距，净高精确等于 BOTTOMNAV_HEIGHT
		button.custom_minimum_size = Vector2(0, BOTTOMNAV_HEIGHT - 8)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_stylebox_override("normal", _nav_style(false))
		button.add_theme_stylebox_override("hover", _nav_style(false))
		button.add_theme_stylebox_override("pressed", _nav_style(true))
		button.pressed.connect(_on_bottom_nav_pressed.bind(key))
		ThemeBuilder.silence_button_click(button)
		row.add_child(button)
		_nav_buttons[key] = button

		var column := VBoxContainer.new()
		button.add_child(column)
		column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		column.alignment = BoxContainer.ALIGNMENT_CENTER
		column.add_theme_constant_override("separation", 4)
		column.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var initial_display := _nav_display_for(key, false, String(item["label"]))
		var initial_texture: Texture2D = initial_display.get("texture", null)
		var icon := ThemeBuilder.icon_rect(initial_texture, NAV_ICON_SIZE)
		# 五枚图标统一 24×24 方框：忽略原图尺寸、等比居中，父容器同一居中对齐。
		# 纹理统一经 IconLibrary 归一化，PNG 与 SVG 都使用同一画布留白。
		icon.custom_minimum_size = Vector2(NAV_ICON_SIZE, NAV_ICON_SIZE)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.pivot_offset = Vector2(NAV_ICON_SIZE, NAV_ICON_SIZE) * 0.5
		var base_scale := 1.0
		icon.set_meta("nav_base_scale", base_scale)
		icon.scale = Vector2.ONE
		column.add_child(icon)
		var caption := ThemeBuilder.label(String(item["label"]), ThemeBuilder.FONT_BODY,
			ThemeBuilder.COLOR_TEXT_DIM)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(caption)
		_nav_icons[key] = icon
		_nav_labels[key] = caption
		if key == "farm":
			# 灵田成熟：图标右上角 8×8 墨绿点；挂在图标上不改变底栏布局宽度
			_farm_nav_dot = ThemeBuilder.color_dot(ThemeBuilder.COLOR_JADE_DARK, 8.0)
			_farm_nav_dot.name = "FarmMatureDot"
			_farm_nav_dot.set_anchors_preset(Control.PRESET_TOP_RIGHT)
			_farm_nav_dot.offset_left = -8
			_farm_nav_dot.offset_right = 0
			_farm_nav_dot.offset_top = -2
			_farm_nav_dot.offset_bottom = 6
			_farm_nav_dot.scale = Vector2.ONE / maxf(icon.scale.x, 0.01)
			_farm_nav_dot.visible = false
			icon.add_child(_farm_nav_dot)
		elif key == "character":
			# 可渡劫：道身图标右上角 8×8 鎏金点，不改变底栏布局宽度
			_character_nav_dot = ThemeBuilder.color_dot(ThemeBuilder.COLOR_TEXT_GOLD, 8.0)
			_character_nav_dot.name = "CharacterBreakDot"
			_character_nav_dot.set_anchors_preset(Control.PRESET_TOP_RIGHT)
			_character_nav_dot.offset_left = -8
			_character_nav_dot.offset_right = 0
			_character_nav_dot.offset_top = -2
			_character_nav_dot.offset_bottom = 6
			_character_nav_dot.scale = Vector2.ONE / maxf(icon.scale.x, 0.01)
			_character_nav_dot.visible = false
			icon.add_child(_character_nav_dot)

		# 圆点组：同一百艺多槽并排多枚槽位色圆点（HBox 容器，refresh 时重建子点）
		var dot := HBoxContainer.new()
		dot.add_theme_constant_override("separation", 2)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.alignment = BoxContainer.ALIGNMENT_CENTER
		dot.anchor_left = 0.5
		dot.anchor_right = 0.5
		dot.anchor_top = 0.0
		dot.anchor_bottom = 0.0
		dot.offset_left = 4.0
		dot.offset_right = 36.0
		dot.offset_top = 6.0
		dot.offset_bottom = 14.0
		dot.visible = false
		button.add_child(dot)
		_nav_dots[key] = dot
	return bar


func _nav_display_for(nav_key: String, active: bool,
		default_caption: String) -> Dictionary:
	var current: Dictionary = NAV_DYNAMIC.get(_current_key, {})
	if active and not current.is_empty() \
			and String(current.get("group", "")) == nav_key:
		return {
			"texture": _page_icon_texture(_current_key),
			"caption": String(current.get("caption", default_caption)),
		}
	return {
		"texture": _page_icon_texture(nav_key),
		"caption": default_caption,
	}


## 唯一图标解析入口：任何页面入口都通过此函数拿到同一份归一化纹理
func _page_icon_texture(page_key: String) -> Texture2D:
	var icon_key := String(PAGE_ICON_KEYS.get(page_key, "gear_array"))
	var primary := ThemeBuilder.hex(ThemeBuilder.COLOR_JADE_DARK)
	var accent := ThemeBuilder.hex(ThemeBuilder.COLOR_JADE)
	var raw: Texture2D
	if icon_key.begins_with("skill_"):
		raw = IconLibrary.get_skill_icon(page_key)
	elif icon_key == "root_dynamic":
		raw = IconLibrary.get_icon(SpiritRootSystem.element_icon(), primary, accent)
	elif icon_key == "natal_dynamic":
		var embryo_id := str(NatalArtifactSystem.get_state().get("embryo_id", ""))
		if embryo_id != "":
			raw = IconLibrary.get_icon(NatalArtifactSystem.embryo_icon(embryo_id),
				primary, accent)
		else:
			raw = IconLibrary.get_icon("ui_slot_natal", primary, accent)
	elif icon_key == "nav_market":
		raw = IconLibrary.get_nav_icon("market")
	elif icon_key == "nav_dao_bold":
		raw = IconLibrary.get_icon(icon_key, primary, accent)
	elif icon_key.begins_with("nav_"):
		raw = IconLibrary.get_nav_icon(icon_key.substr(4))
	else:
		raw = IconLibrary.get_icon(icon_key, primary, accent)
	return IconLibrary.get_normalized_icon("page_icon|%s|%s" % [page_key, icon_key], raw)


func _nav_style(active: bool) -> StyleBoxFlat:
	var box := ThemeBuilder.panel_box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 0, 0)
	box.set_border_width_all(0)
	box.content_margin_top = 4
	box.content_margin_bottom = 4
	if active:
		box.bg_color = ThemeBuilder.COLOR_JADE_SOFT
		box.border_color = ThemeBuilder.COLOR_JADE
		box.border_width_top = 2
	return box


func _build_fx_layer() -> void:
	_ink_vfx = InkVfxLayer.new()
	# 只压在主内容区之上：抽屉(30)/浮层(40)/弹窗(50)/启动层(100) 必须完整遮住它
	_ink_vfx.z_index = InkVfxLayer.Z_INDEX
	add_child(_ink_vfx)


# ---------------------------------------------------------------- 全局产出飘字

## 后台挂机产出统一从顶栏「运行状态胶囊」正下方偏右飘出，不再压住页面内容。
## 仅当前正在查看的技能页才飘字：切页后后台产线只由顶栏胶囊提示。
## 飘字为单色绘制：句中出现材料/灵种名时整条按其品阶色飘出（凡灰~神赤金）
func _grade_tint_for_text(text_value: String) -> Color:
	var best := Color(0, 0, 0, 0)
	var best_len := 0
	for key in DataRegistry.items.keys():
		var item = DataRegistry.get_item(String(key))
		if item == null:
			continue
		var grade: Dictionary = DataRegistry.get_material_grade(String(key))
		if grade.is_empty():
			continue
		var item_name: String = item.display_name
		if text_value.contains(item_name) and item_name.length() > best_len:
			best_len = item_name.length()
			best = ThemeBuilder.get_material_grade_color(int(grade["tier"]))
	return best


func _on_floating_text(slot: int, text_value: String, color: Color) -> void:
	if _ink_vfx == null or _active_capsule == null or text_value.is_empty():
		return
	var tint := _grade_tint_for_text(text_value)
	if tint.a > 0.0:
		color = tint
	# 抽屉整层遮住内容区时，底层飘字完全不可见，直接跳过
	if _drawer_open:
		return
	# 百艺页由卡片自身在图标上方飘字，避免顶栏与卡片重复
	if SKILL_PANEL_KEYS.has(_current_key):
		return
	if not _floats_allowed_for(slot):
		return
	var capsule := _active_capsule.get_global_rect()
	var topbar_end := _topbar.get_global_rect().end.y
	var anchor_y := maxf(capsule.end.y + 8.0, topbar_end + FLOAT_TOP_GAP)
	var anchor := Vector2(capsule.end.x, anchor_y)
	_ink_vfx.play_float(anchor, text_value, color, 14, false)


func _floats_allowed_for(slot: int) -> bool:
	var action_id := GameState.get_active_action(slot)
	if action_id.is_empty():
		return false
	var action := DataRegistry.get_action(action_id)
	if action == null:
		return false
	return _current_key == action.skill_id


## 立即清场：切页瞬间不再残留上一页的产出飘字
func _clear_floats() -> void:
	if _ink_vfx != null:
		_ink_vfx.clear_all()


func _build_toast() -> void:
	_toast_layer = MarginContainer.new()
	add_child(_toast_layer)
	# 操作反馈必须压住通用 BottomSheet(40)，但让位离线报告(50)与冲突仲裁(60)
	_toast_layer.z_index = 45
	_toast_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_toast_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_layer.add_theme_constant_override("margin_left", 16)
	_toast_layer.add_theme_constant_override("margin_right", 16)
	_toast_layer.add_theme_constant_override("margin_bottom", int(BOTTOMNAV_HEIGHT + _safe_bottom + 12.0))
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_END
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_layer.add_child(column)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(row)

	_toast_panel = PanelContainer.new()
	_toast_panel.add_theme_stylebox_override("panel",
		ThemeBuilder.panel_box(ThemeBuilder.COLOR_CARD, ThemeBuilder.COLOR_JADE, 10, 1, 14))
	_toast_panel.modulate.a = 0.0
	_toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_panel.clip_contents = true
	row.add_child(_toast_panel)
	_toast_label = ThemeBuilder.label("", ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_PRIMARY)
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_toast_label.custom_minimum_size = Vector2(0, 0)
	ThemeBuilder.apply_font_size(_toast_label, ThemeBuilder.FONT_CAPTION)
	_toast_panel.add_child(_toast_label)


## 短切后台静默补算：顶栏下方轻量提示条
func _build_settle_banner() -> void:
	_settle_banner = PanelContainer.new()
	add_child(_settle_banner)
	_settle_banner.z_index = 15
	_settle_banner.anchor_left = 0.5
	_settle_banner.anchor_right = 0.5
	_settle_banner.anchor_top = 0.0
	_settle_banner.anchor_bottom = 0.0
	_settle_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_settle_banner.grow_vertical = Control.GROW_DIRECTION_END
	_settle_banner.offset_top = TOPBAR_HEIGHT + _safe_top + 6.0
	_settle_banner.offset_bottom = TOPBAR_HEIGHT + _safe_top + 6.0
	_settle_banner.add_theme_stylebox_override("panel",
		ThemeBuilder.panel_box(ThemeBuilder.COLOR_CARD, ThemeBuilder.COLOR_JADE, 10, 1, 12))
	_settle_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_settle_banner.clip_contents = true
	_settle_banner.modulate.a = 0.0
	_settle_label = ThemeBuilder.label("", ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_JADE)
	_settle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_settle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_settle_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_settle_label.custom_minimum_size = Vector2(0, 0)
	ThemeBuilder.apply_font_size(_settle_label, ThemeBuilder.FONT_CAPTION)
	_settle_banner.add_child(_settle_label)


func _on_resume_settled(seconds: float) -> void:
	if _settle_banner == null:
		return
	var settle_text := "神游片刻，已纳 %s 闭关所得" % GameFormulas.format_duration(seconds)
	var max_w := minf(get_viewport_rect().size.x - 32.0, 460.0)
	ThemeBuilder.fit_wrapped_label(_settle_label, settle_text, _settle_banner, 40.0, max_w)
	if _settle_tween != null and _settle_tween.is_valid():
		_settle_tween.kill()
	# 与顶部提示气泡同款：轻落淡入 → 停留 → 上飘淡出
	var base_y := _settle_banner.position.y
	_settle_banner.modulate.a = 0.0
	_settle_banner.position.y = base_y - 10.0
	_settle_tween = create_tween()
	_settle_tween.set_parallel(true)
	_settle_tween.tween_property(_settle_banner, "modulate:a", 1.0, 0.16) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_settle_tween.tween_property(_settle_banner, "position:y", base_y, 0.16) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_settle_tween.chain().tween_interval(2.4)
	_settle_tween.chain().tween_property(_settle_banner, "position:y", base_y - 12.0, 0.20) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_settle_tween.parallel().tween_property(_settle_banner, "modulate:a", 0.0, 0.20)


# ---------------------------------------------------------------- 抽屉

func _build_drawer() -> void:
	_drawer_layer = Control.new()
	add_child(_drawer_layer)
	_drawer_layer.z_index = 30
	_drawer_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_drawer_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_drawer_layer.visible = false

	_drawer_scrim = ColorRect.new()
	_drawer_scrim.color = Color(0.12, 0.10, 0.08, 0.42)
	_drawer_layer.add_child(_drawer_scrim)
	_drawer_scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_drawer_scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	_drawer_scrim.modulate.a = 0.0
	_drawer_scrim.gui_input.connect(_on_drawer_scrim_input)

	_drawer = PanelContainer.new()
	_drawer_layer.add_child(_drawer)
	_drawer.anchor_left = 0.0
	_drawer.anchor_right = 0.0
	_drawer.anchor_top = 0.0
	_drawer.anchor_bottom = 1.0
	_drawer.offset_left = -DRAWER_WIDTH
	_drawer.offset_right = 0.0
	_drawer.offset_top = 0.0
	_drawer.offset_bottom = 0.0
	var style := ThemeBuilder.panel_box(ThemeBuilder.COLOR_CHROME,
		ThemeBuilder.COLOR_BORDER, 0, 0, 0)
	style.set_border_width_all(0)
	style.border_width_right = 1
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 14 + _safe_top
	style.content_margin_bottom = 14 + _safe_bottom
	_drawer.add_theme_stylebox_override("panel", style)

	var box := ThemeBuilder.vbox(8)
	_drawer.add_child(box)
	var head := ThemeBuilder.hbox(8)
	box.add_child(head)
	head.add_child(ThemeBuilder.title_label("问道总纲", ThemeBuilder.FONT_PAGE_TITLE))
	head.add_child(ThemeBuilder.expander())
	_drawer_close_button = ThemeBuilder.icon_button("✕", 40)
	_drawer_close_button.pressed.connect(_close_drawer)
	ThemeBuilder.silence_button_click(_drawer_close_button)
	head.add_child(_drawer_close_button)

	box.add_child(ThemeBuilder.separator(1, ThemeBuilder.COLOR_BORDER))

	_drawer_scroll = ThemeBuilder.scroll_container()
	_configure_nav_scroll(_drawer_scroll)
	_drawer_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(_drawer_scroll)

	# 导航内容只构建一次，窄屏挂抽屉、宽屏 reparent 到左侧常驻栏
	_nav_content = _build_nav_content()
	_drawer_scroll.add_child(_nav_content)
	# 构建晚于 _build_layout 的首轮布局：此处按当前档位再归位一次，
	# 否则 MEDIUM / WIDE 首帧会把导航留在抽屉里，左侧常驻栏为空。
	_apply_nav_mode(_layout_mode)


func _build_nav_content() -> VBoxContainer:
	var list := ThemeBuilder.vbox(4)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for group in DRAWER_GROUPS:
		var group_dict: Dictionary = group
		list.add_child(ThemeBuilder.spacer(6))
		var group_label := ThemeBuilder.label(String(group_dict["title"]),
			ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_DIM)
		ThemeBuilder.apply_brush_kai(group_label)
		list.add_child(group_label)
		var items: Array = group_dict.get("items", [])
		for key_value in items:
			var key := String(key_value)
			list.add_child(_make_drawer_item(key, _drawer_label(key), ""))

	list.add_child(ThemeBuilder.spacer(8))
	list.add_child(ThemeBuilder.separator(1, ThemeBuilder.COLOR_BORDER))
	# 三才图例按已解锁槽位数动态生成（1 主修 / 2 +分神 / 3 +化身）
	_drawer_legend = ThemeBuilder.hbox(6)
	_drawer_legend.alignment = BoxContainer.ALIGNMENT_CENTER
	list.add_child(_drawer_legend)
	_refresh_drawer_legend()
	# 与 ThemeBuilder.prepare_touch 对齐：分组标题、分隔线、图例等装饰节点不吞滑动事件。
	# 该函数遇到 BaseButton 会直接返回，故导航按钮的 mouse_filter 在 _make_drawer_item 内单独设为 PASS。
	ThemeBuilder.prepare_touch(list)
	return list


## 三才图例：按解锁槽位数渲染「● 主修 ● 分神 ● 化身」（点色走 slot_dot_color）
func _refresh_drawer_legend() -> void:
	if _drawer_legend == null:
		return
	for child in _drawer_legend.get_children():
		_drawer_legend.remove_child(child)
		child.queue_free()
	for slot in range(GameState.get_max_action_slots()):
		if slot > 0:
			var gap := Control.new()
			gap.custom_minimum_size = Vector2(10, 0)
			gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_drawer_legend.add_child(gap)
		_drawer_legend.add_child(ThemeBuilder.color_dot(
			ThemeBuilder.slot_dot_color(slot), 8.0))
		var legend_label := ThemeBuilder.label(GameState.get_slot_text(slot, "name"),
			ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_DIM)
		ThemeBuilder.apply_brush_kai(legend_label)
		_drawer_legend.add_child(legend_label)


func _make_drawer_item(target_key: String, label_text: String, right_text: String) -> Button:
	var button := ThemeBuilder.button("")
	button.custom_minimum_size = Vector2(0, 46)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# 点击触发 + 拖拽冒泡：PASS 让按钮仍收点击，同时把滑动手势继续传给外层 ScrollContainer
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.focus_mode = Control.FOCUS_NONE
	# 松手才触发，按下过程不切页、不收起抽屉
	button.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	button.gui_input.connect(_on_nav_button_gui_input.bind(button))
	button.pressed.connect(_on_drawer_item_pressed.bind(target_key))
	ThemeBuilder.silence_button_click(button)
	var deco := ThemeBuilder.decorate_button(button, label_text, right_text,
		Color(0, 0, 0, 0), _drawer_icon(target_key))
	# 图标 / 标题 / 等级 / 运行圆点：全部 IGNORE，避免子控件抢走手势
	_force_ignore_descendants(button)
	deco["button"] = button
	_drawer_entries[target_key] = deco
	return button


## 导航滚动容器的统一参数（抽屉与左侧常驻栏共用，reparent 后仍有效）
func _configure_nav_scroll(scroll: ScrollContainer) -> void:
	if scroll == null:
		return
	# 12px 死区：手指抖动不抢点击，明确位移才转入滚动
	scroll.scroll_deadzone = NAV_SCROLL_DEADZONE
	scroll.follow_focus = false
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP


## 按钮内部的装饰节点一律不参与命中测试，保证手势全部落到按钮本体
func _force_ignore_descendants(node: Node) -> void:
	for child in node.get_children():
		var ctrl := child as Control
		if ctrl != null:
			ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_force_ignore_descendants(child)


## 导航按钮手势守卫：位移超过死区即标记为「拖动」，
## 松手时 Button 仍会派发 pressed，由 _on_drawer_item_pressed 读标记把这次点击吞掉。
## 注意：Button 的 gui_input 内部逻辑在信号之后执行，故「按下中」标记单独维护，
## 松手时只清 active、不清 guard，否则 pressed 会读不到守卫而误切页。
func _on_nav_button_gui_input(event: InputEvent, button: Button) -> void:
	if button == null:
		return
	var touch := event as InputEventScreenTouch
	if touch != null:
		_begin_or_end_nav_press(button, touch.pressed, touch.position)
		return
	var drag := event as InputEventScreenDrag
	if drag != null:
		_mark_nav_drag(button, drag.position)
		return
	var mouse_button := event as InputEventMouseButton
	if mouse_button != null and mouse_button.button_index == MOUSE_BUTTON_LEFT:
		_begin_or_end_nav_press(button, mouse_button.pressed, mouse_button.position)
		return
	var motion := event as InputEventMouseMotion
	if motion != null:
		_mark_nav_drag(button, motion.position)


func _begin_or_end_nav_press(button: Button, pressed: bool, position: Vector2) -> void:
	if pressed:
		button.set_meta(NAV_PRESS_ORIGIN_META, position)
		button.set_meta(NAV_PRESS_ACTIVE_META, true)
		button.set_meta(NAV_DRAG_GUARD_META, false)
	else:
		button.set_meta(NAV_PRESS_ACTIVE_META, false)


## 仅在「按下中」判定位移，避免鼠标悬停/滑过时把旧原点算成拖动
func _mark_nav_drag(button: Button, position: Vector2) -> void:
	if not bool(button.get_meta(NAV_PRESS_ACTIVE_META, false)):
		return
	if bool(button.get_meta(NAV_DRAG_GUARD_META, false)):
		return
	var origin: Vector2 = button.get_meta(NAV_PRESS_ORIGIN_META, Vector2.INF)
	if origin == Vector2.INF:
		return
	if position.distance_to(origin) > NAV_DRAG_LIMIT:
		button.set_meta(NAV_DRAG_GUARD_META, true)


func _drawer_icon(key: String) -> Texture2D:
	return _page_icon_texture(key)


func _drawer_label(key: String) -> String:
	match key:
		"farm":
			return "洞府灵田"
		"shop":
			return "仙坊阁"
		"bounty":
			return "仙盟悬赏"
		"mail":
			return "仙盟传书"
		"technique":
			return "藏经阁"
		"natal_artifact":
			return "本命法宝"
		"fishing_tea":
			return "灵潭清茗"
		"five_elements":
			return "五行法则"
		"spirit_root":
			return "灵根洗髓"
		"codex":
			return "万象玉简"
		"tower":
			return "镇魔塔"
		"leaderboard":
			return "天道榜"
		"tribulation":
			return "引动天劫"
		"character":
			return "修士道身"
		"inventory":
			return "储物袋"
		"combat":
			return "秘境历练"
		"settings":
			return "设置与仙籍"
		_:
			var skill_name := GameState.get_skill_display_name(key).strip_edges()
			return skill_name if skill_name != "" and skill_name != key else "未名卷页"


func _drawer_item_style(active: bool) -> StyleBoxFlat:
	var box := ThemeBuilder.panel_box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 8, 0, 8)
	box.set_border_width_all(0)
	box.content_margin_top = 4
	box.content_margin_bottom = 4
	if active:
		box.bg_color = ThemeBuilder.COLOR_JADE_SOFT
		box.border_color = ThemeBuilder.COLOR_JADE
		box.border_width_left = 3
	return box


func _open_drawer() -> void:
	if _drawer_open:
		return
	if AudioManager != null:
		AudioManager.play_paper()
	_refresh_drawer()
	_drawer_open = true
	# 抽屉盖住内容区后，底层的飘字/笔触全部挂起并回收，避免穿透与无效绘制
	if _ink_vfx != null:
		_ink_vfx.set_suppressed(true)
	_drawer_layer.visible = true
	_drawer_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_drawer.offset_left = -DRAWER_WIDTH
	_drawer.offset_right = 0.0
	_drawer_scrim.modulate.a = 0.0
	_kill_drawer_tween()
	_drawer_tween = create_tween()
	_drawer_tween.set_parallel(true)
	_drawer_tween.tween_property(_drawer, "offset_left", 0.0, 0.22).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	_drawer_tween.tween_property(_drawer, "offset_right", DRAWER_WIDTH, 0.22).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	_drawer_tween.tween_property(_drawer_scrim, "modulate:a", 1.0, 0.22)


func _close_drawer(play_sound: bool = true) -> void:
	if not _drawer_open:
		return
	if play_sound and AudioManager != null:
		AudioManager.play_paper()
	_drawer_open = false
	_kill_drawer_tween()
	_drawer_tween = create_tween()
	_drawer_tween.set_parallel(true)
	_drawer_tween.tween_property(_drawer, "offset_left", -DRAWER_WIDTH, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_drawer_tween.tween_property(_drawer, "offset_right", 0.0, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_drawer_tween.tween_property(_drawer_scrim, "modulate:a", 0.0, 0.18)
	_drawer_tween.chain().tween_callback(_finish_close_drawer)


func _finish_close_drawer() -> void:
	_drawer_layer.visible = false
	_drawer_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _ink_vfx != null:
		_ink_vfx.set_suppressed(false)


func _kill_drawer_tween() -> void:
	if _drawer_tween != null and _drawer_tween.is_valid():
		_drawer_tween.kill()


func _toggle_drawer() -> void:
	if _drawer_open:
		_close_drawer()
	else:
		_open_drawer()


func _on_drawer_scrim_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_close_drawer()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_close_drawer()


func _on_drawer_item_pressed(target_key: String) -> void:
	# 本次手势已被判定为滑动：Button 松手仍会派发 pressed，这里吞掉，避免误切页/误收抽屉
	var entry: Dictionary = _drawer_entries.get(target_key, {})
	var nav_button: Button = entry.get("button", null)
	if nav_button != null and bool(nav_button.get_meta(NAV_DRAG_GUARD_META, false)):
		nav_button.set_meta(NAV_DRAG_GUARD_META, false)
		return
	# 点击当前页：静默，不关抽屉也不重复切页
	if target_key == _current_key:
		return
	if AudioManager != null:
		AudioManager.play_tap()
	# 条目点击本身已有轻叩；收起抽屉不再叠一层翻页声
	_close_drawer(false)
	_show_panel(target_key)


func _refresh_drawer() -> void:
	if _drawer_entries.is_empty():
		return
	var cap := GameState.get_skill_level_cap()

	for skill_id in SKILL_LEVEL_KEYS:
		var deco: Dictionary = _drawer_entries.get(skill_id, {})
		if deco.is_empty():
			continue
		var level := GameState.get_skill_level(skill_id)
		var left_label: Label = deco.get("left", null)
		if left_label != null:
			left_label.text = _drawer_label(skill_id)
		var level_label: Label = deco["right"]
		level_label.text = "%d/%d 重" % [level, cap]
		# 满级技能用玉青色高亮，与未满级项拉开层次
		level_label.add_theme_color_override("font_color",
			ThemeBuilder.COLOR_JADE if level >= cap else ThemeBuilder.COLOR_TEXT_DIM)
		# 运行圆点：每个占用槽位一枚（主修玉青/分神鎏金/化身紫霞绛），多槽并排
		var dot: Container = deco["dot"]
		var dot_colors: Array = []
		if skill_id == "combat":
			if CombatEngine != null and CombatEngine.is_active():
				dot_colors.append(ThemeBuilder.COLOR_CINNABAR)
		else:
			for slot in range(GameState.SLOT_COUNT):
				var slot_action := GameState.get_active_action(slot)
				if slot_action == "":
					continue
				var slot_act := DataRegistry.get_action(slot_action)
				if slot_act != null and slot_act.skill_id == skill_id:
					dot_colors.append(ThemeBuilder.slot_dot_color(slot))
		ThemeBuilder.set_row_dots(dot, dot_colors)

	var farm_deco: Dictionary = _drawer_entries.get("farm", {})
	if not farm_deco.is_empty():
		var farm_right: Label = farm_deco["right"]
		farm_right.text = "%d/%d 田" % [FarmManager.get_unlocked_count(), FarmManager.get_plot_count()]
		var farm_dot: Container = farm_deco["dot"]
		var mature := FarmManager.has_mature()
		ThemeBuilder.set_row_dots(farm_dot,
			[ThemeBuilder.COLOR_JADE] if mature else [])

	var shop_deco: Dictionary = _drawer_entries.get("shop", {})
	if not shop_deco.is_empty():
		var shop_right: Label = shop_deco["right"]
		shop_right.text = "灵石 %s" % GameFormulas.format_num(
			float(GameState.get_item_count(DataRegistry.SPIRIT_STONE)))

	# 仙盟悬赏：仅解锁后统计可直接交付数量；未解锁仍由下方阶梯门槛覆盖
	var bounty_deco: Dictionary = _drawer_entries.get("bounty", {})
	if not bounty_deco.is_empty():
		var ready_count := 0
		if _is_feature_unlocked("bounty"):
			for bounty_value in GameState.active_bounties:
				if _bounty_can_submit(bounty_value as Dictionary):
					ready_count += 1
		var bounty_right: Label = bounty_deco["right"]
		bounty_right.text = "贡献 %s" % GameFormulas.format_num(float(GameState.alliance_points)) \
			if ready_count == 0 else "×%d" % ready_count
		bounty_right.add_theme_color_override("font_color",
			ThemeBuilder.COLOR_JADE if ready_count > 0 else ThemeBuilder.COLOR_TEXT_DIM)
		var bounty_dot: Container = bounty_deco["dot"]
		ThemeBuilder.set_row_dots(bounty_dot,
			[ThemeBuilder.COLOR_JADE] if ready_count > 0 else [])

	var technique_deco: Dictionary = _drawer_entries.get("technique", {})
	if not technique_deco.is_empty():
		var tech_right: Label = technique_deco["right"]
		tech_right.text = "运转 %d/%d" % [GameState.equipped_techniques.size(),
			GameState.get_technique_slots()]

	var codex_deco: Dictionary = _drawer_entries.get("codex", {})
	if not codex_deco.is_empty():
		var codex_right: Label = codex_deco["right"]
		codex_right.text = "%d%%" % int(round(GameState.get_codex_percent() * 100.0))

	var tower_deco: Dictionary = _drawer_entries.get("tower", {})
	if not tower_deco.is_empty():
		var tower_right: Label = tower_deco["right"]
		tower_right.text = "%d 层" % GameState.tower_highest_floor
		var tower_salary_ready := _tower_salary_ready()
		var tower_dot: Container = tower_deco["dot"]
		ThemeBuilder.set_row_dots(tower_dot,
			[ThemeBuilder.COLOR_TEXT_GOLD] if tower_salary_ready else [])

	var trib_deco: Dictionary = _drawer_entries.get("tribulation", {})
	if not trib_deco.is_empty():
		var ready := _can_tribulate()
		var trib_right: Label = trib_deco["right"]
		trib_right.text = "可突破" if ready else ""
		trib_right.add_theme_color_override("font_color",
			ThemeBuilder.COLOR_AMBER if ready else ThemeBuilder.COLOR_TEXT_DIM)
		var trib_dot: Container = trib_deco["dot"]
		ThemeBuilder.set_row_dots(trib_dot,
			[ThemeBuilder.COLOR_AMBER] if ready else [])

	var mail_deco: Dictionary = _drawer_entries.get("mail", {})
	if not mail_deco.is_empty():
		var mail_count := _cloud_unread_count()
		var mail_right: Label = mail_deco["right"]
		mail_right.text = "%d 封" % mail_count if mail_count > 0 else ""
		mail_right.add_theme_color_override("font_color",
			ThemeBuilder.COLOR_CINNABAR if mail_count > 0 else ThemeBuilder.COLOR_TEXT_DIM)
		ThemeBuilder.set_row_dots(mail_deco["dot"],
			[ThemeBuilder.COLOR_CINNABAR] if mail_count > 0 else [])

	var natal_deco: Dictionary = _drawer_entries.get("natal_artifact", {})
	if not natal_deco.is_empty():
		var natal_state := NatalArtifactSystem.get_state()
		var natal_level := int(natal_state.get("level", 1))
		var natal_right: Label = natal_deco["right"]
		if str(natal_state.get("embryo_id", "")) == "":
			natal_right.text = "未凝练"
			natal_right.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT_DIM)
		else:
			natal_right.text = "%s %d重" % [NatalArtifactSystem.tier_name(natal_level), natal_level]
			natal_right.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT_JADE)

	var tea_deco: Dictionary = _drawer_entries.get("fishing_tea", {})
	if not tea_deco.is_empty():
		var tea_right: Label = tea_deco["right"]
		var tea_info := FishingTeaSystem.get_active_tea_info()
		var tea_name := str(tea_info.get("name", ""))
		if tea_name != "":
			tea_right.text = tea_name
			tea_right.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT_JADE)
		elif bool(FishingTeaSystem.get_state().get("fishing_active", false)):
			tea_right.text = "垂钓中"
			tea_right.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT_SECONDARY)
		else:
			tea_right.text = ""

	var law_deco: Dictionary = _drawer_entries.get("five_elements", {})
	if not law_deco.is_empty():
		var law_right: Label = law_deco["right"]
		law_right.text = "%d/25 重" % FiveElementsSystem.get_total_levels()
		law_right.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT_JADE)

	var settings_deco: Dictionary = _drawer_entries.get("settings", {})
	if not settings_deco.is_empty():
		var settings_right: Label = settings_deco["right"]
		settings_right.text = ""

	# 阶梯门槛：未达境界显示锁定标记；已达境界必须清掉旧标记并恢复解锁态摘要
	for key in FEATURE_UNLOCK_ORDER.keys():
		var feature_key := String(key)
		var feature_deco: Dictionary = _drawer_entries.get(feature_key, {})
		if feature_deco.is_empty():
			continue
		var feature_right: Label = feature_deco["right"]
		var feature_dot: Container = feature_deco["dot"]
		var lock_label := _feature_lock_label(feature_key)
		if not _is_feature_unlocked(feature_key):
			feature_right.text = lock_label
			feature_right.add_theme_color_override("font_color", ThemeBuilder.COLOR_AMBER)
			ThemeBuilder.set_row_dots(feature_dot, [ThemeBuilder.COLOR_AMBER])
			continue
		# 只有此前被锁文案占用时才清理，避免覆盖悬赏/镇魔塔等业务角标
		if feature_right.text == lock_label:
			feature_right.text = ""
			ThemeBuilder.set_row_dots(feature_dot, [])
		if feature_key == "spirit_root":
			feature_right.text = SpiritRootSystem.get_badge_text()
			feature_right.add_theme_color_override("font_color", ThemeBuilder.COLOR_JADE)
			ThemeBuilder.set_row_dots(feature_dot, [])

	# 当前页面高亮（玉青左竖条 + 描边）
	for key in _drawer_entries.keys():
		var deco: Dictionary = _drawer_entries[key]
		var button: Button = deco.get("button", null)
		if button == null:
			continue
		var active := String(key) == _current_key
		button.add_theme_stylebox_override("normal", _drawer_item_style(active))
		button.add_theme_stylebox_override("hover", _drawer_item_style(active))
		# 主标题与浅玉青底 / 左侧黛玉青竖条同色系；未选中回深墨正文色
		var title_label: Label = deco.get("left", null)
		if title_label != null:
			title_label.add_theme_color_override("font_color",
				ThemeBuilder.COLOR_JADE_DARK if active else ThemeBuilder.COLOR_TEXT_PRIMARY)
	_refresh_attention()


## 只算待办状态并更新角标，不重建抽屉；signature 去重避免修为信号反复改节点。
func _refresh_attention() -> void:
	_refresh_character_nav_dot()
	if _menu_attention_dot == null:
		return
	var unread := _cloud_unread_count()
	var bounty_ready := _bounty_ready_count() > 0
	var tower_ready := _tower_salary_ready()
	var trib_ready := _can_tribulate()
	var signature := "%d|%s|%s|%s" % [unread, bounty_ready, tower_ready, trib_ready]
	if signature == _attention_signature:
		return
	_attention_signature = signature
	if _realm_break_dot != null:
		_realm_break_dot.visible = trib_ready
	var trib_deco: Dictionary = _drawer_entries.get("tribulation", {})
	if not trib_deco.is_empty():
		var trib_right: Label = trib_deco["right"]
		trib_right.text = "可突破" if trib_ready else ""
		trib_right.add_theme_color_override("font_color",
			ThemeBuilder.COLOR_AMBER if trib_ready else ThemeBuilder.COLOR_TEXT_DIM)
		ThemeBuilder.set_row_dots(trib_deco["dot"],
			[ThemeBuilder.COLOR_AMBER] if trib_ready else [])
	if _menu_mail_badge != null:
		_menu_mail_badge.visible = unread > 0
	# 有未读数时保留朱砂数字印；其余待办用 8×8 聚合点，二者不叠压
	_menu_attention_dot.visible = unread <= 0 and (bounty_ready or tower_ready or trib_ready)
	# stats_changed 可能先于抽屉刷新到达（如刚通第 1 层 / 刚领俸禄），这里同步两点
	if _is_feature_unlocked("bounty"):
		var bounty_deco: Dictionary = _drawer_entries.get("bounty", {})
		if not bounty_deco.is_empty():
			ThemeBuilder.set_row_dots(bounty_deco["dot"],
				[ThemeBuilder.COLOR_JADE] if bounty_ready else [])
	if _is_feature_unlocked("tower"):
		var tower_deco: Dictionary = _drawer_entries.get("tower", {})
		if not tower_deco.is_empty():
			ThemeBuilder.set_row_dots(tower_deco["dot"],
				[ThemeBuilder.COLOR_TEXT_GOLD] if tower_ready else [])


func _bounty_ready_count() -> int:
	if not _is_feature_unlocked("bounty"):
		return 0
	var count := 0
	for bounty_value in GameState.active_bounties:
		if typeof(bounty_value) == TYPE_DICTIONARY \
				and _bounty_can_submit(bounty_value as Dictionary):
			count += 1
	return count


func _bounty_can_submit(bounty: Dictionary) -> bool:
	if BountyManager == null or not BountyManager.has_method("can_submit"):
		return false
	return bool(BountyManager.can_submit(bounty))


func _tower_salary_ready() -> bool:
	if not _is_feature_unlocked("tower") or GameState.tower_highest_floor < 1:
		return false
	if GameState == null or not GameState.has_method("can_claim_tower_salary"):
		return false
	return bool(GameState.can_claim_tower_salary())


# ---------------------------------------------------------------- 导航 / 面板

func _on_bottom_nav_pressed(nav_key: String) -> void:
	var active := _is_bottom_group_active(nav_key)
	if active:
		# 当前已在该底栏分组内：二次轻触展开快捷切换
		if AudioManager != null:
			AudioManager.play_tap()
		_open_quick_switch(nav_key, true)
		return
	if AudioManager != null:
		AudioManager.play_tap()
	match nav_key:
		"skills":
			_show_panel(_last_skill_key)
		"combat":
			_show_panel("combat")
		"tribulation":
			_show_panel("tribulation")
		"inventory":
			_show_panel("inventory")
		_:
			_show_panel(nav_key)


func _is_bottom_group_active(nav_key: String) -> bool:
	if nav_key == "skills":
		return SKILL_PANEL_KEYS.has(_current_key)
	var group: Dictionary = QUICK_SWITCH_GROUPS.get(nav_key, {})
	var items: Array = group.get("items", [])
	return items.has(_current_key)


## 底栏二次点击：2 列网格单手快捷切换当前分组页面
func _open_quick_switch(nav_key: String, silent: bool = true) -> void:
	var group: Dictionary = QUICK_SWITCH_GROUPS.get(nav_key, {})
	if group.is_empty():
		return
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for value in group.get("items", []):
		grid.add_child(_make_quick_switch_card(String(value)))
	ThemeBuilder.prepare_touch(grid)
	BottomSheet.show_text(String(group.get("title", "快捷切换")),
		[{"custom": grid}], ThemeBuilder.COLOR_TEXT_TITLE_GOLD)
	if not silent and AudioManager != null:
		AudioManager.play_tap()


func _make_quick_switch_card(key: String) -> Button:
	var unlocked := _is_feature_unlocked(key)
	var current := _current_key == key
	var button := ThemeBuilder.button("")
	button.custom_minimum_size = Vector2(0, 54)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bg := ThemeBuilder.COLOR_JADE_PAPER if current else ThemeBuilder.COLOR_CARD_DEEP
	var border := ThemeBuilder.COLOR_JADE_DARK if current else ThemeBuilder.COLOR_BORDER
	button.add_theme_stylebox_override("normal",
		ThemeBuilder.panel_box(bg, border, 8, 1, 8))
	button.add_theme_stylebox_override("hover",
		ThemeBuilder.panel_box(ThemeBuilder.COLOR_JADE_SOFT if current else bg,
			ThemeBuilder.COLOR_JADE_DARK if current else ThemeBuilder.COLOR_JADE, 8, 1, 8))
	button.add_theme_stylebox_override("pressed",
		ThemeBuilder.panel_box(ThemeBuilder.COLOR_JADE_SOFT, ThemeBuilder.COLOR_JADE_DARK, 8, 1, 8))
	var row := ThemeBuilder.hbox(8)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 8.0
	row.offset_right = -8.0
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(row)
	var icon := IconFrame.new()
	icon.setup(_drawer_icon(key), 32,
		ThemeBuilder.COLOR_JADE if unlocked else ThemeBuilder.COLOR_TEXT_MUTED,
		false, 24)
	row.add_child(icon)
	var info := ThemeBuilder.vbox(1)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.custom_minimum_size = Vector2(0, 0)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(info)
	var name_label := ThemeBuilder.label(_quick_switch_name(key), ThemeBuilder.FONT_BODY,
		ThemeBuilder.COLOR_TEXT_JADE if current else ThemeBuilder.COLOR_TEXT_PRIMARY)
	ThemeBuilder.apply_font_size(name_label, ThemeBuilder.FONT_BODY)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(name_label)
	var sub_label := ThemeBuilder.label(_quick_switch_status(key), ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_GOLD if not unlocked else ThemeBuilder.COLOR_TEXT_JADE)
	ThemeBuilder.apply_font_size(sub_label, ThemeBuilder.FONT_CAPTION)
	sub_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sub_label.clip_text = true
	sub_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	sub_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(sub_label)
	button.pressed.connect(func() -> void:
		if BottomSheet.instance != null and is_instance_valid(BottomSheet.instance):
			BottomSheet.instance.hide_sheet()
		_show_panel(key))
	return button


func _quick_switch_name(key: String) -> String:
	if QUICK_SWITCH_LABELS.has(key):
		return String(QUICK_SWITCH_LABELS[key])
	var label := _drawer_label(key).strip_edges()
	if label == "" or label == key:
		return "未名卷页"
	return label


func _quick_switch_status(key: String) -> String:
	if not _is_feature_unlocked(key):
		var lock_label := _feature_lock_label(key)
		return lock_label if lock_label != "" else "尚未开启"
	match key:
		"farm":
			return "%d/%d 田" % [FarmManager.get_unlocked_count(), FarmManager.PLOT_COUNT]
		"fishing_tea":
			var info := FishingTeaSystem.get_active_tea_info()
			if not info.is_empty():
				return String(info.get("name", ""))
			if FishingTeaSystem.is_fishing_active():
				return "垂钓中"
			return "灵潭静候"
		"shop":
			return "灵石 %s" % GameFormulas.format_num(
				float(GameState.get_item_count(DataRegistry.SPIRIT_STONE)))
		"mail":
			var unread := _cloud_unread_count()
			return "%d 封未读" % unread if unread > 0 else "暂无未读"
		"combat":
			return "战斗中" if CombatEngine.is_active() and not CombatEngine.is_tower_mode() \
				else "待命"
		"tower":
			return "%d 层" % GameState.tower_highest_floor
		"bounty":
			return "今日 %d/10" % BountyManager.daily_count()
		"leaderboard":
			return "三榜可览"
		"character":
			var realm := GameState.get_realm()
			return realm.display_name if realm != null else "修士道身"
		"spirit_root":
			return SpiritRootSystem.get_badge_text()
		"natal_artifact":
			var state := NatalArtifactSystem.get_state()
			var level := int(state.get("level", 1))
			if str(state.get("embryo_id", "")) == "":
				return "未凝练"
			return "%s %d重" % [NatalArtifactSystem.tier_name(level), level]
		"five_elements":
			return "%d/25 重" % FiveElementsSystem.get_total_levels()
		"technique":
			return "%d 槽功法" % GameState.get_technique_slots()
		"tribulation":
			return "可渡天劫" if _can_tribulate() else "尚未圆满"
		"inventory":
			return "%d 种物品" % GameState.inventory.size()
		"codex":
			return "%d%%" % int(round(GameState.get_codex_percent() * 100.0))
		"settings":
			return "自动存盘"
		_:
			var cap := GameState.get_skill_level_cap()
			return "%d/%d 重" % [GameState.get_skill_level(key), cap]


## 顶栏胶囊点击分流：按「总并发路数」统一判定
## （combat + 三槽百艺；>=2 一律灵动岛，==1 直达，==0 前往吐纳/渡劫）
func _on_capsule_pressed() -> void:
	var combat_active := 1 if CombatEngine.is_active() else 0
	var skill_count := GameState.get_running_slots().size()
	var total := combat_active + skill_count
	if total >= 2:
		if _island != null and _island.visible:
			_island.hide_island()
		else:
			_show_island()
		return
	if total == 1:
		if combat_active == 1:
			# 纯战斗：秘境 / 镇魔塔直达
			_show_panel("tower" if CombatEngine.tower_floor > 0 else "combat")
			return
		# 纯单路百艺：跳转对应百艺并聚焦定位动作卡
		for slot in range(GameState.SLOT_COUNT):
			var aid := GameState.get_active_action(slot)
			if aid == "":
				continue
			var act := DataRegistry.get_action(aid)
			if act != null:
				EventBus.navigate_to_source.emit({"type": "skill",
					"skill_id": act.skill_id, "action_id": aid})
			return
	# 全空闲：可渡天劫直达天劫页；其余（含真仙圆满已至巅峰）展开
	# 「三才静修」快捷启程灵岛，不再强行跳转吐纳
	if _can_tribulate():
		_show_panel("tribulation")
		return
	if _island != null and _island.visible:
		_island.hide_island()
	else:
		_show_island()


## 修为圆满且存在下一重天劫可渡（真仙圆满已至巅峰不算）
func _can_tribulate() -> bool:
	return GameState.is_cultivation_locked() and GameState.get_realm_requirement() > 0.0


## 灵动岛浮层：从状态胶囊位置弹性展开（懒创建，仅多槽并发时用到）
func _show_island() -> void:
	if _island == null:
		_island = DynamicIslandPopover.new()
		add_child(_island)
	_island.navigate_callback = _show_panel
	_island.show_at(_active_capsule.get_global_rect())




func _nav_kind(key: String) -> String:
	if key == "combat":
		return "combat"
	if key == "tribulation":
		return "tribulation"
	if key == "inventory":
		return "inventory"
	if key == "settings":
		return "settings"
	if key == "farm":
		return "farm"
	if key == "shop":
		return "shop"
	if key == "character":
		return "character"
	if key == "natal_artifact":
		return "natal_artifact"
	if key == "fishing_tea":
		return "fishing_tea"
	if key == "five_elements":
		return "five_elements"
	if key == "spirit_root":
		return "spirit_root"
	if key == "bounty":
		return "bounty"
	if key == "mail":
		return "mail"
	if key == "technique":
		return "technique"
	if key == "codex":
		return "codex"
	if key == "tower":
		return "tower"
	if key == "leaderboard":
		return "leaderboard"
	if DataRegistry.get_skill_meta(key).size() > 0:
		return "skill"
	return ""


func _create_panel(key: String) -> Control:
	match _nav_kind(key):
		"skill":
			var panel := SkillActionPanel.new()
			panel.skill_id = key
			return panel
		"combat":
			return CombatPanel.new()
		"tribulation":
			return TribulationPanel.new()
		"inventory":
			return InventoryPanel.new()
		"settings":
			return SettingsPanel.new()
		"farm":
			return FarmPanel.new()
		"shop":
			return ShopPanel.new()
		"character":
			return CHARACTER_PANEL_SCRIPT.new()
		"natal_artifact":
			return NATAL_ARTIFACT_PANEL_SCRIPT.new()
		"fishing_tea":
			return FISHING_TEA_PANEL_SCRIPT.new()
		"five_elements":
			return FIVE_ELEMENTS_PANEL_SCRIPT.new()
		"spirit_root":
			return SPIRIT_ROOT_PANEL_SCRIPT.new()
		"bounty":
			return BountyPanel.new()
		"mail":
			return MailPanel.new()
		"technique":
			return TechniquePanel.new()
		"codex":
			return CodexPanel.new()
		"tower":
			return TowerPanel.new()
		"leaderboard":
			return LeaderboardPanel.new()
		_:
			return null


func _show_panel(key: String) -> void:
	if key == _current_key:
		_refresh_nav()
		return
	_switch_bg(String(PAGE_BG.get(key, "peaceful")))
	if not _panels.has(key):
		var panel := _create_panel(key)
		if panel == null:
			return
		_panel_host.add_child(panel)
		panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_panels[key] = panel
	for panel_key in _panels.keys():
		var node: Control = _panels[panel_key]
		node.visible = String(panel_key) == key
		if node.visible:
			# 页面切入微动效（淡入 + 12px 上浮；内部自动重置缓存面板基准，狂点不漂移）
			ThemeBuilder.animate_page_enter(node)
	_current_key = key
	# 天道榜 / 仙盟传书仅打开面板时请求一次；面板内部负责手动刷新
	if (key == "leaderboard" or key == "mail") and _panels.has(key) \
			and (_panels[key] as Node).has_method("on_panel_opened"):
		(_panels[key] as Node).call("on_panel_opened")
	# 切页即清场：上一页技能的产出飘字不应跟到新页面
	_clear_floats()
	if SKILL_PANEL_KEYS.has(key):
		_last_skill_key = key
	_refresh_nav()
	# 侧边栏选中态必须与内容同帧刷新，不能等下一次库存/挂机信号
	_refresh_drawer()
	_refresh_topbar()


## 设置页「修行典籍」：打开万象玉简并直接切到典籍分页
func _on_codex_scripture_requested() -> void:
	if _drawer_open:
		_close_drawer()
	_show_panel("codex")
	var codex: Control = _panels.get("codex", null)
	if codex != null and codex.has_method("show_scripture_tab"):
		codex.call("show_scripture_tab")


## 缺料来源一键跳转
func _on_navigate_to_source(source: Dictionary) -> void:
	if source.is_empty():
		return
	if _drawer_open:
		_close_drawer()
	var type := String(source.get("type", ""))
	match type:
		"skill":
			var skill_id := String(source.get("skill_id", ""))
			if DataRegistry.get_skill_meta(skill_id).is_empty():
				return
			_show_panel(skill_id)
			var skill_panel: Control = _panels.get(skill_id, null)
			if skill_panel != null and skill_panel.has_method("focus_action"):
				skill_panel.focus_action(String(source.get("action_id", "")))
		"combat":
			_show_panel("combat")
			var combat_panel: Control = _panels.get("combat", null)
			if combat_panel != null and combat_panel.has_method("select_source"):
				combat_panel.select_source(String(source.get("zone_id", "")),
					String(source.get("enemy_id", "")))
		"farm":
			_show_panel("farm")
		"shop":
			_show_panel("shop")
			var shop_panel: Control = _panels.get("shop", null)
			if shop_panel != null and shop_panel.has_method("select_tab"):
				shop_panel.select_tab(String(source.get("tab", "gear")))
		"inventory_equipment":
			_show_panel("inventory")
			var inventory_panel: Control = _panels.get("inventory", null)
			if inventory_panel != null and inventory_panel.has_method("select_tab"):
				inventory_panel.select_tab(String(source.get("tab", "equipment")))


func _refresh_nav() -> void:
	var active_key := ""
	for entry in BOTTOM_NAV:
		var item: Dictionary = entry
		var key := String(item["key"])
		var active := _is_bottom_group_active(key)
		if active:
			active_key = key
		var button: Button = _nav_buttons.get(key, null)
		if button == null:
			continue
		button.add_theme_stylebox_override("normal", _nav_style(active))
		button.add_theme_stylebox_override("hover", _nav_style(active))
		button.add_theme_color_override("font_color",
			ThemeBuilder.COLOR_JADE if active else Color(ThemeBuilder.COLOR_TEXT_DIM, 0.72))
		var display := _nav_display_for(key, active, String(item.get("label", "")))
		var icon: TextureRect = _nav_icons.get(key, null)
		if icon != null:
			var texture_value: Variant = display.get("texture", null)
			if texture_value is Texture2D:
				icon.texture = texture_value
			icon.custom_minimum_size = Vector2(NAV_ICON_SIZE, NAV_ICON_SIZE)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			_set_nav_icon_filter(icon, active)
			if not active:
				_reset_nav_icon_scale(icon)
		var caption: Label = _nav_labels.get(key, null)
		if caption != null:
			caption.text = String(display.get("caption", String(item.get("label", ""))))
			ThemeBuilder.apply_font_size(caption, ThemeBuilder.FONT_BODY)
			caption.add_theme_color_override("font_color",
				ThemeBuilder.COLOR_JADE if active else Color(ThemeBuilder.COLOR_TEXT_DIM, 0.72))
	var farm_dot: Container = _nav_dots.get("farm", null)
	if farm_dot != null:
		farm_dot.visible = FarmManager.has_mature()
	_refresh_character_nav_dot()
	# 百艺分类运行圆点：0/1/2 每个占用槽位一枚对应色圆点，多槽并排
	for skill_id in SKILL_LEVEL_KEYS:
		var skill_dot: Container = _nav_dots.get(skill_id, null)
		if skill_dot == null:
			continue
		var dot_colors: Array = []
		for slot in range(GameState.SLOT_COUNT):
			var aid := GameState.get_active_action(slot)
			if aid == "":
				continue
			var act := DataRegistry.get_action(aid)
			if act != null and act.skill_id == skill_id:
				dot_colors.append(ThemeBuilder.slot_dot_color(slot))
		ThemeBuilder.set_row_dots(skill_dot, dot_colors)
	if _farm_nav_dot != null:
		_farm_nav_dot.visible = FarmManager.has_mature()
	if active_key != _nav_active_key:
		_nav_active_key = active_key
		if active_key != "":
			_pulse_nav_icon(active_key)


## 道身角标：修为圆满可渡劫时亮 8×8 鎏金点；不参与抽屉 signature 去重。
func _refresh_character_nav_dot() -> void:
	if _character_nav_dot != null:
		_character_nav_dot.visible = _can_tribulate()


## 激活图标保留原水墨色，未激活用暗灰褐水墨滤镜自然褪色
func _set_nav_icon_filter(icon: TextureRect, active: bool) -> void:
	var target := Color(1, 1, 1, 1) if active else Color(0.45, 0.43, 0.40, 0.65)
	if icon.modulate.is_equal_approx(target):
		return
	if icon.has_meta("nav_filter_tween"):
		var old: Variant = icon.get_meta("nav_filter_tween")
		if old is Tween and (old as Tween).is_valid():
			(old as Tween).kill()
	var tween := icon.create_tween()
	tween.tween_property(icon, "modulate", target, 0.12) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	icon.set_meta("nav_filter_tween", tween)


## 图标的基准缩放（单图视觉补偿），脉冲动画必须围绕它而非 1.0
func _nav_icon_base_scale(icon: TextureRect) -> float:
	return float(icon.get_meta("nav_base_scale", 1.0))


func _reset_nav_icon_scale(icon: TextureRect) -> void:
	if icon.has_meta("nav_pulse_tween"):
		var old: Variant = icon.get_meta("nav_pulse_tween")
		if old is Tween and (old as Tween).is_valid():
			(old as Tween).kill()
	var base := _nav_icon_base_scale(icon)
	icon.scale = Vector2(base, base)


func _pulse_nav_icon(key: String) -> void:
	var icon: TextureRect = _nav_icons.get(key, null)
	if icon == null:
		return
	_reset_nav_icon_scale(icon)
	icon.pivot_offset = icon.size * 0.5
	var base := _nav_icon_base_scale(icon)
	var tween := icon.create_tween()
	tween.tween_property(icon, "scale", Vector2(base, base) * 1.08, 0.05) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(icon, "scale", Vector2(base, base), 0.05) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	icon.set_meta("nav_pulse_tween", tween)


# ---------------------------------------------------------------- 顶栏刷新

func _get_page_title(key: String) -> String:
	if DataRegistry.get_skill_meta(key).size() > 0:
		return GameState.get_skill_display_name(key)
	match key:
		"tribulation":
			return "引动天劫"
		"inventory":
			return "储物袋"
		"character":
			return "道身"
		"settings":
			return "设置与仙籍"
		"farm":
			return "洞府灵田"
		"shop":
			return "仙坊阁"
		"bounty":
			return "仙盟悬赏"
		"mail":
			return "仙盟传书"
		"technique":
			return "藏经阁"
		"natal_artifact":
			return "本命法宝"
		"fishing_tea":
			return "灵潭清茗"
		"five_elements":
			return "五行法则"
		"spirit_root":
			return "灵根洗髓"
		"codex":
			return "万象玉简"
		"tower":
			return "镇魔塔"
		_:
			return "玉简问道"


func _refresh_all() -> void:
	_refresh_topbar()
	_refresh_nav()
	_refresh_drawer()


## 顶栏刷新最多约 10 次/秒，合并挂机与战斗的高频 stats 信号
func _refresh_topbar() -> void:
	var now := Time.get_ticks_msec()
	if now - _last_topbar_refresh_ms < 90:
		if not _topbar_refresh_pending:
			_topbar_refresh_pending = true
			get_tree().create_timer(0.09).timeout.connect(_flush_topbar_refresh)
		return
	_last_topbar_refresh_ms = now
	_do_refresh_topbar()


func _flush_topbar_refresh() -> void:
	_topbar_refresh_pending = false
	_last_topbar_refresh_ms = Time.get_ticks_msec()
	_do_refresh_topbar()


func _do_refresh_topbar() -> void:
	var realm := GameState.get_realm()
	var breakthrough_ready := GameState.is_cultivation_locked()
	if realm != null:
		_realm_label.text = _short_realm_name(realm)
		_realm_label.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT)
	_refresh_realm_seal()

	var requirement := GameState.get_realm_requirement()
	var ratio := 0.0
	if requirement > 0.0:
		ratio = clampf(GameState.cultivation_xp / requirement, 0.0, 1.0)
	var target_ratio := ratio if requirement > 0.0 else 1.0
	# 首次直设；运行时 0.22s EASE_OUT；突破后比例回落自动先满格再追新余值
	UiMotion.advance_progress(_cultivation_bar, target_ratio, 0.22)
	_cultivation_pct.visible = true
	if requirement <= 0.0:
		# 最高境界（大乘圆满）：进度条满格，不再显示无意义的 0%
		_cultivation_pct.text = "已至巅峰"
		_cultivation_pct.add_theme_color_override("font_color", ThemeBuilder.COLOR_AMBER)
	elif breakthrough_ready:
		_cultivation_pct.text = "可突破"
		_cultivation_pct.add_theme_color_override("font_color", ThemeBuilder.COLOR_CINNABAR)
	else:
		# 向下取整：99.6% 若四舍五入成 100%，会让玩家误以为已满却没晋升
		_cultivation_pct.text = "%d%%" % int(floor(ratio * 100.0))
		_cultivation_pct.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT)
	# 进度条：暖石轨道 + 玉青填充；可突破时切换朱砂/泥金
	var fill_color := ThemeBuilder.COLOR_CINNABAR if breakthrough_ready else ThemeBuilder.COLOR_JADE
	_cultivation_bar.add_theme_stylebox_override("fill",
		ThemeBuilder.panel_box(fill_color, fill_color, 2, 0, 0))
	_cultivation_bar.add_theme_stylebox_override("background",
		ThemeBuilder.panel_box(Color("#F6E3DE") if breakthrough_ready else Color("#E4DDD0"),
			Color(0, 0, 0, 0), 2, 0, 0))

	_set_stone_value(GameState.get_item_count(DataRegistry.SPIRIT_STONE), false)
	_refresh_capsule()
	_refresh_nav()
	_update_realm_pulse()
	_refresh_attention()


## 顶栏小境界名：朱砂印已显示大境界，这里固定输出 2 字（九层 / 初期 / 圆满），
## 避免「大乘圆满 · 飞升问道」这类长名在 450 窄屏 + 大字档下挤爆顶栏
func _short_realm_name(realm: RealmData) -> String:
	if realm == null:
		return ""
	match realm.tier:
		0:
			var index := clampi(realm.stage - 1, 0, DataRegistry.QI_STAGE_NAMES.size() - 1)
			return String(DataRegistry.QI_STAGE_NAMES[index])
		1, 2, 3, 4, 5, 6, 7:
			return String(["初期", "中期", "后期"][clampi(realm.stage - 1, 0, 2)])
		_:
			return "圆满"


func _refresh_realm_seal() -> void:
	if _realm_seal == null or _realm_seal_label == null:
		return
	var realm := GameState.get_realm()
	var tier := 0 if realm == null else realm.tier
	var prefix := "炼气"
	var style_type := "cinnabar"
	match tier:
		1:
			prefix = "筑基"
			style_type = "jade"
		2:
			prefix = "金丹"
			style_type = "gold"
		3:
			prefix = "元婴"
			style_type = "gold"
		4:
			prefix = "化神"
			style_type = "gold"
		5:
			prefix = "炼虚"
			style_type = "gold"
		6:
			prefix = "合体"
			style_type = "gold"
		7:
			prefix = "大乘"
			style_type = "gold"
		8:
			prefix = "真仙"
			style_type = "gold"
	_realm_seal_label.text = prefix
	var bg := ThemeBuilder.COLOR_CINNABAR
	var border := ThemeBuilder.COLOR_CINNABAR
	if style_type == "gold":
		bg = ThemeBuilder.COLOR_AMBER
		border = ThemeBuilder.COLOR_AMBER
	elif style_type == "jade":
		bg = ThemeBuilder.COLOR_JADE
		border = ThemeBuilder.COLOR_JADE
	_realm_seal.add_theme_stylebox_override("panel",
		ThemeBuilder.panel_box(bg, border, 3, 1, 4))
	# 渡劫提示与境界印共存：玩家始终能看到当前大境界
	_realm_seal.visible = true


## 处于境界瓶颈且修为 100% 时，境界区域脉冲高亮
func _update_realm_pulse() -> void:
	if _realm_panel == null or _realm_style == null:
		return
	var ready := GameState.is_cultivation_locked()
	if ready:
		_realm_style.bg_color = ThemeBuilder.COLOR_GOLD_SOFT
		_realm_style.border_color = ThemeBuilder.COLOR_AMBER
		_realm_style.set_border_width_all(1)
		if _pulse_tween == null or not _pulse_tween.is_valid():
			_pulse_tween = create_tween().set_loops()
			_pulse_tween.tween_property(_realm_panel, "modulate:a", 0.6, 0.8)
			_pulse_tween.tween_property(_realm_panel, "modulate:a", 1.0, 0.8)
	else:
		_realm_style.bg_color = ThemeBuilder.COLOR_CARD
		_realm_style.border_color = ThemeBuilder.COLOR_BORDER
		_realm_style.set_border_width_all(1)
		_realm_panel.modulate.a = 1.0
		if _pulse_tween != null and _pulse_tween.is_valid():
			_pulse_tween.kill()
		_pulse_tween = null


func _on_realm_gui_input(event: InputEvent) -> void:
	var pressed := false
	if event is InputEventScreenTouch:
		pressed = event.pressed
	elif event is InputEventMouseButton:
		pressed = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if not pressed:
		return
	if GameState.is_cultivation_locked():
		_show_panel("tribulation")
	else:
		_show_panel("cultivation")


func _on_stone_gui_input(event: InputEvent) -> void:
	var pressed := false
	if event is InputEventScreenTouch:
		pressed = event.pressed
	elif event is InputEventMouseButton:
		pressed = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if pressed:
		_show_panel("shop")


## 顶栏灵石：大于等于 1 万时使用「1.2万」紧凑写法
func _format_stone_count(value: int) -> String:
	# 亿级直接走统一紧凑格式（如「10.1亿」），避免顶栏出现「101123万」这种
	# 六位长数字把灵石胶囊撑到 450 视口之外
	if value >= 100000000:
		return GameFormulas.format_num(float(value))
	if value >= 10000:
		var wan := float(value) / 10000.0
		if wan >= 100.0:
			return "%d万" % int(round(wan))
		var text := "%.1f" % wan
		if text.ends_with(".0"):
			text = text.substr(0, text.length() - 2)
		return text + "万"
	return GameFormulas.format_num(float(value))


func _refresh_capsule() -> void:
	_active_capsule.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var target := ""
	# 空闲双态：可渡天劫（鎏金高亮）/ 静修（浅褐描边，轻触展开三才启程灵岛）
	var can_tribulate := _can_tribulate()
	var text := "可渡天劫" if can_tribulate else "静修"
	# 技能图标是 ImageTexture、导航图标是 CompressedTexture2D：统一按 Texture2D 接收，
	# 否则战斗中切换到导航图标会触发类型错误并把堆栈刷进 user://logs
	var icon_texture: Texture2D = IconLibrary.get_skill_icon("cultivation")
	var icon_alpha := 0.55
	var color := ThemeBuilder.COLOR_TEXT_GOLD if can_tribulate else ThemeBuilder.COLOR_TEXT_DIM
	var bg := ThemeBuilder.COLOR_GOLD_SOFT if can_tribulate else Color(0, 0, 0, 0)
	var border := ThemeBuilder.COLOR_AMBER if can_tribulate else Color("#C4B296")
	if CombatEngine.is_active():
		# 镇魔塔与秘境严格分称（镇魔塔中 / 镇魔等N修）
		var is_tower := CombatEngine.tower_floor > 0
		target = "tower" if is_tower else "combat"
		text = "镇魔塔中" if is_tower else "秘境中"
		# 与灵岛徽标同口径：战斗 + 运转中百艺 = 总并行路数
		var total_lanes := 1 + GameState.get_running_slots().size()
		if total_lanes >= 2:
			text = ("镇魔" if is_tower else "秘境") + ("等%d修" % total_lanes)
		# 图标沿用战斗（nav_tower 模板不存在），镇魔/秘境由文案分称
		icon_texture = IconLibrary.get_nav_icon("combat")
		icon_alpha = 1.0
		color = ThemeBuilder.COLOR_CINNABAR
		bg = ThemeBuilder.COLOR_CINNABAR_SOFT
		border = ThemeBuilder.COLOR_CINNABAR
	else:
		# 代表槽位固定优先级 0→1→2；多槽并发显示「<主技能>等N修」（≤5 字不挤灵石）
		var running := GameState.get_running_slots()
		var running_count := running.size()
		if running_count > 0:
			var primary := GameState.get_primary_slot()
			var action := DataRegistry.get_action(GameState.get_active_action(primary))
			if action != null:
				target = action.skill_id
				var short_name := String(SHORT_SKILL_NAMES.get(action.skill_id, "运转"))
				text = "%s中" % short_name if running_count == 1 \
					else "%s等%d修" % [short_name, running_count]
				icon_texture = IconLibrary.get_skill_icon(action.skill_id)
				icon_alpha = 1.0
				if running_count > 1:
					# 多槽并发用中性鎏金，不偏袒某一线
					color = ThemeBuilder.COLOR_TEXT_GOLD
					bg = ThemeBuilder.COLOR_GOLD_SOFT
					border = ThemeBuilder.COLOR_AMBER
				elif primary == 0:
					color = ThemeBuilder.COLOR_JADE
					bg = ThemeBuilder.COLOR_JADE_SOFT
					border = ThemeBuilder.COLOR_JADE
				else:
					color = ThemeBuilder.COLOR_AMBER
					bg = ThemeBuilder.COLOR_GOLD_SOFT
					border = ThemeBuilder.COLOR_AMBER
	_capsule_target = target
	_capsule_label.text = text
	_capsule_label.add_theme_color_override("font_color", color)
	# 仅空闲「静修 / 可渡天劫」保留图标；任何运转/战斗态只留纯文本，隐藏图标后
	# capsule_row（ALIGNMENT_CENTER）自然把文字居中，内边距不变、不挤压
	var show_icon := not CombatEngine.is_active() \
		and GameState.get_running_slots().is_empty()
	_capsule_icon.visible = show_icon
	_capsule_icon.texture = icon_texture
	_capsule_icon.modulate = Color(1, 1, 1, icon_alpha)
	_active_capsule.add_theme_color_override("font_color", color)
	_active_capsule.add_theme_color_override("font_hover_color", color)
	var normal_box := ThemeBuilder.panel_box(bg, border, 10, 1, 0)
	normal_box.content_margin_left = 10
	normal_box.content_margin_right = 10
	normal_box.content_margin_top = 4
	normal_box.content_margin_bottom = 4
	_active_capsule.add_theme_stylebox_override("normal", normal_box)
	var hover_box := ThemeBuilder.panel_box(
		bg.darkened(0.04) if bg.a > 0.0 else bg, border, 10, 1, 0)
	hover_box.content_margin_left = 10
	hover_box.content_margin_right = 10
	hover_box.content_margin_top = 4
	hover_box.content_margin_bottom = 4
	_active_capsule.add_theme_stylebox_override("hover", hover_box)
	var pressed_box := ThemeBuilder.panel_box(
		bg.darkened(0.08) if bg.a > 0.0 else bg, border, 10, 1, 0)
	pressed_box.content_margin_left = 10
	pressed_box.content_margin_right = 10
	pressed_box.content_margin_top = 4
	pressed_box.content_margin_bottom = 4
	_active_capsule.add_theme_stylebox_override("pressed", pressed_box)
	# 槽位数变化时同步三才图例（突破金丹/化神后图例增项）
	_refresh_drawer_legend()
	call_deferred("_sync_topbar_chip_heights")


## 右侧状态胶囊与中间灵石/境界卡保持同一水平高度
func _sync_topbar_chip_heights() -> void:
	if _realm_panel == null or _active_capsule == null:
		return
	var target := _realm_panel.size.y
	if target <= 0.0:
		return
	# 96 而非 104：1.20 大字档下 450 宽顶栏必须给灵石与境界让出这 8px
	_active_capsule.custom_minimum_size = Vector2(96.0, target)
	if _stone_capsule != null:
		_stone_capsule.custom_minimum_size.y = target


func _refresh_stones() -> void:
	_set_stone_value(GameState.get_item_count(DataRegistry.SPIRIT_STONE), true)
	_refresh_capsule()
	_refresh_nav()
	_refresh_drawer()


func _set_stone_value(target: int, animate: bool) -> void:
	if _stone_label == null:
		return
	if _stone_tween != null and _stone_tween.is_valid():
		_stone_tween.kill()
	var from := _stone_value
	_stone_value = target
	if not animate or from == target:
		_stone_label.text = _format_stone_count(target)
		return
	_stone_label.text = _format_stone_count(from)
	_stone_tween = create_tween()
	var update_label := func(value: float) -> void:
		_stone_label.text = _format_stone_count(int(round(value)))
	_stone_tween.tween_method(update_label, float(from), float(target), 0.25) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_stone_label.pivot_offset = _stone_label.size * 0.5
	if _stone_pulse_tween != null and _stone_pulse_tween.is_valid():
		_stone_pulse_tween.kill()
	_stone_pulse_tween = create_tween()
	_stone_pulse_tween.tween_property(_stone_label, "scale", Vector2(1.12, 1.12), 0.08)
	_stone_pulse_tween.tween_property(_stone_label, "scale", Vector2.ONE, 0.14) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_action_state_changed(_slot: int, _action_id: String) -> void:
	_refresh_capsule()
	_refresh_drawer()
	_refresh_nav()


func _on_combat_state_changed(_arg: Variant = null) -> void:
	_refresh_capsule()
	_refresh_nav()


func _on_realm_changed(realm_id: String, realm_name: String) -> void:
	var old_realm_id := _last_realm_id
	var is_real_change := _last_realm_id != "" and _last_realm_id != realm_id
	_last_realm_id = realm_id
	_refresh_all()
	if is_real_change and InkVfxLayer.instance != null:
		InkVfxLayer.instance.play_breakthrough("境界突破 · %s" % realm_name,
			ThemeBuilder.COLOR_AMBER, _realm_gain_text(old_realm_id, realm_id), "证")


## 突破副标（纯修仙语，禁开发术语）：小境界展示三维精进实数，
## 大境界展示道体蜕变与百艺新上限
func _realm_gain_text(old_id: String, new_id: String) -> String:
	var realms: Dictionary = DataRegistry.get("realms")
	var old_r: Variant = realms.get(old_id)
	var new_r: Variant = realms.get(new_id)
	if new_r == null:
		return "神识与体魄全面蜕变，威压倍增"
	if old_r != null and int(old_r.tier) == int(new_r.tier):
		return "气血 +%d · 攻击 +%d · 防御 +%d" % [
			int(new_r.max_hp) - int(old_r.max_hp),
			int(new_r.attack) - int(old_r.attack),
			int(new_r.defense) - int(old_r.defense)]
	return "道体蜕变，百艺上限升至 %d 重" % int(new_r.skill_level_cap)


func _on_cultivation_changed(_current: float, _required: float, _full: bool) -> void:
	_refresh_character_nav_dot()
	_refresh_topbar()


func _on_dual_unlocked() -> void:
	if _dual_notified:
		return
	_dual_notified = true
	_show_toast("已解锁「分神双修」：可同时挂载一采集 + 一制造/吐纳")


func _on_offline_report_ready(report: Dictionary) -> void:
	_refresh_all()
	if _modal != null:
		_modal.show_report(report)


func _show_toast(message: String) -> void:
	if _toast_panel == null or _toast_label == null:
		return
	var max_w := minf(get_viewport_rect().size.x - 32.0, 460.0)
	ThemeBuilder.fit_wrapped_label(_toast_label, message, _toast_panel, 44.0, max_w)
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	# 自上而下 10px 轻落淡入 → 停留 → 向上飘散 12px 淡出
	var base_y := _toast_panel.position.y
	_toast_panel.modulate.a = 0.0
	_toast_panel.position.y = base_y - 10.0
	_toast_tween = create_tween()
	_toast_tween.set_parallel(true)
	_toast_tween.tween_property(_toast_panel, "modulate:a", 1.0, 0.16) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_toast_tween.tween_property(_toast_panel, "position:y", base_y, 0.16) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_toast_tween.chain().tween_interval(2.4)
	_toast_tween.chain().tween_property(_toast_panel, "position:y", base_y - 12.0, 0.20) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_toast_tween.parallel().tween_property(_toast_panel, "modulate:a", 0.0, 0.20)
