extends Control

## 灵潭清茗：灵潭垂钓与洞府烹茶双页签界面。
## 不声明 class_name：由 MainShell 以 preload 加载，确保 PCK 单发也能生效。

## 单节点轻量灵潭舞台：纯 _draw，无粒子无 Shader，只在垂钓可见时逐帧重绘。
class TeaPondStage extends Control:
	var fishing_active: bool = false
	var progress: float = 0.0
	var _time: float = 0.0
	var _flash_left: float = 0.0
	var _catch_text: String = ""
	var _catch_left: float = 0.0

	func _process(delta: float) -> void:
		if not fishing_active or not is_visible_in_tree():
			return
		_time += delta
		_flash_left = maxf(0.0, _flash_left - delta)
		_catch_left = maxf(0.0, _catch_left - delta)
		queue_redraw()

	func show_catch(text_value: String) -> void:
		if text_value == "":
			return
		_catch_text = text_value
		_catch_left = 0.8
		_flash_left = 0.55
		queue_redraw()

	func _draw() -> void:
		var center := size * 0.5
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.72, 0.86, 0.83, 0.12))
		for i in range(3):
			var radius := 12.0 + fmod(_time * 12.0 + float(i) * 18.0, 54.0)
			var alpha := 0.18 * (1.0 - radius / 58.0)
			draw_arc(center, radius, 0.0, TAU, 32,
				Color(ThemeBuilder.COLOR_TEXT_JADE.r, ThemeBuilder.COLOR_TEXT_JADE.g,
					ThemeBuilder.COLOR_TEXT_JADE.b, maxf(0.0, alpha)), 1.5, true)
		var rod_tip := Vector2(size.x * 0.30, size.y * 0.20)
		var bob_y := center.y + sin(_time * 2.4) * 3.5
		if progress >= 0.875:
			bob_y += sin(_time * 18.0) * 3.0
		var bob := Vector2(size.x * 0.56, bob_y)
		draw_line(rod_tip, Vector2(bob.x, size.y * 0.10), ThemeBuilder.COLOR_TEXT_PRIMARY, 1.2)
		draw_line(Vector2(bob.x, size.y * 0.10), bob, ThemeBuilder.COLOR_TEXT_SECONDARY, 1.0)
		draw_circle(bob, 4.0, ThemeBuilder.COLOR_TEXT_GOLD)
		draw_arc(bob, 6.5, 0.0, TAU, 16, ThemeBuilder.COLOR_TEXT_JADE, 1.0, true)
		if _flash_left > 0.0:
			draw_arc(center, 22.0 + (0.55 - _flash_left) * 70.0, 0.0, TAU, 40,
				Color(ThemeBuilder.COLOR_TEXT_GOLD.r, ThemeBuilder.COLOR_TEXT_GOLD.g,
					ThemeBuilder.COLOR_TEXT_GOLD.b, _flash_left / 0.55), 2.0, true)
		if _catch_left > 0.0 and _catch_text != "":
			var alpha := clampf(_catch_left / 0.8, 0.0, 1.0)
			var y := center.y + 14.0 - (0.8 - _catch_left) * 30.0
			draw_string(ThemeBuilder.make_font(),
				Vector2(8.0, y), _catch_text, HORIZONTAL_ALIGNMENT_CENTER,
				size.x - 16.0, ThemeBuilder.scaled_font_size(ThemeBuilder.FONT_CAPTION),
				Color(ThemeBuilder.COLOR_TEXT_GOLD.r, ThemeBuilder.COLOR_TEXT_GOLD.g,
					ThemeBuilder.COLOR_TEXT_GOLD.b, alpha))

var _scroll: ScrollContainer
var _content: VBoxContainer
var _tab: String = "fishing"
var _progress_bar: ProgressBar
var _progress_label: Label
var _tea_banner: Label
var _pond_stage: TeaPondStage
var _last_fish_timer: float = -1.0
var _brewing_tea_id: String = ""
var _brew_started_msec: int = 0
var _brewing_icon: IconFrame
var _live_accum: float = 0.0
var _dirty: bool = true
var _rebuild_queued: bool = false


