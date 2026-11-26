extends Control

## 道身：只读汇总 GameState / DataRegistry 的真实属性与进度，不新增存档字段。
## 不声明 class_name：该面板由 MainShell 以 preload 加载，确保 PCK 单发也能生效。

const PORTRAIT_PATH: String = "res://assets/images/dao_portrait.png"
const PORTRAIT_SIZE: int = 124

const SKILL_ORDER: Array = [
	{"id": "herbalism", "name": "采药寻灵"},
	{"id": "woodcutting", "name": "伐木取材"},
	{"id": "mining", "name": "开矿掘脉"},
	{"id": "alchemy", "name": "丹道炼制"},
	{"id": "forging", "name": "器道锻造"},
	{"id": "talisman", "name": "符箓绘制"},
	{"id": "cultivation", "name": "吐纳筑基"},
	{"id": "combat", "name": "秘境历练"},
]

var _scroll: ScrollContainer
var _content: VBoxContainer
var _dirty: bool = true
var _rebuild_queued: bool = false


func _ready() -> void:
	_build_shell()
	_connect_refresh_signals()
	visibility_changed.connect(_on_visibility_changed)
	ThemeBuilder.prepare_touch(self)
	_queue_refresh()


func _build_shell() -> void:
	_scroll = ThemeBuilder.scroll_container()
	_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_scroll)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	_scroll.add_child(margin)

	_content = ThemeBuilder.vbox(10)
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(_content)


func _connect_refresh_signals() -> void:
	_connect_if(EventBus, "stats_changed", Callable(self, "_queue_refresh"))
	_connect_if(EventBus, "equipment_changed", Callable(self, "_queue_refresh"))
	_connect_if(EventBus, "technique_changed", Callable(self, "_queue_refresh"))
	_connect_if(EventBus, "game_loaded", Callable(self, "_queue_refresh"))
	_connect_if(EventBus, "realm_changed", Callable(self, "_on_realm_changed"))
	_connect_if(EventBus, "cultivation_changed", Callable(self, "_on_cultivation_changed"))
	_connect_if(EventBus, "skill_xp_changed", Callable(self, "_on_skill_xp_changed"))


func _connect_if(source: Object, signal_name: String, callback: Callable) -> void:
	if source == null or not source.has_signal(signal_name):
		return
	if not source.is_connected(signal_name, callback):
		source.connect(signal_name, callback)


func _on_realm_changed(_realm_id: String, _realm_name: String) -> void:
	_queue_refresh()


func _on_cultivation_changed(_current: float, _required: float, _full: bool) -> void:
	_queue_refresh()


func _on_skill_xp_changed(_skill_id: String, _xp: float, _level: int) -> void:
	_queue_refresh()


func _on_visibility_changed() -> void:
	if visible and _dirty:
		_queue_refresh()


func _queue_refresh() -> void:
	_dirty = true
	if not visible or not is_inside_tree() or _rebuild_queued:
		return
	_rebuild_queued = true
	call_deferred("_rebuild")


func _rebuild() -> void:
	_rebuild_queued = false
	if not is_inside_tree() or not visible:
		return
	_dirty = false
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()

	_build_overview_card()
	_build_equipment_card()
	_build_attribute_card()
	_build_technique_card()
	_build_skill_card()
	ThemeBuilder.prepare_touch(self)


func _new_card() -> VBoxContainer:
	var card := ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD,
		ThemeBuilder.COLOR_BORDER, 10, 10)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_child(card)
	var box := ThemeBuilder.vbox(8)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(box)
	return box


