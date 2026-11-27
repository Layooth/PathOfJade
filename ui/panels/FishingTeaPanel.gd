extends Control

## 灵潭清茗：灵潭垂钓与洞府烹茶双页签界面。
## 不声明 class_name：由 MainShell 以 preload 加载，确保 PCK 单发也能生效。

## 单节点轻量灵潭舞台：纯 _draw，无粒子无 Shader，只在灵潭页可见时逐帧重绘。
class TeaPondStage extends Control:
	const SKY_TOP := Color("#F5F0E4")
	const SKY_BOTTOM := Color("#DCEAE6")
	const WATER_TOP := Color("#BFDED7")
	const WATER_BOTTOM := Color("#5F9E92")
	const INK := Color(0.20, 0.24, 0.23, 1.0)
	const INK_SOFT := Color(0.28, 0.34, 0.32, 0.55)
	const BAMBOO := Color("#3E6B58")
	const BAMBOO_LIGHT := Color("#7DAF8E")
	const GOLD := Color("#C9A45C")
	const JADE := Color("#3C8C78")
	const RED := Color("#B4483D")

	## 四段式动画相位：剩余 >2.2s 巡游 / 2.2~0.6s 试探点漂 / <0.6s 沉漂扬竿
	const PHASE_NIBBLE: float = 0.8167
	const PHASE_STRIKE: float = 0.95

	var fishing_active: bool = false
	var progress: float = 0.0
	var _time: float = 0.0
	var _flash_left: float = 0.0
	var _catch_text: String = ""
	var _catch_left: float = 0.0
	var _catch_color: Color = Color("#3C8C78")
	var _fill_style: StyleBoxFlat
	var _border_style: StyleBoxFlat

	func _ready() -> void:
		_fill_style = ThemeBuilder.panel_box(Color("#F5F0E4"), Color(0, 0, 0, 0), 12, 0, 0)
		_border_style = ThemeBuilder.panel_box(Color(0, 0, 0, 0),
			Color(0.36, 0.32, 0.26, 0.32), 12, 1, 0)
		set_process(true)

	func _process(delta: float) -> void:
		if not is_visible_in_tree():
			return
		# 歇息时也保留水波与游鱼，仅放慢节奏；垂钓时回到完整灵动状态
		_time += delta
		_flash_left = maxf(0.0, _flash_left - delta)
		_catch_left = maxf(0.0, _catch_left - delta)
		queue_redraw()

	func show_catch(text_value: String) -> void:
		if text_value == "":
			return
		_catch_text = text_value
		_catch_left = 0.9
		_flash_left = 0.6
		_catch_color = _catch_color_for(text_value)
		queue_redraw()


	## 收获纪要文本 → 灵鱼主题色（水花与跃起剪影取同色）
	func _catch_color_for(text_value: String) -> Color:
		if text_value.contains("金髓"):
			return Color("#C9A24B")
		if text_value.contains("寒潭") or text_value.contains("银鳗"):
			return Color("#8FB9C4")
		if text_value.contains("赤鳞") or text_value.contains("火鲤"):
			return Color("#C4573B")
		if text_value.contains("碧波"):
			return Color("#3C8C78")
		if text_value.contains("青纹"):
			return Color("#5C8F7E")
		return Color("#3C8C78")

	func _draw() -> void:
		if _fill_style == null:
			_ready()
		var rect := Rect2(Vector2.ZERO, size)
		draw_style_box(_fill_style, rect)
		var inner := Rect2(Vector2(7, 6), size - Vector2(14, 12))
		var water_y := inner.position.y + inner.size.y * 0.44
		_draw_sky(inner, water_y)
		_draw_mountains(inner, water_y)
		_draw_water(inner, water_y)
		_draw_lotus(inner, water_y)
		_draw_fish(inner, water_y)
		_draw_reeds(inner)
		_draw_bank(inner, water_y)
		if fishing_active:
			_draw_rod_and_line(inner, water_y)
		else:
			_draw_resting_rod(inner)
		_draw_strike_splash(inner, water_y)
		_draw_catch_text(inner)
		draw_style_box(_border_style, rect)

	func _draw_sky(inner: Rect2, water_y: float) -> void:
		var height := maxf(1.0, water_y - inner.position.y)
		var strips := 18
		for i in range(strips):
			var t := float(i) / float(strips - 1)
			var color := SKY_TOP.lerp(SKY_BOTTOM, t)
			var y := inner.position.y + height * t
			draw_rect(Rect2(inner.position.x, y, inner.size.x, height / strips + 1.0), color)
		# 飘渺水雾：两条极淡的横向雾带
		for i in range(2):
			var mist_y := inner.position.y + height * (0.48 + 0.12 * float(i)) \
				+ sin(_time * 0.22 + float(i)) * 2.0
			draw_line(Vector2(inner.position.x + 12.0, mist_y),
				Vector2(inner.end.x - 12.0, mist_y),
				Color(1.0, 1.0, 1.0, 0.18 - 0.04 * float(i)), 5.0, true)

	## 三层错落淡墨山脊 + 山脚飘动宣纸薄雾带
	func _draw_mountains(inner: Rect2, water_y: float) -> void:
		var base := water_y + 1.0
		var layers := [
			{"heights": [0.30, 0.52, 0.34, 0.44, 0.26, 0.38], "color": Color(0.33, 0.40, 0.37, 0.10)},
			{"heights": [0.22, 0.38, 0.20, 0.34, 0.16, 0.28], "color": Color(0.29, 0.36, 0.33, 0.13)},
			{"heights": [0.12, 0.20, 0.08, 0.18, 0.06, 0.14], "color": Color(0.22, 0.29, 0.26, 0.17)},
		]
		for layer in layers:
			var heights: Array = layer["heights"]
			var poly := PackedVector2Array([Vector2(inner.position.x, base)])
			var count := heights.size()
			for i in range(count):
				var t := float(i + 1) / float(count + 1)
				var h := float(heights[i]) * inner.size.y * 0.42
				poly.append(Vector2(inner.position.x + inner.size.x * t, base - h))
			poly.append(Vector2(inner.end.x, base - 6.0))
			poly.append(Vector2(inner.end.x, base))
			draw_colored_polygon(poly, layer["color"])
		# 山脚薄雾：两条横向缓动半透明雾带
		for i in range(2):
			var fog_y := base - 10.0 - float(i) * 7.0 + sin(_time * 0.35 + float(i) * 1.7) * 2.0
			var x_off := fmod(_time * (5.0 + float(i) * 3.0), 40.0)
			draw_line(Vector2(inner.position.x + x_off * 0.5, fog_y),
				Vector2(inner.end.x - 10.0 + x_off * 0.3, fog_y),
				Color(1.0, 1.0, 1.0, 0.20 - 0.06 * float(i)), 7.0 - 2.0 * float(i), true)
		draw_line(Vector2(inner.position.x, base), Vector2(inner.end.x, base),
			Color(0.24, 0.32, 0.28, 0.30), 1.0, true)

	func _draw_water(inner: Rect2, water_y: float) -> void:
		var height := maxf(1.0, inner.end.y - water_y)
		var strips := 20
		for i in range(strips):
			var t := float(i) / float(strips - 1)
			var color := WATER_TOP.lerp(WATER_BOTTOM, t)
			var y := water_y + height * t
			draw_rect(Rect2(inner.position.x, y, inner.size.x, height / strips + 1.0), color)
		# 错落水波：细墨横纹，随呼吸缓慢偏移
		for i in range(7):
			var y := water_y + height * (0.12 + 0.11 * float(i)) \
				+ sin(_time * 0.65 + float(i) * 1.3) * 1.6
			var x0 := inner.position.x + 12.0 + fmod(float(i) * 27.0, 44.0)
			var x1 := inner.end.x - 14.0 - fmod(float(i) * 19.0, 38.0)
			draw_line(Vector2(x0, y), Vector2(x1, y),
				Color(0.10, 0.31, 0.27, 0.13), 1.0, true)
		# 天光反光斑：柔和椭圆随波轻晃
		for i in range(5):
			var gx := inner.position.x + inner.size.x * (0.14 + 0.17 * float(i)) \
				+ sin(_time * 0.5 + float(i) * 1.4) * 5.0
			var gy := water_y + height * (0.16 + 0.12 * float(i % 3))
			var glow := 0.10 + 0.05 * sin(_time * 1.1 + float(i) * 2.0)
			draw_colored_polygon(_ellipse_points(Vector2(gx, gy),
				14.0 + 3.0 * float(i % 2), 2.6, 14),
				Color(1.0, 1.0, 0.96, maxf(0.03, glow)))
		# 错落高光细波纹
		for i in range(9):
			var wy := water_y + height * (0.08 + 0.095 * float(i))
			var wx := inner.position.x + 10.0 \
				+ fmod(_time * 9.0 + float(i) * 43.0, inner.size.x - 30.0)
			draw_line(Vector2(wx, wy), Vector2(wx + 12.0 + 6.0 * float(i % 3), wy),
				Color(1.0, 1.0, 0.97, 0.16), 0.9, true)
		# 荷叶荷花投影倒影（右下浅影）
		var lotus_y := water_y + height * 0.52
		for i in range(3):
			var cx := inner.end.x - 48.0 - float(i) * 22.0
			draw_colored_polygon(_ellipse_points(Vector2(cx, lotus_y + 14.0 + float(i) * 8.0),
				16.0 + 4.0 * float(i % 2), 4.0, 12), Color(0.14, 0.30, 0.25, 0.14))
		# 岸边浅水墨线
		draw_line(Vector2(inner.position.x + 4.0, water_y),
			Vector2(inner.end.x - 4.0, water_y),
			Color(0.18, 0.40, 0.34, 0.22), 1.2, true)

	## 水下多鱼影：小灵鲫 / 中青鱼 / 修长银鳗 + 偶游淡金龙鱼，带胸鳍与正弦摆尾
	func _draw_fish(inner: Rect2, water_y: float) -> void:
		var height := maxf(1.0, inner.end.y - water_y)
		var speed_mult := 0.75 if not fishing_active else 1.0
		var defs := [
			{"scale": 0.72, "speed": 0.085, "y": 0.26, "stretch": 1.0, "tail": 1.0,
				"color": Color(0.16, 0.33, 0.29, 0.26)},
			{"scale": 1.02, "speed": 0.115, "y": 0.44, "stretch": 1.3, "tail": 1.15,
				"color": Color(0.11, 0.26, 0.24, 0.30)},
			{"scale": 0.92, "speed": 0.07, "y": 0.63, "stretch": 2.4, "tail": 0.55,
				"color": Color(0.20, 0.37, 0.42, 0.22)},
		]
		var nibble := fishing_active and progress >= PHASE_NIBBLE and progress < PHASE_STRIKE
		var strike := fishing_active and progress >= PHASE_STRIKE
		for i in range(defs.size()):
			var def: Dictionary = defs[i]
			var speed := float(def["speed"]) * speed_mult
			var cycle := fmod(_time * speed + float(i) * 0.33, 2.0)
			var t := cycle if cycle < 1.0 else 2.0 - cycle
			var x := inner.position.x + inner.size.x * (0.10 + t * 0.76)
			var y := water_y + height * float(def["y"]) \
				+ sin(_time * 0.9 + float(i) * 1.8) * 3.6
			var dir := 1.0 if cycle < 1.0 else -1.0
			if (nibble or strike) and i == 1:
				var bob := _bobber_pos(inner, water_y)
				var approach := 0.74 if nibble else 0.92
				x = lerpf(x, bob.x - 16.0, approach)
				y = lerpf(y, bob.y + 7.0, approach)
				dir = 1.0
			_draw_fish_shape(Vector2(x, y), float(def["scale"]), dir,
				float(def["stretch"]), float(def["tail"]), def["color"])
		# 稀客：淡金尾龙鱼每 26 秒巡游 7 秒
		var dragon_t := fmod(_time, 26.0)
		if dragon_t < 7.0:
			var dt := dragon_t / 7.0
			var dx := inner.position.x + inner.size.x * (0.08 + dt * 0.84)
			var dy := water_y + height * 0.36 + sin(_time * 0.7) * 2.4
			_draw_fish_shape(Vector2(dx, dy), 1.08, 1.0, 1.55, 1.6,
				Color(0.55, 0.44, 0.20, 0.26))

	## 水墨鱼影：拉伸鱼身 + 正弦摆尾 + 背鳍/胸鳍
	func _draw_fish_shape(pos: Vector2, scale: float, dir: float, stretch: float,
			tail_len: float, color: Color) -> void:
		var sway := sin(_time * 6.0 + pos.x * 0.05) * 0.35
		var body_len := 9.0 * scale * stretch
		var body_h := 3.6 * scale + 0.6
		var body := PackedVector2Array([
			pos + Vector2(-body_len, 0.0),
			pos + Vector2(-body_len * 0.45, -body_h),
			pos + Vector2(body_len * 0.55, -body_h * 0.82),
			pos + Vector2(body_len, 0.0),
			pos + Vector2(body_len * 0.55, body_h * 0.82),
			pos + Vector2(-body_len * 0.45, body_h),
		])
		draw_colored_polygon(body, color)
		# 尾鳍：正弦摆动
		var tail_base := pos + Vector2(-body_len * dir, 0.0)
		draw_colored_polygon(PackedVector2Array([
			tail_base,
			tail_base + Vector2(-9.0 * tail_len * dir, -4.4 + sway * 4.0),
			tail_base + Vector2(-7.0 * tail_len * dir, 0.0),
			tail_base + Vector2(-9.0 * tail_len * dir, 4.4 + sway * 4.0),
		]), Color(color.r, color.g, color.b, color.a * 0.92))
		# 背鳍
		draw_colored_polygon(PackedVector2Array([
			pos + Vector2(-2.0, -body_h * 0.9),
			pos + Vector2(2.5, -body_h * 1.8),
			pos + Vector2(5.5, -body_h * 0.8),
		]), Color(color.r, color.g, color.b, color.a * 0.8))
		# 胸鳍（摆尾相位偏移）
		var fin := sin(_time * 6.0 + pos.x * 0.05 + 1.2) * 1.6
		draw_colored_polygon(PackedVector2Array([
			pos + Vector2(-1.0, body_h * 0.5),
			pos + Vector2(-5.0 * dir, body_h * 0.9 + fin),
			pos + Vector2(1.5 * dir, body_h * 0.75),
		]), Color(color.r, color.g, color.b, color.a * 0.7))
		# 目
		draw_circle(pos + Vector2(body_len * 0.62 * dir, -0.8 * scale),
			0.85 * scale, Color(0.05, 0.12, 0.11, minf(1.0, color.a * 5.0)))

	func _draw_lotus(inner: Rect2, water_y: float) -> void:
		var base_y := water_y + (inner.end.y - water_y) * 0.52
		var leaf_centers := [
			Vector2(inner.end.x - 48.0, base_y + 10.0),
			Vector2(inner.end.x - 78.0, base_y + 25.0),
			Vector2(inner.end.x - 34.0, base_y + 31.0),
		]
		for i in range(leaf_centers.size()):
			var center: Vector2 = leaf_centers[i]
			var rx := 22.0 + 4.0 * float(i % 2)
			var ry := 8.0 + 2.0 * float(i % 2)
			var leaf := _ellipse_points(center, rx, ry, 24)
			draw_colored_polygon(leaf, Color(0.22, 0.47, 0.38, 0.58))
			for v in range(5):
				var angle := -0.85 + 0.42 * float(v)
				draw_line(center, center + Vector2(cos(angle), sin(angle)) * Vector2(rx, ry) * 0.72,
					Color(0.14, 0.34, 0.28, 0.42), 0.9, true)
		var flower := Vector2(inner.end.x - 58.0, base_y - 8.0)
		for p in range(5):
			var a := -PI * 0.5 + (float(p) - 2.0) * 0.38
			var petal := PackedVector2Array([
				flower,
				flower + Vector2(cos(a - 0.16), sin(a - 0.16)) * 8.0,
				flower + Vector2(cos(a), sin(a)) * 16.0,
				flower + Vector2(cos(a + 0.16), sin(a + 0.16)) * 8.0,
			])
			draw_colored_polygon(petal, Color(0.94, 0.79, 0.72, 0.86))
		draw_circle(flower, 3.2, Color(0.84, 0.64, 0.28, 0.95))

	func _draw_reeds(inner: Rect2) -> void:
		var base := inner.end.y - 4.0
		for i in range(3):
			var x := inner.end.x - 12.0 - float(i) * 9.0
			var top := Vector2(x - 8.0 - float(i) * 3.0, base - 54.0 - float(i) * 8.0)
			draw_line(Vector2(x, base), top, Color(0.18, 0.31, 0.25, 0.60),
				1.2 + 0.2 * float(i), true)
			for j in range(3):
				var y := lerpf(base, top.y, 0.35 + 0.18 * float(j))
				var dir := -1.0 if j % 2 == 0 else 1.0
				draw_line(Vector2(x, y), Vector2(x + dir * (8.0 + float(j) * 2.0), y - 5.0),
					Color(0.18, 0.31, 0.25, 0.45), 1.0, true)
			draw_circle(top, 2.0, Color(0.30, 0.27, 0.20, 0.45))

	## 弹性青竹钓竿（三次贝塞尔）+ 竹节高光 + 呼吸微颤 + 扬竿大弧度弯竿
	func _draw_rod_and_line(inner: Rect2, water_y: float) -> void:
		var nibble := progress >= PHASE_NIBBLE and progress < PHASE_STRIKE
		var strike := progress >= PHASE_STRIKE
		var breath := sin(_time * 1.6) * 1.3
		var bend := 14.0 + (6.0 if nibble else 0.0) + (44.0 if strike else 0.0)
		var grip := Vector2(inner.position.x + 12.0, inner.end.y - 4.0)
		var tip_base := Vector2(inner.position.x + inner.size.x * 0.58,
			inner.position.y + inner.size.y * 0.15)
		var c1 := grip + Vector2(inner.size.x * 0.17, -inner.size.y * 0.30)
		var c2 := tip_base + Vector2(-inner.size.x * 0.15,
			-inner.size.y * 0.04 + bend * 0.5)
		var tip := tip_base + Vector2(sin(_time * 3.0) * breath * 0.4,
			breath + (sin(_time * 24.0) * 1.6 if nibble else 0.0)
			+ (bend * 0.8 if strike else 0.0))
		var rod := PackedVector2Array()
		for i in range(22):
			rod.append(_cubic_point(grip, c1, c2, tip, float(i) / 21.0))
		draw_polyline(rod, Color(0.17, 0.27, 0.22, 0.95), 7.5, true)
		draw_polyline(rod, BAMBOO, 4.6, true)
		draw_polyline(rod, Color(BAMBOO_LIGHT.r, BAMBOO_LIGHT.g, BAMBOO_LIGHT.b, 0.55),
			1.5, true)
		for t in [0.12, 0.26, 0.40, 0.54, 0.68, 0.82]:
			var p := _cubic_point(grip, c1, c2, tip, float(t))
			draw_circle(p, 2.2 - float(t) * 0.7, Color(0.12, 0.23, 0.17, 0.92))
			draw_circle(p + Vector2(-0.6, -0.7), 0.8, Color(0.72, 0.86, 0.72, 0.75))
		var bob := _bobber_pos(inner, water_y)
		# 鱼线：巡游垂弧 → 试探轻晃 → 扬竿绷直
		var slack := 14.0 + (5.0 if nibble else 0.0)
		if strike:
			slack = 0.5
		var mid := (tip + bob) * 0.5 + Vector2(0, slack)
		var line := PackedVector2Array()
		for i in range(18):
			line.append(_quad_point(tip, mid, bob, float(i) / 17.0))
		draw_polyline(line, Color(0.22, 0.26, 0.24, 0.55), 1.0, true)
		_draw_bobber(bob, nibble, strike)
		_draw_bobber_ripples(bob, nibble)

	func _draw_resting_rod(inner: Rect2) -> void:
		# 歇息时钓竿静置钓台上，竿梢微翘
		var a := Vector2(inner.position.x + 16.0, inner.end.y - 16.0)
		var b := Vector2(inner.position.x + 92.0, inner.end.y - 40.0)
		var c := Vector2(inner.position.x + 120.0, inner.end.y - 56.0)
		var rod := PackedVector2Array()
		for i in range(14):
			rod.append(_quad_point(a, b, c, float(i) / 13.0))
		draw_polyline(rod, Color(0.17, 0.27, 0.22, 0.92), 6.0, true)
		draw_polyline(rod, BAMBOO, 3.4, true)
		for t in [0.22, 0.46, 0.70]:
			draw_circle(_quad_point(a, b, c, float(t)), 1.8, Color(0.12, 0.23, 0.17, 0.9))
		draw_circle(c, 2.2, GOLD)

	## 四段式浮漂：悠闲轻晃 → 急促轻点 → 猛然下沉
	func _bobber_pos(inner: Rect2, water_y: float) -> Vector2:
		var height := maxf(1.0, inner.end.y - water_y)
		var bob_y := water_y + height * 0.24 + sin(_time * 2.3) * 2.2
		if fishing_active:
			if progress >= PHASE_STRIKE:
				bob_y += height * 0.15 + sin(_time * 18.0) * 1.2
			elif progress >= PHASE_NIBBLE:
				bob_y += absf(sin(_time * 3.6)) * 3.4
		return Vector2(inner.position.x + inner.size.x * 0.62, bob_y)

	func _draw_bobber(bob: Vector2, nibble: bool, strike: bool) -> void:
		if not strike:
			draw_set_transform(bob, 0.0, Vector2(1.0, 0.55))
			draw_circle(Vector2(0, 4), 6.0, Color(0.10, 0.25, 0.22, 0.18))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_circle(bob, 5.2, Color("#F4EEE0"))
		draw_circle(bob + Vector2(0, -2.0), 3.8, RED)
		draw_line(bob + Vector2(-4.0, 0.6), bob + Vector2(4.0, 0.6),
			Color(0.82, 0.68, 0.36, 0.95), 1.2, true)
		draw_circle(bob + Vector2(-1.2, -3.0), 1.0, Color(1, 1, 1, 0.72))
		if nibble:
			draw_arc(bob, 8.0 + sin(_time * 18.0) * 1.2, 0.0, TAU, 18,
				Color(0.24, 0.55, 0.47, 0.45), 1.0, true)

	func _draw_bobber_ripples(bob: Vector2, nibble: bool) -> void:
		if nibble:
			# 试探：紧凑同心涟漪 2~3 圈
			for i in range(3):
				var radius := 6.0 + fmod(_time * 16.0 + float(i) * 6.0, 16.0)
				var alpha := 0.26 * (1.0 - radius / 24.0)
				draw_arc(bob + Vector2(0, 3), radius, 0.0, TAU, 20,
					Color(0.19, 0.48, 0.41, maxf(0.0, alpha)), 1.0, true)
		if _flash_left > 0.0:
			var t := 1.0 - _flash_left / 0.6
			for i in range(2):
				draw_arc(bob + Vector2(0, 2), 10.0 + t * 44.0 + float(i) * 7.0,
					0.0, TAU, 32,
					Color(_catch_color.r, _catch_color.g, _catch_color.b,
						_flash_left / 0.6 * (0.7 - 0.25 * float(i))),
					1.6, true)
			for i in range(6):
				var a := TAU * float(i) / 6.0 + _time * 0.8
				var p := bob + Vector2(cos(a), sin(a)) * (8.0 + t * 18.0)
				draw_circle(p, 1.2, Color(0.90, 0.96, 0.90, _flash_left / 0.6 * 0.8))

	## 左下青石钓台 + 苔石 + 垂柳剪影（钓竿自岸边探出的落点）
	func _draw_bank(inner: Rect2, _water_y: float) -> void:
		var base_y := inner.end.y
		# 青石钓台
		draw_colored_polygon(PackedVector2Array([
			Vector2(inner.position.x, base_y),
			Vector2(inner.position.x, base_y - 26.0),
			Vector2(inner.position.x + 46.0, base_y - 30.0),
			Vector2(inner.position.x + 74.0, base_y - 14.0),
			Vector2(inner.position.x + 62.0, base_y),
		]), Color(0.40, 0.42, 0.38, 0.90))
		draw_polyline(PackedVector2Array([
			Vector2(inner.position.x, base_y - 26.0),
			Vector2(inner.position.x + 46.0, base_y - 30.0),
			Vector2(inner.position.x + 74.0, base_y - 14.0),
		]), Color(0.26, 0.28, 0.25, 0.85), 1.4, true)
		# 苔石两枚
		for i in range(2):
			var rock := Vector2(inner.position.x + 52.0 + float(i) * 22.0,
				base_y - 6.0 - float(i) * 3.0)
			draw_colored_polygon(_ellipse_points(rock, 11.0 - float(i), 6.0, 12),
				Color(0.34, 0.37, 0.33, 0.85))
			draw_colored_polygon(_ellipse_points(rock + Vector2(-2.0, -3.0),
				6.0, 2.6, 10), Color(0.42, 0.55, 0.40, 0.55))
		# 垂柳：主干 + 三条随风轻摆的柳枝
		var trunk_base := Vector2(inner.position.x + 6.0, inner.position.y + 4.0)
		draw_line(trunk_base, trunk_base + Vector2(10.0, 26.0),
			Color(0.30, 0.26, 0.20, 0.75), 2.4, true)
		for i in range(3):
			var strand_x := trunk_base.x + 8.0 + float(i) * 7.0
			var sway := sin(_time * 0.9 + float(i) * 1.3) * 3.2
			var start := Vector2(strand_x + 4.0, trunk_base.y + 8.0 + float(i) * 4.0)
			var pts := PackedVector2Array()
			for k in range(6):
				var t := float(k) / 5.0
				pts.append(start + Vector2(sway * t * t, t * 30.0))
			draw_polyline(pts, Color(0.26, 0.42, 0.30, 0.60), 1.2, true)
			for leaf_i in range(3):
				var lp := start + Vector2(sway * 0.8, 10.0 + float(leaf_i) * 8.0)
				draw_line(lp, lp + Vector2(-3.0 + float(leaf_i % 2) * 6.0, 5.0),
					Color(0.26, 0.44, 0.32, 0.55), 1.0, true)

	## 收竿瞬间：翠玉灵光水花 + 弧形水滴 + 对应鱼色的灵鱼剪影跃出水面
	func _draw_strike_splash(inner: Rect2, water_y: float) -> void:
		if _flash_left <= 0.0:
			return
		var t := 1.0 - _flash_left / 0.6
		var bob := _bobber_pos(inner, water_y)
		# 弧形水滴
		for i in range(4):
			var a := -PI * 0.5 + (float(i) - 1.5) * 0.42
			var dist := 8.0 + t * 26.0
			var p := bob + Vector2(cos(a), sin(a)) * dist + Vector2(0, t * 8.0)
			draw_circle(p, 1.5 - float(i) * 0.2,
				Color(0.72, 0.92, 0.82, _flash_left / 0.6 * 0.7))
		# 灵鱼剪影跃出（抛物线，一瞬后消散）
		var leap := sin(t * PI)
		if leap > 0.05:
			var fish_pos := bob + Vector2(6.0, 6.0) - Vector2(0, leap * 26.0)
			draw_colored_polygon(PackedVector2Array([
				fish_pos + Vector2(-10.0, 0.0),
				fish_pos + Vector2(-4.0, -4.0),
				fish_pos + Vector2(8.0, -2.0),
				fish_pos + Vector2(10.0, 0.0),
				fish_pos + Vector2(8.0, 2.0),
				fish_pos + Vector2(-4.0, 4.0),
			]), Color(_catch_color.r, _catch_color.g, _catch_color.b,
				_flash_left / 0.6 * 0.85))
			draw_colored_polygon(PackedVector2Array([
				fish_pos + Vector2(-10.0, 0.0),
				fish_pos + Vector2(-18.0, -5.0),
				fish_pos + Vector2(-16.0, 5.0),
			]), Color(_catch_color.r, _catch_color.g, _catch_color.b,
				_flash_left / 0.6 * 0.6))

	func _cubic_point(a: Vector2, b: Vector2, c: Vector2, d: Vector2,
			t: float) -> Vector2:
		var inv := 1.0 - t
		return a * inv * inv * inv + b * 3.0 * inv * inv * t \
			+ c * 3.0 * inv * t * t + d * t * t * t

	func _draw_catch_text(inner: Rect2) -> void:
		if _catch_left <= 0.0 or _catch_text == "":
			return
		var alpha := clampf(_catch_left / 0.9, 0.0, 1.0)
		var y := inner.end.y - 16.0 - (0.9 - _catch_left) * 20.0
		draw_string(ThemeBuilder.make_font(), Vector2(inner.position.x + 8.0, y),
			_catch_text, HORIZONTAL_ALIGNMENT_CENTER, inner.size.x - 16.0,
			ThemeBuilder.scaled_font_size(ThemeBuilder.FONT_CAPTION),
			Color(0.72, 0.55, 0.22, alpha))

	func _quad_point(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
		var inv := 1.0 - t
		return a * inv * inv + b * 2.0 * inv * t + c * t * t

	func _ellipse_points(center: Vector2, rx: float, ry: float, segments: int) -> PackedVector2Array:
		var points := PackedVector2Array()
		for i in range(segments):
			var angle := TAU * float(i) / float(segments)
			points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
		return points

## 洞府烹茶小舞台：纯 _draw 水墨茶壶 / 茶盏 / 茶烟，内嵌 3 秒 ProgressBar。
class TeaBrewStage extends Control:
	const PAPER := Color("#F6F0E4")
	const INK := Color(0.22, 0.27, 0.24)
	const JADE := Color("#4E8C78")
	const AMBER := Color("#C98434")
	const SMOKE := Color(0.42, 0.58, 0.52)

	var brewing: bool = false
	var progress: float = 0.0
	var remaining: float = 0.0
	var brew_name: String = ""
	var active_name: String = ""
	var active_remain: float = 0.0
	var _time: float = 0.0
	var _finish_left: float = 0.0
	var _bar: ProgressBar
	var _bg: StyleBoxFlat
	var _border: StyleBoxFlat

	func _ready() -> void:
		custom_minimum_size = Vector2(0, 84)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_bg = ThemeBuilder.panel_box(PAPER, Color(0, 0, 0, 0), 10, 0, 0)
		_border = ThemeBuilder.panel_box(Color(0, 0, 0, 0),
			Color(0.42, 0.36, 0.27, 0.26), 10, 1, 0)
		_bar = ThemeBuilder.progress_bar_run(4.0)
		_bar.max_value = 1.0
		_bar.step = 0.0
		_bar.visible = false
		add_child(_bar)
		resized.connect(_layout_bar)
		_layout_bar()
		set_process(true)

	func _layout_bar() -> void:
		if _bar == null:
			return
		_bar.position = Vector2(142.0, maxf(60.0, size.y - 12.0))
		_bar.size = Vector2(maxf(40.0, size.x - 154.0), 4.0)

	func _process(delta: float) -> void:
		if not is_visible_in_tree():
			return
		_time += delta
		_finish_left = maxf(0.0, _finish_left - delta)
		_bar.visible = brewing
		_bar.value = clampf(progress, 0.0, 1.0)
		queue_redraw()

	func trigger_finish() -> void:
		_finish_left = 0.85
		queue_redraw()

	func _draw() -> void:
		draw_style_box(_bg, Rect2(Vector2.ZERO, size))
		var pot := Vector2(54.0, size.y * 0.58)
		var cup := Vector2(108.0, size.y * 0.72)
		if brewing:
			for i in range(4):
				var pulse := sin(_time * 4.2 + float(i) * 0.7) * 0.5 + 0.5
				draw_circle(Vector2(pot.x, pot.y + 18.0),
					18.0 + float(i) * 7.0 + pulse * 2.0,
					Color(AMBER.r, AMBER.g, AMBER.b, 0.035 + 0.025 * pulse))
		_draw_pot(pot, cup)
		_draw_smoke(Vector2(pot.x + 17.0, pot.y - 14.0))
		_draw_text()
		if _finish_left > 0.0:
			var t := 1.0 - _finish_left / 0.85
			for i in range(2):
				draw_arc(cup, 5.0 + t * 24.0 + float(i) * 5.0, 0.0, TAU, 28,
					Color(JADE.r, JADE.g, JADE.b, (1.0 - t) * 0.55), 1.4, true)
		draw_style_box(_border, Rect2(Vector2.ZERO, size))

	func _draw_pot(pot: Vector2, cup: Vector2) -> void:
		# 茶壶壶身：双层水墨椭圆，底部淡影
		draw_set_transform(pot + Vector2(0, 14), 0.0, Vector2(1.0, 0.40))
		draw_circle(Vector2.ZERO, 22.0, Color(0.20, 0.28, 0.24, 0.10))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_colored_polygon(_ellipse(pot, 27.0, 17.0, 26),
			Color(JADE.r, JADE.g, JADE.b, 0.78))
		draw_colored_polygon(_ellipse(pot + Vector2(0, -2), 20.0, 10.0, 24),
			Color(0.72, 0.86, 0.80, 0.55))
		draw_line(pot + Vector2(-18, -10), pot + Vector2(20, -10),
			Color(0.20, 0.36, 0.30, 0.65), 1.2, true)
		# 壶盖
		draw_colored_polygon(_ellipse(pot + Vector2(0, -17), 13.0, 4.5, 20),
			Color(0.28, 0.46, 0.39, 0.78))
		draw_circle(pot + Vector2(0, -21), 2.5, Color(0.72, 0.54, 0.26, 0.9))
		# 壶嘴
		draw_colored_polygon(PackedVector2Array([
			pot + Vector2(19, -8), pot + Vector2(33, -17),
			pot + Vector2(29, -12), pot + Vector2(20, 1),
		]), Color(0.26, 0.44, 0.37, 0.82))
		# 壶把
		draw_arc(pot + Vector2(-20, -2), 11.0, -1.2, 1.8, 18,
			Color(0.26, 0.44, 0.37, 0.80), 2.2, true)
		# 茶盏
		draw_colored_polygon(_ellipse(cup, 13.0, 5.0, 20),
			Color(0.82, 0.88, 0.84, 0.92))
		draw_colored_polygon(_ellipse(cup + Vector2(0, 4), 11.0, 4.0, 18),
			Color(0.42, 0.60, 0.52, 0.62))
		draw_line(cup + Vector2(-8, 8), cup + Vector2(8, 8),
			Color(0.42, 0.36, 0.27, 0.40), 1.0, true)

	func _draw_smoke(origin: Vector2) -> void:
		var count := 3 if brewing else 1
		for i in range(count):
			var points := PackedVector2Array()
			for j in range(12):
				var t := float(j) / 11.0
				var x := origin.x + sin(_time * 1.6 + float(i) * 1.7 + t * 3.2) * (2.0 + t * 4.0)
				var y := origin.y - t * (34.0 if brewing else 18.0) - float(i) * 4.0
				points.append(Vector2(x, y))
			var alpha := (0.18 if brewing else 0.09) * (1.0 - 0.15 * float(i))
			draw_polyline(points, Color(SMOKE.r, SMOKE.g, SMOKE.b, alpha),
				1.2 + 0.3 * float(i), true)

	func _draw_text() -> void:
		var font := ThemeBuilder.make_font()
		var font_size := ThemeBuilder.scaled_font_size(ThemeBuilder.FONT_CAPTION)
		var x := 140.0
		var width := maxf(40.0, size.x - x - 12.0)
		var line1 := "炉火温存"
		var line2 := "静候煎茶"
		var color1 := Color(INK.r, INK.g, INK.b, 0.78)
		var color2 := Color(0.38, 0.44, 0.40, 0.72)
		if brewing:
			line1 = "正在文火慢煎：%s" % brew_name
			line2 = "剩余 %.1f 秒" % maxf(0.0, remaining)
			color1 = Color(0.50, 0.35, 0.16, 0.90)
			color2 = Color(0.46, 0.40, 0.28, 0.78)
		elif active_name != "":
			line1 = "%s生效中" % active_name
			var total := maxi(0, int(ceil(active_remain)))
			line2 = "余 %d 分 %02d 秒" % [total / 60, total % 60]
			color1 = Color(JADE.r, JADE.g, JADE.b, 0.92)
			color2 = Color(0.32, 0.46, 0.40, 0.78)
		draw_string(font, Vector2(x, 30.0), line1, HORIZONTAL_ALIGNMENT_LEFT,
			width, font_size, color1)
		draw_string(font, Vector2(x, 50.0), line2, HORIZONTAL_ALIGNMENT_LEFT,
			width, font_size, color2)

	func _ellipse(center: Vector2, rx: float, ry: float, segments: int) -> PackedVector2Array:
		var points := PackedVector2Array()
		for i in range(segments):
			var angle := TAU * float(i) / float(segments)
			points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
		return points

var _scroll: ScrollContainer
var _content: VBoxContainer
var _tab: String = "fishing"
var _progress_bar: ProgressBar
var _progress_label: Label
var _pity_label: Label
var _tea_banner: Label
var _banner_card: PanelContainer
var _brew_stage: TeaBrewStage
var _pond_stage: TeaPondStage
var _fishing_status_label: Label
var _fishing_toggle: Button
var _logs_box: VBoxContainer
## 收获纪要底卡：宽屏按剩余高度自适应延展，竖屏保持原高度
var _logs_card: Control
var _logs_base_h: float = 0.0
var _logs_signature: String = ""
## 固定条数 Label 池：收获纪要只改 text，不 new / queue_free，最小高度恒定
var _log_views: Array[Label] = []
var _inv_refresh_queued: bool = false
var _tea_cards: Dictionary = {}
var _last_fish_timer: float = -1.0
var _last_fishing_active: bool = false
var _brewing_tea_id: String = ""
var _brew_started_msec: int = 0
var _brewing_icon: IconFrame
var _live_accum: float = 0.0
var _dirty: bool = true
var _rebuild_queued: bool = false


func _ready() -> void:
	_build_shell()
	_connect_signals()
	visibility_changed.connect(_on_visibility_changed)
	resized.connect(_on_self_resized)
	set_process(true)
	ThemeBuilder.prepare_touch(self)
	_queue_refresh()


func _build_shell() -> void:
	_scroll = ThemeBuilder.scroll_container()
	_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	_scroll.add_child(margin)
	_content = ThemeBuilder.vbox(10)
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(_content)


func _connect_signals() -> void:
	# 高频库存/属性信号只做局部增量刷新，绝不重建灵潭画布
	_connect_if(EventBus, "stats_changed", Callable(self, "_on_inventory_changed"))
	_connect_if(EventBus, "inventory_changed", Callable(self, "_on_inventory_changed"))
	_connect_if(EventBus, "realm_changed", Callable(self, "_queue_refresh"))
	_connect_if(EventBus, "game_loaded", Callable(self, "_queue_refresh"))


func _on_inventory_changed() -> void:
	# 同帧多条库存/属性信号合并成一次刷新（三槽挂机时每秒可达十余条）
	if not is_inside_tree() or not visible or _inv_refresh_queued:
		return
	_inv_refresh_queued = true
	call_deferred("_do_inventory_refresh")


func _do_inventory_refresh() -> void:
	_inv_refresh_queued = false
	if not visible or not is_inside_tree():
		return
	_refresh_fishing_frame()
	_refresh_fishing_logs()
	if _tab != "fishing":
		_refresh_tea_cards()
		_refresh_brew_stage()
		_refresh_tea_banner()


func _connect_if(source: Object, signal_name: String, callback: Callable) -> void:
	if source == null or not source.has_signal(signal_name):
		return
	if not source.is_connected(signal_name, callback):
		source.connect(signal_name, callback)


func _on_visibility_changed() -> void:
	if not visible:
		return
	if _dirty:
		_queue_refresh()
		return
	_refresh_fishing_frame()
	_refresh_fishing_logs()
	_refresh_tea_banner()
	if _tab != "fishing":
		_refresh_tea_cards()


func _queue_refresh() -> void:
	_dirty = true
	if not visible or not is_inside_tree() or _rebuild_queued:
		return
	_rebuild_queued = true
	call_deferred("_rebuild")


func _process(delta: float) -> void:
	if not visible or not is_inside_tree():
		return
	var brew_finished := false
	if _brewing_tea_id != "" \
			and Time.get_ticks_msec() - _brew_started_msec >= int(FishingTeaSystem.BREW_SECONDS * 1000.0):
		FishingTeaSystem.resolve_pending_tea()
		_brewing_tea_id = ""
		_brewing_icon = null
		brew_finished = true
		_refresh_tea_cards()
		_refresh_tea_banner(true)
		if _brew_stage != null and is_instance_valid(_brew_stage):
			_brew_stage.trigger_finish()
	if _brewing_icon != null and is_instance_valid(_brewing_icon):
		_brewing_icon.position.x = sin(float(Time.get_ticks_msec()) * 0.012) * 1.8
	# 进度条与画布每帧连续推进，不再依赖 0.5 秒轮询
	_refresh_fishing_frame()
	if _tab != "fishing":
		_refresh_brew_stage()
		if brew_finished:
			_refresh_brew_stage()
	_live_accum += delta
	if _live_accum < 0.5:
		return
	_live_accum = 0.0
	_refresh_tea_banner()
	if _tab != "fishing":
		_refresh_tea_cards()
		_refresh_brew_stage()


func _refresh_live() -> void:
	_refresh_fishing_frame()
	_refresh_fishing_logs()
	_refresh_tea_banner()
	_refresh_tea_cards()
	_refresh_brew_stage()


## 每帧插值：直接读取 FishingTeaSystem 由 ActionRunner 逐帧推进的浮点计时
func _refresh_fishing_frame() -> void:
	if _progress_bar == null or not is_instance_valid(_progress_bar):
		return
	if not FishingTeaSystem.is_unlocked():
		return
	var state := FishingTeaSystem.get_state()
	var active := bool(state.get("fishing_active", false))
	var timer := clampf(float(state.get("fish_timer", 0.0)), 0.0, FishingTeaSystem.ROD_INTERVAL)
	if active and _last_fish_timer >= 0.0 and timer + 1.0 < _last_fish_timer:
		var logs: Array = state.get("recent_logs", [])
		var latest := str((logs[0] as Dictionary).get("text", "")) if not logs.is_empty() else "灵潭有得"
		if _pond_stage != null:
			_pond_stage.show_catch(latest)
		# 收竿一声轻拨：只在本页可见时触发，并与百艺循环拟音共用 0.18s 闸门
		AudioManager.play_fishing_catch()
		_refresh_fishing_logs()
	_last_fish_timer = timer
	if active != _last_fishing_active:
		_last_fishing_active = active
		_apply_fishing_state(active)
	var progress := clampf(timer / FishingTeaSystem.ROD_INTERVAL, 0.0, 1.0) if active else 0.0
	_progress_bar.value = progress
	if _pond_stage != null and is_instance_valid(_pond_stage):
		_pond_stage.fishing_active = active
		_pond_stage.progress = progress
	if _progress_label != null and is_instance_valid(_progress_label):
		var remain := maxf(0.0, FishingTeaSystem.ROD_INTERVAL - timer)
		_progress_label.text = "距下次收竿 %.1f 秒" % remain if active else "灵潭静候"
	var pity_text := "灵韵 %d/10 · 金髓 %d/10" % [
		clampi(int(state.get("pity_dew_count", 0)), 0, 10),
		clampi(int(state.get("pity_gold_count", 0)), 0, 10)]
	if _pity_label != null and is_instance_valid(_pity_label) \
			and _pity_label.text != pity_text:
		_pity_label.text = pity_text


func _apply_fishing_state(active: bool) -> void:
	if _fishing_status_label != null and is_instance_valid(_fishing_status_label):
		_fishing_status_label.text = "垂钓中" if active else "已歇息"
		_fishing_status_label.add_theme_color_override("font_color",
			ThemeBuilder.COLOR_TEXT_JADE if active else ThemeBuilder.COLOR_TEXT_SECONDARY)
	if _fishing_toggle != null and is_instance_valid(_fishing_toggle):
		_fishing_toggle.text = "收竿歇息" if active else "开始垂钓"
		ThemeBuilder.apply_font_size(_fishing_toggle, ThemeBuilder.FONT_BODY_SUB)
		if active:
			ThemeBuilder.apply_secondary_button(_fishing_toggle)
		else:
			ThemeBuilder.apply_primary_button(_fishing_toggle)
	if _pond_stage != null and is_instance_valid(_pond_stage):
		_pond_stage.fishing_active = active


## 固定 8 行 Label 池：单行裁切、就地改写，收获瞬间不触发整页滚动重排
func _build_fishing_log_pool() -> void:
	_log_views.clear()
	_logs_signature = "init"
	for i in range(FishingTeaSystem.MAX_LOGS):
		var label := ThemeBuilder.label("", ThemeBuilder.FONT_CAPTION,
			ThemeBuilder.COLOR_TEXT_SECONDARY)
		ThemeBuilder.apply_font_size(label, ThemeBuilder.FONT_CAPTION)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.clip_text = true
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		_logs_box.add_child(label)
		_log_views.append(label)


func _refresh_fishing_logs() -> void:
	if _logs_box == null or not is_instance_valid(_logs_box) or _log_views.is_empty():
		return
	if not FishingTeaSystem.is_unlocked():
		return
	var state := FishingTeaSystem.get_state()
	var entries: Array = state.get("recent_logs", [])
	var signature_parts: Array[String] = []
	for value in entries:
		if typeof(value) == TYPE_DICTIONARY:
			var dict: Dictionary = value
			signature_parts.append("%s|%s|%s" % [str(dict.get("tone", "")),
				str(dict.get("rare", false)), str(dict.get("text", ""))])
	var signature := "|".join(signature_parts)
	if signature == _logs_signature:
		return
	_logs_signature = signature
	for i in range(_log_views.size()):
		var label := _log_views[i]
		if i >= entries.size() or typeof(entries[i]) != TYPE_DICTIONARY:
			label.text = ""
			label.tooltip_text = ""
			continue
		var entry: Dictionary = entries[i]
		var tone := str(entry.get("tone", "plain"))
		var log_color := ThemeBuilder.COLOR_TEXT_PRIMARY
		match tone:
			"jade":
				log_color = ThemeBuilder.COLOR_TEXT_JADE
			"gold":
				log_color = ThemeBuilder.COLOR_TEXT_GOLD
		var body := "• %s" % str(entry.get("text", ""))
		if label.text != body:
			label.text = body
			label.tooltip_text = body
		label.add_theme_color_override("font_color", log_color)
	if entries.is_empty():
		_log_views[0].text = "尚无收获，灵潭静候垂钓。"
		_log_views[0].add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT_MUTED)


