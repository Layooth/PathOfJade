extends Node
## 「仙盟悬赏」：常驻 3 个悬赏令（物资征集 / 妖兽清剿），提交得灵石 + 仙盟贡献 + 技能经验。

const SLOT_COUNT: int = 3
const FREE_REFRESH_SECONDS: float = 1800.0
const DAILY_BOUNTY_LIMIT: int = 10
const SUBMIT_MATERIAL: String = "material"
const SUBMIT_KILL: String = "kill"
const TRACK_GATHER: String = "gather"
const TRACK_CRAFT: String = "craft"

## 各境界可用的物资悬赏池：item_id -> 基准需求数量 / 采集制造双轨 / 境界层
const MATERIAL_POOL: Array = [
	# ---- 炼气：采集
	{"item": "item_qingye", "amount": 60, "tier": 0, "track": TRACK_GATHER},
	{"item": "item_ninglu", "amount": 25, "tier": 0, "track": TRACK_GATHER},
	{"item": "item_qingling_wood", "amount": 50, "tier": 0, "track": TRACK_GATHER},
	{"item": "item_crude_iron", "amount": 40, "tier": 0, "track": TRACK_GATHER},
	{"item": "item_cuiyun_wood", "amount": 25, "tier": 0, "track": TRACK_GATHER},
	{"item": "item_qinggang_ore", "amount": 20, "tier": 0, "track": TRACK_GATHER},
	# ---- 炼气：制造
	{"item": "item_qi_pill", "amount": 8, "tier": 0, "track": TRACK_CRAFT},
	{"item": "item_heal_powder", "amount": 15, "tier": 0, "track": TRACK_CRAFT},
	{"item": "equip_iron_sword", "amount": 1, "tier": 0, "track": TRACK_CRAFT},
	{"item": "equip_iron_robe", "amount": 1, "tier": 0, "track": TRACK_CRAFT},
	{"item": "item_earth_talisman", "amount": 6, "tier": 0, "track": TRACK_CRAFT},
	{"item": "item_fireball_talisman", "amount": 6, "tier": 0, "track": TRACK_CRAFT},
	# ---- 筑基
	{"item": "item_ziyun", "amount": 150, "tier": 1, "track": TRACK_GATHER},
	{"item": "item_mithril", "amount": 90, "tier": 1, "track": TRACK_GATHER},
	{"item": "item_turtle_talisman", "amount": 15, "tier": 1, "track": TRACK_CRAFT},
	{"item": "item_big_heal", "amount": 20, "tier": 1, "track": TRACK_CRAFT},
	# ---- 金丹
	{"item": "item_hansui", "amount": 200, "tier": 2, "track": TRACK_GATHER},
	{"item": "item_stariron", "amount": 120, "tier": 2, "track": TRACK_GATHER},
	{"item": "item_gold_pill", "amount": 20, "tier": 2, "track": TRACK_CRAFT},
	{"item": "item_taiji_talisman", "amount": 12, "tier": 2, "track": TRACK_CRAFT},
	# ---- 元婴
	{"item": "item_xinghui", "amount": 160, "tier": 3, "track": TRACK_GATHER},
	{"item": "item_primordial_crystal", "amount": 80, "tier": 3, "track": TRACK_GATHER},
	{"item": "item_heart_pill", "amount": 25, "tier": 3, "track": TRACK_CRAFT},
]

const KILL_AMOUNTS: Array = [10, 15, 20, 25]
const BASE_POINTS: int = 20
const SKILL_XP_BASE: float = 180.0


func _ready() -> void:
	EventBus.combat_enemy_defeated.connect(_on_enemy_defeated)


func _now() -> float:
	return Time.get_unix_time_from_system()


func _today_key() -> String:
	var date: Dictionary = Time.get_datetime_dict_from_unix_time(int(_now()))
	return "%04d-%02d-%02d" % [int(date.get("year", 0)),
		int(date.get("month", 0)), int(date.get("day", 0))]


func _daily_state() -> Dictionary:
	var flags: Dictionary = GameState.flags
	var today := _today_key()
	var raw: Variant = flags.get("bounty_daily", null)
	if typeof(raw) != TYPE_DICTIONARY:
		var fresh := {"day": today, "count": 0}
		flags["bounty_daily"] = fresh
		return fresh
	var saved: Dictionary = raw
	if str(saved.get("day", "")) != today:
		saved["day"] = today
		saved["count"] = 0
	flags["bounty_daily"] = saved
	return saved


