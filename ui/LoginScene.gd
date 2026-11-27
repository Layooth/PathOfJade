extends Control
## 仙籍登录：快捷续途 / 道号登录 / 闭关独修。
## 入场不做本地缩放或弹跳，统一由 SceneTransition 宣纸淡出显现；退场仍轻下沉淡出。

const BG_COLOR: Color = Color("#F7F3E8")
## 450 竖屏卡片两侧各 25px（450-400）/2，满足 ≥24px 安全边距
const CARD_MARGIN: int = 24
const CARD_MAX_WIDTH: float = 400.0
## 主内容块上下弹性占位：底部 1.35 > 顶部 1.0，整体垂直居中略偏上
const TOP_SPACER_RATIO: float = 1.0
const BOTTOM_SPACER_RATIO: float = 1.35
## 副标题与登录卡间距（量化要求 20~24px）
const SUBTITLE_CARD_GAP: float = 22.0
## 左下角状态角标与右下角版本号同一水平基线（左 16 / 底 14）
const STATUS_DOT_SIZE: float = 8.0

## 登录页静态山水底图（1:1，1024×1024）；preload 保证第 0 帧纹理已就绪
## COVERED 等比铺满：竖屏裁左右、宽屏裁上下
const LOGIN_BG_TEXTURE: Texture2D = preload("res://assets/ui/login_bg_landscape.webp")

## 主内容层（标题区 + 状态胶囊 + 登录卡）：入场静止就位，退场时整体下沉淡出
var _main_layer: Control
var _card: PanelContainer
var _card_box: VBoxContainer
var _card_title_label: Label
var _username_label: Label
var _username_edit: LineEdit
var _secret_label: Label
var _secret_frame: PanelContainer
var _password_edit: LineEdit
var _secret_toggle: Button
var _identity_frame: PanelContainer
var _identity_box: HBoxContainer
var _identity_name_label: Label
var _hint_label: Label
var _submit_button: Button
var _offline_button: Button
var _secondary_divider: ColorRect
var _secondary_button: Button
## true=已验凭证的快捷续途态；false=道号/密令标准输入态
var _quick_mode: bool = false
var _mode_tween: Tween
## 左下角轻量状态角标：仅连通时显示，与右下角版本号同基线
var _status_badge: HBoxContainer
var _status_dot: ColorRect
var _status_label: Label

var _busy: bool = false
## 退场过渡中：独立于 _busy（登录流程会先置 _busy），防重复触发切场景
var _exiting: bool = false
var _health_known: bool = false


func _ready() -> void:
	# 第 0 帧最先挂载底层山水背景（preload 纹理已就绪），再构建任何前景控件
	_build_login_background()
	# 仙籍页早于 MainShell 加载存档：轻量读取存档里的字号档位，保证 1.20 大字同样适配
	ThemeBuilder.set_font_scale(ThemeBuilder.normalize_font_scale(_saved_font_scale()))
	theme = ThemeBuilder.build_theme()
	_build_ui()
	_prefill_auth()
	CloudSaveManager.health_checked.connect(_on_health_checked, CONNECT_ONE_SHOT)
	CloudSaveManager.probe_server(2.5)
	# 探针若因系统网络栈异常迟迟不回调，2.8s 后按「未通」兜底，绝不卡住登录页
	get_tree().create_timer(2.8).timeout.connect(func() -> void:
		if is_inside_tree() and not _health_known:
			_on_health_checked(false))


func _build_ui() -> void:
	_build_main()
	_build_status_badge()
	_build_patch_badge()


