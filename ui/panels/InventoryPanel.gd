class_name InventoryPanel
extends Control
## 储物袋（移动端单列）：分类筛选、出售换灵石、装备穿戴、丹药吞服。

const FILTERS: Array = [
	{"key": "all", "label": "全部"},
	{"key": "material", "label": "灵材"},
	{"key": "consumable", "label": "丹药"},
	{"key": "equipment", "label": "法宝"},
]
## 装备 / 卸下 / 服用 / 出售：150ms 操作冷却，快速连点不会在同一个状态快照上重复结算
const ACTION_COOLDOWN_MS: int = 150

var _filter: String = "all"
var _filter_buttons: Dictionary = {}
var _list_box: GridContainer
var _list_scroll: ScrollContainer
var _empty_state: CenterContainer
var _equip_box: BoxContainer
var _count_label: Label
var _stats_label: Label
var _body: BoxContainer
var _left_col: VBoxContainer
var _right_col: VBoxContainer
## COMPACT 整页一体化滚动：头部卡片/法宝/分栏/批量栏/物格全在一张滚动页里
var _page_scroll: ScrollContainer
var _page_box: VBoxContainer
var _header: PanelContainer
var _equip_panel: PanelContainer
var _stats_panel: PanelContainer
var _filter_row: BoxContainer
var _action_row: BoxContainer
var _detail_panel: PanelContainer
var _detail_box: VBoxContainer
var _selected_item_id: String = ""
var _grid_buttons: Dictionary = {}
var _layout_mode: int = EventBus.LayoutMode.COMPACT
var _rebuild_queued: bool = false
var _detail_queued: bool = false
var _is_dirty: bool = false
## 上一次有效操作的时间戳：同一帧 / 连点内只结算一次
var _action_lock_ms: int = 0

## 一键化灵：过时低阶材料折算灵石
var _dissolve_button: Button
var _dissolve_lock_ms: int = 0
## 批量熔炼：淘汰装备返还材料 / 折算灵石
var _smelt_button: Button
var _smelt_lock_ms: int = 0


func _ready() -> void:
	_layout_mode = EventBus.current_layout
	_build()
	EventBus.inventory_changed.connect(_queue_rebuild)
	EventBus.equipment_changed.connect(_queue_rebuild)
	EventBus.game_loaded.connect(_queue_rebuild)
	EventBus.layout_changed.connect(_on_layout_changed)
	visibility_changed.connect(_on_visibility_changed)
	_refresh_filter_styles()
	rebuild()


func _build() -> void:
	var root := ThemeBuilder.vbox(10)
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 10)

	# ---- 整页滚动容器（COMPACT 用；宽屏隐藏，块体回归左右双栏）
	_page_scroll = ThemeBuilder.scroll_container()
	_page_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_page_scroll.clip_contents = true
	root.add_child(_page_scroll)
	_page_box = ThemeBuilder.vbox(10)
	_page_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page_scroll.add_child(_page_box)

	# ---- 顶部
	var header := ThemeBuilder.card_panel()
	_header = header
	root.add_child(header)
	var head_box := ThemeBuilder.vbox(4)
	header.add_child(head_box)
	var title_row := ThemeBuilder.hbox(8)
	head_box.add_child(title_row)
	title_row.add_child(ThemeBuilder.title_label("储物袋", 20))
	_count_label = ThemeBuilder.dim_label("", ThemeBuilder.FONT_CAPTION)
	title_row.add_child(_count_label)
	title_row.add_child(ThemeBuilder.expander())
	var help := ThemeBuilder.create_help_button(_show_help)
	help.custom_minimum_size = Vector2(44, 44)
	help.tooltip_text = "储物袋规则"
	title_row.add_child(help)
	title_row.move_child(help, -1)
	ThemeBuilder.attach_header_watermark(header, IconLibrary.get_nav_icon("bag"))

	# ---- 主体：储物袋只保留筛选、批量操作、详情与物品网格
	_body = BoxContainer.new()
	_body.vertical = true
	_body.add_theme_constant_override("separation", 10)
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_body)

	_right_col = ThemeBuilder.vbox(8)
	_right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_right_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_child(_right_col)

	# ---- 第 1 行 · 固定四等分分类栏（切换分页时按钮零位移）
	var filter_row := ThemeBuilder.hbox(8)
	_filter_row = filter_row
	_right_col.add_child(filter_row)
	for entry in FILTERS:
		var dict: Dictionary = entry
		var key := String(dict["key"])
		var button := ThemeBuilder.button(String(dict["label"]))
		button.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_NONE
		ThemeBuilder.apply_font_size(button, ThemeBuilder.FONT_BODY_SUB)
		button.pressed.connect(_on_filter_pressed.bind(key))
		filter_row.add_child(button)
		_filter_buttons[key] = button

	# ---- 第 2 行 · 常驻二等分批量操作栏（任意分页都常驻，绝不显隐改变布局）
	var action_row := ThemeBuilder.hbox(8)
	_action_row = action_row
	_right_col.add_child(action_row)
	_dissolve_button = ThemeBuilder.button("一键化灵")
	_smelt_button = ThemeBuilder.button("批量熔炼")
	for btn in [_dissolve_button, _smelt_button]:
		var b := btn as Button
		b.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.focus_mode = Control.FOCUS_NONE
		ThemeBuilder.apply_font_size(b, ThemeBuilder.FONT_BODY_SUB)
		action_row.add_child(b)
	_dissolve_button.pressed.connect(_on_dissolve_pressed)
	_smelt_button.pressed.connect(_on_smelt_pressed)

	# ---- 详情卡：固定高度槽位（始终占位），选中/切页都不会把列表往下推
	_detail_panel = ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD_DEEP, ThemeBuilder.COLOR_BORDER, 12, 10)
	_detail_panel.custom_minimum_size = Vector2(0, 150)
	# 轻点详情卡空白：完整背景描述 / 属性 / 获取途径（正文保持三行骨架）
	ThemeBuilder.make_card_tappable(_detail_panel, _show_item_detail)
	_right_col.add_child(_detail_panel)
	_detail_box = ThemeBuilder.vbox(6)
	_detail_panel.add_child(_detail_box)

	# ---- 列表（宽屏 2 列网格）：全页唯一允许 EXPAND_FILL 的区域
	_list_scroll = ThemeBuilder.scroll_container()
	_list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_right_col.add_child(_list_scroll)
	_list_box = GridContainer.new()
	_list_box.columns = 4
	_list_box.add_theme_constant_override("h_separation", 8)
	_list_box.add_theme_constant_override("v_separation", 8)
	_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_scroll.add_child(_list_box)
	# 视口宽度变化（转屏 / 切档 / 滚动条出现）时重算物格边长，避免沿用旧宽度
	_page_scroll.resized.connect(func() -> void: call_deferred("_sync_cell_size"))
	_list_scroll.resized.connect(func() -> void: call_deferred("_sync_cell_size"))

	# ---- 空态：独立于物品网格的整区居中容器（不占网格列，窄屏/宽屏都居中）
	_empty_state = CenterContainer.new()
	_empty_state.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_empty_state.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_empty_state.visible = false
	_right_col.add_child(_empty_state)
	var empty_box := ThemeBuilder.vbox(8)
	empty_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_empty_state.add_child(empty_box)
	var bag_icon := IconFrame.new()
	bag_icon.setup(IconLibrary.get_nav_icon("bag"), 40, ThemeBuilder.COLOR_JADE)
	bag_icon.modulate.a = 0.5
	bag_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	empty_box.add_child(bag_icon)
	var tip := ThemeBuilder.label("此处空空如也，先去采集或历练罢。", 13, ThemeBuilder.COLOR_TEXT_DIM)
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	empty_box.add_child(tip)

	ThemeBuilder.prepare_touch(root)


func _on_layout_changed(mode: int, _vp_size: Vector2, workspace_width: float) -> void:
	_layout_mode = mode
	_apply_width(workspace_width)


## 宽窄双模重排：COMPACT = 整页一体化滚动（头部随页滚走、详情改 BottomSheet）；
## MEDIUM/WIDE = 左右双栏（左滚动网格 + 右常驻详情卡）。幂等：按固定顺序归位。
func _apply_width(workspace_width: float) -> void:
	var wide := workspace_width >= 680.0
	if _body == null or _page_box == null:
		return
	if wide:
		_page_scroll.visible = false
		_body.visible = true
		_detail_panel.visible = true
		_reparent(_header, _body_owner_root())
		_reparent(_body, _body_owner_root())
		_reparent(_filter_row, _right_col)
		_reparent(_action_row, _right_col)
		_reparent(_detail_panel, _right_col)
		_reparent(_list_scroll, _right_col)
		_reparent(_list_box, _list_scroll)
		_reparent(_empty_state, _right_col)
		_body.vertical = false
	else:
		# 整页滚动：全部区块进一张滚动页，任意位置上下滑都滚整页
		_detail_panel.visible = false
		_body.visible = false
		_page_scroll.visible = true
		_reparent(_header, _page_box)
		_reparent(_filter_row, _page_box)
		_reparent(_action_row, _page_box)
		_reparent(_list_box, _page_box)
		_reparent(_empty_state, _page_box)
	if _list_box != null:
		_list_box.columns = 4
		call_deferred("_sync_cell_size")