func _ready() -> void:
	_build_shell()
	_connect_signals()
	visibility_changed.connect(_on_visibility_changed)
	set_process(true)
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
	_connect_if(EventBus, "realm_changed", Callable(self, "_queue_refresh"))
	_connect_if(EventBus, "game_loaded", Callable(self, "_queue_refresh"))


func _connect_if(source: Object, signal_name: String, callback: Callable) -> void:
	if source == null or not source.has_signal(signal_name):
		return
	if not source.is_connected(signal_name, callback):
		source.connect(signal_name, callback)


func _on_visibility_changed() -> void:
	if visible and _dirty:
		_queue_refresh()


func _queue_refresh() -> void:
	_dirty = true
	if not visible or not is_inside_tree() or _rebuild_queued:
		return
	_rebuild_queued = true
	call_deferred("_rebuild")


func _process(delta: float) -> void:
	if not visible or not is_inside_tree():
		return
	if _brewing_tea_id != "" \
			and Time.get_ticks_msec() - _brew_started_msec >= int(FishingTeaSystem.BREW_SECONDS * 1000.0):
		FishingTeaSystem.resolve_pending_tea()
		_brewing_tea_id = ""
		_brewing_icon = null
		_queue_refresh()
	if _brewing_icon != null and is_instance_valid(_brewing_icon):
		_brewing_icon.position.x = sin(float(Time.get_ticks_msec()) * 0.012) * 1.8
	_live_accum += delta
	if _live_accum < 0.5:
		return
	_live_accum = 0.0
	_refresh_live()


func _refresh_live() -> void:
	if not FishingTeaSystem.is_unlocked():
		return
	var state := FishingTeaSystem.get_state()
	var timer := clampf(float(state.get("fish_timer", 0.0)), 0.0, FishingTeaSystem.ROD_INTERVAL)
	var progress := clampf(timer / FishingTeaSystem.ROD_INTERVAL, 0.0, 1.0)
	if _last_fish_timer >= 0.0 and timer + 0.5 < _last_fish_timer and _pond_stage != null:
		var logs: Array = state.get("recent_logs", [])
		var latest := str((logs[0] as Dictionary).get("text", "")) if not logs.is_empty() else "灵潭有得"
		_pond_stage.show_catch(latest)
	_last_fish_timer = timer
	if _progress_bar != null and is_instance_valid(_progress_bar):
		_progress_bar.value = progress
	if _pond_stage != null and is_instance_valid(_pond_stage):
		_pond_stage.fishing_active = bool(state.get("fishing_active", false))
		_pond_stage.progress = progress
	if _progress_label != null and is_instance_valid(_progress_label):
		var remain := maxf(0.0, FishingTeaSystem.ROD_INTERVAL - timer)
		_progress_label.text = "距下次收竿 %.1f 秒" % remain
	if _tea_banner != null and is_instance_valid(_tea_banner):
		var info := FishingTeaSystem.get_active_tea_info()
		_tea_banner.text = str(info.get("text", ""))