func _refresh_tea_banner(highlight: bool = false) -> void:
	var info := FishingTeaSystem.get_active_tea_info()
	if _banner_card != null and is_instance_valid(_banner_card):
		_banner_card.visible = not info.is_empty()
	if _tea_banner == null or not is_instance_valid(_tea_banner):
		return
	_tea_banner.text = str(info.get("text", ""))
	if highlight and not info.is_empty() and _banner_card != null:
		_banner_card.modulate = Color(1.24, 1.14, 0.92, 1.0)
		var tween := create_tween()
		tween.tween_property(_banner_card, "modulate", Color.WHITE, 0.5)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _rebuild() -> void:
	_rebuild_queued = false
	if not is_inside_tree() or not visible:
		return
	_dirty = false
	_progress_bar = null
	_progress_label = null
	_pity_label = null
	_tea_banner = null
	_banner_card = null
	_brew_stage = null
	_pond_stage = null
	_fishing_status_label = null
	_fishing_toggle = null
	_logs_box = null
	_logs_card = null
	_logs_base_h = 0.0
	_logs_signature = ""
	_tea_cards.clear()
	_last_fish_timer = -1.0
	_last_fishing_active = false
	_brewing_icon = null
	var pending_state := FishingTeaSystem.get_state()
	var pending_id := str(pending_state.get("pending_tea_id", ""))
	if pending_id != "" and _brewing_tea_id == "":
		_brewing_tea_id = pending_id
		_brew_started_msec = int((float(pending_state.get("pending_tea_ready_unix", 0))
			- FishingTeaSystem.BREW_SECONDS) * 1000.0)
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()

	if not FishingTeaSystem.is_unlocked():
		_build_locked_card()
	else:
		_build_active_banner()
		_build_tabs()
		if _tab == "fishing":
			_build_fishing_tab()
		else:
			_build_tea_tab()
	ThemeBuilder.prepare_touch(self)
	_refresh_live()