func _build_overview_card() -> void:
	var box := _new_card()
	var head := ThemeBuilder.hbox(8)
	box.add_child(head)

	var frame := IconFrame.new()
	frame.setup(IconLibrary.get_ui_icon("dao_body"), 48, ThemeBuilder.COLOR_JADE)
	head.add_child(frame)

	var info := ThemeBuilder.vbox(3)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(info)

	var name_row := ThemeBuilder.hbox(5)
	info.add_child(name_row)
	var name_label := ThemeBuilder.card_title_label(_player_name(),
		ThemeBuilder.FONT_CARD_TITLE, ThemeBuilder.COLOR_TEXT_TITLE)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_row.add_child(name_label)
	var help := ThemeBuilder.create_help_button(Callable(self, "_show_help"))
	help.custom_minimum_size = Vector2(44, 44)
	help.size_flags_horizontal = Control.SIZE_SHRINK_END
	help.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	name_row.add_child(help)

	var badge_flow := HFlowContainer.new()
	badge_flow.add_theme_constant_override("h_separation", 6)
	badge_flow.add_theme_constant_override("v_separation", 4)
	badge_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(badge_flow)
	badge_flow.add_child(ThemeBuilder.chip(_realm_stage_text(), ThemeBuilder.COLOR_AMBER))
	var root_badge := ThemeBuilder.chip(SpiritRootSystem.get_badge_text(), ThemeBuilder.COLOR_JADE)
	root_badge.tooltip_text = "前往灵根洗髓"
	ThemeBuilder.make_card_tappable(root_badge, Callable(self, "_open_page").bind("spirit_root"))
	badge_flow.add_child(root_badge)

	var play_label := ThemeBuilder.label("修行 %s" % _play_time_text(),
		ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_SECONDARY)
	play_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	play_label.clip_text = true
	play_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	info.add_child(play_label)

	var cultivation_row := ThemeBuilder.hbox(6)
	box.add_child(cultivation_row)
	cultivation_row.add_child(ThemeBuilder.label("修为", ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_SECONDARY))
	cultivation_row.add_child(ThemeBuilder.expander())
	cultivation_row.add_child(ThemeBuilder.label(_cultivation_text(),
		ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_PRIMARY))

	var bar := ThemeBuilder.progress_bar(
		ThemeBuilder.COLOR_CINNABAR if GameState.is_cultivation_locked() else ThemeBuilder.COLOR_JADE,
		7.0)
	bar.value = _cultivation_ratio()
	box.add_child(bar)

	var status_row := ThemeBuilder.hbox(6)
	box.add_child(status_row)
	status_row.add_child(ThemeBuilder.label(_dao_heart_text(), ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_JADE))
	status_row.add_child(ThemeBuilder.expander())
	var maxed_realm := GameState.get_realm_index() >= DataRegistry.realm_order.size() - 1
	var has_next_tribulation := GameState.get_realm_requirement() > 0.0 and not maxed_realm
	var trib_text := "前往渡劫" if has_next_tribulation else "已证大道"
	var trib_button := ThemeBuilder.small_button(trib_text)
	var trib_ready := GameState.is_cultivation_locked() and has_next_tribulation
	if has_next_tribulation:
		if trib_ready:
			ThemeBuilder.apply_primary_button(trib_button)
		else:
			ThemeBuilder.apply_secondary_button(trib_button)
	else:
		ThemeBuilder.apply_secondary_button(trib_button)
	trib_button.disabled = not has_next_tribulation
	trib_button.tooltip_text = "" if has_next_tribulation else "大道圆满，暂无下一重天劫"
	ThemeBuilder.apply_font_size(trib_button, ThemeBuilder.FONT_CAPTION)
	trib_button.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
	trib_button.pressed.connect(Callable(self, "_open_page").bind("tribulation"))
	status_row.add_child(trib_button)

	var tea_info := FishingTeaSystem.get_active_tea_info()
	if not tea_info.is_empty():
		var tea_row := ThemeBuilder.hbox(6)
		box.add_child(tea_row)
		tea_row.add_child(ThemeBuilder.icon_rect(
			IconLibrary.get_ui_icon("tea_pot"), 16))
		var tea_label := ThemeBuilder.label(str(tea_info.get("text", "")),
			ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_JADE)
		tea_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tea_label.clip_text = true
		tea_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		tea_row.add_child(tea_label)


