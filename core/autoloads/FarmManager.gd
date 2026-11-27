extends Node
## 「洞府灵田」：独立于主修槽 / 分神槽的第三条纯后台定时产线。
## 生长进度严格由系统时间戳推导，切后台、关游戏、离线均照常成熟。

const PLOT_COUNT: int = 4
const FERTILIZER_ITEM: String = "item_qingye"
const FERTILIZER_COST: int = 3
## 每轮最多施灵肥 3 次；每次剩余时间 ×0.75、产量 +20%，累计缩时约 58% / 丰产 +60%
const MAX_FERT_PER_GROWTH: int = 3
const FERTILIZE_TIME_CUT: float = 0.25
const FERTILIZE_YIELD_BONUS: float = 0.20
const FERTILIZE_MIN_REMAINING: float = 5.0
## 采药寻灵每级提升灵田产量 1.5%（Lv 99 约 2.47×）
const YIELD_PER_HERB_LEVEL: float = 0.015
## 灵田奇珍伴生概率：炼气 / 筑基 / 金丹 / 元婴 / 化神 / 炼虚 / 合体 / 大乘 / 真仙
const DEW_CHANCES: Array[float] = [0.15, 0.20, 0.25, 0.30, 0.34, 0.38, 0.42, 0.46, 0.50]
const FRUIT_CHANCES: Array[float] = [0.04, 0.08, 0.12, 0.16, 0.19, 0.22, 0.25, 0.28, 0.31]

var plots: Array = []
## 仙壤灵脉等级（0~20）：每级生长周期 -1.5%、奇珍伴生 +1.5%（各封顶 30%）。
## 旧存档 farm_plots 为纯数组时默认 0，零迁移兼容。
var soil_spirit_level: int = 0

## 阶梯门槛：批量灵田需开垦二号田；继续淬灵需筑基初期（已有等级不清除）
const BATCH_MIN_PLOTS: int = 2
const SOIL_MIN_REALM_ORDER: int = 9


func can_use_batch() -> bool:
	return get_unlocked_count() >= BATCH_MIN_PLOTS


func can_soil_enrich() -> bool:
	return GameState.get_realm_index() >= SOIL_MIN_REALM_ORDER


## 仙壤淬灵消耗：灵石 100000 × 1.22^level + 富余灵种合计 50×(level+1) 枚
func soil_spirit_stone_cost() -> int:
	return int(round(100000.0 * pow(1.22, float(soil_spirit_level))))


func soil_spirit_seed_cost() -> int:
	return 50 * (soil_spirit_level + 1)


## 当前灵脉重数对应可消耗灵种的最低阶位（按升重后的目标逐重校验）
func soil_seed_min_tier(level: int = -1) -> int:
	var lv := soil_spirit_level if level < 0 else level
	if lv >= 20:
		return 5
	if lv >= 15:
		return 4
	if lv >= 10:
		return 3
	if lv >= 5:
		return 2
	return 1


## 当前重数下合资格灵种的富余总量（每种仍保留 20 枚底仓）
func soil_seed_available_count(level: int = -1) -> int:
	var min_tier := soil_seed_min_tier(level)
	var total := 0
	for seed_data in DataRegistry.get_all_seeds():
		var dict: Dictionary = seed_data
		var crop_id := str(dict.get("crop_id", ""))
		var tier := int(DataRegistry.get_material_grade(crop_id).get("tier", 1))
		if tier < min_tier:
			continue
		total += maxi(0, GameState.get_item_count(str(dict.get("id", ""))) - 20)
	return total


func soil_time_reduction() -> float:
	return minf(0.015 * float(soil_spirit_level), 0.30)


func soil_rare_bonus() -> float:
	return minf(0.015 * float(soil_spirit_level), 0.30)


## 淬灵落账：优先扣低阶富余灵种；灵脉封顶 20 级。批量静音防重建卡顿。
func soil_enrich(times: int = 1) -> Dictionary:
	# 未达筑基初期只拦继续淬灵，既有 soil_spirit_level 与其加成原样保留
	if not can_soil_enrich():
		return {"ok": false, "reason": "需 筑基初期", "levels": 0, "stones": 0, "seeds": 0,
			"consumed": {}}
	var done := 0
	var stones_spent := 0
	var seeds_spent := 0
	var total_consumed := {}
	GameState.change_signals_muted = true
	for i in range(maxi(1, times)):
		if soil_spirit_level >= 20:
			break
		var stone := soil_spirit_stone_cost()
		var need := soil_spirit_seed_cost()
		var min_tier := soil_seed_min_tier(soil_spirit_level)
		if GameState.get_item_count(DataRegistry.SPIRIT_STONE) < stone:
			break
		var plan := _collect_surplus_seeds(need, min_tier)
		if int(plan.get("total", 0)) < need:
			break
		GameState.remove_item(DataRegistry.SPIRIT_STONE, stone)
		for seed_key in (plan["consumed"] as Dictionary).keys():
			var take := int((plan["consumed"] as Dictionary)[seed_key])
			GameState.remove_item(String(seed_key), take)
			total_consumed[String(seed_key)] = int(total_consumed.get(String(seed_key), 0)) + take
		soil_spirit_level += 1
		done += 1
		stones_spent += stone
		seeds_spent += need
	GameState.change_signals_muted = false
	_last_soil_consumed = total_consumed
	if done > 0:
		EventBus.inventory_changed.emit()
		EventBus.farm_changed.emit()
		EventBus.stats_changed.emit()
	return {"ok": done > 0, "levels": done, "stones": stones_spent, "seeds": seeds_spent,
		"consumed": total_consumed}