func _body_owner_root() -> Node:
	return _page_scroll.get_parent()


func _reparent(node: Control, parent: Node) -> void:
	if node == null or parent == null or node.get_parent() == parent:
		return
	if node.get_parent() != null:
		node.get_parent().remove_child(node)
	parent.add_child(node)


## 让物格随列宽保持正方形（最小 76×76）
func _sync_cell_size() -> void:
	if _list_box == null or _list_scroll == null or _grid_buttons.is_empty():
		return
	var columns := maxi(1, _list_box.columns)
	# 以「面板自身宽」为稳定基准，再扣纵向滚动条与安全边距：
	# 不能取 ScrollContainer.size（它会因子内容最小宽被反向撑大，形成 141px 巨格的正反馈）
	var base_width := size.x
	if not _page_scroll.visible and _left_col != null:
		base_width = maxf(200.0, size.x - _left_col.custom_minimum_size.x - 10.0)
	var available := base_width - 12.0 - 8.0
	if available <= 0.0:
		return
	var cell := floorf((available - 8.0 * float(columns - 1)) / float(columns))
	# 下限保证可触控（68 ≥ 44 触控底线），上限防止宽屏出现超大空格
	cell = clampf(cell, 68.0, 110.0)
	for button in _grid_buttons.values():
		(button as Button).custom_minimum_size = Vector2(cell, cell)


func _queue_rebuild() -> void:
	if not is_visible_in_tree():
		_is_dirty = true
		return
	if _rebuild_queued:
		return
	_rebuild_queued = true
	call_deferred("_do_rebuild")


func _do_rebuild() -> void:
	_rebuild_queued = false
	if not is_visible_in_tree():
		_is_dirty = true
		return
	_is_dirty = false
	rebuild()


func _on_visibility_changed() -> void:
	if not is_visible_in_tree() or not _is_dirty:
		return
	_is_dirty = false
	_queue_rebuild()


func rebuild() -> void:
	if _list_box == null:
		return
	_clear(_list_box)
	_grid_buttons.clear()

	var total_stacks := 0
	var items: Array = []
	for key in DataRegistry.items.keys():
		var item := DataRegistry.get_item(String(key))
		if item == null:
			continue
		if GameState.get_item_count(item.id) <= 0:
			continue
		if not _match_filter(item):
			continue
		items.append(item)
		total_stacks += 1
	items.sort_custom(func(a: ItemData, b: ItemData) -> bool:
		if a.category != b.category:
			return a.category < b.category
		# 材料按品阶从高到低（同阶来源等级降序）：常用高阶灵材置顶，旧凡材沉底
		var ga: Dictionary = DataRegistry.get_material_grade(a.id)
		var gb: Dictionary = DataRegistry.get_material_grade(b.id)
		if not ga.is_empty() and not gb.is_empty():
			if int(ga["tier"]) != int(gb["tier"]):
				return int(ga["tier"]) > int(gb["tier"])
			if int(ga["unlock_level"]) != int(gb["unlock_level"]):
				return int(ga["unlock_level"]) > int(gb["unlock_level"])
		return a.id < b.id
	)
	_count_label.text = "共 %d 种" % total_stacks
	_refresh_action_row()
	_apply_width(EventBus.workspace_width)

	if items.is_empty():
		_selected_item_id = ""
		if _list_scroll != null:
			_list_scroll.visible = false
		if _empty_state != null:
			_empty_state.visible = true
		_queue_detail_refresh()
		return

	if _list_scroll != null:
		_list_scroll.visible = true
	if _empty_state != null:
		_empty_state.visible = false

	var has_selected := false
	for item in items:
		if (item as ItemData).id == _selected_item_id:
			has_selected = true
			break
	if not has_selected:
		_selected_item_id = (items[0] as ItemData).id
	for item in items:
		var button := _build_item_cell(item as ItemData)
		_list_box.add_child(button)
		_grid_buttons[(item as ItemData).id] = button
	_refresh_grid_selection()
	# 详情卡与网格刷新合并到帧末执行：同一帧多次状态变化只重建一次详情卡
	_queue_detail_refresh()
	call_deferred("_sync_cell_size")



	# 动态重建后补挂触控约定（按钮 PASS + 14px 滑动守卫）
	ThemeBuilder.prepare_touch(_list_box)
func _match_filter(item: ItemData) -> bool:
	match _filter:
		"material":
			return item.category == ItemData.Category.MATERIAL
		"consumable":
			return item.category == ItemData.Category.CONSUMABLE
		"equipment":
			return item.category == ItemData.Category.EQUIPMENT
		_:
			return true


func _build_item_cell(item: ItemData) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(76, 76)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.tooltip_text = "%s ×%s" % [item.display_name,
		GameFormulas.format_num(float(GameState.get_item_count(item.id)))]
	_apply_cell_style(button, item.id == _selected_item_id)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(center)
	var frame := IconFrame.new()
	frame.setup(IconLibrary.get_item_icon(item.id), 56, ItemData.element_color(item.element),
		false, 44)
	center.add_child(frame)

	var count := GameState.get_item_count(item.id)
	# 数量角标加宣纸微半透底衬：不再压在图标边框线上，字号 >= FONT_CAPTION
	var count_plate := PanelContainer.new()
	count_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var plate_box := ThemeBuilder.panel_box(Color(0.96, 0.94, 0.89, 0.88),
		Color(0, 0, 0, 0), 6, 0, 0)
	plate_box.content_margin_left = 4
	plate_box.content_margin_right = 4
	plate_box.content_margin_top = 1
	plate_box.content_margin_bottom = 1
	count_plate.add_theme_stylebox_override("panel", plate_box)
	count_plate.anchor_left = 1.0
	count_plate.anchor_right = 1.0
	count_plate.anchor_top = 1.0
	count_plate.anchor_bottom = 1.0
	count_plate.offset_left = -78.0
	count_plate.offset_right = -6.0
	count_plate.offset_top = -23.0
	count_plate.offset_bottom = -5.0
	var count_label := ThemeBuilder.label("×%s" % GameFormulas.format_num(float(count)),
		ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_AMBER)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 数量角标文本裁切：亿级「×10.1亿」也不再把 48px 底板顶宽、挤出物格
	count_label.clip_text = true
	count_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	count_plate.add_child(count_label)
	button.add_child(count_plate)

	var dot_color := ItemData.element_color(item.element)
	if GameState.get_quality_count(item.id, 2) > 0:
		dot_color = ThemeBuilder.COLOR_AMBER
	elif GameState.get_quality_count(item.id, 1) > 0:
		dot_color = ThemeBuilder.COLOR_EMERALD
	var dot := PanelContainer.new()
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.add_theme_stylebox_override("panel", ThemeBuilder.circle_box(dot_color, 8.0))
	dot.anchor_left = 0.0
	dot.anchor_right = 0.0
	dot.anchor_top = 0.0
	dot.anchor_bottom = 0.0
	dot.offset_left = 7.0
	dot.offset_right = 15.0
	dot.offset_top = 7.0
	dot.offset_bottom = 15.0
	button.add_child(dot)

	button.pressed.connect(func() -> void: _select_item(item.id))
	return button


func _apply_cell_style(button: Button, selected: bool) -> void:
	var bg := Color("#F0F7F4") if selected else ThemeBuilder.COLOR_CARD
	var border := ThemeBuilder.COLOR_JADE if selected else ThemeBuilder.COLOR_BORDER
	var width := 2 if selected else 1
	button.add_theme_stylebox_override("normal",
		ThemeBuilder.panel_box(ThemeBuilder.card_color(bg), border, 10, width, 0))
	button.add_theme_stylebox_override("hover",
		ThemeBuilder.panel_box(ThemeBuilder.card_color(
			Color("#F4F9F6") if selected else ThemeBuilder.COLOR_CARD_HOVER),
			ThemeBuilder.COLOR_JADE, 10, width, 0))
	button.add_theme_stylebox_override("pressed",
		ThemeBuilder.panel_box(ThemeBuilder.card_color(Color("#EAF4EF")),
			ThemeBuilder.COLOR_JADE, 10, 2, 0))


