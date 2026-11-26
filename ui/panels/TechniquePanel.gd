class_name TechniquePanel
extends Control
## 「藏经阁 · 功法研习」：运转槽 + 9 部功法（解锁 / 运转 / 参悟升级）。

const UNLOCK_ORDER: int = 5
const UNLOCK_LABEL: String = "炼气六层"
const UNLOCK_DESC: String = "藏经阁收录诸天功法，可装配运转、参悟升级，并以仙盟贡献兑换。突破至炼气六层后开启。"

const FILTERS: Array = [
	{"key": "all", "label": "全部"},
	{"key": "wood", "label": "种田丹修"},
	{"key": "sword", "label": "剑修爆发"},
	{"key": "shield", "label": "苟命渡劫"},
]

const SLOT_NAMES: Array[String] = ["功法一", "功法二", "功法三", "功法四"]

const EFFECT_LABELS: Dictionary = {	"herb_double": "采药双倍", "farm_speed": "灵田生长", "alchemy_double": "丹道双倍",
	"alchemy_free": "炼丹免料", "gather_interval": "采集耗时", "seed_bonus": "灵种副产",
	"attack_pct": "攻击", "crit_chance": "会心率", "attack_interval": "攻击间隔",
	"thunder_dmg": "雷符真伤", "sword_qi": "剑气真伤", "max_hp": "最大气血",
	"defense": "防御", "trib_reduce": "天雷减伤", "ward_bonus": "护符减伤",
	"damage_reduce": "妖兽与天劫免伤",
	"meditate_xp": "吐纳修为", "heal_pct": "回血效果",
}

var _normal_root: Control
var _lock_card: PanelContainer
var _filter: String = "all"
var _filter_buttons: Dictionary = {}
var _slots_box: HBoxContainer
var _points_label: Label
var _grid: GridContainer
var _rebuild_queued: bool = false
var _is_dirty: bool = false


func _ready() -> void:
	_build()
	EventBus.technique_changed.connect(_queue_rebuild)
	EventBus.layout_changed.connect(_on_layout_changed)
	EventBus.game_loaded.connect(_queue_rebuild)
	EventBus.realm_changed.connect(_on_realm_changed_for_gate)
	visibility_changed.connect(_on_visibility_changed)
	_apply_unlock_gate()
	_refresh_filter_styles()
	rebuild()


func _is_unlocked() -> bool:
	return GameState.get_realm_index() >= UNLOCK_ORDER


func _apply_unlock_gate() -> void:
	if _normal_root == null:
		return
	var unlocked := _is_unlocked()
	_normal_root.visible = unlocked
	if _lock_card != null:
		_lock_card.visible = not unlocked


func _build_lock_card() -> PanelContainer:
	var card := ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD_DEEP,
		ThemeBuilder.COLOR_BORDER, 10, 16)
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box := ThemeBuilder.vbox(12)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(box)
	var title := ThemeBuilder.title_label("需%s · 藏经阁" % UNLOCK_LABEL,
		ThemeBuilder.FONT_CARD_TITLE)
	title.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT_TITLE_GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeBuilder.apply_font_size(title, ThemeBuilder.FONT_CARD_TITLE)
	box.add_child(title)
	var body := ThemeBuilder.wrap_label(UNLOCK_DESC, ThemeBuilder.FONT_BODY_SUB,
		ThemeBuilder.COLOR_TEXT_SECONDARY)
	ThemeBuilder.apply_font_size(body, ThemeBuilder.FONT_BODY_SUB)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(body)
	card.visible = not _is_unlocked()
	return card


func _build() -> void:
	var root := ThemeBuilder.vbox(10)
	_normal_root = root
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 10)

	var header := ThemeBuilder.card_panel()
	root.add_child(header)
	var head := ThemeBuilder.vbox(6)
	header.add_child(head)
	var title_row := ThemeBuilder.hbox(8)
	head.add_child(title_row)
	title_row.add_child(ThemeBuilder.icon_rect(IconLibrary.get_ui_icon("scripture"), 24))
	title_row.add_child(ThemeBuilder.title_label("藏经阁", 20))
	var help := ThemeBuilder.create_help_button(_show_help)
	help.custom_minimum_size = Vector2(44, 44)
	help.tooltip_text = "查看藏经阁规则"
	title_row.add_child(help)
	title_row.add_child(ThemeBuilder.expander())
	title_row.add_child(ThemeBuilder.create_seal_badge("道藏", "jade"))
	_points_label = ThemeBuilder.label("贡献 0", 14, ThemeBuilder.COLOR_AMBER)
	title_row.add_child(_points_label)
	title_row.move_child(help, -1)

	_slots_box = ThemeBuilder.hbox(6)
	head.add_child(_slots_box)

	var filter_row := ThemeBuilder.hbox(6)
	root.add_child(filter_row)
	for entry in FILTERS:
		var dict: Dictionary = entry
		var key := String(dict["key"])
		var button := ThemeBuilder.small_button(String(dict["label"]))
		button.toggle_mode = true
		button.button_pressed = key == _filter
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ThemeBuilder.apply_font_size(button, ThemeBuilder.FONT_CAPTION)
		button.pressed.connect(_on_filter_pressed.bind(key))
		filter_row.add_child(button)
		_filter_buttons[key] = button

	var scroll := ThemeBuilder.scroll_container()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 1
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_grid)

	ThemeBuilder.prepare_touch(root)
	_apply_width(EventBus.workspace_width)
	_lock_card = _build_lock_card()
	add_child(_lock_card)


