class_name SkillActionPanel
extends Control
## 采集 / 制造 / 吐纳通用面板（移动端单列流式）：
## 技能经验条 + 可点击的悟道池里程碑 + 槽位状态 + 动作卡片列表。

## 用 preload 取脚本实例，避免新组件尚未进入全局类缓存时解析失败
const POOL_BAR_SCRIPT := preload("res://ui/components/PoolMilestoneBar.gd")

## 右上角「?」气泡合并说明：满级锁经验规则 + 淬炼积火候（卡片主面板不再挂长句）
const MERGED_RULE_TIP: String = \
	"百艺达到当前大境界上限后锁定熟练度、突破大境界方可继续精进（期间仍可正常运转获取产出）；淬炼动作可积累总火候"
## 总览卡熟练度条/悟道条统一高度，与 PoolMilestoneBar.BAR_HEIGHT 保持一致
const HEAD_BAR_HEIGHT: float = 12.0

var skill_id: String = "herbalism"

var _level_label: Label
var _title_label: Label
var _xp_bar: ProgressBar
var _xp_tween: Tween
var _xp_label: Label
var _pool_panel: PanelContainer
## 动态类型：组件脚本通过 preload 实例化，调用 set_ratio 走动态派发
var _pool_bar
var _pool_label: Label
var _pool_value: Label
## 可用悟道数值（鎏金）：挂在卡片最底行右侧，与左侧总火候左右呼应
var _pool_avail: Label
var _cards_grid: GridContainer
var _scroll: ScrollContainer
var _shell: VBoxContainer
## 经验行拆色：当前值（浓墨）/ 分母或提示（辅助灰）
var _xp_value_label: Label
## 总火候里程碑摘要：第一行「总火候 / 可用悟道」，第二行自动换行显示加成
var _tm_prefix: Label
var _tm_value: Label
var _tm_bonus: Label
## 动作列表四段分区：运转置顶 / 当阶高阶 / 往期低阶(默认折叠) / 更高阶未解锁(默认折叠)
var _list_root: VBoxContainer
var _fold_low: PanelContainer
var _fold_high: PanelContainer
var _fold_low_box: VBoxContainer
var _fold_high_box: VBoxContainer
var _fold_low_label: Label
var _fold_high_label: Label
var _fold_low_arrow: Label
var _fold_high_arrow: Label
var _fold_low_open: bool = false
var _fold_high_open: bool = false
## 列表重排延后执行标记（避免在按钮信号链里 reparent 打断点击）
var _layout_queued: bool = false
var _mode: int = EventBus.LayoutMode.COMPACT

var _cards: Dictionary = {}
var _is_dirty: bool = false


func _ready() -> void:
	_build()
	_connect_signals()
	visibility_changed.connect(_on_visibility_changed)
	refresh_header()
	refresh_pool()
	_apply_layout(EventBus.current_layout, EventBus.workspace_width)


func _on_layout_changed(mode: int, _vp_size: Vector2, workspace_width: float) -> void:	_apply_layout(mode, workspace_width)