func _refresh_grid_selection() -> void:
	for item_id in _grid_buttons.keys():
		var button: Button = _grid_buttons[item_id]
		_apply_cell_style(button, String(item_id) == _selected_item_id)


func _select_item(item_id: String) -> void:
	if AudioManager != null:
		AudioManager.play_tap()
	_selected_item_id = item_id
	_refresh_grid_selection()
	# 宽屏常驻详情卡 / COMPACT 轻触弹 BottomSheet（释放首屏物格视野）
	if _layout_mode == EventBus.LayoutMode.COMPACT:
		_show_item_sheet()
	else:
		_queue_detail_refresh()


## 连点保护：150ms 内只放行第一次操作，避免同一份按钮快照被重复结算导致状态/UI 错位
func _begin_action() -> bool:
	var now := Time.get_ticks_msec()
	if now < _action_lock_ms:
		return false
	_action_lock_ms = now + ACTION_COOLDOWN_MS
	return true


## 详情卡重建合并到帧末：旧节点先 remove_child 再 queue_free（见 _clear），
## 同一帧内多次请求只执行一次，VBox 不会因新旧节点并存被撑爆或重叠。
func _queue_detail_refresh() -> void:
	if _detail_queued:
		return
	_detail_queued = true
	call_deferred("_do_detail_refresh")


func _do_detail_refresh() -> void:
	_detail_queued = false
	_refresh_detail()


## 先取锚点中心再改状态：装备 / 卸下会立刻触发重建，节点随后可能被回收
func _anchor_center(anchor: Control) -> Vector2:
	if anchor == null or not is_instance_valid(anchor):
		return Vector2(-1.0, -1.0)
	return anchor.get_global_rect().get_center()


func _play_artifact_fx(center: Vector2, equipped: bool) -> void:
	if center.x < 0.0 or not is_visible_in_tree() or InkVfxLayer.instance == null:
		return
	InkVfxLayer.instance.play_artifact_resonance(center, equipped)


func _refresh_detail() -> void:
	if _detail_box == null or _detail_panel == null:
		return
	_clear(_detail_box)
	var item := DataRegistry.get_item(_selected_item_id)
	if item == null or GameState.get_item_count(item.id) <= 0:
		# 固定高度槽位：无选中时显示占位，不再隐藏（隐藏/出现会把列表推来推去）
		var placeholder := ThemeBuilder.label("选中物品查看详情", ThemeBuilder.FONT_BODY_SUB,
			ThemeBuilder.COLOR_TEXT_MUTED)
		placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		placeholder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_detail_box.add_child(placeholder)
		return
	# 可见性归 _apply_width 统一管理（COMPACT 隐藏详情卡、改走 BottomSheet）
	_detail_box.add_child(_build_detail_nodes(item, false))


## COMPACT：轻触物格弹出三段式详情 BottomSheet（身份 + 数值 + 用途 + 操作）
func _show_item_sheet() -> void:
	var item := DataRegistry.get_item(_selected_item_id)
	if item == null:
		return
	if AudioManager != null:
		AudioManager.play_tap()
	_show_item_detail_sheet(item)


## 操作后联动：弹窗内物品耗尽则自动收起
func _after_item_op(item_id: String, from_sheet: bool) -> void:
	if from_sheet and BottomSheet.instance != null \
			and GameState.get_item_count(item_id) <= 0:
		BottomSheet.instance.hide_sheet()


## 详情弹窗操作后：穿戴/整批售出等目标完成即刻收起；
## 单件出售/单颗使用且仍有库存时，原位刷新持有数量与按钮状态。
func _after_sheet_action(item: ItemData, success: bool,
		force_close: bool = false) -> void:
	if not success:
		return
	if force_close or GameState.get_item_count(item.id) <= 0:
		if BottomSheet.instance != null and is_instance_valid(BottomSheet.instance):
			BottomSheet.instance.hide_sheet()
		return
	_show_item_detail_sheet(item)


## 详情内容构建（宽屏固定卡与 COMPACT BottomSheet 共用同一份 UI）
func _build_detail_nodes(item: ItemData, from_sheet: bool) -> VBoxContainer:
	var wrap := ThemeBuilder.vbox(6)
	var count := GameState.get_item_count(item.id)
	var fine_count := GameState.get_quality_count(item.id, 1)
	var epic_count := GameState.get_quality_count(item.id, 2)

	var row := ThemeBuilder.hbox(10)
	wrap.add_child(row)
	var icon_frame := IconFrame.new()
	icon_frame.setup(IconLibrary.get_item_icon(item.id, 2 if epic_count > 0 else (
		1 if fine_count > 0 else -1)), 68, ItemData.element_color(item.element), false, 48)
	row.add_child(icon_frame)

	var info := ThemeBuilder.vbox(3)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	var title_row := ThemeBuilder.hbox(6)
	info.add_child(title_row)
	var name_label := ThemeBuilder.card_title_label(item.display_name)
	ThemeBuilder.apply_material_grade_style(name_label,
		int(DataRegistry.get_material_grade(item.id).get("tier", 1)) \
			if not DataRegistry.get_material_grade(item.id).is_empty() else 0)
	title_row.add_child(name_label)
	title_row.add_child(ThemeBuilder.chip(ItemData.element_name(item.element),
		ItemData.element_color(item.element)))
	title_row.add_child(ThemeBuilder.expander())
	title_row.add_child(ThemeBuilder.label("×%s" % GameFormulas.format_num(float(count)), 15,
		ThemeBuilder.COLOR_AMBER))
	var stat_text := item.get_stat_summary()
	if stat_text != "":
		info.add_child(ThemeBuilder.wrap_label(stat_text, ThemeBuilder.FONT_BODY_SUB,
			ThemeBuilder.COLOR_EMERALD))
	if item.id == DataRegistry.SPIRIT_DEW:
		info.add_child(ThemeBuilder.wrap_label(
			"当前吞服可得修为 +%d" % GameState.get_spirit_dew_gain(), ThemeBuilder.FONT_CAPTION,
			ThemeBuilder.COLOR_EMERALD))
	elif item.id == DataRegistry.CRIMSON_FRUIT:
		var eaten := GameState.crimson_fruit_eaten
		var cap := GameFormulas.CRIMSON_FRUIT_CAP
		var fruit_text := "已炼化 %d / %d 枚" % [eaten, cap]
		if eaten >= cap:
			fruit_text += " · 已满，可出售"
		info.add_child(ThemeBuilder.wrap_label(fruit_text, ThemeBuilder.FONT_CAPTION,
			ThemeBuilder.COLOR_AMBER if eaten >= cap else ThemeBuilder.COLOR_JADE))
	# 同行拆色：品阶称谓走品阶字色，「单价」辅助灰，数字主数值色
	var price_row := ThemeBuilder.hbox(4)
	var grade: Dictionary = DataRegistry.get_material_grade(item.id)
	if not grade.is_empty():
		price_row.add_child(ThemeBuilder.label(String(grade["name"]),
			ThemeBuilder.FONT_CAPTION,
			ThemeBuilder.material_grade_color(int(grade["tier"]))))
	price_row.add_child(ThemeBuilder.label("单价", ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_SECONDARY))
	price_row.add_child(ThemeBuilder.label("%d 灵石" % item.sell_price,
		ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_PRIMARY))
	price_row.add_child(ThemeBuilder.expander())
	info.add_child(price_row)

	var actions := ThemeBuilder.hbox(6)
	wrap.add_child(actions)
	if item.is_equipment():
		var equip_button := ThemeBuilder.small_button("穿戴", true)
		custom_minimum_size_check(equip_button)
		ThemeBuilder.apply_primary_button(equip_button)
		equip_button.pressed.connect(func() -> void:
			if not _begin_action():
				return
			var center := _anchor_center(icon_frame)
			GameState.equip_item(item.id)
			_play_artifact_fx(center, true)
			_after_item_op(item.id, from_sheet)
		)
		actions.add_child(equip_button)
	if item.is_consumable():
		var is_special := item.id == DataRegistry.SPIRIT_DEW \
			or item.id == DataRegistry.CRIMSON_FRUIT
		var use_button := ThemeBuilder.small_button("吞服" if is_special else "使用", true)
		custom_minimum_size_check(use_button)
		ThemeBuilder.apply_primary_button(use_button)
		if item.id == DataRegistry.CRIMSON_FRUIT \
				and GameState.crimson_fruit_eaten >= GameFormulas.CRIMSON_FRUIT_CAP:
			use_button.text = "已炼满"
			use_button.disabled = true
		use_button.pressed.connect(func() -> void:
			if not _begin_action():
				return
			GameState.use_item(item.id)
			_after_item_op(item.id, from_sheet)
		)
		actions.add_child(use_button)
	if item.id != DataRegistry.SPIRIT_STONE:
		var sell_button := ThemeBuilder.small_button("出售")
		custom_minimum_size_check(sell_button)
		sell_button.pressed.connect(func() -> void:
			if not _begin_action():
				return
			GameState.sell_item(item.id, 1)
			_after_item_op(item.id, from_sheet)
		)
		actions.add_child(sell_button)
		if count > 1:
			var sell_all := ThemeBuilder.small_button("全售")
			custom_minimum_size_check(sell_all)
			sell_all.pressed.connect(func() -> void:
				if not _begin_action():
					return
				GameState.sell_item(item.id, count)
				_after_item_op(item.id, from_sheet)
			)
			actions.add_child(sell_all)
		if fine_count > 0:
			var sell_fine := ThemeBuilder.small_button("售精")
			custom_minimum_size_check(sell_fine)
			sell_fine.pressed.connect(func() -> void:
				if not _begin_action():
					return
				GameState.sell_quality_item(item.id, 1, 1)
				_after_item_op(item.id, from_sheet)
			)
			actions.add_child(sell_fine)
		if epic_count > 0:
			var sell_epic := ThemeBuilder.small_button("售极")
			custom_minimum_size_check(sell_epic)
			sell_epic.pressed.connect(func() -> void:
				if not _begin_action():
					return
				GameState.sell_quality_item(item.id, 1, 2)
				_after_item_op(item.id, from_sheet)
			)
			actions.add_child(sell_epic)
	ThemeBuilder.prepare_touch(wrap)
	return wrap


