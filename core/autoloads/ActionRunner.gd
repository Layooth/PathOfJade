extends Node
## 采集 / 制造 / 吐纳 计时引擎。
## 与 UI 完全解耦：只读取 GameState 的槽位配置并推进进度，
## 因此切换右侧工作台 Tab 绝不会中断挂机。

const MAX_FRAME_DELTA: float = 0.5
## 木生火 / 双倍纪要限流（秒）
const LOG_COOLDOWN: float = 20.0
var _last_special_log: float = -999.0

## 飘字配色（与宣纸浅色主题一致，此处内置以免核心层反向依赖 UI）
const COLOR_GAIN: Color = Color("#2A6F62")
const COLOR_SPECIAL: Color = Color("#A87424")
const COLOR_SYNERGY: Color = Color("#2E7D5B")

## 三槽进度（0 主修 / 1 分神 / 2 化身）。此前只有 2 个元素，槽 2 每帧越界写入，
## 导致「化身运转」进度恒为 0、结算从不执行（本次修复的核心 Bug）。
var _progress: Array[float] = [0.0, 0.0, 0.0]


func _ready() -> void:
	set_process(true)
	_sync_progress_slots()
	EventBus.game_loaded.connect(_on_game_loaded)


## 读档 / 云导入完成：进度由 SaveManager 在离线折算后已归零，这里兜底同步槽位数并再清一次
func _on_game_loaded() -> void:
	_sync_progress_slots()
	for slot in range(GameState.SLOT_COUNT):
		reset_progress(slot)


## 槽位数与进度数组保持同长：读档 / 旧档迁移后 GameState.SLOT_COUNT 可能变化
func _sync_progress_slots() -> void:
	if GameState != null and _progress.size() != GameState.SLOT_COUNT:
		_progress.resize(GameState.SLOT_COUNT)


func _process(delta: float) -> void:
	if GameState == null or DataRegistry == null:
		return
	if _progress.size() != GameState.SLOT_COUNT:
		_sync_progress_slots()
	var step: float = minf(delta, MAX_FRAME_DELTA)
	GameState.stats["play_seconds"] = float(GameState.stats.get("play_seconds", 0.0)) + step
	# 灵潭垂钓不占用百艺槽位，随全局轻量时钟推进。
	FishingTeaSystem.tick(step)
	for slot in range(GameState.SLOT_COUNT):
		var action_id: String = GameState.active_slots[slot]
		if action_id == "":
			continue
		var action := DataRegistry.get_action(action_id)
		if action == null:
			GameState.active_slots[slot] = ""
			_progress[slot] = 0.0
			continue
		var interval := get_effective_interval(action_id)
		if interval <= 0.01:
			interval = 0.01
		_progress[slot] += step / interval
		var loops := 0
		while _progress[slot] >= 1.0 and loops < 8:
			_progress[slot] -= 1.0
			loops += 1
			_complete(slot, action)
			if GameState.active_slots[slot] != action_id:
				break
		# 耗尽自动停机：刚结算完一轮就发现下一轮原料不够，立即停掉该槽
		# （不等下个周期再判，避免看起来「空转一圈才停」）。
		# 注意：唯一允许的自动停机条件就是「原料耗尽」——
		# 技能等级/经验达到当前大境界上限时绝不中断运转，材料与成品照常产出。
		if GameState.active_slots[slot] == action_id \
				and not action.inputs.is_empty() \
				and not GameState.has_items(action.inputs):
			GameState.stop_action(slot)
			if AudioManager != null:
				AudioManager.play_error()
			EventBus.toast.emit("原料耗尽，已停止%s" % GameState.get_slot_name(slot))


# ---------------------------------------------------------------- 查询

func reset_progress(slot: int) -> void:
	if slot >= 0 and slot < _progress.size():
		_progress[slot] = 0.0


func get_progress(slot: int) -> float:
	if slot < 0 or slot >= _progress.size():
		return 0.0
	return clampf(_progress[slot], 0.0, 1.0)


