class_name OfflineReportModal
extends Control
## 「闭关收益玉简」离线结算汇总弹窗。
## 高度随内容自适应：收获列表滚动区最矮 MIN_CONTENT_HEIGHT、最高 MAX_CONTENT_HEIGHT，
## 内容少时弹窗紧凑贴合，内容多时交由滚动区完整查看。

## 收获列表滚动区最大高度（px）：超出改滚动，450×800 竖屏不越界
const MAX_CONTENT_HEIGHT: float = 360.0
## 收获过少时滚动区保底高度（玉简形制不塌成一条）
const MIN_CONTENT_HEIGHT: float = 96.0

var _title_label: Label
var _subtitle_label: Label
var _content: VBoxContainer
var _panel: PanelContainer
var _scroll: ScrollContainer
var _dim: ColorRect
## 弹出序号：连点/连发时只让最新一次落地，旧协程直接作废
var _show_token: int = 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build()
	_refresh_panel_width()
	if get_viewport() != null:
		get_viewport().size_changed.connect(_refresh_panel_width)


## 玉简宽度自适应：桌面 480，窄屏让出 24px 边距（450 竖屏不再横向溢出）
func _refresh_panel_width() -> void:
	if _panel == null:
		return
	var vw := get_viewport_rect().size.x
	_panel.custom_minimum_size.x = minf(480.0, maxf(300.0, vw - 24.0))


func _build() -> void:
	var dim := ColorRect.new()
	_dim = dim
	dim.color = Color(0.12, 0.10, 0.08, 0.42)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(480, 0)
	# 宽度在 _ready 末尾按视口宽度收口（450 竖屏自适应到 426）
	# 垂直居中自适应内容高度：面板高度只由内容决定，不写死固定高度
	_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_panel.add_theme_stylebox_override("panel",
		ThemeBuilder.panel_box(ThemeBuilder.COLOR_CARD, ThemeBuilder.COLOR_JADE, 12, 1, 18))
	center.add_child(_panel)

	var box := ThemeBuilder.vbox(10)
	_panel.add_child(box)

	var head := ThemeBuilder.hbox(10)
	box.add_child(head)
	_title_label = ThemeBuilder.title_label("闭关收益玉简", 20)
	head.add_child(_title_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(spacer)
	_subtitle_label = ThemeBuilder.dim_label("", ThemeBuilder.FONT_BODY_SUB)
	head.add_child(_subtitle_label)

	box.add_child(ThemeBuilder.separator(1, ThemeBuilder.COLOR_BORDER))

	_scroll = ThemeBuilder.scroll_container()
	# 只按下方算出的收口高度排版，绝不被内容反向撑大
	_scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	box.add_child(_scroll)
	_content = ThemeBuilder.vbox(10)
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_content)

	box.add_child(ThemeBuilder.separator(1, ThemeBuilder.COLOR_BORDER))

	# 底栏：全宽主按钮（技术说明已移除，单手点击友好）
	var close_button := ThemeBuilder.button("收下此玉简")
	close_button.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
	close_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ThemeBuilder.apply_font_size(close_button, ThemeBuilder.FONT_CARD_TITLE)
	ThemeBuilder.apply_brush_kai(close_button)
	close_button.pressed.connect(_on_dismiss_pressed)
	box.add_child(close_button)


func _on_dismiss_pressed() -> void:
	# 通用按钮已挂轻敲音；这里显式补一次，避免弹窗立即 hide 时被误认为静音
	if AudioManager != null:
		AudioManager.play_click()
	# 居中玉简缩放收起（0.16s）后隐藏
	ThemeBuilder.animate_modal_close(_panel, _dim, hide, false)


