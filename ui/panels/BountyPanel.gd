class_name BountyPanel
extends Control
## 「仙盟悬赏」：3 个常驻悬赏令（物资征集 / 妖兽清剿），提交得灵石+贡献+技能经验。

const UNLOCK_ORDER: int = 2
const UNLOCK_LABEL: String = "炼气三层"
const UNLOCK_DESC: String = "仙盟悬赏可交付物资征集与妖兽清剿令，换取灵石、仙盟贡献与技能经验。突破至炼气三层后开启。"

var _normal_root: Control
var _lock_card: PanelContainer
var _points_label: Label
var _done_label: Label
var _free_button: Button
var _paid_button: Button
var _grid: GridContainer
var _cards: Array[Control] = []
var _poll: float = 0.0
var _rebuild_queued: bool = false
var _is_dirty: bool = false
## 悬赏对象签名：id / 目标未变时仅就地刷新进度与交付按钮
var _bounty_sig: String = ""


func _ready() -> void:
	_build()
	EventBus.bounty_changed.connect(_queue_rebuild)
	EventBus.layout_changed.connect(_on_layout_changed)
	EventBus.game_loaded.connect(_queue_rebuild)
	EventBus.realm_changed.connect(_on_realm_changed_for_gate)
	visibility_changed.connect(_on_visibility_changed)
	_apply_unlock_gate()
	if _is_unlocked():
		BountyManager.ensure_bounties()
	rebuild()


func _process(delta: float) -> void:
	_poll += delta
	if _poll < 1.0:
		return
	_poll = 0.0
	if _free_button != null:
		var remain := BountyManager.free_refresh_remaining()
		_free_button.text = "免费刷新（就绪）" if remain <= 0.0 \
			else "免费刷新（%s）" % GameFormulas.format_duration(remain)
		_free_button.disabled = remain > 0.0


func _is_unlocked() -> bool:
	return GameState.get_realm_index() >= UNLOCK_ORDER


func _apply_unlock_gate() -> void:
	if _normal_root == null:
		return
	var unlocked := _is_unlocked()
	_normal_root.visible = unlocked
	if _lock_card != null:
		_lock_card.visible = not unlocked


func _build_lock_card() -> PanelContainer:
	var card := ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD_DEEP,
		ThemeBuilder.COLOR_BORDER, 10, 16)
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box := ThemeBuilder.vbox(12)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(box)
	var title := ThemeBuilder.title_label("需%s · 仙盟悬赏" % UNLOCK_LABEL,
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
	title_row.add_child(ThemeBuilder.icon_rect(IconLibrary.get_ui_icon("bounty"), 24))
	title_row.add_child(ThemeBuilder.title_label("仙盟悬赏", 20))
	var help := ThemeBuilder.create_help_button(_show_help)
	help.custom_minimum_size = Vector2(44, 44)
	help.tooltip_text = "查看仙盟悬赏规则"
	title_row.add_child(help)
	title_row.add_child(ThemeBuilder.expander())
	title_row.add_child(ThemeBuilder.create_seal_badge("仙盟", "cinnabar"))
	_points_label = ThemeBuilder.label("贡献 0", 14, ThemeBuilder.COLOR_AMBER)
	title_row.add_child(_points_label)
	# 全站唯一「?」固定在最右侧
	title_row.move_child(help, -1)
	_done_label = ThemeBuilder.label("今日赏格 0 / %d 单 · 累计 0 单" % BountyManager.DAILY_BOUNTY_LIMIT,
		ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_SECONDARY)
	head.add_child(_done_label)

	var refresh_row := ThemeBuilder.hbox(6)
	head.add_child(refresh_row)
	_free_button = ThemeBuilder.small_button("免费刷新")
	_free_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ThemeBuilder.apply_font_size(_free_button, ThemeBuilder.FONT_BODY)
	_free_button.pressed.connect(func() -> void: BountyManager.free_refresh_all())
	refresh_row.add_child(_free_button)
	_paid_button = ThemeBuilder.small_button("灵石刷新")
	_paid_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ThemeBuilder.apply_font_size(_paid_button, ThemeBuilder.FONT_BODY)
	_paid_button.pressed.connect(func() -> void: BountyManager.paid_refresh_all())
	refresh_row.add_child(_paid_button)

	var scroll := ThemeBuilder.scroll_container()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 1
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_grid)

	ThemeBuilder.prepare_touch(root)
	_apply_width(EventBus.workspace_width)
	_lock_card = _build_lock_card()
	add_child(_lock_card)