## 宽屏：经验卡与悟道池左右并排；卡片多列
func _apply_layout(mode: int, workspace_width: float) -> void:
	_mode = mode
	if _cards_grid != null:
		var columns := 1
		if workspace_width >= 1060.0:
			columns = 3
		elif workspace_width >= 680.0:
			columns = 2
		_cards_grid.columns = columns
		for child in _cards_grid.get_children():
			if child is Control:
				(child as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL


func _build() -> void:
	_shell = ThemeBuilder.vbox(10)
	add_child(_shell)
	_shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shell.add_theme_constant_override("separation", 10)

	var meta := DataRegistry.get_skill_meta(skill_id)
	var category := String(meta.get("category", "gather"))
	var category_name := "采集"
	if category == "craft":
		category_name = "制造"
	elif category == "meditate":
		category_name = "吐纳"

	# ---- 顶部总览卡：原先「技能头 / 悟道池 / 槽位条」三张卡合并为一张，
	# 竖屏首屏省约 120px。四行结构：
	#   1 标题行（毛笔大标题 + 分类 chip + 等级「X / Y 重」 + 唯一 ?）
	#   2/3 双进度条行（2 列 Grid：左列熟练度条/悟道条共宽，右列进度值/悟道百分比右对齐）
	#   4 底行（左「总火候」EXPAND_FILL 左对齐 + 右「可用悟道」SHRINK_END，左右对称）
	var header := ThemeBuilder.card_panel()
	# 总览卡层级高于滚动列表区：任何残余特效都不会盖在「XXX寻灵」标题上
	header.z_index = 2
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_shell.add_child(header)
	var head_box := ThemeBuilder.vbox(6)
	header.add_child(head_box)

	# 1 标题行
	var title_row := ThemeBuilder.hbox(8)
	head_box.add_child(title_row)
	_title_label = ThemeBuilder.title_label(
		GameState.get_skill_display_name(skill_id), 20)
	title_row.add_child(_title_label)
	title_row.add_child(ThemeBuilder.chip(category_name,
		ThemeBuilder.COLOR_AMBER if category != "gather" else ThemeBuilder.COLOR_JADE))
	title_row.add_child(ThemeBuilder.expander())
	_level_label = ThemeBuilder.label("1 / 20 重", ThemeBuilder.FONT_BODY,
		ThemeBuilder.COLOR_TEXT_JADE)
	_level_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	_level_label.clip_text = true
	_level_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_row.add_child(_level_label)
	var help := ThemeBuilder.create_help_button(_open_glossary_sheet)
	help.custom_minimum_size = Vector2(44, 44)
	help.tooltip_text = MERGED_RULE_TIP
	title_row.add_child(help)

	# 2/3 经验行 + 悟道行：改为两条独立 HBox。
	# 进度条 EXPAND_FILL 吃掉剩余宽度，右侧文案 SHRINK_END 固定贴右；
	# 不再让 GridContainer 把右列压成零宽，1.20 大字档下「悟道 100.00%」仍完整可见。
	var head_grid := ThemeBuilder.vbox(8)
	head_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head_box.add_child(head_grid)

	var xp_row := ThemeBuilder.hbox(8)
	xp_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head_grid.add_child(xp_row)
	_xp_bar = ThemeBuilder.progress_bar(
		DataRegistry.get_skill_color(skill_id).darkened(0.22), HEAD_BAR_HEIGHT)
	_xp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_xp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	xp_row.add_child(_xp_bar)

	var xp_right := ThemeBuilder.hbox(6)
	xp_right.size_flags_horizontal = Control.SIZE_SHRINK_END
	xp_right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	xp_row.add_child(xp_right)
	_xp_value_label = ThemeBuilder.label("", ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_SECONDARY)
	xp_right.add_child(_xp_value_label)
	_xp_label = ThemeBuilder.label("", ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_JADE)
	xp_right.add_child(_xp_label)
	ThemeBuilder.attach_header_watermark(header, IconLibrary.get_skill_icon(skill_id))

	var pool_row := ThemeBuilder.hbox(8)
	pool_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head_grid.add_child(pool_row)
	_pool_bar = POOL_BAR_SCRIPT.new()
	pool_row.add_child(_pool_bar)
	# 须在 add_child 后设（PoolMilestoneBar._ready 会改写最小尺寸）；与经验条严格同高
	_pool_bar.custom_minimum_size = Vector2(0, HEAD_BAR_HEIGHT)
	_pool_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pool_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var pool_right := ThemeBuilder.hbox(6)
	pool_right.size_flags_horizontal = Control.SIZE_SHRINK_END
	pool_right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pool_row.add_child(pool_right)
	_pool_label = ThemeBuilder.label("", ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_SECONDARY)
	pool_right.add_child(_pool_label)
	_pool_value = ThemeBuilder.label("悟道 --%", ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_GOLD)
	_pool_value.clip_text = false
	pool_right.add_child(_pool_value)

	# 4/5 底行拆两行：第一行「总火候 | 可用悟道」左右对齐；
	# 第二行仅在有里程碑加成时显示「耗时 -15.0% · 双倍 +10%」，可换行不撑宽。
	var tm_row := ThemeBuilder.hbox(8)
	tm_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head_box.add_child(tm_row)
	var tm_left := ThemeBuilder.hbox(6)
	tm_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tm_left.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tm_row.add_child(tm_left)
	_tm_prefix = ThemeBuilder.label("总火候", ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_SECONDARY)
	tm_left.add_child(_tm_prefix)
	_tm_value = ThemeBuilder.label("--", ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_JADE)
	tm_left.add_child(_tm_value)

	var avail_right := ThemeBuilder.hbox(6)
	avail_right.size_flags_horizontal = Control.SIZE_SHRINK_END
	avail_right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tm_row.add_child(avail_right)
	var avail_label := ThemeBuilder.label("可用悟道", ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_SECONDARY)
	avail_label.clip_text = true
	avail_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	avail_right.add_child(avail_label)
	_pool_avail = ThemeBuilder.label("0", ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_GOLD)
	_pool_avail.clip_text = true
	_pool_avail.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	avail_right.add_child(_pool_avail)

	_tm_bonus = ThemeBuilder.wrap_label("", ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_SECONDARY)
	ThemeBuilder.apply_font_size(_tm_bonus, ThemeBuilder.FONT_CAPTION)
	_tm_bonus.visible = false
	head_box.add_child(_tm_bonus)

	# 三槽文字状态条已移除：全局三槽状态收口至顶栏胶囊 +「三才运转总览」与卡片槽位按钮

	# ---- 动作卡片：GridContainer，按工作区宽度 1/2/3 列
	var scroll := ThemeBuilder.scroll_container()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# 显式开启裁切：滚出视口的卡片特效/飘字被容器边界挡住（配合 ActionCard 视口校验双保险）
	scroll.clip_contents = true
	_shell.add_child(scroll)
	_scroll = scroll
	_list_root = ThemeBuilder.vbox(10)
	_list_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list_root)
	_cards_grid = GridContainer.new()
	_cards_grid.columns = 1
	_cards_grid.add_theme_constant_override("h_separation", 10)
	_cards_grid.add_theme_constant_override("v_separation", 10)
	_cards_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_root.add_child(_cards_grid)

	# 折叠栏（往期低阶 / 更高阶未解锁）：44 高、PASS + 8px 阈值，不吞列表滑动
	var fold_low := _make_fold_bar()
	_fold_low = fold_low[0]
	_fold_low_label = fold_low[1]
	_fold_low_arrow = fold_low[2]
	_list_root.add_child(_fold_low)
	_fold_low_box = ThemeBuilder.vbox(10)
	_fold_low_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_root.add_child(_fold_low_box)
	var fold_high := _make_fold_bar()
	_fold_high = fold_high[0]
	_fold_high_label = fold_high[1]
	_fold_high_arrow = fold_high[2]
	_list_root.add_child(_fold_high)
	_fold_high_box = ThemeBuilder.vbox(10)
	_fold_high_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_root.add_child(_fold_high_box)
	ThemeBuilder.make_card_tappable(_fold_low, _toggle_low_fold)
	ThemeBuilder.make_card_tappable(_fold_high, _toggle_high_fold)

	for action in DataRegistry.get_actions_for_skill(skill_id):
		var card := ActionCard.new()
		card.name = "Card_%s" % action.id
		card.setup(action)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.glossary_requested.connect(_open_glossary_sheet)
		_cards_grid.add_child(card)
		_cards[action.id] = card

	ThemeBuilder.prepare_touch(_shell)
	_layout_sections()


