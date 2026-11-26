extends Node
## 唯一运行时状态源：背包、技能经验、火候、悟道池、装备、境界、活跃动作。
## 所有修改都通过本单例的方法进行，并抛出 EventBus 信号。

const COMBAT_MARKER: String = "__combat__"
const EQUIP_SLOTS: Array[String] = ["weapon", "armor"]
## 槽位数组固定 3 个（0 主修 / 1 分神 / 2 化身），实际可用数见 get_max_action_slots()
const SLOT_COUNT: int = 3
## 槽位元数据：文案全链路（启动 / 运转中 / 停止）只认这张表，禁止散落 if/else
const SLOT_CONFIGS: Array = [
	{"key": "main", "name": "主修", "start": "主修运转", "running": "主修中", "stop": "停止主修"},
	{"key": "second", "name": "分神", "start": "分神运转", "running": "分神中", "stop": "停止分神"},
	{"key": "third", "name": "化身", "start": "化身运转", "running": "化身中", "stop": "停止化身"},
]
const DAO_HEART_MAX: int = 5
const DEFAULT_ENEMY: String = "enemy_wild_wolf"
const BASE_ATTACK: int = 8
const BASE_DEFENSE: int = 2
const BASE_ACCURACY: float = 0.85
const BASE_ATTACK_INTERVAL: float = 2.2
## 装备品质：凡品 / 精良 / 极品
const QUALITY_MULTIPLIERS: Array[float] = [1.0, 1.2, 1.4]
const QUALITY_NAMES: Array[String] = ["凡品", "精良", "极品"]
## 祭炼开启门槛：筑基中期；旧档 equip_temper_levels 加成保持原样生效
const TEMPER_UNLOCK_ORDER: int = 10
## 与 GameFormulas 共用同一硬上限，兵刃 / 法袍各自独立封顶
const MAX_TEMPER_LEVEL: int = GameFormulas.MAX_TEMPER_LEVEL

# ---------------------------------------------------------------- 运行时状态

var inventory: Dictionary = {}
## item_id -> 精良（+20%）库存数量
var fine_items: Dictionary = {}
## item_id -> 极品（+40%）库存数量
var epic_items: Dictionary = {}
## slot -> {"id": String, "quality": int}  0 凡品 / 1 精良 / 2 极品
var equipment: Dictionary = {}
## 坊市已购商品：upgrade_id -> level（旧存档缺失时为空字典）
var purchased_upgrades: Dictionary = {}
## ---- 仙盟悬赏 ----
var alliance_points: int = 0
var bounties_done: int = 0
var active_bounties: Array = []
var bounty_free_refresh_unix: float = 0.0
## 每日镇魔俸禄领取日（UTC 天数；旧档缺字段默认 -1 表示未领）
var last_tower_salary_day: int = -1
## 本命祭炼等级（兵刃 / 法袍各自独立，封顶 50 重；旧档超上限保留收益但不再提升）
var equip_temper_levels: Dictionary = {"weapon": 0, "armor": 0}
## 渐进伪随机保底计数器（功法残卷 / 灵种伴生 / 灵田奇珍 / 锻造极品；
## 旧档缺字段默认空字典，出货即清零）
var pity_counters: Dictionary = {}
## 大境界奖励倍率（炼气 1x → 真仙 200x）：悬赏灵石与镇魔俸禄共用
const REALM_REWARD_MULT: Array = [1.0, 1.5, 3.0, 6.0, 12.0, 25.0, 50.0, 100.0, 200.0]
## 本源雷压校准：按无头满配模拟反推，随天劫阶位递减，目标单劫总掉血 45%~75%。
const TRIBULATION_SOURCE_SCALE: Array[float] = [0.0, 0.0, 0.0, 4.4, 4.1, 3.8, 3.5, 3.3, 3.2]
## ---- 藏经阁 ----
var unlocked_techniques: Array[String] = []
var equipped_techniques: Array[String] = []
var technique_levels: Dictionary = {}
var skill_xp: Dictionary = {}
var action_mastery_xp: Dictionary = {}
var mastery_pool: Dictionary = {}
var cultivation_xp: float = 0.0
var realm_id: String = "qi_1"
## 大境界序号(tier) -> 道心悟性层数（各境界独立累计，最高 5）
var dao_heart: Dictionary = {}
## 纯内存修行纪要（最多 15 条，不写入存档）
const MAX_RECENT_LOGS: int = 15
var recent_logs: Array[Dictionary] = []
## 仅移动端生效：锁定竖屏
var lock_portrait: bool = true
## 三槽：0 主修 / 1 分神 / 2 化身（实际可用数由境界 max_action_slots 决定）
var active_slots: Array[String] = ["", "", ""]
var current_hp: int = 100
var selected_enemy_id: String = DEFAULT_ENEMY
var selected_region_id: String = "wild_wolf_forest"
## 递进秘境：已击败过的敌人 ID -> true；旧档由 discovered_enemies / 境界阶层回填
var defeated_enemies: Dictionary = {}
var flags: Dictionary = {}
## 离线结算期间为 true：小境界晋升 / 悟道里程碑等不触发震动，避免回前台连震
var offline_settling: bool = false
## 百年朱果永久炼化枚数（上限 50；旧存档缺失默认 0）
var crimson_fruit_eaten: int = 0
var auto_heal_threshold: float = 0.4
var stats: Dictionary = {}


func _ready() -> void:
	reset()


# ---------------------------------------------------------------- 初始化 / 存档

func reset() -> void:
	inventory.clear()
	fine_items.clear()
	epic_items.clear()
	purchased_upgrades.clear()
	recent_logs.clear()
	lock_portrait = true
	crimson_fruit_eaten = 0
	alliance_points = 0
	bounties_done = 0
	active_bounties.clear()
	bounty_free_refresh_unix = 0.0
	unlocked_techniques.clear()
	equipped_techniques.clear()
	technique_levels.clear()
	discovered_items.clear()
	discovered_enemies.clear()
	defeated_enemies.clear()
	tower_highest_floor = 0
	tower_claimed_floors.clear()
	tower_claimed_upto = 0
	last_tower_salary_day = -1
	equip_temper_levels = {"weapon": 0, "armor": 0}
	pity_counters = {}
	equipment = {
		"weapon": {"id": "", "quality": 0},
		"armor": {"id": "", "quality": 0},
	}
	skill_xp.clear()
	action_mastery_xp.clear()
	mastery_pool.clear()
	for skill_id in DataRegistry.skill_order:
		skill_xp[skill_id] = 0.0
		mastery_pool[skill_id] = 0.0
	for action_id in DataRegistry.actions.keys():
		action_mastery_xp[String(action_id)] = 0.0
	cultivation_xp = 0.0
	realm_id = "qi_1"
	dao_heart.clear()
	active_slots = ["", "", ""]
	selected_enemy_id = DEFAULT_ENEMY
	selected_region_id = "wild_wolf_forest"
	flags = {
		"wood_fuel": true,
		"auto_pill": true,
		"auto_heal": true,
		"auto_talisman": true,
		"auto_thunder_talisman": true,
		## 震动强度：0 关闭 / 1 轻柔 / 2 适中 / 3 强劲
		"vibration_level": 2,
		"fps60": false,
		## 0 = 30 FPS / 1 = 60 FPS / 2 = 高刷（对齐设备屏幕最高刷新率）
		"fps_mode": 1,
		"audio": true,
		"audio_volume": 0.25,
		"bgm_enabled": true,
		"bgm_volume": 0.10,
		## 雅乐编排：0 随境而变（日常/战斗自动交叉淡入淡出）/ 1 轮流雅奏（两曲轮转）
		"bgm_mode": 0,
		"audio_balance_v2": true,
		"orientation_portrait_v2": true,
		"ink_fx": true,
		"background_mute": true,
		"font_scale": 1.05,
		"natal_artifact": {},
		"fishing_tea": {},
		"five_elements": {},
		"spirit_root": {},
		"bounty_daily": {},
		"bounty_recent": [],
		"ascended_true_immortal": false,
	}
	auto_heal_threshold = 0.4
	stats = {
		"actions_completed": 0,
		"kills": 0,
		"deaths": 0,
		"play_seconds": 0.0,
		"spirit_stones_earned": 0,
		"tribulation_attempts": 0,
	}
	current_hp = get_max_hp()
	_notify_all()


func _notify_all() -> void:
	EventBus.inventory_changed.emit()
	EventBus.equipment_changed.emit()
	EventBus.stats_changed.emit()
	var realm := get_realm()
	if realm != null:
		EventBus.realm_changed.emit(realm.id, realm.display_name)
		EventBus.cultivation_changed.emit(cultivation_xp, realm.cultivation_required, is_cultivation_full())


func to_dict() -> Dictionary:
	# 三槽全量落盘（旧档仍为 2 项，from_dict 会自动补齐到 SLOT_COUNT）
	var saved_slots: Array[String] = []
	for i in range(SLOT_COUNT):
		saved_slots.append(String(active_slots[i]))
	return {
		"version": 1,
		"inventory": inventory.duplicate(true),
		"fine_items": fine_items.duplicate(true),
		"epic_items": epic_items.duplicate(true),
		"equipment": equipment.duplicate(true),
		"skill_xp": skill_xp.duplicate(true),
		"action_mastery_xp": action_mastery_xp.duplicate(true),
		"mastery_pool": mastery_pool.duplicate(true),
		"cultivation_xp": cultivation_xp,
		"realm_id": realm_id,
		"dao_heart": dao_heart.duplicate(true),
		"dao_heart_stacks": get_dao_heart_stacks(),
		"active_slots": saved_slots,
		"current_hp": current_hp,
		"selected_enemy_id": selected_enemy_id,
		"selected_region_id": selected_region_id,
		"flags": flags.duplicate(true),
		"auto_heal_threshold": auto_heal_threshold,
		"stats": stats.duplicate(true),
		"purchased_upgrades": purchased_upgrades.duplicate(true),
		"alliance_points": alliance_points,
		"bounties_done": bounties_done,
		"active_bounties": active_bounties.duplicate(true),
		"bounty_free_refresh_unix": bounty_free_refresh_unix,
		"unlocked_techniques": unlocked_techniques.duplicate(),
		"equipped_techniques": equipped_techniques.duplicate(),
		"technique_levels": technique_levels.duplicate(true),
		"discovered_items": discovered_items.duplicate(true),
		"discovered_enemies": discovered_enemies.duplicate(true),
		"defeated_enemies": defeated_enemies.duplicate(true),
		"tower_highest_floor": tower_highest_floor,
		"tower_claimed_floors": tower_claimed_floors.duplicate(true),
		"tower_claimed_upto": tower_claimed_upto,
		"last_tower_salary_day": last_tower_salary_day,
		"equip_temper_levels": equip_temper_levels.duplicate(true),
		"pity_counters": pity_counters.duplicate(true),
		"lock_portrait": lock_portrait,
		"crimson_fruit_eaten": crimson_fruit_eaten,
		"farm_plots": FarmManager.to_dict() if FarmManager != null else [],
		"combat_active": CombatEngine != null and CombatEngine.is_active(),
	}


