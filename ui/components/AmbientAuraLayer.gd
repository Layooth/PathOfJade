class_name AmbientAuraLayer
extends Control
## 极轻量主场氛围层：14 颗缓慢上浮的淡墨金尘 / 浮光微粒 + 顶部暖金径向微光。
## 全部通过 _draw() 完成，无 Shader、无外部贴图；切后台自动暂停。

const MOTE_COUNT: int = 14

var _motes: Array[Dictionary] = []
var _time: float = 0.0
var _paused: bool = false
var _glow_texture: GradientTexture2D


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glow_texture = _make_glow()
	_seed_motes()
	set_process(true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		_paused = true
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		_paused = false


func _process(delta: float) -> void:
	if _paused:
		return
	_time += delta
	var rect := get_rect()
	if rect.size.y > 1.0:
		for mote in _motes:
			var ny := float(mote["ny"]) - float(mote["speed"]) * delta / rect.size.y
			if ny < -0.02:
				ny = 1.02
				mote["nx"] = randf_range(0.02, 0.98)
			mote["ny"] = ny
	queue_redraw()


func _draw() -> void:
	var rect := get_rect()
	if _glow_texture != null:
		draw_texture_rect(_glow_texture,
			Rect2(-rect.size.x * 0.2, -rect.size.y * 0.28, rect.size.x * 1.4, rect.size.y * 0.95), false)
	for mote in _motes:
		var phase := _time * float(mote["pulse"]) + float(mote["offset"])
		# 克制浮尘：0.10 ~ 0.16，宣纸底上若隐若现
		var alpha := 0.10 + 0.06 * (0.5 + 0.5 * sin(phase))
		var radius := float(mote["radius"]) * (1.0 + 0.18 * sin(phase * 0.7))
		var color: Color = mote["color"]
		# 归一化坐标：任意窗口宽高下都均匀铺满，不会聚在左半边
		draw_circle(Vector2(float(mote["nx"]) * rect.size.x, float(mote["ny"]) * rect.size.y),
			radius, Color(color.r, color.g, color.b, maxf(0.0, alpha)))


func _seed_motes() -> void:
	var palette: Array[Color] = [Color("#C49A45"), Color("#5B9687"), Color("#A98B57")]
	for i in range(MOTE_COUNT):
		var color: Color = palette[i % palette.size()]
		_motes.append({
			"nx": randf_range(0.02, 0.98),
			"ny": randf_range(0.0, 1.0),
			"radius": randf_range(1.5, 3.5),
			"speed": randf_range(5.0, 14.0),
			"pulse": randf_range(0.5, 1.4),
			"offset": randf_range(0.0, TAU),
			"color": color,
		})


func _make_glow() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.76, 0.60, 0.28, 0.10))
	gradient.set_color(1, Color(0.76, 0.60, 0.28, 0.0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.05)
	texture.fill_to = Vector2(0.5, 0.95)
	texture.width = 128
	texture.height = 128
	return texture
