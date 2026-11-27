class_name DynamicIslandPopover
extends Control
## 「三才运转」灵动岛式原位弹性浮层：从顶栏状态胶囊位置展开/收起。
## 网格对齐版：四列严格对齐（图标 30 → 徽标 42 → 名称/全宽进度条 → 双图标按钮 86px），
## 中间主区「名称左 + 数值右」一行 + 全宽 6px 进度条一行，四行基线零偏差。

const MASK_COLOR := Color(0.14, 0.12, 0.10, 1.0)   # 暖墨遮罩（modulate 渐显至 0.42）
const MASK_ALPHA := 0.42
const ROW_BG := Color("#F3EDE2")                   # 内嵌子卡浅米底
const ROW_BORDER := Color("#D8CDBA")               # 浅褐描边
const ICON_SIZE := 30                              # 图标列固定宽
const BADGE_MIN_X := 42                            # 徽标列固定宽（2 字居中）
const OPS_W := 40                                  # 单枚图标按钮宽（2×40 + 6 = 86px 固定）

var _mask: ColorRect
var _card: PanelContainer
var _card_style: StyleBoxFlat
var _margin: MarginContainer
var _content: VBoxContainer
var _rows: Array = []
var _tween: Tween
var _origin: Rect2
var _busy := false
var _signature_cache := ""
var _text_accum: float = 0.0
## 快捷启程按钮的跳转回调（MainShell 注入 _show_panel）
var navigate_callback: Callable = Callable()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 50
	visible = false

	_mask = ColorRect.new()
	_mask.color = MASK_COLOR
	_mask.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_mask.mouse_filter = Control.MOUSE_FILTER_STOP
	_mask.modulate.a = 0.0
	_mask.gui_input.connect(func(event: InputEvent) -> void:
		if (event is InputEventMouseButton and (event as InputEventMouseButton).pressed) \
				or (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed):
			hide_island())
	add_child(_mask)

	_card = PanelContainer.new()
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	_card.clip_contents = true   # 形变期防子卡溢出胶囊边界
	_card_style = ThemeBuilder.panel_box(ThemeBuilder.COLOR_CARD,
		ThemeBuilder.COLOR_JADE, 18, 1, 0)
	_card_style.border_width_left = 2
	_card_style.border_width_right = 2
	_card_style.border_width_top = 2
	_card_style.border_width_bottom = 2
	_card_style.shadow_color = Color(0.08, 0.06, 0.04, 0.28)
	_card_style.shadow_size = 10
	_card.add_theme_stylebox_override("panel", _card_style)
	add_child(_card)

	_margin = MarginContainer.new()
	_margin.add_theme_constant_override("margin_left", 14)
	_margin.add_theme_constant_override("margin_right", 14)
	_margin.add_theme_constant_override("margin_top", 12)
	_margin.add_theme_constant_override("margin_bottom", 12)
	_card.add_child(_margin)

	_content = ThemeBuilder.vbox(8)
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_margin.add_child(_content)


## 从胶囊位置弹性展开（防连点：动画期间忽略重复调用）
func show_at(origin: Rect2) -> void:
	if _busy or visible:
		return
	_origin = origin
	_refresh_content()
	var vp := get_viewport_rect().size
	var w := maxf(200.0, minf(vp.x - 32.0, 460.0))
	var h := _content.get_combined_minimum_size().y + 24.0
	h = clampf(h, 96.0, vp.y * 0.72)
	var x := maxf(16.0, (vp.x - w) * 0.5)
	var y := maxf(origin.position.y, 8.0)
	var target := Rect2(Vector2(x, y), Vector2(w, h))
	_card.position = origin.position
	_card.size = origin.size
	_set_corner(18)
	_content.modulate.a = 0.0
	_mask.modulate.a = 0.0
	visible = true
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(_card, "position", target.position, 0.26) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_card, "size", target.size, 0.26) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_method(_set_corner, 18.0, 16.0, 0.26)
	_tween.tween_property(_content, "modulate:a", 1.0, 0.22)
	_tween.tween_property(_mask, "modulate:a", MASK_ALPHA, 0.20)


