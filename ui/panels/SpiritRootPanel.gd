extends Control

## 灵根洗髓：炼气七层开启的后天纯化与五行亲和切换界面。
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
	_connect_if(EventBus, "farm_changed", Callable(self, "_queue_refresh"))
	_connect_if(EventBus, "realm_changed", Callable(self, "_on_realm_changed"))
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


func _on_realm_changed(_realm_id: String, _realm_name: String) -> void:
	_queue_refresh()


func _rebuild() -> void:
	_rebuild_queued = false
	if not is_inside_tree() or not visible:
		return
	_dirty = false
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	if not SpiritRootSystem.is_unlocked():
		_build_locked_card()
	else:
		_build_overview_card()
		_build_purify_card()
		_build_switch_card()
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
	box.add_child(ThemeBuilder.card_title_label("灵根洗髓",
		ThemeBuilder.FONT_CARD_TITLE, ThemeBuilder.COLOR_TEXT_TITLE_GOLD))
	var frame := IconFrame.new()
	frame.setup(IconLibrary.get_icon("root_wood"), 72,
		ThemeBuilder.COLOR_TEXT_MUTED, false, 52)
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(frame)
	box.add_child(ThemeBuilder.wrap_label("需炼气七层方可开启灵根洗髓。",
		ThemeBuilder.FONT_BODY, ThemeBuilder.COLOR_TEXT_PRIMARY))
	box.add_child(ThemeBuilder.wrap_label(
		"五灵根 → 四灵根 → 三灵根 → 双灵根 → 天灵根；纯化需跨大境界，并可调引五行亲和。",
		ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_SECONDARY))


func _build_overview_card() -> void:
	var box := _new_card()
	var head := ThemeBuilder.hbox(8)
	box.add_child(head)
	var frame := IconFrame.new()
	frame.setup(IconLibrary.get_icon(SpiritRootSystem.element_icon()), 48, ThemeBuilder.COLOR_JADE)
	head.add_child(frame)
	var title := ThemeBuilder.card_title_label(SpiritRootSystem.get_badge_text(),
		ThemeBuilder.FONT_CARD_TITLE, ThemeBuilder.COLOR_TEXT_TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	head.add_child(title)
	var help := ThemeBuilder.create_help_button(Callable(self, "_show_help"))
	help.custom_minimum_size = Vector2(44, 44)
	head.add_child(help)

	var summary: Array = SpiritRootSystem.get_summary()
	if summary.is_empty():
		box.add_child(ThemeBuilder.wrap_label("五灵根尚未纯化，无额外亲和加成。",
			ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_SECONDARY))
		return
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(grid)
	for entry in summary:
		var row: Dictionary = entry
		var label_text := str(row.get("label", ""))
		if label_text == "对应百艺耗时":
			label_text = _element_craft_label()
		grid.add_child(_summary_cell(label_text, str(row.get("value", ""))))


func _summary_cell(label_text: String, value_text: String) -> Control:
	var cell := ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD_DEEP,
		ThemeBuilder.COLOR_BORDER, 6, 8)
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := ThemeBuilder.hbox(6)
	cell.add_child(row)
	var name_label := ThemeBuilder.label(label_text, ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_SECONDARY)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(name_label)
	row.add_child(ThemeBuilder.label(value_text, ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_JADE))
	return cell


func _element_craft_label() -> String:
	match SpiritRootSystem.get_element():
		"metal":
			return "开矿与器道耗时"
		"wood":
			return "采药与伐木耗时"
		"fire":
			return "丹道与制符耗时"
		_:
			return "对应百艺耗时"


