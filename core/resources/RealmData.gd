class_name RealmData
extends Resource
## 境界静态数据基类：等级上限、离线收益上限、修为门槛、基础属性与渡劫参数。

@export var id: String = ""
@export var display_name: String = ""
## 0 炼气 / 1 筑基 / 2 金丹 / 3 元婴 / 4 化神 / 5 炼虚 / 6 合体 / 7 大乘 / 8 真仙
@export var tier: int = 0
@export var stage: int = 1
@export var skill_level_cap: int = 20
@export var offline_cap_hours: float = 12.0
## 填满后晋升下一境界所需的修为；0 表示当前为 MVP 的终点（不再自动晋升）
@export var cultivation_required: float = 0.0
## 兼容旧字段：等价于 max_action_slots >= 2，新代码请读 combat_independent / max_action_slots
@export var unlocks_dual_cultivation: bool = false
## 战斗是否独立于百艺槽位（筑基「神识御敌」起为 true：秘境与百艺并行不打断）
@export var combat_independent: bool = false
## 可同时运转的百艺槽位上限：1 主修 / 2 +分神 / 3 +化身
@export var max_action_slots: int = 1
@export var requires_tribulation: bool = false

## ---- 基础属性（含前序境界累计加成） ----
@export var max_hp: int = 100
@export var attack: int = 8
@export var defense: int = 2

## 全局动作耗时乘数（金丹「洞府灵阵」0.9）
@export var action_interval_multiplier: float = 1.0

## ---- 渡劫参数 ----
## 渡劫天雷基础伤害
@export var tribulation_damages: Array = []
@export var tribulation_duration: float = 20.0
## 门票物品 id
@export var tribulation_item: String = ""
## 渡劫成功后晋升到的境界
@export var tribulation_target: String = ""
@export var tribulation_name: String = ""

## 本境界的吐纳修炼名（四字）：炼气「吐纳筑基」→ 筑基「筑基凝丹」→ 金丹「凝丹化婴」
## → 元婴「元婴化神」→ 大乘「证道飞升」；缺省兜底「吐纳修行」
@export var meditation_name: String = "吐纳修行"

@export var accent_color: Color = Color("#e0a458")

func get_tier_name() -> String:
	match tier:
		0:
			return "炼气期"
		1:
			return "筑基期"
		2:
			return "金丹期"
		3:
			return "元婴期"
		4:
			return "化神期"
		5:
			return "炼虚期"
		6:
			return "合体期"
		7:
			return "大乘期"
		8:
			return "真仙"
		_:
			return "凡尘"

func get_full_name() -> String:
	return display_name
