class_name SettingsPanel
extends Control
## 设置与仙籍：画面音效、自动托管、仙籍云篆、散功重修、开发者调试。

## 字号三档：按钮只显示纯中文描述，缩放倍率仍为 0.95 / 1.05 / 1.20
const FONT_SCALE_OPTIONS: Array = [
	{"value": 0.95, "label": "偏小"},
	{"value": 1.05, "label": "标准"},
	{"value": 1.20, "label": "偏大"},
]
## 帧率三档：0 = 30 / 1 = 60 / 2 = 高刷（对齐设备屏幕最高刷新率）
## 震动强度四档：0 关闭 / 1 轻柔 / 2 适中 / 3 强劲
const VIBRATION_OPTIONS: Array = [
	{"value": 0, "label": "关闭"},
	{"value": 1, "label": "轻柔"},
	{"value": 2, "label": "适中"},
	{"value": 3, "label": "强劲"},
]
## 按钮只显示纯中文描述，具体帧率由 GameState.get_target_fps() 落地
const FPS_MODES: Array = [
	{"value": 0, "label": "省电"},
	{"value": 1, "label": "流畅"},
	{"value": 2, "label": "高刷"},
]
## 雅乐编排：0 随境而变（日常/战斗自动切曲）/ 1 轮流雅奏（两曲首尾轮转）
const BGM_MODE_OPTIONS: Array = [
	{"value": 0, "label": "随境而变"},
	{"value": 1, "label": "轮流雅奏"},
]
## 关于卡片版本号：优先读应用配置，缺失时回退内置值
const APP_VERSION_FALLBACK: String = "1.0.0"
## 开发者调试连点彩蛋：1.5 秒窗口内累计 7 次；第 4~6 次提示剩余次数
const DEBUG_UNLOCK_TAPS: int = 7
const DEBUG_UNLOCK_HINT_FROM: int = 4
const DEBUG_UNLOCK_WINDOW_MS: int = 1500

var _debug_panel: PanelContainer
var _debug_body: VBoxContainer
var _about_card: PanelContainer
var _version_label: Label
var _stat_value_labels: Dictionary = {}
var _scroll: ScrollContainer
## 连点状态只存内存：不写存档，重启游戏自动回到隐藏态
var _debug_tap_count: int = 0
var _debug_last_tap_ms: int = 0
## 原生 versionName 读成功后缓存，避免每次切页都做一次 JNI 往返
var _cached_native_version: String = ""
var _audio_slider: HSlider
var _audio_volume_label: Label
var _music_slider: HSlider
var _music_volume_label: Label
var _width_margin: MarginContainer
var _scale_buttons: Dictionary = {}
var _fps_buttons: Dictionary = {}
var _vibration_buttons: Dictionary = {}
var _bgm_mode_buttons: Dictionary = {}
var _reset_button: Button
var _cloud_status_label: Label
var _cloud_sync_button: Button
var _cloud_login_button: Button
var _logout_button: Button
var _patch_version_label: Label