func _new_card() -> VBoxContainer:
	var card := ThemeBuilder.card_panel(ThemeBuilder.COLOR_CARD,
		ThemeBuilder.COLOR_BORDER, 10, 10)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_child(card)
	var box := ThemeBuilder.vbox(8)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(box)
	return box


func _build_locked_card() -> void:
	var box := _new_card()
	box.add_child(ThemeBuilder.card_title_label("灵潭清茗",
		ThemeBuilder.FONT_CARD_TITLE, ThemeBuilder.COLOR_TEXT_TITLE_GOLD))
	var frame := IconFrame.new()
	frame.setup(IconLibrary.get_ui_icon("tea_pot"), 72,
		ThemeBuilder.COLOR_TEXT_MUTED, false, 52)
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(frame)
	box.add_child(ThemeBuilder.wrap_label("需化神初期开启灵潭清茗。",
		ThemeBuilder.FONT_BODY, ThemeBuilder.COLOR_TEXT_PRIMARY))
	box.add_child(ThemeBuilder.wrap_label(
		"届时可在灵潭垂钓采集清露与灵鱼，并在洞府烹煮灵茶辅助修行。",
		ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_SECONDARY))


func _build_active_banner() -> void:
	var info := FishingTeaSystem.get_active_tea_info()
	var card := ThemeBuilder.card_panel(ThemeBuilder.COLOR_JADE_SOFT,
		ThemeBuilder.COLOR_BORDER, 8, 8)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 44)
	_content.add_child(card)
	_banner_card = card
	var row := ThemeBuilder.hbox(6)
	card.add_child(row)
	var active_icon := str(info.get("icon", "tea_pot"))
	row.add_child(ThemeBuilder.icon_rect(IconLibrary.get_tea_icon(
		str(info.get("id", "")), active_icon), 18))
	_tea_banner = ThemeBuilder.label(str(info.get("text", "")),
		ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_JADE)
	_tea_banner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tea_banner.clip_text = true
	_tea_banner.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(_tea_banner)
	_banner_card.visible = not info.is_empty()


