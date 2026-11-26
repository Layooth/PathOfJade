extends Control

## 五行法则：合体初期开启的终局参悟界面。
## 不声明 class_name：由 MainShell 以 preload 加载，确保 PCK 单发也能生效。

const LAW_ICON_COLORS: Dictionary = {
	"metal": ["#8A6A1F", "#B08222"],
	"wood": ["#1E5B43", "#227454"],
	"water": ["#174E7A", "#1E62A8"],
	"fire": ["#9C3525", "#C44935"],
	"earth": ["#6F512E", "#8A6238"],
}

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
	_connect_if(EventBus, "realm_changed", Callable(self, "_on_realm_changed"))
	_connect_if(EventBus, "mastery_pool_changed", Callable(self, "_on_pool_changed"))
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


func _on_pool_changed(_skill_id: String, _current: float, _capacity: float) -> void:
	_queue_refresh()


func _rebuild() -> void:
	_rebuild_queued = false
	if not is_inside_tree() or not visible:
		return
	_dirty = false
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	if not FiveElementsSystem.is_unlocked():
		_build_locked_card()
	else:
		_build_overview_card()
		for law_id in FiveElementsSystem.LAW_KEYS:
			_build_law_card(str(law_id))
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
	box.add_child(ThemeBuilder.card_title_label("五行法则",
		ThemeBuilder.FONT_CARD_TITLE, ThemeBuilder.COLOR_TEXT_TITLE_GOLD))
	var frame := IconFrame.new()
	var primary := ThemeBuilder.hex(ThemeBuilder.COLOR_JADE_DARK)
	var accent := ThemeBuilder.hex(ThemeBuilder.COLOR_JADE)
	frame.setup(IconLibrary.get_normalized_icon("page_icon|five_elements|ui_five_elements",
		IconLibrary.get_icon("ui_five_elements", primary, accent)), 72,
		ThemeBuilder.COLOR_TEXT_MUTED, false, 52)
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(frame)
	box.add_child(ThemeBuilder.wrap_label("需合体初期方可参悟五行法则。",
		ThemeBuilder.FONT_BODY, ThemeBuilder.COLOR_TEXT_PRIMARY))
	box.add_child(ThemeBuilder.wrap_label(
		"金主攻伐、木主灵田、水主吐纳、火主产出、土主守御；五法齐备方为飞升根基。",
		ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_SECONDARY))


func _build_overview_card() -> void:
	var box := _new_card()
	var head := ThemeBuilder.hbox(6)
	box.add_child(head)
	head.add_child(ThemeBuilder.card_title_label("五行法则",
		ThemeBuilder.FONT_CARD_TITLE, ThemeBuilder.COLOR_TEXT_TITLE_GOLD))
	var page_icon := IconFrame.new()
	var primary := ThemeBuilder.hex(ThemeBuilder.COLOR_JADE_DARK)
	var accent := ThemeBuilder.hex(ThemeBuilder.COLOR_JADE)
	page_icon.setup(IconLibrary.get_normalized_icon("page_icon|five_elements|ui_five_elements",
		IconLibrary.get_icon("ui_five_elements", primary, accent)), 24,
		ThemeBuilder.COLOR_JADE_DARK, false, 20)
	head.add_child(page_icon)
	head.add_child(ThemeBuilder.expander())
	var help := ThemeBuilder.create_help_button(Callable(self, "_show_help"))
	help.custom_minimum_size = Vector2(44, 44)
	head.add_child(help)

	box.add_child(ThemeBuilder.label("已参悟总重数 %d / 25 重" %
		FiveElementsSystem.get_total_levels(), ThemeBuilder.FONT_BODY,
		ThemeBuilder.COLOR_TEXT_JADE))
	box.add_child(ThemeBuilder.label("当前可用悟道总池 %s" %
		GameFormulas.format_num(FiveElementsSystem.get_total_pool_xp()),
		ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_SECONDARY))

	var ascension := FiveElementsSystem.ascension_ready()
	var progress := "飞升前置："
	if bool(ascension.get("ok", false)):
		progress += "三果齐备，可引动飞升天劫"
	else:
		progress += str(ascension.get("message", "尚未齐备"))
	box.add_child(ThemeBuilder.wrap_label(progress, ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_PRIMARY))

	if FiveElementsSystem.get_level("wood") >= 1:
		var enabled := FiveElementsSystem.is_auto_farm_enabled()
		var row := ThemeBuilder.hbox(6)
		box.add_child(row)
		row.add_child(ThemeBuilder.label("灵田自动轮作", ThemeBuilder.FONT_CAPTION,
			ThemeBuilder.COLOR_TEXT_PRIMARY))
		row.add_child(ThemeBuilder.expander())
		var toggle := ThemeBuilder.small_button("已开启" if enabled else "已关闭")
		ThemeBuilder.apply_toggle_button(toggle, enabled)
		toggle.pressed.connect(Callable(self, "_toggle_auto_farm"))
		row.add_child(toggle)


