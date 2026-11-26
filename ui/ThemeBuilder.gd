class_name ThemeBuilder
extends RefCounted

## 血量掉血残影色（浅朱砂）
const HP_GHOST_COLOR: Color = Color("#E69F8A")
## 程序化「宣纸墨韵」浅色古籍主题与 StyleBoxFlat 工厂（移动端竖屏优先）。
## 以面代线：宣纸底 → 象牙白卡片 → 暖石凹陷，用明度差分层，不再满屏细边框。

# ---------------------------------------------------------------- 宣纸色板
## 底层宣纸 / 顶栏底栏 / 前景卡片 / 凹陷容器
const COLOR_BG: Color = Color("#F4EFE6")
const COLOR_CHROME: Color = Color("#ECE5D8")
const COLOR_CHROME_LINE: Color = Color("#DDD4C4")
const COLOR_CARD: Color = Color("#FCF9F2")
const COLOR_CARD_HOVER: Color = Color("#F4EEE1")
const COLOR_CARD_DEEP: Color = Color("#F3EDE0")
const COLOR_BORDER: Color = Color("#E6DEC9")
const COLOR_TRACK: Color = Color("#E8E0D1")
const COLOR_SUBTLE: Color = Color("#E8E0D1")
## 进度条 / 血条槽色：比卡片底色深一档，保证细条也能读出"轨道 + 填充"
const COLOR_BAR_TRACK: Color = Color("#D5C9B2")
const COLOR_BAR_TRACK_EDGE: Color = Color("#C4B79E")
## 进度条轨道/填充圆角：progress_bar 与 PoolMilestoneBar 共用，保证粗细与轮廓一致
const PROGRESS_BG_RADIUS: int = 5
const PROGRESS_FILL_RADIUS: int = 4
const COLOR_SUBTLE_HOVER: Color = Color("#DDD3C0")
const COLOR_SUBTLE_PRESSED: Color = Color("#D3C8B3")
## 卡片薄宣纸微透：只作用于卡片底色，边框保持不透明
const CARD_ALPHA: float = 0.84
static var _card_style_cache: Dictionary = {}

## ---- 三层字色规范（全站卡片的唯一口径，新代码只准用这 8 个常量） ----
## 第一层 · 卡片标题
const COLOR_TEXT_TITLE: Color = Color("#26211C")       # 焦墨黑：常规卡片标题
const COLOR_TEXT_TITLE_GOLD: Color = Color("#8F6022")  # 沉金褐：页面总览 / 悟道池 / 统计 / 渡劫等仪式标题
## 第二层 · 主数值与核心状态
const COLOR_TEXT_PRIMARY: Color = Color("#38312A")     # 浓墨：核心产出、耗时、等级、价格与正文
const COLOR_TEXT_JADE: Color = Color("#276953")        # 黛玉青：正向增益、运转激活、成熟/可领取
const COLOR_TEXT_GOLD: Color = Color("#9A6822")        # 鎏金琥珀：悟道点、极品品质、淬炼可用
const COLOR_TEXT_DANGER: Color = Color("#B34233")      # 朱砂红：仅材料不足、低血/低道心等警示
## 第三层 · 辅助说明
const COLOR_TEXT_SECONDARY: Color = Color("#7A7165")   # 浅砚暖灰：括号库存、进度分母、标签前缀
const COLOR_TEXT_MUTED: Color = Color("#9E9487")       # 淡烟灰：未解锁条件、未开垦等弱占位

## 兼容别名：旧调用点无需改动即自动落到上面的规范，新代码请直接用 COLOR_TEXT_*
const COLOR_TEXT: Color = COLOR_TEXT_PRIMARY
const COLOR_TEXT_DIM: Color = COLOR_TEXT_MUTED

## 矿物质点缀：玉青 / 朱砂 / 泥金。
## 三者的「文字色」已并入三层规范（见上方 COLOR_TEXT_JADE / GOLD / DANGER），
## 这里直接别名到同一色值：既做填充底色（按钮/印章/进度条），也做文字强调色，
## 保证「同一个绿/金/红」全站只有一种取值，不会再出现深浅不一的散装文字色。
const COLOR_JADE: Color = COLOR_TEXT_JADE
const COLOR_JADE_DARK: Color = Color("#215A4F")
const COLOR_JADE_EDGE: Color = Color("#1C4D43")
const COLOR_JADE_SOFT: Color = Color("#E2EFEA")
const COLOR_JADE_PAPER: Color = Color("#F4FAF7")
const COLOR_CINNABAR: Color = COLOR_TEXT_DANGER
const COLOR_CINNABAR_SOFT: Color = Color("#F8E5E2")
const COLOR_CINNABAR_EDGE: Color = Color("#E4B8B1")
const COLOR_AMBER: Color = COLOR_TEXT_GOLD
const COLOR_GOLD_SOFT: Color = Color("#F6EEDC")
const COLOR_EMERALD: Color = COLOR_TEXT_JADE

## 卡片柔和暖阴影 / 图标底框
const COLOR_SHADOW: Color = Color(0.18, 0.14, 0.10, 0.06)
const COLOR_ICON_FRAME: Color = Color("#EFE9DD")
const COLOR_ICON_FRAME_BORDER: Color = Color("#E2D9C8")

## 触控规范
const TOUCH_MIN: float = 44.0
## 4 级标准字号（标准档基准；最小正文底线已抬到 13，避免手机端小字吃力）
const FONT_PAGE_TITLE: int = 23
const FONT_CARD_TITLE: int = 18
const FONT_BODY: int = 15
const FONT_BODY_SUB: int = 14
## 最小正文底线（AGENTS 红线：不低于 13）
const FONT_CAPTION: int = 13
## 区块小标题（静候时机 / 天雷纪要 / 渡劫条件 / 自动应对 …）：比正文字号略大一档
const FONT_SECTION_TITLE: int = 17
## 兼容旧调用的别名
const FONT_TITLE: int = FONT_PAGE_TITLE
const FONT_SMALL: int = FONT_CAPTION

const FONT_BRUSH_BOLD_PATH: String = "res://assets/fonts/pangmen_cushu.ttf"
const FONT_BRUSH_KAI_PATH: String = "res://assets/fonts/ma_shan_zheng.ttf"

## 无衬线中文字体族：桌面 Windows → Android（Noto / Droid）→ iOS / Linux 全覆盖。
## 末尾 "sans-serif" 是 Android 系统别名兜底，确保「箓 / 淬 / 诀 / 鼎 / 阶 / 窍」等
## 生僻字与「·」「—」等标点在任何真机上都有字形可落，不退化成 FFFC/FFFD 缺字框。
const FONT_STACK: Array[String] = [
	"Microsoft YaHei UI", "Microsoft YaHei", "PingFang SC", "Noto Sans CJK SC",
	"Noto Sans SC", "Source Han Sans SC", "Source Han Sans CN", "Noto Serif CJK SC",
	"Noto Serif SC", "Droid Sans Fallback", "WenQuanYi Micro Hei", "SimHei",
	"Noto Sans CJK JP", "sans-serif",
]

## 全局字号三档：紧凑 95% / 标准 105% / 大字 120%
const FONT_SCALE_COMPACT: float = 0.95
const FONT_SCALE_STANDARD: float = 1.05
const FONT_SCALE_LARGE: float = 1.20
## 当前全局字号倍率：所有文本控件都经 apply_font_size 记录基准值后换算
static var font_scale: float = FONT_SCALE_STANDARD
static var _bold_font: SystemFont = null
static var _fallback_font: SystemFont = null
static var _brush_bold: FontFile = null
static var _brush_kai: FontFile = null


static func set_font_scale(value: float) -> void:
	font_scale = clampf(value, FONT_SCALE_COMPACT, FONT_SCALE_LARGE)


## 把任意历史字号倍率归一化到当前三档：
## 旧档 0.90→0.95、1.00→1.05、1.15→1.20；其他手改值取最近档（同距时偏向标准档）
static func normalize_font_scale(value: float) -> float:
	if is_equal_approx(value, FONT_SCALE_COMPACT) \
			or is_equal_approx(value, FONT_SCALE_STANDARD) \
			or is_equal_approx(value, FONT_SCALE_LARGE):
		return value
	var best := FONT_SCALE_STANDARD
	var best_delta := absf(value - FONT_SCALE_STANDARD)
	for candidate in [FONT_SCALE_COMPACT, FONT_SCALE_LARGE]:
		var delta := absf(value - float(candidate))
		if delta < best_delta - 0.0001:
			best = float(candidate)
			best_delta = delta
	return best


