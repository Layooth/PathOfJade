extends Node
## 静态数据注册表。
## MVP 阶段全部数据以字典表集中实例化为 Resource 对象并注册；
## 结构与 .tres 完全一致，后续可直接把单个实例导出为 .tres 交给 ResourceLoader。

# 与 ItemData.Element 枚举保持同值（常量表达式内不能跨脚本取枚举）
const E_NONE: int = 0
const E_WOOD: int = 1
const E_FIRE: int = 2
const E_EARTH: int = 3
const E_METAL: int = 4
const E_WATER: int = 5

const CAT_MATERIAL: int = 0
const CAT_CONSUMABLE: int = 1
const CAT_EQUIPMENT: int = 2
const CAT_CURRENCY: int = 3

const TYPE_GATHER: int = 0
const TYPE_CRAFT: int = 1
const TYPE_MEDITATE: int = 2

const SPIRIT_STONE: String = "item_spirit_stone"
const QI_PILL: String = "item_qi_pill"
const HEAL_POWDER: String = "item_heal_powder"
const FOUNDATION_PILL: String = "item_foundation_pill"
const EARTH_TALISMAN: String = "item_earth_talisman"
const QINGLING_WOOD: String = "item_qingling_wood"
const BEAST_CORE: String = "item_beast_core"
## 灵田专属奇珍
const SPIRIT_DEW: String = "item_spirit_nectar"
const CRIMSON_FRUIT: String = "item_crimson_fruit"
## 护道清心丹：服下直接 +1 层道心悟性
const QINGXIN_PILL: String = "item_qingxin_pill"
## 所有灵种收割时均可能伴生的奇珍（来源反查用）
const FARM_COMPANION_ITEMS: Array = ["item_spirit_nectar", "item_crimson_fruit"]

## 三才槽位差异化系数（主修求速 / 分神求悟 / 化身求奇珍）：
## 耗时倍率 / 悟道池经验加成 / 灵种副产概率加成（加法，封顶 95%）
const SLOT_TIME_MULT: Array = [1.0, 1.25, 1.45]
const SLOT_POOL_BONUS: Array = [0.0, 0.25, 0.0]
const SLOT_COMPANION_BONUS: Array = [0.0, 0.0, 0.25]
const COMPANION_CHANCE_CAP: float = 0.95

## v3 曲线：按「约 15 天挂机飞升」重排，19 境累计 356,780,000 修为
## 旧 v2 阶梯（100 / 220 / … / 4,200 …）已存档进 SaveManager.V2_REALM_REQUIREMENTS 供保级迁移
## 十大境界道体战力倍率乘区（大境界基值；小境界每级再 +6%：初期 ×1.00 / 中期 ×1.06 / 后期 ×1.12）
const REALM_COMBAT_MULT: Array = [1.0, 1.25, 1.65, 2.2, 3.2, 5.0, 8.0, 13.5, 22.0]

const QI_REQUIREMENTS: Array = [
	200.0, 600.0, 1500.0, 3500.0, 7500.0, 15000.0, 28000.0, 48000.0, 75700.0,
]
const QI_STAGE_NAMES: Array = ["一层", "二层", "三层", "四层", "五层", "六层", "七层", "八层", "九层"]
const TRIBULATION_DAMAGES: Array = [35, 50, 65, 85, 110]

## 吐纳技能随大境界换名：tier -> 四字修炼名（炼气 / 筑基 / 金丹 / 元婴 / 化神 / 炼虚 / 合体 / 大乘 / 真仙）
const CULTIVATION_NAMES: Dictionary = {
	0: "吐纳筑基",
	1: "筑基凝丹",
	2: "凝丹化婴",
	3: "元婴化神",
	4: "化神炼虚",
	5: "炼虚合体",
	6: "合体大乘",
	7: "大乘飞升",
	8: "真仙问道",
}
## 未登记的 tier 或数据缺失时的兜底名
const CULTIVATION_NAME_DEFAULT: String = "吐纳修行"

const SKILL_DEFS: Array = [
	{"id": "herbalism", "name": "采药寻灵", "category": "gather", "color": "#4caf7a", "desc": "识灵植药性，采撷山中草木精华。"},
	{"id": "woodcutting", "name": "伐木取材", "category": "gather", "color": "#4caf7a", "desc": "伐取灵木，为丹炉与符纸备下薪材。"},
	{"id": "mining", "name": "开矿掘脉", "category": "gather", "color": "#4caf7a", "desc": "探查地脉，掘出粗玄铁与矿石。"},
	{"id": "alchemy", "name": "丹道炼制", "category": "craft", "color": "#e0a458", "desc": "以灵火淬炼丹丸，木生火则丹成更盛。"},
	{"id": "forging", "name": "器道锻造", "category": "craft", "color": "#e0a458", "desc": "千锤百炼，火生土、土生金可出精良法宝。"},
	{"id": "talisman", "name": "符箓绘制", "category": "craft", "color": "#e0a458", "desc": "以朱砂灵墨绘符，护身御雷。"},
	{"id": "cultivation", "name": "吐纳筑基", "category": "meditate", "color": "#e0a458", "desc": "静坐吐纳天地灵气，累积境界修为。"},
	{"id": "combat", "name": "秘境历练", "category": "combat", "color": "#d9534f", "desc": "入秘境斩妖，取妖丹与灵石。"},
]

const REGION_DEFS: Array = [
	{
		"id": "wild_wolf_forest",
		"name": "外山妖狼林",
		"tag": "炼气",
		"required_tier": 0,
		"desc": "宗门山门之外的荒林，妖狼成群，是新晋弟子的试炼之地。",
		"enemies": ["enemy_wild_wolf", "enemy_iron_boar", "enemy_wolf_king"],
	},
	{
		"id": "ancient_ruins",
		"name": "古修遗迹",
		"tag": "筑基",
		"required_tier": 1,
		"desc": "深埋地脉的古修洞府，傀儡仍在巡守，妖将精魄散落其间。",
		"enemies": ["enemy_miasma_python", "enemy_stone_golem", "enemy_ruin_guardian"],
	},
	{
		"id": "star_ruins",
		"name": "星陨古墟",
		"tag": "金丹",
		"required_tier": 2,
		"desc": "坠星砸出的深谷，残魂与古猿守着星核，蛟王盘踞最深处。",
		"enemies": ["enemy_star_wraith", "enemy_frost_ape", "enemy_star_dragon"],
	},
	{
		"id": "taixu_marsh",
		"name": "太虚雷泽",
		"tag": "元婴",
		"required_tier": 3,
		"desc": "九天雷气沉降之地，蛟、兽、残灵轮番镇守。",
		"enemies": ["enemy_thunder_serpent", "enemy_taixu_beast", "enemy_dragon_remnant"],
	},
	{
		"id": "youming_abyss",
		"name": "九幽冥渊",
		"tag": "化神",
		"required_tier": 4,
		"desc": "大地最深处裂开的冥渊，幽泉倒流，鬼帝坐镇其中。",
		"enemies": ["enemy_youming_ghost", "enemy_blood_crow", "enemy_jiuyou_king"],
	},
	{
		"id": "star_sea",
		"name": "无尽星海",
		"tag": "炼虚",
		"required_tier": 5,
		"desc": "天外无尽的星尘之海，巨鲸与星龙以星核为食。",
		"enemies": ["enemy_star_whale", "enemy_nebula_spirit", "enemy_void_dragon"],
	},
	{
		"id": "chaos_realm",
		"name": "混沌古界",
		"tag": "合体",
		"required_tier": 6,
		"desc": "天地未分时残留的一隅，道花自生，古神残念仍在。",
		"enemies": ["enemy_chaos_golem", "enemy_void_devourer", "enemy_chaos_lord"],
	},
	{
		"id": "heaven_beyond",
		"name": "三十三天外",
		"tag": "大乘",
		"required_tier": 7,
		"desc": "越过三十三重天之后的虚空，神将巡守，天帝垂目。",
		"enemies": ["enemy_heaven_general", "enemy_primordial_beast", "enemy_heaven_emperor"],
	},
]

