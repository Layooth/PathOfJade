class_name TowerPanel
extends Control
## 「镇魔塔」无尽冲层：动态妖魔、首通奖励、自动冲层、历史最高层持久化。

const UNLOCK_ORDER: int = 9
const UNLOCK_LABEL: String = "筑基初期"
const UNLOCK_DESC: String = "镇魔塔可逐层挑战妖魔，领取首通灵石与每日俸禄，并记录历史最高层。突破至筑基初期后开启。"

var _normal_root: Control
var _lock_card: PanelContainer
var _stage: CombatStage
var _floor_label: Label
var _best_label: Label
var _next_reward_label: Label
var _salary_button: Button
## 连闯期间普通层首通的累计灵石（合并轻气泡播报）
var _auto_run_stones: int = 0
var _enemy_stat_label: RichTextLabel
var _reward_label: Label
var _potion_row: GridContainer
var _start_button: Button
var _stop_button: Button
var _auto_button: Button
var _prev_button: Button
var _next_button: Button
var _floor: int = 1
var _poll: float = 0.0
var _body: BoxContainer
var _left_col: VBoxContainer
var _right_col: VBoxContainer
var _is_dirty: bool = false


func _ready() -> void:
	_floor = maxi(1, GameState.tower_highest_floor + 1)
	_build()
	EventBus.combat_started.connect(_on_any_state)
	EventBus.combat_stopped.connect(_on_any_state_str)
	EventBus.combat_updated.connect(_on_updated)
	EventBus.combat_enemy_defeated.connect(_on_enemy_defeated_for_ring)
	EventBus.layout_changed.connect(_on_layout_changed)
	EventBus.inventory_changed.connect(_refresh_potion_capsules)
	EventBus.realm_changed.connect(_on_realm_changed_for_gate)
	visibility_changed.connect(_on_visibility_changed)
	_apply_unlock_gate()
	refresh()


func _on_realm_changed_for_gate(_realm_id: String, _realm_name: String) -> void:
	_apply_unlock_gate()
	refresh()


func _process(delta: float) -> void:
	# 蓄势条必须逐帧驱动：原先只有秘境页在推 set_charge，
	# 镇魔塔舞台的细进度条一直停在 0（看起来「不走」）
	_update_stage_charge()
	_poll += delta
	if _poll < 0.5:
		return
	_poll = 0.0
	_refresh_live()


## 镇魔塔战斗蓄势：与秘境页同一口径（我方攻击间隔 / 敌方攻击间隔）
func _update_stage_charge() -> void:
	if _stage == null:
		return
	if not CombatEngine.is_active() or CombatEngine.tower_floor <= 0:
		_stage.set_charge(0.0, 0.0)
		return
	var stats := GameState.get_player_stats()
	var player_interval := maxf(0.5, float(stats["interval"]))
	var enemy := CombatEngine.get_current_enemy()
	var enemy_ratio := 0.0
	if enemy != null:
		enemy_ratio = clampf(CombatEngine.enemy_timer / maxf(0.5, enemy.attack_interval),
			0.0, 1.0)
	_stage.set_charge(
		clampf(CombatEngine.player_timer / player_interval, 0.0, 1.0), enemy_ratio)


func _is_unlocked() -> bool:
	return GameState.get_realm_index() >= UNLOCK_ORDER


func _apply_unlock_gate() -> void:
	if _normal_root == null:
		return
	var unlocked := _is_unlocked()
	_normal_root.visible = unlocked
	if _lock_card != null:
		_lock_card.visible = not unlocked
	if not unlocked and _stage != null:
		_stage.clear_preview()


