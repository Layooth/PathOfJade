class_name StatusSidebar
extends PanelContainer
## 宽屏（WIDE）右侧「洞府态势栏」：双槽运转卡 + 灵田微缩板 + 修行纪要。
## 只在 LayoutMode.WIDE 显示，窄屏隐藏但保持状态同步。

const SIDEBAR_WIDTH: float = 260.0
const LOG_LIMIT: int = 8
const LOG_COLORS: Dictionary = {
	"normal": ThemeBuilder.COLOR_TEXT_DIM,
	"good": ThemeBuilder.COLOR_JADE,
	"gold": ThemeBuilder.COLOR_AMBER,
	"warn": ThemeBuilder.COLOR_CINNABAR,
}

signal request_panel(page: String)

var _slot_views: Array[Dictionary] = []
## 灵田微缩格（图标/名称/倒计时/细进度条原地复用，不逐秒重建）
var _farm_cell_views: Array[Dictionary] = []
var _farm_chip: Label
## 当前境界标识：加粗无衬线，层数数字在宽屏右栏也清晰
var _realm_label: Label
## 宽屏右栏修为细条：与顶栏同源，运行时 0.22s 缓动追赶
var _cultivation_bar: ProgressBar
var _log_box: VBoxContainer
var _farm_all_button: Button
var _poll: float = 0.0
var _farm_poll: float = 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(SIDEBAR_WIDTH, 0)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_PASS
	var style := ThemeBuilder.panel_box(ThemeBuilder.COLOR_CHROME,
		ThemeBuilder.COLOR_BORDER, 0, 0, 12)
	style.set_border_width_all(0)
	style.border_width_left = 1
	style.border_color = ThemeBuilder.COLOR_BORDER
	style.bg_color = Color(0, 0, 0, 0)
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	add_theme_stylebox_override("panel", style)

	_build()
	_connect_signals()
	_refresh_all()
	set_process(true)


func _build() -> void:
	var scroll := ThemeBuilder.scroll_container()
	add_child(scroll)
	var box := ThemeBuilder.vbox(8)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)

	var title_row := ThemeBuilder.hbox(6)
	box.add_child(title_row)
	title_row.add_child(ThemeBuilder.card_title_label("洞府态势",
		ThemeBuilder.FONT_CARD_TITLE, ThemeBuilder.COLOR_AMBER))
	title_row.add_child(ThemeBuilder.expander())
	# 与顶栏境界胶囊同源的加粗无衬线，避免右栏缺一份「当前境界」信息
	_realm_label = ThemeBuilder.label("", ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT)
	ThemeBuilder.apply_realm_font(_realm_label)
	title_row.add_child(_realm_label)

	_cultivation_bar = ThemeBuilder.progress_bar(ThemeBuilder.COLOR_JADE, 3)
	_cultivation_bar.max_value = 1.0
	_cultivation_bar.value = 0.0
	box.add_child(_cultivation_bar)

	# ---- 三才运转卡：主修 / 分神 / 化身（未解锁槽位显示解锁境界提示）
	for slot in range(GameState.SLOT_COUNT):
		box.add_child(_build_slot_card(slot))

	box.add_child(ThemeBuilder.separator(1, ThemeBuilder.COLOR_BORDER))

	# ---- 灵田微缩板：标题角标 + 2×2 作物方格（图标/名称/倒计时/细进度条）
	var farm_head := ThemeBuilder.hbox(6)
	box.add_child(farm_head)
	farm_head.add_child(ThemeBuilder.section_title_label("洞府灵田",
		ThemeBuilder.FONT_BODY_SUB))
	_farm_chip = ThemeBuilder.label("", ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_SECONDARY)
	farm_head.add_child(_farm_chip)
	farm_head.add_child(ThemeBuilder.expander())
	var farm_jump := ThemeBuilder.small_button("前往")
	farm_jump.custom_minimum_size = Vector2(56, ThemeBuilder.TOUCH_MIN)
	ThemeBuilder.apply_font_size(farm_jump, ThemeBuilder.FONT_CAPTION)
	farm_jump.pressed.connect(func() -> void: request_panel.emit("farm"))
	farm_head.add_child(farm_jump)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	box.add_child(grid)
	for i in range(4):
		grid.add_child(_build_farm_cell(i))

	_farm_all_button = ThemeBuilder.small_button("一键收割并补种")
	_farm_all_button.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
	ThemeBuilder.apply_font_size(_farm_all_button, ThemeBuilder.FONT_CAPTION)
	ThemeBuilder.apply_primary_button(_farm_all_button)
	_farm_all_button.pressed.connect(_on_harvest_all_pressed)
	box.add_child(_farm_all_button)

	box.add_child(ThemeBuilder.separator(1, ThemeBuilder.COLOR_BORDER))

	# ---- 修行纪要
	box.add_child(ThemeBuilder.section_title_label("修行纪要",
		ThemeBuilder.FONT_BODY_SUB))
	_log_box = ThemeBuilder.vbox(3)
	_log_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(_log_box)


