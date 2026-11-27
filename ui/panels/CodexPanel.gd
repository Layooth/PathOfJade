class_name CodexPanel
extends Control
## 「万象玉简」图鉴：收集进度 + 5 档里程碑 + 分类网格（未收录显示剪影 ???）。

const TABS: Array = [
	{"key": "material", "label": "灵材丹符"},
	{"key": "equipment", "label": "神兵法袍"},
	{"key": "enemy", "label": "秘境妖兽"},
	{"key": "technique", "label": "道藏功法"},
	{"key": "scripture", "label": "典籍"},
]
## 「典籍」页：全游戏核心术语分组词典（纯文本，不参与收集统计）
const SCRIPTURE_GROUPS: Array = [
	{
		"title": "第一章 · 境界与天劫",
		"rows": [
			["三十一境", "自炼气一层至真仙圆满，共 31 境；修为圆满即可破境。"],
			["八重天劫", "筑基、结丹、碎婴、化神、炼虚、合体、大乘、飞升，共八重天劫。"],
			["道心悟性", "渡劫受挫时凝成道心悟性，可减缓当境天雷，渡劫成功后仍留存。"],
			["后期雷压", "入后期后，天劫附带本源雷压；渡劫前宜备护身符与渡劫丹药。"],
			["飞升三果", "大乘圆满飞升需渡劫飞升丹、本命先天至宝与五行法则各 1 重，修为亦须圆满。"],
		],
	},
	{
		"title": "第二章 · 百艺、火候与三才",
		"rows": [
			["百艺分野", "采药、伐木、开矿、丹道、器道、符箓与吐纳，各成一门。"],
			["重数封顶", "百艺重数随大境界封顶；达到当前上限显示「已臻化境」，产出不中断。"],
			["单卡火候", "每张动作卡单修火候，专精该动作，逐步缩短耗时并增添翻倍机缘。"],
			["悟道池", "火候经验汇入悟道池；圆满时显示「悟道圆满」，四档进度依次惠及经验、耗时、免料与双倍、会心。"],
			["三才运转", "主修自始即有；筑基开分神，金丹初期开化身，共三槽。"],
		],
	},
	{
		"title": "第三章 · 道身与秘境历练",
		"rows": [
			["命中与闪避", "高阶兵刃自带命中，抵消中后期妖兽闪避；护甲亦可助己闪避。"],
			["会心机缘", "会心机缘至 75% 为止，多余会心转为会心伤害。"],
			["秘境递进", "须逐阶击败前置妖兽，方能解锁更强之敌与高阶区域。"],
			["法宝祭炼", "筑基中期开启祭炼，兵刃增益攻伐，法袍增益守御。"],
			["镇魔塔与俸禄", "筑基初期开启镇魔塔；每日俸禄按历史最高层结算，每个自然日可领一次。"],
		],
	},
	{
		"title": "第四章 · 洞府灵田",
		"rows": [
			["四块灵田", "四块地块依次开垦；开垦二号灵田后启用一键收获与播种。"],
			["灵肥催熟", "灵草阶位最多低于作物 1 阶；每轮最多施 3 次，每次缩去四分之一剩余时长，丰产 +20%。"],
			["仙壤淬灵", "筑基初期开启；灵脉越高，可耗灵种阶位越高，每种灵种留存 20 枚底仓。"],
			["伴生奇珍", "收割可得聚灵甘露与百年朱果；灵田随时辰生长，闭关亦不歇息。"],
		],
	},
	{
		"title": "第五章 · 灵根洗髓",
		"rows": [
			["开启", "炼气七层开启灵根洗髓。"],
			["后天纯化", "五灵根经四次后天洗髓，依次纯化为天灵根。"],
			["五行导引", "金、木、水、火、土五脉可耗灵石导引切换，切换时保留当前品阶。"],
		],
	},
	{
		"title": "第六章 · 本命法宝",
		"rows": [
			["三择器胚", "元婴初期凝练本命法宝，可选青竹蜂云剑、玄天古钟或掌天灵鼎。"],
			["融材温养", "可熔常规灵材与淘汰装备温养，由灵宝渐至先天至宝；灵种与洗练珍材不可熔入。"],
			["铭刻器纹", "消耗上古残魂、真龙残鳞、幽冥残卷铭刻并洗练器纹。"],
		],
	},
	{
		"title": "第七章 · 灵潭清茗",
		"rows": [
			["开启", "化神初期开启灵潭清茗，垂钓不占三才槽位。"],
			["八档产出", "收竿可得清露、灵鱼、灵石、灵草、悟道、灵种、残宝与玉简奇遇；连续九竿清露，第十竿必有灵应。"],
			["四款灵茶", "悟道清茶、凝神灵茶、破厄剑茶、灵鱼养神汤，依次于化神初期、化神后期、炼虚初期、炼虚后期开启。"],
			["文火慢煎", "按茶方备清露、灵鱼与指定灵草，文火慢煎 3 秒后生效，增益持续 60 分钟。"],
		],
	},
	{
		"title": "第八章 · 五行法则",
		"rows": [
			["开启", "合体初期参悟金、木、水、火、土五条法则。"],
			["逐重参悟", "每条法则至 5 重，消耗对应珍材与悟道池经验逐重参悟。"],
			["木之法则", "木之法则 1 重开启灵田自动收割与续播。"],
			["飞升根基", "五法各至少 1 重，方与大乘飞升三果相合。"],
		],
	},
	{
		"title": "第九章 · 仙盟与玉简云篆",
		"rows": [
			["仙盟悬赏", "炼气三层开启；三枚悬赏令分采集、制造与清剿，每个自然日最多领 10 单。"],
			["急令", "制造令可能化为急令，酬劳更厚；悬赏随大境界精进。"],
			["藏经阁", "炼气六层开启；功法可随大境界增至 4 槽运转。"],
			["天道榜", "登录仙籍可观境界、镇魔塔与灵石三榜。"],
			["仙盟传书", "云端递送物资传书，打开仙盟传书页收取奖励。"],
			["玉简云篆", "仙籍云篆定时自动同步；云端较新时二选一，绝不悄悄覆盖本地或云端。"],
		],
	},
]
const MILESTONES: Array = [
	{"percent": 0.20, "label": "经验+5%"},
	{"percent": 0.40, "label": "双倍+3%"},
	{"percent": 0.60, "label": "气血+10% 灵田+10%"},
	{"percent": 0.80, "label": "耗时-5%"},
	{"percent": 1.00, "label": "攻击+15%"},
]
const EFFECT_LABELS: Dictionary = {
	"herb_double": "采药双倍", "farm_speed": "灵田生长", "alchemy_double": "丹道双倍",
	"alchemy_free": "炼丹免料", "gather_interval": "采集耗时", "seed_bonus": "灵种副产",
	"attack_pct": "攻击", "crit_chance": "会心率", "attack_interval": "攻击间隔",
	"thunder_dmg": "雷符真伤", "sword_qi": "剑气真伤", "max_hp": "最大气血",
	"defense": "防御", "trib_reduce": "天雷减伤", "ward_bonus": "护符减伤",
	"damage_reduce": "妖兽与天劫免伤",
	"meditate_xp": "吐纳修为", "heal_pct": "回血效果",
}

