class_name CombatPanel
extends Control
## 秘境历练（移动端单列）：目标横排切换、双进度条自动战斗、自动应对设置与战斗纪要。

const REGION_ID: String = "wild_wolf_forest"
const MAX_LOG_LINES: int = 40

var _enemy_buttons: Dictionary = {}
var _region_buttons: Dictionary = {}
var _body: BoxContainer
## 宽屏外层：两栏 HBox 在上、战斗纪要全宽卡在下；竖屏时纪要回归整页单列
var _wide_box: VBoxContainer
var _left_col: VBoxContainer
var _right_col: VBoxContainer
## 竖屏整页滚动容器：450×800 且 1.20 大字时，六块内容必然超出可视区
var _compact_scroll: ScrollContainer
var _compact_box: VBoxContainer
var _region_row: GridContainer
## 秘境页签的横滑容器：竖屏 8 个秘境压成一行，省掉约 180px 垂直空间
var _region_scroll: ScrollContainer
var _battle_panel: PanelContainer
var _auto_panel: PanelContainer
var _log_panel: PanelContainer
var _stage: CombatStage
var _enemy_tabs: HBoxContainer
## 详情卡当前预览目标：战斗中可与正在交战的敌人不同，只有确认后才真正换怪
var _preview_enemy_id: String = ""
var _auto_thunder_button: Button

var _enemy_name_label: Label
## 头目标签独立成 chip：不再拼进名号文本，避免「苍月狼王（头目）」撑爆一行
var _enemy_boss_chip: PanelContainer
# 下方信息卡只保留属性/掉落/读条/按钮，血条统一收进 CombatStage
var _enemy_stat_label: Label
var _enemy_lock_label: Label
var _enemy_loot_label: RichTextLabel

var _player_progress: ProgressBar   # 已并入 CombatStage（保留引用壳仅为兼容旧调用）
var _enemy_progress: ProgressBar
var _stats_label: Label
var _threshold_label: Label
var _threshold_slider: HSlider
var _start_button: Button
var _stop_button: Button
var _log_box: VBoxContainer
var _log_scroll: ScrollContainer
## 空战况提示：无记录时只占一行淡墨灰，有战报即隐藏
var _log_empty_label: Label
## 宽屏日志卡原始最小高：剩余高度自适应时以此为基准，竖屏原样恢复
var _bottom_base_h: float = 120.0
var _fit_frames: int = 0
var _auto_heal_button: Button
var _auto_talisman_button: Button
var _is_dirty: bool = false
var _tab_style_active: StyleBoxFlat
var _tab_style_inactive: StyleBoxFlat


func _ready() -> void:
	_build()
	_connect_signals()
	visibility_changed.connect(_on_visibility_changed)
	resized.connect(_on_self_resized)
	refresh_all()


## 秘境战斗判定（严格排除镇魔塔）：所有实时状态读点共用此守卫
func _realm_fighting() -> bool:
	return CombatEngine.is_active() and not CombatEngine.is_tower_mode()


func _process(_delta: float) -> void:
	# 宽屏延展：布局重排后连算 4 帧，等两栏高度稳定再定稿
	if _fit_frames > 0:
		_fit_frames -= 1
		_fit_wide_bottom()
	# 双向隔离：镇魔塔战斗不驱动秘境舞台蓄势条/连胜（归零静止）
	if not _realm_fighting():
		if _stage != null:
			_stage.set_charge(0.0, 0.0)
		return
	var stats := GameState.get_player_stats()
	var player_interval := maxf(0.5, float(stats["interval"]))
	var enemy := CombatEngine.get_current_enemy()
	var enemy_ratio := 0.0
	if enemy != null:
		enemy_ratio = clampf(CombatEngine.enemy_timer / maxf(0.5, enemy.attack_interval), 0.0, 1.0)
	# 蓄势条并入对战舞台（紧贴血条下方）
	_stage.set_charge(
		clampf(CombatEngine.player_timer / player_interval, 0.0, 1.0), enemy_ratio)
	# 连胜计数实时跳动；「切换目标」待确认时不能被连胜文本覆盖
	var current_enemy := CombatEngine.get_current_enemy()
	if current_enemy != null and _preview_enemy_id == current_enemy.id:
		var streak_text := "连胜 %d 场" % CombatEngine.win_streak
		if _start_button.text != streak_text:
			_start_button.text = streak_text


# ---------------------------------------------------------------- 构建