func _ready() -> void:
	_build()
	EventBus.game_loaded.connect(_on_game_loaded)
	EventBus.layout_changed.connect(_on_layout_changed)
	EventBus.stats_changed.connect(_on_stats_changed)
	visibility_changed.connect(_on_visibility_changed)
	_apply_width(EventBus.workspace_width)
	_refresh_font_scale_buttons()
	_refresh_fps_buttons()
	_refresh_vibration_buttons()
	_refresh_bgm_mode_buttons()
	_refresh_audio_volume_label()
	_refresh_music_volume_label()
	_refresh_stats()


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
	title_row.add_child(ThemeBuilder.title_label("设置与仙籍", 20))
	title_row.add_child(ThemeBuilder.chip("定时存档 20s", ThemeBuilder.COLOR_JADE))
	var help := ThemeBuilder.create_help_button(_show_help)
	help.custom_minimum_size = Vector2(44, 44)
	help.tooltip_text = "查看设置与仙籍说明"
	title_row.add_child(help)

	_scroll = ThemeBuilder.scroll_container()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# 12px 死区：轻点卡片时手指/鼠标的 1~2px 抖动不再被判定为触摸拖拽，
	# 避免松手后惯性把页面慢慢带偏（此前「关于」版本行一点就缓慢滑动的原因）
	_scroll.scroll_deadzone = 12
	root.add_child(_scroll)
	var body := ThemeBuilder.vbox(10)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_width_margin = MarginContainer.new()
	_width_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_width_margin)
	_width_margin.add_child(body)

	# ================================================================ 仙籍与云篆（置顶）
	_build_cloud_section(body)

	# ================================================================ 修行自动托管
	var auto_box := _section(body, "修行自动托管")
	var auto_grid := _make_two_column_grid(auto_box)
	_add_grid_toggle(auto_grid, _make_toggle("灵木助燃", "wood_fuel", true))
	_add_grid_toggle(auto_grid, _make_toggle("吐纳自动吞丹", "auto_pill", true))
	_add_grid_toggle(auto_grid, _make_toggle("战斗自动回春散", "auto_heal", true))
	_add_grid_toggle(auto_grid, _make_toggle("自动护身符", "auto_talisman", true))
	_add_grid_toggle(auto_grid, _make_toggle("自动引雷符", "auto_thunder_talisman", true))

	# ================================================================ 画面与音效
	var display_box := _section(body, "画面与音效")

	# 第一行：三档字号分段按钮
	var scale_row := ThemeBuilder.hbox(6)
	display_box.add_child(scale_row)
	for entry in FONT_SCALE_OPTIONS:
		var option: Dictionary = entry
		var value := float(option["value"])
		var scale_button := ThemeBuilder.small_button(String(option["label"]))
		scale_button.toggle_mode = true
		scale_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scale_button.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
		scale_button.pressed.connect(_on_font_scale_pressed.bind(value))
		scale_row.add_child(scale_button)
		_scale_buttons[value] = scale_button

	# 第二行：帧率三档（省电 / 流畅 / 高刷）
	var fps_row := ThemeBuilder.hbox(6)
	display_box.add_child(fps_row)
	for entry in FPS_MODES:
		var option: Dictionary = entry
		var mode := int(option["value"])
		var fps_button := ThemeBuilder.small_button(String(option["label"]))
		fps_button.toggle_mode = true
		fps_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fps_button.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
		fps_button.pressed.connect(_on_fps_mode_pressed.bind(mode))
		fps_row.add_child(fps_button)
		_fps_buttons[mode] = fps_button

	# 第三行：震动强度四档（切换即试震）
	display_box.add_child(ThemeBuilder.dim_label("震动强度", ThemeBuilder.FONT_CAPTION))
	var vibration_row := ThemeBuilder.hbox(6)
	display_box.add_child(vibration_row)
	for entry in VIBRATION_OPTIONS:
		var option: Dictionary = entry
		var level := int(option["value"])
		var vibration_button := ThemeBuilder.small_button(String(option["label"]))
		vibration_button.toggle_mode = true
		vibration_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vibration_button.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
		vibration_button.pressed.connect(_on_vibration_level_pressed.bind(level))
		vibration_row.add_child(vibration_button)
		_vibration_buttons[level] = vibration_button

	# 第四行：音效 + 音量
	var audio_row := ThemeBuilder.hbox(8)
	display_box.add_child(audio_row)
	audio_row.add_child(_make_toggle("音效", "audio", true))
	_audio_volume_label = ThemeBuilder.dim_label("", ThemeBuilder.FONT_CAPTION)
	_audio_volume_label.custom_minimum_size = Vector2(64, 0)
	audio_row.add_child(_audio_volume_label)
	_audio_slider = HSlider.new()
	_audio_slider.min_value = 0.0
	_audio_slider.max_value = 100.0
	_audio_slider.step = 5.0
	_audio_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_audio_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_audio_slider.custom_minimum_size = Vector2(0, 30)
	_audio_slider.value = clampf(float(GameState.flags.get("audio_volume", 0.25)) * 100.0, 0.0, 100.0)
	_audio_slider.value_changed.connect(_on_audio_volume_changed)
	audio_row.add_child(_audio_slider)

	# 音乐 + 音量（与音效独立）
	var music_row := ThemeBuilder.hbox(8)
	display_box.add_child(music_row)
	music_row.add_child(_make_toggle("音乐", "bgm_enabled", true))
	_music_volume_label = ThemeBuilder.dim_label("", ThemeBuilder.FONT_CAPTION)
	_music_volume_label.custom_minimum_size = Vector2(64, 0)
	music_row.add_child(_music_volume_label)
	_music_slider = HSlider.new()
	_music_slider.min_value = 0.0
	_music_slider.max_value = 100.0
	_music_slider.step = 5.0
	_music_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_music_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_music_slider.custom_minimum_size = Vector2(0, 30)
	_music_slider.value = clampf(float(GameState.flags.get("bgm_volume", 0.10)) * 100.0, 0.0, 100.0)
	_music_slider.value_changed.connect(_on_music_volume_changed)
	music_row.add_child(_music_slider)

	# 雅乐编排：随境而变（日常/战斗自动交叉淡入淡出）/ 轮流雅奏（两曲轮转）
	display_box.add_child(ThemeBuilder.dim_label("雅乐编排", ThemeBuilder.FONT_CAPTION))
	var bgm_mode_row := ThemeBuilder.hbox(6)
	display_box.add_child(bgm_mode_row)
	for entry in BGM_MODE_OPTIONS:
		var option: Dictionary = entry
		var mode_value := int(option["value"])
		var mode_button := ThemeBuilder.small_button(String(option["label"]))
		mode_button.toggle_mode = true
		mode_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mode_button.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
		mode_button.pressed.connect(_on_bgm_mode_pressed.bind(mode_value))
		bgm_mode_row.add_child(mode_button)
		_bgm_mode_buttons[mode_value] = mode_button

	# 离屏静音：默认开启，切后台/失焦时静音主总线
	var background_mute_toggle := _make_toggle("离屏静音", "background_mute", true)
	background_mute_toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	background_mute_toggle.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
	background_mute_toggle.tooltip_text = "切出游戏或窗口失焦时静默，归来后恢复"
	display_box.add_child(background_mute_toggle)

	# 第五行：锁定竖屏
	var orient_row := ThemeBuilder.hbox(8)
	display_box.add_child(orient_row)
	var orient_button := ThemeBuilder.small_button("锁定竖屏")
	orient_button.toggle_mode = true
	orient_button.button_pressed = GameState.lock_portrait
	ThemeBuilder.apply_toggle_button(orient_button, GameState.lock_portrait)
	orient_button.toggled.connect(func(pressed: bool) -> void:
		ThemeBuilder.apply_toggle_button(orient_button, pressed)
		_on_lock_portrait_toggled(pressed)
	)
	orient_row.add_child(orient_button)
	orient_row.add_child(ThemeBuilder.wrap_label("仅移动端生效", 11))

	# ================================================================ 道途统计
	var stats_box := _section(body, "道途统计")
	var stats_grid := _make_two_column_grid(stats_box)
	_add_stat_cell(stats_grid, "总出手", "actions")
	_add_stat_cell(stats_grid, "击杀", "kills")
	_add_stat_cell(stats_grid, "渡劫尝试", "tribulation")
	_add_stat_cell(stats_grid, "累计修行", "playtime")
	var codex_button := ThemeBuilder.small_button("修行典籍 · 术语与机制总览")
	codex_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	codex_button.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
	codex_button.pressed.connect(func() -> void: EventBus.codex_scripture_requested.emit())
	stats_box.add_child(codex_button)

	# ================================================================ 散功重修（沉底）
	var danger_box := _section(body, "散功重修", "清空本地进度（谨慎）")
	_reset_button = ThemeBuilder.button("散功重修")
	_reset_button.custom_minimum_size = Vector2(0, 46)
	_reset_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ThemeBuilder.clip_button_text(_reset_button, "散功重修")
	_reset_button.pressed.connect(_on_reset_pressed)
	danger_box.add_child(_reset_button)
	_apply_reset_idle_style()

	# ================================================================ 关于（仅玩家向信息，整卡为连点热区）
	_build_about_card(body)

	# ================================================================ 开发者调试（连点彩蛋解锁，默认隐藏）
	_build_debug_card(body)

	ThemeBuilder.prepare_touch(root)