## 实际耗时 = 基础耗时 × 火候减耗 × 悟道池 25% 减耗
func get_effective_interval(action_id: String) -> float:
	var action := DataRegistry.get_action(action_id)
	if action == null:
		return 3.0
	var mastery_level := GameState.get_mastery_level(action_id)
	var multiplier := GameFormulas.mastery_interval_multiplier(mastery_level)
	# 百艺总火候里程碑：本门全部动作火候累计，每 50 级 -1.5%（最高 -15%）
	multiplier *= GameFormulas.skill_mastery_interval_mult(
		GameState.get_skill_total_mastery(action.skill_id))
	if GameState.is_pool_threshold(action.skill_id, 0.25):
		multiplier *= 0.95
	# 坊市采集法器：永久减耗（多件乘算）
	multiplier *= GameState.get_tool_interval_multiplier(action.skill_id)
	# 三才槽位耗时：主修 1.00x / 分神 1.25x / 化身 1.45x（未挂载动作不加成）
	var slot := GameState.get_slot_of_action(action_id)
	if slot >= 0:
		multiplier *= float(DataRegistry.SLOT_TIME_MULT[slot])
	# 金丹「洞府灵阵」：全局 -10%
	multiplier *= GameState.get_realm_interval_multiplier()
	# 藏经阁《百草灵韵经》：全采集类技能耗时 -10%
	if action.is_gather():
		multiplier *= maxf(0.5, 1.0 + GameFormulas.get_technique_bonus("gather_interval"))
	# 太虚混沌炉：全制造（炼丹/锻造/制符）耗时 -10%
	if action.is_craft():
		multiplier *= maxf(0.5, 1.0 + GameState.get_effect_sum("all_craft_interval"))
	# 图鉴收集 80% 里程碑：全动作耗时 -5%
	multiplier *= maxf(0.5, 1.0 - GameFormulas.get_codex_bonus("interval"))
	# 本命祭炼（法袍）：每 5 级全百艺耗时 -0.5%（末端 maxf 安全下限兜底）
	multiplier *= maxf(0.5, 1.0 - GameState.get_temper_interval_reduction())
	# 本命法宝：掌天灵鼎成长与迅捷器纹共同缩短百艺与吐纳耗时
	multiplier *= maxf(0.5, 1.0 - GameState.get_natal_bonus("skill_interval"))
	# 灵根五行亲和：金/木/火对应百艺方向减耗
	multiplier *= maxf(0.5, 1.0 - SpiritRootSystem.get_skill_interval_reduction(action.skill_id))
	# 灵鱼养神汤：全百艺动作耗时 -5%（负值是减耗，仍受 0.4s 硬下限约束）
	multiplier *= maxf(0.5, 1.0 + FishingTeaSystem.get_bonus("action_interval"))
	return maxf(0.4, action.base_interval * multiplier)


func get_double_chance(action_id: String) -> float:
	var action := DataRegistry.get_action(action_id)
	if action == null:
		return 0.0
	var chance := GameFormulas.mastery_double_chance(GameState.get_mastery_level(action_id))
	# 本命祭炼（兵刃）：每 5 级全百艺双倍概率 +0.5%
	chance += GameState.get_temper_double_bonus()
	# 灵茶（寒髓金髓仙茗）：全百艺双倍几率加成
	chance += FishingTeaSystem.get_bonus("double_chance")
	# 本命法宝：掌天灵鼎成长直接提升百艺双倍产出
	chance += GameState.get_natal_bonus("double_chance")
	# 火之法则：每重双倍产出 +4%
	chance += FiveElementsSystem.get_bonus("double_bonus")
	# 水灵根亲和：丹道与制符双倍产出
	chance += SpiritRootSystem.get_skill_double_bonus(action.skill_id)
	# 百艺总火候里程碑：每 50 级 +1%（最高 +10%），仍在 0.95 上限内
	chance += GameFormulas.skill_mastery_double_bonus(
		GameState.get_skill_total_mastery(action.skill_id))
	if GameState.is_pool_threshold(action.skill_id, 0.95):
		chance += 0.10
	if action.is_gather() and GameState.is_pool_threshold(action.skill_id, 0.50):
		chance += 0.10
	if is_wood_fire_active(action):
		chance += 0.15
	# 坊市百艺宝具：如青铜丹炉
	chance += GameState.get_double_chance_bonus(action.skill_id)
	# 藏经阁：《长春木元功》采药双倍 / 《离火炼丹诀》丹道双倍
	if action.skill_id == "alchemy":
		chance += GameFormulas.get_technique_bonus("alchemy_double")
		# 洞府灵气反哺：每块已播种灵田，丹道双倍 +2%
		chance += GameState.get_farm_aura_alchemy_bonus()
	elif action.is_gather() and action.skill_id == "herbalism":
		chance += GameFormulas.get_technique_bonus("herb_double")
	return GameFormulas.clamp_chance(chance)