func _build() -> void:
	var root := ThemeBuilder.vbox(10)
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 10)

	# ---- 顶部
	var header := ThemeBuilder.card_panel()
	root.add_child(header)
	var head_box := ThemeBuilder.vbox(4)
	header.add_child(head_box)
	var title_row := ThemeBuilder.hbox(8)
	head_box.add_child(title_row)
	title_row.add_child(ThemeBuilder.title_label("秘境历练", 20))
	title_row.add_child(ThemeBuilder.chip("自动回合", ThemeBuilder.COLOR_CINNABAR))
	var help := ThemeBuilder.create_help_button(_show_help)
	help.custom_minimum_size = Vector2(44, 44)
	help.tooltip_text = "秘境历练规则"
	title_row.add_child(help)
	title_row.add_child(ThemeBuilder.expander())
	title_row.move_child(help, -1)
	# 己方攻防命中：左对齐独占「秘境历练」下方一行，明确主语，不再挂在「?」底下
	_stats_label = ThemeBuilder.wrap_label_phrases("", ThemeBuilder.FONT_BODY_SUB,
		ThemeBuilder.COLOR_TEXT_SECONDARY)
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_stats_label.clip_text = false
	head_box.add_child(_stats_label)
	ThemeBuilder.attach_header_watermark(header, IconLibrary.get_nav_icon("combat"))

	# 宽屏左右双栏：左舞台+战斗纪要，右页签+自动应对
	_wide_box = ThemeBuilder.vbox(10)
	_wide_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_wide_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_wide_box)
	_body = BoxContainer.new()
	_body.vertical = true
	_body.add_theme_constant_override("separation", 10)
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_wide_box.add_child(_body)
	_left_col = ThemeBuilder.vbox(8)
	_left_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_left_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_left_col.size_flags_stretch_ratio = 1.05
	_body.add_child(_left_col)
	_right_col = ThemeBuilder.vbox(8)
	_right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_right_col.size_flags_stretch_ratio = 1.0
	_right_col.custom_minimum_size = Vector2(400, 0)
	_body.add_child(_right_col)

	# ---- 对决舞台
	_stage = CombatStage.new()
	# 严格模式隔离：秘境舞台只吃秘境战斗信号（镇魔塔战斗不进血条/飘字）
	_stage.mode_filter = "realm"
	_left_col.add_child(_stage)

	# ---- 秘境页签：始终放进横向滚动容器。
	# 竖屏 = 一行横滑（8 个秘境不再吃 4 行高度），宽屏 = 2 列网格（见 _apply_layout）。
	_region_scroll = ThemeBuilder.GuardedScrollContainer.new()
	_region_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_region_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_region_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ThemeBuilder.style_scrollbar(_region_scroll.get_h_scroll_bar())
	_right_col.add_child(_region_scroll)
	_region_row = GridContainer.new()
	_region_row.columns = 2
	_region_row.add_theme_constant_override("h_separation", 6)
	_region_row.add_theme_constant_override("v_separation", 6)
	_region_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_region_scroll.add_child(_region_row)
	for region_key in DataRegistry.regions.keys():
		var region: Dictionary = DataRegistry.regions[region_key]
		var rid := String(region.get("id", ""))
		var tag := String(region.get("tag", ""))
		var required_tier := int(region.get("required_tier", 0))
		var region_button := ThemeBuilder.small_button("%s [%s]" % [String(region.get("name", rid)), tag])
		region_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ThemeBuilder.apply_font_size(region_button, ThemeBuilder.FONT_CAPTION)
		var region_lock := _region_lock_reason(rid)
		required_tier = int(region.get("required_tier", 0))
		region_button.disabled = region_lock != ""
		region_button.tooltip_text = "可挑战" if region_lock == "" else region_lock
		region_button.pressed.connect(_on_region_pressed.bind(rid))
		_region_row.add_child(region_button)
		_region_buttons[rid] = region_button
	# 横滑尾距：最右「三十三天外 [大乘]」右侧留 12px 安全边距不被屏幕裁断
	var region_tail := Control.new()
	region_tail.custom_minimum_size = Vector2(12, 0)
	region_tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_region_row.add_child(region_tail)

	# ---- 目标横排
	_enemy_tabs = ThemeBuilder.hbox(6)
	_right_col.add_child(_enemy_tabs)
	_rebuild_enemy_tabs()

	# ---- 战斗卡（轻点信息区看妖兽图鉴与完整掉落表）
	_battle_panel = ThemeBuilder.card_panel()
	ThemeBuilder.make_card_tappable(_battle_panel, func() -> void: _show_enemy_detail())
	_left_col.add_child(_battle_panel)
	var battle_box := ThemeBuilder.vbox(8)
	_battle_panel.add_child(battle_box)

	# 名号单独占一行（自适应 + 省略号兜底），属性另起一行可换行：
	# 450 宽 + 1.20 大字档下「苍月狼王」与气血/攻防数值不再互相挤压。
	var enemy_row := ThemeBuilder.hbox(6)
	battle_box.add_child(enemy_row)
	_enemy_name_label = ThemeBuilder.card_title_label("尚未入秘境",
		ThemeBuilder.FONT_CARD_TITLE, ThemeBuilder.COLOR_CINNABAR)
	_enemy_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_enemy_name_label.clip_text = true
	_enemy_name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	enemy_row.add_child(_enemy_name_label)
	_enemy_boss_chip = ThemeBuilder.chip("头目", ThemeBuilder.COLOR_AMBER)
	_enemy_boss_chip.visible = false
	enemy_row.add_child(_enemy_boss_chip)
	_enemy_stat_label = ThemeBuilder.wrap_label("", ThemeBuilder.FONT_BODY_SUB,
		ThemeBuilder.COLOR_TEXT_DIM)
	ThemeBuilder.enable_phrase_wrap(_enemy_stat_label)
	battle_box.add_child(_enemy_stat_label)
	_enemy_lock_label = ThemeBuilder.wrap_label("", ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_CINNABAR)
	ThemeBuilder.apply_font_size(_enemy_lock_label, ThemeBuilder.FONT_CAPTION)
	_enemy_lock_label.visible = false
	battle_box.add_child(_enemy_lock_label)
	# 掉落文本用品阶着色 BBCode（九幽玄晶/龙血草等按凡~神材五色）
	# 掉落整段用单个自适应折行的 RichTextLabel：严格在卡片内宽折行，不横向溢出
	_enemy_loot_label = ThemeBuilder.bbcode_label("", ThemeBuilder.FONT_BODY_SUB)
	_enemy_loot_label.bbcode_enabled = true
	_enemy_loot_label.fit_content = true
	_enemy_loot_label.scroll_active = false
	_enemy_loot_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_enemy_loot_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_enemy_loot_label.custom_minimum_size.x = 0.0
	battle_box.add_child(_enemy_loot_label)

	# 蓄势条已并入对战舞台（紧贴血条下方），详情卡不再重复展示
	var button_row := ThemeBuilder.hbox(8)
	battle_box.add_child(button_row)
	_start_button = ThemeBuilder.button("开始历练")
	_start_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_start_button.size_flags_stretch_ratio = 5.0
	_start_button.custom_minimum_size = Vector2(0, 46)
	ThemeBuilder.clip_button_text(_start_button, "开始历练")
	ThemeBuilder.apply_font_size(_start_button, ThemeBuilder.FONT_CARD_TITLE)
	ThemeBuilder.apply_brush_kai(_start_button)
	ThemeBuilder.apply_primary_button(_start_button)
	_start_button.pressed.connect(_on_start_pressed)
	button_row.add_child(_start_button)
	# 与「开始历练」同量级：同字体同字号、等宽平分；可撤出=浅朱砂描边，禁用=柔和浅米底
	_stop_button = ThemeBuilder.button("撤出秘境")
	_stop_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stop_button.size_flags_stretch_ratio = 5.0
	_stop_button.custom_minimum_size = Vector2(0, 46)
	ThemeBuilder.clip_button_text(_stop_button, "撤出秘境")
	ThemeBuilder.apply_font_size(_stop_button, ThemeBuilder.FONT_CARD_TITLE)
	ThemeBuilder.apply_brush_kai(_stop_button)
	var stop_normal := ThemeBuilder.panel_box(Color("#F7EAE6"),
		ThemeBuilder.COLOR_TEXT_DANGER, 8, 1, 10)
	stop_normal.border_width_bottom = 2
	_stop_button.add_theme_stylebox_override("normal", stop_normal)
	var stop_hover := ThemeBuilder.panel_box(Color("#F2DFD9"),
		ThemeBuilder.COLOR_TEXT_DANGER, 8, 1, 10)
	stop_hover.border_width_bottom = 2
	_stop_button.add_theme_stylebox_override("hover", stop_hover)
	_stop_button.add_theme_stylebox_override("pressed",
		ThemeBuilder.panel_box(Color("#EBD2CB"), ThemeBuilder.COLOR_TEXT_DANGER, 8, 0, 10))
	_stop_button.add_theme_stylebox_override("disabled",
		ThemeBuilder.panel_box(Color("#F2EDE4"), Color("#C9BFB0"), 8, 1, 10))
	for key in ["font_color", "font_hover_color", "font_pressed_color"]:
		_stop_button.add_theme_color_override(key, ThemeBuilder.COLOR_TEXT_DANGER)
	_stop_button.add_theme_color_override("font_disabled_color",
		ThemeBuilder.COLOR_TEXT_MUTED)
	_stop_button.pressed.connect(_on_stop_pressed)
	button_row.add_child(_stop_button)

	# ---- 自动应对
	_auto_panel = ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD_DEEP, ThemeBuilder.COLOR_BORDER, 12, 12)
	_right_col.add_child(_auto_panel)
	var auto_box := ThemeBuilder.vbox(8)
	_auto_panel.add_child(auto_box)
	var auto_title_row := ThemeBuilder.hbox(6)
	auto_box.add_child(auto_title_row)
	auto_title_row.add_child(ThemeBuilder.section_title_label("自动应对",
		ThemeBuilder.FONT_BODY_SUB))
	auto_title_row.add_child(ThemeBuilder.expander())

	# 三个开关严格等宽三等分（不再用流式换行）：库存到 5~6 位数时以省略号收尾，
	# 完整数量走 tooltip，绝不把卡片右边框顶出 450 视口。
	var auto_row := ThemeBuilder.hbox(6)
	auto_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	auto_box.add_child(auto_row)
	_auto_heal_button = _make_toggle("回春散", "auto_heal")
	_auto_heal_button.tooltip_text = "自动回春散"
	auto_row.add_child(_auto_heal_button)
	_auto_talisman_button = _make_toggle("护身符", "auto_talisman")
	_auto_talisman_button.tooltip_text = "自动护身符"
	auto_row.add_child(_auto_talisman_button)
	_auto_thunder_button = _make_toggle("引雷符", "auto_thunder_talisman")
	_auto_thunder_button.tooltip_text = "自动引雷符"
	auto_row.add_child(_auto_thunder_button)

	var slider_row := ThemeBuilder.hbox(8)
	auto_box.add_child(slider_row)
	_threshold_label = ThemeBuilder.dim_label("", ThemeBuilder.FONT_BODY_SUB)
	slider_row.add_child(_threshold_label)
	_threshold_slider = HSlider.new()
	_threshold_slider.min_value = 10.0
	_threshold_slider.max_value = 80.0
	_threshold_slider.step = 5.0
	_threshold_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_threshold_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_threshold_slider.custom_minimum_size = Vector2(0, 32)
	_threshold_slider.value = GameState.auto_heal_threshold * 100.0
	_threshold_slider.value_changed.connect(_on_threshold_changed)
	slider_row.add_child(_threshold_slider)

	# ---- 战斗纪要
	_log_panel = ThemeBuilder.card_panel()
	_log_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log_panel.custom_minimum_size = Vector2(0, 120)
	_left_col.add_child(_log_panel)
	var log_outer := ThemeBuilder.vbox(6)
	_log_panel.add_child(log_outer)
	log_outer.add_child(ThemeBuilder.section_title_label("战斗纪要",
		ThemeBuilder.FONT_BODY_SUB))
	_log_scroll = ThemeBuilder.scroll_container()
	_log_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_outer.add_child(_log_scroll)
	# 上下留白：滚到最新一条时首行不贴顶切头
	var log_margin := MarginContainer.new()
	log_margin.add_theme_constant_override("margin_left", 5)
	log_margin.add_theme_constant_override("margin_right", 5)
	log_margin.add_theme_constant_override("margin_top", 5)
	log_margin.add_theme_constant_override("margin_bottom", 5)
	log_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_log_scroll.add_child(log_margin)
	_log_box = ThemeBuilder.vbox(2)
	_log_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_margin.add_child(_log_box)
	_log_empty_label = ThemeBuilder.wrap_label(
		"尚未交锋，轻触「开始历练」后将在此记录战况",
		ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_DIM)
	ThemeBuilder.apply_font_size(_log_empty_label, ThemeBuilder.FONT_CAPTION)
	_log_box.add_child(_log_empty_label)
	for line in CombatEngine.get_log_lines():
		_append_log_line(line)

	# 竖屏滚动容器：舞台 / 选怪 / 战斗卡 / 自动应对 / 纪要依次落入，窄屏下整页可滚，
	# 不再让最后一块被底部导航压住或互相挤压。
	_compact_scroll = ThemeBuilder.scroll_container()
	_compact_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_compact_scroll.visible = false
	_body.add_child(_compact_scroll)
	_compact_box = ThemeBuilder.vbox(10)
	_compact_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_compact_scroll.add_child(_compact_box)
	# 滚动内容底部留白：否则滚到底时最后一行会紧贴可视区边缘被切半
	var tail_pad := Control.new()
	tail_pad.custom_minimum_size = Vector2(0, 14)
	tail_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_compact_box.add_child(tail_pad)

	ThemeBuilder.prepare_touch(root)
	_apply_layout(EventBus.workspace_width)


