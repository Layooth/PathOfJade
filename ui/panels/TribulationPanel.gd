class_name TribulationPanel
extends Control
## 「引动天劫」渡劫考核：条件检查 + 实时天雷监控（筑基天劫 / 结丹天劫共用）。

const MAX_LOG_LINES: int = 24

var _req_box: VBoxContainer
var _is_dirty: bool = false
var _start_button: Button
var _dao_heart_label: Label
var _limit_chip: PanelContainer
var _limit_label: Label
var _title_label: Label
## 当前境界标识（炼气一层 / 筑基后期 …）：加粗无衬线，层数数字清晰可读
var _realm_label: Label
## 自身气血残影条容器（Main/Ghost 双层，外层裁切）
var _hp_bar: Control
var _hp_label: Label
var _timeline_bar: ProgressBar
var _timeline_label: Label
var _countdown_label: Label
var _state_label: Label
var _result_label: Label
var _pips_row: HBoxContainer
var _pips: Array[PanelContainer] = []
var _log_box: VBoxContainer
var _log_scroll: ScrollContainer
var _stage: TribulationStage
## 监控卡 / 纪要卡：竖屏下纪要要移到监控下方才看得见
var _monitor_panel: PanelContainer
var _log_panel: PanelContainer
## 当前是否「修为已满但缺门票丹药」：主按钮转为「前往炼制」引导
var _ticket_missing: bool = false
## 上一次主按钮形态（primary / guide / locked），避免每次刷新重复叠加 StyleBox
var _last_button_mode: String = ""
var _result_seal: PanelContainer
var _ascension_banner: VBoxContainer
var _body: BoxContainer
var _left_col: VBoxContainer
var _right_col: VBoxContainer


func _ready() -> void:
	_build()
	_connect_signals()
	refresh_requirements()
	_update_static_state()


