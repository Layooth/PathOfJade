class_name InkVfxLayer
extends Control
## 移动端轻量水墨动效层：纯 _draw 笔触 + Tween + 固定对象池。
## 不创建 GPUParticles2D，不做全屏后处理，也不拦截任何输入。

const FLOAT_POOL: int = 16
const EFFECT_POOL: int = 12
const FLOAT_RISE: float = 32.0
const FLOAT_TIME: float = 0.65
## 层级：高于顶栏(10)与内容区，低于轻提示(20)、抽屉(30)、底部浮层(40)、弹窗(50)、启动层(100)
const Z_INDEX: int = 12

## 统一笔墨色盘
const INK_JADE: Color = Color(0.11, 0.32, 0.28)
const INK_JADE_LIGHT: Color = Color(0.22, 0.56, 0.48)
const INK_CINNABAR: Color = Color(0.76, 0.22, 0.18)
const INK_GOLD: Color = Color(0.82, 0.62, 0.22)
## 会心剑弧专用：主弧鎏金琥珀 + 上下伴生弧亮黛玉青（与普攻单弧黛青拉开层次）
const CRIT_GOLD: Color = Color(0.82, 0.58, 0.18, 0.95)
const CRIT_JADE: Color = Color(0.18, 0.52, 0.44, 0.85)
## 会心三道剑气：单弧运笔 0.16s、彼此错开 0.025s、整段生命周期 0.40s
const CRIT_ARC_WRITE_SEC: float = 0.16
const CRIT_ARC_STAGGER_SEC: float = 0.025
const CRIT_SLASH_DURATION: float = 0.40
## 会心十字斩痕：±35° 双锋，0.22s 内伸展后随墨迹淡出
const CRIT_MARK_DURATION: float = 0.22
const CRIT_MARK_ANGLE_DEG: float = 35.0

static var instance: InkVfxLayer = null

var _floats: Array[Label] = []
var _effects: Array[InkEffect] = []
var _float_index: int = 0
var _effect_index: int = 0
## 居中里程碑横幅：暖墨描金匾额载体（内嵌朱砂印章），取代裸字+悬空红印
var _banner_card: PanelContainer
var _banner_title: Label
var _banner_sub: Label
var _banner_seal: PanelContainer
var _banner_seal_label: Label
var _banner_tween: Tween
var _enabled: bool = true
## 侧边抽屉展开时由外壳置位：被完全遮挡的底层画面不再派发飘字与笔触，避免无效渲染
var suppressed: bool = false