const ITEM_DEFS: Array = [
	{
		"id": "item_qingye", "name": "青叶草", "cat": CAT_MATERIAL, "element": E_WOOD, "sell": 2,
		"desc": "山野间最常见的灵草，气息清淡，可炼聚气丹与回春散。",
	},
	{
		"id": "item_ninglu", "name": "凝露花", "cat": CAT_MATERIAL, "element": E_WATER, "sell": 6,
		"desc": "寅时开花的灵植，花瓣凝有月华露水，乃筑基丹主药。",
	},
	{
		"id": "item_qingling_wood", "name": "青灵木", "cat": CAT_MATERIAL, "element": E_WOOD, "sell": 3,
		"desc": "木质青碧，燃之不散黑烟，可作丹炉薪火与符纸原材。",
	},
	{
		"id": "item_cuiyun_wood", "name": "翠云灵木", "cat": CAT_MATERIAL, "element": E_WOOD, "sell": 6,
		"desc": "木纹如翠云舒卷，质地轻韧，最宜炼制炼气期护身法袍。",
	},
	{
		"id": "item_crude_iron", "name": "粗玄铁", "cat": CAT_MATERIAL, "element": E_METAL, "sell": 4,
		"desc": "含玄铁杂质的粗矿，锻造飞剑与法袍的根本材料。",
	},
	{
		"id": "item_qinggang_ore", "name": "青罡铁矿", "cat": CAT_MATERIAL, "element": E_METAL, "sell": 8,
		"desc": "矿脉中泛着青罡寒芒的铁精，是炼气后期兵器的上选。",
	},
	{
		"id": "item_beast_core", "name": "妖兽内丹", "cat": CAT_MATERIAL, "element": E_NONE, "sell": 15,
		"desc": "妖兽精气凝结之核，性烈，是炼制高阶丹药的关键。",
	},
	{
		"id": "item_spirit_stone", "name": "灵石", "cat": CAT_CURRENCY, "element": E_NONE, "sell": 1,
		"desc": "修真界通用之资，蕴含微量天地灵气。",
	},
	{
		"id": "item_spirit_dew", "name": "灵潭清露", "cat": CAT_MATERIAL, "element": E_WATER, "sell": 25,
		"desc": "灵潭聚灵凝成的清露，洞府烹茶必备水引。",
	},
	{
		"id": "item_spirit_fish", "name": "碧波灵鱼", "cat": CAT_MATERIAL, "element": E_WATER, "sell": 120,
		"desc": "灵潭中灵气滋养的灵鱼，可售换灵石或入茶提鲜。",
	},
	{
		"id": "item_qi_pill", "name": "聚气丹", "cat": CAT_CONSUMABLE, "element": E_FIRE, "sell": 10,
		"cultivation": 45, "desc": "吞服可凝聚灵气，直接转化 45 点境界修为；吐纳时可自动服用。",
	},
	{
		"id": "item_heal_powder", "name": "回春散", "cat": CAT_CONSUMABLE, "element": E_WOOD, "sell": 5,
		"heal": 35, "desc": "草木精华调和的散剂，即刻回复 35 点气血。",
	},
	{
		"id": "item_foundation_pill", "name": "筑基丹", "cat": CAT_CONSUMABLE, "element": E_FIRE, "sell": 88,
		"desc": "引动天劫所需之丹，可稳固道基。渡劫时于渡劫面板使用。",
	},
	{
		"id": "item_earth_talisman", "name": "厚土护身符", "cat": CAT_CONSUMABLE, "element": E_EARTH, "sell": 12,
		"ward": 0.4, "desc": "厚土之气凝成的护身符，抵消当次天雷 40% 伤害。",
	},
	{
		"id": "item_fireball_talisman", "name": "烈火攻伐符", "cat": CAT_CONSUMABLE, "element": E_FIRE, "sell": 20,
		"desc": "引赤炎之力化火球轰击妖兽，炼气期破敌利器。",
	},
	{
		"id": "item_qingmu_ward", "name": "青木回春符", "cat": CAT_CONSUMABLE, "element": E_WOOD, "sell": 28,
		"ward": 0.48, "desc": "凝青木生机成盾，抵消当次天雷 48% 伤害。",
	},
	{
		"id": "equip_iron_sword", "name": "玄铁飞剑", "cat": CAT_EQUIPMENT, "element": E_METAL, "sell": 32,
		"slot": "weapon", "atk": 12, "acc": 5, "crit": 2,
		"desc": "粗玄铁锻成的入门飞剑，攻击 +12，命中 +5，会心 +2%。",
	},
	{
		"id": "equip_iron_robe", "name": "玄铁法袍", "cat": CAT_EQUIPMENT, "element": E_EARTH, "sell": 42,
		"slot": "armor", "def": 8, "hp": 60, "dodge": 1,
		"desc": "以玄铁丝混织的法袍，最大气血 +60，防御 +8，闪避 +1%。",
	},
	{
		"id": "equip_qinggang_sword", "name": "青罡灵剑", "cat": CAT_EQUIPMENT, "element": E_METAL, "sell": 82,
		"slot": "weapon", "atk": 20, "acc": 8, "crit": 3,
		"desc": "青罡铁精七锻成锋，攻击 +20，命中 +8，会心 +3%。",
	},
	{
		"id": "equip_cuiyun_robe", "name": "翠云道袍", "cat": CAT_EQUIPMENT, "element": E_WOOD, "sell": 115,
		"slot": "armor", "def": 14, "hp": 110, "dodge": 2,
		"desc": "翠云灵木抽丝织就，最大气血 +110，防御 +14，闪避 +2%。",
	},
	{
		"id": "seed_qingye", "name": "青叶草灵种", "cat": CAT_MATERIAL, "element": E_WOOD, "sell": 7,
		"desc": "可播于洞府灵田，静候十分钟即得青叶草。采摘青叶草时偶有副产。",
	},
	{
		"id": "seed_ninglu", "name": "凝露花灵种", "cat": CAT_MATERIAL, "element": E_WATER, "sell": 22,
		"desc": "可播于洞府灵田，生长二十五分钟，得凝露花。采摘凝露花时偶有副产。",
	},
	{
		"id": "seed_spirit_berry", "name": "赤阳灵果种", "cat": CAT_MATERIAL, "element": E_FIRE, "sell": 40,
		"desc": "可播于洞府灵田，四十五分钟结出赤阳灵果。",
	},
	{
		"id": "item_spirit_berry", "name": "赤阳灵果", "cat": CAT_CONSUMABLE, "element": E_FIRE, "sell": 35,
		"cultivation": 90, "desc": "灵田专属灵果，吞服立得 90 点修为，亦可售 35 灵石。",
	},
	# ---- 筑基期灵材
	{
		"id": "item_ziyun", "name": "紫云芝", "cat": CAT_MATERIAL, "element": E_WOOD, "sell": 12,
		"desc": "生于古木背阴处的灵芝，筑基丹方的主药。",
	},
	{
		"id": "item_chiyan", "name": "赤焰草", "cat": CAT_MATERIAL, "element": E_FIRE, "sell": 30,
		"desc": "叶脉如焰的灵草，火气极盛，结金丹必需。",
	},
	{
		"id": "item_ironwood", "name": "铁心木", "cat": CAT_MATERIAL, "element": E_WOOD, "sell": 10,
		"desc": "木坚如铁，燃时火力绵长，二阶丹炉薪火与符纸。",
	},
	{
		"id": "item_thunderwood", "name": "雷击沉香木", "cat": CAT_MATERIAL, "element": E_FIRE, "sell": 24,
		"desc": "经天雷劈过的沉木，内蕴雷意，可引雷成符。",
	},
	{
		"id": "item_mithril", "name": "秘银矿", "cat": CAT_MATERIAL, "element": E_METAL, "sell": 18,
		"desc": "银光内敛的灵矿，轻而坚韧，筑基法器主材。",
	},
	{
		"id": "item_redgold", "name": "赤铜精金", "cat": CAT_MATERIAL, "element": E_METAL, "sell": 35,
		"desc": "赤色精金，性烈难驯，可铸筑基顶配法宝。",
	},
	{
		"id": "item_demon_essence", "name": "妖将精魄", "cat": CAT_MATERIAL, "element": E_NONE, "sell": 45,
		"desc": "古修遗迹中妖将残魂所凝，高阶丹药与法宝之引。",
	},
	# ---- 筑基期灵种
	{
		"id": "seed_ziyun", "name": "紫云芝灵种", "cat": CAT_MATERIAL, "element": E_WOOD, "sell": 60,
		"desc": "可播于洞府灵田，三十五分钟后得紫云芝。",
	},
	{
		"id": "seed_chiyan", "name": "赤焰草灵种", "cat": CAT_MATERIAL, "element": E_FIRE, "sell": 110,
		"desc": "可播于洞府灵田，五十分钟后得赤焰草。",
	},
	# ---- 筑基期丹药符箓
	{
		"id": "item_peiyuan_pill", "name": "筑基培元丹", "cat": CAT_CONSUMABLE, "element": E_FIRE, "sell": 58,
		"cultivation": 190, "desc": "固本培元之丹，吞服立得 190 点修为；筑基导引术可自动服用。",
	},
	{
		"id": "item_big_heal", "name": "大回春丹", "cat": CAT_CONSUMABLE, "element": E_WOOD, "sell": 32,
		"heal": 110, "desc": "大颗回春丹，即刻回复 110 点气血，渡劫与秘境优先服用。",
	},
	{
		"id": "item_jindan_pill", "name": "结金丹", "cat": CAT_CONSUMABLE, "element": E_FIRE, "sell": 470,
		"desc": "凝丹之药，引动结丹天劫的门票。",
	},
	{
		"id": "item_turtle_talisman", "name": "玄龟盾符", "cat": CAT_CONSUMABLE, "element": E_EARTH, "sell": 38,
		"ward": 0.55, "desc": "玄龟甲片为引的护身符，抵消当次天雷 55% 伤害。",
	},
	{
		"id": "item_thunder_talisman", "name": "引雷攻伐符", "cat": CAT_CONSUMABLE, "element": E_FIRE, "sell": 55,
		"desc": "战斗开场自动消耗，按自身攻击四成半造成先手雷击，对头目妖王威力大减。",
	},
	# ---- 筑基期法宝
	{
		"id": "equip_mithril_sword", "name": "秘银流光剑", "cat": CAT_EQUIPMENT, "element": E_METAL, "sell": 210,
		"slot": "weapon", "atk": 28, "acc": 12, "crit": 4,
		"desc": "秘银锻造的轻剑，攻击 +28，命中 +12，会心 +4%。",
	},
	{
		"id": "equip_mithril_armor", "name": "玄龟秘银甲", "cat": CAT_EQUIPMENT, "element": E_EARTH, "sell": 230,
		"slot": "armor", "def": 20, "hp": 160, "dodge": 3,
		"desc": "玄龟甲纹与秘银混炼，最大气血 +160，防御 +20，闪避 +3%。",
	},
	{
		"id": "equip_redgold_sword", "name": "赤金破军剑", "cat": CAT_EQUIPMENT, "element": E_METAL, "sell": 500,
		"slot": "weapon", "atk": 48, "acc": 16, "crit": 5,
		"desc": "赤铜精金所铸，攻击 +48，命中 +16，会心 +5%。",
	},
	{
		"id": "equip_redgold_robe", "name": "流火金丝袍", "cat": CAT_EQUIPMENT, "element": E_FIRE, "sell": 680,
		"slot": "armor", "def": 34, "hp": 280, "dodge": 4,
		"desc": "金丝织就的法袍，最大气血 +280，防御 +34，闪避 +4%。",
	},
	# ================= 金丹期灵材 / 丹药 / 符箓 / 法宝 =================
	{
		"id": "item_hansui", "name": "寒髓草", "cat": CAT_MATERIAL, "element": E_WATER, "sell": 42,
		"desc": "生于万年冰层裂隙，叶脉凝霜，三阶丹方主药。",
	},
	{
		"id": "item_xinghui", "name": "星辉灵芝", "cat": CAT_MATERIAL, "element": E_WOOD, "sell": 55,
		"desc": "吸星辉而生的灵芝，芝盖有细密光点，化婴丹主药。",
	},
	{
		"id": "item_icewood", "name": "万年玄冰木", "cat": CAT_MATERIAL, "element": E_WATER, "sell": 46,
		"desc": "万年不化的玄冰包裹木心，可制高阶符纸。",
	},
	{
		"id": "item_starwood", "name": "星纹梧桐木", "cat": CAT_MATERIAL, "element": E_WOOD, "sell": 60,
		"desc": "木纹如星轨的梧桐，燃时星火不熄。",
	},
	{
		"id": "item_stariron", "name": "星辰陨铁", "cat": CAT_MATERIAL, "element": E_METAL, "sell": 45,
		"desc": "自星陨中剥离的陨铁，冷冽沉重，三阶利器主材。",
	},
	{
		"id": "item_primordial_crystal", "name": "太初灵晶", "cat": CAT_MATERIAL, "element": E_EARTH, "sell": 85,
		"desc": "天地初开时凝成的一缕本源，金丹顶配法宝之核。",
	},
	{
		"id": "item_star_core", "name": "星辰核心", "cat": CAT_MATERIAL, "element": E_FIRE, "sell": 120,
		"desc": "陨星残核，内蕴星火，可用于炼制化婴丹与三阶法宝。",
	},
	{
		"id": "item_ancient_soul", "name": "上古残魂", "cat": CAT_MATERIAL, "element": E_NONE, "sell": 180,
		"desc": "古墟中不散的残魂，可直接售与仙坊阁换灵石。",
	},
	{
		"id": "item_gold_pill", "name": "三转金丹", "cat": CAT_CONSUMABLE, "element": E_FIRE, "sell": 270,
		"cultivation": 720, "desc": "金丹修士的主丹，吞服立得 720 点修为。",
	},
	{
		"id": "item_heart_pill", "name": "九转护心丹", "cat": CAT_CONSUMABLE, "element": E_WOOD, "sell": 94,
		"heal": 320, "desc": "九转凝炼的护心丹，即刻回复 320 点气血。",
	},
	{
		"id": "item_nascent_pill", "name": "化婴丹", "cat": CAT_CONSUMABLE, "element": E_FIRE, "sell": 1520,
		"desc": "碎婴凝婴之药，引动碎婴天劫的门票。",
	},
	{
		"id": "item_taiji_talisman", "name": "太极金光符", "cat": CAT_CONSUMABLE, "element": E_EARTH, "sell": 156,
		"ward": 0.65, "desc": "太极金光护体，抵消当次天雷 65% 伤害。",
	},
	{
		"id": "item_zixiao_talisman", "name": "紫霄神雷符", "cat": CAT_CONSUMABLE, "element": E_FIRE, "sell": 175,
		"desc": "战斗开场自动消耗，按自身攻击七成造成先手雷击，对头目妖王威力大减。",
	},
	{
		"id": "equip_star_sword", "name": "星陨流光剑", "cat": CAT_EQUIPMENT, "element": E_METAL, "sell": 735,
		"slot": "weapon", "atk": 82, "acc": 20, "crit": 6,
		"desc": "陨铁淬星火，攻击 +82，命中 +20，会心 +6%。",
	},
	{
		"id": "equip_ice_armor", "name": "玄冰星辰甲", "cat": CAT_EQUIPMENT, "element": E_WATER, "sell": 1013,
		"slot": "armor", "def": 56, "hp": 480, "dodge": 6,
		"desc": "玄冰为骨、星砂为面，最大气血 +480，防御 +56，闪避 +6%。",
	},
	{
		"id": "equip_primordial_sword", "name": "太初斩星剑", "cat": CAT_EQUIPMENT, "element": E_METAL, "sell": 1750,
		"slot": "weapon", "atk": 135, "acc": 24, "crit": 7,
		"desc": "太初灵晶铸成，剑出如斩星辰，攻击 +135，命中 +24，会心 +7%。",
	},
	{
		"id": "equip_primordial_robe", "name": "太初星袍", "cat": CAT_EQUIPMENT, "element": E_EARTH, "sell": 1780,
		"slot": "armor", "def": 88, "hp": 820, "dodge": 8,
		"desc": "星袍覆体，万法难侵，最大气血 +820，防御 +88，闪避 +8%。",
	},
	{
		"id": "seed_hansui", "name": "寒髓草灵种", "cat": CAT_MATERIAL, "element": E_WATER, "sell": 240,
		"desc": "可播于洞府灵田，一小时成熟，得寒髓草 6~10 株。",
	},
	{
		"id": "seed_xinghui", "name": "星辉灵芝种", "cat": CAT_MATERIAL, "element": E_WOOD, "sell": 425,
		"desc": "可播于洞府灵田，八十分钟成熟，得星辉灵芝 5~8 株。",
	},
	{
		"id": "seed_jiuye", "name": "九叶仙芝种", "cat": CAT_MATERIAL, "element": E_WOOD, "sell": 900,
		"desc": "可播于洞府灵田，九十分钟成熟，得九叶仙芝 65~105 株。",
	},
	# ---- 化神~大乘期灵种（v4 五株高阶灵药闭环） ----
	{
		"id": "seed_biyu", "name": "碧玉灵参种", "cat": CAT_MATERIAL, "element": E_WOOD, "sell": 160,
		"desc": "可播于洞府灵田，六十分钟成熟，得碧玉灵参 55~90 株。",
	},
	{
		"id": "seed_longxue", "name": "龙血草灵种", "cat": CAT_MATERIAL, "element": E_FIRE, "sell": 1800,
		"desc": "可播于洞府灵田，一百分钟成熟，得龙血草 70~110 株。",
	},
	{
		"id": "seed_taiyi", "name": "太乙青莲种", "cat": CAT_MATERIAL, "element": E_WATER, "sell": 3600,
		"desc": "可播于洞府灵田，一百一十分钟成熟，得太乙青莲 75~120 株。",
	},
	{
		"id": "seed_hundun", "name": "混沌道花种", "cat": CAT_MATERIAL, "element": E_EARTH, "sell": 7000,
		"desc": "可播于洞府灵田，一百二十分钟成熟，得混沌道花 80~130 株。",
	},
	{
		"id": "seed_hongmeng", "name": "鸿蒙不死药种", "cat": CAT_MATERIAL, "element": E_WOOD, "sell": 14000,
		"desc": "可播于洞府灵田，一百四十分钟成熟，得鸿蒙不死药 90~145 株。",
	},
	# ================= 元婴期灵材 / 丹药 / 符箓 / 法宝 =================
	{
		"id": "item_jiuye", "name": "九叶仙芝", "cat": CAT_MATERIAL, "element": E_WOOD, "sell": 90,
		"desc": "一芝九叶，叶叶如玉，元婴丹方的君药。",
	},
	{
		"id": "item_fusang", "name": "扶桑神木", "cat": CAT_MATERIAL, "element": E_FIRE, "sell": 95,
		"desc": "日出之木，薪火不熄，四阶丹符核心。",
	},
	{
		"id": "item_taixu_gold", "name": "太虚仙金", "cat": CAT_MATERIAL, "element": E_METAL, "sell": 130,
		"desc": "太虚之中自生的仙金，锻四阶仙器不可缺。",
	},
	{
		"id": "item_thunder_essence", "name": "太虚雷精", "cat": CAT_MATERIAL, "element": E_FIRE, "sell": 260,
		"desc": "雷泽中凝聚的雷之精魄，炼制飞升丹与仙器之引。",
	},
	{
		"id": "item_dragon_scale", "name": "真龙残鳞", "cat": CAT_MATERIAL, "element": E_WATER, "sell": 450,
		"desc": "真龙蜕下的残鳞，坚不可摧，可直接售 450 灵石。",
	},
	{
		"id": "item_yuanying_pill", "name": "元婴培神丹", "cat": CAT_CONSUMABLE, "element": E_FIRE, "sell": 460,
		"cultivation": 2000, "desc": "元婴修士的主丹，吞服立得 2000 点修为。",
	},
	{
		"id": "item_revive_pill", "name": "九转还魂丹", "cat": CAT_CONSUMABLE, "element": E_WOOD, "sell": 420,
		"heal": 750, "desc": "九转还魂，即刻回复 750 点气血。",
	},
	{
		"id": "item_ascension_pill", "name": "渡劫飞升丹", "cat": CAT_CONSUMABLE, "element": E_FIRE, "sell": 62000,
		"desc": "凝九叶与雷精所成，引动飞升天劫的门票。",
	},
	{
		"id": "item_taixu_shield", "name": "太虚金光符", "cat": CAT_CONSUMABLE, "element": E_EARTH, "sell": 400,
		"ward": 0.75, "desc": "太虚金光护体，抵消当次天雷 75% 伤害。",
	},
	{
		"id": "item_taixu_thunder", "name": "太虚天雷符", "cat": CAT_CONSUMABLE, "element": E_FIRE, "sell": 420,
		"desc": "秘境开场自动消耗，对敌造成 320 点雷击真伤。",
	},
	{
		"id": "equip_taixu_sword", "name": "太虚斩道剑", "cat": CAT_EQUIPMENT, "element": E_METAL, "sell": 3250,
		"slot": "weapon", "atk": 245, "acc": 28, "crit": 8,
		"desc": "太虚仙金所铸，一剑断道，攻击 +245，命中 +28，会心 +8%。",
	},
	{
		"id": "equip_taixu_robe", "name": "太虚混元仙袍", "cat": CAT_EQUIPMENT, "element": E_EARTH, "sell": 3500,
		"slot": "armor", "def": 155, "hp": 1550, "dodge": 10,
		"desc": "混元一气织就，最大气血 +1550，防御 +155，闪避 +10%。",
	},
	# ---- 灵田专属奇珍（野外采药不产）
	{
		"id": "item_spirit_nectar", "name": "聚灵甘露", "cat": CAT_CONSUMABLE, "element": E_WATER, "sell": 300,
		"desc": "灵田灵气凝成的甘露。吞服按当前小境界突破所需修为的 3% 折算（保底 120），受吐纳功法与境界加成。",
	},
	{
		"id": "item_crimson_fruit", "name": "百年朱果", "cat": CAT_CONSUMABLE, "element": E_FIRE, "sell": 1200,
		"desc": "灵田伴生的百年朱果。每枚永久气血 +20、攻击 +2，最多炼化 50 枚；满额后可高价出售。",
	},
	# ================= 筑基 / 金丹过渡灵材（Lv32 采集） =================
	{
		"id": "item_biyu_shen", "name": "碧玉灵参", "cat": CAT_MATERIAL, "element": E_WOOD, "sell": 24,
		"desc": "玉色灵参，三转金丹的辅药，补气最稳。",
	},
	{
		"id": "item_chiyan_wutong", "name": "赤焰梧桐", "cat": CAT_MATERIAL, "element": E_FIRE, "sell": 28,
		"desc": "火气内蕴的灵木，伐之作薪，锻袍炼丹皆宜。",
	},
	{
		"id": "item_hanyu", "name": "寒玉髓矿", "cat": CAT_MATERIAL, "element": E_WATER, "sell": 28,
		"desc": "冰脉深处的玉髓矿石，淬甲可生寒霜护体。",
	},
	# ================= 化神期（Lv81~88） =================
	{
		"id": "item_longxue", "name": "龙血草", "cat": CAT_MATERIAL, "element": E_FIRE, "sell": 220,
		"desc": "生于龙骨遗骸之上的赤草，血气蒸腾，化神丹方之君药。",
	},
	{
		"id": "item_jianmu", "name": "建木灵枝", "cat": CAT_MATERIAL, "element": E_WOOD, "sell": 230,
		"desc": "上达九天的建木残枝，木气生生不息。",
	},
	{
		"id": "item_jiuyou_crystal", "name": "九幽玄晶", "cat": CAT_MATERIAL, "element": E_WATER, "sell": 240,
		"desc": "九幽冥渊中凝结的玄晶，触之魂寒，锻仙兵与镇魂符之基。",
	},
	{
		"id": "item_huashen_pill", "name": "化神培元丹", "cat": CAT_CONSUMABLE, "element": E_FIRE, "sell": 1150,
		"cultivation": 5400, "desc": "化神修士的主丹，吞服立得 5400 点修为。",
	},
	{
		"id": "item_trib_huashen", "name": "化神丹", "cat": CAT_CONSUMABLE, "element": E_FIRE, "sell": 2300,
		"desc": "龙血为引、玄晶为核，引动化神天劫的门票。",
	},
	{
		"id": "item_huashen_note",
		"name": "幽冥残卷",
		"cat": CAT_MATERIAL, "element": E_NONE, "sell": 600,
		"desc": "九幽冥渊中散落的残卷，可售与仙坊阁换灵石。",
	},
	{
		"id": "equip_jiuyou_sword", "name": "九幽斩仙剑", "cat": CAT_EQUIPMENT, "element": E_WATER, "sell": 4700,
		"slot": "weapon", "atk": 370, "acc": 34, "crit": 9,
		"desc": "九幽玄晶所铸，出鞘即有鬼哭，攻击 +370，命中 +34，会心 +9%。",
	},
	{
		"id": "equip_mingyuan_armor", "name": "冥渊玄晶甲", "cat": CAT_EQUIPMENT, "element": E_EARTH, "sell": 5950,
		"slot": "armor", "def": 225, "hp": 2350, "dodge": 12,
		"desc": "玄晶叠锻三十六层，最大气血 +2350，防御 +225，闪避 +12%。",
	},
	{
		"id": "item_xuanbing_talisman", "name": "玄冰护体符", "cat": CAT_CONSUMABLE, "element": E_WATER, "sell": 110,
		"ward": 0.70, "desc": "寒髓研墨落笔成冰，抵消当次天雷 70% 伤害。",
	},
	{
		"id": "item_jiuyou_ward", "name": "九幽镇魂符", "cat": CAT_CONSUMABLE, "element": E_WATER, "sell": 420,
		"ward": 0.80, "desc": "九幽镇魂，抵消当次天雷 80% 伤害。",
	},
	{
		"id": "item_jianmu_ward", "name": "建木长春符", "cat": CAT_CONSUMABLE, "element": E_WOOD, "sell": 620,
		"ward": 0.82, "desc": "借建木灵枝绘就，护体清光绵长不绝，抵消当次天雷 82% 伤害。",
	},
	# ================= 炼虚期（Lv101~108） =================
	{
		"id": "item_taiyi_lian", "name": "太乙青莲", "cat": CAT_MATERIAL, "element": E_WATER, "sell": 620,
		"desc": "太乙池中百年一开的青莲，莲心可洗炼神魂。",
	},
	{
		"id": "item_xingchen_sang", "name": "星辰神桑", "cat": CAT_MATERIAL, "element": E_METAL, "sell": 640,
		"desc": "叶落成星的神桑，木含金气，织袍最上。",
	},
	{
		"id": "item_xingyun_iron", "name": "星陨神铁", "cat": CAT_MATERIAL, "element": E_METAL, "sell": 660,
		"desc": "星海坠落的铁核，历经真空淬炼，非真火不可熔。",
	},
	{
		"id": "item_lianxu_pill", "name": "炼虚归真丹", "cat": CAT_CONSUMABLE, "element": E_FIRE, "sell": 3200,
		"cultivation": 14500, "desc": "炼虚修士的主丹，吞服立得 14500 点修为。",
	},
	{
		"id": "item_trib_lianxu", "name": "炼虚丹", "cat": CAT_CONSUMABLE, "element": E_FIRE, "sell": 6400,
		"desc": "青莲为体、神铁为骨，引动炼虚天劫的门票。",
	},
	{
		"id": "equip_xinghe_sword", "name": "星河破虚剑", "cat": CAT_EQUIPMENT, "element": E_METAL, "sell": 13000,
		"slot": "weapon", "atk": 560, "acc": 40, "crit": 11,
		"desc": "剑起星河倒卷，攻击 +560，命中 +40，会心 +11%。",
	},
	{
		"id": "equip_xingchen_robe", "name": "星辰道袍", "cat": CAT_EQUIPMENT, "element": E_METAL, "sell": 16400,
		"slot": "armor", "def": 340, "hp": 3600, "dodge": 14,
		"desc": "星砂织就的道袍，最大气血 +3600，防御 +340，闪避 +14%。",
	},
	{
		"id": "item_xingyun_ward", "name": "星陨灭魔符", "cat": CAT_CONSUMABLE, "element": E_METAL, "sell": 1050,
		"ward": 0.85, "desc": "星陨为墨，灭魔为纹，抵消当次天雷 85% 伤害。",
	},
	{
		"id": "item_xingchen_thunder", "name": "星辰陨雷符", "cat": CAT_CONSUMABLE, "element": E_FIRE, "sell": 1350,
		"desc": "引九天星辰陨雷轰落，破魔诛邪。",
	},
	# ================= 合体期（Lv120~128） =================
	{
		"id": "item_hundun_flower", "name": "混沌道花", "cat": CAT_MATERIAL, "element": E_EARTH, "sell": 1500,
		"desc": "混沌未分之地开出的道花，一瓣一味，合体丹方之主。",
	},
	{
		"id": "item_hundun_vine", "name": "混沌青藤木", "cat": CAT_MATERIAL, "element": E_WOOD, "sell": 1560,
		"desc": "藤蔓自混沌中垂下，柔韧不可断，可炼软甲亦可为薪。",
	},
	{
		"id": "item_hundun_stone", "name": "混沌母气石", "cat": CAT_MATERIAL, "element": E_EARTH, "sell": 1600,
		"desc": "含一缕天地母气的奇石，锻器时投入可定形不散。",
	},
	{
		"id": "item_heti_pill", "name": "合体混元丹", "cat": CAT_CONSUMABLE, "element": E_FIRE, "sell": 7600,
		"cultivation": 38000, "desc": "合体修士的主丹，吞服立得 38000 点修为。",
	},
	{
		"id": "item_trib_heti", "name": "合体丹", "cat": CAT_CONSUMABLE, "element": E_FIRE, "sell": 15500,
		"desc": "道花为心、母气为炉，引动合体天劫的门票。",
	},
	{
		"id": "equip_hundun_axe", "name": "混沌开天斧", "cat": CAT_EQUIPMENT, "element": E_EARTH, "sell": 35800,
		"slot": "weapon", "atk": 820, "acc": 46, "crit": 13,
		"desc": "一斧开天，重逾山岳，攻击 +820，命中 +46，会心 +13%。",
	},
	{
		"id": "equip_hunyuan_robe", "name": "混元宝衣", "cat": CAT_EQUIPMENT, "element": E_EARTH, "sell": 35500,
		"slot": "armor", "def": 470, "hp": 5200, "dodge": 16,
		"desc": "混元一气织成，最大气血 +5200，防御 +470，闪避 +16%。",
	},
	{
		"id": "item_hundun_ward", "name": "混沌金刚符", "cat": CAT_CONSUMABLE, "element": E_EARTH, "sell": 2400,
		"ward": 0.88, "desc": "混沌金刚不坏，抵消当次天雷 88% 伤害。",
	},
	{
		"id": "item_hundun_thunder", "name": "混沌裂空符", "cat": CAT_CONSUMABLE, "element": E_FIRE, "sell": 2800,
		"desc": "以混沌青藤承雷纹，一击裂空碎岳。",
	},
	# ================= 大乘期（Lv135~145） =================
	{
		"id": "item_hongmeng_herb", "name": "鸿蒙不死药", "cat": CAT_MATERIAL, "element": E_WOOD, "sell": 3600,
		"desc": "鸿蒙初辟时便已生长的仙药，一株可续百年寿元。",
	},
	{
		"id": "item_worldtree", "name": "世界树心木", "cat": CAT_MATERIAL, "element": E_EARTH, "sell": 3800,
		"desc": "世界树的心材，内有一界微光，仙器之脊。",
	},
	{
		"id": "item_hongmeng_gold", "name": "鸿蒙紫金", "cat": CAT_MATERIAL, "element": E_METAL, "sell": 3900,
		"desc": "鸿蒙紫气凝成的金精，非大乘真火不能熔。",
	},
	{
		"id": "item_dacheng_pill", "name": "大乘造化丹", "cat": CAT_CONSUMABLE, "element": E_FIRE, "sell": 18500,
		"cultivation": 96000, "desc": "大乘修士的主丹，吞服立得 96000 点修为。",
	},
	{
		"id": "item_trib_dacheng", "name": "大乘丹", "cat": CAT_CONSUMABLE, "element": E_FIRE, "sell": 37500,
		"desc": "不死药为引、紫金为核，引动大乘天劫的门票。",
	},
	{
		"id": "equip_hongmeng_sword", "name": "鸿蒙诛仙剑", "cat": CAT_EQUIPMENT, "element": E_METAL, "sell": 96800,
		"slot": "weapon", "atk": 1180, "acc": 54, "crit": 15,
		"desc": "鸿蒙紫金铸就，剑锋所指仙神辟易，攻击 +1180，命中 +54，会心 +15%。",
	},
	{
		"id": "equip_zaohua_robe", "name": "造化仙衣", "cat": CAT_EQUIPMENT, "element": E_EARTH, "sell": 96000,
		"slot": "armor", "def": 660, "hp": 7400, "dodge": 18,
		"desc": "造化之力织成，最大气血 +7400，防御 +660，闪避 +18%。",
	},
	{
		"id": "item_hongmeng_thunder", "name": "鸿蒙紫霄神雷符", "cat": CAT_CONSUMABLE, "element": E_FIRE, "sell": 5500,
		"desc": "战斗开场自动消耗，按自身攻击一倍有余造成先手雷击，对头目妖王威力大减。",
	},
	{
		"id": "item_worldtree_ward", "name": "世界树不灭符", "cat": CAT_CONSUMABLE, "element": E_WOOD, "sell": 6200,
		"ward": 0.91, "desc": "取世界树心木精气化盾，万法难侵，抵消当次天雷 91% 伤害。",
	},
	# ================= 功能奇丹 =================
	{
		"id": "item_qingxin_pill", "name": "护道清心丹", "cat": CAT_CONSUMABLE, "element": E_WATER, "sell": 280,
		"desc": "清心护道，服下立增 1 层道心悟性（上限 5 层），渡劫减伤更进一步。",
	},
	{
		"id": "item_jiuzhuan_pill", "name": "九转回元丹", "cat": CAT_CONSUMABLE, "element": E_WOOD, "sell": 780,
		"heal": 2600, "cultivation": 3000,
		"desc": "九转还元，即刻回复 2600 点气血，并得 3000 点修为。",
	},
	{
		"id": "item_taiyi_heal", "name": "太乙回春丹", "cat": CAT_CONSUMABLE, "element": E_WOOD, "sell": 1450,
		"heal": 4160, "desc": "太乙青莲为君，龙血草为引，即刻回复 4160 点气血。",
	},
	{
		"id": "item_hundun_heal", "name": "混沌生肌丹", "cat": CAT_CONSUMABLE, "element": E_WOOD, "sell": 3600,
		"heal": 7020, "desc": "混沌道花化生肌理，太乙青莲续脉，即刻回复 7020 点气血。",
	},
	{
		"id": "item_hongmeng_heal", "name": "鸿蒙造化生生丹", "cat": CAT_CONSUMABLE, "element": E_WOOD, "sell": 8600,
		"heal": 11440, "desc": "鸿蒙不死药与混沌道花相合，生生造化，即刻回复 11440 点气血。",
	},
]