func _build_purify_card() -> void:
	var box := _new_card()
	box.add_child(ThemeBuilder.card_title_label("洗髓纯化",
		ThemeBuilder.FONT_CARD_TITLE, ThemeBuilder.COLOR_TEXT_TITLE_GOLD))
	var plan := SpiritRootSystem.get_purify_plan()
	if plan.is_empty():
		box.add_child(ThemeBuilder.wrap_label("灵根已臻天品圆满，无需再洗髓。",
			ThemeBuilder.FONT_BODY, ThemeBuilder.COLOR_TEXT_JADE))
		return
	box.add_child(ThemeBuilder.wrap_label("下一阶：%s · 需 %s" % [
		str(plan.get("name", "")), _realm_label(int(plan.get("realm", 0)))],
		ThemeBuilder.FONT_BODY, ThemeBuilder.COLOR_TEXT_PRIMARY))
	var items: Dictionary = plan.get("items", {})
	for item_id in items.keys():
		var need := int(items[item_id])
		var have := GameState.get_item_count(str(item_id))
		box.add_child(_cost_row(DataRegistry.get_item_name(str(item_id)), have, need))
	var stones := int(plan.get("stones", 0))
	box.add_child(_cost_row("灵石", GameState.get_item_count(DataRegistry.SPIRIT_STONE), stones))
	var check := SpiritRootSystem.can_purify()
	var button := ThemeBuilder.small_button(
		"需 %s" % str(check.get("reason", "")) if not bool(check.get("ok", false)) else "洗髓纯化")
	button.disabled = not bool(check.get("ok", false))
	if button.disabled:
		ThemeBuilder.apply_secondary_button(button)
	else:
		ThemeBuilder.apply_primary_button(button)
	button.pressed.connect(Callable(self, "_on_purify_pressed"))
	box.add_child(button)


func _cost_row(title_value: String, have: int, need: int) -> Control:
	var row := ThemeBuilder.hbox(6)
	var ok := have >= need
	row.add_child(ThemeBuilder.label(title_value, ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_PRIMARY))
	row.add_child(ThemeBuilder.expander())
	row.add_child(ThemeBuilder.label("%d / %d" % [have, need], ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_JADE if ok else ThemeBuilder.COLOR_TEXT_DANGER))
	return row


func _build_switch_card() -> void:
	var box := _new_card()
	box.add_child(ThemeBuilder.card_title_label("五行亲和切换",
		ThemeBuilder.FONT_CARD_TITLE, ThemeBuilder.COLOR_TEXT_TITLE_GOLD))
	var cost := SpiritRootSystem.get_switch_cost()
	box.add_child(ThemeBuilder.wrap_label(
		"导引改脉保留当前品阶，仅切换主灵根方向（每次需 %d 灵石）。" % cost,
		ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_SECONDARY))
	for element in SpiritRootSystem.ELEMENT_KEYS:
		var key := str(element)
		box.add_child(_switch_row(key, cost))


func _switch_row(element: String, cost: int) -> Control:
	var current := element == SpiritRootSystem.get_element()
	var card := ThemeBuilder.card_panel(
		ThemeBuilder.COLOR_JADE_PAPER if current else ThemeBuilder.COLOR_CARD_DEEP,
		ThemeBuilder.COLOR_JADE_DARK if current else ThemeBuilder.COLOR_BORDER, 6, 6)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 56)
	var row := ThemeBuilder.hbox(6)
	card.add_child(row)
	var frame := IconFrame.new()
	frame.setup(IconLibrary.get_icon(SpiritRootSystem.element_icon(element)), 24,
		ThemeBuilder.COLOR_JADE_DARK if current else ThemeBuilder.COLOR_JADE, false, 20)
	row.add_child(frame)
	var info := ThemeBuilder.vbox(1)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	info.add_child(ThemeBuilder.label("%s灵根" % SpiritRootSystem.element_name(element),
		ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_JADE if current else ThemeBuilder.COLOR_TEXT_PRIMARY))
	var effect := SpiritRootSystem.get_effect_text(element, SpiritRootSystem.get_grade())
	for part in effect.split(" · "):
		var part_label := ThemeBuilder.wrap_label(str(part), ThemeBuilder.FONT_CAPTION,
			ThemeBuilder.COLOR_TEXT_SECONDARY)
		info.add_child(part_label)
	var button := ThemeBuilder.small_button("当前主脉" if current else "导引切换")
	button.custom_minimum_size = Vector2(96, ThemeBuilder.TOUCH_MIN)
	button.size_flags_horizontal = Control.SIZE_SHRINK_END
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.disabled = current or GameState.get_item_count(DataRegistry.SPIRIT_STONE) < cost
	if current:
		ThemeBuilder.apply_secondary_button(button)
		button.add_theme_color_override("font_disabled_color", ThemeBuilder.COLOR_TEXT_JADE)
		button.tooltip_text = "当前生效主灵根"
	elif button.disabled:
		ThemeBuilder.apply_secondary_button(button)
		button.add_theme_color_override("font_disabled_color", ThemeBuilder.COLOR_TEXT_MUTED)
		button.tooltip_text = "灵石不足"
	else:
		ThemeBuilder.apply_primary_button(button)
		button.tooltip_text = "导引改脉至%s灵根" % SpiritRootSystem.element_name(element)
	button.pressed.connect(Callable(self, "_on_switch_pressed").bind(element))
	row.add_child(button)
	return card