func _ignore_mouse_children(node: Node) -> void:
	for child in node.get_children():
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ignore_mouse_children(child)


func _connect_signals() -> void:
	EventBus.skill_xp_changed.connect(_on_skill_xp_changed)
	EventBus.skill_level_up.connect(_on_skill_level_up)
	EventBus.mastery_pool_changed.connect(_on_pool_changed)
	EventBus.action_started.connect(_on_action_changed)
	EventBus.action_stopped.connect(_on_action_changed)
	# 读档恢复运转槽时不重发 action_started（避免开场音效），由 game_loaded 直接刷新
	EventBus.game_loaded.connect(_on_game_loaded)
	EventBus.realm_changed.connect(_on_realm_changed)
	EventBus.inventory_changed.connect(_on_inventory_changed)
	EventBus.combat_started.connect(_on_combat_state_changed)
	EventBus.combat_stopped.connect(_on_combat_state_changed)
	EventBus.layout_changed.connect(_on_layout_changed)


func refresh_header() -> void:
	if not is_visible_in_tree():
		_is_dirty = true
		return
	if _title_label != null:
		_title_label.text = GameState.get_skill_display_name(skill_id)
	var progress := GameState.get_skill_progress(skill_id)
	var level := int(progress["level"])
	var cap := int(progress["cap"])
	# 修仙称谓：等级以「重」计，杜绝 Lv 等英文缩写
	_level_label.text = "%d / %d 重" % [level, cap]
	var capped := bool(progress["capped"])
	UiMotion.advance_progress(_xp_bar, float(progress["ratio"]), 0.22)
	# 第二行右侧不重复等级：满级简短横幅或紧凑经验进度（辅助灰）
	if capped:
		_xp_value_label.text = ""
		_xp_label.text = "已臻化境"
		_xp_label.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT_JADE)
		# 悬停补充下一境界解锁细节（正文保持精简，防 450px 折行）
		var next_cap_realm := _next_cap_realm()
		_xp_label.tooltip_text = "" if next_cap_realm == null else \
			"突破「%s」后解锁至 %d 重" % [
				_tier_name(next_cap_realm.tier), next_cap_realm.skill_level_cap]
	else:
		_xp_value_label.text = "%s / %s" % [
			GameFormulas.format_num(float(progress["into"])),
			GameFormulas.format_num(float(progress["need"]))]
		_xp_value_label.add_theme_color_override("font_color",
			ThemeBuilder.COLOR_TEXT_SECONDARY)
		_xp_label.text = ""
	# 总火候里程碑：第一行只放数值与阶数；第二行放可换行的加成摘要
	if _tm_value != null:
		var total := GameState.get_skill_total_mastery(skill_id)
		var tier := GameFormulas.skill_mastery_tier(total)
		if tier <= 0:
			_tm_value.text = "0（未入阶）"
			_tm_value.add_theme_color_override("font_color",
				ThemeBuilder.COLOR_TEXT_PRIMARY)
			_tm_bonus.text = ""
			_tm_bonus.visible = false
		else:
			_tm_value.text = "%d（%d 阶）" % [total, tier]
			_tm_value.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT_JADE)
			_tm_bonus.text = "耗时 -%.1f%% · 双倍 +%d%%" % [
				float(tier) * 1.5, tier]
			_tm_bonus.visible = true