func _build() -> void:
	# 大字档下整页高度会超出 450×800：外层滚动，避免内容被底部导航截断
	var scroll := ThemeBuilder.scroll_container()
	add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var root := ThemeBuilder.vbox(10)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 10)
	scroll.add_child(root)

	# ---- 顶部
	var header := ThemeBuilder.card_panel()
	root.add_child(header)
	var head_box := ThemeBuilder.vbox(4)
	header.add_child(head_box)
	var title_row := ThemeBuilder.hbox(10)
	head_box.add_child(title_row)
	_title_label = ThemeBuilder.title_label("引动天劫", 20)
	title_row.add_child(_title_label)
	_limit_chip = ThemeBuilder.chip("限时 20 秒", ThemeBuilder.COLOR_CINNABAR)
	title_row.add_child(_limit_chip)
	_limit_label = _limit_chip.get_child(0) as Label
	var help := ThemeBuilder.create_help_button(_show_help)
	help.custom_minimum_size = Vector2(44, 44)
	help.tooltip_text = "查看渡劫规则"
	title_row.add_child(help)
	title_row.add_child(ThemeBuilder.expander())
	title_row.move_child(help, -1)
	# 当前境界：独立一行、加粗无衬线，便于玩家确认本次要渡的是哪个境界的天劫
	_realm_label = ThemeBuilder.label("", ThemeBuilder.FONT_BODY_SUB,
		ThemeBuilder.COLOR_TEXT)
	ThemeBuilder.apply_realm_font(_realm_label)
	head_box.add_child(_realm_label)
	_ascension_banner = ThemeBuilder.vbox(2)
	head_box.add_child(_ascension_banner)
	# 道心说明另起一行并允许换行：塞在标题行里会把整页最小宽度顶到 477
	_dao_heart_label = ThemeBuilder.wrap_label("", ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_DIM)
	head_box.add_child(_dao_heart_label)

	# 整页滚动：竖屏下「舞台 + 监控 + 条件 + 纪要」远超 800 高，
	# 不滚动会把天雷纪要挤出屏幕（其滚动区高度会塌成 0，玩家会以为日志没记录）
	# 外层 scroll 已负责整页滚动，此处绝不嵌套第二层（会把内容压成 0 高）

	# 宽屏左右双栏：左舞台+监控，右条件+纪要
	_body = BoxContainer.new()
	_body.vertical = true
	_body.add_theme_constant_override("separation", 10)
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_body)
	_left_col = ThemeBuilder.vbox(8)
	_left_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_left_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_left_col.size_flags_stretch_ratio = 1.05
	_body.add_child(_left_col)
	_right_col = ThemeBuilder.vbox(8)
	_right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_right_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_right_col.size_flags_stretch_ratio = 0.95
	_body.add_child(_right_col)

	# ---- 阵法舞台
	_stage = TribulationStage.new()
	_left_col.add_child(_stage)

	# ---- 条件
	var req_panel := ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD_DEEP, ThemeBuilder.COLOR_BORDER, 10, 10)
	_right_col.add_child(req_panel)
	var req_outer := ThemeBuilder.vbox(6)
	req_panel.add_child(req_outer)
	req_outer.add_child(ThemeBuilder.section_title_label("渡劫条件"))
	_req_box = ThemeBuilder.vbox(4)
	req_outer.add_child(_req_box)

	# ---- 天雷监控
	_monitor_panel = ThemeBuilder.card_panel()
	_left_col.add_child(_monitor_panel)
	var monitor_box := ThemeBuilder.vbox(8)
	_monitor_panel.add_child(monitor_box)

	var state_row := ThemeBuilder.hbox(10)
	monitor_box.add_child(state_row)
	# 与「天雷纪要」「渡劫条件」同款区块小标题：毛笔楷体 + 14 基准 + 沉金褐
	_state_label = ThemeBuilder.section_title_label("静候时机")
	state_row.add_child(_state_label)
	state_row.add_child(ThemeBuilder.expander())
	_countdown_label = ThemeBuilder.dim_label("", ThemeBuilder.FONT_CAPTION)
	state_row.add_child(_countdown_label)

	_pips_row = ThemeBuilder.hbox(8)
	monitor_box.add_child(_pips_row)

	_timeline_label = ThemeBuilder.dim_label("", ThemeBuilder.FONT_CAPTION)
	monitor_box.add_child(_timeline_label)
	_timeline_bar = ThemeBuilder.progress_bar(ThemeBuilder.COLOR_AMBER, 10)
	monitor_box.add_child(_timeline_bar)

	var hp_row := ThemeBuilder.hbox(8)
	monitor_box.add_child(hp_row)
	hp_row.add_child(ThemeBuilder.dim_label("自身气血", ThemeBuilder.FONT_CAPTION))
	hp_row.add_child(ThemeBuilder.expander())
	_hp_label = ThemeBuilder.dim_label("", ThemeBuilder.FONT_CAPTION)
	hp_row.add_child(_hp_label)
	_hp_bar = ThemeBuilder.create_afterimage_bar(ThemeBuilder.COLOR_JADE,
		ThemeBuilder.HP_GHOST_COLOR, 14.0)
	monitor_box.add_child(_hp_bar)

	_start_button = ThemeBuilder.button("引动天劫", true)
	_start_button.pressed.connect(_on_start_pressed)
	monitor_box.add_child(_start_button)

	_result_label = ThemeBuilder.wrap_label("", ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_AMBER)
	_result_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_result_label.custom_minimum_size = Vector2(0, 0)
	ThemeBuilder.apply_font_size(_result_label, ThemeBuilder.FONT_CAPTION)
	monitor_box.add_child(_result_label)

	# ---- 日志（给最小高度：否则在滚动容器里会被挤成 0 高，永远看不到天雷记录）
	_log_panel = ThemeBuilder.card_panel()
	_log_panel.custom_minimum_size = Vector2(0, 170)
	_log_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_right_col.add_child(_log_panel)
	var log_outer := ThemeBuilder.vbox(6)
	_log_panel.add_child(log_outer)
	log_outer.add_child(ThemeBuilder.section_title_label("天雷纪要"))
	_log_scroll = ThemeBuilder.scroll_container()
	_log_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_outer.add_child(_log_scroll)
	_log_box = ThemeBuilder.vbox(2)
	_log_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_scroll.add_child(_log_box)

	ThemeBuilder.prepare_touch(root)
	# 面板懒加载晚于首次 layout_changed，这里主动按当前工作区宽度排一次，
	# 保证竖屏首次进入时纪要卡就在监控下方
	_on_layout_changed(0, Vector2.ZERO, EventBus.workspace_width)