func daily_count() -> int:
	return int(_daily_state().get("count", 0))


func daily_limit_reached() -> bool:
	return daily_count() >= DAILY_BOUNTY_LIMIT


func _increment_daily() -> void:
	var saved := _daily_state()
	saved["count"] = mini(DAILY_BOUNTY_LIMIT, int(saved.get("count", 0)) + 1)


func _recent_keys() -> Array[String]:
	var out: Array[String] = []
	var flags: Dictionary = GameState.flags
	var raw: Variant = flags.get("bounty_recent", [])
	if typeof(raw) != TYPE_ARRAY:
		return out
	for value in (raw as Array):
		var key := str(value)
		if key != "":
			out.append(key)
	while out.size() > 3:
		out.remove_at(0)
	return out


func _remember_key(key: String) -> void:
	if key == "":
		return
	var recent := _recent_keys()
	if recent.has(key):
		recent.erase(key)
	recent.append(key)
	while recent.size() > 3:
		recent.remove_at(0)
	var flags: Dictionary = GameState.flags
	flags["bounty_recent"] = recent


# ---------------------------------------------------------------- 生成 / 刷新

func ensure_bounties() -> void:
	var bounties: Array = GameState.active_bounties
	var changed := bounties.size() != SLOT_COUNT
	if not changed:
		for value in bounties:
			if not (value is Dictionary) or String((value as Dictionary).get("id", "")) == "":
				changed = true
				break
	if changed:
		GameState.active_bounties.clear()
		var recent := _recent_keys()
		for i in range(SLOT_COUNT):
			var bounty := _roll_bounty(i, _current_keys(), recent)
			GameState.active_bounties.append(bounty)
			_remember_key(String(bounty.get("key", "")))
			recent = _recent_keys()
		EventBus.bounty_changed.emit()
		return
	# 旧存档里的溢出进度直接钳制，不改动任务类型与奖励
	for i in range(GameState.active_bounties.size()):
		var bounty: Dictionary = GameState.active_bounties[i]
		if String(bounty.get("type", "")) != SUBMIT_KILL:
			continue
		bounty["progress"] = mini(maxi(0, int(bounty.get("remaining", 1))),
			maxi(0, int(bounty.get("progress", 0))))
		GameState.active_bounties[i] = bounty


func _current_keys() -> Array:
	var out: Array = []
	for value in GameState.active_bounties:
		if value is Dictionary:
			var key := String((value as Dictionary).get("key", ""))
			if key != "":
				out.append(key)
	return out


func _material_key(item_id: String) -> String:
	return "m_%s" % item_id


func _kill_key(enemy_id: String) -> String:
	return "k_%s" % enemy_id


func _roll_bounty(index: int, exclude: Array = [], recent: Array = []) -> Dictionary:
	var tier := _player_tier()
	var preferred := TRACK_GATHER if index == 0 else (TRACK_CRAFT if index == 1 else SUBMIT_KILL)
	var bounty := _roll_preferred(tier, preferred, exclude, recent)
	if bounty.is_empty():
		for fallback in [TRACK_GATHER, TRACK_CRAFT, SUBMIT_KILL]:
			bounty = _roll_preferred(tier, String(fallback), exclude, recent)
			if not bounty.is_empty():
				break
	if bounty.is_empty():
		bounty = _roll_material(tier, "", exclude, [])
	if bounty.is_empty():
		bounty = {"type": SUBMIT_MATERIAL, "key": "m_item_qingye",
			"title": "物资征集令", "target_id": "item_qingye",
			"target_name": DataRegistry.get_item_name("item_qingye"),
			"skill": "herbalism", "remaining": 30, "enemy_id": "", "stones": 60,
			"points": 20, "xp": SKILL_XP_BASE}
	bounty["id"] = "%s_%d_%d" % [bounty.get("key", "b"), int(_now()), index]
	bounty["created"] = int(_now())
	return bounty


func _roll_preferred(tier: int, preferred: String, exclude: Array, recent: Array) -> Dictionary:
	match preferred:
		TRACK_GATHER:
			return _roll_material(tier, TRACK_GATHER, exclude, recent)
		TRACK_CRAFT:
			return _roll_material(tier, TRACK_CRAFT, exclude, recent)
		SUBMIT_KILL:
			return _roll_kill(tier, exclude, recent)
	return {}


