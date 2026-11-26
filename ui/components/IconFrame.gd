class_name IconFrame
extends PanelContainer
## 统一图标容器：暖石浅底 + 极淡径向背光 + 居中图标；支持品质/成熟流光脉冲。

var _accent: Color = ThemeBuilder.COLOR_JADE
var _texture_rect: TextureRect
var _glow: TextureRect
var _pulse_tween: Tween
var _frame_size: int = 48


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(texture: Texture2D, frame_size: int = 48, accent: Color = ThemeBuilder.COLOR_JADE,
		pulsing: bool = false, icon_size: int = 0) -> void:
	_frame_size = frame_size
	_accent = accent
	custom_minimum_size = Vector2(frame_size, frame_size)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := ThemeBuilder.panel_box(ThemeBuilder.COLOR_ICON_FRAME,
		ThemeBuilder.COLOR_ICON_FRAME_BORDER, 8, 1, 4)
	add_theme_stylebox_override("panel", style)

	_glow = TextureRect.new()
	_glow.texture = _make_radial(accent)
	_glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_glow.stretch_mode = TextureRect.STRETCH_SCALE
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glow.modulate = Color(1, 1, 1, 0.35)
	add_child(_glow)
	_glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_texture_rect = TextureRect.new()
	_texture_rect.texture = texture
	_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_texture_rect)
	_texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var inset := int(round(float(frame_size) * 0.10))
	if icon_size > 0:
		inset = maxi(1, int(round((float(frame_size) - float(icon_size)) * 0.5)))
	_texture_rect.offset_left = inset
	_texture_rect.offset_top = inset
	_texture_rect.offset_right = -inset
	_texture_rect.offset_bottom = -inset

	pivot_offset = Vector2(frame_size, frame_size) * 0.5
	if pulsing:
		set_pulsing(true)


func set_icon(texture: Texture2D, accent: Color = Color(0, 0, 0, 0)) -> void:
	if _texture_rect != null:
		_texture_rect.texture = texture
	if accent.a > 0.0:
		_accent = accent
		if _glow != null:
			_glow.texture = _make_radial(accent)
		add_theme_stylebox_override("panel",
			ThemeBuilder.panel_box(ThemeBuilder.COLOR_ICON_FRAME,
				ThemeBuilder.COLOR_ICON_FRAME_BORDER, 8, 1, 4))


func set_pulsing(enabled: bool) -> void:
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()
		_pulse_tween = null
	if not enabled:
		if _glow != null:
			_glow.modulate = Color(1, 1, 1, 0.35)
		return
	if _glow == null:
		return
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(_glow, "modulate:a", 0.62, 0.9).set_trans(Tween.TRANS_SINE)
	_pulse_tween.tween_property(_glow, "modulate:a", 0.18, 0.9).set_trans(Tween.TRANS_SINE)


func _make_radial(color: Color) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(color.r, color.g, color.b, 0.30))
	gradient.set_color(1, Color(color.r, color.g, color.b, 0.0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 96
	texture.height = 96
	return texture
