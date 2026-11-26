class_name CombatStage
extends Control
## 秘境对决微型舞台：水墨远山 + 双方立绘 + 血条 + 冲刺/受击/飘字/雷电演出。

const STAGE_HEIGHT: float = 160.0
const PLAYER_SIZE: int = 64
const ENEMY_SIZE: int = 68
## 战斗演出贴图（assets/fx 下三张预制水墨 SVG，由 Godot 自动导入；禁止手改 .import）
const FX_FLYING_SWORD: String = "res://assets/fx/fx_flying_sword.svg"
const FX_PALM_WAVE: String = "res://assets/fx/fx_palm_wave.svg"
const FX_BEAST_CLAW: String = "res://assets/fx/fx_beast_claw.svg"
const FX_PROJECTILE_SEC: float = 0.26
## 舞台内飘字池：随舞台一起被 clip_contents 裁剪，不占用全局特效层
const FLOAT_POOL_SIZE: int = 12

var _player_icon: IconFrame
var _enemy_icon: IconFrame
## 统一残影血条容器（内含 Main / Ghost 两条 ProgressBar，外层 clip_contents）
var _player_bar: Control
var _enemy_bar: Control
## 双方蓄势细条（4px，紧贴血条下方）：我方黛玉青 / 敌方朱砂红
var _player_charge: ProgressBar
var _enemy_charge: ProgressBar
var _player_name: Label
var _enemy_name: Label
var _player_hp_text: Label
var _enemy_hp_text: Label

var _player_home: Vector2 = Vector2(22, 26)
var _enemy_home: Vector2 = Vector2(420, 22)
## 每个图标独立的位移 / 闪红 Tween：新动作前先 kill 归位，防止高频攻速下逐渐漂移
var _player_move: Tween
var _enemy_move: Tween
var _player_flash: Tween
var _enemy_flash: Tween
var _float_pool: Array[Label] = []
## 镇魔塔未开战时的预览妖魔（由 TowerPanel 注入，离开塔层时清除）
var _preview_enemy: EnemyData = null
## 战斗模式过滤（严格隔离秘境与镇魔塔状态串扰）：
## ""=全收；"tower"=仅镇魔塔战斗生效；"realm"=仅秘境战斗生效
var mode_filter: String = ""
## 招式轮换记忆：-1 表示尚未出手；只在同一分支内避免「连续两次同一招」
var _last_weapon_move: int = -1
var _last_unarmed_move: int = -1
var _last_enemy_move: int = -1


func _mode_ok() -> bool:
	if mode_filter == "":
		return true
	var tower := CombatEngine.is_active() and CombatEngine.tower_floor > 0
	return (mode_filter == "tower") == tower


func _ready() -> void:
	custom_minimum_size = Vector2(0, STAGE_HEIGHT)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	resized.connect(_layout)
	EventBus.combat_started.connect(_on_combat_started)
	EventBus.combat_stopped.connect(_on_combat_stopped)
	EventBus.combat_enemy_changed.connect(_on_enemy_changed)
	EventBus.combat_updated.connect(_on_state_updated)
	EventBus.combat_player_attack.connect(_on_player_attack)
	EventBus.combat_enemy_attack.connect(_on_enemy_attack)
	EventBus.combat_dodge.connect(_on_attack_dodged)
	EventBus.combat_heal.connect(_on_heal)
	EventBus.combat_thunder_talisman.connect(_on_thunder_talisman)
	EventBus.combat_enemy_defeated.connect(_on_enemy_defeated)
	EventBus.equipment_changed.connect(_refresh_player_icon)
	visibility_changed.connect(_on_visibility_changed)
	_layout()
	_refresh_player_icon()
	_refresh_enemy(CombatEngine.get_current_enemy())
	refresh_idle()
	EventBus.stats_changed.connect(_on_stats_changed)


func _build() -> void:
	_player_icon = IconFrame.new()
	_player_icon.setup(IconLibrary.get_skill_icon("cultivation"), PLAYER_SIZE, ThemeBuilder.COLOR_JADE)
	add_child(_player_icon)
	_player_icon.size = Vector2(PLAYER_SIZE, PLAYER_SIZE)

	_enemy_icon = IconFrame.new()
	_enemy_icon.setup(IconLibrary.get_enemy_icon("enemy_wild_wolf"), ENEMY_SIZE, ThemeBuilder.COLOR_CINNABAR)
	add_child(_enemy_icon)
	_enemy_icon.size = Vector2(ENEMY_SIZE, ENEMY_SIZE)

	_player_bar = ThemeBuilder.create_afterimage_bar(ThemeBuilder.COLOR_JADE)
	add_child(_player_bar)

	_enemy_bar = ThemeBuilder.create_afterimage_bar(ThemeBuilder.COLOR_CINNABAR)
	add_child(_enemy_bar)

	_player_name = ThemeBuilder.label("修士", ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_TITLE)
	# 立绘名固定显示当前境界（炼气一层 …）：加粗无衬线，小字号下不糊
	ThemeBuilder.apply_realm_font(_player_name)
	_player_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_player_name.clip_text = true
	_player_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_player_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_player_name)

	_player_hp_text = ThemeBuilder.label("", ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_SECONDARY)
	_player_hp_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_player_hp_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_player_hp_text)

	_enemy_name = ThemeBuilder.label("妖狼", ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_TITLE)
	_enemy_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_enemy_name.clip_text = true
	_enemy_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_enemy_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_enemy_name)

	_enemy_hp_text = ThemeBuilder.label("", ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_SECONDARY)
	_enemy_hp_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_enemy_hp_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_enemy_hp_text)

	# 蓄势条并入舞台（原详情卡双条上移，释放首屏空间）
	_player_charge = ThemeBuilder.progress_bar(ThemeBuilder.COLOR_JADE, 4.0)
	_player_charge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_player_charge)
	_enemy_charge = ThemeBuilder.progress_bar(ThemeBuilder.COLOR_CINNABAR, 4.0)
	_enemy_charge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_enemy_charge)

	for i in range(FLOAT_POOL_SIZE):
		var node := ThemeBuilder.label("", ThemeBuilder.FONT_BODY,
			ThemeBuilder.COLOR_TEXT_PRIMARY)
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.z_index = 5
		node.visible = false
		node.set_meta("float_active", false)
		add_child(node)
		_float_pool.append(node)


