class_name TribulationStage
extends Control
## 引动天劫舞台：逆向双环护身灵阵 + 中央打坐 + 紫金锯齿天雷 + 冲击波。

const STAGE_HEIGHT: float = 196.0
const CENTER_Y: float = 98.0
## 阵盘显示直径：SVG 为 200×200，栅格化后按 168 显示（外缘留边，竖屏不裁切）
const RING_SIZE: float = 168.0

var _icon: IconFrame
var _cloud_texture: GradientTexture2D
var _cloud_alpha: float = 0.6
var _ring_outer: ImageTexture
var _ring_inner: ImageTexture
## 外环逆时针、内环顺时针；引劫时平滑加速
var _outer_angle: float = 0.0
var _inner_angle: float = 0.0
var _ring_speed: float = 0.32
var _time: float = 0.0
var _active: bool = false
var _result: int = 0
var _shake_origin: Vector2 = Vector2.ZERO

## 兼容旧实现：面板会读取 _pips，这里不参与
var _pips: Array = []


func _ready() -> void:
	custom_minimum_size = Vector2(0, STAGE_HEIGHT)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	EventBus.tribulation_started.connect(_on_started)
	EventBus.tribulation_thunder.connect(_on_thunder)
	EventBus.tribulation_finished.connect(_on_finished)
	EventBus.game_loaded.connect(_on_reset)
	resized.connect(_layout)
	visibility_changed.connect(_on_visibility_changed)
	_layout()
	set_process(is_visible_in_tree())


func _build() -> void:
	# 柔和羽化的雷云背板（径向渐变，在 _draw 中先画，避免硬边与遮挡法阵）
	_cloud_texture = _make_cloud()
	# 八卦双线阵盘（外）+ 双鱼灵珠流光轨（内）：{C1} 浓墨主线条 / {C2} 鎏金点缀
	var primary := ThemeBuilder.hex(ThemeBuilder.COLOR_TEXT_PRIMARY)
	var accent := ThemeBuilder.hex(ThemeBuilder.COLOR_TEXT_GOLD)
	var px := int(RING_SIZE)
	_ring_outer = IconLibrary.get_ui_ring_texture("tribulation_ring_outer", primary, accent, px)
	_ring_inner = IconLibrary.get_ui_ring_texture("tribulation_ring_inner", primary, accent, px)

	_icon = IconFrame.new()
	_icon.setup(IconLibrary.get_skill_icon("cultivation"), 56, ThemeBuilder.COLOR_AMBER, true)
	add_child(_icon)
	_icon.size = Vector2(56, 56)