func from_dict(data: Dictionary) -> void:
	reset()

	var inv := _as_dict(data.get("inventory", {}))
	inventory.clear()
	for key in inv.keys():
		var item_id := String(key)
		# 旧档 item_spirit_dew 指「聚灵甘露」；新号让给灵潭清露，旧物安全迁至 nectar。
		if item_id == "item_spirit_dew":
			item_id = "item_spirit_nectar"
		if DataRegistry.get_item(item_id) != null:
			inventory[item_id] = int(inventory.get(item_id, 0)) + maxi(0, int(inv[key]))

	var fines := _as_dict(data.get("fine_items", {}))
	fine_items.clear()
	for key in fines.keys():
		var item_id := String(key)
		if item_id == "item_spirit_dew":
			item_id = "item_spirit_nectar"
		fine_items[item_id] = int(fine_items.get(item_id, 0)) + maxi(0, int(fines[key]))

	var epics := _as_dict(data.get("epic_items", {}))
	epic_items.clear()
	for key in epics.keys():
		var item_id := String(key)
		if item_id == "item_spirit_dew":
			item_id = "item_spirit_nectar"
		epic_items[item_id] = int(epic_items.get(item_id, 0)) + maxi(0, int(epics[key]))

	var gear := _as_dict(data.get("equipment", {}))
	for slot in EQUIP_SLOTS:
		var entry := _as_dict(gear.get(slot, {}))
		var item_id := String(entry.get("id", ""))
		# 旧存档用 "fine": bool，新存档用 "quality": int
		var quality := 0
		if entry.has("quality"):
			quality = clampi(int(entry.get("quality", 0)), 0, 2)
		elif bool(entry.get("fine", false)):
			quality = 1
		if item_id != "" and DataRegistry.get_item(item_id) == null:
			item_id = ""
			quality = 0
		equipment[slot] = {"id": item_id, "quality": quality}

	var saved_skill_xp := _as_dict(data.get("skill_xp", {}))
	for skill_id in DataRegistry.skill_order:
		skill_xp[skill_id] = maxf(0.0, _as_float(saved_skill_xp.get(skill_id, 0.0), 0.0))

	var saved_mastery := _as_dict(data.get("action_mastery_xp", {}))
	for action_id in DataRegistry.actions.keys():
		action_mastery_xp[String(action_id)] = maxf(0.0, _as_float(saved_mastery.get(action_id, 0.0), 0.0))

	var saved_pool := _as_dict(data.get("mastery_pool", {}))
	for skill_id in DataRegistry.skill_order:
		mastery_pool[skill_id] = maxf(0.0, _as_float(saved_pool.get(skill_id, 0.0), 0.0))

	cultivation_xp = maxf(0.0, _as_float(data.get("cultivation_xp", 0.0), 0.0))
	last_tower_salary_day = int(data.get("last_tower_salary_day", -1))
	equip_temper_levels = {"weapon": 0, "armor": 0}
	pity_counters = _as_dict(data.get("pity_counters", {}))
	var saved_temper := _as_dict(data.get("equip_temper_levels", {}))
	for temper_slot in ["weapon", "armor"]:
		equip_temper_levels[temper_slot] = maxi(0,
			int(saved_temper.get(temper_slot, 0)))
	var saved_realm := String(data.get("realm_id", "qi_1"))
	realm_id = saved_realm if DataRegistry.get_realm(saved_realm) != null else "qi_1"
	# 旧档已是真仙时补回尊号标记，避免飞升记录丢失
	if realm_id == "magnificent":
		flags["ascended_true_immortal"] = true
	dao_heart.clear()
	var saved_dao_heart := _as_dict(data.get("dao_heart", {}))
	for key in saved_dao_heart.keys():
		dao_heart[int(str(key))] = clampi(int(saved_dao_heart[key]), 0, DAO_HEART_MAX)
	if dao_heart.is_empty():
		# 旧存档只有单层 dao_heart_stacks：归属炼气期
		var legacy_stacks := clampi(int(data.get("dao_heart_stacks", 0)), 0, DAO_HEART_MAX)
		if legacy_stacks > 0:
			dao_heart[0] = legacy_stacks

	# 旧档 2 元素 / 现行 3 元素 active_slots 均兼容：安全补齐到 SLOT_COUNT，清掉已锁定槽位上的幽灵运转
	var slots := _as_array(data.get("active_slots", []))
	for i in range(SLOT_COUNT):
		var action_id := ""
		if i < slots.size():
			action_id = String(slots[i])
		if action_id != "" and DataRegistry.get_action(action_id) == null:
			action_id = ""
		active_slots[i] = action_id
	var unlocked_slots := get_max_action_slots()
	for i in range(unlocked_slots, SLOT_COUNT):
		if active_slots[i] == "":
			continue
		var orphan := active_slots[i]
		active_slots[i] = ""
		var moved := false
		for j in range(unlocked_slots):
			if active_slots[j] == "":
				active_slots[j] = orphan
				moved = true
				break
		if not moved:
			# 迁移期静默停止：此时 UI 尚未构建，弹 toast 只会丢消息
			EventBus.action_stopped.emit(i, orphan)

	selected_enemy_id = String(data.get("selected_enemy_id", DEFAULT_ENEMY))
	if DataRegistry.get_enemy(selected_enemy_id) == null:
		selected_enemy_id = DEFAULT_ENEMY
	selected_region_id = String(data.get("selected_region_id", "wild_wolf_forest"))
	if not DataRegistry.regions.has(selected_region_id):
		selected_region_id = "wild_wolf_forest"

	var saved_flags := _as_dict(data.get("flags", {}))
	for key in flags.keys():
		if not saved_flags.has(key):
			continue
		var value: Variant = saved_flags[key]
		# 本命法宝 / 灵潭清茗 / 五行法则 / 灵根洗髓 / 悬赏日报允许存放字典子状态；旧档缺失时保持默认
		if key == "natal_artifact" or key == "fishing_tea" or key == "five_elements" \
				or key == "spirit_root" or key == "bounty_daily":
			flags[key] = value if typeof(value) == TYPE_DICTIONARY else {}
			continue
		if key == "bounty_recent":
			flags[key] = value if typeof(value) == TYPE_ARRAY else []
			continue
		# 保留原始类型（audio_volume 为浮点，其余为布尔）
		if typeof(value) == TYPE_BOOL or typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT:
			flags[key] = value

	# 旧档若仍是上一代默认音量，一次性迁移到新默认；自定义音量保持不变
	if not saved_flags.has("audio_balance_v2"):
		if is_equal_approx(float(flags.get("audio_volume", 0.25)), 0.8):
			flags["audio_volume"] = 0.25
		if is_equal_approx(float(flags.get("bgm_volume", 0.10)), 0.55):
			flags["bgm_volume"] = 0.10
		flags["audio_balance_v2"] = true

	# 旧存档只有 fps60 布尔值：一次性折算成三档 fps_mode（0/1/2）
	if not saved_flags.has("fps_mode"):
		flags["fps_mode"] = 1 if bool(flags.get("fps60", false)) else 0

	# 旧档没有雅乐编排：默认「随境而变」（0），1 为「轮流雅奏」
	if not saved_flags.has("bgm_mode"):
		flags["bgm_mode"] = 0
	else:
		flags["bgm_mode"] = clampi(int(flags.get("bgm_mode", 0)), 0, 1)

	# 旧档「震动开关」bool → 四档强度：true 迁移为 2 适中，false 迁移为 0 关闭
	if not saved_flags.has("vibration_level") and saved_flags.has("vibration"):
		flags["vibration_level"] = 2 if bool(saved_flags.get("vibration", true)) else 0
	flags.erase("vibration")

	auto_heal_threshold = clampf(_as_float(data.get("auto_heal_threshold", 0.4), 0.4), 0.1, 0.9)

	# 旧存档没有 lock_portrait：竖屏优先默认开启。
	# 旧版默认关闭导致手机一进游戏就横屏；首次迁移强制改回竖屏，之后尊重玩家开关。
	if not saved_flags.has("orientation_portrait_v2"):
		lock_portrait = true
		flags["orientation_portrait_v2"] = true
	else:
		lock_portrait = bool(data.get("lock_portrait", true))

	# 旧存档没有百年朱果炼化数：安全默认 0，并钳制到上限
	crimson_fruit_eaten = clampi(int(data.get("crimson_fruit_eaten", 0)), 0,
		GameFormulas.CRIMSON_FRUIT_CAP)

	# ---- 仙盟悬赏 / 藏经阁（旧档缺失时安全初始化）----
	alliance_points = maxi(0, int(data.get("alliance_points", 0)))
	bounties_done = maxi(0, int(data.get("bounties_done", 0)))
	bounty_free_refresh_unix = maxf(0.0, float(data.get("bounty_free_refresh_unix", 0.0)))
	active_bounties.clear()
	var saved_bounties: Variant = data.get("active_bounties", [])
	if typeof(saved_bounties) == TYPE_ARRAY:
		for entry in saved_bounties:
			if entry is Dictionary:
				active_bounties.append((entry as Dictionary).duplicate(true))

	unlocked_techniques.clear()
	var saved_unlocked: Variant = data.get("unlocked_techniques", [])
	if typeof(saved_unlocked) == TYPE_ARRAY:
		for key in saved_unlocked:
			var tech_id := String(key)
			if DataRegistry.get_technique(tech_id) != null:
				unlocked_techniques.append(tech_id)
	equipped_techniques.clear()
	var saved_equipped: Variant = data.get("equipped_techniques", [])
	if typeof(saved_equipped) == TYPE_ARRAY:
		for key in saved_equipped:
			var tech_id := String(key)
			if unlocked_techniques.has(tech_id) and not equipped_techniques.has(tech_id):
				equipped_techniques.append(tech_id)
	technique_levels.clear()
	var saved_levels := _as_dict(data.get("technique_levels", {}))
	for key in saved_levels.keys():
		var tech_id := String(key)
		if DataRegistry.get_technique(tech_id) != null:
			technique_levels[tech_id] = clampi(int(saved_levels[key]), 1, TechniqueData.MAX_LEVEL)

	# ---- 万象玉简 / 镇魔塔（旧档缺失时回填背包与功法收录）----
	discovered_items.clear()
	var saved_discovered := _as_dict(data.get("discovered_items", {}))
	for key in saved_discovered.keys():
		var item_id := String(key)
		if item_id == "item_spirit_dew":
			item_id = "item_spirit_nectar"
		discovered_items[item_id] = true
	discovered_enemies.clear()
	var saved_enemies_seen: Variant = data.get("discovered_enemies", {})
	if typeof(saved_enemies_seen) == TYPE_ARRAY:
		for key in saved_enemies_seen:
			discovered_enemies[String(key)] = true
	elif typeof(saved_enemies_seen) == TYPE_DICTIONARY:
		# to_dict 写出的是 Dictionary 形状，必须同样能读回（否则妖兽图鉴永远丢档）
		for key in (saved_enemies_seen as Dictionary).keys():
			discovered_enemies[String(key)] = true
	# 递进解锁新字段：旧档兼容回填，绝不覆盖已有 clear 记录
	defeated_enemies.clear()
	var saved_defeated: Variant = data.get("defeated_enemies", {})
	if typeof(saved_defeated) == TYPE_ARRAY:
		for key in saved_defeated:
			var enemy_id := String(key)
			if DataRegistry.get_enemy(enemy_id) != null:
				defeated_enemies[enemy_id] = true
	elif typeof(saved_defeated) == TYPE_DICTIONARY:
		for key in (saved_defeated as Dictionary).keys():
			var enemy_id := String(key)
			if DataRegistry.get_enemy(enemy_id) != null and bool(saved_defeated[key]):
				defeated_enemies[enemy_id] = true
	# 旧档中已收录的妖兽视为曾击败；已超出该秘境阶层则整区回填，避免老玩家被新门槛卡住
	for enemy_id in discovered_enemies.keys():
		if DataRegistry.get_enemy(String(enemy_id)) != null:
			defeated_enemies[String(enemy_id)] = true
	var realm := get_realm()
	var realm_tier := 0 if realm == null else realm.tier
	for region_id in DataRegistry.regions.keys():
		var region: Dictionary = DataRegistry.regions[region_id]
		if realm_tier > int(region.get("required_tier", 0)):
			for enemy_id in region.get("enemies", []):
				defeated_enemies[String(enemy_id)] = true
	if not can_challenge_enemy(selected_enemy_id):
		selected_enemy_id = DEFAULT_ENEMY
		selected_region_id = "wild_wolf_forest"
	tower_highest_floor = maxi(0, int(data.get("tower_highest_floor", 0)))
	tower_claimed_floors.clear()
	var saved_floors: Variant = data.get("tower_claimed_floors", {})
	if typeof(saved_floors) == TYPE_ARRAY:
		for key in saved_floors:
			tower_claimed_floors[int(key)] = true
	elif typeof(saved_floors) == TYPE_DICTIONARY:
		for key in (saved_floors as Dictionary).keys():
			tower_claimed_floors[int(key)] = true
	tower_claimed_upto = maxi(0, int(data.get("tower_claimed_upto", 0)))
	_compact_tower_claimed()
	# 最高通关层以首通记录为准：胜利必定发放首通，反之旧版「进塔/战败也加层」
	# 会留下无首通却高层的脏数据，这里一并纠正（不改存档结构，仅规范化数值）
	var claimed_max := tower_claimed_upto
	for floor_key in tower_claimed_floors.keys():
		claimed_max = maxi(claimed_max, int(floor_key))
	tower_highest_floor = claimed_max
	if not data.has("discovered_items"):
		# 老玩家图鉴回填：背包、已穿戴装备、已解锁功法
		for key in inventory.keys():
			discovered_items[String(key)] = true
		for fine_key in fine_items.keys():
			discovered_items[String(fine_key)] = true
		for epic_key in epic_items.keys():
			discovered_items[String(epic_key)] = true
		for slot in EQUIP_SLOTS:
			var entry := _as_dict(equipment.get(slot, {}))
			var equipped_id := String(entry.get("id", ""))
			if equipped_id != "":
				discovered_items[equipped_id] = true
		for tech_id in unlocked_techniques:
			discovered_items[tech_id] = true

	# 旧存档没有 purchased_upgrades 字段：保持 reset() 的空字典即可
	var saved_upgrades := _as_dict(data.get("purchased_upgrades", {}))
	purchased_upgrades.clear()
	for key in saved_upgrades.keys():
		var upgrade_id := String(key)
		if DataRegistry.get_shop_upgrade(upgrade_id) != null:
			purchased_upgrades[upgrade_id] = maxi(0, int(saved_upgrades[key]))

	var saved_stats := _as_dict(data.get("stats", {}))
	for key in stats.keys():
		if saved_stats.has(key):
			stats[key] = saved_stats[key]

	current_hp = clampi(int(data.get("current_hp", get_max_hp())), 0, get_max_hp())
	# 读档自检：修复旧版本卡在非渡劫小境界 100% 的存档（如炼气八层）
	_repair_stuck_cultivation()
	_notify_all()


func _as_dict(value: Variant) -> Dictionary:
	if typeof(value) == TYPE_DICTIONARY:
		return value
	return {}


func _as_array(value: Variant) -> Array:
	if typeof(value) == TYPE_ARRAY:
		return value
	return []


func _as_float(value: Variant, fallback: float) -> float:
	if typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT:
		return float(value)
	return fallback


# ---------------------------------------------------------------- 秘境递进解锁

func mark_enemy_defeated(enemy_id: String) -> void:
	if enemy_id == "" or DataRegistry.get_enemy(enemy_id) == null:
		return
	defeated_enemies[enemy_id] = true


## 同区按数据顺序逐个解锁；进入下一区还需击败上一区末位妖兽。
func can_challenge_enemy(enemy_id: String) -> bool:
	return enemy_lock_reason(enemy_id) == ""


## 返回空串表示可挑战，否则为面向玩家的锁定条件。
func enemy_lock_reason(enemy_id: String) -> String:
	var target := DataRegistry.get_enemy(enemy_id)
	if target == null:
		return "秘境目标不存在"
	var region_keys := DataRegistry.regions.keys()
	if not region_keys.has(target.region_id):
		return "秘境区域不存在"
	var region_index := region_keys.find(target.region_id)
	var region: Dictionary = DataRegistry.regions[target.region_id]
	var realm := get_realm()
	var realm_tier := 0 if realm == null else realm.tier
	if realm_tier < int(region.get("required_tier", 0)):
		return "需达%s境界" % String(region.get("tag", "更高境界"))
	var order: Array = region.get("enemies", [])
	var enemy_index := order.find(enemy_id)
	if enemy_index < 0:
		return "秘境目标不存在"
	if region_index > 0:
		var previous_region: Dictionary = DataRegistry.regions[
			String(region_keys[region_index - 1])]
		var previous_order: Array = previous_region.get("enemies", [])
		if not previous_order.is_empty():
			var final_id := String(previous_order[previous_order.size() - 1])
			var final_enemy := DataRegistry.get_enemy(final_id)
			var final_name := final_enemy.display_name if final_enemy != null else final_id
			if not bool(defeated_enemies.get(final_id, false)):
				return "需先胜 %s" % final_name
	if enemy_index > 0:
		var previous_id := String(order[enemy_index - 1])
		var previous_enemy := DataRegistry.get_enemy(previous_id)
		var previous_name := previous_enemy.display_name if previous_enemy != null else previous_id
		if not bool(defeated_enemies.get(previous_id, false)):
			return "需先胜 %s" % previous_name
	return ""


## 区域按钮锁定条件：境界或上一区头目未胜。
func region_lock_reason(region_id: String) -> String:
	if not DataRegistry.regions.has(region_id):
		return "秘境区域不存在"
	var region: Dictionary = DataRegistry.regions[region_id]
	var realm := get_realm()
	var realm_tier := 0 if realm == null else realm.tier
	if realm_tier < int(region.get("required_tier", 0)):
		return "需达%s境界" % String(region.get("tag", "更高境界"))
	var region_keys := DataRegistry.regions.keys()
	var region_index := region_keys.find(region_id)
	if region_index > 0:
		var previous_region: Dictionary = DataRegistry.regions[
			String(region_keys[region_index - 1])]
		var previous_order: Array = previous_region.get("enemies", [])
		if not previous_order.is_empty():
			var final_id := String(previous_order[previous_order.size() - 1])
			var final_enemy := DataRegistry.get_enemy(final_id)
			var final_name := final_enemy.display_name if final_enemy != null else final_id
			if not bool(defeated_enemies.get(final_id, false)):
				return "需先胜 %s" % final_name
	return ""