var _tab: String = "material"
var _tab_buttons: Dictionary = {}
var _bar: ProgressBar
var _percent_label: Label
var _count_label: Label
var _milestone_row: HFlowContainer


## 进度条上的鎏金菱形里程碑刻度（20/40/60/80%，纯 _draw 零节点开销）
class MilestoneTicks extends Control:
	func _draw() -> void:
		var gold := Color(0.78, 0.63, 0.28, 0.95)
		for i in range(1, 5):
			var x := size.x * 0.2 * float(i)
			var y := size.y * 0.5
			var pts := PackedVector2Array([
				Vector2(x, y - 5.0), Vector2(x + 4.0, y),
				Vector2(x, y + 5.0), Vector2(x - 4.0, y)])
			draw_colored_polygon(pts, gold)
			draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]),
				Color(gold, 0.9), 1.0)
var _grid: GridContainer
var _layout_mode: int = EventBus.LayoutMode.COMPACT
var _rebuild_queued: bool = false
var _is_dirty: bool = false
var _grid_signature: String = ""
## 图鉴卡片池：同一分页内按「id」复用，发现状态变化时只重建对应一张
var _card_cache: Dictionary = {}
var _cache_tab: String = ""


func _ready() -> void:
	_layout_mode = EventBus.current_layout
	_build()
	EventBus.layout_changed.connect(_on_layout_changed)
	EventBus.inventory_changed.connect(_queue_rebuild)
	EventBus.technique_changed.connect(_queue_rebuild)
	EventBus.game_loaded.connect(_queue_rebuild)
	visibility_changed.connect(_on_visibility_changed)
	_refresh_tab_styles()
	rebuild()