## 原路缩回收起（TRANS_CUBIC / EASE_IN）
func hide_island() -> void:
	if not visible or _busy:
		return
	_busy = true
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(_card, "position", _origin.position, 0.18) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.tween_property(_card, "size", _origin.size, 0.18) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.tween_property(_content, "modulate:a", 0.0, 0.16)
	_tween.tween_property(_mask, "modulate:a", 0.0, 0.16)
	_tween.chain().tween_callback(func() -> void:
		visible = false
		_busy = false)


func _set_corner(radius: float) -> void:
	_card_style.set_corner_radius_all(int(radius))


func _process(delta: float) -> void:
	if not visible or _busy:
		return
	# 文本每 0.25 秒才重设一次，避免逐帧触发布局重排；进度条仍每帧连续更新
	_text_accum += delta
	var update_text := _text_accum >= 0.25
	if update_text:
		_text_accum = 0.0
	for entry in _rows:
		var kind := String(entry.get("kind", "slot"))
		var bar: ProgressBar = entry.get("bar", null)
		var value_lbl: Label = entry.get("time", null)
		if kind == "combat":
			var enemy = CombatEngine.get_current_enemy()
			if enemy == null:
				continue
			var ratio := clampf(float(CombatEngine.enemy_hp) / float(maxi(1, enemy.max_hp)),
				0.0, 1.0)
			if bar != null:
				bar.value = ratio
			if update_text and value_lbl != null:
				value_lbl.text = GameFormulas.format_num(
					float(maxi(0, int(CombatEngine.enemy_hp))))
			continue
		var slot := int(entry.get("slot", -1))
		if slot < 0:
			continue
		var action_id := GameState.get_active_action(slot)
		if action_id == "":
			if bar != null:
				bar.value = 0.0
			if update_text and value_lbl != null:
				value_lbl.text = ""
			continue
		var progress := ActionRunner.get_progress(slot)
		if bar != null:
			# 与 ActionCard 完全同向：从左往右蓄势填满 0.0→1.0，满格结算后重置
			bar.value = clampf(progress, 0.0, 1.0)
		if update_text and value_lbl != null:
			var left := ActionRunner.get_effective_interval(action_id) * (1.0 - progress)
			value_lbl.text = "%.1fs" % maxf(0.0, left)
	var signature := _state_signature()
	if signature != _signature_cache:
		_refresh_content()


func _state_signature() -> String:
	var parts: Array[String] = []
	if CombatEngine.is_active():
		var enemy = CombatEngine.get_current_enemy()
		parts.append("c:%s" % (enemy.id if enemy != null else "?"))
	for slot in range(GameState.SLOT_COUNT):
		parts.append("%d:%s" % [slot, GameState.get_active_action(slot)])
	return "|".join(parts)


# ---------------------------------------------------------------- 内容构建

