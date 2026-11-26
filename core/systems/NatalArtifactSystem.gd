class_name NatalArtifactSystem
extends RefCounted

## 本命法宝：纯逻辑模块。状态存于 GameState.flags["natal_artifact"]，
## 不新增存档外层字段；所有落账统一发信号并本地存盘。

const STATE_KEY: String = "natal_artifact"
const UNLOCK_REALM_INDEX: int = 15
const MAX_LEVEL: int = 40
const ENGRAVE_STONE_COST: int = 500
const RECAST_STONE_COST: int = 5000

const EMBRYOS: Dictionary = {
	"qingzhu_sword": {
		"name": "青竹蜂云剑胚",
		"icon": "natal_qingzhu_sword",
		"school": "攻伐流",
		"desc": "青竹化剑，蜂云绕锋；前期锋芒渐长，后期以攻速与会心见长。",
	},
	"xuantian_bell": {
		"name": "玄天古钟胚",
		"icon": "natal_xuantian_bell",
		"school": "守御流",
		"desc": "玄天钟鸣，护住道体；兼顾气血、防御与天雷妖兽减伤。",
	},
	"zhangtian_ding": {
		"name": "掌天灵鼎胚",
		"icon": "natal_zhangtian_ding",
		"school": "百艺流",
		"desc": "掌天造化，鼎纳万象；缩短百艺吐纳耗时并提升双倍与精良。",
	},
}

const RUNES: Dictionary = {
	"ruijin": {
		"name": "锐金器纹",
		"key": "attack_pct",
		"label": "攻击",
		"values": [0.04, 0.07, 0.11, 0.16],
	},
	"houdu": {
		"name": "厚土器纹",
		"key": "max_hp_pct",
		"label": "气血",
		"values": [0.05, 0.09, 0.14, 0.20],
	},
	"bilei": {
		"name": "避雷器纹",
		"key": "damage_reduce",
		"label": "天雷减伤",
		"values": [0.03, 0.05, 0.08, 0.12],
	},
	"wudao": {
		"name": "悟道器纹",
		"key": "skill_gain",
		"label": "百艺悟道",
		"values": [0.06, 0.10, 0.16, 0.24],
	},
	"xunjie": {
		"name": "迅捷器纹",
		"key": "skill_interval",
		"label": "百艺耗时",
		"values": [0.02, 0.04, 0.06, 0.09],
	},
	"guiyuan": {
		"name": "归元器纹",
		"key": "offline_efficiency",
		"label": "离线效率",
		"values": [0.04, 0.07, 0.11, 0.16],
	},
}

const RUNE_TIER_NAMES: Array[String] = ["凡", "灵", "玄", "仙"]
const RUNE_TIER_WEIGHTS: Array[int] = [55, 30, 12, 3]
const ENGRAVE_MATERIALS: Array[String] = [
	"item_ancient_soul", "item_dragon_scale", "item_huashen_note",
]
## 温养普通材料排除灵种与器纹洗练珍材，避免误熔核心养成物资
const FEED_EXCLUDED_MATERIALS: Array[String] = [
	"item_ancient_soul", "item_dragon_scale", "item_huashen_note",
]
const BONUS_LABELS: Dictionary = {
	"attack_pct": "攻击力",
	"crit_chance": "会心率",
	"attack_interval_reduction": "攻击间隔缩减",
	"max_hp_pct": "气血上限",
	"defense_pct": "防御力",
	"damage_reduce": "天雷与妖兽减伤",
	"skill_interval": "百艺与吐纳耗时缩减",
	"double_chance": "百艺双倍产出",
	"quality_chance": "锻造炼丹精良率",
	"skill_gain": "百艺悟道效率",
	"offline_efficiency": "离线效率",
}