func _build_slot_card(slot: int) -> PanelContainer:
	var card := ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD, ThemeBuilder.COLOR_BORDER, 8, 8)
	var box := ThemeBuilder.vbox(3)
	card.add_child(box)

	var head := ThemeBuilder.hbox(6)
	box.add_child(head)
	var tag := ThemeBuilder.label(GameState.get_slot_name(slot),
		ThemeBuilder.FONT_CAPTION, _slot_color(slot))
	head.add_child(tag)
	var icon := IconFrame.new()
	icon.setup(IconLibrary.get_ui_icon("default"), 20, ThemeBuilder.COLOR_TEXT_DIM)
	head.add_child(icon)
	var name_label := ThemeBuilder.label("空闲", ThemeBuilder.FONT_BODY_SUB)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	head.add_child(name_label)

	var bar := ThemeBuilder.progress_bar(_slot_color(slot), 5)
	bar.max_value = 1.0
	bar.value = 0.0
	box.add_child(bar)

	var actions := ThemeBuilder.hbox(6)
	box.add_child(actions)
	var jump := ThemeBuilder.small_button("跳转")
	jump.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
	ThemeBuilder.apply_font_size(jump, ThemeBuilder.FONT_CAPTION)
	jump.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	jump.pressed.connect(func() -> void: _jump_slot(slot))
	actions.add_child(jump)
	var stop := ThemeBuilder.small_button("停止")
	stop.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
	ThemeBuilder.apply_font_size(stop, ThemeBuilder.FONT_CAPTION)
	stop.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stop.pressed.connect(func() -> void: _stop_slot(slot))
	actions.add_child(stop)

	_slot_views.append({
		"name": name_label, "bar": bar, "jump": jump, "stop": stop, "icon": icon,
		"tag": tag,
	})
	return card


## 槽位主色：主修玉青 / 分神鎏金 / 化身沉金
func _slot_color(slot: int) -> Color:
	if slot == 0:
		return ThemeBuilder.COLOR_JADE
	if slot == 1:
		return ThemeBuilder.COLOR_AMBER
	return ThemeBuilder.COLOR_TEXT_GOLD


func _connect_signals() -> void:
	EventBus.action_started.connect(_on_any_state)
	EventBus.action_stopped.connect(_on_any_state)
	# 读档恢复运转槽时不再重发 action_started（避免开场音效），由 game_loaded 直接刷新
	EventBus.game_loaded.connect(_refresh_all)
	EventBus.combat_started.connect(_on_any_state_str)
	EventBus.combat_stopped.connect(_on_any_state_str)
	EventBus.farm_changed.connect(_on_farm_changed)
	EventBus.activity_log_added.connect(_on_log_added)
	EventBus.inventory_changed.connect(_refresh_slots)
	EventBus.realm_changed.connect(_on_realm_changed)


func _on_any_state(_slot: int, _action_id: String) -> void:
	_refresh_slots()


func _on_any_state_str(_arg: String) -> void:
	_refresh_slots()


