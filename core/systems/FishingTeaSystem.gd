class_name FishingTeaSystem
extends RefCounted

## 灵潭清茗：化神初期解锁的轻量后台垂钓与洞府烹茶系统。
## 状态只写入 GameState.flags["fishing_tea"]，不新增存档外层字段。

const STATE_KEY: String = "fishing_tea"
const UNLOCK_REALM_INDEX: int = 18
const ROD_INTERVAL: float = 12.0
const MAX_OFFLINE_RODS: int = 120
const TEA_DURATION: int = 3600
const BREW_SECONDS: float = 3.0
const MAX_LOGS: int = 8

const WUDAO_HERBS: Array[String] = [
	"item_qingye", "item_ninglu", "item_ziyun", "item_jiuye",
	"item_longxue", "item_taiyi_lian", "item_hundun_flower", "item_hongmeng_herb",
]
const NINGSHEN_HERBS: Array[String] = [
	"item_jiuye", "item_longxue", "item_taiyi_lian",
	"item_hundun_flower", "item_hongmeng_herb",
]
const RARE_SEEDS: Array[String] = ["seed_taiyi", "seed_longxue", "seed_hundun", "seed_hongmeng"]

## 灵鱼养神汤旧 ID 保持兼容，fish_soup 只作为外部别名。
const TEA_ALIASES: Dictionary = {"fish_soup": "lingyu_tea"}

const TEAS: Dictionary = {
	"wudao_tea": {
		"name": "悟道清茶",
		"icon": "tea_wudao", "min_realm": 18,
		"dew": 3, "herb_id": "item_ninglu", "herb_count": 20,
		"herbs": ["item_ninglu"],
		"effect": "百艺悟道池充能 +25%",
		"bonus_key": "pool_charge", "bonus": 0.25,
	},
	"ningshen_tea": {
		"name": "凝神灵茶",
		"icon": "tea_ningshen", "min_realm": 20,
		"dew": 3, "herb_id": "item_jiuye", "herb_count": 8,
		"herbs": ["item_jiuye"],
		"effect": "吐纳修为获取 +15%",
		"bonus_key": "meditate_cultivation", "bonus": 0.15,
	},
	"poe_tea": {
		"name": "破厄剑茶",
		"icon": "tea_poe", "min_realm": 21,
		"dew": 4, "herb_id": "item_longxue", "herb_count": 8,
		"herbs": ["item_longxue"],
		"effect": "秘境与镇魔塔攻击伤害 +12%",
		"bonus_key": "combat_damage", "bonus": 0.12,
	},
	"lingyu_tea": {
		"name": "灵鱼养神汤",
		"icon": "tea_fish_soup", "min_realm": 23,
		"dew": 2, "fish": 2, "herb_id": "item_taiyi_lian", "herb_count": 5,
		"herbs": ["item_taiyi_lian"],
		"effect": "全百艺经验与火候 +12% · 动作耗时 -5%",
		"bonus_key": "skill_gain", "bonus": 0.12,
		"mastery_bonus": 0.12, "action_interval": -0.05,
	},
}


static func normalize_tea_id(tea_id: String) -> String:
	return String(TEA_ALIASES.get(tea_id, tea_id))


