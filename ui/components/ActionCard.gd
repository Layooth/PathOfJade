class_name ActionCard
extends PanelContainer
## 移动端动作卡片：实时数值行、库存显示、未解锁禁用、铺满宽度的主次按钮。

## 「时 · 艺 · 候 · 倍」数值行被点按：交给面板弹出百艺与悟道图解
signal glossary_requested

const VERB_BY_SKILL: Dictionary = {
	"herbalism": "采摘", "woodcutting": "砍伐", "mining": "开采",
	"alchemy": "炼制", "forging": "锻造", "talisman": "绘制",
	"cultivation": "吐纳",
}
const TITLE_PREFIXES: Dictionary = {
	"herbalism": ["采摘", "采"], "woodcutting": ["砍伐", "伐", "取"],
	"mining": ["开采", "采"], "alchemy": ["炼制"],
	"forging": ["锻造"], "talisman": ["绘制"], "cultivation": [],
}

## 飘字层由 MainShell 注入（Container 会接管子节点布局，飘字必须画在独立层）
## 后台挂机产出飘字已改由 MainShell 统一锚定到顶栏胶囊下方，此处仅供灵田手动收割复用。
var action: ActionData = null

var _box: VBoxContainer
var _element_chip: PanelContainer
var _name_label: Label
var _status_chip: PanelContainer
var _status_dot: Label
var _status_label: Label
var _status_breath_tween: Tween
var _locked_chip: PanelContainer
var _locked_label: Label
var _progress: ProgressBar
var _interval_label: Label
var _material_label: RichTextLabel
var _mastery_bar: ProgressBar
var _mastery_label: Label
var _mastery_badge: PanelContainer
var _start_button: Button
## 槽位按钮组：0 主修 / 1 分神 / 2 化身（按境界解锁数显隐）
var _start_buttons: Array[Button] = []
## 三态互斥的「缺料」分支按钮（获取缺失原料 ▸），与槽位按钮同排互斥显隐
var _miss_button: Button
var _refine_button: Button
var _icon_frame: IconFrame
var _synergy_chip: PanelContainer
var _style_box: StyleBoxFlat
var _last_running: bool = false
var _last_locked: bool = false
var _was_visible: bool = true
## 脏标记：切页 / 隐藏期间的信号只置脏，切回时统一补刷一次，杜绝切页全量重排
var _dirty: bool = true


func setup(data: ActionData) -> void:
	action = data
	_style_box = ThemeBuilder.panel_box(
		ThemeBuilder.card_color(ThemeBuilder.COLOR_CARD),
		ThemeBuilder.COLOR_BORDER, 10, 1, 12)
	ThemeBuilder.apply_card_shadow(_style_box)
	add_theme_stylebox_override("panel", _style_box)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_build()
	refresh(true)
	ThemeBuilder.prepare_touch(self)


func _ready() -> void:
	EventBus.action_started.connect(_on_action_state_signal)
	EventBus.action_stopped.connect(_on_action_state_signal)
	# 读档恢复运转槽时不重发 action_started（避免开场音效），由 game_loaded 直接刷新卡片态
	EventBus.game_loaded.connect(refresh)
	EventBus.action_completed.connect(_on_action_completed)
	EventBus.mastery_changed.connect(_on_mastery_changed)
	EventBus.mastery_pool_changed.connect(_on_pool_changed)
	EventBus.skill_xp_changed.connect(_on_skill_xp_changed)
	# 库存刷新由 SkillActionPanel._refresh_cards 统一驱动（避免逐卡双重刷新风暴）；
	# 装备/境界变化仍自刷，但走脏标记合并单帧一次
	EventBus.equipment_changed.connect(_on_equipment_changed)
	EventBus.shop_changed.connect(_on_equipment_changed)
	EventBus.technique_changed.connect(_on_equipment_changed)
	EventBus.realm_changed.connect(_on_realm_changed)
	visibility_changed.connect(_on_visibility_changed)
	set_process(is_visible_in_tree())
	refresh(true)


func _process(_delta: float) -> void:
	if action == null:
		return
	var visible_now := is_visible_in_tree()
	if not visible_now:
		# 不可见即停表：切页后不再为空转卡片消耗每帧轮询（切回由 visibility_changed 唤醒）
		if _was_visible:
			_was_visible = false
			_stop_status_breathing()
		set_process(false)
		return
	if not _was_visible:
		_was_visible = true
		refresh()
	var slot := GameState.get_slot_of_action(action.id)
	var running := slot >= 0
	var locked := GameState.get_skill_level(action.skill_id) < action.required_level
	if running != _last_running or locked != _last_locked:
		_last_running = running
		_last_locked = locked
		_dirty = true
		refresh()
	if running and _progress != null:
		_progress.value = ActionRunner.get_progress(slot)
	elif _progress != null:
		_progress.value = 0.0




func _action_verb() -> String:
	return String(VERB_BY_SKILL.get(action.skill_id, "运转")) if action != null else "运转"


func _display_title() -> String:
	if action == null:
		return ""
	var text_value := action.display_name
	var prefixes: Array = TITLE_PREFIXES.get(action.skill_id, [])
	for prefix in prefixes:
		var token := String(prefix)
		if text_value.begins_with(token):
			text_value = text_value.substr(token.length())
			break
	return text_value


func _slot_name(slot_idx: int) -> String:
	return GameState.get_slot_text(slot_idx, "name")


## 卡片底部主操作按钮统一基准：字体族、字号、高度、内边距完全一致；
## 状态差异只允许体现在配色与描边语义上。
func _prepare_slot_button(btn: Button) -> void:
	if btn == null:
		return
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
	btn.clip_text = true
	btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_filter = Control.MOUSE_FILTER_PASS
	btn.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	ThemeBuilder.apply_font_size(btn, ThemeBuilder.FONT_BODY)
	ThemeBuilder.apply_brush_kai(btn)
	ThemeBuilder.tighten_button_padding(btn, 4.0)