func _build_tabs() -> void:
	var row := ThemeBuilder.hbox(6)
	_content.add_child(row)
	var fishing := ThemeBuilder.small_button("灵潭垂钓")
	fishing.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fishing.toggle_mode = true
	fishing.button_pressed = _tab == "fishing"
	ThemeBuilder.apply_toggle_button(fishing, fishing.button_pressed)
	fishing.pressed.connect(Callable(self, "_set_tab").bind("fishing"))
	row.add_child(fishing)
	var tea := ThemeBuilder.small_button("洞府烹茶")
	tea.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tea.toggle_mode = true
	tea.button_pressed = _tab == "tea"
	ThemeBuilder.apply_toggle_button(tea, tea.button_pressed)
	tea.pressed.connect(Callable(self, "_set_tab").bind("tea"))
	row.add_child(tea)
	var help := ThemeBuilder.create_help_button(Callable(self, "_show_help"))
	help.custom_minimum_size = Vector2(44, 44)
	row.add_child(help)


func _on_self_resized() -> void:
	if is_visible_in_tree():
		call_deferred("_fit_bottom")


## 宽屏：灵潭收获纪要补高到底部安全边距；竖屏恢复原高
func _fit_bottom() -> void:
	if _logs_card == null or not is_instance_valid(_logs_card):
		return
	if _tab != "fishing" or EventBus.workspace_width < 680.0:
		_logs_card.custom_minimum_size.y = _logs_base_h
		return
	ThemeBuilder.fit_bottom_card(self, _logs_card, _logs_base_h, 10.0)