## 向下扫描境界表，取第一个开放更高技能等级上限的大境界。
## 炼气 20 / 筑基 45 / 金丹 75 等「当前境界已满」都靠它给出正确的突破目标。
func _next_cap_realm() -> RealmData:
	var realm := GameState.get_realm()
	if realm == null:
		return null
	var current_cap := GameState.get_skill_level_cap()
	var index := DataRegistry.realm_order.find(realm.id)
	if index < 0:
		return null
	for i in range(index + 1, DataRegistry.realm_order.size()):
		var candidate := DataRegistry.get_realm(DataRegistry.realm_order[i])
		if candidate != null and candidate.skill_level_cap > current_cap:
			return candidate
	return null


func _tier_name(tier: int) -> String:
	match tier:
		0:
			return "炼气期"
		1:
			return "筑基期"
		2:
			return "金丹期"
		3:
			return "元婴期"
		4:
			return "大乘"
		_:
			return "更高境界"


func refresh_pool() -> void:
	if not is_visible_in_tree():
		_is_dirty = true
		return
	var info := GameState.get_pool_info(skill_id)
	var ratio := float(info["ratio"])
	var capacity := float(info.get("capacity", 0.0))
	var current := float(info.get("current", 0.0))
	_pool_bar.set_ratio(ratio)
	if capacity > 0.0 and current >= capacity:
		_pool_value.text = "悟道圆满"
		_pool_value.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT_GOLD)
	else:
		_pool_value.text = "悟道 %.2f%%" % (ratio * 100.0)
		_pool_value.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT_GOLD)
	_pool_avail.text = GameFormulas.format_num(current)