func _patch_version_text() -> String:
	var rev := CloudSaveManager.get_current_patch_rev()
	return "天道初开" if rev <= 0 else "天道第 %d 卷" % rev


func _build_cloud_section(parent: VBoxContainer) -> void:
	var box := _section(parent, "仙籍与云篆", "云篆同步需灵脉通畅")
	_cloud_status_label = ThemeBuilder.wrap_label("检测仙籍中…",
		ThemeBuilder.FONT_BODY_SUB, ThemeBuilder.COLOR_TEXT_DIM)
	box.add_child(_cloud_status_label)

	var row := ThemeBuilder.hbox(8)
	box.add_child(row)
	_cloud_sync_button = ThemeBuilder.small_button("立即上传")
	_cloud_sync_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cloud_sync_button.custom_minimum_size = Vector2(0, 44)
	ThemeBuilder.clip_button_text(_cloud_sync_button, "立即上传")
	_cloud_sync_button.pressed.connect(_on_cloud_sync_pressed)
	row.add_child(_cloud_sync_button)

	_cloud_login_button = ThemeBuilder.small_button("拉取云端")
	_cloud_login_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cloud_login_button.custom_minimum_size = Vector2(0, 44)
	ThemeBuilder.clip_button_text(_cloud_login_button, "拉取云端")
	_cloud_login_button.pressed.connect(_on_cloud_login_pressed)
	row.add_child(_cloud_login_button)

	_logout_button = ThemeBuilder.small_button("退出仙籍")
	_logout_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_logout_button.custom_minimum_size = Vector2(0, 44)
	ThemeBuilder.clip_button_text(_logout_button, "退出仙籍")
	_logout_button.pressed.connect(_on_logout_pressed)
	_logout_button.visible = false
	box.add_child(_logout_button)

	if not CloudSaveManager.cloud_synced.is_connected(_on_cloud_synced):
		CloudSaveManager.cloud_synced.connect(_on_cloud_synced)
	_refresh_cloud_status()


func _refresh_cloud_status() -> void:
	if _cloud_status_label == null:
		return
	if CloudSaveManager.is_offline_mode:
		_cloud_status_label.text = "当前为离线单机模式（云篆已暂停）"
		_cloud_status_label.add_theme_color_override("font_color",
			ThemeBuilder.COLOR_TEXT_DANGER)
		_cloud_sync_button.visible = false
		_cloud_login_button.visible = true
		_cloud_login_button.disabled = false
		_cloud_login_button.text = "前往登录仙籍"
		if _logout_button != null:
			_logout_button.visible = false
		return
	if not CloudSaveManager.has_token():
		_cloud_status_label.text = "尚未登录仙籍 · 云篆未启"
		_cloud_status_label.add_theme_color_override("font_color",
			ThemeBuilder.COLOR_TEXT_MUTED)
		_cloud_sync_button.visible = false
		_cloud_login_button.visible = true
		_cloud_login_button.disabled = false
		_cloud_login_button.text = "前往登录仙籍"
		if _logout_button != null:
			_logout_button.visible = false
		return
	var username := String(CloudSaveManager.auth.get("username", ""))
	var uid := int(CloudSaveManager.auth.get("uid", 0))
	var rev := int(CloudSaveManager.auth.get("local_save_rev", 0))
	var conflict := CloudSaveManager.is_conflict_paused()
	var state := "云端冲突待处理" if conflict else \
		("已同步 · 第 %d 版" % rev if rev > 0 else "尚未同步")
	_cloud_status_label.text = "仙籍：%s · UID %d\n%s" % [
		username if username != "" else "未登录", uid, state]
	_cloud_status_label.add_theme_color_override("font_color",
		ThemeBuilder.COLOR_TEXT_DANGER if conflict else ThemeBuilder.COLOR_TEXT_JADE)
	_cloud_sync_button.visible = true
	_cloud_sync_button.disabled = false
	_cloud_sync_button.text = "立即上传"
	_cloud_login_button.visible = true
	_cloud_login_button.disabled = false
	_cloud_login_button.text = "拉取云端"
	if _logout_button != null:
		_logout_button.visible = true


func _on_cloud_synced(_save_rev: int, _uploaded: bool) -> void:
	_refresh_cloud_status()


