class_name SpiritRootSystem
extends RefCounted

## 灵根洗髓：炼气七层开启的后天灵根纯化与五行亲和系统。
## 状态只写入 GameState.flags["spirit_root"]，不新增存档外层字段。

const STATE_KEY: String = "spirit_root"
const UNLOCK_ORDER: int = 6
const MAX_GRADE: int = 4
const GRADE_NAMES: Array[String] = ["五灵根", "四灵根", "三灵根", "双灵根", "天灵根"]
const ELEMENT_KEYS: Array[String] = ["metal", "wood", "water", "fire", "earth"]
const ELEMENT_NAMES: Dictionary = {
	"metal": "金", "wood": "木", "water": "水", "fire": "火", "earth": "土",
}

## 四阶洗髓：门槛严格绑定大境界，杜绝同境连洗。
const PURIFY_STEPS: Array = [
	{
		"grade": 1, "realm": 6, "name": "四灵根",
		"items": {"item_qi_pill": 20, "item_ninglu": 150, "item_beast_core": 12},
		"stones": 800,
	},
	{
		"grade": 2, "realm": 9, "name": "三灵根",
		"items": {"item_foundation_pill": 2, "item_peiyuan_pill": 20, "item_beast_core": 30},
		"stones": 2500,
	},
	{
		"grade": 3, "realm": 12, "name": "双灵根",
		"items": {"item_jindan_pill": 2, "item_gold_pill": 25, "item_demon_essence": 35},
		"stones": 8000,
	},
	{
		"grade": 4, "realm": 15, "name": "天灵根",
		"items": {"item_nascent_pill": 2, "item_yuanying_pill": 30,
			"item_ancient_soul": 20, "item_star_core": 25},
		"stones": 25000,
	},
]

const GRADE_MEDITATE: Array[float] = [0.0, 0.08, 0.16, 0.25, 0.35]
const GRADE_TRIBULATION: Array[float] = [0.0, 0.02, 0.04, 0.07, 0.10]
const ELEMENT_ATTACK: Array[float] = [0.04, 0.08, 0.12, 0.16]
const ELEMENT_INTERVAL: Array[float] = [0.02, 0.04, 0.06, 0.08]
const ELEMENT_FARM_GROWTH: Array[float] = [0.03, 0.06, 0.09, 0.12]
const ELEMENT_WATER_CULTIVATION: Array[float] = [0.03, 0.06, 0.09, 0.12]
const ELEMENT_WATER_DOUBLE: Array[float] = [0.02, 0.04, 0.06, 0.08]
const ELEMENT_FIRE_CRIT: Array[float] = [0.02, 0.04, 0.06, 0.08]
const ELEMENT_EARTH_HP_DEF: Array[float] = [0.04, 0.08, 0.12, 0.16]
const ELEMENT_EARTH_TRIBULATION: Array[float] = [0.02, 0.03, 0.04, 0.06]


static func default_state() -> Dictionary:
	return {"grade": 0, "element": "wood"}


static func get_state() -> Dictionary:
	if GameState == null:
		return default_state()
	var flags: Dictionary = GameState.flags
	var raw: Variant = flags.get(STATE_KEY, null)
	if typeof(raw) != TYPE_DICTIONARY:
		var fresh := default_state()
		flags[STATE_KEY] = fresh
		return fresh
	var saved: Dictionary = raw
	var state := default_state()
	state["grade"] = clampi(int(saved.get("grade", 0)), 0, MAX_GRADE)
	var element := str(saved.get("element", "wood"))
	state["element"] = element if ELEMENT_KEYS.has(element) else "wood"
	flags[STATE_KEY] = state
	return state


static func commit_state(state: Dictionary) -> void:
	if GameState == null:
		return
	var flags: Dictionary = GameState.flags
	flags[STATE_KEY] = state
	EventBus.stats_changed.emit()
	EventBus.farm_changed.emit()
	if SaveManager != null and SaveManager.has_method("save_game"):
		SaveManager.call("save_game", false)


static func is_unlocked() -> bool:
	return GameState != null and GameState.get_realm_index() >= UNLOCK_ORDER


static func get_grade() -> int:
	return int(get_state().get("grade", 0))


static func get_element() -> String:
	return str(get_state().get("element", "wood"))