# ---------------------------------------------------------------- 四段分区与折叠

## 折叠栏：44 高、容器 PASS + 文本 IGNORE（prepare_touch 已统一），8px 阈值内抬起才切换
func _make_fold_bar() -> Array:
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", ThemeBuilder.panel_box(
		ThemeBuilder.COLOR_CARD, ThemeBuilder.COLOR_BORDER, 10, 1, 8))
	bar.custom_minimum_size = Vector2(0, 44)
	var row := ThemeBuilder.hbox(8)
	bar.add_child(row)
	var label := ThemeBuilder.label("", ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_PRIMARY)
	ThemeBuilder.apply_font_size(label, ThemeBuilder.FONT_CAPTION)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)
	var arrow := ThemeBuilder.label("展开 ▸", ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_SECONDARY)
	ThemeBuilder.apply_font_size(arrow, ThemeBuilder.FONT_CAPTION)
	arrow.size_flags_horizontal = Control.SIZE_SHRINK_END
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(arrow)
	return [bar, label, arrow]


func _toggle_low_fold() -> void:
	_fold_low_open = not _fold_low_open
	_layout_sections()


func _toggle_high_fold() -> void:
	_fold_high_open = not _fold_high_open
	_layout_sections()


func _move_card(action_id: String, parent: Node) -> void:
	var card: Control = _cards.get(action_id, null)
	if card == null:
		return
	# 即便已在目标容器里也要 remove+add：appendChild 顺序才是显示顺序，
	# 否则「高阶优先 / 运转置顶」对首次构建时就已在 grid 里的卡片不生效。
	if card.get_parent() != null:
		card.get_parent().remove_child(card)
	parent.add_child(card)


## 四段分区：折叠状态统一固定展示 4 张卡片（运转置顶占名额，恒定总数零跳动），
## 优先级：运转置顶 > 已解锁按解锁等级降序 > 未解锁升序；其余全部收入底部折叠栏
## （往阶XX法门 / 更高阶未解锁）。折叠状态记忆在面板实例上，刷新运转状态不重置。
func _layout_sections() -> void:
	if _cards_grid == null:
		return
	var running: Array[ActionData] = []
	var unlocked: Array[ActionData] = []
	var locked: Array[ActionData] = []
	for action_id in _cards.keys():
		var card: ActionCard = _cards[action_id]
		if card == null or card.action == null:
			continue
		if GameState.get_action_running_slot(card.action.id) >= 0:
			running.append(card.action)
		elif GameState.get_skill_level(skill_id) >= card.action.required_level:
			unlocked.append(card.action)
		else:
			locked.append(card.action)
	running.sort_custom(func(a: ActionData, b: ActionData) -> bool:
		return GameState.get_slot_of_action(a.id) < GameState.get_slot_of_action(b.id))
	unlocked.sort_custom(func(a: ActionData, b: ActionData) -> bool:
		return a.required_level > b.required_level)
	locked.sort_custom(func(a: ActionData, b: ActionData) -> bool:
		return a.required_level < b.required_level)

	# 恒定 4 张：运转 0~3 槽时顶部总数不变（点运转页面零跳动），运转 >=4 则全量置顶
	var visible_count := maxi(4, running.size())
	var ordered: Array[ActionData] = []
	ordered.append_array(running)
	ordered.append_array(unlocked)
	ordered.append_array(locked)
	var low: Array[ActionData] = []

	# 显式组装顺序数组，严禁在遍历 get_children() 时原地 move_child
	# （索引漂移会让首项漏排：曾导致「运转中卡片被滞留的旧卡挤到第二位」）
	var grid_nodes: Array[Control] = []
	var high_nodes: Array[Control] = []
	var skill_level := GameState.get_skill_level(skill_id)
	for i in range(ordered.size()):
		var action := ordered[i]
		if i < visible_count:
			grid_nodes.append(_cards[action.id])
		elif skill_level < action.required_level:
			high_nodes.append(_cards[action.id])
		else:
			low.append(action)

	# 标准归位循环：逐容器按显式顺序从 index 0 起排定
	for i in range(grid_nodes.size()):
		_place_node(grid_nodes[i], _cards_grid, i)
	for i in range(low.size()):
		_place_node(_cards[low[i].id], _fold_low_box, i)
	for i in range(high_nodes.size()):
		_place_node(high_nodes[i], _fold_high_box, i)

	_fold_low.visible = not low.is_empty()
	_fold_low_box.visible = _fold_low_open and not low.is_empty()
	_fold_low_label.text = _fold_low_title(low)
	_fold_low_label.add_theme_color_override("font_color",
		ThemeBuilder.COLOR_TEXT_JADE if _fold_low_open else ThemeBuilder.COLOR_TEXT_PRIMARY)
	_fold_low_arrow.text = "收起 ▾" if _fold_low_open else "展开 ▸"
	_fold_high.visible = not high_nodes.is_empty()
	_fold_high_box.visible = _fold_high_open and not high_nodes.is_empty()
	_fold_high_label.text = _fold_high_title(high_nodes.size())
	_fold_high_label.add_theme_color_override("font_color",
		ThemeBuilder.COLOR_TEXT_JADE if _fold_high_open else ThemeBuilder.COLOR_TEXT_PRIMARY)
	_fold_high_arrow.text = "收起 ▾" if _fold_high_open else "展开 ▸"