const ACTION_DEFS: Array = [
	{
		"id": "gather_qingye", "name": "采摘青叶草", "skill": "herbalism", "type": TYPE_GATHER,
		"interval": 2.5, "level": 1, "element": E_WOOD,
		"inputs": {}, "outputs": {"item_qingye": 1}, "xp": 10.0, "mxp": 8.0,
		"desc": "俯身采下带着晨露的青叶草。",
	},
	{
		"id": "gather_ninglu", "name": "采摘凝露花", "skill": "herbalism", "type": TYPE_GATHER,
		"interval": 4.0, "level": 8, "element": E_WATER,
		"inputs": {}, "outputs": {"item_ninglu": 1}, "xp": 24.0, "mxp": 16.0,
		"desc": "候在寅时花前，采下凝着月华的露花。",
	},
	{
		"id": "cut_qingling", "name": "砍伐青灵木", "skill": "woodcutting", "type": TYPE_GATHER,
		"interval": 3.0, "level": 1, "element": E_WOOD,
		"inputs": {}, "outputs": {"item_qingling_wood": 1}, "xp": 12.0, "mxp": 10.0,
		"desc": "斧落木屑纷飞，青灵木应声而倒。",
	},
	{
		"id": "cut_cuiyun", "name": "砍伐翠云灵木", "skill": "woodcutting", "type": TYPE_GATHER,
		"interval": 3.8, "level": 8, "element": E_WOOD,
		"inputs": {}, "outputs": {"item_cuiyun_wood": 1}, "xp": 24.0, "mxp": 16.0,
		"desc": "翠云灵木纹理轻卷，斧落时木香如云气漫开。",
	},
	{
		"id": "mine_xuaniron", "name": "开采粗玄铁", "skill": "mining", "type": TYPE_GATHER,
		"interval": 3.5, "level": 1, "element": E_METAL,
		"inputs": {}, "outputs": {"item_crude_iron": 1}, "xp": 15.0, "mxp": 12.0,
		"desc": "循着地脉敲开岩层，取出带锈的玄铁粗矿。",
	},
	{
		"id": "mine_qinggang", "name": "开采青罡铁矿", "skill": "mining", "type": TYPE_GATHER,
		"interval": 4.2, "level": 8, "element": E_METAL,
		"inputs": {}, "outputs": {"item_qinggang_ore": 1}, "xp": 24.0, "mxp": 16.0,
		"desc": "青罡铁嵌在冷硬岩层中，镐落时火星泛出青芒。",
	},
	{
		"id": "craft_qi_pill", "name": "炼制聚气丹", "skill": "alchemy", "type": TYPE_CRAFT,
		"interval": 3.0, "level": 1, "element": E_FIRE,
		"inputs": {"item_qingye": 2, "item_qingling_wood": 1}, "outputs": {"item_qi_pill": 1},
		"xp": 18.0, "mxp": 15.0, "wood_fire": true, "free_material": true,
		"desc": "青叶草入炉，青灵木助燃，木生火则丹香四溢。",
	},
	{
		"id": "craft_heal_powder", "name": "炼制回春散", "skill": "alchemy", "type": TYPE_CRAFT,
		"interval": 2.5, "level": 3, "element": E_FIRE,
		"inputs": {"item_qingye": 3}, "outputs": {"item_heal_powder": 2},
		"xp": 16.0, "mxp": 14.0, "free_material": true,
		"desc": "三株青叶草文火慢焙，得一包回春散。",
	},
	{
		"id": "craft_foundation_pill", "name": "炼制筑基丹", "skill": "alchemy", "type": TYPE_CRAFT,
		"interval": 8.0, "level": 12, "element": E_FIRE,
		"inputs": {"item_ninglu": 5, "item_beast_core": 2, "item_qingling_wood": 3},
		"outputs": {"item_foundation_pill": 1},
		"xp": 80.0, "mxp": 50.0, "wood_fire": true, "free_material": true,
		"desc": "凝露花为药，妖丹为引，青灵木助燃，成丹可筑基。",
	},
	{
		"id": "forge_iron_sword", "name": "锻造玄铁飞剑", "skill": "forging", "type": TYPE_CRAFT,
		"interval": 6.0, "level": 1, "element": E_METAL,
		"inputs": {"item_crude_iron": 6}, "outputs": {"equip_iron_sword": 1},
		"xp": 35.0, "mxp": 25.0, "quality": true, "free_material": true,
		"desc": "六块粗玄铁，九锻九淬，锋芒初现。",
	},
	{
		"id": "forge_iron_robe", "name": "锻造玄铁法袍", "skill": "forging", "type": TYPE_CRAFT,
		"interval": 6.5, "level": 5, "element": E_EARTH,
		"inputs": {"item_crude_iron": 8}, "outputs": {"equip_iron_robe": 1},
		"xp": 42.0, "mxp": 30.0, "quality": true, "free_material": true,
		"desc": "玄铁丝混织成袍，土气沉稳，可挡刀兵。",
	},
	{
		"id": "forge_qinggang_sword", "name": "锻造青罡灵剑", "skill": "forging", "type": TYPE_CRAFT,
		"interval": 7.0, "level": 12, "element": E_METAL,
		"inputs": {"item_qinggang_ore": 6, "item_cuiyun_wood": 2},
		"outputs": {"equip_qinggang_sword": 1},
		"xp": 65.0, "mxp": 42.0, "quality": true, "free_material": true,
		"desc": "青罡铁六锻成锋，翠云木为柄，轻灵而不失刚劲。",
	},
	{
		"id": "forge_cuiyun_robe", "name": "锻造翠云道袍", "skill": "forging", "type": TYPE_CRAFT,
		"interval": 7.5, "level": 15, "element": E_WOOD,
		"inputs": {"item_qinggang_ore": 6, "item_cuiyun_wood": 4, "item_ninglu": 2},
		"outputs": {"equip_cuiyun_robe": 1},
		"xp": 75.0, "mxp": 48.0, "quality": true, "free_material": true,
		"desc": "翠云灵木抽丝为面，青罡铁精为骨，轻韧护体。",
	},
	{
		"id": "craft_earth_talisman", "name": "绘制厚土护身符", "skill": "talisman", "type": TYPE_CRAFT,
		"interval": 4.0, "level": 1, "element": E_EARTH,
		"inputs": {"item_qingling_wood": 3, "item_spirit_stone": 5}, "outputs": {"item_earth_talisman": 2},
		"xp": 25.0, "mxp": 20.0, "free_material": true,
		"desc": "以青灵木为纸，灵石磨墨，绘下厚土镇雷之纹。",
	},
	{
		"id": "craft_fireball_talisman", "name": "绘制烈火攻伐符", "skill": "talisman", "type": TYPE_CRAFT,
		"interval": 4.5, "level": 10, "element": E_FIRE,
		"inputs": {"item_qingling_wood": 4, "item_spirit_stone": 10}, "outputs": {"item_fireball_talisman": 2},
		"xp": 55.0, "mxp": 38.0, "free_material": true,
		"desc": "赤炎入墨，火球镇纸，最宜炼气期先手破敌。",
	},
	{
		"id": "meditate_basic", "name": "静坐吐纳", "skill": "cultivation", "type": TYPE_MEDITATE,
		"interval": 3.0, "level": 1, "element": E_NONE,
		"inputs": {}, "outputs": {}, "xp": 12.0, "mxp": 10.0,
		"cultivation": 15, "pill": "item_qi_pill", "pill_cultivation": 45,
		"desc": "五心向天，一呼一吸间引灵气入体。",
	},
	# ================= 筑基期（Lv 21-45） =================
	{
		"id": "gather_ziyun", "name": "采摘紫云芝", "skill": "herbalism", "type": TYPE_GATHER,
		"interval": 4.5, "level": 22, "element": E_WOOD,
		"inputs": {}, "outputs": {"item_ziyun": 1}, "xp": 48.0, "mxp": 32.0,
		"desc": "循着紫气寻到古木背阴处的灵芝。",
	},
	{
		"id": "gather_chiyan", "name": "采摘赤焰草", "skill": "herbalism", "type": TYPE_GATHER,
		"interval": 5.5, "level": 34, "element": E_FIRE,
		"inputs": {}, "outputs": {"item_chiyan": 1}, "xp": 75.0, "mxp": 48.0,
		"desc": "触之灼手的赤色灵草，火气凝而不散。",
	},
	{
		"id": "cut_ironwood", "name": "砍伐铁心木", "skill": "woodcutting", "type": TYPE_GATHER,
		"interval": 4.5, "level": 22, "element": E_WOOD,
		"inputs": {}, "outputs": {"item_ironwood": 1}, "xp": 50.0, "mxp": 34.0,
		"desc": "斧刃与木心相击，铮然作金石声。",
	},
	{
		"id": "cut_thunderwood", "name": "砍伐雷击沉香木", "skill": "woodcutting", "type": TYPE_GATHER,
		"interval": 6.0, "level": 30, "element": E_FIRE,
		"inputs": {}, "outputs": {"item_thunderwood": 1}, "xp": 82.0, "mxp": 52.0,
		"desc": "焦黑木纹间仍有雷光游走，需以灵力护手。",
	},
	{
		"id": "mine_mithril", "name": "开采秘银矿", "skill": "mining", "type": TYPE_GATHER,
		"interval": 5.0, "level": 22, "element": E_METAL,
		"inputs": {}, "outputs": {"item_mithril": 1}, "xp": 55.0, "mxp": 36.0,
		"desc": "岩层深处银光一闪，正是秘银矿脉。",
	},
	{
		"id": "mine_redgold", "name": "开采赤铜精金", "skill": "mining", "type": TYPE_GATHER,
		"interval": 6.5, "level": 35, "element": E_METAL,
		"inputs": {}, "outputs": {"item_redgold": 1}, "xp": 88.0, "mxp": 55.0,
		"desc": "赤色矿脉灼热逼人，需以寒泉淬镐。",
	},
	{
		"id": "craft_peiyuan_pill", "name": "炼制筑基培元丹", "skill": "alchemy", "type": TYPE_CRAFT,
		"interval": 4.5, "level": 22, "element": E_FIRE,
		"inputs": {"item_ziyun": 2, "item_beast_core": 1, "item_ironwood": 1}, "outputs": {"item_peiyuan_pill": 1},
		"xp": 60.0, "mxp": 40.0, "wood_fire": true, "free_material": true,
		"desc": "紫云芝为君，妖丹为引，铁心木助燃，成丹可固本培元。",
	},
	{
		"id": "craft_big_heal", "name": "炼制大回春丹", "skill": "alchemy", "type": TYPE_CRAFT,
		"interval": 4.0, "level": 26, "element": E_FIRE,
		"inputs": {"item_ziyun": 3, "item_ninglu": 2}, "outputs": {"item_big_heal": 2},
		"xp": 68.0, "mxp": 44.0, "free_material": true,
		"desc": "药力沉厚的大颗丹丸，一丸可回 110 气血。",
	},
	{
		"id": "craft_jindan_pill", "name": "炼制结金丹", "skill": "alchemy", "type": TYPE_CRAFT,
		"interval": 12.0, "level": 38, "element": E_FIRE,
		"inputs": {"item_chiyan": 5, "item_biyu_shen": 2, "item_demon_essence": 3, "item_chiyan_wutong": 3},
		"outputs": {"item_jindan_pill": 1},
		"xp": 220.0, "mxp": 120.0, "wood_fire": true, "free_material": true,
		"desc": "赤焰为火，碧玉为引，妖将精魄为核，梧桐为薪，凝成一粒金丹。",
	},
	{
		"id": "forge_mithril_sword", "name": "锻造秘银流光剑", "skill": "forging", "type": TYPE_CRAFT,
		"interval": 8.0, "level": 22, "element": E_METAL,
		"inputs": {"item_mithril": 8, "item_ironwood": 2}, "outputs": {"equip_mithril_sword": 1},
		"xp": 95.0, "mxp": 60.0, "quality": true, "free_material": true,
		"desc": "秘银轻鸣，剑成时流光绕刃。",
	},
	{
		"id": "forge_mithril_armor", "name": "锻造玄龟秘银甲", "skill": "forging", "type": TYPE_CRAFT,
		"interval": 8.5, "level": 26, "element": E_EARTH,
		"inputs": {"item_mithril": 10}, "outputs": {"equip_mithril_armor": 1},
		"xp": 110.0, "mxp": 68.0, "quality": true, "free_material": true,
		"desc": "秘银为骨，玄龟甲纹为面，坚不可摧。",
	},
	{
		"id": "forge_redgold_sword", "name": "锻造赤金破军剑", "skill": "forging", "type": TYPE_CRAFT,
		"interval": 10.0, "level": 36, "element": E_METAL,
		"inputs": {"item_redgold": 10, "item_demon_essence": 1, "item_thunderwood": 1},
		"outputs": {"equip_redgold_sword": 1},
		"xp": 165.0, "mxp": 95.0, "quality": true, "free_material": true,
		"desc": "赤金淬以妖魄，剑鸣如破军。",
	},
	{
		"id": "forge_redgold_robe", "name": "锻造流火金丝袍", "skill": "forging", "type": TYPE_CRAFT,
		"interval": 10.5, "level": 40, "element": E_FIRE,
		"inputs": {"item_redgold": 12, "item_chiyan": 3, "item_chiyan_wutong": 2}, "outputs": {"equip_redgold_robe": 1},
		"xp": 185.0, "mxp": 105.0, "quality": true, "free_material": true,
		"desc": "金丝浸赤焰，袍成时火纹流转。",
	},
	{
		"id": "craft_qingmu_ward", "name": "绘制青木回春符", "skill": "talisman", "type": TYPE_CRAFT,
		"interval": 5.0, "level": 16, "element": E_WOOD,
		"inputs": {"item_qingling_wood": 4, "item_ninglu": 2, "item_spirit_stone": 14},
		"outputs": {"item_qingmu_ward": 2},
		"xp": 62.0, "mxp": 42.0, "free_material": true,
		"desc": "青木生机凝作护身清光，回春之意绵长不绝。",
	},
	{
		"id": "craft_turtle_talisman", "name": "绘制玄龟盾符", "skill": "talisman", "type": TYPE_CRAFT,
		"interval": 5.5, "level": 22, "element": E_EARTH,
		"inputs": {"item_ironwood": 4, "item_spirit_stone": 18},
		"outputs": {"item_turtle_talisman": 2},
		"xp": 72.0, "mxp": 48.0, "free_material": true,
		"desc": "铁心木为纸，灵石磨墨，绘玄龟镇雷之纹。",
	},
	{
		"id": "craft_thunder_talisman", "name": "绘制引雷攻伐符", "skill": "talisman", "type": TYPE_CRAFT,
		"interval": 6.0, "level": 30, "element": E_FIRE,
		"inputs": {"item_thunderwood": 2, "item_spirit_stone": 25},
		"outputs": {"item_thunder_talisman": 2},
		"xp": 92.0, "mxp": 60.0, "free_material": true,
		"desc": "雷击沉香木研墨，落笔即引天雷入符。",
	},
	{
		"id": "meditate_foundation", "name": "筑基导引术", "skill": "cultivation", "type": TYPE_MEDITATE,
		"interval": 4.0, "level": 21, "element": E_NONE,
		"inputs": {}, "outputs": {}, "xp": 45.0, "mxp": 32.0,
		"cultivation": 65, "pill": "item_peiyuan_pill", "pill_cultivation": 190,
		"desc": "以筑基之境引气归元，周天运转更胜从前。",
	},
	# ================= 金丹期（Lv 46-75） =================
	{
		"id": "gather_hansui", "name": "采摘寒髓草", "skill": "herbalism", "type": TYPE_GATHER,
		"interval": 6.0, "level": 46, "element": E_WATER,
		"inputs": {}, "outputs": {"item_hansui": 1}, "xp": 125.0, "mxp": 78.0,
		"desc": "以玉铲剖开冰层，取那株凝霜的寒髓草。",
	},
	{
		"id": "gather_xinghui", "name": "采摘星辉灵芝", "skill": "herbalism", "type": TYPE_GATHER,
		"interval": 7.2, "level": 60, "element": E_WOOD,
		"inputs": {}, "outputs": {"item_xinghui": 1}, "xp": 195.0, "mxp": 115.0,
		"desc": "星辉落处，灵芝自生，需在星移之前采下。",
	},
	{
		"id": "cut_icewood", "name": "砍伐万年玄冰木", "skill": "woodcutting", "type": TYPE_GATHER,
		"interval": 6.0, "level": 46, "element": E_WATER,
		"inputs": {}, "outputs": {"item_icewood": 1}, "xp": 130.0, "mxp": 80.0,
		"desc": "斧刃触及冰壳，寒气沿柄而上。",
	},
	{
		"id": "cut_starwood", "name": "砍伐星纹梧桐木", "skill": "woodcutting", "type": TYPE_GATHER,
		"interval": 7.5, "level": 60, "element": E_WOOD,
		"inputs": {}, "outputs": {"item_starwood": 1}, "xp": 205.0, "mxp": 120.0,
		"desc": "斧落星火四溅，木心纹路如银河。",
	},
	{
		"id": "mine_stariron", "name": "开采星辰陨铁", "skill": "mining", "type": TYPE_GATHER,
		"interval": 6.5, "level": 46, "element": E_METAL,
		"inputs": {}, "outputs": {"item_stariron": 1}, "xp": 140.0, "mxp": 85.0,
		"desc": "陨铁嵌在岩层深处，镐头震得虎口发麻。",
	},
	{
		"id": "mine_primordial_crystal", "name": "开采太初灵晶", "skill": "mining", "type": TYPE_GATHER,
		"interval": 8.0, "level": 60, "element": E_EARTH,
		"inputs": {}, "outputs": {"item_primordial_crystal": 1}, "xp": 220.0, "mxp": 130.0,
		"desc": "晶簇自发微光，仿佛天地初开的一瞬。",
	},
	{
		"id": "craft_gold_pill", "name": "炼制三转金丹", "skill": "alchemy", "type": TYPE_CRAFT,
		"interval": 6.0, "level": 46, "element": E_FIRE,
		"inputs": {"item_hansui": 3, "item_icewood": 1, "item_biyu_shen": 1}, "outputs": {"item_gold_pill": 1},
		"xp": 160.0, "mxp": 95.0, "wood_fire": true, "free_material": true,
		"desc": "寒髓为水，冰木为薪，水火三转而金丹成。",
	},
	{
		"id": "craft_heart_pill", "name": "炼制九转护心丹", "skill": "alchemy", "type": TYPE_CRAFT,
		"interval": 5.5, "level": 52, "element": E_FIRE,
		"inputs": {"item_hansui": 3, "item_ziyun": 2}, "outputs": {"item_heart_pill": 2},
		"xp": 185.0, "mxp": 110.0, "free_material": true,
		"desc": "九转凝炼，一丸护心，回血 320。",
	},
	{
		"id": "craft_nascent_pill", "name": "炼制化婴丹", "skill": "alchemy", "type": TYPE_CRAFT,
		"interval": 16.0, "level": 66, "element": E_FIRE,
		"inputs": {"item_xinghui": 6, "item_star_core": 3, "item_ancient_soul": 2, "item_starwood": 4},
		"outputs": {"item_nascent_pill": 1},
		"xp": 520.0, "mxp": 260.0, "wood_fire": true, "free_material": true,
		"desc": "星辉为魂，星核为心，一丹可碎婴。",
	},
	{
		"id": "forge_star_sword", "name": "锻造星陨流光剑", "skill": "forging", "type": TYPE_CRAFT,
		"interval": 11.0, "level": 48, "element": E_METAL,
		"inputs": {"item_stariron": 10, "item_icewood": 3}, "outputs": {"equip_star_sword": 1},
		"xp": 240.0, "mxp": 135.0, "quality": true, "free_material": true,
		"desc": "陨铁在星火中重铸，剑身流光如银河。",
	},
	{
		"id": "forge_ice_armor", "name": "锻造玄冰星辰甲", "skill": "forging", "type": TYPE_CRAFT,
		"interval": 11.5, "level": 52, "element": E_WATER,
		"inputs": {"item_stariron": 12, "item_hansui": 4, "item_hanyu": 3}, "outputs": {"equip_ice_armor": 1},
		"xp": 270.0, "mxp": 150.0, "quality": true, "free_material": true,
		"desc": "寒髓淬火，冰纹与星砂在甲面上交错。",
	},
	{
		"id": "forge_primordial_sword", "name": "锻造太初斩星剑", "skill": "forging", "type": TYPE_CRAFT,
		"interval": 13.0, "level": 64, "element": E_METAL,
		"inputs": {"item_primordial_crystal": 12, "item_star_core": 2, "item_ancient_soul": 1},
		"outputs": {"equip_primordial_sword": 1},
		"xp": 380.0, "mxp": 200.0, "quality": true, "free_material": true,
		"desc": "灵晶为锋，星核为魄，残魂为引，一剑可斩落星辰。",
	},
	{
		"id": "forge_primordial_robe", "name": "锻造太初星袍", "skill": "forging", "type": TYPE_CRAFT,
		"interval": 13.5, "level": 68, "element": E_EARTH,
		"inputs": {"item_primordial_crystal": 14, "item_xinghui": 4},
		"outputs": {"equip_primordial_robe": 1},
		"xp": 420.0, "mxp": 220.0, "quality": true, "free_material": true,
		"desc": "星辉织入灵晶丝，袍成则周天星斗随之流转。",
	},
	{
		"id": "craft_taiji_talisman", "name": "绘制太极金光符", "skill": "talisman", "type": TYPE_CRAFT,
		"interval": 7.0, "level": 48, "element": E_EARTH,
		"inputs": {"item_icewood": 4, "item_spirit_stone": 65},
		"outputs": {"item_taiji_talisman": 2},
		"xp": 190.0, "mxp": 110.0, "free_material": true,
		"desc": "笔走太极，金光护体，可挡 65% 天雷。",
	},
	{
		"id": "craft_zixiao_talisman", "name": "绘制紫霄神雷符", "skill": "talisman", "type": TYPE_CRAFT,
		"interval": 7.5, "level": 60, "element": E_FIRE,
		"inputs": {"item_starwood": 3, "item_spirit_stone": 95},
		"outputs": {"item_zixiao_talisman": 2},
		"xp": 245.0, "mxp": 140.0, "free_material": true,
		"desc": "以星纹木引紫霄雷意，落笔即有雷鸣。",
	},
	{
		"id": "meditate_gold_core", "name": "金丹吐纳法", "skill": "cultivation", "type": TYPE_MEDITATE,
		"interval": 4.5, "level": 46, "element": E_NONE,
		"inputs": {}, "outputs": {}, "xp": 120.0, "mxp": 75.0,
		"cultivation": 240, "pill": "item_gold_pill", "pill_cultivation": 720,
		"desc": "金丹自转，纳星辉入丹田，周天不息。",
	},
	# ================= 元婴期（Lv 76-99） =================
	{
		"id": "gather_jiuye", "name": "采摘九叶仙芝", "skill": "herbalism", "type": TYPE_GATHER,
		"interval": 8.5, "level": 76, "element": E_WOOD,
		"inputs": {}, "outputs": {"item_jiuye": 1}, "xp": 320.0, "mxp": 180.0,
		"desc": "九叶齐全者方为上品，采时不可伤其根。",
	},
	{
		"id": "cut_fusang", "name": "砍伐扶桑神木", "skill": "woodcutting", "type": TYPE_GATHER,
		"interval": 8.5, "level": 76, "element": E_FIRE,
		"inputs": {}, "outputs": {"item_fusang": 1}, "xp": 330.0, "mxp": 185.0,
		"desc": "斧入木身，火纹如潮，需以真元护腕。",
	},
	{
		"id": "mine_taixu_gold", "name": "开采太虚仙金", "skill": "mining", "type": TYPE_GATHER,
		"interval": 9.0, "level": 76, "element": E_METAL,
		"inputs": {}, "outputs": {"item_taixu_gold": 1}, "xp": 350.0, "mxp": 195.0,
		"desc": "矿脉自虚空中垂落，非大毅力不可得。",
	},
	{
		"id": "craft_yuanying_pill", "name": "炼制元婴培神丹", "skill": "alchemy", "type": TYPE_CRAFT,
		"interval": 7.5, "level": 76, "element": E_FIRE,
		"inputs": {"item_jiuye": 3, "item_fusang": 1}, "outputs": {"item_yuanying_pill": 1},
		"xp": 380.0, "mxp": 210.0, "wood_fire": true, "free_material": true,
		"desc": "九叶为君，扶桑为薪，培神固婴。",
	},
	{
		"id": "craft_revive_pill", "name": "炼制九转还魂丹", "skill": "alchemy", "type": TYPE_CRAFT,
		"interval": 7.0, "level": 80, "element": E_FIRE,
		"inputs": {"item_jiuye": 3, "item_dragon_scale": 1}, "outputs": {"item_revive_pill": 2},
		"xp": 420.0, "mxp": 230.0, "free_material": true,
		"desc": "九转还魂，一丹回 750 气血。",
	},
	{
		"id": "craft_ascension_pill", "name": "炼制渡劫飞升丹", "skill": "alchemy", "type": TYPE_CRAFT,
		"interval": 22.0, "level": 145, "element": E_FIRE,
		"inputs": {"item_hongmeng_herb": 6, "item_hongmeng_gold": 4, "item_worldtree": 3},
		"outputs": {"item_ascension_pill": 1},
		"xp": 1300.0, "mxp": 620.0, "wood_fire": true, "free_material": true,
		"desc": "不死药为引，紫金为体，心木为薪，一丹可飞升。",
	},
	{
		"id": "forge_taixu_sword", "name": "锻造太虚斩道剑", "skill": "forging", "type": TYPE_CRAFT,
		"interval": 15.0, "level": 76, "element": E_METAL,
		"inputs": {"item_taixu_gold": 14, "item_thunder_essence": 3},
		"outputs": {"equip_taixu_sword": 1},
		"xp": 620.0, "mxp": 320.0, "quality": true, "free_material": true,
		"desc": "仙金淬雷精，剑成之日，斩断前路一切阻碍。",
	},
	{
		"id": "forge_taixu_robe", "name": "锻造太虚混元仙袍", "skill": "forging", "type": TYPE_CRAFT,
		"interval": 15.5, "level": 78, "element": E_EARTH,
		"inputs": {"item_taixu_gold": 14, "item_jiuye": 4, "item_dragon_scale": 2},
		"outputs": {"equip_taixu_robe": 1},
		"xp": 680.0, "mxp": 350.0, "quality": true, "free_material": true,
		"desc": "混元之气织入仙金丝，万劫不侵。",
	},
	{
		"id": "craft_taixu_shield", "name": "绘制太虚金光符", "skill": "talisman", "type": TYPE_CRAFT,
		"interval": 8.5, "level": 78, "element": E_EARTH,
		"inputs": {"item_fusang": 4, "item_hanyu": 3, "item_spirit_stone": 160},
		"outputs": {"item_taixu_shield": 2},
		"xp": 410.0, "mxp": 220.0, "free_material": true,
		"desc": "太虚金光罩体，可挡 75% 天雷。",
	},
	{
		"id": "craft_taixu_thunder", "name": "绘制太虚天雷符", "skill": "talisman", "type": TYPE_CRAFT,
		"interval": 9.0, "level": 84, "element": E_FIRE,
		"inputs": {"item_fusang": 3, "item_thunder_essence": 1, "item_spirit_stone": 160},
		"outputs": {"item_taixu_thunder": 2},
		"xp": 480.0, "mxp": 260.0, "free_material": true,
		"desc": "一符落，太虚雷鸣，真伤 320。",
	},
	{
		"id": "meditate_nascent", "name": "元婴化神吐纳", "skill": "cultivation", "type": TYPE_MEDITATE,
		"interval": 5.0, "level": 76, "element": E_NONE,
		"inputs": {}, "outputs": {}, "xp": 280.0, "mxp": 160.0,
		"cultivation": 680, "pill": "item_yuanying_pill", "pill_cultivation": 2000,
		"desc": "元婴出窍，化神归真，吸纳太虚清气。",
	},
	# ================= 筑基 / 金丹过渡采集（Lv32） =================
	{
		"id": "gather_biyu", "name": "采碧玉灵参", "skill": "herbalism", "type": TYPE_GATHER,
		"interval": 5.2, "level": 32, "element": E_WOOD,
		"inputs": {}, "outputs": {"item_biyu_shen": 1}, "xp": 70.0, "mxp": 46.0,
		"desc": "玉色参叶伏在苔痕下，须以竹刀轻取，不可断根。",
	},
	{
		"id": "cut_chiyan_wutong", "name": "伐赤焰梧桐", "skill": "woodcutting", "type": TYPE_GATHER,
		"interval": 5.5, "level": 32, "element": E_FIRE,
		"inputs": {}, "outputs": {"item_chiyan_wutong": 1}, "xp": 72.0, "mxp": 47.0,
		"desc": "斧刃入木，火星四溅，木心竟有火纹流转。",
	},
	{
		"id": "mine_hanyu", "name": "采寒玉髓矿", "skill": "mining", "type": TYPE_GATHER,
		"interval": 6.0, "level": 32, "element": E_WATER,
		"inputs": {}, "outputs": {"item_hanyu": 1}, "xp": 75.0, "mxp": 48.0,
		"desc": "凿开冰壳，玉髓在矿脉深处泛着幽蓝微光。",
	},
	# ================= 化神期采集（Lv82） =================
	{
		"id": "gather_longxue", "name": "采龙血草", "skill": "herbalism", "type": TYPE_GATHER,
		"interval": 9.0, "level": 80, "element": E_FIRE,
		"inputs": {}, "outputs": {"item_longxue": 1}, "xp": 360.0, "mxp": 200.0,
		"desc": "草叶赤如龙血，采时热气扑面，须以真元护住经脉。",
	},
	{
		"id": "cut_jianmu", "name": "取建木灵枝", "skill": "woodcutting", "type": TYPE_GATHER,
		"interval": 9.0, "level": 80, "element": E_WOOD,
		"inputs": {}, "outputs": {"item_jianmu": 1}, "xp": 365.0, "mxp": 202.0,
		"desc": "建木直上九天，只取侧生灵枝，不可伤其主干。",
	},
	{
		"id": "mine_jiuyou", "name": "采九幽玄晶", "skill": "mining", "type": TYPE_GATHER,
		"interval": 9.5, "level": 80, "element": E_WATER,
		"inputs": {}, "outputs": {"item_jiuyou_crystal": 1}, "xp": 370.0, "mxp": 205.0,
		"desc": "幽泉之下晶簇倒悬，触手魂寒，需以玉镐缓取。",
	},
	# ================= 炼虚期采集（Lv102） =================
	{
		"id": "gather_taiyi", "name": "采太乙青莲", "skill": "herbalism", "type": TYPE_GATHER,
		"interval": 10.5, "level": 100, "element": E_WATER,
		"inputs": {}, "outputs": {"item_taiyi_lian": 1}, "xp": 560.0, "mxp": 310.0,
		"desc": "太乙池中青莲百载一开，莲花开时水气成篆。",
	},
	{
		"id": "cut_xingchen_sang", "name": "伐星辰神桑", "skill": "woodcutting", "type": TYPE_GATHER,
		"interval": 10.5, "level": 100, "element": E_METAL,
		"inputs": {}, "outputs": {"item_xingchen_sang": 1}, "xp": 565.0, "mxp": 312.0,
		"desc": "叶落化星，斧落时星屑漫天，木心竟有银河纹。",
	},
	{
		"id": "mine_xingyun", "name": "采星陨神铁", "skill": "mining", "type": TYPE_GATHER,
		"interval": 11.0, "level": 100, "element": E_METAL,
		"inputs": {}, "outputs": {"item_xingyun_iron": 1}, "xp": 570.0, "mxp": 315.0,
		"desc": "星陨铁核嵌于陨坑深处，镐头一击，金星迸射。",
	},
	# ================= 合体期采集（Lv122） =================
	{
		"id": "gather_hundun_flower", "name": "采混沌道花", "skill": "herbalism", "type": TYPE_GATHER,
		"interval": 12.0, "level": 120, "element": E_EARTH,
		"inputs": {}, "outputs": {"item_hundun_flower": 1}, "xp": 820.0, "mxp": 440.0,
		"desc": "混沌之气凝成的道花，一瓣一味，采之如摘道则。",
	},
	{
		"id": "cut_hundun_vine", "name": "伐混沌青藤", "skill": "woodcutting", "type": TYPE_GATHER,
		"interval": 12.0, "level": 120, "element": E_WOOD,
		"inputs": {}, "outputs": {"item_hundun_vine": 1}, "xp": 825.0, "mxp": 445.0,
		"desc": "青藤自混沌中垂下，斧刃落处自行愈合，须一气断之。",
	},
	{
		"id": "mine_hundun_stone", "name": "采混沌母气石", "skill": "mining", "type": TYPE_GATHER,
		"interval": 12.5, "level": 120, "element": E_EARTH,
		"inputs": {}, "outputs": {"item_hundun_stone": 1}, "xp": 830.0, "mxp": 450.0,
		"desc": "石中含一缕天地母气，凿击时四周空间微微凹陷。",
	},
	# ================= 大乘期采集（Lv138） =================
	{
		"id": "gather_hongmeng_herb", "name": "采鸿蒙不死药", "skill": "herbalism", "type": TYPE_GATHER,
		"interval": 13.5, "level": 135, "element": E_WOOD,
		"inputs": {}, "outputs": {"item_hongmeng_herb": 1}, "xp": 1180.0, "mxp": 620.0,
		"desc": "鸿蒙初辟便已生长的仙药，药香所及，枯骨生肌。",
	},
	{
		"id": "cut_worldtree", "name": "取世界树心木", "skill": "woodcutting", "type": TYPE_GATHER,
		"interval": 13.5, "level": 135, "element": E_EARTH,
		"inputs": {}, "outputs": {"item_worldtree": 1}, "xp": 1190.0, "mxp": 625.0,
		"desc": "世界树心材内蕴一界微光，取之需以真意与树灵相商。",
	},
	{
		"id": "mine_hongmeng_gold", "name": "采鸿蒙紫金", "skill": "mining", "type": TYPE_GATHER,
		"interval": 14.0, "level": 135, "element": E_METAL,
		"inputs": {}, "outputs": {"item_hongmeng_gold": 1}, "xp": 1200.0, "mxp": 630.0,
		"desc": "紫金藏于鸿蒙裂隙，采时雷光绕镐，非大乘不可取。",
	},
	# ================= 化神 / 炼虚 / 合体 / 大乘 吐纳 =================
	{
		"id": "meditate_spirit", "name": "化神归元吐纳", "skill": "cultivation", "type": TYPE_MEDITATE,
		"interval": 5.5, "level": 81, "element": E_NONE,
		"inputs": {}, "outputs": {}, "xp": 330.0, "mxp": 180.0,
		"cultivation": 1800, "pill": "item_huashen_pill", "pill_cultivation": 5400,
		"desc": "元神初成，归元合一，一念可纳一山之灵气。",
	},
	{
		"id": "meditate_void", "name": "炼虚太虚吐纳", "skill": "cultivation", "type": TYPE_MEDITATE,
		"interval": 6.0, "level": 101, "element": E_NONE,
		"inputs": {}, "outputs": {}, "xp": 600.0, "mxp": 300.0,
		"cultivation": 4800, "pill": "item_lianxu_pill", "pill_cultivation": 14500,
		"desc": "炼虚成实，周身化作太虚，呼吸间吞吐星河。",
	},
	{
		"id": "meditate_unity", "name": "合体混元吐纳", "skill": "cultivation", "type": TYPE_MEDITATE,
		"interval": 6.5, "level": 121, "element": E_NONE,
		"inputs": {}, "outputs": {}, "xp": 950.0, "mxp": 450.0,
		"cultivation": 12500, "pill": "item_heti_pill", "pill_cultivation": 38000,
		"desc": "神与形合，混元一体，一呼一吸皆合天地节律。",
	},
	{
		"id": "meditate_great", "name": "大乘鸿蒙吐纳", "skill": "cultivation", "type": TYPE_MEDITATE,
		"interval": 7.0, "level": 136, "element": E_NONE,
		"inputs": {}, "outputs": {}, "xp": 1400.0, "mxp": 650.0,
		"cultivation": 32000, "pill": "item_dacheng_pill", "pill_cultivation": 96000,
		"desc": "鸿蒙为息，吞吐即是开辟，直指飞升之门。",
	},
	# ================= 炼丹（化神~大乘 + 功能丹） =================
	{
		"id": "craft_qingxin_pill", "name": "炼制护道清心丹", "skill": "alchemy", "type": TYPE_CRAFT,
		"interval": 7.0, "level": 62, "element": E_WATER,
		"inputs": {"item_xinghui": 2, "item_starwood": 1}, "outputs": {"item_qingxin_pill": 1},
		"xp": 205.0, "mxp": 115.0, "free_material": true,
		"desc": "星辉洗心，星木安神，一丸可固一层道心。",
	},
	{
		"id": "craft_trib_huashen", "name": "炼制化神丹", "skill": "alchemy", "type": TYPE_CRAFT,
		"interval": 16.0, "level": 80, "element": E_FIRE,
		"inputs": {"item_longxue": 4, "item_jianmu": 2, "item_jiuyou_crystal": 2},
		"outputs": {"item_trib_huashen": 1},
		"xp": 400.0, "mxp": 210.0, "wood_fire": true, "free_material": true,
		"desc": "龙血为引，建木为薪，玄晶为核，一丹可化神。",
	},
	{
		"id": "craft_huashen_pill", "name": "炼制化神培元丹", "skill": "alchemy", "type": TYPE_CRAFT,
		"interval": 9.0, "level": 81, "element": E_FIRE,
		"inputs": {"item_longxue": 3, "item_jiuyou_crystal": 1}, "outputs": {"item_huashen_pill": 1},
		"xp": 430.0, "mxp": 230.0, "wood_fire": true, "free_material": true,
		"desc": "龙血入炉，玄晶定形，化神修士的日常主丹。",
	},
	{
		"id": "craft_jiuzhuan_pill", "name": "炼制九转回元丹", "skill": "alchemy", "type": TYPE_CRAFT,
		"interval": 11.0, "level": 90, "element": E_WOOD,
		"inputs": {"item_longxue": 2, "item_jiuye": 2}, "outputs": {"item_jiuzhuan_pill": 1},
		"xp": 500.0, "mxp": 260.0, "free_material": true,
		"desc": "龙血回元，仙芝续脉，一丸兼顾气血与修为。",
	},
	{
		"id": "craft_trib_lianxu", "name": "炼制炼虚丹", "skill": "alchemy", "type": TYPE_CRAFT,
		"interval": 18.0, "level": 100, "element": E_FIRE,
		"inputs": {"item_taiyi_lian": 4, "item_xingchen_sang": 2, "item_xingyun_iron": 2},
		"outputs": {"item_trib_lianxu": 1},
		"xp": 620.0, "mxp": 310.0, "wood_fire": true, "free_material": true,
		"desc": "青莲为体，神桑为脉，神铁为骨，一丹可炼虚。",
	},
	{
		"id": "craft_lianxu_pill", "name": "炼制炼虚归真丹", "skill": "alchemy", "type": TYPE_CRAFT,
		"interval": 10.5, "level": 101, "element": E_FIRE,
		"inputs": {"item_taiyi_lian": 3, "item_huashen_note": 1}, "outputs": {"item_lianxu_pill": 1},
		"xp": 640.0, "mxp": 320.0, "wood_fire": true, "free_material": true,
		"desc": "青莲炼魂，残卷铸基，炼虚修士的日常主丹。",
	},
	{
		"id": "craft_taiyi_heal", "name": "炼制太乙回春丹", "skill": "alchemy", "type": TYPE_CRAFT,
		"interval": 8.5, "level": 105, "element": E_FIRE,
		"inputs": {"item_taiyi_lian": 3, "item_longxue": 2},
		"outputs": {"item_taiyi_heal": 2},
		"xp": 720.0, "mxp": 360.0, "wood_fire": true, "free_material": true,
		"desc": "太乙青莲养脉，龙血草生肌，一炉可得两枚回春丹。",
	},
	{
		"id": "craft_trib_heti", "name": "炼制合体丹", "skill": "alchemy", "type": TYPE_CRAFT,
		"interval": 20.0, "level": 120, "element": E_FIRE,
		"inputs": {"item_hundun_flower": 4, "item_hundun_vine": 2, "item_hundun_stone": 2},
		"outputs": {"item_trib_heti": 1},
		"xp": 900.0, "mxp": 440.0, "wood_fire": true, "free_material": true,
		"desc": "道花为心，青藤为络，母气石为炉，一丹可合体。",
	},
	{
		"id": "craft_heti_pill", "name": "炼制合体混元丹", "skill": "alchemy", "type": TYPE_CRAFT,
		"interval": 12.0, "level": 121, "element": E_FIRE,
		"inputs": {"item_hundun_flower": 3, "item_hundun_stone": 1}, "outputs": {"item_heti_pill": 1},
		"xp": 920.0, "mxp": 450.0, "wood_fire": true, "free_material": true,
		"desc": "道花入炉，母气定形，合体修士的日常主丹。",
	},
	{
		"id": "craft_hundun_heal", "name": "炼制混沌生肌丹", "skill": "alchemy", "type": TYPE_CRAFT,
		"interval": 9.5, "level": 125, "element": E_FIRE,
		"inputs": {"item_hundun_flower": 3, "item_taiyi_lian": 2},
		"outputs": {"item_hundun_heal": 2},
		"xp": 1000.0, "mxp": 500.0, "wood_fire": true, "free_material": true,
		"desc": "混沌道花化生肌理，太乙青莲续脉，一炉两枚。",
	},
	{
		"id": "craft_trib_dacheng", "name": "炼制大乘丹", "skill": "alchemy", "type": TYPE_CRAFT,
		"interval": 22.0, "level": 135, "element": E_FIRE,
		"inputs": {"item_hongmeng_herb": 4, "item_worldtree": 2, "item_hongmeng_gold": 2},
		"outputs": {"item_trib_dacheng": 1},
		"xp": 1220.0, "mxp": 580.0, "wood_fire": true, "free_material": true,
		"desc": "不死药为引，心木为薪，紫金为核，一丹可大乘。",
	},
	{
		"id": "craft_dacheng_pill", "name": "炼制大乘造化丹", "skill": "alchemy", "type": TYPE_CRAFT,
		"interval": 13.5, "level": 136, "element": E_FIRE,
		"inputs": {"item_hongmeng_herb": 3, "item_worldtree": 1}, "outputs": {"item_dacheng_pill": 1},
		"xp": 1250.0, "mxp": 600.0, "wood_fire": true, "free_material": true,
		"desc": "仙药炼形，心木铸神，大乘修士的日常主丹。",
	},
	{
		"id": "craft_hongmeng_heal", "name": "炼制鸿蒙造化生生丹", "skill": "alchemy", "type": TYPE_CRAFT,
		"interval": 10.5, "level": 140, "element": E_FIRE,
		"inputs": {"item_hongmeng_herb": 3, "item_hundun_flower": 2},
		"outputs": {"item_hongmeng_heal": 2},
		"xp": 1270.0, "mxp": 610.0, "wood_fire": true, "free_material": true,
		"desc": "鸿蒙不死药养魂，混沌道花化生，生生造化不绝。",
	},
	# ================= 锻造（化神~大乘仙兵仙甲） =================
	{
		"id": "forge_jiuyou_sword", "name": "锻造九幽斩仙剑", "skill": "forging", "type": TYPE_CRAFT,
		"interval": 16.0, "level": 84, "element": E_WATER,
		"inputs": {"item_jiuyou_crystal": 12, "item_longxue": 4}, "outputs": {"equip_jiuyou_sword": 1},
		"xp": 380.0, "mxp": 200.0, "quality": true, "free_material": true,
		"desc": "玄晶十二，龙血四滴，淬出鞘即有鬼哭的斩仙一剑。",
	},
	{
		"id": "forge_mingyuan_armor", "name": "锻造冥渊玄晶甲", "skill": "forging", "type": TYPE_CRAFT,
		"interval": 16.5, "level": 88, "element": E_EARTH,
		"inputs": {"item_jiuyou_crystal": 14, "item_jianmu": 6}, "outputs": {"equip_mingyuan_armor": 1},
		"xp": 400.0, "mxp": 210.0, "quality": true, "free_material": true,
		"desc": "玄晶叠锻三十六层，建木丝为络，寒气自成甲光。",
	},
	{
		"id": "forge_xinghe_sword", "name": "锻造星河破虚剑", "skill": "forging", "type": TYPE_CRAFT,
		"interval": 17.0, "level": 104, "element": E_METAL,
		"inputs": {"item_xingyun_iron": 12, "item_taiyi_lian": 4, "item_huashen_note": 2},
		"outputs": {"equip_xinghe_sword": 1},
		"xp": 570.0, "mxp": 290.0, "quality": true, "free_material": true,
		"desc": "神铁为骨，青莲洗锋，残卷引星，剑起时星河倒卷。",
	},
	{
		"id": "forge_xingchen_robe", "name": "锻造星辰道袍", "skill": "forging", "type": TYPE_CRAFT,
		"interval": 17.5, "level": 108, "element": E_METAL,
		"inputs": {"item_xingyun_iron": 14, "item_xingchen_sang": 6}, "outputs": {"equip_xingchen_robe": 1},
		"xp": 600.0, "mxp": 305.0, "quality": true, "free_material": true,
		"desc": "神桑织星砂，神铁作经纬，袍成则周天星斗加身。",
	},
	{
		"id": "forge_hundun_axe", "name": "锻造混沌开天斧", "skill": "forging", "type": TYPE_CRAFT,
		"interval": 18.0, "level": 124, "element": E_EARTH,
		"inputs": {"item_hundun_stone": 12, "item_hundun_vine": 6}, "outputs": {"equip_hundun_axe": 1},
		"xp": 830.0, "mxp": 410.0, "quality": true, "free_material": true,
		"desc": "母气石为斧身，青藤为柄，一斧落下，天地初分。",
	},
	{
		"id": "forge_hunyuan_robe", "name": "锻造混元宝衣", "skill": "forging", "type": TYPE_CRAFT,
		"interval": 18.5, "level": 128, "element": E_EARTH,
		"inputs": {"item_hundun_stone": 14, "item_hundun_flower": 4}, "outputs": {"equip_hunyuan_robe": 1},
		"xp": 870.0, "mxp": 430.0, "quality": true, "free_material": true,
		"desc": "道花入织，母气定形，混元一气，万劫不侵。",
	},
	{
		"id": "forge_hongmeng_sword", "name": "锻造鸿蒙诛仙剑", "skill": "forging", "type": TYPE_CRAFT,
		"interval": 19.0, "level": 140, "element": E_METAL,
		"inputs": {"item_hongmeng_gold": 14, "item_worldtree": 6}, "outputs": {"equip_hongmeng_sword": 1},
		"xp": 1200.0, "mxp": 560.0, "quality": true, "free_material": true,
		"desc": "紫金为锋，心木为脊，剑成之日，仙神辟易。",
	},
	{
		"id": "forge_zaohua_robe", "name": "锻造造化仙衣", "skill": "forging", "type": TYPE_CRAFT,
		"interval": 19.5, "level": 145, "element": E_EARTH,
		"inputs": {"item_hongmeng_gold": 16, "item_hongmeng_herb": 4}, "outputs": {"equip_zaohua_robe": 1},
		"xp": 1300.0, "mxp": 600.0, "quality": true, "free_material": true,
		"desc": "仙药汁染紫金丝，造化之力在衣上流转不息。",
	},
	# ================= 制符（金丹过渡 ~ 大乘） =================
	{
		"id": "craft_xuanbing_talisman", "name": "绘制玄冰护体符", "skill": "talisman", "type": TYPE_CRAFT,
		"interval": 7.2, "level": 48, "element": E_WATER,
		"inputs": {"item_hansui": 2, "item_spirit_stone": 60}, "outputs": {"item_xuanbing_talisman": 2},
		"xp": 190.0, "mxp": 105.0, "free_material": true,
		"desc": "寒髓研墨，落笔成冰，可挡七成天雷。",
	},
	{
		"id": "craft_jiuyou_ward", "name": "绘制九幽镇魂符", "skill": "talisman", "type": TYPE_CRAFT,
		"interval": 8.0, "level": 85, "element": E_WATER,
		"inputs": {"item_jiuyou_crystal": 2, "item_spirit_stone": 180}, "outputs": {"item_jiuyou_ward": 2},
		"xp": 420.0, "mxp": 220.0, "free_material": true,
		"desc": "玄晶为墨，幽泉为引，镇魂纹一成，天雷八成不入。",
	},
	{
		"id": "craft_jianmu_ward", "name": "绘制建木长春符", "skill": "talisman", "type": TYPE_CRAFT,
		"interval": 8.2, "level": 92, "element": E_WOOD,
		"inputs": {"item_jianmu": 3, "item_spirit_stone": 240}, "outputs": {"item_jianmu_ward": 2},
		"xp": 470.0, "mxp": 245.0, "free_material": true,
		"desc": "建木灵枝研墨，长春清光护体，生机不绝。",
	},
	{
		"id": "craft_xingyun_ward", "name": "绘制星陨灭魔符", "skill": "talisman", "type": TYPE_CRAFT,
		"interval": 8.5, "level": 105, "element": E_METAL,
		"inputs": {"item_xingyun_iron": 2, "item_spirit_stone": 320}, "outputs": {"item_xingyun_ward": 2},
		"xp": 600.0, "mxp": 310.0, "free_material": true,
		"desc": "星陨为墨，灭魔为纹，可挡八成半的天雷。",
	},
	{
		"id": "craft_xingchen_thunder", "name": "绘制星辰陨雷符", "skill": "talisman", "type": TYPE_CRAFT,
		"interval": 8.8, "level": 110, "element": E_FIRE,
		"inputs": {"item_xingchen_sang": 3, "item_spirit_stone": 420}, "outputs": {"item_xingchen_thunder": 2},
		"xp": 660.0, "mxp": 340.0, "free_material": true,
		"desc": "星辰神桑引雷，陨雷落纸，破魔诛邪。",
	},
	{
		"id": "craft_hundun_ward", "name": "绘制混沌金刚符", "skill": "talisman", "type": TYPE_CRAFT,
		"interval": 9.0, "level": 125, "element": E_EARTH,
		"inputs": {"item_hundun_stone": 2, "item_spirit_stone": 600}, "outputs": {"item_hundun_ward": 2},
		"xp": 870.0, "mxp": 440.0, "free_material": true,
		"desc": "母气石磨墨，金刚不坏之纹落纸，天雷近九成不入。",
	},
	{
		"id": "craft_hundun_thunder", "name": "绘制混沌裂空符", "skill": "talisman", "type": TYPE_CRAFT,
		"interval": 9.4, "level": 128, "element": E_FIRE,
		"inputs": {"item_hundun_vine": 3, "item_spirit_stone": 720}, "outputs": {"item_hundun_thunder": 2},
		"xp": 960.0, "mxp": 480.0, "free_material": true,
		"desc": "青藤承雷，裂空成纹，一击碎岳。",
	},
	{
		"id": "craft_hongmeng_thunder", "name": "绘制鸿蒙紫霄神雷符", "skill": "talisman", "type": TYPE_CRAFT,
		"interval": 10.0, "level": 142, "element": E_FIRE,
		"inputs": {"item_hongmeng_gold": 2, "item_spirit_stone": 900}, "outputs": {"item_hongmeng_thunder": 2},
		"xp": 1240.0, "mxp": 600.0, "free_material": true,
		"desc": "紫金引雷，一符落处，鸿蒙紫霄轰然降临，真伤 980。",
	},
	{
		"id": "craft_worldtree_ward", "name": "绘制世界树不灭符", "skill": "talisman", "type": TYPE_CRAFT,
		"interval": 10.5, "level": 146, "element": E_WOOD,
		"inputs": {"item_worldtree": 2, "item_spirit_stone": 1100}, "outputs": {"item_worldtree_ward": 2},
		"xp": 1340.0, "mxp": 650.0, "free_material": true,
		"desc": "心木精气化盾，万法难侵，清光不灭。",
	},
]