var _last_soil_consumed: Dictionary = {}


## 收集富余灵种（合资格阶位内低阶优先），凑满 need 枚；返回 {consumed, total}
func _collect_surplus_seeds(need: int, min_tier: int = 1) -> Dictionary:
	var entries: Array = []
	for seed_data in DataRegistry.get_all_seeds():
		var dict: Dictionary = seed_data
		var seed_id := String(dict.get("id", ""))
		var have := GameState.get_item_count(seed_id)
		var tier := int(DataRegistry.get_material_grade(
			String(dict.get("crop_id", ""))).get("tier", 1))
		# 「富余」= 超出 20 枚底仓的部分才可吞吐；低阶灵种按当前灵脉门槛排除
		var spare := have - 20
		if spare > 0 and tier >= min_tier:
			entries.append({"id": seed_id, "spare": spare, "tier": tier})
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["tier"]) != int(b["tier"]):
			return int(a["tier"]) < int(b["tier"])
		return int(a["spare"]) < int(b["spare"]))
	var consumed := {}
	var total := 0
	for entry in entries:
		if total >= need:
			break
		var take := mini(int(entry["spare"]), need - total)
		if take > 0:
			consumed[String(entry["id"])] = take
			total += take
	_last_soil_consumed = consumed
	return {"consumed": consumed, "total": total}

var _last_mature: int = 0
var _maturity_generation: int = 0


func _ready() -> void:
	_ensure_plots()
	_last_mature = count_mature()
	_schedule_maturity_notification()


## 只在下一块灵田即将成熟时挂一次性计时器；不逐帧/每秒扫描全表。
## 每次种植/施肥/收割都会推进 generation，旧计时器到点后自动作废。
func _schedule_maturity_notification() -> void:
	_maturity_generation += 1
	# 与当前成熟数对齐：收割/补种后下一轮成熟仍能正确触发一次通知
	_last_mature = count_mature()
	if not is_inside_tree():
		return
	var wait := -1.0
	for i in range(plots.size()):
		if is_empty(i) or is_mature(i):
			continue
		var remaining := get_remaining(i)
		if wait < 0.0 or remaining < wait:
			wait = remaining
	if wait < 0.0:
		return
	var token := _maturity_generation
	get_tree().create_timer(maxf(0.05, wait + 0.05)).timeout.connect(
		_on_maturity_due.bind(token))


func _on_maturity_due(token: int) -> void:
	if token != _maturity_generation or not is_inside_tree():
		return
	var count := count_mature()
	if count != _last_mature:
		_last_mature = count
		EventBus.farm_changed.emit()
	if FiveElementsSystem.is_auto_farm_enabled():
		_auto_cycle_mature()
		_last_mature = count_mature()
	_schedule_maturity_notification()


# ---------------------------------------------------------------- 结构

func _empty_plot(unlocked: bool) -> Dictionary:
	return {
		"unlocked": unlocked,
		"seed_id": "",
		"planted_unix": 0,
		"duration_sec": 0,
		"fertilized": false,
		"fert_count": 0,
		"fertilize_count": 0,
		"last_seed": "",
	}


func _ensure_plots() -> void:
	while plots.size() < PLOT_COUNT:
		var index := plots.size()
		plots.append(_empty_plot(index == 0))
	if plots.size() > 0:
		var first: Dictionary = plots[0]
		first["unlocked"] = true


func get_plots() -> Array:
	return plots


func get_plot(index: int) -> Dictionary:
	if index < 0 or index >= plots.size():
		return {}
	var plot: Variant = plots[index]
	if typeof(plot) == TYPE_DICTIONARY:
		return plot
	return {}


func get_plot_count() -> int:
	return plots.size()


func get_unlocked_count() -> int:
	var count := 0
	for plot in plots:
		var dict: Dictionary = plot
		if bool(dict.get("unlocked", false)):
			count += 1
	return count


## 已播种（生长中或已成熟）的灵田数量：灵气反哺光环依据
func count_planted() -> int:
	var count := 0
	for plot in plots:
		var dict: Dictionary = plot
		if String(dict.get("seed_id", "")) != "":
			count += 1
	return count


func _realm_tier() -> int:
	var realm := GameState.get_realm()
	return clampi(0 if realm == null else realm.tier, 0, DEW_CHANCES.size() - 1)


func is_unlocked(index: int) -> bool:
	var plot := get_plot(index)
	return bool(plot.get("unlocked", false))


