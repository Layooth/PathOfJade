class_name LeaderboardPanel
extends Control
## 天道榜：三榜页签（境界 / 镇魔塔 / 灵石）+ 我的名次置顶摘要 + 轻量排行列表。
## 只在打开面板或手动刷新时请求；列表与摘要完全由服务端数据驱动。

const BOARD_REALM: String = "realm"
const BOARD_TOWER: String = "tower"
const BOARD_STONES: String = "stones"
const REFRESH_COOLDOWN_MS: int = 10000
const ROW_MARGIN: int = 8
const LIST_WIDTH: float = 344.0

const LOADING_TEXT: String = "正在感应天道名录……"
const OFFLINE_TITLE: String = "闭关独修中 · 暂未观榜"
const OFFLINE_BODY: String = "当前处于离线闭关状态，无法感应诸天同道名录。登录仙籍后即可观览境界、镇魔塔与灵石三榜，并记入自身名次。"
const EMPTY_TEXT: String = "尚无同道上榜，同步云篆后即可入榜"
const RETRY_HINT: String = "请核对灵脉后轻触右上「刷新」重试。"

var _current_board: String = BOARD_REALM
var _tabs: Dictionary = {}
var _tabs_container: HBoxContainer
var _list_box: VBoxContainer
var _scroll: ScrollContainer
var _my_rank_box: PanelContainer
var _my_rank_label: Label
var _my_value_label: Label
var _notice_box: PanelContainer
var _notice_title: Label
var _notice_body: Label
var _notice_button: Button
var _refresh_button: Button
var _cache: Dictionary = {}
var _is_loading: bool = false
var _last_request_ms: int = -REFRESH_COOLDOWN_MS


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_ui()
	_apply_trim_to_tree(self)
	ThemeBuilder.prepare_touch(self)
	if not CloudSaveManager.leaderboard_loaded.is_connected(_on_leaderboard_loaded):
		CloudSaveManager.leaderboard_loaded.connect(_on_leaderboard_loaded)
	if not CloudSaveManager.auth_changed.is_connected(_apply_session_view):
		CloudSaveManager.auth_changed.connect(_apply_session_view)
	_apply_session_view()


func _exit_tree() -> void:
	if CloudSaveManager.leaderboard_loaded.is_connected(_on_leaderboard_loaded):
		CloudSaveManager.leaderboard_loaded.disconnect(_on_leaderboard_loaded)
	if CloudSaveManager.auth_changed.is_connected(_apply_session_view):
		CloudSaveManager.auth_changed.disconnect(_apply_session_view)


func _is_logged_in() -> bool:
	return CloudSaveManager.has_token() and not CloudSaveManager.is_offline_mode


## 由 MainShell 在切到本页时调用，仅此处/手动刷新触发请求，无后台轮询。
func on_panel_opened() -> void:
	_apply_session_view()
	if _is_logged_in():
		_request_board(_current_board, false)


func _build_ui() -> void:
	var root := ThemeBuilder.vbox(10)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 10.0
	root.offset_right = -10.0
	root.offset_top = 10.0
	root.offset_bottom = -10.0
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(root)

	root.add_child(_build_header())
	_tabs_container = _build_tabs()
	root.add_child(_tabs_container)
	_my_rank_box = _build_my_rank_card()
	root.add_child(_my_rank_box)

	_scroll = ThemeBuilder.scroll_container()
	_scroll.custom_minimum_size = Vector2(LIST_WIDTH, 0)
	root.add_child(_scroll)
	_list_box = ThemeBuilder.vbox(8)
	_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_box.mouse_filter = Control.MOUSE_FILTER_PASS
	_scroll.add_child(_list_box)

	# 所有非有榜状态共用同一张根节点提示卡；空 ScrollContainer 一律整块隐藏
	_notice_box = _build_notice_card()
	root.add_child(_notice_box)