## 折叠栏主标题按百艺类别命名，副标按未满火候项数切换，紧凑单行不折行。
func _fold_category_name() -> String:
	match skill_id:
		"herbalism":
			return "灵药"
		"woodcutting":
			return "灵木"
		"mining":
			return "矿脉"
		"alchemy":
			return "丹方"
		"forging":
			return "器谱"
		"talisman":
			return "符箓"
		"cultivation":
			return "吐纳"
		_:
			return "百艺"


func _fold_low_title(items: Array) -> String:
	var unmaxed := 0
	for entry in items:
		var act: ActionData = entry
		if GameState.get_mastery_level(act.id) < GameFormulas.MAX_MASTERY_LEVEL:
			unmaxed += 1
	var suffix := "%d 项可淬炼" % unmaxed if unmaxed > 0 else "均已圆满"
	return "往阶%s（共 %d 项 · %s）" % [
		_fold_category_name(), items.size(), suffix]


func _fold_high_title(count: int) -> String:
	return "后续%s（共 %d 项）" % [_fold_category_name(), count]


## 归位单节点：必要时换容器，再用 move_child 定序（升序遍历调用，索引不漂移）
func _place_node(node: Control, parent: Control, index: int) -> void:
	if node.get_parent() != parent:
		if node.get_parent() != null:
			node.get_parent().remove_child(node)
		parent.add_child(node)
	parent.move_child(node, index)


## 来源跳转目标在折叠区内时自动展开（在 focus_action 滚动前调用）
func _expand_for(action_id: String) -> void:
	var card: Control = _cards.get(action_id, null)
	if card == null:
		return
	if _fold_low_box != null and _fold_low_box.is_ancestor_of(card) and not _fold_low_open:
		_fold_low_open = true
		_layout_sections()
	elif _fold_high_box != null and _fold_high_box.is_ancestor_of(card) and not _fold_high_open:
		_fold_high_open = true
		_layout_sections()


# ---------------------------------------------------------------- 百艺与悟道图解

func _on_pool_gui_input(event: InputEvent) -> void:
	var pressed := false
	if event is InputEventScreenTouch:
		pressed = event.pressed
	elif event is InputEventMouseButton:
		pressed = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if pressed:
		_open_glossary_sheet()