func _make_cloud() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.32, 0.28, 0.22, 0.16))
	gradient.add_point(0.45, Color(0.36, 0.31, 0.24, 0.09))
	gradient.set_color(gradient.get_point_count() - 1, Color(0.36, 0.31, 0.24, 0.0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.42)
	texture.fill_to = Vector2(1.0, 0.85)
	texture.width = 160
	texture.height = 120
	return texture


func _layout() -> void:
	_icon.position = Vector2(size.x * 0.5 - 28.0, CENTER_Y - 28.0)
	_shake_origin = _icon.position
	queue_redraw()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_time += delta
	# 静候 0.32 rad/s，引劫平滑加速到 1.8 rad/s；内环反向且稍快，形成对转
	_ring_speed = lerpf(_ring_speed, 1.8 if _active else 0.32, clampf(delta * 2.0, 0.0, 1.0))
	_outer_angle -= delta * _ring_speed
	_inner_angle += delta * _ring_speed * 1.35
	queue_redraw()


func _draw() -> void:
	var width := maxf(size.x, 320.0)
	var center := Vector2(width * 0.5, CENTER_Y)

	# 宣纸底：极浅半透明，劫云与水墨远山直接透出
	draw_rect(Rect2(Vector2.ZERO, Vector2(width, size.y)),
		Color(Color("#EFE9DC"), 0.25))

	# 柔和雷云背板（径向羽化）
	if _cloud_texture != null:
		draw_texture_rect(_cloud_texture,
			Rect2(center.x - 150.0, CENTER_Y - 172.0, 300.0, 210.0), false,
			Color(1, 1, 1, _cloud_alpha))

	# 中央灵光
	draw_circle(center, 34.0, Color(ThemeBuilder.COLOR_JADE, 0.10 if not _active else 0.16))

	# 双环阵盘：外环逆时针「八卦双线阵盘」，内环顺时针「双鱼灵珠流光轨」。
	# 纹理由 IconSvgPack 的 200×200 模板注入 {C1}/{C2} 后缓存，纯 2D draw，无新增节点。
	var ring_alpha := 1.0
	if _result == 2:
		ring_alpha = 0.92
	elif _result == 1:
		ring_alpha = 0.42
	var ring_rect := Rect2(-RING_SIZE * 0.5, -RING_SIZE * 0.5, RING_SIZE, RING_SIZE)
	if _ring_outer != null:
		draw_set_transform(center, _outer_angle, Vector2.ONE)
		draw_texture_rect(_ring_outer, ring_rect, false, Color(1, 1, 1, ring_alpha))
	if _ring_inner != null:
		draw_set_transform(center, _inner_angle, Vector2.ONE)
		draw_texture_rect(_ring_inner, ring_rect, false, Color(1, 1, 1, ring_alpha))
	# 必须复位变换矩阵，否则后续绘制（飘字/调试描边）会跟着环一起转
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# 冲击波由 InkVfxLayer 接管，舞台只保留法阵与劫云


# ---------------------------------------------------------------- 演出

func _on_started() -> void:
	_active = true
	_result = 0
	_cloud_alpha = 1.0
	if is_visible_in_tree():
		_icon.set_pulsing(true)


func _on_thunder(_index: int, damage: int, warded: bool, _hp: int, _max_hp: int) -> void:
	if not is_visible_in_tree():
		return
	# 每道天雷一次 0.10s 轻量高光，复用 UiMotion 的 kill+回落，防高速连雷堆积
	UiMotion.flash_once(_icon)
	var offset := get_global_rect().position
	var center := offset + Vector2(maxf(size.x, 320.0) * 0.5, CENTER_Y)
	var ink := InkVfxLayer.instance
	if ink != null:
		var color := ThemeBuilder.COLOR_AMBER if warded else Color("#6B4C9A")
		ink.play_thunder(center + Vector2(randf_range(-70.0, 70.0), -170.0),
			center + Vector2(0, -16), color)
		ink.play_splash(center, ThemeBuilder.COLOR_CINNABAR)
		ink.play_float(center + Vector2(28, 4), "-%d" % damage,
			ThemeBuilder.COLOR_CINNABAR, 14, false)
	_shake()


func _on_finished(success: bool, _message: String) -> void:
	_active = false
	_result = 2 if success else 1
	if is_visible_in_tree():
		_icon.set_pulsing(success)
	var ink := InkVfxLayer.instance
	if ink != null and is_visible_in_tree():
		var center := get_global_rect().position + Vector2(maxf(size.x, 320.0) * 0.5, CENTER_Y)
		ink.play_float(center + Vector2(0, -54),
			"证道" if success else "道心 +1", ThemeBuilder.COLOR_AMBER,
			20 if success else 14, success)


func _on_reset() -> void:
	_active = false
	_result = 0
	_cloud_alpha = 0.6


func _on_visibility_changed() -> void:
	var vis := is_visible_in_tree()
	set_process(vis)
	if vis:
		# 隐藏期间不驱动脉冲 Tween，回到页面时按当前状态补一次
		_icon.set_pulsing(_active or _result == 2)


func _shake() -> void:
	if not is_visible_in_tree():
		return
	_icon.position = _shake_origin
	var tween := create_tween()
	tween.tween_property(_icon, "position", _shake_origin + Vector2(-5, 3), 0.03)
	tween.tween_property(_icon, "position", _shake_origin + Vector2(5, -2), 0.04)
	tween.tween_property(_icon, "position", _shake_origin, 0.03)
