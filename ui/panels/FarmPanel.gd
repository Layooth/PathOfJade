class_name FarmPanel
extends Control
## 「洞府灵田」：独立于挂机槽位的第三条后台产线，真实时间戳驱动，离线照常成熟。

const PLOT_NAMES: Array[String] = ["一", "二", "三", "四"]

var _summary_label: Label
var _aura_panel: PanelContainer
var _aura_label: Label
var _soil_label: Label
## 灵脉明细：生长 / 伴生 / 灵气反哺增量，可换行不截断
var _soil_detail_label: Label
var _soil_button: Button
var _plots_box: GridContainer
var _harvest_all_button: Button
var _replant_button: Button
var _plot_refs: Array = []
var _plot_cards: Array = []
var _seed_box: VBoxContainer
var _seed_hint_label: Label
var _body: BoxContainer
var _left_col: VBoxContainer
var _right_col: VBoxContainer
## 窄屏滚动内容列：灵田网格 + 灵种匣同列，仓库紧贴网格下方
var _scroll_content: VBoxContainer
var _selected_plot: int = -1
var _is_dirty: bool = false


func _ready() -> void:
	_build()
	EventBus.farm_changed.connect(_on_farm_changed)
	EventBus.inventory_changed.connect(_on_inventory_changed)
	EventBus.game_loaded.connect(_on_farm_changed)
	EventBus.layout_changed.connect(_on_layout_changed)
	EventBus.realm_changed.connect(_on_realm_changed_for_gates)
	visibility_changed.connect(_on_visibility_changed)
	_rebuild()


func _on_realm_changed_for_gates(_realm_id: String, _realm_name: String) -> void:
	_refresh_soil_label()
	_refresh_summary()


func _on_inventory_changed() -> void:
	if not is_visible_in_tree():
		_is_dirty = true
		return
	# 库存变化只更新灵种匣 / 摘要 / 灵脉数字，不重建整页地块卡
	_refresh_soil_label()
	_refresh_summary()
	_refresh_seed_overview()


func _on_visibility_changed() -> void:
	set_process(is_visible_in_tree())
	if is_visible_in_tree() and _is_dirty:
		_is_dirty = false
		_rebuild()


func _process(_delta: float) -> void:
	for ref in _plot_refs:
		var dict: Dictionary = ref
		var index := int(dict.get("index", -1))
		var bar: ProgressBar = dict.get("bar", null)
		var remain: RichTextLabel = dict.get("remain", null)
		var icon: IconFrame = dict.get("icon", null)
		if index < 0 or bar == null:
			continue
		var stage := _plot_stage(index)
		if icon != null and stage != int(dict.get("stage", stage)):
			dict["stage"] = stage
			icon.set_icon(_crop_icon(stage, String(dict.get("crop_id", ""))),
				_stage_accent(stage))
		bar.value = FarmManager.get_progress(index)
		if remain != null:
			remain.text = _remain_text(index, String(dict.get("crop_id", "")))


## 生长中/成熟地块展示真实作物图标（空闲/未开垦保留通用地格图）
func _crop_icon(stage: int, crop_id: String) -> Texture2D:
	if stage > 0 and crop_id != "":
		return IconLibrary.get_item_icon(crop_id)
	return _stage_texture(stage, crop_id)


## 紧凑时长：1时29分 / 12分30秒 / 45秒
func _compact_duration(sec: float) -> String:
	var s := int(ceil(sec))
	if s >= 3600:
		return "%d时%d分" % [s / 3600, (s % 3600) / 60]
	if s >= 60:
		return "%d分%d秒" % [s / 60, s % 60]
	return "%d秒" % maxi(1, s)


## 倒计时与库存同行拆色：[浓墨]剩余 …[次要灰] · 存…
func _remain_text(index: int, crop_id: String) -> String:
	if FarmManager.is_mature(index):
		return "[color=%s]已成熟[/color]" % ThemeBuilder.hex(ThemeBuilder.COLOR_TEXT_JADE)
	return "[color=%s]剩余 %s[/color][color=%s] · 存%s[/color]" % [
		ThemeBuilder.hex(ThemeBuilder.COLOR_TEXT_PRIMARY),
		_compact_duration(FarmManager.get_remaining(index)),
		ThemeBuilder.hex(ThemeBuilder.COLOR_TEXT_SECONDARY),
		GameFormulas.format_num(float(GameState.get_item_count(crop_id)))]


# ---------------------------------------------------------------- 构建

func _build() -> void:
	var root := ThemeBuilder.vbox(10)
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 10)

	var header := ThemeBuilder.card_panel()
	root.add_child(header)
	var head_box := ThemeBuilder.vbox(4)
	header.add_child(head_box)
	var title_row := ThemeBuilder.hbox(8)
	head_box.add_child(title_row)
	title_row.add_child(ThemeBuilder.title_label("洞府灵田", 20))
	# 「后台生长」装饰标签已移除：标题行只留毛笔标题 + 弹性占位 + 最右「?」
	title_row.add_child(ThemeBuilder.expander())
	var help := ThemeBuilder.create_help_button(_show_help)
	help.custom_minimum_size = Vector2(44, 44)
	help.tooltip_text = "洞府灵田规则"
	title_row.add_child(help)
	# 汇总行可换行：大数字（灵种库存 1.2万）+ 1.20 大字档下不允许把卡片撑宽
	_summary_label = ThemeBuilder.wrap_label("", ThemeBuilder.FONT_BODY_SUB,
		ThemeBuilder.COLOR_TEXT_DIM)
	head_box.add_child(_summary_label)

	# 灵气反哺光环：浅玉青状态胶囊，随已播种田数实时变化
	_aura_panel = PanelContainer.new()
	_aura_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_aura_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_aura_label = ThemeBuilder.label("", ThemeBuilder.FONT_BODY_SUB)
	_aura_panel.add_child(_aura_label)
	head_box.add_child(_aura_panel)
	# 仙壤淬灵：灵脉品阶 + 淬灵按钮；明细独立成行可换行，1.20 大字档也不截断
	var soil_box := ThemeBuilder.vbox(2)
	soil_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head_box.add_child(soil_box)
	var soil_row := ThemeBuilder.hbox(8)
	soil_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	soil_box.add_child(soil_row)
	_soil_label = ThemeBuilder.label("", ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_JADE)
	soil_row.add_child(_soil_label)
	soil_row.add_child(ThemeBuilder.expander())
	_soil_button = ThemeBuilder.small_button("淬灵")
	_soil_button.custom_minimum_size = Vector2(64, ThemeBuilder.TOUCH_MIN)
	_soil_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ThemeBuilder.apply_font_size(_soil_button, ThemeBuilder.FONT_BODY_SUB)
	ThemeBuilder.apply_brush_kai(_soil_button)
	_soil_button.pressed.connect(_show_soil_sheet)
	soil_row.add_child(_soil_button)
	_soil_detail_label = ThemeBuilder.wrap_label("", ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_SECONDARY)
	_soil_detail_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	soil_box.add_child(_soil_detail_label)
	ThemeBuilder.attach_header_watermark(header, IconLibrary.get_nav_icon("farm"))

	# 主体：窄屏上下堆叠 / 宽屏左「灵田」右「灵种匣」
	_body = BoxContainer.new()
	_body.vertical = true
	_body.add_theme_constant_override("separation", 10)
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_body)

	_left_col = ThemeBuilder.vbox(8)
	_left_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_left_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_child(_left_col)

	var action_row := ThemeBuilder.hbox(6)
	_left_col.add_child(action_row)
	_harvest_all_button = ThemeBuilder.button("一键收获")
	ThemeBuilder.apply_brush_kai(_harvest_all_button)
	_harvest_all_button.custom_minimum_size = Vector2(0, 48)
	_harvest_all_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_harvest_all_button.size_flags_stretch_ratio = 6.0
	ThemeBuilder.apply_primary_button(_harvest_all_button)
	_harvest_all_button.add_theme_color_override("font_disabled_color",
		ThemeBuilder.COLOR_TEXT_MUTED)
	_harvest_all_button.pressed.connect(_on_harvest_all_pressed)
	action_row.add_child(_harvest_all_button)

	# 一键播种：浅玉青描边（#E5EFEA 底 + 黛玉青描边），与主收获按钮同量级
	_replant_button = ThemeBuilder.button("一键播种")
	ThemeBuilder.apply_brush_kai(_replant_button)
	_replant_button.custom_minimum_size = Vector2(0, 48)
	_replant_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_replant_button.size_flags_stretch_ratio = 4.0
	ThemeBuilder.apply_font_size(_replant_button, ThemeBuilder.FONT_BODY_SUB)
	_replant_button.add_theme_stylebox_override("normal",
		ThemeBuilder.panel_box(Color("#E5EFEA"), ThemeBuilder.COLOR_TEXT_JADE, 8, 1, 10))
	_replant_button.add_theme_stylebox_override("hover",
		ThemeBuilder.panel_box(Color("#DBEAE4"), ThemeBuilder.COLOR_TEXT_JADE, 8, 1, 10))
	_replant_button.add_theme_stylebox_override("pressed",
		ThemeBuilder.panel_box(Color("#D5E5DE"), ThemeBuilder.COLOR_TEXT_JADE, 8, 1, 10))
	_replant_button.add_theme_stylebox_override("disabled",
		ThemeBuilder.panel_box(ThemeBuilder.COLOR_SUBTLE, ThemeBuilder.COLOR_BORDER, 8, 1, 10))
	_replant_button.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT_JADE)
	_replant_button.add_theme_color_override("font_disabled_color", ThemeBuilder.COLOR_TEXT_MUTED)
	_replant_button.pressed.connect(_on_plant_all_pressed)
	action_row.add_child(_replant_button)

	var scroll := ThemeBuilder.scroll_container()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_left_col.add_child(scroll)
	# 滚动内容只保留一个子容器：窄屏时灵种匣并入此列，紧贴灵田网格下方
	_scroll_content = ThemeBuilder.vbox(12)
	_scroll_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_scroll_content)
	# 2 列 × 2 行：一屏看全 4 块灵田
	_plots_box = GridContainer.new()
	_plots_box.columns = 2
	_plots_box.add_theme_constant_override("h_separation", 8)
	_plots_box.add_theme_constant_override("v_separation", 8)
	_plots_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll_content.add_child(_plots_box)

	# 灵种匣（宽屏常驻右栏，窄屏接在网格下方）
	_right_col = ThemeBuilder.vbox(8)
	_right_col.custom_minimum_size = Vector2(240, 0)
	_right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_child(_right_col)
	var seed_panel := ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD_DEEP, ThemeBuilder.COLOR_BORDER, 10, 10)
	_right_col.add_child(seed_panel)
	var seed_outer := ThemeBuilder.vbox(4)
	seed_panel.add_child(seed_outer)
	var seed_title := ThemeBuilder.hbox(6)
	seed_outer.add_child(seed_title)
	seed_title.add_child(ThemeBuilder.card_title_label("灵种匣",
		ThemeBuilder.FONT_CARD_TITLE, ThemeBuilder.COLOR_AMBER))
	seed_title.add_child(ThemeBuilder.expander())
	_seed_hint_label = ThemeBuilder.dim_label("", ThemeBuilder.FONT_CAPTION)
	seed_title.add_child(_seed_hint_label)
	_seed_box = ThemeBuilder.vbox(4)
	_seed_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	seed_outer.add_child(_seed_box)

	ThemeBuilder.prepare_touch(root)
	_apply_width(EventBus.workspace_width)