func _build_header() -> PanelContainer:
	var card := ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD, ThemeBuilder.COLOR_BORDER, 10, 10)
	var title_row := ThemeBuilder.hbox(8)
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(title_row)
	var title := ThemeBuilder.card_title_label("天道榜", ThemeBuilder.FONT_CARD_TITLE,
		ThemeBuilder.COLOR_TEXT_TITLE_GOLD)
	ThemeBuilder.apply_brush_kai(title)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)
	# 单行右侧：紧凑「刷新」+ 最右唯一问号；未登录时刷新由状态机隐藏
	_refresh_button = ThemeBuilder.small_button("刷新")
	_refresh_button.custom_minimum_size = Vector2(58, ThemeBuilder.TOUCH_MIN)
	_refresh_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	ThemeBuilder.clip_button_text(_refresh_button, "刷新天道榜（10 息内仅一次）")
	_refresh_button.pressed.connect(_on_refresh_pressed)
	title_row.add_child(_refresh_button)
	var help_button := ThemeBuilder.create_help_button(_show_help)
	help_button.custom_minimum_size = Vector2(44, 44)
	ThemeBuilder.apply_font_size(help_button, ThemeBuilder.FONT_CAPTION)
	title_row.add_child(help_button)
	return card


func _build_tabs() -> HBoxContainer:
	var tabs := ThemeBuilder.hbox(6)
	tabs.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
	for def in [["realm", "境界榜"], ["tower", "镇魔塔"], ["stones", "灵石榜"]]:
		var kind := String(def[0])
		var btn := ThemeBuilder.small_button(String(def[1]))
		btn.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ThemeBuilder.clip_button_text(btn, String(def[1]))
		btn.pressed.connect(_on_tab_pressed.bind(kind))
		tabs.add_child(btn)
		_tabs[kind] = btn
	_refresh_tab_styles()
	return tabs


func _build_my_rank_card() -> PanelContainer:
	var card := ThemeBuilder.card_panel(ThemeBuilder.COLOR_JADE_PAPER,
		ThemeBuilder.COLOR_JADE_SOFT, 10, 10)
	var row := ThemeBuilder.hbox(8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(row)
	_my_rank_label = _make_label("暂未上榜，同步云篆后入榜", ThemeBuilder.FONT_BODY,
		ThemeBuilder.COLOR_TEXT_GOLD)
	_my_rank_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_my_rank_label)
	_my_value_label = _make_label("", ThemeBuilder.FONT_BODY_SUB, ThemeBuilder.COLOR_TEXT_SECONDARY)
	_my_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_my_value_label.custom_minimum_size = Vector2(104, 0)
	_my_value_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	row.add_child(_my_value_label)
	return card


func _build_notice_card() -> PanelContainer:
	var card := ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD_DEEP,
		ThemeBuilder.COLOR_BORDER, 10, 16)
	card.name = "NoticeCard"
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var box := ThemeBuilder.vbox(10)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.custom_minimum_size = Vector2(0, 180)
	card.add_child(box)
	_notice_title = ThemeBuilder.label(OFFLINE_TITLE, ThemeBuilder.FONT_CARD_TITLE,
		ThemeBuilder.COLOR_TEXT_TITLE_GOLD)
	ThemeBuilder.apply_font_size(_notice_title, ThemeBuilder.FONT_CARD_TITLE)
	_notice_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_notice_title)
	_notice_body = ThemeBuilder.wrap_label(OFFLINE_BODY, ThemeBuilder.FONT_BODY_SUB,
		ThemeBuilder.COLOR_TEXT_SECONDARY)
	ThemeBuilder.apply_font_size(_notice_body, ThemeBuilder.FONT_BODY_SUB)
	_notice_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notice_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_notice_body.custom_minimum_size = Vector2(0, 60)
	box.add_child(_notice_body)
	_notice_button = ThemeBuilder.button("前往登录仙籍", true)
	ThemeBuilder.apply_font_size(_notice_button, ThemeBuilder.FONT_BODY)
	_notice_button.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
	_notice_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ThemeBuilder.clip_button_text(_notice_button, "前往登录仙籍")
	_notice_button.pressed.connect(_on_go_login_pressed)
	box.add_child(_notice_button)
	return card


func _apply_trim_to_tree(node: Node) -> void:
	if node is Label:
		var label_node := node as Label
		if label_node.autowrap_mode != TextServer.AUTOWRAP_OFF:
			# 自动换行正文必须保留多行高度，不能被单行省略号裁剪压成 0 高
			label_node.clip_text = false
			label_node.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		else:
			label_node.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			label_node.clip_text = true
	elif node is Button:
		var button_node := node as Button
		button_node.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button_node.clip_text = true
	for child in node.get_children():
		_apply_trim_to_tree(child)


