class_name BottomSheet
extends Control
## 移动端通用底部浮层：说明列表 / 可点击选项 / 2 列网格快捷切换。
## 通过静态 instance 由 MainShell 注册，任意面板可调用。

static var instance: BottomSheet = null

const MIN_SHEET_HEIGHT: float = 160.0
const SHEET_VIEWPORT_RATIO: float = 0.78
const SHEET_BASE_PADDING: float = 32.0
const SLIDE_TIME: float = 0.16

var _scrim: ColorRect
var _panel: PanelContainer
var _panel_box: VBoxContainer
var _title_label: Label
var _head: HBoxContainer
var _detail_head: HBoxContainer
var _detail_icon: IconFrame
var _body: VBoxContainer
var _scroll: ScrollContainer
var _panel_height: float = 0.0
var _open: bool = false
var _opened_msec: int = 0
var _present_token: int = 0
var _tween: Tween


func _ready() -> void:
	instance = self
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_build()


func _build() -> void:
	_scrim = ColorRect.new()
	_scrim.color = Color(0.12, 0.10, 0.08, 0.42)
	add_child(_scrim)
	_scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	_scrim.gui_input.connect(_on_scrim_gui_input)

	_panel = PanelContainer.new()
	add_child(_panel)
	_panel.anchor_left = 0.0
	_panel.anchor_right = 1.0
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_panel.offset_left = 0.0
	_panel.offset_right = 0.0
	_panel.offset_top = 0.0
	_panel.offset_bottom = 0.0
	_panel.add_theme_stylebox_override("panel",
		ThemeBuilder.panel_box(ThemeBuilder.COLOR_CARD, ThemeBuilder.COLOR_JADE, 16, 1, 16))

	var box := ThemeBuilder.vbox(10)
	_panel_box = box
	_panel.add_child(box)

	var handle := ColorRect.new()
	handle.color = ThemeBuilder.COLOR_BORDER
	handle.custom_minimum_size = Vector2(44, 4)
	handle.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(handle)

	# 三段式详情专用身份头，与旧标题头互斥；旧 show_text 等接口保持不变
	var detail_head := ThemeBuilder.hbox(8)
	detail_head.visible = false
	_detail_head = detail_head
	box.add_child(detail_head)

	var head := ThemeBuilder.hbox(8)
	_head = head
	box.add_child(head)
	_title_label = ThemeBuilder.title_label("", ThemeBuilder.FONT_PAGE_TITLE)
	# 标题必须可换行：1.20 大字档下长标题会把浮层最小宽度顶出 450 屏幕
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_title_label)
	var close_button := ThemeBuilder.button("收起")
	close_button.custom_minimum_size = Vector2(88, ThemeBuilder.TOUCH_MIN)
	ThemeBuilder.apply_font_size(close_button, ThemeBuilder.FONT_BODY)
	ThemeBuilder.apply_brush_kai(close_button)
	close_button.pressed.connect(hide_sheet)
	head.add_child(close_button)

	_scroll = ThemeBuilder.scroll_container()
	_scroll.custom_minimum_size = Vector2(0, 0)
	box.add_child(_scroll)
	_body = ThemeBuilder.vbox(8)
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_body)


