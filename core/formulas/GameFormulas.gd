class_name GameFormulas
extends RefCounted
## 纯静态公式库：经验曲线、火候减耗、五行加成、战斗与渡劫计算。
## 不持有任何状态，便于单元测试与离线复用。

const MAX_SKILL_LEVEL: int = 150
const MAX_MASTERY_LEVEL: int = 150
## 兵刃 / 法袍祭炼共同硬上限；旧档超出部分保留收益，但不再允许继续提升
const MAX_TEMPER_LEVEL: int = 50

# ---------------------------------------------------------------- 长线曲线集中调参
## 技能：单次获取倍率 / 曲线纵向放大 / 指数分母（越小后期越陡）
## v4（31 境 / 150 级）：等级上限 150，指数分母放宽到 9.2，Lv100~150 不再出现天文数字
const SKILL_EXP_GLOBAL_MULT: float = 0.42
const SKILL_CURVE_SCALE: float = 2.8
const SKILL_CURVE_DIVISOR: float = 9.2
## 火候：单项动作专精，成长再慢一档
const MASTERY_EXP_GLOBAL_MULT: float = 0.32
const MASTERY_CURVE_SCALE: float = 2.2
const MASTERY_CURVE_DIVISOR: float = 9.5
## 旧版技能曲线分母：只用于把旧存档还原成旧等级，新玩法路径不得调用
const LEGACY_SKILL_CURVE_DIVISOR: float = 7.0
## v3 曲线分母（6.2 / 6.5）：只供 exp_curve_version < 4 的旧档保级迁移
const V3_SKILL_CURVE_DIVISOR: float = 6.2
const V3_MASTERY_CURVE_DIVISOR: float = 6.5

## 火候每级缩短 0.20% 耗时（150 级约 30%）
const MASTERY_INTERVAL_PER_LEVEL: float = 0.0020
## 火候每 5 级 +1% 双倍/极品率，最高 20%
const MASTERY_DOUBLE_PER_5: float = 0.01
const MASTERY_DOUBLE_CAP: float = 0.20

## 悟道池（v3 加深）：容量不再随火候倍率联动，单动作固定 3000；
## 注入按实际火候经验的 0.55 倍累加（浮点累加，不再 1:1 灌满）。
## 例：7 动作技能总池 21,000，4 动作吐纳池 12,000。
const POOL_RATIO: float = 0.55
const POOL_CAPACITY_BASE: float = 3000.0
const POOL_CAPACITY_PER_ACTION: float = POOL_CAPACITY_BASE

const POOL_THRESHOLDS: Array = [
	{"ratio": 0.10, "label": "10%", "effect": "技能全局经验 +5%"},
	{"ratio": 0.25, "label": "25%", "effect": "技能全局耗时 -5%"},
	{"ratio": 0.50, "label": "50%", "effect": "制造 20% 免料 / 采集 +10% 双倍"},
	{"ratio": 0.95, "label": "95%", "effect": "全局产出会心率 +10%"},
]

## 五行相生：(源, 目标)
const ELEMENT_CYCLE: Array = [
	{"from": 1, "to": 2, "label": "木生火"},
	{"from": 2, "to": 3, "label": "火生土"},
	{"from": 3, "to": 4, "label": "土生金"},
	{"from": 4, "to": 5, "label": "金生水"},
	{"from": 5, "to": 1, "label": "水生木"},
]

static var _skill_xp_table: Dictionary = {}
static var _mastery_xp_table: Dictionary = {}
static var _legacy_skill_table: Dictionary = {}
static var _legacy_mastery_table: Dictionary = {}


# ---------------------------------------------------------------- 技能经验曲线

## 由 level 升往 level+1 所需的单级经验（长线指数曲线）
static func get_skill_exp_to_next(level: int) -> int:
	if level >= MAX_SKILL_LEVEL:
		return 0
	var lv: float = float(maxi(1, level))
	var base: float = 0.25 * (lv + 300.0 * pow(2.0, lv / SKILL_CURVE_DIVISOR))
	return maxi(100, int(floor(base * SKILL_CURVE_SCALE)))


## 兼容旧调用名：单级经验（浮点）
static func skill_step_xp(level: int) -> float:
	return float(get_skill_exp_to_next(level))