# ---------------------------------------------------------------- 境界

func get_realm() -> RealmData:
	var realm := DataRegistry.get_realm(realm_id)
	if realm == null:
		realm = DataRegistry.get_realm("qi_1")
	return realm


## 吐纳技能按当前大境界换名；其他技能保持数据表名称。
func get_skill_display_name(skill_id: String) -> String:
	if skill_id == "cultivation":
		return get_cultivation_stage_name()
	return DataRegistry.get_skill_name(skill_id)


## 吐纳名由境界数据自带（RealmData.meditation_name，19 个境界在注册时写入）；
## 数据缺失时回退到 tier 映射，仍缺失则用「吐纳修行」兜底。
func get_cultivation_stage_name() -> String:
	var realm := get_realm()
	if realm == null:
		return DataRegistry.CULTIVATION_NAME_DEFAULT
	if realm.meditation_name != "":
		return realm.meditation_name
	return DataRegistry.get_cultivation_name_for_tier(realm.tier)


func get_realm_index() -> int:
	return maxi(0, DataRegistry.get_realm_index(realm_id))


func get_skill_level_cap() -> int:
	var realm := get_realm()
	if realm == null:
		return 20
	return realm.skill_level_cap


func get_offline_cap_hours() -> float:
	var realm := get_realm()
	if realm == null:
		return 12.0
	return realm.offline_cap_hours


func is_dual_cultivation_unlocked() -> bool:
	var realm := get_realm()
	return realm != null and realm.unlocks_dual_cultivation


func get_realm_requirement() -> float:
	var realm := get_realm()
	if realm == null:
		return 0.0
	return realm.cultivation_required


func is_cultivation_full() -> bool:
	var requirement := get_realm_requirement()
	if requirement <= 0.0:
		return false
	return cultivation_xp >= requirement - 0.001


func is_cultivation_locked() -> bool:
	var realm := get_realm()
	return realm != null and realm.requires_tribulation and is_cultivation_full()


func add_cultivation(amount: float) -> void:
	if amount <= 0.0:
		return
	var realm := get_realm()
	if realm == null:
		return
	if realm.cultivation_required <= 0.0:
		return
	if cultivation_xp >= realm.cultivation_required:
		# 满值兜底：非渡劫境界补一次晋升，避免异常赋值/旧存档停在 100%
		if not realm.requires_tribulation:
			_advance_realm()
		return
	cultivation_xp = minf(cultivation_xp + amount, realm.cultivation_required)
	EventBus.cultivation_changed.emit(cultivation_xp, realm.cultivation_required, is_cultivation_full())
	if is_cultivation_full() and not realm.requires_tribulation:
		_advance_realm()


func _advance_realm() -> void:
	# 只有「当前境界本身是渡劫瓶颈」时才必须走引动天劫；进入渡劫境（如炼气九层）照常晋升。
	# 旧实现误判 next.requires_tribulation，导致炼气八层满修为永远升不到九层。
	var current := get_realm()
	if current != null and current.requires_tribulation:
		return
	var next := DataRegistry.get_next_realm(realm_id)
	if next == null:
		return
	realm_id = next.id
	cultivation_xp = 0.0
	current_hp = get_max_hp()
	EventBus.realm_changed.emit(realm_id, next.display_name)
	EventBus.cultivation_changed.emit(cultivation_xp, next.cultivation_required, false)
	EventBus.toast.emit("境界稳固：%s" % next.display_name)
	EventBus.stats_changed.emit()
	if not offline_settling:
		vibrate_heavy()


## 读档自检：旧版本 _advance_realm() 会把「下一境界需要渡劫」当成拦截条件，
## 使炼气八层、筑基中期等小境界卡在 100%。这里补一次晋升，旧存档无需重开。
func _repair_stuck_cultivation() -> void:
	var realm := get_realm()
	if realm == null or realm.cultivation_required <= 0.0:
		return
	# 炼气九层 / 筑基后期 / 金丹后期 / 元婴后期：本就该停在满修为等待渡劫
	if realm.requires_tribulation:
		return
	if not is_cultivation_full():
		return
	# 读档修数据不当作玩家突破，静音处理
	var previous := offline_settling
	offline_settling = true
	_advance_realm()
	offline_settling = previous


## 渡劫成功：按当前境界的 tribulation_target 晋升（筑基 / 金丹通用）
func advance_after_tribulation() -> void:
	var current := get_realm()
	var target_id := ""
	if current != null:
		target_id = current.tribulation_target
	var next_realm: RealmData = DataRegistry.get_realm(target_id) if target_id != "" else null
	if next_realm == null:
		next_realm = DataRegistry.get_next_realm(realm_id)
	if next_realm == null:
		return
	var was_dual := is_dual_cultivation_unlocked()
	realm_id = next_realm.id
	if realm_id == "magnificent":
		flags["ascended_true_immortal"] = true
	cultivation_xp = 0.0
	current_hp = get_max_hp()
	EventBus.realm_changed.emit(realm_id, next_realm.display_name)
	EventBus.cultivation_changed.emit(cultivation_xp, next_realm.cultivation_required, false)
	if next_realm.unlocks_dual_cultivation and not was_dual:
		EventBus.dual_cultivation_unlocked.emit()
	EventBus.stats_changed.emit()


## 兼容旧调用
func promote_to_foundation() -> void:
	advance_after_tribulation()


## 道心悟性按大境界独立累计（tier -> 层数）
func get_dao_heart_stacks(tier: int = -1) -> int:
	var key := tier
	if key < 0:
		var realm := get_realm()
		key = 0 if realm == null else realm.tier
	return clampi(int(dao_heart.get(key, 0)), 0, DAO_HEART_MAX)


func add_dao_heart_stack(tier: int = -1) -> void:
	var key := tier
	if key < 0:
		var realm := get_realm()
		key = 0 if realm == null else realm.tier
	dao_heart[key] = mini(DAO_HEART_MAX, get_dao_heart_stacks(key) + 1)
	EventBus.stats_changed.emit()


func restore_hp(ratio: float = 1.0) -> void:
	var max_hp := get_max_hp()
	current_hp = clampi(int(roundf(float(max_hp) * ratio)), 0, max_hp)
	EventBus.stats_changed.emit()


# ---------------------------------------------------------------- 藏经阁（功法研习）

func get_technique_level(technique_id: String) -> int:
	return clampi(int(technique_levels.get(technique_id, 1)), 1, TechniqueData.MAX_LEVEL)


func is_technique_unlocked(technique_id: String) -> bool:
	return unlocked_techniques.has(technique_id)


func is_technique_equipped(technique_id: String) -> bool:
	return equipped_techniques.has(technique_id)


## 运转槽位随大境界解锁：炼气 1 / 筑基 2 / 金丹 3 / 元婴 4
func get_technique_slots() -> int:
	var realm := get_realm()
	var tier := 0 if realm == null else realm.tier
	return clampi(tier + 1, 1, 4)


func unlock_technique(technique_id: String) -> bool:
	var tech := DataRegistry.get_technique(technique_id)
	if tech == null or is_technique_unlocked(technique_id):
		return false
	if alliance_points < tech.unlock_cost_points:
		EventBus.toast.emit("仙盟贡献不足：需 %d" % tech.unlock_cost_points)
		return false
	alliance_points -= tech.unlock_cost_points
	grant_technique(technique_id, "兑换")
	vibrate_light()
	return true


func grant_technique(technique_id: String, source: String = "掉落") -> bool:
	var tech := DataRegistry.get_technique(technique_id)
	if tech == null or is_technique_unlocked(technique_id):
		return false
	unlocked_techniques.append(technique_id)
	technique_levels[technique_id] = 1
	push_activity_log("参悟《%s》（%s）" % [tech.name, source], "gold")
	EventBus.toast.emit("已参悟《%s》" % tech.name)
	if AudioManager != null:
		AudioManager.play_level_up()
	EventBus.technique_unlocked.emit(technique_id)
	EventBus.technique_changed.emit()
	EventBus.stats_changed.emit()
	# 秘境头目掉落新功法：中震惊喜；兑换入手保持轻震
	if not offline_settling and source.contains("掉落"):
		vibrate_medium()
	return true


func equip_technique(technique_id: String) -> bool:
	if not is_technique_unlocked(technique_id) or is_technique_equipped(technique_id):
		return false
	if equipped_techniques.size() >= get_technique_slots():
		EventBus.toast.emit("功法位已满（%d），请先卸下一部" % get_technique_slots())
		return false
	equipped_techniques.append(technique_id)
	var tech := DataRegistry.get_technique(technique_id)
	EventBus.toast.emit("运转《%s》" % (tech.name if tech != null else technique_id))
	EventBus.technique_changed.emit()
	EventBus.stats_changed.emit()
	vibrate_light()
	if AudioManager != null:
		AudioManager.play_equip_use()
	return true


func unequip_technique(technique_id: String) -> bool:
	if not equipped_techniques.has(technique_id):
		return false
	equipped_techniques.erase(technique_id)
	EventBus.technique_changed.emit()
	EventBus.stats_changed.emit()
	vibrate_light()
	if AudioManager != null:
		AudioManager.play_equip_use()
	return true


func technique_upgrade_cost(technique_id: String) -> Dictionary:
	var level := get_technique_level(technique_id)
	var realm := get_realm()
	var tier := 0 if realm == null else realm.tier
	return {
		"points": 20 + 20 * level,
		"stones": (100 + 80 * level) * (tier + 1),
	}


func can_upgrade_technique(technique_id: String) -> Dictionary:
	if not is_technique_unlocked(technique_id):
		return {"ok": false, "reason": "尚未参悟"}
	var level := get_technique_level(technique_id)
	if level >= TechniqueData.MAX_LEVEL:
		return {"ok": false, "reason": "已至 5 重"}
	var cost := technique_upgrade_cost(technique_id)
	if alliance_points < int(cost["points"]):
		return {"ok": false, "reason": "贡献不足"}
	if get_item_count(DataRegistry.SPIRIT_STONE) < int(cost["stones"]):
		return {"ok": false, "reason": "灵石不足"}
	return {"ok": true, "reason": ""}


func upgrade_technique(technique_id: String) -> bool:
	var check := can_upgrade_technique(technique_id)
	if not bool(check.get("ok", false)):
		EventBus.toast.emit(String(check.get("reason", "无法参悟")))
		return false
	var cost := technique_upgrade_cost(technique_id)
	alliance_points -= int(cost["points"])
	remove_item(DataRegistry.SPIRIT_STONE, int(cost["stones"]))
	var level := get_technique_level(technique_id) + 1
	technique_levels[technique_id] = level
	var tech := DataRegistry.get_technique(technique_id)
	push_activity_log("《%s》参悟至 %d 重" % [
		tech.name if tech != null else technique_id, level], "good")
	EventBus.toast.emit("《%s》参悟至 %d 重" % [
		tech.name if tech != null else technique_id, level])
	EventBus.technique_changed.emit()
	EventBus.stats_changed.emit()
	# 主动参悟升级：中震确认
	vibrate_medium()
	return true


# ---------------------------------------------------------------- 修行纪要（仅内存）

## tone: normal / good / gold / warn
func push_activity_log(text: String, tone: String = "normal") -> void:
	if text == "":
		return
	var clock := Time.get_time_dict_from_system()
	var entry := {
		"time": "%02d:%02d" % [int(clock.get("hour", 0)), int(clock.get("minute", 0))],
		"text": text,
		"tone": tone,
	}
	recent_logs.append(entry)
	while recent_logs.size() > MAX_RECENT_LOGS:
		recent_logs.pop_front()
	EventBus.activity_log_added.emit(entry)


func get_recent_logs(count: int = 10) -> Array:
	var start := maxi(0, recent_logs.size() - count)
	return recent_logs.slice(start, recent_logs.size())


# ---------------------------------------------------------------- 仙坊阁（法器 / 扩建 / 灵种）

func get_upgrade_level(upgrade_id: String) -> int:
	return int(purchased_upgrades.get(upgrade_id, 0))


func has_upgrade(upgrade_id: String) -> bool:
	return get_upgrade_level(upgrade_id) > 0


## 汇总某类效果（effect_value × 等级），target 命中技能或 "all"
## 复合商品（extra_effects）里的同类效果一并累加，如「太虚混沌炉」的全制造减耗
func get_effect_sum(effect_type: String, target: String = "") -> float:
	var total := 0.0
	for key in purchased_upgrades.keys():
		var data := DataRegistry.get_shop_upgrade(String(key))
		if data == null:
			continue
		var level := float(get_upgrade_level(data.id))
		if level <= 0.0:
			continue
		if data.effect_type == effect_type \
				and (target == "" or data.effect_target == target or data.effect_target == "all"):
			total += data.effect_value * level
		var extras: Dictionary = data.extra_effects
		if extras.has(effect_type):
			total += float(extras[effect_type]) * level
	return total


## 采集法器带来的耗时乘数（多件乘算）
func get_tool_interval_multiplier(skill_id: String) -> float:
	var reductions: Array = []
	for key in purchased_upgrades.keys():
		var data := DataRegistry.get_shop_upgrade(String(key))
		if data == null or data.effect_type != "interval":
			continue
		if data.effect_target != skill_id and data.effect_target != "all":
			continue
		for i in range(get_upgrade_level(data.id)):
			reductions.append(absf(data.effect_value))
	return GameFormulas.interval_multiplier(reductions)


func get_double_chance_bonus(skill_id: String) -> float:
	return get_effect_sum("double_chance", skill_id)


func get_quality_bonus() -> float:
	return get_effect_sum("quality_pct")


## 洞府灵气反哺：已播种灵田数量 → 吐纳修为 / 丹道双倍
func get_farm_aura_cultivation_bonus() -> float:
	if FarmManager == null:
		return 0.0
	return GameFormulas.farm_aura_cultivation(FarmManager.count_planted())


func get_farm_aura_alchemy_bonus() -> float:
	if FarmManager == null:
		return 0.0
	return GameFormulas.farm_aura_alchemy_double(FarmManager.count_planted())


func get_cultivation_multiplier() -> float:
	return 1.0 + get_effect_sum("cultivation_pct") + get_farm_aura_cultivation_bonus()


func get_heal_multiplier() -> float:
	# 坊市护身灵铃 / 紫金镇魂铃 + 藏经阁《周天吐纳真解》回血加成
	return 1.0 + get_effect_sum("heal_pct") + GameFormulas.get_technique_bonus("heal_pct")


