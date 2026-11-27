class_name StatusSidebar
extends PanelContainer
## 宽屏（WIDE）右侧「洞府态势栏」：双槽运转卡 + 灵田微缩板 + 修行纪要。
## 只在 LayoutMode.WIDE 显示，窄屏隐藏但保持状态同步。

const SIDEBAR_WIDTH: float = 260.0
## 6 行固定池：四路并行时多出的战斗行不挤压灵田与纪要，1.20 字档仍能一屏展示
const LOG_LIMIT: int = 6
const LOG_COLORS: Dictionary = {
	"normal": ThemeBuilder.COLOR_TEXT_DIM,
	"good": ThemeBuilder.COLOR_JADE,
	"gold": ThemeBuilder.COLOR_AMBER,
	"warn": ThemeBuilder.COLOR_CINNABAR,
}

signal request_panel(page: String)

var _slot_views: Array[Dictionary] = []
## 常驻第 1 张卡：战斗与三才槽位彻底解耦（第四路并行），空闲也占位不掉高
var _combat_row: PanelContainer
var _combat_tag: Label
var _combat_label: Label
var _combat_bar: ProgressBar
var _combat_view: Dictionary = {}
var _combat_sig: String = ""
## 灵田微缩格（图标/名称/倒计时/细进度条原地复用，不逐秒重建）
var _farm_cell_views: Array[Dictionary] = []
var _farm_chip: Label
## 当前境界标识：加粗无衬线，层数数字在宽屏右栏也清晰
var _realm_label: Label
## 宽屏右栏修为细条：与顶栏同源，运行时 0.22s 缓动追赶
var _cultivation_bar: ProgressBar
var _log_box: VBoxContainer
var _farm_all_button: Button
## 灵田双按钮：收并种（主操作）+ 催熟（消耗近阶灵草）
var _farm_ripen_button: Button
var _farm_ripen_sig: String = ""
var _farm_poll: float = 0.0
var _scroll: ScrollContainer
## 修行纪要固定 Label 池：条数与行高恒定，增删记录绝不新建/销毁节点
var _log_views: Array[Dictionary] = []
var _log_sig: String = ""
## 隐藏期间只记账，重新可见时补刷（避免后台空转）
var _slots_dirty: bool = false
var _farm_dirty: bool = false
var _logs_dirty: bool = false
var _slots_sig: String = ""
var _farm_chip_sig: String = ""
var _farm_btn_sig: String = ""


func _ready() -> void:
	custom_minimum_size = Vector2(SIDEBAR_WIDTH, 0)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_PASS
	var style := ThemeBuilder.panel_box(ThemeBuilder.COLOR_CHROME,
		ThemeBuilder.COLOR_BORDER, 0, 0, 12)
	style.set_border_width_all(0)
	style.border_width_left = 1
	style.border_color = ThemeBuilder.COLOR_BORDER
	style.bg_color = Color(0, 0, 0, 0)
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	add_theme_stylebox_override("panel", style)

	_build()
	_connect_signals()
	_refresh_all()
	set_process(true)