func _on_layout_changed(_mode: int, _vp: Vector2, workspace: float) -> void:
	_apply_width(workspace)


func _apply_width(workspace: float) -> void:
	if _grid != null:
		_grid.columns = 3 if workspace >= 1060.0 else (2 if workspace >= 680.0 else 1)
		for child in _grid.get_children():
			if child is Control:
				(child as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL


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


func _on_realm_changed_for_gate(_realm_id: String, _realm_name: String) -> void:
	_apply_unlock_gate()
	_queue_rebuild()


func _on_visibility_changed() -> void:
	set_process(is_visible_in_tree())
	if not is_visible_in_tree() or not _is_dirty:
		return
	_is_dirty = false
	_queue_rebuild()


func rebuild() -> void:
	if _grid == null:
		return
	_apply_unlock_gate()
	if not _is_unlocked():
		return
	BountyManager.ensure_bounties()
	_points_label.text = "贡献 %s" % GameFormulas.format_num(float(GameState.alliance_points))
	_done_label.text = "今日赏格 %d / %d 单 · 累计 %s 单" % [
		BountyManager.daily_count(), BountyManager.DAILY_BOUNTY_LIMIT,
		GameFormulas.format_num(float(GameState.bounties_done))]
	var remain := BountyManager.free_refresh_remaining()
	var daily_full := BountyManager.daily_limit_reached()
	_free_button.text = "免费刷新" if remain <= 0.0 \
		else "免费刷新 %s" % _cooldown_text(remain)
	_free_button.disabled = daily_full or remain > 0.0
	_paid_button.text = "灵石刷新 %d" % BountyManager.paid_refresh_cost()
	_paid_button.disabled = daily_full
	if _free_button.disabled:
		ThemeBuilder.apply_secondary_button(_free_button)
	else:
		ThemeBuilder.apply_primary_button(_free_button)
	ThemeBuilder.apply_secondary_button(_paid_button)

	# 悬赏对象本身没换（后台掉材料只推进度）时：只就地刷新每张卡的进度与交付按钮，
	# 不销毁 / 重建任何卡片，滚动位置自然保持不动。
	var sig_parts: PackedStringArray = []
	for bounty_value in GameState.active_bounties:
		var bounty: Dictionary = bounty_value
		sig_parts.append("%s|%s|%d" % [String(bounty.get("id", "")),
			String(bounty.get("target_id", "")), int(bounty.get("remaining", 0))])
	var bounty_sig := "\n".join(sig_parts)
	if bounty_sig == _bounty_sig and _cards.size() == GameState.active_bounties.size():
		var valid := true
		for card_value in _cards:
			var card := card_value as Control
			if card == null or not is_instance_valid(card):
				valid = false
				break
		if valid:
			for i in range(_cards.size()):
				_refresh_card_state(_cards[i] as PanelContainer, GameState.active_bounties[i])
			return
	_bounty_sig = bounty_sig
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	_cards.clear()
	for i in range(GameState.active_bounties.size()):
		var card := _build_card(i, GameState.active_bounties[i])
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_grid.add_child(card)
		_cards.append(card)



	# 动态重建后补挂触控约定（按钮 PASS + 14px 滑动守卫）
	ThemeBuilder.prepare_touch(self)
func _build_card(index: int, bounty: Dictionary) -> PanelContainer:
	var is_kill := String(bounty.get("type", "")) == BountyManager.SUBMIT_KILL
	var can_submit := BountyManager.can_submit(bounty)
	var card := ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD, ThemeBuilder.COLOR_BORDER, 12, 12)
	var outer := ThemeBuilder.hbox(8)
	card.add_child(outer)

	var icon := IconFrame.new()
	outer.add_child(icon)
	var target := String(bounty.get("target_id", ""))
	var tex: Texture2D = IconLibrary.get_enemy_icon(target) if is_kill \
		else IconLibrary.get_item_icon(target)
	icon.setup(tex, 44, ThemeBuilder.COLOR_CINNABAR if is_kill else ThemeBuilder.COLOR_JADE)

	var box := ThemeBuilder.vbox(3)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(box)

	# ① 悬赏标题 + 类型标签
	var title_row := ThemeBuilder.hbox(6)
	box.add_child(title_row)
	var bounty_title := ThemeBuilder.card_title_label("%s ×%d" % [
		String(bounty.get("target_name", "")), int(bounty.get("remaining", 0))])
	# 物资征集按物品品阶 / 妖兽清剿按妖兽品阶着色
	if not is_kill:
		ThemeBuilder.apply_item_grade_style(bounty_title, target)
	else:
		ThemeBuilder.apply_enemy_grade_style(bounty_title, target)
	title_row.add_child(bounty_title)
	title_row.add_child(ThemeBuilder.chip("妖兽清剿" if is_kill else "物资征集",
		ThemeBuilder.COLOR_CINNABAR if is_kill else ThemeBuilder.COLOR_JADE))
	if bool(bounty.get("is_urgent", false)):
		title_row.add_child(ThemeBuilder.chip("急令", ThemeBuilder.COLOR_TEXT_GOLD))
	title_row.add_child(ThemeBuilder.expander())

	# ② 单行进度目标：达标玉青、未达标浓墨（留引用供后台掉落时就地改写）
	var progress_label := ThemeBuilder.label(BountyManager.get_progress_text(bounty),
		ThemeBuilder.FONT_BODY_SUB,
		ThemeBuilder.COLOR_TEXT_JADE if can_submit else ThemeBuilder.COLOR_TEXT_PRIMARY)
	box.add_child(progress_label)

	# ③ 紧凑奖励摘要（单行省略，技能经验等明细收进委托书浮层）
	var reward_label := ThemeBuilder.label("灵石 +%s · 贡献 +%d" % [
		GameFormulas.format_num(float(bounty.get("stones", 0))),
		int(bounty.get("points", 0))], ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_GOLD)
	reward_label.clip_text = true
	reward_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(reward_label)

	var submit_text := "交付领奖"
	if BountyManager.daily_limit_reached():
		submit_text = "今日已满额"
	elif not can_submit:
		submit_text = "进度不足"
	var submit := ThemeBuilder.small_button(submit_text)
	submit.custom_minimum_size = Vector2(0, ThemeBuilder.TOUCH_MIN)
	submit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ThemeBuilder.apply_font_size(submit, ThemeBuilder.FONT_BODY)
	submit.disabled = not can_submit
	if can_submit:
		ThemeBuilder.apply_primary_button(submit)
	submit.pressed.connect(_on_submit_pressed.bind(index, submit))
	box.add_child(submit)
	card.set_meta("bounty_progress_label", progress_label)
	card.set_meta("bounty_submit", submit)
	# 轻点卡片空白处：完整委托书 + 目标来源快捷跳转
	ThemeBuilder.make_card_tappable(card, func() -> void: _show_detail(bounty, is_kill))
	return card