func unlock_plot(index: int) -> bool:
	if index < 0 or index >= plots.size():
		return false
	var plot := get_plot(index)
	if bool(plot.get("unlocked", false)):
		return false
	plot["unlocked"] = true
	plots[index] = plot
	EventBus.farm_changed.emit()
	return true


# ---------------------------------------------------------------- 时间与状态

func _now() -> float:
	return Time.get_unix_time_from_system()


func is_empty(index: int) -> bool:
	var plot := get_plot(index)
	return String(plot.get("seed_id", "")) == ""


func is_growing(index: int) -> bool:
	if is_empty(index):
		return false
	return not is_mature(index)


func is_mature(index: int) -> bool:
	var plot := get_plot(index)
	if String(plot.get("seed_id", "")) == "":
		return false
	var ready_at := float(plot.get("planted_unix", 0)) + float(plot.get("duration_sec", 0))
	return _now() >= ready_at


func get_remaining(index: int) -> float:
	var plot := get_plot(index)
	if String(plot.get("seed_id", "")) == "":
		return 0.0
	var ready_at := float(plot.get("planted_unix", 0)) + float(plot.get("duration_sec", 0))
	return maxf(0.0, ready_at - _now())


func get_progress(index: int) -> float:
	var plot := get_plot(index)
	if String(plot.get("seed_id", "")) == "":
		return 0.0
	var duration := float(plot.get("duration_sec", 0))
	if duration <= 0.0:
		return 1.0
	return clampf((_now() - float(plot.get("planted_unix", 0))) / duration, 0.0, 1.0)


func count_mature() -> int:
	var count := 0
	for i in range(plots.size()):
		if is_mature(i):
			count += 1
	return count


func has_mature() -> bool:
	return count_mature() > 0


func is_fertilized(index: int) -> bool:
	var plot := get_plot(index)
	return bool(plot.get("fertilized", false))


# ---------------------------------------------------------------- 种植 / 施肥 / 收获

func can_plant(index: int, seed_id: String) -> Dictionary:
	if not is_unlocked(index):
		return {"ok": false, "reason": "灵田尚未开垦"}
	if not is_empty(index):
		return {"ok": false, "reason": "该地块已种植"}
	if DataRegistry.get_seed(seed_id).is_empty():
		return {"ok": false, "reason": "未知灵种"}
	if GameState.get_item_count(seed_id) <= 0:
		return {"ok": false, "reason": "储物袋中没有该灵种"}
	return {"ok": true, "reason": ""}


## 藏经阁《长春木元功》+ 仙壤灵脉：灵田生长加快（缩短实际生长时长）
func _grow_duration(base_seconds: float) -> int:
	var speed := GameFormulas.get_technique_bonus("farm_speed")
	var duration := base_seconds / maxf(1.01, 1.0 + speed)
	# 仙壤淬灵：每级 -1.5%（封顶 -30%）
	duration *= 1.0 - soil_time_reduction()
	# 木之法则：每重灵田生长耗时 -4%
	duration *= 1.0 - FiveElementsSystem.get_bonus("farm_growth_reduction")
	# 木灵根亲和：灵田生长耗时 -3% / -6% / -9% / -12%
	duration *= 1.0 - SpiritRootSystem.get_bonus("farm_growth_reduction")
	return maxi(10, int(round(duration)))


func plant(index: int, seed_id: String, silent: bool = false) -> bool:
	var check := can_plant(index, seed_id)
	if not bool(check.get("ok", false)):
		if not silent:
			EventBus.toast.emit(String(check.get("reason", "无法播种")))
		return false
	var seed_data := DataRegistry.get_seed(seed_id)
	GameState.remove_item(seed_id, 1)
	plots[index] = {
		"unlocked": true,
		"seed_id": seed_id,
		"planted_unix": int(_now()),
		"duration_sec": _grow_duration(float(seed_data.get("grow_seconds", 600.0))),
		"fertilized": false,
		"fert_count": 0,
		"fertilize_count": 0,
		"last_seed": seed_id,
	}
	if not silent:
		EventBus.toast.emit("已播下 %s" % String(seed_data.get("name", "灵种")))
		GameState.vibrate_light()
		if AudioManager != null:
			AudioManager.play_farm_action()
		EventBus.farm_changed.emit()
	_schedule_maturity_notification()
	return true


func can_fertilize(index: int) -> bool:
	if is_empty(index) or is_mature(index):
		return false
	if get_fertilize_count(index) >= MAX_FERT_PER_GROWTH:
		return false
	if get_remaining(index) <= FERTILIZE_MIN_REMAINING:
		return false
	return not get_best_fertilizer_herb("", index).is_empty()


## 单株肥力：与材料五档品阶同源（DataRegistry.get_material_grade 单一入口）
func get_herb_fertility(herb_id: String) -> int:
	return int(DataRegistry.get_material_grade(herb_id).get("fertility", 10))