## 操作按钮统一 44 高触控热区
func custom_minimum_size_check(button: Button) -> void:
	button.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)


## 随身法宝属性行：基础值 + 祭炼增益鎏金括号（兵刃括攻、法袍括气血/防），
## HFlow 多 Label 天然换行（禁用 RichTextLabel：最小宽≈0 逐字换行会撑爆行高）
func _build_temper_stats_row(item: ItemData, quality: int, temper_level: int,
		slot: String) -> Control:
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 0)
	flow.add_theme_constant_override("v_separation", 2)
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var mult := GameState.get_quality_multiplier(quality)
	var parts: Array = []
	if item.attack_bonus != 0:
		parts.append({"label": "攻", "value": int(round(float(item.attack_bonus) * mult)),
			"temper": temper_level * 15 if slot == "weapon" else 0})
	if item.defense_bonus != 0:
		parts.append({"label": "防", "value": int(round(float(item.defense_bonus) * mult)),
			"temper": temper_level * 10 if slot == "armor" else 0})
	if item.max_hp_bonus != 0:
		parts.append({"label": "气血", "value": int(round(float(item.max_hp_bonus) * mult)),
			"temper": temper_level * 180 if slot == "armor" else 0})
	if item.accuracy_bonus != 0:
		parts.append({"label": "命中", "value": int(round(float(item.accuracy_bonus) * mult)),
			"temper": 0})
	if item.crit_bonus != 0.0:
		parts.append({"label": "会心", "value": int(round(item.crit_bonus * mult)),
			"temper": 0, "suffix": "%"})
	if item.dodge_bonus != 0.0:
		parts.append({"label": "闪避", "value": int(round(item.dodge_bonus * mult)),
			"temper": 0, "suffix": "%"})
	var first := true
	for part in parts:
		if not first:
			flow.add_child(ThemeBuilder.label(" · ", ThemeBuilder.FONT_CAPTION,
				ThemeBuilder.COLOR_TEXT_JADE))
		first = false
		flow.add_child(ThemeBuilder.label("%s +%d%s" % [
			part["label"], part["value"], String(part.get("suffix", ""))],
			ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_JADE))
		if int(part["temper"]) > 0:
			flow.add_child(ThemeBuilder.label("(+%d)" % int(part["temper"]),
				ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_GOLD))
	return flow


## 本命祭炼弹窗：祭炼层次 / 消耗 / 属性增量对比 + 祭炼 1 次 / 连炼 10 次
func _show_temper_sheet(slot: String) -> void:
	if not GameState.can_temper_equipment():
		EventBus.toast.emit("需 筑基中期")
		return
	var level := GameState.get_temper_level(slot)
	var stone := GameState.temper_stone_cost(slot)
	var mat_need := GameState.temper_material_cost(slot)
	var mat_id := GameState.find_temper_material()
	var slot_name := "兵刃" if slot == "weapon" else "法袍"
	# 累计收益按实际等级计算（非单级增量）
	var gain_text := ""
	var next_gain_text := ""
	var per_level := ""
	if slot == "weapon":
		gain_text = "攻击 +%d · 会心 +%.2f%% · 全百艺双倍 +%.1f%%" % [
			level * 15, minf(float(level) * 0.15, 25.0), float(level / 5) * 0.5]
		next_gain_text = "攻击 +%d · 会心 +%.2f%% · 全百艺双倍 +%.1f%%" % [
			(level + 1) * 15, minf(float(level + 1) * 0.15, 25.0),
			float((level + 1) / 5) * 0.5]
		per_level = "本重 +15 攻 / +0.15% 会心"
	else:
		gain_text = "气血 +%d · 防御 +%d · 全百艺耗时 -%.1f%%" % [
			level * 180, level * 10, float(level / 5) * 0.5]
		next_gain_text = "气血 +%d · 防御 +%d · 全百艺耗时 -%.1f%%" % [
			(level + 1) * 180, (level + 1) * 10, float((level + 1) / 5) * 0.5]
		per_level = "本重 +180 气血 / +10 防御"
	var rows: Array = [{
		"text": "当前累计（祭炼 %d 重）" % level,
		"desc": "%s。" % gain_text,
	}]
	var next_desc := "灵石 %s" % GameFormulas.format_num(float(stone))
	if mat_id == "":
		next_desc = "需库存 3 阶以上灵材/丹药（当前无富余）"
	else:
		next_desc += " + %s ×%d（存 %s）" % [DataRegistry.get_item_name(mat_id), mat_need,
			GameFormulas.format_num(float(GameState.get_item_count(mat_id)))]
	rows.append({
		"text": "祭炼至 %d 重累计" % (level + 1),
		"desc": "%s（%s）。消耗：%s。" % [next_gain_text, per_level, next_desc],
	})
	var ops := ThemeBuilder.hbox(8)
	ops.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var once := ThemeBuilder.button("祭炼 1 次")
	once.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
	once.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ThemeBuilder.apply_font_size(once, ThemeBuilder.FONT_BODY_SUB)
	ThemeBuilder.apply_brush_kai(once)
	ThemeBuilder.apply_primary_button(once)
	once.pressed.connect(func() -> void: _do_temper(slot, 1))
	ops.add_child(once)
	var ten := ThemeBuilder.button("连炼 10 次")
	ten.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
	ten.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ThemeBuilder.apply_font_size(ten, ThemeBuilder.FONT_BODY_SUB)
	ThemeBuilder.apply_brush_kai(ten)
	ThemeBuilder.apply_secondary_button(ten)
	ten.pressed.connect(func() -> void: _do_temper(slot, 10))
	ops.add_child(ten)
	ThemeBuilder.prepare_touch(ops)
	rows.append({"custom": ops})
	BottomSheet.show_text("本命祭炼 · %s" % slot_name, rows,
		ThemeBuilder.COLOR_JADE)


func _do_temper(slot: String, times: int) -> void:
	if not _begin_action():
		return
	if BottomSheet.instance != null:
		BottomSheet.instance.hide_sheet()
	var result := GameState.temper_equipment(slot, times)
	if not bool(result.get("ok", false)):
		EventBus.toast.emit("祭炼未成：灵石或 3 阶以上灵材不足")
		return
	_rebuild_equipment()
	EventBus.toast.emit("祭炼至 %d 重（+%d 重）：消耗 灵石 %s、%s ×%d" % [
		GameState.get_temper_level(slot),
		int(result["levels"]),
		GameFormulas.format_num(float(int(result["stones"]))),
		DataRegistry.get_item_name(String(result["mat_id"])),
		int(result["mat_amount"])])
	GameState.vibrate_medium()


# ---------------------------------------------------------------- 一键化灵