## 「木生火」：丹道配方 + 灵木助燃开关 + 背包有青灵木
func is_wood_fire_active(action: ActionData) -> bool:
	if action == null or not action.wood_fire_capable:
		return false
	if not bool(GameState.flags.get("wood_fuel", false)):
		return false
	return GameState.get_item_count(DataRegistry.QINGLING_WOOD) > 0


## 「火生土 / 土生金」：器道 + 已装备火/土属性法宝
func has_fire_earth_synergy() -> bool:
	for slot in GameState.EQUIP_SLOTS:
		var entry := GameState.get_equipped(slot)
		var item_id := String(entry.get("id", ""))
		if item_id == "":
			continue
		var item := DataRegistry.get_item(item_id)
		if item == null:
			continue
		if item.element == ItemData.Element.FIRE or item.element == ItemData.Element.EARTH:
			return true
	return false


func get_quality_chance(action: ActionData) -> float:
	if action == null or not action.quality_capable:
		return 0.0
	var chance := 0.0
	if has_fire_earth_synergy():
		chance += 0.15
	# 坊市地火锻锤：精良品质概率 +15%
	chance += GameState.get_quality_bonus()
	# 本命法宝：掌天灵鼎成长提升锻造炼丹精良率
	chance += GameState.get_natal_bonus("quality_chance")
	# 火之法则：1 重起精良/极品产出率 +8%
	chance += FiveElementsSystem.get_bonus("quality_bonus")
	return GameFormulas.clamp_chance(chance, 0.9)


# ---------------------------------------------------------------- 结算