func _on_cloud_sync_pressed() -> void:
	if CloudSaveManager.is_offline_mode:
		return
	_cloud_sync_button.disabled = true
	_cloud_sync_button.text = "上传中…"
	var result := await CloudSaveManager.upload_save(false)
	_cloud_sync_button.disabled = false
	_cloud_sync_button.text = "立即上传"
	_refresh_cloud_status()
	if bool(result.get("ok", false)):
		EventBus.toast.emit("玉简已入云篆")
	elif int(result.get("http", 0)) == 409:
		EventBus.toast.emit("云端玉简较新，请二选一")
	else:
		EventBus.toast.emit(String(result.get("message", "云篆上传失败")))


func _on_cloud_login_pressed() -> void:
	if CloudSaveManager.has_token() and not CloudSaveManager.is_offline_mode:
		_cloud_login_button.disabled = true
		_cloud_login_button.text = "读取中…"
		var result := await CloudSaveManager.request_pull_confirm()
		if not is_inside_tree():
			return
		_cloud_login_button.disabled = false
		_cloud_login_button.text = "拉取云端"
		_refresh_cloud_status()
		if not bool(result.get("ok", false)):
			EventBus.toast.emit(String(result.get("message", "读取云端失败")))
		elif not bool(result.get("exists", false)):
			EventBus.toast.emit("云端暂无玉简")
		return
	SaveManager.save_game(false)
	if CloudSaveManager.get("skip_boot_overlay") != null:
		CloudSaveManager.set("skip_boot_overlay", true)
	SceneTransition.transition_to_scene("res://ui/LoginScene.tscn", "收摄心神，重返山门……")


func _show_help() -> void:
	BottomSheet.show_help("设置与仙籍 · 说明", [
		{"text": "本地存盘", "desc": "进度由系统自动刻入玉简：每 20 秒定时存盘，境界突破与退出/切页前亦会落盘；无需手动操作。"},
		{"text": "仙籍与云篆", "desc": "在线可立即上传 / 拉取云端；散功重修与退出仙籍均需二次确认，云端玉简不会被误覆盖。"},
		{"text": "画面与护道托管", "desc": "字号、帧率、音效、雅乐与竖屏锁定即时生效；自动托管开关会持久保存。"},
		{"text": "雅乐编排", "desc": "「随境而变」：日常静修奏平静曲，踏入秘境或镇魔塔转战斗曲，曲声于一息之间柔缓交替；「轮流雅奏」：两曲首尾相衔轮转，不受战斗影响。二者皆受音乐开关与音量节制。"},
	])


func _section(parent: VBoxContainer, title_text: String, subtitle: String = "") -> VBoxContainer:
	var panel := ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD, ThemeBuilder.COLOR_BORDER, 12, 12)
	parent.add_child(panel)
	var box := ThemeBuilder.vbox(8)
	panel.add_child(box)
	var row := ThemeBuilder.hbox(8)
	box.add_child(row)
	row.add_child(ThemeBuilder.card_title_label(title_text, ThemeBuilder.FONT_CARD_TITLE,
		ThemeBuilder.COLOR_AMBER))
	row.add_child(ThemeBuilder.expander())
	if subtitle != "":
		row.add_child(ThemeBuilder.dim_label(subtitle, 11))
	return box


func _make_two_column_grid(parent: VBoxContainer) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(grid)
	return grid


## 开关统一样式：等宽撑满单元格 + 44px 最小高度
func _add_grid_toggle(grid: GridContainer, button: Button) -> void:
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
	grid.add_child(button)


# ---------------------------------------------------------------- 道途统计四宫格

## 轻量数值格：浅底小卡 + 说明 + 数值；数值用 autowrap，450 宽 + 1.20 大字也不会撑破两列
func _add_stat_cell(grid: GridContainer, caption: String, stat_key: String) -> void:
	var cell := PanelContainer.new()
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.add_theme_stylebox_override("panel",
		ThemeBuilder.panel_box(ThemeBuilder.COLOR_SUBTLE, ThemeBuilder.COLOR_BORDER, 8, 1, 8))
	grid.add_child(cell)
	var col := ThemeBuilder.vbox(2)
	cell.add_child(col)
	col.add_child(ThemeBuilder.label(caption, ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_DIM))
	var value := ThemeBuilder.wrap_label("—", ThemeBuilder.FONT_BODY_SUB, ThemeBuilder.COLOR_TEXT)
	col.add_child(value)
	_stat_value_labels[stat_key] = value


func _refresh_stats() -> void:
	if _stat_value_labels.is_empty():
		return
	_set_stat_value("actions",
		GameFormulas.format_num(float(GameState.stats.get("actions_completed", 0))))
	_set_stat_value("kills",
		GameFormulas.format_num(float(GameState.stats.get("kills", 0))))
	_set_stat_value("tribulation", str(int(GameState.stats.get("tribulation_attempts", 0))))
	_set_stat_value("playtime",
		GameFormulas.format_duration(float(GameState.stats.get("play_seconds", 0.0))))


func _set_stat_value(stat_key: String, text_value: String) -> void:
	var value_label: Label = _stat_value_labels.get(stat_key, null)
	if value_label != null and value_label.text != text_value:
		value_label.text = text_value


## stats_changed 在挂机时很频繁：仅在设置页可见时刷新，避免不可见面板反复文本重排
func _on_stats_changed() -> void:
	if is_visible_in_tree():
		_refresh_stats()


func _make_toggle(text_value: String, flag_key: String, default_value: bool) -> Button:
	var button := ThemeBuilder.small_button(text_value)
	button.toggle_mode = true
	button.button_pressed = GameState.is_flag(flag_key, default_value)
	ThemeBuilder.apply_toggle_button(button, button.button_pressed)
	button.toggled.connect(func(pressed: bool) -> void:
		GameState.set_flag(flag_key, pressed)
		ThemeBuilder.apply_toggle_button(button, pressed)
		if flag_key == "audio" or flag_key == "background_mute":
			if AudioManager != null:
				AudioManager.sync_bus_mute()
		elif flag_key == "bgm_enabled":
			if AudioManager != null:
				AudioManager.apply_bgm_state()
	)
	return button