func _realm_label(order: int) -> String:
	match order:
		6:
			return "炼气七层"
		9:
			return "筑基初期"
		12:
			return "金丹初期"
		15:
			return "元婴初期"
	return "境界 %d 阶" % order


func _on_purify_pressed() -> void:
	var result: Dictionary = SpiritRootSystem.purify()
	EventBus.toast.emit(str(result.get("message", "")))
	_queue_refresh()


func _on_switch_pressed(element: String) -> void:
	var cost := SpiritRootSystem.get_switch_cost()
	BottomSheet.show_detail({
		"title": "导引改脉",
		"icon": IconLibrary.get_icon(SpiritRootSystem.element_icon(element)),
		"tags": [
			{"text": "目标 %s灵根" % SpiritRootSystem.element_name(element),
				"color": ThemeBuilder.COLOR_TEXT_JADE},
			{"text": "灵石 %d" % cost, "color": ThemeBuilder.COLOR_TEXT_GOLD},
		],
		"rows": [
			{"label": "当前品阶", "value": SpiritRootSystem.get_grade_name()},
			{"label": "当前主灵根", "value": SpiritRootSystem.element_name()},
			{"label": "目标主灵根", "value": SpiritRootSystem.element_name(element)},
		],
		"note": "切换后保留当前灵根品阶，仅改变五行亲和方向。",
		"actions": [{
			"text": "确认切换",
			"callback": Callable(self, "_confirm_switch").bind(element),
			"accent": true,
			"primary": true,
			"full_width": true,
		}],
	})


func _confirm_switch(element: String) -> void:
	var result: Dictionary = SpiritRootSystem.switch_element(element)
	if bool(result.get("ok", false)):
		if BottomSheet.instance != null:
			BottomSheet.instance.hide_sheet()
		EventBus.toast.emit("灵根已导引至%s灵根" % SpiritRootSystem.element_name(element))
	else:
		EventBus.toast.emit(str(result.get("message", "")))
	_queue_refresh()


func _show_help() -> void:
	BottomSheet.show_help("灵根洗髓 · 图解", [
		{"text": "灵根品阶", "desc": "五灵根、四灵根、三灵根、双灵根、天灵根共五阶；纯化门槛分别为炼气七层、筑基初期、金丹初期与元婴初期。"},
		{"text": "基础收益", "desc": "每阶提升吐纳修为与渡劫抗性；高阶灵根不会突破已有会心、减伤与双倍硬上限。"},
		{"text": "五行亲和", "desc": "金重攻伐与矿器，木重灵田，水重吐纳与丹符双倍，火重丹符与会心，土重气血防御与抗雷。"},
		{"text": "导引改脉", "desc": "炼气七层后可切换主灵根，消耗灵石 300 ×（当前品阶 + 1），品阶保持不变。"},
	])
