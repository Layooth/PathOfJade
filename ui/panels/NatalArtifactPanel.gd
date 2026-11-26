extends Control

## 本命法宝专用界面：元婴初期解锁，三选一器胚、融材温养、器纹洗练。
## 不声明 class_name：由 MainShell 以 preload 加载，确保 PCK 单发也能生效。

var _scroll: ScrollContainer
var _content: VBoxContainer
var _dirty: bool = true
var _rebuild_queued: bool = false


func _ready() -> void:
	_build_shell()
	_connect_signals()
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


func _connect_signals() -> void:
	_connect_if(EventBus, "stats_changed", Callable(self, "_queue_refresh"))
	_connect_if(EventBus, "inventory_changed", Callable(self, "_queue_refresh"))
	_connect_if(EventBus, "equipment_changed", Callable(self, "_queue_refresh"))
	_connect_if(EventBus, "realm_changed", Callable(self, "_queue_refresh"))
	_connect_if(EventBus, "game_loaded", Callable(self, "_queue_refresh"))


func _connect_if(source: Object, signal_name: String, callback: Callable) -> void:
	if source == null or not source.has_signal(signal_name):
		return
	if not source.is_connected(signal_name, callback):
		source.connect(signal_name, callback)


func _queue_refresh() -> void:
	_dirty = true
	if not visible or not is_inside_tree() or _rebuild_queued:
		return
	_rebuild_queued = true
	call_deferred("_rebuild")


func _on_visibility_changed() -> void:
	if visible and _dirty:
		_queue_refresh()


func _rebuild() -> void:
	_rebuild_queued = false
	if not is_inside_tree() or not visible:
		return
	_dirty = false
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()

	if not NatalArtifactSystem.is_unlocked():
		_build_locked_card()
	else:
		var state := NatalArtifactSystem.get_state()
		if str(state.get("embryo_id", "")) == "":
			_build_embryo_choice()
		else:
			_build_overview_card(state)
			_build_summary_card()
			_build_feed_card(state)
			_build_engraving_card(state)
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


func _build_locked_card() -> void:
	var box := _new_card()
	box.add_child(ThemeBuilder.card_title_label("本命法宝",
		ThemeBuilder.FONT_CARD_TITLE, ThemeBuilder.COLOR_TEXT_TITLE_GOLD))
	var frame := IconFrame.new()
	frame.setup(IconLibrary.get_ui_icon("slot_natal"), 72,
		ThemeBuilder.COLOR_TEXT_MUTED, false, 52)
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(frame)
	box.add_child(ThemeBuilder.wrap_label("需元婴初期方可凝练本命法宝。",
		ThemeBuilder.FONT_BODY, ThemeBuilder.COLOR_TEXT_PRIMARY))
	box.add_child(ThemeBuilder.wrap_label(
		"届时可选青竹蜂云剑胚、玄天古钟胚或掌天灵鼎胚，并以融材温养与器纹铭刻伴随修行。",
		ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_SECONDARY))


func _build_embryo_choice() -> void:
	var box := _new_card()
	box.add_child(ThemeBuilder.card_title_label("择一凝练器胚",
		ThemeBuilder.FONT_CARD_TITLE, ThemeBuilder.COLOR_TEXT_TITLE_GOLD))
	box.add_child(ThemeBuilder.wrap_label("器胚决定成长方向；凝练后可用重铸改换流派。",
		ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_SECONDARY))
	for embryo_id in NatalArtifactSystem.EMBRYOS.keys():
		box.add_child(_embryo_card(str(embryo_id)))


func _embryo_card(embryo_id: String) -> PanelContainer:
	var info: Dictionary = NatalArtifactSystem.EMBRYOS[embryo_id]
	var card := ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD_DEEP,
		ThemeBuilder.COLOR_BORDER, 8, 8)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 124)
	ThemeBuilder.make_card_tappable(card,
		Callable(self, "_confirm_embryo").bind(embryo_id))
	var row := ThemeBuilder.hbox(8)
	card.add_child(row)
	var frame := IconFrame.new()
	frame.setup(IconLibrary.get_icon(str(info.get("icon", "ui_slot_natal"))),
		48, ThemeBuilder.COLOR_JADE, false, 36)
	row.add_child(frame)
	var body := ThemeBuilder.vbox(2)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(body)
	body.add_child(ThemeBuilder.label(str(info.get("name", "")),
		ThemeBuilder.FONT_BODY, ThemeBuilder.COLOR_TEXT_TITLE))
	body.add_child(ThemeBuilder.chip(str(info.get("school", "")), ThemeBuilder.COLOR_JADE))
	body.add_child(ThemeBuilder.wrap_label(str(info.get("desc", "")),
		ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_SECONDARY))
	body.add_child(ThemeBuilder.label("1 重：%s" %
		NatalArtifactSystem.embryo_effect_text(embryo_id, 1),
		ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_PRIMARY))
	body.add_child(ThemeBuilder.label("40 重：%s" %
		NatalArtifactSystem.embryo_effect_text(embryo_id, 40),
		ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_JADE))
	return card