func _apply_occupied_gold_style(btn: Button) -> void:
	if btn == null:
		return
	var normal := ThemeBuilder.panel_box(ThemeBuilder.COLOR_GOLD_SOFT,
		Color("#D9BE8C"), 8, 2, 8)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover",
		ThemeBuilder.panel_box(Color("#EFE4CC"), ThemeBuilder.COLOR_TEXT_GOLD, 8, 2, 8))
	btn.add_theme_stylebox_override("pressed",
		ThemeBuilder.panel_box(Color("#E7D8BA"), ThemeBuilder.COLOR_TEXT_GOLD, 8, 2, 8))
	btn.add_theme_stylebox_override("disabled", normal)
	btn.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT_GOLD)
	btn.add_theme_color_override("font_hover_color", ThemeBuilder.COLOR_TEXT_GOLD)
	btn.add_theme_color_override("font_pressed_color", ThemeBuilder.COLOR_TEXT_GOLD)
	btn.add_theme_color_override("font_disabled_color", ThemeBuilder.COLOR_TEXT_MUTED)
	ThemeBuilder.apply_font_size(btn, ThemeBuilder.FONT_BODY)
	_prepare_slot_button(btn)


func _reset_slot_style(btn: Button, slot_idx: int) -> void:
	if btn == null:
		return
	for key in ["normal", "hover", "pressed", "disabled"]:
		btn.remove_theme_stylebox_override(key)
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
		btn.remove_theme_color_override(key)
	ThemeBuilder.apply_font_size(btn, ThemeBuilder.FONT_BODY)
	ThemeBuilder.apply_brush_kai(btn)
	ThemeBuilder.apply_slot_button(btn, slot_idx)
	ThemeBuilder.apply_font_size(btn, ThemeBuilder.FONT_BODY)
	_prepare_slot_button(btn)


# ---------------------------------------------------------------- 构建