func _build() -> void:
	var scroll := ThemeBuilder.scroll_container()
	_scroll = scroll
	add_child(scroll)
	# 紧凑 5px 区距：把省出的纵向空间让给修行纪要，1440×900 一屏装下
	var box := ThemeBuilder.vbox(5)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)

	var title_row := ThemeBuilder.hbox(6)
	box.add_child(title_row)
	title_row.add_child(ThemeBuilder.card_title_label("洞府态势",
		ThemeBuilder.FONT_CARD_TITLE, ThemeBuilder.COLOR_AMBER))
	title_row.add_child(ThemeBuilder.expander())
	# 与顶栏境界胶囊同源的加粗无衬线，避免右栏缺一份「当前境界」信息
	_realm_label = ThemeBuilder.label("", ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT)
	ThemeBuilder.apply_realm_font(_realm_label)
	title_row.add_child(_realm_label)

	_cultivation_bar = ThemeBuilder.progress_bar(ThemeBuilder.COLOR_JADE, 3)
	_cultivation_bar.max_value = 1.0
	_cultivation_bar.value = 0.0
	box.add_child(_cultivation_bar)

	# ---- 战斗独立行：秘境 / 镇魔塔第四路，不顶占任何百艺槽位
	_combat_row = _build_combat_row()
	box.add_child(_combat_row)
	# ---- 三才运转卡：严格一对一绑定真实槽位 0 / 1 / 2
	for slot in range(GameState.SLOT_COUNT):
		box.add_child(_build_slot_card(slot))

	box.add_child(ThemeBuilder.separator(1, ThemeBuilder.COLOR_BORDER))

	# ---- 灵田微缩板：标题角标 + 2×2 作物方格（图标/名称/倒计时/细进度条）
	var farm_head := ThemeBuilder.hbox(6)
	box.add_child(farm_head)
	farm_head.add_child(ThemeBuilder.section_title_label("洞府灵田",
		ThemeBuilder.FONT_BODY_SUB))
	_farm_chip = ThemeBuilder.label("", ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_SECONDARY)
	farm_head.add_child(_farm_chip)
	farm_head.add_child(ThemeBuilder.expander())
	var farm_jump := ThemeBuilder.small_button("前往")
	farm_jump.custom_minimum_size = Vector2(56, ThemeBuilder.TOUCH_MIN)
	ThemeBuilder.apply_font_size(farm_jump, ThemeBuilder.FONT_CAPTION)
	farm_jump.pressed.connect(func() -> void: request_panel.emit("farm"))
	farm_head.add_child(farm_jump)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 5)
	box.add_child(grid)
	for i in range(4):
		grid.add_child(_build_farm_cell(i))

	# 双按钮并排：一键收并种（主操作）/ 一键催熟（消耗近阶灵草，可催时鎏金高亮）
	var farm_actions := ThemeBuilder.hbox(6)
	box.add_child(farm_actions)
	_farm_all_button = ThemeBuilder.small_button("一键收并种")
	_farm_all_button.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
	ThemeBuilder.apply_font_size(_farm_all_button, ThemeBuilder.FONT_CAPTION)
	ThemeBuilder.apply_primary_button(_farm_all_button)
	_farm_all_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_farm_all_button.pressed.connect(_on_harvest_all_pressed)
	farm_actions.add_child(_farm_all_button)
	_farm_ripen_button = ThemeBuilder.small_button("一键催熟")
	_farm_ripen_button.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
	ThemeBuilder.apply_font_size(_farm_ripen_button, ThemeBuilder.FONT_CAPTION)
	_farm_ripen_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ThemeBuilder.apply_consume_button(_farm_ripen_button)
	ThemeBuilder.apply_font_size(_farm_ripen_button, ThemeBuilder.FONT_CAPTION)
	_farm_ripen_button.pressed.connect(_on_ripen_all_pressed)
	farm_actions.add_child(_farm_ripen_button)

	box.add_child(ThemeBuilder.separator(1, ThemeBuilder.COLOR_BORDER))

	# ---- 修行纪要
	box.add_child(ThemeBuilder.section_title_label("修行纪要",
		ThemeBuilder.FONT_BODY_SUB))
	_log_box = ThemeBuilder.vbox(2)
	_log_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(_log_box)
	# 固定 8 行就地改写：行数、行高与容器最小高度永远不变，日志刷新不再触发整栏重排
	for i in range(LOG_LIMIT):
		_log_views.append(_build_log_row())
	_log_sig = "init"


## 常驻战斗卡：与「主修 / 分神 / 化身」完全同款结构（标签 + 图标 + 名称 /
## 细进度条 / 同款跳转 + 停止），空闲态也保留整卡高度，状态切换零跳动
func _build_combat_row() -> PanelContainer:
	var card := ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD,
		ThemeBuilder.COLOR_BORDER, 8, 6)
	var box := ThemeBuilder.vbox(2)
	card.add_child(box)

	var head := ThemeBuilder.hbox(4)
	box.add_child(head)
	_combat_tag = ThemeBuilder.label("历练", ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_CINNABAR)
	ThemeBuilder.apply_font_size(_combat_tag, ThemeBuilder.FONT_CAPTION)
	head.add_child(_combat_tag)
	var icon := IconFrame.new()
	icon.setup(IconLibrary.get_ui_icon("default"), 18, ThemeBuilder.COLOR_TEXT_DIM)
	head.add_child(icon)
	_combat_label = ThemeBuilder.label("空闲", ThemeBuilder.FONT_BODY_SUB)
	ThemeBuilder.apply_font_size(_combat_label, ThemeBuilder.FONT_BODY_SUB)
	_combat_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# 敌名 / 层数直接完整展示，不裁切成省略号
	_combat_label.clip_text = false
	head.add_child(_combat_label)

	_combat_bar = ThemeBuilder.progress_bar_run()
	_combat_bar.max_value = 1.0
	_combat_bar.step = 0.0
	_combat_bar.value = 0.0
	ThemeBuilder.set_bar_fill(_combat_bar, ThemeBuilder.COLOR_CINNABAR)
	box.add_child(_combat_bar)

	var actions := ThemeBuilder.hbox(5)
	box.add_child(actions)
	var jump := ThemeBuilder.small_button("跳转")
	jump.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
	ThemeBuilder.apply_font_size(jump, ThemeBuilder.FONT_CAPTION)
	jump.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	jump.pressed.connect(func() -> void:
		request_panel.emit("tower" if CombatEngine.tower_floor > 0 else "combat"))
	actions.add_child(jump)
	var stop := ThemeBuilder.small_button("停止")
	stop.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
	ThemeBuilder.apply_font_size(stop, ThemeBuilder.FONT_CAPTION)
	stop.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stop.pressed.connect(func() -> void:
		CombatEngine.stop_combat("态势栏撤出")
		_refresh_combat_row())
	actions.add_child(stop)

	_combat_view = {
		"name": _combat_label, "bar": _combat_bar, "jump": jump, "stop": stop,
		"icon": icon, "tag": _combat_tag,
	}
	return card