## 近阶门槛：灵草阶位最多低于作物 1 阶，禁止低阶废草强催高阶仙药。
func is_herb_eligible_for_plot(index: int, herb_id: String) -> bool:
	if is_empty(index):
		return false
	var herb_tier := int(DataRegistry.get_material_grade(herb_id).get("tier", 1))
	return herb_tier >= _plot_crop_tier(get_plot(index)) - 1


## 玩家在「选草」浮层最后一次指定的草药：主按钮优先使用它（运行时记忆，
## 不落存档；库存不足时自动回退低阶顺延）
var preferred_fertilizer_herb: String = ""


## 智能选草：优先玩家指定草药；否则按解锁等级从低到高遍历行囊。
## plot_index >= 0 时严格过滤近阶灵草；旧调用未传地块索引时保持原口径。
func get_best_fertilizer_herb(preferred_id: String = "", plot_index: int = -1) -> Dictionary:
	if plot_index >= 0 and get_fertilize_count(plot_index) >= MAX_FERT_PER_GROWTH:
		return {}
	var herbs := DataRegistry.get_all_herb_ids()
	var candidates: Array[String] = []
	if preferred_id != "" and herbs.has(preferred_id) \
			and (plot_index < 0 or is_herb_eligible_for_plot(plot_index, preferred_id)):
		candidates.append(preferred_id)
	for herb_id in herbs:
		if herb_id == preferred_id:
			continue
		if plot_index >= 0 and not is_herb_eligible_for_plot(plot_index, herb_id):
			continue
		candidates.append(herb_id)
	for herb_id in candidates:
		var fertility := get_herb_fertility(herb_id)
		var needed := int(ceilf(GameFormulas.FERTILIZER_BASE_COST / float(fertility)))
		if GameState.get_item_count(herb_id) >= needed:
			return {
				"item_id": herb_id,
				"count_needed": needed,
				"fertility_per_unit": fertility,
				"total_fertility": float(needed * fertility),
			}
	return {}


## 自动选草施肥（UI 主按钮；preferred_id 用于「选草浮层」指定草药后的顺延兜底）
func fertilize_plot(index: int, preferred_id: String = "") -> bool:
	return fertilize(index, preferred_id)


## 严格使用指定草药施肥：不足或阶位不合时直接拒绝，绝不静默顺延到其它草药。
func fertilize_with(index: int, herb_id: String) -> bool:
	if is_empty(index) or is_mature(index):
		EventBus.toast.emit("当前无法施肥")
		return false
	if get_fertilize_count(index) >= MAX_FERT_PER_GROWTH:
		EventBus.toast.emit("灵肥已足 (%d/%d)" % [MAX_FERT_PER_GROWTH, MAX_FERT_PER_GROWTH])
		return false
	if not is_herb_eligible_for_plot(index, herb_id):
		EventBus.toast.emit("需近阶灵草")
		return false
	var fertility := get_herb_fertility(herb_id)
	var needed := int(ceilf(GameFormulas.FERTILIZER_BASE_COST / float(fertility)))
	var have := GameState.get_item_count(herb_id)
	if have < needed:
		EventBus.toast.emit("需 %s ×%d（存 %d），肥力不足一次施肥" % [
			DataRegistry.get_item_name(herb_id), needed, have])
		return false
	preferred_fertilizer_herb = herb_id
	return _apply_fertilizer(index, herb_id, needed)


func fertilize(index: int, preferred_id: String = "") -> bool:
	if is_empty(index) or is_mature(index):
		EventBus.toast.emit("当前无法施肥")
		return false
	if get_fertilize_count(index) >= MAX_FERT_PER_GROWTH:
		EventBus.toast.emit("灵肥已足 (%d/%d)" % [MAX_FERT_PER_GROWTH, MAX_FERT_PER_GROWTH])
		return false
	var plan := get_best_fertilizer_herb(preferred_id, index)
	if plan.is_empty():
		EventBus.toast.emit("需近阶灵草")
		return false
	return _apply_fertilizer(index, String(plan["item_id"]), int(plan["count_needed"]))


## 共用落账：扣近阶灵草 → 剩余时间固定 ×0.75（保底 5 秒）→ 每轮最多 3 次。
## 旧存档无 fert_count 时由 fertilize_count / fertilized 安全推导，读旧档零迁移。
func _apply_fertilizer(index: int, herb_id: String, needed: int) -> bool:
	var count := get_fertilize_count(index)
	if count >= MAX_FERT_PER_GROWTH:
		return false
	if not is_herb_eligible_for_plot(index, herb_id):
		return false
	GameState.remove_item(herb_id, needed)
	var plot := get_plot(index)
	var now := _now()
	var duration := float(plot.get("duration_sec", 0))
	var remaining := maxf(0.0, float(plot.get("planted_unix", 0)) + duration - now)
	var new_remaining := maxf(FERTILIZE_MIN_REMAINING, remaining * (1.0 - FERTILIZE_TIME_CUT))
	plot["planted_unix"] = int(now - (duration - new_remaining))
	count += 1
	plot["fert_count"] = count
	plot["fertilize_count"] = count
	plot["fertilized"] = true
	plots[index] = plot
	if not _batch_quiet:
		GameState.vibrate_light()
		if AudioManager != null:
			AudioManager.play_farm_action()
		EventBus.toast.emit("施下灵肥（%s ×%d）：剩余时间 -%d%%，灵肥 %d/%d，本次产量 +%d%%" % [
			DataRegistry.get_item_name(herb_id), needed,
			int(round(FERTILIZE_TIME_CUT * 100.0)), count, MAX_FERT_PER_GROWTH,
			int(round(_yield_bonus_of(count) * 100.0))])
		EventBus.farm_changed.emit()
	_schedule_maturity_notification()
	return true