func _on_layout_changed(_mode: int, _vp: Vector2, workspace: float) -> void:
	_apply_width(workspace)


func _apply_width(workspace: float) -> void:
	if _grid != null:
		_grid.columns = 2 if workspace >= 680.0 else 1
		for child in _grid.get_children():
			if child is Control:
				(child as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL


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


func _on_realm_changed_for_gate(_realm_id: String, _realm_name: String) -> void:
	_apply_unlock_gate()
	_queue_rebuild()


func _on_visibility_changed() -> void:
	if not is_visible_in_tree() or not _is_dirty:
		return
	_is_dirty = false
	_queue_rebuild()


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


# ---------------------------------------------------------------- 构建

func rebuild() -> void:
	if _grid == null:
		return
	_apply_unlock_gate()
	if not _is_unlocked():
		return
	_points_label.text = "贡献 %s" % GameFormulas.format_num(float(GameState.alliance_points))
	_rebuild_slots()
	_apply_width(EventBus.workspace_width)
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	for tech_value in DataRegistry.get_techniques_by_school(_filter):
		var tech := tech_value as TechniqueData
		var card := _build_card(tech)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_grid.add_child(card)



	# 动态重建后补挂触控约定（按钮 PASS + 14px 滑动守卫）
	ThemeBuilder.prepare_touch(self)
func _rebuild_slots() -> void:
	if _slots_box == null:
		return
	for child in _slots_box.get_children():
		_slots_box.remove_child(child)
		child.queue_free()
	var slot_count := GameState.get_technique_slots()
	var next_realm := {1: "筑基", 2: "金丹", 3: "元婴"}
	for i in range(4):
		var slot := PanelContainer.new()
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.add_theme_stylebox_override("panel", ThemeBuilder.panel_box(
			ThemeBuilder.COLOR_CARD_DEEP, ThemeBuilder.COLOR_BORDER, 8, 1, 8))
		var box := ThemeBuilder.vbox(2)
		slot.add_child(box)
		if i >= slot_count:
			box.add_child(ThemeBuilder.label(SLOT_NAMES[i], ThemeBuilder.FONT_CAPTION,
				ThemeBuilder.COLOR_TEXT_DIM))
			box.add_child(ThemeBuilder.label("%s解锁" % String(next_realm.get(i, "更高境界")), 10,
				ThemeBuilder.COLOR_TEXT_DIM))
			_slots_box.add_child(slot)
			continue
		var tech_id := String(GameState.equipped_techniques[i]) \
			if i < GameState.equipped_techniques.size() else ""
		box.add_child(ThemeBuilder.label(SLOT_NAMES[i], ThemeBuilder.FONT_CAPTION,
			ThemeBuilder.COLOR_JADE))
		if tech_id == "":
			box.add_child(ThemeBuilder.label("空闲", 11, ThemeBuilder.COLOR_TEXT_DIM))
			_slots_box.add_child(slot)
			continue
		var tech := DataRegistry.get_technique(tech_id)
		var name_label := ThemeBuilder.label(tech.name if tech != null else tech_id,
			ThemeBuilder.FONT_CAPTION)
		name_label.clip_text = true
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		ThemeBuilder.apply_technique_grade_style(name_label, tech_id)
		box.add_child(name_label)
		var off := ThemeBuilder.small_button("卸下")
		off.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
		ThemeBuilder.apply_font_size(off, ThemeBuilder.FONT_CAPTION)
		off.pressed.connect(func() -> void:
			GameState.unequip_technique(tech_id)
			_play_equip_stamp(slot)
		)
		box.add_child(off)
		_slots_box.add_child(slot)


func _build_card(tech: TechniqueData) -> PanelContainer:
	var unlocked := GameState.is_technique_unlocked(tech.id)
	var equipped := GameState.is_technique_equipped(tech.id)
	var level := GameState.get_technique_level(tech.id)
	var card := ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD, ThemeBuilder.COLOR_BORDER, 12, 12)
	if equipped:
		card.add_theme_stylebox_override("panel", ThemeBuilder.panel_box(
			ThemeBuilder.card_color(ThemeBuilder.COLOR_CARD),
			ThemeBuilder.COLOR_JADE, 12, 1, 12))
	var outer := ThemeBuilder.hbox(8)
	card.add_child(outer)
	# 轻点卡片空白处：功法背景 + 1~5 重阶梯 + 掉落秘境
	ThemeBuilder.make_card_tappable(card, func() -> void: _show_detail(tech))

	var icon := IconFrame.new()
	outer.add_child(icon)
	icon.setup(IconLibrary.get_technique_icon(tech.icon_key), 44,
		_school_color(tech.school))

	var box := ThemeBuilder.vbox(3)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(box)

	var title_row := ThemeBuilder.hbox(6)
	box.add_child(title_row)
	var tech_title := ThemeBuilder.card_title_label("《%s》" % tech.name)
	ThemeBuilder.apply_technique_grade_style(tech_title, tech.id)
	title_row.add_child(tech_title)
	title_row.add_child(ThemeBuilder.create_seal_badge(tech.school_name(),
		"gold" if tech.school == "sword" else ("jade" if tech.school == "wood" else "cinnabar")))
	title_row.add_child(ThemeBuilder.expander())
	if unlocked:
		title_row.add_child(ThemeBuilder.label("%d 重" % level, ThemeBuilder.FONT_CAPTION,
			ThemeBuilder.COLOR_JADE))

	# ② 单行当前生效加成（超出省略号），完整 1~5 重成长阶梯收进详情浮层
	var details := _effect_text(tech, 1 if not unlocked else level)
	var detail_label := ThemeBuilder.label(details, ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_PRIMARY if unlocked else ThemeBuilder.COLOR_TEXT_MUTED)
	detail_label.clip_text = true
	detail_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(detail_label)

	var actions := ThemeBuilder.hbox(6)
	box.add_child(actions)
	if not unlocked:
		if tech.is_drop_only():
			box.add_child(ThemeBuilder.dim_label("头目掉落：%s（%.0f%%）· 可贡献保底兑换" % [
				DataRegistry.get_enemy_name(tech.drop_enemy_id), tech.drop_chance * 100.0], 10))
		var cost := tech.unlock_cost_points
		var unlock_button := ThemeBuilder.small_button("兑换 · 贡献 %d" % cost)
		unlock_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ThemeBuilder.apply_font_size(unlock_button, ThemeBuilder.FONT_CAPTION)
		unlock_button.disabled = GameState.alliance_points < cost
		if not unlock_button.disabled:
			ThemeBuilder.apply_primary_button(unlock_button)
		unlock_button.pressed.connect(func() -> void: GameState.unlock_technique(tech.id))
		actions.add_child(unlock_button)
		return card

	if equipped:
		var off := ThemeBuilder.small_button("卸下")
		off.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ThemeBuilder.apply_font_size(off, ThemeBuilder.FONT_CAPTION)
		off.pressed.connect(func() -> void:
			GameState.unequip_technique(tech.id)
			_play_equip_stamp(icon)
		)
		actions.add_child(off)
	else:
		var on := ThemeBuilder.small_button("运转")
		on.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ThemeBuilder.apply_font_size(on, ThemeBuilder.FONT_CAPTION)
		on.pressed.connect(func() -> void:
			GameState.equip_technique(tech.id)
			_play_equip_stamp(icon)
		)
		actions.add_child(on)

	if level < TechniqueData.MAX_LEVEL:
		var cost := GameState.technique_upgrade_cost(tech.id)
		var check := GameState.can_upgrade_technique(tech.id)
		var up := ThemeBuilder.small_button("参悟 · %d贡献/%d灵石" % [
			int(cost["points"]), int(cost["stones"])])
		up.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ThemeBuilder.apply_font_size(up, ThemeBuilder.FONT_CAPTION)
		up.disabled = not bool(check.get("ok", false))
		if up.disabled:
			up.text = String(check.get("reason", "材料不足"))
		up.pressed.connect(GameState.upgrade_technique.bind(tech.id))
		actions.add_child(up)
	return card


