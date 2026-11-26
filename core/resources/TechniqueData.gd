class_name TechniqueData
extends Resource
## 藏经阁功法：可解锁、可装备到运转槽、可消耗贡献+灵石参悟升级。

enum UnlockType { POINTS, DROP }

@export var id: String = ""
@export var name: String = ""
@export var school: String = "wood"          ## wood / sword / shield
@export var description: String = ""
@export var unlock_type: int = UnlockType.POINTS
@export var unlock_cost_points: int = 60
@export var drop_enemy_id: String = ""
@export var drop_chance: float = 0.0
## 效果键 -> 基础数值（Lv1）；每级线性 +25%，Lv5 = 200%
@export var effects: Dictionary = {}
@export var icon_key: String = "tech_wood"

const MAX_LEVEL: int = 5


func is_drop_only() -> bool:
	return unlock_type == UnlockType.DROP


func school_name() -> String:
	match school:
		"wood":
			return "种田丹修"
		"sword":
			return "剑修爆发"
		"shield":
			return "苟命渡劫"
		_:
			return "杂学"


func get_effect(key: String) -> float:
	return float(effects.get(key, 0.0))


## 参悟 Lv1~Lv5 的倍率：1.0 / 1.25 / 1.5 / 1.75 / 2.0
static func level_multiplier(level: int) -> float:
	return 1.0 + 0.25 * float(clampi(level, 1, MAX_LEVEL) - 1)


func get_scaled_effect(key: String, level: int) -> float:
	# 九霄迅雷步攻击加成按 +4% / +6% / +8% / +10% / +12% 平滑成长，
	# 避免通用倍率让首重直接到 +8%。
	if id == "tech_xunlei" and key == "attack_pct":
		return 0.04 + 0.02 * float(clampi(level, 1, MAX_LEVEL) - 1)
	return get_effect(key) * level_multiplier(level)