func _build_attribute_card() -> void:
	var box := _new_card()
	box.add_child(ThemeBuilder.card_title_label("道身属性",
		ThemeBuilder.FONT_CARD_TITLE, ThemeBuilder.COLOR_TEXT_TITLE_GOLD))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(grid)

	var stats: Dictionary = GameState.get_player_stats()
	var max_hp: int = int(stats.get("max_hp", GameState.get_max_hp()))
	var current_hp: int = clampi(GameState.current_hp, 0, max_hp)
	var crit := GameState.get_crit_chance()
	var dodge := GameState.get_dodge()
	var raw_accuracy := float(stats.get("raw_accuracy", GameState.get_raw_accuracy()))
	var interval := float(stats.get("interval", 0.0))
	var tower_floor: int = maxi(0, GameState.tower_highest_floor)
	var tower_text := "未登塔" if tower_floor <= 0 else "%d 层" % tower_floor

	_add_stat_cell(grid, "气血", _hp_text(current_hp, max_hp))
	_add_stat_cell(grid, "攻击力", _compact_amount(float(stats.get("attack", 0))))
	_add_stat_cell(grid, "防御力", _compact_amount(float(stats.get("defense", 0))))
	_add_stat_cell(grid, "命中率", _rate_text(raw_accuracy))
	_add_stat_cell(grid, "闪避率", _rate_text(dodge))
	_add_stat_cell(grid, "会心率", _rate_text(crit))
	_add_stat_cell(grid, "攻击间隔", "%.2f 秒" % interval)
	_add_stat_cell(grid, "灵石持有", _compact_amount(float(
		GameState.get_item_count(DataRegistry.SPIRIT_STONE))))
	_add_stat_cell(grid, "仙盟贡献", _compact_amount(float(GameState.alliance_points)))
	_add_stat_cell(grid, "镇魔塔", tower_text)


func _add_stat_cell(grid: GridContainer, title: String, value: String) -> void:
	var cell := ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD_DEEP,
		ThemeBuilder.COLOR_BORDER, 8, 7)
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.custom_minimum_size = Vector2(0, 44)
	grid.add_child(cell)
	var row := ThemeBuilder.hbox(6)
	cell.add_child(row)
	var title_label := ThemeBuilder.label(title, ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_SECONDARY)
	ThemeBuilder.apply_font_size(title_label, ThemeBuilder.FONT_CAPTION)
	title_label.custom_minimum_size = Vector2(56, 0)
	title_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	row.add_child(title_label)
	var value_label := ThemeBuilder.label(value, ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_JADE)
	ThemeBuilder.apply_font_size(value_label, ThemeBuilder.FONT_CAPTION)
	value_label.custom_minimum_size = Vector2(0, 0)
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.clip_text = false
	value_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	row.add_child(value_label)


## 属性大数统一保留量级单位，避免窄胶囊把「万 / 亿」裁掉
func _compact_amount(value: float) -> String:
	var abs_value := absf(value)
	if abs_value >= 100000000.0:
		return _amount_with_unit(value / 100000000.0, "亿")
	if abs_value >= 10000.0:
		return _amount_with_unit(value / 10000.0, "万")
	return GameFormulas.format_num(value)


func _amount_with_unit(value: float, unit: String) -> String:
	var text := "%.1f" % value
	if text.ends_with(".0"):
		text = text.substr(0, text.length() - 2)
	return text + unit


## 高气血用万位简写，避免 2 列属性格被长小数撑出省略号
func _hp_text(current_hp: int, max_hp: int) -> String:
	if max_hp >= 100000:
		return "%d万/%d万" % [
			int(round(float(current_hp) / 10000.0)),
			int(round(float(max_hp) / 10000.0))]
	if max_hp >= 10000:
		return "%s/%s" % [
			_amount_with_unit(float(current_hp) / 10000.0, "万"),
			_amount_with_unit(float(max_hp) / 10000.0, "万")]
	return "%s/%s" % [
		GameFormulas.format_num(float(current_hp)),
		GameFormulas.format_num(float(max_hp))]


func _rate_text(value: float) -> String:
	if value > 1.0:
		return "%.0f%%+" % (value * 100.0)
	return "%.0f%%" % (value * 100.0)