func _complete(slot: int, action: ActionData) -> void:
	if action.is_meditate():
		_complete_meditate(slot, action)
		return

	# 原料校验
	if not action.inputs.is_empty() and not GameState.has_items(action.inputs):
		GameState.stop_action(slot)
		if AudioManager != null:
			AudioManager.play_error()
		EventBus.toast.emit("原料不足，已停止：%s" % action.display_name)
		return

	var wood_fire := is_wood_fire_active(action)
	var quality_chance := get_quality_chance(action)
	var free_material := false
	if action.is_craft() and action.free_material_capable and GameState.is_pool_threshold(action.skill_id, 0.50):
		var free_chance := 0.20
		if action.skill_id == "alchemy":
			free_chance += GameFormulas.get_technique_bonus("alchemy_free")
		free_material = randf() < free_chance

	if not action.inputs.is_empty() and not free_material:
		for item_id in action.inputs.keys():
			GameState.remove_item(String(item_id), int(action.inputs[item_id]))

	# 双倍产出：概率 ≤100% 按概率 ×2；>100% 必定 ×2，超出部分转「三倍暴产」判定（×3）
	var double_chance := get_double_chance(action.id) \
		+ GameFormulas.get_codex_bonus("double")
	var doubled := true
	var triple := false
	if double_chance <= 1.0:
		doubled = randf() < double_chance
	else:
		triple = randf() < clampf(double_chance - 1.0, 0.0, 1.0)
	var out_mult := 3 if triple else (2 if doubled else 1)
	var gained_items: Dictionary = {}
	for item_id in action.outputs.keys():
		var base_amount := int(action.outputs[item_id])
		var total := base_amount * out_mult
		if total <= 0:
			continue
		GameState.add_item(String(item_id), total)
		gained_items[String(item_id)] = total

	# 采集副产灵种（化身槽：副产概率 +25%；渐进保底 +3%/连空，20 次内必出）
	var seed_drop := DataRegistry.get_seed_drop(action.id)
	if not seed_drop.is_empty():
		var pity: Dictionary = GameState.pity_counters
		var pity_key := "seed_" + action.id
		var misses := int(pity.get(pity_key, 0))
		var companion_chance := float(seed_drop.get("chance", 0.0)) \
			+ GameFormulas.get_technique_bonus("seed_bonus") \
			+ float(DataRegistry.SLOT_COMPANION_BONUS[slot]) \
			+ 0.03 * float(misses)
		var got_seed := misses >= 20 or randf() < GameFormulas.clamp_chance(
			companion_chance, DataRegistry.COMPANION_CHANCE_CAP)
		if got_seed:
			pity[pity_key] = 0
			var seed_id := String(seed_drop.get("seed_id", ""))
			if DataRegistry.get_item(seed_id) != null:
				GameState.add_item(seed_id, 1)
				gained_items[seed_id] = int(gained_items.get(seed_id, 0)) + 1
				GameState.push_activity_log("偶得 %s ×1" % DataRegistry.get_item_name(seed_id), "gold")
		else:
			pity[pity_key] = misses + 1

	# 木生火 / 双倍 / 三倍暴产：限流写入纪要，避免刷屏
	var now_sec := Time.get_ticks_msec() / 1000.0
	if wood_fire or doubled or triple:
		if now_sec - _last_special_log >= LOG_COOLDOWN:
			_last_special_log = now_sec
			var log_text := "双倍产出：%s"
			if triple:
				log_text = "三倍灵韵暴产！%s"
			elif wood_fire:
				log_text = "木生火：%s 火候大盛"
			GameState.push_activity_log(log_text % action.display_name,
				"gold" if triple else "good")

	# 器道品质：精良（+20%）/ 极品（+40%）；火候提升极品率（25%→35%），
	# 锻造极品保底：连 8 件未出极品，第 9 件必出
	var quality_result := 0
	if action.quality_capable and quality_chance > 0.0 and randf() < quality_chance:
		quality_result = 2 if randf() < _epic_rate(action) else 1
	if action.quality_capable and action.skill_id == "forging":
		var pity: Dictionary = GameState.pity_counters
		if quality_result == 2:
			pity["forging_epic"] = 0
		else:
			var miss := int(pity.get("forging_epic", 0))
			if miss >= 8:
				quality_result = 2
				pity["forging_epic"] = 0
			else:
				pity["forging_epic"] = miss + 1
	if quality_result > 0:
		for item_id in action.outputs.keys():
			var item := DataRegistry.get_item(String(item_id))
			if item == null or not (item.is_equipment() or item.is_consumable()):
				continue
			var amount := int(action.outputs[item_id])
			if quality_result == 2:
				GameState.add_epic_item(String(item_id), amount)
			else:
				GameState.add_fine_item(String(item_id), amount)
			GameState.push_activity_log("%s出%s：%s" % [
				"锻造" if action.skill_id == "forging" else "炼出",
				GameState.get_quality_name(quality_result),
				DataRegistry.get_item_name(String(item_id))],
				"gold" if quality_result == 2 else "good")

	# 乙艺出货：只有精良/极品才中震，凡品与普通双倍不震（自动挂机保持安静）
	if action.is_craft() and (action.skill_id == "alchemy" or action.skill_id == "forging") \
			and quality_result > 0:
		GameState.vibrate_medium()
	var skill_gain := GameState.add_skill_xp(action.skill_id, action.skill_xp)
	var mastery_gain := GameState.add_mastery_xp(action.id, action.mastery_xp)
	# 分神槽：悟道池经验 +25%（求悟）
	if slot == 1 and mastery_gain > 0:
		GameState.add_pool_xp(action.skill_id,
			float(mastery_gain) * GameFormulas.POOL_RATIO * DataRegistry.SLOT_POOL_BONUS[1])
	GameState.stats["actions_completed"] = int(GameState.stats.get("actions_completed", 0)) + 1

	var payload := {
		"items": gained_items,
		"cultivation": 0,
		"skill_xp": float(skill_gain),
		"mastery_xp": float(mastery_gain),
		"doubled": doubled,
		"triple": triple,
		"wood_fire": wood_fire,
		"quality": quality_result,
	}
	EventBus.action_completed.emit(slot, action.id, payload)
	_emit_floating(slot, action, gained_items, doubled, wood_fire, quality_result, triple)