func _build_law_card(law_id: String) -> void:
	var law: Dictionary = FiveElementsSystem.LAWS[law_id]
	var level := FiveElementsSystem.get_level(law_id)
	var card := ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD_DEEP,
		ThemeBuilder.COLOR_BORDER, 8, 8)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_child(card)
	var box := ThemeBuilder.vbox(6)
	card.add_child(box)
	var head := ThemeBuilder.hbox(8)
	box.add_child(head)
	var colors: Array = LAW_ICON_COLORS.get(law_id, LAW_ICON_COLORS["metal"])
	var frame := IconFrame.new()
	frame.setup(IconLibrary.get_icon(str(law.get("icon", "law_metal")),
		String(colors[0]), String(colors[1])),
		48, Color(String(colors[1])), false, 36)
	head.add_child(frame)
	var info := ThemeBuilder.vbox(2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(info)
	info.add_child(ThemeBuilder.label("%s · %d / 5 重" % [
		str(law.get("name", "")), level], ThemeBuilder.FONT_BODY,
		ThemeBuilder.COLOR_TEXT_TITLE))
	info.add_child(ThemeBuilder.wrap_label(
		FiveElementsSystem.get_effect_text(law_id, level),
		ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_JADE))

	var next_level := level + 1
	if next_level <= FiveElementsSystem.MAX_LEVEL:
		var materials: Array = law.get("materials", [])
		var material_id := "item_hundun_stone" if materials.is_empty() else str(materials[0])
		var cost_text := "下一重：%s ×%d · 悟道 %s" % [
			DataRegistry.get_item_name(material_id),
			FiveElementsSystem.material_cost(next_level),
			GameFormulas.format_num(float(FiveElementsSystem.pool_cost(next_level)))]
		box.add_child(ThemeBuilder.wrap_label(cost_text, ThemeBuilder.FONT_CAPTION,
			ThemeBuilder.COLOR_TEXT_SECONDARY))

	var check := FiveElementsSystem.can_upgrade(law_id)
	var button_text := "参悟法则"
	if level >= FiveElementsSystem.MAX_LEVEL:
		button_text = "已至圆满"
	elif not bool(check.get("ok", false)):
		button_text = str(check.get("reason", "暂不可参悟"))
	var button := ThemeBuilder.small_button(button_text)
	button.disabled = not bool(check.get("ok", false))
	if button.disabled:
		ThemeBuilder.apply_secondary_button(button)
	else:
		ThemeBuilder.apply_primary_button(button)
	button.pressed.connect(Callable(self, "_upgrade").bind(law_id))
	box.add_child(button)


func _upgrade(law_id: String) -> void:
	var result: Dictionary = FiveElementsSystem.upgrade(law_id)
	EventBus.toast.emit(str(result.get("message", "参悟完成")))
	_queue_refresh()


func _toggle_auto_farm() -> void:
	var enabled := not FiveElementsSystem.is_auto_farm_enabled()
	FiveElementsSystem.set_auto_farm(enabled)
	EventBus.toast.emit("灵田自动轮作已开启" if enabled else "灵田自动轮作已关闭")
	_queue_refresh()


func _show_help() -> void:
	BottomSheet.show_help("五行法则 · 图解", [
		{"text": "金之法则", "desc": "每重攻击 +5%；1 重起秘境与镇魔塔攻击间隔 -10%。"},
		{"text": "木之法则", "desc": "每重灵田生长耗时 -4%；1 重起开启自动收获与轮作。"},
		{"text": "水之法则", "desc": "1 重起吐纳修为 +15%；每重离线折算效率 +4%。"},
		{"text": "火之法则", "desc": "1 重起精良与极品产出率 +8%；每重双倍产出 +4%。"},
		{"text": "土之法则", "desc": "1 重起天雷抗性 +10%；每重气血上限与防御力 +6%。"},
		{"text": "飞升三果", "desc": "本命法宝 31 重、五行皆至少 1 重、修为圆满并持有渡劫飞升丹。"},
	])