func _refresh_content() -> void:
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	_rows.clear()

	# 头部整组水平居中：标题 + 徽标 + 紧凑收起胶囊（全部 SHRINK_CENTER 垂直齐平）
	var idle := _total_active() <= 0
	var head := ThemeBuilder.hbox(8)
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(head)
	var title := ThemeBuilder.label("三才静修" if idle else "三才运转",
		ThemeBuilder.FONT_CARD_TITLE, ThemeBuilder.COLOR_TEXT)
	ThemeBuilder.apply_brush_kai(title)
	ThemeBuilder.apply_font_size(title, ThemeBuilder.FONT_CARD_TITLE)
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ThemeBuilder.fit_wrapped_label(title, title.text, null, 0.0, 180.0)
	head.add_child(title)
	var running := GameState.get_running_slots().size()
	if idle:
		head.add_child(_make_chip("全槽空闲", ThemeBuilder.COLOR_TEXT_SECONDARY))
	elif CombatEngine.is_active():
		head.add_child(_make_chip("%d 路并行" % (1 + running), ThemeBuilder.COLOR_CINNABAR))
	else:
		head.add_child(_make_chip("%d/%d 运转中" % [running, GameState.get_max_action_slots()],
			ThemeBuilder.COLOR_JADE))
	var close_btn := ThemeBuilder.button("收起")
	close_btn.custom_minimum_size = Vector2(56, ThemeBuilder.TOUCH_MIN)
	close_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ThemeBuilder.apply_font_size(close_btn, ThemeBuilder.FONT_BODY_SUB)
	ThemeBuilder.apply_brush_kai(close_btn)
	var close_box := ThemeBuilder.panel_box(Color("#EFE9DE"), ThemeBuilder.COLOR_BORDER,
		10, 1, 8)
	close_box.content_margin_left = 10
	close_box.content_margin_right = 10
	close_btn.add_theme_stylebox_override("normal", close_box)
	close_btn.add_theme_stylebox_override("hover",
		ThemeBuilder.panel_box(Color("#E8E0D2"), ThemeBuilder.COLOR_BORDER, 10, 1, 8))
	close_btn.add_theme_stylebox_override("pressed",
		ThemeBuilder.panel_box(Color("#E2D8C6"), ThemeBuilder.COLOR_BORDER, 10, 1, 8))
	close_btn.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT_SECONDARY)
	close_btn.pressed.connect(hide_island)
	head.add_child(close_btn)

	if CombatEngine.is_active():
		_content.add_child(_build_combat_row())
	for slot in range(GameState.SLOT_COUNT):
		if not GameState.is_slot_unlocked(slot):
			continue
		_content.add_child(_build_slot_row(slot))
	# 全空闲态：底部快捷启程一行（真仙圆满智能换后期入口）
	if idle:
		_content.add_child(_build_quick_nav())
	_signature_cache = _state_signature()

	ThemeBuilder.prepare_touch(_card)
	_card.mouse_filter = Control.MOUSE_FILTER_STOP


## 内嵌浅米子卡包装：底 #F3EDE2 / 圆角 12 / 浅褐描边 / 内边距 10×8
func _wrap_row(inner: Control) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := ThemeBuilder.panel_box(ROW_BG, ROW_BORDER, 12, 1, 0)
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", box)
	card.add_child(inner)
	return card


## 中间主区：上行「名称左 + 数值右」，下行全宽 6px 进度条（四列网格的弹性列）
func _build_mid(name_text: String, grade_item_id: String, idle: bool) -> Dictionary:
	var mid := ThemeBuilder.vbox(6)
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var top := ThemeBuilder.hbox(6)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mid.add_child(top)
	var name_lbl := ThemeBuilder.label(name_text, ThemeBuilder.FONT_BODY_SUB,
		ThemeBuilder.COLOR_TEXT_SECONDARY if idle else ThemeBuilder.COLOR_TEXT)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	name_lbl.clip_text = true
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if not idle and grade_item_id != "":
		ThemeBuilder.apply_item_grade_style(name_lbl, grade_item_id)
	top.add_child(name_lbl)
	var value_lbl := ThemeBuilder.label("", ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_SECONDARY)
	value_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	value_lbl.size_flags_horizontal = Control.SIZE_SHRINK_END
	value_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(value_lbl)
	var bar := ThemeBuilder.mini_countdown_bar(ThemeBuilder.COLOR_JADE)
	bar.max_value = 1.0
	bar.step = 0.0
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mid.add_child(bar)
	return {"mid": mid, "bar": bar, "value": value_lbl}


## 双图标操作列：等宽 40×44（2×40 + 6 = 86px 固定），四行右缘绝对对齐
func _build_ops(jump_tip: String, stop_tip: String, accent: Color,
		on_jump: Callable, on_stop: Callable) -> Control:
	var ops := ThemeBuilder.hbox(6)
	ops.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ops.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ops.add_child(_make_icon_button("jump", Color("#E5EFEA"), ThemeBuilder.COLOR_TEXT_JADE,
		ThemeBuilder.COLOR_TEXT_JADE, jump_tip, on_jump))
	ops.add_child(_make_icon_button("stop", Color("#F7EAE6"), ThemeBuilder.COLOR_TEXT_DANGER,
		ThemeBuilder.COLOR_TEXT_DANGER, stop_tip, on_stop))
	return ops