## 对战舞台刷新蓄势占比（CombatPanel._process 驱动）
func set_charge(player_ratio: float, enemy_ratio: float) -> void:
	if _player_charge != null:
		_player_charge.value = clampf(player_ratio, 0.0, 1.0)
		_enemy_charge.value = clampf(enemy_ratio, 0.0, 1.0)


## 大数紧凑格式：≥ 10000 显示「15.0万」，合体/大乘期百万血量也不挤爆血条行
func _format_hp(value: float) -> String:
	if value >= 10000.0:
		return "%.1f万" % (value / 10000.0)
	return "%d" % int(roundf(value))


func _layout() -> void:
	var width := maxf(size.x, 320.0)
	_player_home = Vector2(20.0, 16.0)
	_enemy_home = Vector2(width - 20.0 - float(ENEMY_SIZE), 12.0)
	# 重排时先终止在播动画并归位，避免 Tween 继续追着旧坐标跑
	_stop_icon_motion(_player_icon)
	_stop_icon_motion(_enemy_icon)
	_player_icon.position = _player_home
	_player_icon.size = Vector2(PLAYER_SIZE, PLAYER_SIZE)
	_enemy_icon.position = _enemy_home
	_enemy_icon.size = Vector2(ENEMY_SIZE, ENEMY_SIZE)

	# 名字独占血条上方一行、血量数值独立在血条下方一行：
	# 六位数血量（150000 / 150000）不再与「九幽鬼帝」挤在同一行叠字。
	# 图标与名称 6px、名称与血条 4px、蓄势条紧贴血条下方 2px。
	var bar_width := width * 0.34
	var name_y := 86.0
	var bar_y := 106.0
	var charge_y := 118.0
	var hp_y := 124.0
	_player_bar.position = Vector2(20.0, bar_y)
	_player_bar.size = Vector2(bar_width, 10)
	_enemy_bar.position = Vector2(width - 20.0 - bar_width, bar_y)
	_enemy_bar.size = Vector2(bar_width, 10)
	_player_charge.position = Vector2(20.0, charge_y)
	_player_charge.size = Vector2(bar_width, 4)
	_enemy_charge.position = Vector2(width - 20.0 - bar_width, charge_y)
	_enemy_charge.size = Vector2(bar_width, 4)

	_player_name.position = Vector2(20.0, name_y)
	_player_name.size = Vector2(bar_width, 16)
	_player_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_player_hp_text.position = Vector2(20.0, hp_y)
	_player_hp_text.size = Vector2(bar_width, 14)
	_player_hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	var enemy_x := width - 20.0 - bar_width
	_enemy_name.position = Vector2(enemy_x, name_y)
	_enemy_name.size = Vector2(bar_width, 16)
	_enemy_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_enemy_hp_text.position = Vector2(enemy_x, hp_y)
	_enemy_hp_text.size = Vector2(bar_width, 14)
	_enemy_hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	queue_redraw()


func _draw() -> void:
	var width := maxf(size.x, 320.0)
	# 宣纸底：半透明，让底层水墨孤峰透出
	draw_rect(Rect2(Vector2.ZERO, Vector2(width, size.y)),
		Color(Color("#EFE9DC"), 0.25))
	# 水墨远山：由淡到浓两层剪影
	var back: PackedVector2Array = PackedVector2Array([
		Vector2(0, 74), Vector2(width * 0.14, 48), Vector2(width * 0.26, 66),
		Vector2(width * 0.40, 40), Vector2(width * 0.56, 68), Vector2(width * 0.72, 46),
		Vector2(width * 0.86, 66), Vector2(width, 52), Vector2(width, 160), Vector2(0, 160),
	])
	draw_colored_polygon(back, Color(Color("#E5DDCE"), 0.35))
	var front: PackedVector2Array = PackedVector2Array([
		Vector2(0, 104), Vector2(width * 0.18, 82), Vector2(width * 0.34, 100),
		Vector2(width * 0.52, 78), Vector2(width * 0.70, 102), Vector2(width * 0.88, 84),
		Vector2(width, 100), Vector2(width, 160), Vector2(0, 160),
	])
	draw_colored_polygon(front, Color(Color("#D3C9B7"), 0.30))
	# 中央「交锋」锚点：浅褐圆环 + 交叉双剑暗纹，低对比度融入远山，消除左右空洞
	var center := Vector2(width * 0.5, 52.0)
	var ink := Color(Color("#A99B84"), 0.20)
	draw_arc(center, 24.0, 0.0, TAU, 40, ink, 1.5)
	draw_line(center + Vector2(-9.0, 9.0), center + Vector2(9.0, -9.0), ink, 2.0)
	draw_line(center + Vector2(-9.0, -9.0), center + Vector2(9.0, 9.0), ink, 2.0)
	# 脚底淡墨投影
	draw_set_transform(_player_home + Vector2(PLAYER_SIZE * 0.5, PLAYER_SIZE - 2.0), 0.0,
		Vector2(1.0, 0.30))
	draw_circle(Vector2.ZERO, 30.0, Color(ThemeBuilder.COLOR_JADE, 0.12))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_set_transform(_enemy_home + Vector2(ENEMY_SIZE * 0.5, ENEMY_SIZE - 2.0), 0.0,
		Vector2(1.0, 0.30))
	draw_circle(Vector2.ZERO, 32.0, Color(ThemeBuilder.COLOR_CINNABAR, 0.12))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ---------------------------------------------------------------- 演出