class InkEffect:
	extends Control
	var kind: String = "slash"
	var color: Color = Color.WHITE
	var points: PackedVector2Array = PackedVector2Array()
	var center: Vector2 = Vector2.ZERO
	var radius: float = 0.0
	var t: float = 0.0
	var dots: Array[Vector2] = []
	var spark_color: Color = INK_GOLD
	var stamp_scale: float = 1.0
	var sweep_width: float = 160.0
	## 会心三道剑气：点集 / 配色 / 线宽倍率 / 各自起始延迟（0.025s 依次划出）
	var crit_arcs: Array = []
	var crit_colors: Array = []
	var crit_widths: PackedFloat32Array = PackedFloat32Array()
	var crit_delays: PackedFloat32Array = PackedFloat32Array()
	## 十字斩痕的第二道锋芒色（与主色交错）
	var accent: Color = INK_JADE_LIGHT
	## 制符「S」朱砂符纹：采样点 / 单位法线 / 动态笔宽（三者等长，配合 draw_polygon 描丝带）
	var stroke_points: PackedVector2Array = PackedVector2Array()
	var stroke_normals: PackedVector2Array = PackedVector2Array()
	var stroke_widths: PackedFloat32Array = PackedFloat32Array()
	## 法宝共鸣：true = 装备（向内凝练）/ false = 卸下（向外轻散）
	var inward: bool = true
	const ARTIFACT_DURATION: float = 0.45
	## 一气呵成节奏：0~45% 运笔，45~62% 凝符定格，62~100% 浮散淡出
	const STROKE_DURATION: float = 0.62
	const STROKE_WRITE_END: float = 0.45
	const STROKE_HOLD_END: float = 0.62
	## 七门百艺专属矿物颜料（浅宣纸底高对比；固定色，不受全局墨水色影响）
	const SKILL_HERB: Color = Color("#3B7A57")
	const SKILL_HERB_LIGHT: Color = Color("#7FB08A")
	const SKILL_WOOD_INK: Color = Color("#4A3B2A")
	const SKILL_CHIP: Color = Color("#9A6B2F")
	const SKILL_STONE: Color = Color("#D9A441")
	const SKILL_WARM: Color = Color("#FFF3D6")
	const SKILL_ALCHEMY: Color = Color("#C8963E")
	const SKILL_EMBER: Color = Color("#E08A3C")
	const SKILL_FORGE_DARK: Color = Color("#8A5A16")
	const SKILL_DAI: Color = Color("#33484F")
	const SKILL_CINNABAR: Color = Color(0.76, 0.22, 0.18)
	var _tween: Tween

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func reset() -> void:
		if _tween != null and _tween.is_valid():
			_tween.kill()
		_tween = null
		t = 0.0
		points = PackedVector2Array()
		stroke_points = PackedVector2Array()
		stroke_normals = PackedVector2Array()
		stroke_widths = PackedFloat32Array()
		dots.clear()
		stamp_scale = 1.0
		sweep_width = 160.0
		inward = true
		modulate.a = 1.0
		scale = Vector2.ONE
		visible = false

	func play_slash(points_value: PackedVector2Array, color_value: Color) -> void:
		reset()
		kind = "slash"
		points = points_value
		color = color_value
		visible = true
		pivot_offset = size * 0.5
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_method(_set_t, 0.0, 1.0, 0.16).set_trans(Tween.TRANS_CUBIC) \
			.set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "modulate:a", 0.0, 0.16).set_delay(0.06)
		tween.chain().tween_callback(_finish)
		_tween = tween
		queue_redraw()

	func play_splash(center_value: Vector2, color_value: Color) -> void:
		reset()
		kind = "splash"
		center = center_value
		color = color_value
		dots.clear()
		for i in range(4):
			var angle := TAU * float(i) / 4.0 + randf_range(-0.5, 0.5)
			dots.append(Vector2(cos(angle), sin(angle)) * randf_range(8.0, 20.0))
		visible = true
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_method(_set_t, 0.0, 1.0, 0.28).set_trans(Tween.TRANS_CUBIC) \
			.set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "modulate:a", 0.0, 0.28).set_delay(0.08)
		tween.chain().tween_callback(_finish)
		_tween = tween
		queue_redraw()

	func play_thunder(points_value: PackedVector2Array, color_value: Color) -> void:
		reset()
		kind = "thunder"
		points = points_value
		color = color_value
		visible = true
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_method(_set_t, 0.0, 1.0, 0.18)
		tween.tween_property(self, "modulate:a", 0.0, 0.18)
		tween.chain().tween_callback(_finish)
		_tween = tween
		queue_redraw()

	func play_ring(center_value: Vector2, color_value: Color, max_radius: float) -> void:
		reset()
		kind = "ring"
		center = center_value
		color = color_value
		radius = max_radius
		visible = true
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_method(_set_t, 0.0, 1.0, 0.55).set_trans(Tween.TRANS_CUBIC) \
			.set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "modulate:a", 0.0, 0.55)
		tween.chain().tween_callback(_finish)
		_tween = tween
		queue_redraw()

	func play_smoke(center_value: Vector2, color_value: Color) -> void:
		_begin("smoke", center_value, color_value, 0.50, 0.50)

	func play_hammer(center_value: Vector2, color_value: Color, spark: Color) -> void:
		_begin("hammer", center_value, color_value, 0.25, 0.55)
		spark_color = spark

	func play_leaves(center_value: Vector2, color_value: Color) -> void:
		_begin("leaves", center_value, color_value, 0.40, 0.40)

	func play_debris(center_value: Vector2, color_value: Color) -> void:
		_begin("debris", center_value, color_value, 0.22, 0.35)

	func play_gather(center_value: Vector2, color_value: Color) -> void:
		_begin("gather", center_value, color_value, 0.45, 0.45)

	func play_ripple(center_value: Vector2, color_value: Color) -> void:
		_begin("ripple", center_value, color_value, 0.50, 0.35)

	func play_harvest(center_value: Vector2, color_value: Color, width: float) -> void:
		_begin("harvest", center_value, color_value, 0.26, 0.35)
		sweep_width = width

	func play_gold_flow(center_value: Vector2, color_value: Color) -> void:
		_begin("gold", center_value, color_value, 0.25, 0.45)

	func play_cross(center_value: Vector2, color_value: Color) -> void:
		_begin("cross", center_value, color_value, 0.20, 0.35)

	## 会心三道交错剑气：线性 t 自行推导每道弧的运笔与淡出，错开 0.025s 依次划出
	func play_crit_slash(arcs: Array, colors: Array, widths: PackedFloat32Array,
			delays: PackedFloat32Array) -> void:
		reset()
		kind = "crit_slash"
		crit_arcs = arcs
		crit_colors = colors
		crit_widths = widths
		crit_delays = delays
		visible = true
		pivot_offset = size * 0.5
		var tween := create_tween()
		tween.tween_method(_set_t, 0.0, 1.0, CRIT_SLASH_DURATION)
		tween.tween_callback(_finish)
		_tween = tween
		queue_redraw()

	## 会心十字斩痕：±35° 两道短促墨锋快速伸展，随后随墨迹淡出（纯 _draw，0.22s）
	func play_crit_mark(center_value: Vector2, color_value: Color,
			accent_value: Color) -> void:
		reset()
		kind = "crit_mark"
		center = center_value
		color = color_value
		accent = accent_value
		visible = true
		var tween := create_tween()
		tween.tween_method(_set_t, 0.0, 1.0, CRIT_MARK_DURATION)
		tween.tween_callback(_finish)
		_tween = tween
		queue_redraw()

	func play_dissolve(center_value: Vector2, color_value: Color) -> void:
		reset()
		kind = "dissolve"
		center = center_value
		color = color_value
		dots.clear()
		for i in range(5):
			var angle := TAU * float(i) / 5.0 + randf_range(-0.3, 0.3)
			dots.append(Vector2(cos(angle), sin(angle)) * randf_range(20.0, 32.0))
		visible = true
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_method(_set_t, 0.0, 1.0, 0.32).set_trans(Tween.TRANS_CUBIC) \
			.set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "modulate:a", 0.0, 0.32).set_delay(0.04)
		tween.chain().tween_callback(_finish)
		_tween = tween
		queue_redraw()

	func play_stamp(center_value: Vector2, color_value: Color) -> void:
		reset()
		kind = "stamp"
		center = center_value
		color = color_value
		stamp_scale = 1.30
		visible = true
		var tween := create_tween()
		tween.tween_method(_set_stamp_scale, 1.30, 1.0, 0.18) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_interval(0.15)
		tween.tween_property(self, "modulate:a", 0.0, 0.18)
		tween.tween_callback(_finish)
		_tween = tween
		queue_redraw()

	## 法宝共鸣：双层同心弧形灵纹旋转合拢 + 4 枚四角星芒微闪（纯 _draw，约 0.45s）。
	## equipped=true 装备：灵纹由外向内凝练、星芒收束；false 卸下：向外轻散。
	func play_artifact(center_value: Vector2, color_value: Color, equipped: bool) -> void:
		reset()
		kind = "artifact"
		center = center_value
		color = color_value
		inward = equipped
		visible = true
		# 线性 t：各 draw 内部自控缓动，尾段 40% 平滑淡出
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_method(_set_t, 0.0, 1.0, ARTIFACT_DURATION)
		tween.tween_property(self, "modulate:a", 0.0, ARTIFACT_DURATION * 0.40) \
			.set_delay(ARTIFACT_DURATION * 0.60)
		tween.chain().tween_callback(_finish)
		_tween = tween
		queue_redraw()

	## 制符完成：毛笔书写「S」型朱砂符纹（运笔 → 凝符 → 浮散），复用同一对象池槽位
	func play_talisman_s_stroke(center_value: Vector2, color_value: Color) -> void:
		reset()
		kind = "talisman_s_stroke"
		center = center_value
		color = color_value
		_build_talisman_stroke()
		visible = true
		# 线性 t：三个阶段的百分比阈值即真实时间占比
		var tween := create_tween()
		tween.tween_method(_set_t, 0.0, 1.0, STROKE_DURATION)
		tween.tween_callback(_finish)
		_tween = tween
		queue_redraw()

	## 两段三次贝塞尔拼成 S：右上起笔 → 左上弧 → 斜掠符心 → 右下弧 → 左下出锋
	func _build_talisman_stroke() -> void:
		var p0 := Vector2(6.0, -25.0)
		var c1 := Vector2(-14.0, -22.0)
		var c2 := Vector2(-16.0, -4.0)
		var p1 := Vector2(0.0, 0.0)
		var c3 := Vector2(16.0, 4.0)
		var c4 := Vector2(14.0, 22.0)
		var p2 := Vector2(-6.0, 25.0)
		var raw := PackedVector2Array()
		var segments := 18
		for i in range(segments + 1):
			var u := float(i) / float(segments)
			if u <= 0.5:
				raw.append(_cubic_bezier(p0, c1, c2, p1, u * 2.0))
			else:
				raw.append(_cubic_bezier(p1, c3, c4, p2, (u - 0.5) * 2.0))
		# 每笔 ±6° 随机偏转：连续画符不出现机械复制感
		var angle := deg_to_rad(randf_range(-6.0, 6.0))
		var cos_a := cos(angle)
		var sin_a := sin(angle)
		stroke_points = PackedVector2Array()
		for local in raw:
			var rotated := Vector2(local.x * cos_a - local.y * sin_a,
				local.x * sin_a + local.y * cos_a)
			stroke_points.append(center + rotated)
		# 预结算法线与笔宽：draw 阶段只做偏移，不重复三角函数
		var count := stroke_points.size()
		stroke_normals = PackedVector2Array()
		stroke_widths = PackedFloat32Array()
		for i in range(count):
			var prev := stroke_points[maxi(0, i - 1)]
			var next := stroke_points[mini(count - 1, i + 1)]
			var tangent := next - prev
			if tangent.length_squared() < 0.000001:
				tangent = Vector2(0.0, 1.0)
			tangent = tangent.normalized()
			stroke_normals.append(Vector2(-tangent.y, tangent.x))
			stroke_widths.append(_stroke_width(float(i) / float(maxi(1, count - 1))))

	## 提按：起笔顿按 3.5 → 转折收 2.2 → 符心行笔 4.5 → 出锋 0.4
	func _stroke_width(u: float) -> float:
		if u < 0.22:
			return lerpf(3.5, 2.2, u / 0.22)
		if u < 0.52:
			return lerpf(2.2, 4.5, (u - 0.22) / 0.30)
		return lerpf(4.5, 0.4, pow(clampf((u - 0.52) / 0.48, 0.0, 1.0), 0.8))

	func _cubic_bezier(a: Vector2, b: Vector2, c: Vector2, d: Vector2, u: float) -> Vector2:
		var inv := 1.0 - u
		return a * (inv * inv * inv) + b * (3.0 * inv * inv * u) \
			+ c * (3.0 * inv * u * u) + d * (u * u * u)

	# ---- 七门百艺完成笔触（统一 0.50~0.65s，尾段 35% 淡出） ----

	func play_skill_herb(c: Vector2) -> void:
		_begin_skill("skill_herb", c, SKILL_HERB, 0.62)

	func play_skill_wood(c: Vector2) -> void:
		_begin_skill("skill_wood", c, SKILL_WOOD_INK, 0.50)

	func play_skill_mine(c: Vector2) -> void:
		_begin_skill("skill_mine", c, SKILL_STONE, 0.56)

	func play_skill_alchemy(c: Vector2) -> void:
		_begin_skill("skill_alchemy", c, SKILL_ALCHEMY, 0.65)

	func play_skill_forge(c: Vector2) -> void:
		_begin_skill("skill_forge", c, SKILL_EMBER, 0.52)

	func play_skill_cultivate(c: Vector2) -> void:
		_begin_skill("skill_cultivate", c, SKILL_DAI, 0.65)

	## 兜底：非百艺 / 未知 skill_id → 柔和水墨圆晕（不再出现穿屏直线斜劈）
	func play_ink_halo(c: Vector2) -> void:
		_begin_skill("skill_halo", c, SKILL_DAI, 0.52)

	## 百艺统一节奏：线性 t（各 draw 内部自行缓动），尾段 35% 平滑 alpha 淡出
	func _begin_skill(kind_value: String, center_value: Vector2, color_value: Color,
			duration: float) -> void:
		reset()
		kind = kind_value
		center = center_value
		color = color_value
		visible = true
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_method(_set_t, 0.0, 1.0, duration)
		tween.tween_property(self, "modulate:a", 0.0, duration * 0.35) \
			.set_delay(duration * 0.65)
		tween.chain().tween_callback(_finish)
		_tween = tween
		queue_redraw()

	func _begin(kind_value: String, center_value: Vector2, color_value: Color,
			duration: float, fade_delay_ratio: float) -> void:
		reset()
		kind = kind_value
		center = center_value
		color = color_value
		visible = true
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_method(_set_t, 0.0, 1.0, duration).set_trans(Tween.TRANS_CUBIC) \
			.set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "modulate:a", 0.0, duration * 0.55) \
			.set_delay(duration * fade_delay_ratio)
		tween.chain().tween_callback(_finish)
		_tween = tween
		queue_redraw()

	func _set_stamp_scale(value: float) -> void:
		stamp_scale = value
		queue_redraw()

	func _set_t(value: float) -> void:
		t = value
		queue_redraw()

	func _finish() -> void:
		visible = false
		_tween = null

	func _draw() -> void:
		match kind:
			"slash":
				_draw_slash()
			"splash":
				_draw_splash()
			"thunder":
				_draw_thunder()
			"ring":
				_draw_ring()
			"smoke":
				_draw_smoke()
			"hammer":
				_draw_hammer()
			"leaves":
				_draw_leaves()
			"debris":
				_draw_debris()
			"gather":
				_draw_gather()
			"ripple":
				_draw_ripple()
			"harvest":
				_draw_harvest()
			"gold":
				_draw_gold()
			"cross":
				_draw_cross()
			"crit_slash":
				_draw_crit_slash()
			"crit_mark":
				_draw_crit_mark()
			"dissolve":
				_draw_dissolve()
			"stamp":
				_draw_stamp()
			"artifact":
				_draw_artifact()
			"talisman_s_stroke":
				_draw_talisman_stroke()
			"skill_herb":
				_draw_skill_herb()
			"skill_wood":
				_draw_skill_wood()
			"skill_mine":
				_draw_skill_mine()
			"skill_alchemy":
				_draw_skill_alchemy()
			"skill_forge":
				_draw_skill_forge()
			"skill_cultivate":
				_draw_skill_cultivate()
			"skill_halo":
				_draw_skill_halo()

	func _draw_slash() -> void:
		if points.size() < 2:
			return
		var count := points.size() - 1
		for i in range(count):
			var p := float(i) / float(maxi(1, count))
			if p > t:
				break
			var width := 0.8 + sin(PI * p) * 4.4
			draw_line(points[i], points[i + 1], Color(color, 0.16), width * 2.4, true)
			draw_line(points[i], points[i + 1], Color(color, 0.88), width, true)

	func _draw_splash() -> void:
		var spread := 1.0 + t * 1.6
		for i in range(dots.size()):
			var pos := center + dots[i] * spread
			var r := lerpf(2.0, 4.2, t) * (1.0 - t * 0.45)
			draw_circle(pos, r, Color(color, 0.72 * (1.0 - t)))
			draw_circle(pos, r * 1.9, Color(color, 0.12 * (1.0 - t)))

	func _draw_thunder() -> void:
		if points.size() < 2:
			return
		var glow := Color(color.r, color.g, color.b, 0.22 * (1.0 - t * 0.35))
		var core := Color(0.92, 0.98, 0.96, 0.92 * (1.0 - t * 0.25))
		for i in range(points.size() - 1):
			draw_line(points[i], points[i + 1], glow, 8.0, true)
			draw_line(points[i], points[i + 1], color, 3.4, true)
			draw_line(points[i], points[i + 1], core, 1.2, true)

	func _draw_ring() -> void:
		var r := lerpf(8.0, radius, t)
		draw_arc(center, r, 0.0, TAU, 64, Color(color, 0.65 * (1.0 - t)), 5.0, true)
		draw_arc(center, r * 0.84, 0.0, TAU, 48, Color(color, 0.34 * (1.0 - t)), 2.0, true)

	func _draw_smoke() -> void:
		var previous := center + Vector2(0, 10)
		for i in range(1, 9):
			var p := float(i) / 8.0
			var next := center + Vector2(sin(p * 5.0 + t * 3.0) * 5.0,
				10.0 - p * (42.0 + t * 12.0))
			var width := lerpf(3.2, 0.6, p)
			draw_line(previous, next, Color(color, 0.35), width * 1.8, true)
			draw_line(previous, next, Color(color, 0.62), width, true)
			previous = next

	func _draw_hammer() -> void:
		var r := lerpf(4.0, 28.0, t)
		for i in range(4):
			var start := TAU * float(i) / 4.0 + 0.25
			draw_arc(center, r, start, start + 1.05, 14, Color(color, 0.72), 5.0, true)
		for i in range(3):
			var angle := -PI * 0.85 + float(i) * 0.55
			var dir := Vector2(cos(angle), sin(angle))
			draw_line(center + dir * (r * 0.75), center + dir * (r + 10.0),
				Color(spark_color, 0.85), 2.0, true)

	func _draw_leaves() -> void:
		for i in range(2):
			var side := -1.0 if i == 0 else 1.0
			var base := center + Vector2(side * 12.0, 12.0)
			var lift := 20.0 + t * 18.0
			var tip := base + Vector2(side * (9.0 + t * 5.0), -lift)
			var mid := base + Vector2(side * (13.0 + t * 3.0), -lift * 0.48)
			var pts := PackedVector2Array([base, mid, tip])
			draw_polyline(pts, Color(color, 0.78), 2.4, true)
			draw_line(mid, base.lerp(tip, 0.55), Color(color, 0.24), 1.2, true)

	func _draw_debris() -> void:
		for i in range(3):
			var angle := -PI * 0.75 + float(i) * 0.45
			var dir := Vector2(cos(angle), sin(angle))
			var start := center + dir * 3.0
			var end := center + dir * (13.0 + t * 8.0)
			draw_line(start, end, Color(color, 0.8), 3.0, true)
			draw_line(start, end, Color(color, 0.24), 6.0, true)

	func _draw_gather() -> void:
		var r := lerpf(26.0, 3.0, t)
		for i in range(3):
			var angle := -PI * 0.5 + TAU * float(i) / 3.0
			var start := center + Vector2(cos(angle), sin(angle)) * r
			var end := center + Vector2(cos(angle), sin(angle)) * (r * 0.55)
			draw_line(start, end, Color(color, 0.55), 1.5, true)

	func _draw_ripple() -> void:
		for i in range(2):
			var r := lerpf(6.0, 36.0, t) + float(i) * 5.0
			draw_arc(center, r, 0.0, TAU, 40, Color(color, 0.45 * (1.0 - t)), 1.8, true)

	func _draw_harvest() -> void:
		var half := sweep_width * 0.5
		var pts := PackedVector2Array()
		for i in range(13):
			var p := float(i) / 12.0
			if p > t:
				break
			pts.append(center + Vector2(lerpf(-half, half, p), sin(PI * p) * 16.0))
		if pts.size() > 1:
			draw_polyline(pts, Color(color, 0.18), 10.0, true)
			draw_polyline(pts, Color(color, 0.62), 3.2, true)

	func _draw_gold() -> void:
		var pts := PackedVector2Array()
		for i in range(9):
			var p := float(i) / 8.0
			pts.append(center + Vector2(lerpf(-24.0, 24.0, p), -sin(PI * p) * 12.0 + 2.0))
		draw_polyline(pts, Color(color, 0.2), 5.0, true)
		draw_polyline(pts, Color(color, 0.9), 1.8, true)

	func _draw_cross() -> void:
		for i in range(2):
			var dir := Vector2(1, 1).normalized() if i == 0 else Vector2(1, -1).normalized()
			var start := center - dir * 42.0
			var end := center + dir * 42.0
			for j in range(8):
				var p := float(j) / 8.0
				if p > t:
					break
				var a := start.lerp(end, p)
				var b := start.lerp(end, p + 0.13)
				draw_line(a, b, Color(color, 0.82), 1.0 + sin(PI * p) * 4.0, true)
		draw_circle(center, 4.0 * (1.0 - t), Color(INK_CINNABAR, 0.85 * (1.0 - t)))

	## 三道交错剑气：各道按自身延迟推进，运笔完成后各自淡出；主弧线宽加倍显厚重
	func _draw_crit_slash() -> void:
		var elapsed := t * CRIT_SLASH_DURATION
		for i in range(crit_arcs.size()):
			var pts: PackedVector2Array = crit_arcs[i]
			if pts.size() < 2:
				continue
			var delay := 0.0
			if i < crit_delays.size():
				delay = crit_delays[i]
			var write := clampf((elapsed - delay) / CRIT_ARC_WRITE_SEC, 0.0, 1.0)
			if write <= 0.0:
				continue
			var fade := 1.0 - clampf((elapsed - delay - CRIT_ARC_WRITE_SEC) / 0.18, 0.0, 1.0)
			var col: Color = crit_colors[i] if i < crit_colors.size() else color
			var width_scale := 1.0
			if i < crit_widths.size():
				width_scale = crit_widths[i]
			var core_alpha := col.a * 0.88 * fade
			var glow_alpha := col.a * 0.16 * fade
			var count := pts.size() - 1
			for j in range(count):
				var p := float(j) / float(maxi(1, count))
				if p > write:
					break
				var width := (0.8 + sin(PI * p) * 4.4) * width_scale
				draw_line(pts[j], pts[j + 1], Color(col.r, col.g, col.b, glow_alpha),
					width * 2.4, true)
				draw_line(pts[j], pts[j + 1], Color(col.r, col.g, col.b, core_alpha),
					width, true)

	## 十字斩痕：前 40% 快速伸展，后 60% 随墨迹淡出。
	## 两道为整条「两头收尖、中段饱满」的毛笔锋丝带（单块多边形填充，无分段接缝），
	## 笔画带极轻弧度，主锋鎏金略长、副锋黛青略短，交叉点稍作错位。
	func _draw_crit_mark() -> void:
		var grow := clampf(t / 0.40, 0.0, 1.0)
		var eased := 1.0 - pow(1.0 - grow, 3.0)
		var fade := 1.0 - clampf((t - 0.40) / 0.60, 0.0, 1.0)
		var angle := deg_to_rad(CRIT_MARK_ANGLE_DEG)
		for i in range(2):
			var dir := Vector2(cos(angle), sin(angle))
			if i == 1:
				dir = Vector2(cos(-angle), sin(-angle))
			var perp := Vector2(-dir.y, dir.x)
			var col: Color = color if i == 0 else accent
			var reach := lerpf(8.0, 32.0, eased) * (1.0 if i == 0 else 0.82)
			var origin := center + perp * (1.5 if i == 0 else -1.5)
			var bow := perp * (4.2 if i == 0 else -3.4)
			var peak_width := 6.2 if i == 0 else 5.0
			var points := PackedVector2Array()
			var widths := PackedFloat32Array()
			for k in range(11):
				var p := float(k) / 10.0
				points.append(origin + dir * lerpf(-reach, reach, p)
					+ bow * (1.0 - pow(2.0 * p - 1.0, 2.0)))
				# 中段最饱满、两端收至 0.4px 笔尖
				widths.append(lerpf(0.4, peak_width, 1.0 - pow(absf(2.0 * p - 1.0), 0.5)))
			# 浓墨描边 + 鎏金/黛青笔身：压在任何彩色立绘上都能读清，又不失水墨层次
			var edge := _ribbon_poly(points, widths, 1.0, 1.4)
			var body := _ribbon_poly(points, widths, 1.0)
			_fill_poly(edge, Color(0.20, 0.15, 0.11, 0.40 * fade))
			_fill_poly(body, Color(col.r, col.g, col.b, 0.95 * fade * col.a))
		# 墨点飞溅：4 粒浓墨随斩痕向外轻溅，收笔更快
		var splash := fade * (1.0 - pow(1.0 - grow, 2.0))
		for i in range(4):
			var ang := -PI * 0.75 + float(i) * 0.9
			var dir_s := Vector2(cos(ang), sin(ang))
			var dist := lerpf(7.0, 22.0, splash)
			draw_circle(center + dir_s * dist, lerpf(2.0, 0.7, splash),
				Color(0.20, 0.15, 0.11, 0.45 * fade))

	func _draw_dissolve() -> void:
		var spread := 1.0 + t * 0.6
		for i in range(dots.size()):
			var pos := center + dots[i] * spread
			var r := lerpf(3.0, 7.0, float(i % 3) / 2.0) * (1.0 - t * 0.6)
			draw_circle(pos, r, Color(color, 0.58 * (1.0 - t)))
			draw_circle(pos, r * 1.8, Color(color, 0.10 * (1.0 - t)))

	func _draw_stamp() -> void:
		var s := 15.0 * stamp_scale
		var c := center
		# 残缺方框：四边各留一个缺口
		draw_line(c + Vector2(-s, -s), c + Vector2(-s, s * 0.25), Color(color, 0.86), 2.6, true)
		draw_line(c + Vector2(-s, s * 0.55), c + Vector2(-s, s), Color(color, 0.86), 2.6, true)
		draw_line(c + Vector2(-s, s), c + Vector2(s * 0.35, s), Color(color, 0.86), 2.6, true)
		draw_line(c + Vector2(s * 0.6, s), c + Vector2(s, s), Color(color, 0.86), 2.6, true)
		draw_line(c + Vector2(s, s), c + Vector2(s, -s * 0.2), Color(color, 0.86), 2.6, true)
		draw_line(c + Vector2(s, -s * 0.55), c + Vector2(s, -s), Color(color, 0.86), 2.6, true)
		draw_line(c + Vector2(s, -s), c + Vector2(-s * 0.4, -s), Color(color, 0.86), 2.6, true)
		draw_line(c + Vector2(-s * 0.65, -s), c + Vector2(-s, -s), Color(color, 0.86), 2.6, true)

	## 法宝共鸣：外层玉青弧纹顺时针收束、内层鎏金弧纹逆时针旋转，四枚星芒呼吸微闪。
	## 只做 draw_arc / draw_circle / draw_polygon，不新增节点，移动端开销可控。
	func _draw_artifact() -> void:
		var u := clampf(t, 0.0, 1.0)
		# 合拢量：装备先快后缓（凝练有力），卸下先缓后快（轻散）
		var close := _ease_out_cubic(u) if inward else _ease_in_out_cubic(u)
		var spin := (u if inward else 1.0 - u) * PI * 1.35
		var fade := 1.0 - u * 0.82
		var r_outer := lerpf(31.0, 13.0, close)
		var r_inner := lerpf(24.0, 8.0, close)
		# 外层双弧：玉青灵纹（两段各 100°，绕心旋转）
		for i in range(2):
			var start := spin + PI * float(i)
			draw_arc(center, r_outer, start, start + 1.75, 22,
				Color(INK_JADE_LIGHT, 0.52 * fade), lerpf(3.0, 1.2, close), true)
		# 内层双弧：鎏金灵纹（反向旋转，形成同心对转）
		for i in range(2):
			var start := -spin * 1.35 + PI * float(i) + 0.35
			draw_arc(center, r_inner, start, start + 1.30, 18,
				Color(INK_GOLD, 0.60 * fade), lerpf(2.2, 0.9, close), true)
		# 圆心凝练光点：向内收成一点，向外散作薄晕
		var core := lerpf(6.0, 1.6, close) if inward else lerpf(1.8, 7.6, close)
		draw_circle(center, core * 1.9, Color(INK_GOLD, 0.14 * fade))
		draw_circle(center, core * 0.5, Color(0.99, 0.96, 0.88, 0.72 * fade))
		# 四枚星芒：随灵纹旋转、半径同步收束/扩散，亮度按相位呼吸
		for i in range(4):
			var ang := spin * 1.8 + TAU * float(i) / 4.0
			var dist := lerpf(26.0, 9.0, close) if inward else lerpf(9.0, 27.0, close)
			var pos := center + Vector2(cos(ang), sin(ang)) * dist
			var blink := 0.55 + 0.45 * sin(TAU * 1.6 * u + float(i) * 1.7)
			var length_px := lerpf(5.4, 2.0, close) * blink
			var spark := INK_GOLD if i % 2 == 0 else INK_JADE_LIGHT
			_draw_star4(pos, maxf(1.4, length_px), maxf(0.9, length_px * 0.42), ang,
				Color(spark, 0.85 * fade), Color(1.0, 0.98, 0.92, 0.66 * fade))

	## 「S」朱砂符纹：底层晕染 + 上层饱满朱砂，双层叠画模拟宣纸洇墨
	func _draw_talisman_stroke() -> void:
		if stroke_points.size() < 2:
			return
		var write_u := 1.0
		var fade := 1.0
		var drift := 0.0
		var expand := 1.0
		var hold := 0.0
		if t < STROKE_WRITE_END:
			write_u = _ease_out_cubic(t / STROKE_WRITE_END)
		elif t < STROKE_HOLD_END:
			# 凝符：完整符纹定格，晕染层微幅增亮
			hold = clampf((t - STROKE_WRITE_END) / 0.05, 0.0, 1.0)
		else:
			hold = 1.0
			var p := clampf((t - STROKE_HOLD_END) / (1.0 - STROKE_HOLD_END), 0.0, 1.0)
			fade = 1.0 - p
			drift = -3.0 * p
			expand = 1.0 + 0.04 * p
		_draw_talisman_ribbon(write_u, 1.5,
			Color(color, (0.22 + 0.09 * hold) * fade), drift, expand)
		var tip := _draw_talisman_ribbon(write_u, 0.0, Color(color, 0.92 * fade), drift, expand)
		# 落笔墨点：书写阶段跟随笔尖，收锋即隐
		if write_u < 0.999 and fade > 0.01:
			draw_circle(tip, 2.5, Color(color.lightened(0.18), 0.95 * fade))
			draw_circle(tip, 4.8, Color(color, 0.16 * fade))

	## 按当前书写进度截取丝带多边形；grow 为半宽外扩量（晕染层 +1.5 → 总宽 +3）
	## 返回当前笔尖坐标，供落墨点复用
	func _draw_talisman_ribbon(u_max: float, grow: float, col: Color,
			drift: float, expand: float) -> Vector2:
		var count := stroke_points.size()
		if count < 2 or col.a <= 0.002:
			return center
		var limit := clampf(u_max, 0.0, 1.0) * float(count - 1)
		var last_index := int(floor(limit))
		var left := PackedVector2Array()
		var right := PackedVector2Array()
		for i in range(last_index + 1):
			# 最小半宽 0.25：防止左右顶点重合形成退化多边形（三角化失败红字）
			var half := maxf(0.25, stroke_widths[i] * 0.5 + grow)
			var normal := stroke_normals[i]
			left.append(_xform_point(stroke_points[i] + normal * half, drift, expand))
			right.append(_xform_point(stroke_points[i] - normal * half, drift, expand))
		var tip := _xform_point(stroke_points[last_index], drift, expand)
		# 笔尖落在两个采样点之间时补一个插值顶点，书写前端始终是完整的圆钝笔锋
		if limit > float(last_index) and last_index < count - 1:
			var frac := limit - float(last_index)
			var point := stroke_points[last_index].lerp(stroke_points[last_index + 1], frac)
			var normal := stroke_normals[last_index].lerp(stroke_normals[last_index + 1],
				frac).normalized()
			var half := maxf(0.25,
				lerpf(stroke_widths[last_index], stroke_widths[last_index + 1], frac) \
				* 0.5 + grow)
			tip = _xform_point(point, drift, expand)
			left.append(_xform_point(point + normal * half, drift, expand))
			right.append(_xform_point(point - normal * half, drift, expand))
		var poly := PackedVector2Array()
		poly.append_array(left)
		for i in range(right.size() - 1, -1, -1):
			poly.append(right[i])
		if poly.size() >= 3:
			var colors := PackedColorArray()
			colors.resize(poly.size())
			colors.fill(col)
			draw_polygon(poly, colors)
		return tip

	## 消散阶段的浮散与微扩都围绕符心做，避免整体漂移错位
	func _xform_point(point: Vector2, drift: float, expand: float) -> Vector2:
		return center + (point - center) * expand + Vector2(0.0, drift)

	func _ease_out_cubic(x: float) -> float:
		var inv := 1.0 - clampf(x, 0.0, 1.0)
		return 1.0 - inv * inv * inv

	func _ease_in_out_cubic(x: float) -> float:
		var v := clampf(x, 0.0, 1.0)
		if v < 0.5:
			return 4.0 * v * v * v
		var inv := -2.0 * v + 2.0
		return 1.0 - inv * inv * inv * 0.5

	# ---------------------------------------------------------------- 七门百艺笔触

	## 采药：自底部向上左右分叉的两片柳叶 + 三颗淡翠灵露
	func _draw_skill_herb() -> void:
		# 下限 0.15：t=0 首帧柳叶塌缩成一点时丝带多边形退化，
		# 三角化失败会刷「Invalid polygon data」红字（grow<0.15 实测必失败）
		var grow := maxf(0.15, _ease_out_cubic(clampf(t / 0.62, 0.0, 1.0)))
		var base := center + Vector2(0.0, 13.0)
		for side in [-1.0, 1.0]:
			var tip := base + Vector2(side * 13.0 * grow, -24.0 * grow)
			var leaf := _arc_points(base, tip, Vector2(side * 5.0 * grow, 1.0), 9)
			var widths := PackedFloat32Array()
			for i in range(leaf.size()):
				var u := float(i) / float(leaf.size() - 1)
				# 端点留 0.7px 最小笔宽：宽度为 0 会让丝带首尾顶点重合，
				# 多边形退化 → draw_polygon 报「triangulation failed」
				widths.append(maxf(0.7, sin(PI * u) * 5.4 * (0.45 + 0.55 * grow)))
			_fill_poly(_ribbon_poly(leaf, widths, 1.0, 1.4), Color(SKILL_HERB_LIGHT, 0.20))
			_fill_poly(_ribbon_poly(leaf, widths, 1.0), Color(SKILL_HERB, 0.84))
			draw_polyline(leaf, Color(SKILL_HERB, 0.30), 1.1, true)
		var rise := _ease_out_cubic(clampf(t / 0.75, 0.0, 1.0))
		for i in range(3):
			var pos := base + Vector2(-9.0 + 9.0 * float(i) + sin(t * 7.0 + float(i) * 1.7) * 2.2,
				-4.0 - 26.0 * rise * (0.72 + 0.09 * float(i)))
			draw_circle(pos, 1.5 + 0.25 * float(i), Color(SKILL_HERB_LIGHT, 0.72 * (1.0 - t)))

	## 伐木：左上至右下的弯月斧风 + 四枚木屑碎叶
	func _draw_skill_wood() -> void:
		var sweep := _ease_out_cubic(clampf(t / 0.55, 0.0, 1.0))
		var arc := _arc_points(center + Vector2(-26.0, -20.0), center + Vector2(26.0, 20.0),
			Vector2(0.0, -11.0), 11)
		var widths := PackedFloat32Array()
		for i in range(arc.size()):
			var u := float(i) / float(arc.size() - 1)
			widths.append(0.5 + sin(PI * u) * 4.0)
		_fill_poly(_ribbon_poly(arc, widths, sweep, 3.0), Color(SKILL_WOOD_INK, 0.14))
		_fill_poly(_ribbon_poly(arc, widths, sweep), Color(SKILL_WOOD_INK, 0.86))
		var fly := _ease_out_cubic(clampf((t - 0.18) / 0.62, 0.0, 1.0))
		if fly <= 0.0:
			return
		for i in range(4):
			var idx := clampi(2 + i * 2, 0, arc.size() - 1)
			var dir := (arc[clampi(idx + 1, 0, arc.size() - 1)]
				- arc[clampi(idx - 1, 0, arc.size() - 1)]).normalized()
			var pos := arc[idx] + dir * (18.0 * fly) + Vector2(0.0, 5.0 * fly * fly)
			var size := 3.4 * (1.0 - 0.55 * fly)
			var axis := Vector2(cos(t * 4.0 + float(i) * 0.8), sin(t * 4.0 + float(i) * 0.8))
			var nrm := Vector2(-axis.y, axis.x)
			draw_colored_polygon(PackedVector2Array([
				pos + axis * size, pos + nrm * size * 0.45,
				pos - axis * size, pos - nrm * size * 0.45]),
				Color(SKILL_CHIP, 0.85 * (1.0 - fly * 0.7)))

	## 采矿：右上短促镐击 → 中心四角金石星芒 + 抛石火星
	func _draw_skill_mine() -> void:
		var strike := clampf(t / 0.30, 0.0, 1.0)
		if strike < 1.0:
			var arc := _arc_points(center + Vector2(24.0, -26.0), center + Vector2(3.0, -2.0),
				Vector2(-7.0, -3.0), 7)
			_fill_poly(_ribbon_poly(arc,
				PackedFloat32Array([0.5, 1.6, 3.0, 3.6, 2.8, 1.5, 0.5]),
				_ease_out_cubic(strike)), Color(SKILL_STONE, 0.90))
		var burst := clampf((t - 0.30) / 0.70, 0.0, 1.0)
		if burst <= 0.0:
			return
		var grow := _ease_out_cubic(burst)
		_draw_star4(center, lerpf(6.0, 21.0, grow), lerpf(2.2, 6.6, grow),
			lerpf(-0.45, 0.30, burst), Color(SKILL_STONE, 0.86), Color(SKILL_WARM, 0.85))
		for i in range(4):
			var dir := Vector2(cos(-PI * 0.85 + float(i) * PI * 0.32),
				sin(-PI * 0.85 + float(i) * PI * 0.32))
			var pos := center + dir * (26.0 * grow) + Vector2(0.0, 22.0 * grow * grow)
			draw_circle(pos, lerpf(2.4, 1.1, burst), Color(SKILL_STONE, 0.80 * (1.0 - burst)))
			draw_circle(pos, lerpf(1.4, 0.6, burst), Color(SKILL_WARM, 0.90 * (1.0 - burst)))

	## 炼丹：呼吸扩张的暖金成丹光环 + 双股相位相反灵烟
	func _draw_skill_alchemy() -> void:
		var breathe := 0.5 + 0.5 * sin(TAU * 1.4 * t - PI * 0.5)
		var ring_r := lerpf(9.0, 23.0, _ease_out_cubic(clampf(t / 0.80, 0.0, 1.0)))
		draw_arc(center, ring_r, 0.0, TAU, 36, Color(SKILL_ALCHEMY, 0.26 + 0.20 * breathe),
			lerpf(3.4, 1.0, t), true)
		draw_arc(center, ring_r * 0.72, 0.0, TAU, 28, Color(SKILL_WARM, 0.34 * (1.0 - t)),
			1.2, true)
		var rise := _ease_out_cubic(clampf(t / 0.80, 0.0, 1.0))
		for side in [-1.0, 1.0]:
			var pts := PackedVector2Array()
			var widths := PackedFloat32Array()
			var steps := 12
			for i in range(steps + 1):
				var u := float(i) / float(steps)
				var sway := sin(u * 5.4 + t * 5.0 + (0.0 if side < 0.0 else PI)) * 4.6 * u
				pts.append(center + Vector2(side * (4.0 + sway), lerpf(15.0, -28.0, u)))
				widths.append(lerpf(1.1, 4.3, u) * (1.0 - 0.5 * u))
			_fill_poly(_ribbon_poly(pts, widths, rise, 1.6), Color(SKILL_ALCHEMY, 0.12))
			_fill_poly(_ribbon_poly(pts, widths, rise), Color(SKILL_ALCHEMY, 0.46))

	## 锻造：由粗变细的暗金淬火气浪 + 六道亮金转朱红的火星
	func _draw_skill_forge() -> void:
		var shock := _ease_out_cubic(clampf(t / 0.55, 0.0, 1.0))
		draw_arc(center, lerpf(6.0, 29.0, shock), 0.0, TAU, 40,
			Color(SKILL_FORGE_DARK, 0.55 * (1.0 - shock)), lerpf(5.0, 0.7, shock), true)
		var fly := _ease_out_cubic(clampf(t / 0.70, 0.0, 1.0))
		for i in range(6):
			var dir := Vector2(cos(TAU * float(i) / 6.0 + 0.22), sin(TAU * float(i) / 6.0 + 0.22))
			var head := center + dir * (30.0 * fly)
			var tail := center + dir * (30.0 * fly - lerpf(9.0, 2.0, fly))
			var col := SKILL_EMBER.lerp(SKILL_CINNABAR, fly)
			col.a = 0.92 * (1.0 - fly * 0.85)
			draw_line(tail, head, col, lerpf(2.4, 0.9, fly), true)
			draw_circle(head, lerpf(1.8, 0.7, fly), Color(SKILL_WARM, col.a))

	## 吐纳：左右对称气流相向环绕合拢 + 中心灵波
	func _draw_skill_cultivate() -> void:
		var close := _ease_out_cubic(clampf(t / 0.75, 0.0, 1.0))
		var radius := lerpf(26.0, 16.0, close)
		var spin := lerpf(0.55, 0.0, close)
		for side in [-1.0, 1.0]:
			var pts := PackedVector2Array()
			var widths := PackedFloat32Array()
			var steps := 10
			for i in range(steps + 1):
				var u := float(i) / float(steps)
				# 左弧取 129°~230°，右弧镜像；随 close 相向旋转并收拢半径
				var ang := lerpf(PI * 0.72, PI * 1.28, u) + spin * float(side)
				var px := cos(ang) * radius * (1.0 if float(side) < 0.0 else -1.0)
				pts.append(center + Vector2(px, sin(ang) * radius))
				widths.append(sin(PI * u) * 3.2 + 0.5)
			_fill_poly(_ribbon_poly(pts, widths, 1.0, 2.0), Color(SKILL_HERB_LIGHT, 0.16))
			_fill_poly(_ribbon_poly(pts, widths, 1.0), Color(SKILL_DAI, 0.62))
		if close > 0.72:
			var wave := (close - 0.72) / 0.28
			draw_arc(center, lerpf(4.0, 20.0, _ease_out_cubic(wave)), 0.0, TAU, 30,
				Color(SKILL_DAI, 0.30 * (1.0 - wave)), 2.0, true)

	## 兜底：极淡水墨圆晕
	func _draw_skill_halo() -> void:
		var r := lerpf(6.0, 22.0, _ease_out_cubic(clampf(t / 0.80, 0.0, 1.0)))
		draw_circle(center, r, Color(color, 0.10 * (1.0 - t)))
		draw_arc(center, r, 0.0, TAU, 32, Color(color, 0.34 * (1.0 - t)), 2.2, true)

	## 四角星芒：两层交叉细菱形 + 中心暖白高光
	func _draw_star4(c: Vector2, length_px: float, width_px: float, angle: float,
			col: Color, glow: Color) -> void:
		for k in range(2):
			var a := angle + PI * 0.5 * float(k)
			var dir := Vector2(cos(a), sin(a))
			var nrm := Vector2(-dir.y, dir.x)
			draw_colored_polygon(PackedVector2Array([
				c + dir * length_px, c + nrm * width_px,
				c - dir * length_px, c - nrm * width_px]), col)
		draw_circle(c, maxf(1.4, width_px * 0.5), glow)

	# ---------------------------------------------------------------- 通用几何

	## 二次贝塞尔采样（含首尾）
	func _arc_points(from: Vector2, to: Vector2, bulge: Vector2, count: int) -> PackedVector2Array:
		var pts := PackedVector2Array()
		var ctrl := (from + to) * 0.5 + bulge
		var steps := maxi(2, count)
		for i in range(steps):
			pts.append(_quad_bezier(from, ctrl, to, float(i) / float(steps - 1)))
		return pts

	func _quad_bezier(a: Vector2, c: Vector2, b: Vector2, u: float) -> Vector2:
		var inv := 1.0 - u
		return a * (inv * inv) + c * (2.0 * inv * u) + b * (u * u)

	## 中心线采样点 + 逐点笔宽 → 闭合丝带多边形（左右法线偏移，避免粗线断口）
	func _ribbon_poly(points: PackedVector2Array, widths: PackedFloat32Array, upto: float,
			grow: float = 0.0) -> PackedVector2Array:
		var poly := PackedVector2Array()
		var count := points.size()
		if count < 2 or widths.size() != count:
			return poly
		# 整条丝带塌缩成一点（笔触首帧等）：跳过，退化多边形会让 draw_polygon 报错
		var span := Rect2(points[0], Vector2.ZERO)
		for i in range(1, count):
			span = span.expand(points[i])
		if span.size.x + span.size.y < 3.0:
			return poly
		var limit := clampf(upto, 0.0, 1.0) * float(count - 1)
		var last_index := int(floor(limit))
		var left := PackedVector2Array()
		var right := PackedVector2Array()
		for i in range(last_index + 1):
			var normal := _point_normal(points, count, i)
			# 最小半宽 0.25：保证左右两侧顶点永不重合（退化多边形会三角化失败）
			var half := maxf(0.25, widths[i] * 0.5 + grow)
			left.append(points[i] + normal * half)
			right.append(points[i] - normal * half)
		if limit > float(last_index) and last_index < count - 1:
			var frac := limit - float(last_index)
			var point := points[last_index].lerp(points[last_index + 1], frac)
			var normal := _point_normal(points, count, last_index)
			var half := maxf(0.25,
				lerpf(widths[last_index], widths[last_index + 1], frac) * 0.5 + grow)
			left.append(point + normal * half)
			right.append(point - normal * half)
		poly.append_array(left)
		for i in range(right.size() - 1, -1, -1):
			poly.append(right[i])
		return poly

	func _point_normal(points: PackedVector2Array, count: int, i: int) -> Vector2:
		var tangent := points[mini(count - 1, i + 1)] - points[maxi(0, i - 1)]
		if tangent.length_squared() < 0.000001:
			return Vector2(0.0, 1.0)
		tangent = tangent.normalized()
		return Vector2(-tangent.y, tangent.x)

	func _fill_poly(poly: PackedVector2Array, col: Color) -> void:
		if poly.size() < 3 or col.a <= 0.002:
			return
		var colors := PackedColorArray()
		colors.resize(poly.size())
		colors.fill(col)
		draw_polygon(poly, colors)