func _build_slot_card(slot: int) -> PanelContainer:
	# 紧凑卡：内边距 6、行距 2、图标 18；跳转 / 停止仍保持 44px 触控高度
	var card := ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD, ThemeBuilder.COLOR_BORDER, 8, 6)
	var box := ThemeBuilder.vbox(2)
	card.add_child(box)

	var head := ThemeBuilder.hbox(4)
	box.add_child(head)
	var tag := ThemeBuilder.label(GameState.get_slot_name(slot),
		ThemeBuilder.FONT_CAPTION, _slot_color(slot))
	head.add_child(tag)
	var icon := IconFrame.new()
	icon.setup(IconLibrary.get_ui_icon("default"), 18, ThemeBuilder.COLOR_TEXT_DIM)
	head.add_child(icon)
	var name_label := ThemeBuilder.label("空闲", ThemeBuilder.FONT_BODY_SUB)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	head.add_child(name_label)

	# 三才运转条与动作卡统一：6px 胶囊 + 对应槽位专属色（点 / 条 / 标签一一对应）
	var bar := ThemeBuilder.progress_bar_run()
	bar.max_value = 1.0
	bar.step = 0.0
	bar.value = 0.0
	ThemeBuilder.set_bar_fill(bar, _slot_color(slot))
	box.add_child(bar)

	var actions := ThemeBuilder.hbox(5)
	box.add_child(actions)
	var jump := ThemeBuilder.small_button("跳转")
	jump.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
	ThemeBuilder.apply_font_size(jump, ThemeBuilder.FONT_CAPTION)
	jump.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	jump.pressed.connect(func() -> void: _jump_slot(slot))
	actions.add_child(jump)
	var stop := ThemeBuilder.small_button("停止")
	stop.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
	ThemeBuilder.apply_font_size(stop, ThemeBuilder.FONT_CAPTION)
	stop.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stop.pressed.connect(func() -> void: _stop_slot(slot))
	actions.add_child(stop)

	_slot_views.append({
		"name": name_label, "bar": bar, "jump": jump, "stop": stop, "icon": icon,
		"tag": tag,
	})
	return card


## 槽位主色：主修翠玉绿 / 分神靛青蓝 / 化身紫霄紫（与动作卡、灵动岛同源）
func _slot_color(slot: int) -> Color:
	return ThemeBuilder.slot_dot_color(slot)


func _connect_signals() -> void:
	EventBus.action_started.connect(_on_any_state)
	EventBus.action_stopped.connect(_on_any_state)
	# 读档恢复运转槽时不再重发 action_started（避免开场音效），由 game_loaded 直接刷新
	EventBus.game_loaded.connect(_refresh_all)
	EventBus.combat_started.connect(_on_any_state_str)
	EventBus.combat_stopped.connect(_on_any_state_str)
	EventBus.farm_changed.connect(_on_farm_changed)
	EventBus.activity_log_added.connect(_on_log_added)
	EventBus.inventory_changed.connect(_on_inventory_changed)
	EventBus.realm_changed.connect(_on_realm_changed)
	visibility_changed.connect(_on_visibility_changed)


## 隐藏（窄屏 / 中屏）时不做任何 UI 更新，只置脏；重新可见后一次性补齐
func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		return
	_refresh_combat_row()
	if _slots_dirty:
		_slots_dirty = false
		_refresh_slots()
	if _farm_dirty:
		_farm_dirty = false
		_refresh_farm()
	if _logs_dirty:
		_logs_dirty = false
		_refresh_logs()


func _on_any_state(_slot: int, _action_id: String) -> void:
	_refresh_slots()


func _on_any_state_str(_arg: String) -> void:
	_refresh_slots()
	_refresh_combat_row()


func _on_inventory_changed() -> void:
	_refresh_slots()


## 突破后吐纳名（吐纳筑基/筑基凝丹/凝丹化婴/元婴化神/证道飞升）要立刻换字
func _on_realm_changed(_realm_id: String, _realm_name: String) -> void:
	_refresh_realm()
	_refresh_slots()


func _on_farm_changed() -> void:
	if not is_visible_in_tree():
		_farm_dirty = true
		return
	_refresh_farm()