func get_fertilize_count(index: int) -> int:
	return _fertilize_count(get_plot(index))


func _fertilize_count(plot: Dictionary) -> int:
	var legacy := int(plot.get("fertilize_count",
		1 if bool(plot.get("fertilized", false)) else 0))
	return clampi(int(plot.get("fert_count", legacy)), 0, MAX_FERT_PER_GROWTH)


## 丰产层数：每轮最多 3 次 ×20%，满施 +60%。保留 tier_max 形参兼容旧调用。
func _yield_bonus_of(count: int, _tier_max: int = 3) -> float:
	return minf(FERTILIZE_YIELD_BONUS * float(maxi(0, count)),
		FERTILIZE_YIELD_BONUS * float(MAX_FERT_PER_GROWTH))


## 地块当前丰产加成（供卡片「产量+X%」与收割乘区共用单一出口）
func get_plot_yield_bonus(index: int) -> float:
	var plot := get_plot(index)
	return _yield_bonus_of(_fertilize_count(plot), int(plot.get("fertilize_tier_max", 3)))


## 地块作物品阶（灵种 → crop_id → 品阶；无种/未知按 1 阶）
func _plot_crop_tier(plot: Dictionary) -> int:
	var seed_id := String(plot.get("seed_id", ""))
	var seed_data := DataRegistry.get_seed(seed_id) if seed_id != "" else {}
	var crop_id := String(seed_data.get("crop_id", "")) if not seed_data.is_empty() else ""
	if crop_id == "":
		return 1
	return int(DataRegistry.get_material_grade(crop_id).get("tier", 1))


## 批量施肥期间静音逐次 toast / 震动 / farm_changed（一键催熟连施几十次会卡死 UI）
var _batch_quiet := false


## 一键催熟：为单块生长中的灵田自动补施至每轮 3 次上限，绝不突破上限。
## 指定草药时严格使用该近阶草药；未指定时按低阶→高阶顺序选合资格灵草。
## 整轮只在结束时补发一次 inventory/farm 变更信号，杜绝逐次全量重建。
func batch_fertilize_to_ripe(index: int, preferred_id: String = "",
		emit_change: bool = true) -> Dictionary:
	var consumed := {}
	_batch_quiet = true
	GameState.change_signals_muted = true
	while get_fertilize_count(index) < MAX_FERT_PER_GROWTH:
		if is_empty(index) or is_mature(index):
			break
		var plan := get_best_fertilizer_herb(preferred_id, index)
		if plan.is_empty():
			break
		var herb_id := String(plan["item_id"])
		if preferred_id != "" and herb_id != preferred_id:
			break
		var before := get_remaining(index)
		if not fertilize(index, herb_id):
			break
		consumed[herb_id] = int(consumed.get(herb_id, 0)) + int(plan["count_needed"])
		if get_remaining(index) >= before and not is_mature(index):
			break
	_batch_quiet = false
	GameState.change_signals_muted = false
	if not consumed.is_empty() and emit_change:
		EventBus.inventory_changed.emit()
		EventBus.farm_changed.emit()
	_schedule_maturity_notification()
	return {
		"ok": is_mature(index) or not consumed.is_empty(),
		"mature": is_mature(index),
		"full": get_fertilize_count(index) >= MAX_FERT_PER_GROWTH,
		"consumed": consumed,
	}


## 是否存在可继续一键催熟的生长地块（用于主按钮置灰与「灵肥已足」提示）
## 一键催熟全部生长地块（FarmPanel 与右栏洞府态势共用同一逻辑）：
## 逐块静默补施至 3 次上限或草药耗尽，返回 {plots: 实际催熟块数, consumed: 消耗汇总}
func ripen_all_plots(preferred_id: String = "") -> Dictionary:
	var did := 0
	var consumed := {}
	for i in range(PLOT_COUNT):
		if is_empty(i) or is_mature(i):
			continue
		var herb := preferred_id if preferred_id != "" else preferred_fertilizer_herb
		var result := batch_fertilize_to_ripe(i, herb, false)
		var used: Dictionary = result.get("consumed", {})
		if used.is_empty():
			continue
		did += 1
		for key in used.keys():
			consumed[key] = int(consumed.get(key, 0)) + int(used[key])
	return {"plots": did, "consumed": consumed}