func get_heal_amount(item: ItemData) -> int:
	if item == null:
		return 0
	return maxi(0, int(roundf(float(item.heal_amount) * get_heal_multiplier())))


func can_purchase_upgrade(upgrade_id: String) -> Dictionary:
	var data := DataRegistry.get_shop_upgrade(upgrade_id)
	if data == null:
		return {"ok": false, "reason": "未知商品"}
	if data.is_repeatable():
		if get_item_count(DataRegistry.SPIRIT_STONE) < data.cost_stones:
			return {"ok": false, "reason": "灵石不足"}
		return {"ok": true, "reason": ""}
	if data.max_level > 0 and get_upgrade_level(upgrade_id) >= data.max_level:
		return {"ok": false, "reason": "已拥有"}
	if data.prerequisite_id != "" and not has_upgrade(data.prerequisite_id):
		var prereq := DataRegistry.get_shop_upgrade(data.prerequisite_id)
		return {"ok": false, "reason": "需%s" % ("前置法器" if prereq == null else prereq.name)}
	if get_realm_index() < data.required_realm_index:
		var realm_name := "更高境界"
		if data.required_realm_index >= 0 and data.required_realm_index < DataRegistry.realm_order.size():
			var realm: RealmData = DataRegistry.get_realm(DataRegistry.realm_order[data.required_realm_index])
			if realm != null:
				realm_name = realm.display_name
		return {"ok": false, "reason": "需 %s" % realm_name}
	if get_item_count(DataRegistry.SPIRIT_STONE) < data.cost_stones:
		return {"ok": false, "reason": "灵石不足"}
	return {"ok": true, "reason": ""}


func purchase_upgrade(upgrade_id: String) -> bool:
	var data := DataRegistry.get_shop_upgrade(upgrade_id)
	if data == null:
		return false
	var check := can_purchase_upgrade(upgrade_id)
	if not bool(check.get("ok", false)):
		EventBus.toast.emit(String(check.get("reason", "无法购买")))
		return false
	if not remove_item(DataRegistry.SPIRIT_STONE, data.cost_stones):
		return false
	if data.is_repeatable():
		add_item(data.effect_target, 1)
		EventBus.toast.emit("购得 %s ×1" % data.name)
	else:
		purchased_upgrades[upgrade_id] = get_upgrade_level(upgrade_id) + 1
		if data.effect_type == "unlock_plot" and FarmManager != null:
			FarmManager.unlock_plot(int(data.effect_target))
		EventBus.toast.emit("已拥有 %s" % data.name)
	EventBus.shop_changed.emit()
	EventBus.stats_changed.emit()
	return true


# ---------------------------------------------------------------- 通用开关 / 反馈

func is_flag(key: String, fallback: bool = false) -> bool:
	return bool(flags.get(key, fallback))


func set_flag(key: String, value: bool) -> void:
	flags[key] = value
	EventBus.stats_changed.emit()


## 震动调度统一由 AudioManager 负责（四档强度 + 120ms 冷却 + 前台门控），
## 这里只保留语义化转发，旧调用点无需改动。
func vibrate_light() -> void:
	if AudioManager != null:
		AudioManager.play_vibrate_light()


func vibrate_medium() -> void:
	if AudioManager != null:
		AudioManager.play_vibrate_medium()


func vibrate_heavy() -> void:
	if AudioManager != null:
		AudioManager.play_vibrate_heavy()


## 大境界渡劫成功：中震 → 0.11s → 重震
func vibrate_breakthrough() -> void:
	if AudioManager != null:
		AudioManager.play_vibrate_breakthrough()


# ---------------------------------------------------------------- 属性

func _equip_stat(slot: String, stat_key: String) -> float:
	var entry := _as_dict(equipment.get(slot, {}))
	var item_id := String(entry.get("id", ""))
	if item_id == "":
		return 0.0
	var item := DataRegistry.get_item(item_id)
	if item == null:
		return 0.0
	var quality := clampi(int(entry.get("quality", 0)), 0, 2)
	var mult := float(QUALITY_MULTIPLIERS[quality])
	match stat_key:
		"attack":
			return float(item.attack_bonus) * mult
		"defense":
			return float(item.defense_bonus) * mult
		"max_hp":
			return float(item.max_hp_bonus) * mult
		"accuracy":
			return float(item.accuracy_bonus) * mult
		"crit_bonus":
			return item.crit_bonus * mult
		"dodge_bonus":
			return item.dodge_bonus * mult
	return 0.0


## 道体战力倍率：大境界基值 × 小境界（初期 1.00 / 中期 1.06 / 后期 1.12）
func get_realm_combat_mult() -> float:
	var realm := get_realm()
	if realm == null:
		return 1.0
	var base := float(DataRegistry.REALM_COMBAT_MULT[clampi(realm.tier, 0,
		DataRegistry.REALM_COMBAT_MULT.size() - 1)])
	return base * (1.0 + 0.06 * float(clampi(realm.stage - 1, 0, 2)))


## 本命法宝加成（器胚成长 + 已铭刻器纹），统一由逻辑模块汇总。
func get_natal_bonus(key: String) -> float:
	return NatalArtifactSystem.get_bonus(key)


## 会心率：功法 + 本命祭炼 + 本命法宝，战斗与道身面板共用同一口径。
func get_crit_chance_raw() -> float:
	return (GameFormulas.get_technique_bonus("crit_chance")
		+ get_temper_crit_chance() + get_natal_bonus("crit_chance")
		+ SpiritRootSystem.get_bonus("crit_chance")
		+ (_equip_stat("weapon", "crit_bonus")
		+ _equip_stat("armor", "crit_bonus")) / 100.0)


func get_crit_chance() -> float:
	return clampf(get_crit_chance_raw(), 0.0, 0.75)


## 天雷与妖兽减伤：功法 + 本命法宝 + 土之法则，战斗与渡劫共用。
func get_damage_reduce_bonus() -> float:
	return clampf(GameFormulas.get_technique_bonus("trib_reduce")
		+ GameFormulas.get_technique_bonus("damage_reduce")
		+ get_natal_bonus("damage_reduce")
		+ FiveElementsSystem.get_bonus("tribulation_reduction")
		+ SpiritRootSystem.get_bonus("tribulation_reduction"), 0.0, 0.5)


## 天雷单道伤害统一入口：元婴起加入无视固定防御的本源雷压。
## 低境界沿用旧公式；高阶在「原扣防后伤害」与「最大气血比例雷压」中取较大值。
func get_tribulation_thunder_damage(base: int, ward_ratio: float = 0.0,
		dao_heart_stacks: int = -1) -> int:
	var stats := get_player_stats()
	var stacks := dao_heart_stacks
	if stacks < 0:
		stacks = get_dao_heart_stacks()
	var reduce := get_damage_reduce_bonus()
	var original := GameFormulas.tribulation_damage(base, int(stats["defense"]),
		stacks, ward_ratio)
	if reduce > 0.0:
		original = maxi(1, int(roundf(float(original) * maxf(0.5, 1.0 - reduce))))
	var realm := get_realm()
	var tier := 0 if realm == null else realm.tier
	if tier < 3:
		return maxi(1, original)
	# 本源雷压：护符/功法减伤与避雷/五行/玄天古钟减伤分别夹取后连乘。
	var ward_survive := 1.0 - minf(0.85, ward_ratio)
	var reduce_survive := 1.0 - minf(0.50, reduce)
	var final_reduce := ward_survive * reduce_survive
	var scale := 0.0
	if tier >= 0 and tier < TRIBULATION_SOURCE_SCALE.size():
		scale = TRIBULATION_SOURCE_SCALE[tier]
	var source_pressure := float(stats["max_hp"]) \
		* (0.14 + 0.02 * float(tier)) * final_reduce * scale
	return maxi(1, maxi(original, int(roundf(source_pressure))))


## 本命祭炼百分比放大：兵刃每级总攻 +1.2%，法袍每级总气血/防御 +1.2%
func get_temper_pct(slot: String) -> float:
	return 0.012 * float(get_temper_level(slot))


func get_max_hp() -> int:
	var realm := get_realm()
	var base := realm.max_hp if realm != null else 100
	var bonus := int(roundf(_equip_stat("weapon", "max_hp") + _equip_stat("armor", "max_hp")))
	# 固定项汇总：朱果与祭炼并入乘区（不再被百分比稀释）
	var total := float(base + bonus)
	total += float(GameFormulas.crimson_fruit_hp_bonus(crimson_fruit_eaten))
	total += float(get_temper_hp_bonus())
	# 乘区链：功法%（含混元镇道钟）→ 图鉴% → 祭炼% → 境界道体倍率
	total *= 1.0 + GameFormulas.get_technique_bonus("max_hp")
	total *= 1.0 + get_effect_sum("max_hp_pct") + GameFormulas.get_codex_bonus("max_hp")
	total *= 1.0 + get_temper_pct("armor")
	total *= 1.0 + get_natal_bonus("max_hp_pct")
	total *= 1.0 + FiveElementsSystem.get_bonus("hp_def_pct")
	total *= 1.0 + SpiritRootSystem.get_bonus("hp_def_pct")
	total *= get_realm_combat_mult()
	return int(roundf(total))


func get_attack() -> int:
	var realm := get_realm()
	var base := realm.attack if realm != null else BASE_ATTACK
	# 固定项汇总：朱果与祭炼并入乘区
	var total := float(base + int(roundf(
		_equip_stat("weapon", "attack") + _equip_stat("armor", "attack"))))
	total += float(GameFormulas.crimson_fruit_attack_bonus(crimson_fruit_eaten))
	total += float(get_temper_attack_bonus())
	# 乘区链：功法% → 图鉴% → 祭炼% → 境界道体倍率
	total *= 1.0 + GameFormulas.get_technique_bonus("attack_pct")
	total *= 1.0 + GameFormulas.get_codex_bonus("attack")
	total *= 1.0 + get_temper_pct("weapon")
	total *= 1.0 + get_natal_bonus("attack_pct")
	total *= 1.0 + FiveElementsSystem.get_bonus("attack_pct")
	total *= 1.0 + SpiritRootSystem.get_bonus("attack_pct")
	total *= get_realm_combat_mult()
	return int(roundf(total))


func get_defense() -> int:
	var realm := get_realm()
	var base := realm.defense if realm != null else BASE_DEFENSE
	# 固定项汇总：祭炼并入乘区
	var total := float(base + int(roundf(
		_equip_stat("weapon", "defense") + _equip_stat("armor", "defense"))))
	total += float(get_temper_defense_bonus())
	# 乘区链：功法% → 图鉴% → 祭炼% → 境界道体倍率
	total *= 1.0 + GameFormulas.get_technique_bonus("defense")
	total *= 1.0 + GameFormulas.get_codex_bonus("defense")
	total *= 1.0 + get_temper_pct("armor")
	total *= 1.0 + get_natal_bonus("defense_pct")
	total *= 1.0 + FiveElementsSystem.get_bonus("hp_def_pct")
	total *= 1.0 + SpiritRootSystem.get_bonus("hp_def_pct")
	total *= get_realm_combat_mult()
	return int(roundf(total))


# ---------------------------------------------------------------- 本命祭炼（中后期长线消耗口）

## 祭炼消耗：灵石 5000 × 1.15^level，0→1 重 5000，49→50 重约 471 万。
## 材料 5 + level×1.5 件；未满 10 重需 2 阶以上灵材，满 10 重后需 3 阶以上
const TEMPER_STONE_BASE: float = 5000.0
const TEMPER_STONE_GROWTH: float = 1.15
const TEMPER_MAT_BASE: int = 5
const TEMPER_CRIT_CAP: float = 0.25


func get_temper_level(slot: String) -> int:
	return maxi(0, int(equip_temper_levels.get(slot, 0)))


## 本命祭炼开启门槛：筑基中期；旧档已有祭炼层次继续生效，仅禁止继续升级
func can_temper_equipment() -> bool:
	return get_realm_index() >= TEMPER_UNLOCK_ORDER


## 指定槽位是否还能继续祭炼：境界达标且当前重数未达 50 重
func can_temper_slot(slot: String) -> bool:
	return can_temper_equipment() and get_temper_level(slot) < MAX_TEMPER_LEVEL


func temper_stone_cost(slot: String) -> int:
	return int(round(TEMPER_STONE_BASE * pow(TEMPER_STONE_GROWTH,
		float(get_temper_level(slot)))))


func temper_material_cost(slot: String) -> int:
	return TEMPER_MAT_BASE + int(get_temper_level(slot) * 1.5)


## 当前重数所需材料品阶：未满 10 重为 2 阶，满 10 重起为 3 阶
func get_temper_material_min_tier(slot: String = "") -> int:
	if slot != "" and get_temper_level(slot) >= 10:
		return 3
	return 2


## 祭炼材料候选：按当前重数筛选品阶门槛，优先库存 > 50 中最富余者
func find_temper_material(slot: String = "") -> String:
	var best := ""
	var best_score := -100000
	var min_tier := get_temper_material_min_tier(slot)
	for item_key in inventory.keys():
		var item_id := String(item_key)
		var count := get_item_count(item_id)
		if count <= 0:
			continue
		var item := DataRegistry.get_item(item_id)
		if item == null or item.is_equipment():
			continue
		var tier := int(DataRegistry.get_material_grade(item_id).get("tier", 0))
		if tier < min_tier:
			continue
		# 库存 > 50 优先（score 加权），同档取最富余
		var score := count + (50000 if count > 50 else 0)
		if score > best_score:
			best_score = score
			best = item_id
	return best


## 祭炼落账：可连炼 times 次，材料/灵石不足即停。批量期间静音信号防重建卡顿。
func temper_equipment(slot: String, times: int = 1) -> Dictionary:
	# 未达筑基中期或已达 50 重均不落账、不扣材料；旧档超上限原样保留收益
	if not can_temper_equipment():
		return {"ok": false, "reason": "需 筑基中期", "levels": 0,
			"stones": 0, "mat_id": "", "mat_amount": 0}
	if get_temper_level(slot) >= MAX_TEMPER_LEVEL:
		return {"ok": false, "reason": "已至祭炼圆满之境", "levels": 0,
			"stones": 0, "mat_id": "", "mat_amount": 0}
	var done := 0
	var stones_spent := 0
	var mat_id := ""
	var mat_spent := 0
	var reason := ""
	change_signals_muted = true
	for i in range(maxi(1, times)):
		if get_temper_level(slot) >= MAX_TEMPER_LEVEL:
			reason = "已至祭炼圆满之境"
			break
		var stone := temper_stone_cost(slot)
		var mat_need := temper_material_cost(slot)
		var candidate := find_temper_material(slot)
		if candidate == "" or get_item_count(candidate) < mat_need \
				or get_item_count(DataRegistry.SPIRIT_STONE) < stone:
			break
		remove_item(DataRegistry.SPIRIT_STONE, stone)
		remove_item(candidate, mat_need)
		equip_temper_levels[slot] = get_temper_level(slot) + 1
		done += 1
		stones_spent += stone
		mat_id = candidate
		mat_spent += mat_need
	change_signals_muted = false
	if done > 0:
		EventBus.inventory_changed.emit()
		EventBus.equipment_changed.emit()
		EventBus.stats_changed.emit()
	return {"ok": done > 0, "reason": reason, "levels": done, "stones": stones_spent,
		"mat_id": mat_id, "mat_amount": mat_spent}