func _effect_text(tech: TechniqueData, level: int) -> String:
	var parts: Array[String] = []
	for key in tech.effects.keys():
		var value := tech.get_scaled_effect(String(key), level)
		var label := String(EFFECT_LABELS.get(String(key), String(key)))
		parts.append("%s %s%.0f%%" % [label, "+" if value >= 0.0 else "", value * 100.0])
	return " · ".join(parts)


## 详情浮层：头部身份 + 当前摘要卡 + 各重进阶卡
func _show_detail(tech: TechniqueData) -> void:
	if AudioManager != null:
		AudioManager.play_tap()
	var level := GameState.get_technique_level(tech.id)
	var grade_color := ThemeBuilder.get_material_grade_color(
		int(DataRegistry.get_technique_grade(tech.id).get("tier", 1)))
	var school_color := _school_color(tech.school)
	var rows: Array = [
		{"custom": _build_current_card(tech, level)},
		{"custom": _build_progress_card(tech, level)},
	]
	if tech.is_drop_only():
		rows.append({
			"text": "掉落秘境",
			"desc": "%s（%.0f%%）" % [DataRegistry.get_enemy_name(tech.drop_enemy_id),
				tech.drop_chance * 100.0],
		})
	BottomSheet.show_detail({
		"title": "《%s》" % tech.name,
		"title_color": grade_color,
		"icon": IconLibrary.get_technique_icon(tech.icon_key),
		"icon_accent": school_color,
		"tags": [{"text": tech.school_name(), "color": school_color}],
		"rows": rows,
	})