func _make_label(text_value: String, size: int, color: Color) -> Label:
	var l := ThemeBuilder.label(text_value, size, color)
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.clip_text = true
	return l


func _show_help() -> void:
	BottomSheet.show_help("天道榜 · 说明", [
		{"text": "榜单范围", "desc": "榜单统计已同步玉简云篆的同道，服务端约每 20 秒刷新。"},
		{"text": "我的名次", "desc": "自身名次按全服实时数据单独折算，即使未进前 50 也会显示。"},
		{"text": "三榜口径", "desc": "境界榜按境界与修为排序，镇魔塔榜按历史最高层排序，灵石榜按灵石数量排序。"},
	])


func _on_tab_pressed(kind: String) -> void:
	if not _is_logged_in():
		_show_offline_state()
		return
	if kind == _current_board:
		return
	_current_board = kind
	_refresh_tab_styles()
	if _cache.has(kind):
		_render(kind, _cache[kind])
	else:
		_request_board(kind, false)


func _refresh_tab_styles() -> void:
	for kind in _tabs.keys():
		var btn: Button = _tabs[kind]
		if btn == null:
			continue
		ThemeBuilder.apply_toggle_button(btn, String(kind) == _current_board)


func _on_refresh_pressed() -> void:
	if not _is_logged_in():
		_show_offline_state()
		return
	_request_board(_current_board, true)


func _on_go_login_pressed() -> void:
	# 只保存本地单机进度；绝不删档、绝不走退出仙籍清凭证流程
	SaveManager.save_game(false)
	if CloudSaveManager.get("skip_boot_overlay") != null:
		CloudSaveManager.set("skip_boot_overlay", true)
	SceneTransition.transition_to_scene("res://ui/LoginScene.tscn")


func _apply_session_view() -> void:
	if not _is_logged_in():
		_show_offline_state()
		return
	if _tabs_container != null:
		_tabs_container.visible = true
	if _refresh_button != null:
		_refresh_button.visible = true
	if _cache.has(_current_board):
		_render(_current_board, _cache[_current_board])
	else:
		_show_notice(LOADING_TEXT, "稍候片刻，三榜名录即将展开。", false)


func _show_offline_state() -> void:
	_is_loading = false
	if _refresh_button != null:
		_refresh_button.visible = false
	if _tabs_container != null:
		_tabs_container.visible = false
	if _my_rank_box != null:
		_my_rank_box.visible = false
	if _scroll != null:
		_scroll.visible = false
	_show_notice(OFFLINE_TITLE, OFFLINE_BODY, true)


func _show_notice(title_text: String, body_text: String, show_login: bool) -> void:
	if _notice_box == null:
		return
	_notice_box.visible = true
	_notice_title.text = title_text
	_notice_body.text = body_text
	_notice_button.visible = show_login
	if _scroll != null:
		_scroll.visible = false
	if _my_rank_box != null:
		_my_rank_box.visible = false


func _show_list() -> void:
	if _notice_box != null:
		_notice_box.visible = false
	if _scroll != null:
		_scroll.visible = true
	if _my_rank_box != null:
		_my_rank_box.visible = true
	if _tabs_container != null:
		_tabs_container.visible = true
	if _refresh_button != null:
		_refresh_button.visible = _is_logged_in()


func _request_board(kind: String, manual: bool) -> void:
	if not _is_logged_in():
		_show_offline_state()
		return
	if _is_loading:
		return
	var now := Time.get_ticks_msec()
	if now - _last_request_ms < REFRESH_COOLDOWN_MS:
		if manual:
			EventBus.toast.emit("天机尚在推演，稍候再问天道榜")
		return
	_last_request_ms = now
	_is_loading = true
	_show_notice(LOADING_TEXT, "稍候片刻，三榜名录即将展开。", false)
	CloudSaveManager.fetch_leaderboard(kind, 50)


func _on_leaderboard_loaded(ok: bool, board_type: String, data: Dictionary,
		message: String) -> void:
	if not _is_logged_in():
		_show_offline_state()
		return
	# 迟到/重复响应不得覆盖当前提示态；只有本次请求的首次回调有效
	if not _is_loading:
		return
	_is_loading = false
	if not ok:
		var detail := message if message != "" else "感应失败，服务端暂无回应。"
		_show_notice("天道榜暂不可读", detail + "\n" + RETRY_HINT, false)
		return
	var kind := board_type if board_type != "" else _current_board
	_cache[kind] = data.duplicate(true)
	if kind != _current_board:
		return
	_render(kind, data)