func _build() -> void:
	var root := ThemeBuilder.vbox(10)
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 10)

	var header := ThemeBuilder.card_panel()
	root.add_child(header)
	var head := ThemeBuilder.vbox(6)
	header.add_child(head)
	var title_row := ThemeBuilder.hbox(8)
	head.add_child(title_row)
	title_row.add_child(ThemeBuilder.icon_rect(IconLibrary.get_ui_icon("codex"), 24))
	title_row.add_child(ThemeBuilder.title_label("万象玉简", 20))
	title_row.add_child(ThemeBuilder.expander())
	# 进度统计同行拆色：百分比黛玉青 + 数量辅助灰（双 Label，禁 RichTextLabel）
	_percent_label = ThemeBuilder.label("0%", 15, ThemeBuilder.COLOR_JADE)
	title_row.add_child(_percent_label)
	_count_label = ThemeBuilder.label("· 0 / 0", ThemeBuilder.FONT_BODY_SUB,
		ThemeBuilder.COLOR_TEXT_SECONDARY)
	title_row.add_child(_count_label)
	# 「?」固定最右上角，与全站各页一致
	var help := ThemeBuilder.create_help_button(_show_help)
	help.custom_minimum_size = Vector2(44, 44)
	help.tooltip_text = "品阶图例与收集规则"
	title_row.add_child(help)

	# 进度条 + 20/40/60/80% 四枚鎏金菱形里程碑刻度（纯 _draw，不加节点）
	var bar_wrap := Control.new()
	bar_wrap.custom_minimum_size = Vector2(0, 16)
	bar_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(bar_wrap)
	_bar = ThemeBuilder.progress_bar(ThemeBuilder.COLOR_JADE, 10)
	bar_wrap.add_child(_bar)
	_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bar.offset_top = 3.0
	var ticks := MilestoneTicks.new()
	ticks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_wrap.add_child(ticks)
	ticks.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_milestone_row = HFlowContainer.new()
	_milestone_row.add_theme_constant_override("h_separation", 4)
	_milestone_row.add_theme_constant_override("v_separation", 4)
	head.add_child(_milestone_row)

	var filter_row := ThemeBuilder.hbox(6)
	root.add_child(filter_row)
	for entry in TABS:
		var dict: Dictionary = entry
		var key := String(dict["key"])
		var button := ThemeBuilder.small_button(String(dict["label"]))
		button.toggle_mode = true
		button.button_pressed = key == _tab
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ThemeBuilder.apply_font_size(button, ThemeBuilder.FONT_CAPTION)
		button.pressed.connect(_on_tab_pressed.bind(key))
		filter_row.add_child(button)
		_tab_buttons[key] = button

	var scroll := ThemeBuilder.scroll_container()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_grid)

	ThemeBuilder.prepare_touch(root)
	_apply_width(EventBus.workspace_width)


func _on_layout_changed(mode: int, _vp: Vector2, workspace: float) -> void:
	_layout_mode = mode
	_apply_width(workspace)


func _apply_width(_workspace: float) -> void:
	if _grid == null:
		return
	if _tab == "scripture":
		_grid.columns = 1
		return
	match _layout_mode:
		EventBus.LayoutMode.WIDE:
			_grid.columns = 5
		EventBus.LayoutMode.MEDIUM:
			_grid.columns = 4
		_:
			_grid.columns = 3


func _on_tab_pressed(key: String) -> void:
	_tab = key
	_refresh_tab_styles()
	rebuild()


func _refresh_tab_styles() -> void:
	for tab_key in _tab_buttons.keys():
		var button: Button = _tab_buttons[tab_key]
		var active := String(tab_key) == _tab
		button.button_pressed = active
		ThemeBuilder.apply_toggle_button(button, active)


func _queue_rebuild() -> void:
	if not is_visible_in_tree():
		_is_dirty = true
		return
	if _rebuild_queued:
		return
	_rebuild_queued = true
	call_deferred("_do_rebuild")