func _on_log_added(_entry: Dictionary) -> void:
	if not is_visible_in_tree():
		_logs_dirty = true
		return
	_refresh_logs()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	# 三才进度条逐帧读取 ActionRunner 浮点进度；这里只改 value，不碰文本与节点
	_refresh_progress()
	_farm_poll += delta
	# 微缩灵田每秒刷新，与灵田面板同一倒计时来源
	if _farm_poll >= 1.0:
		_farm_poll = 0.0
		_refresh_farm()


func _refresh_all() -> void:
	_refresh_realm()
	_refresh_combat_row()
	if not is_visible_in_tree():
		_slots_dirty = true
		_farm_dirty = true
		_logs_dirty = true
		return
	_refresh_slots()
	_refresh_farm()
	_refresh_logs()


## 当前境界：与顶栏境界胶囊同源，右侧态势栏也能一眼看清「炼气九层 / 金丹中期」
func _refresh_realm() -> void:
	if _realm_label == null:
		return
	var realm := GameState.get_realm()
	_realm_label.text = "—" if realm == null else realm.display_name
	# 与顶栏境界印 / 左侧「修士道身」同读九重大境界配色表
	_realm_label.add_theme_color_override("font_color", ThemeBuilder.realm_tier_color(
		0 if realm == null else realm.tier))
	var requirement := GameState.get_realm_requirement()
	var target_ratio := clampf(GameState.cultivation_xp / requirement, 0.0, 1.0) \
		if requirement > 0.0 else 1.0
	UiMotion.advance_progress(_cultivation_bar, target_ratio, 0.22)


# ---------------------------------------------------------------- 三才槽位（与战斗解耦）

func _refresh_slots() -> void:
	if _slot_views.is_empty():
		return
	if not is_visible_in_tree():
		_slots_dirty = true
		return
	# 签名早退：只看真实槽位动作，战斗不再参与（库存信号可能每秒来数次）
	var parts: PackedStringArray = []
	for slot in range(GameState.SLOT_COUNT):
		parts.append("%s|%s|%s" % [GameState.get_active_action(slot),
			str(GameState.is_slot_unlocked(slot)),
			GameState.get_skill_display_name("cultivation")])
	var signature := "|".join(parts)
	if signature == _slots_sig:
		return
	_slots_sig = signature
	for slot in range(_slot_views.size()):
		var view: Dictionary = _slot_views[slot]
		var name_label: Label = view["name"]
		var jump: Button = view["jump"]
		var stop: Button = view["stop"]
		# 严格一对一：卡片索引 == ActionRunner 槽位索引，战斗不顶占、不顺延
		var action_id := GameState.get_active_action(slot)
		if action_id != "":
			var action := DataRegistry.get_action(action_id)
			var display_name := DataRegistry.get_action_name(action_id)
			if action != null and action.skill_id == "cultivation":
				display_name = GameState.get_skill_display_name("cultivation")
			name_label.text = display_name
			name_label.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT)
			(view["tag"] as Label).add_theme_color_override("font_color", _slot_color(slot))
			if action != null:
				(view["icon"] as IconFrame).set_icon(
					IconLibrary.get_skill_icon(action.skill_id), _slot_color(slot))
			jump.disabled = false
			stop.disabled = false
		elif not GameState.is_slot_unlocked(slot):
			name_label.text = GameState.get_slot_unlock_hint(slot)
			name_label.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT_DIM)
			(view["icon"] as IconFrame).set_icon(
				IconLibrary.get_ui_icon("default"), ThemeBuilder.COLOR_TEXT_DIM)
			jump.disabled = true
			stop.disabled = true
			(view["tag"] as Label).add_theme_color_override("font_color",
				ThemeBuilder.COLOR_TEXT_MUTED)
		else:
			name_label.text = "空闲"
			name_label.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT_DIM)
			(view["icon"] as IconFrame).set_icon(
				IconLibrary.get_ui_icon("default"), ThemeBuilder.COLOR_TEXT_DIM)
			jump.disabled = true
			stop.disabled = true
		(view["bar"] as ProgressBar).value = _slot_bar_value(slot)


## 槽位进度单一出口：三张卡各自读对应真实槽位，60FPS 逐帧推进
func _slot_bar_value(slot: int) -> float:
	if GameState.get_active_action(slot) == "":
		return 0.0
	return clampf(ActionRunner.get_progress(slot), 0.0, 1.0)


func _refresh_progress() -> void:
	for slot in range(_slot_views.size()):
		var view: Dictionary = _slot_views[slot]
		(view["bar"] as ProgressBar).value = _slot_bar_value(slot)
	_refresh_combat_progress()


# ---------------------------------------------------------------- 常驻战斗卡