func _connect_signals() -> void:
	EventBus.tribulation_started.connect(_on_started)
	EventBus.tribulation_updated.connect(_on_updated)
	EventBus.tribulation_thunder.connect(_on_thunder)
	EventBus.tribulation_finished.connect(_on_finished)
	EventBus.combat_log.connect(_append_log)
	EventBus.layout_changed.connect(_on_layout_changed)
	EventBus.inventory_changed.connect(refresh_requirements)
	EventBus.cultivation_changed.connect(_on_cultivation_changed)
	EventBus.realm_changed.connect(_on_realm_changed)
	EventBus.stats_changed.connect(_update_static_state)
	visibility_changed.connect(_on_visibility_changed)


func refresh_requirements() -> void:
	if _req_box == null:
		return
	if not is_visible_in_tree():
		_is_dirty = true
		return
	_is_dirty = false
	_clear(_req_box)
	var realm := GameState.get_realm()
	var is_bottleneck := realm != null and realm.requires_tribulation
	var full := GameState.is_cultivation_full()
	var ticket_id := "" if realm == null else realm.tribulation_item
	var ticket_count := 0 if ticket_id == "" else GameState.get_item_count(ticket_id)
	var ticket_name := "无需门票" if ticket_id == "" else DataRegistry.get_item_name(ticket_id)
	var damages: Array = [] if realm == null else realm.tribulation_damages
	var duration := 20.0 if realm == null else realm.tribulation_duration
	var trib_name := "天劫" if realm == null or realm.tribulation_name == "" else realm.tribulation_name

	_title_label.text = "引动%s" % trib_name
	_limit_label.text = "限时 %d 秒" % int(duration)
	if _realm_label != null:
		_realm_label.text = "当前境界 · %s" % ("未知" if realm == null else realm.display_name)

	var tier := 0 if realm == null else realm.tier
	var stacks := GameState.get_dao_heart_stacks(tier)

	_add_req_row("%s修为圆满" % ("当前境界" if is_bottleneck else "（当前境界无需渡劫）"),
		is_bottleneck and full,
		"当前：%s（修为 %d%%）" % [
			"已至瓶颈" if is_bottleneck else ("%s" % ("未知" if realm == null else realm.display_name)),
			# 与顶栏一致向下取整，避免 99.6% 显示成 100% 却仍不可引劫
			int(floor(GameState.cultivation_xp / maxf(1.0, GameState.get_realm_requirement()) * 100.0)),
		])
	_add_ticket_row(ticket_id, ticket_name, ticket_count)
	_add_req_row("玄龟盾符 / 厚土护身符（择优护体）",
		true, "天雷降下前优先消耗玄龟盾符（-55%），无则用厚土护身符（-40%）")
	_add_req_row("道心悟性 %d / 5 层" % stacks, true, "本境界天雷伤害 -%d%%" % (stacks * 10))
	if realm != null and realm.tribulation_target == "magnificent":
		var ascension := FiveElementsSystem.ascension_ready()
		_req_box.add_child(ThemeBuilder.section_title_label("飞升三果"))
		_add_req_row("大乘后期修为圆满并持有渡劫飞升丹",
			bool(ascension.get("cultivation_ticket_ok", false)), "飞升天劫门票与修为门槛")
		_add_req_row("本命法宝已至先天至宝（31 重）",
			bool(ascension.get("natal_ok", false)), "本命法宝需温养至 31 重以上")
		_add_req_row("五行法则金木水火土均至少 1 重",
			bool(ascension.get("laws_ok", false)), "五条法则缺一不可")
		if _ascension_banner != null:
			_clear(_ascension_banner)
			var ticket_ok := bool(ascension.get("cultivation_ticket_ok", false))
			var natal_ok := bool(ascension.get("natal_ok", false))
			var laws_ok := bool(ascension.get("laws_ok", false))
			_add_banner_line("%s · 修为圆满并持有渡劫飞升丹" % ("已齐" if ticket_ok else "待补"), ticket_ok)
			_add_banner_line("%s · 本命法宝先天至宝（31 重）" % ("已齐" if natal_ok else "待补"), natal_ok)
			_add_banner_line("%s · 五行法则五条均至少 1 重" % ("已齐" if laws_ok else "待补"), laws_ok)
	elif _ascension_banner != null:
		_clear(_ascension_banner)

	_dao_heart_label.text = "道心悟性 %d 层 · 天雷 -%d%%" % [stacks, stacks * 10]
	_timeline_label.text = "天劫进度（%d 秒 · 每 4 秒一雷）" % int(duration)
	_rebuild_pips(damages.size())
	_refresh_button_state()