## 右下角天道卷号：纯文字贴角，1px 宣纸色文字阴影保证叠在山石上仍清晰
func _build_patch_badge() -> void:
	var rev := CloudSaveManager.get_current_patch_rev()
	var patch_text := "天道初开" if rev <= 0 else "天道第 %d 卷" % rev
	var text_value := "v%s · %s" % [ThemeBuilder.APP_DISPLAY_VERSION, patch_text]
	var badge := ThemeBuilder.label(text_value, ThemeBuilder.FONT_CAPTION,
		Color(0.173, 0.165, 0.149, 0.75))
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.size_flags_horizontal = Control.SIZE_SHRINK_END
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.anchor_left = 1.0
	badge.anchor_right = 1.0
	badge.anchor_top = 1.0
	badge.anchor_bottom = 1.0
	badge.offset_left = -160
	badge.offset_right = -14
	badge.add_theme_color_override("font_shadow_color", Color(0.97, 0.95, 0.91, 0.85))
	badge.add_theme_constant_override("shadow_offset_x", 1)
	badge.add_theme_constant_override("shadow_offset_y", 1)
	add_child(badge)
	# 按当前字号实际行高反推顶部 offset，保证底边距恒为 14px（不被 Label 最小高度顶掉）
	var badge_h := maxf(18.0, badge.get_combined_minimum_size().y)
	badge.custom_minimum_size = Vector2(0, badge_h)
	badge.offset_top = -14.0 - badge_h
	badge.offset_bottom = -14.0


## 全屏 1:1 水墨山水图，等比铺满视口（竖屏裁左右、宽屏裁上下）
func _build_login_background() -> void:
	var bg := TextureRect.new()
	bg.name = "LoginBgTexture"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var texture: Texture2D = LOGIN_BG_TEXTURE
	if texture != null:
		bg.texture = texture
	else:
		# 资源缺失兜底：纯宣纸底，绝不黑屏（preload 正常时不会走这里）
		var fallback := ColorRect.new()
		fallback.color = BG_COLOR
		fallback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg.add_child(fallback)
	add_child(bg)
	move_child(bg, 0)

	# 极淡宣纸雾：宽屏裁到山体时压暗背景，保证标题/副标题对比度
	var veil := ColorRect.new()
	veil.name = "LoginBgVeil"
	veil.color = Color(BG_COLOR, 0.20)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)
	move_child(veil, 1)


func _build_main() -> void:
	var margin := MarginContainer.new()
	margin.visible = true
	margin.scale = Vector2.ONE
	margin.modulate = Color(1, 1, 1, 1)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", CARD_MARGIN)
	margin.add_theme_constant_override("margin_right", CARD_MARGIN)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)
	# 记录主内容层：退场 Tween 只动它（父级是普通 Control，不与容器排版打架）
	_main_layer = margin

	# 上下弹性占位：底部 stretch_ratio 1.35 > 顶部 1.0，内容垂直居中略偏上
	var stack := ThemeBuilder.vbox(0)
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(stack)
	var top_space := Control.new()
	top_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	top_space.size_flags_stretch_ratio = TOP_SPACER_RATIO
	top_space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(top_space)

	# 内容块固定最大宽 400（450 竖屏左右各 25px），宽屏不拉宽
	var column := ThemeBuilder.vbox(0)
	column.custom_minimum_size = Vector2(CARD_MAX_WIDTH, 0)
	column.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stack.add_child(column)

	var header := ThemeBuilder.vbox(6)
	column.add_child(header)
	var title := ThemeBuilder.title_label("玉简问道", 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeBuilder.apply_brush_kai(title)
	_apply_paper_halo(title, 6)
	header.add_child(title)

	var subtitle := ThemeBuilder.wrap_label("一卷青简问长生，半盏清茶悟天道",
		ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_SECONDARY)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_paper_halo(subtitle, 4)
	header.add_child(subtitle)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, SUBTITLE_CARD_GAP)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(gap)
	column.add_child(_build_card())

	var bottom_space := Control.new()
	bottom_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bottom_space.size_flags_stretch_ratio = BOTTOM_SPACER_RATIO
	bottom_space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(bottom_space)


## 山水底图上的文字用宣纸色描边，宽屏裁到山体时仍保持清晰
func _apply_paper_halo(label: Label, size: int) -> void:
	label.add_theme_color_override("font_outline_color",
		Color(0.969, 0.953, 0.910, 0.95))
	label.add_theme_constant_override("outline_size", size)