func _set_tab(tab: String) -> void:
	if _tab == tab:
		return
	_tab = tab
	_queue_refresh()


func _build_fishing_tab() -> void:
	var status := _new_card()
	status.add_child(ThemeBuilder.card_title_label("灵潭垂钓",
		ThemeBuilder.FONT_CARD_TITLE, ThemeBuilder.COLOR_TEXT_TITLE_GOLD))
	var head := ThemeBuilder.hbox(8)
	status.add_child(head)
	var frame := IconFrame.new()
	frame.setup(IconLibrary.get_ui_icon("fishing_rod"), 48,
		ThemeBuilder.COLOR_JADE, false, 36)
	head.add_child(frame)
	var info := ThemeBuilder.vbox(4)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(info)
	var active := FishingTeaSystem.is_fishing_active()
	var status_row := ThemeBuilder.hbox(6)
	info.add_child(status_row)
	var status_label := ThemeBuilder.label("垂钓中" if active else "已歇息",
		ThemeBuilder.FONT_BODY, ThemeBuilder.COLOR_TEXT_JADE if active
		else ThemeBuilder.COLOR_TEXT_SECONDARY)
	ThemeBuilder.apply_font_size(status_label, ThemeBuilder.FONT_BODY)
	_fishing_status_label = status_label
	status_row.add_child(status_label)
	_progress_label = ThemeBuilder.label("", ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_SECONDARY)
	ThemeBuilder.apply_font_size(_progress_label, ThemeBuilder.FONT_CAPTION)
	_progress_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_row.add_child(_progress_label)
	var toggle_text := "收竿歇息" if active else "开始垂钓"
	var toggle := ThemeBuilder.small_button(toggle_text)
	toggle.custom_minimum_size = Vector2(110, ThemeBuilder.TOUCH_MIN)
	toggle.size_flags_horizontal = Control.SIZE_SHRINK_END
	ThemeBuilder.apply_font_size(toggle, ThemeBuilder.FONT_BODY_SUB)
	if active:
		ThemeBuilder.apply_secondary_button(toggle)
	else:
		ThemeBuilder.apply_primary_button(toggle)
	toggle.pressed.connect(Callable(self, "_toggle_fishing"))
	_fishing_toggle = toggle
	_last_fishing_active = active
	status_row.add_child(toggle)
	var progress_row := ThemeBuilder.hbox(6)
	info.add_child(progress_row)
	_progress_bar = ThemeBuilder.progress_bar_run()
	_progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_row.add_child(_progress_bar)
	_pity_label = ThemeBuilder.label("", ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_GOLD)
	ThemeBuilder.apply_font_size(_pity_label, ThemeBuilder.FONT_CAPTION)
	_pity_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	progress_row.add_child(_pity_label)

	_pond_stage = TeaPondStage.new()
	_pond_stage.custom_minimum_size = Vector2(0, 160)
	_pond_stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pond_stage.clip_contents = true
	_pond_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status.add_child(_pond_stage)

	var logs := _new_card()
	_logs_card = logs
	logs.add_child(ThemeBuilder.card_title_label("灵潭收获纪要",
		ThemeBuilder.FONT_CARD_TITLE, ThemeBuilder.COLOR_TEXT_TITLE_GOLD))
	# 纪要容器持久化：库存信号只更新条目，不销毁画布或整页
	var log_margin := MarginContainer.new()
	log_margin.add_theme_constant_override("margin_left", 5)
	log_margin.add_theme_constant_override("margin_right", 5)
	log_margin.add_theme_constant_override("margin_top", 5)
	log_margin.add_theme_constant_override("margin_bottom", 5)
	log_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	logs.add_child(log_margin)
	_logs_box = ThemeBuilder.vbox(3)
	_logs_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_margin.add_child(_logs_box)
	_logs_signature = ""
	_build_fishing_log_pool()
	_refresh_fishing_logs()
	_logs_base_h = logs.get_combined_minimum_size().y
	call_deferred("_fit_bottom")