func _rebuild_pips(count: int) -> void:
	if _pips_row == null:
		return
	_clear(_pips_row)
	_pips.clear()
	var total := maxi(1, count)
	for i in range(total):
		var pip := PanelContainer.new()
		pip.add_theme_stylebox_override("panel",
			ThemeBuilder.panel_box(ThemeBuilder.COLOR_CARD_DEEP, ThemeBuilder.COLOR_BORDER, 6, 1, 6))
		pip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_pips_row.add_child(pip)
		var pip_label := ThemeBuilder.label("第%d雷" % (i + 1),
			ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_DIM)
		pip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if total > 5:
			pip_label.text = str(i + 1)
		pip.add_child(pip_label)
		_pips.append(pip)


func _show_help() -> void:
	var realm := GameState.get_realm()
	var ticket_id := "" if realm == null else realm.tribulation_item
	var ticket_text := "门票" if ticket_id == "" else DataRegistry.get_item_name(ticket_id)
	var thunder_count := 0 if realm == null else realm.tribulation_damages.size()
	BottomSheet.show_help("引动天劫 · 规则", [
		{"text": "渡劫流程", "desc": "修为圆满后投入%s，%d 道天雷将依次落下，限时 20 秒。" % [ticket_text, thunder_count]},
		{"text": "失败代价", "desc": "渡劫失败不扣修为、不删档，并永久获得道心悟性；悟性可降低后续天雷伤害。"},
		{"text": "护身符", "desc": "天雷降下前自动择优消耗玄龟盾符（-55%）或厚土护身符（-40%）。"},
	])


func _add_req_row(title_text: String, ok: bool, detail: String) -> void:
	var row := ThemeBuilder.hbox(8)
	row.add_child(ThemeBuilder.label("●" if ok else "○", 13,
		ThemeBuilder.COLOR_JADE if ok else ThemeBuilder.COLOR_CINNABAR))
	var col := ThemeBuilder.vbox(0)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	col.add_child(ThemeBuilder.label(title_text, 13,
		ThemeBuilder.COLOR_TEXT if ok else ThemeBuilder.COLOR_TEXT_DIM))
	if detail != "":
		col.add_child(ThemeBuilder.wrap_label(detail, ThemeBuilder.FONT_CAPTION))
	_req_box.add_child(row)


func _add_banner_line(text_value: String, ok: bool) -> void:
	if _ascension_banner == null:
		return
	var label := ThemeBuilder.label("", ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_JADE if ok else ThemeBuilder.COLOR_TEXT_DIM)
	ThemeBuilder.apply_font_size(label, ThemeBuilder.FONT_CAPTION)
	var max_w := minf(EventBus.current_viewport.x - 32.0, 460.0) - 32.0
	ThemeBuilder.fit_wrapped_label(label, ("● " if ok else "○ ") + text_value,
		null, 0.0, max_w)
	_ascension_banner.add_child(label)


## 门票丹药条件行：不足时整行可点（看配方），右侧给「去炼制 ▸」金色提示。
## 容器 PASS + 8px 容差（ThemeBuilder.make_card_tappable），不会吞掉列表滑动。
func _add_ticket_row(ticket_id: String, ticket_name: String, count: int) -> void:
	var lacking := ticket_id != "" and count < 1
	var row := ThemeBuilder.hbox(8)
	row.add_child(ThemeBuilder.label("○" if lacking else "●", 13,
		ThemeBuilder.COLOR_TEXT_DANGER if lacking else ThemeBuilder.COLOR_JADE))
	var col := ThemeBuilder.vbox(0)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	col.add_child(ThemeBuilder.label(
		"%s（当前 %s）" % [ticket_name, GameFormulas.format_num(float(count))], 13,
		ThemeBuilder.COLOR_TEXT_MUTED if lacking else ThemeBuilder.COLOR_TEXT_PRIMARY))
	if ticket_id != "":
		col.add_child(ThemeBuilder.wrap_label(
			"丹道炼制可得 · 点此查看配方" if lacking else "丹道炼制可得",
			ThemeBuilder.FONT_CAPTION))
	if lacking:
		var hint := ThemeBuilder.label("去炼制 ▸", ThemeBuilder.FONT_CAPTION,
			ThemeBuilder.COLOR_TEXT_GOLD)
		hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(hint)
		ThemeBuilder.make_card_tappable(row, _show_ticket_recipe)
	_req_box.add_child(row)


