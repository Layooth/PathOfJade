class_name TooltipHelper
extends RefCounted
## 全站已停用鼠标悬停浮层：保留原有挂载接口为空操作，避免调用方改动或报错。
## 说明入口统一走点击：右上角「?」与百艺卡片 / 法宝 / 物品的 BottomSheet 详情。

const BOUND_META: String = "tooltip_custom_bound"

## 热重载 / 上一次运行残留的自绘浮层句柄
static var _layer: CanvasLayer
static var _panel: PanelContainer
static var _label: Label


## 兼容旧调用：不再注册任何 mouse_entered / mouse_exited 监听，也不创建浮层。
static func attach(control: Control, _text_value: String = "",
		_prefer_above: bool = true) -> Control:
	_cleanup_overlay()
	if control != null:
		# 去掉旧版的绑定标记与系统 tooltip，确保悬停时不会再冒出任何气泡
		if control.has_meta(BOUND_META):
			control.remove_meta(BOUND_META)
		if control.has_meta("tooltip_text"):
			control.remove_meta("tooltip_text")
		control.tooltip_text = ""
	return control


static func attach_lines(control: Control, _lines: Array) -> Control:
	return attach(control)


static func stat_line(label_text: String, value_text: String) -> String:
	return "%s：%s" % [label_text, value_text]


## 隐藏并释放任何已存在的悬停提示浮层（含热重载残留）
static func _cleanup_overlay() -> void:
	if _panel != null and is_instance_valid(_panel):
		_panel.visible = false
		_panel.queue_free()
	_panel = null
	_label = null
	if _layer != null and is_instance_valid(_layer):
		_layer.queue_free()
	_layer = null