func _toggle_fishing() -> void:
	var active := FishingTeaSystem.toggle_fishing()
	EventBus.toast.emit("已开始灵潭垂钓" if active else "已收竿歇息")
	_last_fish_timer = -1.0
	_apply_fishing_state(active)
	_refresh_fishing_frame()


func _build_tea_tab() -> void:
	var box := _new_card()
	box.add_child(ThemeBuilder.card_title_label("洞府烹茶",
		ThemeBuilder.FONT_CARD_TITLE, ThemeBuilder.COLOR_TEXT_TITLE_GOLD))
	box.add_child(ThemeBuilder.wrap_label("同时仅一款灵茶生效，重泡将替换并重新计时 60 分钟。",
		ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_SECONDARY))
	_brew_stage = TeaBrewStage.new()
	_brew_stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(_brew_stage)
	_refresh_brew_stage()
	for tea_id in FishingTeaSystem.TEAS.keys():
		box.add_child(_tea_card(str(tea_id)))


func _tea_card(tea_id: String) -> PanelContainer:
	var key := FishingTeaSystem.normalize_tea_id(tea_id)
	var tea: Dictionary = FishingTeaSystem.TEAS[key]
	var unlocked := FishingTeaSystem.is_tea_unlocked(key)
	var card := ThemeBuilder.card_panel(
		ThemeBuilder.COLOR_CARD_DEEP if unlocked else ThemeBuilder.COLOR_SUBTLE,
		ThemeBuilder.COLOR_BORDER, 8, 8)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 128)
	var row := ThemeBuilder.hbox(8)
	card.add_child(row)
	var frame := IconFrame.new()
	frame.setup(IconLibrary.get_tea_icon(key, str(tea.get("icon", "tea_pot"))), 44,
		ThemeBuilder.COLOR_JADE if unlocked else ThemeBuilder.COLOR_TEXT_MUTED, false, 34)
	row.add_child(frame)
	var info := ThemeBuilder.vbox(3)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.custom_minimum_size = Vector2(0, 0)
	row.add_child(info)
	var tea_name := ThemeBuilder.label(str(tea.get("name", "")),
		ThemeBuilder.FONT_BODY,
		ThemeBuilder.COLOR_TEXT_TITLE if unlocked else ThemeBuilder.COLOR_TEXT_MUTED)
	tea_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tea_name.clip_text = true
	tea_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	info.add_child(tea_name)
	var material_refs: Dictionary = {}
	var enough := true
	if not unlocked:
		info.add_child(ThemeBuilder.label(FishingTeaSystem.get_tea_unlock_label(key),
			ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_DANGER))
		info.add_child(ThemeBuilder.wrap_label(str(tea.get("effect", "")),
			ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_MUTED))
	else:
		# 材料清单走系统统一出口（支持指定灵鱼：赤鳞火鲤 / 寒潭银鳗 + 金髓龙鱼）
		var costs := FishingTeaSystem.get_tea_costs(key)
		for item_value in costs.keys():
			enough = _add_material_row(info, String(item_value),
				int(costs[item_value]), material_refs) and enough
		info.add_child(ThemeBuilder.wrap_label(str(tea.get("effect", "")),
			ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_JADE))
	var brewing := _brewing_tea_id == key
	var brew := ThemeBuilder.small_button("文火慢煎中…" if brewing else "烹煮饮用")
	brew.custom_minimum_size = Vector2(96, ThemeBuilder.TOUCH_MIN)
	brew.size_flags_horizontal = Control.SIZE_SHRINK_END
	brew.disabled = not unlocked or _brewing_tea_id != "" or not enough
	brew.tooltip_text = FishingTeaSystem.get_tea_unlock_label(key) if not unlocked else ""
	if brewing:
		_brewing_icon = frame
	brew.pressed.connect(Callable(self, "_brew").bind(key))
	row.add_child(brew)
	_tea_cards[key] = {
		"unlocked": unlocked, "materials": material_refs, "brew": brew,
	}
	return card