## rows: Array[Dictionary] -> {"text", "desc", "color", "callback"(可选)}
func show_info(title_text: String, rows: Array,
		title_color: Color = ThemeBuilder.COLOR_TEXT) -> void:
	if _panel == null:
		_build()
	_restore_legacy_head()
	_clear(_body)
	_reset_sheet_size()
	_title_label.text = title_text
	_title_label.add_theme_color_override("font_color", title_color)
	for row in rows:
		if typeof(row) != TYPE_DICTIONARY:
			continue
		var dict: Dictionary = row
		var color: Color = dict.get("color", ThemeBuilder.COLOR_TEXT)
		var text_value := String(dict.get("text", ""))
		var desc := String(dict.get("desc", ""))
		# 富文本行：混色图例等场景，颜色值由 ThemeBuilder.hex(COLOR_*) 生成
		if dict.has("bbcode"):
			var bbcode_label := ThemeBuilder.bbcode_label(
				ThemeBuilder.protect_phrases(String(dict["bbcode"])),
				int(dict.get("font_size", ThemeBuilder.FONT_CAPTION)))
			ThemeBuilder.enable_phrase_wrap(bbcode_label)
			_body.add_child(bbcode_label)
			if desc != "":
				_body.add_child(_phrase_desc_label(desc))
			continue
		# 自定义行节点（图标战利品行等）：调用方组装好控件整行塞入。
		# 必须 SHRINK_BEGIN：BoxContainer 子节点默认 FILL 会被垂直均分，
		# 行间撑出大片空白（丰收弹窗曾因此「行漂在半空」）
		if dict.has("custom"):
			var custom_node: Variant = dict["custom"]
			if custom_node is Control:
				(custom_node as Control).size_flags_vertical = Control.SIZE_SHRINK_BEGIN
				_body.add_child(custom_node)
				if desc != "":
					_body.add_child(ThemeBuilder.wrap_label(desc, ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_DIM))
			continue
		var callback_value: Variant = dict.get("callback", null)
		if callback_value is Callable:
			var callback: Callable = callback_value
			var button := ThemeBuilder.button(text_value)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
			ThemeBuilder.apply_font_size(button, ThemeBuilder.FONT_BODY)
			ThemeBuilder.apply_brush_kai(button)
			button.add_theme_color_override("font_color", color)
			button.pressed.connect(func() -> void:
				hide_sheet()
				callback.call()
			)
			_body.add_child(button)
			if desc != "":
				_body.add_child(ThemeBuilder.wrap_label(desc, ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_DIM))
			continue
		var item := ThemeBuilder.vbox(2)
		_body.add_child(item)
		item.add_child(ThemeBuilder.wrap_label(text_value, 14, color))
		if desc != "":
			item.add_child(_phrase_desc_label(desc))
	# 动态行/按钮补挂触控约定（PASS + 14px 滑动守卫）
	ThemeBuilder.prepare_touch(_body)
	_present()