## 祭炼收益：兵刃 攻+15/级、会心+0.15%/级（封顶 +25%）、每 5 级全百艺双倍 +0.5%；
## 法袍 气血+180/级、防御+10/级、每 5 级全百艺耗时 -0.5%
func get_temper_attack_bonus() -> int:
	return get_temper_level("weapon") * 15


func get_temper_crit_chance() -> float:
	return minf(float(get_temper_level("weapon")) * 0.0015, TEMPER_CRIT_CAP)


func get_temper_double_bonus() -> float:
	return 0.005 * float(get_temper_level("weapon") / 5)


func get_temper_hp_bonus() -> int:
	return get_temper_level("armor") * 180


func get_temper_defense_bonus() -> int:
	return get_temper_level("armor") * 10


func get_temper_interval_reduction() -> float:
	return 0.005 * float(get_temper_level("armor") / 5)


# ---------------------------------------------------------------- 万象玉简 / 镇魔塔

var discovered_items: Dictionary = {}
var discovered_enemies: Dictionary = {}
var tower_highest_floor: int = 0
## 已领取首通奖励的层数（只保留跳层记录；连续层压缩进 tower_claimed_upto）
var tower_claimed_floors: Dictionary = {}
## 首通高水位：1..N 层已全部领取。塔层无限递增，用单个整数替代无限增长的字典
var tower_claimed_upto: int = 0


func discover_item(item_id: String) -> void:
	if item_id == "" or discovered_items.has(item_id):
		return
	discovered_items[item_id] = true
	var item := DataRegistry.get_item(item_id)
	if item != null:
		push_activity_log("万象玉简收录：%s" % item.display_name, "normal")
	if AudioManager != null:
		AudioManager.play_level_up()


func discover_enemy(enemy_id: String) -> void:
	if enemy_id == "":
		return
	mark_enemy_defeated(enemy_id)
	if discovered_enemies.has(enemy_id):
		return
	discovered_enemies[enemy_id] = true
	var enemy := DataRegistry.get_enemy(enemy_id)
	if enemy != null:
		push_activity_log("万象玉简收录：%s" % enemy.display_name, "normal")
	if AudioManager != null:
		AudioManager.play_level_up()


## 图鉴总收集度：物品 + 妖兽 + 功法 / 全部条目
## 已解锁集合必须与当前图鉴目录严格取交集（历史遗留/已删条目会造成 158/157 分子超分母）
func get_codex_percent() -> float:
	var total := get_codex_total()
	if total <= 0:
		return 0.0
	return clampf(float(get_codex_found()) / float(total), 0.0, 1.0)


func get_codex_found() -> int:
	var found := 0
	for item_key in discovered_items.keys():
		if DataRegistry.items.has(String(item_key)):
			found += 1
	for enemy_key in discovered_enemies.keys():
		if DataRegistry.enemies.has(String(enemy_key)):
			found += 1
	for tech_id in unlocked_techniques:
		if DataRegistry.techniques.has(String(tech_id)):
			found += 1
	for tea_id in FishingTeaSystem.get_brewed_teas():
		if FishingTeaSystem.TEAS.has(tea_id):
			found += 1
	return clampi(found, 0, get_codex_total())


func get_codex_total() -> int:
	return DataRegistry.items.size() + DataRegistry.enemies.size() \
		+ DataRegistry.techniques.size() + FishingTeaSystem.TEAS.size()


func is_tower_floor_claimed(floor_num: int) -> bool:
	return floor_num <= tower_claimed_upto or tower_claimed_floors.has(floor_num)


## 当前最大可选层 = 已通关最高层 + 1（尚未通关任何层时只能是第 1 层）
func get_tower_max_floor() -> int:
	return maxi(1, tower_highest_floor + 1)


func is_tower_floor_unlocked(floor_num: int) -> bool:
	return floor_num >= 1 and floor_num <= get_tower_max_floor()


## 把「自第 1 层起连续已领」的层数压缩进高水位，字典只留跳层键。
## 旧存档每条首通都存一个键，塔层无限递增会让存档无限膨胀。
func _compact_tower_claimed() -> void:
	if tower_claimed_floors.is_empty():
		return
	var floor_num := tower_claimed_upto + 1
	while tower_claimed_floors.has(floor_num):
		tower_claimed_floors.erase(floor_num)
		floor_num += 1
	tower_claimed_upto = floor_num - 1


## 首通奖励层段倍率：每跨 25 层升一档，妖王层在公式内翻倍。
## 倍率封顶可避免仙阶无尽段首通灵石无限膨胀；每日俸禄公式保持不变。
const TOWER_FIRST_CLEAR_TIER_MULTIPLIERS: Array = [
	1.0, 2.0, 3.0, 5.0, 8.0, 12.0, 18.0, 26.0
]


## 镇魔塔首通奖励统一入口：CombatEngine 结算与 TowerPanel 预览共用
func get_tower_first_clear_reward(floor_num: int) -> Dictionary:
	var safe_floor := maxi(1, floor_num)
	var tier_index := clampi((safe_floor - 1) / 25, 0,
		TOWER_FIRST_CLEAR_TIER_MULTIPLIERS.size() - 1)
	var tier_mult := float(TOWER_FIRST_CLEAR_TIER_MULTIPLIERS[tier_index])
	var king_mult := 2 if safe_floor % 5 == 0 else 1
	return {
		"stones": int(round(50.0 * float(safe_floor) * tier_mult * float(king_mult))),
		"points": int(round(float(10 + safe_floor) * tier_mult * float(king_mult))),
		"tier": tier_index + 1,
		"king": king_mult == 2,
	}


## 首通奖励入账
func claim_tower_floor(floor_num: int, stones: int, points: int) -> void:
	if is_tower_floor_claimed(floor_num):
		return
	if floor_num == tower_claimed_upto + 1:
		tower_claimed_upto = floor_num
		# 高水位推进后顺手吃掉此前记录的跳层键
		while tower_claimed_floors.has(tower_claimed_upto + 1):
			tower_claimed_upto += 1
			tower_claimed_floors.erase(tower_claimed_upto)
	else:
		tower_claimed_floors[floor_num] = true
	if stones > 0:
		add_item(DataRegistry.SPIRIT_STONE, stones)
	alliance_points += points
	push_activity_log("首通镇魔塔第 %d 层 · 灵石 +%d 贡献 +%d" % [floor_num, stones, points], "gold")


## 境界经验加成：元婴 +10% / 化神·炼虚 +15% / 合体·大乘·真仙 +25%
func get_skill_xp_multiplier() -> float:
	var realm := get_realm()
	if realm == null:
		return 1.0
	if realm.tier >= 6:
		return 1.25
	if realm.tier >= 4:
		return 1.15
	if realm.tier >= 3:
		return 1.10
	return 1.0


## 真仙「终局光环」：全部动作产出 +20%（与离线效率独立）
func get_yield_multiplier() -> float:
	var realm := get_realm()
	return 1.20 if realm != null and realm.tier >= 8 else 1.0


## 元婴「元婴出窍」：离线结算效率 +15%
func get_offline_efficiency() -> float:
	var realm := get_realm()
	var base := 1.15 if realm != null and realm.tier >= 3 else 1.0
	var total := base + get_natal_bonus("offline_efficiency") \
		+ FishingTeaSystem.get_bonus("offline_efficiency") \
		+ FiveElementsSystem.get_bonus("offline_efficiency")
	return clampf(total, 1.0, 2.2)


## 金丹「洞府灵阵」等境界级全局减耗
func get_realm_interval_multiplier() -> float:
	var realm := get_realm()
	if realm == null:
		return 1.0
	return clampf(realm.action_interval_multiplier, 0.5, 1.0)


func get_quality_name(quality: int) -> String:
	var index := clampi(quality, 0, 2)
	return String(QUALITY_NAMES[index])


func get_quality_multiplier(quality: int) -> float:
	return float(QUALITY_MULTIPLIERS[clampi(quality, 0, 2)])


## 真实命中总额（可超过 100%），用于抵消敌人闪避。
func get_raw_accuracy() -> float:
	return BASE_ACCURACY \
		+ (_equip_stat("weapon", "accuracy") + _equip_stat("armor", "accuracy")) / 100.0


## 面板展示总命中，不截断在 0.99，便于玩家判断高闪避目标。
func get_accuracy() -> float:
	return get_raw_accuracy()


## 玩家闪避：基础 5% + 装备闪避词条，夹取 5%~45%。
func get_dodge() -> float:
	var total := 0.05 \
		+ (_equip_stat("armor", "dodge_bonus")
		+ _equip_stat("weapon", "dodge_bonus")) / 100.0
	return clampf(total, 0.05, 0.45)


func get_player_stats() -> Dictionary:
	return {
		"max_hp": get_max_hp(),
		"attack": get_attack(),
		"defense": get_defense(),
		"accuracy": get_accuracy(),
		"raw_accuracy": get_raw_accuracy(),
		"dodge": get_dodge(),
		"interval": maxf(0.55, BASE_ATTACK_INTERVAL
			* maxf(0.5, 1.0 + GameFormulas.get_technique_bonus("attack_interval"))
			* maxf(0.5, 1.0 - get_natal_bonus("attack_interval_reduction"))
			* maxf(0.5, 1.0 - FiveElementsSystem.get_bonus("attack_interval_reduction"))),
	}


# ---------------------------------------------------------------- 技能 / 经验

func get_skill_xp(skill_id: String) -> float:
	return float(skill_xp.get(skill_id, 0.0))


## 境界技能上限锁经验：把全部百艺经验钳制到当前大境界上限（溢出直接舍弃，不暂存）。
## 读档 / 云端导入 / 旧档迁移完成后统一调用；突破大境界后上限变大，自然解锁续修。
func clamp_skill_xp_to_cap() -> void:
	var cap_xp := GameFormulas.xp_for_level(get_skill_level_cap())
	for skill_id in DataRegistry.skill_order:
		skill_xp[skill_id] = clampf(get_skill_xp(skill_id), 0.0, cap_xp)


func get_skill_level(skill_id: String) -> int:
	return GameFormulas.level_for_xp(get_skill_xp(skill_id), get_skill_level_cap())


func get_skill_progress(skill_id: String) -> Dictionary:
	var level := get_skill_level(skill_id)
	var cap := get_skill_level_cap()
	var current := get_skill_xp(skill_id)
	var floor_xp := GameFormulas.xp_for_level(level)
	var next_xp := GameFormulas.xp_for_level(mini(level + 1, GameFormulas.MAX_SKILL_LEVEL))
	var span := maxf(1.0, next_xp - floor_xp)
	var ratio := clampf((current - floor_xp) / span, 0.0, 1.0)
	if level >= cap:
		ratio = 1.0
	return {
		"level": level,
		"cap": cap,
		"xp": current,
		"into": maxf(0.0, current - floor_xp),
		"need": span,
		"ratio": ratio,
		"capped": level >= cap,
	}


## 技能经验百分比加成：悟道池 10% 里程碑 +5%、图鉴 20% 里程碑 +5%、元婴/大乘境界加成
func get_skill_gain_bonus(skill_id: String) -> float:
	var bonus := 1.05 if is_pool_threshold(skill_id, 0.10) else 1.0
	# 万象玉简 20% 里程碑：技能全局经验 +5%
	bonus *= 1.0 + GameFormulas.get_codex_bonus("xp")
	# 元婴「元婴出窍」：全技能经验 +10%
	bonus *= get_skill_xp_multiplier()
	# 本命法宝器纹：悟道器纹提升百艺悟道效率
	bonus *= 1.0 + get_natal_bonus("skill_gain")
	# 灵鱼养神汤：全百艺经验获取 +12%
	bonus *= 1.0 + FishingTeaSystem.get_bonus("skill_gain")
	return bonus


## 单次基础经验 → 实际入账经验（UI 展示与实际入账共用这一口径）
func get_skill_gain(skill_id: String, base_amount: float) -> int:
	return GameFormulas.scale_skill_gain(base_amount, get_skill_gain_bonus(skill_id))


func get_action_skill_xp_gain(action_id: String) -> int:
	var action := DataRegistry.get_action(action_id)
	if action == null:
		return 0
	# 已到境界上限时实际入账为 0，展示值必须同为 0
	if get_skill_level(action.skill_id) >= get_skill_level_cap():
		return 0
	return get_skill_gain(action.skill_id, action.skill_xp)


## 入账入口：传入基础经验，统一乘全局倍率与各项加成
func add_skill_xp(skill_id: String, amount: float) -> int:
	if amount <= 0.0:
		return 0
	return grant_skill_xp(skill_id, get_skill_gain(skill_id, amount))


## 已按新公式算好的经验直接入账（离线补算等聚合场景，避免二次乘算）。
## 境界技能上限锁经验：等级与累计经验严格钳制在当前大境界上限，
## 溢出经验直接舍弃（不累计、不暂存，突破大境界后从上限节点自然续修，
## 绝不会出现「突破后一次性连跳多级」）。
func grant_skill_xp(skill_id: String, gain: int) -> int:
	if gain <= 0:
		return 0
	var cap := get_skill_level_cap()
	var current_level := get_skill_level(skill_id)
	var cap_xp := GameFormulas.xp_for_level(cap)
	# 兜底钳制：即便历史/云端数据带入越界经验，也先压回上限再结算
	var before := clampf(get_skill_xp(skill_id), 0.0, cap_xp)
	if current_level >= cap:
		skill_xp[skill_id] = cap_xp
		# 满级后百艺经验半数化入悟道（消浪费感，供淬炼/高阶消耗）
		add_pool_xp(skill_id, float(gain) * 0.5)
		# 值虽不变仍广播一次：保证满级横幅/进度条在持续挂机时始终同步
		EventBus.skill_xp_changed.emit(skill_id, cap_xp, cap)
		EventBus.stats_changed.emit()
		return 0
	var room := maxf(0.0, cap_xp - before)
	var into_levels := minf(float(gain), room)
	var overflow := float(gain) - into_levels
	var total := minf(before + into_levels, cap_xp)
	skill_xp[skill_id] = total
	var new_level := get_skill_level(skill_id)
	EventBus.skill_xp_changed.emit(skill_id, total, new_level)
	EventBus.stats_changed.emit()
	if new_level > current_level:
		# 自动挂机升级不震动（禁震红线），只保留界面提示与音效
		EventBus.skill_level_up.emit(skill_id, new_level)
		push_activity_log("%s 升至 %d 重" % [DataRegistry.get_skill_name(skill_id), new_level], "good")
	# 升至满级当次的溢出部分同样半数化入悟道
	if overflow > 0.0:
		add_pool_xp(skill_id, overflow * 0.5)
	return maxi(0, int(roundf(total - before)))