## 当前门槛下可化灵的材料 { item_id: count }；include_herbs=false 只收木材与矿石
func _collect_dissolvable(include_herbs: bool) -> Dictionary:
	var threshold := GameFormulas.outdated_material_threshold(GameState.get_skill_level_cap())
	var out := {}
	for key in GameState.inventory.keys():
		var item_id := String(key)
		var count := GameState.get_item_count(item_id)
		if count <= 0:
			continue
		var info: Dictionary = DataRegistry.get_material_tier_info(item_id)
		if info.is_empty():
			continue
		if not include_herbs and String(info.get("category", "")) != "wood_ore":
			continue
		if int(info.get("unlock_level", 9999)) > threshold:
			continue
		out[item_id] = count
	return out


## 按钮态：有可化灵材料 → 鎏金描边高亮；无 → 柔和置灰（点击提示暂无）
func _refresh_dissolve_button() -> void:
	if _dissolve_button == null:
		return
	var has := not _collect_dissolvable(false).is_empty()
	_dissolve_button.add_theme_color_override("font_color",
		ThemeBuilder.COLOR_TEXT_GOLD if has else ThemeBuilder.COLOR_TEXT_MUTED)
	if has:
		_dissolve_button.add_theme_stylebox_override("normal",
			ThemeBuilder.panel_box(ThemeBuilder.COLOR_GOLD_SOFT,
				ThemeBuilder.COLOR_AMBER, 8, 1, 8))
		_dissolve_button.tooltip_text = "把落后当前境界的旧木材矿石折算成灵石"
	else:
		_dissolve_button.remove_theme_stylebox_override("normal")
		_dissolve_button.tooltip_text = ""


func _on_dissolve_pressed() -> void:
	if _collect_dissolvable(false).is_empty():
		EventBus.toast.emit("暂无过时低阶材料")
		return
	_show_dissolve_sheet(false)


## 化灵预览浮层：汇总 + 范围切换（实时重算）+ 明细清单 + 确认按钮
func _show_dissolve_sheet(include_herbs: bool) -> void:
	if AudioManager != null:
		AudioManager.play_tap()
	var items := _collect_dissolvable(include_herbs)
	var total := 0
	var item_ids := items.keys()
	item_ids.sort()
	for item_id in item_ids:
		var unit := DataRegistry.get_material_dissolve_value(String(item_id))
		total += unit * int(items[item_id])

	var settings_card := ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD_DEEP,
		ThemeBuilder.COLOR_BORDER, 8, 12)
	settings_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var settings_box := ThemeBuilder.vbox(6)
	settings_card.add_child(settings_box)
	var settings_title := ThemeBuilder.section_title_label("筛选与预计收益",
		ThemeBuilder.FONT_BODY_SUB)
	ThemeBuilder.apply_font_size(settings_title, ThemeBuilder.FONT_BODY_SUB)
	settings_box.add_child(settings_title)
	var summary := ThemeBuilder.hbox(8)
	summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_box.add_child(summary)
	var scope_label := ThemeBuilder.label("筛出范围：过时灵材",
		ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_SECONDARY)
	scope_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scope_label.custom_minimum_size = Vector2(0, 0)
	scope_label.clip_text = true
	scope_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	ThemeBuilder.apply_font_size(scope_label, ThemeBuilder.FONT_CAPTION)
	summary.add_child(scope_label)
	var gain_label := ThemeBuilder.label("预计凝练 +%d 灵石" % total,
		ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_GOLD)
	gain_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	gain_label.custom_minimum_size = Vector2(0, 0)
	gain_label.clip_text = true
	gain_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	ThemeBuilder.apply_font_size(gain_label, ThemeBuilder.FONT_CAPTION)
	summary.add_child(gain_label)
	var scope_text := "范围：%s ▸" % ("仅过时木材与矿石" if not include_herbs
		else "含过时草药与妖兽材料")
	var scope_button := ThemeBuilder.small_button(scope_text)
	scope_button.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
	scope_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ThemeBuilder.apply_font_size(scope_button, ThemeBuilder.FONT_CAPTION)
	ThemeBuilder.clip_button_text(scope_button, scope_text)
	scope_button.pressed.connect(func() -> void:
		if BottomSheet.instance != null and is_instance_valid(BottomSheet.instance):
			BottomSheet.instance.hide_sheet()
		_show_dissolve_sheet(not include_herbs))
	settings_box.add_child(scope_button)

	var list_card := ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD_DEEP,
		ThemeBuilder.COLOR_BORDER, 8, 12)
	list_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var list_box := ThemeBuilder.vbox(6)
	list_card.add_child(list_box)
	var list_title := ThemeBuilder.section_title_label("化灵清单", ThemeBuilder.FONT_BODY_SUB)
	ThemeBuilder.apply_font_size(list_title, ThemeBuilder.FONT_BODY_SUB)
	list_box.add_child(list_title)
	if item_ids.is_empty():
		var empty_label := ThemeBuilder.wrap_label("暂无可化灵的低阶材料。",
			ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_SECONDARY)
		ThemeBuilder.apply_font_size(empty_label, ThemeBuilder.FONT_CAPTION)
		list_box.add_child(empty_label)
	for item_id in item_ids:
		var unit := DataRegistry.get_material_dissolve_value(String(item_id))
		var count := int(items[item_id])
		var tier := int(DataRegistry.get_material_grade(String(item_id)).get("tier", 1))
		var row := ThemeBuilder.hbox(6)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var name_label := ThemeBuilder.label("%s ×%d（单价 %d）" % [
			DataRegistry.get_item_name(String(item_id)), count, unit],
			ThemeBuilder.FONT_CAPTION, ThemeBuilder.get_material_grade_color(tier))
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.clip_text = true
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		ThemeBuilder.apply_font_size(name_label, ThemeBuilder.FONT_CAPTION)
		row.add_child(name_label)
		var value_label := ThemeBuilder.label("+%d 灵石" % (unit * count),
			ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_JADE)
		value_label.size_flags_horizontal = Control.SIZE_SHRINK_END
		ThemeBuilder.apply_font_size(value_label, ThemeBuilder.FONT_CAPTION)
		row.add_child(value_label)
		list_box.add_child(row)

	var confirm_text := "确认化灵 · +%d 灵石" % total
	BottomSheet.show_detail({
		"title": "低阶材料化灵",
		"rows": [
			{"custom": settings_card},
			{"custom": list_card},
		],
		"actions": [{
			"text": confirm_text,
			"primary": true,
			"full_width": true,
			"callback": func() -> void:
				if BottomSheet.instance != null and is_instance_valid(BottomSheet.instance):
					BottomSheet.instance.hide_sheet()
				_confirm_dissolve(items, total),
		}],
	})


## 结算（防连点）：原子扣除 + 灵石到账，行囊列表经 inventory_changed 信号安全刷新
func _confirm_dissolve(items: Dictionary, _expected: int) -> void:
	var now := Time.get_ticks_msec()
	if now < _dissolve_lock_ms:
		return
	_dissolve_lock_ms = now + ACTION_COOLDOWN_MS
	var gained := GameState.dissolve_materials_for_stones(items)
	if gained > 0:
		if AudioManager != null:
			AudioManager.play_coin()
		EventBus.toast.emit("一键化灵完成：共获灵石 +%s" % GameFormulas.format_num(float(gained)))
	# 浮层由 BottomSheet 回调行自动关闭，这里只负责结算与刷新


# ---------------------------------------------------------------- 批量熔炼（淘汰装备）

## 装备综合战力评分：攻 + 防×1.5 + 气血×0.08，再乘品质加成倍率
func _equip_score(item: ItemData, quality: int) -> float:
	var mult := GameState.get_quality_multiplier(quality)
	return (float(item.attack_bonus) + float(item.defense_bonus) * 1.5
		+ float(item.max_hp_bonus) * 0.08) * mult


## 淘汰判定：阶位过时（unlock ≤ cap-20）或属性低于对应槽位已穿戴装备。
## 返回原因标签（空串 = 未淘汰）。
func _obsolete_reason(item: ItemData, quality: int) -> String:
	var cap := GameState.get_skill_level_cap()
	var unlock := DataRegistry.get_equipment_unlock_level(item.id)
	if unlock <= GameFormulas.obsolete_equipment_threshold(cap):
		return "旧阶"
	var worn: Dictionary = GameState.get_equipped(item.equip_slot)
	var worn_id := String(worn.get("id", ""))
	if worn_id != "" and worn_id != item.id:
		var worn_item := DataRegistry.get_item(worn_id)
		if worn_item != null:
			var worn_quality := clampi(int(worn.get("quality", 0)), 0, 2)
			if _equip_score(item, quality) < _equip_score(worn_item, worn_quality):
				return "低于已装备"
	return ""


