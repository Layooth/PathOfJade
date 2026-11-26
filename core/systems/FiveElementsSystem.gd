class_name FiveElementsSystem
extends RefCounted

## 五行法则：合体初期开启的终局长线系统。
## 状态只写入 GameState.flags["five_elements"]，不新增存档外层字段。

const STATE_KEY: String = "five_elements"
const UNLOCK_REALM_INDEX: int = 24
const MAX_LEVEL: int = 5
const LAW_KEYS: Array[String] = ["metal", "wood", "water", "fire", "earth"]
const MATERIAL_COUNTS: Array[int] = [1, 2, 3, 4, 5]
const POOL_COSTS: Array[int] = [18000, 36000, 60000, 60000, 66000]

const LAWS: Dictionary = {
	"metal": {
		"name": "金之法则", "icon": "law_metal",
		"materials": ["item_hundun_stone", "item_hongmeng_gold"],
	},
	"wood": {
		"name": "木之法则", "icon": "law_wood",
		"materials": ["item_hundun_vine", "item_worldtree"],
	},
	"water": {
		"name": "水之法则", "icon": "law_water",
		"materials": ["item_jiuyou_crystal", "item_taiyi_lian"],
	},
	"fire": {
		"name": "火之法则", "icon": "law_fire",
		"materials": ["item_hundun_flower", "item_hongmeng_herb"],
	},
	"earth": {
		"name": "土之法则", "icon": "law_earth",
		"materials": ["item_hundun_stone", "item_xingyun_iron"],
	},
}


static func default_state() -> Dictionary:
	return {
		"levels": {"metal": 0, "wood": 0, "water": 0, "fire": 0, "earth": 0},
		"auto_farm_enabled": true,
	}


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
	var levels: Dictionary = default_state()["levels"]
	var saved_levels: Variant = saved.get("levels", {})
	if typeof(saved_levels) == TYPE_DICTIONARY:
		for law_id in LAW_KEYS:
			levels[law_id] = clampi(int((saved_levels as Dictionary).get(law_id, 0)), 0, MAX_LEVEL)
	state["levels"] = levels
	state["auto_farm_enabled"] = bool(saved.get("auto_farm_enabled", true))
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
	return GameState != null and GameState.get_realm_index() >= UNLOCK_REALM_INDEX


static func get_level(law_id: String) -> int:
	if not LAWS.has(law_id):
		return 0
	var state := get_state()
	var levels: Dictionary = state.get("levels", {})
	return clampi(int(levels.get(law_id, 0)), 0, MAX_LEVEL)


static func get_total_levels() -> int:
	var total := 0
	for law_id in LAW_KEYS:
		total += get_level(str(law_id))
	return total


static func get_law_name(law_id: String) -> String:
	var law: Dictionary = LAWS.get(law_id, {})
	return str(law.get("name", "未知法则"))


static func get_law_icon(law_id: String) -> String:
	var law: Dictionary = LAWS.get(law_id, {})
	return str(law.get("icon", "law_metal"))


static func get_total_pool_xp() -> float:
	if GameState == null:
		return 0.0
	var total := 0.0
	for skill_id in DataRegistry.skill_order:
		total += GameState.get_pool_current(str(skill_id))
	return total


static func consume_pool_xp(amount: float) -> void:
	if amount <= 0.0 or GameState == null:
		return
	var remain := amount
	var skills: Array = DataRegistry.skill_order
	skills.sort_custom(func(a: String, b: String) -> bool:
		return GameState.get_pool_current(a) > GameState.get_pool_current(b))
	for skill_id_value in skills:
		if remain <= 0.0:
			break
		var skill_id := str(skill_id_value)
		var have := GameState.get_pool_current(skill_id)
		if have <= 0.0:
			continue
		var take := minf(have, remain)
		GameState.mastery_pool[skill_id] = have - take
		remain -= take
		EventBus.mastery_pool_changed.emit(skill_id,
			GameState.get_pool_current(skill_id), GameState.get_pool_capacity(skill_id))


static func material_cost(next_level: int) -> int:
	var index := clampi(next_level - 1, 0, MATERIAL_COUNTS.size() - 1)
	return MATERIAL_COUNTS[index]


static func pool_cost(next_level: int) -> int:
	var index := clampi(next_level - 1, 0, POOL_COSTS.size() - 1)
	return POOL_COSTS[index]


static func choose_material(law_id: String, next_level: int, preferred: String = "") -> String:
	if not LAWS.has(law_id):
		return ""
	var law: Dictionary = LAWS[law_id]
	var candidates: Array = law.get("materials", [])
	var need := material_cost(next_level)
	if preferred != "" and candidates.has(preferred) \
			and GameState.get_item_count(preferred) >= need:
		return preferred
	for value in candidates:
		var item_id := str(value)
		if GameState.get_item_count(item_id) >= need:
			return item_id
	return ""