# ---------------------------------------------------------------- 火候 / 悟道池

func get_mastery_xp(action_id: String) -> float:
	return float(action_mastery_xp.get(action_id, 0.0))


func get_mastery_level(action_id: String) -> int:
	return GameFormulas.mastery_level_for_xp(get_mastery_xp(action_id))


## 单门百艺总火候：该技能全部动作的火候等级之和（未练过的按初始 1 重计入）。
## 实时由 action_mastery_xp 派生，不落存档，老存档零迁移风险。
func get_skill_total_mastery(skill_id: String) -> int:
	var total := 0
	for action_id in DataRegistry.get_action_ids_for_skill(skill_id):
		total += maxi(1, get_mastery_level(action_id))
	return total


func get_mastery_progress(action_id: String) -> Dictionary:
	var level := get_mastery_level(action_id)
	var current := get_mastery_xp(action_id)
	var floor_xp := GameFormulas.mastery_xp_for_level(level)
	var next_xp := GameFormulas.mastery_xp_for_level(mini(level + 1, GameFormulas.MAX_MASTERY_LEVEL))
	var span := maxf(1.0, next_xp - floor_xp)
	return {
		"level": level,
		"xp": current,
		"into": maxf(0.0, current - floor_xp),
		"need": span,
		"ratio": clampf((current - floor_xp) / span, 0.0, 1.0),
		"maxed": level >= GameFormulas.MAX_MASTERY_LEVEL,
	}


## 单次火候经验：基础值 × 全局火候倍率（UI 展示与实际入账共用）
func get_mastery_gain(base_amount: float) -> int:
	# 灵鱼养神汤：全百艺火候获取 +12%
	return GameFormulas.scale_mastery_gain(base_amount
		* (1.0 + FishingTeaSystem.get_bonus("mastery_gain")))


func get_action_mastery_xp_gain(action_id: String) -> int:
	var action := DataRegistry.get_action(action_id)
	if action == null:
		return 0
	if get_mastery_level(action_id) >= GameFormulas.MAX_MASTERY_LEVEL:
		return 0
	return get_mastery_gain(action.mastery_xp)


## 入账入口：传基础火候经验，统一乘全局倍率
func add_mastery_xp(action_id: String, amount: float) -> int:
	if amount <= 0.0:
		return 0
	return grant_mastery_xp(action_id, get_mastery_gain(amount))


## 已按新公式算好的火候经验直接入账（离线聚合）
func grant_mastery_xp(action_id: String, gain: int) -> int:
	if gain <= 0:
		return 0
	var max_xp := GameFormulas.mastery_xp_for_level(GameFormulas.MAX_MASTERY_LEVEL)
	var before := get_mastery_xp(action_id)
	if before < max_xp:
		var before_level := get_mastery_level(action_id)
		action_mastery_xp[action_id] = minf(before + float(gain), max_xp)
		var after_level := get_mastery_level(action_id)
		EventBus.mastery_changed.emit(action_id, action_mastery_xp[action_id], after_level)
		if after_level > before_level:
			EventBus.mastery_level_up.emit(action_id, after_level)
			push_activity_log("%s 火候 %d 重" % [
				DataRegistry.get_action_name(action_id), after_level], "normal")
	var action := DataRegistry.get_action(action_id)
	if action != null:
		# 悟道池注入同样以“实际入账火候经验”为基准
		add_pool_xp(action.skill_id, float(gain) * GameFormulas.POOL_RATIO)
	return maxi(0, int(roundf(get_mastery_xp(action_id) - before)))


func get_pool_capacity(skill_id: String) -> float:
	return GameFormulas.pool_capacity(DataRegistry.get_skill_action_count(skill_id))


func get_pool_current(skill_id: String) -> float:
	return float(mastery_pool.get(skill_id, 0.0))


func add_pool_xp(skill_id: String, amount: float) -> void:
	if amount <= 0.0:
		return
	# 悟道清茶：悟道池充能 +25%，统一入口覆盖在线、离线与满级溢出。
	amount *= 1.0 + FishingTeaSystem.get_bonus("pool_charge")
	var capacity := get_pool_capacity(skill_id)
	var current := get_pool_current(skill_id)
	if current >= capacity:
		return
	var unlocked_before := _pool_unlocked_count(skill_id)
	current = minf(current + amount, capacity)
	mastery_pool[skill_id] = current
	EventBus.mastery_pool_changed.emit(skill_id, current, capacity)
	# 里程碑跨档属于惊喜事件：仅在前进档位且非离线结算时给一次中震
	if not offline_settling and _pool_unlocked_count(skill_id) > unlocked_before:
		vibrate_medium()


func _pool_unlocked_count(skill_id: String) -> int:
	var capacity := get_pool_capacity(skill_id)
	if capacity <= 0.0:
		return 0
	var ratio := get_pool_current(skill_id) / capacity
	var count := 0
	for entry in GameFormulas.POOL_THRESHOLDS:
		if ratio >= float(entry["ratio"]) - 0.0001:
			count += 1
	return count


func is_pool_threshold(skill_id: String, ratio: float) -> bool:
	var capacity := get_pool_capacity(skill_id)
	if capacity <= 0.0:
		return false
	return get_pool_current(skill_id) / capacity >= ratio - 0.0001


func get_pool_info(skill_id: String) -> Dictionary:
	var capacity := get_pool_capacity(skill_id)
	var current := get_pool_current(skill_id)
	var ratio := GameFormulas.pool_ratio(current, capacity)
	var active: Array[String] = []
	var next_label := ""
	for entry in GameFormulas.POOL_THRESHOLDS:
		var threshold := float(entry["ratio"])
		if ratio >= threshold - 0.0001:
			active.append(String(entry["label"]))
		elif next_label == "":
			next_label = String(entry["label"])
	return {
		"current": current,
		"capacity": capacity,
		"ratio": ratio,
		"active": active,
		"next": next_label,
	}


## 花费悟道池直接提升某个动作的火候（返回预览信息用于 UI 提示）
func preview_mastery_spend(action_id: String) -> Dictionary:
	var action := DataRegistry.get_action(action_id)
	if action == null:
		return {"ok": false, "cost": 0.0, "warnings": ["动作不存在"]}
	var level := get_mastery_level(action_id)
	if level >= GameFormulas.MAX_MASTERY_LEVEL:
		return {"ok": false, "cost": 0.0, "warnings": ["火候已至圆满"]}
	var cost := GameFormulas.mastery_xp_for_level(level + 1) - get_mastery_xp(action_id)
	cost = maxf(1.0, cost)
	var capacity := get_pool_capacity(action.skill_id)
	var pool := get_pool_current(action.skill_id)
	var warnings: Array[String] = []
	if pool < cost:
		warnings.append("悟道池不足，尚需 %s" % GameFormulas.format_num(cost - pool))
	var after := maxf(0.0, pool - cost)
	for entry in GameFormulas.POOL_THRESHOLDS:
		var threshold := float(entry["ratio"])
		if capacity <= 0.0:
			continue
		if pool / capacity >= threshold and after / capacity < threshold:
			warnings.append("将跌破 %s 里程碑：%s" % [String(entry["label"]), String(entry["effect"])])
	return {"ok": pool >= cost, "cost": cost, "warnings": warnings, "level": level}


func spend_pool_for_mastery(action_id: String) -> bool:
	var preview := preview_mastery_spend(action_id)
	if not bool(preview.get("ok", false)):
		EventBus.toast.emit("悟道池不足，无法淬炼火候")
		return false
	var action := DataRegistry.get_action(action_id)
	if action == null:
		return false
	var cost := float(preview.get("cost", 0.0))
	var skill_id := action.skill_id
	var capacity := get_pool_capacity(skill_id)
	mastery_pool[skill_id] = maxf(0.0, get_pool_current(skill_id) - cost)
	EventBus.mastery_pool_changed.emit(skill_id, get_pool_current(skill_id), capacity)
	var level := get_mastery_level(action_id)
	action_mastery_xp[action_id] = GameFormulas.mastery_xp_for_level(mini(level + 1, GameFormulas.MAX_MASTERY_LEVEL))
	EventBus.mastery_changed.emit(action_id, get_mastery_xp(action_id), get_mastery_level(action_id))
	EventBus.toast.emit("以悟道池淬炼：%s 火候提升至 %d 级" % [action.display_name, get_mastery_level(action_id)])
	return true


# ---------------------------------------------------------------- 背包

func get_item_count(item_id: String) -> int:
	return int(inventory.get(item_id, 0))


func add_item(item_id: String, amount: int = 1) -> void:
	if amount <= 0:
		return
	if DataRegistry.get_item(item_id) == null:
		return
	inventory[item_id] = get_item_count(item_id) + amount
	discover_item(item_id)
	if item_id == DataRegistry.SPIRIT_STONE:
		stats["spirit_stones_earned"] = int(stats.get("spirit_stones_earned", 0)) + amount
	# 批处理事务期间只改内存记脏，退出时统一补发一次汇总信号
	if _batch_depth > 0 or change_signals_muted:
		_batch_dirty = true
		return
	EventBus.item_gained.emit(item_id, amount)
	EventBus.inventory_changed.emit()
	EventBus.stats_changed.emit()


func add_fine_item(item_id: String, amount: int = 1) -> void:
	if amount <= 0:
		return
	fine_items[item_id] = int(fine_items.get(item_id, 0)) + amount


func add_epic_item(item_id: String, amount: int = 1) -> void:
	if amount <= 0:
		return
	epic_items[item_id] = int(epic_items.get(item_id, 0)) + amount


func get_quality_count(item_id: String, quality: int) -> int:
	if quality == 2:
		return int(epic_items.get(item_id, 0))
	if quality == 1:
		return int(fine_items.get(item_id, 0))
	return get_item_count(item_id)


## 出售品质变体（精良 ×2 价 / 极品 ×3 价）
func sell_quality_item(item_id: String, amount: int, quality: int) -> int:
	var item := DataRegistry.get_item(item_id)
	if item == null or quality <= 0:
		return 0
	var have := get_quality_count(item_id, quality)
	var count := mini(amount, have)
	if count <= 0:
		return 0
	var store: Dictionary = epic_items if quality == 2 else fine_items
	store[item_id] = have - count
	var price_mult := 3 if quality == 2 else 2
	var gained := item.sell_price * price_mult * count
	add_item(DataRegistry.SPIRIT_STONE, gained)
	EventBus.inventory_changed.emit()
	EventBus.toast.emit("出售 %s（%s）×%d，得灵石 %d" % [
		item.display_name, get_quality_name(quality), count, gained])
	return gained


## 批量落账期间临时静音 inventory_changed（如灵田一键催熟连扣草药），
## 避免逐次触发全卡重建造成卡顿；结束时由调用方补发一次信号
var change_signals_muted := false
## 批处理静默事务：begin_batch 后单项变更只改内存并记脏，
## end_batch 深度归零时统一补发一次汇总信号（可嵌套）
var _batch_depth: int = 0
var _batch_dirty: bool = false


func begin_batch() -> void:
	_batch_depth += 1
	change_signals_muted = true


func end_batch() -> void:
	_batch_depth = maxi(0, _batch_depth - 1)
	if _batch_depth > 0:
		return
	change_signals_muted = false
	if _batch_dirty:
		_batch_dirty = false
		EventBus.inventory_changed.emit()
		EventBus.stats_changed.emit()


func remove_item(item_id: String, amount: int = 1) -> bool:
	if amount <= 0:
		return true
	var have := get_item_count(item_id)
	if have < amount:
		return false
	if have == amount:
		inventory.erase(item_id)
	else:
		inventory[item_id] = have - amount
	if _batch_depth > 0 or change_signals_muted:
		_batch_dirty = true
	else:
		EventBus.inventory_changed.emit()
	return true


func has_items(required: Dictionary) -> bool:
	for key in required.keys():
		if get_item_count(String(key)) < int(required[key]):
			return false
	return true


func max_affordable(required: Dictionary) -> int:
	var best := 999999
	for key in required.keys():
		var need := int(required[key])
		if need <= 0:
			continue
		best = mini(best, get_item_count(String(key)) / need)
	return maxi(0, best)


func consume_many(required: Dictionary, times: int) -> void:
	if times <= 0:
		return
	for key in required.keys():
		remove_item(String(key), int(required[key]) * times)


## 按品质扣减库存（0 凡品走 inventory / 1 精良 / 2 极品）
func remove_quality_item(item_id: String, amount: int, quality: int) -> bool:
	if quality <= 0:
		return remove_item(item_id, amount)
	var store: Dictionary = epic_items if quality == 2 else fine_items
	var have := get_quality_count(item_id, quality)
	var count := mini(amount, have)
	if count <= 0:
		return false
	store[item_id] = have - count
	EventBus.inventory_changed.emit()
	return true


## 淘汰装备批量熔炼（原子结算）。
## targets: [{ "item_id": String, "quality": int(0/1/2), "count": int }]
## 已穿戴装备天然受保护：equip_item 时它已从三本库存账中扣走，只存在于
## equipment 字典里，熔炼只动 inventory / fine_items / epic_items 三本账。
func smelt_obsolete_equipment(targets: Array, mode: String) -> Dictionary:
	var smelted := 0
	var total_stones := 0
	var total_materials: Dictionary = {}
	# 批处理静默事务：循环内只改内存，退出时统一补发一次信号
	begin_batch()
	for entry in targets:
		var dict := _as_dict(entry)
		var item_id := String(dict.get("item_id", ""))
		var quality := clampi(int(dict.get("quality", 0)), 0, 2)
		var count := int(dict.get("count", 0))
		if item_id == "" or count <= 0:
			continue
		var item := DataRegistry.get_item(item_id)
		if item == null or not item.is_equipment():
			continue
		var have := get_quality_count(item_id, quality)
		var real_count := mini(count, have)
		if real_count <= 0:
			continue
		# 单位收益 × 实际件数（堆叠 5 件就必须返 5 份）
		var smelt_yield: Dictionary = DataRegistry.get_equipment_smelt_yield(item_id, quality, mode)
		var stones := int(smelt_yield.get("stones", 0)) * real_count
		var materials: Dictionary = smelt_yield.get("materials", {})
		var removed := true
		for item_key in materials.keys():
			var give := int(materials[item_key]) * real_count
			if give > 0:
				add_item(String(item_key), give)
		if stones > 0:
			add_item(DataRegistry.SPIRIT_STONE, stones)
		# 先加返还再扣装备：即使中途中断玩家也不吃亏
		if not remove_quality_item(item_id, real_count, quality):
			removed = false
		if not removed:
			continue
		smelted += real_count
		total_stones += stones
		for item_key in materials.keys():
			total_materials[item_key] = int(total_materials.get(item_key, 0)) \
				+ int(materials[item_key])
	if smelted > 0:
		vibrate_medium()
	end_batch()
	return {
		"smelted_count": smelted,
		"stones": total_stones,
		"materials": total_materials,
	}