func can_batch_ripen() -> bool:
	for i in range(PLOT_COUNT):
		if is_empty(i) or is_mature(i):
			continue
		if get_fertilize_count(i) < MAX_FERT_PER_GROWTH \
				and not get_best_fertilizer_herb(preferred_fertilizer_herb, i).is_empty():
			return true
	return false


## 灵田产量乘区：采药等级 × 灵肥 × 功法/图鉴产量钩子
func get_harvest_yield_multiplier(plot: Dictionary) -> float:
	var herbalism_lv := GameState.get_skill_level("herbalism")
	var multiplier := 1.0 + float(maxi(0, herbalism_lv - 1)) * YIELD_PER_HERB_LEVEL
	var fert_count := _fertilize_count(plot)
	if fert_count > 0:
		# 产量加成随施肥次数叠加；低阶肥催高阶药封顶 +50%（见 _yield_bonus_of 阶位校准）
		multiplier *= 1.0 + _yield_bonus_of(fert_count, int(plot.get("fertilize_tier_max", 3)))
	multiplier *= 1.0 + GameFormulas.get_technique_bonus("farm_yield") \
		+ GameFormulas.get_codex_bonus("farm_yield")
	return maxf(0.1, multiplier)


## 灵田专属奇珍：每次收割按境界独立判定，各产 1 枚；仙壤灵脉额外 +1.5%/级（封顶 +30%）；
## 渐进保底：连空每次 +4% 伴生率，任一奇珍出货即清零
func _roll_rare_drops(items: Dictionary) -> void:
	var tier := _realm_tier()
	var pity: Dictionary = GameState.pity_counters
	var misses := int(pity.get("farm_rare", 0))
	var bonus := soil_rare_bonus() + 0.04 * float(misses)
	var dropped := false
	if randf() < DEW_CHANCES[tier] + bonus:
		items[DataRegistry.SPIRIT_DEW] = int(items.get(DataRegistry.SPIRIT_DEW, 0)) + 1
		dropped = true
	if randf() < FRUIT_CHANCES[tier] + bonus:
		items[DataRegistry.CRIMSON_FRUIT] = int(items.get(DataRegistry.CRIMSON_FRUIT, 0)) + 1
		dropped = true
	pity["farm_rare"] = 0 if dropped else misses + 1


func harvest(index: int, announce: bool = true, batch: bool = false) -> Dictionary:
	var result := {"ok": false, "items": {}, "name": "", "rare": {}}
	if not is_unlocked(index) or is_empty(index) or not is_mature(index):
		return result
	var plot := get_plot(index)
	var seed_id := String(plot.get("seed_id", ""))
	var seed_data := DataRegistry.get_seed(seed_id)
	if seed_data.is_empty():
		plots[index] = _empty_plot(true)
		EventBus.farm_changed.emit()
		_schedule_maturity_notification()
		return result
	var min_yield := int(seed_data.get("min_yield", 1))
	var max_yield := maxi(min_yield, int(seed_data.get("max_yield", min_yield)))
	var base_amount := randi_range(min_yield, max_yield)
	var amount := maxi(1, int(roundf(float(base_amount) * get_harvest_yield_multiplier(plot))))
	var crop_id := String(seed_data.get("crop_id", ""))
	var harvested_items: Dictionary = {}
	if crop_id != "":
		harvested_items[crop_id] = amount
		GameState.add_item(crop_id, amount)
	# 伴生奇珍（野外采药不产）
	var rare_items: Dictionary = {}
	_roll_rare_drops(rare_items)
	for item_id in rare_items.keys():
		var rare_amount := int(rare_items[item_id])
		GameState.add_item(String(item_id), rare_amount)
		harvested_items[item_id] = int(harvested_items.get(item_id, 0)) + rare_amount
	var crop_name := DataRegistry.get_item_name(crop_id)
	result = {
		"ok": true,
		"items": harvested_items,
		"name": crop_name,
		"seed_id": seed_id,
		"rare": rare_items,
	}
	plots[index] = {
		"unlocked": true,
		"seed_id": "",
		"planted_unix": 0,
		"duration_sec": 0,
		"fertilized": false,
		"fert_count": 0,
		"fertilize_count": 0,
		"last_seed": seed_id,
	}
	# 只有伴生奇珍才中震；普通灵草收割由面板给轻震。
	# batch（一键收获）模式：震动与刷新由调用方统一做一次，避免四连震/四连刷。
	if not rare_items.is_empty():
		if not batch:
			GameState.vibrate_medium()
		if announce:
			GameState.push_activity_log("灵田偶得奇珍：%s" % _format_harvest_summary(rare_items), "gold")
	# 批量模式：音效与刷新由调用方收尾统一发一次（防单帧信号风暴）
	if not batch:
		EventBus.farm_harvested.emit(harvested_items)
		EventBus.farm_changed.emit()
	_schedule_maturity_notification()
	return result