func _make_icon_button(icon_key: String, bg: Color, edge: Color, tint: Color,
		tip: String, on_pressed: Callable) -> Button:
	var btn := ThemeBuilder.button("")
	btn.custom_minimum_size = Vector2(OPS_W, ThemeBuilder.TOUCH_MIN)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.tooltip_text = tip
	for state in ["normal", "hover", "pressed"]:
		var shade := bg.darkened(0.05 if state == "hover" else (0.1 if state == "pressed" else 0.0))
		btn.add_theme_stylebox_override(state,
			ThemeBuilder.panel_box(shade, edge, 10, 1, 0))
	var icon := TextureRect.new()
	icon.texture = IconLibrary.get_ui_icon(icon_key)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.modulate = tint
	btn.add_child(icon)
	icon.set_anchors_preset(Control.PRESET_CENTER)
	icon.offset_left = -9.0
	icon.offset_top = -9.0
	icon.offset_right = 9.0
	icon.offset_bottom = 9.0
	btn.pressed.connect(func() -> void:
		if AudioManager != null:
			AudioManager.play_tap()
		on_pressed.call())
	return btn


func _build_slot_row(slot: int) -> Control:
	var action_id := GameState.get_active_action(slot)
	var action: ActionData = DataRegistry.get_action(action_id) if action_id != "" else null
	var row := ThemeBuilder.hbox(8)
	row.custom_minimum_size = Vector2(0, 54)
	row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 列 1：30×30 图标
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if action != null:
		var out_ids: Array = action.outputs.keys()
		icon.texture = IconLibrary.get_item_icon(String(out_ids[0])) \
			if not out_ids.is_empty() else IconLibrary.get_skill_icon(action.skill_id)
	else:
		icon.texture = IconLibrary.get_skill_icon("cultivation")
		icon.modulate = Color(1, 1, 1, 0.45)
	row.add_child(icon)
	# 列 2：42px 定宽徽标
	row.add_child(_slot_badge(slot))

	# 列 3：名称/数值行 + 全宽进度条
	var grade_id := ""
	if action != null:
		var out_keys: Array = action.outputs.keys()
		if not out_keys.is_empty():
			grade_id = String(out_keys[0])
	var mid_data := _build_mid(
		action.display_name if action != null else "空闲 · 待指派法门",
		grade_id, action == null)
	if action != null and grade_id == "":
		(mid_data["mid"].get_child(0) as HBoxContainer).get_child(0).add_theme_color_override(
			"font_color", ThemeBuilder.COLOR_TEXT)
	row.add_child(mid_data["mid"])
	var bar: ProgressBar = mid_data["bar"]
	# 三才进度条与动作卡 / 右栏严格同色：主修翠玉绿 · 分神靛青蓝 · 化身紫霄紫
	ThemeBuilder.set_bar_fill(bar, ThemeBuilder.slot_dot_color(slot), 3)

	# 列 4：双图标操作（仅运转中）
	if action != null:
		row.add_child(_build_ops("前往查看", "停止运转",
			ThemeBuilder.slot_dot_color(slot),
			func() -> void:
				hide_island()
				EventBus.navigate_to_source.emit({"type": "skill",
					"skill_id": action.skill_id, "action_id": action_id}),
			func() -> void:
				GameState.stop_action(slot)
				_after_line_changed()))
	_rows.append({"kind": "slot", "slot": slot, "bar": bar, "time": mid_data["value"]})
	return _wrap_row(row)