## 三段式详情：身份头（图标/名称/标签/收起）+ 核心数值卡 + 补充说明 + 可选操作区。
## 旧 show_text/show_grid/show_sources 完全不变；新弹窗统一走本接口。
## detail: {
##   "title": String, "title_color": Color, "icon": Texture2D, "icon_accent": Color,
##   "tags": Array[{text, color}], "rows": Array[{label, value, color}],
##   "note": String, "actions": Array[{text, callback, accent}]
## }
func _show_detail_view(detail: Dictionary) -> void:
	if _panel == null:
		_build()
	_clear(_body)
	_reset_sheet_size()
	_detail_icon = null
	_clear(_detail_head)
	_head.visible = false
	_detail_head.visible = true
	_body.add_theme_constant_override("separation", 11)
	var title_text := String(detail.get("title", ""))
	var title_color: Color = detail.get("title_color", ThemeBuilder.COLOR_TEXT_PRIMARY)
	var icon_texture: Variant = detail.get("icon", null)
	var icon_accent: Color = detail.get("icon_accent", ThemeBuilder.COLOR_JADE)
	if icon_texture is Texture2D:
		_detail_icon = IconFrame.new()
		_detail_icon.setup(icon_texture as Texture2D, 44, icon_accent, false, 30)
		_detail_head.add_child(_detail_icon)
	else:
		var icon_placeholder := Control.new()
		icon_placeholder.custom_minimum_size = Vector2(44, 44)
		icon_placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_detail_head.add_child(icon_placeholder)
	var identity := ThemeBuilder.vbox(2)
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_head.add_child(identity)
	var name_label := ThemeBuilder.wrap_label(title_text, ThemeBuilder.FONT_CARD_TITLE,
		title_color)
	ThemeBuilder.apply_font_size(name_label, ThemeBuilder.FONT_CARD_TITLE)
	identity.add_child(name_label)
	var tag_flow := HFlowContainer.new()
	tag_flow.add_theme_constant_override("h_separation", 5)
	tag_flow.add_theme_constant_override("v_separation", 3)
	tag_flow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	identity.add_child(tag_flow)
	for tag_value in detail.get("tags", []):
		if typeof(tag_value) != TYPE_DICTIONARY:
			continue
		var tag: Dictionary = tag_value
		var tag_text := String(tag.get("text", ""))
		if tag_text == "":
			continue
		tag_flow.add_child(_make_detail_tag(tag_text,
			tag.get("color", ThemeBuilder.COLOR_TEXT_SECONDARY)))
	var close_button := ThemeBuilder.button("收起")
	close_button.custom_minimum_size = Vector2(88, ThemeBuilder.TOUCH_MIN)
	ThemeBuilder.apply_font_size(close_button, ThemeBuilder.FONT_BODY)
	ThemeBuilder.apply_brush_kai(close_button)
	close_button.pressed.connect(hide_sheet)
	_detail_head.add_child(close_button)

	var card := ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD_DEEP,
		ThemeBuilder.COLOR_BORDER, 8, 12)
	var card_box := ThemeBuilder.vbox(7)
	card.add_child(card_box)
	for row_value in detail.get("rows", []):
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		if row.has("custom"):
			var custom_value: Variant = row["custom"]
			if custom_value is Control:
				var custom_node := custom_value as Control
				custom_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				custom_node.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
				_body.add_child(custom_node)
			continue
		var line := ThemeBuilder.hbox(8)
		line.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		card_box.add_child(line)
		var key_label := ThemeBuilder.label(String(row.get("label", "")),
			ThemeBuilder.FONT_BODY_SUB, ThemeBuilder.COLOR_TEXT_SECONDARY)
		key_label.custom_minimum_size = Vector2(76, 0)
		key_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		key_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		line.add_child(key_label)
		var value_color: Color = row.get("color", ThemeBuilder.COLOR_TEXT_PRIMARY)
		var value_text := String(row.get("value", ""))
		var value_label := ThemeBuilder.wrap_label_phrases(value_text,
			ThemeBuilder.FONT_BODY_SUB, value_color)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(value_label)
	if not card_box.get_children().is_empty():
		_body.add_child(card)

	var note_text := String(detail.get("note", ""))
	if note_text != "":
		_body.add_child(ThemeBuilder.wrap_label(note_text, ThemeBuilder.FONT_BODY_SUB,
			ThemeBuilder.COLOR_TEXT_SECONDARY))

	var actions: Array = detail.get("actions", [])
	if not actions.is_empty():
		var has_full_width := false
		for action_value in actions:
			if typeof(action_value) == TYPE_DICTIONARY \
					and bool((action_value as Dictionary).get("full_width", false)):
				has_full_width = true
				break
		var action_host: Container
		if has_full_width:
			var action_box := ThemeBuilder.vbox(8)
			action_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			action_host = action_box
		else:
			var action_flow := HFlowContainer.new()
			action_flow.add_theme_constant_override("h_separation", 8)
			action_flow.add_theme_constant_override("v_separation", 8)
			action_host = action_flow
		_body.add_child(action_host)
		for action_value in actions:
			if typeof(action_value) != TYPE_DICTIONARY:
				continue
			var action: Dictionary = action_value
			var callback_value: Variant = action.get("callback", null)
			if not (callback_value is Callable):
				continue
			var button := ThemeBuilder.small_button(String(action.get("text", "")),
				bool(action.get("accent", false)))
			button.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
			ThemeBuilder.apply_font_size(button, ThemeBuilder.FONT_BODY)
			ThemeBuilder.apply_brush_kai(button)
			if bool(action.get("primary", false)):
				ThemeBuilder.apply_primary_button(button)
			if bool(action.get("full_width", false)):
				button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.disabled = bool(action.get("disabled", false))
			var action_callback: Callable = callback_value
			button.pressed.connect(func() -> void: action_callback.call())
			action_host.add_child(button)

	ThemeBuilder.prepare_touch(_detail_head)
	ThemeBuilder.prepare_touch(_body)
	_present()


func _make_detail_tag(text_value: String, color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", ThemeBuilder.chip_box(color))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tag_label := ThemeBuilder.label(text_value, ThemeBuilder.FONT_CAPTION,
		color.darkened(0.08))
	ThemeBuilder.apply_font_size(tag_label, ThemeBuilder.FONT_CAPTION)
	tag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(tag_label)
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return panel


## 详情头图标的屏幕中心，供装备 / 卸下音效与灵纹反馈定位
func detail_icon_center() -> Vector2:
	if _detail_icon != null and is_instance_valid(_detail_icon):
		return _detail_icon.get_global_rect().get_center()
	return Vector2(-1, -1)


## 恢复旧接口标题头，避免 show_detail 后旧 show_text 仍停留在详情头
func _restore_legacy_head() -> void:
	if _detail_head != null:
		_detail_head.visible = false
	if _head != null:
		_head.visible = true
	if _body != null:
		_body.add_theme_constant_override("separation", 8)