static func default_state() -> Dictionary:
	return {
		"fishing_active": false,
		"fish_timer": 0.0,
		"active_tea_id": "",
		"tea_expire_unix": 0,
		"brewed_teas": [],
		"pity_dew_count": 0,
		"pending_tea_id": "",
		"pending_tea_ready_unix": 0,
		"recent_logs": [],
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
	state["fishing_active"] = bool(saved.get("fishing_active", false))
	state["fish_timer"] = clampf(float(saved.get("fish_timer", 0.0)), 0.0, ROD_INTERVAL)
	var tea_id := normalize_tea_id(str(saved.get("active_tea_id", "")))
	state["active_tea_id"] = tea_id if TEAS.has(tea_id) else ""
	state["tea_expire_unix"] = maxi(0, int(saved.get("tea_expire_unix", 0)))
	var brewed: Array = []
	var raw_brewed: Variant = saved.get("brewed_teas", [])
	if typeof(raw_brewed) == TYPE_ARRAY:
		for value in (raw_brewed as Array):
			var brew_id := normalize_tea_id(str(value))
			if TEAS.has(brew_id) and not brewed.has(brew_id):
				brewed.append(brew_id)
	state["brewed_teas"] = brewed
	state["pity_dew_count"] = clampi(int(saved.get("pity_dew_count", 0)), 0, 9)
	var pending_id := normalize_tea_id(str(saved.get("pending_tea_id", "")))
	state["pending_tea_id"] = pending_id if TEAS.has(pending_id) else ""
	state["pending_tea_ready_unix"] = maxi(0, int(saved.get("pending_tea_ready_unix", 0)))
	var logs: Array = []
	var raw_logs: Variant = saved.get("recent_logs", [])
	if typeof(raw_logs) == TYPE_ARRAY:
		for value in (raw_logs as Array):
			if typeof(value) == TYPE_DICTIONARY:
				var entry: Dictionary = value
				logs.append({
					"text": str(entry.get("text", "")),
					"rare": bool(entry.get("rare", false)),
					"tone": _normalize_log_tone(str(entry.get("tone", ""))),
				})
			elif str(value) != "":
				logs.append({"text": str(value), "rare": false, "tone": "plain"})
			if logs.size() >= MAX_LOGS:
				break
	state["recent_logs"] = logs
	var resolved := _resolve_pending_tea(state)
	flags[STATE_KEY] = state
	if resolved:
		commit_state(state)
	return state


static func commit_state(state: Dictionary) -> void:
	if GameState == null:
		return
	var flags: Dictionary = GameState.flags
	flags[STATE_KEY] = state
	EventBus.inventory_changed.emit()
	EventBus.stats_changed.emit()
	if SaveManager != null and SaveManager.has_method("save_game"):
		SaveManager.call("save_game", false)


static func resolve_pending_tea() -> bool:
	if GameState == null:
		return false
	var flags: Dictionary = GameState.flags
	var raw: Variant = flags.get(STATE_KEY, null)
	if typeof(raw) != TYPE_DICTIONARY:
		return false
	var state: Dictionary = raw
	var changed := _resolve_pending_tea(state)
	if changed:
		commit_state(state)
	return changed


static func _resolve_pending_tea(state: Dictionary) -> bool:
	var pending_id := normalize_tea_id(str(state.get("pending_tea_id", "")))
	if pending_id == "":
		return false
	if not TEAS.has(pending_id):
		state["pending_tea_id"] = ""
		state["pending_tea_ready_unix"] = 0
		return true
	if int(state.get("pending_tea_ready_unix", 0)) > Time.get_unix_time_from_system():
		return false
	state["active_tea_id"] = pending_id
	state["tea_expire_unix"] = Time.get_unix_time_from_system() + TEA_DURATION
	state["pending_tea_id"] = ""
	state["pending_tea_ready_unix"] = 0
	var brewed: Array = state.get("brewed_teas", [])
	if not brewed.has(pending_id):
		brewed.append(pending_id)
	state["brewed_teas"] = brewed
	return true


static func is_unlocked() -> bool:
	return GameState != null and GameState.get_realm_index() >= UNLOCK_REALM_INDEX


static func get_brewed_teas() -> Array[String]:
	var out: Array[String] = []
	for value in (get_state().get("brewed_teas", []) as Array):
		out.append(str(value))
	return out


static func is_tea_brewed(tea_id: String) -> bool:
	return get_brewed_teas().has(normalize_tea_id(tea_id))


static func is_tea_unlocked(tea_id: String) -> bool:
	var key := normalize_tea_id(tea_id)
	if not TEAS.has(key):
		return false
	return GameState != null and GameState.get_realm_index() >= int(TEAS[key].get("min_realm", 18))


static func get_tea_unlock_label(tea_id: String) -> String:
	var key := normalize_tea_id(tea_id)
	if not TEAS.has(key):
		return "尚未开启"
	var index := int(TEAS[key].get("min_realm", 18))
	if index < 0 or index >= DataRegistry.realm_order.size():
		return "尚未开启"
	var realm := DataRegistry.get_realm(str(DataRegistry.realm_order[index]))
	return "需%s" % (realm.display_name if realm != null else "尚未开启")


static func _normalize_log_tone(tone: String) -> String:
	match tone:
		"jade", "gold":
			return tone
		_:
			return "plain"


static func refresh_expired() -> bool:
	var state := get_state()
	var tea_id := str(state.get("active_tea_id", ""))
	if tea_id == "":
		return false
	if int(state.get("tea_expire_unix", 0)) > Time.get_unix_time_from_system():
		return false
	state["active_tea_id"] = ""
	state["tea_expire_unix"] = 0
	if GameState != null:
		var flags: Dictionary = GameState.flags
		flags[STATE_KEY] = state
	EventBus.stats_changed.emit()
	return true


static func get_bonus(key: String) -> float:
	refresh_expired()
	var state := get_state()
	var tea_id := str(state.get("active_tea_id", ""))
	if not TEAS.has(tea_id):
		return 0.0
	var tea: Dictionary = TEAS[tea_id]
	if key == "mastery_gain" and tea.has("mastery_bonus"):
		return float(tea.get("mastery_bonus", 0.0))
	if key == "action_interval" and tea.has("action_interval"):
		return float(tea.get("action_interval", 0.0))
	if str(tea.get("bonus_key", "")) != key:
		return 0.0
	return float(tea.get("bonus", 0.0))


static func get_active_tea_info() -> Dictionary:
	refresh_expired()
	var state := get_state()
	var tea_id := str(state.get("active_tea_id", ""))
	if not TEAS.has(tea_id):
		return {}
	var tea: Dictionary = TEAS[tea_id]
	var remain := maxi(0, int(state.get("tea_expire_unix", 0)) - Time.get_unix_time_from_system())
	return {
		"id": tea_id,
		"name": str(tea.get("name", "")),
		"icon": str(tea.get("icon", "tea_pot")),
		"effect": str(tea.get("effect", "")),
		"remain": remain,
		"text": "%s生效中 · 余 %d 分 %d 秒" % [
			str(tea.get("name", "")), remain / 60, remain % 60],
	}


static func is_fishing_active() -> bool:
	var state := get_state()
	return bool(state.get("fishing_active", false))


static func toggle_fishing() -> bool:
	if not is_unlocked():
		return false
	var state := get_state()
	state["fishing_active"] = not bool(state.get("fishing_active", false))
	commit_state(state)
	return bool(state["fishing_active"])


static func tick(delta: float) -> void:
	if delta <= 0.0 or GameState == null or not is_unlocked():
		return
	refresh_expired()
	var state := get_state()
	if not bool(state.get("fishing_active", false)):
		return
	var timer := clampf(float(state.get("fish_timer", 0.0)) + delta, 0.0, ROD_INTERVAL)
	var rods := int(floor(timer / ROD_INTERVAL))
	if rods <= 0:
		state["fish_timer"] = timer
		return
	timer -= float(rods) * ROD_INTERVAL
	state["fish_timer"] = timer
	_process_rods(state, rods)
	commit_state(state)


static func settle_offline(seconds: float) -> Dictionary:
	if seconds <= 0.0 or GameState == null or not is_unlocked():
		return {}
	refresh_expired()
	var state := get_state()
	if not bool(state.get("fishing_active", false)):
		return {}
	var timer := maxf(0.0, float(state.get("fish_timer", 0.0)) + seconds)
	var rods := mini(MAX_OFFLINE_RODS, int(floor(timer / ROD_INTERVAL)))
	if rods <= 0:
		state["fish_timer"] = minf(timer, ROD_INTERVAL)
		return {}
	state["fish_timer"] = clampf(timer - float(rods) * ROD_INTERVAL, 0.0, ROD_INTERVAL)
	var result := _process_rods(state, rods)
	result["rods"] = rods
	commit_state(state)
	return result


static func _process_rods(state: Dictionary, rods: int) -> Dictionary:
	var gained: Dictionary = {}
	var pool_gains: Dictionary = {}
	var pity := clampi(int(state.get("pity_dew_count", 0)), 0, 9)
	for _i in range(rods):
		var forced_surprise := pity >= 9
		var roll := randi() % 100
		if forced_surprise:
			roll = 32 + randi() % 68
		if roll < 32:
			_gain_item(gained, "item_spirit_dew", 1)
			_add_log(state, "灵潭收竿：灵潭清露 ×1", false, "plain")
			pity = mini(9, pity + 1)
			continue
		pity = 0
		if roll < 52:
			_gain_item(gained, "item_spirit_fish", 1)
			_add_log(state, "灵潭收竿：碧波灵鱼 ×1", false, "jade")
		elif roll < 68:
			var amount := _reward_amount(25, 55)
			_gain_item(gained, DataRegistry.SPIRIT_STONE, amount)
			_add_log(state, "灵潭收竿：灵石 ×%d" % amount, false, "jade")
		elif roll < 78:
			var herbs := ["item_jiuye", "item_longxue", "item_taiyi_lian"]
			var herb_id := str(herbs[randi() % herbs.size()])
			var count := randi_range(1, 2)
			_gain_item(gained, herb_id, count)
			_add_log(state, "潭边漂流灵草：%s ×%d" % [
				DataRegistry.get_item_name(herb_id), count], false, "jade")
		elif roll < 86:
			_gain_pool(state, pool_gains)
		elif roll < 92:
			var seed_id := str(RARE_SEEDS[randi() % RARE_SEEDS.size()])
			_gain_item(gained, seed_id, 1)
			_add_log(state, "古修灵种：%s ×1" % DataRegistry.get_item_name(seed_id),
				true, "gold")
		elif roll < 97:
			var relic := _random_relic()
			_gain_item(gained, relic, 1)
			_add_log(state, "秘境残宝：%s ×1" % DataRegistry.get_item_name(relic),
				true, "gold")
		else:
			_gain_grand_discovery(state, gained, pool_gains)
	state["pity_dew_count"] = pity
	return {"items": gained, "pool": pool_gains, "rods": rods, "pity": pity}


static func _reward_amount(min_value: int, max_value: int) -> int:
	return maxi(1, int(round(GameState.get_realm_reward_mult()
		* float(randi_range(min_value, max_value)))))


static func _random_relic() -> String:
	var relics := ["item_ancient_soul", "item_dragon_scale", "item_huashen_note"]
	return str(relics[randi() % relics.size()])


static func _preferred_skill() -> String:
	for slot in range(GameState.SLOT_COUNT):
		var action_id := str(GameState.active_slots[slot])
		if action_id == "":
			continue
		var action := DataRegistry.get_action(action_id)
		if action != null and action.skill_id != "combat":
			return action.skill_id
	var candidates: Array[String] = []
	for skill_id in DataRegistry.skill_order:
		var sid := str(skill_id)
		if sid != "combat" and GameState.get_skill_level(sid) > 1:
			candidates.append(sid)
	if candidates.is_empty():
		return ""
	return candidates[randi() % candidates.size()]


static func _gain_pool(state: Dictionary, pool_gains: Dictionary) -> void:
	var skill_id := _preferred_skill()
	if skill_id == "":
		var stones := _reward_amount(30, 50)
		GameState.add_item(DataRegistry.SPIRIT_STONE, stones)
		_add_log(state, "灵潭悟道：清露化灵石 ×%d" % stones, false, "jade")
		return
	var amount := float(_reward_amount(120, 220))
	GameState.add_pool_xp(skill_id, amount)
	pool_gains[skill_id] = float(pool_gains.get(skill_id, 0.0)) + amount
	_add_log(state, "灵潭悟道：%s悟道池 +%d" % [
		DataRegistry.get_skill_name(skill_id), int(amount)], false, "jade")


static func _gain_grand_discovery(state: Dictionary, gained: Dictionary,
		pool_gains: Dictionary) -> void:
	var stones := _reward_amount(300, 600)
	var seed_id := str(RARE_SEEDS[randi() % RARE_SEEDS.size()])
	var relic := _random_relic()
	_gain_item(gained, DataRegistry.SPIRIT_STONE, stones)
	_gain_item(gained, seed_id, 1)
	_gain_item(gained, relic, 1)
	_add_log(state, "古修漂流玉简：灵石 ×%d · %s ×1 · %s ×1" % [
		stones, DataRegistry.get_item_name(seed_id), DataRegistry.get_item_name(relic)],
		true, "gold")


static func _gain_item(gained: Dictionary, item_id: String, amount: int) -> void:
	if amount <= 0:
		return
	GameState.add_item(item_id, amount)
	gained[item_id] = int(gained.get(item_id, 0)) + amount


static func _add_log(state: Dictionary, text: String, rare: bool,
		tone: String = "plain") -> void:
	var logs: Variant = state.get("recent_logs", [])
	var list: Array = logs if logs is Array else []
	list.insert(0, {"text": text, "rare": rare, "tone": _normalize_log_tone(tone)})
	while list.size() > MAX_LOGS:
		list.remove_at(list.size() - 1)
	state["recent_logs"] = list


static func _best_herb(herbs: Array, count: int) -> String:
	var best := ""
	var best_count := 0
	for value in herbs:
		var item_id := str(value)
		var have := GameState.get_item_count(item_id)
		if have >= count and have > best_count:
			best = item_id
			best_count = have
	return best


static func brew_tea(tea_id: String, _legacy_herb_id: String = "") -> Dictionary:
	var key := normalize_tea_id(tea_id)
	if not is_unlocked() or not TEAS.has(key):
		return {"ok": false, "message": "当前无法烹煮此灵茶"}
	if not is_tea_unlocked(key):
		return {"ok": false, "message": get_tea_unlock_label(key)}
	resolve_pending_tea()
	refresh_expired()
	var state := get_state()
	if str(state.get("pending_tea_id", "")) != "":
		return {"ok": false, "message": "文火慢煎中，请稍候"}
	var tea: Dictionary = TEAS[key]
	var dew := int(tea.get("dew", 0))
	var herb_id := str(tea.get("herb_id", ""))
	var herb_count := int(tea.get("herb_count", 0))
	var fish_count := int(tea.get("fish", 0))
	if GameState.get_item_count("item_spirit_dew") < dew:
		return {"ok": false, "message": "灵潭清露不足"}
	if fish_count > 0 and GameState.get_item_count("item_spirit_fish") < fish_count:
		return {"ok": false, "message": "碧波灵鱼不足"}
	if herb_id != "" and GameState.get_item_count(herb_id) < herb_count:
		return {"ok": false, "message": "%s不足" % DataRegistry.get_item_name(herb_id)}
	GameState.remove_item("item_spirit_dew", dew)
	if fish_count > 0:
		GameState.remove_item("item_spirit_fish", fish_count)
	if herb_id != "":
		GameState.remove_item(herb_id, herb_count)
	state["pending_tea_id"] = key
	state["pending_tea_ready_unix"] = int(Time.get_unix_time_from_system()) + int(BREW_SECONDS)
	commit_state(state)
	return {"ok": true, "pending": true, "seconds": BREW_SECONDS,
		"message": "文火慢煎中…"}
