class_name PoolMilestoneBar
extends Control
## 悟道池进度条：轨道 + 鎏金琥珀填充 + 10% / 25% / 50% / 95% 四枚水墨里程碑节点。
## 纯 _draw() 矢量绘制，不引入任何外部贴图；数值更新用 0.22s EASE_OUT 追赶，
## 满格保持沉稳静止纯色，不叠任何移动流光。

const THRESHOLDS: Array = [0.10, 0.25, 0.50, 0.95]
## 12px 条高的 37.5%：菱形半高居中且不越出轨道上下边缘
const NODE_HALF_HEIGHT: float = 4.5
const BAR_HEIGHT: float = 12.0
## 未达成节点：浅宣纸底 + 淡烟灰 1px 描边（与鎏金填充拉开明度差）
const NODE_PENDING_FILL: Color = Color("#EFE9DD")

## 目标比例（外部读取）与实际绘制比例（Tween 追赶）
var ratio: float = 0.0
var _display_ratio: float = 0.0
var _ratio_tween: Tween


func _ready() -> void:
	custom_minimum_size = Vector2(0, BAR_HEIGHT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 百分比不变但容器宽度变化时也要重绘，节点位置才不会停留在旧坐标
	resized.connect(queue_redraw)


func set_ratio(value: float) -> void:
	var clamped := clampf(value, 0.0, 1.0)
	if is_equal_approx(clamped, ratio):
		return
	ratio = clamped
	# 首次赋值不做开屏假涨
	if not has_meta("ui_progress_ready"):
		_set_display(clamped)
		set_meta("ui_progress_ready", true)
		return
	if _ratio_tween != null and _ratio_tween.is_valid():
		_ratio_tween.kill()
	var current := _display_ratio
	if clamped < current - 0.02 and current > 0.02 and clamped > 0.001:
		# 阈值消耗导致回落：先 0.08s 快速拉满，再归零平滑追到新值
		_ratio_tween = create_tween()
		_ratio_tween.tween_method(_set_display, current, 1.0, 0.08) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_ratio_tween.tween_callback(func() -> void: _set_display(0.0))
		_ratio_tween.tween_method(_set_display, 0.0, clamped, 0.22) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		_ratio_tween = create_tween()
		_ratio_tween.tween_method(_set_display, current, clamped, 0.22) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _set_display(value: float) -> void:
	_display_ratio = clampf(value, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var width := size.x
	if width <= 0.0:
		return
	var height := maxf(size.y, BAR_HEIGHT)
	var radius := int(height * 0.5)
	# 轨道/填充与 ThemeBuilder.progress_bar 完全同款：底色、边框、圆角一致
	draw_style_box(ThemeBuilder.panel_box(ThemeBuilder.COLOR_BAR_TRACK,
		ThemeBuilder.COLOR_BAR_TRACK_EDGE, ThemeBuilder.PROGRESS_BG_RADIUS, 1, 0),
		Rect2(0, 0, width, height))
	if _display_ratio > 0.0:
		var fill_width := maxf(float(radius), width * _display_ratio)
		draw_style_box(ThemeBuilder.flat_box(ThemeBuilder.COLOR_TEXT_GOLD,
			ThemeBuilder.PROGRESS_FILL_RADIUS, 0, 0), Rect2(0, 0, fill_width, height))
	for i in range(THRESHOLDS.size()):
		var center := Vector2(width * float(THRESHOLDS[i]), height * 0.5)
		_draw_node(center, i)


func _draw_node(center: Vector2, index: int) -> void:
	var half := NODE_HALF_HEIGHT
	var shape := PackedVector2Array([
		center + Vector2(0.0, -half),
		center + Vector2(half, 0.0),
		center + Vector2(0.0, half),
		center + Vector2(-half, 0.0),
	])
	var ring := PackedVector2Array([shape[0], shape[1], shape[2], shape[3], shape[0]])
	if _display_ratio + 0.0001 >= float(THRESHOLDS[index]):
		# 已达成：宣纸白实心 + 1px 深墨描边，压在鎏金填充上依然清晰
		draw_colored_polygon(shape, ThemeBuilder.COLOR_CARD)
		draw_polyline(ring, ThemeBuilder.COLOR_TEXT_PRIMARY, 1.0, true)
	else:
		# 未达成：浅宣纸底 + 1px 淡烟灰描边
		draw_colored_polygon(shape, NODE_PENDING_FILL)
		draw_polyline(ring, ThemeBuilder.COLOR_TEXT_MUTED, 1.0, true)