func _show_short_confirm(title_text: String, note_text: String,
		options: Array) -> void:
	var box := ThemeBuilder.vbox(8)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var note_card := ThemeBuilder.card_panel(ThemeBuilder.COLOR_JADE_PAPER,
		ThemeBuilder.COLOR_JADE_SOFT, 8, 10)
	note_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var note := ThemeBuilder.wrap_label(note_text, ThemeBuilder.FONT_BODY_SUB,
		ThemeBuilder.COLOR_TEXT_PRIMARY)
	ThemeBuilder.apply_font_size(note, ThemeBuilder.FONT_BODY_SUB)
	note_card.add_child(note)
	box.add_child(note_card)
	for value in options:
		var option: Dictionary = value
		var button := ThemeBuilder.small_button(String(option.get("text", "")),
			bool(option.get("primary", false)))
		button.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ThemeBuilder.apply_font_size(button, ThemeBuilder.FONT_CAPTION)
		var callback_value: Variant = option.get("callback", null)
		var callback: Callable = callback_value if callback_value is Callable else Callable()
		button.pressed.connect(func() -> void:
			if BottomSheet.instance != null and is_instance_valid(BottomSheet.instance):
				BottomSheet.instance.hide_sheet()
			if callback.is_valid():
				callback.call())
		box.add_child(button)
	ThemeBuilder.prepare_touch(box)
	BottomSheet.show_text(title_text, [{"custom": box}])


func _confirm_embryo(embryo_id: String) -> void:
	BottomSheet.show_grid("凝练 %s" % NatalArtifactSystem.embryo_name(embryo_id), [
		{"text": "确认凝练", "callback": Callable(self, "_do_create_embryo").bind(embryo_id)},
		{"text": "暂缓", "callback": Callable(self, "_noop")},
	])


func _do_create_embryo(embryo_id: String) -> void:
	var result: Dictionary = NatalArtifactSystem.create_embryo(embryo_id)
	EventBus.toast.emit(str(result.get("message", "")))
	_queue_refresh()


func _build_overview_card(state: Dictionary) -> void:
	var box := _new_card()
	var head := ThemeBuilder.hbox(8)
	box.add_child(head)
	var embryo_id := str(state.get("embryo_id", ""))
	var info: Dictionary = NatalArtifactSystem.EMBRYOS.get(embryo_id, {})
	var frame := IconFrame.new()
	frame.setup(IconLibrary.get_icon(str(info.get("icon", "ui_slot_natal"))),
		72, ThemeBuilder.COLOR_JADE, false, 52)
	head.add_child(frame)
	var body := ThemeBuilder.vbox(3)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(body)
	body.add_child(ThemeBuilder.label(str(info.get("name", "未凝练")),
		ThemeBuilder.FONT_CARD_TITLE, ThemeBuilder.COLOR_TEXT_TITLE))
	var badge_row := ThemeBuilder.hbox(5)
	body.add_child(badge_row)
	badge_row.add_child(ThemeBuilder.chip(
		NatalArtifactSystem.tier_name(int(state.get("level", 1))), ThemeBuilder.COLOR_AMBER))
	badge_row.add_child(ThemeBuilder.label("%d 重" % int(state.get("level", 1)),
		ThemeBuilder.FONT_BODY, ThemeBuilder.COLOR_TEXT_PRIMARY))
	badge_row.add_child(ThemeBuilder.expander())
	var recast := ThemeBuilder.small_button("重铸")
	recast.pressed.connect(Callable(self, "_choose_recast_material"))
	badge_row.add_child(recast)
	var help := ThemeBuilder.create_help_button(Callable(self, "_show_help"))
	help.custom_minimum_size = Vector2(44, 44)
	head.add_child(help)

	var level := int(state.get("level", 1))
	var need := NatalArtifactSystem.required_xp(level)
	var ratio := 1.0 if need <= 0 else clampf(float(state.get("xp", 0.0)) / float(need), 0.0, 1.0)
	var bar := ThemeBuilder.progress_bar(ThemeBuilder.COLOR_JADE, 7.0)
	bar.value = ratio
	box.add_child(bar)
	box.add_child(ThemeBuilder.label("温养灵气 %s" % (
		"圆满" if need <= 0 else "%d / %d" % [int(state.get("xp", 0.0)), need]),
		ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_SECONDARY))