## 左下角轻量状态角标：非按钮、无胶囊边框，与右下角版本号同一水平基线
func _build_status_badge() -> void:
	_status_badge = HBoxContainer.new()
	_status_badge.name = "SpiritStatusBadge"
	_status_badge.anchor_left = 0.0
	_status_badge.anchor_right = 0.0
	_status_badge.anchor_top = 1.0
	_status_badge.anchor_bottom = 1.0
	_status_badge.offset_left = 16
	_status_badge.offset_right = 212
	_status_badge.alignment = BoxContainer.ALIGNMENT_BEGIN
	_status_badge.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_status_badge.add_theme_constant_override("separation", 6)
	_status_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_badge.visible = false
	add_child(_status_badge)

	_status_dot = ColorRect.new()
	_status_dot.custom_minimum_size = Vector2(STATUS_DOT_SIZE, STATUS_DOT_SIZE)
	_status_dot.color = ThemeBuilder.COLOR_TEXT_JADE
	_status_dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_status_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_badge.add_child(_status_dot)

	_status_label = ThemeBuilder.label("灵脉已通 · 云篆可书", ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_JADE)
	_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_badge.add_child(_status_label)
	# 与右下版本号同高、同底边距 14px（按当前字号行高反推，1.20 档也不漂移）
	var badge_h := maxf(STATUS_DOT_SIZE + 2.0, _status_label.get_combined_minimum_size().y)
	_status_badge.custom_minimum_size = Vector2(0, badge_h)
	_status_badge.offset_top = -14.0 - badge_h
	_status_badge.offset_bottom = -14.0