## 竖屏重排：舞台 → 秘境/怪物选择 → 属性与按钮 → 消耗品与自动应对 → 战斗纪要沉底。
## 宽屏沿用原有左右双栏，仅把各区块归还到各自栏位。
func _apply_layout(workspace_width: float) -> void:
	if _body == null:
		return
	var compact := workspace_width < 680.0
	_body.vertical = compact
	# 宽屏两栏只取所需高度，纪要紧随其后；竖屏整页滚动仍占满剩余高度
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL if compact \
		else Control.SIZE_SHRINK_BEGIN
	if _log_panel != null:
		_log_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if _left_col != null:
		_left_col.visible = not compact
		_left_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_left_col.size_flags_stretch_ratio = 1.05
	if _right_col != null:
		_right_col.visible = not compact
		# 两列在 HBox 内等高拉伸：左列详情卡底边与右列自动应对底边齐平
		_right_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_right_col.size_flags_stretch_ratio = 1.0
		_right_col.custom_minimum_size = Vector2(0 if compact else 400, 0)
	if _battle_panel != null:
		_battle_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN if compact \
			else Control.SIZE_EXPAND_FILL
	if _auto_panel != null:
		_auto_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN if compact \
			else Control.SIZE_EXPAND_FILL
	if _compact_scroll != null:
		_compact_scroll.visible = compact
	# 秘境共 8 个：竖屏排成 1 行横滑（8 列），宽屏回到 2 列网格。
	# 3 列在 450 宽 + 1.20 大字档会把「星陨古墟 [金丹]」顶出卡片，故竖屏不做多列。
	if _region_row != null:
		_region_row.columns = 8 if compact else 2
	if compact:
		# 竖屏保持原单列：舞台 → 选择 → 详情 → 自动应对 → 纪要
		_stack_nodes(_compact_box, [
			_stage, _region_scroll, _enemy_tabs, _battle_panel,
			_auto_panel, _log_panel,
		])
		if _log_panel != null:
			_bottom_base_h = 120.0
			_log_panel.custom_minimum_size.y = _bottom_base_h
			_log_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	else:
		# 宽屏：两栏在上，纪要移出左列，作为整宽底卡铺满主面板
		_stack_nodes(_left_col, [_stage, _battle_panel])
		_stack_nodes(_right_col, [_region_scroll, _enemy_tabs, _auto_panel])
		_stack_nodes(_wide_box, [_body, _log_panel])
		if _log_panel != null:
			_bottom_base_h = 120.0
			_log_panel.custom_minimum_size.y = _bottom_base_h
			_log_panel.size_flags_vertical = Control.SIZE_FILL
			call_deferred("_fit_wide_bottom")