func _do_rebuild() -> void:
	_rebuild_queued = false
	if not is_visible_in_tree():
		_is_dirty = true
		return
	_is_dirty = false
	rebuild()


func _on_visibility_changed() -> void:
	if not is_visible_in_tree() or not _is_dirty:
		return
	_is_dirty = false
	_queue_rebuild()


func rebuild() -> void:
	if _grid == null:
		return
	# 上一轮分帧补建未完成：完成后统一重刷，避免被高频收集信号反复打断
	if not _pending_entries.is_empty():
		_rebuild_pending = true
		return
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	var entries := _entries()
	var signature_parts: PackedStringArray = [_tab]
	for entry in entries:
		signature_parts.append("%s:%s" % [entry.get("id", ""), entry.get("found", false)])
	var signature := "\n".join(signature_parts)
	var percent := GameState.get_codex_percent()
	_percent_label.text = "%d%%" % int(round(percent * 100.0))
	_count_label.text = "· %d / %d" % [GameState.get_codex_found(), GameState.get_codex_total()]
	_bar.value = percent
	if signature == _grid_signature and _grid.get_child_count() > 0:
		return
	_grid_signature = signature
	for child in _milestone_row.get_children():
		_milestone_row.remove_child(child)
		child.queue_free()
	for entry in MILESTONES:
		var dict: Dictionary = entry
		var reached := percent + 0.0001 >= float(dict["percent"])
		var text_value := "%d%% %s" % [
			int(round(float(dict["percent"]) * 100.0)), String(dict["label"])]
		# 轻量通透徽标（非厚重实底块）：达成=浅玉青底玉青字带勾，未达=宣纸灰底暖灰字
		var badge := PanelContainer.new()
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var bg := Color(0.85, 0.92, 0.89, 1.0) if reached else ThemeBuilder.COLOR_SUBTLE
		var edge := ThemeBuilder.COLOR_TEXT_JADE if reached else ThemeBuilder.COLOR_BORDER
		var box := ThemeBuilder.panel_box(bg, edge, 8, 1, 0)
		box.content_margin_left = 6
		box.content_margin_right = 6
		box.content_margin_top = 2
		box.content_margin_bottom = 2
		badge.add_theme_stylebox_override("panel", box)
		var lbl := ThemeBuilder.label(("✓ " if reached else "") + text_value,
			ThemeBuilder.FONT_CAPTION,
			ThemeBuilder.COLOR_TEXT_JADE if reached else ThemeBuilder.COLOR_TEXT_SECONDARY)
		badge.add_child(lbl)
		_milestone_row.add_child(badge)

	_apply_width(EventBus.workspace_width)
	# 换分页才整页重建；同一分页内的状态变化走卡片池复用
	if _tab == "scripture":
		_cache_tab = _tab
		_clear_card_cache()
		for child in _grid.get_children():
			_grid.remove_child(child)
			child.queue_free()
		_build_scripture_cards()
		return
	if _cache_tab != _tab:
		_cache_tab = _tab
		_clear_card_cache()
		for child in _grid.get_children():
			_grid.remove_child(child)
			child.queue_free()
	_rebuild_cards_pooled(entries)


## 同分页卡片池：发现的词条保留原节点，只新建「新发现」或「未收录 → 已收录」的卡片。
## 首次铺满同样分帧补建（每帧最多 CARD_CHUNK 张），避免整页数百个节点同帧构建。
const CARD_CHUNK: int = 8
var _rebuild_gen: int = 0
var _rebuild_cursor: int = 0
var _pending_entries: Array = []
var _pending_prev: Dictionary = {}
var _pending_next: Dictionary = {}
var _rebuild_pending: bool = false


func _rebuild_cards_pooled(entries: Array) -> void:
	_rebuild_gen += 1
	var gen := _rebuild_gen
	_rebuild_cursor = 0
	_pending_entries = entries
	_pending_prev = _card_cache.duplicate()
	_pending_next = {}
	# 旧卡片先摘出容器（保留节点供复用），避免切分页时旧词条闪现在前排
	for key in _pending_prev.keys():
		var old_node: Variant = (_pending_prev[key] as Dictionary).get("node", null)
		if old_node is Node and (old_node as Node).get_parent() == _grid:
			_grid.remove_child(old_node as Node)
	if _rebuild_step(gen):
		_finish_card_rebuild(gen)
	else:
		_drive_card_rebuild(gen)