func _build_lock_card() -> PanelContainer:
	var card := ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD_DEEP,
		ThemeBuilder.COLOR_BORDER, 10, 16)
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box := ThemeBuilder.vbox(12)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(box)
	var title := ThemeBuilder.title_label("需%s · 镇魔塔" % UNLOCK_LABEL,
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
	title_row.add_child(ThemeBuilder.icon_rect(IconLibrary.get_ui_icon("tower"), 24))
	title_row.add_child(ThemeBuilder.title_label("镇魔塔", 20))
	title_row.add_child(ThemeBuilder.expander())
	_best_label = ThemeBuilder.label("历史最高 0 层", ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_AMBER)
	title_row.add_child(_best_label)
	var help := ThemeBuilder.create_help_button(_show_help)
	help.custom_minimum_size = Vector2(44, 44)
	help.tooltip_text = "查看镇魔塔规则"
	title_row.add_child(help)

	# 每日俸禄上移至标题卡：紧凑贴右，释放中间操作区一整行
	var salary_row := ThemeBuilder.hbox(6)
	head.add_child(salary_row)
	salary_row.add_child(ThemeBuilder.expander())
	_salary_button = ThemeBuilder.button("领取今日俸禄")
	_salary_button.custom_minimum_size = Vector2(160, ThemeBuilder.TOUCH_MIN)
	_salary_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	ThemeBuilder.apply_font_size(_salary_button, ThemeBuilder.FONT_CAPTION)
	ThemeBuilder.apply_brush_kai(_salary_button)
	ThemeBuilder.apply_secondary_button(_salary_button)
	_salary_button.pressed.connect(_on_salary_pressed)
	salary_row.add_child(_salary_button)

	# 宽屏左右双栏
	var body := BoxContainer.new()
	body.vertical = true
	body.add_theme_constant_override("separation", 10)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	var left := ThemeBuilder.vbox(8)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.15
	body.add_child(left)
	_left_col = left
	var right := ThemeBuilder.vbox(8)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_stretch_ratio = 0.85
	body.add_child(right)
	_right_col = right
	_body = body

	_floor_label = ThemeBuilder.card_title_label("镇魔塔 · 第 1 层",
		ThemeBuilder.FONT_CARD_TITLE, ThemeBuilder.COLOR_AMBER)
	_floor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left.add_child(_floor_label)
	# 首通节点神赐预告：下一重奖内容一目了然
	_next_reward_label = ThemeBuilder.wrap_label("", ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_JADE)
	ThemeBuilder.apply_font_size(_next_reward_label, ThemeBuilder.FONT_CAPTION)
	_next_reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_next_reward_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_next_reward_label.custom_minimum_size = Vector2(0, 0)
	_next_reward_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(_next_reward_label)

	_stage = CombatStage.new()
	# 严格模式隔离：镇魔塔舞台只吃镇魔塔战斗信号（秘境战斗不进血条/飘字）
	_stage.mode_filter = "tower"
	left.add_child(_stage)

	var button_row := ThemeBuilder.hbox(6)
	left.add_child(button_row)
	_prev_button = ThemeBuilder.small_button("上一层")
	_prev_button.custom_minimum_size = Vector2(0, 44)
	ThemeBuilder.apply_font_size(_prev_button, ThemeBuilder.FONT_CAPTION)
	_prev_button.pressed.connect(_on_floor_step.bind(-1))
	button_row.add_child(_prev_button)
	_next_button = ThemeBuilder.small_button("下一层")
	_next_button.custom_minimum_size = Vector2(0, 44)
	ThemeBuilder.apply_font_size(_next_button, ThemeBuilder.FONT_CAPTION)
	_next_button.pressed.connect(_on_floor_step.bind(1))
	button_row.add_child(_next_button)

	_start_button = ThemeBuilder.button("开始冲层")
	_start_button.custom_minimum_size = Vector2(0, 46)
	_start_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_start_button.size_flags_stretch_ratio = 6.0
	ThemeBuilder.apply_font_size(_start_button, ThemeBuilder.FONT_CARD_TITLE)
	ThemeBuilder.apply_brush_kai(_start_button)
	ThemeBuilder.apply_primary_button(_start_button)
	_start_button.pressed.connect(_on_start_pressed)
	button_row.add_child(_start_button)
	_stop_button = ThemeBuilder.button("撤出镇魔塔")
	_stop_button.custom_minimum_size = Vector2(0, 46)
	_stop_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stop_button.size_flags_stretch_ratio = 4.0
	ThemeBuilder.apply_font_size(_stop_button, 14)
	ThemeBuilder.apply_brush_kai(_stop_button)
	ThemeBuilder.apply_secondary_button(_stop_button)
	_stop_button.pressed.connect(_on_stop_pressed)
	button_row.add_child(_stop_button)

	_auto_button = ThemeBuilder.small_button("连闯下一层")
	_auto_button.toggle_mode = true
	_auto_button.button_pressed = GameState.is_flag("tower_auto", true)
	_auto_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ThemeBuilder.apply_font_size(_auto_button, ThemeBuilder.FONT_CAPTION)
	ThemeBuilder.apply_toggle_button(_auto_button, _auto_button.button_pressed)
	_auto_button.toggled.connect(_on_auto_toggled)
	left.add_child(_auto_button)

	var info := ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD_DEEP, ThemeBuilder.COLOR_BORDER, 12, 10)
	info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(info)
	var info_box := ThemeBuilder.vbox(6)
	info.add_child(info_box)
	info_box.add_child(ThemeBuilder.section_title_label("当前层妖魔",
		ThemeBuilder.FONT_CAPTION))
	# 妖魔名用品阶 BBCode（按楼层折算），属性行跟随
	_enemy_stat_label = ThemeBuilder.bbcode_label("", ThemeBuilder.FONT_BODY_SUB)
	info_box.add_child(_enemy_stat_label)
	info_box.add_child(ThemeBuilder.separator(1, ThemeBuilder.COLOR_BORDER))
	info_box.add_child(ThemeBuilder.section_title_label("首通奖励",
		ThemeBuilder.FONT_CAPTION))
	_reward_label = ThemeBuilder.wrap_label("", ThemeBuilder.FONT_BODY_SUB)
	ThemeBuilder.apply_font_size(_reward_label, ThemeBuilder.FONT_BODY_SUB)
	_reward_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_reward_label.custom_minimum_size = Vector2(0, 0)
	info_box.add_child(_reward_label)
	info_box.add_child(ThemeBuilder.separator(1, ThemeBuilder.COLOR_BORDER))
	info_box.add_child(ThemeBuilder.section_title_label("消耗品",
		ThemeBuilder.FONT_CAPTION))
	_potion_row = GridContainer.new()
	_potion_row.columns = 2
	_potion_row.add_theme_constant_override("h_separation", 8)
	_potion_row.add_theme_constant_override("v_separation", 8)
	_potion_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_box.add_child(_potion_row)

	ThemeBuilder.prepare_touch(root)
	_apply_width(EventBus.workspace_width)
	_lock_card = _build_lock_card()
	add_child(_lock_card)