## 木之法则：成熟即自动收获，并按上次灵种或库存高阶灵种自动续播。
func _auto_cycle_mature() -> void:
	if not FiveElementsSystem.is_auto_farm_enabled():
		return
	var ripe := get_ripe_plot_indices()
	if ripe.is_empty():
		return
	GameState.begin_batch()
	for i in ripe:
		harvest(i, false, true)
	GameState.end_batch()
	var empties := get_empty_unlocked_plot_indices()
	if not empties.is_empty():
		var fallback_seed := ""
		var seeds := _seed_tier_order()
		if not seeds.is_empty():
			fallback_seed = seeds[0]
		GameState.begin_batch()
		for i in empties:
			var seed_id := String(get_plot(i).get("last_seed", ""))
			if seed_id == "" or GameState.get_item_count(seed_id) <= 0:
				seed_id = fallback_seed
			if seed_id != "":
				plant(i, seed_id, true)
		GameState.end_batch()
	EventBus.farm_changed.emit()


func harvest_all() -> Dictionary:
	var total_items: Dictionary = {}
	var harvested := 0
	GameState.begin_batch()
	for i in range(plots.size()):
		if not is_mature(i):
			continue
		var result := harvest(i, false, true)
		if not bool(result.get("ok", false)):
			continue
		harvested += 1
		var items: Dictionary = result.get("items", {})
		for item_id in items.keys():
			total_items[item_id] = int(total_items.get(item_id, 0)) + int(items[item_id])
	GameState.end_batch()
	if harvested > 0:
		EventBus.farm_changed.emit()
	_schedule_maturity_notification()
	if harvested == 0:
		EventBus.toast.emit("灵田暂无成熟作物")
		return {"count": 0, "items": {}, "summary": ""}
	var summary := _format_harvest_summary(total_items)
	EventBus.toast.emit("灵田大丰收：%s" % summary)
	GameState.push_activity_log("灵田大丰收：%s" % summary, "gold")
	return {"count": harvested, "items": total_items, "summary": summary}


# ---------------------------------------------------------------- 一键收获 / 一键播种

func get_ripe_plot_indices() -> Array[int]:
	var out: Array[int] = []
	for i in range(plots.size()):
		if is_unlocked(i) and is_mature(i):
			out.append(i)
	return out


func get_empty_unlocked_plot_indices() -> Array[int]:
	var out: Array[int] = []
	for i in range(plots.size()):
		if is_unlocked(i) and is_empty(i):
			out.append(i)
	return out


## 一键收获：复用单块完整结算（产量乘区 / 奇珍伴生），抑制逐块震动与刷新，
## 全程只震一次；返回汇总明细供面板展示战利品清单。
func harvest_all_plots() -> Dictionary:
	if not can_use_batch():
		return {"harvested_count": 0, "items": {}, "reason": "需二号灵田"}
	var total_items: Dictionary = {}
	var harvested := 0
	GameState.begin_batch()
	for i in get_ripe_plot_indices():
		var result := harvest(i, false, true)
		if not bool(result.get("ok", false)):
			continue
		harvested += 1
		var items: Dictionary = result.get("items", {})
		for item_id in items.keys():
			total_items[item_id] = int(total_items.get(item_id, 0)) + int(items[item_id])
	GameState.end_batch()
	if harvested > 0:
		GameState.vibrate_medium()
		EventBus.farm_harvested.emit(total_items)
		EventBus.farm_changed.emit()
	_schedule_maturity_notification()
	return {"harvested_count": harvested, "items": total_items}


## 背包内库存 > 0 的灵种，按售价（品阶）从高到低
func _seed_tier_order() -> Array[String]:
	var entries: Array = []
	for seed_def in DataRegistry.SEED_DEFS:
		var sid := String((seed_def as Dictionary).get("id", ""))
		if GameState.get_item_count(sid) <= 0:
			continue
		var item := DataRegistry.get_item(sid)
		entries.append({"id": sid, "price": 0 if item == null else item.sell_price})
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["price"]) > int(b["price"]))
	var out: Array[String] = []
	for entry in entries:
		out.append(String(entry["id"]))
	return out


## 一键播种：指定 seed_id = 按库存上限批量种满；seed_id 为空 = 智能混播
## （按品阶从高到低依次填满全部空地）。全程只震一次、只刷一次。
func plant_all_plots(seed_id: String = "") -> Dictionary:
	if not can_use_batch():
		return {"planted_count": 0, "used_seeds": {}, "reason": "需二号灵田"}
	var empty := get_empty_unlocked_plot_indices()
	if empty.is_empty():
		return {"planted_count": 0, "used_seeds": {}}
	var used: Dictionary = {}
	var planted := 0
	GameState.begin_batch()
	if seed_id != "":
		var count: int = mini(empty.size(), GameState.get_item_count(seed_id))
		for i in range(count):
			if plant(empty[i], seed_id, true):
				planted += 1
		if planted > 0:
			used[seed_id] = planted
	else:
		for sid in _seed_tier_order():
			while planted < empty.size() and GameState.get_item_count(sid) > 0:
				if not plant(empty[planted], sid, true):
					break
				planted += 1
				used[sid] = int(used.get(sid, 0)) + 1
	GameState.end_batch()
	if planted > 0:
		GameState.vibrate_light()
		EventBus.toast.emit("已播种 %d 块灵田" % planted)
		EventBus.farm_changed.emit()
	_schedule_maturity_notification()
	return {"planted_count": planted, "used_seeds": used}