## 配方浮层：解锁等级 / 耗时 / 逐项材料库存（缺料标朱砂）+ 直达炼丹
func _show_ticket_recipe() -> void:
	var realm := GameState.get_realm()
	if realm == null or realm.tribulation_item == "":
		return
	var pill_id := realm.tribulation_item
	var action := _craft_action_for(pill_id)
	if action == null:
		EventBus.toast.emit("暂未找到「%s」的炼制配方" % DataRegistry.get_item_name(pill_id))
		return
	if AudioManager != null:
		AudioManager.play_tap()
	var rows: Array = []
	rows.append({
		"text": "%s · 炼丹 %d 重解锁" % [action.display_name, action.required_level],
		"desc": "单次耗时约 %.1f 秒，产 1 枚；解锁后可常态运转批量炼制。" % action.base_interval,
	})
	for key in action.inputs.keys():
		var need := int(action.inputs[key])
		var have := GameState.get_item_count(String(key))
		var lacking := have < need
		rows.append({
			"text": "%s ×%d" % [DataRegistry.get_item_name(String(key)), need],
			"desc": ("库存 %d · 缺 %d" % [have, need - have]) if lacking \
				else ("库存 %d · 充足" % have),
			"color": ThemeBuilder.COLOR_TEXT_DANGER if lacking else ThemeBuilder.COLOR_TEXT_JADE,
		})
	rows.append({
		"text": "前往炼丹 ▸",
		"desc": "跳到炼丹页并定位「%s」。" % action.display_name,
		"color": ThemeBuilder.COLOR_TEXT_GOLD,
		"callback": _go_craft_pill,
	})
	BottomSheet.show_text(DataRegistry.get_item_name(pill_id), rows)


## 反查该丹药的炼丹动作（不依赖倒排优先级，避免拿到怪物掉落这类来源）
func _craft_action_for(item_id: String) -> ActionData:
	for entry in DataRegistry.actions.values():
		var action := entry as ActionData
		if action != null and action.skill_id == "alchemy" and action.outputs.has(item_id):
			return action
	return null


## 跳到「百艺 · 炼丹」并定位高亮目标配方（未解锁的配方同样会定位并显示解锁等级）
func _go_craft_pill() -> void:
	var realm := GameState.get_realm()
	if realm == null or realm.tribulation_item == "":
		return
	var sources := DataRegistry.get_item_sources(realm.tribulation_item)
	for source in sources:
		if String(source.get("type", "")) == "skill":
			EventBus.navigate_to_source.emit(source)
			return
	if not sources.is_empty():
		EventBus.navigate_to_source.emit(sources[0])
		return
	EventBus.toast.emit("暂无「%s」的已知来源" % DataRegistry.get_item_name(realm.tribulation_item))


func _refresh_button_state() -> void:
	var check := CombatEngine.can_start_tribulation()
	var ok := bool(check.get("ok", false))
	var realm := GameState.get_realm()
	var ticket_id := "" if realm == null else realm.tribulation_item
	var ticket_text := "" if ticket_id == "" else "（消耗 %s ×1）" % DataRegistry.get_item_name(ticket_id)
	# 只有「修为已满 + 缺门票丹药」才转引导，其它前置不满足仍是禁用文案
	_ticket_missing = not ok and ticket_id != "" \
		and String(check.get("reason", "")) == "missing_ticket"
	if CombatEngine.is_tribulation_active():
		_start_button.text = "天雷将至，凝神应对"
		_start_button.disabled = true
		_set_button_mode("locked")
	elif _ticket_missing:
		# 缺丹不再死锁：可点击的「前往炼制」引导，直接跳到炼丹配方
		_start_button.text = "前往炼制 · %s ▸" % DataRegistry.get_item_name(ticket_id)
		_start_button.disabled = false
		_set_button_mode("guide")
	else:
		_start_button.disabled = not ok
		_start_button.text = ("引动天劫%s" % ticket_text) if ok else String(check.get("message", ""))
		_set_button_mode("primary" if ok else "locked")