## 达到 level 级所需的累计经验（1 级为 0 起点）
static func xp_for_level(level: int) -> float:
	var l: int = clampi(level, 1, MAX_SKILL_LEVEL)
	if _skill_xp_table.has(l):
		return float(_skill_xp_table[l])
	var total: float = 0.0
	for i in range(1, l):
		total += float(get_skill_exp_to_next(i))
	_skill_xp_table[l] = total
	return total


## 与 xp_for_level 等价的语义别名，便于外部按“累计经验”理解
static func get_total_exp_for_level(level: int) -> float:
	return xp_for_level(level)


static func level_for_xp(xp: float, max_level: int = MAX_SKILL_LEVEL) -> int:
	var cap: int = clampi(max_level, 1, MAX_SKILL_LEVEL)
	var level: int = 1
	while level < cap and xp >= xp_for_level(level + 1):
		level += 1
	return level


# ---------------------------------------------------------------- 火候（单物品专精）

## 由 level 升往 level+1 所需的单级火候经验
static func get_mastery_exp_to_next(level: int) -> int:
	if level >= MAX_MASTERY_LEVEL:
		return 0
	var lv: float = float(maxi(1, level))
	var base: float = 0.25 * (lv + 300.0 * pow(2.0, lv / MASTERY_CURVE_DIVISOR))
	return maxi(80, int(floor(base * MASTERY_CURVE_SCALE)))


## 兼容旧调用名：单级火候经验（浮点）
static func mastery_step_xp(level: int) -> float:
	return float(get_mastery_exp_to_next(level))


static func mastery_xp_for_level(level: int) -> float:
	var l: int = clampi(level, 1, MAX_MASTERY_LEVEL)
	if _mastery_xp_table.has(l):
		return float(_mastery_xp_table[l])
	var total: float = 0.0
	for i in range(1, l):
		total += float(get_mastery_exp_to_next(i))
	_mastery_xp_table[l] = total
	return total


static func mastery_level_for_xp(xp: float) -> int:
	var level: int = 1
	while level < MAX_MASTERY_LEVEL and xp >= mastery_xp_for_level(level + 1):
		level += 1
	return level


# ---------------------------------------------------------------- 旧版曲线（仅存档保级迁移）

## 以下函数逐字保留改版前公式，只用于把旧存档累计经验还原成旧等级。
## 新玩法路径（升级、入账、UI）禁止调用。
static func _ensure_legacy_skill_table() -> void:
	if not _legacy_skill_table.is_empty():
		return
	var total: float = 0.0
	_legacy_skill_table[1] = 0.0
	for i in range(1, MAX_SKILL_LEVEL):
		total += floorf((float(i) + 300.0 * pow(2.0, float(i) / LEGACY_SKILL_CURVE_DIVISOR)) / 4.0)
		_legacy_skill_table[i + 1] = total


static func legacy_skill_xp_for_level(level: int) -> float:
	_ensure_legacy_skill_table()
	var l: int = clampi(level, 1, MAX_SKILL_LEVEL)
	return float(_legacy_skill_table.get(l, 0.0))


static func legacy_skill_level_for_xp(xp: float, max_level: int = MAX_SKILL_LEVEL) -> int:
	var cap: int = clampi(max_level, 1, MAX_SKILL_LEVEL)
	var level: int = 1
	while level < cap and xp >= legacy_skill_xp_for_level(level + 1):
		level += 1
	return level


static func _ensure_legacy_mastery_table() -> void:
	if not _legacy_mastery_table.is_empty():
		return
	var total: float = 0.0
	_legacy_mastery_table[1] = 0.0
	for i in range(1, MAX_MASTERY_LEVEL):
		var step: float
		if i <= 30:
			step = floorf(30.0 * pow(1.06, float(i - 1)) + 15.0 * float(i))
		else:
			var base: float = 30.0 * pow(1.06, 29.0)
			step = floorf(base * pow(1.08, float(i - 30)) + 15.0 * float(i))
		total += step
		_legacy_mastery_table[i + 1] = total


static func legacy_mastery_xp_for_level(level: int) -> float:
	_ensure_legacy_mastery_table()
	var l: int = clampi(level, 1, MAX_MASTERY_LEVEL)
	return float(_legacy_mastery_table.get(l, 0.0))