const ENEMY_DEFS: Array = [
	{
		"id": "enemy_wild_wolf", "name": "灵气妖狼", "region": "wild_wolf_forest",
		"hp": 80, "atk": 10, "interval": 2.6, "def": 2, "dodge": 0.0, "xp": 25.0,
		"desc": "受灵气侵染的野狼，双目幽绿，动作迅捷。",
		"loot": [
			{"item_id": "item_spirit_stone", "min": 4, "max": 8, "chance": 1.0},
			{"item_id": "item_qingye", "min": 1, "max": 1, "chance": 0.30},
			{"item_id": "item_beast_core", "min": 1, "max": 1, "chance": 0.15},
		],
	},
	{
		"id": "enemy_iron_boar", "name": "玄甲妖猪", "region": "wild_wolf_forest",
		"hp": 150, "atk": 16, "interval": 3.0, "def": 6, "dodge": 0.0, "xp": 40.0,
		"desc": "背生玄铁硬甲的妖猪，冲撞之势可裂青石。",
		"loot": [
			{"item_id": "item_spirit_stone", "min": 10, "max": 18, "chance": 1.0},
			{"item_id": "item_crude_iron", "min": 2, "max": 2, "chance": 0.35},
			{"item_id": "item_beast_core", "min": 1, "max": 1, "chance": 0.30},
		],
	},
	{
		"id": "enemy_wolf_king", "name": "苍月狼王", "region": "wild_wolf_forest", "boss": true,
		"hp": 280, "atk": 24, "interval": 2.4, "def": 10, "dodge": 0.02, "xp": 80.0,
		"desc": "狼群之首，额头生有苍月纹，长啸可乱人心神。",
		"loot": [
			{"item_id": "item_spirit_stone", "min": 25, "max": 40, "chance": 1.0},
			{"item_id": "item_beast_core", "min": 2, "max": 2, "chance": 0.65},
			{"item_id": "item_ninglu", "min": 2, "max": 2, "chance": 0.40},
		],
	},
	# ================= 古修遗迹（筑基期秘境） =================
	{
		"id": "enemy_miasma_python", "name": "毒瘴妖蟒", "region": "ancient_ruins",
		"hp": 520, "atk": 36, "interval": 2.6, "def": 16, "dodge": 0.05, "xp": 160.0,
		"desc": "盘踞遗迹水道的巨蟒，吐息带毒瘴。",
		"loot": [
			{"item_id": "item_spirit_stone", "min": 35, "max": 55, "chance": 1.0},
			{"item_id": "item_ziyun", "min": 1, "max": 1, "chance": 0.35},
			{"item_id": "item_demon_essence", "min": 1, "max": 1, "chance": 0.18},
		],
	},
	{
		"id": "enemy_stone_golem", "name": "石甲傀儡", "region": "ancient_ruins",
		"hp": 880, "atk": 50, "interval": 3.1, "def": 26, "dodge": 0.06, "xp": 240.0,
		"desc": "古修遗留的守墓傀儡，石甲厚重，行动迟缓。",
		"loot": [
			{"item_id": "item_spirit_stone", "min": 60, "max": 90, "chance": 1.0},
			{"item_id": "item_mithril", "min": 2, "max": 2, "chance": 0.40},
			{"item_id": "item_demon_essence", "min": 1, "max": 1, "chance": 0.32},
		],
	},
	{
		"id": "enemy_ruin_guardian", "name": "遗迹金傀", "region": "ancient_ruins", "boss": true,
		"hp": 1500, "atk": 72, "interval": 2.5, "def": 36, "dodge": 0.08, "xp": 420.0,
		"desc": "遗迹最深处的金甲傀儡，胸口嵌着残缺的阵核。",
		"loot": [
			{"item_id": "item_spirit_stone", "min": 120, "max": 180, "chance": 1.0},
			{"item_id": "item_demon_essence", "min": 2, "max": 2, "chance": 0.65},
			{"item_id": "item_chiyan", "min": 2, "max": 2, "chance": 0.45},
			{"item_id": "item_redgold", "min": 2, "max": 2, "chance": 0.30},
		],
	},
	# ================= 星陨古墟（金丹期秘境） =================
	{
		"id": "enemy_star_wraith", "name": "星墟残魂", "region": "star_ruins",
		"hp": 2600, "atk": 108, "interval": 2.4, "def": 48, "dodge": 0.12, "xp": 620.0,
		"desc": "陨星余烬中不散的残魂，飘忽无定。",
		"loot": [
			{"item_id": "item_spirit_stone", "min": 160, "max": 240, "chance": 1.0},
			{"item_id": "item_hansui", "min": 2, "max": 2, "chance": 0.35},
			{"item_id": "item_star_core", "min": 1, "max": 1, "chance": 0.20},
		],
	},
	{
		"id": "enemy_frost_ape", "name": "玄冰古猿", "region": "star_ruins",
		"hp": 4200, "atk": 145, "interval": 2.9, "def": 68, "dodge": 0.12, "xp": 980.0,
		"desc": "栖于冰窟的古猿，肩覆玄冰，力能裂石。",
		"loot": [
			{"item_id": "item_spirit_stone", "min": 260, "max": 380, "chance": 1.0},
			{"item_id": "item_stariron", "min": 2, "max": 2, "chance": 0.40},
			{"item_id": "item_star_core", "min": 1, "max": 1, "chance": 0.35},
			{"item_id": "item_ancient_soul", "min": 1, "max": 1, "chance": 0.20},
		],
	},
	{
		"id": "enemy_star_dragon", "name": "陨星蛟王", "region": "star_ruins", "boss": true,
		"hp": 7200, "atk": 205, "interval": 2.5, "def": 92, "dodge": 0.16, "xp": 1800.0,
		"desc": "吞星而生的蛟王，额顶星珠不灭，古墟之主。",
		"loot": [
			{"item_id": "item_spirit_stone", "min": 500, "max": 750, "chance": 1.0},
			{"item_id": "item_star_core", "min": 2, "max": 2, "chance": 0.70},
			{"item_id": "item_ancient_soul", "min": 2, "max": 2, "chance": 0.55},
			{"item_id": "item_primordial_crystal", "min": 2, "max": 2, "chance": 0.35},
		],
	},
	# ================= 太虚雷泽（元婴期秘境） =================
	{
		"id": "enemy_thunder_serpent", "name": "雷泽灵蛟", "region": "taixu_marsh",
		"hp": 13500, "atk": 310, "interval": 2.3, "def": 135, "dodge": 0.20, "xp": 3600.0,
		"desc": "雷泽深处的灵蛟，鳞片间电弧游走。",
		"loot": [
			{"item_id": "item_spirit_stone", "min": 450, "max": 650, "chance": 1.0},
			{"item_id": "item_jiuye", "min": 2, "max": 2, "chance": 0.35},
			{"item_id": "item_thunder_essence", "min": 1, "max": 1, "chance": 0.25},
		],
	},
	{
		"id": "enemy_taixu_beast", "name": "太虚雷兽", "region": "taixu_marsh",
		"hp": 21000, "atk": 420, "interval": 2.7, "def": 175, "dodge": 0.22, "xp": 5400.0,
		"desc": "生于雷云中心的古兽，怒吼即雷鸣。",
		"loot": [
			{"item_id": "item_spirit_stone", "min": 720, "max": 1000, "chance": 1.0},
			{"item_id": "item_taixu_gold", "min": 2, "max": 2, "chance": 0.40},
			{"item_id": "item_thunder_essence", "min": 1, "max": 1, "chance": 0.40},
			{"item_id": "item_dragon_scale", "min": 1, "max": 1, "chance": 0.25},
		],
	},
	{
		"id": "enemy_dragon_remnant", "name": "真龙残灵", "region": "taixu_marsh", "boss": true,
		"hp": 36000, "atk": 580, "interval": 2.4, "def": 230, "dodge": 0.25, "xp": 11000.0,
		"desc": "雷泽尽头的真龙残灵，一声龙吟可碎金石。",
		"loot": [
			{"item_id": "item_spirit_stone", "min": 1400, "max": 2000, "chance": 1.0},
			{"item_id": "item_thunder_essence", "min": 2, "max": 2, "chance": 0.75},
			{"item_id": "item_dragon_scale", "min": 2, "max": 2, "chance": 0.60},
			{"item_id": "item_fusang", "min": 3, "max": 3, "chance": 0.45},
		],
	},
	# ================= 九幽冥渊（化神期秘境） =================
	{
		"id": "enemy_youming_ghost", "name": "幽冥鬼将", "region": "youming_abyss",
		"hp": 38000, "atk": 780, "interval": 2.4, "def": 300, "dodge": 0.26, "xp": 20000.0,
		"desc": "披着残甲的鬼将，幽泉自甲缝间滴落。",
		"loot": [
			{"item_id": "item_spirit_stone", "min": 2200, "max": 3000, "chance": 1.0},
			{"item_id": "item_jiuyou_crystal", "min": 1, "max": 2, "chance": 0.35},
			{"item_id": "item_longxue", "min": 1, "max": 1, "chance": 0.30},
		],
	},
	{
		"id": "enemy_blood_crow", "name": "血羽冥鸦", "region": "youming_abyss",
		"hp": 58000, "atk": 1000, "interval": 2.2, "def": 360, "dodge": 0.28, "xp": 32000.0,
		"desc": "羽如凝血，成群掠过低空时阴风大作。",
		"loot": [
			{"item_id": "item_spirit_stone", "min": 2600, "max": 3600, "chance": 1.0},
			{"item_id": "item_longxue", "min": 2, "max": 2, "chance": 0.40},
			{"item_id": "item_jiuyou_crystal", "min": 1, "max": 1, "chance": 0.30},
		],
	},
	{
		"id": "enemy_jiuyou_king", "name": "九幽鬼帝", "region": "youming_abyss", "boss": true,
		"hp": 92000, "atk": 1300, "interval": 2.5, "def": 430, "dodge": 0.30, "xp": 52000.0,
		"desc": "冥渊之主，头戴九旒冕，一喝可散人魂魄。",
		"loot": [
			{"item_id": "item_spirit_stone", "min": 3200, "max": 4500, "chance": 1.0},
			{"item_id": "item_jiuyou_crystal", "min": 2, "max": 2, "chance": 0.70},
			{"item_id": "item_longxue", "min": 2, "max": 2, "chance": 0.55},
			{"item_id": "item_huashen_note", "min": 1, "max": 1, "chance": 0.30},
		],
	},
	# ================= 无尽星海（炼虚期秘境） =================
	{
		"id": "enemy_star_whale", "name": "星海巨鲸", "region": "star_sea",
		"hp": 115000, "atk": 1800, "interval": 2.6, "def": 560, "dodge": 0.32, "xp": 80000.0,
		"desc": "游弋于星尘之间的巨鲸，尾鳍一扫即成星漩。",
		"loot": [
			{"item_id": "item_spirit_stone", "min": 5500, "max": 7500, "chance": 1.0},
			{"item_id": "item_taiyi_lian", "min": 1, "max": 1, "chance": 0.35},
			{"item_id": "item_xingyun_iron", "min": 1, "max": 1, "chance": 0.30},
		],
	},
	{
		"id": "enemy_nebula_spirit", "name": "星云灵魅", "region": "star_sea",
		"hp": 175000, "atk": 2200, "interval": 2.3, "def": 660, "dodge": 0.34, "xp": 120000.0,
		"desc": "星云凝成的灵魅，形体聚散无常，触之则神魂恍惚。",
		"loot": [
			{"item_id": "item_spirit_stone", "min": 6800, "max": 9000, "chance": 1.0},
			{"item_id": "item_xingchen_sang", "min": 2, "max": 2, "chance": 0.35},
			{"item_id": "item_xingyun_iron", "min": 1, "max": 1, "chance": 0.32},
		],
	},
	{
		"id": "enemy_void_dragon", "name": "虚空星龙", "region": "star_sea", "boss": true,
		"hp": 270000, "atk": 2700, "interval": 2.4, "def": 780, "dodge": 0.36, "xp": 180000.0,
		"desc": "盘踞星海尽头的星龙，鳞片即是压缩的星核。",
		"loot": [
			{"item_id": "item_spirit_stone", "min": 8500, "max": 11000, "chance": 1.0},
			{"item_id": "item_xingyun_iron", "min": 3, "max": 3, "chance": 0.70},
			{"item_id": "item_taiyi_lian", "min": 2, "max": 2, "chance": 0.55},
			{"item_id": "item_xingchen_sang", "min": 3, "max": 3, "chance": 0.45},
		],
	},
	# ================= 混沌古界（合体期秘境） =================
	{
		"id": "enemy_chaos_golem", "name": "混沌石魔", "region": "chaos_realm",
		"hp": 320000, "atk": 3800, "interval": 3.0, "def": 1100, "dodge": 0.35, "xp": 320000.0,
		"desc": "由混沌碎石自行拼合的巨魔，砸落时地面寸寸龟裂。",
		"loot": [
			{"item_id": "item_spirit_stone", "min": 14000, "max": 19000, "chance": 1.0},
			{"item_id": "item_hundun_stone", "min": 1, "max": 1, "chance": 0.35},
			{"item_id": "item_hundun_vine", "min": 1, "max": 1, "chance": 0.30},
		],
	},
	{
		"id": "enemy_void_devourer", "name": "噬界妖虫", "region": "chaos_realm",
		"hp": 480000, "atk": 4600, "interval": 2.2, "def": 1300, "dodge": 0.38, "xp": 480000.0,
		"desc": "口器能咬穿空间壁垒的妖虫，所过之处界面如纸。",
		"loot": [
			{"item_id": "item_spirit_stone", "min": 17000, "max": 23000, "chance": 1.0},
			{"item_id": "item_hundun_vine", "min": 2, "max": 2, "chance": 0.35},
			{"item_id": "item_hundun_flower", "min": 1, "max": 1, "chance": 0.28},
		],
	},
	{
		"id": "enemy_chaos_lord", "name": "混沌古神", "region": "chaos_realm", "boss": true,
		"hp": 750000, "atk": 5600, "interval": 2.5, "def": 1350, "dodge": 0.40, "xp": 700000.0,
		"desc": "混沌未分时的古神残念，睁眼即是开天，闭眼便是归墟。",
		"loot": [
			{"item_id": "item_spirit_stone", "min": 21000, "max": 28000, "chance": 1.0},
			{"item_id": "item_hundun_flower", "min": 2, "max": 2, "chance": 0.70},
			{"item_id": "item_hundun_stone", "min": 3, "max": 3, "chance": 0.60},
			{"item_id": "item_hundun_vine", "min": 3, "max": 3, "chance": 0.50},
		],
	},
	# ================= 三十三天外（大乘期秘境） =================
	{
		"id": "enemy_heaven_general", "name": "天外神将", "region": "heaven_beyond",
		"hp": 820000, "atk": 8000, "interval": 2.4, "def": 2200, "dodge": 0.38, "xp": 1200000.0,
		"desc": "三十三天外的巡天神将，金甲无隙，长戟所指皆成规矩。",
		"loot": [
			{"item_id": "item_spirit_stone", "min": 35000, "max": 47000, "chance": 1.0},
			{"item_id": "item_hongmeng_herb", "min": 1, "max": 1, "chance": 0.30},
			{"item_id": "item_worldtree", "min": 1, "max": 1, "chance": 0.28},
		],
	},
	{
		"id": "enemy_primordial_beast", "name": "鸿蒙凶兽", "region": "heaven_beyond",
		"hp": 1250000, "atk": 9800, "interval": 2.6, "def": 2600, "dodge": 0.40, "xp": 1800000.0,
		"desc": "鸿蒙初辟时便存在的凶兽，一爪可撕开裂界。",
		"loot": [
			{"item_id": "item_spirit_stone", "min": 44000, "max": 58000, "chance": 1.0},
			{"item_id": "item_worldtree", "min": 2, "max": 2, "chance": 0.32},
			{"item_id": "item_hongmeng_gold", "min": 1, "max": 1, "chance": 0.25},
		],
	},
	{
		"id": "enemy_heaven_emperor", "name": "三十三天帝", "region": "heaven_beyond", "boss": true,
		"hp": 1850000, "atk": 12000, "interval": 2.3, "def": 2600, "dodge": 0.42, "xp": 2600000.0,
		"desc": "统御三十三天的天帝，抬手便是天条，垂目即是雷劫。",
		"loot": [
			{"item_id": "item_spirit_stone", "min": 52000, "max": 68000, "chance": 1.0},
			{"item_id": "item_hongmeng_gold", "min": 3, "max": 3, "chance": 0.70},
			{"item_id": "item_hongmeng_herb", "min": 2, "max": 2, "chance": 0.60},
			{"item_id": "item_worldtree", "min": 3, "max": 3, "chance": 0.50},
		],
	},
]