func _on_self_resized() -> void:
	_request_fit()


func _request_fit() -> void:
	_fit_frames = 4


## 宽屏：把纪要卡补高到面板底部安全边距；竖屏完全交给整页滚动
func _fit_wide_bottom() -> void:
	if _body == null or _log_panel == null or _log_panel.get_parent() != _wide_box:
		return
	if get_viewport().get_visible_rect().size.x < 840:
		return
	# 直接按「两栏底边 → 面板底边」的可用高计算，避免迭代式补高受旧尺寸影响
	# 再减 10 为两栏与纪要之间的正常间距，最终底边留 10px 安全边距
	var available := get_global_rect().end.y - _body.get_global_rect().end.y - 20.0
	var target := maxf(_bottom_base_h, available)
	if absf(target - _log_panel.custom_minimum_size.y) > 0.6:
		_log_panel.custom_minimum_size.y = target


## 按给定顺序 reparent 并重排（节点可能已经在该容器中）
func _stack_nodes(target: Node, nodes: Array) -> void:
	if target == null:
		return
	for index in range(nodes.size()):
		var node: Node = nodes[index]
		if node == null:
			continue
		if node.get_parent() != target:
			node.reparent(target, false)
		target.move_child(node, index)


func _make_toggle(text_value: String, flag_key: String) -> Button:
	var button := ThemeBuilder.small_button(text_value)
	button.toggle_mode = true
	button.button_pressed = GameState.is_flag(flag_key, true)
	ThemeBuilder.apply_toggle_button(button, button.button_pressed)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
	ThemeBuilder.apply_font_size(button, ThemeBuilder.FONT_CAPTION)
	ThemeBuilder.clip_button_text(button, text_value)
	ThemeBuilder.tighten_button_padding(button, 4.0)
	button.toggled.connect(func(pressed: bool) -> void:
		GameState.set_flag(flag_key, pressed)
		ThemeBuilder.apply_toggle_button(button, pressed)
		# 重刷样式会恢复 10px 内边距，这里补回紧凑 6px，防切换后文字区变窄再截
		ThemeBuilder.tighten_button_padding(button, 4.0)
	)
	return button


func _connect_signals() -> void:
	EventBus.combat_updated.connect(_on_combat_updated)
	EventBus.combat_log.connect(_on_combat_log)
	EventBus.combat_started.connect(_on_combat_started)
	EventBus.combat_stopped.connect(_on_combat_stopped)
	EventBus.inventory_changed.connect(_refresh_auto_stock)
	EventBus.stats_changed.connect(_refresh_stats)
	EventBus.equipment_changed.connect(_refresh_stats)
	EventBus.technique_changed.connect(_refresh_stats)
	EventBus.realm_changed.connect(_on_realm_changed)
	EventBus.layout_changed.connect(_on_layout_changed)


# ---------------------------------------------------------------- 刷新

func refresh_all() -> void:
	if not is_visible_in_tree():
		_is_dirty = true
		return
	_is_dirty = false
	_refresh_stats()
	_refresh_auto_stock()
	_refresh_buttons()
	_refresh_threshold_label()
	_refresh_region_highlight()
	_refresh_enemy_tabs()
	# 双向隔离：镇魔塔战斗不把塔妖将写进秘境信息卡，走选中秘境妖兽静态预览
	var enemy := CombatEngine.get_current_enemy() if _realm_fighting() else null
	if enemy != null:
		_apply_enemy_header(enemy)
		_set_enemy_lock_hint("")
	else:
		_enemy_name_label.text = "尚未入秘境"
		if _enemy_boss_chip != null:
			_enemy_boss_chip.visible = false
		_show_selected_preview()