## 低阶材料一键化灵：原子结算——逐项复核实际库存后扣除，按化灵单价累加灵石。
## 不新增存档字段（灵石本就是背包物品），老存档零迁移。
func dissolve_materials_for_stones(item_counts: Dictionary) -> int:
	var total := 0
	begin_batch()
	for key in item_counts.keys():
		var item_id := String(key)
		var want := int(item_counts[key])
		if want <= 0 or item_id == DataRegistry.SPIRIT_STONE:
			continue
		var count: int = mini(want, get_item_count(item_id))
		if count <= 0:
			continue
		var value := DataRegistry.get_material_dissolve_value(item_id)
		if value <= 0:
			continue
		if not remove_item(item_id, count):
			continue
		total += value * count
	if total > 0:
		add_item(DataRegistry.SPIRIT_STONE, total)
		vibrate_medium()
	end_batch()
	return total


func sell_item(item_id: String, amount: int = 1) -> int:
	if item_id == DataRegistry.SPIRIT_STONE:
		EventBus.toast.emit("灵石乃通用之资，无法出售")
		return 0
	var item := DataRegistry.get_item(item_id)
	if item == null:
		return 0
	var have := get_item_count(item_id)
	var count := mini(amount, have)
	if count <= 0:
		return 0
	if not remove_item(item_id, count):
		return 0
	var gained := item.sell_price * count
	add_item(DataRegistry.SPIRIT_STONE, gained)
	EventBus.toast.emit("出售 %s ×%d，得灵石 %d" % [item.display_name, count, gained])
	if AudioManager != null:
		AudioManager.play_coin()
	vibrate_light()
	return gained


func use_item(item_id: String) -> bool:
	var item := DataRegistry.get_item(item_id)
	if item == null or not item.is_consumable():
		return false
	if get_item_count(item_id) <= 0:
		return false
	# 灵田专属奇珍：动态效果，不走静态 cultivation/heal 字段
	if item_id == DataRegistry.SPIRIT_DEW:
		return _use_spirit_dew(item)
	if item_id == DataRegistry.CRIMSON_FRUIT:
		return _use_crimson_fruit(item)
	# 护道清心丹：直接加 1 层本境界道心（上限 5 层）
	if item_id == DataRegistry.QINGXIN_PILL:
		if get_dao_heart_stacks() >= DAO_HEART_MAX:
			EventBus.toast.emit("本境界道心已至 %d 层圆满" % DAO_HEART_MAX)
			return false
		remove_item(item_id, 1)
		add_dao_heart_stack()
		EventBus.toast.emit("服下 %s，道心悟性 +1（当前 %d 层）" % [
			item.display_name, get_dao_heart_stacks()])
		vibrate_light()
		if AudioManager != null:
			AudioManager.play_equip_use()
		return true
	if item.heal_amount > 0:
		var max_hp := get_max_hp()
		# 九转回元丹这类「回血 + 修为」双效丹：任一效果可用即允许服用
		var can_heal := current_hp < max_hp
		var can_cultivate := item.cultivation_gain > 0 \
			and get_realm_requirement() > 0.0 and not is_cultivation_full()
		if not can_heal and not can_cultivate:
			EventBus.toast.emit("气血充盈，无需服用")
			return false
		remove_item(item_id, 1)
		var notes: Array[String] = []
		if can_heal:
			var healed := get_heal_amount(item)
			current_hp = mini(max_hp, current_hp + healed)
			notes.append("回复 %d 气血" % healed)
		if can_cultivate:
			var cult_gain := get_consumable_cultivation_gain(item)
			add_cultivation(float(cult_gain))
			notes.append("修为 +%d" % cult_gain)
		EventBus.stats_changed.emit()
		EventBus.toast.emit("服用 %s，%s" % [item.display_name, "，".join(notes)])
		vibrate_light()
		if AudioManager != null:
			AudioManager.play_equip_use()
		return true
	if item.cultivation_gain > 0:
		if get_realm_requirement() <= 0.0 or is_cultivation_full():
			EventBus.toast.emit("当前修为已至上限，无需服用")
			return false
		var gain := get_consumable_cultivation_gain(item)
		remove_item(item_id, 1)
		add_cultivation(float(gain))
		EventBus.toast.emit("服用 %s，修为 +%d" % [item.display_name, gain])
		vibrate_light()
		if AudioManager != null:
			AudioManager.play_equip_use()
		return true
	if DataRegistry.is_tribulation_ticket(item.id):
		# 四种突破丹药（筑基丹/结金丹/化婴丹/渡劫飞升丹）统一按物品名提示
		EventBus.toast.emit("%s需在「引动天劫」面板中投入" % item.display_name)
		return false
	if item.ward_ratio > 0.0:
		EventBus.toast.emit("%s 会在战斗与渡劫中自动生效" % item.display_name)
		return false
	return false


## 手动服丹 / 灵果的实际修为：与吐纳自动服丹、聚灵甘露走同一套乘区
## （综合修为倍率 = 1 + 坊市 cultivation_pct + 灵田灵气反哺；再乘《周天吐纳真解》meditate_xp）
func get_consumable_cultivation_gain(item: ItemData) -> int:
	if item == null or item.cultivation_gain <= 0:
		return 0
	var gain := float(item.cultivation_gain) * get_cultivation_multiplier()
	gain *= 1.0 + GameFormulas.get_technique_bonus("meditate_xp")
	return maxi(1, int(roundf(gain)))


## 吐纳单次实际修为（自动服丹生效时按丹药值算）：与 ActionRunner._complete_meditate 同一口径，供 UI 展示
func get_meditate_cultivation_gain(action_id: String) -> int:
	var action := DataRegistry.get_action(action_id)
	if action == null or action.cultivation_gain <= 0:
		return 0
	var base := action.cultivation_gain
	if action.pill_item_id != "" and bool(flags.get("auto_pill", false)) \
			and action.pill_cultivation_gain > 0 \
			and get_item_count(action.pill_item_id) > 0:
		base = action.pill_cultivation_gain
	var gain := float(base) * get_cultivation_multiplier()
	gain *= 1.0 + GameFormulas.get_technique_bonus("meditate_xp")
	return maxi(1, int(roundf(gain)))


## 聚灵甘露：按当前小境界突破所需修为的 3% 结算（保底 120），受吐纳加成
func get_spirit_dew_gain() -> int:
	var requirement := get_realm_requirement()
	if requirement <= 0.0:
		return 0
	var gain := maxf(120.0, requirement * 0.03)
	gain *= get_cultivation_multiplier()
	gain *= 1.0 + GameFormulas.get_technique_bonus("meditate_xp")
	return int(roundf(gain))


func _use_spirit_dew(item: ItemData) -> bool:
	if get_realm_requirement() <= 0.0 or is_cultivation_full():
		EventBus.toast.emit("当前修为已至上限，无需服用聚灵甘露")
		return false
	var gain := get_spirit_dew_gain()
	remove_item(item.id, 1)
	add_cultivation(float(gain))
	EventBus.toast.emit("服下聚灵甘露，修为 +%d" % gain)
	vibrate_light()
	if AudioManager != null:
		AudioManager.play_equip_use()
	return true


func _use_crimson_fruit(item: ItemData) -> bool:
	if crimson_fruit_eaten >= GameFormulas.CRIMSON_FRUIT_CAP:
		EventBus.toast.emit("已炼化 %d 枚百年朱果，再多也无益，可高价出售"
			% GameFormulas.CRIMSON_FRUIT_CAP)
		return false
	remove_item(item.id, 1)
	crimson_fruit_eaten += 1
	current_hp = mini(get_max_hp(), current_hp + GameFormulas.CRIMSON_FRUIT_HP)
	EventBus.stats_changed.emit()
	EventBus.toast.emit("炼化百年朱果：最大气血 +%d、攻击 +%d（已炼化 %d / %d）" % [
		GameFormulas.CRIMSON_FRUIT_HP, GameFormulas.CRIMSON_FRUIT_ATK,
		crimson_fruit_eaten, GameFormulas.CRIMSON_FRUIT_CAP])
	vibrate_light()
	if AudioManager != null:
		AudioManager.play_equip_use()
	return true


# ---------------------------------------------------------------- 装备

func equip_item(item_id: String) -> bool:
	if int(epic_items.get(item_id, 0)) > 0:
		return equip_item_with_quality(item_id, 2)
	if int(fine_items.get(item_id, 0)) > 0:
		return equip_item_with_quality(item_id, 1)
	return equip_item_with_quality(item_id, 0)


## 指定品质穿戴：供储物袋按品质拆格后的单格操作使用，存档字段不变
func equip_item_with_quality(item_id: String, requested_quality: int) -> bool:
	var item := DataRegistry.get_item(item_id)
	if item == null or not item.is_equipment():
		return false
	if get_quality_count(item_id, requested_quality) <= 0:
		return false
	var slot := item.equip_slot
	if not EQUIP_SLOTS.has(slot):
		return false
	var quality := clampi(requested_quality, 0, 2)
	if quality == 2:
		epic_items[item_id] = int(epic_items[item_id]) - 1
	elif quality == 1:
		fine_items[item_id] = int(fine_items[item_id]) - 1
	else:
		remove_item(item_id, 1)
	var old := _as_dict(equipment.get(slot, {}))
	var old_id := String(old.get("id", ""))
	if old_id != "":
		add_item(old_id, 1)
		var old_quality := clampi(int(old.get("quality", 0)), 0, 2)
		if old_quality == 2:
			add_epic_item(old_id, 1)
		elif old_quality == 1:
			add_fine_item(old_id, 1)
	equipment[slot] = {"id": item_id, "quality": quality}
	current_hp = mini(current_hp, get_max_hp())
	EventBus.equipment_changed.emit()
	EventBus.stats_changed.emit()
	var suffix := "" if quality == 0 else "（%s）" % get_quality_name(quality)
	EventBus.toast.emit("已装备 %s%s" % [item.display_name, suffix])
	vibrate_light()
	if AudioManager != null:
		AudioManager.play_equip_puton()
	return true


func unequip_slot(slot: String) -> bool:
	var entry := _as_dict(equipment.get(slot, {}))
	var item_id := String(entry.get("id", ""))
	if item_id == "":
		return false
	add_item(item_id, 1)
	var quality := clampi(int(entry.get("quality", 0)), 0, 2)
	if quality == 2:
		add_epic_item(item_id, 1)
	elif quality == 1:
		add_fine_item(item_id, 1)
	equipment[slot] = {"id": "", "quality": 0}
	current_hp = mini(current_hp, get_max_hp())
	EventBus.equipment_changed.emit()
	EventBus.stats_changed.emit()
	vibrate_light()
	if AudioManager != null:
		AudioManager.play_equip_puton()
	return true


func get_equipped(slot: String) -> Dictionary:
	return _as_dict(equipment.get(slot, {}))


## 大境界奖励倍率（悬赏灵石 / 镇魔俸禄共用）
func get_realm_reward_mult() -> float:
	var realm := get_realm()
	var tier := 0 if realm == null else realm.tier
	return REALM_REWARD_MULT[clampi(tier, 0, REALM_REWARD_MULT.size() - 1)]


## 每日镇魔俸禄：自然日（UTC 天数）重置，旧档缺字段默认 -1
func get_tower_salary_day() -> int:
	return int(Time.get_unix_time_from_system() / 86400.0)


func can_claim_tower_salary() -> bool:
	return tower_highest_floor >= 1 and last_tower_salary_day != get_tower_salary_day()


## 领取今日镇魔俸禄：灵石 = 最高层 × 境界倍率 × 100，贡献 = 最高层 × 倍率 / 2
func claim_tower_salary() -> Dictionary:
	if not can_claim_tower_salary():
		return {}
	last_tower_salary_day = get_tower_salary_day()
	var mult := get_realm_reward_mult()
	var stones := int(round(float(tower_highest_floor) * mult * 100.0))
	var points := maxi(1, int(round(float(tower_highest_floor) * mult * 0.5)))
	add_item(DataRegistry.SPIRIT_STONE, stones)
	alliance_points += points
	EventBus.stats_changed.emit()
	return {"stones": stones, "points": points}


# ---------------------------------------------------------------- 动作槽位

## 已解锁的百艺槽位数：主修始终开启；分神沿用境界原逻辑；
## 第三槽「身外化身」提前到金丹初期（realm_order>=12 / tier>=2）。
func get_max_action_slots() -> int:
	var realm := get_realm()
	if realm == null:
		return 1
	var base := clampi(realm.max_action_slots, 1, SLOT_COUNT)
	if get_realm_index() >= 12:
		return SLOT_COUNT
	return mini(base, 2)


## 兼容旧调用名
func get_slot_capacity() -> int:
	return get_max_action_slots()


## 战斗是否独立于百艺槽位：筑基「神识御敌」起为 true（秘境与百艺并行，互不打断）
func is_combat_independent() -> bool:
	var realm := get_realm()
	return realm != null and realm.combat_independent


## 槽位名：0 主修 / 1 分神 / 2 化身
func get_slot_name(slot_idx: int) -> String:
	if slot_idx >= 0 and slot_idx < SLOT_CONFIGS.size():
		return String((SLOT_CONFIGS[slot_idx] as Dictionary)["name"])
	return "槽位%d" % (slot_idx + 1)


## 槽位文案统一出口（start / running / stop）
func get_slot_text(slot_idx: int, kind: String) -> String:
	if slot_idx >= 0 and slot_idx < SLOT_CONFIGS.size():
		return String((SLOT_CONFIGS[slot_idx] as Dictionary).get(kind, ""))
	return ""


## 槽位是否已解锁（严格按当前境界的 max_action_slots）
func is_slot_unlocked(slot_idx: int) -> bool:
	return slot_idx >= 0 and slot_idx < get_max_action_slots()


