class_name MailPanel
extends Control
## 仙盟传书：服务端下发灵石/物资的列表与领取；未登录时只显示宣纸提示卡。

const OFFLINE_TITLE: String = "闭关独修中 · 暂未收取传书"
const EMPTY_TITLE: String = "暂无新的仙盟传书"
const LOADING_TEXT: String = "正在感应仙盟传书……"
const HELP_TEXT: String = "可在此收取掌教与仙盟下发的灵石及物资传书。领取后物资即刻入囊，并将刻入本地玉简。"

var _header: PanelContainer
var _refresh_button: Button
var _notice_box: PanelContainer
var _notice_title: Label
var _notice_body: Label
var _scroll: ScrollContainer
var _list_box: VBoxContainer
var _mails: Array = []
var _loading: bool = false
var _claim_busy_id: int = -1
var _claim_buttons: Dictionary = {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_ui()
	ThemeBuilder.prepare_touch(self)
	if not CloudSaveManager.mail_list_loaded.is_connected(_on_mail_list_loaded):
		CloudSaveManager.mail_list_loaded.connect(_on_mail_list_loaded)
	if not CloudSaveManager.mail_claimed.is_connected(_on_mail_claimed):
		CloudSaveManager.mail_claimed.connect(_on_mail_claimed)
	if not CloudSaveManager.auth_changed.is_connected(_apply_session_view):
		CloudSaveManager.auth_changed.connect(_apply_session_view)
	_apply_session_view()


func _exit_tree() -> void:
	if CloudSaveManager.mail_list_loaded.is_connected(_on_mail_list_loaded):
		CloudSaveManager.mail_list_loaded.disconnect(_on_mail_list_loaded)
	if CloudSaveManager.mail_claimed.is_connected(_on_mail_claimed):
		CloudSaveManager.mail_claimed.disconnect(_on_mail_claimed)
	if CloudSaveManager.auth_changed.is_connected(_apply_session_view):
		CloudSaveManager.auth_changed.disconnect(_apply_session_view)


func _is_logged_in() -> bool:
	return CloudSaveManager.has_token() and not CloudSaveManager.is_offline_mode


## MainShell 打开本页时调用：仅此处与手动刷新触发网络请求。
func on_panel_opened() -> void:
	_apply_session_view()
	if _is_logged_in():
		fetch_mail_list()


func _build_ui() -> void:
	var root := ThemeBuilder.vbox(10)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 10.0
	root.offset_right = -10.0
	root.offset_top = 10.0
	root.offset_bottom = -10.0
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(root)
	_header = _build_header()
	root.add_child(_header)
	_scroll = ThemeBuilder.scroll_container()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_scroll)
	_list_box = ThemeBuilder.vbox(8)
	_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_box.mouse_filter = Control.MOUSE_FILTER_PASS
	_scroll.add_child(_list_box)
	_notice_box = _build_notice_card()
	root.add_child(_notice_box)
	_scroll.visible = false


