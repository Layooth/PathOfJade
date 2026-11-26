class_name BootSplashOverlay
extends Control
## 启动过渡层：宣纸底 + 居中玉简图 + 极细玉青进度条。
## 分帧预热 5 张水墨背景与音频缓存，淡出后释放自身。

const LOGO_CANDIDATES: Array[String] = [
	"res://assets/images/splash_logo.png",
	"res://assets/images/splash_logo.jpg",
	"res://assets/images/splash_logo.jpeg",
]
const BG_CANDIDATES: Dictionary = {
	"peaceful": [
		"res://assets/images/bg/bg_peaceful.png",
		"res://assets/images/bg/bg_peaceful.jpg",
	],
	"combat": [
		"res://assets/images/bg/bg_combat.png",
		"res://assets/images/bg/bg_combat.jpg",
	],
	"market": [
		"res://assets/images/bg/bg_market.png",
		"res://assets/images/bg/bg_market.jpg",
	],
	"codex": [
		"res://assets/images/bg/bg_codex.png",
		"res://assets/images/bg/bg_codex.jpg",
	],
	"tribulation": [
		"res://assets/images/bg/bg_tribulation.png",
		"res://assets/images/bg/bg_tribulation.jpg",
	],
}
const MIN_DURATION_SEC: float = 0.85
const FADE_OUT_SEC: float = 0.35
## Boot 底图 1080×1920 中，完整画卷占 880×880。
## 过渡层按同一缩放比例取 Logo，避免 Boot → 游戏内时突然缩小。
const BOOT_IMAGE_SIZE: Vector2 = Vector2(1080.0, 1920.0)
const BOOT_ART_SIZE: float = 880.0

var _logo: TextureRect
var _bar: ProgressBar
var _hint: Label
var _footer: Label
var _column: VBoxContainer
var _top_pad: Control
var _stage_index: int = 0
var _finished: bool = false

const STAGES: Array[String] = [
	"正在展开玉简…",
	"汇集天地灵气…",
	"道途已启",
]


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 100
	_build()
	resized.connect(_layout)
	_layout()
	# 在首帧前就把 Logo 准备好；引擎 Boot Splash 会一直覆盖到这一帧完成
	var logo := _load_first(LOGO_CANDIDATES)
	if logo is Texture2D:
		_logo.texture = logo
	call_deferred("_run")


func _build() -> void:
	var paper := ColorRect.new()
	paper.color = ThemeBuilder.COLOR_BG
	paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(paper)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_column = VBoxContainer.new()
	_column.alignment = BoxContainer.ALIGNMENT_CENTER
	_column.add_theme_constant_override("separation", 16)
	_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(_column)

	# 顶部占位抵消进度条/提示语的高度，让 Logo 中心与 Boot 图中心一致
	_top_pad = Control.new()
	_top_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_column.add_child(_top_pad)

	_logo = TextureRect.new()
	_logo.custom_minimum_size = Vector2(300, 300)
	_logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_logo.material = _make_paper_blend_material()
	_column.add_child(_logo)

	_bar = ProgressBar.new()
	_bar.custom_minimum_size = Vector2(280, 4)
	_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_bar.show_percentage = false
	_bar.value = 0.0
	var track := StyleBoxFlat.new()
	track.bg_color = Color(ThemeBuilder.COLOR_JADE, 0.14)
	track.set_corner_radius_all(2)
	_bar.add_theme_stylebox_override("background", track)
	var fill := StyleBoxFlat.new()
	fill.bg_color = ThemeBuilder.COLOR_JADE
	fill.set_corner_radius_all(2)
	_bar.add_theme_stylebox_override("fill", fill)
	_column.add_child(_bar)

	_hint = ThemeBuilder.label(STAGES[0], ThemeBuilder.FONT_BODY_SUB,
		ThemeBuilder.COLOR_TEXT_SECONDARY)
	ThemeBuilder.apply_brush_kai(_hint)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.custom_minimum_size = Vector2(280, 0)
	_column.add_child(_hint)

	_footer = ThemeBuilder.label("玉简问道 · PathOfJade", ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_DIM)
	ThemeBuilder.apply_brush_bold(_footer)
	_footer.modulate.a = 0.55
	_footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_footer.offset_left = 22.0
	_footer.offset_right = 300.0
	_footer.offset_top = -34.0
	_footer.offset_bottom = -14.0
	add_child(_footer)


func _make_paper_blend_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
render_mode blend_mix;
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float lum = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
	float paper_mask = smoothstep(0.82, 0.97, lum);
	vec3 paper = vec3(0.957, 0.937, 0.902);
	vec3 rgb = mix(tex.rgb, paper, paper_mask);
	vec2 p = abs(UV - vec2(0.5)) - vec2(0.455);
	float d = length(max(p, vec2(0.0))) - 0.02;
	float edge = 1.0 - smoothstep(0.0, 0.05, d);
	COLOR = vec4(rgb, tex.a * edge);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	return material


func _layout() -> void:
	if _column == null:
		return
	var vp := get_viewport_rect().size
	# 与 Boot Splash 的 KEEP 缩放完全一致：取宽/高缩放较小者。
	var boot_scale := minf(vp.x / BOOT_IMAGE_SIZE.x, vp.y / BOOT_IMAGE_SIZE.y)
	var logo_size := clampf(BOOT_ART_SIZE * boot_scale, 240.0, 460.0)
	logo_size = minf(logo_size, vp.y * 0.52)
	_logo.custom_minimum_size = Vector2(logo_size, logo_size)
	_column.custom_minimum_size = Vector2(minf(vp.x - 48.0, maxf(300.0, logo_size + 40.0)), 0)
	var below_height := _bar.get_combined_minimum_size().y \
		+ _hint.get_combined_minimum_size().y + 16.0
	_top_pad.custom_minimum_size = Vector2(0.0, below_height)


func _run() -> void:
	var started := Time.get_ticks_msec()
	await _advance_to(14.0)

	var index := 0
	for theme_key in BG_CANDIDATES.keys():
		await get_tree().process_frame
		_load_first(BG_CANDIDATES[theme_key])
		index += 1
		await _advance_to(14.0 + float(index) * 12.0)

	if AudioManager != null:
		AudioManager.prewarm()
	await _advance_to(82.0)
	_set_stage(1)
	await _advance_to(94.0)
	_set_stage(2)
	await _advance_to(100.0)

	var elapsed := float(Time.get_ticks_msec() - started) / 1000.0
	var remain := MIN_DURATION_SEC - elapsed
	if remain > 0.0:
		await get_tree().create_timer(remain).timeout
	_finish()


func _load_first(paths: Array) -> Resource:
	for path_value in paths:
		var path := String(path_value)
		if ResourceLoader.exists(path):
			return load(path)
	return null


func _advance_to(target: float) -> void:
	var tween := create_tween()
	tween.tween_property(_bar, "value", target, 0.12) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished


func _set_stage(index: int) -> void:
	_stage_index = clampi(index, 0, STAGES.size() - 1)
	if _hint != null:
		_hint.text = STAGES[_stage_index]


func _finish() -> void:
	if _finished:
		return
	_finished = true
	if AudioManager != null:
		AudioManager.fade_in_bgm()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, FADE_OUT_SEC) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
	queue_free()