## 动作当前占用的槽位索引（0/1/2），未运行返回 -1
func get_action_running_slot(action_id: String) -> int:
	return get_slot_of_action(action_id)


## 动作原料是否充足（空配方视为充足）
func has_ingredients(action_id: String) -> bool:
	var action := DataRegistry.get_action(action_id)
	if action == null:
		return false
	return action.inputs.is_empty() or has_items(action.inputs)


## 第 slot_idx 槽的解锁境界名（已解锁返回空串）：第一/二槽沿用原逻辑，第三槽金丹初期
func get_slot_unlock_hint(slot_idx: int) -> String:
	if slot_idx < get_max_action_slots():
		return ""
	match slot_idx:
		1:
			return "筑基初期"
		2:
			return "金丹初期"
	return "未解锁"


## 正在运转的百艺动作数量（不含秘境历练）
func count_active_actions() -> int:
	var count := 0
	for i in range(SLOT_COUNT):
		if active_slots[i] != "":
			count += 1
	return count


## 运转中的槽位索引（0→1→2 确定性升序）
func get_running_slots() -> Array[int]:
	var out: Array[int] = []
	for i in range(SLOT_COUNT):
		if active_slots[i] != "":
			out.append(i)
	return out


## 代表槽位：固定优先级 0（主修）→ 1（分神）→ 2（化身），
## 避免后启动/后台结算导致胶囊文字乱跳
func get_primary_slot() -> int:
	for i in range(SLOT_COUNT):
		if active_slots[i] != "":
			return i
	return -1


## 展示槽位 → 实际动作槽位：秘境历练固定占主修展示位，百艺顺延到分神展示位
func get_display_action_slot(display_slot: int) -> int:
	if display_slot < 0 or display_slot >= SLOT_COUNT:
		return -1
	var combat := CombatEngine != null and CombatEngine.is_active()
	if not combat:
		return display_slot if active_slots[display_slot] != "" else -1
	if display_slot != 1:
		return -1
	if active_slots[0] != "":
		return 0
	if active_slots[1] != "":
		return 1
	return -1


## 展示槽位上正在运转的百艺动作 id（秘境占位时返回顺延到分神位的动作）
func get_display_action_id(display_slot: int) -> String:
	var real_slot := get_display_action_slot(display_slot)
	return "" if real_slot < 0 else active_slots[real_slot]


## 秘境入场前的槽位仲裁：
##   · 筑基起「神识御敌」：战斗独立于百艺，完全不占用、也不打断任何 active_slots；
##   · 炼气期：战斗与百艺互斥，清空全部百艺槽并回传被停项名称。
func reserve_combat_slot() -> Array[String]:
	var stopped: Array[String] = []
	if is_combat_independent():
		return stopped
	for i in range(SLOT_COUNT):
		if active_slots[i] == "":
			continue
		stopped.append(DataRegistry.get_action_name(active_slots[i]))
		stop_action(i)
	return stopped


func get_active_action(slot: int) -> String:
	if slot < 0 or slot >= SLOT_COUNT:
		return ""
	return active_slots[slot]


func is_action_active(action_id: String) -> bool:
	return get_slot_of_action(action_id) >= 0


func get_slot_of_action(action_id: String) -> int:
	for i in range(SLOT_COUNT):
		if active_slots[i] == action_id:
			return i
	return -1


func _action_category(action_id: String) -> String:
	var action := DataRegistry.get_action(action_id)
	if action == null:
		return ""
	return DataRegistry.get_skill_category(action.skill_id)


func is_combo_allowed(action_a: String, action_b: String) -> bool:
	var cat_a := _action_category(action_a)
	var cat_b := _action_category(action_b)
	var a_gather := cat_a == "gather"
	var b_gather := cat_b == "gather"
	var a_make := cat_a == "craft" or cat_a == "meditate"
	var b_make := cat_b == "craft" or cat_b == "meditate"
	return (a_gather and b_make) or (b_gather and a_make)


## 原料缺口描述，如「青叶草 缺 2（存 0）、青灵木 缺 1（存 0）」
func get_material_shortage(required: Dictionary) -> String:
	var parts: Array[String] = []
	for key in required.keys():
		var need := int(required[key])
		var have := get_item_count(String(key))
		if have >= need:
			continue
		parts.append("%s 缺 %d（存 %d）" % [
			DataRegistry.get_item_name(String(key)), need - have, have])
	return "、".join(parts)


func start_action(action_id: String, slot_idx: int = -1) -> bool:
	# slot_idx >= 0：显式槽位按钮入口（统一校验链）；-1：自动寻位（旧调用兼容）
	if slot_idx >= 0:
		return start_action_in_slot(action_id, slot_idx)
	var action := DataRegistry.get_action(action_id)
	if action == null:
		return false
	if get_skill_level(action.skill_id) < action.required_level:
		EventBus.toast.emit("%s 修为不足：需 %d 级" % [
			DataRegistry.get_skill_name(action.skill_id),
			action.required_level,
		])
		return false
	if is_action_active(action_id):
		EventBus.toast.emit("该功法已在运转")
		return false
	# 开炉前先验料，避免白等一个进度条
	if not action.inputs.is_empty() and not has_items(action.inputs):
		var shortage := get_material_shortage(action.inputs)
		if shortage != "":
			EventBus.toast.emit("原料不足：%s" % shortage)
		else:
			EventBus.toast.emit("原料不足")
		return false
	var capacity := get_max_action_slots()
	var combat_active := CombatEngine != null and CombatEngine.is_active()
	var slot := -1

	# 炼气期「战斗与百艺互斥」：转入百艺即自动撤出秘境；筑基起战斗独立，不动百艺
	if combat_active and not is_combat_independent():
		CombatEngine.stop_combat("转入百艺运转")
		combat_active = false
		EventBus.toast.emit("已撤出秘境历练，转入「%s」" % action.display_name)

	if active_slots[0] == "":
		slot = 0
	else:
		# 2/3 槽：只在已解锁范围内找空位；互斥模式下战斗仍占 1 位
		var limit: int = mini(capacity - (1 if combat_active else 0), SLOT_COUNT)
		if is_combo_allowed(active_slots[0], action_id):
			for i in range(1, limit):
				if active_slots[i] == "":
					slot = i
					break
	if slot < 0:
		# 没有空位：换修主修位（分神 / 化身线保留，搭配不合则拒绝）
		for i in range(1, SLOT_COUNT):
			if active_slots[i] == "":
				continue
			if not is_combo_allowed(action_id, active_slots[i]):
				EventBus.toast.emit("与%s线「%s」搭配不合，请先停用该线" % [
					get_slot_name(i), DataRegistry.get_action_name(active_slots[i])])
				return false
		var previous := active_slots[0]
		if previous != "":
			stop_action(0)
			EventBus.toast.emit("已换修：%s → %s" % [
				DataRegistry.get_action_name(previous), action.display_name])
		slot = 0
	# 兜底：绝不向未解锁槽位写入
	if slot < 0 or slot >= capacity:
		return false
	active_slots[slot] = action_id
	if ActionRunner != null:
		ActionRunner.reset_progress(slot)
	EventBus.action_started.emit(slot, action_id)
	EventBus.stats_changed.emit()
	return true


## 指定槽位启动（UI 三按钮「主修 / 分神 / 化身」用）。
## 统一校验链：解锁 → 已在本槽 → 等级 → 原料 → 同动作跨槽搬家 → 目标位无缝替换。
## slot 0 走自动寻位路径（保留战艺互斥与换修提示）。
func start_action_in_slot(action_id: String, slot: int) -> bool:
	if not is_slot_unlocked(slot):
		EventBus.toast.emit("%s：需%s" % [get_slot_name(slot), get_slot_unlock_hint(slot)])
		return false
	var action := DataRegistry.get_action(action_id)
	if action == null:
		return false
	var running := get_action_running_slot(action_id)
	if running == slot:
		return true
	if get_skill_level(action.skill_id) < action.required_level:
		EventBus.toast.emit("%s 修为不足：需 %d 级" % [
			DataRegistry.get_skill_name(action.skill_id), action.required_level])
		return false
	if not has_ingredients(action_id):
		EventBus.toast.emit("原料不足：%s" % action.display_name)
		return false
	if running >= 0:
		# 同动作跨槽：安静停旧槽再落到目标槽，绝不双占（进度条不会互抢）
		stop_action(running)
	if slot == 0:
		return start_action(action_id)
	if active_slots[slot] != "":
		# 目标位忙碌：无缝替换（校验全部通过后才动旧行）
		var previous := active_slots[slot]
		stop_action(slot)
		EventBus.toast.emit("%s已换修：%s → %s" % [
			get_slot_name(slot), DataRegistry.get_action_name(previous), action.display_name])
	_place_action(slot, action_id)
	return true


func _place_action(slot: int, action_id: String) -> void:
	active_slots[slot] = action_id
	if ActionRunner != null:
		ActionRunner.reset_progress(slot)
	EventBus.action_started.emit(slot, action_id)
	EventBus.stats_changed.emit()


func stop_action(slot: int) -> void:
	if slot < 0 or slot >= SLOT_COUNT:
		return
	var action_id := active_slots[slot]
	if action_id == "":
		return
	active_slots[slot] = ""
	if ActionRunner != null:
		ActionRunner.reset_progress(slot)
	EventBus.action_stopped.emit(slot, action_id)
	EventBus.stats_changed.emit()


func stop_all_actions() -> void:
	for i in range(SLOT_COUNT):
		stop_action(i)


func get_status_text() -> String:
	var parts: Array[String] = []
	if CombatEngine != null and CombatEngine.is_active():
		var enemy := CombatEngine.get_current_enemy()
		parts.append("秘境：%s" % ("历练中" if enemy == null else enemy.display_name))
	for i in range(SLOT_COUNT):
		var action_id := active_slots[i]
		if action_id == "":
			continue
		parts.append(DataRegistry.get_action_name(action_id))
	if parts.is_empty():
		return "静修中（未运转功法）"
	return " · ".join(parts)


## 顶部槽位展示：秘境历练视为占用主修位，采集等顺延到分神位
func get_slot_display() -> Dictionary:
	var combat := CombatEngine != null and CombatEngine.is_active()
	var main_id := active_slots[0]
	var second_id := active_slots[1]
	var dual := is_dual_cultivation_unlocked()
	var result := {
		"main_text": "空闲",
		"main_running": false,
		"main_combat": false,
		"second_text": "空闲" if dual else "筑基解锁",
		"second_running": false,
	}
	if combat:
		result["main_text"] = "秘境历练中"
		result["main_running"] = true
		result["main_combat"] = true
		var side_id := get_display_action_id(1)
		if side_id != "":
			result["second_text"] = DataRegistry.get_action_name(side_id)
			result["second_running"] = true
		return result
	if main_id != "":
		result["main_text"] = DataRegistry.get_action_name(main_id)
		result["main_running"] = true
	if second_id != "":
		result["second_text"] = DataRegistry.get_action_name(second_id)
		result["second_running"] = true
	return result


## 抽屉运行圆点：0 无 / 1 主修（玉青）/ 2 分神（琥珀金）
func get_skill_running_level(skill_id: String) -> int:
	var combat := CombatEngine != null and CombatEngine.is_active()
	if combat and skill_id == "combat":
		return 1
	if active_slots[0] != "":
		var main_action := DataRegistry.get_action(active_slots[0])
		if main_action != null and main_action.skill_id == skill_id:
			return 2 if combat else 1
	if active_slots[1] != "":
		var second_action := DataRegistry.get_action(active_slots[1])
		if second_action != null and second_action.skill_id == skill_id:
			return 2
	return 0


# ---------------------------------------------------------------- 自动消耗（战斗 / 渡劫）

## 优先玄龟盾符（55%），再退厚土护身符（40%）
func consume_best_ward() -> Dictionary:
	for entry in DataRegistry.WARD_ITEMS:
		var dict: Dictionary = entry
		var item_id := String(dict.get("id", ""))
		if get_item_count(item_id) <= 0:
			continue
		remove_item(item_id, 1)
		return {
			"ok": true,
			"ratio": float(dict.get("ratio", 0.0)),
			"item_id": item_id,
			"name": DataRegistry.get_item_name(item_id),
		}
	return {"ok": false, "ratio": 0.0, "item_id": "", "name": ""}


## 优先大回春丹（110），再退回春散（35）
func consume_best_heal() -> Dictionary:
	var max_hp := get_max_hp()
	for entry in DataRegistry.HEAL_ITEMS:
		var dict: Dictionary = entry
		var item_id := String(dict.get("id", ""))
		if get_item_count(item_id) <= 0:
			continue
		remove_item(item_id, 1)
		var healed := int(roundf(float(dict.get("heal", 0)) * get_heal_multiplier()))
		current_hp = mini(max_hp, current_hp + healed)
		EventBus.stats_changed.emit()
		var heal_name := DataRegistry.get_item_name(item_id)
		EventBus.combat_heal.emit(healed, heal_name)
		return {
			"ok": true,
			"healed": healed,
			"item_id": item_id,
			"name": heal_name,
		}
	return {"ok": false, "healed": 0, "item_id": "", "name": ""}


# ---------------------------------------------------------------- 战斗辅助

var last_auto_heal_name: String = ""


func try_auto_heal() -> bool:
	if not bool(flags.get("auto_heal", true)):
		return false
	var max_hp := get_max_hp()
	if max_hp <= 0 or current_hp <= 0:
		return false
	if float(current_hp) / float(max_hp) >= auto_heal_threshold:
		return false
	var result := consume_best_heal()
	if not bool(result.get("ok", false)):
		return false
	last_auto_heal_name = String(result.get("name", "回春散"))
	return true


# ---------------------------------------------------------------- 帧率档位

const FPS_MODE_LOW: int = 30
const FPS_MODE_STANDARD: int = 60
## 高刷档兜底：拿不到屏幕刷新率、或屏幕本身只有 60Hz 时用 120
const FPS_MODE_HIGH_FALLBACK: int = 120


## 档位 → 目标帧率。档位 2「高刷」不再用 0（无限制），而是对齐设备屏幕最高刷新率；
## 屏幕只报 60Hz 或取不到（返回 0）时回退 120，避免等于「流畅」档而失去意义。
func get_target_fps(mode: int) -> int:
	match clampi(mode, 0, 2):
		2:
			var hz: int = int(round(DisplayServer.screen_get_refresh_rate()))
			return hz if hz > 60 else FPS_MODE_HIGH_FALLBACK
		1:
			return FPS_MODE_STANDARD
		_:
			return FPS_MODE_LOW


## 唯一的帧率落地入口：外壳启动与设置页切档都走这里，避免两处逻辑漂移。
func apply_fps_mode(mode: int) -> void:
	Engine.max_fps = get_target_fps(mode)