## 标题「?」、悟道池整卡、动作卡的「时 · 艺 · 候 · 倍」行共用这一份图解
func _open_glossary_sheet() -> void:
	var meta := DataRegistry.get_skill_meta(skill_id)
	var info := GameState.get_pool_info(skill_id)
	var rows: Array = []
	rows.append({
		"text": "本门百艺",
		"desc": String(meta.get("desc", "静心修习，自有精进。")),
		"color": ThemeBuilder.COLOR_AMBER,
	})
	rows.append({
		"text": "时 · 单次耗时",
		"desc": "完成一次动作所需时间；受境界、火候、坊市法器与藏经阁功法共同影响。",
		"color": ThemeBuilder.COLOR_TEXT,
	})
	rows.append({
		"text": "艺 · 技能经验",
		"desc": "每次运转获得的百艺经验，决定技能重数与高阶动作的解锁。百艺达到当前大境界上限后锁定熟练度、突破大境界方可继续精进（期间仍可正常运转获取产出）；此艺臻至化境后，多余心得尽数化入悟道。三才分工：主修求速 · 分神求悟 · 化身求奇珍。",
		"color": ThemeBuilder.COLOR_TEXT,
	})
	rows.append({
		"text": "候 · 火候经验",
		"desc": "注入当前动作的专精经验；火候只加成对应动作，采药火候不会加成伐木或开矿。",
		"color": ThemeBuilder.COLOR_TEXT,
	})
	rows.append({
		"text": "倍 · 双倍概率",
		"desc": "本次产出翻倍的概率；火候每 5 重 +1%，悟道池、五行相生与藏经阁另有加成。",
		"color": ThemeBuilder.COLOR_TEXT,
	})
	rows.append({
		"text": "五行相生",
		"desc": "木生火（丹道产出提升）、火生土 / 土生金（器道精良率提升）；满足条件时动作卡会亮起对应标签。",
		"color": ThemeBuilder.COLOR_EMERALD,
	})
	rows.append({
		"text": "火候收益",
		"desc": "每重耗时 -0.20%，150 重约 -30%；每 5 重双倍 / 精良率 +1%，150 重给满 20% 上限。",
		"color": ThemeBuilder.COLOR_TEXT,
	})
	rows.append({
		"text": "总火候里程碑",
		"desc": "淬炼动作可积累总火候；本门百艺所有动作火候累计每满 50 重，永久提升全系运转速度 -1.5% 与双倍产出 +1%（上限 500 重）。",
		"color": ThemeBuilder.COLOR_TEXT_JADE,
	})
	rows.append({
		"text": "悟道池 · 总专精",
		"desc": "每次运转所得火候经验全额汇入此公共池；池容 = 本技能动作数 × %s。" % \
			GameFormulas.format_num(GameFormulas.POOL_CAPACITY_PER_ACTION),
		"color": ThemeBuilder.COLOR_AMBER,
	})
	rows.append({
		"text": "当前池：%s / %s（%.1f%%）" % [
			GameFormulas.format_num(float(info["current"])),
			GameFormulas.format_num(float(info["capacity"])),
			float(info["ratio"]) * 100.0,
		],
		"desc": "进度条上的 10%% / 25%% / 50%% / 95%% 四枚菱形即四档里程碑，达成后自动生效。",
		"color": ThemeBuilder.COLOR_TEXT,
	})
	for entry in GameFormulas.POOL_THRESHOLDS:
		var dict: Dictionary = entry
		var ratio := float(dict["ratio"])
		var unlocked := GameState.is_pool_threshold(skill_id, ratio)
		rows.append({
			"text": "%s ｜ %s" % [String(dict["label"]), String(dict["effect"])],
			"desc": "已达成" if unlocked else "未达成 · 需池内经验达到 %s" % String(dict["label"]),
			"color": ThemeBuilder.COLOR_EMERALD if unlocked else ThemeBuilder.COLOR_TEXT_DIM,
		})
	rows.append({
		"text": "淬炼火候",
		"desc": "轻触动作卡片「淬炼」，消耗本技能悟道值直接提升该动作 1 重火候；圆满后按钮变为「火候圆满」。",
		"color": ThemeBuilder.COLOR_AMBER,
	})
	BottomSheet.show_help("百艺与悟道图解", rows)