func _ready() -> void:
	instance = self
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = Z_INDEX
	_build_pool()


func _exit_tree() -> void:
	if instance == self:
		instance = null


func _build_pool() -> void:
	for i in range(FLOAT_POOL):
		var label := ThemeBuilder.label("", ThemeBuilder.FONT_BODY, ThemeBuilder.COLOR_TEXT)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.visible = false
		add_child(label)
		_floats.append(label)
	for i in range(EFFECT_POOL):
		var effect := InkEffect.new()
		effect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		effect.visible = false
		add_child(effect)
		_effects.append(effect)
	# 居中里程碑横幅：暖墨描金匾额载体（半透深墨宣纸底 + 鎏金描边 + 内嵌朱砂印章），
	# 全链 MOUSE_FILTER_IGNORE，全过程零阻挡点击
	_banner_card = PanelContainer.new()
	_banner_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_card.clip_contents = true
	_banner_card.visible = false
	# 绝对 z=35：压过宽屏常驻左栏(20)/抽屉(30)，仍让位 BottomSheet(40)/弹窗(50)
	_banner_card.z_as_relative = false
	_banner_card.z_index = 35
	_banner_card.anchor_left = 0.5
	_banner_card.anchor_right = 0.5
	_banner_card.anchor_top = 0.0
	_banner_card.anchor_bottom = 0.0
	_banner_card.offset_top = 118.0
	_banner_card.grow_vertical = Control.GROW_DIRECTION_END
	# 全站同源温润白玉宣纸底（0.98 近不透明，杜绝底层标题透字重影）+ 鎏金描边微投影
	var banner_box := ThemeBuilder.panel_box(Color(0.985, 0.972, 0.940, 0.98),
		Color(0.76, 0.56, 0.22, 0.92), 12, 2, 14)
	banner_box.shadow_color = Color(0.25, 0.20, 0.14, 0.14)
	banner_box.shadow_size = 6
	_banner_card.add_theme_stylebox_override("panel", banner_box)
	add_child(_banner_card)
	var banner_row := ThemeBuilder.hbox(12)
	banner_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_row.alignment = BoxContainer.ALIGNMENT_CENTER
	banner_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_banner_card.add_child(banner_row)
	var banner_text := ThemeBuilder.vbox(2)
	banner_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	banner_text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	banner_text.custom_minimum_size = Vector2(0, 0)
	banner_row.add_child(banner_text)
	_banner_title = ThemeBuilder.title_label("", 26)
	_banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_banner_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_banner_title.custom_minimum_size = Vector2(0, 0)
	_banner_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ThemeBuilder.apply_font_size(_banner_title, ThemeBuilder.FONT_CARD_TITLE)
	banner_text.add_child(_banner_title)
	_banner_sub = ThemeBuilder.label("", ThemeBuilder.FONT_CAPTION,
		Color(0.32, 0.28, 0.23, 1.0))
	_banner_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_banner_sub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_banner_sub.custom_minimum_size = Vector2(0, 0)
	_banner_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ThemeBuilder.apply_font_size(_banner_sub, ThemeBuilder.FONT_CAPTION)
	banner_text.add_child(_banner_sub)
	# 朱砂闲章嵌在横幅内部最右垂直居中：26×26 暗朱砂底 + 宣纸白字（动态印文 镇/证/道）
	_banner_seal = PanelContainer.new()
	_banner_seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_seal.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_banner_seal.custom_minimum_size = Vector2(26, 26)
	var seal_box := ThemeBuilder.panel_box(Color(0.72, 0.24, 0.20, 0.90),
		Color(0.72, 0.24, 0.20, 0.90), 4, 0, 2)
	_banner_seal.add_theme_stylebox_override("panel", seal_box)
	_banner_seal_label = ThemeBuilder.label("道", ThemeBuilder.FONT_CAPTION,
		Color(0.98, 0.95, 0.90))
	_banner_seal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_seal_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner_seal_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ThemeBuilder.apply_font_size(_banner_seal_label, ThemeBuilder.FONT_CAPTION)
	_banner_seal.add_child(_banner_seal_label)
	banner_row.add_child(_banner_seal)