static func default_state() -> Dictionary:
	return {
		"embryo_id": "",
		"level": 1,
		"xp": 0.0,
		"engravings": [],
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
	state["embryo_id"] = str(saved.get("embryo_id", ""))
	if not EMBRYOS.has(String(state["embryo_id"])):
		state["embryo_id"] = ""
	state["level"] = clampi(int(saved.get("level", 1)), 1, MAX_LEVEL)
	state["xp"] = maxf(0.0, float(saved.get("xp", 0.0)))
	if int(state["level"]) >= MAX_LEVEL:
		state["xp"] = 0.0
	var slots := slot_count(int(state["level"]))
	var engraved: Array = []
	var raw_engraving: Variant = saved.get("engravings", [])
	if typeof(raw_engraving) == TYPE_ARRAY:
		for value in (raw_engraving as Array):
			if typeof(value) != TYPE_DICTIONARY:
				continue
			var entry: Dictionary = value
			var rune_id := str(entry.get("id", ""))
			if not RUNES.has(rune_id):
				continue
			engraved.append({
				"id": rune_id,
				"tier": clampi(int(entry.get("tier", 1)), 1, 4),
			})
			if engraved.size() >= slots:
				break
	while engraved.size() < slots:
		engraved.append({"id": "", "tier": 0})
	state["engravings"] = engraved
	flags[STATE_KEY] = state
	return state


static func commit_state(state: Dictionary) -> void:
	if GameState == null:
		return
	var flags: Dictionary = GameState.flags
	flags[STATE_KEY] = state
	EventBus.inventory_changed.emit()
	EventBus.equipment_changed.emit()
	EventBus.stats_changed.emit()
	if SaveManager != null and SaveManager.has_method("save_game"):
		SaveManager.call("save_game", false)


static func is_unlocked() -> bool:
	return GameState != null and GameState.get_realm_index() >= UNLOCK_REALM_INDEX


static func tier_index(level: int) -> int:
	if level <= 10:
		return 0
	if level <= 20:
		return 1
	if level <= 30:
		return 2
	return 3


static func tier_name(level: int) -> String:
	match tier_index(level):
		0:
			return "灵宝"
		1:
			return "古宝"
		2:
			return "通天灵宝"
		_:
			return "先天至宝"


static func slot_count(level: int) -> int:
	return clampi(tier_index(level) + 1, 1, 3)


static func required_xp(level: int) -> int:
	if level >= MAX_LEVEL:
		return 0
	return int(round(100.0 * pow(1.16, float(level - 1))))


static func embryo_name(embryo_id: String) -> String:
	var info: Dictionary = EMBRYOS.get(embryo_id, {})
	return str(info.get("name", "未凝练"))


static func embryo_icon(embryo_id: String) -> String:
	var info: Dictionary = EMBRYOS.get(embryo_id, {})
	return str(info.get("icon", "ui_slot_natal"))


static func can_create_embryo(embryo_id: String) -> bool:
	return is_unlocked() and EMBRYOS.has(embryo_id) \
		and str(get_state().get("embryo_id", "")) == ""


static func create_embryo(embryo_id: String) -> Dictionary:
	if not can_create_embryo(embryo_id):
		return {"ok": false, "message": "当前无法凝练此器胚"}
	var state := default_state()
	state["embryo_id"] = embryo_id
	commit_state(state)
	return {"ok": true, "message": "已凝练 %s" % embryo_name(embryo_id)}


static func can_recast(material_id: String) -> bool:
	if GameState == null or not is_unlocked():
		return false
	var state := get_state()
	if str(state.get("embryo_id", "")) == "":
		return false
	if GameState.get_item_count(DataRegistry.SPIRIT_STONE) < RECAST_STONE_COST:
		return false
	if material_id == "item_ancient_soul":
		return GameState.get_item_count(material_id) >= 2
	if material_id == "item_dragon_scale":
		return GameState.get_item_count(material_id) >= 1
	return false


static func recast_embryo(embryo_id: String, material_id: String) -> Dictionary:
	if not EMBRYOS.has(embryo_id) or not can_recast(material_id):
		return {"ok": false, "message": "重铸条件不足"}
	var state := get_state()
	if str(state["embryo_id"]) == embryo_id:
		return {"ok": false, "message": "已是此器胚"}
	var need := 2 if material_id == "item_ancient_soul" else 1
	GameState.remove_item(DataRegistry.SPIRIT_STONE, RECAST_STONE_COST)
	GameState.remove_item(material_id, need)
	state["embryo_id"] = embryo_id
	commit_state(state)
	return {"ok": true, "message": "已重铸为 %s" % embryo_name(embryo_id)}


static func apply_gain(state: Dictionary, gain: float) -> int:
	var levels := 0
	if int(state.get("level", 1)) >= MAX_LEVEL:
		state["xp"] = 0.0
		return 0
	var xp := maxf(0.0, float(state.get("xp", 0.0)) + gain)
	var level := clampi(int(state.get("level", 1)), 1, MAX_LEVEL)
	while level < MAX_LEVEL:
		var need := float(required_xp(level))
		if need <= 0.0 or xp + 0.0001 < need:
			break
		xp -= need
		level += 1
		levels += 1
	state["level"] = level
	state["xp"] = 0.0 if level >= MAX_LEVEL else xp
	return levels


static func is_equipped_item(item_id: String) -> bool:
	if GameState == null:
		return false
	for slot in GameState.EQUIP_SLOTS:
		var entry: Dictionary = GameState.get_equipped(slot)
		if str(entry.get("id", "")) == item_id:
			return true
	return false


static func material_gain(item_id: String) -> int:
	var item := DataRegistry.get_item(item_id)
	if item == null or item.category != ItemData.Category.MATERIAL:
		return 0
	if item_id == DataRegistry.SPIRIT_STONE:
		return 0
	# 碧波灵鱼肉蕴灵机，作为本命温养材料固定折算 15 点灵气。
	if item_id == "item_spirit_fish":
		return 15
	return maxi(1, int(floor(float(item.sell_price) / 10.0)))


static func equipment_gain(item_id: String, quality: int) -> int:
	var item := DataRegistry.get_item(item_id)
	if item == null or item.category != ItemData.Category.EQUIPMENT:
		return 0
	if is_equipped_item(item_id):
		return 0
	var mult := 1.0
	match clampi(quality, 0, 2):
		1:
			mult = 2.0
		2:
			mult = 3.5
	return maxi(1, int(floor(float(item.sell_price) / 10.0 * mult)))


## 可作温养的普通材料：排除全部灵种与洗练珍材，仅保留常规灵材。
static func is_feed_material(item_id: String) -> bool:
	if item_id.begins_with("seed_") or FEED_EXCLUDED_MATERIALS.has(item_id):
		return false
	return material_gain(item_id) > 0


static func get_feed_materials() -> Array[String]:
	var out: Array[String] = []
	if GameState == null:
		return out
	for key in GameState.inventory.keys():
		var item_id := str(key)
		if GameState.get_item_count(item_id) <= 0 or not is_feed_material(item_id):
			continue
		out.append(item_id)
	out.sort_custom(func(a: String, b: String) -> bool:
		return material_gain(a) > material_gain(b))
	return out


static func feed_material(item_id: String, ratio: float = 1.0) -> Dictionary:
	if not is_unlocked():
		return {"ok": false, "message": "需元婴初期开启"}
	if not is_feed_material(item_id):
		return {"ok": false, "message": "此物不可熔入温养"}
	var per := material_gain(item_id)
	if per <= 0:
		return {"ok": false, "message": "不可熔入此物"}
	var count := int(floor(float(GameState.get_item_count(item_id)) * clampf(ratio, 0.0, 1.0)))
	if count <= 0:
		return {"ok": false, "message": "没有可熔入的材料"}
	GameState.remove_item(item_id, count)
	var state := get_state()
	var levels := apply_gain(state, float(per * count))
	commit_state(state)
	return {"ok": true, "count": count, "xp": per * count, "levels": levels}


static func feed_equipment(item_id: String, quality: int, ratio: float = 1.0) -> Dictionary:
	if not is_unlocked():
		return {"ok": false, "message": "需元婴初期开启"}
	var per := equipment_gain(item_id, quality)
	if per <= 0:
		return {"ok": false, "message": "不可熔入此装备"}
	var count := int(floor(float(GameState.get_quality_count(item_id, quality))
		* clampf(ratio, 0.0, 1.0)))
	if count <= 0:
		return {"ok": false, "message": "没有可熔入的闲置装备"}
	GameState.remove_quality_item(item_id, count, quality)
	var state := get_state()
	var levels := apply_gain(state, float(per * count))
	commit_state(state)
	return {"ok": true, "count": count, "xp": per * count, "levels": levels}


static func smelt_obsolete_equipment() -> Dictionary:
	if not is_unlocked() or GameState == null:
		return {"ok": false, "message": "需元婴初期开启"}
	var cap := GameState.get_skill_level_cap()
	var threshold := GameFormulas.obsolete_equipment_threshold(cap)
	var targets: Array = []
	for key in GameState.inventory.keys():
		var item_id := str(key)
		var item := DataRegistry.get_item(item_id)
		if item == null or item.category != ItemData.Category.EQUIPMENT:
			continue
		if is_equipped_item(item_id):
			continue
		if DataRegistry.get_equipment_unlock_level(item_id) > threshold:
			continue
		for quality in range(3):
			if GameState.get_quality_count(item_id, quality) > 0:
				targets.append({"id": item_id, "quality": quality})
	var gained := 0
	var levels := 0
	var state := get_state()
	for target in targets:
		var dict: Dictionary = target
		var per := equipment_gain(str(dict["id"]), int(dict["quality"]))
		var count := GameState.get_quality_count(str(dict["id"]), int(dict["quality"]))
		if per <= 0 or count <= 0:
			continue
		GameState.remove_quality_item(str(dict["id"]), count, int(dict["quality"]))
		gained += per * count
		levels += apply_gain(state, float(per * count))
	if targets.is_empty():
		return {"ok": false, "message": "暂无可熔入的淘汰装备"}
	commit_state(state)
	return {"ok": true, "xp": gained, "levels": levels, "count": targets.size()}


static func can_engrave(slot_index: int, material_id: String) -> bool:
	if GameState == null or not is_unlocked():
		return false
	var state := get_state()
	if slot_index < 0 or slot_index >= slot_count(int(state.get("level", 1))):
		return false
	if not ENGRAVE_MATERIALS.has(material_id):
		return false
	if GameState.get_item_count(DataRegistry.SPIRIT_STONE) < ENGRAVE_STONE_COST:
		return false
	return GameState.get_item_count(material_id) >= 1


static func engrave(slot_index: int, material_id: String) -> Dictionary:
	if not can_engrave(slot_index, material_id):
		return {"ok": false, "message": "洗练条件不足"}
	var roll := randi() % 100
	var tier := 0
	if roll >= 97:
		tier = 3
	elif roll >= 85:
		tier = 2
	elif roll >= 55:
		tier = 1
	var rune_keys := RUNES.keys()
	var rune_id := str(rune_keys[randi() % rune_keys.size()])
	GameState.remove_item(DataRegistry.SPIRIT_STONE, ENGRAVE_STONE_COST)
	GameState.remove_item(material_id, 1)
	var state := get_state()
	var engraving_value: Variant = state.get("engravings", [])
	var list: Array = engraving_value if engraving_value is Array else []
	while list.size() <= slot_index:
		list.append({"id": "", "tier": 0})
	list[slot_index] = {"id": rune_id, "tier": tier + 1}
	state["engravings"] = list
	commit_state(state)
	return {"ok": true, "name": str((RUNES[rune_id] as Dictionary)["name"]),
		"tier": tier + 1, "message": "铭刻 %s · %s品" % [
			str((RUNES[rune_id] as Dictionary)["name"]), RUNE_TIER_NAMES[tier]]}


static func get_bonus(key: String) -> float:
	var state := get_state()
	var embryo_id := str(state.get("embryo_id", ""))
	if embryo_id == "":
		return 0.0
	var level := float(clampi(int(state.get("level", 1)), 1, MAX_LEVEL))
	var total := 0.0
	match embryo_id:
		"qingzhu_sword":
			match key:
				"attack_pct":
					total += 0.05 + level * 0.01
				"crit_chance":
					total += 0.017 + level * 0.003
				"attack_interval_reduction":
					total += minf(0.18, 0.026 + level * 0.0038)
		"xuantian_bell":
			match key:
				"max_hp_pct":
					total += 0.07 + level * 0.012
				"defense_pct":
					total += 0.05 + level * 0.01
				"damage_reduce":
					total += minf(0.18, 0.026 + level * 0.0038)
		"zhangtian_ding":
			match key:
				"skill_interval":
					total += minf(0.20, 0.026 + level * 0.0043)
				"double_chance":
					total += 0.016 + level * 0.0041
				"quality_chance":
					total += 0.017 + level * 0.0033
	var engraving_value: Variant = state.get("engravings", [])
	if engraving_value is Array:
		var tier_mult := 1.35 if tier_index(int(level)) == 3 else 1.0
		for value in (engraving_value as Array):
			if typeof(value) != TYPE_DICTIONARY:
				continue
			var entry: Dictionary = value
			var rune_id := str(entry.get("id", ""))
			if not RUNES.has(rune_id):
				continue
			var rune: Dictionary = RUNES[rune_id]
			if str(rune.get("key", "")) != key:
				continue
			var values: Array = rune.get("values", [])
			var tier := clampi(int(entry.get("tier", 1)), 1, 4) - 1
			if tier >= 0 and tier < values.size():
				total += float(values[tier]) * tier_mult
	return total


static func get_summary() -> Array:
	var out: Array = []
	for key in BONUS_LABELS.keys():
		var value := get_bonus(str(key))
		if value <= 0.0:
			continue
		out.append({
			"label": str(BONUS_LABELS[key]),
			"value": "%+.1f%%" % (value * 100.0),
			"key": str(key),
		})
	return out


static func embryo_effect_text(embryo_id: String, level: int) -> String:
	match embryo_id:
		"qingzhu_sword":
			return "攻击 +%.1f%% · 会心 +%.1f%% · 攻击间隔 -%.1f%%" % [
				(0.05 + level * 0.01) * 100.0,
				(0.017 + level * 0.003) * 100.0,
				minf(0.18, 0.026 + level * 0.0038) * 100.0]
		"xuantian_bell":
			return "气血 +%.1f%% · 防御 +%.1f%% · 减伤 +%.1f%%" % [
				(0.07 + level * 0.012) * 100.0,
				(0.05 + level * 0.01) * 100.0,
				minf(0.18, 0.026 + level * 0.0038) * 100.0]
		"zhangtian_ding":
			return "百艺耗时 -%.1f%% · 双倍 +%.1f%% · 精良 +%.1f%%" % [
				minf(0.20, 0.026 + level * 0.0043) * 100.0,
				(0.016 + level * 0.0041) * 100.0,
				(0.017 + level * 0.0033) * 100.0]
	return "暂无记载"


static func engraving_value_text(rune_id: String, tier: int) -> String:
	if not RUNES.has(rune_id):
		return ""
	var rune: Dictionary = RUNES[rune_id]
	var values: Array = rune.get("values", [])
	var index := clampi(tier - 1, 0, 3)
	if index >= values.size():
		return ""
	var value := float(values[index])
	var suffix := "+" if str(rune.get("key", "")) != "skill_interval" else "-"
	return "%s %s%.1f%%" % [str(rune.get("label", "")), suffix, absf(value) * 100.0]