# ---------------------------------------------------------------- 震动强度四档

func _current_vibration_level() -> int:
	return clampi(int(GameState.flags.get("vibration_level", 2)), 0, 3)


func _on_vibration_level_pressed(level: int) -> void:
	if level == _current_vibration_level():
		_refresh_vibration_buttons()
		return
	GameState.flags["vibration_level"] = level
	EventBus.stats_changed.emit()
	SaveManager.save_game(false)
	_refresh_vibration_buttons()
	# 立即试震：轻柔/适中/强劲的振幅与时长阶梯不同，方便当场盲调
	if level > 0 and AudioManager != null:
		AudioManager.play_vibrate_medium()


func _refresh_vibration_buttons() -> void:
	var current := _current_vibration_level()
	for level_value in _vibration_buttons.keys():
		var button: Button = _vibration_buttons[level_value]
		var selected := int(level_value) == current
		button.button_pressed = selected
		_style_segment_button(button, selected)


# ---------------------------------------------------------------- 关于 / 连点彩蛋

## 整张「关于」卡片即热区：PASS 让它照常接收轻点、又不吞外层 ScrollContainer 的滑动。
## 不再使用 Button：Button 会在按下时 accept_event，且样式/焦点语义都与「一张说明卡」不符。
func _build_about_card(parent: VBoxContainer) -> void:
	_about_card = ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD, ThemeBuilder.COLOR_BORDER, 12, 12)
	_about_card.mouse_filter = Control.MOUSE_FILTER_PASS
	_about_card.gui_input.connect(_on_about_card_gui_input)
	parent.add_child(_about_card)
	var box := ThemeBuilder.vbox(8)
	_about_card.add_child(box)
	var head := ThemeBuilder.hbox(8)
	box.add_child(head)
	head.add_child(ThemeBuilder.card_title_label("关于",
		ThemeBuilder.FONT_CARD_TITLE, ThemeBuilder.COLOR_AMBER))
	head.add_child(ThemeBuilder.expander())
	box.add_child(ThemeBuilder.wrap_label("玉简问道 · PathOfJade",
		ThemeBuilder.FONT_BODY_SUB, ThemeBuilder.COLOR_TEXT))
	_version_label = ThemeBuilder.label("版本 v%s" % get_app_version(),
		ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_DIM)
	box.add_child(_version_label)
	_patch_version_label = ThemeBuilder.label(_patch_version_text(),
		ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_SECONDARY)
	box.add_child(_patch_version_label)


## 打开设置页时重读一次，保证展示永远是最新（Android 上重新导出 APK 后无需改代码）
func _refresh_version() -> void:
	if _version_label == null:
		return
	var text_value := "版本 v%s" % get_app_version()
	if _version_label.text != text_value:
		_version_label.text = text_value


## 版本号：Android 真机优先用原生 APK 的 versionName（与导出预设 Version Name 一致），
## 其余平台或原生读取失败时回退 application/config/version，最终兜底 "1.0.0"。
func get_app_version() -> String:
	var native := _read_android_version_name()
	if native != "":
		return native
	var configured := str(ProjectSettings.get_setting("application/config/version", "")).strip_edges()
	if configured != "":
		return configured
	return APP_VERSION_FALLBACK


## 原生包信息读取：多策略依次尝试，全部失败返回空串（交给上层回退 config/version），绝不抛错。
## 策略一 ActivityThread.currentApplication()（隐藏 API，Android 9+ 可能被系统拦截）；
## 策略二 org.godotengine.godot.Godot.getActivity()（应用自身公开类，不受隐藏 API 限制）。
func _read_android_version_name() -> String:
	if not OS.has_feature("android"):
		return ""
	if not ClassDB.class_exists("JavaClassWrapper"):
		return ""
	if _cached_native_version != "":
		return _cached_native_version
	var version := ""
	var thread_class: Variant = JavaClassWrapper.wrap("android.app.ActivityThread")
	if thread_class != null:
		var app: Variant = thread_class.currentApplication()
		if app != null:
			version = _android_version_from_context(app)
	if version == "":
		var godot_class: Variant = JavaClassWrapper.wrap("org.godotengine.godot.Godot")
		if godot_class != null:
			var activity: Variant = godot_class.getActivity()
			if activity != null:
				version = _android_version_from_context(activity)
	if version != "":
		_cached_native_version = version
		if OS.is_debug_build():
			print("[PathOfJade] 原生 APK versionName = ", version)
	return version


## Context（Application / Activity）→ PackageInfo.versionName
func _android_version_from_context(context: Variant) -> String:
	var package_name: Variant = context.getPackageName()
	if package_name == null or str(package_name) == "":
		return ""
	var manager: Variant = context.getPackageManager()
	if manager == null:
		return ""
	var info: Variant = manager.getPackageInfo(str(package_name), 0)
	if info == null:
		return ""
	var version: Variant = info.get("versionName")
	if version == null:
		return ""
	return str(version).strip_edges()


func _on_about_card_gui_input(event: InputEvent) -> void:
	# 只认「按下」这一下。emulate_touch_from_mouse 开启时同一次点击会同时派发
	# InputEventScreenTouch 与 InputEventMouseButton，这里只取其一，避免一次点击算两次。
	var tapped := false
	var touch := event as InputEventScreenTouch
	if touch != null:
		tapped = touch.pressed
	elif not Input.is_emulating_touch_from_mouse():
		var mouse_button := event as InputEventMouseButton
		tapped = mouse_button != null and mouse_button.pressed \
			and mouse_button.button_index == MOUSE_BUTTON_LEFT
	if tapped:
		_count_debug_tap()