static func legacy_mastery_level_for_xp(xp: float) -> int:
	var level: int = 1
	while level < MAX_MASTERY_LEVEL and xp >= legacy_mastery_xp_for_level(level + 1):
		level += 1
	return level


# ---------------------------------------------------------------- v3 曲线（只供 v3 旧档迁移）

## exp_curve_version == 3 时用的阈值曲线（divisor 6.2 / 6.5，倍率 2.8 / 2.2）。
## v4 把上限抬到 150 并放宽分母后，老档必须用这套旧阈值还原等级与级内比例。
static var _v3_skill_table: Dictionary = {}
static var _v3_mastery_table: Dictionary = {}


static func v3_skill_xp_for_level(level: int) -> float:
	var l: int = clampi(level, 1, MAX_SKILL_LEVEL)
	if _v3_skill_table.has(l):
		return float(_v3_skill_table[l])
	var total := 0.0
	for i in range(1, l):
		var lv := float(maxi(1, i))
		var base := 0.25 * (lv + 300.0 * pow(2.0, lv / V3_SKILL_CURVE_DIVISOR))
		total += float(maxi(100, int(floor(base * SKILL_CURVE_SCALE))))
	_v3_skill_table[l] = total
	return total


static func v3_skill_level_for_xp(xp: float, max_level: int = MAX_SKILL_LEVEL) -> int:
	var cap: int = clampi(max_level, 1, MAX_SKILL_LEVEL)
	var level := 1
	while level < cap and xp >= v3_skill_xp_for_level(level + 1):
		level += 1
	return level


static func v3_mastery_xp_for_level(level: int) -> float:
	var l: int = clampi(level, 1, MAX_MASTERY_LEVEL)
	if _v3_mastery_table.has(l):
		return float(_v3_mastery_table[l])
	var total := 0.0
	for i in range(1, l):
		var lv := float(maxi(1, i))
		var base := 0.25 * (lv + 300.0 * pow(2.0, lv / V3_MASTERY_CURVE_DIVISOR))
		total += float(maxi(80, int(floor(base * MASTERY_CURVE_SCALE))))
	_v3_mastery_table[l] = total
	return total


static func v3_mastery_level_for_xp(xp: float) -> int:
	var level := 1
	while level < MAX_MASTERY_LEVEL and xp >= v3_mastery_xp_for_level(level + 1):
		level += 1
	return level


# ---------------------------------------------------------------- 获取倍率（唯一口径）

## 单次技能经验：基础值 × 全局倍率 × 各项百分比加成，向下取整且保底 1
static func scale_skill_gain(base_amount: float, bonus_multiplier: float = 1.0) -> int:
	if base_amount <= 0.0:
		return 0
	return maxi(1, int(floor(base_amount * SKILL_EXP_GLOBAL_MULT * maxf(0.0, bonus_multiplier))))


## 单次火候经验：基础值 × 全局倍率，向下取整且保底 1
static func scale_mastery_gain(base_amount: float) -> int:
	if base_amount <= 0.0:
		return 0
	return maxi(1, int(floor(base_amount * MASTERY_EXP_GLOBAL_MULT)))


## 火候带来的耗时乘数（1.0 -> 0.755）
static func mastery_interval_multiplier(mastery_level: int) -> float:
	var l: int = clampi(mastery_level, 1, MAX_MASTERY_LEVEL)
	return 1.0 - MASTERY_INTERVAL_PER_LEVEL * float(l - 1)


# ---------------------------------------------------------------- 灵田施肥肥力折算
## 单次施肥标准肥力：30 点 = 原版「青叶草 10 点/株 × 3 株」，历史行为完全一致。
## 本类保持纯静态不引用 autoload：草药解锁等级由 FarmManager 查 DataRegistry 后传入。
const FERTILIZER_BASE_COST: float = 30.0

## 单株肥力按采药解锁档位分五档：越珍贵的草药肥力越高，高阶 1 株即可抵一次标准施肥。
static func herb_fertility_by_level(unlock_level: int) -> int:
	return int(get_material_grade_by_level(unlock_level).get("fertility", 10))


## 万物品阶（纯静态，阈值与灵田肥力五档完全同源）：
## ≤15 凡阶10 / ≤45 灵阶30 / ≤78 玄阶90 / ≤115 仙阶240 / >115 神阶600
const MATERIAL_GRADE_NAMES: Array[String] = ["凡阶", "灵阶", "玄阶", "仙阶", "神阶"]