func _rebuild() -> void:
	_rebuild_queued = false
	if not is_inside_tree() or not visible:
		return
	_dirty = false
	_progress_bar = null
	_progress_label = null
	_tea_banner = null
	_pond_stage = null
	_brewing_icon = null
	var pending_state := FishingTeaSystem.get_state()
	var pending_id := str(pending_state.get("pending_tea_id", ""))
	if pending_id != "" and _brewing_tea_id == "":
		_brewing_tea_id = pending_id
		_brew_started_msec = int((float(pending_state.get("pending_tea_ready_unix", 0))
			- FishingTeaSystem.BREW_SECONDS) * 1000.0)
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()

	if not FishingTeaSystem.is_unlocked():
		_build_locked_card()
	else:
		_build_active_banner()
		_build_tabs()
		if _tab == "fishing":
			_build_fishing_tab()
		else:
			_build_tea_tab()
	ThemeBuilder.prepare_touch(self)
	_refresh_live()


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
	box.add_child(ThemeBuilder.card_title_label("灵潭清茗",
		ThemeBuilder.FONT_CARD_TITLE, ThemeBuilder.COLOR_TEXT_TITLE_GOLD))
	var frame := IconFrame.new()
	frame.setup(IconLibrary.get_ui_icon("tea_pot"), 72,
		ThemeBuilder.COLOR_TEXT_MUTED, false, 52)
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(frame)
	box.add_child(ThemeBuilder.wrap_label("需化神初期开启灵潭清茗。",
		ThemeBuilder.FONT_BODY, ThemeBuilder.COLOR_TEXT_PRIMARY))
	box.add_child(ThemeBuilder.wrap_label(
		"届时可在灵潭垂钓采集清露与灵鱼，并在洞府烹煮灵茶辅助修行。",
		ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_SECONDARY))


func _build_active_banner() -> void:
	var info := FishingTeaSystem.get_active_tea_info()
	if info.is_empty():
		return
	var card := ThemeBuilder.card_panel(ThemeBuilder.COLOR_JADE_SOFT,
		ThemeBuilder.COLOR_BORDER, 8, 8)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 44)
	_content.add_child(card)
	var row := ThemeBuilder.hbox(6)
	card.add_child(row)
	var active_icon := str(info.get("icon", "tea_pot"))
	row.add_child(ThemeBuilder.icon_rect(IconLibrary.get_icon(active_icon), 18))
	_tea_banner = ThemeBuilder.label(str(info.get("text", "")),
		ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_JADE)
	_tea_banner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tea_banner.clip_text = true
	_tea_banner.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(_tea_banner)


func _build_tabs() -> void:
	var row := ThemeBuilder.hbox(6)
	_content.add_child(row)
	var fishing := ThemeBuilder.small_button("灵潭垂钓")
	fishing.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fishing.toggle_mode = true
	fishing.button_pressed = _tab == "fishing"
	ThemeBuilder.apply_toggle_button(fishing, fishing.button_pressed)
	fishing.pressed.connect(Callable(self, "_set_tab").bind("fishing"))
	row.add_child(fishing)
	var tea := ThemeBuilder.small_button("洞府烹茶")
	tea.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tea.toggle_mode = true
	tea.button_pressed = _tab == "tea"
	ThemeBuilder.apply_toggle_button(tea, tea.button_pressed)
	tea.pressed.connect(Callable(self, "_set_tab").bind("tea"))
	row.add_child(tea)
	var help := ThemeBuilder.create_help_button(Callable(self, "_show_help"))
	help.custom_minimum_size = Vector2(44, 44)
	row.add_child(help)


func _set_tab(tab: String) -> void:
	if _tab == tab:
		return
	_tab = tab
	_queue_refresh()