## 基准字号 → 当前档位实际字号（四舍五入，至少 1）
static func scaled_font_size(base_size: int) -> int:
	return maxi(1, int(roundf(float(base_size) * font_scale)))


static func make_font() -> SystemFont:
	if _fallback_font != null:
		return _fallback_font
	_fallback_font = _make_system_font(400)
	return _fallback_font


## 正文/标题共用的清晰加粗无衬线字体（境界层数、数值等必须一眼可读的文本）。
## 注意：必须新建 SystemFont 实例，绝不能改 make_font() 的缓存实例字重，
## 否则会把全站正文一起变成粗体。
static func make_bold_font() -> SystemFont:
	if _bold_font != null:
		return _bold_font
	_bold_font = _make_system_font(700)
	return _bold_font


static func _make_system_font(weight: int) -> SystemFont:
	var font := SystemFont.new()
	var names := PackedStringArray()
	for name in FONT_STACK:
		names.append(name)
	font.font_names = names
	font.font_weight = weight
	font.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	# 系统级缺字回退：个别字形不在首选族时由 OS 兜底，避免出现豆腐块
	font.allow_system_fallback = true
	return font


static func get_brush_bold() -> Font:
	if _brush_bold != null:
		return _brush_bold
	var loaded: Resource = load(FONT_BRUSH_BOLD_PATH)
	if loaded is FontFile:
		_brush_bold = loaded as FontFile
		_configure_brush_font(_brush_bold)
		return _brush_bold
	return make_font()


static func get_brush_kai() -> Font:
	if _brush_kai != null:
		return _brush_kai
	var loaded: Resource = load(FONT_BRUSH_KAI_PATH)
	if loaded is FontFile:
		_brush_kai = loaded as FontFile
		_configure_brush_font(_brush_kai)
		return _brush_kai
	return make_font()


## 毛笔字体缺字回退到项目默认无衬线；保持默认矢量光栅化，不启用 MSDF。
## 回退链必须挂满：毛笔字库只有常用字，缺字时若没有 fallbacks 会直接画成
## U+FFFC/U+FFFD 豆腐块（真机上表现为「ffsc」方块）。
static func _configure_brush_font(font: FontFile) -> void:
	font.fallbacks = [make_font()]
	font.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	font.multichannel_signed_distance_field = false


static func apply_brush_bold(control: Control) -> void:
	if control == null:
		return
	control.add_theme_font_override("font", get_brush_bold())


static func apply_brush_kai(control: Control) -> void:
	if control == null:
		return
	control.add_theme_font_override("font", get_brush_kai())


static func panel_box(bg: Color, border: Color, radius: int = 8, border_width: int = 1,
		margin: int = 12) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	box.content_margin_left = margin
	box.content_margin_right = margin
	box.content_margin_top = margin
	box.content_margin_bottom = margin
	box.anti_aliasing = true
	return box


static func card_color(color: Color) -> Color:
	var result := color
	result.a = CARD_ALPHA
	return result


## 移动端降低过度绘制：卡片不再绘制阴影，仅保留 1px 暖石边框
static func apply_card_shadow(box: StyleBoxFlat) -> StyleBoxFlat:
	if box == null:
		return box
	box.shadow_size = 0
	box.shadow_color = Color(0, 0, 0, 0)
	return box


static func flat_box(bg: Color, radius: int = 4, margin_h: int = 8, margin_v: int = 4) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.set_corner_radius_all(radius)
	box.content_margin_left = margin_h
	box.content_margin_right = margin_h
	box.content_margin_top = margin_v
	box.content_margin_bottom = margin_v
	box.anti_aliasing = true
	return box


