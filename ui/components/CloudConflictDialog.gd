class_name CloudConflictDialog
extends Control
## 玉简云篆冲突仲裁：本地 / 云端双卡对比 + 二选一。
## 最大宽 410px，450 竖屏左右各留 20px；所有按钮等宽 + clip_text。

signal closed

var _card: PanelContainer
var _title_label: Label
var _desc_label: Label
var _hint_label: Label
var _local_values: Dictionary = {}
var _cloud_values: Dictionary = {}
var _cloud_block: PanelContainer
var _buttons: GridContainer
var _read_button: Button
var _keep_button: Button
var _busy: bool = false
var _confirm_only: bool = false
var _mode: String = "conflict"


func _ready() -> void:
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.color = Color(0.17, 0.165, 0.149, 0.44)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_card = ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD, ThemeBuilder.COLOR_BORDER, 14, 14)
	_card.clip_contents = true
	_card.custom_minimum_size = Vector2(410, 0)
	center.add_child(_card)
	var box := ThemeBuilder.vbox(10)
	_card.add_child(box)

	_title_label = ThemeBuilder.card_title_label("玉简云篆冲突",
		ThemeBuilder.FONT_CARD_TITLE, ThemeBuilder.COLOR_TEXT_TITLE_GOLD)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_title_label)

	_desc_label = ThemeBuilder.wrap_label(
		"检测到云端玉简与当前本地修行进度不一致，请选择要保留的存档：",
		ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_SECONDARY)
	_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_desc_label)

	var local_block := _make_info_block("本地玉简", false)
	box.add_child(local_block["panel"])
	_local_values = local_block["values"]

	var cloud_block := _make_info_block("云端玉简", true)
	_cloud_block = cloud_block["panel"]
	box.add_child(_cloud_block)
	_cloud_values = cloud_block["values"]

	_hint_label = ThemeBuilder.wrap_label("", ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_DANGER)
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.custom_minimum_size = Vector2(0, 20)
	box.add_child(_hint_label)

	var buttons := GridContainer.new()
	buttons.columns = 2
	buttons.add_theme_constant_override("h_separation", 12)
	buttons.add_theme_constant_override("v_separation", 10)
	_buttons = buttons
	box.add_child(buttons)

	_read_button = ThemeBuilder.button("读取云端覆盖本地")
	_read_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_read_button.custom_minimum_size = Vector2(0, 46)
	ThemeBuilder.apply_font_size(_read_button, ThemeBuilder.FONT_CAPTION)
	ThemeBuilder.clip_button_text(_read_button, "读取云端覆盖本地")
	ThemeBuilder.apply_primary_button(_read_button)
	_read_button.pressed.connect(_on_read_cloud_pressed)
	buttons.add_child(_read_button)

	_keep_button = ThemeBuilder.button("以本地覆盖云端")
	_keep_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_keep_button.custom_minimum_size = Vector2(0, 46)
	ThemeBuilder.apply_font_size(_keep_button, ThemeBuilder.FONT_CAPTION)
	ThemeBuilder.clip_button_text(_keep_button, "以本地覆盖云端")
	_apply_gold_button(_keep_button)
	_keep_button.pressed.connect(_on_keep_local_pressed)
	buttons.add_child(_keep_button)