## 灵田种子表：seed_id -> {id, name, crop_id, grow_seconds, min_yield, max_yield, desc}
const SEED_DEFS: Array = [
	{
		"id": "seed_qingye", "crop": "item_qingye", "name": "青叶草灵种",
		"grow": 600, "min": 35, "max": 55,
		"desc": "十分钟成熟，大丰收青叶草 35~55 株。",
	},
	{
		"id": "seed_ninglu", "crop": "item_ninglu", "name": "凝露花灵种",
		"grow": 1500, "min": 40, "max": 65,
		"desc": "二十五分钟成熟，大丰收凝露花 40~65 朵。",
	},
	{
		"id": "seed_spirit_berry", "crop": "item_spirit_berry", "name": "赤阳灵果种",
		"grow": 2700, "min": 3, "max": 5,
		"desc": "四十五分钟成熟，收获赤阳灵果 3~5 枚。",
	},
	{
		"id": "seed_ziyun", "crop": "item_ziyun", "name": "紫云芝灵种",
		"grow": 2100, "min": 45, "max": 70,
		"desc": "三十五分钟成熟，大丰收紫云芝 45~70 株。",
	},
	{
		"id": "seed_chiyan", "crop": "item_chiyan", "name": "赤焰草灵种",
		"grow": 3000, "min": 50, "max": 80,
		"desc": "五十分钟成熟，大丰收赤焰草 50~80 株。",
	},
	{
		"id": "seed_hansui", "crop": "item_hansui", "name": "寒髓草灵种",
		"grow": 3600, "min": 55, "max": 85,
		"desc": "六十分钟成熟，大丰收寒髓草 55~85 株。",
	},
	{
		"id": "seed_xinghui", "crop": "item_xinghui", "name": "星辉灵芝种",
		"grow": 4800, "min": 60, "max": 95,
		"desc": "八十分钟成熟，大丰收星辉灵芝 60~95 株。",
	},
	{
		"id": "seed_jiuye", "crop": "item_jiuye", "name": "九叶仙芝种",
		"grow": 5400, "min": 65, "max": 105,
		"desc": "九十分钟成熟，大丰收九叶仙芝 65~105 株。",
	},
	{
		"id": "seed_biyu", "crop": "item_biyu_shen", "name": "碧玉灵参种",
		"grow": 3600, "min": 55, "max": 90,
		"desc": "六十分钟成熟，大丰收碧玉灵参 55~90 株。",
	},
	{
		"id": "seed_longxue", "crop": "item_longxue", "name": "龙血草灵种",
		"grow": 6000, "min": 70, "max": 110,
		"desc": "一百分钟成熟，大丰收龙血草 70~110 株。",
	},
	{
		"id": "seed_taiyi", "crop": "item_taiyi_lian", "name": "太乙青莲种",
		"grow": 6600, "min": 75, "max": 120,
		"desc": "一百一十分钟成熟，大丰收太乙青莲 75~120 株。",
	},
	{
		"id": "seed_hundun", "crop": "item_hundun_flower", "name": "混沌道花种",
		"grow": 7200, "min": 80, "max": 130,
		"desc": "一百二十分钟成熟，大丰收混沌道花 80~130 株。",
	},
	{
		"id": "seed_hongmeng", "crop": "item_hongmeng_herb", "name": "鸿蒙不死药种",
		"grow": 8400, "min": 90, "max": 145,
		"desc": "一百四十分钟成熟，大丰收鸿蒙不死药 90~145 株。",
	},
]

## 采集主产副产灵种：action_id -> {seed_id, chance}
const SEED_DROPS: Dictionary = {
	"gather_qingye": {"seed_id": "seed_qingye", "chance": 0.12},
	"gather_ninglu": {"seed_id": "seed_ninglu", "chance": 0.15},
	"gather_ziyun": {"seed_id": "seed_ziyun", "chance": 0.12},
	"gather_chiyan": {"seed_id": "seed_chiyan", "chance": 0.12},
	"gather_hansui": {"seed_id": "seed_hansui", "chance": 0.12},
	"gather_xinghui": {"seed_id": "seed_xinghui", "chance": 0.12},
	"gather_jiuye": {"seed_id": "seed_jiuye", "chance": 0.12},
	"gather_biyu": {"seed_id": "seed_biyu", "chance": 0.12},
	"gather_longxue": {"seed_id": "seed_longxue", "chance": 0.12},
	"gather_taiyi": {"seed_id": "seed_taiyi", "chance": 0.12},
	"gather_hundun_flower": {"seed_id": "seed_hundun", "chance": 0.12},
	"gather_hongmeng_herb": {"seed_id": "seed_hongmeng", "chance": 0.12},
}