static func circle_box(color: Color, size: float = 8.0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(int(size * 0.5))
	box.content_margin_left = 0
	box.content_margin_right = 0
	box.content_margin_top = 0
	box.content_margin_bottom = 0
	box.anti_aliasing = true
	return box


static func build_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = make_font()
	theme.default_font_size = scaled_font_size(FONT_BODY)

	# ---- PanelContainer / Panel（象牙白卡片 + 暖阴影）
	var card_style := panel_box(card_color(COLOR_CARD), COLOR_BORDER, 10, 1)
	apply_card_shadow(card_style)
	theme.set_stylebox("panel", "PanelContainer", card_style)
	theme.set_stylebox("panel", "Panel", card_style)
	theme.set_stylebox("panel", "PopupPanel", panel_box(COLOR_CARD, COLOR_BORDER, 10, 1, 14))
	theme.set_stylebox("panel", "ScrollContainer", flat_box(Color(0, 0, 0, 0), 0, 0, 0))

	# ---- Button（默认次按钮：暖石实底、无边框）
	var transparent := Color(0, 0, 0, 0)
	var btn_normal := panel_box(COLOR_SUBTLE, transparent, 8, 0, 12)
	btn_normal.content_margin_top = 10
	btn_normal.content_margin_bottom = 10
	var btn_hover := panel_box(COLOR_SUBTLE_HOVER, transparent, 8, 0, 12)
	btn_hover.content_margin_top = 10
	btn_hover.content_margin_bottom = 10
	var btn_pressed := panel_box(COLOR_SUBTLE_PRESSED, transparent, 8, 0, 12)
	btn_pressed.content_margin_top = 10
	btn_pressed.content_margin_bottom = 10
	var btn_disabled := panel_box(Color("#F0EADF"), transparent, 8, 0, 12)
	btn_disabled.content_margin_top = 10
	btn_disabled.content_margin_bottom = 10
	theme.set_stylebox("normal", "Button", btn_normal)
	theme.set_stylebox("hover", "Button", btn_hover)
	theme.set_stylebox("pressed", "Button", btn_pressed)
	theme.set_stylebox("disabled", "Button", btn_disabled)
	theme.set_stylebox("focus", "Button", panel_box(transparent, COLOR_JADE, 8, 1, 12))
	theme.set_color("font_color", "Button", COLOR_TEXT)
	theme.set_color("font_hover_color", "Button", COLOR_TEXT)
	theme.set_color("font_pressed_color", "Button", COLOR_JADE)
	theme.set_color("font_disabled_color", "Button", COLOR_TEXT_MUTED)
	theme.set_font_size("font_size", "Button", scaled_font_size(FONT_CARD_TITLE))

	# ---- Label（默认落到三层规范第二层：主数值/正文）
	theme.set_color("font_color", "Label", COLOR_TEXT_PRIMARY)
	theme.set_font_size("font_size", "Label", scaled_font_size(FONT_BODY))

	# ---- RichTextLabel（同上；面板内 [color=#...] 必须由 COLOR_TEXT_* 生成）
	theme.set_color("default_color", "RichTextLabel", COLOR_TEXT_PRIMARY)
	theme.set_font_size("normal_font_size", "RichTextLabel", scaled_font_size(FONT_SMALL))

	# ---- ProgressBar（暖石底槽，无边框）
	theme.set_stylebox("background", "ProgressBar", panel_box(COLOR_TRACK, transparent, 4, 0, 0))
	theme.set_stylebox("fill", "ProgressBar", flat_box(COLOR_JADE, 4, 0, 0))
	theme.set_color("font_color", "ProgressBar", COLOR_TEXT)
	theme.set_font_size("font_size", "ProgressBar", scaled_font_size(FONT_CAPTION))

	# ---- LineEdit / TextEdit（凹陷暖石输入框）
	theme.set_stylebox("normal", "LineEdit", panel_box(COLOR_SUBTLE, COLOR_CHROME_LINE, 8, 1, 10))
	theme.set_stylebox("focus", "LineEdit", panel_box(COLOR_CARD, COLOR_JADE, 8, 1, 10))
	theme.set_color("font_color", "LineEdit", COLOR_TEXT)
	theme.set_color("font_placeholder_color", "LineEdit", COLOR_TEXT_DIM)
	theme.set_stylebox("normal", "TextEdit", panel_box(COLOR_SUBTLE, COLOR_CHROME_LINE, 8, 1, 10))
	theme.set_stylebox("focus", "TextEdit", panel_box(COLOR_CARD, COLOR_JADE, 8, 1, 10))
	theme.set_color("font_color", "TextEdit", COLOR_TEXT)

	# ---- HSlider
	theme.set_stylebox("slider", "HSlider", flat_box(COLOR_TRACK, 4, 0, 4))
	theme.set_stylebox("grabber_area", "HSlider", flat_box(COLOR_JADE, 4, 0, 4))
	theme.set_stylebox("grabber_area_highlight", "HSlider", flat_box(COLOR_JADE_DARK, 4, 0, 4))

	# ---- Tooltip
	var tooltip_style := panel_box(COLOR_CARD, COLOR_BORDER, 8, 1, 10)
	apply_card_shadow(tooltip_style)
	theme.set_stylebox("panel", "TooltipPanel", tooltip_style)
	theme.set_color("font_color", "TooltipLabel", COLOR_TEXT)

	theme.set_constant("separation", "HBoxContainer", 8)
	theme.set_constant("separation", "VBoxContainer", 8)
	return theme


# ---------------------------------------------------------------- 常用控件工厂

## 统一字号入口：记录基准字号并按当前档位换算，切换字号时可无损重算
static func apply_font_size(node: Control, base_size: int,
		theme_item: String = "font_size") -> Control:
	if node == null:
		return node
	if not (node is Label or node is Button or node is RichTextLabel):
		return node
	base_size = maxi(base_size, FONT_CAPTION)
	node.set_meta("_font_base_" + theme_item, base_size)
	node.add_theme_font_size_override(theme_item, scaled_font_size(base_size))
	return node


## 提示横幅专用：按当前字体实测单行宽度，短句单行贴合，超长句才满宽折行。
## pad_h 传入容器左右内边距 + 固定图标/印章宽 + 冗余空间。
static func fit_wrapped_label(label: Label, text_value: String, host: Control,
		pad_h: float, max_width: float) -> void:
	if label == null:
		return
	label.text = text_value
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var font: Font = label.get_theme_font("font")
	if font == null:
		font = make_font()
	var font_size := label.get_theme_font_size("font_size")
	var text_w := font.get_string_size(text_value, HORIZONTAL_ALIGNMENT_LEFT,
		-1, font_size).x
	var max_w := maxf(120.0, max_width)
	var available := maxf(1.0, max_w - pad_h)
	if text_w + pad_h <= max_w:
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.custom_minimum_size.x = maxf(1.0, text_w)
		if host != null:
			host.custom_minimum_size.x = maxf(1.0, text_w + pad_h)
	else:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size.x = available
		if host != null:
			host.custom_minimum_size.x = max_w


## 遍历整棵 UI 树，把所有已记录基准字号（或首次遇到的字号覆盖）按当前档位重算
static func apply_font_scale_to_tree(root: Node) -> void:
	if root == null:
		return
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.append(child)
		if node is Control:
			_rescale_control_fonts(node as Control)


static func _rescale_control_fonts(ctrl: Control) -> void:
	for theme_item in ["font_size", "normal_font_size"]:
		if not ctrl.has_theme_font_size_override(theme_item):
			continue
		var meta_key: String = "_font_base_" + String(theme_item)
		var base := int(ctrl.get_meta(meta_key, 0))
		if base <= 0:
			# 旧代码直接写的覆盖值：首次遇到时视为基准字号
			base = ctrl.get_theme_font_size(theme_item)
			ctrl.set_meta(meta_key, base)
		base = maxi(base, FONT_CAPTION)
		ctrl.add_theme_font_size_override(theme_item, scaled_font_size(base))


## 常量 → BBCode 十六进制，避免面板里散落 "#RRGGBB" 字面量
static func hex(color: Color) -> String:
	return "#" + color.to_html(false)


# ---------------------------------------------------------------- 卡片轻点看详情

## 按下→抬起位移上限（px）：超过视为拖拽，交给 ScrollContainer，不弹详情
const TAP_SLOP: float = 8.0
static var _tap_lock_ms: int = 0


## 让卡片支持「轻点看详情」：
##   卡片 PASS（不拦截滚动）、内部装饰 IGNORE（prepare_touch 已统一处理）；
##   只有「抬起点与按下点相距 ≤ 8px」且「没有落在任何按钮上」才算点击。
## 触屏同时会派发 ScreenTouch 与模拟 MouseButton，用 meta 记账天然去重。
static func make_card_tappable(card: Control, on_tap: Callable) -> void:
	if card == null or on_tap.is_null():
		return
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	card.set_meta("tap_press", Vector2.INF)
	card.gui_input.connect(func(event: InputEvent) -> void:
		var pos := Vector2.INF
		var pressed := false
		var is_touch := event is InputEventScreenTouch
		var is_mouse := event is InputEventMouseButton
		if not is_touch and not is_mouse:
			return
		if is_touch:
			var touch := event as InputEventScreenTouch
			pos = touch.position
			pressed = touch.pressed
		else:
			var mouse := event as InputEventMouseButton
			if mouse.button_index != MOUSE_BUTTON_LEFT:
				return
			pos = mouse.position
			pressed = mouse.pressed
		if pressed:
			# 按在按钮上的手势整段忽略：按钮可能在「按下→抬起」之间被 refresh 隐藏或重排
			# （如点「分神运转」后其余按钮立即收起），若只在抬起时判断，就会把这次抬起
			# 误判成「点卡片空白」弹出详情浮层，把后续点击全吞掉——真机表现正是
			# 「运转按钮点不动 / 要连点好几次」。
			if _card_hits_button(card, card.get_global_rect().position + pos):
				card.set_meta("tap_press", Vector2.INF)
				return
			card.set_meta("tap_press", pos)
			return
		var start: Vector2 = card.get_meta("tap_press", Vector2.INF)
		card.set_meta("tap_press", Vector2.INF)
		if start == Vector2.INF or start.distance_to(pos) > TAP_SLOP:
			return
		# gui_input 的 position 是卡片局部坐标，按钮命中检测必须换算到全局
		if _card_hits_button(card, card.get_global_rect().position + pos):
			return
		var now := Time.get_ticks_msec()
		if now < _tap_lock_ms:
			return
		_tap_lock_ms = now + 150
		on_tap.call()
	)


static func _card_hits_button(node: Node, global_pos: Vector2) -> bool:
	for child in node.get_children():
		if child is BaseButton and (child as Control).is_visible_in_tree():
			if (child as Control).get_global_rect().has_point(global_pos):
				return true
		if _card_hits_button(child, global_pos):
			return true
	return false


static func label(text_value: String, font_size: int = FONT_BODY, color: Color = COLOR_TEXT_PRIMARY) -> Label:
	var node := Label.new()
	node.text = text_value
	apply_font_size(node, font_size)
	node.add_theme_color_override("font_color", color)
	# 纯展示节点：不拦截触控，保证手指落在卡片上仍可滑动滚动容器
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


## 第三层辅助灰字：括号库存、进度分母、简短说明
static func dim_label(text_value: String, font_size: int = FONT_SMALL) -> Label:
	return label(text_value, font_size, COLOR_TEXT_SECONDARY)


## 第一层页面级标题：沉金褐（仪式感），毛笔粗体
static func title_label(text_value: String, font_size: int = FONT_TITLE) -> Label:
	var node := label(text_value, maxi(font_size, FONT_PAGE_TITLE), COLOR_TEXT_TITLE_GOLD)
	apply_brush_bold(node)
	return node


## 第一层卡片标题：焦墨黑，毛笔楷体
static func card_title_label(text_value: String, font_size: int = FONT_CARD_TITLE,
		color: Color = COLOR_TEXT_TITLE) -> Label:
	var node := label(text_value, maxi(font_size, FONT_CARD_TITLE), color)
	apply_brush_kai(node)
	return node


## 卡片内区块/小节标题：统一走毛笔楷体（ma_shan_zheng），字号仍受全局缩放控制。
## 大屏（MEDIUM / WIDE）下若用裸 label 会退回系统默认字体，与页面风格割裂。
static func section_title_label(text_value: String, font_size: int = FONT_SECTION_TITLE,
		color: Color = COLOR_TEXT_TITLE_GOLD) -> Label:
	var node := label(text_value, font_size, color)
	apply_brush_kai(node)
	return node


## 境界层数 / 关键数值：清晰加粗无衬线（手机小字号下「一层」~「九层」不糊成一团）。
static func apply_realm_font(control: Control) -> void:
	if control == null:
		return
	control.add_theme_font_override("font", make_bold_font())


static func apply_bold(label_node: Label) -> void:
	if label_node == null:
		return
	# 独立实例：不改写 make_font() 的共享缓存，避免全站正文被连带加粗
	label_node.add_theme_font_override("font", make_bold_font())


static func wrap_label(text_value: String, font_size: int = FONT_SMALL,
		color: Color = COLOR_TEXT_SECONDARY) -> Label:
	var node := label(text_value, font_size, color)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return node


static func button(text_value: String, accent: bool = false) -> Button:
	var node := Button.new()
	node.text = text_value
	node.focus_mode = Control.FOCUS_NONE
	node.custom_minimum_size = Vector2(0, TOUCH_MIN)
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if accent:
		node.add_theme_color_override("font_color", COLOR_AMBER)
		node.add_theme_color_override("font_hover_color", COLOR_AMBER)
	# 主操作按钮统一 16px，与 44px 触控高度匹配
	apply_font_size(node, FONT_CARD_TITLE)
	# 统一挂接程序化轻敲音（AudioManager 关闭音效时自身会忽略）
	node.pressed.connect(_play_click)
	UiMotion.bind_press(node)
	return node


static func _play_click() -> void:
	if AudioManager != null:
		AudioManager.play_click()


## 导航按钮自行控制音效时，移除通用轻敲音，避免同一次点击叠两层
static func silence_button_click(button: Button) -> void:
	if button == null:
		return
	var click := Callable(ThemeBuilder, "_play_click")
	if button.pressed.is_connected(click):
		button.pressed.disconnect(click)


static func small_button(text_value: String, accent: bool = false) -> Button:
	var node := button(text_value, accent)
	apply_font_size(node, 13)
	var transparent := Color(0, 0, 0, 0)
	var box := panel_box(COLOR_SUBTLE, transparent, 8, 0, 10)
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	node.add_theme_stylebox_override("normal", box)
	var hover := panel_box(COLOR_SUBTLE_HOVER, transparent, 8, 0, 10)
	hover.content_margin_top = 8
	hover.content_margin_bottom = 8
	node.add_theme_stylebox_override("hover", hover)
	var pressed := panel_box(COLOR_SUBTLE_PRESSED, transparent, 8, 0, 10)
	pressed.content_margin_top = 8
	pressed.content_margin_bottom = 8
	node.add_theme_stylebox_override("pressed", pressed)
	node.add_theme_color_override("font_color", COLOR_TEXT)
	node.add_theme_color_override("font_hover_color", COLOR_TEXT)
	return node


## 并排按钮防溢出：文本超长时省略号裁切，最小宽不再随文字膨胀
static func clip_button_text(button: Button, tooltip: String = "") -> void:
	if button == null:
		return
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if tooltip != "":
		button.tooltip_text = tooltip


## 收紧按钮左右内边距：只改该按钮自身的 StyleBox 覆盖，不污染全局 Theme
static func tighten_button_padding(button: Button, padding: float = 6.0) -> void:
	if button == null:
		return
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		if not button.has_theme_stylebox_override(state):
			continue
		var box := button.get_theme_stylebox(state)
		if box is StyleBoxFlat:
			var flat := box as StyleBoxFlat
			flat.content_margin_left = padding
			flat.content_margin_right = padding


static func icon_button(text_value: String, size: float = 44.0) -> Button:
	var node := button(text_value)
	node.custom_minimum_size = Vector2(size, size)
	apply_font_size(node, 20)
	return node


## 全局唯一「?」说明按钮：30×30 触控区 + 20×20 水墨矢量图标，右上角标题行专用。
## 默认透明底，悬停/按下统一淡青墨圆角 15px；点击自动轻触音并回调。
static func create_help_button(on_pressed: Callable) -> Button:
	var node := Button.new()
	node.focus_mode = Control.FOCUS_NONE
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.custom_minimum_size = Vector2(30, 30)
	node.size_flags_horizontal = Control.SIZE_SHRINK_END
	node.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	node.tooltip_text = "查看说明"
	var transparent := Color(0, 0, 0, 0)
	node.add_theme_stylebox_override("normal", panel_box(transparent, transparent, 15, 0, 0))
	node.add_theme_stylebox_override("hover", panel_box(COLOR_JADE_SOFT, transparent, 15, 0, 0))
	node.add_theme_stylebox_override("pressed",
		panel_box(COLOR_JADE_SOFT.darkened(0.06), transparent, 15, 0, 0))
	node.add_theme_stylebox_override("disabled", panel_box(transparent, transparent, 15, 0, 0))
	var icon := TextureRect.new()
	icon.texture = IconLibrary.get_ui_icon("help")
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_child(icon)
	icon.set_anchors_preset(Control.PRESET_CENTER)
	icon.offset_left = -10.0
	icon.offset_top = -10.0
	icon.offset_right = 10.0
	icon.offset_bottom = 10.0
	node.pressed.connect(func() -> void:
		if AudioManager != null:
			AudioManager.play_tap()
		if on_pressed.is_valid():
			on_pressed.call()
	)
	return node


## 标题卡右侧 110×110 深墨线稿暗纹；置于内容之下，不参与交互
static func attach_header_watermark(header: PanelContainer, texture: Texture2D) -> void:
	if header == null or texture == null:
		return
	header.clip_contents = true
	var layer := Control.new()
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(layer)
	header.move_child(layer, 0)
	var watermark := TextureRect.new()
	watermark.texture = texture
	watermark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	watermark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	watermark.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	watermark.modulate = Color(1, 1, 1, 0.06)
	watermark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(watermark)
	# 贴靠右下内角：错开经验/悟道文字主区，暗纹不压字
	watermark.anchor_left = 1.0
	watermark.anchor_right = 1.0
	watermark.anchor_top = 1.0
	watermark.anchor_bottom = 1.0
	watermark.offset_left = -118.0
	watermark.offset_right = -8.0
	watermark.offset_top = -112.0
	watermark.offset_bottom = -2.0


## 灵岛迷你倒计时条：6px 高 / 3px 圆角 / 暖褐半透明底轨（value=剩余占比，随秒数缩短）
static func mini_countdown_bar(fill_color: Color) -> ProgressBar:
	var bar := progress_bar(fill_color, 6.0)
	bar.add_theme_stylebox_override("background",
		panel_box(Color(0.55, 0.49, 0.40, 0.28), Color(0.55, 0.49, 0.40, 0.36), 3, 1, 0))
	var fill := flat_box(fill_color, 3, 0, 0)
	fill.border_color = fill_color
	fill.set_border_width_all(0)
	bar.add_theme_stylebox_override("fill", fill)
	return bar


static func progress_bar(fill_color: Color = COLOR_JADE, height: float = 10.0) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.value = 0.0
	bar.step = 0.001
	bar.custom_minimum_size = Vector2(0, height)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 轨道必须比卡片底色明显深一档：原先 COLOR_TRACK(#E8E0D1) 在 #FCF9F2 卡片上几乎看不见，
	# 8~10px 的条会被误读成一条黑线或下划线。这里改用深一档的槽色 + 1px 描边。
	bar.add_theme_stylebox_override("background",
		panel_box(COLOR_BAR_TRACK, COLOR_BAR_TRACK_EDGE, PROGRESS_BG_RADIUS, 1, 0))
	var fill := flat_box(fill_color, PROGRESS_FILL_RADIUS, 0, 0)
	fill.border_color = fill_color
	fill.set_border_width_all(0)
	bar.add_theme_stylebox_override("fill", fill)
	return bar


## 通用残影血条：外层 Control 裁切，ghost 在下 / main 在上，二者共占满容器。
## meta 暴露 main/ghost 给 UiMotion.set_afterimage_value()，避免调用方重复建条。
static func create_afterimage_bar(fill_color: Color,
		ghost_color: Color = HP_GHOST_COLOR, height: float = 10.0) -> Control:
	var root := Control.new()
	root.name = "AfterimageBar"
	root.clip_contents = true
	root.custom_minimum_size = Vector2(0, height)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ghost := progress_bar(ghost_color, height)
	ghost.name = "Ghost"
	ghost.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(ghost)
	var main := progress_bar(fill_color, height)
	main.name = "Main"
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(main)
	root.set_meta("afterimage_main", main)
	root.set_meta("afterimage_ghost", ghost)
	return root


static var _chip_style_cache: Dictionary = {}


static func chip_box(color: Color) -> StyleBoxFlat:
	var cache_key := color.to_html(true)
	var cached: StyleBoxFlat = _chip_style_cache.get(cache_key, null)
	if cached != null:
		return cached
	var bg := COLOR_CARD.lerp(color, 0.14)
	if color == COLOR_JADE or color == COLOR_EMERALD:
		bg = COLOR_JADE_SOFT
	elif color == COLOR_CINNABAR:
		bg = COLOR_CINNABAR_SOFT
	elif color == COLOR_AMBER:
		bg = COLOR_GOLD_SOFT
	var box := panel_box(bg, Color(0, 0, 0, 0), 5, 0, 8)
	box.content_margin_top = 2
	box.content_margin_bottom = 2
	_chip_style_cache[cache_key] = box
	return box


static func chip(text_value: String, color: Color) -> PanelContainer:
	# 去线框：纯浅色底块 + 同色系文字
	var fg := color.darkened(0.08)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", chip_box(color))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var text_node := label(text_value, 12, fg)
	text_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(text_node)
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return panel


static func card_panel(bg: Color = COLOR_CARD, border: Color = COLOR_BORDER, radius: int = 10,
		margin: int = 12) -> PanelContainer:
	var panel := PanelContainer.new()
	var cache_key := "%s|%s|%d|%d" % [bg.to_html(true), border.to_html(true), radius, margin]
	var style: StyleBoxFlat = _card_style_cache.get(cache_key, null)
	if style == null:
		style = panel_box(card_color(bg), border, radius, 1, margin)
		apply_card_shadow(style)
		_card_style_cache[cache_key] = style
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	return panel


static func vbox(separation: int = 8) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	box.mouse_filter = Control.MOUSE_FILTER_PASS
	return box


static func hbox(separation: int = 8) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	box.mouse_filter = Control.MOUSE_FILTER_PASS
	return box


static func separator(height: int = 1, color: Color = COLOR_BORDER) -> ColorRect:
	var rect := ColorRect.new()
	rect.color = color
	rect.custom_minimum_size = Vector2(0, height)
	rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


static func spacer(height: float) -> Control:
	var node := Control.new()
	node.custom_minimum_size = Vector2(0, height)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


static func expander() -> Control:
	var node := Control.new()
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


static func section_header(title_text: String, subtitle: String = "") -> VBoxContainer:
	var box := vbox(2)
	box.add_child(title_label(title_text, FONT_TITLE))
	if subtitle != "":
		box.add_child(dim_label(subtitle, FONT_SMALL))
	return box


## 自定义拖拽滚动守卫容器（全站列表统一接入）：
## 仅「真触屏按下拖动」或「鼠标左键按住拖动」才交给引擎原生拖滚；
## 无按压的悬停 MouseMotion 一律不触发滚动逻辑（杜绝鼠标悬停自动滚动），
## 无主 ScreenDrag（残留触点 / 跨弹窗状态粘连）在派发前直接吞掉；
## 松开 / 鼠标移出 / 失焦 / 隐藏 / 失去窗口焦点时强制复位拖拽状态。
## 说明：引擎内置滚动在 C++ 层处理，super._gui_input 不可达——故用 _input
## 前置过滤（早于 GUI 派发），命中的无主拖动 set_input_as_handled 即可拦下。
class GuardedScrollContainer extends ScrollContainer:
	## 全实例共享按压账本：多列表对「无主拖动」的判定必须一致
	static var _touch_down := {}
	static var _press_inside := false
	static var _is_dragging := false


	func _input(event: InputEvent) -> void:
		if event is InputEventScreenTouch:
			var touch := event as InputEventScreenTouch
			if touch.pressed:
				_touch_down[touch.index] = true
				# 仅在列表可视矩形内初始化起始点
				if get_global_rect().has_point(touch.position):
					_press_inside = true
			else:
				_touch_down.erase(touch.index)
				_is_dragging = false
				if _touch_down.is_empty():
					_press_inside = false
		elif event is InputEventMouseButton:
			var mouse := event as InputEventMouseButton
			if mouse.button_index == MOUSE_BUTTON_LEFT:
				if mouse.pressed:
					if get_global_rect().has_point(mouse.position):
						_press_inside = true
				else:
					_is_dragging = false
					_press_inside = false
		elif event is InputEventScreenDrag:
			# 严格校验：拖动仅在「按压点始于列表可视矩形内」时放行；
			# 悬停游走 / 残留触点 / 触控板轻点锁定的无主拖动一律吞掉，
			# 绝不让其驱动 scroll_vertical
			if not _press_inside and not _touch_down.has(
					(event as InputEventScreenDrag).index):
				_is_dragging = false
				get_viewport().set_input_as_handled()
				return
			_is_dragging = true
		elif event is InputEventMouseMotion:
			var motion := event as InputEventMouseMotion
			# 悬停（左键未按住）：不触发任何滚动逻辑，原样放行给子节点；
			# 左键按住的拖动交给引擎原生处理，绝不手写偏移累加
			if (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) == 0:
				_is_dragging = false
				_press_inside = false


	func _notification(what: int) -> void:
		match what:
			NOTIFICATION_MOUSE_EXIT, NOTIFICATION_FOCUS_EXIT, \
					NOTIFICATION_WM_WINDOW_FOCUS_OUT:
				_reset_drag_state()
			NOTIFICATION_VISIBILITY_CHANGED:
				if not is_visible_in_tree():
					_reset_drag_state()


	func _reset_drag_state() -> void:
		_touch_down.clear()
		_press_inside = false
		_is_dragging = false


static func scroll_container() -> ScrollContainer:
	var scroll := GuardedScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	# 死区 16px：默认 0 时手指 1~2px 微抖就会被判成滑动并抢走按钮的 pressed；
	# follow_focus=false 防止焦点跳转打断拖拽
	scroll.scroll_deadzone = 16
	scroll.follow_focus = false
	style_scrollbar(scroll.get_v_scroll_bar())
	return scroll


# ---------------------------------------------------------------- 材料五档品阶配色
## 五档矿物水墨品阶色（唯一配色口径，越高级越华贵）：
## 凡材 素砚灰 → 灵材 翠竹青 → 玄材 沧溟蓝 → 仙材 紫霞绛 → 神材 赤金辉
const COLOR_GRADE_1_MORTAL := Color("#7A7165")   # 一阶 · 凡材（素砚灰）
const COLOR_GRADE_2_SPIRIT := Color("#227454")   # 二阶 · 灵材（翠竹青）
const COLOR_GRADE_3_MYSTIC := Color("#1E62A8")   # 三阶 · 玄材（沧溟蓝）
const COLOR_GRADE_4_IMMORTAL := Color("#7B369E") # 四阶 · 仙材（紫霞绛）
const COLOR_GRADE_5_DIVINE := Color("#BA5B10")   # 五阶 · 神材（赤金辉，区别于危险朱砂）


# ---------------------------------------------------------------- UI 物理微动效
## 全站一次性 Tween 管理：挂在节点 meta 上，新动画自动 kill 旧的（防连点打架/错位）。
## 红线：动画仅插值 modulate / position / scale 等合成属性，禁止逐帧改布局尺寸/字体/StyleBox。

static func _start_ui_tween(node: Control) -> Tween:
	if node.has_meta("_ui_tween"):
		var old: Variant = node.get_meta("_ui_tween")
		if old is Tween and (old as Tween).is_valid():
			(old as Tween).kill()
	var tw := node.create_tween()
	node.set_meta("_ui_tween", tw)
	return tw


## 页面切入微动效：淡入 + 12px 极轻上浮（0.18s）。切页复用缓存时自动重置基准。
static func animate_page_enter(panel: Control) -> void:
	if panel == null:
		return
	var tw := _start_ui_tween(panel)
	var base_y := panel.position.y
	panel.modulate.a = 0.0
	panel.position.y = base_y + 12.0
	tw.set_parallel(true)
	tw.tween_property(panel, "modulate:a", 1.0, 0.18) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "position:y", base_y, 0.18) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## 弹窗开启：底部抽屉 = 从下 36px 滑入 + 淡入；居中弹窗 = 0.92 弹性舒展 + 淡入。
static func animate_modal_open(card: Control, backdrop: ColorRect = null,
		is_bottom_sheet: bool = true) -> void:
	if card == null:
		return
	var tw := _start_ui_tween(card)
	tw.set_parallel(true)
	if backdrop != null:
		backdrop.modulate.a = 0.0
		tw.tween_property(backdrop, "modulate:a", 1.0, 0.20)
	card.modulate.a = 0.0
	if is_bottom_sheet:
		var base_y := card.position.y
		card.position.y = base_y + 36.0
		tw.tween_property(card, "position:y", base_y, 0.22) \
			.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		tw.tween_property(card, "modulate:a", 1.0, 0.22) \
			.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	else:
		card.pivot_offset = card.size * 0.5
		card.scale = Vector2(0.92, 0.92)
		tw.tween_property(card, "scale", Vector2.ONE, 0.22) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(card, "modulate:a", 1.0, 0.22)


## 弹窗收起：反向动画（0.16s）后触发 on_finished 释放/隐藏；期间 mouse_filter 忽略防连点。
static func animate_modal_close(card: Control, backdrop: ColorRect,
		on_finished: Callable, is_bottom_sheet: bool = true) -> void:
	if card == null:
		on_finished.call()
		return
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tw := _start_ui_tween(card)
	tw.set_parallel(true)
	if backdrop != null:
		tw.tween_property(backdrop, "modulate:a", 0.0, 0.16)
	if is_bottom_sheet:
		tw.tween_property(card, "position:y", card.position.y + 28.0, 0.16) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tw.tween_property(card, "modulate:a", 0.0, 0.16) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	else:
		card.pivot_offset = card.size * 0.5
		tw.tween_property(card, "scale", Vector2(0.94, 0.94), 0.16) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tw.tween_property(card, "modulate:a", 0.0, 0.16)
	tw.chain().tween_callback(func() -> void:
		card.mouse_filter = Control.MOUSE_FILTER_PASS
		on_finished.call())


## 按钮微按压反馈：按下 0.06s 缩至 0.97，抬起/滑动取消 0.10s 回弹。
static func _attach_press_feedback(button: BaseButton) -> void:
	if button.has_meta("press_feedback"):
		return
	button.set_meta("press_feedback", true)
	button.button_down.connect(func() -> void:
		button.pivot_offset = button.size * 0.5
		var tw := _start_ui_tween(button)
		tw.tween_property(button, "scale", Vector2(0.97, 0.97), 0.06))
	button.button_up.connect(func() -> void: press_release(button))


static func press_release(button: BaseButton) -> void:
	if button == null:
		return
	var tw := _start_ui_tween(button)
	tw.tween_property(button, "scale", Vector2.ONE, 0.10) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## 三才槽位指示色（全站唯一口径）：
## 0 主修 黛玉青 / 1 分神 鎏金琥珀 / 2 化身 紫霞绛
static func slot_dot_color(slot_idx: int) -> Color:
	match clampi(slot_idx, 0, 2):
		1:
			return COLOR_TEXT_GOLD
		2:
			return COLOR_GRADE_4_IMMORTAL
	return COLOR_TEXT_JADE


static func get_material_grade_color(tier: int) -> Color:
	match clampi(tier, 1, 5):
		2:
			return COLOR_GRADE_2_SPIRIT
		3:
			return COLOR_GRADE_3_MYSTIC
		4:
			return COLOR_GRADE_4_IMMORTAL
		5:
			return COLOR_GRADE_5_DIVINE
	return COLOR_GRADE_1_MORTAL


## 旧入口兼容（内部统一走 get_material_grade_color）
static func material_grade_color(tier: int) -> Color:
	return get_material_grade_color(tier)


## 品阶名称统一渲染：只调字色，绝不覆盖控件原有字体族
## （神材曾用 apply_bold 会把毛笔楷体换成黑体，导致同页字体不统一——已移除）
static func apply_material_grade_style(node: Control, tier: int) -> void:
	if node == null:
		return
	var color := get_material_grade_color(tier)
	if node is RichTextLabel:
		(node as RichTextLabel).add_theme_color_override("default_color", color)
	else:
		node.add_theme_color_override("font_color", color)


## 全站统一入口①：按物品 ID 应用品阶字色（Label/RichTextLabel）。
## 非材料/灵种返回 false、保持原样；神材自动加粗。
static func apply_item_grade_style(ctrl: Control, item_id: String) -> bool:
	if ctrl == null:
		return false
	var grade: Dictionary = DataRegistry.get_item_grade(item_id)
	if grade.is_empty():
		return false
	apply_material_grade_style(ctrl, int(grade["tier"]))
	return true


## 功法版：道藏功法名称按五档品阶字色（仅改字色，不覆盖字体族）
static func apply_technique_grade_style(ctrl: Control, tech_id: String) -> bool:
	if ctrl == null:
		return false
	var grade: Dictionary = DataRegistry.get_technique_grade(tech_id)
	if grade.is_empty():
		return false
	apply_material_grade_style(ctrl, int(grade["tier"]))
	return true


## 妖兽/妖魔版：仅改字色（含镇魔塔 tower_<floor> 动态妖魔）
static func apply_enemy_grade_style(ctrl: Control, enemy_id: String) -> bool:
	if ctrl == null:
		return false
	var grade: Dictionary = DataRegistry.get_enemy_grade(enemy_id)
	if grade.is_empty():
		return false
	apply_material_grade_style(ctrl, int(grade["tier"]))
	return true


static func format_enemy_grade_bbcode(enemy_id: String, text_value: String = "") -> String:
	var name := text_value if text_value != "" else DataRegistry.get_enemy_name(enemy_id)
	var grade: Dictionary = DataRegistry.get_enemy_grade(enemy_id)
	if grade.is_empty():
		return name
	return "[color=%s]%s[/color]" % [
		hex(get_material_grade_color(int(grade["tier"]))), name]


## 镇魔塔按楼层直接着色
static func apply_tower_grade_style(ctrl: Control, floor: int) -> bool:
	if ctrl == null:
		return false
	var grade: Dictionary = DataRegistry.get_tower_enemy_grade(floor)
	if grade.is_empty():
		return false
	apply_material_grade_style(ctrl, int(grade["tier"]))
	return true


static func format_technique_grade_bbcode(tech_id: String, text_value: String = "") -> String:
	var name := text_value if text_value != "" else String(
		DataRegistry.get_technique(tech_id).name) if DataRegistry.get_technique(tech_id) != null else tech_id
	var grade: Dictionary = DataRegistry.get_technique_grade(tech_id)
	if grade.is_empty():
		return name
	return "[color=%s]%s[/color]" % [
		hex(get_material_grade_color(int(grade["tier"]))), name]


## 全站统一入口②：品阶着色 BBCode（颜色走 hex()，神材加粗；非材料原样返回）。
## text 为空时自动取物品名。
static func format_item_grade_bbcode(item_id: String, text_value: String = "") -> String:
	var name := text_value if text_value != "" else DataRegistry.get_item_name(item_id)
	var grade: Dictionary = DataRegistry.get_item_grade(item_id)
	if grade.is_empty():
		return name
	# 只上色不加粗：RichTextLabel 内 [b] 会切换 bold_font，同排字形突变
	return "[color=%s]%s[/color]" % [
		hex(get_material_grade_color(int(grade["tier"]))), name]


## 纯文本 → 品阶着色 BBCode：把句中出现的材料/灵种名逐个着色（名称长的优先，
## 避免「青叶草」误伤「青叶草灵种」）。用于离线玉简、掉落文本等自由文本。
static func colorize_item_names_bbcode(text_value: String) -> String:
	var names: Array = []
	for key in DataRegistry.items.keys():
		var item = DataRegistry.get_item(String(key))
		if item == null:
			continue
		if DataRegistry.get_material_grade(String(key)).is_empty():
			continue
		names.append({"id": String(key), "name": item.display_name})
	# 长名优先 + 单遍从左到右扫描：避免「青叶草」套进已着色的「青叶草灵种」
	names.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a["name"]).length() > String(b["name"]).length())
	var out := ""
	var i := 0
	while i < text_value.length():
		var matched := false
		for entry in names:
			var n := String(entry["name"])
			if n != "" and text_value.substr(i, n.length()) == n:
				out += format_item_grade_bbcode(String(entry["id"]), n)
				i += n.length()
				matched = true
				break
		if not matched:
			out += text_value[i]
			i += 1
	return out