func _refresh_combat_row() -> void:
	if _combat_view.is_empty():
		return
	var active := CombatEngine.is_active()
	var tower := active and CombatEngine.tower_floor > 0
	var enemy := CombatEngine.get_current_enemy() if active else null
	if tower:
		_combat_tag.text = "镇魔"
		# 层号优先，悬停再看当前妖魔名，短卡不重复前缀
		var text := "第 %d 层" % CombatEngine.tower_floor
		_combat_label.text = text
		_combat_label.tooltip_text = "%s · %s" % [text,
			enemy.display_name if enemy != null else "镇塔妖魔"]
	elif active:
		_combat_tag.text = "历练"
		var text := enemy.display_name if enemy != null else "妖兽"
		_combat_label.text = text
		_combat_label.tooltip_text = "历练 · " + text
	else:
		_combat_tag.text = "历练"
		_combat_label.text = "空闲"
		_combat_label.tooltip_text = "前往秘境或镇魔塔开局"
	var sig := "%s|%s|%s" % [str(active), str(tower), _combat_label.text]
	if sig == _combat_sig:
		return
	_combat_sig = sig
	var name_color := ThemeBuilder.COLOR_TEXT_DIM if not active \
		else ThemeBuilder.COLOR_CINNABAR
	var tag_color := ThemeBuilder.COLOR_TEXT_MUTED if not active \
		else ThemeBuilder.COLOR_CINNABAR
	_combat_label.add_theme_color_override("font_color", name_color)
	_combat_tag.add_theme_color_override("font_color", tag_color)
	var icon_frame: IconFrame = _combat_view["icon"]
	if active and enemy != null:
		icon_frame.set_icon(IconLibrary.get_enemy_icon(enemy.get_icon_key()),
			ThemeBuilder.COLOR_CINNABAR)
	else:
		icon_frame.set_icon(IconLibrary.get_ui_icon("default"),
			ThemeBuilder.COLOR_TEXT_DIM)
	(_combat_view["jump"] as Button).disabled = false
	(_combat_view["stop"] as Button).disabled = not active
	_refresh_combat_progress()


func _refresh_combat_progress() -> void:
	if _combat_view.is_empty():
		return
	var enemy := CombatEngine.get_current_enemy() if CombatEngine.is_active() else null
	var ratio := 0.0
	if enemy != null:
		ratio = clampf(float(CombatEngine.enemy_hp) / float(maxi(1, enemy.max_hp)),
			0.0, 1.0)
	_combat_bar.value = ratio


func _jump_slot(slot: int) -> void:
	var action_id := GameState.get_active_action(slot)
	if action_id == "":
		request_panel.emit("farm" if slot == 1 else _last_skill())
		return
	var action := DataRegistry.get_action(action_id)
	request_panel.emit(action.skill_id if action != null else "herbalism")


func _stop_slot(slot: int) -> void:
	if GameState.get_active_action(slot) != "":
		GameState.stop_action(slot)
	_refresh_slots()


func _last_skill() -> String:
	return "herbalism"


# ---------------------------------------------------------------- 灵田

## 灵田微缩格：空田 / 未开垦复用灵田 SVG 小图标 + 两行短文案，
## 耕作中保留「状态圆点 + 作物名 / 倒计时 + 细进度条」，四格同高、无虚线压字。
func _build_farm_cell(index: int) -> PanelContainer:
	var card := ThemeBuilder.card_panel(ThemeBuilder.COLOR_SUBTLE,
		ThemeBuilder.COLOR_BORDER, 8, 8)
	card.custom_minimum_size = Vector2(0, 60)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	var v := ThemeBuilder.vbox(2)
	card.add_child(v)
	# 第一行：空闲态用灵田小图标，耕作态用状态圆点；名称独占剩余宽度
	var head := ThemeBuilder.hbox(4)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(head)
	var farm_icon := IconFrame.new()
	farm_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	farm_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	farm_icon.modulate = Color(1, 1, 1, 0.82)
	farm_icon.visible = false
	head.add_child(farm_icon)
	var dot := ThemeBuilder.color_dot(ThemeBuilder.COLOR_TEXT_DIM, 8.0)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(dot)
	var name_label := ThemeBuilder.label("", ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_DIM)
	ThemeBuilder.apply_font_size(name_label, ThemeBuilder.FONT_CAPTION)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.custom_minimum_size = Vector2(0, 0)
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(name_label)
	# 第二行：倒计时 / 已成熟 / 待播，独立占行
	var time_label := ThemeBuilder.label("", ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_SECONDARY)
	ThemeBuilder.apply_font_size(time_label, ThemeBuilder.FONT_CAPTION)
	time_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	time_label.custom_minimum_size = Vector2(0, 0)
	time_label.clip_text = true
	time_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	time_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(time_label)
	# 灵田生长条统一暖金棕（微缩格保持 4px 紧凑胶囊）
	var bar := ThemeBuilder.progress_bar_grow(4.0)
	bar.max_value = 1.0
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(bar)
	ThemeBuilder.make_card_tappable(card, _on_plot_pressed.bind(index))
	_farm_cell_views.append({
		"card": card, "dot": dot, "farm_icon": farm_icon, "name": name_label,
		"time": time_label, "bar": bar, "last": {},
	})
	return card