func _build_equipment_card() -> void:
	var box := _new_card()
	box.add_child(ThemeBuilder.card_title_label("随身法宝",
		ThemeBuilder.FONT_CARD_TITLE, ThemeBuilder.COLOR_TEXT_TITLE_GOLD))
	var row := ThemeBuilder.hbox(8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(row)

	row.add_child(_build_equipment_slot("weapon", "主兵", "未佩兵刃", "slot_weapon"))

	var center := CenterContainer.new()
	center.custom_minimum_size = Vector2(PORTRAIT_SIZE, PORTRAIT_SIZE)
	center.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	center.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var portrait := TextureRect.new()
	portrait.texture = _portrait_texture()
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.custom_minimum_size = Vector2(PORTRAIT_SIZE, PORTRAIT_SIZE)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(portrait)
	row.add_child(center)

	row.add_child(_build_equipment_slot("armor", "护身", "未着法衣", "slot_armor"))
	box.add_child(_build_natal_slot_card())


func _build_equipment_slot(slot: String, slot_name: String, empty_text: String,
		empty_icon: String) -> PanelContainer:
	var card := ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD_DEEP,
		ThemeBuilder.COLOR_BORDER, 8, 8)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_FILL
	card.custom_minimum_size = Vector2(0, PORTRAIT_SIZE)

	var center := VBoxContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 4)
	card.add_child(center)

	var equipped: Dictionary = GameState.get_equipped(slot)
	var item_id := str(equipped.get("id", ""))
	var item: ItemData = DataRegistry.get_item(item_id)
	var quality := clampi(int(equipped.get("quality", 0)), 0, 2)
	var temper_level := GameState.get_temper_level(slot)
	var texture: Texture2D
	var accent := ThemeBuilder.COLOR_JADE
	var name_text := empty_text
	var detail_text := "前往行囊"
	if item != null:
		texture = IconLibrary.get_item_icon(item.id, quality)
		accent = _quality_color(quality)
		name_text = item.display_name
		detail_text = GameState.get_quality_name(quality)
		if temper_level >= GameState.MAX_TEMPER_LEVEL:
			detail_text += " · 祭炼 %d / %d 重 · 已圆满" % [
				temper_level, GameState.MAX_TEMPER_LEVEL]
		elif temper_level > 0:
			detail_text += " · 祭炼 %d / %d 重" % [
				temper_level, GameState.MAX_TEMPER_LEVEL]
		card.tooltip_text = item.get_stat_summary()
	else:
		texture = IconLibrary.get_ui_icon(empty_icon)

	var frame := IconFrame.new()
	frame.setup(texture, 36, accent, false, 28)
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	center.add_child(frame)
	center.add_child(_centered_caption(slot_name, ThemeBuilder.COLOR_TEXT_DIM, ""))
	center.add_child(_centered_caption(name_text, accent, name_text))
	center.add_child(_centered_caption(detail_text, ThemeBuilder.COLOR_TEXT_SECONDARY, detail_text))
	if item != null:
		ThemeBuilder.make_card_tappable(card,
			Callable(self, "_open_equipment_sheet").bind(slot))
	else:
		ThemeBuilder.make_card_tappable(card,
			Callable(self, "_open_inventory_equipment"))
	return card