func _build_header() -> PanelContainer:
	var card := ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD, ThemeBuilder.COLOR_BORDER, 10, 10)
	var row := ThemeBuilder.hbox(8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(row)
	var title := ThemeBuilder.card_title_label("仙盟传书", ThemeBuilder.FONT_CARD_TITLE,
		ThemeBuilder.COLOR_TEXT_TITLE_GOLD)
	ThemeBuilder.apply_brush_kai(title)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ThemeBuilder.apply_font_size(title, ThemeBuilder.FONT_CARD_TITLE)
	row.add_child(title)
	_refresh_button = ThemeBuilder.small_button("刷新")
	_refresh_button.custom_minimum_size = Vector2(58, ThemeBuilder.TOUCH_MIN)
	_refresh_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	_refresh_button.pressed.connect(_on_refresh_pressed)
	row.add_child(_refresh_button)
	var help := ThemeBuilder.create_help_button(_show_help)
	help.custom_minimum_size = Vector2(44, 44)
	ThemeBuilder.apply_font_size(help, ThemeBuilder.FONT_CAPTION)
	row.add_child(help)
	return card


func _build_notice_card() -> PanelContainer:
	var card := ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD_DEEP,
		ThemeBuilder.COLOR_BORDER, 10, 16)
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var box := ThemeBuilder.vbox(10)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.custom_minimum_size = Vector2(0, 180)
	card.add_child(box)
	_notice_title = ThemeBuilder.label(OFFLINE_TITLE, ThemeBuilder.FONT_CARD_TITLE,
		ThemeBuilder.COLOR_TEXT_TITLE_GOLD)
	ThemeBuilder.apply_font_size(_notice_title, ThemeBuilder.FONT_CARD_TITLE)
	_notice_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notice_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_notice_title.clip_text = true
	box.add_child(_notice_title)
	_notice_body = ThemeBuilder.wrap_label(CloudSaveManager.MAIL_OFFLINE_TEXT,
		ThemeBuilder.FONT_BODY_SUB, ThemeBuilder.COLOR_TEXT_SECONDARY)
	ThemeBuilder.apply_font_size(_notice_body, ThemeBuilder.FONT_BODY_SUB)
	_notice_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notice_body.custom_minimum_size = Vector2(0, 60)
	box.add_child(_notice_body)
	return card


func _show_notice(title_text: String, body_text: String) -> void:
	_notice_box.visible = true
	_scroll.visible = false
	_notice_title.text = title_text
	_notice_body.text = body_text


func _show_list() -> void:
	_notice_box.visible = false
	_scroll.visible = true


func _apply_session_view() -> void:
	_claim_buttons.clear()
	_claim_busy_id = -1
	_mails.clear()
	_clear_list()
	if not _is_logged_in():
		_refresh_button.disabled = false
		_show_notice(OFFLINE_TITLE, CloudSaveManager.MAIL_OFFLINE_TEXT)
		return
	_refresh_button.disabled = false
	_show_notice(EMPTY_TITLE, "轻触右上「刷新」收取掌教与仙盟下发的物资传书。")


func fetch_mail_list() -> void:
	if not _is_logged_in():
		_show_notice(OFFLINE_TITLE, CloudSaveManager.MAIL_OFFLINE_TEXT)
		return
	if _loading:
		return
	_loading = true
	_refresh_button.disabled = true
	_show_notice("收取中", LOADING_TEXT)
	CloudSaveManager.fetch_mail_list()


func _on_refresh_pressed() -> void:
	if AudioManager != null:
		AudioManager.play_tap()
	fetch_mail_list()


func _show_help() -> void:
	BottomSheet.show_help("仙盟传书 · 说明", [
		{"text": "收取传书", "desc": HELP_TEXT},
	])


func _on_mail_list_loaded(ok: bool, mails: Array, message: String) -> void:
	_loading = false
	_refresh_button.disabled = false
	if not ok:
		_show_notice("传书暂不可读", message if message != "" else "请稍后再试。")
		return
	_mails = mails.duplicate(true)
	_claim_buttons.clear()
	_claim_busy_id = -1
	_clear_list()
	if _mails.is_empty():
		_show_notice(EMPTY_TITLE, "待掌教或仙盟下发传书后，此处会列出可领取的物资。")
		return
	_show_list()
	for value in _mails:
		if typeof(value) == TYPE_DICTIONARY:
			_list_box.add_child(_build_mail_card(value as Dictionary))


func _clear_list() -> void:
	for child in _list_box.get_children():
		_list_box.remove_child(child)
		child.queue_free()


