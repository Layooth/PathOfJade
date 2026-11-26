class_name UiMotion
extends RefCounted
## 古籍风轻动效工具：统一按钮回弹、呼吸与数值缓动。
## 所有动效只改视觉属性，不参与容器布局。


static func bind_press(button: Button) -> void:
	if button == null or button.has_meta("ui_motion_press"):
		return
	button.set_meta("ui_motion_press", true)
	button.resized.connect(func() -> void:
		button.pivot_offset = button.size * 0.5
	)
	button.button_down.connect(func() -> void:
		if button.disabled:
			return
		_kill_meta_tween(button, "ui_motion_press_tween")
		button.pivot_offset = button.size * 0.5
		var tween := button.create_tween()
		tween.tween_property(button, "scale", Vector2(0.96, 0.96), 0.04) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		button.set_meta("ui_motion_press_tween", tween)
	)
	button.button_up.connect(func() -> void:
		_kill_meta_tween(button, "ui_motion_press_tween")
		button.pivot_offset = button.size * 0.5
		var tween := button.create_tween()
		tween.tween_property(button, "scale", Vector2.ONE, 0.04) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		button.set_meta("ui_motion_press_tween", tween)
	)


static func breathe(control: Control, active: bool) -> void:
	if control == null:
		return
	control.pivot_offset = control.size * 0.5
	var existing: Variant = control.get_meta("ui_motion_breathe") if control.has_meta("ui_motion_breathe") else null
	if active:
		if existing is Tween and (existing as Tween).is_valid():
			return
		var tween := control.create_tween().set_loops()
		tween.tween_property(control, "scale", Vector2(1.04, 1.04), 0.7) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(control, "scale", Vector2.ONE, 0.7) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		control.set_meta("ui_motion_breathe", tween)
	else:
		if existing is Tween and (existing as Tween).is_valid():
			(existing as Tween).kill()
		control.set_meta("ui_motion_breathe", null)
		var tween := control.create_tween()
		tween.tween_property(control, "scale", Vector2.ONE, 0.18) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


static func tween_progress(bar: ProgressBar, target: float, duration: float = 0.22) -> void:
	if bar == null:
		return
	_kill_meta_tween(bar, "ui_motion_progress_tween")
	var tween := bar.create_tween()
	tween.tween_property(bar, "value", clampf(target, 0.0, 1.0), duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	bar.set_meta("ui_motion_progress_tween", tween)


## 成长条通用缓动：首次/切页 instant 直设；升级导致比例回落时先 0.08s 拉满再归零追新值。
static func advance_progress(bar: ProgressBar, target: float,
		duration: float = 0.22, instant: bool = false) -> void:
	if bar == null:
		return
	var value := clampf(target, 0.0, 1.0)
	if instant or not bar.has_meta("ui_progress_ready"):
		_kill_meta_tween(bar, "ui_motion_progress_tween")
		bar.value = value
		bar.set_meta("ui_progress_ready", true)
		return
	var current := bar.value
	if value < current - 0.02 and current > 0.02 and value > 0.001:
		_kill_meta_tween(bar, "ui_motion_progress_tween")
		var tween := bar.create_tween()
		tween.tween_property(bar, "value", 1.0, 0.08) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_callback(func() -> void: bar.value = 0.0)
		tween.tween_property(bar, "value", value, duration) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		bar.set_meta("ui_motion_progress_tween", tween)
		return
	tween_progress(bar, value, duration)


## ThemeBuilder.create_afterimage_bar() 的统一驱动：掉血立即落主条、残影延迟追赶；
## 回血主条与残影并行上涨；instant 用于切怪/重开战对齐，禁止旧残影跨怪拖尾。
static func set_afterimage_value(container: Control, target: float,
		instant: bool = false) -> void:
	if container == null or not container.has_meta("afterimage_main"):
		return
	var main: ProgressBar = container.get_meta("afterimage_main")
	var ghost: ProgressBar = container.get_meta("afterimage_ghost")
	var value := clampf(target, 0.0, 1.0)
	_kill_meta_tween(container, "ui_afterimage_rise_tween")
	if instant:
		_kill_meta_tween(ghost, "ui_afterimage_ghost_tween")
		_kill_meta_tween(main, "ui_motion_progress_tween")
		main.value = value
		ghost.value = value
		return
	if value < main.value - 0.0001:
		# 掉血：主条瞬时落到新值，残影原地顿 0.15s 再 0.35s 追赶
		_kill_meta_tween(main, "ui_motion_progress_tween")
		main.value = value
		_kill_meta_tween(ghost, "ui_afterimage_ghost_tween")
		var tween := ghost.create_tween()
		tween.tween_interval(0.15)
		tween.tween_property(ghost, "value", value, 0.35) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		ghost.set_meta("ui_afterimage_ghost_tween", tween)
	elif value > main.value + 0.0001:
		# 回血：0.20s 同步上涨，残影贴在主条下方不外露
		_kill_meta_tween(ghost, "ui_afterimage_ghost_tween")
		var tween := container.create_tween()
		tween.set_parallel(true)
		tween.tween_property(main, "value", value, 0.20) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(ghost, "value", value, 0.20) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		container.set_meta("ui_afterimage_rise_tween", tween)
	else:
		main.value = value
		ghost.value = value


## 低血呼吸：0.78~1.0，单程 0.45s；与 breathe() 的 scale 动画互不干扰。
static func breathe_alpha(control: Control, active: bool) -> void:
	if control == null:
		return
	var existing: Variant = control.get_meta("ui_motion_breathe_alpha") \
		if control.has_meta("ui_motion_breathe_alpha") else null
	if active:
		if existing is Tween and (existing as Tween).is_valid():
			return
		var tween := control.create_tween().set_loops()
		tween.tween_property(control, "modulate:a", 0.78, 0.45) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(control, "modulate:a", 1.0, 0.45) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		control.set_meta("ui_motion_breathe_alpha", tween)
	else:
		if existing is Tween and (existing as Tween).is_valid():
			(existing as Tween).kill()
		control.set_meta("ui_motion_breathe_alpha", null)
		control.modulate.a = 1.0


## 满轮节拍：1.18 高光 0.10s 平滑回落，先 kill 防止高速动作 Tween 堆积。
static func flash_once(control: Control) -> void:
	if control == null:
		return
	_kill_meta_tween(control, "ui_motion_flash_tween")
	control.modulate = Color(1.18, 1.18, 1.15, 1.0)
	var tween := control.create_tween()
	tween.tween_property(control, "modulate", Color.WHITE, 0.10) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	control.set_meta("ui_motion_flash_tween", tween)


static func fade_in(control: Control, duration: float = 0.12) -> void:
	if control == null:
		return
	_kill_meta_tween(control, "ui_motion_fade_tween")
	control.modulate.a = 0.0
	var tween := control.create_tween()
	tween.tween_property(control, "modulate:a", 1.0, duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	control.set_meta("ui_motion_fade_tween", tween)


static func pulse(control: Control, peak: float = 1.12, duration: float = 0.22) -> void:
	if control == null:
		return
	control.pivot_offset = control.size * 0.5
	_kill_meta_tween(control, "ui_motion_pulse_tween")
	var tween := control.create_tween()
	tween.tween_property(control, "scale", Vector2(peak, peak), duration * 0.4) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", Vector2.ONE, duration * 0.6) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	control.set_meta("ui_motion_pulse_tween", tween)


static func _kill_meta_tween(node: Node, meta_key: String) -> void:
	var existing: Variant = node.get_meta(meta_key) if node.has_meta(meta_key) else null
	if existing is Tween and (existing as Tween).is_valid():
		(existing as Tween).kill()