## 突破后吐纳名（吐纳筑基/筑基凝丹/凝丹化婴/元婴化神/证道飞升）要立刻换字
func _on_realm_changed(_realm_id: String, _realm_name: String) -> void:
	_refresh_realm()
	_refresh_slots()


func _on_farm_changed() -> void:
	_refresh_farm()


func _on_log_added(_entry: Dictionary) -> void:
	_refresh_logs()


func _process(delta: float) -> void:
	_poll += delta
	_farm_poll += delta
	if _poll >= 0.3:
		_poll = 0.0
		_refresh_progress()
	# 微缩灵田每秒刷新，与灵田面板同一倒计时来源
	if _farm_poll >= 1.0:
		_farm_poll = 0.0
		_refresh_farm()


func _refresh_all() -> void:
	_refresh_realm()
	_refresh_slots()
	_refresh_farm()
	_refresh_logs()


## 当前境界：与顶栏境界胶囊同源，右侧态势栏也能一眼看清「炼气九层 / 金丹中期」
func _refresh_realm() -> void:
	if _realm_label == null:
		return
	var realm := GameState.get_realm()
	_realm_label.text = "—" if realm == null else realm.display_name
	var requirement := GameState.get_realm_requirement()
	var target_ratio := clampf(GameState.cultivation_xp / requirement, 0.0, 1.0) \
		if requirement > 0.0 else 1.0
	UiMotion.advance_progress(_cultivation_bar, target_ratio, 0.22)


# ---------------------------------------------------------------- 双槽

func _refresh_slots() -> void:
	var combat_active := CombatEngine.is_active()
	for slot in range(_slot_views.size()):
		var view: Dictionary = _slot_views[slot]
		var name_label: Label = view["name"]
		var jump: Button = view["jump"]
		var stop: Button = view["stop"]

		if slot == 0 and combat_active:
			var enemy := CombatEngine.get_current_enemy()
			name_label.text = "秘境历练" if enemy == null else enemy.display_name
			name_label.add_theme_color_override("font_color", ThemeBuilder.COLOR_CINNABAR)
			var tower_icon := IconLibrary.get_enemy_icon("enemy_wild_wolf")
			if enemy != null:
				tower_icon = IconLibrary.get_enemy_icon(enemy.get_icon_key())
			(view["icon"] as IconFrame).set_icon(tower_icon, ThemeBuilder.COLOR_CINNABAR)
			jump.disabled = false
			stop.disabled = false
			continue

		# 秘境占主修位时，百艺顺延到分神位展示（与顶部胶囊、百艺槽位条同源）
		var action_id := GameState.get_display_action_id(slot)
		if action_id != "":
			var action := DataRegistry.get_action(action_id)
			var display_name := DataRegistry.get_action_name(action_id)
			if action != null and action.skill_id == "cultivation":
				# 吐纳分支不显示具体动作名，统一用境界修炼名，图标保持不变
				display_name = GameState.get_skill_display_name("cultivation")
			name_label.text = display_name
			name_label.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT)
			var accent := ThemeBuilder.COLOR_JADE if slot == 0 else ThemeBuilder.COLOR_AMBER
			if action != null:
				(view["icon"] as IconFrame).set_icon(
					IconLibrary.get_skill_icon(action.skill_id), accent)
			jump.disabled = false
			stop.disabled = false
		elif slot >= GameState.get_max_action_slots():
			name_label.text = GameState.get_slot_unlock_hint(slot)
			name_label.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT_DIM)
			(view["icon"] as IconFrame).set_icon(
				IconLibrary.get_ui_icon("default"), ThemeBuilder.COLOR_TEXT_DIM)
			jump.disabled = true
			stop.disabled = true
			(view["tag"] as Label).add_theme_color_override("font_color",
				ThemeBuilder.COLOR_TEXT_MUTED)
		else:
			name_label.text = "空闲"
			name_label.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT_DIM)
			(view["icon"] as IconFrame).set_icon(
				IconLibrary.get_ui_icon("default"), ThemeBuilder.COLOR_TEXT_DIM)
			jump.disabled = true
			stop.disabled = true
		# 立即写入真实进度（严禁清零等 0.3s 轮询回写——完工瞬间会让另两槽闪烁）
		(view["bar"] as ProgressBar).value = _slot_bar_value(slot)


