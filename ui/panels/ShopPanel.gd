class_name ShopPanel
extends Control
## 「仙坊阁」：灵石消耗出口 —— 法器宝具 / 洞府扩建 / 灵种杂货。

const FILTERS: Array = [
	{"key": "gear", "label": "法器宝具"},
	{"key": "farm", "label": "洞府扩建"},
	{"key": "seed", "label": "灵种杂货"},
]

var _filter: String = "gear"
var _filter_buttons: Dictionary = {}
var _list_box: GridContainer
var _rebuild_queued: bool = false
var _is_dirty: bool = false


func _ready() -> void:
	_build()
	EventBus.shop_changed.connect(_queue_rebuild)
	EventBus.inventory_changed.connect(_queue_rebuild)
	EventBus.game_loaded.connect(_queue_rebuild)
	EventBus.layout_changed.connect(_on_layout_changed)
	visibility_changed.connect(_on_visibility_changed)
	_refresh_filter_styles()
	rebuild()
	_on_layout_changed(EventBus.current_layout, EventBus.current_viewport, EventBus.workspace_width)


func _on_layout_changed(_mode: int, _vp_size: Vector2, workspace_width: float) -> void:
	if _list_box != null:
		_list_box.columns = 2 if workspace_width >= 680.0 else 1


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
	title_row.add_child(ThemeBuilder.title_label("仙坊阁", 20))
	title_row.add_child(ThemeBuilder.chip("灵石可用", ThemeBuilder.COLOR_AMBER))
	var help := ThemeBuilder.create_help_button(_show_help)
	help.custom_minimum_size = Vector2(44, 44)
	help.tooltip_text = "仙坊阁规则"
	title_row.add_child(help)
	title_row.add_child(ThemeBuilder.expander())
	title_row.move_child(help, -1)
	ThemeBuilder.attach_header_watermark(header, IconLibrary.get_nav_icon("shop"))

	var filter_row := ThemeBuilder.hbox(6)
	root.add_child(filter_row)
	for entry in FILTERS:
		var dict: Dictionary = entry
		var key := String(dict["key"])
		var button := ThemeBuilder.small_button(String(dict["label"]))
		button.toggle_mode = true
		button.button_pressed = key == _filter
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ThemeBuilder.apply_font_size(button, 13)
		button.pressed.connect(_on_filter_pressed.bind(key))
		filter_row.add_child(button)
		_filter_buttons[key] = button

	var scroll := ThemeBuilder.scroll_container()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	_list_box = GridContainer.new()
	_list_box.columns = 1
	_list_box.add_theme_constant_override("h_separation", 8)
	_list_box.add_theme_constant_override("v_separation", 8)
	_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list_box)

	ThemeBuilder.prepare_touch(root)


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

	var items: Array = DataRegistry.get_shop_upgrades_by_category(_filter)
	items.sort_custom(func(a: ShopUpgradeData, b: ShopUpgradeData) -> bool:
		var a_owned := _is_maxed(a)
		var b_owned := _is_maxed(b)
		if a_owned != b_owned:
			return not a_owned
		return a.cost_stones < b.cost_stones
	)
	if items.is_empty():
		_list_box.add_child(ThemeBuilder.dim_label("此处暂无货品。", 13))
		return
	for upgrade in items:
		var row := _build_row(upgrade as ShopUpgradeData)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_list_box.add_child(row)



	# 动态重建后补挂触控约定（按钮 PASS + 14px 滑动守卫）
	ThemeBuilder.prepare_touch(_list_box)
func _is_maxed(upgrade: ShopUpgradeData) -> bool:
	if upgrade.is_repeatable():
		return false
	return GameState.get_upgrade_level(upgrade.id) >= upgrade.max_level