func _add_material_row(parent: VBoxContainer, item_id: String, need: int,
		store: Dictionary) -> bool:
	var have := GameState.get_item_count(item_id)
	var enough := have >= need
	var row := ThemeBuilder.hbox(6)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_label := ThemeBuilder.label(DataRegistry.get_item_name(item_id),
		ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_SECONDARY)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(name_label)
	var count_label := ThemeBuilder.label("%d / %d" % [need, have],
		ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_JADE if enough else ThemeBuilder.COLOR_TEXT_DANGER)
	count_label.custom_minimum_size = Vector2(72, 0)
	count_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	ThemeBuilder.apply_font_size(count_label, ThemeBuilder.FONT_CAPTION)
	row.add_child(count_label)
	parent.add_child(row)
	store[item_id] = {"need": need, "label": count_label}
	return enough


func _refresh_brew_stage() -> void:
	if _brew_stage == null or not is_instance_valid(_brew_stage):
		return
	var info := FishingTeaSystem.get_active_tea_info()
	var active_name := str(info.get("name", ""))
	var active_remain := float(info.get("remain", 0))
	var brewing := _brewing_tea_id != ""
	var brew_name := ""
	var remaining := 0.0
	var progress := 0.0
	if brewing:
		var tea: Dictionary = FishingTeaSystem.TEAS.get(_brewing_tea_id, {})
		brew_name = str(tea.get("name", _brewing_tea_id))
		var elapsed := maxf(0.0,
			float(Time.get_ticks_msec() - _brew_started_msec) / 1000.0)
		remaining = maxf(0.0, FishingTeaSystem.BREW_SECONDS - elapsed)
		progress = clampf(elapsed / maxf(0.01, FishingTeaSystem.BREW_SECONDS), 0.0, 1.0)
	_brew_stage.brewing = brewing
	_brew_stage.brew_name = brew_name
	_brew_stage.remaining = remaining
	_brew_stage.progress = progress
	_brew_stage.active_name = active_name
	_brew_stage.active_remain = active_remain