func _render(kind: String, data: Dictionary) -> void:
	if _list_box == null:
		return
	for child in _list_box.get_children():
		_list_box.remove_child(child)
		child.queue_free()
	var entries: Array = data.get("entries", [])
	if entries.is_empty():
		_show_notice("暂无同道入榜", EMPTY_TEXT + "\n" + RETRY_HINT, false)
		return
	_show_list()
	_render_my_rank(kind, data.get("my_rank", {}))
	for entry in entries:
		if entry is Dictionary:
			_list_box.add_child(_make_row(kind, entry as Dictionary))


func _render_my_rank(kind: String, mine: Dictionary) -> void:
	var rank := maxi(0, int(mine.get("rank", 0)))
	var my_uid := int(CloudSaveManager.auth.get("uid", 0))
	if mine.get("uid") != my_uid and my_uid > 0:
		rank = 0
	if rank <= 0:
		_my_rank_label.text = "暂未上榜，同步云篆后入榜"
		_my_value_label.text = ""
		return
	_my_rank_label.text = "第 %d 名" % rank
	_my_value_label.text = _core_value(kind, mine)


func _make_row(kind: String, entry: Dictionary) -> PanelContainer:
	var rank := maxi(1, int(entry.get("rank", 1)))
	var is_me := my_uid_matches(entry)
	var bg := ThemeBuilder.COLOR_CARD
	var rank_color := ThemeBuilder.COLOR_TEXT_SECONDARY
	if rank == 1:
		bg = ThemeBuilder.COLOR_GOLD_SOFT
		rank_color = ThemeBuilder.COLOR_TEXT_GOLD
	elif rank <= 3:
		bg = ThemeBuilder.COLOR_JADE_SOFT
		rank_color = ThemeBuilder.COLOR_TEXT_JADE
	var border := ThemeBuilder.COLOR_JADE_DARK if is_me else ThemeBuilder.COLOR_BORDER
	var card := ThemeBuilder.card_panel(bg, border, 8, ROW_MARGIN)
	if is_me:
		card.add_theme_stylebox_override("panel", ThemeBuilder.panel_box(
			bg, ThemeBuilder.COLOR_JADE_DARK, 8, 1, ROW_MARGIN))
	var row := ThemeBuilder.hbox(8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(row)
	var rank_label := _make_label("第 %d 名" % rank, ThemeBuilder.FONT_BODY_SUB, rank_color)
	rank_label.custom_minimum_size = Vector2(48, 0)
	rank_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	row.add_child(rank_label)
	var middle := ThemeBuilder.vbox(2)
	middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(middle)
	var name_text := String(entry.get("username", "同道"))
	if is_me and name_text != "我":
		name_text += " · 我"
	var name_label := _make_label(name_text, ThemeBuilder.FONT_BODY_SUB,
		ThemeBuilder.COLOR_TEXT_PRIMARY)
	middle.add_child(name_label)
	middle.add_child(_make_label(String(entry.get("realm_name", "未知境界")),
		ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_SECONDARY))
	var right := ThemeBuilder.vbox(2)
	right.custom_minimum_size = Vector2(104, 0)
	right.size_flags_horizontal = Control.SIZE_SHRINK_END
	row.add_child(right)
	var value_label := _make_label(_core_value(kind, entry),
		ThemeBuilder.FONT_BODY_SUB, ThemeBuilder.COLOR_TEXT_GOLD)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(value_label)
	return card


func my_uid_matches(entry: Dictionary) -> bool:
	var my_uid := int(CloudSaveManager.auth.get("uid", 0))
	return my_uid > 0 and int(entry.get("uid", -1)) == my_uid


func _core_value(kind: String, entry: Dictionary) -> String:
	match kind:
		BOARD_TOWER:
			var floor := maxi(0, int(entry.get("tower_floor", 0)))
			return "第 %d 层" % floor if floor > 0 else "未登塔"
		BOARD_STONES:
			return "灵石 %s" % String(entry.get("spirit_stones", "0"))
		_:
			return "修为 %s" % GameFormulas.format_num(
				float(entry.get("cultivation_xp", 0)))