func _count_debug_tap() -> void:
	# 已解锁时不再计数，避免 Toast 反复打扰
	if _debug_panel != null and _debug_panel.visible:
		return
	var now := Time.get_ticks_msec()
	if now - _debug_last_tap_ms > DEBUG_UNLOCK_WINDOW_MS:
		_debug_tap_count = 0
	_debug_last_tap_ms = now
	_debug_tap_count += 1
	if _debug_tap_count >= DEBUG_UNLOCK_TAPS:
		_unlock_debug_panel()
		return
	# 第 4~6 次给剩余次数提示，前三次静默（避免误触时刷屏）
	if _debug_tap_count >= DEBUG_UNLOCK_HINT_FROM:
		EventBus.toast.emit("再轻点 %d 次开启调试" % (DEBUG_UNLOCK_TAPS - _debug_tap_count))


# ---------------------------------------------------------------- 开发者调试（默认隐藏）

func _build_debug_card(parent: VBoxContainer) -> void:
	_debug_panel = ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD, ThemeBuilder.COLOR_BORDER, 12, 12)
	_debug_panel.visible = false
	parent.add_child(_debug_panel)
	var debug_box := ThemeBuilder.vbox(8)
	_debug_panel.add_child(debug_box)

	var debug_head := ThemeBuilder.hbox(8)
	debug_box.add_child(debug_head)
	debug_head.add_child(ThemeBuilder.card_title_label("开发者调试",
		ThemeBuilder.FONT_CARD_TITLE, ThemeBuilder.COLOR_AMBER))
	debug_head.add_child(ThemeBuilder.expander())
	var hide_button := ThemeBuilder.small_button("隐藏")
	hide_button.custom_minimum_size = Vector2(56, ThemeBuilder.TOUCH_MIN)
	ThemeBuilder.apply_font_size(hide_button, ThemeBuilder.FONT_CAPTION)
	hide_button.tooltip_text = "收起开发者调试（重启游戏后仍为隐藏）"
	hide_button.pressed.connect(_on_debug_hide_pressed)
	debug_head.add_child(hide_button)

	_debug_body = ThemeBuilder.vbox(8)
	debug_box.add_child(_debug_body)

	_debug_body.add_child(ThemeBuilder.section_title_label("闭关推演", ThemeBuilder.FONT_CAPTION))
	var offline_row := ThemeBuilder.hbox(6)
	_debug_body.add_child(offline_row)
	var sim30 := ThemeBuilder.button("闭关 30 分")
	sim30.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ThemeBuilder.apply_font_size(sim30, 13)
	sim30.pressed.connect(_simulate.bind(0.5))
	offline_row.add_child(sim30)
	var sim2 := ThemeBuilder.button("闭关 2 小时")
	sim2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ThemeBuilder.apply_font_size(sim2, 13)
	sim2.pressed.connect(_simulate.bind(2.0))
	offline_row.add_child(sim2)
	var sim8 := ThemeBuilder.button("闭关 8 小时")
	sim8.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ThemeBuilder.apply_font_size(sim8, 13)
	sim8.pressed.connect(_simulate.bind(8.0))
	offline_row.add_child(sim8)
	_debug_body.add_child(ThemeBuilder.wrap_label(
		"推演将真实计入道行并写入玉简。神游归来时亦会补算所得（≥5 秒静默入账，≥60 秒呈报玉简）。", 11))

	_debug_body.add_child(ThemeBuilder.section_title_label("生命周期", ThemeBuilder.FONT_CAPTION))
	var life_row := ThemeBuilder.hbox(6)
	_debug_body.add_child(life_row)
	var life20 := ThemeBuilder.button("神游 20 秒")
	life20.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ThemeBuilder.apply_font_size(life20, 13)
	life20.pressed.connect(_on_lifecycle_test.bind(20.0))
	life_row.add_child(life20)
	var life90 := ThemeBuilder.button("神游 90 秒")
	life90.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ThemeBuilder.apply_font_size(life90, 13)
	life90.pressed.connect(_on_lifecycle_test.bind(90.0))
	life_row.add_child(life90)
	_debug_body.add_child(ThemeBuilder.wrap_label(
		"20 秒：顶部轻量提示（静默补算）；90 秒：弹出「闭关收益玉简」。真机上锁屏 / 切应用即触发同一逻辑。", 11))


func _unlock_debug_panel() -> void:
	_debug_tap_count = 0
	_debug_last_tap_ms = 0
	if _debug_panel == null:
		return
	_debug_panel.visible = true
	# 主动操作：轻震一次（移动端前台才生效，桌面自动忽略）
	GameState.vibrate_light()
	EventBus.toast.emit("已开启开发者调试")
	_scroll_to_debug()


func _on_debug_hide_pressed() -> void:
	_debug_tap_count = 0
	_debug_last_tap_ms = 0
	if _debug_panel != null:
		_debug_panel.visible = false


## 解锁后等两帧让容器完成重排，再把调试卡滚入视野（只动面板内 ScrollContainer）
func _scroll_to_debug() -> void:
	if _scroll == null or _debug_panel == null:
		return
	await get_tree().process_frame
	await get_tree().process_frame
	if _scroll == null or not is_instance_valid(_debug_panel):
		return
	_scroll.ensure_control_visible(_debug_panel)


# ---------------------------------------------------------------- 字号档位