# ---------------------------------------------------------------- 缺料引导定位

## 从来源跳转回来时滚动到目标动作卡片，并做一次玉青描边提示
func focus_action(action_id: String) -> void:
	var card: Control = _cards.get(action_id, null)
	if card == null:
		return
	# 目标在折叠区内时先自动展开，再滚动定位（缺料来源跳转永不失灵）
	_expand_for(action_id)
	await get_tree().process_frame
	await get_tree().process_frame
	if _scroll != null and is_instance_valid(card):
		# ensure_control_visible 在 GridContainer 尚未完成布局时可能无效，直接按卡片 y 定位
		var bar := _scroll.get_v_scroll_bar()
		var max_scroll := 0 if bar == null else int(bar.max_value)
		_scroll.scroll_vertical = clampi(int(card.position.y - 16.0), 0, max_scroll)
	# 已移除绿色圆圈聚焦特效：仅保留页面切换与滚动定位


# ---------------------------------------------------------------- 信号

func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		return
	# 切回本页先同步卡片槽位占用态（其它百艺可能刚启停动作）
	_refresh_cards()
	if not _is_dirty:
		return
	_is_dirty = false
	refresh_header()
	refresh_pool()


## 同步所有动作卡按钮行（空闲高亮 / 占用显示动作名）；只改文案与样式
func _refresh_cards() -> void:
	for action_id in _cards.keys():
		var card: ActionCard = _cards[action_id]
		if card != null and is_instance_valid(card):
			card.refresh()


## 顶栏槽位轻点跳转：直接切到对应百艺并高亮定位正在运转的动作卡


func _on_skill_xp_changed(changed_skill: String, _xp: float, _level: int) -> void:
	if changed_skill == skill_id:
		refresh_header()


func _on_skill_level_up(changed_skill: String, _level: int) -> void:
	if changed_skill != skill_id:
		return
	refresh_header()
	if InkVfxLayer.instance != null and is_visible_in_tree():
		InkVfxLayer.instance.play_ring(
			get_global_rect().position + Vector2(size.x * 0.5, 64.0),
			ThemeBuilder.COLOR_AMBER, 54.0)


func _on_pool_changed(changed_skill: String, _current: float, _capacity: float) -> void:
	if changed_skill == skill_id:
		refresh_pool()


## 读档/云导入：恢复出来的运转槽不重发 action_started（避免开场音效），直接按新状态刷新
func _on_game_loaded() -> void:
	_is_dirty = true
	if is_visible_in_tree():
		refresh_header()
		refresh_pool()
	_on_action_changed(-1, "")


func _on_action_changed(_slot: int, _action_id: String) -> void:
	# 同步全部卡片的槽位占用态（只改按钮文案/样式，不重建节点）
	_refresh_cards()
	# 重排会 reparent 卡片：必须延后到下一帧执行，否则在本帧「按钮 pressed 信号链」里
	# remove_child/add_child 会打断点击处理（真机表现：按钮点不动、要连点好几次）
	if _layout_queued:
		return
	_layout_queued = true
	call_deferred("_deferred_sections")


func _deferred_sections() -> void:
	_layout_queued = false
	if not is_inside_tree():
		return
	_layout_sections()


## 秘境状态变化：三槽文字条已移除，卡片按钮态无需感知战斗
func _on_combat_state_changed(_arg: String) -> void:
	pass


func _on_inventory_changed() -> void:
	# 脏标记合并：同帧多信号只刷新一次；隐藏页延后到切回时补刷
	if not is_visible_in_tree():
		return
	if _cards_refresh_queued:
		return
	_cards_refresh_queued = true
	call_deferred("_do_cards_refresh")


var _cards_refresh_queued := false


func _do_cards_refresh() -> void:
	_cards_refresh_queued = false
	if not is_visible_in_tree():
		return
	_refresh_cards()


func _on_realm_changed(_realm_id: String, _realm_name: String) -> void:
	refresh_header()
	refresh_pool()
	_layout_sections()