func _build_mail_card(mail: Dictionary) -> PanelContainer:
	var card := ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD, ThemeBuilder.COLOR_BORDER, 10, 10)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := ThemeBuilder.vbox(7)
	card.add_child(box)
	box.add_child(_build_head_row(mail))
	var body := ThemeBuilder.wrap_label(String(mail.get("body", "")),
		ThemeBuilder.FONT_BODY_SUB, ThemeBuilder.COLOR_TEXT_PRIMARY)
	ThemeBuilder.apply_font_size(body, ThemeBuilder.FONT_BODY_SUB)
	body.custom_minimum_size = Vector2(0, 34)
	box.add_child(body)
	box.add_child(_build_reward_flow(mail))
	var action_row := ThemeBuilder.hbox(6)
	action_row.add_child(ThemeBuilder.expander())
	var mail_id := int(mail.get("id", 0))
	var claimed := bool(mail.get("claimed", false))
	var button: Button = ThemeBuilder.button("已领取" if claimed else "领取物资", not claimed)
	button.custom_minimum_size = Vector2(112, ThemeBuilder.TOUCH_MIN)
	button.size_flags_horizontal = Control.SIZE_SHRINK_END
	button.disabled = claimed
	ThemeBuilder.apply_font_size(button, ThemeBuilder.FONT_BODY_SUB)
	if not claimed:
		button.pressed.connect(_on_claim_pressed.bind(mail_id))
		_claim_buttons[mail_id] = button
	action_row.add_child(button)
	box.add_child(action_row)
	return card


func _build_head_row(mail: Dictionary) -> Control:
	var row := ThemeBuilder.hbox(6)
	var title := ThemeBuilder.label(String(mail.get("title", "仙盟传书")),
		ThemeBuilder.FONT_CARD_TITLE, ThemeBuilder.COLOR_TEXT_PRIMARY)
	ThemeBuilder.apply_font_size(title, ThemeBuilder.FONT_CARD_TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(title)
	var is_global := int(mail.get("target_uid", 0)) == 0
	var tag := ThemeBuilder.create_seal_badge(
		"全服同道" if is_global else "专属传书", "jade" if is_global else "gold")
	for child in tag.get_children():
		if child is Label:
			ThemeBuilder.apply_font_size(child as Label, ThemeBuilder.FONT_CAPTION)
	row.add_child(tag)
	var time_text := _format_time(int(mail.get("created_at", 0)))
	var time_label := ThemeBuilder.label(time_text, ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_DIM)
	ThemeBuilder.apply_font_size(time_label, ThemeBuilder.FONT_CAPTION)
	time_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	row.add_child(time_label)
	return row


func _build_reward_flow(mail: Dictionary) -> Control:
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 3)
	flow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var stones := maxi(0, int(mail.get("spirit_stones", 0)))
	if stones > 0:
		flow.add_child(_reward_label("灵石 ×%d" % stones, ThemeBuilder.COLOR_TEXT_GOLD))
	var items: Variant = mail.get("items", [])
	if typeof(items) == TYPE_ARRAY:
		for value in items:
			if typeof(value) != TYPE_DICTIONARY:
				continue
			var entry: Dictionary = value
			var item_id := String(entry.get("id", ""))
			var count := maxi(0, int(entry.get("count", 0)))
			if item_id == "" or count <= 0:
				continue
			flow.add_child(_reward_label("%s ×%d" % [DataRegistry.get_item_name(item_id), count],
				ThemeBuilder.COLOR_TEXT_JADE))
	if flow.get_children().is_empty():
		flow.add_child(_reward_label("附礼：无", ThemeBuilder.COLOR_TEXT_DIM))
	return flow


func _reward_label(text_value: String, color: Color) -> Label:
	var label := ThemeBuilder.label(text_value, ThemeBuilder.FONT_BODY_SUB, color)
	ThemeBuilder.apply_font_size(label, ThemeBuilder.FONT_BODY_SUB)
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return label


func _on_claim_pressed(mail_id: int) -> void:
	if _claim_busy_id >= 0:
		return
	_claim_busy_id = mail_id
	var button: Button = _claim_buttons.get(mail_id, null)
	if button != null:
		button.disabled = true
		button.text = "领取中"
	CloudSaveManager.claim_mail(mail_id)