## 槽位进度单一出口：洞府态势卡片与 0.3s 轮询共用，杜绝首帧归零跳变
func _slot_bar_value(slot: int) -> float:
	if slot == 0 and CombatEngine.is_active():
		var player_interval := maxf(0.5, float(GameState.get_player_stats()["interval"]))
		return clampf(CombatEngine.player_timer / player_interval, 0.0, 1.0)
	var real_slot := GameState.get_display_action_slot(slot)
	return ActionRunner.get_progress(real_slot) if real_slot >= 0 else 0.0


func _refresh_progress() -> void:
	for slot in range(_slot_views.size()):
		var view: Dictionary = _slot_views[slot]
		(view["bar"] as ProgressBar).value = _slot_bar_value(slot)


func _jump_slot(slot: int) -> void:
	if slot == 0 and CombatEngine.is_active():
		request_panel.emit("combat")
		return
	var real_slot := GameState.get_display_action_slot(slot)
	if real_slot < 0:
		request_panel.emit("farm" if slot == 1 else _last_skill())
		return
	var action := DataRegistry.get_action(GameState.get_active_action(real_slot))
	request_panel.emit(action.skill_id if action != null else "herbalism")


func _stop_slot(slot: int) -> void:
	if slot == 0 and CombatEngine.is_active():
		CombatEngine.stop_combat("态势栏撤出")
		_refresh_slots()
		return
	var real_slot := GameState.get_display_action_slot(slot)
	if real_slot >= 0:
		GameState.stop_action(real_slot)
	_refresh_slots()


func _last_skill() -> String:
	return "herbalism"


# ---------------------------------------------------------------- 灵田

## 灵田微缩格：图标+名称 / 倒计时 / 3px 成熟细进度条，空闲格虚线描边；
## 全部原地更新文本与贴图，逐秒刷新不重建节点
func _build_farm_cell(index: int) -> PanelContainer:
	var card := ThemeBuilder.card_panel(ThemeBuilder.COLOR_SUBTLE,
		ThemeBuilder.COLOR_BORDER, 8, 8)
	card.custom_minimum_size = Vector2(0, 58)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	var v := ThemeBuilder.vbox(2)
	card.add_child(v)
	var head := ThemeBuilder.hbox(4)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(head)
	var icon := IconFrame.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.setup(IconLibrary.get_ui_icon("farm"), 18, ThemeBuilder.COLOR_TEXT_DIM)
	head.add_child(icon)
	var name_label := ThemeBuilder.label("", ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_DIM)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(name_label)
	var time_label := ThemeBuilder.label("", ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_SECONDARY)
	time_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(time_label)
	var bar := ThemeBuilder.progress_bar(ThemeBuilder.COLOR_AMBER, 3)
	bar.max_value = 1.0
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(bar)
	# 空闲格虚线描边覆盖层（纯 _draw，零节点开销）
	var dash := DashBorder.new()
	dash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(dash)
	dash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dash.visible = false
	ThemeBuilder.make_card_tappable(card, _on_plot_pressed.bind(index))
	_farm_cell_views.append({
		"card": card, "icon": icon, "name": name_label,
		"time": time_label, "bar": bar, "dash": dash,
	})
	return card


## 空闲格柔和虚线描边（原生 StyleBoxFlat 无虚线，走轻量 _draw）
class DashBorder extends Control:
	var dash_color := Color(0.55, 0.50, 0.42, 0.7)


	func _ready() -> void:
		resized.connect(queue_redraw)


	func _draw() -> void:
		var r := Rect2(Vector2(1.5, 1.5), size - Vector2(3.0, 3.0))
		var seg := 5.0
		var gap := 4.0
		var x := r.position.x
		while x < r.end.x:
			draw_line(Vector2(x, r.position.y),
				Vector2(minf(x + seg, r.end.x), r.position.y), dash_color, 1.5)
			draw_line(Vector2(x, r.end.y),
				Vector2(minf(x + seg, r.end.x), r.end.y), dash_color, 1.5)
			x += seg + gap
		var y := r.position.y
		while y < r.end.y:
			draw_line(Vector2(r.position.x, y),
				Vector2(r.position.x, minf(y + seg, r.end.y)), dash_color, 1.5)
			draw_line(Vector2(r.end.x, y),
				Vector2(r.end.x, minf(y + seg, r.end.y)), dash_color, 1.5)
			y += seg + gap