func _show_selected_preview() -> void:
	var preview_id := _preview_enemy_id
	if preview_id == "":
		preview_id = GameState.selected_enemy_id
	var enemy := DataRegistry.get_enemy(preview_id)
	if enemy == null:
		if _enemy_boss_chip != null:
			_enemy_boss_chip.visible = false
		_enemy_stat_label.text = ""
		_enemy_loot_label.text = ""
		_set_enemy_lock_hint("")
		return
	_apply_enemy_header(enemy)
	_set_enemy_lock_hint(_enemy_lock_reason(enemy.id))


func _set_enemy_lock_hint(reason: String) -> void:
	if _enemy_lock_label == null:
		return
	_enemy_lock_label.visible = reason != ""
	_enemy_lock_label.text = "需先击败前置妖兽 · %s" % reason if reason != "" else ""


## 妖兽详情浮层：图鉴描述 + 完整掉落概率表（镇魔塔战斗中只看选中秘境妖兽）
func _effective_hit(enemy: EnemyData) -> float:
	if enemy == null:
		return GameState.get_raw_accuracy()
	return clampf(GameState.get_raw_accuracy() - enemy.dodge, 0.35, 0.99)


func _show_enemy_detail() -> void:
	var preview_id := _preview_enemy_id
	if preview_id == "":
		preview_id = GameState.selected_enemy_id
	var enemy := DataRegistry.get_enemy(preview_id)
	if enemy == null and _realm_fighting():
		enemy = CombatEngine.get_current_enemy()
	if enemy == null:
		return
	if AudioManager != null:
		AudioManager.play_tap()
	var rows: Array = []
	rows.append({
		"text": "图鉴",
		"desc": enemy.description if enemy.description != "" else "暂无记载。",
	})
	rows.append({
		"text": "属性",
		"desc": "气血 %s · 攻击 %s · 防御 %s · 间隔 %.1fs" % [
			GameFormulas.format_num(float(enemy.max_hp)),
			GameFormulas.format_num(float(enemy.attack)),
			GameFormulas.format_num(float(enemy.defense)),
			enemy.attack_interval],
	})
	if enemy.dodge > 0.0:
		rows.append({
			"text": "身法",
			"desc": "闪避 %.0f%% · 当前总命中 %.0f%% · 有效命中 %.0f%%" % [
				enemy.dodge * 100.0, GameState.get_raw_accuracy() * 100.0,
				_effective_hit(enemy) * 100.0],
		})
	for entry in enemy.loot_table:
		var dict: Dictionary = entry
		var item_id := String(dict.get("item_id", ""))
		var chance := float(dict.get("chance", 0.0)) * 100.0
		# 大数万/亿紧凑格式：「灵石 60万~80万（100%）」
		var lo := int(dict.get("min", 1))
		var hi := int(dict.get("max", 1))
		var range_text := "×%s" % GameFormulas.format_num(float(lo)) if lo == hi \
			else "%s~%s" % [GameFormulas.format_num(float(lo)), GameFormulas.format_num(float(hi))]
		rows.append({
			"bbcode": "%s %s（%.0f%%）" % [
				ThemeBuilder.format_item_grade_bbcode(item_id), range_text, chance],
			"desc": "击败后按概率掉落。",
		})
	var egrade: Dictionary = DataRegistry.get_enemy_grade(enemy.id)
	BottomSheet.show_text(enemy.display_name, rows,
		ThemeBuilder.get_material_grade_color(int(egrade.get("tier", 1))) \
			if not egrade.is_empty() else ThemeBuilder.COLOR_TEXT)


## 名号 / 头目标签 / 属性 / 掉落：名号不再拼接受击后缀，头目态单列 chip 展示
func _apply_enemy_header(enemy: EnemyData) -> void:
	if enemy == null:
		return
	_enemy_name_label.text = enemy.display_name
	ThemeBuilder.apply_enemy_grade_style(_enemy_name_label, enemy.id)
	if _enemy_boss_chip != null:
		_enemy_boss_chip.visible = enemy.is_boss
	var stat_text := "气血 %s · 攻击 %s · 防御 %s · 间隔 %.1fs" % [
		GameFormulas.format_num(float(enemy.max_hp)),
		GameFormulas.format_num(float(enemy.attack)),
		GameFormulas.format_num(float(enemy.defense)),
		enemy.attack_interval]
	if enemy.dodge > 0.0:
		stat_text += " · 闪避 %.0f%% · 有效命中 %.0f%%" % [
			enemy.dodge * 100.0, _effective_hit(enemy) * 100.0]
	_enemy_stat_label.text = ThemeBuilder.protect_phrases(stat_text)
	# 先按物品品阶着色，再做防断词（WJ 只作用于可见文字，不会破坏 BBCode 色标）
	var loot_bbcode := ThemeBuilder.colorize_item_names_bbcode(enemy.get_loot_text())
	_enemy_loot_label.text = "掉落：%s" % ThemeBuilder.protect_phrases(loot_bbcode)


func _refresh_stats() -> void:
	if not is_visible_in_tree():
		_is_dirty = true
		return
	var stats := GameState.get_player_stats()
	var attack := int(stats["attack"])
	var defense := int(stats["defense"])
	var accuracy := int(round(float(stats.get("raw_accuracy", stats["accuracy"])) * 100.0))
	# 万/亿紧凑格式 + 「己方：」主语；词组用 · 分隔，沿用全站防断词口径
	_stats_label.text = ThemeBuilder.protect_phrases("己方：攻%s · 防%s · 命中%d%%" % [
		GameFormulas.format_num(float(attack)),
		GameFormulas.format_num(float(defense)), accuracy])
	# 悬停/长按仍能看全量精确值
	_stats_label.tooltip_text = "己方：攻击 %d · 防御 %d · 命中 %d%%" % [
		attack, defense, accuracy]