func _make_info_block(title_text: String, with_time: bool) -> Dictionary:
	var panel := ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD_DEEP,
		ThemeBuilder.COLOR_BORDER, 10, 10)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := ThemeBuilder.vbox(5)
	panel.add_child(box)
	var head := ThemeBuilder.card_title_label(title_text, ThemeBuilder.FONT_BODY_SUB,
		ThemeBuilder.COLOR_AMBER)
	box.add_child(head)

	var rows: Array = [
		["realm", "境界"], ["stones", "灵石"], ["play", "修行时长"], ["rev", "版本"],
	]
	if with_time:
		rows.append(["time", "云端保存"])
	var values := {}
	for entry in rows:
		var key := String(entry[0])
		var row := ThemeBuilder.hbox(8)
		var name_label := ThemeBuilder.dim_label(String(entry[1]), ThemeBuilder.FONT_CAPTION)
		name_label.custom_minimum_size = Vector2(66, 0)
		row.add_child(name_label)
		var value_label := ThemeBuilder.label("—", ThemeBuilder.FONT_CAPTION,
			ThemeBuilder.COLOR_TEXT_PRIMARY)
		value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_label.clip_text = true
		value_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		row.add_child(value_label)
		box.add_child(row)
		values[key] = value_label
	return {"panel": panel, "values": values}


func _apply_gold_button(button: Button) -> void:
	var normal := ThemeBuilder.panel_box(ThemeBuilder.COLOR_AMBER,
		ThemeBuilder.COLOR_AMBER.darkened(0.12), 8, 1, 10)
	var hover := ThemeBuilder.panel_box(ThemeBuilder.COLOR_AMBER.lightened(0.08),
		ThemeBuilder.COLOR_AMBER, 8, 1, 10)
	var pressed_box := ThemeBuilder.panel_box(ThemeBuilder.COLOR_AMBER.darkened(0.10),
		ThemeBuilder.COLOR_AMBER.darkened(0.18), 8, 1, 10)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed_box)
	button.add_theme_color_override("font_color", ThemeBuilder.COLOR_CARD)
	button.add_theme_color_override("font_hover_color", ThemeBuilder.COLOR_CARD)
	button.add_theme_color_override("font_pressed_color", ThemeBuilder.COLOR_CARD)


func show_conflict(local_summary: Dictionary, cloud_summary: Dictionary,
		confirm_only: bool = false) -> void:
	_mode = "conflict"
	_confirm_only = confirm_only
	_busy = false
	var width := minf(410.0, get_viewport_rect().size.x - 40.0)
	_card.custom_minimum_size = Vector2(maxf(300.0, width), 0)
	_title_label.text = "玉简云篆冲突"
	_cloud_block.visible = true
	_fill_block(_local_values, local_summary, false)
	_fill_block(_cloud_values, cloud_summary, true)
	_hint_label.text = ""
	_desc_label.text = "确认以云端玉简覆盖当前本地修行进度？" if confirm_only \
		else "检测到云端玉简与当前本地修行进度不一致，请选择要保留的存档："
	_buttons.columns = 2
	_read_button.text = "读取云端覆盖本地"
	_keep_button.text = "暂不覆盖" if confirm_only else "以本地覆盖云端"
	ThemeBuilder.apply_primary_button(_read_button)
	_apply_gold_button(_keep_button)
	_read_button.tooltip_text = "读取云端覆盖本地"
	_keep_button.tooltip_text = _keep_button.text
	_read_button.disabled = false
	_keep_button.disabled = false
	visible = true
	move_to_front()


## 新账号云端无档，但本地已有他号/离线进度：强制二选一，禁止静默上传。
func show_new_account(local_summary: Dictionary) -> void:
	_mode = "new_account"
	_confirm_only = false
	_busy = false
	var width := minf(410.0, get_viewport_rect().size.x - 40.0)
	_card.custom_minimum_size = Vector2(maxf(300.0, width), 0)
	_title_label.text = "新仙籍启程确认"
	_cloud_block.visible = false
	_fill_block(_local_values, local_summary, false)
	_hint_label.text = ""
	_desc_label.text = "当前设备存有其他道号或闭关独修的本地进度，而本账号云端尚无档案。请选择如何处置："
	_buttons.columns = 1
	_read_button.text = "重头修行（新建空白档）"
	_keep_button.text = "继承本地进度并上云"
	ThemeBuilder.apply_secondary_button(_read_button, true)
	_apply_gold_button(_keep_button)
	_read_button.tooltip_text = "清空本地进度，以炼气一层重新开始"
	_keep_button.tooltip_text = "把当前本地进度作为本账号首版上传"
	_read_button.disabled = false
	_keep_button.disabled = false
	visible = true
	move_to_front()