func _complete_meditate(slot: int, action: ActionData) -> void:
	var realm := GameState.get_realm()
	var realm_name := "当前境界" if realm == null else realm.display_name
	# 大乘圆满：修为门槛为 0，已无更高境界，正常停转并提示巅峰（不提示不存在的天劫）
	if GameState.get_realm_requirement() <= 0.0:
		GameState.stop_action(slot)
		var peak_text := "%s修为已至巅峰" % realm_name
		EventBus.toast.emit(peak_text)
		GameState.push_activity_log(peak_text, "gold")
		return
	# 渡劫瓶颈：炼气九层 / 筑基后期 / 金丹后期 / 元婴后期，按当前境界动态拼接
	if GameState.is_cultivation_locked():
		GameState.stop_action(slot)
		var locked_text := "%s修为已圆满，可前往引动天劫" % realm_name
		if realm != null and realm.tribulation_name != "":
			locked_text += "（%s）" % realm.tribulation_name
		EventBus.toast.emit(locked_text)
		GameState.push_activity_log(locked_text, "gold")
		return
	var gain := action.cultivation_gain
	var used_pill := false
	if action.pill_item_id != "" and bool(GameState.flags.get("auto_pill", false)):
		if GameState.get_item_count(action.pill_item_id) > 0:
			GameState.remove_item(action.pill_item_id, 1)
			gain = action.pill_cultivation_gain if action.pill_cultivation_gain > 0 else action.cultivation_gain
			used_pill = true
	# 坊市聚灵蒲团：修为获取 +20%
	gain = int(roundf(float(gain) * GameState.get_cultivation_multiplier()))
	# 功法、凝神灵茶、水之法则与灵根亲和共同提升吐纳修为
	if action.is_meditate():
		gain = int(roundf(float(gain) * (1.0 + GameFormulas.get_technique_bonus("meditate_xp")
			+ FishingTeaSystem.get_bonus("meditate_cultivation")
			+ FiveElementsSystem.get_bonus("meditate_cultivation")
			+ SpiritRootSystem.get_bonus("meditate_cultivation"))))
	GameState.add_cultivation(float(gain))
	# 灵鱼养神汤：全百艺经验与火候 +12%，与分神/灵根加成同口径叠加
	var tea_skill_mult := 1.0 + FishingTeaSystem.get_bonus("skill_gain")
	var tea_mastery_mult := 1.0 + FishingTeaSystem.get_bonus("mastery_gain")
	var skill_gain := GameState.add_skill_xp(action.skill_id,
		float(action.skill_xp) * tea_skill_mult)
	var mastery_gain := GameState.add_mastery_xp(action.id,
		float(action.mastery_xp) * tea_mastery_mult)
	# 分神槽：悟道池经验 +25%（求悟，吐纳同样生效）
	if slot == 1 and mastery_gain > 0:
		GameState.add_pool_xp(action.skill_id,
			float(mastery_gain) * GameFormulas.POOL_RATIO * DataRegistry.SLOT_POOL_BONUS[1])
	GameState.stats["actions_completed"] = int(GameState.stats.get("actions_completed", 0)) + 1
	var payload := {
		"items": {},
		"cultivation": gain,
		"skill_xp": float(skill_gain),
		"mastery_xp": float(mastery_gain),
		"doubled": used_pill,
		"wood_fire": false,
		"fine": 0,
	}
	EventBus.action_completed.emit(slot, action.id, payload)
	var text := "修为 +%d%s" % [gain, "（吞丹）" if used_pill else ""]
	EventBus.floating_text.emit(slot, text, COLOR_SPECIAL)


func _emit_floating(slot: int, action: ActionData, gained: Dictionary, doubled: bool,
		wood_fire: bool, quality: int, triple: bool = false) -> void:
	var parts: Array[String] = []
	for item_id in gained.keys():
		parts.append("+%d %s" % [int(gained[item_id]), DataRegistry.get_item_name(String(item_id))])
	if parts.is_empty():
		return
	var text := " ".join(parts)
	var color := COLOR_GAIN
	if triple:
		color = COLOR_SPECIAL
	elif wood_fire:
		color = COLOR_SYNERGY
	elif doubled:
		color = COLOR_SPECIAL
	EventBus.floating_text.emit(slot, text, color)
	if triple:
		EventBus.floating_text.emit(slot, "三倍灵韵暴产！", COLOR_SPECIAL)
	if quality == 2:
		EventBus.floating_text.emit(slot, "极品品质！", COLOR_SPECIAL)
	elif quality == 1:
		EventBus.floating_text.emit(slot, "精良品质！", COLOR_SYNERGY)


## 极品率：基础 25% + 火候 0~15%（Lv150 满额）+ 总火候阶位 1%/阶，封顶 35%
func _epic_rate(action: ActionData) -> float:
	var mastery := float(GameState.get_mastery_level(action.id))
	var tier := float(GameFormulas.skill_mastery_tier(
		GameState.get_skill_total_mastery(action.skill_id)))
	return clampf(0.25 + mastery / 150.0 * 0.15 + tier * 0.01, 0.25, 0.35)