## 「?」帮助浮层通用万物品阶图例（BBCode，颜色与实物名称 100% 同源）
static func material_grade_legend_bbcode() -> String:
	return "[color=%s]凡阶[/color]（炼气） · [color=%s]灵阶[/color]（筑基） · " % [
		hex(get_material_grade_color(1)), hex(get_material_grade_color(2))] \
		+ "[color=%s]玄阶[/color]（金丹/元婴） · [color=%s]仙阶[/color]（化神/炼虚） · " % [
		hex(get_material_grade_color(3)), hex(get_material_grade_color(4))] \
		+ "[color=%s]神阶[/color]（合体/大乘）" % hex(get_material_grade_color(5))


## BBCode 富文本标签（颜色值必须由 hex(COLOR_*) 生成，禁止硬编码字面量）
static func bbcode_label(bbcode: String, font_size: int = FONT_CAPTION) -> RichTextLabel:
	var rich := RichTextLabel.new()
	rich.bbcode_enabled = true
	rich.text = bbcode
	rich.fit_content = true
	rich.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rich.add_theme_font_size_override("normal_font_size", scaled_font_size(font_size))
	return rich


# ---------------------------------------------------------------- 移动端滚动条

static var _blank_icon: ImageTexture = null


## 1px 透明图标：顶掉默认上下箭头
static func blank_icon() -> ImageTexture:
	if _blank_icon == null:
		var image := Image.create(1, 1, false, Image.FORMAT_RGBA8)
		image.fill(Color(0, 0, 0, 0))
		_blank_icon = ImageTexture.create_from_image(image)
	return _blank_icon