func _choose_recast_material() -> void:
	BottomSheet.show_grid("重铸消耗", [
		{"text": "上古残魂 ×2", "callback": Callable(self, "_confirm_recast").bind("item_ancient_soul")},
		{"text": "真龙残鳞 ×1", "callback": Callable(self, "_confirm_recast").bind("item_dragon_scale")},
	])


func _confirm_recast(material_id: String) -> void:
	_show_short_confirm("确认重铸", "重铸后保留当前重数、温养经验与已铭刻器纹，仅更换器胚。", [
		{"text": "确认重铸", "primary": true,
			"callback": Callable(self, "_do_recast").bind(material_id)},
		{"text": "暂缓", "callback": Callable(self, "_noop")},
	])


func _do_recast(material_id: String) -> void:
	var options: Array = []
	for embryo_id in NatalArtifactSystem.EMBRYOS.keys():
		options.append({"text": NatalArtifactSystem.embryo_name(str(embryo_id)),
			"callback": Callable(self, "_do_recast_to").bind(embryo_id, material_id)})
	BottomSheet.show_grid("选择新器胚", options)


func _do_recast_to(embryo_id: String, material_id: String) -> void:
	var result: Dictionary = NatalArtifactSystem.recast_embryo(embryo_id, material_id)
	EventBus.toast.emit(str(result.get("message", "")))
	_queue_refresh()


func _build_summary_card() -> void:
	var box := _new_card()
	box.add_child(ThemeBuilder.card_title_label("总加成",
		ThemeBuilder.FONT_CARD_TITLE, ThemeBuilder.COLOR_TEXT_TITLE_GOLD))
	var bonus_rows := NatalArtifactSystem.get_summary()
	if bonus_rows.is_empty():
		box.add_child(ThemeBuilder.label("暂无生效加成",
			ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_MUTED))
		return
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(grid)
	for row in bonus_rows:
		var dict: Dictionary = row
		grid.add_child(_value_cell(str(dict.get("label", "")), str(dict.get("value", ""))))


func _value_cell(title: String, value: String) -> PanelContainer:
	var cell := ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD_DEEP,
		ThemeBuilder.COLOR_BORDER, 8, 7)
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.custom_minimum_size = Vector2(0, 44)
	var row := ThemeBuilder.hbox(6)
	cell.add_child(row)
	var title_label := ThemeBuilder.label(title, ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_SECONDARY)
	row.add_child(title_label)
	row.add_child(ThemeBuilder.expander())
	var value_label := ThemeBuilder.label(value, ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_JADE)
	value_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	row.add_child(value_label)
	return cell


func _build_feed_card(state: Dictionary) -> void:
	var box := _new_card()
	box.add_child(ThemeBuilder.card_title_label("融材温养",
		ThemeBuilder.FONT_CARD_TITLE, ThemeBuilder.COLOR_TEXT_TITLE_GOLD))
	box.add_child(ThemeBuilder.wrap_label("普通材料按售价每 10 灵石折算 1 点灵气，至少 1 点。",
		ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_SECONDARY))
	var level := int(state.get("level", 1))
	var maxed := level >= NatalArtifactSystem.MAX_LEVEL
	var pick := ThemeBuilder.small_button("选择材料熔入")
	pick.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
	ThemeBuilder.apply_font_size(pick, ThemeBuilder.FONT_CAPTION)
	pick.disabled = maxed
	pick.tooltip_text = "已达 40 重圆满，无需继续温养" if maxed else ""
	pick.pressed.connect(Callable(self, "_pick_material"))
	box.add_child(pick)
	var smelt := ThemeBuilder.small_button("一键熔入淘汰装")
	smelt.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
	ThemeBuilder.apply_font_size(smelt, ThemeBuilder.FONT_CAPTION)
	smelt.disabled = maxed
	smelt.tooltip_text = "已达 40 重圆满，无需继续温养" if maxed else ""
	smelt.pressed.connect(Callable(self, "_smelt_equipment"))
	box.add_child(smelt)
	if maxed:
		box.add_child(ThemeBuilder.label("已达 40 重圆满",
			ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_JADE))