func _build_fishing_tab() -> void:
	var status := _new_card()
	status.add_child(ThemeBuilder.card_title_label("灵潭垂钓",
		ThemeBuilder.FONT_CARD_TITLE, ThemeBuilder.COLOR_TEXT_TITLE_GOLD))
	var head := ThemeBuilder.hbox(8)
	status.add_child(head)
	var frame := IconFrame.new()
	frame.setup(IconLibrary.get_ui_icon("fishing_rod"), 48,
		ThemeBuilder.COLOR_JADE, false, 36)
	head.add_child(frame)
	var info := ThemeBuilder.vbox(4)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(info)
	var active := FishingTeaSystem.is_fishing_active()
	info.add_child(ThemeBuilder.label("垂钓中" if active else "已歇息",
		ThemeBuilder.FONT_BODY, ThemeBuilder.COLOR_TEXT_JADE if active
		else ThemeBuilder.COLOR_TEXT_SECONDARY))
	_progress_bar = ThemeBuilder.progress_bar(ThemeBuilder.COLOR_JADE, 7.0)
	info.add_child(_progress_bar)
	_progress_label = ThemeBuilder.label("", ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_SECONDARY)
	info.add_child(_progress_label)
	var toggle_text := "收竿歇息" if active else "开始垂钓"
	var toggle := ThemeBuilder.small_button(toggle_text)
	toggle.pressed.connect(Callable(self, "_toggle_fishing"))
	status.add_child(toggle)

	_pond_stage = TeaPondStage.new()
	_pond_stage.custom_minimum_size = Vector2(0, 104)
	_pond_stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pond_stage.clip_contents = true
	_pond_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status.add_child(_pond_stage)

	var logs := _new_card()
	logs.add_child(ThemeBuilder.card_title_label("灵潭收获纪要",
		ThemeBuilder.FONT_CARD_TITLE, ThemeBuilder.COLOR_TEXT_TITLE_GOLD))
	var state := FishingTeaSystem.get_state()
	var entries: Variant = state.get("recent_logs", [])
	var list: Array = entries if entries is Array else []
	if list.is_empty():
		logs.add_child(ThemeBuilder.label("尚无收获，灵潭静候垂钓。",
			ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_MUTED))
		return
	for value in list:
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = value
		var tone := str(entry.get("tone", "plain"))
		var log_color := ThemeBuilder.COLOR_TEXT_PRIMARY
		match tone:
			"jade":
				log_color = ThemeBuilder.COLOR_TEXT_JADE
			"gold":
				log_color = ThemeBuilder.COLOR_TEXT_GOLD
		var label := ThemeBuilder.label("• %s" % str(entry.get("text", "")),
			ThemeBuilder.FONT_CAPTION, log_color)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.clip_text = true
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.tooltip_text = label.text
		logs.add_child(label)


func _toggle_fishing() -> void:
	var active := FishingTeaSystem.toggle_fishing()
	EventBus.toast.emit("已开始灵潭垂钓" if active else "已收竿歇息")
	_queue_refresh()


func _build_tea_tab() -> void:
	var box := _new_card()
	box.add_child(ThemeBuilder.card_title_label("洞府烹茶",
		ThemeBuilder.FONT_CARD_TITLE, ThemeBuilder.COLOR_TEXT_TITLE_GOLD))
	box.add_child(ThemeBuilder.wrap_label("同时仅一款灵茶生效，重泡将替换并重新计时 60 分钟。",
		ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_SECONDARY))
	for tea_id in FishingTeaSystem.TEAS.keys():
		box.add_child(_tea_card(str(tea_id)))