func _material_candidates(tier: int, track: String = "") -> Array:
	var out: Array = []
	for value in MATERIAL_POOL:
		var entry: Dictionary = value
		if int(entry.get("tier", 0)) != tier:
			continue
		if track != "" and String(entry.get("track", "")) != track:
			continue
		out.append(entry)
	if out.is_empty():
		for value in MATERIAL_POOL:
			var entry: Dictionary = value
			if int(entry.get("tier", 0)) > tier:
				continue
			if track != "" and String(entry.get("track", "")) != track:
				continue
			out.append(entry)
	return out


func _filter_material_pool(pool: Array, exclude: Array, recent: Array) -> Array:
	var out: Array = []
	for value in pool:
		var entry: Dictionary = value
		var item_id := String(entry.get("item", ""))
		var key := _material_key(item_id)
		if exclude.has(key) or recent.has(key):
			continue
		var skill_id := _skill_for_item_id(item_id)
		if not _item_unlocked(item_id, skill_id):
			continue
		out.append(entry)
	return out


func _item_unlocked(item_id: String, skill_id: String) -> bool:
	var grade := DataRegistry.get_item_grade(item_id)
	var need := int(grade.get("unlock_level", 9999))
	var item := DataRegistry.get_item(item_id)
	if item != null and item.category == ItemData.Category.EQUIPMENT:
		need = mini(need, DataRegistry.get_equipment_unlock_level(item_id))
	return need <= maxi(1, GameState.get_skill_level(skill_id))


func _weight_of(entry: Dictionary) -> float:
	if String(entry.get("track", "")) != TRACK_GATHER:
		return 1.0
	return 0.25 if GameState.get_item_count(String(entry.get("item", ""))) >= 500 else 1.0


func _pick_weighted(pool: Array) -> Dictionary:
	var total := 0.0
	for value in pool:
		total += _weight_of(value as Dictionary)
	if total <= 0.0:
		return {}
	var roll := randf() * total
	for value in pool:
		var entry: Dictionary = value
		roll -= _weight_of(entry)
		if roll <= 0.0:
			return entry
	return pool[pool.size() - 1]


func _roll_material(tier: int, track: String = "", exclude: Array = [],
		recent: Array = []) -> Dictionary:
	var pool := _material_candidates(tier, track)
	var filtered := _filter_material_pool(pool, exclude, recent)
	if filtered.is_empty():
		filtered = _filter_material_pool(pool, exclude, [])
	if filtered.is_empty():
		filtered = pool
	if filtered.is_empty():
		return {}
	var pick := _pick_weighted(filtered)
	if pick.is_empty():
		return {}
	var item_id := String(pick.get("item", ""))
	var entry_track := String(pick.get("track", TRACK_GATHER))
	var amount := int(round(float(pick.get("amount", 1)) * randf_range(0.85, 1.15)))
	var points := int(mini(120, BASE_POINTS + 25 * tier))
	var stones := int(round(60.0 * (1.0 + 0.25 * float(tier))))
	var is_urgent := false
	var is_clearance := false
	if entry_track == TRACK_CRAFT and randf() < 0.25:
		is_urgent = true
		stones = int(round(float(stones) * 1.4))
		points = 30
	if entry_track == TRACK_GATHER and GameState.get_item_count(item_id) >= 500 \
			and randf() < 0.30:
		is_clearance = true
		amount = maxi(1, int(round(float(amount) * 1.5)))
		points = mini(120, points + 5)
	var item := DataRegistry.get_item(item_id)
	var item_name := item_id if item == null else item.display_name
	var skill_id := _skill_for_item_id(item_id)
	return {
		"type": SUBMIT_MATERIAL,
		"key": _material_key(item_id),
		"title": "物资征集令",
		"target_id": item_id,
		"target_name": item_name,
		"skill": skill_id,
		"track": entry_track,
		"remaining": maxi(1, amount),
		"enemy_id": "",
		"stones": stones,
		"points": points,
		"xp": SKILL_XP_BASE * (1.0 + 0.8 * float(tier)),
		"is_urgent": is_urgent,
		"is_clearance": is_clearance,
	}


