class_name TooltipHelper
extends RefCounted
## 轻量悬浮提示工具：统一挂接 tooltip 文本，避免各面板重复设置。


static func attach(control: Control, text_value: String) -> Control:
	if control == null or text_value == "":
		return control
	control.tooltip_text = text_value
	return control


static func attach_lines(control: Control, lines: Array) -> Control:
	var parts: Array[String] = []
	for line in lines:
		parts.append(String(line))
	return attach(control, "\n".join(parts))


static func stat_line(label_text: String, value_text: String) -> String:
	return "%s：%s" % [label_text, value_text]