## 待熔炼清单：[{ item_id, quality, count, reason }]。
## 极品（q2）永远保护；include_fine=true 才纳入精良（q1）。
func _collect_smeltable(include_fine: bool) -> Array:
	var seen: Dictionary = {}
	for key in GameState.inventory.keys():
		if DataRegistry.get_item(String(key)) != null \
				and DataRegistry.get_item(String(key)).is_equipment():
			seen[String(key)] = true
	for key in GameState.fine_items.keys():
		if int(GameState.fine_items[key]) > 0:
			seen[String(key)] = true
	var out: Array = []
	for item_id in seen.keys():
		var item := DataRegistry.get_item(String(item_id))
		if item == null:
			continue
		for quality in [0, 1]:
			if quality == 1 and not include_fine:
				continue
			var count := GameState.get_quality_count(String(item_id), quality)
			if count <= 0:
				continue
			var reason := _obsolete_reason(item, quality)
			if reason == "":
				continue
			out.append({"item_id": String(item_id), "quality": quality,
				"count": count, "reason": reason})
	return out


## 批量操作栏：两枚按钮任意分页常驻（只切换样式，绝不显隐改变布局）
func _refresh_action_row() -> void:
	if _dissolve_button == null or _smelt_button == null:
		return
	_style_batch_button(_dissolve_button, not _collect_dissolvable(false).is_empty(),
		"把落后当前境界的旧木材矿石折算成灵石", "暂无过时低阶材料")
	_style_batch_button(_smelt_button, not _collect_smeltable(false).is_empty(),
		"把落后当前境界的闲置装备熔炼成材料或灵石", "暂无可熔炼的淘汰装备")


## 可处理=浅鎏金底+沉金褐描边；暂无=柔和浅米底+淡描边（按钮永远在场，点击给轻提示）
func _style_batch_button(button: Button, ready: bool, tip_ready: String, tip_empty: String) -> void:
	if ready:
		var normal := ThemeBuilder.panel_box(Color("#F5ECDC"),
			ThemeBuilder.COLOR_TEXT_TITLE_GOLD, 8, 2, 8)
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover",
			ThemeBuilder.panel_box(Color("#EFE1CB"), ThemeBuilder.COLOR_TEXT_TITLE_GOLD, 8, 2, 8))
		button.add_theme_stylebox_override("pressed",
			ThemeBuilder.panel_box(Color("#EADBC2"), ThemeBuilder.COLOR_TEXT_TITLE_GOLD, 8, 2, 8))
		button.add_theme_stylebox_override("disabled", normal)
		button.add_theme_color_override("font_color", Color("#7A5018"))
		button.add_theme_color_override("font_hover_color", Color("#7A5018"))
		button.add_theme_color_override("font_disabled_color", Color("#7A5018"))
		button.tooltip_text = tip_ready
	else:
		var idle := ThemeBuilder.panel_box(ThemeBuilder.COLOR_SUBTLE,
			ThemeBuilder.COLOR_BORDER, 8, 1, 8)
		button.add_theme_stylebox_override("normal", idle)
		button.add_theme_stylebox_override("hover", idle)
		button.add_theme_stylebox_override("pressed", idle)
		button.add_theme_stylebox_override("disabled", idle)
		button.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT_MUTED)
		button.add_theme_color_override("font_hover_color", ThemeBuilder.COLOR_TEXT_MUTED)
		button.add_theme_color_override("font_disabled_color", ThemeBuilder.COLOR_TEXT_MUTED)
		button.tooltip_text = tip_empty


func _on_smelt_pressed() -> void:
	if _collect_smeltable(false).is_empty():
		EventBus.toast.emit("暂无可熔炼的淘汰装备")
		return
	_show_smelt_sheet(false, "materials")


## 双模式预览浮层：收益预览 + 模式切换 + 品质保护开关 + 待熔炼清单 + 确认
func _show_smelt_sheet(include_fine: bool, mode: String) -> void:
	if AudioManager != null:
		AudioManager.play_tap()
	var targets := _collect_smeltable(include_fine)
	var total_stones := 0
	var total_materials: Dictionary = {}
	var total_pieces := 0
	for target in targets:
		var dict: Dictionary = target
		# 每条候选是一个「堆叠」：收益与件数都必须乘以 count（玄铁飞剑×5 = 5 件）
		var count := int(dict.get("count", 1))
		total_pieces += count
		var smelt_yield: Dictionary = DataRegistry.get_equipment_smelt_yield(
			String(dict["item_id"]), int(dict["quality"]), mode)
		total_stones += int(smelt_yield.get("stones", 0)) * count
		var materials: Dictionary = smelt_yield.get("materials", {})
		for key in materials.keys():
			total_materials[key] = int(total_materials.get(key, 0)) \
				+ int(materials[key]) * count
	var settings_card := ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD_DEEP,
		ThemeBuilder.COLOR_BORDER, 8, 12)
	settings_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var settings_box := ThemeBuilder.vbox(6)
	settings_card.add_child(settings_box)
	var settings_title := ThemeBuilder.section_title_label("熔炼设置与预计返还",
		ThemeBuilder.FONT_BODY_SUB)
	ThemeBuilder.apply_font_size(settings_title, ThemeBuilder.FONT_BODY_SUB)
	settings_box.add_child(settings_title)
	var summary := ThemeBuilder.hbox(8)
	summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_box.add_child(summary)
	var return_title := ThemeBuilder.label("预计返还", ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_SECONDARY)
	return_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ThemeBuilder.apply_font_size(return_title, ThemeBuilder.FONT_CAPTION)
	summary.add_child(return_title)
	var return_parts: Array[String] = []
	if total_stones > 0:
		return_parts.append("灵石 +%d" % total_stones)
	for key in total_materials.keys():
		return_parts.append("%s ×%d" % [DataRegistry.get_item_name(String(key)),
			int(total_materials[key])])
	var return_text := " · ".join(return_parts) if not return_parts.is_empty() else "暂无返还"
	var return_label := ThemeBuilder.label(return_text, ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_GOLD)
	return_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	return_label.clip_text = true
	return_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	ThemeBuilder.apply_font_size(return_label, ThemeBuilder.FONT_CAPTION)
	summary.add_child(return_label)

	var mode_text := "回收模式：%s ▸" % (
		"返还锻造材料" if mode == "materials" else "全额折算灵石")
	var mode_button := ThemeBuilder.small_button(mode_text)
	mode_button.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
	mode_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ThemeBuilder.apply_font_size(mode_button, ThemeBuilder.FONT_CAPTION)
	ThemeBuilder.clip_button_text(mode_button, mode_text)
	mode_button.pressed.connect(func() -> void:
		if BottomSheet.instance != null and is_instance_valid(BottomSheet.instance):
			BottomSheet.instance.hide_sheet()
		_show_smelt_sheet(include_fine,
			"stones" if mode == "materials" else "materials"))
	settings_box.add_child(mode_button)
	var quality_text := "品质保护：已含精良 ▸" if include_fine else "品质保护：仅熔炼凡品 ▸"
	var quality_button := ThemeBuilder.small_button(quality_text)
	quality_button.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
	quality_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ThemeBuilder.apply_font_size(quality_button, ThemeBuilder.FONT_CAPTION)
	ThemeBuilder.clip_button_text(quality_button, quality_text)
	quality_button.pressed.connect(func() -> void:
		if BottomSheet.instance != null and is_instance_valid(BottomSheet.instance):
			BottomSheet.instance.hide_sheet()
		_show_smelt_sheet(not include_fine, mode))
	settings_box.add_child(quality_button)

	var list_card := ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD_DEEP,
		ThemeBuilder.COLOR_BORDER, 8, 12)
	list_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var list_box := ThemeBuilder.vbox(6)
	list_card.add_child(list_box)
	var list_title := ThemeBuilder.section_title_label("待熔装备清单",
		ThemeBuilder.FONT_BODY_SUB)
	ThemeBuilder.apply_font_size(list_title, ThemeBuilder.FONT_BODY_SUB)
	list_box.add_child(list_title)
	if targets.is_empty():
		var empty_label := ThemeBuilder.wrap_label("暂无可熔炼的淘汰装备。",
			ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_SECONDARY)
		ThemeBuilder.apply_font_size(empty_label, ThemeBuilder.FONT_CAPTION)
		list_box.add_child(empty_label)
	for target in targets:
		var dict: Dictionary = target
		var item := DataRegistry.get_item(String(dict["item_id"]))
		if item == null:
			continue
		var tier := int(DataRegistry.get_material_grade(item.id).get("tier", 1))
		var row := ThemeBuilder.hbox(6)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var name_label := ThemeBuilder.label("%s ×%d" % [
			item.display_name, int(dict["count"])],
			ThemeBuilder.FONT_CAPTION, ThemeBuilder.get_material_grade_color(tier))
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.clip_text = true
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		ThemeBuilder.apply_font_size(name_label, ThemeBuilder.FONT_CAPTION)
		row.add_child(name_label)
		var reason := String(dict.get("reason", "可熔"))
		if not reason.contains("可熔"):
			reason += "可熔"
		var reason_label := ThemeBuilder.label(reason, ThemeBuilder.FONT_CAPTION,
			ThemeBuilder.COLOR_TEXT_SECONDARY)
		reason_label.size_flags_horizontal = Control.SIZE_SHRINK_END
		ThemeBuilder.apply_font_size(reason_label, ThemeBuilder.FONT_CAPTION)
		row.add_child(reason_label)
		list_box.add_child(row)

	var confirm_text := "确认熔炼 (%d 件)" % total_pieces if not targets.is_empty() \
		else "暂无可熔装备"
	BottomSheet.show_detail({
		"title": "淘汰装备批量熔炼",
		"rows": [
			{"custom": settings_card},
			{"custom": list_card},
		],
		"actions": [{
			"text": confirm_text,
			"primary": true,
			"full_width": true,
			"disabled": targets.is_empty(),
			"callback": func() -> void:
				if BottomSheet.instance != null and is_instance_valid(BottomSheet.instance):
					BottomSheet.instance.hide_sheet()
				_confirm_smelt(targets, mode),
		}],
	})