static func can_upgrade(law_id: String) -> Dictionary:
	if not is_unlocked() or not LAWS.has(law_id):
		return {"ok": false, "reason": "需合体初期开启五行法则"}
	var current := get_level(law_id)
	if current >= MAX_LEVEL:
		return {"ok": false, "reason": "已参悟至 5 重"}
	var next_level := current + 1
	var material_id := choose_material(law_id, next_level)
	if material_id == "":
		return {"ok": false, "reason": "高阶法则材料不足"}
	var need_pool := float(pool_cost(next_level))
	if get_total_pool_xp() + 0.0001 < need_pool:
		return {"ok": false, "reason": "悟道池经验不足"}
	return {
		"ok": true, "material_id": material_id,
		"material_name": DataRegistry.get_item_name(material_id),
		"material_count": material_cost(next_level), "pool": need_pool,
	}


static func upgrade(law_id: String, preferred_material: String = "") -> Dictionary:
	var check := can_upgrade(law_id)
	if not bool(check.get("ok", false)):
		return check
	var current := get_level(law_id)
	var next_level := current + 1
	var material_id := choose_material(law_id, next_level, preferred_material)
	if material_id == "":
		material_id = str(check.get("material_id", ""))
	GameState.remove_item(material_id, material_cost(next_level))
	consume_pool_xp(float(check.get("pool", 0.0)))
	var state := get_state()
	var levels: Dictionary = state.get("levels", {})
	levels[law_id] = next_level
	state["levels"] = levels
	commit_state(state)
	return {"ok": true, "level": next_level,
		"message": "%s参悟至 %d 重" % [get_law_name(law_id), next_level]}


static func is_auto_farm_enabled() -> bool:
	if get_level("wood") < 1:
		return false
	var state := get_state()
	return bool(state.get("auto_farm_enabled", true))


static func set_auto_farm(enabled: bool) -> void:
	var state := get_state()
	state["auto_farm_enabled"] = enabled
	commit_state(state)


static func get_bonus(key: String) -> float:
	if not is_unlocked():
		return 0.0
	match key:
		"attack_pct":
			return 0.05 * float(get_level("metal"))
		"attack_interval_reduction":
			return 0.10 if get_level("metal") >= 1 else 0.0
		"farm_growth_reduction":
			return 0.04 * float(get_level("wood"))
		"meditate_cultivation":
			return 0.15 if get_level("water") >= 1 else 0.0
		"offline_efficiency":
			return 0.04 * float(get_level("water"))
		"quality_bonus":
			return 0.08 if get_level("fire") >= 1 else 0.0
		"double_bonus":
			return 0.04 * float(get_level("fire"))
		"tribulation_reduction":
			return 0.10 if get_level("earth") >= 1 else 0.0
		"hp_def_pct":
			return 0.06 * float(get_level("earth"))
	return 0.0


static func get_effect_text(law_id: String, level: int) -> String:
	if level <= 0:
		return "尚未参悟"
	match law_id:
		"metal":
			return "攻击 +%.0f%% · 攻击间隔 -10%%" % [5.0 * float(level)]
		"wood":
			return "灵田生长 -%.0f%% · 自动轮作已开启" % [4.0 * float(level)]
		"water":
			return "吐纳修为 +15%% · 离线效率 +%.0f%%" % [4.0 * float(level)]
		"fire":
			return "精良极品 +8%% · 双倍产出 +%.0f%%" % [4.0 * float(level)]
		"earth":
			return "天雷抗性 +10%% · 气血与防御 +%.0f%%" % [6.0 * float(level)]
	return "暂无记载"


static func ascension_ready() -> Dictionary:
	var missing: Array[String] = []
	var realm := GameState.get_realm()
	var is_great_late := realm != null and realm.id == "great_late"
	var full_and_ticket := is_great_late and GameState.is_cultivation_full() \
		and GameState.get_item_count("item_ascension_pill") >= 1
	if not full_and_ticket:
		missing.append("大乘后期修为圆满并持有渡劫飞升丹")
	var natal_state := NatalArtifactSystem.get_state()
	var natal_ok := int(natal_state.get("level", 0)) >= 31
	if not natal_ok:
		missing.append("本命法宝温养至先天至宝（31 重）")
	var laws_ok := true
	for law_id in LAW_KEYS:
		if get_level(str(law_id)) < 1:
			laws_ok = false
			break
	if not laws_ok:
		missing.append("五行法则金木水火土均已参悟至少 1 重")
	return {
		"ok": missing.is_empty(),
		"missing": missing,
		"message": "；".join(missing),
		"cultivation_ticket_ok": full_and_ticket,
		"natal_ok": natal_ok,
		"laws_ok": laws_ok,
	}


static func is_ascended() -> bool:
	return GameState != null and bool(GameState.flags.get("ascended_true_immortal", false))