func _pick_material() -> void:
	var item_ids := NatalArtifactSystem.get_feed_materials()
	if item_ids.is_empty():
		EventBus.toast.emit("暂无可熔入的普通材料")
		return
	var scroll := ThemeBuilder.scroll_container()
	scroll.custom_minimum_size = Vector2(0, 320)
	var list := ThemeBuilder.vbox(8)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for item_id in item_ids:
		var iid := String(item_id)
		var item := DataRegistry.get_item(iid)
		if item == null:
			continue
		var gain := NatalArtifactSystem.material_gain(iid)
		var card := ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD_DEEP,
			ThemeBuilder.COLOR_BORDER, 8, 8)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var row := ThemeBuilder.hbox(8)
		card.add_child(row)
		var icon := IconFrame.new()
		icon.setup(IconLibrary.get_item_icon(iid), 36, ThemeBuilder.COLOR_JADE, false, 28)
		row.add_child(icon)
		var info := ThemeBuilder.vbox(1)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var name_row := ThemeBuilder.hbox(6)
		name_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_child(name_row)
		var name_label := ThemeBuilder.wrap_label(item.display_name,
			ThemeBuilder.FONT_BODY, ThemeBuilder.COLOR_TEXT_PRIMARY)
		ThemeBuilder.apply_font_size(name_label, ThemeBuilder.FONT_BODY)
		ThemeBuilder.apply_item_grade_style(name_label, iid)
		name_row.add_child(name_label)
		var count_label := ThemeBuilder.label("×%d" % GameState.get_item_count(iid),
			ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_JADE)
		count_label.size_flags_horizontal = Control.SIZE_SHRINK_END
		name_row.add_child(count_label)
		var gain_label := ThemeBuilder.label("每份 +%d 温养灵气" % gain,
			ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_JADE)
		info.add_child(gain_label)
		var feed_button := ThemeBuilder.small_button("熔入")
		feed_button.custom_minimum_size = Vector2(72, ThemeBuilder.TOUCH_MIN)
		ThemeBuilder.apply_font_size(feed_button, ThemeBuilder.FONT_CAPTION)
		ThemeBuilder.tighten_button_padding(feed_button, 4.0)
		feed_button.pressed.connect(func() -> void:
			if BottomSheet.instance != null:
				BottomSheet.instance.hide_sheet()
			_pick_ratio(iid))
		row.add_child(feed_button)
		list.add_child(card)
	ThemeBuilder.prepare_touch(scroll)
	BottomSheet.show_text("选择熔入材料", [{"custom": scroll}])


func _pick_ratio(item_id: String) -> void:
	BottomSheet.show_grid("熔入比例", [
		{"text": "10%", "callback": Callable(self, "_do_feed").bind(item_id, 0.1)},
		{"text": "50%", "callback": Callable(self, "_do_feed").bind(item_id, 0.5)},
		{"text": "全部", "callback": Callable(self, "_do_feed").bind(item_id, 1.0)},
	])


func _do_feed(item_id: String, ratio: float) -> void:
	var result: Dictionary = NatalArtifactSystem.feed_material(item_id, ratio)
	EventBus.toast.emit(str(result.get("message", "熔入完成")))
	_queue_refresh()


func _smelt_equipment() -> void:
	var result: Dictionary = NatalArtifactSystem.smelt_obsolete_equipment()
	EventBus.toast.emit(str(result.get("message", "已熔入淘汰装备")))
	_queue_refresh()


func _build_engraving_card(state: Dictionary) -> void:
	var box := _new_card()
	box.add_child(ThemeBuilder.card_title_label("器纹铭刻",
		ThemeBuilder.FONT_CARD_TITLE, ThemeBuilder.COLOR_TEXT_TITLE_GOLD))
	box.add_child(ThemeBuilder.wrap_label("每次洗练消耗 500 灵石与 1 件头目珍材。",
		ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_SECONDARY))
	var level := int(state.get("level", 1))
	var unlocked := NatalArtifactSystem.slot_count(level)
	var tier_labels := ["灵宝", "古宝", "通天灵宝"]
	var engraving_value: Variant = state.get("engravings", [])
	var list: Array = engraving_value if engraving_value is Array else []
	for i in range(3):
		var entry: Dictionary = {"id": "", "tier": 0}
		if i < list.size() and typeof(list[i]) == TYPE_DICTIONARY:
			entry = list[i]
		box.add_child(_engraving_slot(i, i < unlocked, tier_labels[i], entry))