static func get_grade_name(grade: int = -1) -> String:
	var value := get_grade() if grade < 0 else grade
	return GRADE_NAMES[clampi(value, 0, MAX_GRADE)]


static func element_name(element: String = "") -> String:
	var key := get_element() if element == "" else element
	return str(ELEMENT_NAMES.get(key, "木"))


static func element_icon(element: String = "") -> String:
	var key := get_element() if element == "" else element
	return "root_" + (key if ELEMENT_KEYS.has(key) else "wood")


static func get_badge_text() -> String:
	return "%s · %s" % [get_grade_name(), element_name()]


static func get_purify_plan() -> Dictionary:
	var grade := get_grade()
	if grade < 0 or grade >= PURIFY_STEPS.size():
		return {}
	var plan: Dictionary = PURIFY_STEPS[grade]
	return plan.duplicate(true)


static func get_switch_cost() -> int:
	return 300 * (get_grade() + 1)


static func can_purify() -> Dictionary:
	if not is_unlocked():
		return {"ok": false, "reason": "需炼气七层开启"}
	var plan := get_purify_plan()
	if plan.is_empty():
		return {"ok": false, "reason": "灵根已臻天品圆满"}
	if GameState.get_realm_index() < int(plan.get("realm", 0)):
		return {"ok": false, "reason": "境界未达 %s" % plan.get("name", "下一阶")}
	var items: Dictionary = plan.get("items", {})
	for item_id in items.keys():
		if GameState.get_item_count(str(item_id)) < int(items[item_id]):
			return {"ok": false, "reason": "洗髓材料不足"}
	if GameState.get_item_count(DataRegistry.SPIRIT_STONE) < int(plan.get("stones", 0)):
		return {"ok": false, "reason": "灵石不足"}
	return {"ok": true, "plan": plan}


static func purify() -> Dictionary:
	var check := can_purify()
	if not bool(check.get("ok", false)):
		return check
	var plan: Dictionary = check.get("plan", {})
	var items: Dictionary = plan.get("items", {})
	for item_id in items.keys():
		GameState.remove_item(str(item_id), int(items[item_id]))
	GameState.remove_item(DataRegistry.SPIRIT_STONE, int(plan.get("stones", 0)))
	var state := get_state()
	state["grade"] = clampi(get_grade() + 1, 0, MAX_GRADE)
	commit_state(state)
	return {"ok": true, "message": "洗髓成功，已化为%s" % get_grade_name()}


static func can_switch(element: String) -> Dictionary:
	if not is_unlocked():
		return {"ok": false, "reason": "需炼气七层开启"}
	if not ELEMENT_KEYS.has(element):
		return {"ok": false, "reason": "未知五行方向"}
	if element == get_element():
		return {"ok": false, "reason": "当前已是该主灵根"}
	if GameState.get_item_count(DataRegistry.SPIRIT_STONE) < get_switch_cost():
		return {"ok": false, "reason": "导引灵石不足"}
	return {"ok": true, "cost": get_switch_cost()}


static func switch_element(element: String) -> Dictionary:
	var check := can_switch(element)
	if not bool(check.get("ok", false)):
		return check
	GameState.remove_item(DataRegistry.SPIRIT_STONE, int(check.get("cost", 0)))
	var state := get_state()
	state["element"] = element
	commit_state(state)
	return {"ok": true, "message": "导引改脉完成，主灵根转为%s" % element_name(element)}


static func _index() -> int:
	return clampi(get_grade() - 1, 0, ELEMENT_ATTACK.size() - 1)


static func get_bonus(key: String) -> float:
	if not is_unlocked() or get_grade() <= 0:
		return 0.0
	var i := _index()
	var element := get_element()
	match key:
		"meditate_cultivation":
			return GRADE_MEDITATE[clampi(get_grade(), 0, MAX_GRADE)] \
				+ (ELEMENT_WATER_CULTIVATION[i] if element == "water" else 0.0)
		"tribulation_reduction":
			return GRADE_TRIBULATION[clampi(get_grade(), 0, MAX_GRADE)] \
				+ (ELEMENT_EARTH_TRIBULATION[i] if element == "earth" else 0.0)
		"attack_pct":
			return ELEMENT_ATTACK[i] if element == "metal" else 0.0
		"hp_def_pct":
			return ELEMENT_EARTH_HP_DEF[i] if element == "earth" else 0.0
		"crit_chance":
			return ELEMENT_FIRE_CRIT[i] if element == "fire" else 0.0
		"farm_growth_reduction":
			return ELEMENT_FARM_GROWTH[i] if element == "wood" else 0.0
	return 0.0