func _on_layout_changed(_mode: int, _vp_size: Vector2, workspace_width: float) -> void:
	_apply_width(workspace_width)


func _apply_width(workspace_width: float) -> void:
	var wide := workspace_width >= 680.0
	if _body != null:
		_body.vertical = not wide
	if _right_col != null:
		_right_col.custom_minimum_size = Vector2(240.0 if wide else 0.0, 0)
	# 窄屏把「灵种匣」搬进滚动列紧贴网格；宽屏搬回右栏，左右分栏不变
	if _right_col != null and _scroll_content != null and _body != null:
		var target: Node = _body if wide else _scroll_content
		if _right_col.get_parent() != target:
			_right_col.reparent(target, false)
		if wide and _left_col != null:
			_body.move_child(_right_col, _left_col.get_index() + 1)


func _is_wide() -> bool:
	return EventBus.workspace_width >= 680.0


func _rebuild() -> void:
	_refresh_soil_label()
	if _plots_box == null:
		return
	_clear(_plots_box)
	_plot_refs.clear()
	_plot_cards.clear()
	for i in range(FarmManager.get_plot_count()):
		var card := _build_plot_card(i)
		_plots_box.add_child(card)
		_plot_cards.append(card)
	_refresh_summary()
	_refresh_seed_overview()


## 灵种匣：持有灵种列表，宽屏可直接点选播种（点地块 → 点灵种）

	# 动态重建后补挂触控约定（按钮 PASS + 14px 滑动守卫）
	ThemeBuilder.prepare_touch(_scroll_content)
func _refresh_seed_overview() -> void:
	if _seed_box == null:
		return
	for child in _seed_box.get_children():
		_seed_box.remove_child(child)
		child.queue_free()
	var free_plot := _first_empty_plot()
	if _seed_hint_label != null:
		if _is_wide() and _selected_plot >= 0:
			_seed_hint_label.text = "已选 %d 号田" % (_selected_plot + 1)
			_seed_hint_label.add_theme_color_override("font_color", ThemeBuilder.COLOR_JADE)
		elif free_plot < 0:
			# 满耕是常态而非危险：暖灰提示（§4.4 朱砂红仅用于缺料/危险）
			_seed_hint_label.text = "灵田已满耕"
			_seed_hint_label.add_theme_color_override("font_color",
				ThemeBuilder.COLOR_TEXT_SECONDARY)
		elif _is_wide():
			_seed_hint_label.text = "先点左侧空闲田"
			_seed_hint_label.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT_DIM)
		else:
			_seed_hint_label.text = ""
			_seed_hint_label.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT_DIM)

	var has_seed := false
	var seed_entries: Array = []
	for seed_data in DataRegistry.get_all_seeds():
		var dict: Dictionary = seed_data
		var seed_id := String(dict.get("id", ""))
		var count := GameState.get_item_count(seed_id)
		if count <= 0:
			continue
		seed_entries.append({"id": seed_id, "count": count,
			"name": String(dict.get("name", seed_id))})
	# 有库存灵种按品阶降序（同阶来源等级降序）：高阶常用置顶
	seed_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ga: Dictionary = DataRegistry.get_item_grade(String(a["id"]))
		var gb: Dictionary = DataRegistry.get_item_grade(String(b["id"]))
		if int(ga.get("tier", 0)) != int(gb.get("tier", 0)):
			return int(ga.get("tier", 0)) > int(gb.get("tier", 0))
		return int(ga.get("unlock_level", 0)) > int(gb.get("unlock_level", 0)))
	for entry in seed_entries:
		var seed_id := String(entry["id"])
		var count := int(entry["count"])
		has_seed = true
		var row := ThemeBuilder.hbox(6)
		row.add_child(ThemeBuilder.icon_rect(IconLibrary.get_item_icon(seed_id), 18))
		var name_label := ThemeBuilder.label("%s ×%s" % [
			String(entry["name"]).replace("灵种", "种"),
			GameFormulas.format_num(float(count))], ThemeBuilder.FONT_BODY_SUB,
			ThemeBuilder.COLOR_TEXT)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# 长名称 + 大数量时省略而不是把整行撑出卡片（横向溢出会被窗口裁掉）
		name_label.clip_text = true
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		ThemeBuilder.apply_material_grade_style(name_label,
			int(DataRegistry.get_material_grade(seed_id).get("tier", 1)))
		row.add_child(name_label)
		var plant := ThemeBuilder.small_button("播种")
		plant.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
		ThemeBuilder.apply_font_size(plant, ThemeBuilder.FONT_CAPTION)
		if free_plot < 0:
			# 没有已开垦空田时不再提供无效点击
			plant.text = "无空地"
			plant.disabled = true
		plant.pressed.connect(_on_seed_clicked.bind(seed_id))
		row.add_child(plant)
		_seed_box.add_child(row)
	# 动态行补挂触控约定（PASS + 14px 滑动守卫）
	ThemeBuilder.prepare_touch(_seed_box)
	if has_seed:
		return
	_seed_box.add_child(ThemeBuilder.label("尚无灵种，可去仙坊阁购买，或采药时偶得",
		ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_DIM))
	var go := ThemeBuilder.small_button("前往仙坊阁")
	go.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
	ThemeBuilder.apply_font_size(go, ThemeBuilder.FONT_CAPTION)
	go.pressed.connect(func() -> void:
		EventBus.navigate_to_source.emit({"type": "shop", "tab": "seed"})
	)
	_seed_box.add_child(go)