func _engraving_slot(index: int, unlocked: bool, unlock_label: String,
		entry: Dictionary) -> PanelContainer:
	var card := ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD_DEEP,
		ThemeBuilder.COLOR_BORDER, 8, 8)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 56)
	var row := ThemeBuilder.hbox(6)
	card.add_child(row)
	var frame := IconFrame.new()
	frame.setup(IconLibrary.get_icon("ui_natal_rune"), 36,
		ThemeBuilder.COLOR_JADE if unlocked else ThemeBuilder.COLOR_TEXT_MUTED, false, 28)
	row.add_child(frame)
	var info := ThemeBuilder.vbox(1)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	if unlocked:
		var rune_id := str(entry.get("id", ""))
		var tier := int(entry.get("tier", 0))
		if rune_id == "":
			info.add_child(ThemeBuilder.label("第 %d 槽 · 空" % (index + 1),
				ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_PRIMARY))
		else:
			var rune: Dictionary = NatalArtifactSystem.RUNES[rune_id]
			info.add_child(ThemeBuilder.label("%s · %s品" % [
				str(rune.get("name", "")),
				NatalArtifactSystem.RUNE_TIER_NAMES[clampi(tier - 1, 0, 3)]],
				ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_JADE))
			info.add_child(ThemeBuilder.label(NatalArtifactSystem.engraving_value_text(rune_id, tier),
				ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_SECONDARY))
		var wash := ThemeBuilder.small_button("洗练")
		wash.pressed.connect(Callable(self, "_choose_engrave_material").bind(index))
		row.add_child(wash)
	else:
		info.add_child(ThemeBuilder.label("第 %d 槽 · 需%s解锁" % [index + 1, unlock_label],
			ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_MUTED))
	return card


func _choose_engrave_material(slot_index: int) -> void:
	var box := ThemeBuilder.vbox(8)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for material_id in NatalArtifactSystem.ENGRAVE_MATERIALS:
		var iid := String(material_id)
		var have := GameState.get_item_count(iid)
		var button := ThemeBuilder.button("%s ×1 (存 %d)" % [
			DataRegistry.get_item_name(iid), have])
		button.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.disabled = have <= 0
		ThemeBuilder.apply_font_size(button, ThemeBuilder.FONT_CAPTION)
		button.tooltip_text = "库存不足" if have <= 0 else "消耗 1 件洗练珍材"
		button.pressed.connect(func() -> void:
			if BottomSheet.instance != null:
				BottomSheet.instance.hide_sheet()
			_confirm_engrave(slot_index, iid))
		box.add_child(button)
	ThemeBuilder.prepare_touch(box)
	BottomSheet.show_text("选择洗练珍材", [{"custom": box}])


func _confirm_engrave(slot_index: int, material_id: String) -> void:
	_show_short_confirm("确认洗练", "洗练将消耗一件珍材，为此器纹槽重铸一条新的器纹。", [
		{"text": "确认洗练", "primary": true,
			"callback": Callable(self, "_do_engrave").bind(slot_index, material_id)},
		{"text": "暂缓", "callback": Callable(self, "_noop")},
	])


func _do_engrave(slot_index: int, material_id: String) -> void:
	var result: Dictionary = NatalArtifactSystem.engrave(slot_index, material_id)
	EventBus.toast.emit(str(result.get("message", "洗练完成")))
	_queue_refresh()


func _show_help() -> void:
	BottomSheet.show_help("本命法宝 · 图解", [
		{"text": "器胚", "desc": "青竹蜂云剑主攻伐，玄天古钟主守御，掌天灵鼎主百艺。"},
		{"text": "阶级", "desc": "1~10 重灵宝，11~20 重古宝，21~30 重通天灵宝，31~40 重先天至宝；器纹效用额外乘 1.35。"},
		{"text": "温养", "desc": "熔入普通材料或闲置装备累积灵气，每重所需灵气按 1.16 倍递增。"},
		{"text": "器纹", "desc": "锐金、厚土、避雷、悟道、迅捷、归元六类，分凡灵玄仙四档。"},
	])


func _noop() -> void:
	pass