func _build() -> void:
	# 上下两段式：上段图标 + 信息，下段铺满全宽的主次按钮
	var root := ThemeBuilder.vbox(8)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(root)

	var top := ThemeBuilder.hbox(8)
	top.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(top)

	_icon_frame = IconFrame.new()
	top.add_child(_icon_frame)
	_icon_frame.setup(_pick_icon_texture(), 56, _pick_icon_accent(), false, 36)

	_box = ThemeBuilder.vbox(6)
	_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_box)

	var head := ThemeBuilder.hbox(6)
	_box.add_child(head)
	_element_chip = ThemeBuilder.chip(ItemData.element_name(action.element), ItemData.element_color(action.element))
	head.add_child(_element_chip)
	_name_label = ThemeBuilder.card_title_label(_display_title())
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_label.clip_text = true
	_name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	head.add_child(_name_label)
	# 右侧实际单次耗时（火候/悟道池/坊市法器/境界全部乘区已计入）
	_interval_label = ThemeBuilder.label("", ThemeBuilder.FONT_BODY_SUB,
		ThemeBuilder.COLOR_TEXT_PRIMARY)
	head.add_child(_interval_label)
	_locked_chip = ThemeBuilder.chip("需 1 重", ThemeBuilder.COLOR_CINNABAR)
	_locked_chip.visible = false
	_locked_label = _locked_chip.get_child(0) as Label
	head.add_child(_locked_chip)
	_status_chip = PanelContainer.new()
	_status_chip.add_theme_stylebox_override("panel", ThemeBuilder.chip_box(ThemeBuilder.COLOR_TEXT_DIM))
	_status_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_chip.visible = false
	var status_row := ThemeBuilder.hbox(3)
	status_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_chip.add_child(status_row)
	_status_dot = ThemeBuilder.label("●", ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_JADE)
	_status_dot.visible = false
	status_row.add_child(_status_dot)
	_status_label = ThemeBuilder.label("待运转", ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_DIM)
	status_row.add_child(_status_label)
	head.add_child(_status_chip)

	# 运转条：全站统一翠玉绿胶囊（6px，无突出端点圆点，与右栏三才条一致）
	_progress = ThemeBuilder.progress_bar_run()
	_progress.clip_contents = true
	_box.add_child(_progress)

	_material_label = RichTextLabel.new()
	_material_label.bbcode_enabled = true
	_material_label.fit_content = true
	_material_label.scroll_active = false
	# 按词折行 + NBSP 防断：材料名与「×N (存X)」不再被拆到两行
	_material_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_material_label.custom_minimum_size = Vector2(0, 0)
	ThemeBuilder.apply_font_size(_material_label, ThemeBuilder.FONT_BODY_SUB, "normal_font_size")
	_material_label.add_theme_color_override("default_color", ThemeBuilder.COLOR_TEXT_DIM)
	_material_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_child(_material_label)

	var mastery_row := ThemeBuilder.hbox(4)
	_box.add_child(mastery_row)
	mastery_row.add_child(ThemeBuilder.dim_label("火候", ThemeBuilder.FONT_BODY_SUB))
	_mastery_bar = ThemeBuilder.progress_bar_grow()
	_mastery_bar.custom_minimum_size = Vector2(56, ThemeBuilder.BAR_HEIGHT_GROW)
	_mastery_bar.size_flags_horizontal = Control.SIZE_FILL
	_mastery_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mastery_row.add_child(_mastery_bar)
	_mastery_label = ThemeBuilder.dim_label("1 重", ThemeBuilder.FONT_BODY_SUB)
	mastery_row.add_child(_mastery_label)
	# 火候满级（150）徽章：替代淬炼按钮，温润鎏金、不可点
	_mastery_badge = ThemeBuilder.chip("已圆满", ThemeBuilder.COLOR_TEXT_GOLD)
	_mastery_badge.visible = false
	mastery_row.add_child(_mastery_badge)
	mastery_row.add_child(ThemeBuilder.expander())
	_synergy_chip = ThemeBuilder.chip("木生火 +15%", ThemeBuilder.COLOR_EMERALD)
	_synergy_chip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_synergy_chip.visible = false
	# 独立一行：与「火候 / 淬炼」同排时，窄屏大字档会把卡片乃至整页最小宽度顶爆
	_box.add_child(_synergy_chip)

	# 内联紧凑淬炼按钮：悟道池足够时琥珀金亮起
	_refine_button = ThemeBuilder.small_button("淬炼")
	_refine_button.custom_minimum_size = Vector2(76, ThemeBuilder.TOUCH_MIN)
	ThemeBuilder.apply_font_size(_refine_button, ThemeBuilder.FONT_BODY)
	ThemeBuilder.apply_brush_kai(_refine_button)
	_refine_button.add_theme_stylebox_override("normal",
		ThemeBuilder.panel_box(ThemeBuilder.COLOR_SUBTLE, Color(0, 0, 0, 0), 8, 0, 8))
	_refine_button.add_theme_stylebox_override("hover",
		ThemeBuilder.panel_box(ThemeBuilder.COLOR_GOLD_SOFT, ThemeBuilder.COLOR_AMBER, 8, 1, 8))
	_refine_button.add_theme_stylebox_override("disabled",
		ThemeBuilder.panel_box(Color("#F0EADF"), Color(0, 0, 0, 0), 8, 0, 8))
	_refine_button.tooltip_text = "消耗悟道值提升火候"
	_refine_button.pressed.connect(_on_refine_pressed)
	mastery_row.add_child(_refine_button)

	# 底部操作区：三态互斥（运转停止 / 缺料获取 / 空闲 N 枚槽位按钮）。
	# 全部按钮由 _create_slot_button 统一工厂创建，只靠三才配色分层，其余属性 100% 相同。
	var actions_row := ThemeBuilder.hbox(6)
	actions_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(actions_row)
	_start_buttons.clear()
	for i in range(GameState.SLOT_COUNT):
		var btn := _create_slot_button(i)
		btn.visible = i == 0
		actions_row.add_child(btn)
		_start_buttons.append(btn)
	_start_button = _start_buttons[0]
	# B 态按钮：缺料时与槽位按钮互斥显隐（浅鎏金底 + 沉金褐描边）
	_miss_button = ThemeBuilder.button("获取缺失原料 ▸")
	_miss_button.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
	_miss_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_miss_button.mouse_filter = Control.MOUSE_FILTER_PASS
	_miss_button.focus_mode = Control.FOCUS_NONE
	_miss_button.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	ThemeBuilder.apply_font_size(_miss_button, ThemeBuilder.FONT_BODY)
	ThemeBuilder.apply_brush_kai(_miss_button)
	_prepare_slot_button(_miss_button)
	var miss_normal := ThemeBuilder.panel_box(Color("#F5ECDC"),
		ThemeBuilder.COLOR_TEXT_GOLD, 8, 2, 8)
	miss_normal.border_width_bottom = 2
	_miss_button.add_theme_stylebox_override("normal", miss_normal)
	_miss_button.add_theme_stylebox_override("hover",
		ThemeBuilder.panel_box(Color("#EFE1CB"), ThemeBuilder.COLOR_TEXT_GOLD, 8, 2, 8))
	_miss_button.add_theme_stylebox_override("pressed",
		ThemeBuilder.panel_box(Color("#EADBC2"), ThemeBuilder.COLOR_TEXT_GOLD, 8, 2, 8))
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
		_miss_button.add_theme_color_override(key, Color("#7A5018"))
	_miss_button.visible = false
	_miss_button.pressed.connect(func() -> void: _handle_missing_materials(_missing_inputs()))
	actions_row.add_child(_miss_button)

	TooltipHelper.attach(self, action.description)


## 槽位按钮统一工厂：三枚按钮除三才配色外 100% 相同
## （毛笔楷体 + FONT_BODY + 44 高 + 全宽 + STOP 点击零丢失）
func _create_slot_button(slot_idx: int) -> Button:
	var btn := ThemeBuilder.button("开始运转")
	btn.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# §4.1 红线：按钮一律 PASS（按在按钮上也能滑动列表），防误触交给
	# prepare_touch 的 14px 滑动守卫；命中判定在轻点路径早已排除按钮区
	btn.mouse_filter = Control.MOUSE_FILTER_PASS
	btn.focus_mode = Control.FOCUS_NONE
	btn.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	# 占用态显示长动作名（如「炼制九转回元丹」）时省略号截断，三颗严格等宽
	btn.clip_text = true
	btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	ThemeBuilder.apply_font_size(btn, ThemeBuilder.FONT_BODY)
	ThemeBuilder.apply_brush_kai(btn)
	ThemeBuilder.apply_slot_button(btn, slot_idx)
	ThemeBuilder.apply_font_size(btn, ThemeBuilder.FONT_BODY)
	_prepare_slot_button(btn)
	if slot_idx == 0:
		btn.pressed.connect(_on_start_pressed)
	else:
		btn.text = GameState.get_slot_text(slot_idx, "start")
		btn.pressed.connect(_on_slot_pressed.bind(slot_idx))
	return btn


# ---------------------------------------------------------------- 刷新