func _build_card() -> PanelContainer:
	# 单层通透宣纸卡：微透底隐约透出山水 + 1px 淡墨细线，无嵌套内框
	_card = PanelContainer.new()
	_card.clip_contents = true
	_card.visible = true
	_card.scale = Vector2.ONE
	_card.modulate = Color(1, 1, 1, 1)
	_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_card.add_theme_stylebox_override("panel",
		ThemeBuilder.panel_box(Color(0.98, 0.965, 0.933, 0.90),
			Color(0.173, 0.165, 0.149, 0.18), 12, 1, 22))
	var box := ThemeBuilder.vbox(10)
	_card_box = box
	_card.add_child(box)

	_card_title_label = ThemeBuilder.card_title_label("仙籍登录",
		ThemeBuilder.FONT_CARD_TITLE, ThemeBuilder.COLOR_TEXT_TITLE_GOLD)
	_card_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeBuilder.apply_brush_kai(_card_title_label)
	box.add_child(_card_title_label)

	_username_label = ThemeBuilder.dim_label("道号", ThemeBuilder.FONT_CAPTION)
	box.add_child(_username_label)
	_username_edit = _make_edit("请输入2~16位道号")
	_username_edit.text_submitted.connect(_on_username_submitted)
	box.add_child(_username_edit)

	_secret_label = ThemeBuilder.dim_label("密令", ThemeBuilder.FONT_CAPTION)
	box.add_child(_secret_label)
	_build_secret_row(box)

	# 快捷续途态身份提示：浅玉青圆角玉牌 + 3px 紧致间距，绝不回填或保存明文密令
	_identity_frame = PanelContainer.new()
	_identity_frame.name = "IdentityJadePlate"
	_identity_frame.custom_minimum_size = Vector2(0, 42)
	_identity_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var identity_style := ThemeBuilder.panel_box(ThemeBuilder.COLOR_JADE_PAPER,
		ThemeBuilder.COLOR_BORDER, 6, 1, 8)
	identity_style.content_margin_left = 14
	identity_style.content_margin_right = 14
	_identity_frame.add_theme_stylebox_override("panel", identity_style)
	box.add_child(_identity_frame)

	_identity_box = ThemeBuilder.hbox(3)
	_identity_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_identity_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_identity_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_identity_box.clip_contents = true
	_identity_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_identity_frame.add_child(_identity_box)
	var identity_hint := ThemeBuilder.label("已验仙籍 · 道号 ·",
		ThemeBuilder.FONT_BODY, ThemeBuilder.COLOR_TEXT_PRIMARY)
	ThemeBuilder.apply_font_size(identity_hint, ThemeBuilder.FONT_BODY)
	identity_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	identity_hint.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_identity_box.add_child(identity_hint)
	# 道号宽度按文本自身计算，避免固定 112px 造成整行视觉重心左偏
	_identity_name_label = ThemeBuilder.label("", ThemeBuilder.FONT_BODY,
		ThemeBuilder.COLOR_TEXT_JADE)
	ThemeBuilder.apply_font_size(_identity_name_label, ThemeBuilder.FONT_BODY)
	_identity_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_identity_name_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_identity_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_identity_name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_identity_name_label.clip_text = false
	_identity_box.add_child(_identity_name_label)

	# 提示行默认隐藏：空文本不占高度，出现校验/状态提示时才撑开
	_hint_label = Label.new()
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hint_label.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT_JADE)
	ThemeBuilder.apply_font_size(_hint_label, ThemeBuilder.FONT_CAPTION)
	_hint_label.visible = false
	box.add_child(_hint_label)

	# 主次按钮组：主按钮全宽实心，次级纯文字紧随其下 8px
	var buttons := ThemeBuilder.vbox(8)
	box.add_child(buttons)
	_submit_button = ThemeBuilder.button("踏入仙途")
	_submit_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_submit_button.custom_minimum_size = Vector2(0, 44)
	ThemeBuilder.apply_font_size(_submit_button, ThemeBuilder.FONT_CARD_TITLE)
	ThemeBuilder.apply_brush_kai(_submit_button)
	ThemeBuilder.apply_primary_button(_submit_button)
	# 内边距收到 8：让实际高度贴住 44px（默认 10 会被毛笔字体内边距撑到 46）
	var jade := ThemeBuilder.panel_box(ThemeBuilder.COLOR_JADE,
		ThemeBuilder.COLOR_JADE_EDGE, 8, 0, 8)
	jade.border_width_bottom = 2
	var jade_hover := ThemeBuilder.panel_box(ThemeBuilder.COLOR_JADE_DARK,
		ThemeBuilder.COLOR_JADE_EDGE, 8, 0, 8)
	jade_hover.border_width_bottom = 2
	_submit_button.add_theme_stylebox_override("normal", jade)
	_submit_button.add_theme_stylebox_override("hover", jade_hover)
	_submit_button.add_theme_stylebox_override("pressed", jade_hover)
	ThemeBuilder.clip_button_text(_submit_button, "踏入仙途")
	_submit_button.pressed.connect(_on_submit_pressed)
	buttons.add_child(_submit_button)

	var secondary_row := ThemeBuilder.hbox(16)
	secondary_row.alignment = BoxContainer.ALIGNMENT_CENTER
	secondary_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	buttons.add_child(secondary_row)
	_offline_button = _make_offline_button("闭关独修")
	_offline_button.pressed.connect(_on_offline_pressed)
	secondary_row.add_child(_offline_button)
	_secondary_divider = ColorRect.new()
	_secondary_divider.color = ThemeBuilder.COLOR_CHROME_LINE
	_secondary_divider.custom_minimum_size = Vector2(1, 14)
	_secondary_divider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_secondary_divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	secondary_row.add_child(_secondary_divider)
	_secondary_button = _make_offline_button("切换道号")
	_secondary_button.pressed.connect(_on_secondary_pressed)
	secondary_row.add_child(_secondary_button)

	return _card