static func get_material_grade_by_level(unlock_level: int) -> Dictionary:
	var tier := 1
	var fertility := 10
	if unlock_level > 115:
		tier = 5
		fertility = 600
	elif unlock_level > 78:
		tier = 4
		fertility = 240
	elif unlock_level > 45:
		tier = 3
		fertility = 90
	elif unlock_level > 15:
		tier = 2
		fertility = 30
	return {"tier": tier, "name": MATERIAL_GRADE_NAMES[tier - 1],
		"fertility": fertility}


# ---------------------------------------------------------------- 低阶材料一键化灵
## 「过时低阶」门槛：落后当前境界技能上限 25 级即视为淘汰旧材。
## 炼气期上限 20 → threshold 1（新手阶段几乎不误清开局材料）。
static func outdated_material_threshold(current_cap: int) -> int:
	return maxi(1, current_cap - 25)


# ---------------------------------------------------------------- 淘汰装备批量熔炼
## 熔炼品质倍率：凡品 1.0 / 精良 1.4 / 极品 2.0。
## 与穿戴加成的 QUALITY_MULTIPLIERS(1.0/1.2/1.4) 是两套口径，互不影响。
const SMELT_QUALITY_MULTIPLIERS: Array[float] = [1.0, 1.4, 2.0]


static func smelt_quality_mult(quality: int) -> float:
	return SMELT_QUALITY_MULTIPLIERS[clampi(quality, 0, 2)]


## 淘汰装备阶位门槛：落后当前境界技能上限 20 级即视为过时（材料化灵是 -25，两套口径）。
static func obsolete_equipment_threshold(current_cap: int) -> int:
	return maxi(1, current_cap - 20)


# ---------------------------------------------------------------- 百艺总火候里程碑
## 单门百艺全部动作的火候等级累计，每满 50 级为 1 阶（上限 10 阶 = 500 级）：
## 每阶 动作耗时 -1.5%、双倍产出 +1.0%。实时派生，不落存档。

const SKILL_MASTERY_TIER_SIZE: int = 50
const SKILL_MASTERY_TIER_CAP: int = 10


static func skill_mastery_tier(total_mastery: int) -> int:
	return mini(SKILL_MASTERY_TIER_CAP,
		int(floor(float(maxi(0, total_mastery)) / float(SKILL_MASTERY_TIER_SIZE))))


static func skill_mastery_interval_mult(total_mastery: int) -> float:
	return 1.0 - float(skill_mastery_tier(total_mastery)) * 0.015


static func skill_mastery_double_bonus(total_mastery: int) -> float:
	return float(skill_mastery_tier(total_mastery)) * 0.01


## 火候带来的双倍产出 / 极品率
## 满级 99 直接给到上限 0.20：floor(99/5)=19 → 19%，原公式永远摸不到 20% 上限
static func mastery_double_chance(mastery_level: int) -> float:
	var l: int = clampi(mastery_level, 1, MAX_MASTERY_LEVEL)
	if l >= MAX_MASTERY_LEVEL:
		return MASTERY_DOUBLE_CAP
	return minf(MASTERY_DOUBLE_CAP, floorf(float(l) / 5.0) * MASTERY_DOUBLE_PER_5)


# ---------------------------------------------------------------- 悟道池

static func pool_capacity(action_count: int) -> float:
	return POOL_CAPACITY_PER_ACTION * float(maxi(1, action_count))


static func pool_ratio(current: float, capacity: float) -> float:
	if capacity <= 0.0:
		return 0.0
	return clampf(current / capacity, 0.0, 1.0)


# ---------------------------------------------------------------- 坊市 / 法器加成

## 万象玉简：收集度全局里程碑（20/40/60/80/100%）
## 60% 同时给「气血 +10%」与「灵田产量 +10%」（farm_yield 由 FarmManager 读取）
const CODEX_MILESTONES: Array = [
	{"percent": 0.20, "key": "xp", "value": 0.05},
	{"percent": 0.40, "key": "double", "value": 0.03},
	{"percent": 0.60, "key": "max_hp", "value": 0.10},
	{"percent": 0.60, "key": "farm_yield", "value": 0.10},
	{"percent": 0.80, "key": "interval", "value": 0.05},
	{"percent": 1.00, "key": "attack", "value": 0.15},
]

