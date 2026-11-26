extends Node
## 全局「宣纸水墨渐隐 + 后台异步预加载」场景过渡单例。
## 置顶 CanvasLayer(100) 遮罩 + 居中卷首视觉，三段式：
##   ① 淡入宣纸遮罩 0.30s → ② ResourceLoader 后台异步加载（遮罩完整展示 ≥0.45s）
##   → ③ change_scene_to_packed 切场景后 0.35s 淡出。
## 过渡期间遮罩 mouse_filter=STOP 拦截误触；结束后恢复 IGNORE。

const FADE_IN_TIME := 0.30
## 遮罩完整（不透明）展示的最短时长，防加载过快文字一闪而过
const MIN_SHOW_TIME := 0.45
const FADE_OUT_TIME := 0.35
## 副文案最大行宽：450 竖屏左右各留 45px
const SUBTITLE_MAX_WIDTH := 360.0
const RING_SIZE := 72.0
const RING_OUTER_RADIUS := 28.0
const RING_INNER_RADIUS := 18.0
const MAIN_TITLE_SIZE := 28

## 卷首水墨灵环：两圈断续细弧反向慢转；仅遮罩可见时 _process，隐藏即停。
class InkRing:
	extends Control

	const OUTER_SPEED := 0.8
	const INNER_SPEED := -1.2
	const OUTER_COLOR := Color(0.153, 0.412, 0.325, 0.55)
	const INNER_COLOR := Color(0.604, 0.408, 0.133, 0.65)

	var active: bool = false
	var _outer_angle: float = 0.0
	var _inner_angle: float = 0.0

	func _ready() -> void:
		custom_minimum_size = Vector2(RING_SIZE, RING_SIZE)
		size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		size_flags_vertical = Control.SIZE_SHRINK_CENTER
		size = Vector2(RING_SIZE, RING_SIZE)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_process(false)

	func set_active(value: bool) -> void:
		if active == value:
			return
		active = value
		if value:
			set_process(true)
			queue_redraw()
		else:
			set_process(false)

	func _process(delta: float) -> void:
		if not active or not is_visible_in_tree():
			set_process(false)
			return
		_outer_angle += OUTER_SPEED * delta
		_inner_angle += INNER_SPEED * delta
		queue_redraw()

	func _draw() -> void:
		var center := Vector2(RING_SIZE * 0.5, RING_SIZE * 0.5)
		_draw_dashed_ring(center, RING_OUTER_RADIUS, OUTER_COLOR, 1.5, _outer_angle)
		_draw_dashed_ring(center, RING_INNER_RADIUS, INNER_COLOR, 1.2, _inner_angle)

	func _draw_dashed_ring(center: Vector2, radius: float, color: Color,
			line_width: float, rotation: float) -> void:
		var segments: Array[float] = [0.15, 1.15, 1.95, 2.95, 3.75, 4.75, 5.55, 6.45]
		for i in range(0, segments.size(), 2):
			var start := rotation + segments[i]
			var end := rotation + segments[i + 1]
			draw_arc(center, radius, start, end, 18, color, line_width, true)
			var start_point := center + Vector2(radius * cos(start), radius * sin(start))
			var end_point := center + Vector2(radius * cos(end), radius * sin(end))
			draw_circle(start_point, 1.5, color, true, 1.0, true)
			draw_circle(end_point, 1.5, color, true, 1.0, true)

var _layer: CanvasLayer
var _mask: ColorRect
var _quote_box: CenterContainer
var _ring: InkRing
var _main_label: Label
var _quote_label: Label
var _breath_tween: Tween

var _is_transitioning: bool = false
## 1 = 异步加载轮询中；2 = 已进入切场景/淡出阶段
var _phase: int = 0
var _loading_path: String = ""
## 遮罩完全不透明后的累计展示时长（秒）
var _show_elapsed: float = 0.0


func _ready() -> void:
	set_process(false)
	_layer = CanvasLayer.new()
	_layer.layer = 100
	add_child(_layer)

	_mask = ColorRect.new()
	_mask.name = "TransitionMask"
	_mask.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_mask.color = Color(ThemeBuilder.COLOR_BG, 0.0)
	_mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mask.visible = false
	_layer.add_child(_mask)

	_quote_box = CenterContainer.new()
	_quote_box.name = "QuoteBox"
	_quote_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_quote_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quote_box.visible = false
	_layer.add_child(_quote_box)

	var column := ThemeBuilder.vbox(14)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quote_box.add_child(column)

	_ring = InkRing.new()
	_ring.name = "InkRing"
	column.add_child(_ring)

	var title_row := ThemeBuilder.hbox(10)
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	title_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	title_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(title_row)
	_main_label = ThemeBuilder.label("云篆流转", MAIN_TITLE_SIZE,
		ThemeBuilder.COLOR_TEXT_GOLD)
	_main_label.name = "MainTitle"
	_main_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_main_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ThemeBuilder.apply_brush_kai(_main_label)
	ThemeBuilder.apply_font_size(_main_label, MAIN_TITLE_SIZE)
	title_row.add_child(_main_label)
	var seal := ThemeBuilder.create_seal_badge("问道", "cinnabar")
	seal.name = "SealBadge"
	# create_seal_badge 内置 10 号字，统一抬到 FONT_CAPTION 红线以上
	for child in seal.get_children():
		if child is Label:
			ThemeBuilder.apply_font_size(child as Label, ThemeBuilder.FONT_CAPTION)
	title_row.add_child(seal)

	var rule := ColorRect.new()
	rule.name = "GoldRule"
	rule.color = Color(ThemeBuilder.COLOR_TEXT_GOLD, 0.35)
	rule.custom_minimum_size = Vector2(48, 1)
	rule.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(rule)

	_quote_label = ThemeBuilder.wrap_label("正在开启……", ThemeBuilder.FONT_BODY_SUB,
		ThemeBuilder.COLOR_TEXT_SECONDARY)
	_quote_label.name = "Subtitle"
	_quote_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_quote_label.custom_minimum_size = Vector2(SUBTITLE_MAX_WIDTH, 0)
	_quote_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_quote_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ThemeBuilder.apply_font_size(_quote_label, ThemeBuilder.FONT_BODY_SUB)
	column.add_child(_quote_label)