func _on_mail_claimed(ok: bool, mail_id: int, reward: Dictionary, message: String) -> void:
	_claim_busy_id = -1
	if ok:
		_credit_reward(reward)
		_mark_claimed(mail_id)
		if CloudSaveManager.has_method("set_unread_mail_count"):
			var unread_value: Variant = CloudSaveManager.get("unread_mail_count")
			var unread_count := 0 if unread_value == null else int(unread_value)
			CloudSaveManager.set_unread_mail_count(maxi(0, unread_count - 1))
		EventBus.toast.emit("已收下仙盟传书：" + _reward_summary(reward))
		return
	# 服务端判定已领：本地卡片同步为已领取，避免重复点击
	if message.contains("已领取"):
		_mark_claimed(mail_id)
		EventBus.toast.emit("该传书物资已领取")
		return
	var button: Button = _claim_buttons.get(mail_id, null)
	if button != null:
		button.disabled = false
		button.text = "领取物资"
	EventBus.toast.emit(message if message != "" else "领取失败，请稍后再试")


func _credit_reward(reward: Dictionary) -> void:
	var stones := maxi(0, int(reward.get("spirit_stones", 0)))
	var parts: Array[String] = []
	GameState.begin_batch()
	if stones > 0:
		GameState.add_item(DataRegistry.SPIRIT_STONE, stones)
		parts.append("灵石 ×%d" % stones)
	var items: Variant = reward.get("items", [])
	if typeof(items) == TYPE_ARRAY:
		for value in items:
			if typeof(value) != TYPE_DICTIONARY:
				continue
			var entry: Dictionary = value
			var item_id := String(entry.get("id", ""))
			var count := maxi(0, int(entry.get("count", 0)))
			if item_id == "" or count <= 0:
				continue
			if DataRegistry.get_item(item_id) == null:
				push_warning("仙盟传书含未知物品 ID，已跳过：" + item_id)
				continue
			GameState.add_item(item_id, count)
			parts.append("%s ×%d" % [DataRegistry.get_item_name(item_id), count])
	GameState.end_batch()
	SaveManager.save_game(false)
	if parts.is_empty():
		parts.append("无附带物资")


func _reward_summary(reward: Dictionary) -> String:
	var parts: Array[String] = []
	var stones := maxi(0, int(reward.get("spirit_stones", 0)))
	if stones > 0:
		parts.append("灵石 ×%d" % stones)
	var items: Variant = reward.get("items", [])
	if typeof(items) == TYPE_ARRAY:
		for value in items:
			if typeof(value) != TYPE_DICTIONARY:
				continue
			var entry: Dictionary = value
			var item_id := String(entry.get("id", ""))
			var count := maxi(0, int(entry.get("count", 0)))
			if item_id != "" and count > 0 and DataRegistry.get_item(item_id) != null:
				parts.append("%s ×%d" % [DataRegistry.get_item_name(item_id), count])
	return " · ".join(parts) if not parts.is_empty() else "无附带物资"


func _mark_claimed(mail_id: int) -> void:
	for value in _mails:
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var mail: Dictionary = value
		if int(mail.get("id", 0)) == mail_id:
			mail["claimed"] = true
	_clear_list()
	for value in _mails:
		if typeof(value) == TYPE_DICTIONARY:
			_list_box.add_child(_build_mail_card(value as Dictionary))
	_show_list()


func _format_time(unix_time: int) -> String:
	if unix_time <= 0:
		return "—"
	var dict := Time.get_datetime_dict_from_unix_time(unix_time)
	return "%02d-%02d %02d:%02d" % [int(dict.get("month", 0)), int(dict.get("day", 0)),
		int(dict.get("hour", 0)), int(dict.get("minute", 0))]