func _roll_kill(tier: int, exclude: Array = [], recent: Array = []) -> Dictionary:
	var enemies: Array = []
	for enemy_id in DataRegistry.enemies.keys():
		if GameState.enemy_lock_reason(str(enemy_id)) != "":
			continue
		var enemy := DataRegistry.get_enemy(str(enemy_id)) as EnemyData
		if enemy == null:
			continue
		var region: Dictionary = DataRegistry.regions.get(enemy.region_id, {})
		var region_tier := int(region.get("required_tier", 0))
		if region_tier > tier or region_tier < maxi(0, tier - 2):
			continue
		enemies.append(enemy)
	if enemies.is_empty():
		for enemy_id in DataRegistry.enemies.keys():
			if GameState.enemy_lock_reason(str(enemy_id)) == "":
				var fallback := DataRegistry.get_enemy(str(enemy_id)) as EnemyData
				if fallback != null:
					enemies.append(fallback)
	var filtered: Array = []
	for enemy in enemies:
		var key := _kill_key((enemy as EnemyData).id)
		if exclude.has(key) or recent.has(key):
			continue
		filtered.append(enemy)
	if filtered.is_empty():
		filtered = enemies
	if filtered.is_empty():
		return {}
	var picked: EnemyData = filtered[randi() % filtered.size()]
	var amount := int(KILL_AMOUNTS[mini(tier, KILL_AMOUNTS.size() - 1)]
		* randf_range(0.8, 1.2))
	return {
		"type": SUBMIT_KILL,
		"key": _kill_key(picked.id),
		"title": "妖兽清剿令",
		"target_id": picked.id,
		"target_name": picked.display_name,
		"skill": "combat",
		"remaining": maxi(1, amount),
		"progress": 0,
		"enemy_id": picked.id,
		"stones": int(round(75.0 * (1.0 + 0.25 * float(tier)))),
		"points": int(mini(120, BASE_POINTS + 30 * tier)),
		"xp": SKILL_XP_BASE * 1.3 * (1.0 + 0.8 * float(tier)),
		"is_urgent": false,
		"is_clearance": false,
	}


func _skill_for_item_id(item_id: String) -> String:
	return _skill_for_item(DataRegistry.get_item(item_id))


func _skill_for_item(item: ItemData) -> String:
	if item == null:
		return "herbalism"
	match item.category:
		ItemData.Category.EQUIPMENT:
			return "forging"
		ItemData.Category.CONSUMABLE:
			if item.ward_ratio > 0.0:
				return "talisman"
			return "alchemy"
		_:
			return "herbalism"


func _player_tier() -> int:
	var realm := GameState.get_realm()
	return 0 if realm == null else realm.tier


# ---------------------------------------------------------------- 进度 / 提交

func get_progress(bounty: Dictionary) -> int:
	if String(bounty.get("type", "")) == SUBMIT_KILL:
		var target := maxi(0, int(bounty.get("remaining", 1)))
		return mini(target, maxi(0, int(bounty.get("progress", 0))))
	return GameState.get_item_count(String(bounty.get("target_id", "")))


func can_submit(bounty: Dictionary) -> bool:
	if daily_limit_reached():
		return false
	return get_progress(bounty) >= int(bounty.get("remaining", 1))


func _bonus_drop_id() -> String:
	var seeds: Array = []
	for seed_key in DataRegistry.farm_seeds.keys():
		var seed: Dictionary = DataRegistry.farm_seeds[seed_key]
		var tier := int(DataRegistry.get_material_grade(
			String(seed.get("crop_id", ""))).get("tier", 1))
		if tier >= 3:
			seeds.append(String(seed_key))
	if not seeds.is_empty() and randf() < 0.5:
		return String(seeds[randi() % seeds.size()])
	return DataRegistry.SPIRIT_DEW


func submit(index: int) -> bool:
	if index < 0 or index >= GameState.active_bounties.size():
		return false
	if daily_limit_reached():
		EventBus.toast.emit("今日赏格已尽 (%d/%d)" % [DAILY_BOUNTY_LIMIT, DAILY_BOUNTY_LIMIT])
		return false
	var bounty: Dictionary = GameState.active_bounties[index]
	if not can_submit(bounty):
		EventBus.toast.emit("进度不足：%s" % _progress_text(bounty))
		return false
	var need := int(bounty.get("remaining", 1))
	if String(bounty.get("type", "")) == SUBMIT_MATERIAL:
		GameState.remove_item(String(bounty.get("target_id", "")), need)
	var stones := int(round(float(bounty.get("stones", 0)) * GameState.get_realm_reward_mult()))
	GameState.add_item(DataRegistry.SPIRIT_STONE, stones)
	GameState.alliance_points += int(bounty.get("points", 0))
	GameState.bounties_done += 1
	_increment_daily()
	_remember_key(String(bounty.get("key", "")))
	var skill_id := String(bounty.get("skill", "herbalism"))
	GameState.add_skill_xp(skill_id, float(bounty.get("xp", 0.0)))
	var bonus_text := ""
	if randf() < 0.25:
		var bonus_id := _bonus_drop_id()
		GameState.add_item(bonus_id, 1)
		bonus_text = "，机缘附赠 %s ×1" % DataRegistry.get_item_name(bonus_id)
	GameState.push_activity_log("悬赏达成：%s · 贡献 +%d%s" % [
		String(bounty.get("target_name", "")), int(bounty.get("points", 0)), bonus_text], "gold")
	EventBus.toast.emit("悬赏达成，贡献 +%d，灵石 %s%s" % [
		int(bounty.get("points", 0)), GameFormulas.format_num(float(stones)), bonus_text])
	var recent := _recent_keys()
	GameState.active_bounties[index] = _roll_bounty(index, _current_keys(), recent)
	_remember_key(String((GameState.active_bounties[index] as Dictionary).get("key", "")))
	EventBus.bounty_changed.emit()
	EventBus.stats_changed.emit()
	GameState.vibrate_light()
	if AudioManager != null:
		AudioManager.play_coin()
	SaveManager.save_game(false)
	return true