# ---------------------------------------------------------------- 灵田奇珍 / 灵气反哺
## 百年朱果：每枚永久气血 / 攻击，最多炼化 50 枚
const CRIMSON_FRUIT_CAP: int = 50
const CRIMSON_FRUIT_HP: int = 20
const CRIMSON_FRUIT_ATK: int = 2
## 每块已播种灵田：吐纳修为 +3%、丹道双倍 +2%
const FARM_AURA_CULTIVATION_PER_PLOT: float = 0.03
const FARM_AURA_ALCHEMY_PER_PLOT: float = 0.02
## 仙壤灵脉反哺：每重 +1% 修为（20 重封顶 +20%）、每 2 重 +1% 丹道双倍（封顶 +10%）
const FARM_SOIL_MAX_LEVEL: int = 20
const FARM_AURA_SOIL_CULTIVATION_PER_LEVEL: float = 0.01
const FARM_AURA_SOIL_ALCHEMY_PER_TWO_LEVELS: float = 0.01


static func crimson_fruit_hp_bonus(eaten: int) -> int:
	return clampi(eaten, 0, CRIMSON_FRUIT_CAP) * CRIMSON_FRUIT_HP


static func crimson_fruit_attack_bonus(eaten: int) -> int:
	return clampi(eaten, 0, CRIMSON_FRUIT_CAP) * CRIMSON_FRUIT_ATK


## 灵田基础反哺（与灵脉无关，炼气期开荒数值保持不变）
static func farm_aura_plot_cultivation(planted: int) -> float:
	return FARM_AURA_CULTIVATION_PER_PLOT * float(clampi(planted, 0, 4))


static func farm_aura_plot_alchemy(planted: int) -> float:
	return FARM_AURA_ALCHEMY_PER_PLOT * float(clampi(planted, 0, 4))


## 灵脉自身的反哺档位（与是否有田无关，仅用于展示「这一重给了多少」）
static func farm_soil_cultivation_pct(soil_level: int) -> float:
	return FARM_AURA_SOIL_CULTIVATION_PER_LEVEL \
		* float(clampi(soil_level, 0, FARM_SOIL_MAX_LEVEL))


static func farm_soil_alchemy_pct(soil_level: int) -> float:
	var pairs := clampi(soil_level, 0, FARM_SOIL_MAX_LEVEL) / 2
	return FARM_AURA_SOIL_ALCHEMY_PER_TWO_LEVELS * float(pairs)


## 灵脉加成仅在至少一块灵田已播种（灵气反哺激活）时计入
static func farm_aura_soil_cultivation(soil_level: int, planted: int) -> float:
	return farm_soil_cultivation_pct(soil_level) if planted > 0 else 0.0


static func farm_aura_soil_alchemy(soil_level: int, planted: int) -> float:
	return farm_soil_alchemy_pct(soil_level) if planted > 0 else 0.0


## 灵气反哺总出口：基础灵田 + 灵脉（修为 32% / 丹道 18% 为 4 田 + 20 重满配）
static func farm_aura_cultivation(planted: int, soil_level: int = 0) -> float:
	return farm_aura_plot_cultivation(planted) \
		+ farm_aura_soil_cultivation(soil_level, planted)


static func farm_aura_alchemy_double(planted: int, soil_level: int = 0) -> float:
	return farm_aura_plot_alchemy(planted) \
		+ farm_aura_soil_alchemy(soil_level, planted)

static func get_codex_bonus(bonus_key: String) -> float:
	var total := 0.0
	if GameState == null:
		return total
	var percent := GameState.get_codex_percent()
	for entry in CODEX_MILESTONES:
		var dict: Dictionary = entry
		if percent + 0.0001 >= float(dict["percent"]) and String(dict["key"]) == bonus_key:
			total += float(dict["value"])
	return total


## 藏经阁：汇总已装备功法的某项加成（含参悟等级线性放大）
static func get_technique_bonus(bonus_key: String) -> float:
	var total := 0.0
	if GameState == null:
		return total
	for tech_id in GameState.equipped_techniques:
		var tech := DataRegistry.get_technique(String(tech_id))
		if tech == null or not tech.effects.has(bonus_key):
			continue
		total += tech.get_scaled_effect(bonus_key, GameState.get_technique_level(tech.id))
	return total