## 统一对外入口：淡入遮罩 → 后台异步预加载 → 切场景 → 淡出。
## 过渡中重复调用直接忽略；调用方无需 await（内部自带协程）。
func transition_to_scene(target_path: String, hint_text: String = "") -> void:
	if _is_transitioning or target_path == "":
		return
	_is_transitioning = true
	_loading_path = target_path
	_show_elapsed = 0.0
	_phase = 1

	_apply_scene_copy(target_path, hint_text)
	_quote_box.modulate = Color(1, 1, 1, 0)
	_mask.color = Color(ThemeBuilder.COLOR_BG, 0.0)
	_quote_box.visible = true
	_mask.visible = true
	_ring.set_active(true)
	# 拦截输入防误触：全屏遮罩置于 layer=100，吃掉底下一切点击
	_mask.mouse_filter = Control.MOUSE_FILTER_STOP

	# ① 淡入宣纸遮罩与中心视觉
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_mask, "color:a", 1.0, FADE_IN_TIME)
	tween.tween_property(_quote_box, "modulate:a", 1.0, FADE_IN_TIME)
	_start_subtitle_breath()
	await tween.finished

	# ② 后台异步预加载；_process 轮询直至就绪，且遮罩完整展示至少 MIN_SHOW_TIME
	var error := ResourceLoader.load_threaded_request(_loading_path)
	if error != OK:
		# 请求即失败（路径非法等）：同步切场景兜底，绝不卡在遮罩后
		_switch_by_file()
		return
	set_process(true)


## 目标场景自动匹配文案；hint_text 非空时优先作为副文案，兼容旧调用。
func _apply_scene_copy(target_path: String, hint_text: String) -> void:
	var path := String(target_path)
	var main_text := "云篆流转"
	var sub_text := "正在开启……"
	if path.contains("MainShell"):
		main_text = "踏入洞天"
		sub_text = "灵脉已接引，洞天渐开……"
	elif path.contains("LoginScene"):
		main_text = "敛息归真"
		sub_text = "暂别仙途，静待重逢……"
	var custom := hint_text.strip_edges()
	_main_label.text = main_text
	_quote_label.text = custom if custom != "" else sub_text


func _start_subtitle_breath() -> void:
	if _breath_tween != null and _breath_tween.is_valid():
		return
	_quote_label.modulate.a = 0.65
	_breath_tween = create_tween().set_loops()
	_breath_tween.tween_property(_quote_label, "modulate:a", 1.0, 0.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_breath_tween.tween_property(_quote_label, "modulate:a", 0.65, 0.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _process(delta: float) -> void:
	if not _is_transitioning or _phase != 1:
		return
	_show_elapsed += delta
	var progress: Array = []
	var status := ResourceLoader.load_threaded_get_status(_loading_path, progress)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		# 加载就绪但遮罩展示未满：继续等到最短展示时长，避免引语一闪而过
		if _show_elapsed >= MIN_SHOW_TIME:
			_phase = 2
			set_process(false)
			_switch_by_packed()
		return
	if status == ResourceLoader.THREAD_LOAD_FAILED \
			or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		_phase = 2
		set_process(false)
		_switch_by_file()


## 等新场景 _ready 执行完成并经过一次渲染提交后再揭幕：
## change_scene_* 是延迟生效，单帧 process_frame 可能仍停在旧场景。
func _wait_new_scene_ready() -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	await get_tree().process_frame


## ③ 切场景（异步预加载产物）+ 新场景就绪 + 淡出
func _switch_by_packed() -> void:
	var packed := ResourceLoader.load_threaded_get(_loading_path) as PackedScene
	if packed == null:
		_switch_by_file()
		return
	get_tree().change_scene_to_packed(packed)
	await _wait_new_scene_ready()
	await _fade_out()
	_finish()


## 兜底路径：直接同步切场景（加载失败 / 请求失败）
func _switch_by_file() -> void:
	get_tree().change_scene_to_file(_loading_path)
	await _wait_new_scene_ready()
	await _fade_out()
	_finish()


func _fade_out() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_mask, "color:a", 0.0, FADE_OUT_TIME)
	tween.tween_property(_quote_box, "modulate:a", 0.0, FADE_OUT_TIME)
	await tween.finished


func _finish() -> void:
	_ring.set_active(false)
	if _breath_tween != null and _breath_tween.is_valid():
		_breath_tween.kill()
	_breath_tween = null
	_quote_label.modulate.a = 1.0
	_mask.visible = false
	_mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quote_box.visible = false
	_quote_box.modulate.a = 1.0
	_main_label.text = ""
	_quote_label.text = ""
	_loading_path = ""
	_phase = 0
	_is_transitioning = false