func set_enabled(value: bool) -> void:
	_enabled = value
	if not value:
		clear_all()


## 抽屉这类整层遮挡展开时挂起特效：回收在播对象并拒绝新请求，收起后自动恢复
func set_suppressed(value: bool) -> void:
	if suppressed == value:
		return
	suppressed = value
	if value:
		clear_all()


func is_enabled() -> bool:
	if not _enabled or suppressed:
		return false
	return GameState == null or GameState.is_flag("ink_fx", true)


func play_float(global_pos: Vector2, text_value: String, color: Color,
		font_size: int = ThemeBuilder.FONT_BODY, emphasis: bool = false,
		rise: float = -1.0, pop_scale: float = 0.0) -> void:
	if not is_enabled() or not is_visible_in_tree() or text_value.is_empty():
		return
	var node := _next_float()
	node.text = text_value
	ThemeBuilder.apply_font_size(node, font_size)
	node.add_theme_color_override("font_color", color)
	node.add_theme_color_override("font_shadow_color", Color(0.99, 0.97, 0.93, 0.9))
	node.add_theme_constant_override("shadow_offset_x", 1)
	node.add_theme_constant_override("shadow_offset_y", 1)
	node.modulate = Color(1, 1, 1, 1)
	node.visible = true
	node.size = node.get_combined_minimum_size()
	var local := global_pos - get_global_rect().position
	local.x = clampf(local.x, 6.0, maxf(6.0, size.x - node.size.x - 6.0))
	local.y = maxf(local.y, 4.0)
	node.position = local
	node.pivot_offset = node.size * 0.5
	node.scale = Vector2(1.15, 1.15) if emphasis else Vector2.ONE
	# 会心飘字：从放大的落点弹性收束到原尺寸，形成「砸下」的打击感
	if pop_scale > 0.01:
		node.scale = Vector2(pop_scale, pop_scale)
	node.set_meta("ink_active", true)
	var start_y := node.position.y
	var rise_px := FLOAT_RISE if rise <= 0.0 else rise
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(node, "position:y", start_y - rise_px, FLOAT_TIME) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "modulate:a", 0.0, 0.34).set_delay(0.3)
	if pop_scale > 0.01:
		tween.tween_property(node, "scale", Vector2.ONE, 0.24) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(func() -> void: _recycle_float(node))
	node.set_meta("ink_tween", tween)