func _build_current_card(tech: TechniqueData, level: int) -> Control:
	var card := ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD_DEEP,
		ThemeBuilder.COLOR_BORDER, 8, 12)
	var box := ThemeBuilder.vbox(6)
	card.add_child(box)

	var level_row := ThemeBuilder.hbox(6)
	box.add_child(level_row)
	level_row.add_child(ThemeBuilder.label("参悟重数", ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_SECONDARY))
	level_row.add_child(ThemeBuilder.expander())
	level_row.add_child(ThemeBuilder.label("%d / %d 重" % [level, TechniqueData.MAX_LEVEL],
		ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_JADE))

	var effect_row := ThemeBuilder.hbox(6)
	box.add_child(effect_row)
	effect_row.add_child(ThemeBuilder.label("当前效用", ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_SECONDARY))
	var effect_value := ThemeBuilder.wrap_label(
		_effect_text(tech, maxi(1, level)), ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_JADE)
	effect_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	effect_row.add_child(effect_value)

	var desc := ThemeBuilder.wrap_label(
		tech.description if tech.description != "" else "暂无记载。",
		ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_SECONDARY)
	box.add_child(desc)
	return card


func _build_progress_card(tech: TechniqueData, level: int) -> Control:
	var card := ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD_DEEP,
		ThemeBuilder.COLOR_BORDER, 8, 12)
	var box := ThemeBuilder.vbox(6)
	card.add_child(box)
	box.add_child(ThemeBuilder.section_title_label("各重进阶",
		ThemeBuilder.FONT_BODY_SUB))
	for i in range(1, TechniqueData.MAX_LEVEL + 1):
		var row := ThemeBuilder.hbox(6)
		box.add_child(row)
		var color := ThemeBuilder.COLOR_TEXT_JADE if i == level \
			else (ThemeBuilder.COLOR_TEXT_SECONDARY if i > level
				else ThemeBuilder.COLOR_TEXT_PRIMARY)
		row.add_child(ThemeBuilder.label("第 %d 重" % i, ThemeBuilder.FONT_CAPTION, color))
		row.add_child(ThemeBuilder.expander())
		var value := ThemeBuilder.wrap_label(_effect_text(tech, i),
			ThemeBuilder.FONT_CAPTION, color)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(value)
	return card


func _school_color(school: String) -> Color:
	match school:
		"sword":
			return ThemeBuilder.COLOR_AMBER
		"shield":
			return Color("#2A6B8C")
		_:
			return ThemeBuilder.COLOR_JADE


func _play_equip_stamp(anchor: Control) -> void:
	if not is_visible_in_tree() or anchor == null or InkVfxLayer.instance == null:
		return
	InkVfxLayer.instance.play_stamp(anchor.get_global_rect().get_center(),
		InkVfxLayer.INK_CINNABAR)


func _show_help() -> void:
	BottomSheet.show_help("藏经阁 · 规则", [
		{"text": "万物品阶", "bbcode": ThemeBuilder.material_grade_legend_bbcode()},
		{"text": "功法位", "desc": "功法位随大境界解锁；装配功法后立即生效，可随时切换。"},
		{"text": "参悟精进", "desc": "消耗仙盟贡献与灵石提升功法重数，效果随重数增长。"},
		{"text": "掉落与兑换", "desc": "部分高阶功法由秘境头目掉落；未解锁时也可用贡献保底兑换。"},
	])