## 密令行：外框与道号输入框完全同款（圆角 8 / 高 42 / 同底同边），
## 内部无边框 LineEdit + 右侧纯文字「显/隐」，左右边缘与道号严格对齐
func _build_secret_row(parent: Control) -> void:
	_secret_frame = PanelContainer.new()
	_secret_frame.custom_minimum_size = Vector2(0, 42)
	_secret_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_secret_frame.add_theme_stylebox_override("panel", _input_style(false))
	parent.add_child(_secret_frame)

	var row := ThemeBuilder.hbox(2)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_secret_frame.add_child(row)

	_password_edit = LineEdit.new()
	_password_edit.placeholder_text = "请输入密令"
	_password_edit.secret = true
	_password_edit.secret_character = "●"
	_password_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_password_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for style_name in ["normal", "focus", "read_only"]:
		_password_edit.add_theme_stylebox_override(style_name, StyleBoxEmpty.new())
	_password_edit.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT)
	_password_edit.add_theme_color_override("font_placeholder_color", ThemeBuilder.COLOR_TEXT_MUTED)
	_password_edit.add_theme_color_override("caret_color", ThemeBuilder.COLOR_JADE)
	_password_edit.add_theme_font_size_override("font_size",
		ThemeBuilder.scaled_font_size(ThemeBuilder.FONT_BODY))
	_password_edit.text_submitted.connect(_on_password_submitted)
	_password_edit.focus_entered.connect(_on_secret_focus.bind(true))
	_password_edit.focus_exited.connect(_on_secret_focus.bind(false))
	row.add_child(_password_edit)

	_secret_toggle = Button.new()
	_secret_toggle.text = "显"
	_secret_toggle.flat = true
	_secret_toggle.focus_mode = Control.FOCUS_NONE
	_secret_toggle.custom_minimum_size = Vector2(36, 0)
	_secret_toggle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_secret_toggle.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for style_name in ["normal", "hover", "pressed", "disabled", "focus"]:
		_secret_toggle.add_theme_stylebox_override(style_name, StyleBoxEmpty.new())
	ThemeBuilder.apply_font_size(_secret_toggle, ThemeBuilder.FONT_BODY)
	_secret_toggle.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT_SECONDARY)
	_secret_toggle.add_theme_color_override("font_hover_color", ThemeBuilder.COLOR_JADE)
	_secret_toggle.add_theme_color_override("font_pressed_color", ThemeBuilder.COLOR_JADE)
	_secret_toggle.add_theme_color_override("font_disabled_color",
		Color(ThemeBuilder.COLOR_TEXT_MUTED, 0.5))
	_secret_toggle.tooltip_text = "切换密文明暗"
	_secret_toggle.pressed.connect(_on_secret_toggle_pressed)
	row.add_child(_secret_toggle)


## 输入框统一底/边样式（道号与密令共用，保证左右边缘与观感一致）
func _input_style(focused: bool) -> StyleBoxFlat:
	if focused:
		return ThemeBuilder.panel_box(ThemeBuilder.COLOR_JADE_SOFT,
			ThemeBuilder.COLOR_JADE, 8, 1, 10)
	return ThemeBuilder.panel_box(ThemeBuilder.COLOR_CARD_DEEP,
		ThemeBuilder.COLOR_BORDER, 8, 1, 10)


func _on_secret_focus(focused: bool) -> void:
	if _secret_frame != null:
		_secret_frame.add_theme_stylebox_override("panel", _input_style(focused))


func _make_edit(placeholder: String, secret: bool = false) -> LineEdit:
	var edit := LineEdit.new()
	edit.placeholder_text = placeholder
	edit.secret = secret
	edit.secret_character = "●"
	edit.custom_minimum_size = Vector2(0, 42)
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.add_theme_stylebox_override("normal", _input_style(false))
	edit.add_theme_stylebox_override("focus", _input_style(true))
	edit.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT)
	edit.add_theme_color_override("font_placeholder_color", ThemeBuilder.COLOR_TEXT_MUTED)
	edit.add_theme_color_override("caret_color", ThemeBuilder.COLOR_JADE)
	# apply_font_size 只覆盖 Label/Button/RichTextLabel，LineEdit 需显式取缩放后的字号
	edit.add_theme_font_size_override("font_size",
		ThemeBuilder.scaled_font_size(ThemeBuilder.FONT_BODY))
	return edit


func _saved_font_scale() -> float:
	if not FileAccess.file_exists("user://save_data.json"):
		return ThemeBuilder.FONT_SCALE_STANDARD
	var file := FileAccess.open("user://save_data.json", FileAccess.READ)
	if file == null:
		return ThemeBuilder.FONT_SCALE_STANDARD
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return ThemeBuilder.FONT_SCALE_STANDARD
	var state_variant: Variant = (parsed as Dictionary).get("state", {})
	if typeof(state_variant) != TYPE_DICTIONARY:
		return ThemeBuilder.FONT_SCALE_STANDARD
	var flags_variant: Variant = (state_variant as Dictionary).get("flags", {})
	if typeof(flags_variant) != TYPE_DICTIONARY:
		return ThemeBuilder.FONT_SCALE_STANDARD
	return float((flags_variant as Dictionary).get("font_scale",
		ThemeBuilder.FONT_SCALE_STANDARD))