## 超细移动端滚动条：3px、透明轨道、低透明度玉灰滑块、无箭头。
## 参数用基类 ScrollBar：竖滑（VScrollBar）与横滑（HScrollBar）共用同一套皮肤。
static func style_scrollbar(bar: ScrollBar) -> void:
	if bar == null:
		return
	bar.custom_minimum_size = Vector2(0, 3) if bar is HScrollBar else Vector2(3, 0)
	var track := panel_box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 0, 0)
	track.content_margin_left = 0
	track.content_margin_right = 0
	track.content_margin_top = 0
	track.content_margin_bottom = 0
	bar.add_theme_stylebox_override("scroll", track)
	bar.add_theme_stylebox_override("scroll_focus", track)
	bar.add_theme_stylebox_override("grabber",
		panel_box(Color(COLOR_BORDER, 0.85), Color(0, 0, 0, 0), 2, 0, 0))
	bar.add_theme_stylebox_override("grabber_highlight",
		panel_box(Color(COLOR_JADE, 0.55), Color(0, 0, 0, 0), 2, 0, 0))
	bar.add_theme_stylebox_override("grabber_pressed",
		panel_box(Color(COLOR_JADE, 0.75), Color(0, 0, 0, 0), 2, 0, 0))
	var blank := blank_icon()
	for icon_name in ["increment", "decrement", "increment_icon", "decrement_icon"]:
		bar.add_theme_icon_override(icon_name, blank)
	bar.add_theme_constant_override("minimum_grab_thickness", 12)