func _refresh_auto_stock() -> void:
	if _auto_heal_button == null:
		return
	if not is_visible_in_tree():
		_is_dirty = true
		return
	var heal_stock := _stock_total(DataRegistry.HEAL_ITEMS)
	var ward_stock := _stock_total(DataRegistry.WARD_ITEMS)
	var thunder_stock := _stock_total(DataRegistry.THUNDER_ITEMS)
	# 按钮上走万/亿紧凑格式（如「(6.6万)」），精确库存走 tooltip；
	# 三等分按钮在 1.20 大字档下不会被六位数字挤出卡片
	_auto_heal_button.text = "回春散 (%s)" % GameFormulas.format_num(float(heal_stock))
	_auto_heal_button.tooltip_text = "自动回春散 · 库存 %d 份" % heal_stock
	_auto_talisman_button.text = "护身符 (%s)" % GameFormulas.format_num(float(ward_stock))
	_auto_talisman_button.tooltip_text = "自动护身符 · 库存 %d 份" % ward_stock
	_auto_thunder_button.text = "引雷符 (%s)" % GameFormulas.format_num(float(thunder_stock))
	_auto_thunder_button.tooltip_text = "自动引雷符 · 库存 %d 份" % thunder_stock
	for btn in [_auto_heal_button, _auto_talisman_button, _auto_thunder_button]:
		ThemeBuilder.apply_font_size(btn, ThemeBuilder.FONT_CAPTION)
		ThemeBuilder.tighten_button_padding(btn, 4.0)


func _stock_total(entries: Array) -> int:
	var total := 0
	for entry in entries:
		var dict: Dictionary = entry
		total += GameState.get_item_count(String(dict.get("id", "")))
	return total


## 跨越 AutoLoad 版本差：新方法不存在时安全降级，不阻断秘境下半屏构建。
func _enemy_lock_reason(enemy_id: String) -> String:
	if GameState == null:
		return ""
	if GameState.has_method("enemy_lock_reason"):
		return String(GameState.call("enemy_lock_reason", enemy_id))
	if GameState.has_method("is_enemy_unlocked"):
		return "" if bool(GameState.call("is_enemy_unlocked", enemy_id)) \
			else "需先击败前置妖兽"
	return ""


func _region_lock_reason(region_id: String) -> String:
	if GameState == null:
		return ""
	if GameState.has_method("region_lock_reason"):
		return String(GameState.call("region_lock_reason", region_id))
	# 旧基包兜底：只校验原有境界门槛，不阻断区域列表渲染
	var region: Dictionary = DataRegistry.regions.get(region_id, {})
	if region.is_empty():
		return ""
	var realm := GameState.get_realm()
	var tier := 0 if realm == null else realm.tier
	if tier < int(region.get("required_tier", 0)):
		return "需达%s境界" % String(region.get("tag", "更高境界"))
	return ""


func _refresh_buttons() -> void:
	# 镇魔塔战斗期间保持「未进秘境」按钮态（进入可点 / 撤出禁用）
	var in_combat := _realm_fighting()
	var current_enemy := CombatEngine.get_current_enemy() if in_combat else null
	var switching := in_combat and current_enemy != null \
		and _preview_enemy_id != "" and _preview_enemy_id != current_enemy.id
	var preview_id := _preview_enemy_id if _preview_enemy_id != "" \
		else GameState.selected_enemy_id
	var lock_reason := "" if in_combat else _enemy_lock_reason(preview_id)
	var locked := lock_reason != "" and not switching
	_start_button.disabled = (in_combat and not switching) or locked
	_stop_button.disabled = not in_combat
	if switching:
		# 战斗中已选中其它预览目标：显式确认后才切换，黛玉青主按钮高亮
		_start_button.text = "切换目标"
		_start_button.tooltip_text = "切换到当前预览妖兽并重新开战"
		_start_button.remove_theme_stylebox_override("disabled")
		_start_button.remove_theme_color_override("font_disabled_color")
		ThemeBuilder.apply_primary_button(_start_button)
	elif in_combat:
		# 战斗中左按钮 = 状态展示：实时连胜（浅玉青淡底 + 黛玉青字，禁点）
		_start_button.text = "连胜 %d 场" % CombatEngine.win_streak
		_start_button.tooltip_text = "点击其它妖兽页签可预览并切换目标"
		_start_button.add_theme_stylebox_override("disabled",
			ThemeBuilder.panel_box(ThemeBuilder.COLOR_JADE_SOFT,
				ThemeBuilder.COLOR_JADE, 8, 1, 10))
		_start_button.add_theme_color_override("font_disabled_color",
			ThemeBuilder.COLOR_TEXT_JADE)
	else:
		_start_button.text = "开始历练"
		_start_button.tooltip_text = "可挑战" if not locked else (
			"需先击败前置妖兽（%s）" % lock_reason)
		_start_button.remove_theme_stylebox_override("disabled")
		_start_button.remove_theme_color_override("font_disabled_color")
		if locked:
			ThemeBuilder.apply_secondary_button(_start_button, true)
		else:
			ThemeBuilder.apply_primary_button(_start_button)
	# 「撤出秘境」样式在构建时一次配好（浅朱砂 / 禁用浅米），这里不再重刷 StyleBox


func _refresh_threshold_label() -> void:
	_threshold_label.text = "喝药阈值 %d%%" % int(round(GameState.auto_heal_threshold * 100.0))


func _enemies_for_region(region_id: String) -> Array:
	if DataRegistry == null or region_id == "":
		return []
	if DataRegistry.has_method("get_enemies_for_region"):
		var result: Variant = DataRegistry.call("get_enemies_for_region", region_id)
		if typeof(result) == TYPE_ARRAY:
			return result
	# 旧基包兜底：直接从区域数据取 id，再逐个取妖兽定义
	var out: Array = []
	var region: Dictionary = DataRegistry.regions.get(region_id, {})
	for enemy_id in region.get("enemies", []):
		var enemy := DataRegistry.get_enemy(String(enemy_id))
		if enemy != null:
			out.append(enemy)
	return out