## 紧凑横排：左图标 + 中两行信息 + 右价格按钮，避免 450 宽下横向挤压
func _build_row(upgrade: ShopUpgradeData) -> PanelContainer:
	var owned := _is_maxed(upgrade)
	var card := ThemeBuilder.card_panel(
		ThemeBuilder.COLOR_CARD if not owned else ThemeBuilder.COLOR_CARD_DEEP,
		ThemeBuilder.COLOR_BORDER, 8, 10)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if owned:
		card.modulate.a = 0.72
	var outer := ThemeBuilder.hbox(8)
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(outer)

	var icon_frame := IconFrame.new()
	icon_frame.custom_minimum_size = Vector2(44, 44)
	outer.add_child(icon_frame)
	var accent := ThemeBuilder.COLOR_JADE
	if upgrade.category == "farm":
		accent = ThemeBuilder.COLOR_EMERALD
	elif upgrade.category == "seed":
		accent = ThemeBuilder.COLOR_AMBER
	icon_frame.setup(IconLibrary.get_shop_icon(upgrade), 44, accent, false, 34)

	var box := ThemeBuilder.vbox(2)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.custom_minimum_size = Vector2(0, 0)
	outer.add_child(box)

	var shop_title := ThemeBuilder.label(upgrade.name, ThemeBuilder.FONT_BODY,
		ThemeBuilder.COLOR_TEXT_PRIMARY)
	ThemeBuilder.apply_font_size(shop_title, ThemeBuilder.FONT_BODY)
	shop_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_title.clip_text = true
	shop_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	ThemeBuilder.apply_item_grade_style(shop_title, upgrade.effect_target)
	box.add_child(shop_title)

	var owned_level := GameState.get_upgrade_level(upgrade.id)
	var detail_text := ""
	if upgrade.category == "seed":
		detail_text = "库存 %s · 可复购" % GameFormulas.format_num(
			float(GameState.get_item_count(upgrade.effect_target)))
	else:
		detail_text = _effect_line(upgrade)
		if upgrade.max_level > 0:
			detail_text += " · 已购 %d/%d" % [owned_level, upgrade.max_level]
		elif upgrade.is_repeatable():
			detail_text += " · 已购 %d 次" % owned_level
	var detail_label := ThemeBuilder.wrap_label(detail_text, ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_SECONDARY)
	ThemeBuilder.apply_font_size(detail_label, ThemeBuilder.FONT_CAPTION)
	detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_label.clip_text = true
	detail_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(detail_label)

	var check := GameState.can_purchase_upgrade(upgrade.id)
	var can_buy := bool(check.get("ok", false))
	var reason := String(check.get("reason", ""))
	var price_text := "%s 灵石" % GameFormulas.format_num(float(upgrade.cost_stones))
	var buy_text := price_text
	if owned:
		buy_text = "已拥有"
	elif not can_buy and reason != "灵石不足":
		buy_text = reason

	var buy_button := ThemeBuilder.small_button(buy_text)
	buy_button.custom_minimum_size = Vector2(104, ThemeBuilder.TOUCH_MIN)
	buy_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	buy_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	buy_button.clip_text = true
	buy_button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	buy_button.tooltip_text = buy_text if buy_text == price_text else reason
	ThemeBuilder.apply_font_size(buy_button, ThemeBuilder.FONT_CAPTION)
	ThemeBuilder.tighten_button_padding(buy_button, 6.0)
	buy_button.disabled = not can_buy
	if can_buy:
		ThemeBuilder.apply_primary_button(buy_button)
	elif reason == "灵石不足":
		buy_button.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT_DANGER)
		buy_button.add_theme_color_override("font_disabled_color", ThemeBuilder.COLOR_TEXT_DANGER)
	else:
		buy_button.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT_MUTED)
		buy_button.add_theme_color_override("font_disabled_color", ThemeBuilder.COLOR_TEXT_MUTED)
	buy_button.pressed.connect(_on_buy_pressed.bind(upgrade.id, buy_button))
	outer.add_child(buy_button)

	ThemeBuilder.make_card_tappable(card, func() -> void: _show_detail(upgrade))
	return card


## 效果行：技能类目标前面补上「采药寻灵 · 」，避免同类商品只剩一串相同的百分比
func _effect_line(upgrade: ShopUpgradeData) -> String:
	var text := upgrade.get_effect_text()
	var target := upgrade.effect_target
	var meta := DataRegistry.get_skill_meta(target)
	if target != "" and not meta.is_empty():
		return "%s · %s" % [String(meta.get("name", target)), text]
	return text