func _rebuild_step(gen: int) -> bool:
	if gen != _rebuild_gen or _grid == null:
		return true
	var target := mini(_rebuild_cursor + CARD_CHUNK, _pending_entries.size())
	while _rebuild_cursor < target:
		var entry: Dictionary = _pending_entries[_rebuild_cursor]
		var entry_id := String(entry.get("id", ""))
		var found := bool(entry.get("found", false))
		var cache_key := "%s|%s" % [_tab, entry_id]
		var cached: Variant = _pending_prev.get(cache_key, null)
		var node: Button = null
		if cached is Dictionary:
			var cached_node: Variant = (cached as Dictionary).get("node", null)
			if cached_node is Button and is_instance_valid(cached_node) \
					and bool((cached as Dictionary).get("found", false)) == found:
				node = cached_node as Button
		if node == null:
			if cached is Dictionary:
				var stale: Variant = (cached as Dictionary).get("node", null)
				if stale is Node and is_instance_valid(stale):
					_free_card_node(stale as Node)
			node = _build_card(entry)
			node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			ThemeBuilder.prepare_touch(node)
		_card_cache[cache_key] = {"node": node, "found": found}
		_pending_next[cache_key] = true
		if node.get_parent() != _grid:
			if node.get_parent() != null:
				node.get_parent().remove_child(node)
			_grid.add_child(node)
		_grid.move_child(node, _rebuild_cursor)
		_rebuild_cursor += 1
	return _rebuild_cursor >= _pending_entries.size()


func _drive_card_rebuild(gen: int) -> void:
	while gen == _rebuild_gen and is_inside_tree():
		# 切走后暂停补建，切回再续：后台补建不与当前页抢帧
		if not is_visible_in_tree():
			await visibility_changed
			continue
		await get_tree().process_frame
		if gen != _rebuild_gen or not is_inside_tree():
			return
		if _rebuild_step(gen):
			_finish_card_rebuild(gen)
			return


func _finish_card_rebuild(gen: int) -> void:
	if gen != _rebuild_gen:
		return
	for key in _pending_prev.keys():
		if _pending_next.has(key):
			continue
		var leftover: Variant = (_pending_prev[key] as Dictionary).get("node", null)
		if leftover is Node and is_instance_valid(leftover):
			_free_card_node(leftover as Node)
		_card_cache.erase(key)
	_pending_entries = []
	_pending_prev = {}
	ThemeBuilder.prepare_touch(self)
	if _rebuild_pending:
		_rebuild_pending = false
		call_deferred("rebuild")


func _free_card_node(node: Node) -> void:
	if node.get_parent() != null:
		node.get_parent().remove_child(node)
	node.queue_free()


func _clear_card_cache() -> void:
	for key in _card_cache.keys():
		var node: Variant = (_card_cache[key] as Dictionary).get("node", null)
		if node is Node and is_instance_valid(node):
			_free_card_node(node as Node)
	_card_cache.clear()


## 设置页「修行典籍」入口：跳到万象玉简并切到典籍分页

	# 动态重建后补挂触控约定（按钮 PASS + 14px 滑动守卫）
	ThemeBuilder.prepare_touch(self)
func show_scripture_tab() -> void:
	if _tab == "scripture":
		return
	_tab = "scripture"
	_refresh_tab_styles()
	rebuild()


## 典籍分页：按分组铺满整行的词条卡
func _build_scripture_cards() -> void:
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	for group_value in SCRIPTURE_GROUPS:
		var group: Dictionary = group_value
		var card := ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD_DEEP,
			ThemeBuilder.COLOR_BORDER, 8, 12)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_grid.add_child(card)
		var box := ThemeBuilder.vbox(8)
		card.add_child(box)
		box.add_child(ThemeBuilder.card_title_label(String(group["title"]),
			ThemeBuilder.FONT_CARD_TITLE, ThemeBuilder.COLOR_TEXT_TITLE_GOLD))
		for row_value in (group["rows"] as Array):
			var row: Array = row_value
			var entry := ThemeBuilder.wrap_label("%s ｜ %s" % [
				String(row[0]), String(row[1])],
				ThemeBuilder.FONT_BODY_SUB, ThemeBuilder.COLOR_TEXT)
			ThemeBuilder.apply_font_size(entry, ThemeBuilder.FONT_BODY_SUB)
			box.add_child(entry)