func _on_combat_started(enemy_id: String) -> void:
	# 模式过滤：非本模式战斗的信号一律不进舞台（防秘境/镇魔塔串扰）
	if not _mode_ok():
		return
	_preview_enemy = null
	_refresh_player_icon()
	_refresh_enemy(_resolve_enemy(enemy_id))
	# 重新开战：双方血条瞬时对齐，禁止上一局残影残留
	var p_max := maxf(1.0, float(GameState.get_max_hp()))
	UiMotion.set_afterimage_value(_player_bar,
		clampf(float(GameState.current_hp) / p_max, 0.0, 1.0), true)
	UiMotion.breathe_alpha(_player_bar, false)
	UiMotion.set_afterimage_value(_enemy_bar, 1.0, true)
	modulate = Color(1, 1, 1)


func _on_combat_stopped(_reason: String) -> void:
	_stop_icon_motion(_player_icon)
	_stop_icon_motion(_enemy_icon)
	_clear_temp_fx()
	refresh_idle()


func _on_stats_changed() -> void:
	if not CombatEngine.is_active():
		refresh_idle()


## 页面切换：可见且未开战时刷新静候态；隐藏时终止在播 Tween，避免后台空转
func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		if not CombatEngine.is_active():
			refresh_idle()
		return
	_stop_icon_motion(_player_icon)
	_stop_icon_motion(_enemy_icon)
	_clear_temp_fx()


## 静候 / 未开打：玩家按真实气血、敌按当前选中怪物满血显示数值
func refresh_idle() -> void:
	if _player_bar == null:
		return
	var max_hp := maxi(1, GameState.get_max_hp())
	var hp := clampi(GameState.current_hp, 0, max_hp)
	var ratio := float(hp) / float(max_hp)
	UiMotion.set_afterimage_value(_player_bar, ratio, true)
	UiMotion.breathe_alpha(_player_bar, false)
	_player_hp_text.text = "%s / %s" % [_format_hp(hp), _format_hp(max_hp)]
	var target := CombatEngine.get_current_enemy()
	if target == null:
		# 静候时优先显示外部预览（镇魔塔选层），否则回落到「当前选中怪物」
		target = _preview_enemy
		if target == null:
			target = DataRegistry.get_enemy(GameState.selected_enemy_id)
		if target != null:
			_refresh_enemy(target)
	if target == null:
		return
	var enemy_hp := target.max_hp
	if CombatEngine.is_active() and CombatEngine.enemy_hp > 0:
		enemy_hp = CombatEngine.enemy_hp
	UiMotion.set_afterimage_value(_enemy_bar,
		float(enemy_hp) / float(maxi(1, target.max_hp)), true)
	_enemy_hp_text.text = "%s / %s" % [_format_hp(enemy_hp), _format_hp(target.max_hp)]


func _on_enemy_changed(enemy_id: String, first_spawn: bool) -> void:
	# 模式过滤：非本模式战斗的信号一律不进舞台（防秘境/镇魔塔串扰）
	if not _mode_ok():
		return
	var target := _resolve_enemy(enemy_id)
	_refresh_enemy(target)
	# 切怪/新刷：主条与残影瞬时对齐新目标，绝不拖上一只怪的残影
	if target != null:
		var enemy_max := maxi(1, target.max_hp)
		var enemy_hp := enemy_max
		if CombatEngine.is_active() and CombatEngine.enemy_hp > 0:
			enemy_hp = CombatEngine.enemy_hp
		UiMotion.set_afterimage_value(_enemy_bar,
			float(enemy_hp) / float(enemy_max), true)
	if not first_spawn:
		_stop_icon_motion(_enemy_icon)
		_enemy_icon.modulate.a = 1.0
		_enemy_icon.position = _enemy_home


func _on_state_updated(payload: Dictionary) -> void:
	# 模式过滤：非本模式战斗的信号一律不进舞台（防秘境/镇魔塔串扰）
	if not _mode_ok():
		return
	var player_max := maxf(1.0, float(payload.get("max_hp", 1)))
	var enemy_max := maxf(1.0, float(payload.get("enemy_max", 1)))
	var player_ratio := clampf(float(payload.get("hp", 0)) / player_max, 0.0, 1.0)
	var enemy_ratio := clampf(float(payload.get("enemy_hp", 0)) / enemy_max, 0.0, 1.0)
	UiMotion.set_afterimage_value(_player_bar, player_ratio)
	UiMotion.set_afterimage_value(_enemy_bar, enemy_ratio)
	UiMotion.breathe_alpha(_player_bar, player_ratio > 0.0 and player_ratio < 0.30)
	_player_hp_text.text = "%s / %s" % [_format_hp(float(payload.get("hp", 0))), _format_hp(player_max)]
	_enemy_hp_text.text = "%s / %s" % [_format_hp(float(payload.get("enemy_hp", 0))), _format_hp(enemy_max)]


