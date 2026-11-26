class_name ItemData
extends Resource
## 物品静态数据基类。
## 由 DataRegistry 在启动时集中实例化注册；字段与 .tres 资源一一对应，
## 后续可直接把 DataRegistry 中的实例导出为 .tres 再改用 ResourceLoader 加载。

enum Element { NONE, WOOD, FIRE, EARTH, METAL, WATER }
enum Category { MATERIAL, CONSUMABLE, EQUIPMENT, CURRENCY }

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
## 预留矢量图标路径（MVP 阶段为空，界面用配色 + 文字徽标代替）
@export var icon_path: String = ""
@export var element: Element = Element.NONE
@export var category: Category = Category.MATERIAL
@export var stackable: bool = true
@export var max_stack: int = 9999
@export var sell_price: int = 1

@export_group("Equipment")
## "weapon" / "armor"
@export var equip_slot: String = ""
@export var attack_bonus: int = 0
@export var defense_bonus: int = 0
@export var max_hp_bonus: int = 0
@export var accuracy_bonus: int = 0
## 装备自带会心 / 闪避百分比数值（如 2 表示 +2%）
@export var crit_bonus: float = 0.0
@export var dodge_bonus: float = 0.0

@export_group("Consumable")
@export var heal_amount: int = 0
@export var cultivation_gain: int = 0
## 天雷减伤比例（厚土护身符 0.4）
@export var ward_ratio: float = 0.0

static func element_name(value: int) -> String:
	match value:
		Element.WOOD:
			return "木"
		Element.FIRE:
			return "火"
		Element.EARTH:
			return "土"
		Element.METAL:
			return "金"
		Element.WATER:
			return "水"
		_:
			return "无"

static func element_color(value: int) -> Color:
	match value:
		Element.WOOD:
			return Color("#2E7D5B")
		Element.FIRE:
			return Color("#C2432D")
		Element.EARTH:
			return Color("#9A6B2F")
		Element.METAL:
			return Color("#52606D")
		Element.WATER:
			return Color("#2A6B8C")
		_:
			return Color("#8C8375")

static func category_name(value: int) -> String:
	match value:
		Category.CONSUMABLE:
			return "丹药符箓"
		Category.EQUIPMENT:
			return "法宝装备"
		Category.CURRENCY:
			return "通用"
		_:
			return "灵材"

func is_equipment() -> bool:
	return category == Category.EQUIPMENT and equip_slot != ""

func is_consumable() -> bool:
	return category == Category.CONSUMABLE

func get_stat_summary() -> String:
	var parts: Array[String] = []
	if attack_bonus != 0:
		parts.append("攻击 +%d" % attack_bonus)
	if defense_bonus != 0:
		parts.append("防御 +%d" % defense_bonus)
	if max_hp_bonus != 0:
		parts.append("气血 +%d" % max_hp_bonus)
	if accuracy_bonus != 0:
		parts.append("命中 +%d" % accuracy_bonus)
	if crit_bonus != 0.0:
		parts.append("会心 +%d%%" % int(round(crit_bonus)))
	if dodge_bonus != 0.0:
		parts.append("闪避 +%d%%" % int(round(dodge_bonus)))
	if heal_amount != 0:
		parts.append("回复 %d 气血" % heal_amount)
	if cultivation_gain != 0:
		parts.append("修为 +%d" % cultivation_gain)
	if ward_ratio > 0.0:
		parts.append("天雷减伤 %d%%" % int(round(ward_ratio * 100.0)))
	return "，".join(parts)