func _confirm_smelt(targets: Array, mode: String) -> void:
	var now := Time.get_ticks_msec()
	if now < _smelt_lock_ms:
		return
	_smelt_lock_ms = now + ACTION_COOLDOWN_MS
	var result: Dictionary = GameState.smelt_obsolete_equipment(targets, mode)
	var smelted := int(result.get("smelted_count", 0))
	if smelted <= 0:
		EventBus.toast.emit("没有可熔炼的装备")
		return
	if AudioManager != null:
		AudioManager.play_coin()
	var stones := int(result.get("stones", 0))
	var materials: Dictionary = result.get("materials", {})
	var parts: Array[String] = []
	if stones > 0:
		parts.append("灵石 +%d" % stones)
	for key in materials.keys():
		parts.append("%s ×%d" % [DataRegistry.get_item_name(String(key)),
			int(materials[key])])
	EventBus.toast.emit("熔炼 %d 件：%s" % [smelted, " · ".join(parts)])


func _show_help() -> void:
	BottomSheet.show_help("储物袋 · 规则", [
		{"text": "万物品阶（涵盖灵材、丹符、法宝、功法与妖兽）", "bbcode": ThemeBuilder.material_grade_legend_bbcode()},
		{"text": "分栏与物格", "desc": "顶部分栏按灵材 / 丹药 / 法宝归类；轻触任意物格，即可在上方详览与施用。"},
		{"text": "品质与五行", "desc": "物格左上角灵点：玉青为精良、泥金为极品，其余显五行本色。"},
		{"text": "操作", "desc": "丹药可吞服，法宝可穿戴，灵材与多余物品可出售；聚灵甘露按当前境界折算修为，百年朱果永久增加气血与攻击。"},
	])


func _rebuild_equipment() -> void:
	_clear(_equip_box)
	var labels := {"weapon": "兵刃", "armor": "法袍"}
	var temper_unlocked := GameState.can_temper_equipment()
	for slot in GameState.EQUIP_SLOTS:
		var column := ThemeBuilder.vbox(3)
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var head := ThemeBuilder.hbox(6)
		head.custom_minimum_size = Vector2(0, 34)
		column.add_child(head)
		head.add_child(ThemeBuilder.label(String(labels.get(slot, slot)), ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_DIM))

		var entry := GameState.get_equipped(slot)
		var item_id := String(entry.get("id", ""))
		var quality := clampi(int(entry.get("quality", 0)), 0, 2)
		var slot_icon := IconFrame.new()
		head.add_child(slot_icon)
		if item_id == "":
			var placeholder := "equip_sword" if slot == "weapon" else "equip_robe"
			slot_icon.setup(IconLibrary.get_icon(placeholder,
				ThemeBuilder.hex(ThemeBuilder.COLOR_TEXT_MUTED),
				ThemeBuilder.hex(ThemeBuilder.COLOR_ICON_FRAME_BORDER)), 30,
				ThemeBuilder.COLOR_TEXT_MUTED)
			head.add_child(ThemeBuilder.dim_label("未装备", ThemeBuilder.FONT_CAPTION))
			var locked_temper := ThemeBuilder.small_button("需 筑基中期" if not temper_unlocked
				else "祭炼（需先穿戴法宝）")
			locked_temper.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
			locked_temper.disabled = true
			locked_temper.tooltip_text = "" if temper_unlocked else "筑基中期开启祭炼"
			ThemeBuilder.apply_font_size(locked_temper, ThemeBuilder.FONT_BODY_SUB)
			column.add_child(locked_temper)
		else:
			var item := DataRegistry.get_item(item_id)
			var item_name := item_id if item == null else item.display_name
			var accent := ThemeBuilder.COLOR_JADE
			if quality == 2:
				accent = ThemeBuilder.COLOR_AMBER
			elif quality == 1:
				accent = ThemeBuilder.COLOR_EMERALD
			slot_icon.setup(IconLibrary.get_item_icon(item_id, quality), 30, accent)
			var name_label := ThemeBuilder.label(item_name, ThemeBuilder.FONT_BODY_SUB)
			name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			name_label.clip_text = true
			name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			head.add_child(name_label)
			# 祭炼/品质徽标改挂第二行流式容器：两枚印章不再和名称挤在同一行，
			# 450 宽 + 1.20 大字档下两个法宝槽才能保持左右并排而不撑破卡片
			var badge_row := HFlowContainer.new()
			badge_row.add_theme_constant_override("h_separation", 4)
			badge_row.add_theme_constant_override("v_separation", 2)
			badge_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			column.add_child(badge_row)
			var temper_level := GameState.get_temper_level(slot)
			if temper_level > 0:
				badge_row.add_child(ThemeBuilder.create_seal_badge("祭炼 +%d" % temper_level,
					"gold" if temper_level >= 10 else "jade"))
			if quality > 0:
				# 品质徽标紧凑「极品 / 精良」（增益数字在括号拆色行体现）
				badge_row.add_child(ThemeBuilder.create_seal_badge(
					GameState.get_quality_name(quality),
					"gold" if quality == 2 else "jade"))
			if item != null:
				# 属性行 + 祭炼增益鎏金括号（如「攻 +1652(+735)」），点击祭炼立刻可见跳涨
				column.add_child(_build_temper_stats_row(item, quality, temper_level, slot))
			var btn_row := ThemeBuilder.hbox(6)
			column.add_child(btn_row)
			var temper_button := ThemeBuilder.small_button("祭炼" if temper_unlocked
				else "需 筑基中期")
			temper_button.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
			temper_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			temper_button.disabled = not temper_unlocked
			temper_button.tooltip_text = "" if temper_unlocked else "筑基中期开启祭炼"
			ThemeBuilder.apply_font_size(temper_button, ThemeBuilder.FONT_BODY_SUB)
			ThemeBuilder.apply_brush_kai(temper_button)
			temper_button.pressed.connect(func() -> void:
				if AudioManager != null:
					AudioManager.play_tap()
				_show_temper_sheet(slot))
			btn_row.add_child(temper_button)
			var button := ThemeBuilder.small_button("卸下")
			button.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			ThemeBuilder.apply_font_size(button, ThemeBuilder.FONT_BODY_SUB)
			button.pressed.connect(func() -> void:
				if not _begin_action():
					return
				var center := _anchor_center(slot_icon)
				GameState.unequip_slot(slot)
				_play_artifact_fx(center, false)
			)
			btn_row.add_child(button)
		_equip_box.add_child(column)


## 按品质折算后的实际攻防（与 GameState 的装备结算完全一致）

	# 动态重建后补挂触控约定（按钮 PASS + 14px 滑动守卫）
	ThemeBuilder.prepare_touch(_equip_box)
func _format_item_stats(item: ItemData, quality: int) -> String:
	var mult := GameState.get_quality_multiplier(quality)
	var parts: Array[String] = []
	if item.attack_bonus != 0:
		parts.append("攻 +%d" % int(round(float(item.attack_bonus) * mult)))
	if item.defense_bonus != 0:
		parts.append("防 +%d" % int(round(float(item.defense_bonus) * mult)))
	if item.max_hp_bonus != 0:
		parts.append("气血 +%d" % int(round(float(item.max_hp_bonus) * mult)))
	if item.accuracy_bonus != 0:
		parts.append("命中 +%d" % int(round(float(item.accuracy_bonus) * mult)))
	# 品质增益已并入右上角徽标（「极品 +18%」），属性句不再拼尾巴防截断
	return " · ".join(parts)