func _current_font_scale() -> float:
	# 旧档 0.90/1.00/1.15 也会被归一到新三档，按钮高亮不会落空
	return ThemeBuilder.normalize_font_scale(
		float(GameState.flags.get("font_scale", ThemeBuilder.FONT_SCALE_STANDARD)))


func _on_font_scale_pressed(value: float) -> void:
	if is_equal_approx(_current_font_scale(), value):
		_refresh_font_scale_buttons()
		return
	GameState.flags["font_scale"] = value
	EventBus.font_scale_changed.emit(value)
	SaveManager.save_game(false)
	_refresh_font_scale_buttons()


func _refresh_font_scale_buttons() -> void:
	if _scale_buttons.is_empty():
		return
	var current := _current_font_scale()
	for entry in FONT_SCALE_OPTIONS:
		var option: Dictionary = entry
		var value := float(option["value"])
		var button: Button = _scale_buttons.get(value, null)
		if button == null:
			continue
		var selected := is_equal_approx(value, current)
		button.button_pressed = selected
		_style_segment_button(button, selected)


func _style_segment_button(button: Button, selected: bool) -> void:
	var bg := ThemeBuilder.COLOR_JADE_SOFT if selected else ThemeBuilder.COLOR_SUBTLE
	var border := ThemeBuilder.COLOR_JADE if selected else ThemeBuilder.COLOR_BORDER
	var fg := ThemeBuilder.COLOR_JADE if selected else ThemeBuilder.COLOR_TEXT_DIM
	button.add_theme_stylebox_override("normal", ThemeBuilder.panel_box(bg, border, 8, 1, 10))
	button.add_theme_stylebox_override("hover",
		ThemeBuilder.panel_box(bg.lightened(0.06), border, 8, 1, 10))
	button.add_theme_stylebox_override("pressed",
		ThemeBuilder.panel_box(bg.darkened(0.08), border, 8, 1, 10))
	button.add_theme_color_override("font_color", fg)
	button.add_theme_color_override("font_hover_color", fg)
	button.add_theme_color_override("font_pressed_color", fg)


# ---------------------------------------------------------------- 帧率档位

func _current_fps_mode() -> int:
	return clampi(int(GameState.flags.get("fps_mode", 0)), 0, 2)


func _on_fps_mode_pressed(mode: int) -> void:
	if mode == _current_fps_mode():
		_refresh_fps_buttons()
		return
	GameState.flags["fps_mode"] = mode
	_apply_fps_mode(mode)
	SaveManager.save_game(false)
	_refresh_fps_buttons()


func _refresh_fps_buttons() -> void:
	if _fps_buttons.is_empty():
		return
	var current := _current_fps_mode()
	for entry in FPS_MODES:
		var option: Dictionary = entry
		var mode := int(option["value"])
		var button: Button = _fps_buttons.get(mode, null)
		if button == null:
			continue
		var selected := mode == current
		button.button_pressed = selected
		_style_segment_button(button, selected)


func _apply_fps_mode(mode: int) -> void:
	# 与外壳启动共用同一入口：档位 2 取设备屏幕最高刷新率，不再是无限制（0）
	GameState.apply_fps_mode(mode)


# ---------------------------------------------------------------- 雅乐编排

func _current_bgm_mode() -> int:
	return clampi(int(GameState.flags.get("bgm_mode", 0)), 0, 1)


func _on_bgm_mode_pressed(mode: int) -> void:
	if mode == _current_bgm_mode():
		_refresh_bgm_mode_buttons()
		return
	GameState.flags["bgm_mode"] = mode
	# 立即按新编排换曲：随境而变按战斗状态归位，轮流雅奏从下一首起轮转
	if AudioManager != null:
		AudioManager.apply_bgm_state()
	SaveManager.save_game(false)
	_refresh_bgm_mode_buttons()


func _refresh_bgm_mode_buttons() -> void:
	if _bgm_mode_buttons.is_empty():
		return
	var current := _current_bgm_mode()
	for entry in BGM_MODE_OPTIONS:
		var option: Dictionary = entry
		var mode_value := int(option["value"])
		var button: Button = _bgm_mode_buttons.get(mode_value, null)
		if button == null:
			continue
		var selected := mode_value == current
		button.button_pressed = selected
		_style_segment_button(button, selected)


# ---------------------------------------------------------------- 竖屏锁 / 音量

func _on_lock_portrait_toggled(pressed: bool) -> void:
	GameState.lock_portrait = pressed
	SaveManager.save_game(false)
	if not (OS.has_feature("android") or OS.has_feature("ios")):
		EventBus.toast.emit("已记录设置（仅移动端生效）")
		return
	if pressed:
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	else:
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR)


func _on_layout_changed(_mode: int, _vp_size: Vector2, workspace_width: float) -> void:
	_apply_width(workspace_width)


func _apply_width(workspace_width: float) -> void:
	if _width_margin == null:
		return
	var extra := int(round(maxf(0.0, (workspace_width - 760.0) * 0.5)))
	_width_margin.add_theme_constant_override("margin_left", extra)
	_width_margin.add_theme_constant_override("margin_right", extra)


func _on_audio_volume_changed(value: float) -> void:
	GameState.flags["audio_volume"] = clampf(value / 100.0, 0.0, 1.0)
	_refresh_audio_volume_label()
	EventBus.stats_changed.emit()


func _on_music_volume_changed(value: float) -> void:
	GameState.flags["bgm_volume"] = clampf(value / 100.0, 0.0, 1.0)
	_refresh_music_volume_label()
	if AudioManager != null:
		AudioManager.set_bgm_volume(float(GameState.flags["bgm_volume"]))
		AudioManager.apply_bgm_state()
	EventBus.stats_changed.emit()