## 空田 / 未开垦图标：复用灵田 SVG 归一化缓存，柔和淡化，状态变化时才重设
func _apply_farm_cell_icon(view: Dictionary, state: String) -> void:
	var icon_frame: IconFrame = view["farm_icon"]
	var last: Dictionary = view["last"]
	if last.get("icon_state", "") == state:
		return
	last["icon_state"] = state
	var source: Texture2D = IconLibrary.get_farm_locked_icon() if state == "locked" \
		else IconLibrary.get_farm_icon(0)
	var texture := IconLibrary.get_normalized_icon(
		"sidebar_farm_%s" % state, source, 48, 4)
	icon_frame.setup(texture, 18, ThemeBuilder.COLOR_TEXT_DIM, false, 18)


func _refresh_farm() -> void:
	if _farm_cell_views.is_empty():
		return
	if not is_visible_in_tree():
		_farm_dirty = true
		return
	var ready := 0
	var empty := 0
	var planted := 0
	var growing := 0
	var unlocked_cnt := 0
	for i in range(_farm_cell_views.size()):
		var view: Dictionary = _farm_cell_views[i]
		var card: PanelContainer = view["card"]
		var dot: PanelContainer = view["dot"]
		var farm_icon: IconFrame = view["farm_icon"]
		var name_label: Label = view["name"]
		var time_label: Label = view["time"]
		var bar: ProgressBar = view["bar"]
		var last: Dictionary = view["last"]
		var border := ThemeBuilder.COLOR_BORDER
		# 空田底板比耕作中略淡一档，仍保留浅描边与圆角，不画虚线
		var cell_bg := Color(ThemeBuilder.COLOR_SUBTLE.r, ThemeBuilder.COLOR_SUBTLE.g,
			ThemeBuilder.COLOR_SUBTLE.b, 0.72)
		var dot_color := ThemeBuilder.COLOR_TEXT_DIM
		farm_icon.visible = false
		dot.visible = true
		# 细进度条常驻：空闲态就是空灰底槽，保证四格高度恒定
		bar.value = 0.0
		time_label.text = ""
		if not FarmManager.is_unlocked(i):
			name_label.text = "未开垦"
			name_label.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT_DIM)
			time_label.text = "待开垦"
			time_label.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT_DIM)
			dot.visible = false
			farm_icon.visible = true
			_apply_farm_cell_icon(view, "locked")
		else:
			unlocked_cnt += 1
			var plot: Dictionary = FarmManager.get_plot(i)
			var seed_id := String(plot.get("seed_id", ""))
			var crop_name := "灵田作物"
			if seed_id != "":
				var seed_data := DataRegistry.get_seed(seed_id)
				var crop_id := String(seed_data.get("crop_id", ""))
				crop_name = DataRegistry.get_item_name(crop_id) \
					if crop_id != "" else String(seed_data.get("name", "灵田作物"))
			if FarmManager.is_mature(i):
				ready += 1
				planted += 1
				name_label.text = crop_name
				name_label.add_theme_color_override("font_color", ThemeBuilder.COLOR_JADE)
				time_label.text = "已成熟"
				time_label.add_theme_color_override("font_color", ThemeBuilder.COLOR_JADE)
				dot_color = ThemeBuilder.COLOR_JADE
				border = ThemeBuilder.COLOR_JADE
				cell_bg = ThemeBuilder.COLOR_JADE_SOFT
				bar.visible = true
				bar.value = 1.0
				if last.get("bar_color") != ThemeBuilder.COLOR_JADE:
					last["bar_color"] = ThemeBuilder.COLOR_JADE
					ThemeBuilder.set_bar_fill(bar, ThemeBuilder.COLOR_JADE, 2)
			elif FarmManager.is_empty(i):
				empty += 1
				name_label.text = "空田"
				name_label.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT_SECONDARY)
				time_label.text = "待播"
				time_label.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT_DIM)
				dot.visible = false
				farm_icon.visible = true
				_apply_farm_cell_icon(view, "empty")
			else:
				planted += 1
				growing += 1
				var remaining := FarmManager.get_remaining(i)
				name_label.text = crop_name
				name_label.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT)
				time_label.text = _compact_duration(remaining)
				time_label.add_theme_color_override("font_color",
					ThemeBuilder.COLOR_TEXT_SECONDARY)
				dot_color = ThemeBuilder.COLOR_AMBER
				cell_bg = ThemeBuilder.COLOR_GOLD_SOFT
				bar.visible = true
				var duration := maxf(1.0, float(plot.get("duration_sec", 1)))
				bar.value = clampf(1.0 - remaining / duration, 0.0, 1.0)
				if last.get("bar_color") != ThemeBuilder.COLOR_AMBER:
					last["bar_color"] = ThemeBuilder.COLOR_AMBER
					ThemeBuilder.set_bar_fill(bar, ThemeBuilder.COLOR_AMBER, 2)
		if last.get("dot") != dot_color:
			last["dot"] = dot_color
			dot.add_theme_stylebox_override("panel", ThemeBuilder.circle_box(dot_color, 8.0))
		# 卡片样式只在田块状态变化时重设，避免每秒分配 StyleBox 触发重绘
		if last.get("bg") != cell_bg or last.get("border") != border:
			last["bg"] = cell_bg
			last["border"] = border
			card.add_theme_stylebox_override("normal",
				ThemeBuilder.panel_box(cell_bg, border, 8, 1, 6))
	# 标题角标：有熟显「N块已熟」，否则「N/M 耕作」；数值不变时不重设样式
	var chip_sig := "%d|%d|%d" % [ready, planted, unlocked_cnt]
	if _farm_chip != null and chip_sig != _farm_chip_sig:
		_farm_chip_sig = chip_sig
		if ready > 0:
			_farm_chip.text = "%d块已熟" % ready
			_farm_chip.add_theme_color_override("font_color", ThemeBuilder.COLOR_JADE)
		else:
			_farm_chip.text = "%d/%d 耕作" % [planted, unlocked_cnt]
			_farm_chip.add_theme_color_override("font_color",
				ThemeBuilder.COLOR_TEXT_SECONDARY)
	# 底部双按钮：状态签名不变时不动样式（每秒轮询零分配）
	# 左「一键收并种」：有熟可收/有空可补时高亮；右「一键催熟」：可施肥时鎏金高亮
	var btn_sig := "ready:%d|empty:%d" % [ready, empty]
	if btn_sig != _farm_btn_sig:
		_farm_btn_sig = btn_sig
		if ready > 0:
			_farm_all_button.disabled = false
			_farm_all_button.text = "一键收并种"
			_farm_all_button.tooltip_text = "收割 %d 块成熟灵田并自动补种" % ready
			ThemeBuilder.apply_primary_button(_farm_all_button)
		elif empty > 0:
			_farm_all_button.disabled = false
			_farm_all_button.text = "一键收并种"
			_farm_all_button.tooltip_text = "补种 %d 块空地" % empty
			ThemeBuilder.apply_secondary_button(_farm_all_button)
		else:
			_farm_all_button.disabled = true
			_farm_all_button.text = "一键收并种"
			_farm_all_button.tooltip_text = "暂无成熟灵田或待补种空地"
			ThemeBuilder.apply_secondary_button(_farm_all_button)
	var ripen_ok := FarmManager.can_batch_ripen()
	var ripen_sig := "%s|%d" % [str(ripen_ok), growing]
	if _farm_ripen_button != null and ripen_sig != _farm_ripen_sig:
		_farm_ripen_sig = ripen_sig
		if ripen_ok:
			_farm_ripen_button.disabled = false
			_farm_ripen_button.text = "一键催熟"
			_farm_ripen_button.tooltip_text = "为 %d 块生长灵田补施近阶灵草至本轮上限" % growing
			ThemeBuilder.apply_consume_button(_farm_ripen_button)
		elif growing <= 0:
			_farm_ripen_button.disabled = true
			_farm_ripen_button.text = "暂无可催熟"
			_farm_ripen_button.tooltip_text = "先在灵田播种，生长中方可催熟"
			ThemeBuilder.apply_consume_button(_farm_ripen_button)
		else:
			_farm_ripen_button.disabled = true
			_farm_ripen_button.text = "灵肥已足"
			_farm_ripen_button.tooltip_text = "本轮灵肥已施满 3 次，或缺少近阶灵草"
			ThemeBuilder.apply_consume_button(_farm_ripen_button)
		ThemeBuilder.apply_font_size(_farm_ripen_button, ThemeBuilder.FONT_CAPTION)