## force = false 时若距上次刷新没有状态变化则直接跳过：
## 切页 / 切回 / 无关信号都不再重排 RichTextLabel 与按钮样式。
func refresh(force: bool = false) -> void:
	if action == null:
		return
	if not force and not _dirty:
		return
	_dirty = false
	var slot := GameState.get_slot_of_action(action.id)
	var running := slot >= 0
	var level := GameState.get_skill_level(action.skill_id)
	var locked := level < action.required_level
	var missing := _missing_inputs()
	var lacks := not missing.is_empty()

	if locked:
		modulate.a = 0.7
		_locked_chip.visible = true
		if _locked_label != null:
			_locked_label.text = "需 %d 重" % action.required_level
		_status_chip.visible = false
		_stop_status_breathing()
	else:
		modulate.a = 1.0
		_locked_chip.visible = false
		# 未运转且原料充足时不再显示“待运转”，状态由主按钮表达
		_status_chip.visible = running or lacks
		if not running:
			_stop_status_breathing()

	if running:
		# 主修中 / 分神中 / 化身中：徽章、描边、进度条统一取对应槽位专属色
		_apply_status_chip(GameState.get_slot_text(slot, "running"),
			ThemeBuilder.slot_dot_color(slot), true)
	else:
		_update_status_text(running, locked, lacks)
	_apply_card_running(running, slot)
	# 三态互斥按钮行：A 运转 / B 缺料 / C 空闲（只切显隐与文案，不重建节点）
	_render_button_row(slot, running, lacks, locked)

	_start_button.disabled = locked
	var mastery_maxed := GameState.get_mastery_level(action.id) >= GameFormulas.MAX_MASTERY_LEVEL
	_refine_button.disabled = locked or mastery_maxed

	_refresh_stats_line()
	_refresh_material()
	_refresh_detail_tap()
	_refresh_mastery()
	_synergy_chip.visible = ActionRunner.is_wood_fire_active(action) and not locked


## 指定槽位启动（分神 / 化身）：成功后必须立刻刷新本卡
## （否则 chip 不变成「化身中」、按钮不变成「停止化身」，玩家以为没点上会反复点）
func _on_slot_pressed(slot: int) -> void:
	if action == null:
		return
	if GameState.start_action_in_slot(action.id, slot):
		GameState.vibrate_light()
		refresh(true)


## 三态互斥按钮行（唯一优先级入口，杜绝按钮混排）：
##   A 运转中 → 仅 1 枚全宽「停止XX」；B 缺料 → 仅 1 枚全宽「获取缺失原料 ▸」；
##   C 空闲且料足 → 按解锁数 1/2/3 枚等宽槽位按钮。
func _render_button_row(slot: int, running: bool, lacks: bool, locked: bool) -> void:
	var unlocked := GameState.get_max_action_slots()
	var single := unlocked <= 1
	if running:
		_miss_button.visible = false
		for i in range(_start_buttons.size()):
			_start_buttons[i].visible = i == 0
		_start_button.disabled = false
		_start_button.text = "停止主修" if single else "停%s" % _slot_name(slot)
		ThemeBuilder.apply_stop_slot_button(_start_button)
		ThemeBuilder.apply_font_size(_start_button, ThemeBuilder.FONT_BODY)
		_prepare_slot_button(_start_button)
		return
	if lacks and not locked:
		for btn in _start_buttons:
			btn.visible = false
		_miss_button.visible = true
		var missing := _missing_inputs()
		_miss_button.text = ("前往获取：%s ▸" % DataRegistry.get_item_name(
			String(missing[0].get("item_id", "")))) if missing.size() == 1 \
			else "获取缺失原料 ▸"
		return
	_miss_button.visible = false
	for i in range(_start_buttons.size()):
		var btn := _start_buttons[i]
		btn.visible = i < unlocked
		btn.disabled = locked
		btn.tooltip_text = ""
		if not btn.visible:
			continue
		if locked:
			btn.text = ("开始%s" % _action_verb()) if single else _slot_name(i)
			_reset_slot_style(btn, i)
			continue
		var slot_action := GameState.get_active_action(i)
		if slot_action != "" and slot_action != action.id:
			btn.text = ("切换%s" % _action_verb()) if single else ("换%s" % _slot_name(i))
			btn.tooltip_text = "当前占用：%s" % DataRegistry.get_action_name(slot_action)
			_apply_occupied_gold_style(btn)
		else:
			btn.text = ("开始%s" % _action_verb()) if single else _slot_name(i)
			_reset_slot_style(btn, i)


func _lacks_material() -> bool:
	return not _missing_inputs().is_empty()


## 当前缺口原料：[{item_id, missing}]
func _missing_inputs() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if action == null:
		return out
	for item_id in action.inputs.keys():
		var need_count := int(action.inputs[item_id])
		var have := GameState.get_item_count(String(item_id))
		if have < need_count:
			out.append({"item_id": String(item_id), "missing": need_count - have})
	return out


## 顶部状态文字：未解锁 / 运转中 / 原料不足 / 待运转
func _update_status_text(running: bool, locked: bool, lacks: bool) -> void:
	if _status_label == null or locked:
		return
	if running:
		# 主修中 / 分神中 / 化身中：文字与徽章色都跟随对应槽位
		var slot := GameState.get_slot_of_action(action.id)
		_apply_status_chip(GameState.get_slot_text(slot, "running"),
			ThemeBuilder.slot_dot_color(slot), true)
	elif lacks:
		_apply_status_chip("原料不足", ThemeBuilder.COLOR_CINNABAR)
	else:
		_apply_status_chip("待运转", ThemeBuilder.COLOR_TEXT_DIM)


func _apply_status_chip(text_value: String, color: Color, show_dot: bool = false) -> void:
	if _status_chip == null or _status_label == null:
		return
	_status_dot.visible = show_dot
	_status_dot.add_theme_color_override("font_color", color)
	_status_label.text = text_value
	_status_label.add_theme_color_override("font_color", color.darkened(0.08))
	_status_chip.add_theme_stylebox_override("panel", ThemeBuilder.chip_box(color))
	if show_dot:
		_start_status_breathing()
	else:
		_stop_status_breathing()