## 缺料获取指引：每种缺口材料一个分组，来源行右侧「前往 ▸」
## blocks: [{item_id, name, missing, sources: Array[Dictionary]}]
func show_source_guide(title_text: String, blocks: Array) -> void:
	if _panel == null:
		_build()
	_restore_legacy_head()
	_clear(_body)
	_reset_sheet_size()
	_title_label.text = title_text
	for block in blocks:
		if typeof(block) != TYPE_DICTIONARY:
			continue
		var data: Dictionary = block
		var item_id := String(data.get("item_id", ""))
		var sources: Array = data.get("sources", [])

		var head := ThemeBuilder.hbox(8)
		_body.add_child(head)
		var icon := IconFrame.new()
		icon.setup(IconLibrary.get_item_icon(item_id), 32, ThemeBuilder.COLOR_CINNABAR)
		head.add_child(icon)
		var info := ThemeBuilder.vbox(2)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(info)
		info.add_child(ThemeBuilder.label("%s（缺 %d）" % [
			String(data.get("name", "")), int(data.get("missing", 0))], 14,
			ThemeBuilder.COLOR_TEXT))
		info.add_child(ThemeBuilder.dim_label("可选来源 %d 处" % sources.size(),
			ThemeBuilder.FONT_CAPTION))

		if sources.is_empty():
			_body.add_child(ThemeBuilder.wrap_label("暂无已知来源，可留意后续解锁。",
				ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_DIM))
		for source in sources:
			if typeof(source) != TYPE_DICTIONARY:
				continue
			var source_dict: Dictionary = source
			var row := ThemeBuilder.hbox(8)
			_body.add_child(row)
			var label := ThemeBuilder.wrap_label(String(source_dict.get("label", "")),
				ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_SECONDARY)
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(label)
			var go := ThemeBuilder.small_button("前往 ▸")
			go.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
			ThemeBuilder.apply_font_size(go, ThemeBuilder.FONT_BODY)
			ThemeBuilder.apply_brush_kai(go)
			var payload: Dictionary = source_dict.duplicate(true)
			go.pressed.connect(func() -> void:
				hide_sheet()
				EventBus.navigate_to_source.emit(payload)
			)
			row.add_child(go)
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(0, 4)
		spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_body.add_child(spacer)
	_present()


## 2 列网格快捷切换：entries -> {"text", "sub", "dot_color", "callback"}
func show_buttons_grid(title_text: String, entries: Array, columns: int = 2,
		play_sound: bool = true) -> void:
	if _panel == null:
		_build()
	_restore_legacy_head()
	_clear(_body)
	_reset_sheet_size()
	_title_label.text = title_text
	var grid := GridContainer.new()
	grid.columns = maxi(1, columns)
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_child(grid)

	for entry in entries:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var dict: Dictionary = entry
		var callback_value: Variant = dict.get("callback", null)
		if not (callback_value is Callable):
			continue
		var callback: Callable = callback_value
		var button := ThemeBuilder.button("")
		button.custom_minimum_size = Vector2(0, 54)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func() -> void:
			hide_sheet()
			callback.call()
		)

		var row := HBoxContainer.new()
		button.add_child(row)
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.offset_left = 10.0
		row.offset_right = -10.0
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 6)

		var icon_value: Variant = dict.get("icon", null)
		if icon_value is Texture2D:
			var icon_rect := ThemeBuilder.icon_rect(icon_value as Texture2D, 20)
			row.add_child(icon_rect)
		else:
			var dot := PanelContainer.new()
			dot.custom_minimum_size = Vector2(8, 8)
			dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			dot.add_theme_stylebox_override("panel",
				ThemeBuilder.circle_box(dict.get("dot_color", Color(0, 0, 0, 0)), 8.0))
			row.add_child(dot)

		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.alignment = BoxContainer.ALIGNMENT_CENTER
		column.add_theme_constant_override("separation", 0)
		column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(column)

		var name_label := ThemeBuilder.label(String(dict.get("text", "")),
			ThemeBuilder.FONT_BODY, ThemeBuilder.COLOR_TEXT_PRIMARY)
		ThemeBuilder.apply_font_size(name_label, ThemeBuilder.FONT_BODY)
		name_label.clip_text = true
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		column.add_child(name_label)
		var sub_text := String(dict.get("sub", ""))
		if sub_text != "":
			column.add_child(ThemeBuilder.label(sub_text, ThemeBuilder.FONT_CAPTION,
				ThemeBuilder.COLOR_TEXT_DIM))

		grid.add_child(button)

	_present(play_sound)