func _refresh_audio_volume_label() -> void:
	if _audio_volume_label == null:
		return
	var volume := clampf(float(GameState.flags.get("audio_volume", 0.25)), 0.0, 1.0)
	_audio_volume_label.text = "音量 %d%%" % int(round(volume * 100.0))


func _refresh_music_volume_label() -> void:
	if _music_volume_label == null:
		return
	var volume := clampf(float(GameState.flags.get("bgm_volume", 0.10)), 0.0, 1.0)
	_music_volume_label.text = "音量 %d%%" % int(round(volume * 100.0))


# ---------------------------------------------------------------- 散功重修 / 退出仙籍

func _show_confirm_sheet(title_text: String, note_text: String,
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
		ThemeBuilder.clip_button_text(button, String(option.get("text", "")))
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


func _on_reset_pressed() -> void:
	if CloudSaveManager.has_token() and not CloudSaveManager.is_offline_mode:
		var username := String(CloudSaveManager.auth.get("username", "无名"))
		_show_confirm_sheet("散功重修",
			"当前已登录仙籍（道号：%s），散功重修将同时清空本地与云端玉简进度，一切从头再来，是否确认？" % username,
			[
				{"text": "确认散功重修", "primary": true, "callback": _perform_reset_online},
				{"text": "暂不散功", "callback": _cancel_reset},
			])
		return
	_show_confirm_sheet("散功重修",
		"确定要散功重修吗？当前本地修行进度将全部清零。",
		[
			{"text": "确认散功重修", "primary": true, "callback": _perform_reset_local},
			{"text": "暂不散功", "callback": _cancel_reset},
		])


func _cancel_reset() -> void:
	pass


func _perform_reset_local() -> void:
	SaveManager.reset_save()
	_refresh_stats()
	_refresh_cloud_status()


## 在线散功重修：先归零本地，再立即强制覆写云端，避免旧云档残留或后续冲突
func _perform_reset_online() -> void:
	SaveManager.reset_save()
	var result := await CloudSaveManager.upload_save(true)
	if not is_inside_tree():
		return
	if bool(result.get("ok", false)):
		EventBus.toast.emit("已散功重修，本地与云端玉简皆归零")
	else:
		EventBus.toast.emit("本地已归零，云端覆写失败：" + String(result.get("message", "")))
	_refresh_stats()
	_refresh_cloud_status()


func _on_logout_pressed() -> void:
	_show_confirm_sheet("退出仙籍",
		"退出仙籍后云端玉简仍会妥善保留。是否同时清空本机残留进度？",
		[
			{"text": "退出并清本机", "primary": true, "callback": _confirm_logout_clear_local},
			{"text": "仅退出登录", "callback": _confirm_logout_keep_local},
		])


func _confirm_logout_clear_local() -> void:
	CloudSaveManager.logout_and_clear_local(true)


func _confirm_logout_keep_local() -> void:
	CloudSaveManager.logout_and_clear_local(false)


func _apply_reset_idle_style() -> void:
	if _reset_button == null:
		return
	ThemeBuilder.apply_secondary_button(_reset_button, true)
	# 文字统一朱砂红，与常规按钮明确区分
	_reset_button.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT_DANGER)
	_reset_button.add_theme_color_override("font_hover_color",
		ThemeBuilder.COLOR_TEXT_DANGER.lightened(0.18))
	_reset_button.add_theme_color_override("font_pressed_color",
		ThemeBuilder.COLOR_TEXT_DANGER.darkened(0.12))


func _on_visibility_changed() -> void:
	if not visible:
		# 离开设置页即清零连点，避免半截序列带到下次进入
		_debug_tap_count = 0
		_debug_last_tap_ms = 0
		return
	# 每次切入设置页实时刷新道途统计、云篆状态与版本号（Android 重装新 APK 后无需改代码）
	_refresh_stats()
	_refresh_cloud_status()
	if _patch_version_label != null:
		_patch_version_label.text = _patch_version_text()
	_refresh_version()


# ---------------------------------------------------------------- 调试

func _simulate(hours: float) -> void:
	var has_activity := CombatEngine.is_active()
	for slot in range(GameState.SLOT_COUNT):
		if GameState.get_active_action(slot) != "":
			has_activity = true
	if not has_activity:
		EventBus.toast.emit("请先运转一门功课，再推演闭关所得")
		return
	SaveManager.simulate_offline(hours)


func _on_lifecycle_test(seconds: float) -> void:
	var has_activity := CombatEngine.is_active()
	for slot in range(GameState.SLOT_COUNT):
		if GameState.get_active_action(slot) != "":
			has_activity = true
	if not has_activity:
		EventBus.toast.emit("请先运转一门功课，再测试神游补算")
		return
	SaveManager.debug_suspend_resume(seconds)


func _on_game_loaded() -> void:
	_refresh_font_scale_buttons()
	_apply_fps_mode(_current_fps_mode())
	_refresh_fps_buttons()
	_refresh_vibration_buttons()
	_refresh_bgm_mode_buttons()
	_refresh_audio_volume_label()
	_refresh_music_volume_label()
	_refresh_stats()
	if _audio_slider != null:
		var volume := clampf(float(GameState.flags.get("audio_volume", 0.25)), 0.0, 1.0)
		_audio_slider.set_value_no_signal(volume * 100.0)
	if _music_slider != null:
		var music_volume := clampf(float(GameState.flags.get("bgm_volume", 0.10)), 0.0, 1.0)
		_music_slider.set_value_no_signal(music_volume * 100.0)