func _start_status_breathing() -> void:
	if _status_dot == null or not is_visible_in_tree():
		return
	if _status_breath_tween != null and _status_breath_tween.is_valid():
		return
	_status_dot.modulate.a = 1.0
	_status_breath_tween = create_tween().set_loops()
	_status_breath_tween.tween_property(_status_dot, "modulate:a", 0.4, 0.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_status_breath_tween.tween_property(_status_dot, "modulate:a", 1.0, 0.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _stop_status_breathing() -> void:
	if _status_breath_tween != null and _status_breath_tween.is_valid():
		_status_breath_tween.kill()
	_status_breath_tween = null
	if _status_dot != null:
		_status_dot.modulate.a = 1.0


func _apply_start_style(running: bool, guiding: bool = false) -> void:
	var bg := ThemeBuilder.COLOR_CINNABAR_SOFT if running else ThemeBuilder.COLOR_JADE
	var border := ThemeBuilder.COLOR_CINNABAR if running else ThemeBuilder.COLOR_JADE_EDGE
	var font_color := ThemeBuilder.COLOR_CINNABAR if running else ThemeBuilder.COLOR_CARD
	if guiding:
		# 缺料引导：浅泥金底 + 深金字 + 1px 淡金边，与可运转玉青实底区分
		bg = ThemeBuilder.COLOR_GOLD_SOFT
		border = Color("#DECBA1")
		font_color = ThemeBuilder.COLOR_AMBER
	var normal_box := ThemeBuilder.panel_box(bg, border, 8, 1 if guiding else 0, 12)
	if not running and not guiding:
		normal_box.border_width_bottom = 2
	_start_button.add_theme_stylebox_override("normal", normal_box)
	var hover_bg := bg.darkened(0.04)
	var hover_border := border
	if guiding:
		hover_bg = Color("#F1E6CE")
		hover_border = ThemeBuilder.COLOR_AMBER
	elif not running:
		hover_bg = ThemeBuilder.COLOR_JADE_DARK
	var hover := ThemeBuilder.panel_box(hover_bg, hover_border, 8, 1 if guiding else 0, 12)
	if not running and not guiding:
		hover.border_width_bottom = 2
	_start_button.add_theme_stylebox_override("hover", hover)
	_start_button.add_theme_stylebox_override("pressed",
		ThemeBuilder.panel_box(bg.darkened(0.08), Color(0, 0, 0, 0), 8, 0, 12))
	_start_button.add_theme_color_override("font_color", font_color)
	_start_button.add_theme_color_override("font_hover_color", font_color)
	_start_button.add_theme_color_override("font_pressed_color", font_color)


## 标题右侧实际单次耗时；完整明细走「点卡片」详情浮层
func _refresh_stats_line() -> void:
	if _interval_label == null:
		return
	_interval_label.text = "%.2fs" % ActionRunner.get_effective_interval(action.id)


func _refresh_material() -> void:
	if action == null or _material_label == null:
		return
	var parts: Array[String] = []

	# 同行主次拆色：材料名走主数值色、括号库存走辅助灰、不足才用朱砂警示
	var c_primary := ThemeBuilder.hex(ThemeBuilder.COLOR_TEXT_PRIMARY)
	var c_secondary := ThemeBuilder.hex(ThemeBuilder.COLOR_TEXT_SECONDARY)
	var c_danger := ThemeBuilder.hex(ThemeBuilder.COLOR_TEXT_DANGER)
	var c_muted := ThemeBuilder.hex(ThemeBuilder.COLOR_TEXT_MUTED)
	var c_gold := ThemeBuilder.hex(ThemeBuilder.COLOR_TEXT_GOLD)
	var c_jade := ThemeBuilder.hex(ThemeBuilder.COLOR_TEXT_JADE)

	if action.inputs.is_empty():
		# 采集 / 吐纳等无原料卡片：保持原有单行「产出×N (存X)」展示不变
		if action.pill_item_id == "" and not action.is_gather():
			parts.append("[color=%s]无需材料[/color]" % c_muted)
		var out_parts: Array[String] = []
		for item_id in action.outputs.keys():
			var per := int(action.outputs[item_id])
			var have := GameState.get_item_count(String(item_id))
			out_parts.append("%s[color=%s]×%d (存%s)[/color]" % [
				ThemeBuilder.format_item_grade_bbcode(String(item_id)),
				c_secondary, per, GameFormulas.format_num(float(have))])
		if action.cultivation_gain > 0:
			out_parts.append("[color=%s]修为+%d[/color]" % [
				c_gold, GameState.get_meditate_cultivation_gain(action.id)])
		if out_parts.is_empty():
			out_parts.append("[color=%s]—[/color]" % c_muted)
		var left_text := " + ".join(parts)
		var right_text := " + ".join(out_parts)
		var material_text := ("%s  →  %s" % [left_text, right_text]) \
			if left_text != "" else right_text
		var seed_drop := DataRegistry.get_seed_drop(action.id)
		if not seed_drop.is_empty():
			material_text += " [color=%s]+灵种[/color]" % c_jade
		_material_label.text = ThemeBuilder.protect_phrases(material_text)
		return

	# 制造类：原料只留「名称×数量」，缺料整项标红；产出另起一行，避免行尾悬空 + / →
	var input_parts: Array[String] = []
	for item_id in action.inputs.keys():
		var need_count := int(action.inputs[item_id])
		var have := GameState.get_item_count(String(item_id))
		var short := have < need_count
		var name_bb := ThemeBuilder.format_item_grade_bbcode(String(item_id))
		if short:
			name_bb = "[color=%s]%s[/color]" % [c_danger,
				DataRegistry.get_item_name(String(item_id))]
		var qty_color := c_danger if short else c_secondary
		input_parts.append("%s[color=%s]×%d[/color]" % [
			name_bb, qty_color, need_count])
	if action.pill_item_id != "" and GameState.is_flag("auto_pill", false):
		var pill_have := GameState.get_item_count(action.pill_item_id)
		var pill_short := pill_have <= 0
		var pill_name := ThemeBuilder.format_item_grade_bbcode(action.pill_item_id)
		if pill_short:
			pill_name = "[color=%s]%s[/color]" % [c_danger,
				DataRegistry.get_item_name(action.pill_item_id)]
		input_parts.append("%s[color=%s]×1[/color]" % [pill_name,
			c_danger if pill_short else c_secondary])
	var input_line := " · ".join(input_parts)

	var output_line := ""
	if action.outputs.size() == 1:
		var out_id := String(action.outputs.keys()[0])
		var per := int(action.outputs[out_id])
		var have := GameState.get_item_count(out_id)
		output_line = "每次产 ×%d · 持有 %s" % [per, GameFormulas.format_num(float(have))]
	elif action.outputs.size() > 1:
		var out_parts: Array[String] = []
		for item_id in action.outputs.keys():
			out_parts.append("%s×%d" % [
				ThemeBuilder.format_item_grade_bbcode(String(item_id)),
				int(action.outputs[item_id])])
		output_line = "每次产 " + " · ".join(out_parts)
	if action.cultivation_gain > 0:
		output_line += (" · " if output_line != "" else "") \
			+ "修为+%d" % GameState.get_meditate_cultivation_gain(action.id)
	var seed_drop := DataRegistry.get_seed_drop(action.id)
	if not seed_drop.is_empty():
		output_line += (" · " if output_line != "" else "") \
			+ "[color=%s]+灵种[/color]" % c_jade
	var material_text := input_line
	if output_line != "":
		material_text += "\n" + output_line
	_material_label.text = ThemeBuilder.protect_phrases(material_text)


func _refresh_mastery() -> void:
	if action == null:
		return
	var progress := GameState.get_mastery_progress(action.id)
	var level := int(progress["level"])
	# 减耗百分比收进详情浮层，卡片上只留等级
	_mastery_label.text = "%d 重" % level
	if bool(progress["maxed"]):
		_mastery_label.text = "%d 重 · 圆满" % GameFormulas.MAX_MASTERY_LEVEL
		UiMotion.advance_progress(_mastery_bar, 1.0)
	else:
		UiMotion.advance_progress(_mastery_bar, float(progress["ratio"]))
	_update_refine_button()


# ---------------------------------------------------------------- 交互

## 轻点卡片空白处：完整数值明细（耗时构成 / 经验 / 双倍率构成 / 副产概率 / 火候减耗）
func _refresh_detail_tap() -> void:
	if action != null and not has_meta("tap_press"):
		ThemeBuilder.make_card_tappable(self, _show_detail)


func _show_detail() -> void:
	if action == null:
		return
	if AudioManager != null:
		AudioManager.play_tap()

	var interval := ActionRunner.get_effective_interval(action.id)
	var base := maxf(0.01, action.base_interval)
	var reduced := maxf(0.0, (1.0 - interval / base) * 100.0)
	var tags: Array = []
	var element_name := ItemData.element_name(action.element)
	if element_name != "" and element_name != "无":
		tags.append({"text": element_name + "行", "color": ItemData.element_color(action.element)})
	var skill_name := GameState.get_skill_display_name(action.skill_id)
	if skill_name != "":
		tags.append({"text": skill_name, "color": ThemeBuilder.COLOR_TEXT_JADE})

	var rows: Array = []
	rows.append({
		"label": "单次耗时", "value": "%.2fs" % interval,
		"color": ThemeBuilder.COLOR_TEXT_PRIMARY,
	})
	var outputs: Array[String] = []
	for item_id in action.outputs.keys():
		outputs.append("%s ×%d" % [DataRegistry.get_item_name(String(item_id)),
			int(action.outputs[item_id])])
	if not outputs.is_empty():
		rows.append({
			"label": "本次采获" if action.inputs.is_empty() else "配方产出",
			"value": " · ".join(outputs), "color": ThemeBuilder.COLOR_TEXT_JADE,
		})
	if not action.inputs.is_empty():
		var inputs: Array[String] = []
		for item_id in action.inputs.keys():
			# 详情里保留精确库存，卡片上不写「(存xxx)」以保持紧凑
			inputs.append("%s ×%d（存%s）" % [
				DataRegistry.get_item_name(String(item_id)),
				int(action.inputs[item_id]),
				GameFormulas.format_num(float(GameState.get_item_count(String(item_id))))])
		rows.append({
			"label": "所需原料", "value": " · ".join(inputs),
			"color": ThemeBuilder.COLOR_TEXT_PRIMARY,
		})
	rows.append({
		"label": "技能经验", "value": "+%d" % GameState.get_action_skill_xp_gain(action.id),
		"color": ThemeBuilder.COLOR_TEXT_GOLD,
	})
	rows.append({
		"label": "火候经验", "value": "+%d" % GameState.get_action_mastery_xp_gain(action.id),
		"color": ThemeBuilder.COLOR_TEXT_GOLD,
	})
	rows.append({
		"label": "双倍产出",
		"value": "%.0f%%" % (ActionRunner.get_double_chance(action.id) * 100.0),
		"color": ThemeBuilder.COLOR_TEXT_JADE,
	})
	if action.skill_id == "alchemy":
		# 洞府灵气反哺：与 FarmPanel 同一动态出口，不再写死 8%
		var farm_aura := GameState.get_farm_aura_alchemy_bonus()
		if farm_aura > 0.0001:
			rows.append({
				"label": "洞府灵气反哺",
				"value": "+%.0f%%" % (farm_aura * 100.0),
				"color": ThemeBuilder.COLOR_TEXT_JADE,
			})
	var seed_drop := DataRegistry.get_seed_drop(action.id)
	if not seed_drop.is_empty():
		rows.append({
			"label": "副产灵种",
			"value": "%s · %d%%" % [DataRegistry.get_item_name(
				String(seed_drop.get("seed_id", ""))),
				int(round(float(seed_drop.get("chance", 0.0)) * 100.0))],
			"color": ThemeBuilder.COLOR_TEXT_GOLD,
		})
	if action.cultivation_gain > 0:
		rows.append({
			"label": "单次修为",
			"value": "+%d" % GameState.get_meditate_cultivation_gain(action.id),
			"color": ThemeBuilder.COLOR_TEXT_GOLD,
		})

	var note := "基础 %.1f 秒，受火候、悟道池、法器与境界共同加成，耗时已缩减 %.1f%%。" \
		% [base, reduced]
	if action.inputs.is_empty():
		note += "\n本次采获为单次所得，采集时另有灵种机缘。"
	else:
		note += "\n配方产出为单次所得，所需原料在运转时逐轮消耗。"
	note += "\n双倍产出受火候、悟道池里程碑与坊市法器增益；丹道另享洞府灵气反哺。"
	BottomSheet.show_detail({
		"title": action.display_name,
		"icon": _pick_icon_texture(),
		"icon_accent": _pick_icon_accent(),
		"tags": tags,
		"rows": rows,
		"note": note,
	})


func _on_start_pressed() -> void:
	if action == null:
		return
	var slot := GameState.get_slot_of_action(action.id)
	if slot >= 0:
		GameState.stop_action(slot)
		GameState.vibrate_light()
		refresh(true)
		return
	if GameState.get_skill_level(action.skill_id) < action.required_level:
		return
	var missing := _missing_inputs()
	if not missing.is_empty():
		_handle_missing_materials(missing)
		return
	GameState.start_action(action.id)
	if GameState.get_slot_of_action(action.id) >= 0:
		GameState.vibrate_light()
	refresh(true)


## 缺 1 种：直达最高优先级来源；缺多种：弹出获取指引
func _handle_missing_materials(missing: Array[Dictionary]) -> void:
	if AudioManager != null:
		AudioManager.play_error()
	if missing.size() == 1:
		var item_id := String(missing[0].get("item_id", ""))
		var sources := DataRegistry.get_item_sources(item_id)
		if sources.is_empty():
			EventBus.toast.emit("暂无「%s」的已知来源" % DataRegistry.get_item_name(item_id))
			return
		EventBus.navigate_to_source.emit(sources[0])
		return
	_open_missing_guide(missing)


func _open_missing_guide(missing: Array[Dictionary]) -> void:
	var blocks: Array = []
	for entry in missing:
		var item_id := String(entry.get("item_id", ""))
		blocks.append({
			"item_id": item_id,
			"name": DataRegistry.get_item_name(item_id),
			"missing": int(entry.get("missing", 0)),
			"sources": DataRegistry.get_item_sources(item_id),
		})
	BottomSheet.show_sources("缺失原料获取指引", blocks)


## 淬炼按钮状态：悟道池足够 → 琥珀金亮起；不足/满级 → 灰置 + tooltip 说明
func _update_refine_button() -> void:
	if _refine_button == null or action == null:
		return
	if GameState.get_mastery_level(action.id) >= GameFormulas.MAX_MASTERY_LEVEL:
		# 满级不再给可点的「淬炼」，改为「已圆满」鎏金徽章
		_refine_button.visible = false
		_mastery_badge.visible = true
		return
	_refine_button.visible = true
	_mastery_badge.visible = false
	var preview := GameState.preview_mastery_spend(action.id)
	var cost := maxf(1.0, float(preview.get("cost", 0.0)))
	var pool := GameState.get_pool_current(action.skill_id)
	var affordable := pool >= cost
	_refine_button.text = "淬炼"
	_refine_button.disabled = not affordable
	_refine_button.tooltip_text = "需消耗 %s 悟道值提升火候" % GameFormulas.format_num(cost)
	_apply_refine_style(affordable)


func _apply_refine_style(affordable: bool) -> void:
	var border := ThemeBuilder.COLOR_AMBER if affordable else Color(0, 0, 0, 0)
	var bg := ThemeBuilder.COLOR_GOLD_SOFT if affordable else ThemeBuilder.COLOR_SUBTLE
	var fg := ThemeBuilder.COLOR_AMBER if affordable else ThemeBuilder.COLOR_TEXT_DIM
	_refine_button.add_theme_stylebox_override("normal",
		ThemeBuilder.panel_box(bg, border, 8, 1 if affordable else 0, 8))
	_refine_button.add_theme_color_override("font_color", fg)
	_refine_button.add_theme_color_override("font_disabled_color", ThemeBuilder.COLOR_TEXT_MUTED)


func _on_refine_pressed() -> void:
	if action == null:
		return
	if GameState.get_skill_level(action.skill_id) < action.required_level:
		return
	var preview := GameState.preview_mastery_spend(action.id)
	if not bool(preview.get("ok", false)):
		EventBus.toast.emit("悟道池不足，无法淬炼")
		return
	var warnings: Array = preview.get("warnings", [])
	for warning in warnings:
		EventBus.toast.emit(String(warning))
	GameState.spend_pool_for_mastery(action.id)
	if is_visible_in_tree() and _icon_frame != null and InkVfxLayer.instance != null:
		InkVfxLayer.instance.play_hammer(_icon_frame.get_global_rect().get_center(),
			InkVfxLayer.INK_JADE, InkVfxLayer.INK_GOLD)
	refresh(true)


## 运转中的卡片才亮起对应槽位专属色描边、极淡同色内底与同色运转条
func _apply_card_running(running: bool, slot: int = 0) -> void:
	if _style_box == null:
		return
	var accent := ThemeBuilder.slot_dot_color(slot)
	_style_box.bg_color = ThemeBuilder.card_color(
		ThemeBuilder.slot_paper_color(slot) if running else ThemeBuilder.COLOR_CARD)
	_style_box.border_color = accent if running else ThemeBuilder.COLOR_BORDER
	_style_box.set_border_width_all(2 if running else 1)
	if _progress != null:
		# 6px 胶囊、无端点圆头；只换只读样式引用
		ThemeBuilder.set_bar_fill(_progress,
			accent if running else ThemeBuilder.COLOR_BAR_RUN)


# ---------------------------------------------------------------- 信号

## 隐藏卡片只置脏，切回时统一补刷一次（切页不再被动触发整页重排）
func _mark_dirty_and_refresh() -> void:
	_dirty = true
	if is_visible_in_tree():
		refresh()


func _on_action_state_signal(_slot: int, action_id: String) -> void:
	if action != null and action_id == action.id:
		_mark_dirty_and_refresh()


func _on_action_completed(_slot: int, action_id: String, gained: Dictionary) -> void:
	if action != null and action_id == action.id:
		UiMotion.flash_once(_progress)
		_spawn_output_effect()
		_spawn_output_float(gained)


## 滚动视口防穿模校验：折叠/切页/滚出 ScrollContainer 可视区的卡片一律不播飘字，
## 杜绝「+1 XXX」与笔触残影从顶部总览卡标题上穿出的穿模现象
func _in_scroll_viewport() -> bool:
	if not is_visible_in_tree():
		return false
	var node: Node = get_parent()
	var scroll: ScrollContainer = null
	while node != null:
		if node is ScrollContainer:
			scroll = node
			break
		node = node.get_parent()
	if scroll == null:
		return true
	var vp := scroll.get_global_rect()
	var card := get_global_rect()
	return card.position.y >= vp.position.y - 8.0 \
		and card.end.y <= vp.end.y + 8.0


## 百艺完成笔触：技能 → 样式映射集中在 InkVfxLayer.play_skill_finish()，此处只传 skill_id
func _spawn_output_effect() -> void:
	if action == null or _icon_frame == null or not _in_scroll_viewport():
		return
	if InkVfxLayer.instance == null:
		return
	InkVfxLayer.instance.play_skill_finish(action.skill_id,
		_icon_frame.get_global_rect().get_center())


func _spawn_output_float(gained: Dictionary) -> void:
	if action == null or _icon_frame == null or InkVfxLayer.instance == null:
		return
	if not _in_scroll_viewport():
		return
	var parts: Array[String] = []
	var items: Dictionary = gained.get("items", {})
	for item_id in items.keys():
		var count := int(items[item_id])
		if count > 0:
			parts.append("+%d %s" % [count, DataRegistry.get_item_name(String(item_id))])
	var cultivation := int(gained.get("cultivation", 0))
	if cultivation > 0:
		parts.append("修为 +%d" % cultivation)
	if parts.is_empty():
		return
	var triple := bool(gained.get("triple", false))
	var special := bool(gained.get("doubled", false)) \
		or int(gained.get("quality", 0)) > 0 or triple
	var color := ThemeBuilder.COLOR_AMBER if special else ThemeBuilder.COLOR_TEXT
	if triple:
		parts.insert(0, "三倍灵韵暴产！")
	# 起点锚定图标框中上部（非卡片顶边），上浮 20px：贴顶卡片的飘字不越过滚动视口上沿
	var origin := _icon_frame.get_global_rect().position + Vector2(0.0, 10.0)
	if InkVfxLayer.instance != null:
		InkVfxLayer.instance.play_float(origin, " · ".join(parts), color,
			16 if special else 13, special, 20.0)


## 动作专属图标 > 产出物图标 > 技能通用图标
func _pick_icon_texture() -> Texture2D:
	if action == null:
		return IconLibrary.get_ui_icon("default")
	var icon_key := DataRegistry.get_action_icon_key(action.id)
	if icon_key != "":
		return IconLibrary.get_action_icon(icon_key)
	for item_id in action.outputs.keys():
		return IconLibrary.get_item_icon(String(item_id))
	return IconLibrary.get_skill_icon(action.skill_id)


func _pick_icon_accent() -> Color:
	if action == null:
		return ThemeBuilder.COLOR_JADE
	return ItemData.element_color(action.element)


func _on_mastery_changed(action_id: String, _xp: float, _level: int) -> void:
	if action != null and action_id == action.id:
		if not is_visible_in_tree():
			_dirty = true
			return
		_refresh_mastery()


func _on_pool_changed(skill_id: String, _current: float, _capacity: float) -> void:
	if action != null and skill_id == action.skill_id:
		if not is_visible_in_tree():
			_dirty = true
			return
		_refresh_stats_line()
		_refresh_mastery()
		_update_refine_button()


func _on_skill_xp_changed(skill_id: String, _xp: float, _level: int) -> void:
	if action != null and skill_id == action.skill_id:
		_mark_dirty_and_refresh()


## 脏标记合并刷新：同帧多信号只重绘一次
var _refresh_queued := false


func _queue_refresh() -> void:
	if _refresh_queued:
		return
	_refresh_queued = true
	call_deferred("_do_queued_refresh")


func _do_queued_refresh() -> void:
	_refresh_queued = false
	_mark_dirty_and_refresh()


func _on_equipment_changed() -> void:
	_queue_refresh()


func _on_realm_changed(_realm_id: String, _realm_name: String) -> void:
	_queue_refresh()


func _on_visibility_changed() -> void:
	var vis := is_visible_in_tree()
	_was_visible = vis
	if vis:
		set_process(true)
		refresh()
	else:
		_stop_status_breathing()
		set_process(false)