func show_report(report: Dictionary) -> void:
	# 宽屏居中且限制最大宽度，窄屏自适应留边
	var vp_w := get_viewport_rect().size.x
	if _panel != null:
		_panel.custom_minimum_size = Vector2(minf(540.0, maxf(320.0, vp_w * 0.92)), 0)
	if _content == null:
		_build()
	_clear_content()

	var simulated := bool(report.get("simulated", false))
	_title_label.text = "推演闭关" if simulated else "闭关收益玉简"
	_subtitle_label.text = "闭关 %s" % String(report.get("settled_text", "0 秒"))

	var c_label := ThemeBuilder.hex(ThemeBuilder.COLOR_TEXT_SECONDARY)
	var c_value := ThemeBuilder.hex(ThemeBuilder.COLOR_TEXT_PRIMARY)
	var c_jade := ThemeBuilder.hex(ThemeBuilder.COLOR_TEXT_JADE)
	var c_gold := ThemeBuilder.hex(ThemeBuilder.COLOR_TEXT_GOLD)
	var overview: Array[String] = []
	# 时长在标题行右侧已展示，总览不重复；仅被上限截断时补一行说明
	var duration_text := String(report.get("duration_text", ""))
	var settled_text := String(report.get("settled_text", ""))
	if duration_text != "" and duration_text != settled_text:
		overview.append("[color=%s]闭关上限：[/color][color=%s]已按 %d 小时上限折算[/color]" % [
			c_label, c_gold, int(report.get("cap_hours", 12))])
	# 境界行仅在真正突破时出现（杜绝「A → A」无效占位）
	var realm_before := String(report.get("realm_before", ""))
	var realm_after := String(report.get("realm_after", ""))
	if realm_before != realm_after and realm_after != "":
		overview.append("[color=%s]境界突破：[/color][color=%s]%s → %s[/color]" % [
			c_label, c_jade, realm_before, realm_after])
	if not overview.is_empty():
		_add_section("总览", overview)

	var cultivation := int(report.get("cultivation", 0))
	if cultivation > 0:
		_add_section("境界修为", ["[color=%s]吐纳所获修为：[/color][color=%s]+%s[/color]" % [
			c_label, c_jade, GameFormulas.format_num(float(cultivation))]])

	var skills: Array = report.get("skills", [])
	if not skills.is_empty():
		var lines: Array[String] = []
		for row in skills:
			var data: Dictionary = row
			var from_level := int(data.get("from", 1))
			var to_level := int(data.get("to", 1))
			var level_text := "%d 重" % from_level
			if to_level > from_level:
				level_text = "%d 重 → %d 重" % [from_level, to_level]
			lines.append("[color=%s]%s：[/color][color=%s]+%s 经验[/color][color=%s]（%s）[/color]" % [
				c_label, String(data.get("name", "")),
				c_value, GameFormulas.format_num(float(data.get("xp", 0.0))),
				c_jade, level_text,
			])
		_add_section("技能精进", lines)

	var items: Array = report.get("items", [])
	if items.is_empty():
		# 全空态：单行提示，不堆空卡片
		_content.add_child(ThemeBuilder.wrap_label(
			"闭关期间未运转百艺或秘境，静心养神。",
			ThemeBuilder.FONT_BODY_SUB, ThemeBuilder.COLOR_TEXT_SECONDARY))
	else:
		var loot_card := ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD_DEEP,
			ThemeBuilder.COLOR_BORDER, 8, 10)
		_content.add_child(loot_card)
		var loot_box := ThemeBuilder.vbox(6)
		loot_card.add_child(loot_box)
		loot_box.add_child(ThemeBuilder.card_title_label("储物袋入账",
			ThemeBuilder.FONT_CARD_TITLE, ThemeBuilder.COLOR_AMBER))
		var loot_rows: Array = []
		for row in items:
			var data: Dictionary = row
			loot_rows.append(data)
		# 奇珍置顶 → 其余按品阶从高到低
		loot_rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			var ia := _find_item_id(String(a.get("name", "")))
			var ib := _find_item_id(String(b.get("name", "")))
			var ra := 1 if (ia == DataRegistry.SPIRIT_DEW or ia == DataRegistry.CRIMSON_FRUIT) else 0
			var rb := 1 if (ib == DataRegistry.SPIRIT_DEW or ib == DataRegistry.CRIMSON_FRUIT) else 0
			if ra != rb:
				return ra > rb
			return int(DataRegistry.get_item_grade(ia).get("tier", 0)) \
				> int(DataRegistry.get_item_grade(ib).get("tier", 0)))
		for data in loot_rows:
			loot_box.add_child(_build_loot_row(
				String(data.get("name", "")), int(data.get("amount", 0))))

	var farm_note := String(report.get("farm_note", ""))
	if farm_note != "":
		_add_section("洞府灵田", [farm_note], ThemeBuilder.COLOR_JADE)

	var combat: Dictionary = report.get("combat", {})
	if not combat.is_empty():
		var combat_lines: Array[String] = []
		combat_lines.append("秘境目标：%s" % String(combat.get("enemy_name", "-")))
		combat_lines.append("击杀数：%d" % int(combat.get("kills", 0)))
		combat_lines.append("消耗回春散：%d" % int(combat.get("potions_used", 0)))
		if int(combat.get("talismans_used", 0)) > 0:
			combat_lines.append("消耗厚土护身符：%d" % int(combat.get("talismans_used", 0)))
		_add_section("秘境历练", combat_lines)

	var notes: Array = report.get("notes", [])
	if not notes.is_empty():
		var note_lines: Array[String] = []
		for note in notes:
			note_lines.append("· %s" % String(note))
		_add_section("注记", note_lines, ThemeBuilder.COLOR_CINNABAR)

	# 高度自适应：内容少时贴合包裹，多时以 MAX_CONTENT_HEIGHT 封顶并由滚动区承接。
	# 必须先隐形上屏再量高——未 show 时容器不排版，自换行文本会按近 0 宽折行、
	# min_size 虚高数倍，内容只有一行也会撑出半屏大空洞。
	_show_token += 1
	var token := _show_token
	_panel.modulate.a = 0.0
	_dim.modulate.a = 0.0
	show()
	move_to_front()
	_scroll.custom_minimum_size = Vector2(0, 0)
	var need := 0.0
	var prev := -1.0
	for i in range(8):
		await get_tree().process_frame
		if token != _show_token or not is_inside_tree() or _content == null or _scroll == null:
			return
		need = _content.get_combined_minimum_size().y
		# 连续两帧量高一致即认为排版收敛（至少等 3 帧）
		if i >= 2 and absf(need - prev) < 0.5:
			break
		prev = need
	_scroll.custom_minimum_size = Vector2(0, clampf(need + 4.0, MIN_CONTENT_HEIGHT, MAX_CONTENT_HEIGHT))
	ThemeBuilder.prepare_touch(_content)
	# 居中玉简弹性舒展开启（0.22s BACK）；alpha 由此动画从 0 淡入，中间态不可见
	ThemeBuilder.animate_modal_open(_panel, _dim, false)