func _on_enemy_defeated(enemy_id: String, _loot: Dictionary) -> void:
	var changed := false
	for i in range(GameState.active_bounties.size()):
		var bounty: Dictionary = GameState.active_bounties[i]
		if String(bounty.get("type", "")) != SUBMIT_KILL:
			continue
		if String(bounty.get("enemy_id", "")) != enemy_id:
			continue
		var target := maxi(0, int(bounty.get("remaining", 1)))
		bounty["progress"] = mini(target, maxi(0, int(bounty.get("progress", 0))) + 1)
		GameState.active_bounties[i] = bounty
		changed = true
	if changed:
		EventBus.bounty_changed.emit()


func add_offline_kills(enemy_id: String, amount: int) -> void:
	if amount <= 0:
		return
	var changed := false
	for i in range(GameState.active_bounties.size()):
		var bounty: Dictionary = GameState.active_bounties[i]
		if String(bounty.get("type", "")) != SUBMIT_KILL:
			continue
		if String(bounty.get("enemy_id", "")) != enemy_id:
			continue
		var target := maxi(0, int(bounty.get("remaining", 1)))
		bounty["progress"] = mini(target, maxi(0, int(bounty.get("progress", 0))) + amount)
		GameState.active_bounties[i] = bounty
		changed = true
	if changed:
		EventBus.bounty_changed.emit()


# ---------------------------------------------------------------- 刷新

func free_refresh_remaining() -> float:
	var ready_at := GameState.bounty_free_refresh_unix
	return maxf(0.0, ready_at - _now())


func can_free_refresh() -> bool:
	return free_refresh_remaining() <= 0.0


func free_refresh_all() -> bool:
	if not can_free_refresh():
		EventBus.toast.emit("免费刷新冷却中：%s" % GameFormulas.format_duration(free_refresh_remaining()))
		return false
	GameState.bounty_free_refresh_unix = _now() + FREE_REFRESH_SECONDS
	_reroll_all()
	EventBus.toast.emit("免费刷新全部悬赏")
	return true


func paid_refresh_cost() -> int:
	return int(60.0 * pow(1.65, float(_player_tier())))


func paid_refresh_all() -> bool:
	var cost := paid_refresh_cost()
	if GameState.get_item_count(DataRegistry.SPIRIT_STONE) < cost:
		EventBus.toast.emit("灵石不足：需 %d" % cost)
		return false
	GameState.remove_item(DataRegistry.SPIRIT_STONE, cost)
	_reroll_all()
	EventBus.toast.emit("已花 %d 灵石加急刷新" % cost)
	return true


func _reroll_all() -> void:
	GameState.active_bounties.clear()
	var recent := _recent_keys()
	for i in range(SLOT_COUNT):
		var bounty := _roll_bounty(i, _current_keys(), recent)
		GameState.active_bounties.append(bounty)
		_remember_key(String(bounty.get("key", "")))
		recent = _recent_keys()
	EventBus.bounty_changed.emit()
	EventBus.stats_changed.emit()


func get_progress_text(bounty: Dictionary) -> String:
	return _progress_text(bounty)


func _progress_text(bounty: Dictionary) -> String:
	var have := get_progress(bounty)
	var need := int(bounty.get("remaining", 1))
	if String(bounty.get("type", "")) == SUBMIT_KILL:
		return "已击杀 %d / %d" % [mini(have, need), need]
	return "库存 %s / %d" % [GameFormulas.format_num(float(have)), need]