func _refresh_tea_cards() -> void:
	for key_value in _tea_cards.keys():
		var key := String(key_value)
		var entry: Dictionary = _tea_cards[key]
		if not bool(entry.get("unlocked", false)):
			continue
		var enough := true
		var materials: Dictionary = entry.get("materials", {})
		for item_value in materials.keys():
			var item_id := String(item_value)
			var material: Dictionary = materials[item_id]
			var need := int(material.get("need", 0))
			var have := GameState.get_item_count(item_id)
			var label: Label = material.get("label", null)
			if label != null and is_instance_valid(label):
				label.text = "%d / %d" % [need, have]
				label.add_theme_color_override("font_color",
					ThemeBuilder.COLOR_TEXT_JADE if have >= need
					else ThemeBuilder.COLOR_TEXT_DANGER)
			enough = enough and have >= need
		var brew: Button = entry.get("brew", null)
		if brew != null and is_instance_valid(brew):
			var brewing := _brewing_tea_id == key
			brew.text = "文火慢煎中…" if brewing else "烹煮饮用"
			brew.disabled = _brewing_tea_id != "" or not enough


func _brew(tea_id: String) -> void:
	var key := FishingTeaSystem.normalize_tea_id(tea_id)
	var result: Dictionary = FishingTeaSystem.brew_tea(key)
	if bool(result.get("ok", false)):
		_brewing_tea_id = key
		_brew_started_msec = Time.get_ticks_msec()
		_refresh_tea_cards()
		_refresh_brew_stage()
		return
	# 只提示失败；煎煮过程由煮茶舞台承载，不再弹中央悬浮气泡
	EventBus.toast.emit(str(result.get("message", "")))


func _show_help() -> void:
	BottomSheet.show_help("灵潭清茗 · 图解", [
		{"text": "灵潭垂钓", "desc": "化神初期开启；每 12 秒自动收竿一次，连续九竿清露必有灵应；十竿未得金髓龙鱼，则第十竿必入鱼群保底。离线最多补算 120 竿。"},
		{"text": "灵鱼生态", "desc": "青纹灵鲫（凡阶常见，可作灵田肥材或化灵）· 碧波灵鱼（中阶主力，养神汤主料）· 赤鳞火鲤（灵阶稀有，斗战茶主料）· 寒潭银鳗（玄阶，仙茗主料）· 金髓龙鱼（仙阶稀世，仙茗与高阶祭炼灵材）。"},
		{"text": "灵茶时限", "desc": "同时仅一款生效，烹煮需文火慢煎 3 秒，茶香持续 60 分钟。"},
		{"text": "悟道清茶", "desc": "化神初期；灵潭清露×3 与凝露花×20，悟道池充能 +25%。"},
		{"text": "凝神灵茶", "desc": "化神后期；灵潭清露×3 与九叶仙芝×8，吐纳修为 +15%。"},
		{"text": "破厄剑茶", "desc": "炼虚初期；灵潭清露×4 与龙血草×8，秘境与镇魔塔攻击伤害 +12%。"},
		{"text": "赤鳞斗战茶", "desc": "炼虚初期；灵潭清露×3、赤鳞火鲤×1 与赤焰草×6，会心率 +6%。"},
		{"text": "灵鱼养神汤", "desc": "炼虚后期；灵潭清露×2、碧波灵鱼×2 与太乙青莲×5，全百艺经验与火候 +12%、动作耗时 -5%。"},
		{"text": "寒髓金髓仙茗", "desc": "炼虚中期；灵潭清露×4、寒潭银鳗×1 与金髓龙鱼×1，全百艺双倍 +5%、动作耗时 -6%。"},
	])