## 宽屏：点「播种」先选中地块，再点右侧灵种；窄屏：弹选种浮层
func _on_plant_pressed(index: int) -> void:
	if _is_wide():
		_selected_plot = index
		_rebuild()
		return
	_open_seed_picker(index)


## 第一块「已开垦且空闲」的灵田；没有则返回 -1
func _first_empty_plot() -> int:
	for i in range(FarmManager.get_plot_count()):
		if FarmManager.is_unlocked(i) and FarmManager.is_empty(i):
			return i
	return -1


func _on_seed_clicked(seed_id: String) -> void:
	if not _is_wide():
		# 竖屏：灵种匣直接种进第一块空闲田，不再要求“先选左侧地块”
		var free_plot := _first_empty_plot()
		if free_plot < 0:
			EventBus.toast.emit("暂无空闲灵田：成熟田先收割，未开垦田可往仙坊阁开辟")
			return
		var compact_check := FarmManager.can_plant(free_plot, seed_id)
		if not bool(compact_check.get("ok", false)):
			EventBus.toast.emit(String(compact_check.get("reason", "该地块不可播种")))
			return
		FarmManager.plant(free_plot, seed_id)
		_rebuild()
		return

	if _selected_plot < 0:
		if _first_empty_plot() < 0:
			EventBus.toast.emit("暂无空闲灵田：成熟田先收割，未开垦田可往仙坊阁开辟")
		else:
			EventBus.toast.emit("先轻触左侧空闲灵田，再择灵种")
		return
	var check := FarmManager.can_plant(_selected_plot, seed_id)
	if not bool(check.get("ok", false)):
		EventBus.toast.emit(String(check.get("reason", "该地块不可播种")))
		return
	FarmManager.plant(_selected_plot, seed_id)
	_selected_plot = -1
	_rebuild()


## 0 空闲 / 1 幼芽(<40%) / 2 生长期 / 3 成熟
func _plot_stage(index: int) -> int:
	if FarmManager.is_empty(index):
		return 0
	if FarmManager.is_mature(index):
		return 3
	return 1 if FarmManager.get_progress(index) < 0.35 else 2


func _stage_accent(stage: int) -> Color:
	return ThemeBuilder.COLOR_AMBER if stage == 3 else ThemeBuilder.COLOR_JADE


func _stage_texture(stage: int, crop_id: String) -> Texture2D:
	if stage == 0:
		return IconLibrary.get_farm_icon(0, crop_id)
	if stage == 3:
		return IconLibrary.get_farm_growth_icon("farm_stage_mature", crop_id)
	if stage == 2:
		return IconLibrary.get_farm_growth_icon("farm_stage_growing", crop_id)
	return IconLibrary.get_farm_growth_icon("farm_stage_sprout", crop_id)


func _build_plot_card(index: int) -> PanelContainer:
	var plot := FarmManager.get_plot(index)
	var unlocked := bool(plot.get("unlocked", false))
	var seed_id := String(plot.get("seed_id", ""))
	var mature := FarmManager.is_mature(index)

	# 只有「100% 成熟可收割」才用玉青高亮边框，生长中统一低调暗玉灰
	var border := ThemeBuilder.COLOR_BORDER
	if mature:
		border = ThemeBuilder.COLOR_JADE
	elif _is_wide() and _selected_plot == index:
		border = ThemeBuilder.COLOR_JADE
	var card := ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD, border, 12, 10)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# 2x2 网格四张卡统一最小高度，同一行左右严格等高
	card.custom_minimum_size = Vector2(0, 148)
	var box := ThemeBuilder.vbox(4)
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_child(box)

	var stage := _plot_stage(index)
	var seed_data := DataRegistry.get_seed(seed_id)
	var crop_id := String(seed_data.get("crop_id", ""))
	var title_row := ThemeBuilder.hbox(6)
	box.add_child(title_row)
	var icon_frame := IconFrame.new()
	title_row.add_child(icon_frame)
	# 未开垦与空闲同处 stage 0：未开垦改用专用荒石杂草图标 + 暗灰背光，
	# 否则两种状态只能靠 0.75 透明度区分，视觉上几乎同图
	var icon_texture: Texture2D = _crop_icon(stage, crop_id) if unlocked \
		else IconLibrary.get_farm_locked_icon()
	var icon_accent: Color = _stage_accent(stage) if unlocked else ThemeBuilder.COLOR_TEXT_DIM
	icon_frame.setup(icon_texture, 52, icon_accent, stage == 3, 48)

	var title_col := ThemeBuilder.vbox(0)
	title_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title_col)
	var plot_name := PLOT_NAMES[index] if index < PLOT_NAMES.size() else str(index + 1)
	title_col.add_child(ThemeBuilder.card_title_label("%s号灵田" % plot_name))
	var state_text := "未开垦"
	var state_color := ThemeBuilder.COLOR_TEXT_DIM
	var fert_count := FarmManager.get_fertilize_count(index)
	if mature:
		state_text = "可收割"
		state_color = ThemeBuilder.COLOR_JADE
	elif seed_id != "":
		state_text = "生长中"
		state_color = ThemeBuilder.COLOR_AMBER
	elif unlocked:
		state_text = "空闲"
	# 灵肥进度与产量叠加显性化：「生长中 · 灵肥 1/3 · 产量+20%」
	var state_row_text := state_text
	if seed_id != "":
		if fert_count >= FarmManager.MAX_FERT_PER_GROWTH:
			state_row_text += " · 已施足 (3/3)"
		else:
			state_row_text += " · 灵肥 %d/3" % fert_count
		if fert_count > 0:
			state_row_text += "[color=%s] · 产量+%d%%[/color]" % [
				ThemeBuilder.hex(ThemeBuilder.COLOR_TEXT_JADE),
				int(round(FarmManager.get_plot_yield_bonus(index) * 100.0))]
	if state_row_text.find("[color") >= 0:
		var state_rich := ThemeBuilder.bbcode_label(
			"[color=%s]%s[/color]" % [ThemeBuilder.hex(state_color), state_row_text],
			ThemeBuilder.FONT_CAPTION)
		title_col.add_child(state_rich)
	else:
		title_col.add_child(ThemeBuilder.label(state_text, ThemeBuilder.FONT_CAPTION, state_color))

	# 状态副文固定一行：未开垦也有说明，避免只有标题导致卡片高度不齐
	var sub_text := "未开垦，可于仙坊阁开垦。"
	var sub_color := ThemeBuilder.COLOR_TEXT_MUTED
	if unlocked:
		if seed_id == "":
			sub_text = "空闲地块，轻触播种。"
			sub_color = ThemeBuilder.COLOR_TEXT_SECONDARY
		elif mature:
			sub_text = "灵田已熟，可即刻收割。"
			sub_color = ThemeBuilder.COLOR_TEXT_JADE
		else:
			sub_text = "灵肥已施足 (3/3)。" \
				if fert_count >= FarmManager.MAX_FERT_PER_GROWTH \
				else "灵田生长中，可施近阶灵肥（%d/3）。" % fert_count
			sub_color = ThemeBuilder.COLOR_TEXT_SECONDARY
	var state_sub := ThemeBuilder.label(sub_text, ThemeBuilder.FONT_CAPTION, sub_color)
	# 固定单行：窄卡片只省略不换行，保证四张卡描述区高度完全一致
	state_sub.clip_text = true
	state_sub.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	state_sub.custom_minimum_size = Vector2(0, 18)
	state_sub.tooltip_text = sub_text
	box.add_child(state_sub)
	# 描述区与底部按钮之间弹性占位，压住按钮底边对齐
	box.add_child(_plot_elastic_space())

	if not unlocked:
		card.modulate.a = 0.75
		var open_button := ThemeBuilder.small_button("前往仙坊阁 ▸")
		open_button.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
		# 直接落到「洞府扩建」页签：否则会停在法器宝具页，玩家找不到开垦项
		open_button.pressed.connect(func() -> void:
			EventBus.navigate_to_source.emit({"type": "shop", "tab": "farm"})
		)
		box.add_child(open_button)
		return card

	if seed_id == "":
		var plant_button := ThemeBuilder.small_button("播种")
		plant_button.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
		plant_button.add_theme_color_override("font_color", ThemeBuilder.COLOR_JADE)
		plant_button.pressed.connect(_on_plant_pressed.bind(index))
		box.add_child(plant_button)
		return card

	# 单行收获物名（去掉「XXX种 →」冗余前缀），品阶字色 + 省略号防贴边
	var crop_label := ThemeBuilder.label(DataRegistry.get_item_name(crop_id),
		ThemeBuilder.FONT_BODY_SUB)
	ThemeBuilder.apply_item_grade_style(crop_label, crop_id)
	crop_label.clip_text = true
	crop_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(crop_label)

	# 灵田生长条统一暖金棕胶囊（成熟与否由「可收获」徽记表达，不靠条色）
	var bar := ThemeBuilder.progress_bar_grow()
	bar.value = FarmManager.get_progress(index)
	box.add_child(bar)

	# 灵肥徽记 + 剩余时间：流式布局，2 列格子遇上 1.20 大字档会自动换行，
	# 不再把「余 XX 分 XX 秒」顶到卡片右边框（HBox + expander 在窄列里必然溢出）
	# 倒计时 + 库存同行拆色（紧凑「剩余 1时29分 · 存1.23万」，产量层数已在状态行）
	var info_row := HFlowContainer.new()
	info_row.add_theme_constant_override("h_separation", 6)
	info_row.add_theme_constant_override("v_separation", 2)
	box.add_child(info_row)
	# 成熟/生长状态同样把按钮压到卡片底边，与空闲/未开垦两卡同基线
	box.add_child(_plot_elastic_space())
	var remain := ThemeBuilder.bbcode_label(_remain_text(index, crop_id),
		ThemeBuilder.FONT_BODY_SUB)
	# 撑满行宽防逐字换行（流式容器给窄宽度时 fit_content 会把文本挤成竖排）
	remain.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_row.add_child(remain)

	if mature:
		var harvest_button := ThemeBuilder.small_button("收割")
		harvest_button.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
		harvest_button.add_theme_color_override("font_color", ThemeBuilder.COLOR_JADE)
		harvest_button.pressed.connect(_on_harvest_pressed.bind(index))
		box.add_child(harvest_button)
	else:
		_plot_refs.append({"index": index, "bar": bar, "remain": remain,
			"icon": icon_frame, "crop_id": crop_id, "stage": stage})
		# 施灵肥：只显示近阶灵草；每轮最多 3 次。按钮文案同时显示灵肥进度。
		var plan := FarmManager.get_best_fertilizer_herb(
			FarmManager.preferred_fertilizer_herb, index)
		var fert_row := ThemeBuilder.hbox(6)
		fert_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_child(fert_row)
		var fertilize_button := ThemeBuilder.small_button("施灵肥（需近阶灵草）")
		fertilize_button.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
		fertilize_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ThemeBuilder.apply_font_size(fertilize_button, ThemeBuilder.FONT_BODY_SUB)
		fertilize_button.clip_text = true
		fertilize_button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		if fert_count >= FarmManager.MAX_FERT_PER_GROWTH:
			fertilize_button.text = "已施足"
			fertilize_button.disabled = true
			fertilize_button.add_theme_color_override("font_disabled_color",
				ThemeBuilder.COLOR_TEXT_JADE)
			fertilize_button.tooltip_text = "本轮灵肥已施满 3 次"
		elif plan.is_empty():
			fertilize_button.disabled = true
			fertilize_button.add_theme_color_override("font_disabled_color",
				ThemeBuilder.COLOR_TEXT_MUTED)
			fertilize_button.tooltip_text = "需近阶灵草（灵草阶位最多低于作物 1 阶）"
		else:
			var herb_id := String(plan["item_id"])
			fertilize_button.text = "灵肥 %s×%d (%d/3)" % [
				DataRegistry.get_item_name(herb_id), int(plan["count_needed"]), fert_count]
			fertilize_button.add_theme_color_override("font_color",
				ThemeBuilder.COLOR_TEXT_JADE)
			fertilize_button.tooltip_text = "近阶灵草 · 每轮最多 3 次"
		fertilize_button.pressed.connect(_on_fertilize_pressed.bind(index))
		fert_row.add_child(fertilize_button)
		var pick_button := ThemeBuilder.small_button("选草")
		pick_button.custom_minimum_size = Vector2(64, ThemeBuilder.TOUCH_MIN)
		ThemeBuilder.apply_font_size(pick_button, ThemeBuilder.FONT_CAPTION)
		pick_button.disabled = plan.is_empty()
		pick_button.tooltip_text = "需近阶灵草" if plan.is_empty() else "选择合资格灵草施肥"
		pick_button.pressed.connect(_show_fertilize_sheet.bind(index))
		fert_row.add_child(pick_button)

	return card