func _compact_duration(seconds: float) -> String:
	if seconds < 60.0:
		return "%d秒" % maxi(1, int(seconds))
	if seconds < 3600.0:
		return "%d分" % int(ceil(seconds / 60.0))
	return "%d时%d分" % [int(seconds / 3600.0), int(ceil(fmod(seconds, 3600.0) / 60.0))]


## 库存中品阶（售价）最高的灵种：空闲格一键快速补种用
func _best_seed_id() -> String:
	var best := ""
	var best_price := -1
	for seed_data in DataRegistry.get_all_seeds():
		var dict: Dictionary = seed_data
		var seed_id := String(dict.get("id", ""))
		if GameState.get_item_count(seed_id) <= 0:
			continue
		var item := DataRegistry.get_item(seed_id)
		var price := 0 if item == null else item.sell_price
		if price > best_price:
			best_price = price
			best = seed_id
	return best


func _on_plot_pressed(index: int) -> void:
	if not FarmManager.is_unlocked(index):
		request_panel.emit("shop")
		return
	if FarmManager.is_mature(index):
		FarmManager.harvest(index)
		return
	if FarmManager.is_empty(index):
		var seed := _best_seed_id()
		if seed == "":
			request_panel.emit("farm")
			return
		FarmManager.plant(index, seed)
		return
	request_panel.emit("farm")