func _centered_caption(text_value: String, color: Color, tooltip: String) -> Label:
	var label := ThemeBuilder.label(text_value, ThemeBuilder.FONT_CAPTION, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if tooltip != "":
		label.tooltip_text = tooltip
	return label


func _build_natal_slot_card() -> PanelContainer:
	var card := ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD_DEEP,
		ThemeBuilder.COLOR_BORDER, 8, 8)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 56)
	var unlocked := NatalArtifactSystem.is_unlocked()
	if unlocked:
		ThemeBuilder.make_card_tappable(card,
			Callable(self, "_open_page").bind("natal_artifact"))
	var row := ThemeBuilder.hbox(8)
	card.add_child(row)
	var state := NatalArtifactSystem.get_state()
	var embryo_id := str(state.get("embryo_id", ""))
	var icon_key := "ui_slot_natal"
	if embryo_id != "":
		icon_key = NatalArtifactSystem.embryo_icon(embryo_id)
	var frame := IconFrame.new()
	frame.setup(IconLibrary.get_icon(icon_key), 36,
		ThemeBuilder.COLOR_JADE if unlocked else ThemeBuilder.COLOR_TEXT_DIM, false, 28)
	row.add_child(frame)
	row.add_child(ThemeBuilder.label("本命法宝 · 丹田温养",
		ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_PRIMARY))
	row.add_child(ThemeBuilder.expander())
	if not unlocked:
		row.add_child(ThemeBuilder.chip("需元婴初期开启", ThemeBuilder.COLOR_TEXT_MUTED))
	elif embryo_id == "":
		row.add_child(ThemeBuilder.chip("尚未凝练器胚，轻触择一", ThemeBuilder.COLOR_AMBER))
	else:
		row.add_child(ThemeBuilder.chip("%s · %d 重" % [
			NatalArtifactSystem.tier_name(int(state.get("level", 1))),
			int(state.get("level", 1))], ThemeBuilder.COLOR_JADE))
	return card


func _build_technique_card() -> void:
	var box := _new_card()
	var head := ThemeBuilder.hbox(6)
	box.add_child(head)
	head.add_child(ThemeBuilder.card_title_label("已运功法",
		ThemeBuilder.FONT_CARD_TITLE, ThemeBuilder.COLOR_TEXT_TITLE_GOLD))
	head.add_child(ThemeBuilder.expander())
	var jump := ThemeBuilder.small_button("藏经阁 ▸")
	jump.pressed.connect(Callable(self, "_open_page").bind("technique"))
	head.add_child(jump)

	if GameState.get_realm_index() < 5:
		box.add_child(ThemeBuilder.label("需炼气六层开启藏经阁",
			ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_MUTED))
		return

	var technique_ids: Array = GameState.equipped_techniques
	var any_equipped := false
	for value in technique_ids:
		var technique_id := str(value)
		if technique_id == "":
			continue
		var tech: TechniqueData = DataRegistry.get_technique(technique_id)
		if tech == null:
			continue
		any_equipped = true
		var row := ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD_DEEP,
			ThemeBuilder.COLOR_BORDER, 8, 7)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_child(row)
		var line := ThemeBuilder.hbox(6)
		row.add_child(line)
		var name_label := ThemeBuilder.label("%s · 第 %d 重" % [
			tech.name, GameState.get_technique_level(tech.id)],
			ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_JADE)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.clip_text = true
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		line.add_child(name_label)
		var desc := tech.description if tech.description != "" else "暂无记载"
		box.add_child(ThemeBuilder.wrap_label(desc, ThemeBuilder.FONT_CAPTION,
			ThemeBuilder.COLOR_TEXT_SECONDARY))
	if not any_equipped:
		box.add_child(ThemeBuilder.label("暂未运转功法，可往藏经阁参悟",
			ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_MUTED))


func _build_skill_card() -> void:
	var box := _new_card()
	box.add_child(ThemeBuilder.card_title_label("百艺与历练",
		ThemeBuilder.FONT_CARD_TITLE, ThemeBuilder.COLOR_TEXT_TITLE_GOLD))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(grid)
	var cap := GameState.get_skill_level_cap()
	for entry in SKILL_ORDER:
		var skill_id := String((entry as Dictionary)["id"])
		var display_name := String((entry as Dictionary)["name"])
		var level := GameState.get_skill_level(skill_id)
		var full := level >= cap
		grid.add_child(_build_skill_cell(display_name,
			"%d / %d 重" % [level, cap], skill_id, full))