func _reset_sheet_size() -> void:
	_present_token += 1
	_panel_height = 0.0
	if _panel != null:
		_panel.custom_minimum_size = Vector2(0, 0)
		_panel.reset_size()
	if _scroll != null:
		_scroll.custom_minimum_size = Vector2(0, 0)
		_scroll.reset_size()
	if _body != null:
		_body.reset_size()


func _present(play_sound: bool = true) -> void:
	var token := _present_token
	_opened_msec = Time.get_ticks_msec()
	if play_sound and AudioManager != null:
		AudioManager.play_paper()
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	move_to_front()
	# 测量阶段保持透明：玩家看不到锁宽与定高过程，避免首帧高度跳变
	_panel.modulate = Color(1, 1, 1, 0)
	_scrim.modulate.a = 0.0
	var vp := get_viewport_rect().size
	var extra_side := maxf(0.0, (vp.x - 560.0) * 0.5)
	var sheet_width := maxf(160.0, vp.x - extra_side * 2.0)
	var inner_width := maxf(120.0, sheet_width - 32.0)
	_panel.offset_left = extra_side
	_panel.offset_right = -extra_side
	# 显式锁定目标宽度，autowrap 文本才能按真实宽度在首帧就正确折行
	_panel.custom_minimum_size.x = sheet_width
	_panel.size.x = sheet_width
	if _panel_box != null:
		_panel_box.custom_minimum_size.x = inner_width
	if _scroll != null:
		_scroll.custom_minimum_size.x = inner_width
		_scroll.custom_minimum_size.y = 0.0
		_scroll.reset_size()
	if _body != null:
		_body.custom_minimum_size.x = inner_width
		_body.reset_size()
	_panel.custom_minimum_size.y = 0.0
	_panel.reset_size()
	var tree := get_tree()
	if tree == null:
		return
	# 第一帧完成容器水平宽度分发；第二帧完成 autowrap 文本在真实宽度下的重排
	await tree.process_frame
	if token != _present_token or not is_inside_tree():
		return
	await tree.process_frame
	if token != _present_token or not is_inside_tree():
		return
	var content_height := maxf(_body.get_combined_minimum_size().y, _body.size.y)
	var head_height := 0.0
	if _detail_head != null and _detail_head.is_visible_in_tree():
		head_height += _detail_head.get_combined_minimum_size().y
	if _head != null and _head.is_visible_in_tree():
		head_height += _head.get_combined_minimum_size().y
	var separation := 0.0
	if _panel_box != null:
		separation = float(_panel_box.get_theme_constant("separation", "VBoxContainer"))
	var chrome_height := SHEET_BASE_PADDING + 4.0 + separation * 2.0
	var max_height := maxf(MIN_SHEET_HEIGHT, vp.y * SHEET_VIEWPORT_RATIO)
	var target_height := clampf(head_height + content_height + chrome_height,
		MIN_SHEET_HEIGHT, max_height)
	var max_body_height := maxf(40.0, target_height - head_height - chrome_height)
	# 内容未超出上限时精确贴合，只有超高内容才留下滚动空间
	_scroll.custom_minimum_size.y = minf(content_height, max_body_height)
	_panel.custom_minimum_size.y = target_height
	# 自定义行可能在定高后的首帧才完成最终排布，动画前再复核一次，杜绝底部空白
	for _i in range(2):
		await tree.process_frame
		if token != _present_token or not is_inside_tree():
			return
		var remeasured := maxf(_body.get_combined_minimum_size().y, _body.size.y)
		if absf(remeasured - content_height) <= 2.0:
			break
		content_height = remeasured
		target_height = clampf(head_height + content_height + chrome_height,
			MIN_SHEET_HEIGHT, max_height)
		max_body_height = maxf(40.0, target_height - head_height - chrome_height)
		_scroll.custom_minimum_size.y = minf(content_height, max_body_height)
		_panel.custom_minimum_size.y = target_height
	_panel_height = _panel.get_combined_minimum_size().y
	_panel.offset_top = 0.0
	_panel.offset_bottom = 0.0
	_open = true
	_kill_tween()
	# 统一开启动效：自下 36px 滑入 + 淡入（0.22s QUART），背板同步渐显
	ThemeBuilder.animate_modal_open(_panel, _scrim, true)