# ---------------------------------------------------------------- 三才槽位按钮

## 主修 / 分神 / 化身：同字体、同字号、同高度、同圆角，只靠配色分层（避免「分神」看起来像禁用）
const SLOT_BUTTON_PALETTE: Dictionary = {
	0: {"bg": "#276953", "border": "#1E5644", "fg": "#FBF8F2", "hover": "#1F5D49", "pressed": "#1B5140"},
	1: {"bg": "#E5EFEA", "border": "#276953", "fg": "#1E5644", "hover": "#DBEAE4", "pressed": "#D5E5DE"},
	2: {"bg": "#F5ECDC", "border": "#8F6022", "fg": "#7A5018", "hover": "#EFE3CE", "pressed": "#EADBC2"},
}
## 停止态：朱砂暖红浅底 + 描边，与未运转态明显区分
const STOP_BUTTON_PALETTE: Dictionary = {
	"bg": "#F7EAE6", "border": "#B34233", "fg": "#9E3527",
	"hover": "#F1DFDA", "pressed": "#EBD2CC",
}


static func apply_slot_button(button: Button, slot_index: int) -> void:
	if button == null:
		return
	var palette: Dictionary = SLOT_BUTTON_PALETTE.get(clampi(slot_index, 0, 2),
		SLOT_BUTTON_PALETTE[0])
	_apply_slot_palette(button, palette)