func _rebuild_enemy_tabs() -> void:
	if _enemy_tabs == null:
		return
	for child in _enemy_tabs.get_children():
		_enemy_tabs.remove_child(child)
		child.queue_free()
	_enemy_buttons.clear()
	var region_id := String(GameState.get("selected_region_id"))
	if region_id == "" or not DataRegistry.regions.has(region_id):
		var keys := DataRegistry.regions.keys()
		region_id = String(keys[0]) if not keys.is_empty() else ""
		if region_id != "" and GameState.get("selected_region_id") != null:
			GameState.set("selected_region_id", region_id)
	var enemies := _enemies_for_region(region_id)
	if not enemies.is_empty():
		var selected_id := String(GameState.get("selected_enemy_id"))
		var selected_valid := false
		for enemy in enemies:
			if String(enemy.id) == selected_id:
				selected_valid = true
				break
		if not selected_valid and GameState.get("selected_enemy_id") != null:
			GameState.selected_enemy_id = enemies[0].id
	for enemy in enemies:
		var lock_reason := _enemy_lock_reason(enemy.id)
		var tab_text: String = String(enemy.display_name) if lock_reason == "" \
			else "锁 · %s" % String(enemy.display_name)
		var button := ThemeBuilder.small_button(tab_text)
		button.tooltip_text = "可挑战" if lock_reason == "" else lock_reason
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
		ThemeBuilder.apply_font_size(button, ThemeBuilder.FONT_CAPTION)
		# 三格均分 + 省略号 + 6px 内边距：妖兽名再长也严格落在卡片内宽
		ThemeBuilder.clip_button_text(button, tab_text)
		ThemeBuilder.tighten_button_padding(button, 4.0)
		ThemeBuilder.apply_enemy_grade_style(button, enemy.id)
		button.pressed.connect(_on_enemy_tab_pressed.bind(enemy.id))
		_enemy_tabs.add_child(button)
		_enemy_buttons[enemy.id] = button
	_refresh_enemy_tabs()



	# 动态重建后补挂触控约定（按钮 PASS + 14px 滑动守卫）
	ThemeBuilder.prepare_touch(_enemy_tabs)
func _refresh_region_highlight() -> void:
	for rid in _region_buttons.keys():
		var button: Button = _region_buttons[rid]
		var region_lock := _region_lock_reason(String(rid))
		button.disabled = region_lock != ""
		button.tooltip_text = "可挑战" if region_lock == "" else region_lock
		var active := String(rid) == GameState.selected_region_id
		button.add_theme_stylebox_override("normal", _tab_style(active))
		button.add_theme_stylebox_override("hover", _tab_style(active))
		button.add_theme_color_override("font_color",
			ThemeBuilder.COLOR_JADE if active else ThemeBuilder.COLOR_TEXT_DIM)


func _show_help() -> void:
	BottomSheet.show_help("秘境历练 · 规则", [
		{"text": "万物品阶", "bbcode": ThemeBuilder.material_grade_legend_bbcode(),
			"desc": "妖兽与镇魔塔妖魔名同样按此五档着色（与万象玉简一致）。"},
		{"text": "自动回合", "desc": "双方各自蓄势，气机满盈即出手；胜后连战，败则遁出秘境并恢复三成气血。"},
		{"text": "自动应对", "desc": "可设护道回春散、护身符与引雷符，依设定阈值与先后自行施用。引雷符每战初启时自耗 1 张，降下 45 点雷击真伤。"},
		{"text": "会心", "desc": "会心触发自有其极；剑意通明，超凡会心可化作更凌厉的破敌之威（会心造诣越深，会心一击越狠）。"},
		{"text": "区域与目标", "desc": "同一秘境须按顺序击败前置妖兽；跨入下一片秘境还须先胜上一片秘境头目。轻触妖兽可察看掉落与根底。"},
	])


## 缺料来源跳转：切区域并选中指定怪物
func select_source(zone_id: String, enemy_id: String) -> void:
	if zone_id != "" and DataRegistry.regions.has(zone_id):
		if GameState.selected_region_id != zone_id:
			_on_region_pressed(zone_id)
	if enemy_id != "" and DataRegistry.get_enemy(enemy_id) != null:
		_on_enemy_tab_pressed(enemy_id)
	refresh_all()


func _on_region_pressed(region_id: String) -> void:
	if region_id == GameState.selected_region_id:
		return
	var was_fighting := _realm_fighting()
	# 战斗中切区域只更新预览；不中断当前秘境战斗（镇魔塔冲层同样不受影响）
	GameState.selected_region_id = region_id
	var enemies := _enemies_for_region(region_id)
	if not enemies.is_empty():
		var target_id := String(enemies[0].id)
		_preview_enemy_id = target_id
		if not was_fighting:
			GameState.selected_enemy_id = target_id
	_rebuild_enemy_tabs()
	_refresh_region_highlight()
	refresh_all()
	if was_fighting:
		_show_selected_preview()
		_refresh_enemy_tabs()
		_refresh_buttons()
	elif _stage != null:
		var target := DataRegistry.get_enemy(GameState.selected_enemy_id)
		_stage.show_preview_enemy(target)
		_stage.refresh_idle()
		_stage.set_charge(0.0, 0.0)


func _refresh_enemy_tabs() -> void:
	var selected := GameState.selected_enemy_id
	# 镇魔塔战斗不改秘境页签选中（防串显镇塔妖将）
	if _realm_fighting() and CombatEngine.get_current_enemy() != null:
		selected = CombatEngine.get_current_enemy().id
	for enemy_id in _enemy_buttons.keys():
		var button: Button = _enemy_buttons[enemy_id]
		var active := String(enemy_id) == selected
		button.add_theme_stylebox_override("normal", _tab_style(active))
		button.add_theme_stylebox_override("hover", _tab_style(active))
		button.add_theme_color_override("font_color",
			ThemeBuilder.COLOR_JADE if active else ThemeBuilder.COLOR_TEXT_DIM)


func _tab_style(active: bool) -> StyleBoxFlat:
	if active and _tab_style_active != null:
		return _tab_style_active
	if not active and _tab_style_inactive != null:
		return _tab_style_inactive
	var box := ThemeBuilder.panel_box(ThemeBuilder.COLOR_SUBTLE, Color(0, 0, 0, 0), 8, 0, 10)
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	if active:
		box.bg_color = ThemeBuilder.COLOR_JADE_SOFT
		box.border_color = ThemeBuilder.COLOR_JADE
		box.set_border_width_all(1)
		_tab_style_active = box
	else:
		_tab_style_inactive = box
	return box