func _fill_block(values: Dictionary, summary: Dictionary, with_time: bool) -> void:
	(values["realm"] as Label).text = String(summary.get("realm_name", "未知"))
	(values["stones"] as Label).text = String(summary.get("spirit_stones", "0"))
	(values["play"] as Label).text = _format_duration(
		int(summary.get("play_seconds", 0)))
	(values["rev"] as Label).text = _format_rev(int(summary.get("save_rev", 0)))
	if with_time:
		(values["time"] as Label).text = _format_time(
			int(summary.get("updated_at", 0)))


func _format_duration(seconds: int) -> String:
	var total := maxi(0, seconds)
	var hours := total / 3600
	var minutes := (total % 3600) / 60
	if hours > 0:
		return "%d时%d分" % [hours, minutes]
	return "%d分" % minutes


func _format_time(unix_time: int) -> String:
	if unix_time <= 0:
		return "尚未同步"
	var dt := Time.get_datetime_dict_from_unix_time(unix_time)
	return "%04d-%02d-%02d %02d:%02d" % [int(dt["year"]), int(dt["month"]),
		int(dt["day"]), int(dt["hour"]), int(dt["minute"])]


func _format_rev(rev: int) -> String:
	return "尚未同步" if rev <= 0 else "第 %d 版" % rev


func _on_read_cloud_pressed() -> void:
	if _busy:
		return
	if _mode == "new_account":
		_set_busy(true, "重置中...", "")
		var reset_result := await CloudSaveManager.resolve_new_account_choice(true)
		if not is_inside_tree():
			return
		if bool(reset_result.get("ok", false)):
			visible = false
			_set_busy(false)
			EventBus.toast.emit("已重头修行并建立云端首版")
			closed.emit()
			return
		_set_busy(false)
		_hint_label.text = String(reset_result.get("message", "建立云端首版失败"))
		return
	_set_busy(true, "读取中...", "")
	var result := await CloudSaveManager.download_save()
	if not is_inside_tree():
		return
	if bool(result.get("ok", false)):
		CloudSaveManager.clear_conflict()
		visible = false
		_set_busy(false)
		EventBus.toast.emit("已读取云端玉简")
		closed.emit()
		return
	_set_busy(false)
	_hint_label.text = String(result.get("message", "读取云端玉简失败"))


func _on_keep_local_pressed() -> void:
	if _busy:
		return
	if _confirm_only:
		visible = false
		closed.emit()
		return
	_set_busy(true, "", "上传中...")
	var result := {}
	if _mode == "new_account":
		result = await CloudSaveManager.resolve_new_account_choice(false)
	else:
		result = await CloudSaveManager.upload_save(true)
	if not is_inside_tree():
		return
	if bool(result.get("ok", false)):
		CloudSaveManager.clear_conflict()
		visible = false
		_set_busy(false)
		EventBus.toast.emit("已将本地进度覆写至云端" if _mode == "conflict"
			else "已将本地进度继承为新账号首版")
		closed.emit()
		return
	_set_busy(false)
	_hint_label.text = String(result.get("message", "覆写云端玉简失败"))


func _set_busy(value: bool, read_text: String = "", keep_text: String = "") -> void:
	_busy = value
	_read_button.disabled = value
	_keep_button.disabled = value
	if read_text != "":
		_read_button.text = read_text
	if keep_text != "":
		_keep_button.text = keep_text
	if not value:
		if _mode == "new_account":
			_read_button.text = "重头修行（新建空白档）"
			_keep_button.text = "继承本地进度并上云"
		else:
			_read_button.text = "读取云端覆盖本地"
			_keep_button.text = "暂不覆盖" if _confirm_only else "以本地覆盖云端"
