class_name EnemyData
extends Resource
## 秘境怪物静态数据基类（含掉落表）。

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var region_id: String = "wild_wolf_forest"
@export var max_hp: int = 100
@export var attack: int = 10
@export var attack_interval: float = 2.6
@export var defense: int = 0
@export var accuracy: float = 0.9
@export var dodge: float = 0.0
@export var is_boss: bool = false
@export var xp_reward: float = 25.0
## Array[Dictionary]: {"item_id": String, "min": int, "max": int, "chance": float}
@export var loot_table: Array = []
## 图标源 enemy_id（镇魔塔动态守将复用全秘境妖兽造型；空 = 用自身 id 解析图标）
@export var icon_id: String = ""


## 图标解析键：动态塔敌带 icon_id，其余用自身 id
func get_icon_key() -> String:
	return icon_id if icon_id != "" else id


func get_name_suffix() -> String:
	return "（头目）" if is_boss else ""

func get_loot_text() -> String:
	var parts: Array[String] = []
	for entry in loot_table:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var dict: Dictionary = entry
		var item_id := String(dict.get("item_id", ""))
		var lo := int(dict.get("min", 1))
		var hi := int(dict.get("max", lo))
		var chance := float(dict.get("chance", 1.0))
		# 大数走万/亿紧凑格式：「灵石 60万~80万（100%）」，消除一长串零
		var amount_text := "×%s" % GameFormulas.format_num(float(lo)) if lo == hi \
			else "%s~%s" % [GameFormulas.format_num(float(lo)),
				GameFormulas.format_num(float(hi))]
		parts.append("%s %s（%d%%）" % [DataRegistry.get_item_name(item_id), amount_text, int(round(chance * 100.0))])
	return "，".join(parts)