## 多个「减耗比例」按乘算叠加（火候、悟道池、法器各自独立生效）
static func interval_multiplier(reductions: Array) -> float:
	var multiplier := 1.0
	for value in reductions:
		multiplier *= 1.0 - clampf(float(value), 0.0, 0.9)
	return maxf(0.05, multiplier)


## 多个乘区（如 1.2、0.95）连乘
static func product_multiplier(values: Array) -> float:
	var multiplier := 1.0
	for value in values:
		multiplier *= float(value)
	return maxf(0.01, multiplier)


## 概率类加成统一夹取，避免超过 100%
static func clamp_chance(value: float, max_chance: float = 0.95) -> float:
	return clampf(value, 0.0, max_chance)


# ---------------------------------------------------------------- 五行

static func generates(source: int, target: int) -> bool:
	for entry in ELEMENT_CYCLE:
		if int(entry["from"]) == source and int(entry["to"]) == target:
			return true
	return false


static func synergy_label(source: int, target: int) -> String:
	for entry in ELEMENT_CYCLE:
		if int(entry["from"]) == source and int(entry["to"]) == target:
			return String(entry["label"])
	return ""


# ---------------------------------------------------------------- 战斗

## 单次伤害：max(1, round(atk * randf_range(0.85,1.15) - def * 0.6))
static func compute_damage(attack: int, defense: int, roll: float) -> int:
	var raw: float = float(attack) * roll - float(defense) * 0.6
	return maxi(1, int(roundf(raw)))


## 期望伤害（roll 取 1.0，用于离线结算与 DPS 估算）
static func expected_damage(attack: int, defense: int) -> float:
	return maxf(1.0, float(attack) - float(defense) * 0.6)


## 基础气血：100，境界每推进一层 +15
static func base_max_hp(progression_index: int) -> int:
	return 100 + 15 * maxi(0, progression_index)


## 天雷伤害：道心悟性每层 -10%（最多 5 层），护身符按比例减伤（55% / 40%）
static func tribulation_damage(base: int, defense: int, dao_heart_stacks: int,
		ward_ratio: float = 0.0) -> int:
	var mult: float = 1.0 - minf(0.1 * float(clampi(dao_heart_stacks, 0, 5)), 0.5)
	var raw: float = float(base) * mult - float(defense) * 0.8
	if ward_ratio > 0.0:
		raw *= 1.0 - clampf(ward_ratio, 0.0, 0.9)
	return maxi(1, int(roundf(raw)))


# ---------------------------------------------------------------- 杂项格式化

static func offline_cap_seconds(hours: float) -> float:
	return maxf(0.0, hours) * 3600.0


static func format_duration(seconds: float) -> String:
	var total: int = maxi(0, int(seconds))
	var hours: int = total / 3600
	var minutes: int = (total % 3600) / 60
	var secs: int = total % 60
	if hours > 0:
		return "%d 小时 %02d 分" % [hours, minutes]
	if minutes > 0:
		return "%d 分 %02d 秒" % [minutes, secs]
	return "%d 秒" % secs


## 统一大数字格式：<1万 整数，<1亿 中文万位（1.83万），>=1亿 亿位（1.25亿）
## 整数值去「.00」尾：1100.00万 → 1100万，1.20万 / 1.83万 保留两位
static func format_num(value: float) -> String:
	var negative := value < 0.0
	var amount := absf(value)
	var text := ""
	if amount < 10000.0:
		text = str(int(roundf(amount)))
	elif amount < 100000000.0:
		text = _trim_zero_dec("%.2f万" % (amount / 10000.0))
	else:
		text = _trim_zero_dec("%.2f亿" % (amount / 100000000.0))
	return ("-" + text) if negative else text


static func _trim_zero_dec(text: String) -> String:
	for suffix in [".00万", ".00亿"]:
		if text.ends_with(suffix):
			return text.substr(0, text.length() - suffix.length()) + suffix.substr(suffix.length() - 1)
	return text


static func format_number(value: float) -> String:
	var rounded: int = int(roundf(value))
	var text: String = str(absi(rounded))
	var out: String = ""
	var count: int = 0
	for i in range(text.length() - 1, -1, -1):
		out = text[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "," + out
	return ("-" if rounded < 0 else "") + out