func _on_player_attack(damage: int, crit: bool) -> void:
	# 模式过滤：非本模式战斗的信号一律不进舞台（防秘境/镇魔塔串扰）
	if not _mode_ok():
		return
	if not is_visible_in_tree():
		return
	UiMotion.flash_once(_player_charge)
	if _fx_enabled():
		# 按法器装备状态分流：持械四招（御剑/瞬步/剑气/落剑），空手三招（冲撞/掌印/重拳）
		if _weapon_equipped():
			_play_weapon_move(crit)
		else:
			_play_unarmed_move(crit)
	var color := ThemeBuilder.COLOR_AMBER if crit else ThemeBuilder.COLOR_CINNABAR
	var text_value := ("会心 -%d" % damage) if crit else ("-%d" % damage)
	_play_float(_enemy_icon, text_value, color, 17 if crit else 14, crit)


func _on_enemy_attack(damage: int, ward_ratio: float) -> void:
	# 模式过滤：非本模式战斗的信号一律不进舞台（防秘境/镇魔塔串扰）
	if not _mode_ok():
		return
	if not is_visible_in_tree():
		return
	UiMotion.flash_once(_enemy_charge)
	if _fx_enabled():
		_play_enemy_move()
	_play_float(_player_icon, "-%d" % damage, ThemeBuilder.COLOR_CINNABAR, 14, false)
	if ward_ratio > 0.0:
		_play_float(_player_icon, "盾 -%d%%" % int(round(ward_ratio * 100.0)),
			ThemeBuilder.COLOR_TEXT_GOLD, ThemeBuilder.FONT_CAPTION, false,
			Vector2(26.0, -16.0))


## 攻击被闪避：受击方朝己方后方轻巧侧移
func _on_attack_dodged(dodger: String) -> void:
	# 模式过滤：非本模式战斗的信号一律不进舞台（防秘境/镇魔塔串扰）
	if not _mode_ok():
		return
	if not _fx_enabled():
		return
	if dodger == "player":
		_play_dodge(_player_icon)
	else:
		_play_dodge(_enemy_icon)


func _on_heal(amount: int, _item_name: String) -> void:
	# 模式过滤：非本模式战斗的信号一律不进舞台（防秘境/镇魔塔串扰）
	if not _mode_ok():
		return
	if not CombatEngine.is_active() or not is_visible_in_tree():
		return
	_play_float(_player_icon, "+%d" % amount, ThemeBuilder.COLOR_EMERALD, 14, false,
		Vector2(-6.0, -6.0))


func _on_thunder_talisman(damage: int) -> void:
	# 模式过滤：非本模式战斗的信号一律不进舞台（防秘境/镇魔塔串扰）
	if not _mode_ok():
		return
	if not is_visible_in_tree():
		return
	var ink := InkVfxLayer.instance
	var enemy_center := _enemy_icon.get_global_rect().get_center()
	if ink != null:
		ink.play_thunder(enemy_center + Vector2(-46, -70), enemy_center,
			InkVfxLayer.INK_GOLD)
		ink.play_splash(enemy_center, InkVfxLayer.INK_GOLD)
		_play_float(_enemy_icon, "雷 -%d" % damage, ThemeBuilder.COLOR_TEXT_GOLD, 18, true)


func _on_enemy_defeated(_enemy_id: String, _loot: Dictionary) -> void:
	# 模式过滤：非本模式战斗的信号一律不进舞台（防秘境/镇魔塔串扰）
	if not _mode_ok():
		return
	if not is_visible_in_tree():
		return
	if InkVfxLayer.instance != null:
		InkVfxLayer.instance.play_dissolve(_enemy_icon.get_global_rect().get_center(),
			InkVfxLayer.INK_JADE_LIGHT)


func _refresh_player_icon() -> void:
	var realm := GameState.get_realm()
	# 立绘跟随武器，名称固定显示当前境界（如「炼气一层」）
	_player_name.text = realm.display_name if realm != null else "修士"
	var entry := GameState.get_equipped("weapon")
	var item_id := String(entry.get("id", ""))
	var quality := clampi(int(entry.get("quality", 0)), 0, 2)
	if item_id == "":
		_player_icon.set_icon(IconLibrary.get_skill_icon("cultivation"), ThemeBuilder.COLOR_JADE)
		return
	var accent := ThemeBuilder.COLOR_JADE
	if quality == 2:
		accent = ThemeBuilder.COLOR_AMBER
	_player_icon.set_icon(IconLibrary.get_item_icon(item_id, quality), accent)


## 镇魔塔妖魔是运行时生成的（不在 DataRegistry 注册表），需回落到当前战斗实例
func _resolve_enemy(enemy_id: String) -> EnemyData:
	var target := DataRegistry.get_enemy(enemy_id)
	if target != null:
		return target
	var current := CombatEngine.get_current_enemy()
	if current != null and current.id == enemy_id:
		return current
	return null