func _tea_card(tea_id: String) -> PanelContainer:
	var key := FishingTeaSystem.normalize_tea_id(tea_id)
	var tea: Dictionary = FishingTeaSystem.TEAS[key]
	var unlocked := FishingTeaSystem.is_tea_unlocked(key)
	var card := ThemeBuilder.card_panel(
		ThemeBuilder.COLOR_CARD_DEEP if unlocked else ThemeBuilder.COLOR_SUBTLE,
		ThemeBuilder.COLOR_BORDER, 8, 8)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 128)
	var row := ThemeBuilder.hbox(8)
	card.add_child(row)
	var frame := IconFrame.new()
	frame.setup(IconLibrary.get_icon(str(tea.get("icon", "tea_pot"))), 44,
		ThemeBuilder.COLOR_JADE if unlocked else ThemeBuilder.COLOR_TEXT_MUTED, false, 34)
	row.add_child(frame)
	var info := ThemeBuilder.vbox(3)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.custom_minimum_size = Vector2(0, 0)
	row.add_child(info)
	var tea_name := ThemeBuilder.label(str(tea.get("name", "")),
		ThemeBuilder.FONT_BODY,
		ThemeBuilder.COLOR_TEXT_TITLE if unlocked else ThemeBuilder.COLOR_TEXT_MUTED)
	tea_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tea_name.clip_text = true
	tea_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	info.add_child(tea_name)
	if not unlocked:
		info.add_child(ThemeBuilder.label(FishingTeaSystem.get_tea_unlock_label(key),
			ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_DANGER))
		info.add_child(ThemeBuilder.wrap_label(str(tea.get("effect", "")),
			ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_MUTED))
	else:
		var enough := true
		enough = _add_material_row(info, "item_spirit_dew", int(tea.get("dew", 0))) and enough
		if int(tea.get("fish", 0)) > 0:
			enough = _add_material_row(info, "item_spirit_fish",
				int(tea.get("fish", 0))) and enough
		var herb_id := str(tea.get("herb_id", ""))
		if herb_id != "":
			enough = _add_material_row(info, herb_id, int(tea.get("herb_count", 0))) and enough
		info.add_child(ThemeBuilder.wrap_label(str(tea.get("effect", "")),
			ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_JADE))
	var brewing := _brewing_tea_id == key
	var brew := ThemeBuilder.small_button("文火慢煎中…" if brewing else "烹煮饮用")
	brew.custom_minimum_size = Vector2(96, ThemeBuilder.TOUCH_MIN)
	brew.size_flags_horizontal = Control.SIZE_SHRINK_END
	brew.disabled = not unlocked or brewing
	brew.tooltip_text = FishingTeaSystem.get_tea_unlock_label(key) if not unlocked else ""
	if brewing:
		_brewing_icon = frame
	brew.pressed.connect(Callable(self, "_brew").bind(key))
	row.add_child(brew)
	return card


func _add_material_row(parent: VBoxContainer, item_id: String, need: int) -> bool:
	var have := GameState.get_item_count(item_id)
	var enough := have >= need
	var row := ThemeBuilder.hbox(6)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_label := ThemeBuilder.label(DataRegistry.get_item_name(item_id),
		ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_SECONDARY)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(name_label)
	var count_label := ThemeBuilder.label("%d / %d" % [need, have],
		ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_JADE if enough else ThemeBuilder.COLOR_TEXT_DANGER)
	count_label.custom_minimum_size = Vector2(72, 0)
	count_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	ThemeBuilder.apply_font_size(count_label, ThemeBuilder.FONT_CAPTION)
	row.add_child(count_label)
	parent.add_child(row)
	return enough


func _brew(tea_id: String) -> void:
	var key := FishingTeaSystem.normalize_tea_id(tea_id)
	var result: Dictionary = FishingTeaSystem.brew_tea(key)
	if bool(result.get("ok", false)):
		_brewing_tea_id = key
		_brew_started_msec = Time.get_ticks_msec()
	EventBus.toast.emit(str(result.get("message", "")))
	_queue_refresh()


func _show_help() -> void:
	BottomSheet.show_help("灵潭清茗 · 图解", [
		{"text": "灵潭垂钓", "desc": "化神初期开启；每 12 秒自动收竿一次，连续九竿清露必有灵应，离线最多补算 120 竿。"},
		{"text": "灵茶时限", "desc": "同时仅一款生效，烹煮需文火慢煎 3 秒，茶香持续 60 分钟。"},
		{"text": "悟道清茶", "desc": "化神初期；灵潭清露×3 与凝露花×20，悟道池充能 +25%。"},
		{"text": "凝神灵茶", "desc": "化神后期；灵潭清露×3 与九叶仙芝×8，吐纳修为 +15%。"},
		{"text": "破厄剑茶", "desc": "炼虚初期；灵潭清露×4 与龙血草×8，秘境与镇魔塔攻击伤害 +12%。"},
		{"text": "灵鱼养神汤", "desc": "炼虚后期；灵潭清露×2、碧波灵鱼×2 与太乙青莲×5，全百艺经验与火候 +12%、动作耗时 -5%。"},
	])