func _plot_elastic_space() -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 0)
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return spacer


# ---------------------------------------------------------------- 刷新

func _on_farm_changed() -> void:
	if not is_visible_in_tree():
		_is_dirty = true
		return
	_queue_refresh()


## 脏标记合并刷新：同帧多信号只重绘一次（call_deferred 收口）
var _refresh_queued := false


func _queue_refresh() -> void:
	if _refresh_queued:
		return
	_refresh_queued = true
	call_deferred("_do_refresh")


func _do_refresh() -> void:
	_refresh_queued = false
	if not is_visible_in_tree():
		_is_dirty = true
		return
	_rebuild()
	_refresh_summary()
	_refresh_seed_overview()


func _refresh_summary() -> void:
	if _summary_label == null:
		return
	var unlocked := FarmManager.get_unlocked_count()
	var mature := FarmManager.count_mature()
	_summary_label.text = "已开垦 %d / %d · 成熟 %d 块 · 灵种库存 %s" % [
		unlocked, FarmManager.get_plot_count(), mature,
		GameFormulas.format_num(float(_seed_stock()))]
	if _harvest_all_button != null:
		# 左：一键收获（二号灵田后启用；此前保留按钮并给出明确门槛）
		var batch_ok := FarmManager.can_use_batch()
		_harvest_all_button.disabled = not batch_ok or mature <= 0
		_harvest_all_button.text = "需二号灵田" if not batch_ok else "一键收获"
		_harvest_all_button.tooltip_text = "" if batch_ok else "开垦二号灵田后启用批量收获"
	# 右：三态智能按钮（空地→播种 / 满耕生长→催熟 / 全熟→禁用）
	if _replant_button != null:
		if not FarmManager.can_use_batch():
			_set_right_button_mode("locked", 0)
		else:
			var empty := FarmManager.get_empty_unlocked_plot_indices().size()
			var growing := 0
			for i in range(FarmManager.PLOT_COUNT):
				if FarmManager.is_empty(i) or FarmManager.is_mature(i):
					continue
				if bool(FarmManager.get_plot(i).get("unlocked", false)):
					growing += 1
			if empty > 0:
				_set_right_button_mode("plant", empty)
			elif growing > 0:
				_set_right_button_mode("ripen", growing)
			else:
				_set_right_button_mode("done", 0)
	_refresh_aura_chip()


## 顶栏右按钮三态切换（重建连接防重复，样式随态切换）
func _set_right_button_mode(mode: String, count: int) -> void:
	if _replant_button == null:
		return
	if _replant_button.pressed.is_connected(_on_plant_all_pressed):
		_replant_button.pressed.disconnect(_on_plant_all_pressed)
	if _replant_button.pressed.is_connected(_on_ripen_all_pressed):
		_replant_button.pressed.disconnect(_on_ripen_all_pressed)
	match mode:
		"locked":
			_replant_button.text = "需二号灵田"
			_replant_button.disabled = true
			_replant_button.tooltip_text = "开垦二号灵田后启用批量播种 / 催熟"
			_apply_right_button_style(false)
		"plant":
			_replant_button.tooltip_text = ""
			_replant_button.text = "一键播种"
			_replant_button.disabled = count <= 0 or _seed_stock() <= 0
			_apply_right_button_style(false)
			_replant_button.pressed.connect(_on_plant_all_pressed)
		"ripen":
			var can_ripen := FarmManager.can_batch_ripen()
			_replant_button.text = "一键催熟" if can_ripen else "灵肥已足"
			_replant_button.disabled = not can_ripen
			_replant_button.tooltip_text = "" if can_ripen \
				else "生长中地块已施满 3 次，或无近阶灵草"
			_apply_right_button_style(true)
			_replant_button.pressed.connect(_on_ripen_all_pressed)
		_:
			_replant_button.tooltip_text = ""
			_replant_button.text = "均已成熟"
			_replant_button.disabled = true
			_apply_right_button_style(false)