func _on_layout_changed(_mode: int, _vp: Vector2, workspace: float) -> void:
	_apply_width(workspace)


func _apply_width(workspace: float) -> void:
	if _body != null:
		_body.vertical = workspace < 680.0
	if _left_col != null:
		# 竖屏内容贴顶排布，避免左栏被撑开留下大片空洞
		_left_col.size_flags_vertical = Control.SIZE_FILL \
			if _body != null and _body.vertical else Control.SIZE_EXPAND_FILL


func _on_any_state(_enemy_id: String) -> void:
	refresh()


func _on_visibility_changed() -> void:
	set_process(is_visible_in_tree())
	if not is_visible_in_tree():
		# 离开镇魔塔时必须撤掉预览，否则秘境页会残留塔层妖魔
		if _stage != null:
			_stage.clear_preview()
		_is_dirty = true
		return
	_is_dirty = false
	refresh()


func _on_enemy_defeated_for_ring(_enemy_id: String, _loot: Dictionary) -> void:
	var floor_num := CombatEngine.tower_floor
	if floor_num <= 0:
		return
	# 首通奖励在击杀信号之后结算，延后一帧再确认；同时刷新已解锁层数
	call_deferred("_ring_first_clear", floor_num)
	call_deferred("refresh")


func _ring_first_clear(floor_num: int) -> void:
	if _stage == null or not GameState.is_tower_floor_claimed(floor_num):
		return
	if not is_visible_in_tree():
		return
	# 连闯智能节流：普通层首通合并为顶部轻气泡（防每秒刷屏），
	# 仅 5 层妖王里程碑 / 手动单层挑战才弹居中大横幅
	var auto_running := GameState.is_flag("tower_auto", true) and CombatEngine.is_active()
	if auto_running and floor_num % 5 != 0:
		_auto_run_stones += int(GameState.get_tower_first_clear_reward(floor_num).get(
			"stones", 0))
		EventBus.toast.emit("连闯首通已至第 %d 层（累计灵石 +%s）" % [floor_num,
			GameFormulas.format_num(float(_auto_run_stones))])
		return
	if InkVfxLayer.instance != null:
		# 副标精简直观：去掉「获赐：」「本程累计」赘字，确保 450 + 1.20 大字档单行不折
		var subtitle := ""
		if floor_num % 5 == 0:
			subtitle = "百年朱果 ×1 · 聚灵甘露 ×2" if floor_num % 10 == 0 \
				else "仙盟贡献 + 高阶灵材礼匣"
		if _auto_run_stones > 0:
			subtitle += (" · " if subtitle != "" else "") \
				+ "灵石 +%s" % GameFormulas.format_num(float(_auto_run_stones))
			_auto_run_stones = 0
		InkVfxLayer.instance.play_breakthrough("镇魔塔首通 · 第 %d 层" % floor_num,
			ThemeBuilder.COLOR_AMBER, subtitle, "镇")