func _entries() -> Array:
	var out: Array = []
	match _tab:
		"material":
			for key in DataRegistry.items.keys():
				var item := DataRegistry.get_item(String(key))
				if item != null and item.category != ItemData.Category.EQUIPMENT:
					out.append({"id": String(key), "name": item.display_name,
						"desc": item.description, "found": GameState.discovered_items.has(String(key)),
						"kind": "item"})
			for tea_id in FishingTeaSystem.TEAS.keys():
				var tea: Dictionary = FishingTeaSystem.TEAS[tea_id]
				out.append({"id": String(tea_id), "name": str(tea.get("name", "")),
					"desc": "烹煮饮用后收录，功效持续 60 分钟。",
					"found": FishingTeaSystem.is_tea_brewed(String(tea_id)),
					"icon": str(tea.get("icon", "tea_pot")), "kind": "tea"})
		"equipment":
			for key in DataRegistry.items.keys():
				var item := DataRegistry.get_item(String(key))
				if item != null and item.category == ItemData.Category.EQUIPMENT:
					out.append({"id": String(key), "name": item.display_name,
						"desc": item.description, "found": GameState.discovered_items.has(String(key)),
						"kind": "item"})
		"enemy":
			for key in DataRegistry.enemies.keys():
				var enemy := DataRegistry.get_enemy(String(key))
				out.append({"id": String(key), "name": enemy.display_name if enemy != null else String(key),
					"desc": enemy.description if enemy != null else "",
					"found": GameState.discovered_enemies.has(String(key)),
					"enemy": true, "kind": "enemy"})
		"technique":
			for tech_value in DataRegistry.get_all_techniques():
				var tech := tech_value as TechniqueData
				out.append({"id": tech.id, "name": tech.name, "desc": tech.description,
					"found": GameState.is_technique_unlocked(tech.id),
					"icon": tech.icon_key, "kind": "technique"})
	return out


func _build_card(entry: Dictionary) -> Button:
	var found := bool(entry.get("found", false))
	var button := Button.new()
	button.custom_minimum_size = Vector2(86, 104)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.tooltip_text = String(entry.get("name", ""))
	var bg := ThemeBuilder.COLOR_CARD if found else ThemeBuilder.COLOR_CARD_DEEP
	var border := ThemeBuilder.COLOR_BORDER
	button.add_theme_stylebox_override("normal",
		ThemeBuilder.panel_box(ThemeBuilder.card_color(bg), border, 10, 1, 6))
	button.add_theme_stylebox_override("hover",
		ThemeBuilder.panel_box(ThemeBuilder.card_color(
			ThemeBuilder.COLOR_CARD_HOVER if found else bg),
			ThemeBuilder.COLOR_JADE if found else border, 10, 1, 6))
	button.add_theme_stylebox_override("pressed",
		ThemeBuilder.panel_box(ThemeBuilder.card_color(ThemeBuilder.COLOR_CARD_HOVER),
			border, 10, 1, 6))

	var box := ThemeBuilder.vbox(4)
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 6.0
	box.offset_right = -6.0
	box.offset_top = 8.0
	box.offset_bottom = -6.0
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(box)

	if found:
		var tex: Texture2D
		if String(entry.get("kind", "")) == "tea":
			tex = IconLibrary.get_icon(String(entry.get("icon", "tea_pot")))
		elif entry.has("icon"):
			tex = IconLibrary.get_technique_icon(String(entry["icon"]))
		elif entry.has("enemy"):
			tex = IconLibrary.get_enemy_icon(String(entry["id"]))
		else:
			tex = IconLibrary.get_item_icon(String(entry["id"]))
		var frame := IconFrame.new()
		frame.setup(tex, 48, ThemeBuilder.COLOR_JADE, false, 40)
		frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		box.add_child(frame)
		var name_label := ThemeBuilder.card_title_label(String(entry.get("name", "")),
			ThemeBuilder.FONT_CARD_TITLE, ThemeBuilder.COLOR_TEXT)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.clip_text = true
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_child(name_label)
		# 材料/灵种名称直接用品阶字色（神材加粗）：保持「图标 + 名称」干净两段布局
		var grade: Dictionary = DataRegistry.get_item_grade(String(entry.get("id", "")))
		if String(entry.get("kind", "")) == "tea":
			name_label.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT_JADE)
		elif not grade.is_empty():
			ThemeBuilder.apply_material_grade_style(name_label, int(grade["tier"]))
		elif String(entry.get("kind", "")) == "technique":
			ThemeBuilder.apply_technique_grade_style(name_label, String(entry.get("id", "")))
		elif String(entry.get("kind", "")) == "enemy":
			ThemeBuilder.apply_enemy_grade_style(name_label, String(entry.get("id", "")))
		button.pressed.connect(func() -> void: _show_entry(entry))
	else:
		var question := ThemeBuilder.label("？", 24, ThemeBuilder.COLOR_TEXT_DIM)
		question.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(question)
		var missing := ThemeBuilder.label("未收录", 11, ThemeBuilder.COLOR_TEXT_DIM)
		missing.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(missing)
	return button