func _refresh_enemy(target: EnemyData) -> void:
	if target == null:
		_enemy_name.text = "静候"
		return
	var accent := ThemeBuilder.COLOR_CINNABAR if not target.is_boss else ThemeBuilder.COLOR_AMBER
	# 动态塔层妖魔按 icon_id 轮换全秘境妖兽造型（确定性哈希，见 DataRegistry）
	_enemy_icon.set_icon(IconLibrary.get_enemy_icon(target.get_icon_key()), accent)
	_enemy_name.text = target.display_name
	# 名牌用品阶字色（含镇魔塔 tower_<floor> 动态妖魔），头目由旁侧 chip 标识
	ThemeBuilder.apply_enemy_grade_style(_enemy_name, target.id)
	UiMotion.set_afterimage_value(_enemy_bar, 1.0, true)


## 镇魔塔未开战预览：把右侧立绘 / 名称 / 气血切到当前选中层数的妖魔
func show_preview_enemy(target: EnemyData) -> void:
	if target == null or _enemy_icon == null:
		return
	_preview_enemy = target
	_refresh_enemy(target)
	var max_hp := maxi(1, target.max_hp)
	UiMotion.set_afterimage_value(_enemy_bar, 1.0, true)
	_enemy_hp_text.text = "%s / %s" % [_format_hp(max_hp), _format_hp(max_hp)]


func clear_preview() -> void:
	_preview_enemy = null


# ---------------------------------------------------------------- 出手 / 受击动效

## 动效开关：不可见或关闭水墨特效时全部跳过
func _fx_enabled() -> bool:
	return is_visible_in_tree() and GameState.is_flag("ink_fx", true)


func _icon_home(icon: Control) -> Vector2:
	return _enemy_home if icon == _enemy_icon else _player_home


func _store_move(icon: Control, tween: Tween) -> void:
	if icon == _enemy_icon:
		_enemy_move = tween
	else:
		_player_move = tween


func _store_flash(icon: Control, tween: Tween) -> void:
	if icon == _enemy_icon:
		_enemy_flash = tween
	else:
		_player_flash = tween


## 终止该图标未结束的位移/闪红并归位：高频攻速下也不会逐次偏移
func _stop_icon_motion(icon: Control) -> void:
	if icon == null:
		return
	var move: Tween = _enemy_move if icon == _enemy_icon else _player_move
	if move != null and move.is_valid():
		move.kill()
	var flash: Tween = _enemy_flash if icon == _enemy_icon else _player_flash
	if flash != null and flash.is_valid():
		flash.kill()
	if icon == _enemy_icon:
		_enemy_move = null
		_enemy_flash = null
	else:
		_player_move = null
		_player_flash = null
	icon.position = _icon_home(icon)
	icon.scale = Vector2.ONE
	icon.modulate = Color(1, 1, 1, 1)


## 攻击前冲：我方向右、敌方向左；会心更远并叠加放大回弹
func _play_lunge(icon: Control, crit: bool) -> void:
	if icon == null:
		return
	var home := _icon_home(icon)
	_stop_icon_motion(icon)
	var direction := 1.0 if icon == _player_icon else -1.0
	var distance := 26.0 if crit else 20.0
	var tween := create_tween()
	tween.tween_property(icon, "position", home + Vector2(distance * direction, 0.0), 0.07) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if crit:
		tween.parallel().tween_property(icon, "scale", Vector2(1.12, 1.12), 0.07) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(icon, "position", home, 0.11) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	if crit:
		tween.parallel().tween_property(icon, "scale", Vector2.ONE, 0.11) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_store_move(icon, tween)


## 受击：横向快速往返震动 + 短暂偏红高亮；
## 会心追加 ±4px 多向微震（0.14s），比普攻更「顿」但不放大位移干扰视线
func _play_hit_shake(icon: Control, crit: bool = false) -> void:
	if icon == null:
		return
	var home := _icon_home(icon)
	_stop_icon_motion(icon)
	var tween := create_tween()
	if crit:
		var jolts: Array[Vector2] = [
			Vector2(4.0, -4.0), Vector2(-4.0, 3.0), Vector2(3.0, -2.0),
			Vector2(-2.0, 1.0), Vector2.ZERO,
		]
		var steps: Array[float] = [0.03, 0.03, 0.03, 0.03, 0.02]
		for i in range(jolts.size()):
			tween.tween_property(icon, "position", home + jolts[i], steps[i])
	else:
		var offsets: Array[float] = [6.0, -6.0, 4.0, -3.0, 0.0]
		var durations: Array[float] = [0.035, 0.035, 0.035, 0.035, 0.04]
		for i in range(offsets.size()):
			tween.tween_property(icon, "position", home + Vector2(offsets[i], 0.0),
				durations[i])
	_store_move(icon, tween)
	var flash := create_tween()
	flash.tween_property(icon, "modulate", Color(1.0, 0.52, 0.48, 1.0), 0.05)
	flash.tween_property(icon, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.07)
	_store_flash(icon, flash)


## 闪避：受击方朝己方后方侧移约 10px 再回位
func _play_dodge(icon: Control) -> void:
	if icon == null:
		return
	var home := _icon_home(icon)
	_stop_icon_motion(icon)
	var backward := -1.0 if icon == _player_icon else 1.0
	var tween := create_tween()
	tween.tween_property(icon, "position", home + Vector2(10.0 * backward, -2.0), 0.07) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(icon, "position", home, 0.08) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_store_move(icon, tween)