static func apply_stop_slot_button(button: Button) -> void:
	if button == null:
		return
	_apply_slot_palette(button, STOP_BUTTON_PALETTE)


## 统一套用：2px 描边（1.5px 在 StyleBoxFlat 里只能取整）+ 8px 内边距，44 高可容纳 4 字
static func _apply_slot_palette(button: Button, palette: Dictionary) -> void:
	var bg := Color(String(palette["bg"]))
	var border := Color(String(palette["border"]))
	var fg := Color(String(palette["fg"]))
	button.custom_minimum_size = Vector2(0, TOUCH_MIN)
	button.add_theme_stylebox_override("normal", panel_box(bg, border, 8, 2, 8))
	button.add_theme_stylebox_override("hover",
		panel_box(Color(String(palette["hover"])), border, 8, 2, 8))
	button.add_theme_stylebox_override("pressed",
		panel_box(Color(String(palette["pressed"])), border, 8, 2, 8))
	button.add_theme_stylebox_override("disabled",
		panel_box(COLOR_SUBTLE, COLOR_BORDER, 8, 1, 8))
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(key, fg)
	button.add_theme_color_override("font_disabled_color", COLOR_TEXT_MUTED)
	apply_font_size(button, FONT_CARD_TITLE)
	apply_brush_kai(button)


# ---------------------------------------------------------------- 主次按钮

## 主操作按钮：玉青实底 + 微厚底边，轻拟物按压感
static func apply_primary_button(button: Button) -> void:
	if button == null:
		return
	var normal := panel_box(COLOR_JADE, COLOR_JADE_EDGE, 8, 0, 10)
	normal.border_width_bottom = 2
	var hover := panel_box(COLOR_JADE_DARK, COLOR_JADE_EDGE, 8, 0, 10)
	hover.border_width_bottom = 2
	var pressed := panel_box(COLOR_JADE_DARK, Color(0, 0, 0, 0), 8, 0, 10)
	pressed.content_margin_top += 2
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled",
		panel_box(Color("#D8D0BF"), Color(0, 0, 0, 0), 8, 0, 10))
	button.add_theme_color_override("font_color", COLOR_CARD)
	button.add_theme_color_override("font_hover_color", COLOR_CARD)
	button.add_theme_color_override("font_pressed_color", COLOR_CARD)
	button.add_theme_color_override("font_disabled_color", Color("#7A7267"))


## 次操作按钮：暖石实底无框；danger = true 时用柔和朱砂浅底
static func apply_secondary_button(button: Button, danger: bool = false) -> void:
	if button == null:
		return
	var bg := COLOR_CINNABAR_SOFT if danger else COLOR_SUBTLE
	var border := COLOR_CINNABAR_EDGE if danger else Color(0, 0, 0, 0)
	var fg := COLOR_CINNABAR if danger else COLOR_TEXT
	button.add_theme_stylebox_override("normal", panel_box(bg, border, 8, 1 if danger else 0, 10))
	button.add_theme_stylebox_override("hover",
		panel_box(bg.darkened(0.04), border, 8, 1 if danger else 0, 10))
	button.add_theme_stylebox_override("pressed",
		panel_box(bg.darkened(0.08), border, 8, 1 if danger else 0, 10))
	button.add_theme_stylebox_override("disabled",
		panel_box(Color("#F0EADF"), Color(0, 0, 0, 0), 8, 0, 10))
	button.add_theme_color_override("font_color", fg)
	button.add_theme_color_override("font_hover_color", fg)
	button.add_theme_color_override("font_pressed_color", fg)
	button.add_theme_color_override("font_disabled_color", Color("#7A7267"))