func _show_entry(entry: Dictionary) -> void:
	var kind := String(entry.get("kind", "item"))
	var entry_id := String(entry.get("id", ""))
	var rows: Array = []
	var actions: Array = []
	var icon_texture: Texture2D = null
	var title := String(entry.get("name", "词条"))
	if kind == "tea":
		var tea: Dictionary = FishingTeaSystem.TEAS.get(entry_id, {})
		if tea.is_empty():
			return
		var fish_count := int(tea.get("fish", 0))
		var recipe := "灵潭清露 ×%d · %s" % [int(tea.get("dew", 0)),
			("碧波灵鱼 ×%d" % fish_count) if fish_count > 0
			else ("合用灵草 ×%d" % int(tea.get("herb_count", 0)))]
		rows.append({"text": "灵茶说明", "desc": "烹煮饮用后获得增益，灵茶功效持续 60 分钟。"})
		rows.append({"text": "配方消耗", "desc": recipe})
		rows.append({"text": "持续功效", "desc": str(tea.get("effect", ""))})
		rows.append({"text": "收录状态", "desc": "已品鉴" if FishingTeaSystem.is_tea_brewed(entry_id)
			else "尚未烹煮饮用"})
		icon_texture = IconLibrary.get_icon(str(tea.get("icon", "tea_pot")))
		actions.append({"text": "前往洞府烹茶 ▸", "callback": Callable(self, "_open_fishing_tea"),
			"full_width": true, "primary": true})
		_show_detail(title, rows, ThemeBuilder.COLOR_TEXT_JADE, icon_texture, actions)
		return
	if kind == "item":
		var item := DataRegistry.get_item(entry_id)
		if item == null:
			return
		rows.append({"text": "词条说明", "desc": item.description if item.description != "" else "暂无说明。"})
		var mgrade: Dictionary = DataRegistry.get_item_grade(entry_id)
		if not mgrade.is_empty():
			rows.append({
				"text": "品阶：%s" % String(mgrade["name"]),
				"desc": "来源解锁 %d 重 · 灵田肥力 %d/株" % [
					int(mgrade["unlock_level"]), int(mgrade["fertility"])],
				"color": ThemeBuilder.material_grade_color(int(mgrade["tier"])),
			})
		var stats := item.get_stat_summary()
		if stats == "":
			stats = "售价 %d 灵石" % item.sell_price
		else:
			stats += " · 售价 %d 灵石" % item.sell_price
		rows.append({"text": "属性", "desc": stats})
		var sources := DataRegistry.get_item_sources(entry_id)
		var source_text := "暂无已知来源"
		var has_fishing_source := false
		if not sources.is_empty():
			var parts: Array[String] = []
			for source in sources:
				var source_dict: Dictionary = source
				parts.append(String(source_dict.get("label", "")))
				if String(source_dict.get("type", "")) == "fishing_tea":
					has_fishing_source = true
			source_text = "\n".join(parts)
		rows.append({"text": "获取来源", "desc": source_text})
		if has_fishing_source:
			icon_texture = IconLibrary.get_item_icon(entry_id)
			actions.append({"text": "前往洞府烹茶 ▸", "callback": Callable(self, "_open_fishing_tea"),
				"full_width": true, "primary": true})
	elif kind == "enemy":
		var enemy := DataRegistry.get_enemy(entry_id)
		if enemy == null:
			return
		rows.append({"text": "妖兽说明", "desc": enemy.description if enemy.description != "" else "暂无说明。"})
		rows.append({"text": "属性", "desc": "气血 %d · 攻击 %d · 防御 %d · 间隔 %.1fs" % [
			enemy.max_hp, enemy.attack, enemy.defense, enemy.attack_interval]})
		var region: Dictionary = DataRegistry.regions.get(enemy.region_id, {})
		rows.append({"text": "出没区域", "desc": "%s（%s）" % [
			String(region.get("name", enemy.region_id)),
			"头目" if enemy.is_boss else "普通"]})
		if not enemy.loot_table.is_empty():
			rows.append({"text": "掉落", "desc": enemy.get_loot_text()})
	else:
		var tech := DataRegistry.get_technique(entry_id)
		if tech == null:
			return
		rows.append({"text": "道藏说明", "desc": tech.description if tech.description != "" else "暂无说明。"})
		rows.append({"text": "流派", "desc": tech.school_name()})
		var effect_parts: Array[String] = []
		for key in tech.effects.keys():
			var value := tech.get_scaled_effect(String(key), 1)
			effect_parts.append("%s %s%.0f%%" % [
				String(EFFECT_LABELS.get(String(key), String(key))),
				"+" if value >= 0.0 else "", value * 100.0])
		rows.append({"text": "基础效果", "desc": " · ".join(effect_parts)})
		if tech.is_drop_only():
			rows.append({"text": "获取来源", "desc": "%s 掉落（%.0f%%）· 可用贡献保底兑换" % [
				DataRegistry.get_enemy_name(tech.drop_enemy_id), tech.drop_chance * 100.0]})
		else:
			rows.append({"text": "获取来源", "desc": "藏经阁兑换 · 贡献 %d" % tech.unlock_cost_points})
	# 材料/丹符/法宝/功法标题用品阶字色（与网格名称同源）
	var title_color := ThemeBuilder.COLOR_TEXT
	if kind == "item":
		var g2: Dictionary = DataRegistry.get_item_grade(entry_id)
		if not g2.is_empty():
			title_color = ThemeBuilder.get_material_grade_color(int(g2["tier"]))
	elif kind == "technique":
		var tg: Dictionary = DataRegistry.get_technique_grade(entry_id)
		if not tg.is_empty():
			title_color = ThemeBuilder.get_material_grade_color(int(tg["tier"]))
	elif kind == "enemy":
		var eg: Dictionary = DataRegistry.get_enemy_grade(entry_id)
		if not eg.is_empty():
			title_color = ThemeBuilder.get_material_grade_color(int(eg["tier"]))
	if not actions.is_empty():
		_show_detail(title, rows, title_color, icon_texture, actions)
		return
	BottomSheet.show_text(title, rows, title_color)