## 播动态=浅玉青描边；催熟态=浅鎏金描边 + 沉金褐毛笔字
func _apply_right_button_style(gold: bool) -> void:
	var bg := Color("#F3E9D6") if gold else Color("#E5EFEA")
	var hover := Color("#EEDFC4") if gold else Color("#DBEAE4")
	var pressed := Color("#E8D8BA") if gold else Color("#D5E5DE")
	var edge := ThemeBuilder.COLOR_TEXT_GOLD if gold else ThemeBuilder.COLOR_TEXT_JADE
	_replant_button.add_theme_stylebox_override("normal",
		ThemeBuilder.panel_box(bg, edge, 8, 1, 10))
	_replant_button.add_theme_stylebox_override("hover",
		ThemeBuilder.panel_box(hover, edge, 8, 1, 10))
	_replant_button.add_theme_stylebox_override("pressed",
		ThemeBuilder.panel_box(pressed, edge, 8, 1, 10))
	_replant_button.add_theme_stylebox_override("disabled",
		ThemeBuilder.panel_box(ThemeBuilder.COLOR_SUBTLE, ThemeBuilder.COLOR_BORDER, 8, 1, 10))
	_replant_button.add_theme_color_override("font_color",
		ThemeBuilder.COLOR_TEXT_GOLD if gold else ThemeBuilder.COLOR_TEXT_JADE)
	_replant_button.add_theme_color_override("font_disabled_color",
		ThemeBuilder.COLOR_TEXT_MUTED)


## 一键催熟：所有生长中地块连续施肥至成熟或草药耗尽（逻辑在 FarmManager 单出口）
func _on_ripen_all_pressed() -> void:
	var result := FarmManager.ripen_all_plots()
	var did := int(result.get("plots", 0))
	var consumed: Dictionary = result.get("consumed", {})
	if did <= 0:
		EventBus.toast.emit("灵肥已足" if not FarmManager.can_batch_ripen()
			else "需近阶灵草")
		return
	EventBus.inventory_changed.emit()
	EventBus.farm_changed.emit()
	GameState.vibrate_medium()
	EventBus.toast.emit("灵肥催熟 %d 块：%s" % [did, _format_items(consumed)])


func _refresh_aura_chip() -> void:
	if _aura_panel == null or _aura_label == null:
		return
	var aura := GameState.get_farm_aura_breakdown()
	var planted := int(aura["planted"])
	var soil_level := int(aura["soil_level"])
	var soil_cultivation := int(round(float(aura["soil_cultivation"]) * 100.0))
	var soil_alchemy := int(round(float(aura["soil_alchemy"]) * 100.0))
	if planted > 0:
		var cultivation := int(round(float(aura["cultivation"]) * 100.0))
		var alchemy := int(round(float(aura["alchemy"]) * 100.0))
		_aura_label.text = "灵气反哺：修为 +%d%% · 丹道双倍 +%d%%" % [cultivation, alchemy]
		_aura_label.add_theme_color_override("font_color", ThemeBuilder.COLOR_JADE)
		_aura_panel.tooltip_text = "灵田 %d 块：修为 +%d%% · 丹道 +%d%%；灵脉 %d 重：修为 +%d%% · 丹道 +%d%%" % [
			planted,
			int(round(float(aura["plot_cultivation"]) * 100.0)),
			int(round(float(aura["plot_alchemy"]) * 100.0)),
			soil_level, soil_cultivation, soil_alchemy]
		var box := ThemeBuilder.panel_box(ThemeBuilder.COLOR_JADE_SOFT,
			ThemeBuilder.COLOR_JADE, 8, 1, 8)
		box.content_margin_top = 3
		box.content_margin_bottom = 3
		box.content_margin_left = 10
		box.content_margin_right = 10
		_aura_panel.add_theme_stylebox_override("panel", box)
	else:
		_aura_label.text = "灵气反哺：未激活（播种即生效）"
		_aura_label.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT_DIM)
		_aura_panel.tooltip_text = "已淬灵脉 %d 重：播种后额外获得修为 +%d%% · 丹道 +%d%%" % [
			soil_level, soil_cultivation, soil_alchemy]
		var box := ThemeBuilder.panel_box(ThemeBuilder.COLOR_SUBTLE,
			Color(0, 0, 0, 0), 8, 0, 8)
		box.content_margin_top = 3
		box.content_margin_bottom = 3
		box.content_margin_left = 10
		box.content_margin_right = 10
		_aura_panel.add_theme_stylebox_override("panel", box)


## 仙壤灵脉品阶展示：「灵脉 · 三重」+ 明细行「生长 / 伴生 / 反哺修为 / 丹道双倍」
func _refresh_soil_label() -> void:
	if _soil_label == null:
		return
	var level := FarmManager.soil_spirit_level
	var names := ["零重", "一重", "二重", "三重", "四重", "五重", "六重", "七重", "八重", "九重",
		"十重", "十一重", "十二重", "十三重", "十四重", "十五重", "十六重", "十七重", "十八重", "十九重", "二十重"]
	_soil_label.text = "灵脉 · %s" % names[clampi(level, 0, 20)]
	var aura_cultivation := int(round(GameFormulas.farm_soil_cultivation_pct(level) * 100.0))
	var aura_alchemy := int(round(GameFormulas.farm_soil_alchemy_pct(level) * 100.0))
	var detail := "（生长 -%d%% · 伴生 +%d%% · 反哺修为 +%d%% / 丹道 +%d%%）" % [
		int(round(FarmManager.soil_time_reduction() * 100.0)),
		int(round(FarmManager.soil_rare_bonus() * 100.0)),
		aura_cultivation, aura_alchemy]
	if _soil_detail_label != null:
		_soil_detail_label.text = detail
		_soil_detail_label.tooltip_text = "仙壤灵脉 %d 重：%s；反哺需至少一块已播种灵田生效" % [
			level, detail]
	_soil_label.tooltip_text = _soil_label.text + detail
	# 未达筑基初期只禁用继续淬灵；旧档已有 level 与增益保留原样显示
	if _soil_button != null:
		var can_enrich := FarmManager.can_soil_enrich()
		_soil_button.disabled = not can_enrich
		_soil_button.text = "需 筑基初期" if not can_enrich else "淬灵"
		_soil_button.tooltip_text = "" if can_enrich else "筑基初期开启淬灵，已淬灵脉继续生效"