## 就地刷新：只改进度文本 / 颜色与交付按钮态，不碰节点树
func _refresh_card_state(card: PanelContainer, bounty: Dictionary) -> void:
	var progress_value: Variant = card.get_meta("bounty_progress_label", null)
	var submit_value: Variant = card.get_meta("bounty_submit", null)
	var progress_label := progress_value as Label
	var submit := submit_value as Button
	if progress_label == null or submit == null:
		return
	var can_submit := BountyManager.can_submit(bounty)
	progress_label.text = BountyManager.get_progress_text(bounty)
	progress_label.add_theme_color_override("font_color",
		ThemeBuilder.COLOR_TEXT_JADE if can_submit else ThemeBuilder.COLOR_TEXT_PRIMARY)
	var submit_text := "交付领奖"
	if BountyManager.daily_limit_reached():
		submit_text = "今日已满额"
	elif not can_submit:
		submit_text = "进度不足"
	if submit.text != submit_text:
		submit.text = submit_text
	submit.disabled = not can_submit
	if can_submit:
		ThemeBuilder.apply_primary_button(submit)
	else:
		ThemeBuilder.apply_secondary_button(submit)


## 委托书浮层：完整委托说明、精确进度、完整奖励，并给出目标来源跳转
func _show_detail(bounty: Dictionary, is_kill: bool) -> void:
	if AudioManager != null:
		AudioManager.play_tap()
	var target := String(bounty.get("target_id", ""))
	var skill_id := String(bounty.get("skill", "herbalism"))
	var xp := GameState.get_skill_gain(skill_id, float(bounty.get("xp", 0.0)))
	var rows: Array = []
	rows.append({
		"text": "委托",
		"desc": "仙盟张贴的%s：凑齐目标即可交付，领取灵石、仙盟贡献与百艺经验。"
			% ("妖兽清剿令" if is_kill else "物资征集令"),
	})
	rows.append({"text": "进度", "desc": BountyManager.get_progress_text(bounty)})
	rows.append({
		"text": "奖励",
		"desc": "灵石 %s · 贡献 %d · %s经验 +%s" % [
			GameFormulas.format_num(float(bounty.get("stones", 0))),
			int(bounty.get("points", 0)),
			GameState.get_skill_display_name(skill_id),
			GameFormulas.format_num(float(xp))],
	})
	var source: Dictionary = {}
	if is_kill:
		var enemy := DataRegistry.get_enemy(target)
		source = {
			"type": "combat",
			"enemy_id": target,
			"zone_id": "" if enemy == null else enemy.region_id,
		}
	else:
		var sources := DataRegistry.get_item_sources(target)
		if not sources.is_empty():
			source = sources[0]
	if not source.is_empty():
		rows.append({
			"text": "前往获取",
			"desc": "轻触直接跳到目标来源。",
			"callback": Callable(self, "_go_source").bind(source),
		})
	BottomSheet.show_text("悬赏委托书", rows)