func _make_offline_button(text_value: String) -> Button:
	# 次级纯文字入口：固定 96×44、无边框无底色；不裁剪文字，避免缩成 0 宽
	var button := Button.new()
	button.text = text_value
	button.visible = true
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.custom_minimum_size = Vector2(96, 44)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for style_name in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(style_name, StyleBoxEmpty.new())
	ThemeBuilder.apply_font_size(button, ThemeBuilder.FONT_BODY_SUB)
	var muted := ThemeBuilder.COLOR_TEXT_SECONDARY
	button.add_theme_color_override("font_color", muted)
	button.add_theme_color_override("font_hover_color", ThemeBuilder.COLOR_JADE)
	button.add_theme_color_override("font_pressed_color", ThemeBuilder.COLOR_JADE_DARK)
	button.add_theme_color_override("font_disabled_color", Color(muted, 0.4))
	return button


func _prefill_auth() -> void:
	var name := String(CloudSaveManager.auth.get("username", ""))
	_username_edit.text = name
	_password_edit.text = ""
	_apply_login_mode(CloudSaveManager.has_saved_identity())


## 快捷续途态 / 标准输入态切换；只显示节点，不销毁，避免重复建卡与焦点抖动
func _apply_login_mode(quick: bool) -> void:
	_quick_mode = quick
	var saved := CloudSaveManager.has_saved_identity()
	var name := String(CloudSaveManager.auth.get("username", ""))
	_card_title_label.text = "仙籍已验" if quick else "仙籍登录"
	_identity_frame.visible = quick
	_username_label.visible = not quick
	_username_edit.visible = not quick
	_secret_label.visible = not quick
	_secret_frame.visible = not quick
	_offline_button.visible = true
	_secondary_button.visible = quick or saved
	_secondary_divider.visible = quick or saved
	_secondary_button.text = "切换道号" if quick else "返回"
	# 任何模式切换都清掉内存中的密令：本地从不保存、也不跨账号残留
	_password_edit.text = ""
	_secret_toggle.text = "显"
	_password_edit.secret = true
	if quick:
		_identity_name_label.text = name
		# 按当前字号实测文本宽度给道号标签最小宽度：既避免 112px 固定宽度导致左偏，
		# 也避免 HBox 把无宽度 Label 压成 1px，保证「韩立」完整可见且整行居中
		var name_font := _identity_name_label.get_theme_font("font")
		var name_font_size := _identity_name_label.get_theme_font_size("font_size")
		var name_width := 0.0
		if name_font != null:
			name_width = name_font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT,
				-1, name_font_size).x
		_identity_name_label.custom_minimum_size = Vector2(ceili(name_width + 4.0), 0)
		_username_edit.text = ""
	else:
		_username_edit.text = name
	_set_hint("", false)


func _on_secondary_pressed() -> void:
	if _busy:
		return
	if AudioManager != null:
		AudioManager.play_tap()
	if _mode_tween != null and _mode_tween.is_valid():
		_mode_tween.kill()
	var target := not _quick_mode
	if target and not CloudSaveManager.has_saved_identity():
		return
	_mode_tween = create_tween()
	_mode_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_mode_tween.tween_property(_card_box, "modulate:a", 0.0, 0.08)
	_mode_tween.tween_callback(func() -> void: _apply_login_mode(target))
	_mode_tween.tween_property(_card_box, "modulate:a", 1.0, 0.12)


func _validate() -> String:
	var username := _username_edit.text.strip_edges()
	var password := _password_edit.text
	if username.length() < 2 or username.length() > 16:
		return "道号需为 2~16 个字"
	if password == "":
		return "请输入密令"
	return ""