# ---------------------------------------------------------------- 多招式战斗演出

## 已装备法器（兵刃槽有物品）走御剑四招，否则走体修三招
func _weapon_equipped() -> bool:
	var entry := GameState.get_equipped("weapon")
	return String(entry.get("id", "")) != ""


## 同分支内轮换不重复：连续两次绝不选同一招
func _pick_move(count: int, last: int) -> int:
	if count <= 1:
		return 0
	var pick := randi() % count
	if pick == last:
		pick = (last + 1 + randi() % maxi(1, count - 1)) % count
	return pick


## 固定锚点：所有冲锋位移均以 base_pos 为基准，绝不从当前帧位置累加
func _player_anchor() -> Vector2:
	return _player_home + Vector2(PLAYER_SIZE * 0.5, PLAYER_SIZE * 0.5)


func _enemy_anchor() -> Vector2:
	return _enemy_home + Vector2(ENEMY_SIZE * 0.5, ENEMY_SIZE * 0.5)


func _play_weapon_move(crit: bool) -> void:
	var move := _pick_move(4, _last_weapon_move)
	_last_weapon_move = move
	match move:
		0:
			_move_flying_sword(crit)
		1:
			_move_close_slash(crit)
		2:
			_move_sword_qi(crit)
		_:
			_move_heaven_sword(crit)


func _play_unarmed_move(crit: bool) -> void:
	var move := _pick_move(3, _last_unarmed_move)
	_last_unarmed_move = move
	match move:
		0:
			_move_wind_charge(crit)
		1:
			_move_palm_wave(crit)
		_:
			_move_heavy_punch(crit)


## 招式 A · 御剑飞斩：会心三剑扇形齐射
func _move_flying_sword(crit: bool) -> void:
	_play_lunge(_player_icon, crit)
	_play_hit_shake(_enemy_icon, crit)
	var from := _player_anchor() + Vector2(28.0, 0.0)
	var target := _enemy_anchor()
	var base_angle := (target - from).angle()
	if crit:
		var fan: Array[Vector2] = [Vector2(-12, -22), Vector2(0, 0), Vector2(12, 22)]
		for i in range(fan.size()):
			_spawn_projectile(FX_FLYING_SWORD, from + fan[i] * 0.45, target + fan[i],
				base_angle + float(i - 1) * 0.16, 42.0, 1.0, float(i) * 0.03)
	else:
		_spawn_projectile(FX_FLYING_SWORD, from, target, base_angle, 44.0, 1.0, 0.0)
	_later(FX_PROJECTILE_SEC, func() -> void:
		_splash_at_enemy(InkVfxLayer.INK_GOLD if crit else InkVfxLayer.INK_JADE)
	)


## 招式 B · 瞬步贴身斩：蓄力 → 贴脸 → 鎏金弯月；会心再叠十字双斩
func _move_close_slash(crit: bool) -> void:
	_play_hit_shake(_enemy_icon, crit)
	_play_dash(_player_icon, _dash_gap())
	_later(0.14, func() -> void:
		var ink := InkVfxLayer.instance
		if ink == null:
			return
		var center := _enemy_icon.get_global_rect().get_center()
		ink.play_slash(center + Vector2(-42, -20), center + Vector2(30, 18),
			InkVfxLayer.INK_GOLD)
		if crit:
			ink.play_slash(center + Vector2(-30, 24), center + Vector2(32, -22),
				InkVfxLayer.INK_GOLD)
			ink.play_crit_mark(center)
		ink.play_splash(center, InkVfxLayer.INK_GOLD)
	)


## 招式 C · 剑气纵横：上挑 / 下劈 / 双轨交错三选一；会心三道剑气齐发
func _move_sword_qi(crit: bool) -> void:
	_play_lunge(_player_icon, crit)
	_play_hit_shake(_enemy_icon, crit)
	_later(0.08, func() -> void:
		var ink := InkVfxLayer.instance
		if ink == null:
			return
		var start := _player_icon.get_global_rect().get_center()
		var end := _enemy_icon.get_global_rect().get_center()
		if crit:
			ink.play_crit_slash(start, end)
			ink.play_splash(end, InkVfxLayer.INK_GOLD)
			return
		match randi() % 3:
			0:
				ink.play_slash(start + Vector2(18, 12), end + Vector2(0, -14),
					InkVfxLayer.INK_JADE)
			1:
				ink.play_slash(start + Vector2(18, -14), end + Vector2(0, 14),
					InkVfxLayer.INK_JADE)
			_:
				ink.play_slash(start + Vector2(16, -16), end + Vector2(0, 6),
					InkVfxLayer.INK_JADE)
				ink.play_slash(start + Vector2(16, 16), end + Vector2(0, -6),
					InkVfxLayer.INK_JADE_LIGHT)
		ink.play_splash(end, InkVfxLayer.INK_CINNABAR)
	)


## 招式 D · 九天落剑：垂直下劈贯体 + 底部横向水墨气浪
func _move_heaven_sword(crit: bool) -> void:
	_play_lunge(_player_icon, crit)
	_play_hit_shake(_enemy_icon, crit)
	var target := _enemy_anchor()
	_spawn_projectile(FX_FLYING_SWORD, target + Vector2(0, -108), target,
		PI * 0.5, 46.0, 1.3 if crit else 1.0, 0.0, Vector2(0, -6))
	_later(0.22, func() -> void:
		var ink := InkVfxLayer.instance
		if ink == null:
			return
		var center := _enemy_icon.get_global_rect().get_center()
		ink.play_harvest(center, InkVfxLayer.INK_GOLD, 130.0)
		ink.play_splash(center, InkVfxLayer.INK_GOLD)
	)