func _on_any_state_str(_reason: String) -> void:
	refresh()


func _on_updated(_payload: Dictionary) -> void:
	_refresh_live()


func _on_floor_step(step: int) -> void:
	if CombatEngine.is_active() and CombatEngine.tower_floor > 0:
		EventBus.toast.emit("冲层中无法选层，请先撤出")
		return
	var max_floor := GameState.get_tower_max_floor()
	if step > 0 and _floor >= max_floor:
		EventBus.toast.emit("需先击败当前层妖魔方可继续深入")
		return
	if step < 0 and _floor <= 1:
		return
	_floor = clampi(_floor + step, 1, max_floor)
	refresh()


func _on_start_pressed() -> void:
	# 秘境战斗中点冲层：自动遁出秘境转战镇魔塔（避免双战冲突与状态串扰）
	if CombatEngine.is_active() and CombatEngine.tower_floor <= 0:
		CombatEngine.stop_combat("转战镇魔塔")
		EventBus.toast.emit("已遁出秘境，转战镇魔塔")
	elif CombatEngine.is_active():
		EventBus.toast.emit("冲层中无法重复开战，请先撤出")
		return
	_auto_run_stones = 0
	var check := CombatEngine.start_tower_combat(_floor)
	if bool(check.get("ok", false)):
		refresh()
	else:
		EventBus.toast.emit(String(check.get("message", "无法开始冲层")))
		refresh()


func _on_stop_pressed() -> void:
	if CombatEngine.is_active():
		CombatEngine.stop_combat("撤出镇魔塔")
	_auto_run_stones = 0
	refresh()


func _on_auto_toggled(pressed: bool) -> void:
	GameState.flags["tower_auto"] = pressed
	ThemeBuilder.apply_toggle_button(_auto_button, pressed)