## 仙壤淬灵弹窗：升级前后生长速度与奇珍伴生率对比
func _show_soil_sheet() -> void:
	if not FarmManager.can_soil_enrich():
		EventBus.toast.emit("需 筑基初期")
		return
	if AudioManager != null:
		AudioManager.play_tap()
	var level := FarmManager.soil_spirit_level
	if level >= 20:
		EventBus.toast.emit("仙壤灵脉已至二十重圆满")
		return
	var stone := FarmManager.soil_spirit_stone_cost()
	var need := FarmManager.soil_spirit_seed_cost()
	var min_tier := FarmManager.soil_seed_min_tier(level)
	var available := FarmManager.soil_seed_available_count(level)
	var card := ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD_DEEP,
		ThemeBuilder.COLOR_BORDER, 8, 12)
	var box := ThemeBuilder.vbox(6)
	card.add_child(box)
	box.add_child(_soil_value_row("生长周期", "-%d%% → -%d%%" % [
		int(round(FarmManager.soil_time_reduction() * 100.0)),
		int(round(minf(0.015 * float(level + 1), 0.30) * 100.0))]))
	box.add_child(_soil_value_row("奇珍伴生", "+%d%% → +%d%%" % [
		int(round(FarmManager.soil_rare_bonus() * 100.0)),
		int(round(minf(0.015 * float(level + 1), 0.30) * 100.0))]))
	# 灵气反哺增量：升级前就能看到这一重带来的收益（需已播种灵田生效）
	box.add_child(_soil_value_row("反哺 · 修为", "+%d%% → +%d%%" % [
		int(round(GameFormulas.farm_soil_cultivation_pct(level) * 100.0)),
		int(round(GameFormulas.farm_soil_cultivation_pct(level + 1) * 100.0))]))
	box.add_child(_soil_value_row("反哺 · 丹道双倍", "+%d%% → +%d%%" % [
		int(round(GameFormulas.farm_soil_alchemy_pct(level) * 100.0)),
		int(round(GameFormulas.farm_soil_alchemy_pct(level + 1) * 100.0))]))
	box.add_child(_soil_value_row("所需灵石", GameFormulas.format_num(float(stone))))
	box.add_child(_soil_value_row("所需灵种", "%d 阶及以上灵种 %d 枚 · 当前可用 %d 枚" % [
		min_tier, need, available]))

	var tip := ThemeBuilder.wrap_label(
		"每种灵种保留 20 枚底仓；连淬会按每升一重后的阶位门槛逐重校验，高阶灵种不足时停在可淬灵的最高次数。"
		+ "灵气反哺随灵脉成长：每重 +1% 修为、每 2 重 +1% 丹道双倍（20 重封顶 +20% / +10%），需至少一块已播种灵田生效。",
		ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_SECONDARY)
	var ops := ThemeBuilder.hbox(8)
	ops.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var once := ThemeBuilder.button("淬灵 1 次")
	once.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
	once.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ThemeBuilder.apply_font_size(once, ThemeBuilder.FONT_CAPTION)
	ThemeBuilder.apply_brush_kai(once)
	ThemeBuilder.apply_primary_button(once)
	once.pressed.connect(func() -> void: _do_soil_enrich(1))
	ops.add_child(once)
	var five := ThemeBuilder.button("连淬 5 次")
	five.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
	five.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ThemeBuilder.apply_font_size(five, ThemeBuilder.FONT_CAPTION)
	ThemeBuilder.apply_brush_kai(five)
	ThemeBuilder.apply_secondary_button(five)
	five.pressed.connect(func() -> void: _do_soil_enrich(5))
	ops.add_child(five)
	ThemeBuilder.prepare_touch(ops)

	BottomSheet.show_detail({
		"title": "仙壤淬灵",
		"title_color": ThemeBuilder.COLOR_TEXT_JADE,
		"tags": [{"text": "%d 重 → %d 重" % [level, level + 1],
			"color": ThemeBuilder.COLOR_TEXT_GOLD}],
		"rows": [
			{"custom": card},
			{"custom": tip},
			{"custom": ops},
		],
	})


func _soil_value_row(label_text: String, value_text: String) -> Control:
	var row := ThemeBuilder.hbox(8)
	row.add_child(ThemeBuilder.label(label_text, ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_SECONDARY))
	var value := ThemeBuilder.wrap_label(value_text, ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_PRIMARY)
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value)
	return row


func _do_soil_enrich(times: int) -> void:
	if BottomSheet.instance != null:
		BottomSheet.instance.hide_sheet()
	var result := FarmManager.soil_enrich(times)
	if not bool(result.get("ok", false)):
		EventBus.toast.emit("淬灵未成：灵石或富余灵种不足（每种留存 20 枚底仓）")
		return
	_refresh_soil_label()
	_rebuild()
	EventBus.toast.emit("仙壤淬灵 +%d 重：灵石 -%s，灵种 -%d" % [
		int(result["levels"]),
		GameFormulas.format_num(float(int(result["stones"]))),
		int(result["seeds"])])
	GameState.vibrate_medium()


func _show_help() -> void:
	BottomSheet.show_help("洞府灵田 · 规则", [
		{"text": "万物品阶（涵盖灵材、丹符、法宝、功法与妖兽）", "bbcode": ThemeBuilder.material_grade_legend_bbcode()},
		{"text": "静置生长", "desc": "灵田独立产线，不占用主修 / 分神；神游或关闭游戏也照常成熟。"},
		{"text": "大丰收", "desc": "收割量随采药寻灵重数、灵肥与功法提升；每次收割还可能伴生灵田奇珍。"},
		{"text": "施灵肥", "desc": "灵草阶位最多低于作物 1 阶，近阶灵草方可施肥；每轮最多施 3 次，每次剩余时间 ×0.75（保底 5 秒）、丰产 +20%，满施累计缩时约 58%、丰产 +60%。基础生长时长与伴生奇珍仍需依靠「仙壤淬灵」。"},
		{"text": "灵气反哺", "desc": "每块已播种灵田提供吐纳修为 +3%、丹道双倍 +2%（四块 +12% / +8%）。仙壤灵脉每重再 +1% 修为、每 2 重再 +1% 丹道双倍，20 重封顶 +20% / +10%——四块满种且灵脉二十重时合计修为 +32%、丹道双倍 +18%。"},
		{"text": "仙壤淬灵", "desc": "吞吐富余灵种与灵石淬炼仙壤：每重生长周期 -1.5%、奇珍伴生 +1.5%（各封顶 30%）；同时放大灵气反哺（每重 +1% 修为 / 每 2 重 +1% 丹道双倍，封顶 +20% / +10%）。每种灵种留存 20 枚底仓。"},
	])


func _seed_stock() -> int:
	var total := 0
	for seed_data in DataRegistry.get_all_seeds():
		var dict: Dictionary = seed_data
		total += GameState.get_item_count(String(dict.get("id", "")))
	return total


# ---------------------------------------------------------------- 交互

func _on_harvest_pressed(index: int) -> void:
	var result := FarmManager.harvest(index)
	if bool(result.get("ok", false)):
		GameState.vibrate_light()
		var text := _format_items(result.get("items", {}))
		EventBus.toast.emit("收获 %s" % text)
		_play_farm_harvest(index)
		_spawn_floating(index, "+" + text, ThemeBuilder.COLOR_JADE)


func _on_harvest_all_pressed() -> void:
	var result := FarmManager.harvest_all_plots()
	var harvested := int(result.get("harvested_count", 0))
	if harvested <= 0:
		return
	# 修行纪要 / 资源刷新由 FarmManager 统一处理，这里只做特效与战利品清单
	var items: Dictionary = result.get("items", {})
	if InkVfxLayer.instance != null and is_visible_in_tree() and _plots_box != null:
		InkVfxLayer.instance.play_harvest(_plots_box.get_global_rect().get_center(),
			InkVfxLayer.INK_JADE, maxf(120.0, _plots_box.size.x))
	_spawn_floating(-1, "+" + _format_items(items), ThemeBuilder.COLOR_JADE)
	# 战利品明细：奇珍置顶，其余按品阶从高到低；带图标单行（无「已入行囊」冗余文案）
	var loot_ids: Array = items.keys()
	loot_ids.sort_custom(func(a: Variant, b: Variant) -> bool:
		var ra := 1 if _is_rare_loot(String(a)) else 0
		var rb := 1 if _is_rare_loot(String(b)) else 0
		if ra != rb:
			return ra > rb
		return int(DataRegistry.get_item_grade(String(a)).get("tier", 0)) \
			> int(DataRegistry.get_item_grade(String(b)).get("tier", 0)))
	var rows: Array = []
	rows.append({"custom": ThemeBuilder.spacer(10)})
	var loot_card := ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD_DEEP,
		ThemeBuilder.COLOR_BORDER, 8, 12)
	var loot_box := ThemeBuilder.vbox(2)
	loot_card.add_child(loot_box)
	for item_id in loot_ids:
		loot_box.add_child(_build_loot_row(String(item_id), int(items[item_id])))
	rows.append({"custom": loot_card})
	# 底部闭环：始终展示按钮；可播种时黛玉青主按钮，禁用态深灰墨字浅底。
	var empty := 0
	for i in range(FarmManager.PLOT_COUNT):
		if FarmManager.is_empty(i):
			empty += 1
	var can_plant := empty > 0 and _seed_stock() > 0
	var plant_btn := ThemeBuilder.button("顺手一键播种")
	plant_btn.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
	plant_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ThemeBuilder.apply_font_size(plant_btn, ThemeBuilder.FONT_CARD_TITLE)
	ThemeBuilder.apply_brush_kai(plant_btn)
	plant_btn.disabled = not can_plant
	if can_plant:
		ThemeBuilder.apply_primary_button(plant_btn)
		var normal := ThemeBuilder.panel_box(ThemeBuilder.COLOR_JADE_DARK,
			ThemeBuilder.COLOR_JADE_EDGE, 8, 0, 10)
		normal.border_width_bottom = 2
		plant_btn.add_theme_stylebox_override("normal", normal)
	else:
		ThemeBuilder.apply_secondary_button(plant_btn)
		plant_btn.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT_SECONDARY)
		plant_btn.add_theme_color_override("font_disabled_color", ThemeBuilder.COLOR_TEXT_MUTED)
		plant_btn.tooltip_text = "暂无空地或灵种，无法一键播种"
	plant_btn.pressed.connect(func() -> void:
		if BottomSheet.instance != null:
			BottomSheet.instance.hide_sheet()
		_on_plant_all_pressed())
	rows.insert(0, {"text": "收获地块", "desc": "%d 块" % harvested})
	rows.append({"custom": ThemeBuilder.spacer(10)})
	rows.append({"custom": plant_btn})
	BottomSheet.show_text("灵田丰收", rows)