func select_tab(tab: String) -> void:
	if String(tab) in ["all", "material", "consumable", "equipment"]:
		_on_filter_pressed(String(tab))


func _on_filter_pressed(key: String) -> void:
	_filter = key
	# 只清选中，详情槽保持常驻占位（由 rebuild 自动选中当前页首项）
	_selected_item_id = ""
	_refresh_filter_styles()
	rebuild()


## 宽屏详情卡轻触：同样进入三段式详情 BottomSheet
func _show_item_detail() -> void:
	var item := DataRegistry.get_item(_selected_item_id)
	if item == null:
		return
	if AudioManager != null:
		AudioManager.play_tap()
	_show_item_detail_sheet(item)


## 行囊三段式详情：身份（IconFrame + 品阶色名称 + 标签）+ 核心数值 + 用途 + 操作
func _show_item_detail_sheet(item: ItemData) -> void:
	var count := GameState.get_item_count(item.id)
	var fine_count := GameState.get_quality_count(item.id, 1)
	var epic_count := GameState.get_quality_count(item.id, 2)
	var grade: Dictionary = DataRegistry.get_material_grade(item.id)
	var tier := int(grade.get("tier", 0))
	var grade_color := ThemeBuilder.COLOR_TEXT_PRIMARY
	if not grade.is_empty():
		grade_color = ThemeBuilder.material_grade_color(tier)

	var tags: Array = []
	if not grade.is_empty():
		tags.append({"text": String(grade["name"]), "color": grade_color})
	if item.element != ItemData.Element.NONE:
		tags.append({"text": ItemData.element_name(item.element) + "行",
			"color": ItemData.element_color(item.element)})
	tags.append({"text": ItemData.category_name(item.category),
		"color": ThemeBuilder.COLOR_TEXT_SECONDARY})

	var stock := "凡品 ×%d" % count
	if fine_count > 0:
		stock += " · 精良 ×%d" % fine_count
	if epic_count > 0:
		stock += " · 极品 ×%d" % epic_count
	var rows: Array = [
		{"label": "持有", "value": stock, "color": ThemeBuilder.COLOR_TEXT_PRIMARY},
		{"label": "化灵单价", "value": "%d 灵石" % DataRegistry.get_material_dissolve_value(item.id),
			"color": ThemeBuilder.COLOR_TEXT_GOLD},
		{"label": "出售单价", "value": "%d 灵石" % item.sell_price,
			"color": ThemeBuilder.COLOR_TEXT_GOLD},
	]
	var stat_text := item.get_stat_summary()
	if stat_text != "":
		rows.append({"label": "关键属性", "value": stat_text,
			"color": ThemeBuilder.COLOR_TEXT_JADE})
	if not grade.is_empty():
		rows.append({
			"label": "品阶效用",
			"value": "肥力 %d / 株" % int(grade.get("fertility", 0)),
			"color": ThemeBuilder.COLOR_TEXT_JADE,
		})
	if item.id == DataRegistry.SPIRIT_DEW:
		rows.append({
			"label": "吞服修为", "value": "+%d" % GameState.get_spirit_dew_gain(),
			"color": ThemeBuilder.COLOR_TEXT_JADE,
		})
	elif item.id == DataRegistry.CRIMSON_FRUIT:
		rows.append({
			"label": "已炼化",
			"value": "%d / %d" % [GameState.crimson_fruit_eaten, GameFormulas.CRIMSON_FRUIT_CAP],
			"color": ThemeBuilder.COLOR_TEXT_GOLD,
		})

	var note := item.description if item.description != "" else "此物可用于修行、炼制或换取灵石。"
	var sources := DataRegistry.get_item_sources(item.id)
	if not sources.is_empty():
		var source := sources[0] as Dictionary
		note += "\n获取途径：%s" % String(source.get("label", source.get("type", "未知")))

	BottomSheet.show_detail({
		"title": item.display_name,
		"title_color": grade_color,
		"icon": IconLibrary.get_item_icon(item.id, 2 if epic_count > 0 else (
			1 if fine_count > 0 else -1)),
		"icon_accent": ItemData.element_color(item.element),
		"tags": tags,
		"rows": rows,
		"note": note,
		"actions": _build_item_detail_actions(item, count),
	})


func _build_item_detail_actions(item: ItemData, count: int) -> Array:
	var actions: Array = []
	if item.is_equipment():
		actions.append({
			"text": "穿戴", "accent": true, "primary": true,
			"callback": func() -> void:
				if not _begin_action():
					return
				var center := _sheet_icon_center()
				var ok := bool(GameState.equip_item(item.id))
				if ok:
					_play_artifact_fx(center, true)
				_after_sheet_action(item, ok, true),
		})
	if item.is_consumable():
		var is_special := item.id == DataRegistry.SPIRIT_DEW \
			or item.id == DataRegistry.CRIMSON_FRUIT
		var is_cap := item.id == DataRegistry.CRIMSON_FRUIT \
			and GameState.crimson_fruit_eaten >= GameFormulas.CRIMSON_FRUIT_CAP
		actions.append({
			"text": "已炼满" if is_cap else ("吞服" if is_special else "使用"),
			"accent": true, "primary": true, "disabled": is_cap,
			"callback": func() -> void:
				if not _begin_action():
					return
				var ok := bool(GameState.use_item(item.id))
				_after_sheet_action(item, ok),
		})
	if item.id != DataRegistry.SPIRIT_STONE:
		actions.append({
			"text": "出售",
			"callback": func() -> void:
				if not _begin_action():
					return
				var ok := bool(GameState.sell_item(item.id, 1))
				_after_sheet_action(item, ok),
		})
		if count > 1:
			actions.append({
				"text": "全售",
				"callback": func() -> void:
					if not _begin_action():
						return
					var ok := bool(GameState.sell_item(item.id, count))
					_after_sheet_action(item, ok, true),
			})
		if GameState.get_quality_count(item.id, 1) > 0:
			actions.append({
				"text": "售精",
				"callback": func() -> void:
					if not _begin_action():
						return
					var ok := bool(GameState.sell_quality_item(item.id, 1, 1))
					_after_sheet_action(item, ok),
			})
		if GameState.get_quality_count(item.id, 2) > 0:
			actions.append({
				"text": "售极",
				"callback": func() -> void:
					if not _begin_action():
						return
					var ok := bool(GameState.sell_quality_item(item.id, 1, 2))
					_after_sheet_action(item, ok, true),
			})
	return actions


func _sheet_icon_center() -> Vector2:
	if BottomSheet.instance != null and is_instance_valid(BottomSheet.instance):
		return BottomSheet.instance.detail_icon_center()
	return Vector2(-1, -1)


## 分类栏两态样式：选中=浅玉青底+黛玉青描边+深玉青字；未选中=浅宣纸米底+柔和次要字
func _refresh_filter_styles() -> void:
	for filter_key in _filter_buttons.keys():
		var button: Button = _filter_buttons[filter_key]
		var selected := String(filter_key) == _filter
		button.button_pressed = selected
		if selected:
			var sel := ThemeBuilder.panel_box(Color("#E5EFEA"),
				ThemeBuilder.COLOR_TEXT_JADE, 8, 2, 10)
			button.add_theme_stylebox_override("normal", sel)
			button.add_theme_stylebox_override("hover", sel)
			button.add_theme_stylebox_override("pressed", sel)
			button.add_theme_stylebox_override("disabled", sel)
			button.add_theme_color_override("font_color", Color("#1E5644"))
			button.add_theme_color_override("font_hover_color", Color("#1E5644"))
			button.add_theme_color_override("font_pressed_color", Color("#1E5644"))
		else:
			var idle := ThemeBuilder.panel_box(ThemeBuilder.COLOR_SUBTLE,
				ThemeBuilder.COLOR_BORDER, 8, 1, 10)
			button.add_theme_stylebox_override("normal", idle)
			button.add_theme_stylebox_override("hover",
				ThemeBuilder.panel_box(ThemeBuilder.COLOR_SUBTLE_HOVER,
					ThemeBuilder.COLOR_BORDER, 8, 1, 10))
			button.add_theme_stylebox_override("pressed", idle)
			button.add_theme_stylebox_override("disabled", idle)
			button.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT_SECONDARY)
			button.add_theme_color_override("font_hover_color", ThemeBuilder.COLOR_TEXT_PRIMARY)
			button.add_theme_color_override("font_pressed_color", ThemeBuilder.COLOR_TEXT_PRIMARY)


func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()