## 下一重奖预告文案：每 5 层节点，偶数赐奇珍 / 奇数赐仙盟礼
func _next_reward_text() -> String:
	var next_node := ((GameState.tower_highest_floor / 5) + 1) * 5
	var reward: Dictionary = DataRegistry.get_tower_milestone_reward(next_node)
	if reward.is_empty():
		return ""
	var parts: Array[String] = []
	for value in reward.get("items", []):
		var entry: Dictionary = value
		var item_id := String(entry.get("id", ""))
		if item_id == "":
			continue
		parts.append("%s ×%d" % [DataRegistry.get_item_name(item_id),
			int(entry.get("amount", 1))])
	var item_text := "、".join(parts)
	if parts.size() > 3:
		item_text = "、".join(parts.slice(0, 3)) + " 等"
	return "下一重奖：第 %d 层 · %s · 贡献 +%d" % [next_node, item_text,
		int(reward.get("points", 0))]


func _show_help() -> void:
	BottomSheet.show_help("镇魔塔 · 规则", [
		{"text": "冲层首通", "desc": "每 5 层为妖王层，首通灵石与贡献按双倍结算；普通层首通奖励随层数递增。"},
		{"text": "每日俸禄", "desc": "历史最高层达到 1 层后每日可领一次：灵石 = 最高层 × 境界倍率 × 100，贡献 = 最高层 × 境界倍率 ÷ 2（至少 1 点）。"},
		{"text": "状态隔离", "desc": "镇魔塔战斗、选层与连闯进度独立结算，不与秘境历练状态互相干扰。"},
	])


func _on_salary_pressed() -> void:
	if AudioManager != null:
		AudioManager.play_click()
	var gained := GameState.claim_tower_salary()
	if gained.is_empty():
		EventBus.toast.emit("今日俸禄已领，明日再来")
		return
	EventBus.toast.emit("镇魔俸禄：灵石 %s，贡献 +%d" % [
		GameFormulas.format_num(float(int(gained["stones"]))), int(gained["points"])])
	GameState.push_activity_log("领取镇魔俸禄：灵石 %s" % [
		GameFormulas.format_num(float(int(gained["stones"])))], "gold")
	refresh()


func refresh() -> void:
	_apply_unlock_gate()
	if not _is_unlocked():
		return
	if _stage == null:
		return
	if not is_visible_in_tree():
		_is_dirty = true
		return
	_is_dirty = false
	var running := CombatEngine.is_active() and CombatEngine.tower_floor > 0
	var max_floor := GameState.get_tower_max_floor()
	if running:
		_floor = CombatEngine.tower_floor
	else:
		_floor = clampi(_floor, 1, max_floor)
	_floor_label.text = "镇魔塔 · 第 %d 层" % _floor
	_best_label.text = "历史最高 %d 层" % GameState.tower_highest_floor
	# 下一重奖预告 + 今日俸禄状态
	_next_reward_label.text = _next_reward_text()
	var salary_ready := GameState.can_claim_tower_salary()
	_salary_button.disabled = not salary_ready
	_salary_button.text = "领取今日俸禄" if salary_ready else \
		("今日俸禄已领" if GameState.tower_highest_floor >= 1 else "通关第 1 层解锁俸禄")
	if salary_ready:
		ThemeBuilder.apply_primary_button(_salary_button)
	else:
		ThemeBuilder.apply_secondary_button(_salary_button)
	_start_button.disabled = running
	_start_button.text = "冲层中…" if running else "开始冲层"
	_stop_button.disabled = not running
	ThemeBuilder.apply_secondary_button(_stop_button, running)

	# 选层：第 1 层禁用 ◀；到达已解锁上限时 ▶ 置灰但仍可点（点了给 Toast 说明）
	_prev_button.disabled = _floor <= 1
	var next_locked := running or _floor >= max_floor
	_next_button.disabled = false
	_next_button.modulate = Color(1, 1, 1, 0.45) if next_locked else Color(1, 1, 1, 1)
	_next_button.tooltip_text = "" if not next_locked else "需先击败当前层妖魔方可继续深入"

	var enemy := CombatEngine.get_current_enemy() if running else DataRegistry.get_tower_enemy(_floor)
	if enemy != null:
		_enemy_stat_label.text = "%s\n气血 %s · 攻击 %s · 防御 %s · 间隔 %.1fs%s" % [
			ThemeBuilder.format_enemy_grade_bbcode(enemy.id, enemy.display_name),
			GameFormulas.format_num(float(enemy.max_hp)),
			GameFormulas.format_num(float(enemy.attack)),
			GameFormulas.format_num(float(enemy.defense)),
			enemy.attack_interval, "（妖王层）" if enemy.is_boss else ""]
		if not running:
			# 未开战时，舞台右侧预览当前选中层数的镇塔妖魔
			_stage.show_preview_enemy(enemy)
	var reward: Dictionary = GameState.get_tower_first_clear_reward(_floor)
	var first_clear := not GameState.is_tower_floor_claimed(_floor)
	_reward_label.text = "灵石 %s · 贡献 %d · 层段 %d%s%s" % [
		GameFormulas.format_num(float(int(reward.get("stones", 0)))),
		int(reward.get("points", 0)),
		int(reward.get("tier", 1)),
		"（妖王层 ×2）" if bool(reward.get("king", false)) else "",
		"" if first_clear else " · 已领取"]
	_refresh_potion_capsules()
	_refresh_live()
	if not running:
		_stage.refresh_idle()