## 伴生奇珍（聚灵甘露 / 百年朱果）：战利品行前置徽章 + 数量鎏金
func _is_rare_loot(item_id: String) -> bool:
	return item_id == DataRegistry.SPIRIT_DEW or item_id == DataRegistry.CRIMSON_FRUIT


## 单行战利品：图标 + 品阶名 + 奇珍徽章 + 右侧「×数量 (存总数)」同行拆色
func _build_loot_row(item_id: String, count: int) -> Control:
	var rare := _is_rare_loot(item_id)
	var row := ThemeBuilder.hbox(8)
	row.custom_minimum_size = Vector2(0, 40)
	row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := TextureRect.new()
	icon.texture = IconLibrary.get_item_icon(item_id)
	icon.custom_minimum_size = Vector2(28, 28)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var name_lbl := ThemeBuilder.label(DataRegistry.get_item_name(item_id),
		ThemeBuilder.FONT_BODY_SUB)
	name_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ThemeBuilder.apply_item_grade_style(name_lbl, item_id)
	row.add_child(name_lbl)
	if rare:
		row.add_child(ThemeBuilder.create_seal_badge("奇珍", "gold"))
	row.add_child(ThemeBuilder.expander())
	# 双 Label 拆色（RichTextLabel 最小宽≈0 会逐字换行撑爆行高，禁用）
	var count_box := ThemeBuilder.hbox(4)
	count_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	count_box.add_child(ThemeBuilder.label("×%d" % count, ThemeBuilder.FONT_BODY_SUB,
		ThemeBuilder.COLOR_TEXT_JADE))
	count_box.add_child(ThemeBuilder.label("(存%s)" % GameFormulas.format_num(
		float(GameState.get_item_count(item_id))), ThemeBuilder.FONT_BODY_SUB,
		ThemeBuilder.COLOR_TEXT_SECONDARY))
	row.add_child(count_box)
	return row


## 一键播种浮层：智能混播主按钮 + 背包灵种按品阶从高到低逐项播种
func _on_plant_all_pressed() -> void:
	var empty := FarmManager.get_empty_unlocked_plot_indices()
	if empty.is_empty() or _seed_stock() <= 0:
		return
	if AudioManager != null:
		AudioManager.play_tap()
	var sheet := ThemeBuilder.vbox(9)
	sheet.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var smart_card := PanelContainer.new()
	var smart_style := ThemeBuilder.panel_box(ThemeBuilder.COLOR_JADE_PAPER,
		ThemeBuilder.COLOR_JADE_EDGE, 8, 1, 10)
	smart_card.add_theme_stylebox_override("panel", smart_style)
	var smart_row := ThemeBuilder.hbox(8)
	smart_card.add_child(smart_row)
	var smart_col := ThemeBuilder.vbox(2)
	smart_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	smart_row.add_child(smart_col)
	var smart_title := ThemeBuilder.label("优先高阶智能混播", ThemeBuilder.FONT_BODY,
		ThemeBuilder.COLOR_TEXT_TITLE_GOLD)
	ThemeBuilder.apply_font_size(smart_title, ThemeBuilder.FONT_BODY)
	smart_col.add_child(smart_title)
	var smart_desc := ThemeBuilder.wrap_label(
		"按灵种品阶从高到低填满当前空地（%d 块）" % empty.size(),
		ThemeBuilder.FONT_BODY_SUB, ThemeBuilder.COLOR_TEXT_PRIMARY)
	ThemeBuilder.apply_font_size(smart_desc, ThemeBuilder.FONT_BODY_SUB)
	smart_col.add_child(smart_desc)
	var smart_button := ThemeBuilder.button("智能混播", true)
	smart_button.custom_minimum_size = Vector2(96, ThemeBuilder.TOUCH_MIN)
	smart_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	smart_button.pressed.connect(func() -> void:
		BottomSheet.instance.hide_sheet()
		FarmManager.plant_all_plots(""))
	smart_row.add_child(smart_button)
	sheet.add_child(smart_card)

	for sid in FarmManager._seed_tier_order():
		var have := GameState.get_item_count(sid)
		if have <= 0:
			continue
		var seed_data := DataRegistry.get_seed(sid)
		var seed_card := ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD_DEEP,
			ThemeBuilder.COLOR_BORDER, 8, 8)
		seed_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var seed_row := ThemeBuilder.hbox(8)
		seed_card.add_child(seed_row)
		var icon := IconFrame.new()
		icon.setup(IconLibrary.get_item_icon(sid), 36,
			ThemeBuilder.get_material_grade_color(
				int(DataRegistry.get_material_grade(sid).get("tier", 1))), false, 24)
		seed_row.add_child(icon)
		var info_col := ThemeBuilder.vbox(1)
		info_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var seed_name := ThemeBuilder.label("%s ×%d" % [
			String(seed_data.get("name", sid)), have], ThemeBuilder.FONT_BODY,
			ThemeBuilder.get_material_grade_color(
				int(DataRegistry.get_material_grade(sid).get("tier", 1))))
		ThemeBuilder.apply_font_size(seed_name, ThemeBuilder.FONT_BODY)
		seed_name.clip_text = true
		seed_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		info_col.add_child(seed_name)
		var seed_meta := ThemeBuilder.label("成熟 %s · 预计收获 %d~%d" % [
			GameFormulas.format_duration(float(seed_data.get("grow_seconds", 0))),
			int(seed_data.get("min_yield", 1)),
			int(seed_data.get("max_yield", 1))],
			ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_SECONDARY)
		ThemeBuilder.apply_font_size(seed_meta, ThemeBuilder.FONT_CAPTION)
		seed_meta.clip_text = true
		seed_meta.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		info_col.add_child(seed_meta)
		seed_row.add_child(info_col)
		var seed_button := ThemeBuilder.small_button("全播")
		seed_button.custom_minimum_size = Vector2(60, ThemeBuilder.TOUCH_MIN)
		seed_button.pressed.connect(func() -> void:
			BottomSheet.instance.hide_sheet()
			FarmManager.plant_all_plots(sid))
		seed_row.add_child(seed_button)
		sheet.add_child(seed_card)
	ThemeBuilder.prepare_touch(sheet)
	BottomSheet.show_text("一键播种", [{"custom": sheet}])


func _on_fertilize_pressed(index: int) -> void:
	FarmManager.fertilize(index, FarmManager.preferred_fertilizer_herb)
	_play_farm_ripple(index)


## 行囊中有库存的草药种数（决定「选草」按钮是否可用）
func _herb_stock_count() -> int:
	var n := 0
	for herb_id in DataRegistry.get_all_herb_ids():
		if GameState.get_item_count(herb_id) > 0:
			n += 1
	return n