## 秘境历练行：妖兽名（品阶字色）+ 气血占比条 + 数值（紧凑万/亿）
func _build_combat_row() -> Control:
	var enemy = CombatEngine.get_current_enemy()
	var row := ThemeBuilder.hbox(8)
	row.custom_minimum_size = Vector2(0, 54)
	row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if enemy != null:
		icon.texture = IconLibrary.get_enemy_icon(enemy.get_icon_key())
	row.add_child(icon)
	row.add_child(_make_chip("镇魔" if CombatEngine.tower_floor > 0 else "历练",
		ThemeBuilder.COLOR_CINNABAR))
	var grade_id := ""
	if enemy != null:
		var egrade: Dictionary = DataRegistry.get_enemy_grade(enemy.id)
		if not egrade.is_empty():
			grade_id = enemy.id
	var mid_data := _build_mid(
		enemy.display_name if enemy != null else "秘境历练",
		grade_id, false)
	if enemy != null:
		ThemeBuilder.apply_enemy_grade_style(
			(mid_data["mid"].get_child(0) as HBoxContainer).get_child(0), enemy.id)
	var bar: ProgressBar = mid_data["bar"]
	bar.add_theme_stylebox_override("fill",
		ThemeBuilder.flat_box(ThemeBuilder.COLOR_CINNABAR, 3, 0, 0))
	row.add_child(mid_data["mid"])
	row.add_child(_build_ops("前往查看", "遁出秘境",
		ThemeBuilder.COLOR_CINNABAR,
		func() -> void:
			hide_island()
			EventBus.navigate_to_source.emit({"type": "combat"}),
		func() -> void:
			CombatEngine.stop_combat("灵岛遁出")
			_after_line_changed()))
	_rows.append({"kind": "combat", "bar": bar, "time": mid_data["value"]})
	return _wrap_row(row)


## 全空闲快捷启程：未满级 前往吐纳/百艺采集/秘境历练；
## 真仙圆满已至巅峰 智能换 百艺丹器/洞府灵田/镇魔塔·秘境
func _build_quick_nav() -> Control:
	var row := ThemeBuilder.hbox(6)
	row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var peak := GameState.get_realm_requirement() <= 0.0
	var entries: Array = [["百艺丹器", "alchemy"], ["洞府灵田", "farm"],
		["镇魔塔 / 秘境", "tower" if GameState.tower_highest_floor > 0 else "combat"]]
	if not peak:
		entries = [["前往吐纳", "cultivation"], ["百艺采集", "herbalism"],
			["秘境历练", "combat"]]
	for entry in entries:
		var label_text := String(entry[0])
		var key := String(entry[1])
		var btn := ThemeBuilder.button(label_text)
		btn.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ThemeBuilder.apply_font_size(btn, ThemeBuilder.FONT_BODY_SUB)
		ThemeBuilder.apply_brush_kai(btn)
		if not peak:
			ThemeBuilder.apply_primary_button(btn)
		btn.pressed.connect(func() -> void:
			hide_island()
			if navigate_callback.is_valid():
				navigate_callback.call(key))
		row.add_child(btn)
	ThemeBuilder.prepare_touch(row)
	return row


## 停 / 遁出后的统一联动：即时刷新顶栏胶囊文案；总并发 <=1 自动平滑收起
func _after_line_changed() -> void:
	EventBus.stats_changed.emit()
	if _total_active() <= 1:
		hide_island()
	else:
		_refresh_content()


## 总并发路数 = 战斗（秘境/镇魔塔）+ 三槽百艺
func _total_active() -> int:
	return (1 if CombatEngine.is_active() else 0) \
		+ GameState.get_running_slots().size()


func _slot_badge(slot: int) -> Control:
	return _make_chip(GameState.get_slot_text(slot, "name"),
		ThemeBuilder.slot_dot_color(slot))


## 42px 定宽色标胶囊（2 字居中，四行徽标列绝对对齐）
func _make_chip(text_value: String, color: Color) -> Control:
	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(BADGE_MIN_X, 0)
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_theme_stylebox_override("panel",
		ThemeBuilder.panel_box(color.lightened(0.8), color, 8, 1, 2))
	var lbl := ThemeBuilder.label(text_value, ThemeBuilder.FONT_CAPTION,
		color.darkened(0.3))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip.add_child(lbl)
	return chip