func _refresh_farm() -> void:
	var ready := 0
	var empty := 0
	var planted := 0
	var unlocked_cnt := 0
	for i in range(_farm_cell_views.size()):
		var view: Dictionary = _farm_cell_views[i]
		var card: PanelContainer = view["card"]
		var icon: IconFrame = view["icon"]
		var name_label: Label = view["name"]
		var time_label: Label = view["time"]
		var bar: ProgressBar = view["bar"]
		var dash: Control = view["dash"]
		var border := ThemeBuilder.COLOR_BORDER
		var cell_bg := ThemeBuilder.COLOR_SUBTLE
		dash.visible = false
		bar.value = 0.0
		bar.visible = false
		time_label.text = ""
		if not FarmManager.is_unlocked(i):
			name_label.text = ["一", "二", "三", "四"][i] + "号 未开垦"
			name_label.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT_DIM)
			icon.set_icon(IconLibrary.get_ui_icon("farm"), ThemeBuilder.COLOR_TEXT_DIM)
			card.add_theme_stylebox_override("normal",
				ThemeBuilder.panel_box(cell_bg, border, 8, 1, 6))
			continue
		unlocked_cnt += 1
		if FarmManager.is_mature(i):
			ready += 1
			planted += 1
			name_label.text = "可收获"
			name_label.add_theme_color_override("font_color", ThemeBuilder.COLOR_JADE)
			border = ThemeBuilder.COLOR_JADE
			cell_bg = ThemeBuilder.COLOR_JADE_SOFT
			bar.visible = true
			bar.value = 1.0
			bar.add_theme_stylebox_override("fill",
				ThemeBuilder.panel_box(ThemeBuilder.COLOR_JADE, Color(0, 0, 0, 0), 2, 0, 0))
		elif FarmManager.is_empty(i):
			empty += 1
			name_label.text = "＋ 空闲"
			name_label.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT_DIM)
			dash.visible = true
			border = Color(0, 0, 0, 0)
		else:
			planted += 1
			var remaining := FarmManager.get_remaining(i)
			time_label.text = _compact_duration(remaining)
			name_label.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT)
			cell_bg = ThemeBuilder.COLOR_GOLD_SOFT
			bar.visible = true
			var plot: Dictionary = FarmManager.get_plot(i)
			var duration := maxf(1.0, float(plot.get("duration_sec", 1)))
			bar.value = clampf(1.0 - remaining / duration, 0.0, 1.0)
			bar.add_theme_stylebox_override("fill",
				ThemeBuilder.panel_box(ThemeBuilder.COLOR_AMBER, Color(0, 0, 0, 0), 2, 0, 0))
		# 作物图标与名称（生长中/成熟格）
		var plot2: Dictionary = FarmManager.get_plot(i)
		var seed_id := String(plot2.get("seed_id", ""))
		if seed_id != "":
			var seed_data := DataRegistry.get_seed(seed_id)
			var crop_id := String(seed_data.get("crop_id", ""))
			name_label.text = DataRegistry.get_item_name(crop_id) \
				if crop_id != "" else String(seed_data.get("name", "灵田"))
			if FarmManager.is_mature(i):
				name_label.text += " · 可收获"
			if crop_id != "":
				icon.set_icon(IconLibrary.get_item_icon(crop_id),
					ThemeBuilder.COLOR_JADE if FarmManager.is_mature(i) else ThemeBuilder.COLOR_TEXT_GOLD)
		card.add_theme_stylebox_override("normal",
			ThemeBuilder.panel_box(cell_bg, border, 8, 1, 6))
	# 标题角标：有熟显「N块已熟」，否则「N/M 耕作」
	if _farm_chip != null:
		if ready > 0:
			_farm_chip.text = "%d块已熟" % ready
			_farm_chip.add_theme_color_override("font_color", ThemeBuilder.COLOR_JADE)
		else:
			_farm_chip.text = "%d/%d 耕作" % [planted, unlocked_cnt]
			_farm_chip.add_theme_color_override("font_color",
				ThemeBuilder.COLOR_TEXT_SECONDARY)
	# 底部主按钮三态智能联动
	if ready > 0:
		_farm_all_button.disabled = false
		_farm_all_button.text = "一键收割并补种 (%d)" % ready
		ThemeBuilder.apply_primary_button(_farm_all_button)
	elif empty > 0:
		_farm_all_button.disabled = false
		_farm_all_button.text = "一键补种空地 (%d)" % empty
		ThemeBuilder.apply_secondary_button(_farm_all_button)
	else:
		_farm_all_button.disabled = true
		_farm_all_button.text = "一键收割并补种"
		ThemeBuilder.apply_secondary_button(_farm_all_button)