## 只收秘境战报（镇魔塔战报由塔纪要缓冲承接，不混入秘境纪要）
func _on_combat_log(line: String) -> void:
	if CombatEngine.is_tower_mode():
		return
	_append_log_line(line)


func _append_log_line(line: String) -> void:
	if _log_box == null:
		return
	# 隐藏页不追加节点（战斗可能在后台继续，回来只显示之后的新战报）
	if not is_visible_in_tree():
		_is_dirty = true
		return
	if _log_empty_label != null and _log_empty_label.visible:
		_log_empty_label.visible = false
	_log_box.add_child(ThemeBuilder.wrap_label(line, ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT))
	while _log_box.get_child_count() > MAX_LOG_LINES:
		var first := _log_box.get_child(0)
		_log_box.remove_child(first)
		first.queue_free()
	call_deferred("_scroll_log_to_bottom")


func _scroll_log_to_bottom() -> void:
	if _log_scroll == null:
		return
	var bar := _log_scroll.get_v_scroll_bar()
	if bar != null:
		_log_scroll.scroll_vertical = int(bar.max_value)


# ---------------------------------------------------------------- 交互

func _on_enemy_tab_pressed(enemy_id: String) -> void:
	var lock_reason := _enemy_lock_reason(enemy_id)
	if lock_reason != "":
		EventBus.toast.emit("需先击败前置妖兽（%s）" % lock_reason)
		return
	_preview_enemy_id = enemy_id
	if _realm_fighting():
		# 战斗中只更新详情卡预览；舞台与 CombatEngine 保持当前交战目标，
		# 玩家必须点「切换目标」才真正换怪。
		_show_selected_preview()
		_refresh_buttons()
		return
	GameState.selected_enemy_id = enemy_id
	_refresh_enemy_tabs()
	_refresh_buttons()
	if CombatEngine.is_active() and CombatEngine.is_tower_mode():
		# 镇魔塔冲层中点秘境妖兽：自动撤出镇魔塔转战（防双战冲突）
		CombatEngine.stop_combat("转战秘境")
		EventBus.toast.emit("已撤出镇魔塔，转战秘境")
		CombatEngine.start_combat(enemy_id)
	else:
		_show_selected_preview()
		if _stage != null:
			var target := DataRegistry.get_enemy(enemy_id)
			_stage.show_preview_enemy(target)
			_stage.refresh_idle()
			_stage.set_charge(0.0, 0.0)


func _on_start_pressed() -> void:
	var target_id := _preview_enemy_id if _preview_enemy_id != "" \
		else GameState.selected_enemy_id
	var lock_reason := _enemy_lock_reason(target_id)
	if lock_reason != "":
		EventBus.toast.emit("需先击败前置妖兽（%s）" % lock_reason)
		refresh_all()
		return
	# 战斗中点「切换目标」：重置单目标连胜后以预览目标重开战斗
	if _realm_fighting():
		var current_enemy := CombatEngine.get_current_enemy()
		if current_enemy == null or current_enemy.id == target_id:
			return
		CombatEngine.win_streak = 0
		GameState.selected_enemy_id = target_id
		CombatEngine.start_combat(target_id)
		EventBus.toast.emit("已切换目标：%s" % DataRegistry.get_enemy_name(target_id))
		refresh_all()
		return
	# 镇魔塔冲层中点「开始历练」：自动撤出镇魔塔转战秘境（防双战冲突与状态串扰）
	if CombatEngine.is_active() and CombatEngine.is_tower_mode():
		CombatEngine.stop_combat("转战秘境")
		EventBus.toast.emit("已撤出镇魔塔，转战秘境")
	GameState.selected_enemy_id = target_id
	CombatEngine.start_combat(target_id)
	refresh_all()


func _on_stop_pressed() -> void:
	CombatEngine.stop_combat("主动撤出秘境")
	refresh_all()


func _on_visibility_changed() -> void:
	set_process(is_visible_in_tree())
	if is_visible_in_tree():
		_request_fit()
		if _is_dirty:
			_is_dirty = false
			refresh_all()


func _on_threshold_changed(value: float) -> void:
	GameState.auto_heal_threshold = clampf(value / 100.0, 0.1, 0.9)
	_refresh_threshold_label()


func _on_combat_updated(payload: Dictionary) -> void:
	if not is_visible_in_tree():
		_is_dirty = true
		return
	# 双向隔离：镇魔塔战斗的实时 payload 不进秘境面板
	if not _realm_fighting():
		refresh_all()
		return
	if not bool(payload.get("active", false)):
		refresh_all()
		return
	var live := CombatEngine.get_current_enemy()
	var preview_enemy := DataRegistry.get_enemy(_preview_enemy_id) \
		if _preview_enemy_id != "" else null
	if preview_enemy != null and (live == null or preview_enemy.id != live.id):
		# 战斗中预览其它目标：信息卡保持预览名，舞台仍显示实时交战敌人
		_enemy_name_label.text = preview_enemy.display_name
		ThemeBuilder.apply_enemy_grade_style(_enemy_name_label, preview_enemy.id)
	else:
		_enemy_name_label.text = String(payload.get("enemy_name", "无"))
		if live != null:
			ThemeBuilder.apply_enemy_grade_style(_enemy_name_label, live.id)
	if _enemy_boss_chip != null:
		_enemy_boss_chip.visible = live != null and live.is_boss
	_refresh_enemy_tabs()


func _on_combat_started(enemy_id: String) -> void:
	_preview_enemy_id = enemy_id
	_refresh_buttons()
	_refresh_enemy_tabs()
	refresh_all()


func _on_layout_changed(_mode: int, _vp_size: Vector2, workspace_width: float) -> void:
	_apply_layout(workspace_width)


func _on_realm_changed(_realm_id: String, _realm_name: String) -> void:
	refresh_all()


func _on_combat_stopped(_reason: String) -> void:
	_preview_enemy_id = GameState.selected_enemy_id
	_refresh_buttons()
	_refresh_enemy_tabs()
	_refresh_stats()
	_show_selected_preview()