func _show_detail(title: String, rows: Array, title_color: Color,
		icon_texture: Texture2D, actions: Array) -> void:
	var detail_rows: Array = []
	for row_value in rows:
		var row: Dictionary = row_value
		detail_rows.append({
			"label": String(row.get("text", "")),
			"value": String(row.get("desc", "")),
			"color": row.get("color", ThemeBuilder.COLOR_TEXT_PRIMARY),
		})
	BottomSheet.show_detail({
		"title": title,
		"title_color": title_color,
		"icon": icon_texture,
		"icon_accent": ThemeBuilder.COLOR_JADE,
		"rows": detail_rows,
		"actions": actions,
	})


func _open_fishing_tea() -> void:
	if BottomSheet.instance != null:
		BottomSheet.instance.hide_sheet()
	EventBus.navigate_to.emit("fishing_tea")


func _show_help() -> void:
	BottomSheet.show_help("万象玉简 · 图例", [
		{"text": "万物品阶（涵盖灵材、丹符、法宝、功法与妖兽）", "bbcode": ThemeBuilder.material_grade_legend_bbcode()},
		{"text": "收集规则", "desc": "首次获得材料 / 击败妖兽 / 参悟功法 / 烹煮灵茶即自动收录；未收录显示剪影 ???。品阶名称颜色与行囊、灵田完全同源。"},
	])