func _on_harvest_all_pressed() -> void:
	var ready := 0
	var empty := 0
	for i in range(_farm_cell_views.size()):
		if not FarmManager.is_unlocked(i):
			continue
		if FarmManager.is_mature(i):
			ready += 1
		elif FarmManager.is_empty(i):
			empty += 1
	if ready > 0:
		FarmManager.harvest_all()
		FarmManager.replant_all()
	elif empty > 0:
		FarmManager.replant_all()
	else:
		return
	_refresh_farm()


## 一键催熟：与 FarmPanel 共用 FarmManager.ripen_all_plots（单出口逻辑）
func _on_ripen_all_pressed() -> void:
	if not FarmManager.can_batch_ripen():
		EventBus.toast.emit("灵肥已足" if FarmManager.count_planted() > 0 else "暂无可催熟")
		return
	var result := FarmManager.ripen_all_plots()
	var did := int(result.get("plots", 0))
	if did <= 0:
		EventBus.toast.emit("需近阶灵草")
		return
	EventBus.inventory_changed.emit()
	EventBus.farm_changed.emit()
	GameState.vibrate_medium()
	EventBus.toast.emit("灵肥催熟 %d 块" % did)
	_refresh_farm()


# ---------------------------------------------------------------- 纪要

## 纪要行：单行不折行 + clip_text，行高只由字号决定，内容变化不改最小尺寸
func _build_log_row() -> Dictionary:
	var row := ThemeBuilder.hbox(4)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var time_label := ThemeBuilder.label("", ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_DIM)
	# 时间列自适应：00:04 四位时间在 1.20 大字档下也绝不裁成「00:0」
	time_label.custom_minimum_size = Vector2(48, 0)
	time_label.clip_text = false
	row.add_child(time_label)
	var text_label := ThemeBuilder.label("", ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_DIM)
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_label.clip_text = true
	text_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(text_label)
	_log_box.add_child(row)
	return {"row": row, "time": time_label, "text": text_label, "tone": "", "full": ""}


## 修行纪要：8 行固定池按环形顺序就地改写，不 queue_free / new / 改最小高度
func _refresh_logs() -> void:
	if _log_box == null or _log_views.is_empty():
		return
	if not is_visible_in_tree():
		_logs_dirty = true
		return
	_logs_dirty = false
	var entries := GameState.get_recent_logs(LOG_LIMIT)
	var parts: PackedStringArray = []
	for entry in entries:
		var dict: Dictionary = entry
		parts.append("%s|%s|%s" % [String(dict.get("time", "")),
			String(dict.get("tone", "normal")), String(dict.get("text", ""))])
	var signature := "|".join(parts)
	if signature == _log_sig:
		return
	_log_sig = signature
	for i in range(_log_views.size()):
		var view: Dictionary = _log_views[i]
		var time_label: Label = view["time"]
		var text_label: Label = view["text"]
		var row: Control = view["row"]
		if i < entries.size():
			var entry: Dictionary = entries[i]
			var time_text := String(entry.get("time", ""))
			var body := String(entry.get("text", ""))
			var tone := String(entry.get("tone", "normal"))
			time_label.text = time_text
			text_label.text = body
			if String(view.get("tone", "")) != tone:
				view["tone"] = tone
				text_label.add_theme_color_override("font_color",
					LOG_COLORS.get(tone, ThemeBuilder.COLOR_TEXT_DIM))
			if String(view.get("full", "")) != body:
				view["full"] = body
				row.tooltip_text = ("%s %s" % [time_text, body]).strip_edges()
			row.visible = true
		else:
			row.visible = true
			time_label.text = ""
			text_label.text = ""
			row.tooltip_text = ""
	if entries.is_empty():
		var empty_view: Dictionary = _log_views[0]
		(empty_view["text"] as Label).text = "暂无纪要，开始运转功法吧"
		(empty_view["text"] as Label).add_theme_color_override("font_color",
			ThemeBuilder.COLOR_TEXT_DIM)
		empty_view["tone"] = "normal"