## 体修 A · 御风冲撞：撞入敌身迸发墨圈涟漪
func _move_wind_charge(crit: bool) -> void:
	_play_lunge(_player_icon, crit)
	_play_hit_shake(_enemy_icon, crit)
	_later(0.09, func() -> void:
		var ink := InkVfxLayer.instance
		if ink == null:
			return
		var center := _enemy_icon.get_global_rect().get_center()
		ink.play_ring(center, InkVfxLayer.INK_JADE_LIGHT, 96.0)
		ink.play_splash(center, InkVfxLayer.INK_JADE)
	)


## 体修 B · 开山掌印：推出掌风气劲，命中震散气浪
func _move_palm_wave(crit: bool) -> void:
	_play_lunge(_player_icon, false)
	_play_hit_shake(_enemy_icon, crit)
	var from := _player_anchor() + Vector2(26.0, 0.0)
	var target := _enemy_anchor()
	_spawn_projectile(FX_PALM_WAVE, from, target, (target - from).angle(),
		48.0, 1.35 if crit else 1.0, 0.0)
	_later(0.22, func() -> void:
		var ink := InkVfxLayer.instance
		if ink == null:
			return
		var center := _enemy_icon.get_global_rect().get_center()
		ink.play_splash(center, InkVfxLayer.INK_GOLD if crit else InkVfxLayer.INK_JADE_LIGHT)
		ink.play_ring(center, InkVfxLayer.INK_GOLD, 74.0)
	)


## 体修 C · 裂空重拳：突进重击，受击震颤更明显
func _move_heavy_punch(_crit: bool) -> void:
	_play_dash(_player_icon, _dash_gap() * 0.92)
	_play_hit_shake(_enemy_icon, true)
	_later(0.13, func() -> void:
		var ink := InkVfxLayer.instance
		if ink == null:
			return
		var center := _enemy_icon.get_global_rect().get_center()
		ink.play_splash(center, InkVfxLayer.INK_CINNABAR)
		ink.play_ring(center, InkVfxLayer.INK_JADE, 64.0)
	)


## 妖兽反击：扑击 / 妖爪裂空 二选一，不连续重复
func _play_enemy_move() -> void:
	var move := _pick_move(2, _last_enemy_move)
	_last_enemy_move = move
	_play_lunge(_enemy_icon, false)
	_play_hit_shake(_player_icon)
	var ink := InkVfxLayer.instance
	if ink == null:
		return
	var from := _enemy_icon.get_global_rect().get_center()
	var to := _player_icon.get_global_rect().get_center()
	ink.play_slash(from, to, InkVfxLayer.INK_CINNABAR)
	ink.play_splash(to, InkVfxLayer.INK_CINNABAR)
	if move == 1:
		_spawn_claw(_player_anchor())


## 贴图特效：TextureRect + Tween，动画结束即 queue_free，不做常驻节点
func _spawn_projectile(path: String, from_local: Vector2, to_local: Vector2,
		rotation_rad: float, size: float, scale_mul: float, delay: float,
		arc: Vector2 = Vector2(0, -12)) -> void:
	var texture := load(path) as Texture2D
	if texture == null or not is_inside_tree():
		return
	var node := TextureRect.new()
	node.texture = texture
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.custom_minimum_size = Vector2(size, size)
	node.size = Vector2(size, size)
	node.pivot_offset = Vector2(size, size) * 0.5
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.rotation = rotation_rad
	node.scale = Vector2(scale_mul, scale_mul)
	node.modulate = Color(1, 1, 1, 0.0)
	node.position = from_local - Vector2(size, size) * 0.5
	node.set_meta("fx_temp", true)
	add_child(node)
	var mid := (from_local + to_local) * 0.5 + arc
	var tween := create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_property(node, "modulate:a", 1.0, 0.07)
	tween.parallel().tween_method(
		_update_projectile.bind(node, from_local, mid, to_local, size),
		0.0, 1.0, FX_PROJECTILE_SEC).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(node, "modulate:a", 0.0, 0.10)
	tween.tween_callback(node.queue_free)


func _update_projectile(u: float, node: TextureRect, a: Vector2, c: Vector2,
		b: Vector2, size: float) -> void:
	if not is_instance_valid(node):
		return
	node.position = _quad_point(a, c, b, u) - Vector2(size, size) * 0.5


## 妖爪裂空：在玩家头像上刷出墨红爪痕，随即渐隐销毁
func _spawn_claw(local_center: Vector2) -> void:
	var texture := load(FX_BEAST_CLAW) as Texture2D
	if texture == null or not is_inside_tree():
		return
	var size := 76.0
	var node := TextureRect.new()
	node.texture = texture
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.custom_minimum_size = Vector2(size, size)
	node.size = Vector2(size, size)
	node.pivot_offset = Vector2(size, size) * 0.5
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.position = local_center - Vector2(size, size) * 0.5
	node.rotation = deg_to_rad(randf_range(-28.0, 28.0))
	node.scale = Vector2(0.78, 0.78)
	node.modulate = Color(1, 1, 1, 0.0)
	node.set_meta("fx_temp", true)
	add_child(node)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(node, "modulate:a", 1.0, 0.07)
	tween.tween_property(node, "scale", Vector2(1.06, 1.06), 0.34) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(node, "modulate:a", 0.0, 0.16)
	tween.chain().tween_callback(node.queue_free)