func _on_submit_pressed() -> void:
	if _busy:
		return
	if _quick_mode:
		# 已验仙籍：不重发 /api/auth/login、不回填密令；云篆同步交给 MainShell.begin_session
		if not CloudSaveManager.has_saved_identity():
			_apply_login_mode(false)
			_set_hint("仙籍凭证已失效，请重验密令", true)
			return
		_set_busy(true, "仙籍已验")
		_set_hint("旧契犹在，径入洞天……", false)
		_enter_game("仙籍已验，正在踏入洞天……")
		return
	var error := _validate()
	if error != "":
		_set_hint(error, true)
		return
	_set_busy(true, "感应灵脉中...")
	var username := _username_edit.text.strip_edges()
	var password := _password_edit.text
	var result := await CloudSaveManager.login(username, password)
	if not is_inside_tree():
		return
	if not bool(result.get("ok", false)):
		_set_busy(false)
		_set_hint(String(result.get("message", "感应灵脉失败")), true)
		return
	# 云端版本检查与冲突弹窗统一交给 MainShell 的 begin_session，
	# 避免登录页提前自动覆盖本地进度
	_set_hint("仙籍已录，正入道途…", false)
	_enter_game("灵脉已接引，正在踏入洞天……")


func _on_offline_pressed() -> void:
	if _busy:
		return
	# 闭关独修绝不发起网络请求，也不改写云端凭证，只标记本地模式
	CloudSaveManager.set_offline_mode(true)
	_set_hint("已入闭关，灵脉可日后再续", false)
	_enter_game("万法归心，正在步入洞天……")


## 登录卡与标题区轻微下沉淡出后，转入全局水墨过渡切往主界面
func _enter_game(hint_text: String = "") -> void:
	if _exiting:
		return
	_exiting = true
	_busy = true
	if _submit_button != null:
		_submit_button.disabled = true
	if _offline_button != null:
		_offline_button.disabled = true
	if _secondary_button != null:
		_secondary_button.disabled = true
	if CloudSaveManager.get("skip_boot_overlay") != null:
		CloudSaveManager.set("skip_boot_overlay", true)
	var tween := create_tween()
	tween.set_parallel(true)
	if _main_layer != null:
		tween.tween_property(_main_layer, "position:y",
			_main_layer.position.y + 12.0, 0.20)
		tween.tween_property(_main_layer, "modulate:a", 0.0, 0.20)
	await tween.finished
	if not is_inside_tree():
		return
	SceneTransition.transition_to_scene("res://ui/MainShell.tscn", hint_text)


func _set_busy(value: bool, text_value: String = "") -> void:
	_busy = value
	_submit_button.disabled = value
	_offline_button.disabled = value
	if _secondary_button != null:
		_secondary_button.disabled = value
	if value:
		_submit_button.text = text_value
	else:
		_submit_button.text = "踏入仙途"


func _set_hint(text_value: String, is_error: bool) -> void:
	if _hint_label == null:
		return
	_hint_label.text = text_value
	# 空提示直接折叠，不占卡片垂直高度
	_hint_label.visible = text_value.strip_edges() != ""
	_hint_label.add_theme_color_override("font_color",
		ThemeBuilder.COLOR_TEXT_DANGER if is_error else ThemeBuilder.COLOR_TEXT_JADE)


func _on_username_submitted(_text: String) -> void:
	_password_edit.grab_focus()


func _on_password_submitted(_text: String) -> void:
	_on_submit_pressed()


## 密令明暗切换：默认密文显示「显」，点击转明文并显示「隐」
func _on_secret_toggle_pressed() -> void:
	_password_edit.secret = not _password_edit.secret
	_secret_toggle.text = "显" if _password_edit.secret else "隐"


## 连通性判定只控制左下角角标显隐：仅确认服务端连通时显示，断网完全隐藏，
## 不再挤在标题与卡片之间改变流式布局高度（登录卡绝不上下跳动）
func _on_health_checked(ok: bool) -> void:
	if _health_known or not is_inside_tree():
		return
	_health_known = true
	if _status_badge != null:
		_status_badge.visible = ok
	if ok:
		_status_dot.color = ThemeBuilder.COLOR_TEXT_JADE
		_status_label.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT_JADE)