## 自动消耗优先级（渡劫 / 战斗 / 镇魔塔）：高品阶优先，用尽自动降级
const HEAL_ITEMS: Array = [
	{"id": "item_hongmeng_heal", "heal": 11440},
	{"id": "item_hundun_heal", "heal": 7020},
	{"id": "item_taiyi_heal", "heal": 4160},
	{"id": "item_jiuzhuan_pill", "heal": 2600},
	{"id": "item_revive_pill", "heal": 750},
	{"id": "item_heart_pill", "heal": 320},
	{"id": "item_big_heal", "heal": 110},
	{"id": "item_heal_powder", "heal": 35},
]

const WARD_ITEMS: Array = [
	{"id": "item_worldtree_ward", "ratio": 0.91},
	{"id": "item_hundun_ward", "ratio": 0.88},
	{"id": "item_xingyun_ward", "ratio": 0.85},
	{"id": "item_jianmu_ward", "ratio": 0.82},
	{"id": "item_jiuyou_ward", "ratio": 0.80},
	{"id": "item_taixu_shield", "ratio": 0.75},
	{"id": "item_xuanbing_talisman", "ratio": 0.70},
	{"id": "item_taiji_talisman", "ratio": 0.65},
	{"id": "item_turtle_talisman", "ratio": 0.55},
	{"id": "item_qingmu_ward", "ratio": 0.48},
	{"id": "item_earth_talisman", "ratio": 0.4},
]

## 引雷攻伐符：鸿蒙紫霄（980）> 混沌裂空（760）> 星辰陨雷（540）> 太虚天雷（320）
## > 紫霄神雷（140）> 引雷攻伐（45）> 烈火攻伐（18）
## 攻伐符箓：damage=符面值（保底=10%），mult=玩家攻击力克制倍率（头目/妖王再 ×0.55）。
## 定位开场先手破防，绝不替代普攻输出。
## （星陨灭魔符为护符 ward 0.85，不入攻伐池。）
const THUNDER_ITEMS: Array = [
	{"id": "item_hongmeng_thunder", "damage": 980, "mult": 1.40},
	{"id": "item_hundun_thunder", "damage": 760, "mult": 1.26},
	{"id": "item_xingchen_thunder", "damage": 540, "mult": 1.12},
	{"id": "item_taixu_thunder", "damage": 320, "mult": 0.95},
	{"id": "item_zixiao_talisman", "damage": 140, "mult": 0.70},
	{"id": "item_thunder_talisman", "damage": 45, "mult": 0.45},
	{"id": "item_fireball_talisman", "damage": 18, "mult": 0.30},
]

const THUNDER_TALISMAN: String = "item_thunder_talisman"
const THUNDER_TALISMAN_DAMAGE: int = 45

## 「仙坊阁」商品表
const SHOP_DEFS: Array = [
	# ---- 采集法器
	{
		"id": "tool_herb_hoe_1", "name": "青铜药锄", "category": "gear", "cost": 180,
		"effect_type": "interval", "effect_target": "herbalism", "effect_value": -0.15,
		"desc": "采药寻灵耗时 -15%。",
	},
	{
		"id": "tool_wood_axe_1", "name": "玄铁伐木斧", "category": "gear", "cost": 180,
		"effect_type": "interval", "effect_target": "woodcutting", "effect_value": -0.15,
		"desc": "伐木取材耗时 -15%。",
	},
	{
		"id": "tool_mine_pick_1", "name": "破岩灵镐", "category": "gear", "cost": 220,
		"effect_type": "interval", "effect_target": "mining", "effect_value": -0.15,
		"desc": "开矿掘脉耗时 -15%。",
	},
	{
		"id": "tool_herb_hoe_2", "name": "碧玉药锄", "category": "gear", "cost": 950,
		"effect_type": "interval", "effect_target": "herbalism", "effect_value": -0.15,
		"prerequisite": "tool_herb_hoe_1", "required_realm": 9,
		"desc": "采药寻灵耗时再 -15%（需筑基期）。",
	},
	# ---- 百艺宝具
	{
		"id": "gear_alchemy_furnace_1", "name": "青铜丹炉", "category": "gear", "cost": 360,
		"effect_type": "double_chance", "effect_target": "alchemy", "effect_value": 0.10,
		"desc": "丹道炼制双倍产出率 +10%。",
	},
	{
		"id": "gear_forge_hammer_1", "name": "地火锻锤", "category": "gear", "cost": 420,
		"effect_type": "quality_pct", "effect_target": "forging", "effect_value": 0.15,
		"desc": "器道锻造精良品质概率 +15%。",
	},
	{
		"id": "gear_meditate_mat_1", "name": "聚灵蒲团", "category": "gear", "cost": 520,
		"effect_type": "cultivation_pct", "effect_target": "cultivation", "effect_value": 0.20,
		"desc": "吐纳筑基修为获取 +20%。",
	},
	{
		"id": "gear_combat_bell_1", "name": "护身灵铃", "category": "gear", "cost": 600,
		"effect_type": "heal_pct", "effect_target": "all", "effect_value": 0.20,
		"desc": "战斗与渡劫中回春散回血效果 +20%。",
	},
	# ---- 洞府扩建
	{
		"id": "farm_plot_2", "name": "开垦二号灵田", "category": "farm", "cost": 240,
		"effect_type": "unlock_plot", "effect_target": "1", "effect_value": 1.0,
		"desc": "在洞府中开出第二块灵田。",
	},
	{
		"id": "farm_plot_3", "name": "开垦三号灵田", "category": "farm", "cost": 680,
		"effect_type": "unlock_plot", "effect_target": "2", "effect_value": 1.0,
		"prerequisite": "farm_plot_2",
		"desc": "在洞府中开出第三块灵田。",
	},
	{
		"id": "farm_plot_4", "name": "开垦四号灵田", "category": "farm", "cost": 1600,
		"effect_type": "unlock_plot", "effect_target": "3", "effect_value": 1.0,
		"prerequisite": "farm_plot_3",
		"desc": "在洞府中开出第四块灵田。",
	},
	# ---- 灵种杂货（可反复购买）
	{
		"id": "seed_qingye", "name": "青叶草灵种", "category": "seed", "cost": 15, "max_level": 0,
		"effect_type": "grant_item", "effect_target": "seed_qingye",
		"desc": "15 灵石 / 粒，十分钟可收。",
	},
	{
		"id": "seed_ninglu", "name": "凝露花灵种", "category": "seed", "cost": 45, "max_level": 0,
		"effect_type": "grant_item", "effect_target": "seed_ninglu",
		"desc": "45 灵石 / 粒，二十五分钟可收。",
	},
	{
		"id": "seed_spirit_berry", "name": "赤阳灵果种", "category": "seed", "cost": 80, "max_level": 0,
		"effect_type": "grant_item", "effect_target": "seed_spirit_berry",
		"desc": "80 灵石 / 粒，四十五分钟得赤阳灵果。",
	},
	# ---- 筑基期上架
	{
		"id": "tool_wood_axe_2", "name": "寒铁灵斧", "category": "gear", "cost": 950,
		"effect_type": "interval", "effect_target": "woodcutting", "effect_value": -0.15,
		"prerequisite": "tool_wood_axe_1", "required_realm": 9,
		"desc": "伐木取材耗时再 -15%（需筑基期）。",
	},
	{
		"id": "tool_mine_pick_2", "name": "玄金破脉镐", "category": "gear", "cost": 1100,
		"effect_type": "interval", "effect_target": "mining", "effect_value": -0.15,
		"prerequisite": "tool_mine_pick_1", "required_realm": 9,
		"desc": "开矿掘脉耗时再 -15%（需筑基期）。",
	},
	{
		"id": "gear_alchemy_furnace_2", "name": "离火八卦炉", "category": "gear", "cost": 1500,
		"effect_type": "double_chance", "effect_target": "alchemy", "effect_value": 0.12,
		"prerequisite": "gear_alchemy_furnace_1", "required_realm": 9,
		"desc": "丹道炼制双倍产出率再 +12%。",
	},
	{
		"id": "gear_talisman_brush_1", "name": "紫毫灵笔", "category": "gear", "cost": 850,
		"effect_type": "interval", "effect_target": "talisman", "effect_value": -0.15,
		"required_realm": 9,
		"desc": "符箓绘制耗时 -15%。",
	},
	{
		"id": "gear_auto_pill_array", "name": "聚灵自转阵盘", "category": "gear", "cost": 1350,
		"effect_type": "interval", "effect_target": "cultivation", "effect_value": -0.15,
		"required_realm": 9,
		"desc": "吐纳筑基耗时 -15%。",
	},
	{
		"id": "seed_ziyun", "name": "紫云芝灵种", "category": "seed", "cost": 120, "max_level": 0,
		"effect_type": "grant_item", "effect_target": "seed_ziyun",
		"desc": "120 灵石 / 粒，三十五分钟可收。",
	},
	{
		"id": "seed_chiyan", "name": "赤焰草灵种", "category": "seed", "cost": 220, "max_level": 0,
		"effect_type": "grant_item", "effect_target": "seed_chiyan",
		"desc": "220 灵石 / 粒，五十分钟可收。",
	},
	{
		"id": "seed_biyu", "name": "碧玉灵参种", "category": "seed", "cost": 320, "max_level": 0,
		"effect_type": "grant_item", "effect_target": "seed_biyu",
		"desc": "320 灵石 / 粒，六十分钟可收。",
	},
	# ---- 金丹期上架（三阶法器）
	{
		"id": "tool_herb_hoe_3", "name": "星辰灵锄", "category": "gear", "cost": 2600,
		"effect_type": "interval", "effect_target": "herbalism", "effect_value": -0.15,
		"prerequisite": "tool_herb_hoe_2", "required_realm": 12,
		"desc": "采药寻灵耗时再 -15%（需金丹期）。",
	},
	{
		"id": "tool_wood_axe_3", "name": "玄冰神斧", "category": "gear", "cost": 2600,
		"effect_type": "interval", "effect_target": "woodcutting", "effect_value": -0.15,
		"prerequisite": "tool_wood_axe_2", "required_realm": 12,
		"desc": "伐木取材耗时再 -15%（需金丹期）。",
	},
	{
		"id": "tool_mine_pick_3", "name": "太初破岳镐", "category": "gear", "cost": 3000,
		"effect_type": "interval", "effect_target": "mining", "effect_value": -0.15,
		"prerequisite": "tool_mine_pick_2", "required_realm": 12,
		"desc": "开矿掘脉耗时再 -15%（需金丹期）。",
	},
	{
		"id": "gear_alchemy_furnace_3", "name": "九霄乾坤鼎", "category": "gear", "cost": 4000,
		"effect_type": "double_chance", "effect_target": "alchemy", "effect_value": 0.15,
		"prerequisite": "gear_alchemy_furnace_2", "required_realm": 12,
		"desc": "丹道炼制双倍产出率再 +15%。",
	},
	{
		"id": "gear_combat_bell_2", "name": "紫金镇魂铃", "category": "gear", "cost": 3600,
		"effect_type": "heal_pct", "effect_target": "all", "effect_value": 0.25,
		"prerequisite": "gear_combat_bell_1", "required_realm": 12,
		"desc": "战斗与渡劫中回血丹回复效果再 +25%。",
	},
	{
		"id": "seed_hansui", "name": "寒髓草灵种", "category": "seed", "cost": 480, "max_level": 0,
		"effect_type": "grant_item", "effect_target": "seed_hansui",
		"desc": "480 灵石 / 粒，一小时可收。",
	},
	{
		"id": "seed_xinghui", "name": "星辉灵芝种", "category": "seed", "cost": 850, "max_level": 0,
		"effect_type": "grant_item", "effect_target": "seed_xinghui",
		"desc": "850 灵石 / 粒，八十分钟可收。",
	},
	# ---- 元婴期上架（终极法器）
	{
		"id": "gear_taixu_furnace", "name": "太虚混沌炉", "category": "gear", "cost": 9000,
		"effect_type": "double_chance", "effect_target": "alchemy", "effect_value": 0.15,
		"extra_effects": {"all_craft_interval": -0.10},
		"prerequisite": "gear_alchemy_furnace_3", "required_realm": 15,
		"desc": "丹道炼制双倍产出率再 +15%，全制造耗时 -10%。",
	},
	{
		"id": "gear_taixu_bell", "name": "混元镇道钟", "category": "gear", "cost": 8200,
		"effect_type": "max_hp_pct", "effect_target": "all", "effect_value": 0.15,
		"prerequisite": "gear_combat_bell_2", "required_realm": 15,
		"desc": "最大气血 +15%，回血丹回复效果再 +25%。",
	},
	{
		"id": "seed_jiuye", "name": "九叶仙芝种", "category": "seed", "cost": 1800, "max_level": 0,
		"effect_type": "grant_item", "effect_target": "seed_jiuye",
		"desc": "1800 灵石 / 粒，九十分钟可收。",
	},
	{
		"id": "seed_longxue", "name": "龙血草灵种", "category": "seed", "cost": 3600, "max_level": 0,
		"effect_type": "grant_item", "effect_target": "seed_longxue", "required_realm": 18,
		"desc": "3600 灵石 / 粒，一百分钟可收。",
	},
	{
		"id": "seed_taiyi", "name": "太乙青莲种", "category": "seed", "cost": 7200, "max_level": 0,
		"effect_type": "grant_item", "effect_target": "seed_taiyi", "required_realm": 21,
		"desc": "7200 灵石 / 粒，一百一十分钟可收。",
	},
	{
		"id": "seed_hundun", "name": "混沌道花种", "category": "seed", "cost": 14000, "max_level": 0,
		"effect_type": "grant_item", "effect_target": "seed_hundun", "required_realm": 24,
		"desc": "14000 灵石 / 粒，一百二十分钟可收。",
	},
	{
		"id": "seed_hongmeng", "name": "鸿蒙不死药种", "category": "seed", "cost": 28000, "max_level": 0,
		"effect_type": "grant_item", "effect_target": "seed_hongmeng", "required_realm": 27,
		"desc": "28000 灵石 / 粒，一百四十分钟可收。",
	},
]

## ---- 藏经阁功法表（9 部，三流派） ----
const TECHNIQUE_DEFS: Array = [
	# 种田丹修流
	{
		"id": "tech_changchun", "name": "长春木元功", "school": "wood", "points": 60,
		"icon": "tech_changchun",
		"desc": "木元滋养，采药双倍与灵田生长皆受益。",
		"effects": {"herb_double": 0.12, "farm_speed": 0.15},
	},
	{
		"id": "tech_danfire", "name": "离火炼丹诀", "school": "wood", "points": 140,
		"icon": "tech_lihuo",
		"desc": "离火催丹，双倍更易触发且时有原料不耗。",
		"effects": {"alchemy_double": 0.10, "alchemy_free": 0.08},
	},
	{
		"id": "tech_baicao", "name": "百草灵韵经", "school": "wood", "points": 240,
		"icon": "tech_baicao",
		"desc": "通晓百草，采集更快、副产灵种更多。",
		"effects": {"gather_interval": -0.10, "seed_bonus": 0.06},
		"drop_enemy": "enemy_wolf_king", "drop_chance": 0.08,
	},
	# 剑修爆发流
	{
		"id": "tech_gengjin", "name": "庚金剑诀", "school": "sword", "points": 60,
		"icon": "tech_gengjin",
		"desc": "庚金锐意，攻击与会心齐升。",
		"effects": {"attack_pct": 0.12, "crit_chance": 0.10},
	},
	{
		"id": "tech_xunlei", "name": "九霄迅雷步", "school": "sword", "points": 160,
		"icon": "tech_jiuxiao",
		"desc": "身如迅雷，攻势更快、雷符更烈，出手亦更有力。",
		"effects": {"attack_interval": -0.10, "thunder_dmg": 0.35, "attack_pct": 0.04},
	},
	{
		"id": "tech_zhanxing", "name": "太初斩星剑意", "school": "sword", "points": 320,
		"icon": "tech_taichu",
		"desc": "每三击引剑气，附带攻击力四成真伤。",
		"effects": {"attack_pct": 0.15, "sword_qi": 0.40},
		"drop_enemy": "enemy_ruin_guardian", "drop_chance": 0.08,
	},
	# 苟命渡劫流
	{
		"id": "tech_xuangui", "name": "玄龟镇脉功", "school": "shield", "points": 60,
		"icon": "tech_xuangui",
		"desc": "玄龟镇脉，气血与防御同涨。",
		"effects": {"max_hp": 0.18, "defense": 0.15},
	},
	{
		"id": "tech_dujie", "name": "太虚避劫经", "school": "shield", "points": 180,
		"icon": "tech_taixu_bijie",
		"desc": "太虚避劫，天雷威势得缓，妖兽与天劫之伤亦能化解。",
		"effects": {"trib_reduce": 0.12, "damage_reduce": 0.04},
	},
	{
		"id": "tech_tunna", "name": "周天吐纳真解", "school": "shield", "points": 400,
		"icon": "tech_zhoutian_tuna",
		"desc": "周天吐纳，修为与回血效果双增。",
		"effects": {"meditate_xp": 0.22, "heal_pct": 0.15},
		"drop_enemy": "enemy_star_dragon", "drop_chance": 0.10,
	},
	# ================= 九幽冥渊（化神期功法） =================
	{
		"id": "tech_youming", "name": "幽冥噬魂诀", "school": "sword", "points": 600,
		"icon": "tech_youming",
		"desc": "幽冥之气噬魂夺魄，攻击与会心齐升。",
		"effects": {"attack_pct": 0.18, "crit_chance": 0.12},
		"drop_enemy": "enemy_jiuyou_king", "drop_chance": 0.10,
	},
	{
		"id": "tech_jiuyou_body", "name": "九幽不灭体", "school": "shield", "points": 600,
		"icon": "tech_jiuyou_bumie",
		"desc": "九幽淬体，气血与防御同固。",
		"effects": {"max_hp": 0.22, "defense": 0.18},
		"drop_enemy": "enemy_youming_ghost", "drop_chance": 0.06,
	},
	{
		"id": "tech_longxue", "name": "龙血淬体诀", "school": "wood", "points": 600,
		"icon": "tech_longxue",
		"desc": "龙血淬体，回血更盛，灵田生长更快。",
		"effects": {"heal_pct": 0.25, "farm_speed": 0.20},
		"drop_enemy": "enemy_blood_crow", "drop_chance": 0.06,
	},
	# ================= 无尽星海（炼虚期功法） =================
	{
		"id": "tech_xinghe", "name": "星河倒卷剑意", "school": "sword", "points": 900,
		"icon": "tech_xinghe_jian",
		"desc": "剑引星河倒卷，攻击大增且剑气更烈。",
		"effects": {"attack_pct": 0.22, "sword_qi": 0.50},
		"drop_enemy": "enemy_void_dragon", "drop_chance": 0.10,
	},
	{
		"id": "tech_xingchen", "name": "星辰炼神术", "school": "shield", "points": 900,
		"icon": "tech_xingchen_lianshen",
		"desc": "星辰炼神，天雷威势得缓，妖兽与天劫之伤皆可抵御。",
		"effects": {"trib_reduce": 0.15, "damage_reduce": 0.06},
		"drop_enemy": "enemy_nebula_spirit", "drop_chance": 0.06,
	},
	{
		"id": "tech_yinhe", "name": "银河灌溉法", "school": "wood", "points": 900,
		"icon": "tech_yinhe_guangai",
		"desc": "引银河之水灌溉百草，采药双倍与采集速度同升。",
		"effects": {"herb_double": 0.15, "gather_interval": -0.12},
		"drop_enemy": "enemy_star_whale", "drop_chance": 0.06,
	},
	# ================= 混沌古界（合体期功法） =================
	{
		"id": "tech_hundun", "name": "混沌开天诀", "school": "sword", "points": 1300,
		"icon": "tech_hundun_kaitian",
		"desc": "一斧开天，攻击大涨且出手更快。",
		"effects": {"attack_pct": 0.26, "attack_interval": -0.12},
		"drop_enemy": "enemy_chaos_lord", "drop_chance": 0.10,
	},
	{
		"id": "tech_hunyuan", "name": "混元一气功", "school": "shield", "points": 1300,
		"icon": "tech_hunyuan_yiqi",
		"desc": "混元一气，气血与回血效果同增。",
		"effects": {"max_hp": 0.28, "heal_pct": 0.20},
		"drop_enemy": "enemy_chaos_golem", "drop_chance": 0.06,
	},
	{
		"id": "tech_zaohua", "name": "造化炼丹经", "school": "wood", "points": 1300,
		"icon": "tech_zaohua_dan",
		"desc": "夺造化之工，丹道双倍与免料率同升。",
		"effects": {"alchemy_double": 0.14, "alchemy_free": 0.10},
		"drop_enemy": "enemy_void_devourer", "drop_chance": 0.06,
	},
	# ================= 三十三天外（大乘期功法） =================
	{
		"id": "tech_hongmeng", "name": "鸿蒙诛仙剑意", "school": "sword", "points": 1800,
		"icon": "tech_hongmeng_zhuxian",
		"desc": "鸿蒙剑意，攻击与会心再登一层。",
		"effects": {"attack_pct": 0.30, "crit_chance": 0.15},
		"drop_enemy": "enemy_heaven_emperor", "drop_chance": 0.10,
	},
	{
		"id": "tech_taixu_zhenjing", "name": "太虚证道真经", "school": "shield", "points": 1800,
		"icon": "tech_taixu_zhengdao",
		"desc": "证道太虚，天雷减伤与吐纳修为同增。",
		"effects": {"trib_reduce": 0.18, "meditate_xp": 0.25},
		"drop_enemy": "enemy_heaven_general", "drop_chance": 0.06,
	},
	{
		"id": "tech_zhoutian", "name": "周天星斗大阵", "school": "wood", "points": 1800,
		"icon": "tech_zhoutian_xingdou",
		"desc": "布周天大阵，采集更快、灵种副产更多。",
		"effects": {"gather_interval": -0.15, "seed_bonus": 0.10},
		"drop_enemy": "enemy_primordial_beast", "drop_chance": 0.06,
	},
]

var items: Dictionary = {}
var actions: Dictionary = {}
var enemies: Dictionary = {}
var realms: Dictionary = {}
var techniques: Dictionary = {}
var shop_upgrades: Dictionary = {}
var farm_seeds: Dictionary = {}
var realm_order: Array[String] = []
var skill_order: Array[String] = []
var skills: Dictionary = {}
var skill_action_ids: Dictionary = {}
var region_enemies: Dictionary = {}
var regions: Dictionary = {}
## item_id -> Array[Dictionary] 来源倒排缓存
var _item_sources: Dictionary = {}

var _ready_done: bool = false


func _ready() -> void:
	rebuild_registries()


## 幂等重建：PCK 热重载脚本后由 BootScene 调用；只清静态配置/索引，不触碰 GameState。
func rebuild_registries() -> void:
	_ready_done = false
	items.clear()
	actions.clear()
	enemies.clear()
	realms.clear()
	techniques.clear()
	shop_upgrades.clear()
	farm_seeds.clear()
	realm_order.clear()
	skill_order.clear()
	skills.clear()
	skill_action_ids.clear()
	region_enemies.clear()
	regions.clear()
	_item_sources.clear()
	_load_all()


func _load_all() -> void:
	if _ready_done:
		return
	_ready_done = true
	_register_skills()
	_register_realms()
	_register_items()
	_register_actions()
	_register_enemies()
	_register_farm_seeds()
	_register_shop_upgrades()
	_register_techniques()
	_build_item_source_index()