func _refresh_potion_capsules() -> void:
	if _potion_row == null:
		return
	for child in _potion_row.get_children():
		_potion_row.remove_child(child)
		child.queue_free()
	var items: Array = [
		"item_revive_pill", "item_heart_pill", "item_taixu_shield",
		"item_taiji_talisman", "item_taixu_thunder",
	]
	for item_id in items:
		var iid := String(item_id)
		var capsule := ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD_DEEP,
			ThemeBuilder.COLOR_BORDER, 6, 8)
		capsule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var row := ThemeBuilder.hbox(4)
		capsule.add_child(row)
		row.add_child(ThemeBuilder.icon_rect(IconLibrary.get_item_icon(iid), 24))
		var name_label := ThemeBuilder.label(DataRegistry.get_item_name(iid),
			ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_PRIMARY)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.clip_text = true
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		row.add_child(name_label)
		row.add_child(ThemeBuilder.label("×%d" % GameState.get_item_count(iid),
			ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_JADE))
		ThemeBuilder.make_card_tappable(capsule,
			Callable(self, "_show_consumable_info").bind(iid))
		_potion_row.add_child(capsule)


func _show_consumable_info(item_id: String) -> void:
	var item := DataRegistry.get_item(item_id)
	var effect := item.description if item != null and item.description != "" else "暂无说明。"
	BottomSheet.show_text(DataRegistry.get_item_name(item_id), [
		{"text": "效用", "desc": effect},
	])


func _refresh_live() -> void:
	if _stage == null or not CombatEngine.is_active() or CombatEngine.tower_floor <= 0:
		return
	# 「连闯下一层」自动推进时同步选中层数与顶部标题/下一重奖预览
	if _floor != CombatEngine.tower_floor:
		_floor = CombatEngine.tower_floor
		_floor_label.text = "镇魔塔 · 第 %d 层" % _floor
		_next_reward_label.text = _next_reward_text()
	var enemy := CombatEngine.get_current_enemy()
	if enemy == null:
		return
	_enemy_stat_label.text = "%s\n气血 %s / %s · 攻击 %s · 防御 %s%s" % [
		ThemeBuilder.format_enemy_grade_bbcode(enemy.id, enemy.display_name),
		GameFormulas.format_num(float(maxi(0, CombatEngine.enemy_hp))),
		GameFormulas.format_num(float(enemy.max_hp)),
		GameFormulas.format_num(float(enemy.attack)),
		GameFormulas.format_num(float(enemy.defense)),
		"（妖王层）" if enemy.is_boss else ""]