## 按数量从高到低汇总：青叶草 ×142 · 聚灵甘露 ×1
func _format_harvest_summary(items: Dictionary) -> String:
	var rows: Array = []
	for key in items.keys():
		var amount := int(items[key])
		if amount > 0:
			rows.append({"id": String(key), "amount": amount})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["amount"]) > int(b["amount"])
	)
	var parts: Array[String] = []
	for row in rows:
		parts.append("%s ×%d" % [DataRegistry.get_item_name(String(row["id"])), int(row["amount"])])
	return " · ".join(parts)


## 一键原样补种：把刚收割过的地块按上次灵种重新种下
func replant_all() -> Dictionary:
	var planted := 0
	var missing := 0
	for i in range(plots.size()):
		if not is_unlocked(i) or not is_empty(i):
			continue
		var plot := get_plot(i)
		var seed_id := String(plot.get("last_seed", ""))
		if seed_id == "":
			continue
		if GameState.get_item_count(seed_id) <= 0:
			missing += 1
			continue
		if plant(i, seed_id, true):
			planted += 1
	if planted > 0:
		EventBus.toast.emit("已补种 %d 块灵田" % planted)
	elif missing > 0:
		EventBus.toast.emit("灵种不足，先到仙坊阁购置")
	else:
		EventBus.toast.emit("没有可补种的地块")
	return {"planted": planted, "missing": missing}


# ---------------------------------------------------------------- 离线 / 存档

## 调试：把所有已种植地块的播种时间前移，用于模拟闭关
func shift_planted(seconds: float) -> int:
	if seconds <= 0.0:
		return 0
	var shifted := 0
	for i in range(plots.size()):
		var plot := get_plot(i)
		if String(plot.get("seed_id", "")) == "":
			continue
		plot["planted_unix"] = int(plot.get("planted_unix", 0) - int(seconds))
		plots[i] = plot
		shifted += 1
	if shifted > 0:
		_last_mature = count_mature()
		EventBus.farm_changed.emit()
	_schedule_maturity_notification()
	return shifted


## 新档写 {plots, soil_spirit_level}；旧档读纯数组（soil_spirit_level 默认 0）
func to_dict() -> Dictionary:
	var out: Array = []
	for plot in plots:
		var dict: Dictionary = plot
		out.append(dict.duplicate(true))
	return {"plots": out, "soil_spirit_level": soil_spirit_level}


func from_dict(data: Variant) -> void:
	var source: Array = []
	soil_spirit_level = 0
	if typeof(data) == TYPE_ARRAY:
		# 旧档：纯地块数组，灵脉默认 0（零迁移）
		source = data
	elif typeof(data) == TYPE_DICTIONARY:
		var dict: Dictionary = data
		soil_spirit_level = clampi(int(dict.get("soil_spirit_level", 0)), 0, 20)
		var nested: Variant = dict.get("plots", [])
		if typeof(nested) == TYPE_ARRAY:
			source = nested

	plots.clear()
	_ensure_plots()
	for i in range(mini(source.size(), PLOT_COUNT)):
		var raw: Variant = source[i]
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = raw
		var plot := _empty_plot(i == 0)
		var seed_id := String(entry.get("seed_id", ""))
		var seed_data := DataRegistry.get_seed(seed_id)
		if seed_id != "" and not seed_data.is_empty():
			plot["seed_id"] = seed_id
			plot["planted_unix"] = int(entry.get("planted_unix", 0))
			plot["duration_sec"] = _grow_duration(float(seed_data.get("grow_seconds", 600.0)))
			var legacy_count := int(entry.get("fertilize_count",
				1 if bool(entry.get("fertilized", false)) else 0))
			var saved_count := clampi(int(entry.get("fert_count", legacy_count)),
				0, MAX_FERT_PER_GROWTH)
			plot["fert_count"] = saved_count
			plot["fertilize_count"] = saved_count
			plot["fertilized"] = saved_count > 0
			plot["last_seed"] = seed_id
		else:
			var last_seed := String(entry.get("last_seed", ""))
			if not DataRegistry.get_seed(last_seed).is_empty():
				plot["last_seed"] = last_seed
		plot["unlocked"] = bool(entry.get("unlocked", i == 0)) or i == 0
		plots[i] = plot

	# 与坊市购买记录对齐（旧存档只有购买记录时也能补正）
	for i in range(1, PLOT_COUNT):
		var upgrade_id := "farm_plot_%d" % (i + 1)
		if GameState.has_upgrade(upgrade_id):
			var plot := get_plot(i)
			plot["unlocked"] = true
			plots[i] = plot
	if plots.size() > 0:
		var first: Dictionary = plots[0]
		first["unlocked"] = true

	_last_mature = count_mature()
	EventBus.farm_changed.emit()
	_schedule_maturity_notification()