## 按显示名反查物品 ID（report.items 只带 name/amount）
func _find_item_id(display_name: String) -> String:
	for key in DataRegistry.items.keys():
		var item = DataRegistry.get_item(String(key))
		if item != null and item.display_name == display_name:
			return String(key)
	return ""


## 单行战利品：图标 + 品阶名 + 右侧「×数量 (存总数)」同行拆色
func _build_loot_row(display_name: String, amount: int) -> Control:
	var item_id := _find_item_id(display_name)
	var row := ThemeBuilder.hbox(8)
	row.custom_minimum_size = Vector2(0, 40)
	row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := TextureRect.new()
	if item_id != "":
		icon.texture = IconLibrary.get_item_icon(item_id)
	icon.custom_minimum_size = Vector2(28, 28)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var name_lbl := ThemeBuilder.label(display_name, ThemeBuilder.FONT_BODY_SUB)
	if item_id != "":
		ThemeBuilder.apply_item_grade_style(name_lbl, item_id)
	row.add_child(name_lbl)
	row.add_child(ThemeBuilder.expander())
	# 双 Label 拆色（RichTextLabel 最小宽≈0 会逐字换行撑爆行高，禁用）
	var count_box := ThemeBuilder.hbox(4)
	count_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	count_box.add_child(ThemeBuilder.label("×%s" % GameFormulas.format_num(float(amount)),
		ThemeBuilder.FONT_BODY_SUB, ThemeBuilder.COLOR_TEXT_PRIMARY))
	count_box.add_child(ThemeBuilder.label("(存%s)" % (
		GameFormulas.format_num(float(GameState.get_item_count(item_id))) \
			if item_id != "" else "-"),
		ThemeBuilder.FONT_BODY_SUB, ThemeBuilder.COLOR_TEXT_SECONDARY))
	row.add_child(count_box)
	return row


func _add_section(title_text: String, lines: Array, color: Color = ThemeBuilder.COLOR_TEXT) -> void:
	var card := ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD_DEEP, ThemeBuilder.COLOR_BORDER, 8, 10)
	_content.add_child(card)
	var box := ThemeBuilder.vbox(4)
	card.add_child(box)
	box.add_child(ThemeBuilder.card_title_label(title_text,
		ThemeBuilder.FONT_CARD_TITLE, ThemeBuilder.COLOR_AMBER))
	for line in lines:
		# 离线收获行中的材料/灵种名按品阶着色（长名优先，避免子串误伤）
		var rich := ThemeBuilder.bbcode_label(
			ThemeBuilder.colorize_item_names_bbcode(String(line)),
			ThemeBuilder.FONT_BODY_SUB)
		rich.add_theme_color_override("default_color", color)
		box.add_child(rich)


func _clear_content() -> void:
	# 先摘出树再释放：同帧内旧节点不会继续参与容器最小尺寸计算
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()