func _build_skill_cell(title: String, value: String, skill_id: String,
		full: bool) -> PanelContainer:
	var card := ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD_DEEP,
		ThemeBuilder.COLOR_BORDER, 8, 7)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 44)
	ThemeBuilder.make_card_tappable(card,
		Callable(self, "_open_skill").bind(skill_id))
	var row := ThemeBuilder.hbox(6)
	card.add_child(row)
	var title_label := ThemeBuilder.label(title, ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_PRIMARY)
	row.add_child(title_label)
	row.add_child(ThemeBuilder.expander())
	var value_label := ThemeBuilder.label(value, ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_JADE if full else ThemeBuilder.COLOR_TEXT_SECONDARY)
	value_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	row.add_child(value_label)
	return card


func _open_page(page: String) -> void:
	EventBus.navigate_to.emit(page)


func _open_inventory_equipment() -> void:
	if BottomSheet.instance != null and is_instance_valid(BottomSheet.instance):
		BottomSheet.instance.hide_sheet()
	EventBus.navigate_to_source.emit({
		"type": "inventory_equipment",
		"tab": "equipment",
	})


func _open_equipment_sheet(slot: String) -> void:
	var equipped: Dictionary = GameState.get_equipped(slot)
	var item_id := str(equipped.get("id", ""))
	var item := DataRegistry.get_item(item_id)
	if item == null:
		_open_inventory_equipment()
		return
	if AudioManager != null:
		AudioManager.play_tap()
	var quality := clampi(int(equipped.get("quality", 0)), 0, 2)
	var temper_level := GameState.get_temper_level(slot)
	var title_color := _quality_color(quality)
	var temper_label := "尚未祭炼"
	if temper_level >= GameState.MAX_TEMPER_LEVEL:
		temper_label = "祭炼 %d / %d 重 · 已圆满" % [
			temper_level, GameState.MAX_TEMPER_LEVEL]
	elif temper_level > 0:
		temper_label = "祭炼 %d / %d 重" % [temper_level, GameState.MAX_TEMPER_LEVEL]
	var tags: Array = [
		{"text": GameState.get_quality_name(quality), "color": title_color},
		{"text": temper_label,
			"color": ThemeBuilder.COLOR_TEXT_GOLD if temper_level > 0
				else ThemeBuilder.COLOR_TEXT_SECONDARY},
	]
	var rows: Array = _equipment_effect_rows(item, quality, slot, temper_level)
	rows.append({"custom": _equipment_action_row(slot)})
	BottomSheet.show_detail({
		"title": item.display_name,
		"title_color": title_color,
		"icon": IconLibrary.get_item_icon(item.id, quality),
		"icon_accent": title_color,
		"tags": tags,
		"rows": rows,
	})