func play_slash(from_global: Vector2, to_global: Vector2, color: Color) -> void:
	if not is_enabled() or not is_visible_in_tree():
		return
	var offset := get_global_rect().position
	var start := from_global - offset
	var end := to_global - offset
	var mid := (start + end) * 0.5
	var dir := (end - start).normalized()
	# 普攻弧每击不重样：弯度 18~36px、弯形指数 0.84~1.18 各自随机
	var bend := Vector2(-dir.y, dir.x) * randf_range(18.0, 36.0)
	var bend_profile := randf_range(0.84, 1.18)
	var points := PackedVector2Array()
	for i in range(13):
		var p := float(i) / 12.0
		var curve := start.lerp(mid, p).lerp(mid.lerp(end, p), p)
		points.append(curve + bend * pow(sin(PI * p), bend_profile))
	var effect := _next_effect()
	effect.play_slash(points, color)


## 会心一击：三道水墨剑气同出剑锋、同收目标（起止点完全一致），
## 仅靠弯度与弯形拉开层次：上路高扬、主弧居中鎏金加粗、下路低伏，
## 错开 0.025s 依次划出；抵达目标后自动补一道水墨十字斩痕（见 _schedule_crit_mark）。
func play_crit_slash(from_global: Vector2, to_global: Vector2) -> void:
	if not is_enabled() or not is_visible_in_tree():
		return
	var offset := get_global_rect().position
	var start := from_global - offset
	var end := to_global - offset
	var mid := (start + end) * 0.5
	var dir := (end - start).normalized()
	var normal := Vector2(-dir.y, dir.x)
	var arcs: Array = []
	var colors: Array = []
	var widths := PackedFloat32Array([1.55, 0.85, 0.85])
	var delays := PackedFloat32Array([0.0, CRIT_ARC_STAGGER_SEC,
		CRIT_ARC_STAGGER_SEC * 2.0])
	var base_bend := randf_range(20.0, 28.0)
	# 弯度倍率 / 弯形指数：三道差别放到肉眼一望即知，但仍共用同一对起止点
	var factors: Array[float] = [1.0, 1.50, -0.85]
	var profiles: Array[float] = [1.0, 0.85, 1.15]
	for i in range(3):
		var bend := normal * base_bend * factors[i] * randf_range(0.94, 1.06)
		var bend_profile := float(profiles[i])
		var points := PackedVector2Array()
		for k in range(13):
			var p := float(k) / 12.0
			var curve := start.lerp(mid, p).lerp(mid.lerp(end, p), p)
			points.append(curve + bend * pow(sin(PI * p), bend_profile))
		arcs.append(points)
		colors.append(CRIT_GOLD if i == 0 else CRIT_JADE)
	_next_effect().play_crit_slash(arcs, colors, widths, delays)
	_schedule_crit_mark(to_global)


