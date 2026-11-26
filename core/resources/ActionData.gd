class_name ActionData
extends Resource
## 采集 / 制造 / 吐纳 动作（配方）静态数据基类。

enum ActionType { GATHER, CRAFT, MEDITATE }

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
## herbalism / woodcutting / mining / alchemy / forging / talisman / cultivation
@export var skill_id: String = ""
@export var action_type: ActionType = ActionType.GATHER
## 基础耗时（秒），实际耗时受火候与悟道池修正
@export var base_interval: float = 3.0
@export var required_level: int = 1
@export var element: ItemData.Element = ItemData.Element.NONE
## item_id -> count
@export var inputs: Dictionary = {}
## item_id -> count（单次产出）
@export var outputs: Dictionary = {}
## item_id -> count（副产，来源反查与展示用）
@export var byproducts: Dictionary = {}
@export var skill_xp: float = 10.0
@export var mastery_xp: float = 8.0
## 吐纳类：单次获得境界修为
@export var cultivation_gain: int = 0
## 吐纳类：自动吞服丹药的额外修为总量
@export var pill_cultivation_gain: int = 0
## 吐纳类：可自动消耗的丹药 item_id
@export var pill_item_id: String = ""
## 是否可触发「木生火」（丹道）
@export var wood_fire_capable: bool = false
## 是否可触发「火生土 / 土生金」精良品质（器道）
@export var quality_capable: bool = false
## 是否可被悟道池「免料」特性影响（制造类）
@export var free_material_capable: bool = false

func is_craft() -> bool:
	return action_type == ActionType.CRAFT

func is_gather() -> bool:
	return action_type == ActionType.GATHER

func is_meditate() -> bool:
	return action_type == ActionType.MEDITATE

func get_first_output_id() -> String:
	for key in outputs.keys():
		return String(key)
	return ""

func get_input_text() -> String:
	if inputs.is_empty():
		return "无需材料"
	var parts: Array[String] = []
	for item_id in inputs.keys():
		parts.append("%s ×%d" % [DataRegistry.get_item_name(String(item_id)), int(inputs[item_id])])
	return " + ".join(parts)

func get_output_text() -> String:
	var parts: Array[String] = []
	for item_id in outputs.keys():
		parts.append("%s ×%d" % [DataRegistry.get_item_name(String(item_id)), int(outputs[item_id])])
	if action_type == ActionType.MEDITATE:
		parts.append("修为 +%d" % cultivation_gain)
	return "，".join(parts)