## 主按钮三态样式：primary（玉青实底）/ guide（鎏金描边）/ locked（灰底 + 淡烟灰字）
func _set_button_mode(mode: String) -> void:
	if _start_button == null or mode == _last_button_mode:
		return
	_last_button_mode = mode
	_start_button.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
	if mode == "guide":
		var normal := ThemeBuilder.panel_box(ThemeBuilder.COLOR_GOLD_SOFT,
			ThemeBuilder.COLOR_AMBER, 8, 1, 12)
		normal.border_width_bottom = 2
		_start_button.add_theme_stylebox_override("normal", normal)
		var hover := ThemeBuilder.panel_box(ThemeBuilder.COLOR_GOLD_SOFT.darkened(0.05),
			ThemeBuilder.COLOR_AMBER, 8, 1, 12)
		hover.border_width_bottom = 2
		_start_button.add_theme_stylebox_override("hover", hover)
		_start_button.add_theme_stylebox_override("pressed",
			ThemeBuilder.panel_box(ThemeBuilder.COLOR_GOLD_SOFT.darkened(0.09),
				ThemeBuilder.COLOR_AMBER, 8, 0, 12))
		for key in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
			_start_button.add_theme_color_override(key, ThemeBuilder.COLOR_TEXT_GOLD)
		return
	ThemeBuilder.apply_primary_button(_start_button)
	_start_button.add_theme_color_override("font_disabled_color", ThemeBuilder.COLOR_TEXT_MUTED)


func _update_static_state() -> void:
	if _hp_bar == null:
		return
	var max_hp := GameState.get_max_hp()
	UiMotion.set_afterimage_value(_hp_bar,
		clampf(float(GameState.current_hp) / float(maxi(1, max_hp)), 0.0, 1.0), true)
	UiMotion.breathe_alpha(_hp_bar, false)
	_hp_label.text = "%d / %d" % [GameState.current_hp, max_hp]
	if not CombatEngine.is_tribulation_active():
		_timeline_bar.value = 0.0
		if _start_button != null:
			_refresh_button_state()


# ---------------------------------------------------------------- 事件

func _on_start_pressed() -> void:
	# 缺丹态：主按钮是「前往炼制」引导，点击轻震并跳到炼丹配方
	if _ticket_missing:
		GameState.vibrate_light()
		_go_craft_pill()
		return
	# 先清空再引劫：start_tribulation() 内部已经写入「引动…」与「盘坐崖顶」两行，
	# 若在之后清空会把这两行一起抹掉
	_result_label.text = ""
	_clear(_log_box)
	var result := CombatEngine.start_tribulation()
	if not bool(result.get("ok", false)):
		return
	_refresh_button_state()


func _on_started() -> void:
	_state_label.text = "天雷将至"
	_state_label.add_theme_color_override("font_color", ThemeBuilder.COLOR_CINNABAR)
	_countdown_label.text = "第一道天雷：4.0s"
	_timeline_bar.value = 0.0
	for i in range(_pips.size()):
		_style_pip(i, false)
	_refresh_button_state()
	_append_log("你盘坐崖顶，天穹骤暗。")


func _on_updated(elapsed: float, duration: float, hp: int, max_hp: int, next_in: float) -> void:
	_timeline_bar.value = clampf(elapsed / maxf(1.0, duration), 0.0, 1.0)
	var ratio := clampf(float(hp) / float(maxi(1, max_hp)), 0.0, 1.0)
	UiMotion.set_afterimage_value(_hp_bar, ratio)
	UiMotion.breathe_alpha(_hp_bar, ratio > 0.0 and ratio < 0.30)
	_hp_label.text = "%d / %d" % [hp, max_hp]
	if next_in > 0.05:
		_countdown_label.text = "下一道天雷：%.1fs" % next_in
	else:
		_countdown_label.text = "天雷已渡"


func _on_thunder(index: int, damage: int, warded: bool, hp: int, max_hp: int) -> void:
	_style_pip(index, true)
	var ratio := clampf(float(hp) / float(maxi(1, max_hp)), 0.0, 1.0)
	UiMotion.set_afterimage_value(_hp_bar, ratio)
	UiMotion.breathe_alpha(_hp_bar, ratio > 0.0 and ratio < 0.30)
	_hp_label.text = "%d / %d" % [hp, max_hp]
	_state_label.text = "第 %d 道天雷 · -%d 气血" % [index + 1, damage]
	if warded:
		_countdown_label.text = "护身符已生效"