## 目标受击处的水墨十字斩痕（±35° 双锋，0.22s 伸展后淡出）
func play_crit_mark(global_pos: Vector2) -> void:
	if not is_enabled() or not is_visible_in_tree():
		return
	_next_effect().play_crit_mark(global_pos - get_global_rect().position,
		Color(0.99, 0.96, 0.89, 0.96), CRIT_GOLD)


## 剑弧抵达目标的同一瞬间落痕：延后一个运笔时长，避免斩痕先于剑气出现
func _schedule_crit_mark(target_global: Vector2) -> void:
	if not is_inside_tree():
		return
	await get_tree().create_timer(CRIT_ARC_WRITE_SEC).timeout
	if not is_inside_tree() or not is_enabled() or not is_visible_in_tree():
		return
	play_crit_mark(target_global)


func play_splash(global_pos: Vector2, color: Color) -> void:
	if not is_enabled() or not is_visible_in_tree():
		return
	_next_effect().play_splash(global_pos - get_global_rect().position, color)


func play_thunder(from_global: Vector2, to_global: Vector2, color: Color) -> void:
	if not is_enabled() or not is_visible_in_tree():
		return
	var offset := get_global_rect().position
	var start := from_global - offset
	var end := to_global - offset
	var points := PackedVector2Array([start])
	for i in range(1, 7):
		var p := float(i) / 7.0
		points.append(start.lerp(end, p) + Vector2(randf_range(-14.0, 14.0),
			randf_range(-4.0, 4.0)))
	points.append(end)
	_next_effect().play_thunder(points, color)