func _compact_duration(seconds: float) -> String:
	if seconds < 60.0:
		return "%d秒" % maxi(1, int(seconds))
	if seconds < 3600.0:
		return "%d分" % int(ceil(seconds / 60.0))
	return "%d时%d分" % [int(seconds / 3600.0), int(ceil(fmod(seconds, 3600.0) / 60.0))]


## 库存中品阶（售价）最高的灵种：空闲格一键快速补种用
func _best_seed_id() -> String:
	var best := ""
	var best_price := -1
	for seed_data in DataRegistry.get_all_seeds():
		var dict: Dictionary = seed_data
		var seed_id := String(dict.get("id", ""))
		if GameState.get_item_count(seed_id) <= 0:
			continue
		var item := DataRegistry.get_item(seed_id)
		var price := 0 if item == null else item.sell_price
		if price > best_price:
			best_price = price
			best = seed_id
	return best


func _on_plot_pressed(index: int) -> void:
	if not FarmManager.is_unlocked(index):
		request_panel.emit("shop")
		return
	if FarmManager.is_mature(index):
		FarmManager.harvest(index)
		return
	if FarmManager.is_empty(index):
		var seed := _best_seed_id()
		if seed == "":
			request_panel.emit("farm")
			return
		FarmManager.plant(index, seed)
		return
	request_panel.emit("farm")


func _on_harvest_all_pressed() -> void:
	var ready := 0
	var empty := 0
	for i in range(_farm_cell_views.size()):
		if not FarmManager.is_unlocked(i):
			continue
		if FarmManager.is_mature(i):
			ready += 1
		elif FarmManager.is_empty(i):
			empty += 1
	if ready > 0:
		FarmManager.harvest_all()
		FarmManager.replant_all()
	elif empty > 0:
		FarmManager.replant_all()
	else:
		return
	_refresh_farm()


# ---------------------------------------------------------------- 纪要

func _refresh_logs() -> void:
	if _log_box == null:
		return
	for child in _log_box.get_children():
		_log_box.remove_child(child)
		child.queue_free()
	var entries := GameState.get_recent_logs(LOG_LIMIT)
	if entries.is_empty():
		_log_box.add_child(ThemeBuilder.dim_label("暂无纪要，开始运转功法吧",
			ThemeBuilder.FONT_CAPTION))
		return
	for entry in entries:
		var dict: Dictionary = entry
		var row := ThemeBuilder.hbox(4)
		row.add_child(ThemeBuilder.label(String(dict.get("time", "")),
			ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_DIM))
		var tone := String(dict.get("tone", "normal"))
		var text_label := ThemeBuilder.label(String(dict.get("text", "")),
			ThemeBuilder.FONT_CAPTION,
			LOG_COLORS.get(tone, ThemeBuilder.COLOR_TEXT_DIM))
		text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(text_label)
		_log_box.add_child(row)