func hide_sheet() -> void:
	_present_token += 1
	if not _open:
		visible = false
		return
	_open = false
	_kill_tween()
	# 统一收起动效：下滑 28px + 淡出（期间拦截重复点击）
	ThemeBuilder.animate_modal_close(_panel, _scrim, _finish_hide, true)


func _finish_hide() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()


func _on_scrim_gui_input(event: InputEvent) -> void:
	# 打开后的极短时间内忽略遮罩点击，避免触发弹窗的同一触摸序列立即把弹窗关掉
	if Time.get_ticks_msec() - _opened_msec < 220:
		return
	if event is InputEventScreenTouch and event.pressed:
		hide_sheet()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		hide_sheet()


## 说明正文：结构化属性 / 掉落行走防断词，长攻略仍用普通按词折行
func _phrase_desc_label(text_value: String) -> Label:
	var structured := ThemeBuilder.is_structured_line(text_value)
	var node := ThemeBuilder.wrap_label_phrases(text_value, ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_DIM) if structured \
		else ThemeBuilder.wrap_label(text_value, ThemeBuilder.FONT_CAPTION,
			ThemeBuilder.COLOR_TEXT_DIM)
	return node


func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


static func show_text(title_text: String, rows: Array,
		title_color: Color = ThemeBuilder.COLOR_TEXT) -> void:
	if instance != null and is_instance_valid(instance):
		instance.show_info(title_text, rows, title_color)


## 问号说明专用：每个条目一张宣纸小卡，标题醒目、正文换行，底部留安全空白。
static func show_help(title_text: String, rows: Array) -> void:
	if instance != null and is_instance_valid(instance):
		instance._show_help_cards(title_text, rows)


func _show_help_cards(title_text: String, rows: Array) -> void:
	if _panel == null:
		_build()
	_restore_legacy_head()
	_clear(_body)
	_reset_sheet_size()
	_body.add_theme_constant_override("separation", 9)
	_title_label.text = title_text
	_title_label.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT_TITLE_GOLD)
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		var title := String(row.get("text", ""))
		if title == "":
			continue
		var card := ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD_DEEP,
			ThemeBuilder.COLOR_BORDER, 8, 10)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var card_box := ThemeBuilder.vbox(4)
		card.add_child(card_box)
		var heading_color: Color = row.get("color", ThemeBuilder.COLOR_TEXT_TITLE_GOLD)
		if heading_color != ThemeBuilder.COLOR_TEXT_TITLE_GOLD \
				and heading_color != ThemeBuilder.COLOR_TEXT_JADE:
			heading_color = ThemeBuilder.COLOR_TEXT_TITLE_GOLD
		var heading := ThemeBuilder.label(title, ThemeBuilder.FONT_BODY, heading_color)
		ThemeBuilder.apply_font_size(heading, ThemeBuilder.FONT_BODY)
		heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card_box.add_child(heading)
		var body_text := String(row.get("desc", ""))
		if row.has("bbcode"):
			var rich := ThemeBuilder.bbcode_label(String(row["bbcode"]),
				ThemeBuilder.FONT_BODY_SUB)
			rich.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			card_box.add_child(rich)
		if body_text != "":
			var body_label := ThemeBuilder.wrap_label(body_text,
				ThemeBuilder.FONT_BODY_SUB, ThemeBuilder.COLOR_TEXT_PRIMARY)
			ThemeBuilder.apply_font_size(body_label, ThemeBuilder.FONT_BODY_SUB)
			card_box.add_child(body_label)
		_body.add_child(card)
	var safe_bottom := Control.new()
	safe_bottom.custom_minimum_size = Vector2(0, 6)
	safe_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.add_child(safe_bottom)
	ThemeBuilder.prepare_touch(_body)
	_present()


## 新详情弹窗统一入口；detail 结构见 show_detail() 注释
static func show_detail(detail: Dictionary) -> void:
	if instance != null and is_instance_valid(instance):
		instance._show_detail_view(detail)


static func show_grid(title_text: String, entries: Array, columns: int = 2,
		play_sound: bool = true) -> void:
	if instance != null and is_instance_valid(instance):
		instance.show_buttons_grid(title_text, entries, columns, play_sound)


static func show_sources(title_text: String, blocks: Array) -> void:
	if instance != null and is_instance_valid(instance):
		instance.show_source_guide(title_text, blocks)