## 开关 / 分段选中态：ON 为玉青浅底 + 细边，OFF 为暖石无框
static func apply_toggle_button(button: Button, on: bool) -> void:
	if button == null:
		return
	var bg := COLOR_JADE_SOFT if on else COLOR_SUBTLE
	var border := COLOR_JADE if on else Color(0, 0, 0, 0)
	var fg := COLOR_JADE if on else COLOR_TEXT_DIM
	button.add_theme_stylebox_override("normal",
		panel_box(bg, border, 8, 1 if on else 0, 10))
	button.add_theme_stylebox_override("hover",
		panel_box(bg.darkened(0.03), border, 8, 1 if on else 0, 10))
	button.add_theme_stylebox_override("pressed",
		panel_box(bg.darkened(0.06), border, 8, 1 if on else 0, 10))
	button.add_theme_color_override("font_color", fg)
	button.add_theme_color_override("font_hover_color", fg)
	button.add_theme_color_override("font_pressed_color", fg)


## 图例用真实色点
static func color_dot(color: Color, dot_size: float = 8.0) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(dot_size, dot_size)
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", circle_box(color, dot_size))
	return panel


# ---------------------------------------------------------------- 触控

## 让 ScrollContainer 内的装饰性节点不吞掉滑动事件。
## 规则：Label/ProgressBar/ColorRect 设为 IGNORE；ScrollContainer 保持 STOP（自己处理拖拽）；
## 其余容器与**按钮**统一 PASS。
##
## 按钮必须是 PASS 而不是 STOP：Godot 的 ScrollContainer 只有在「自己收到按下事件」时才会
## 记录 drag_touch_index，之后才响应 ScreenDrag。手指如果按在 STOP 的按钮上，按下事件被按钮
## 独占，滑动事件永远不会进入 ScrollContainer —— 真机表现就是「按在按钮上怎么滑都不动」。
## PASS = 既能收到点击，又把事件继续传给父级 ScrollContainer。
static func prepare_touch(root: Node) -> void:
	if root == null:
		return
	if root is Control:
		var ctrl := root as Control
		if ctrl is ScrollContainer:
			ctrl.mouse_filter = Control.MOUSE_FILTER_STOP
			# §4.1：死区 16 + 不跟随焦点，滑动手势不被焦点跳转打断
			(ctrl as ScrollContainer).scroll_deadzone = 16
			(ctrl as ScrollContainer).follow_focus = false
		elif ctrl is Label or ctrl is ProgressBar or ctrl is ColorRect or ctrl is TextureRect \
				or ctrl is RichTextLabel:
			ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		else:
			# §4.1 红线：全站所有 Button（无一例外）一律 PASS，按在按钮上也能滑动列表；
			# 防误触由 _attach_scroll_guard 的 14px 滑动守卫承担
			ctrl.mouse_filter = Control.MOUSE_FILTER_PASS
			if ctrl is BaseButton:
				_attach_scroll_guard(ctrl as BaseButton)
				_attach_press_feedback(ctrl as BaseButton)
	for child in root.get_children():
		prepare_touch(child)


## 14px 滑动防误触守卫（meta 去重，可重复调用 prepare_touch）：
## 按钮位于 ScrollContainer 内时记录按下点，位移 >=14px 即标记拖拽并取消按压态，
## 抬起时 accept_event() 阻断 pressed；<14px 的轻点原样放行（100% 一次即中）。
static func _attach_scroll_guard(button: BaseButton) -> void:
	if button.has_meta("scroll_guard"):
		return
	# 不在滚动容器里的按钮不需要守卫（如顶栏固定按钮）
	var node: Node = button.get_parent()
	var in_scroll := false
	while node != null:
		if node is ScrollContainer:
			in_scroll = true
			break
		node = node.get_parent()
	if not in_scroll:
		return
	button.set_meta("scroll_guard", true)
	button.focus_mode = Control.FOCUS_NONE
	button.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	button.set_meta("_drag_start", Vector2.INF)
	button.set_meta("_scroll_dragged", false)
	button.gui_input.connect(func(event: InputEvent) -> void:
		var pos := Vector2.INF
		var is_down := false
		var is_up := false
		var is_move := false
		if event is InputEventScreenTouch:
			var touch := event as InputEventScreenTouch
			pos = touch.position
			is_down = touch.pressed
			is_up = not touch.pressed
		elif event is InputEventScreenDrag:
			pos = (event as InputEventScreenDrag).position
			is_move = true
		elif event is InputEventMouseButton:
			var mouse := event as InputEventMouseButton
			if mouse.button_index != MOUSE_BUTTON_LEFT:
				return
			pos = mouse.position
			is_down = mouse.pressed
			is_up = not mouse.pressed
		elif event is InputEventMouseMotion:
			if not button.is_pressed():
				return
			pos = (event as InputEventMouseMotion).position
			is_move = true
		if is_down:
			button.set_meta("_drag_start", pos)
			button.set_meta("_scroll_dragged", false)
		elif is_move:
			var start: Vector2 = button.get_meta("_drag_start", Vector2.INF)
			if start != Vector2.INF and not bool(button.get_meta("_scroll_dragged", false)):
				if start.distance_to(pos) >= 14.0:
					button.set_meta("_scroll_dragged", true)
					button.button_pressed = false
					press_release(button)
		elif is_up:
			var dragged := bool(button.get_meta("_scroll_dragged", false))
			button.set_meta("_drag_start", Vector2.INF)
			button.set_meta("_scroll_dragged", false)
			if dragged:
				press_release(button)   # 滑动取消也要回弹按压态
				button.accept_event()
	)


## 给按钮叠加纯装饰性文字/圆点（不拦截点击）
## 朱砂 / 琥珀 / 玉青 小方印
static func create_seal_badge(text_value: String, style_type: String = "cinnabar") -> PanelContainer:
	# 朱砂 / 泥金 / 玉青实底白字小印
	var bg := COLOR_CINNABAR
	var border := COLOR_CINNABAR
	var font_color := COLOR_CARD
	if style_type == "gold":
		bg = COLOR_AMBER
		border = COLOR_AMBER
	elif style_type == "jade":
		bg = COLOR_JADE
		border = COLOR_JADE
	var box := panel_box(bg, border, 3, 1, 4)
	box.content_margin_top = 1
	box.content_margin_bottom = 1
	box.content_margin_left = 5
	box.content_margin_right = 5
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", box)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var text_node := label(text_value, 10, font_color)
	text_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(text_node)
	return panel


static func icon_rect(texture: Texture2D, icon_size: int = 20) -> TextureRect:
	var node := TextureRect.new()
	node.texture = texture
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	node.custom_minimum_size = Vector2(icon_size, icon_size)
	node.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


static func decorate_button(button_node: Button, left_text: String, right_text: String = "",
		dot_color: Color = Color(0, 0, 0, 0), icon: Texture2D = null) -> Dictionary:
	var row := HBoxContainer.new()
	button_node.add_child(row)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 14.0
	row.offset_right = -14.0
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 6)

	var icon_node: TextureRect = null
	if icon != null:
		icon_node = icon_rect(icon, 20)
		button_node.add_child(icon_node)
		icon_node.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
		icon_node.offset_left = 12.0
		icon_node.offset_top = -10.0
		icon_node.offset_bottom = 10.0
		row.offset_left = 42.0

	var left := label(left_text, maxi(FONT_CARD_TITLE - 1, 15))
	apply_brush_kai(left)
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.clip_text = true
	left.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(left)

	var right := label(right_text, 12, COLOR_TEXT_DIM)
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(right)

	# 「dot」升级为圆点组容器（HBox）：同一行可并排多枚槽位色圆点
	var dot := HBoxContainer.new()
	dot.add_theme_constant_override("separation", 2)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(dot)
	set_row_dots(dot, [] if dot_color.a <= 0.0 else [dot_color])

	return {"left": left, "right": right, "dot": dot, "icon": icon_node}


## 行内运行圆点组：按颜色数组重建（空数组=清空隐藏；多槽并发时并排多枚）
static func set_row_dots(dot_box: Container, colors: Array) -> void:
	if dot_box == null:
		return
	for child in dot_box.get_children():
		dot_box.remove_child(child)
		child.queue_free()
	for color in colors:
		var dot := PanelContainer.new()
		dot.custom_minimum_size = Vector2(8, 8)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.add_theme_stylebox_override("panel", circle_box(color, 8.0))
		dot_box.add_child(dot)
	dot_box.visible = not colors.is_empty()