## 卡片详情浮层：身份 + 核心数值 + 用途说明
func _show_detail(upgrade: ShopUpgradeData) -> void:
	if AudioManager != null:
		AudioManager.play_tap()
	var level := GameState.get_upgrade_level(upgrade.id)
	var repeatable := upgrade.is_repeatable()
	var owned := level > 0
	var status_text := "尚未购入"
	if repeatable and owned:
		status_text = "已购 %d 次" % level
	elif owned:
		status_text = "已拥有"

	var category_text := "法器宝具"
	match upgrade.category:
		"farm":
			category_text = "洞府扩建"
		"seed":
			category_text = "灵种杂货"
	var tags: Array = [
		{"text": category_text, "color": ThemeBuilder.COLOR_TEXT_JADE},
		{"text": "可反复购置" if repeatable else "永久",
			"color": ThemeBuilder.COLOR_TEXT_GOLD if repeatable else ThemeBuilder.COLOR_TEXT_SECONDARY},
	]
	var rows: Array = [
		{"label": "购入状态", "value": status_text,
			"color": ThemeBuilder.COLOR_TEXT_JADE if owned else ThemeBuilder.COLOR_TEXT_SECONDARY},
		{"label": "核心效用", "value": _effect_line(upgrade),
			"color": ThemeBuilder.COLOR_TEXT_JADE},
		{"label": "当前效用", "value": _value_at(upgrade, level) if owned else "尚未购入。",
			"color": ThemeBuilder.COLOR_TEXT_PRIMARY},
	]
	if not owned or repeatable:
		rows.append({
			"label": "购入效用", "value": _value_at(upgrade, level + 1),
			"color": ThemeBuilder.COLOR_TEXT_GOLD,
		})
	rows.append({
		"label": "所需灵石", "value": upgrade.get_cost_text(),
		"color": ThemeBuilder.COLOR_TEXT_GOLD,
	})
	BottomSheet.show_detail({
		"title": upgrade.name,
		"icon": IconLibrary.get_shop_icon(upgrade),
		"icon_accent": ThemeBuilder.COLOR_JADE if upgrade.category == "gear" \
			else (ThemeBuilder.COLOR_EMERALD if upgrade.category == "farm" \
			else ThemeBuilder.COLOR_AMBER),
		"tags": tags,
		"rows": rows,
		"note": upgrade.description if upgrade.description != "" else "暂无说明。",
	})


## 某购置次数下的累计效果文案（百分比类才累加，获得物品类原样返回）
func _value_at(upgrade: ShopUpgradeData, level: int) -> String:
	if level <= 0:
		return "尚未购入。"
	var percent_types := ["interval", "double_chance", "quality_pct",
		"cultivation_pct", "heal_pct", "all_craft_interval"]
	if not (upgrade.effect_type in percent_types):
		return upgrade.get_effect_text()
	if upgrade.max_level <= 1:
		return upgrade.get_effect_text()
	var total := upgrade.effect_value * float(level)
	return "%s（已购 %d 次，累计 %+.0f%%）" % [upgrade.get_effect_text(), level, total * 100.0]


## 缺料来源跳转：切到对应页签
func select_tab(tab: String) -> void:
	if tab == _filter:
		return
	for entry in FILTERS:
		var dict: Dictionary = entry
		if String(dict.get("key", "")) == tab:
			_on_filter_pressed(tab)
			return


func _clean_description(desc: String) -> String:
	var text := desc
	for pair in [
		["采药寻灵", "采药"], ["伐木取材", "伐木"], ["开矿掘脉", "开矿"],
		["丹道炼制", "丹道"], ["器道锻造", "器道"], ["符箓绘制", "符箓"],
		["吐纳筑基", "吐纳"], ["双倍产出率", "双倍"], ["精良品质概率", "精良率"],
		["修为获取", "修为"], ["回春散回血效果", "回血"], ["回血丹回复效果", "回血"],
		["回血效果", "回血"], ["战斗与渡劫中", ""], ["药草", ""], ["再 ", ""],
	]:
		text = text.replace(String(pair[0]), String(pair[1]))
	var regex := RegEx.new()
	regex.compile("[（(]需[^）)]*[）)]")
	text = regex.sub(text, "", true)
	text = text.strip_edges()
	while text.ends_with("。"):
		text = text.substr(0, text.length() - 1)
	return text


func _show_help() -> void:
	BottomSheet.show_help("仙坊阁 · 规则", [
		{"text": "法器宝具", "desc": "永久生效，分别提升对应百艺的耗时、双倍几率、品质或修为收益。"},
		{"text": "洞府扩建", "desc": "解锁额外灵田地块；地块永久保留，可种植所有已获得灵种。"},
		{"text": "灵种杂货", "desc": "灵种可反复购置，种下后按成熟时间在洞府灵田收获。"},
	])


func _on_filter_pressed(key: String) -> void:
	_filter = key
	_refresh_filter_styles()
	rebuild()


func _refresh_filter_styles() -> void:
	for filter_key in _filter_buttons.keys():
		var button: Button = _filter_buttons[filter_key]
		var active := String(filter_key) == _filter
		button.button_pressed = active
		ThemeBuilder.apply_toggle_button(button, active)


func _on_buy_pressed(upgrade_id: String, anchor: Control = null) -> void:
	if GameState.purchase_upgrade(upgrade_id):
		GameState.vibrate_light()
		if AudioManager != null:
			AudioManager.play_coin()
		if anchor != null:
			UiMotion.pulse(anchor, 1.12, 0.22)
			if InkVfxLayer.instance != null:
				InkVfxLayer.instance.play_gold_flow(
					anchor.get_global_rect().get_center(), InkVfxLayer.INK_GOLD)
	rebuild()


func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