func _on_finished(success: bool, message: String) -> void:
	UiMotion.breathe_alpha(_hp_bar, false)
	_state_label.text = "渡劫成功" if success else "渡劫失败"
	_state_label.add_theme_color_override("font_color",
		ThemeBuilder.COLOR_JADE if success else ThemeBuilder.COLOR_CINNABAR)
	if _result_seal != null and is_instance_valid(_result_seal):
		_result_seal.queue_free()
		_result_seal = null
	if success:
		var realm := GameState.get_realm()
		var realm_name := "下一境界" if realm == null else realm.display_name
		ThemeBuilder.fit_wrapped_label(_result_label,
			"%s，已晋入%s。技能上限提升，新配方与秘境同步开放。" % [message, realm_name],
			null, 0.0, minf(EventBus.current_viewport.x - 32.0, 460.0) - 32.0)
		# 居中里程碑横幅：渡劫成功（暖墨描金匾额 + 落印）
		if InkVfxLayer.instance != null:
			InkVfxLayer.instance.play_breakthrough("渡劫成功 · %s" % realm_name,
				ThemeBuilder.COLOR_AMBER,
				"道体蜕变，百艺上限升至 %d 重" % int(realm.skill_level_cap), "证")
		# 「证道」落款朱砂印
		var parent := _result_label.get_parent()
		if parent != null:
			_result_seal = ThemeBuilder.create_seal_badge("证道", "cinnabar")
			parent.add_child(_result_seal)
			parent.move_child(_result_seal, _result_label.get_index())
	else:
		ThemeBuilder.fit_wrapped_label(_result_label,
			"%s。修为未损，道心悟性 +1（当前 %d 层）。可再备门票重试。" % [
				message, GameState.get_dao_heart_stacks()],
			null, 0.0, minf(EventBus.current_viewport.x - 32.0, 460.0) - 32.0)
	_result_label.add_theme_color_override("font_color",
		ThemeBuilder.COLOR_JADE if success else ThemeBuilder.COLOR_AMBER)
	_countdown_label.text = ""
	refresh_requirements()
	_update_static_state()


func _style_pip(index: int, struck: bool) -> void:
	if index < 0 or index >= _pips.size():
		return
	var pip := _pips[index]
	if struck:
		pip.add_theme_stylebox_override("panel",
			ThemeBuilder.panel_box(ThemeBuilder.COLOR_CINNABAR_SOFT,
				ThemeBuilder.COLOR_CINNABAR_EDGE, 6, 1, 6))
	else:
		pip.add_theme_stylebox_override("panel",
			ThemeBuilder.panel_box(ThemeBuilder.COLOR_CARD_DEEP, ThemeBuilder.COLOR_BORDER, 6, 1, 6))


func _on_layout_changed(_mode: int, _vp_size: Vector2, workspace_width: float) -> void:
	var compact := workspace_width < 680.0
	if _body != null:
		_body.vertical = compact
	# 竖屏把「天雷纪要」提到监控下方：渡劫时它才是正在刷新的信息，
	# 放在条件卡之后会被挤出首屏（实测 y≈988），玩家以为日志没记录
	if _log_panel != null and is_instance_valid(_log_panel):
		if compact:
			if _log_panel.get_parent() != _left_col:
				_log_panel.reparent(_left_col, false)
		elif _log_panel.get_parent() != _right_col:
			_log_panel.reparent(_right_col, false)


func _on_visibility_changed() -> void:
	set_process(is_visible_in_tree())
	if is_visible_in_tree() and _is_dirty:
		_is_dirty = false
		refresh_requirements()


func _on_cultivation_changed(_current: float, _required: float, _full: bool) -> void:
	refresh_requirements()


func _on_realm_changed(_realm_id: String, _realm_name: String) -> void:
	refresh_requirements()


func _append_log(line: String) -> void:
	if _log_box == null:
		return
	_log_box.add_child(ThemeBuilder.wrap_label(line, ThemeBuilder.FONT_BODY_SUB))
	while _log_box.get_child_count() > MAX_LOG_LINES:
		var first := _log_box.get_child(0)
		_log_box.remove_child(first)
		first.queue_free()
	call_deferred("_scroll_to_bottom")


func _scroll_to_bottom() -> void:
	if _log_scroll == null:
		return
	var bar := _log_scroll.get_v_scroll_bar()
	if bar != null:
		_log_scroll.scroll_vertical = int(bar.max_value)


func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()