func _go_source(source: Dictionary) -> void:
	EventBus.navigate_to_source.emit(source)


func _on_submit_pressed(index: int, anchor: Control) -> void:
	if not BountyManager.submit(index):
		return
	if anchor != null:
		UiMotion.pulse(anchor, 1.12, 0.22)
		if InkVfxLayer.instance != null:
			InkVfxLayer.instance.play_gold_flow(
				anchor.get_global_rect().get_center(), InkVfxLayer.INK_GOLD)
	if _points_label != null:
		UiMotion.pulse(_points_label, 1.12, 0.22)


## 免费刷新冷却文案：mm:ss，长时间也保持两位分钟，避免按钮宽度跳动
func _cooldown_text(seconds: float) -> String:
	var total := maxi(0, int(ceil(seconds)))
	return "%02d:%02d" % [total / 60, total % 60]


func _show_help() -> void:
	BottomSheet.show_help("仙盟悬赏 · 规则", [
		{"text": "悬赏令", "desc": "常驻 3 个悬赏：采集物资、制造物资与妖兽清剿各占其一，交付后领取灵石、仙盟贡献与技能经验。"},
		{"text": "今日赏格", "desc": "每个自然日最多交付 10 单；跨天后自动归零，累计完成数不受影响。"},
		{"text": "仙盟急令", "desc": "制造类委托有几率成为急令，灵石奖励 ×1.4、贡献 +30，并以鎏金徽章标出。"},
		{"text": "免费刷新", "desc": "每 30 分钟可免费刷新全部悬赏；也可消耗灵石刷新。"},
		{"text": "仙盟贡献", "desc": "完成悬赏积累贡献，可在藏经阁兑换功法与参悟升级。"},
	])