static func get_skill_interval_reduction(skill_id: String) -> float:
	if not is_unlocked() or get_grade() <= 0:
		return 0.0
	var i := _index()
	match get_element():
		"metal":
			return ELEMENT_INTERVAL[i] if skill_id == "mining" or skill_id == "forging" else 0.0
		"wood":
			return ELEMENT_INTERVAL[i] if skill_id == "herbalism" or skill_id == "woodcutting" else 0.0
		"fire":
			return ELEMENT_INTERVAL[i] if skill_id == "alchemy" or skill_id == "talisman" else 0.0
	return 0.0


static func get_skill_double_bonus(skill_id: String) -> float:
	if not is_unlocked() or get_grade() <= 0 or get_element() != "water":
		return 0.0
	if skill_id == "alchemy" or skill_id == "talisman":
		return ELEMENT_WATER_DOUBLE[_index()]
	return 0.0


static func get_effect_text(element: String, grade: int) -> String:
	if grade <= 0 or not ELEMENT_KEYS.has(element):
		return "五灵根无额外亲和"
	var i := clampi(grade - 1, 0, ELEMENT_ATTACK.size() - 1)
	match element:
		"metal":
			return "攻击 +%.0f%% · 开矿与器道耗时 -%.0f%%" % [
				ELEMENT_ATTACK[i] * 100.0, ELEMENT_INTERVAL[i] * 100.0]
		"wood":
			return "采药与伐木耗时 -%.0f%% · 灵田生长 -%.0f%%" % [
				ELEMENT_INTERVAL[i] * 100.0, ELEMENT_FARM_GROWTH[i] * 100.0]
		"water":
			return "吐纳额外 +%.0f%% · 丹符双倍 +%.0f%%" % [
				ELEMENT_WATER_CULTIVATION[i] * 100.0, ELEMENT_WATER_DOUBLE[i] * 100.0]
		"fire":
			return "丹符耗时 -%.0f%% · 会心 +%.0f%%" % [
				ELEMENT_INTERVAL[i] * 100.0, ELEMENT_FIRE_CRIT[i] * 100.0]
		"earth":
			return "气血与防御 +%.0f%% · 抗雷额外 +%.0f%%" % [
				ELEMENT_EARTH_HP_DEF[i] * 100.0, ELEMENT_EARTH_TRIBULATION[i] * 100.0]
	return "暂无记载"


static func get_summary() -> Array:
	var out: Array = []
	var base_med := get_bonus("meditate_cultivation")
	var base_trib := get_bonus("tribulation_reduction")
	if base_med > 0.0:
		out.append({"label": "吐纳修为", "value": "+%.0f%%" % (base_med * 100.0)})
	if base_trib > 0.0:
		out.append({"label": "渡劫抗性", "value": "+%.0f%%" % (base_trib * 100.0)})
	if get_grade() <= 0:
		return out
	for key in ["attack_pct", "hp_def_pct", "crit_chance", "farm_growth_reduction"]:
		var value := get_bonus(key)
		if value > 0.0:
			out.append({"label": _bonus_label(key), "value": "+%.0f%%" % (value * 100.0)})
	var element := get_element()
	var i := _index()
	if element == "metal" or element == "wood" or element == "fire":
		out.append({"label": "对应百艺耗时", "value": "-%.0f%%" % (ELEMENT_INTERVAL[i] * 100.0)})
	if element == "water":
		out.append({"label": "丹符双倍", "value": "+%.0f%%" % (ELEMENT_WATER_DOUBLE[i] * 100.0)})
	return out


static func _bonus_label(key: String) -> String:
	match key:
		"attack_pct":
			return "攻击力"
		"hp_def_pct":
			return "气血与防御"
		"crit_chance":
			return "会心率"
		"farm_growth_reduction":
			return "灵田生长"
	return key