func _equipment_action_row(slot: String) -> Control:
	var row := ThemeBuilder.hbox(8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
	var temper_full := GameState.get_temper_level(slot) >= GameState.MAX_TEMPER_LEVEL
	var can_temper := GameState.can_temper_slot(slot)
	var temper_text := "祭炼已圆满" if temper_full else (
		"祭炼" if can_temper else "需筑基中期")
	var temper_button := ThemeBuilder.small_button(temper_text)
	temper_button.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
	temper_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	temper_button.disabled = not can_temper
	if temper_full:
		temper_button.tooltip_text = "已臻极境，无需再耗灵石与灵材"
	elif not can_temper:
		temper_button.tooltip_text = "筑基中期开启祭炼"
	else:
		temper_button.tooltip_text = "需 %d 阶及以上灵材/丹药" % [
			GameState.get_temper_material_min_tier(slot)]
	ThemeBuilder.apply_font_size(temper_button, ThemeBuilder.FONT_CAPTION)
	ThemeBuilder.tighten_button_padding(temper_button, 6.0)
	if can_temper:
		ThemeBuilder.apply_primary_button(temper_button)
	else:
		ThemeBuilder.apply_secondary_button(temper_button)
	temper_button.pressed.connect(func() -> void: _do_temper(slot))
	row.add_child(temper_button)

	var unequip_button := ThemeBuilder.small_button("卸下")
	unequip_button.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
	unequip_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ThemeBuilder.apply_font_size(unequip_button, ThemeBuilder.FONT_CAPTION)
	ThemeBuilder.tighten_button_padding(unequip_button, 6.0)
	unequip_button.pressed.connect(func() -> void:
		if BottomSheet.instance != null and is_instance_valid(BottomSheet.instance):
			BottomSheet.instance.hide_sheet()
		GameState.unequip_slot(slot)
		_queue_refresh())
	row.add_child(unequip_button)

	var change_button := ThemeBuilder.small_button("前往行囊换装")
	change_button.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
	change_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ThemeBuilder.apply_font_size(change_button, ThemeBuilder.FONT_CAPTION)
	ThemeBuilder.tighten_button_padding(change_button, 6.0)
	change_button.pressed.connect(Callable(self, "_open_inventory_equipment"))
	row.add_child(change_button)
	ThemeBuilder.prepare_touch(row)
	return row


func _equipment_effect_rows(item: ItemData, quality: int, slot: String,
		temper_level: int) -> Array:
	var mult := GameState.get_quality_multiplier(quality)
	var rows: Array = []
	if item.attack_bonus != 0:
		rows.append({"label": "攻击", "value": "%d" % int(round(
			float(item.attack_bonus) * mult)), "color": ThemeBuilder.COLOR_TEXT_JADE})
	if item.defense_bonus != 0:
		rows.append({"label": "防御", "value": "%d" % int(round(
			float(item.defense_bonus) * mult)), "color": ThemeBuilder.COLOR_TEXT_JADE})
	if item.max_hp_bonus != 0:
		rows.append({"label": "气血", "value": "%d" % int(round(
			float(item.max_hp_bonus) * mult)), "color": ThemeBuilder.COLOR_TEXT_JADE})
	if item.accuracy_bonus != 0:
		rows.append({"label": "命中", "value": "%d" % int(round(
			float(item.accuracy_bonus) * mult)), "color": ThemeBuilder.COLOR_TEXT_JADE})
	if item.crit_bonus != 0.0:
		rows.append({"label": "会心", "value": "%d%%" % int(round(item.crit_bonus * mult)),
			"color": ThemeBuilder.COLOR_TEXT_JADE})
	if item.dodge_bonus != 0.0:
		rows.append({"label": "闪避", "value": "%d%%" % int(round(item.dodge_bonus * mult)),
			"color": ThemeBuilder.COLOR_TEXT_JADE})
	if temper_level > 0:
		var temper_text := ""
		if slot == "weapon":
			temper_text = "攻击 +%d · 会心 +%.2f%% · 全百艺双倍 +%.1f%%" % [
				GameState.get_temper_attack_bonus(),
				GameState.get_temper_crit_chance() * 100.0,
				GameState.get_temper_double_bonus() * 100.0]
		else:
			temper_text = "气血 +%d · 防御 +%d · 全百艺耗时 -%.1f%%" % [
				GameState.get_temper_hp_bonus(),
				GameState.get_temper_defense_bonus(),
				GameState.get_temper_interval_reduction() * 100.0]
		rows.append({"label": "祭炼加成", "value": temper_text,
			"color": ThemeBuilder.COLOR_TEXT_GOLD})
		rows.append({"label": "祭炼百分比", "value": "+%.1f%%" % (
			GameState.get_temper_pct(slot) * 100.0), "color": ThemeBuilder.COLOR_TEXT_GOLD})
	return rows


func _do_temper(slot: String) -> void:
	if BottomSheet.instance != null and is_instance_valid(BottomSheet.instance):
		BottomSheet.instance.hide_sheet()
	if not GameState.can_temper_equipment():
		EventBus.toast.emit("需筑基中期")
		return
	if GameState.get_temper_level(slot) >= GameState.MAX_TEMPER_LEVEL:
		EventBus.toast.emit("已至祭炼圆满之境")
		return
	var result := GameState.temper_equipment(slot, 1)
	if not bool(result.get("ok", false)):
		var reason := String(result.get("reason", ""))
		if reason == "已至祭炼圆满之境":
			EventBus.toast.emit(reason)
		else:
			EventBus.toast.emit("祭炼未成：灵石或 %d 阶以上灵材不足" % [
				GameState.get_temper_material_min_tier(slot)])
		return
	_queue_refresh()
	EventBus.toast.emit("祭炼至 %d 重（+%d 重）：消耗 灵石 %s、%s ×%d" % [
		GameState.get_temper_level(slot),
		int(result["levels"]),
		GameFormulas.format_num(float(int(result["stones"]))),
		DataRegistry.get_item_name(String(result["mat_id"])),
		int(result["mat_amount"])])
	GameState.vibrate_medium()


func _open_skill(skill_id: String) -> void:
	_open_page(skill_id)


func _show_help() -> void:
	BottomSheet.show_help("道身 · 说明", [
		{"text": "道身属性", "desc": "气血、攻防、命中、会心、闪避与攻击间隔均取自当前修行真实汇总。"},
		{"text": "随身法宝", "desc": "主兵与护身取自行囊穿戴；轻触法宝格可前往行囊换装或祭炼。"},
		{"text": "本命法宝", "desc": "丹田温养槽位预留给元婴初期开启的本命法宝系统。"},
		{"text": "参悟功法", "desc": "已运功法与参悟重数来自藏经阁，效果说明取自功法原文。"},
		{"text": "百艺与历练", "desc": "七门百艺与秘境历练当前重数受境界上限约束，轻触条目可直达对应页面。"},
	])


func _portrait_texture() -> Texture2D:
	if ResourceLoader.exists(PORTRAIT_PATH):
		var loaded: Resource = ResourceLoader.load(PORTRAIT_PATH, "Texture2D",
			ResourceLoader.CACHE_MODE_REPLACE)
		if loaded is Texture2D:
			return loaded as Texture2D
	return IconLibrary.get_ui_icon("dao_body")


func _player_name() -> String:
	if CloudSaveManager == null:
		return "闭关散修"
	var has_identity := false
	if CloudSaveManager.has_method("has_saved_identity"):
		has_identity = bool(CloudSaveManager.call("has_saved_identity"))
	elif CloudSaveManager.has_method("has_token"):
		has_identity = bool(CloudSaveManager.call("has_token"))
	if not has_identity:
		return "闭关散修"
	var auth_value: Variant = CloudSaveManager.get("auth")
	if typeof(auth_value) != TYPE_DICTIONARY:
		return "闭关散修"
	var username := str((auth_value as Dictionary).get("username", "")).strip_edges()
	return username if username != "" else "闭关散修"


func _realm_stage_text() -> String:
	var realm: RealmData = GameState.get_realm()
	if realm == null:
		return "炼气 · 一层"
	var full_name := realm.display_name
	if full_name.length() <= 2:
		return full_name
	return "%s · %s" % [full_name.substr(0, 2), full_name.substr(2)]


func _play_time_text() -> String:
	var value: Variant = GameState.stats.get("play_seconds", 0.0)
	return GameFormulas.format_duration(maxf(0.0, float(value)))


func _cultivation_ratio() -> float:
	var requirement := GameState.get_realm_requirement()
	if requirement <= 0.0:
		return 1.0
	return clampf(GameState.cultivation_xp / requirement, 0.0, 1.0)


func _cultivation_text() -> String:
	var requirement := GameState.get_realm_requirement()
	if requirement <= 0.0:
		return "大道圆满"
	return "%s / %s" % [
		GameFormulas.format_num(GameState.cultivation_xp),
		GameFormulas.format_num(requirement)]


func _dao_heart_text() -> String:
	return "道心 %d / %d 层" % [
		GameState.get_dao_heart_stacks(), GameState.DAO_HEART_MAX]


func _quality_color(quality: int) -> Color:
	match clampi(quality, 0, 2):
		1:
			return ThemeBuilder.COLOR_EMERALD
		2:
			return ThemeBuilder.COLOR_TEXT_GOLD
		_:
			return ThemeBuilder.COLOR_TEXT_PRIMARY