# ------------------------------------------------------------------ 注册

func _register_skills() -> void:
	for entry in SKILL_DEFS:
		var dict: Dictionary = entry
		var sid := String(dict.get("id", ""))
		skills[sid] = {
			"id": sid,
			"name": String(dict.get("name", sid)),
			"category": String(dict.get("category", "gather")),
			"color": Color(String(dict.get("color", "#e0a458"))),
			"desc": String(dict.get("desc", "")),
		}
		skill_order.append(sid)
		skill_action_ids[sid] = []


func _make_realm(id: String, name: String, tier: int, stage: int, cap: int, offline_hours: float,
		requirement: float, dual: bool, tribulation: bool, hp: int, atk: int, defense: int,
		interval_mult: float = 1.0) -> RealmData:
	var realm := RealmData.new()
	realm.id = id
	realm.display_name = name
	realm.tier = tier
	realm.stage = stage
	realm.skill_level_cap = cap
	realm.offline_cap_hours = offline_hours
	realm.cultivation_required = requirement
	# 三阶神识：筑基「神识御敌」战斗独立 / 金丹「分神双修」2 槽 / 化神「身外化身」3 槽
	realm.combat_independent = tier >= 1
	realm.max_action_slots = 1 if tier <= 0 else (2 if tier <= 3 else 3)
	# 旧字段保留为派生值，外部老调用不会报错
	realm.unlocks_dual_cultivation = dual or realm.max_action_slots >= 2
	realm.requires_tribulation = tribulation
	realm.max_hp = hp
	realm.attack = atk
	realm.defense = defense
	realm.action_interval_multiplier = interval_mult
	realm.tribulation_damages = TRIBULATION_DAMAGES.duplicate()
	# 每个境界自带吐纳修炼名，UI 侧只读不推断
	realm.meditation_name = get_cultivation_name_for_tier(tier)
	if tier == 0:
		realm.accent_color = Color("#e0a458")
	elif tier == 1:
		realm.accent_color = Color("#3eb489")
	elif tier == 2:
		realm.accent_color = Color("#8fb8ff")
	else:
		realm.accent_color = Color("#c79bff")
	return realm


func _register_realms() -> void:
	# ---- 炼气 1~9 层（技能上限 20，累计 180,000，九层触发筑基天劫） ----
	for i in range(9):
		var realm := _make_realm(
			"qi_%d" % (i + 1),
			"炼气%s" % String(QI_STAGE_NAMES[i]),
			0, i + 1, 20, 12.0,
			float(QI_REQUIREMENTS[i]),
			false,
			i == 8,
			100 + 15 * i, 8, 2
		)
		realms[realm.id] = realm
		realm_order.append(realm.id)

	# ---- 筑基 / 金丹 / 元婴 / 化神 / 炼虚 / 合体 / 大乘（各分初/中/后期，共 21 境） ----
	# cap = 技能等级上限，offline = 离线结算上限（小时），mult = 全局动作耗时乘数
	var stage_defs: Array = [
		{"tier": 1, "cap": 40, "offline": 12.0, "mult": 1.0, "rows": [
			{"id": "foundation_early", "name": "筑基初期", "req": 400000.0, "hp": 265, "atk": 13, "def": 5},
			{"id": "foundation_mid", "name": "筑基中期", "req": 800000.0, "hp": 310, "atk": 18, "def": 8},
			{"id": "foundation_late", "name": "筑基后期", "req": 1400000.0, "hp": 355, "atk": 23, "def": 11, "trib": true},
		]},
		{"tier": 2, "cap": 60, "offline": 24.0, "mult": 0.9, "rows": [
			{"id": "core_early", "name": "金丹初期", "req": 4000000.0, "hp": 400, "atk": 34, "def": 18},
			{"id": "core_mid", "name": "金丹中期", "req": 8000000.0, "hp": 520, "atk": 48, "def": 26},
			{"id": "core_late", "name": "金丹后期", "req": 14000000.0, "hp": 640, "atk": 62, "def": 34, "trib": true},
		]},
		{"tier": 3, "cap": 80, "offline": 24.0, "mult": 0.9, "rows": [
			{"id": "nascent_early", "name": "元婴初期", "req": 28000000.0, "hp": 760, "atk": 76, "def": 42},
			{"id": "nascent_mid", "name": "元婴中期", "req": 52000000.0, "hp": 1000, "atk": 102, "def": 58},
			{"id": "nascent_late", "name": "元婴后期", "req": 85000000.0, "hp": 1240, "atk": 128, "def": 74, "trib": true},
		]},
		{"tier": 4, "cap": 100, "offline": 24.0, "mult": 0.85, "rows": [
			{"id": "spirit_early", "name": "化神初期", "req": 150000000.0, "hp": 1500, "atk": 152, "def": 88},
			{"id": "spirit_mid", "name": "化神中期", "req": 260000000.0, "hp": 1800, "atk": 176, "def": 102},
			{"id": "spirit_late", "name": "化神后期", "req": 420000000.0, "hp": 2150, "atk": 200, "def": 116, "trib": true},
		]},
		{"tier": 5, "cap": 120, "offline": 24.0, "mult": 0.85, "rows": [
			{"id": "void_early", "name": "炼虚初期", "req": 720000000.0, "hp": 2500, "atk": 230, "def": 130},
			{"id": "void_mid", "name": "炼虚中期", "req": 1200000000.0, "hp": 2900, "atk": 260, "def": 145},
			{"id": "void_late", "name": "炼虚后期", "req": 1900000000.0, "hp": 3350, "atk": 295, "def": 160, "trib": true},
		]},
		{"tier": 6, "cap": 135, "offline": 24.0, "mult": 0.8, "rows": [
			{"id": "unity_early", "name": "合体初期", "req": 3200000000.0, "hp": 3800, "atk": 330, "def": 175},
			{"id": "unity_mid", "name": "合体中期", "req": 5200000000.0, "hp": 4300, "atk": 370, "def": 190},
			{"id": "unity_late", "name": "合体后期", "req": 8000000000.0, "hp": 4850, "atk": 410, "def": 205, "trib": true},
		]},
		{"tier": 7, "cap": 150, "offline": 24.0, "mult": 0.8, "rows": [
			{"id": "great_early", "name": "大乘初期", "req": 13000000000.0, "hp": 5450, "atk": 455, "def": 220},
			{"id": "great_mid", "name": "大乘中期", "req": 21000000000.0, "hp": 6100, "atk": 505, "def": 235},
			{"id": "great_late", "name": "大乘后期", "req": 32000000000.0, "hp": 6800, "atk": 560, "def": 250, "trib": true},
		]},
	]
	for stage in stage_defs:
		var dict: Dictionary = stage
		var rows: Array = dict["rows"]
		for i in range(rows.size()):
			var row: Dictionary = rows[i]
			var realm := _make_realm(
				String(row["id"]), String(row["name"]),
				int(dict["tier"]), i + 1, int(dict["cap"]), float(dict["offline"]),
				float(row["req"]), true, bool(row.get("trib", false)),
				int(row["hp"]), int(row["atk"]), int(row["def"]),
				float(dict["mult"])
			)
			realms[realm.id] = realm
			realm_order.append(realm.id)

	# ---- 真仙圆满 · 飞升仙界（终点，终局光环 +20% 产出与技能经验） ----
	var magnificent := _make_realm(
		"magnificent", "真仙圆满 · 飞升仙界", 8, 1, 150, 24.0, 0.0, true, false,
		8000, 620, 270, 0.8)
	realms[magnificent.id] = magnificent
	realm_order.append(magnificent.id)

	# ---- 八重天劫：门票 / 时长 / 天雷 / 目标境界 ----
	var qi_tribulation: RealmData = realms["qi_9"]
	qi_tribulation.tribulation_name = "筑基天劫"
	qi_tribulation.tribulation_item = FOUNDATION_PILL
	qi_tribulation.tribulation_duration = 20.0
	qi_tribulation.tribulation_target = "foundation_early"
	qi_tribulation.tribulation_damages = [35, 50, 65, 85, 110]

	var core_tribulation: RealmData = realms["foundation_late"]
	core_tribulation.tribulation_name = "结丹天劫"
	core_tribulation.tribulation_item = "item_jindan_pill"
	core_tribulation.tribulation_duration = 24.0
	core_tribulation.tribulation_target = "core_early"
	core_tribulation.tribulation_damages = [120, 155, 195, 240, 290, 350]

	# ---- 碎婴天劫：金丹后期 → 元婴初期（7 雷 / 28 秒 / 化婴丹） ----
	var nascent_tribulation: RealmData = realms["core_late"]
	nascent_tribulation.tribulation_name = "碎婴天劫"
	nascent_tribulation.tribulation_item = "item_nascent_pill"
	nascent_tribulation.tribulation_duration = 28.0
	nascent_tribulation.tribulation_target = "nascent_early"
	nascent_tribulation.tribulation_damages = [380, 460, 560, 680, 820, 980, 1180]

	# ---- 化神天劫：元婴后期 → 化神初期（7 雷 / 30 秒 / 化神丹） ----
	var huashen_tribulation: RealmData = realms["nascent_late"]
	huashen_tribulation.tribulation_name = "化神天劫"
	huashen_tribulation.tribulation_item = "item_trib_huashen"
	huashen_tribulation.tribulation_duration = 30.0
	huashen_tribulation.tribulation_target = "spirit_early"
	huashen_tribulation.tribulation_damages = [600, 750, 900, 1050, 1200, 1300, 1400]

	# ---- 炼虚天劫：化神后期 → 炼虚初期（8 雷 / 31 秒 / 炼虚丹） ----
	var lianxu_tribulation: RealmData = realms["spirit_late"]
	lianxu_tribulation.tribulation_name = "炼虚天劫"
	lianxu_tribulation.tribulation_item = "item_trib_lianxu"
	lianxu_tribulation.tribulation_duration = 31.0
	lianxu_tribulation.tribulation_target = "void_early"
	lianxu_tribulation.tribulation_damages = [1100, 1300, 1500, 1700, 1900, 2100, 2300, 2500]

	# ---- 合体天劫：炼虚后期 → 合体初期（8 雷 / 33 秒 / 合体丹） ----
	var heti_tribulation: RealmData = realms["void_late"]
	heti_tribulation.tribulation_name = "合体天劫"
	heti_tribulation.tribulation_item = "item_trib_heti"
	heti_tribulation.tribulation_duration = 33.0
	heti_tribulation.tribulation_target = "unity_early"
	heti_tribulation.tribulation_damages = [1900, 2200, 2500, 2800, 3100, 3400, 3700, 4000]

	# ---- 大乘天劫：合体后期 → 大乘初期（9 雷 / 34 秒 / 大乘丹） ----
	var dacheng_tribulation: RealmData = realms["unity_late"]
	dacheng_tribulation.tribulation_name = "大乘天劫"
	dacheng_tribulation.tribulation_item = "item_trib_dacheng"
	dacheng_tribulation.tribulation_duration = 34.0
	dacheng_tribulation.tribulation_target = "great_early"
	dacheng_tribulation.tribulation_damages = [2600, 2900, 3200, 3500, 3800, 4100, 4400, 4700, 5000]

	# ---- 飞升天劫：大乘后期 → 真仙圆满（9 雷 / 36 秒 / 渡劫飞升丹） ----
	var ascension_tribulation: RealmData = realms["great_late"]
	ascension_tribulation.tribulation_name = "飞升天劫"
	ascension_tribulation.tribulation_item = "item_ascension_pill"
	ascension_tribulation.tribulation_duration = 36.0
	ascension_tribulation.tribulation_target = "magnificent"
	ascension_tribulation.tribulation_damages = [3600, 4000, 4400, 4800, 5200, 5600, 6000, 6400, 6800]


func _register_items() -> void:
	for entry in ITEM_DEFS:
		var dict: Dictionary = entry
		var item := ItemData.new()
		item.id = String(dict.get("id", ""))
		item.display_name = String(dict.get("name", item.id))
		item.description = String(dict.get("desc", ""))
		item.category = int(dict.get("cat", CAT_MATERIAL))
		item.element = int(dict.get("element", E_NONE))
		item.sell_price = int(dict.get("sell", 1))
		item.equip_slot = String(dict.get("slot", ""))
		item.attack_bonus = int(dict.get("atk", 0))
		item.defense_bonus = int(dict.get("def", 0))
		item.max_hp_bonus = int(dict.get("hp", 0))
		item.accuracy_bonus = int(dict.get("acc", 0))
		item.crit_bonus = float(dict.get("crit", 0.0))
		item.dodge_bonus = float(dict.get("dodge", 0.0))
		item.heal_amount = int(dict.get("heal", 0))
		item.cultivation_gain = int(dict.get("cultivation", 0))
		item.ward_ratio = float(dict.get("ward", 0.0))
		item.stackable = item.category != CAT_EQUIPMENT
		items[item.id] = item


func _register_actions() -> void:
	for entry in ACTION_DEFS:
		var dict: Dictionary = entry
		var action := ActionData.new()
		action.id = String(dict.get("id", ""))
		action.display_name = String(dict.get("name", action.id))
		action.description = String(dict.get("desc", ""))
		action.skill_id = String(dict.get("skill", ""))
		action.action_type = int(dict.get("type", TYPE_GATHER))
		action.base_interval = float(dict.get("interval", 3.0))
		action.required_level = int(dict.get("level", 1))
		action.element = int(dict.get("element", E_NONE))
		action.inputs = (dict.get("inputs", {}) as Dictionary).duplicate()
		action.outputs = (dict.get("outputs", {}) as Dictionary).duplicate()
		action.byproducts = (dict.get("byproducts", {}) as Dictionary).duplicate()
		action.skill_xp = float(dict.get("xp", 10.0))
		action.mastery_xp = float(dict.get("mxp", 8.0))
		action.cultivation_gain = int(dict.get("cultivation", 0))
		action.pill_item_id = String(dict.get("pill", ""))
		action.pill_cultivation_gain = int(dict.get("pill_cultivation", 0))
		action.wood_fire_capable = bool(dict.get("wood_fire", false))
		action.quality_capable = bool(dict.get("quality", false))
		action.free_material_capable = bool(dict.get("free_material", false))
		actions[action.id] = action
		if skill_action_ids.has(action.skill_id):
			var list: Array = skill_action_ids[action.skill_id]
			list.append(action.id)
			skill_action_ids[action.skill_id] = list


func _register_enemies() -> void:
	for entry in ENEMY_DEFS:
		var dict: Dictionary = entry
		var enemy := EnemyData.new()
		enemy.id = String(dict.get("id", ""))
		enemy.display_name = String(dict.get("name", enemy.id))
		enemy.description = String(dict.get("desc", ""))
		enemy.region_id = String(dict.get("region", ""))
		enemy.max_hp = int(dict.get("hp", 100))
		enemy.attack = int(dict.get("atk", 10))
		enemy.attack_interval = float(dict.get("interval", 2.6))
		enemy.defense = int(dict.get("def", 0))
		enemy.dodge = float(dict.get("dodge", 0.0))
		enemy.is_boss = bool(dict.get("boss", false))
		enemy.xp_reward = float(dict.get("xp", 25.0))
		var loot: Array = dict.get("loot", [])
		enemy.loot_table = loot.duplicate(true)
		enemies[enemy.id] = enemy
		if not region_enemies.has(enemy.region_id):
			region_enemies[enemy.region_id] = []
		var list: Array = region_enemies[enemy.region_id]
		list.append(enemy.id)
		region_enemies[enemy.region_id] = list

	for entry in REGION_DEFS:
		var dict: Dictionary = entry
		var rid := String(dict.get("id", ""))
		regions[rid] = {
			"id": rid,
			"name": String(dict.get("name", rid)),
			"tag": String(dict.get("tag", "")),
			"required_tier": int(dict.get("required_tier", 0)),
			"desc": String(dict.get("desc", "")),
			"enemies": (dict.get("enemies", []) as Array).duplicate(),
		}


func _register_farm_seeds() -> void:
	for entry in SEED_DEFS:
		var dict: Dictionary = entry
		var seed_id := String(dict.get("id", ""))
		farm_seeds[seed_id] = {
			"id": seed_id,
			"name": String(dict.get("name", seed_id)),
			"crop_id": String(dict.get("crop", "")),
			"grow_seconds": float(dict.get("grow", 600)),
			"min_yield": int(dict.get("min", 1)),
			"max_yield": int(dict.get("max", 1)),
			"desc": String(dict.get("desc", "")),
		}


func _register_techniques() -> void:
	for entry in TECHNIQUE_DEFS:
		var dict: Dictionary = entry
		var tech := TechniqueData.new()
		tech.id = String(dict.get("id", ""))
		tech.name = String(dict.get("name", tech.id))
		tech.school = String(dict.get("school", "wood"))
		tech.description = String(dict.get("desc", ""))
		tech.unlock_cost_points = int(dict.get("points", 60))
		tech.icon_key = String(dict.get("icon", "tech_wood"))
		tech.effects = (dict.get("effects", {}) as Dictionary).duplicate()
		var drop_enemy := String(dict.get("drop_enemy", ""))
		tech.drop_enemy_id = drop_enemy
		tech.drop_chance = float(dict.get("drop_chance", 0.0))
		tech.unlock_type = TechniqueData.UnlockType.DROP if drop_enemy != "" \
			else TechniqueData.UnlockType.POINTS
		techniques[tech.id] = tech


# ---------------------------------------------------------------- 吐纳功课专属图标

## 8 门吐纳动作 → 独立精绘模板键（炼气→大乘进阶；空值回退技能通用图标）
const ACTION_ICON_KEYS := {
	"meditate_basic": "act_meditate_qi",
	"meditate_foundation": "act_meditate_foundation",
	"meditate_gold_core": "act_meditate_core",
	"meditate_nascent": "act_meditate_nascent",
	"meditate_spirit": "act_meditate_spirit",
	"meditate_void": "act_meditate_void",
	"meditate_unity": "act_meditate_unity",
	"meditate_great": "act_meditate_mahayana",
}


func get_action_icon_key(action_id: String) -> String:
	return String(ACTION_ICON_KEYS.get(action_id, ""))


func _register_shop_upgrades() -> void:
	for entry in SHOP_DEFS:
		var dict: Dictionary = entry
		var upgrade := ShopUpgradeData.new()
		upgrade.id = String(dict.get("id", ""))
		upgrade.name = String(dict.get("name", upgrade.id))
		upgrade.description = String(dict.get("desc", ""))
		upgrade.category = String(dict.get("category", "gear"))
		upgrade.cost_stones = int(dict.get("cost", 0))
		upgrade.required_realm_index = int(dict.get("required_realm", 0))
		upgrade.prerequisite_id = String(dict.get("prerequisite", ""))
		upgrade.effect_type = String(dict.get("effect_type", ""))
		upgrade.effect_target = String(dict.get("effect_target", ""))
		upgrade.effect_value = float(dict.get("effect_value", 0.0))
		upgrade.max_level = int(dict.get("max_level", 1))
		# 复合效果（如「太虚混沌炉」= 丹道双倍 + 全制造减耗）：主效果走 effect_*，附加效果走 extra_effects
		var extras: Variant = dict.get("extra_effects", {})
		upgrade.extra_effects = extras if typeof(extras) == TYPE_DICTIONARY else {}
		shop_upgrades[upgrade.id] = upgrade


# ------------------------------------------------------------------ 来源反查

func _shop_tab_label(tab: String) -> String:
	match tab:
		"gear":
			return "法器宝具"
		"farm":
			return "洞府扩建"
		"seed":
			return "灵种杂货"
	return tab


func _add_item_source(item_id: String, source: Dictionary) -> void:
	if item_id == "" or not items.has(item_id):
		return
	var list: Array = _item_sources.get(item_id, [])
	for entry in list:
		var dict: Dictionary = entry
		if String(dict.get("type", "")) == String(source.get("type", "")) \
				and String(dict.get("label", "")) == String(source.get("label", "")):
			return
	list.append(source)
	_item_sources[item_id] = list


## 全自动倒排：扫描动作产出/副产、怪物掉落、灵田种子与坊市商品
func _build_item_source_index() -> void:
	_item_sources.clear()

	# 1) 百艺采集 / 制作
	for action in actions.values():
		var skill_name := get_skill_name(action.skill_id)
		for item_id in action.outputs.keys():
			_add_item_source(String(item_id), {
				"type": "skill", "skill_id": action.skill_id, "action_id": action.id,
				"label": "%s · %s" % [skill_name, action.display_name],
			})
		for item_id in action.byproducts.keys():
			_add_item_source(String(item_id), {
				"type": "skill", "skill_id": action.skill_id, "action_id": action.id,
				"label": "%s · %s（副产）" % [skill_name, action.display_name],
			})
		var seed_drop: Dictionary = SEED_DROPS.get(action.id, {})
		if not seed_drop.is_empty():
			_add_item_source(String(seed_drop.get("seed_id", "")), {
				"type": "skill", "skill_id": action.skill_id, "action_id": action.id,
				"label": "%s · %s（副产）" % [skill_name, action.display_name],
			})

	# 2) 秘境怪物掉落
	for enemy in enemies.values():
		var region: Dictionary = regions.get(enemy.region_id, {})
		var region_name := String(region.get("name", enemy.region_id))
		for entry in enemy.loot_table:
			if typeof(entry) != TYPE_DICTIONARY:
				continue
			var loot: Dictionary = entry
			_add_item_source(String(loot.get("item_id", "")), {
				"type": "combat", "zone_id": enemy.region_id, "enemy_id": enemy.id,
				"label": "秘境历练 · %s（%s）" % [region_name, enemy.display_name],
			})

	# 3) 洞府灵田：主作物 + 灵种伴生奇珍
	for seed_id in farm_seeds.keys():
		var seed: Dictionary = farm_seeds[seed_id]
		var seed_name := String(seed.get("name", seed_id))
		_add_item_source(String(seed.get("crop_id", "")), {
			"type": "farm", "seed_id": String(seed_id),
			"label": "洞府灵田 · 种植%s" % seed_name,
		})
		for companion in FARM_COMPANION_ITEMS:
			_add_item_source(String(companion), {
				"type": "farm", "seed_id": String(seed_id),
				"label": "洞府灵田 · 种植%s（伴生）" % seed_name,
			})

	# 4) 灵潭清茗 · 垂钓
	for item_id in ["item_spirit_dew", "item_spirit_fish"]:
		_add_item_source(item_id, {
			"type": "fishing_tea", "page_id": "fishing_tea",
			"label": "灵潭清茗 · 垂钓",
		})

	# 5) 仙坊阁购买
	for upgrade in shop_upgrades.values():
		if upgrade.effect_type != "grant_item" or upgrade.effect_target == "":
			continue
		_add_item_source(upgrade.effect_target, {
			"type": "shop", "tab": upgrade.category, "item_id": upgrade.id,
			"label": "仙坊阁 · %s" % _shop_tab_label(upgrade.category),
		})


# ------------------------------------------------------------------ 查询

func get_item(item_id: String) -> ItemData:
	return items.get(item_id, null) as ItemData


func get_action(action_id: String) -> ActionData:
	return actions.get(action_id, null) as ActionData