func play_ring(global_pos: Vector2, color: Color, max_radius: float = 110.0) -> void:
	if not is_enabled() or not is_visible_in_tree():
		return
	_next_effect().play_ring(global_pos - get_global_rect().position, color, max_radius)


func play_smoke(global_pos: Vector2, color: Color = INK_JADE_LIGHT) -> void:
	if not is_enabled() or not is_visible_in_tree():
		return
	_next_effect().play_smoke(global_pos - get_global_rect().position, color)


func play_hammer(global_pos: Vector2, color: Color = INK_JADE,
		spark: Color = INK_GOLD) -> void:
	if not is_enabled() or not is_visible_in_tree():
		return
	_next_effect().play_hammer(global_pos - get_global_rect().position, color, spark)


func play_leaves(global_pos: Vector2, color: Color = INK_JADE) -> void:
	if not is_enabled() or not is_visible_in_tree():
		return
	_next_effect().play_leaves(global_pos - get_global_rect().position, color)


func play_debris(global_pos: Vector2, color: Color = INK_JADE) -> void:
	if not is_enabled() or not is_visible_in_tree():
		return
	_next_effect().play_debris(global_pos - get_global_rect().position, color)


func play_gather(global_pos: Vector2, color: Color = INK_JADE_LIGHT) -> void:
	if not is_enabled() or not is_visible_in_tree():
		return
	_next_effect().play_gather(global_pos - get_global_rect().position, color)