## 「选草化肥」浮层：一行剩余时长 + 一键催熟主卡 + 每种灵草独立小卡。
## 肥力/消耗/次数口径与 FarmManager 完全一致，不在弹窗重复图解规则。
func _show_fertilize_sheet(index: int) -> void:
	if FarmManager.is_empty(index) or FarmManager.is_mature(index):
		return
	if AudioManager != null:
		AudioManager.play_tap()
	var sheet := ThemeBuilder.vbox(9)
	sheet.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var remain_label := ThemeBuilder.label(
		"剩余 %s" % GameFormulas.format_duration(FarmManager.get_remaining(index)),
		ThemeBuilder.FONT_BODY_SUB, ThemeBuilder.COLOR_TEXT_PRIMARY)
	ThemeBuilder.apply_font_size(remain_label, ThemeBuilder.FONT_BODY_SUB)
	sheet.add_child(remain_label)

	var fert_count := FarmManager.get_fertilize_count(index)
	var full := fert_count >= FarmManager.MAX_FERT_PER_GROWTH
	var plan := FarmManager.get_best_fertilizer_herb(
		FarmManager.preferred_fertilizer_herb, index)
	var quick_card := PanelContainer.new()
	quick_card.add_theme_stylebox_override("panel",
		ThemeBuilder.panel_box(ThemeBuilder.COLOR_GOLD_SOFT,
			ThemeBuilder.COLOR_BORDER, 8, 1, 10))
	var quick_row := ThemeBuilder.hbox(8)
	quick_card.add_child(quick_row)
	var quick_col := ThemeBuilder.vbox(2)
	quick_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quick_row.add_child(quick_col)
	var quick_title := ThemeBuilder.label("本轮灵肥 %d/3" % fert_count,
		ThemeBuilder.FONT_BODY, ThemeBuilder.COLOR_TEXT_TITLE_GOLD)
	ThemeBuilder.apply_font_size(quick_title, ThemeBuilder.FONT_BODY)
	quick_col.add_child(quick_title)
	var quick_desc := ThemeBuilder.wrap_label(
		"已施足，等待自然成熟" if full else "自动补施至 3 次上限，仅用近阶灵草",
		ThemeBuilder.FONT_BODY_SUB, ThemeBuilder.COLOR_TEXT_PRIMARY)
	ThemeBuilder.apply_font_size(quick_desc, ThemeBuilder.FONT_BODY_SUB)
	quick_col.add_child(quick_desc)
	var quick_button := ThemeBuilder.button("灵肥已足" if full else "一键催熟")
	quick_button.custom_minimum_size = Vector2(96, ThemeBuilder.TOUCH_MIN)
	quick_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	quick_button.disabled = full or plan.is_empty()
	if not quick_button.disabled:
		quick_button.pressed.connect(func() -> void:
			BottomSheet.instance.hide_sheet()
			FarmManager.batch_fertilize_to_ripe(index))
	quick_row.add_child(quick_button)
	sheet.add_child(quick_card)

	var eligible_count := 0
	for herb_id in DataRegistry.get_all_herb_ids():
		if not FarmManager.is_herb_eligible_for_plot(index, herb_id):
			continue
		var have := GameState.get_item_count(herb_id)
		if have <= 0:
			continue
		eligible_count += 1
		var fertility := FarmManager.get_herb_fertility(herb_id)
		var needed := int(ceilf(GameFormulas.FERTILIZER_BASE_COST / float(fertility)))
		var enough := have >= needed and not full
		var grade: Dictionary = DataRegistry.get_material_grade(herb_id)
		var grade_color := ThemeBuilder.get_material_grade_color(int(grade.get("tier", 1))) \
			if enough else ThemeBuilder.COLOR_TEXT_MUTED
		var herb_card := ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD_DEEP,
			ThemeBuilder.COLOR_BORDER, 8, 8)
		herb_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var herb_row := ThemeBuilder.hbox(8)
		herb_card.add_child(herb_row)
		var icon := IconFrame.new()
		icon.setup(IconLibrary.get_item_icon(herb_id), 36, grade_color, false, 24)
		herb_row.add_child(icon)
		var info_col := ThemeBuilder.vbox(1)
		info_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var herb_name := ThemeBuilder.label("%s ×%d（存 %s）" % [
			DataRegistry.get_item_name(herb_id), needed,
			GameFormulas.format_num(float(have))], ThemeBuilder.FONT_BODY, grade_color)
		ThemeBuilder.apply_font_size(herb_name, ThemeBuilder.FONT_BODY)
		herb_name.clip_text = true
		herb_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		info_col.add_child(herb_name)
		var herb_meta := ThemeBuilder.label("%s · %d 肥力/株 · 够施 %d 次" % [
			String(grade.get("name", "凡材")), fertility, int(have / needed)],
			ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_SECONDARY)
		ThemeBuilder.apply_font_size(herb_meta, ThemeBuilder.FONT_CAPTION)
		herb_meta.clip_text = true
		herb_meta.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		info_col.add_child(herb_meta)
		herb_row.add_child(info_col)
		var herb_button := ThemeBuilder.small_button("施肥")
		herb_button.custom_minimum_size = Vector2(60, ThemeBuilder.TOUCH_MIN)
		herb_button.disabled = not enough
		if enough:
			herb_button.pressed.connect(func() -> void:
				BottomSheet.instance.hide_sheet()
				FarmManager.fertilize_with(index, herb_id))
		herb_row.add_child(herb_button)
		sheet.add_child(herb_card)
	if eligible_count == 0:
		var empty_hint := ThemeBuilder.wrap_label("需近阶灵草：灵草阶位最多低于作物 1 阶。",
			ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_MUTED)
		ThemeBuilder.apply_font_size(empty_hint, ThemeBuilder.FONT_CAPTION)
		sheet.add_child(empty_hint)
	ThemeBuilder.prepare_touch(sheet)
	BottomSheet.show_text("选草化肥", [{"custom": sheet}])


func _plant_seed(index: int, seed_id: String) -> void:
	FarmManager.plant(index, seed_id)
	_play_farm_ripple(index)


func _play_farm_ripple(index: int) -> void:
	if not is_visible_in_tree() or InkVfxLayer.instance == null:
		return
	if index >= 0 and index < _plot_cards.size() and _plot_cards[index] != null:
		InkVfxLayer.instance.play_ripple(
			_plot_cards[index].get_global_rect().get_center(), InkVfxLayer.INK_JADE_LIGHT)


func _play_farm_harvest(index: int) -> void:
	if not is_visible_in_tree() or InkVfxLayer.instance == null:
		return
	if index >= 0 and index < _plot_cards.size() and _plot_cards[index] != null:
		var rect: Rect2 = _plot_cards[index].get_global_rect()
		InkVfxLayer.instance.play_harvest(rect.get_center(), InkVfxLayer.INK_JADE,
			maxf(100.0, rect.size.x))


func _open_seed_picker(index: int) -> void:
	var rows: Array = []
	for seed_data in DataRegistry.get_all_seeds():
		var dict: Dictionary = seed_data
		var seed_id := String(dict.get("id", ""))
		var owned := GameState.get_item_count(seed_id)
		if owned <= 0:
			continue
		var grow := int(dict.get("grow_seconds", 600.0))
		var crop_id := String(dict.get("crop_id", ""))
		rows.append({
			"text": "%s ×%s" % [String(dict.get("name", seed_id)),
				GameFormulas.format_num(float(owned))],
			"desc": "%s成熟 → %s×%d~%d" % [
				GameFormulas.format_duration(float(grow)),
				DataRegistry.get_item_name(crop_id),
				int(dict.get("min_yield", 1)),
				int(dict.get("max_yield", 1)),
			],
			"callback": Callable(self, "_plant_seed").bind(index, seed_id),
		})
	if rows.is_empty():
		rows.append({
			"text": "储物袋中没有灵种",
			"desc": "可在仙坊阁购置灵种，采摘时亦有概率副产。",
		})
		rows.append({
			"text": "前往仙坊阁 ▸",
			"callback": Callable(self, "_go_shop"),
		})
	var plot_name := PLOT_NAMES[index] if index < PLOT_NAMES.size() else str(index + 1)
	rows.insert(0, {"text": "播种地块", "desc": "%s号灵田" % plot_name})
	BottomSheet.show_text("选择灵种", rows)


func _go_shop() -> void:
	# 直落「灵种杂货」页签，省得玩家在法器页里翻找灵种
	EventBus.navigate_to_source.emit({"type": "shop", "tab": "seed"})


func _format_items(items: Dictionary) -> String:
	var parts: Array[String] = []
	for item_id in items.keys():
		parts.append("%s ×%d" % [DataRegistry.get_item_name(String(item_id)), int(items[item_id])])
	return " ".join(parts)


func _spawn_floating(index: int, text_value: String, color: Color) -> void:
	if InkVfxLayer.instance == null or not is_visible_in_tree():
		return
	var origin := get_global_rect().position + Vector2(24.0, 80.0)
	if index >= 0 and index < _plot_cards.size():
		var card: Control = _plot_cards[index]
		if card != null:
			origin = card.get_global_rect().position + Vector2(24.0, 24.0)
	InkVfxLayer.instance.play_float(origin, text_value, color, 14,
		color == ThemeBuilder.COLOR_AMBER)


func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()