func _quad_point(a: Vector2, c: Vector2, b: Vector2, u: float) -> Vector2:
	var inv := 1.0 - u
	return a * (inv * inv) + c * (2.0 * inv * u) + b * (u * u)


func _dash_gap() -> float:
	return maxf(60.0, _enemy_home.x - (_player_home.x + float(PLAYER_SIZE)) - 4.0)


## 瞬步/重拳：后背蓄力 → 疾冲到敌方边缘 → 短暂顿挫 → 弹性归位
func _play_dash(icon: Control, distance: float) -> void:
	if icon == null:
		return
	var home := _icon_home(icon)
	_stop_icon_motion(icon)
	var direction := 1.0 if icon == _player_icon else -1.0
	var tween := create_tween()
	tween.tween_property(icon, "position", home + Vector2(-10.0 * direction, 0.0), 0.05) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(icon, "position", home + Vector2(distance * direction, 0.0), 0.08) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_interval(0.05)
	tween.tween_property(icon, "position", home, 0.15) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_store_move(icon, tween)


func _splash_at_enemy(color: Color) -> void:
	var ink := InkVfxLayer.instance
	if ink == null or _enemy_icon == null:
		return
	ink.play_splash(_enemy_icon.get_global_rect().get_center(), color)


## 延迟回调：节点已销毁时静默跳过，避免切页后回调打到失效节点
func _later(delay: float, action: Callable) -> void:
	if not is_inside_tree():
		return
	await get_tree().create_timer(delay).timeout
	if not is_inside_tree():
		return
	action.call()


## 停战 / 切页时回收残留的飞剑、掌印、爪痕节点
func _next_float_label() -> Label:
	for node in _float_pool:
		if not node.has_meta("float_active") or not bool(node.get_meta("float_active")):
			return node
	var oldest := _float_pool[0]
	_recycle_float(oldest)
	return oldest


func _recycle_float(node: Label) -> void:
	if node == null:
		return
	var old_tween: Variant = null
	if node.has_meta("float_tween"):
		old_tween = node.get_meta("float_tween")
	if old_tween is Tween and (old_tween as Tween).is_valid():
		(old_tween as Tween).kill()
	node.set_meta("float_tween", null)
	node.set_meta("float_active", false)
	node.visible = false
	node.modulate = Color(1, 1, 1, 1)
	node.scale = Vector2.ONE


## 舞台内轻量飘字：受击图标中心偏下起飘，水平 ±14px 微随机防连击重叠。
func _play_float(target_icon: Control, text_value: String, color: Color,
		font_size: int = 14, crit: bool = false,
		offset: Vector2 = Vector2.ZERO) -> void:
	if not is_visible_in_tree() or target_icon == null or text_value.is_empty():
		return
	var node := _next_float_label()
	node.text = text_value
	ThemeBuilder.apply_font_size(node, font_size)
	node.add_theme_color_override("font_color", color)
	node.add_theme_color_override("font_shadow_color", Color(0.99, 0.97, 0.93, 0.9))
	node.add_theme_constant_override("shadow_offset_x", 1)
	node.add_theme_constant_override("shadow_offset_y", 1)
	node.size = node.get_combined_minimum_size()
	var center_local: Vector2 = target_icon.get_global_rect().get_center() - global_position
	var start_x: float = center_local.x - node.size.x * 0.5 \
		+ randf_range(-14.0, 14.0) + offset.x
	var start_y: float = center_local.y + float(target_icon.size.y) * 0.18 \
		- node.size.y * 0.5 + offset.y
	# 会心弹性缩放会放大实际外接矩形，预留 20px 安全边距防止被舞台裁掉
	var safe_pad := 20.0 if crit else 6.0
	node.position = Vector2(
		clampf(start_x, 4.0 + safe_pad,
			maxf(4.0 + safe_pad, size.x - node.size.x - 4.0 - safe_pad)),
		clampf(start_y, 4.0 + safe_pad,
			maxf(4.0 + safe_pad, size.y - node.size.y - 8.0 - safe_pad)))
	node.scale = Vector2.ONE
	node.modulate = Color(1, 1, 1, 1)
	node.visible = true
	node.set_meta("float_active", true)

	var tween := create_tween()
	tween.set_parallel(true)
	var base_y := node.position.y
	if crit:
		tween.tween_method(func(t: float) -> void:
			node.scale = Vector2.ONE.lerp(Vector2(1.24, 1.24), sin(PI * t)),
			0.0, 1.0, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_method(func(t: float) -> void:
			node.position.y = base_y - 14.0 * sin(PI * t) - 8.0 * t,
			0.0, 1.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		tween.tween_method(func(t: float) -> void:
			node.position.y = base_y - 22.0 * t,
			0.0, 1.0, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "modulate:a", 0.0, 0.55).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(func() -> void: _recycle_float(node))
	node.set_meta("float_tween", tween)


func _clear_temp_fx() -> void:
	for node in _float_pool:
		_recycle_float(node)
	for child in get_children():
		if child.has_meta("fx_temp"):
			child.queue_free()