## 物品来源反查：按 技能 → 战斗 → 灵田 → 坊市 的优先级返回
func get_item_sources(item_id: String) -> Array[Dictionary]:
	if not _ready_done:
		_load_all()
	var out: Array[Dictionary] = []
	var cached: Array = _item_sources.get(item_id, [])
	for entry in cached:
		out.append((entry as Dictionary).duplicate(true))
	return out


## 镇魔塔：按层数动态生成妖魔（每 5 层妖王，属性指数平滑缩放）。
## 守将图标按层数确定性哈希从全秘境妖兽图标池轮换（普通层普通池 / 妖王层头目池），
## 同层稳定不闪烁、相邻层连续变化，杜绝全塔一张默认鬼脸。
var _tower_icon_pool: Array = []
var _tower_boss_icon_pool: Array = []


func _build_tower_icon_pools() -> void:
	if not _tower_icon_pool.is_empty():
		return
	for enemy_key in enemies.keys():
		var ed = enemies[enemy_key]
		if ed == null:
			continue
		var key := String(enemy_key)
		if (ed as EnemyData).is_boss:
			_tower_boss_icon_pool.append(key)
		else:
			_tower_icon_pool.append(key)
	# 排序保证跨会话哈希取模结果确定一致
	_tower_icon_pool.sort()
	_tower_boss_icon_pool.sort()


func get_tower_enemy(floor_num: int) -> EnemyData:
	if floor_num < 1:
		return null
	var enemy := EnemyData.new()
	var is_king := floor_num % 5 == 0
	enemy.id = "tower_%d" % floor_num
	enemy.region_id = "tower"
	enemy.is_boss = is_king
	enemy.max_hp = roundi(220.0 * pow(1.085, float(floor_num - 1)))
	enemy.attack = roundi(16.0 * pow(1.088, float(floor_num - 1)))
	enemy.defense = roundi(5.0 * pow(1.075, float(floor_num - 1)))
	enemy.attack_interval = 2.5
	enemy.xp_reward = 40.0 * float(floor_num)
	# 图标池确定性分配：普通层 pool[(f*7+3)%N]，妖王层 boss_pool[(f/5*3)%N]
	_build_tower_icon_pools()
	if is_king:
		if not _tower_boss_icon_pool.is_empty():
			enemy.icon_id = String(_tower_boss_icon_pool[
				(int(floor_num / 5) * 3) % _tower_boss_icon_pool.size()])
	else:
		if not _tower_icon_pool.is_empty():
			enemy.icon_id = String(_tower_icon_pool[
				(floor_num * 7 + 3) % _tower_icon_pool.size()])
	if is_king:
		enemy.max_hp = int(roundf(float(enemy.max_hp) * 1.5))
		enemy.attack = int(roundf(float(enemy.attack) * 1.2))
		enemy.defense = int(roundf(float(enemy.defense) * 1.15))
		enemy.display_name = "镇塔妖王"
		enemy.description = "每五层一现的镇塔妖王。"
	else:
		enemy.display_name = "镇塔妖将"
		enemy.description = "镇魔塔中的寻常妖将。"
	return enemy


func get_enemy_name(enemy_id: String) -> String:
	var enemy := get_enemy(enemy_id)
	return enemy_id if enemy == null else enemy.display_name


func get_enemy(enemy_id: String) -> EnemyData:
	if not _ready_done:
		_load_all()
	return enemies.get(enemy_id, null) as EnemyData


func get_realm(realm_id: String) -> RealmData:
	return realms.get(realm_id, null) as RealmData


## tier -> 吐纳修炼名（0 炼气 / 1 筑基 / 2 金丹 / 3 元婴 / 4 大乘），未登记回退「吐纳修行」
func get_cultivation_name_for_tier(tier: int) -> String:
	return String(CULTIVATION_NAMES.get(tier, CULTIVATION_NAME_DEFAULT))


## 是否为渡劫门票（筑基丹 / 结金丹 / 化婴丹 / 渡劫飞升丹）：
## 这类丹药不能直接吞服，必须在「引动天劫」面板投入
func is_tribulation_ticket(item_id: String) -> bool:
	if item_id == "":
		return false
	for realm_value in realms.values():
		var realm := realm_value as RealmData
		if realm != null and realm.tribulation_item == item_id:
			return true
	return false


func get_item_name(item_id: String) -> String:
	var item := get_item(item_id)
	if item == null:
		return item_id
	return item.display_name


func get_action_name(action_id: String) -> String:
	var action := get_action(action_id)
	if action == null:
		return action_id
	return action.display_name


func get_skill_name(skill_id: String) -> String:
	var meta: Dictionary = skills.get(skill_id, {})
	return String(meta.get("name", skill_id))


func get_skill_category(skill_id: String) -> String:
	var meta: Dictionary = skills.get(skill_id, {})
	return String(meta.get("category", "gather"))


func get_skill_color(skill_id: String) -> Color:
	var meta: Dictionary = skills.get(skill_id, {})
	return meta.get("color", Color("#3eb489"))


func get_skill_meta(skill_id: String) -> Dictionary:
	return skills.get(skill_id, {})


func get_actions_for_skill(skill_id: String) -> Array[ActionData]:
	var out: Array[ActionData] = []
	for action_id in get_action_ids_for_skill(skill_id):
		var action := get_action(action_id)
		if action != null:
			out.append(action)
	# v4 追加的过渡动作（Lv32 碧玉灵参 / Lv48 玄冰护体符 等）是后插入的，
	# 必须按解锁等级稳定排序，否则百艺页动作乱序（Lv32 排在 Lv76 后面）。
	out.sort_custom(func(a: ActionData, b: ActionData) -> bool:
		return a.required_level < b.required_level)
	return out


## 全量草药列表：从采药动作主产出动态提取（覆盖炼气青叶草 → 大乘鸿蒙不死药），
## 自动排除灵种 / 灵田奇珍，按采药解锁等级从低到高排序（施肥「优先烧旧草」用）。
func get_all_herb_ids() -> Array[String]:
	var entries: Array = []
	for action_id in get_action_ids_for_skill("herbalism"):
		var action := get_action(action_id)
		if action == null or action.outputs.is_empty():
			continue
		var item_id := String(action.outputs.keys()[0])
		if item_id.begins_with("seed_") or item_id == SPIRIT_DEW or item_id == CRIMSON_FRUIT:
			continue
		entries.append({"id": item_id, "level": action.required_level})
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["level"]) < int(b["level"]))
	var out: Array[String] = []
	for entry in entries:
		out.append(String(entry["id"]))
	return out


## 某草药对应采药动作的解锁等级（找不到时返回极大值，肥力折算按最高档兜底）
func get_herb_unlock_level(herb_id: String) -> int:
	for action_id in get_action_ids_for_skill("herbalism"):
		var action := get_action(action_id)
		if action != null and action.outputs.has(herb_id):
			return action.required_level
	return 9999


# ---------------------------------------------------------------- 低阶材料一键化灵

## 材料来源阶位与品类：
##   wood_ore  = 伐木 / 采矿产出（unlock_level 取两系中较低者）
##   herb_other = 采药产出与妖兽基础材料（妖兽取掉落秘境 tier 对齐的首境界技能上限）
## 丹药 / 装备 / 符箓 / 功法 / 灵种 / 天劫门票 / 奇珍 / 灵石一律排除（非 CAT_MATERIAL 或白名单外）。
func get_material_tier_info(item_id: String) -> Dictionary:
	var item := get_item(item_id)
	if item == null or item.category != ItemData.Category.MATERIAL:
		return {}
	if item_id == SPIRIT_STONE or item_id == SPIRIT_DEW or item_id == CRIMSON_FRUIT:
		return {}
	if String(item_id).begins_with("seed_"):
		return {}
	var best := {}
	for skill_id in ["woodcutting", "mining"]:
		for action_id in get_action_ids_for_skill(skill_id):
			var action := get_action(action_id)
			if action != null and action.outputs.has(item_id):
				var lv := action.required_level
				if best.is_empty() or lv < int(best["unlock_level"]):
					best = {"category": "wood_ore", "unlock_level": lv}
	if not best.is_empty():
		return best
	for action_id in get_action_ids_for_skill("herbalism"):
		var action := get_action(action_id)
		if action != null and action.outputs.has(item_id):
			var lv := action.required_level
			if best.is_empty() or lv < int(best["unlock_level"]):
				best = {"category": "herb_other", "unlock_level": lv}
	if not best.is_empty():
		return best
	# 妖兽基础材料：按掉落秘境的 required_tier 找该 tier 首个境界的技能上限
	var enemy_lv := get_enemy_drop_unlock_level(item_id)
	if enemy_lv < 9999:
		best = {"category": "herb_other", "unlock_level": enemy_lv}
	if not best.is_empty():
		return best
	return {}


## 材料五档品阶（凡材/灵材/玄材/仙材/神材）：单一查询入口。
## 来源解锁等级复用 get_material_tier_info（采集动作 + 妖兽掉落），
## 无明确来源时按售价保底推算；非 CAT_MATERIAL 返回空字典。
## 兼容别名：全品类统一走 get_item_grade
func get_material_grade(item_id: String) -> Dictionary:
	return get_item_grade(item_id)


## 万物品阶：覆盖材料/灵种/丹药/灵符/装备（货币除外），1~5 阶。
## unlock_level 优先级：① 灵种→收获草药 ② 全部百艺动作产出 ③ 妖兽掉落
## ④ 坊市门槛 ⑤ 售价保底推算。
func get_item_grade(item_id: String) -> Dictionary:
	var item := get_item(item_id)
	if item == null or item.category == ItemData.Category.CURRENCY:
		return {}
	if String(item_id) == SPIRIT_STONE:
		return {}
	# ① 灵种映射到对应收获草药的同款品阶
	if String(item_id).begins_with("seed_"):
		for seed_def in SEED_DEFS:
			if String((seed_def as Dictionary).get("id", "")) == String(item_id):
				var crop := String((seed_def as Dictionary).get("crop", ""))
				if crop != "" and crop != item_id:
					return get_item_grade(crop)
				break
	var lv := 9999
	# ② 全部百艺动作产出（采药/伐木/采矿/炼丹/锻造/制符/吐纳）最低解锁等级
	for skill_id in skill_order:
		for action_id in get_action_ids_for_skill(String(skill_id)):
			var action := get_action(action_id)
			if action != null and action.outputs.has(item_id):
				lv = mini(lv, action.required_level)
	# ③ 秘境/镇魔塔妖兽掉落
	if lv == 9999:
		lv = get_enemy_drop_unlock_level(item_id)
	# ④ 坊市商品门槛（required_realm_index → 境界技能上限）
	if lv == 9999:
		for key in shop_upgrades.keys():
			var up = shop_upgrades[key]
			if up == null:
				continue
			if String(up.effect_target) != String(item_id) and String(up.id) != String(item_id):
				continue
			var realm_idx := int(up.required_realm_index)
			if realm_idx > 0 and realm_idx < realm_order.size():
				var realm := get_realm(String(realm_order[realm_idx]))
				if realm != null:
					lv = mini(lv, realm.skill_level_cap)
	# ⑤ 售价保底推算（1 灵石 ≈ 0.25 级，封顶 150）
	if lv == 9999:
		if item.sell_price > 0:
			lv = mini(150, int(ceilf(float(item.sell_price) * 0.25)))
		else:
			return {}
	var grade := GameFormulas.get_material_grade_by_level(lv)
	grade["unlock_level"] = lv
	return grade


# ---------------------------------------------------------------- 妖兽/妖魔品阶

## 秘境 tier → 等效解锁等级（与规格的五档对位：
## 炼气凡 / 筑基灵 / 金丹·元婴玄 / 化神·炼虚仙 / 合体·大乘神）
const REGION_TIER_EQUIV_LEVELS: Array[int] = [10, 30, 60, 75, 100, 110, 135, 150]


## 秘境妖兽品阶：按所属秘境 required_tier 取等效解锁等级映射 1~5 阶。
## 镇魔塔动态妖魔（tower_<floor>）自动走楼层折算。
func get_enemy_grade(enemy_id: String) -> Dictionary:
	var enemy := get_enemy(enemy_id)
	if enemy == null:
		if String(enemy_id).begins_with("tower_"):
			var floor_num := int(String(enemy_id).trim_prefix("tower_"))
			if floor_num > 0:
				return get_tower_enemy_grade(floor_num)
		return {}
	var region: Dictionary = regions.get(enemy.region_id, {})
	var tier := clampi(int(region.get("required_tier", 0)), 0,
		REGION_TIER_EQUIV_LEVELS.size() - 1)
	var lv := REGION_TIER_EQUIV_LEVELS[tier]
	var grade := GameFormulas.get_material_grade_by_level(lv)
	grade["unlock_level"] = lv
	return grade


## 镇魔塔里程碑奖励统一数据源：CombatEngine 发奖与 TowerPanel 预告共用。
## 所有 item_id 均来自 ITEM_DEFS / 系统耗材表，禁止另写阶位名或虚构材料。
func get_tower_milestone_reward(floor_num: int) -> Dictionary:
	var safe_floor := maxi(1, floor_num)
	if safe_floor < 5 or safe_floor % 5 != 0:
		return {}
	var is_tenth := safe_floor % 10 == 0
	var band := 0
	if safe_floor >= 130:
		band = 3
	elif safe_floor >= 90:
		band = 2
	elif safe_floor >= 50:
		band = 1
	var endless_step := 0
	if band == 3:
		endless_step = clampi((safe_floor - 130) / 20, 0, 4)
	var items: Array = []
	var points := 0
	if is_tenth:
		match band:
			0:
				items = [
					{"id": "item_crimson_fruit", "amount": 1},
					{"id": "item_spirit_nectar", "amount": 2},
					{"id": "item_beast_core", "amount": 5},
				]
				points = 40 + safe_floor * 2
			1:
				items = [
					{"id": "item_taixu_gold", "amount": 4},
					{"id": "item_nascent_pill", "amount": 2},
					{"id": "item_yuanying_pill", "amount": 2},
					{"id": "item_spirit_nectar", "amount": 4},
				]
				points = 200 + safe_floor * 5
			2:
				items = [
					{"id": "item_hundun_flower", "amount": 3},
					{"id": "item_hundun_stone", "amount": 3},
					{"id": "item_trib_lianxu", "amount": 2},
					{"id": "item_huashen_note", "amount": 2},
				]
				points = 800 + safe_floor * 10
			_:
				items = [
					{"id": "item_hongmeng_herb", "amount": 2 + endless_step},
					{"id": "item_worldtree", "amount": 2 + endless_step},
					{"id": "item_hongmeng_gold", "amount": 2 + endless_step},
					{"id": "item_ascension_pill", "amount": 1 + mini(2, endless_step / 2)},
					{"id": "item_worldtree_ward", "amount": 1 + mini(2, endless_step / 2)},
				]
				points = 2000 + safe_floor * 20 + endless_step * 600
	else:
		match band:
			0:
				items = [
					{"id": "item_beast_core", "amount": 5},
					{"id": "item_ziyun", "amount": 5},
					{"id": "item_mithril", "amount": 5},
				]
				points = 20 + safe_floor * 2
			1:
				items = [
					{"id": "item_ancient_soul", "amount": 3},
					{"id": "item_star_core", "amount": 3},
					{"id": "item_nascent_pill", "amount": 2},
				]
				points = 120 + safe_floor * 5
			2:
				items = [
					{"id": "item_huashen_note", "amount": 2},
					{"id": "item_taiyi_lian", "amount": 2},
					{"id": "item_hundun_flower", "amount": 1},
					{"id": "item_trib_lianxu", "amount": 1},
				]
				points = 500 + safe_floor * 10
			_:
				items = [
					{"id": "item_demon_essence", "amount": 4 + endless_step},
					{"id": "item_thunder_essence", "amount": 3 + endless_step},
					{"id": "item_dragon_scale", "amount": 2 + endless_step},
					{"id": "item_hongmeng_gold", "amount": 1 + endless_step},
				]
				points = 1200 + safe_floor * 15 + endless_step * 400
	return {
		"floor": safe_floor,
		"band": band,
		"tenth": is_tenth,
		"items": items,
		"points": points,
	}


## 镇魔塔妖魔品阶：每 3 层约等 1 级（第 1 层凡阶 … 第 40 层起神阶）
func get_tower_enemy_grade(floor: int) -> Dictionary:
	var lv := clampi(int(floor) * 3, 1, 150)
	var grade := GameFormulas.get_material_grade_by_level(lv)
	grade["unlock_level"] = lv
	return grade


## 道藏功法品阶（21+ 门全覆盖）：以贡献兑换门槛推导档位
## （points 60→1800 与境界推进吻合：60→6 凡阶 … 1800→145 神阶）
func get_technique_grade(tech_id: String) -> Dictionary:
	var tech := get_technique(tech_id)
	if tech == null:
		return {}
	var lv := clampi(int(round(float(tech.unlock_cost_points) * 0.08)) + 1, 1, 150)
	var grade := GameFormulas.get_material_grade_by_level(lv)
	grade["unlock_level"] = lv
	return grade


## 化灵单价：优先物品定义的售价；没有售价的按来源解锁等级保底折算，
## 保证全部基础木材矿石都能化灵（不低于 1 灵石）。
func get_material_dissolve_value(item_id: String) -> int:
	var item := get_item(item_id)
	if item == null:
		return 0
	if item.sell_price > 0:
		return item.sell_price
	var info := get_material_tier_info(item_id)
	if info.is_empty():
		return 0
	return maxi(1, int(ceilf(int(info["unlock_level"]) * 0.25)))


# ---------------------------------------------------------------- 淘汰装备批量熔炼

## 妖兽掉落物品的来源阶位：掉落秘境 required_tier 对齐该 tier 首个境界的技能上限
func get_enemy_drop_unlock_level(item_id: String) -> int:
	var best := 9999
	for enemy_id in enemies.keys():
		var enemy := enemies[enemy_id] as EnemyData
		if enemy == null:
			continue
		for loot in enemy.loot_table:
			if String((loot as Dictionary).get("item_id", "")) != item_id:
				continue
			var region: Dictionary = regions.get(enemy.region_id, {})
			var tier := int(region.get("required_tier", 99))
			for realm_id in realm_order:
				var realm := get_realm(realm_id)
				if realm != null and realm.tier == tier:
					best = mini(best, realm.skill_level_cap)
					break
	return best


## 装备锻造配方（无锻造配方 = 纯妖兽掉落装备）
func get_equipment_recipe(item_id: String) -> ActionData:
	for action_id in get_action_ids_for_skill("forging"):
		var action := get_action(action_id)
		if action != null and action.outputs.has(item_id):
			return action
	return null


## 装备来源解锁等级：锻造配方等级，妖兽掉落取秘境阶位对齐值
func get_equipment_unlock_level(item_id: String) -> int:
	var recipe := get_equipment_recipe(item_id)
	if recipe != null:
		return recipe.required_level
	return get_enemy_drop_unlock_level(item_id)


## 熔炼收益（双模式）：
##   mode == "materials"：按锻造配方材料消耗的 45% × 品质倍率向下取整返还
##   （每项核心主材至少返还 1 个）；无配方（纯掉落装备）自动回退折算灵石。
##   mode == "stones"：优先 sell_price，其次配方材料成本 ×45%，再次 unlock_level × 4
##   保底估算，乘以品质倍率向上取整。
func get_equipment_smelt_yield(item_id: String, quality: int, mode: String) -> Dictionary:
	var mult := GameFormulas.smelt_quality_mult(quality)
	var stones := 0
	var materials := {}
	if mode == "materials":
		var recipe := get_equipment_recipe(item_id)
		if recipe != null:
			for key in recipe.inputs.keys():
				var need := int(recipe.inputs[key])
				if need <= 0:
					continue
				var back := maxi(1, int(floor(float(need) * 0.45 * mult)))
				materials[String(key)] = int(materials.get(String(key), 0)) + back
	# 材料模式但无配方（纯掉落装备）或灵石模式：折算灵石
	if materials.is_empty():
		stones = int(ceilf(_equipment_stone_base(item_id) * mult))
	return {"stones": stones, "materials": materials}


## 灵石折算基准：sell_price → 配方材料成本 ×45% → unlock_level × 4 保底。
## 注意不能写成 lambda：GDScript lambda 按值捕获，内部改局部变量不生效。
func _equipment_stone_base(item_id: String) -> float:
	var item := get_item(item_id)
	if item != null and item.sell_price > 0:
		return float(item.sell_price)
	var recipe := get_equipment_recipe(item_id)
	if recipe != null:
		var cost := 0
		for key in recipe.inputs.keys():
			var mat := get_item(String(key))
			if mat != null:
				cost += mat.sell_price * int(recipe.inputs[key])
		return float(cost) * 0.45
	return float(mini(get_equipment_unlock_level(item_id), 150)) * 4.0


func get_action_ids_for_skill(skill_id: String) -> Array[String]:
	var out: Array[String] = []
	var raw: Array = skill_action_ids.get(skill_id, [])
	for entry in raw:
		out.append(String(entry))
	return out


func get_skill_action_count(skill_id: String) -> int:
	var raw: Array = skill_action_ids.get(skill_id, [])
	return raw.size()


func get_enemies_for_region(region_id: String) -> Array[EnemyData]:
	var out: Array[EnemyData] = []
	var raw: Array = region_enemies.get(region_id, [])
	for entry in raw:
		var enemy := get_enemy(String(entry))
		if enemy != null:
			out.append(enemy)
	return out


func get_realm_index(realm_id: String) -> int:
	return realm_order.find(realm_id)


func get_next_realm(realm_id: String) -> RealmData:
	var index := get_realm_index(realm_id)
	if index < 0 or index + 1 >= realm_order.size():
		return null
	return get_realm(realm_order[index + 1])


func get_max_skill_cap() -> int:
	var cap := 1
	for realm_id in realm_order:
		var realm := get_realm(realm_id)
		if realm != null:
			cap = maxi(cap, realm.skill_level_cap)
	return cap


# ------------------------------------------------------------------ 藏经阁

func get_technique(technique_id: String) -> TechniqueData:
	return techniques.get(technique_id, null) as TechniqueData


func get_all_techniques() -> Array:
	var out: Array = []
	for key in techniques.keys():
		out.append(techniques[key])
	return out


func get_techniques_by_school(school: String) -> Array:
	var out: Array = []
	for key in techniques.keys():
		var tech := techniques[key] as TechniqueData
		if tech != null and (school == "all" or tech.school == school):
			out.append(tech)
	return out


# ------------------------------------------------------------------ 坊市 / 灵田

func get_shop_upgrade(upgrade_id: String) -> ShopUpgradeData:
	return shop_upgrades.get(upgrade_id, null) as ShopUpgradeData


func get_shop_upgrades_by_category(category: String) -> Array[ShopUpgradeData]:
	var out: Array[ShopUpgradeData] = []
	for key in shop_upgrades.keys():
		var upgrade := shop_upgrades[key] as ShopUpgradeData
		if upgrade != null and upgrade.category == category:
			out.append(upgrade)
	return out


func get_seed(seed_id: String) -> Dictionary:
	var data: Variant = farm_seeds.get(seed_id, null)
	if typeof(data) == TYPE_DICTIONARY:
		return data
	return {}


func get_all_seeds() -> Array:
	var out: Array = []
	for seed_id in farm_seeds.keys():
		out.append(farm_seeds[seed_id])
	return out


func get_seed_drop(action_id: String) -> Dictionary:
	var data: Variant = SEED_DROPS.get(action_id, null)
	if typeof(data) == TYPE_DICTIONARY:
		return data
	return {}



































































