## 百艺完成统一入口：七门技能各走专属样式，未知 / 非百艺回退柔和水墨圆晕。
## 技能 → 样式的映射只在这里维护，调用处（ActionCard._spawn_output_effect）只传 skill_id。
func play_skill_finish(skill_id: String, global_pos: Vector2) -> void:
	if not is_enabled() or not is_visible_in_tree():
		return
	var local := global_pos - get_global_rect().position
	var effect := _next_effect()
	match skill_id:
		"herbalism":
			effect.play_skill_herb(local)
		"woodcutting":
			effect.play_skill_wood(local)
		"mining":
			effect.play_skill_mine(local)
		"alchemy":
			effect.play_skill_alchemy(local)
		"forging":
			effect.play_skill_forge(local)
		"talisman":
			effect.play_talisman_s_stroke(local, INK_CINNABAR)
		"cultivation":
			effect.play_skill_cultivate(local)
		_:
			effect.play_ink_halo(local)


## 制符完成：毛笔书写「S」型朱砂符纹（替代此前的直斜劈砍线段）
func play_talisman(global_pos: Vector2, color: Color = INK_CINNABAR) -> void:
	if not is_enabled() or not is_visible_in_tree():
		return
	_next_effect().play_talisman_s_stroke(global_pos - get_global_rect().position, color)


func play_ripple(global_pos: Vector2, color: Color = INK_JADE_LIGHT) -> void:
	if not is_enabled() or not is_visible_in_tree():
		return
	_next_effect().play_ripple(global_pos - get_global_rect().position, color)


func play_harvest(global_pos: Vector2, color: Color = INK_JADE, width: float = 160.0) -> void:
	if not is_enabled() or not is_visible_in_tree():
		return
	_next_effect().play_harvest(global_pos - get_global_rect().position, color, width)


func play_gold_flow(global_pos: Vector2, color: Color = INK_GOLD) -> void:
	if not is_enabled() or not is_visible_in_tree():
		return
	_next_effect().play_gold_flow(global_pos - get_global_rect().position, color)


func play_cross(global_pos: Vector2, color: Color = INK_JADE) -> void:
	if not is_enabled() or not is_visible_in_tree():
		return
	_next_effect().play_cross(global_pos - get_global_rect().position, color)


func play_dissolve(global_pos: Vector2, color: Color = INK_JADE_LIGHT) -> void:
	if not is_enabled() or not is_visible_in_tree():
		return
	_next_effect().play_dissolve(global_pos - get_global_rect().position, color)


func play_stamp(global_pos: Vector2, color: Color = INK_CINNABAR) -> void:
	if not is_enabled() or not is_visible_in_tree():
		return
	_next_effect().play_stamp(global_pos - get_global_rect().position, color)


## 法宝共鸣：装备（向内凝练，玉青）/ 卸下（向外轻散，鎏金）
func play_artifact_resonance(global_pos: Vector2, equipped: bool = true) -> void:
	if not is_enabled() or not is_visible_in_tree():
		return
	_next_effect().play_artifact(global_pos - get_global_rect().position,
		INK_JADE_LIGHT if equipped else INK_GOLD, equipped)


func play_breakthrough(text_value: String, color: Color = ThemeBuilder.COLOR_AMBER,
		subtitle: String = "", seal_text: String = "道") -> void:
	if not is_enabled() or not is_visible_in_tree():
		return
	var center := get_global_rect().get_center()
	play_ring(center, color, 128.0)
	play_banner(text_value, subtitle, color, seal_text)


## 居中里程碑横幅：0.24s 卷轴舒展（0.88→1 弹性）+ 延迟 0.10s 落印盖章（1.45→1 干脆下压）
## + 停留 1.4s + 0.22s 上浮 10px 淡出。新横幅立即顶替旧横幅不排队；全程零阻挡点击。
func play_banner(text_value: String, subtitle: String = "",
		color: Color = ThemeBuilder.COLOR_AMBER, seal_text: String = "道") -> void:
	if not is_enabled() or not is_visible_in_tree() or text_value.is_empty():
		return
	if _banner_card == null:
		return
	# 动态朱文闲章：镇（镇魔破关）/ 证（证道破境）/ 道（通用）
	_banner_seal_label.text = seal_text if seal_text != "" else "道"
	if _banner_tween != null and _banner_tween.is_valid():
		_banner_tween.kill()
	# 主标题固定沉稳鎏金琥珀（浅宣纸底上清晰雅致；color 仅保留给光圈等外围特效）
	_banner_title.add_theme_color_override("font_color",
		Color(0.58, 0.39, 0.10, 1.0))
	var vp_w := get_viewport().get_visible_rect().size.x
	var max_w := minf(vp_w - 32.0, 460.0)
	var pad_h := 82.0
	ThemeBuilder.fit_wrapped_label(_banner_title, text_value, _banner_card,
		pad_h, max_w)
	if subtitle != "":
		_banner_sub.visible = true
		ThemeBuilder.fit_wrapped_label(_banner_sub, subtitle, null, pad_h, max_w)
	else:
		_banner_sub.visible = false
		_banner_sub.text = ""
		_banner_sub.custom_minimum_size.x = 0.0
	var need_w := _banner_title.custom_minimum_size.x
	if _banner_sub.visible:
		need_w = maxf(need_w, _banner_sub.custom_minimum_size.x)
	_banner_card.custom_minimum_size.x = clampf(need_w + pad_h, 1.0, max_w)
	_banner_card.visible = true
	_banner_card.modulate = Color(1, 1, 1, 1)
	_banner_card.position.y = 118.0
	# 卡片按实测宽度居中；超长句由 fit_wrapped_label 顶到 max_w
	var banner_w := _banner_card.custom_minimum_size.x
	var half_w := banner_w * 0.5
	_banner_card.offset_left = -half_w
	_banner_card.offset_right = half_w
	_banner_card.pivot_offset = Vector2(_banner_card.size.x * 0.5,
		_banner_card.get_combined_minimum_size().y * 0.5)
	_banner_card.scale = Vector2(0.88, 0.88)
	_banner_seal.pivot_offset = _banner_seal.size * 0.5
	_banner_seal.scale = Vector2(1.45, 1.45)
	_banner_seal.modulate = Color(1, 1, 1, 0)
	_banner_tween = create_tween()
	_banner_tween.set_parallel(true)
	_banner_tween.tween_property(_banner_card, "scale", Vector2.ONE, 0.24) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_banner_tween.tween_property(_banner_seal, "scale", Vector2.ONE, 0.12) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(0.10)
	_banner_tween.tween_property(_banner_seal, "modulate:a", 1.0, 0.12) \
		.set_delay(0.10)
	_banner_tween.chain().tween_interval(1.4)
	_banner_tween.chain().tween_property(_banner_card, "position:y", 108.0, 0.22) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_banner_tween.parallel().tween_property(_banner_card, "modulate:a", 0.0, 0.22)
	_banner_tween.chain().tween_callback(_finish_banner)


func clear_floats() -> void:
	for node in _floats:
		if node == null:
			continue
		if node.has_meta("ink_tween"):
			var tween: Variant = node.get_meta("ink_tween")
			if tween is Tween and (tween as Tween).is_valid():
				(tween as Tween).kill()
		node.visible = false
		node.set_meta("ink_active", false)
		node.modulate.a = 1.0


func clear_all() -> void:
	clear_floats()
	for effect in _effects:
		if effect != null:
			effect.reset()
	if _banner_tween != null and _banner_tween.is_valid():
		_banner_tween.kill()
	if _banner_card != null:
		_banner_card.visible = false


func _next_float() -> Label:
	for node in _floats:
		if not bool(node.get_meta("ink_active", false)):
			return node
	var node := _floats[_float_index]
	_float_index = (_float_index + 1) % _floats.size()
	if node.has_meta("ink_tween"):
		var old: Variant = node.get_meta("ink_tween")
		if old is Tween and (old as Tween).is_valid():
			(old as Tween).kill()
	node.set_meta("ink_active", false)
	node.visible = false
	return node


func _next_effect() -> InkEffect:
	for effect in _effects:
		if not effect.visible:
			return effect
	var effect := _effects[_effect_index]
	_effect_index = (_effect_index + 1) % _effects.size()
	effect.reset()
	return effect


func _recycle_float(node: Label) -> void:
	if node == null:
		return
	node.visible = false
	node.modulate.a = 1.0
	node.set_meta("ink_active", false)


func _finish_banner() -> void:
	if _banner_card != null:
		_banner_card.visible = false
		_banner_card.modulate.a = 1.0
		_banner_card.scale = Vector2.ONE
