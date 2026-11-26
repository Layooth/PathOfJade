class_name ShopUpgradeData
extends Resource
## 「仙坊阁」商品静态数据基类。
## 结构固定，后续可直接导出为 .tres 交给 ResourceLoader 加载。

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
## "gear"（法器宝具）/ "farm"（洞府扩建）/ "seed"（灵种杂货）
@export var category: String = "gear"
@export var cost_stones: int = 0
## 购买所需的最低境界序号（0 = 炼气一层）
@export var required_realm_index: int = 0
## 前置商品 id（需已拥有）
@export var prerequisite_id: String = ""
## interval / double_chance / quality_pct / cultivation_pct / heal_pct / unlock_plot / grant_item
@export var effect_type: String = ""
## 作用目标：技能 id / "all" / 地块序号 / 物品 id
@export var effect_target: String = ""
@export var effect_value: float = 0.0
## 附加效果：{effect_type: value}，与主 effect_* 同时生效（如「太虚混沌炉」双倍 + 全制造减耗）
@export var extra_effects: Dictionary = {}
## 0 = 无限量供应（灵种），>0 = 一次性/可升级上限
@export var max_level: int = 1
@export var icon_path: String = ""

func is_repeatable() -> bool:
	return max_level <= 0

func get_cost_text() -> String:
	return "%s 灵石" % GameFormulas.format_num(float(cost_stones))

func get_effect_text() -> String:
	var text := _effect_text_for(effect_type, effect_value)
	for key in extra_effects.keys():
		var extra := _effect_text_for(String(key), float(extra_effects[key]))
		if extra == "":
			continue
		text = extra if text == "" else text + " · " + extra
	return text


## 摘要词条保持紧凑（450 宽单行不截断），完整说明在卡片详情浮层里
func _effect_text_for(kind: String, value: float) -> String:
	match kind:
		"interval":
			return "耗时 %+d%%" % int(round(value * 100.0))
		"double_chance":
			return "双倍 %+d%%" % int(round(value * 100.0))
		"quality_pct":
			return "精良率 %+d%%" % int(round(value * 100.0))
		"cultivation_pct":
			return "修为 %+d%%" % int(round(value * 100.0))
		"heal_pct":
			return "回血 %+d%%" % int(round(value * 100.0))
		"all_craft_interval":
			return "全制造 %+d%%" % int(round(value * 100.0))
		"max_hp_pct":
			# 混元镇道钟：此前未映射导致卡片效果行整段空白
			return "气血上限 %+d%%" % int(round(value * 100.0))
		"unlock_plot":
			return "解锁第 %d 块灵田" % (int(effect_target) + 1)
		"grant_item":
			return "获得 %s" % DataRegistry.get_item_name(effect_target)
	return ""
