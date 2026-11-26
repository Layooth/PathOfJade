extends Node
## 双进度条自动回合制战斗 + 限时渡劫考核状态机（筑基 / 结丹两套配置）。
## 独立于 UI 运行，切页不中断。

const TRIB_INTERVAL: float = 4.0
const RESPAWN_DELAY: float = 0.9
const NOTIFY_INTERVAL: float = 0.1
const ENEMY_ACCURACY: float = 0.95
## 战斗实时纪要只留内存：与面板展示条数一致，长时间挂机不累积
const MAX_LOG_LINES: int = 40

# ---- 战斗 ----
var active: bool = false
var enemy: EnemyData = null
var enemy_hp: int = 0
var player_timer: float = 0.0
## 会话内连胜（击败递增 / 战败清零，仅运行时展示「连胜 X 场」）
var win_streak: int = 0
var enemy_timer: float = 0.0
var respawn_timer: float = 0.0
## 单场死亡结算锁：true=本场已结算过。开场雷击秒杀等未经结算的死亡
## 由 _tick_combat 兜底补结算；锁保证单场最多结算一次，杜绝重入死循环
var _death_settled: bool = false

# ---- 渡劫（参数在开始渡劫时按当前境界载入） ----
var trib_active: bool = false
var trib_elapsed: float = 0.0
var trib_index: int = 0
var _trib_damages: Array = [35, 50, 65, 85, 110]
var _trib_duration: float = 20.0
var _trib_name: String = "天劫"
## 藏经阁《太初斩星剑意》剑气计数
var _player_attack_count: int = 0
## 镇魔塔当前层数（0 = 普通秘境）
var tower_floor: int = 0


# ---------------------------------------------------------------- 镇魔塔

## 冲层：按层数动态生成妖魔，复用自动回血/护符/雷符与功法加成
func start_tower_combat(floor_num: int) -> Dictionary:
	if trib_active:
		return {"ok": false, "message": "天劫将至，无暇分身镇魔塔"}
	# 可选层严格限制为「已通关最高层 + 1」，防止绕过 UI 直接跳层
	if floor_num < 1 or floor_num > GameState.get_tower_max_floor():
		return {"ok": false, "message": "需先击败当前层妖魔方可继续深入"}
	var target := DataRegistry.get_tower_enemy(floor_num)
	if target == null:
		return {"ok": false, "message": "妖魔生成失败"}
	if active:
		stop_combat("进入镇魔塔")
	# 冲塔同样占用一个挂机槽位，与百艺保持互斥/上限一致
	var stopped := GameState.reserve_combat_slot()
	if not stopped.is_empty():
		EventBus.toast.emit("已停止「%s」，转入镇魔塔" % String(stopped[0]))
	if GameState.current_hp <= 0:
		GameState.restore_hp(1.0)
	tower_floor = floor_num
	_player_attack_count = 0
	enemy = target
	enemy_hp = enemy.max_hp
	player_timer = 0.0
	enemy_timer = 0.0
	respawn_timer = 0.0
	_death_settled = false
	active = true
	_log("镇魔塔 · 第 %d 层：%s 拦路。" % [floor_num, enemy.display_name])
	EventBus.combat_enemy_changed.emit(enemy.id, true)
	_try_thunder_talisman()
	if not active:
		# 开场雷击秒杀且已结算退战（非连闯）：立即中止本场后续初始化
		return {"ok": true, "message": "雷击诛灭，本层已破"}
	EventBus.combat_started.emit(enemy.id)
	EventBus.stats_changed.emit()
	_emit_combat_state()
	return {"ok": true, "message": "第 %d 层开战" % floor_num}


## 战败 / 手动撤出时退出塔层记录。
## 注意：最高通关层只在真正击败妖魔（_on_enemy_defeated）时更新，
## 进入挑战、战败、中途撤出都不得改写，否则会凭空解锁更高层。
## 塔神赐里程碑（每 5 层首通一次性）：
## 偶数节点（10/20/…）= 百年朱果 ×1 + 聚灵甘露 ×2；奇数节点（5/15/…）= 仙盟贡献 + 高阶灵材礼匣
func _grant_tower_milestone(floor_num: int) -> void:
	var reward: Dictionary = DataRegistry.get_tower_milestone_reward(floor_num)
	if reward.is_empty():
		return
	var parts: Array[String] = []
	for value in reward.get("items", []):
		var entry: Dictionary = value
		var item_id := String(entry.get("id", ""))
		if item_id == "" or DataRegistry.get_item(item_id) == null:
			continue
		var amount := maxi(1, int(entry.get("amount", 1)))
		GameState.add_item(item_id, amount)
		parts.append("%s ×%d" % [DataRegistry.get_item_name(item_id), amount])
	var points := maxi(0, int(reward.get("points", 0)))
	if points > 0:
		GameState.alliance_points += points
	var node_name := "十层重奖" if bool(reward.get("tenth", false)) else "妖王礼赐"
	_log("塔神赐福（第 %d 层 · %s）：%s，仙盟贡献 +%d" % [
		floor_num, node_name, "，".join(parts), points])
	GameState.push_activity_log("镇魔塔神赐：%s" % "，".join(parts), "gold")
	GameState.vibrate_heavy()


func _exit_tower(reason: String) -> void:
	if tower_floor <= 0:
		return
	_log("镇魔塔止步于第 %d 层（%s），历史最高 %d 层。" % [
		tower_floor, reason, GameState.tower_highest_floor])
	tower_floor = 0

var _notify_accum: float = 0.0
var _log_lines: Array[String] = []
## 镇魔塔独立纪要缓冲（双模式双向隔离：塔战报不混入秘境纪要）
var _tower_log_lines: Array[String] = []


func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	if GameState == null or DataRegistry == null:
		return
	var step: float = minf(delta, 0.5)
	if trib_active:
		_tick_tribulation(step)
	if active:
		_tick_combat(step)
	_notify_accum += step
	if _notify_accum >= NOTIFY_INTERVAL:
		_notify_accum = 0.0
		if trib_active:
			_emit_trib_state()
		elif active:
			_emit_combat_state()


# ---------------------------------------------------------------- 查询

func is_active() -> bool:
	return active


func is_tribulation_active() -> bool:
	return trib_active


func get_current_enemy() -> EnemyData:
	return enemy


func get_log_lines() -> Array[String]:
	return _log_lines.duplicate()


## 当前是否镇魔塔战斗（秘境/镇魔塔双模式双向隔离判定）
func is_tower_mode() -> bool:
	return active and tower_floor > 0


func get_trib_state() -> Dictionary:
	return {
		"active": trib_active,
		"elapsed": trib_elapsed,
		"duration": _trib_duration,
		"index": trib_index,
		"name": _trib_name,
		"hp": GameState.current_hp,
		"max_hp": GameState.get_max_hp(),
		"next_in": maxf(0.0, TRIB_INTERVAL * float(trib_index + 1) - trib_elapsed),
	}


# ---------------------------------------------------------------- 战斗流程

func start_combat(enemy_id: String) -> bool:
	if trib_active:
		EventBus.toast.emit("天劫将至，无暇分身秘境")
		return false
	if active:
		if enemy != null and enemy.id == enemy_id:
			return true
		stop_combat("更换历练目标")
	var target := DataRegistry.get_enemy(enemy_id)
	if target == null:
		EventBus.toast.emit("秘境目标不存在")
		return false
	# 递进限制在引擎层再校验一次：直接调用也不能跳过前置妖兽
	var lock_reason := GameState.enemy_lock_reason(enemy_id)
	if lock_reason != "":
		EventBus.toast.emit("需先击败前置妖兽（%s）" % lock_reason)
		return false
	# 秘境与百艺共享同一套槽位上限：炼气期自动停下百艺，筑基期只让出分神位
	var stopped := GameState.reserve_combat_slot()
	if not stopped.is_empty():
		EventBus.toast.emit("已停止「%s」，转入秘境历练" % String(stopped[0]))
	enemy = target
	enemy_hp = enemy.max_hp
	player_timer = 0.0
	enemy_timer = 0.0
	respawn_timer = 0.0
	_death_settled = false
	active = true
	GameState.selected_enemy_id = enemy.id
	GameState.selected_region_id = enemy.region_id
	if GameState.current_hp <= 0:
		GameState.restore_hp(1.0)
	_log("踏入秘境：%s" % enemy.display_name)
	EventBus.combat_enemy_changed.emit(enemy.id, true)
	_try_thunder_talisman()
	EventBus.combat_started.emit(enemy.id)
	EventBus.stats_changed.emit()
	_emit_combat_state()
	return true


func resume_from_save(enemy_id: String) -> void:
	var target := DataRegistry.get_enemy(enemy_id)
	if target == null or not GameState.can_challenge_enemy(enemy_id):
		return
	enemy = target
	enemy_hp = target.max_hp
	player_timer = 0.0
	enemy_timer = 0.0
	_death_settled = false
	respawn_timer = 0.0
	active = true
	# 槽位仲裁统一交给 SaveManager 在离线结算之后处理：此处若提前停百艺，
	# _run_offline 就取不到 active_slots，百艺与吐纳收益会被算成 0。
	if GameState.current_hp <= 0:
		GameState.restore_hp(1.0)
	EventBus.combat_enemy_changed.emit(target.id, true)


func stop_combat(reason: String = "已撤出秘境") -> void:
	tower_floor = 0
	if not active:
		return
	active = false
	enemy_hp = 0
	player_timer = 0.0
	enemy_timer = 0.0
	_log(reason)
	EventBus.combat_stopped.emit(reason)
	EventBus.stats_changed.emit()
	_emit_combat_state()


func _tick_combat(delta: float) -> void:
	if GameState.current_hp <= 0:
		_defeat()
		return
	if enemy == null:
		stop_combat("目标已消散")
		return
	var stats := GameState.get_player_stats()
	var player_interval := maxf(0.55, float(stats["interval"]))

	if enemy_hp <= 0:
		# 镇魔塔单层战斗不复活：等待「连闯下一层」计时或已停战
		if tower_floor > 0:
			return
		if not _death_settled:
			# 未经结算的死亡（开场雷击秒杀等）：兜底补走统一胜利结算
			_on_enemy_defeated()
			return
		respawn_timer -= delta
		if respawn_timer <= 0.0:
			enemy_hp = enemy.max_hp
			player_timer = 0.0
			enemy_timer = 0.0
			_death_settled = false
			_log("%s 再次扑出。" % enemy.display_name)
			EventBus.combat_enemy_changed.emit(enemy.id, false)
			_try_thunder_talisman()
		return

	player_timer += delta
	if player_timer >= player_interval:
		player_timer -= player_interval
		_player_attack(stats)
	if enemy_hp <= 0:
		_on_enemy_defeated()
		return
	if GameState.current_hp <= 0:
		_defeat()
		return

	enemy_timer += delta
	if enemy_timer >= maxf(0.5, enemy.attack_interval):
		enemy_timer -= maxf(0.5, enemy.attack_interval)
		_enemy_attack(stats)
	if GameState.current_hp <= 0:
		_defeat()


func _player_attack(stats: Dictionary) -> void:
	var raw_accuracy := float(stats.get("raw_accuracy", stats.get("accuracy", 0.85)))
	var enemy_dodge := 0.0 if enemy == null else clampf(enemy.dodge, 0.0, 0.95)
	var effective_accuracy := clampf(raw_accuracy - enemy_dodge, 0.35, 0.99)
	if randf() > effective_accuracy:
		_log("你的攻势被%s闪开。" % enemy.display_name)
		EventBus.combat_dodge.emit("enemy")
		return
	var roll := randf_range(0.85, 1.15)
	var damage := GameFormulas.compute_damage(int(stats["attack"]), enemy.defense, roll)
	# 藏经阁《庚金剑诀》+ 本命祭炼：会心触发率封顶 75%，
	# 溢出部分按 1:1.5 转化为会心伤害倍率（1.75x 起步，例：面板 95% → 2.05x）
	var crit_chance := GameState.get_crit_chance_raw()
	var crit := crit_chance > 0.0 and randf() < clampf(crit_chance, 0.0, 0.75)
	if crit:
		var overflow_crit := maxf(0.0, crit_chance - 0.75)
		var crit_mult := 1.75 + overflow_crit * 1.5
		damage = int(roundf(float(damage) * crit_mult))
	# 藏经阁《太初斩星剑意》：每第 3 次普攻附带剑气真伤
	_player_attack_count += 1
	var sword_qi := GameFormulas.get_technique_bonus("sword_qi")
	var qi_damage := 0
	if sword_qi > 0.0 and _player_attack_count % 3 == 0:
		qi_damage = maxi(1, int(roundf(float(stats["attack"]) * sword_qi)))
		damage += qi_damage
	# 破厄剑茶：秘境与镇魔塔攻击伤害 +12%
	damage = int(roundf(float(damage) * (1.0 + FishingTeaSystem.get_bonus("combat_damage"))))
	enemy_hp = maxi(0, enemy_hp - damage)
	var suffix := ""
	if crit:
		suffix += "（会心）"
	if qi_damage > 0:
		suffix += "（剑气 +%d）" % qi_damage
	_log("你斩出 %d 点伤害%s（%s 余 %d 气血）" % [
		damage, suffix, enemy.display_name, enemy_hp])
	EventBus.combat_player_attack.emit(damage, crit)


func _enemy_attack(stats: Dictionary) -> void:
	var player_dodge := clampf(float(stats.get("dodge", 0.05)), 0.05, 0.45)
	var effective_enemy_accuracy := clampf(ENEMY_ACCURACY - player_dodge, 0.50, 0.95)
	if randf() > effective_enemy_accuracy:
		_log("%s 扑空。" % enemy.display_name)
		EventBus.combat_dodge.emit("player")
		return
	var roll := randf_range(0.85, 1.15)
	var damage := GameFormulas.compute_damage(enemy.attack, int(stats["defense"]), roll)
	var ward_name := ""
	var ward_ratio := 0.0
	if GameState.is_flag("auto_talisman", true) and damage >= 10:
		var ward := GameState.consume_best_ward()
		if bool(ward.get("ok", false)):
			# 藏经阁《太虚避劫经》：护身符额外减伤
			ward_ratio = clampf(float(ward.get("ratio", 0.0))
				+ GameFormulas.get_technique_bonus("ward_bonus"), 0.0, 0.9)
			damage = maxi(1, int(roundf(float(damage) * (1.0 - ward_ratio))))
			ward_name = String(ward.get("name", "护身符"))
	# 功法《太虚避劫经》《星辰炼神术》与玄天古钟/土之法则共用全局免伤（≤50%）
	var global_reduce := GameState.get_damage_reduce_bonus()
	if global_reduce > 0.0:
		damage = maxi(1, int(roundf(float(damage) * (1.0 - global_reduce))))
	GameState.current_hp = maxi(0, GameState.current_hp - damage)
	var ward_text := "" if ward_name == "" else "（%s减伤）" % ward_name
	_log("%s 击中你 -%d 气血%s" % [enemy.display_name, damage, ward_text])
	EventBus.combat_enemy_attack.emit(damage, ward_ratio)
	if GameState.current_hp > 0 and GameState.try_auto_heal():
		_log("护道吞服%s" % GameState.last_auto_heal_name)
	EventBus.stats_changed.emit()


## 引雷符：每场战斗开场对敌造成一次雷击真伤（按 THUNDER_ITEMS 顺序取首张库存）
func _try_thunder_talisman() -> void:
	if enemy == null or enemy_hp <= 0:
		return
	if not GameState.is_flag("auto_thunder_talisman", true):
		return
	for entry in DataRegistry.THUNDER_ITEMS:
		var dict: Dictionary = entry
		var item_id := String(dict.get("id", ""))
		if item_id == "" or GameState.get_item_count(item_id) <= 0:
			continue
		GameState.remove_item(item_id, 1)
		# 攻伐符箓 = 开场先手破防，绝不替代普攻输出：
		# 品阶克制倍率 × 玩家攻击 − 敌防×0.5（保底 10% 符面伤害）；
		# 头目/妖王 0.55x 抗性——移除「敌最大气血 %」逃课扣血，杜绝跨阶炸血。
		# 藏经阁《九霄迅雷步》再 +35%
		var mult := float(dict.get("mult", 0.45))
		if enemy.is_boss:
			mult *= 0.55
		var raw := float(GameState.get_attack()) * mult - float(enemy.defense) * 0.5
		var base_damage := maxf(raw, float(dict.get("damage", 45)) * 0.10)
		var damage := int(roundf(base_damage
			* (1.0 + GameFormulas.get_technique_bonus("thunder_dmg"))))
		var item_name := DataRegistry.get_item_name(item_id)
		enemy_hp = maxi(0, enemy_hp - damage)
		_log("%s落下：-%d 雷击真伤" % [item_name, damage])
		EventBus.combat_thunder_talisman.emit(damage)
		# 雷击秒杀：立即走统一胜利结算（状态锁防重入；塔层自动冲层由
		# create_timer 延迟推进，不递归），彻底消除 0/N 卡死与单帧叠字
		if enemy_hp <= 0:
			_on_enemy_defeated()
		return


func _on_enemy_defeated() -> void:
	if enemy == null or _death_settled:
		return
	_death_settled = true
	win_streak += 1
	enemy_hp = 0
	respawn_timer = RESPAWN_DELAY
	var gained := _grant_loot()
	var parts: Array[String] = []
	for item_id in gained.keys():
		parts.append("%s ×%d" % [DataRegistry.get_item_name(String(item_id)), int(gained[item_id])])
	var loot_text := "无" if parts.is_empty() else "，".join(parts)
	_log("击杀 %s，获得：%s" % [enemy.display_name, loot_text])
	EventBus.combat_enemy_defeated.emit(enemy.id, gained)
	# 镇魔塔妖魔不写入秘境递进记录；秘境胜利即记入已击败
	if tower_floor <= 0:
		GameState.mark_enemy_defeated(enemy.id)
	GameState.discover_enemy(enemy.id)

	# ---- 镇魔塔：首通奖励 + 自动冲层
	if tower_floor > 0:
		var floor_num := tower_floor
		var first_clear := not GameState.is_tower_floor_claimed(floor_num)
		if first_clear:
			var reward: Dictionary = GameState.get_tower_first_clear_reward(floor_num)
			var reward_stones := int(reward.get("stones", 0))
			var reward_points := int(reward.get("points", 0))
			GameState.claim_tower_floor(floor_num, reward_stones, reward_points)
			# 首次击败守关妖魔、刷新最高层：厚重仪式感单次重震
			GameState.vibrate_heavy()
			if AudioManager != null:
				AudioManager.play_breakthrough()
			_log("首通第 %d 层（层段 %d）：灵石 +%d，贡献 +%d" % [floor_num,
				int(reward.get("tier", 1)), reward_stones, reward_points])
			# 5 层节点神赐（一次性）：偶数节点赐奇珍，奇数节点赐仙盟礼
			if floor_num % 5 == 0:
				_grant_tower_milestone(floor_num)
		if floor_num > GameState.tower_highest_floor:
			GameState.tower_highest_floor = floor_num
		if GameState.is_flag("tower_auto", true):
			var next_floor := floor_num + 1
			_log("第 %d 层已破，1 秒后冲击第 %d 层。" % [floor_num, next_floor])
			var scheduled := floor_num
			get_tree().create_timer(1.0).timeout.connect(func() -> void:
				if tower_floor == scheduled and active:
					start_tower_combat(scheduled + 1))
		else:
			tower_floor = 0
			stop_combat("本层已破")
		EventBus.stats_changed.emit()
		return
	if enemy.is_boss:
		GameState.push_activity_log("击败头目 %s" % enemy.display_name, "gold")
	# 藏经阁：头目掉落功法（渐进保底：连刷每场 +2.5%，20 场必出，出货清零）
	var tech_pity_key := "tech_" + enemy.id
	var tech_pity: Dictionary = GameState.pity_counters
	var tech_misses := int(tech_pity.get(tech_pity_key, 0))
	var tech_dropped := false
	for tech_value in DataRegistry.get_all_techniques():
		var tech := tech_value as TechniqueData
		if tech == null or tech.drop_enemy_id != enemy.id:
			continue
		if GameState.is_technique_unlocked(tech.id):
			continue
		var effective := float(tech.drop_chance) + 0.025 * float(tech_misses)
		if tech_misses >= 20 or randf() < effective:
			GameState.grant_technique(tech.id, "头目掉落")
			tech_dropped = true
	if tech_dropped:
		tech_pity[tech_pity_key] = 0
	else:
		tech_pity[tech_pity_key] = tech_misses + 1
	EventBus.stats_changed.emit()


func _grant_loot() -> Dictionary:
	var gained: Dictionary = {}
	if enemy == null:
		return gained
	for entry in enemy.loot_table:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var dict: Dictionary = entry
		var chance := float(dict.get("chance", 1.0))
		if randf() > chance:
			continue
		var item_id := String(dict.get("item_id", ""))
		if DataRegistry.get_item(item_id) == null:
			continue
		var min_amount := int(dict.get("min", 1))
		var max_amount := maxi(min_amount, int(dict.get("max", min_amount)))
		var amount := randi_range(min_amount, max_amount)
		GameState.add_item(item_id, amount)
		gained[item_id] = int(gained.get(item_id, 0)) + amount
	GameState.add_skill_xp("combat", enemy.xp_reward)
	GameState.stats["kills"] = int(GameState.stats.get("kills", 0)) + 1
	return gained


func _defeat() -> void:
	active = false
	win_streak = 0
	enemy_hp = 0
	player_timer = 0.0
	enemy_timer = 0.0
	_exit_tower("道体受损")
	GameState.stats["deaths"] = int(GameState.stats.get("deaths", 0)) + 1
	GameState.current_hp = 0
	GameState.restore_hp(0.3)
	_log("道体崩散，已遁出秘境（气血恢复三成）。")
	EventBus.combat_stopped.emit("道体受损，已遁出秘境")
	EventBus.stats_changed.emit()
	SaveManager.save_game(false)


func _emit_combat_state() -> void:
	var stats := GameState.get_player_stats()
	var enemy_name := "无"
	var enemy_max := 0
	var enemy_now := 0
	var player_progress := 0.0
	var enemy_progress := 0.0
	if enemy != null:
		enemy_name = enemy.display_name
		enemy_max = enemy.max_hp
		enemy_now = maxi(0, enemy_hp)
		player_progress = clampf(player_timer / maxf(0.55, float(stats["interval"])), 0.0, 1.0)
		enemy_progress = clampf(enemy_timer / maxf(0.5, enemy.attack_interval), 0.0, 1.0)
	EventBus.combat_updated.emit({
		"active": active,
		"enemy_id": "" if enemy == null else enemy.id,
		"enemy_name": enemy_name,
		"enemy_hp": enemy_now,
		"enemy_max": enemy_max,
		"hp": GameState.current_hp,
		"max_hp": GameState.get_max_hp(),
		"player_progress": player_progress,
		"enemy_progress": enemy_progress,
		"attack": int(stats["attack"]),
		"defense": int(stats["defense"]),
		"accuracy": float(stats["accuracy"]),
	})


# ---------------------------------------------------------------- 渡劫状态机

func can_start_tribulation() -> Dictionary:
	if trib_active:
		return {"ok": false, "message": "天劫已至，凝神应对"}
	var realm := GameState.get_realm()
	if realm == null or not realm.requires_tribulation:
		return {"ok": false, "message": "当前境界无需渡劫"}
	if not GameState.is_cultivation_full():
		return {"ok": false, "message": "修为未满，尚不可引劫"}
	if realm.tribulation_item != "" and GameState.get_item_count(realm.tribulation_item) < 1:
		# reason / item_id 供 UI 判定「缺丹可引导去炼制」，不再只是死锁文案
		return {
			"ok": false,
			"reason": "missing_ticket",
			"item_id": realm.tribulation_item,
			"message": "缺少 %s ×1" % DataRegistry.get_item_name(realm.tribulation_item),
		}
	if realm.tribulation_target == "magnificent":
		var ascension := FiveElementsSystem.ascension_ready()
		if not bool(ascension.get("ok", false)):
			return {"ok": false, "message": "飞升三果未齐：%s" % String(ascension.get("message", ""))}
	return {"ok": true, "message": "可引动天劫"}


func start_tribulation() -> Dictionary:
	var check := can_start_tribulation()
	if not bool(check.get("ok", false)):
		EventBus.toast.emit(String(check.get("message", "")))
		return check
	var realm := GameState.get_realm()
	if active:
		stop_combat("天劫将至，退出秘境")
	# 载入当前境界的渡劫配置
	_trib_damages = (realm.tribulation_damages as Array).duplicate()
	if _trib_damages.is_empty():
		_trib_damages = [35, 50, 65, 85, 110]
	_trib_duration = realm.tribulation_duration if realm.tribulation_duration > 0.0 else 20.0
	_trib_name = realm.tribulation_name if realm.tribulation_name != "" else "天劫"
	if realm.tribulation_item != "":
		GameState.remove_item(realm.tribulation_item, 1)
	GameState.stats["tribulation_attempts"] = int(GameState.stats.get("tribulation_attempts", 0)) + 1
	GameState.restore_hp(1.0)
	trib_active = true
	trib_elapsed = 0.0
	trib_index = 0
	_log_lines.clear()
	_tower_log_lines.clear()
	_log("引动%s！%d 道天雷将依次落下。" % [_trib_name, _trib_damages.size()])
	EventBus.tribulation_started.emit()
	_emit_trib_state()
	return {"ok": true, "message": "天雷将至"}


func _tick_tribulation(delta: float) -> void:
	trib_elapsed += delta
	while trib_index < _trib_damages.size() and trib_elapsed >= TRIB_INTERVAL * float(trib_index + 1):
		_apply_thunder(trib_index)
		trib_index += 1
		if GameState.current_hp <= 0:
			_finish_tribulation(false, "第 %d 道天雷震散护体真气" % trib_index)
			return
	if trib_index >= _trib_damages.size():
		_finish_tribulation(true, "天雷已渡")
		return
	_emit_trib_state()


func _apply_thunder(index: int) -> void:
	var base: int = int(_trib_damages[index])
	var stats := GameState.get_player_stats()
	var ward_ratio := 0.0
	var ward_name := ""
	if GameState.is_flag("auto_talisman", true):
		var ward := GameState.consume_best_ward()
		if bool(ward.get("ok", false)):
			# 藏经阁《太虚避劫经》：护符额外减伤 +8%
			ward_ratio = clampf(float(ward.get("ratio", 0.0))
				+ GameFormulas.get_technique_bonus("ward_bonus"), 0.0, 0.9)
			ward_name = String(ward.get("name", ""))
	# 统一入口：元婴起加入本源雷压，避免护符与高额防御把天雷压到保底 1 点。
	var damage := GameState.get_tribulation_thunder_damage(
		base, ward_ratio, GameState.get_dao_heart_stacks())
	GameState.current_hp = maxi(0, GameState.current_hp - damage)
	var ward_text := "" if ward_name == "" else "（%s抵消 %d%%）" % [ward_name, int(round(ward_ratio * 100.0))]
	_log("第 %d 道天雷落下：-%d 气血%s" % [index + 1, damage, ward_text])
	GameState.vibrate_heavy()
	EventBus.tribulation_thunder.emit(index, damage, ward_ratio > 0.0,
		GameState.current_hp, GameState.get_max_hp())
	if GameState.current_hp > 0 and GameState.try_auto_heal():
		_log("护道吞服%s" % GameState.last_auto_heal_name)
	EventBus.stats_changed.emit()


func _finish_tribulation(success: bool, message: String) -> void:
	trib_active = false
	if success:
		var from_name := String(_trib_name)
		GameState.advance_after_tribulation()
		# 大境界渡劫成功：专属双连击（中震 → 0.11s → 重震）
		GameState.vibrate_breakthrough()
		var realm := GameState.get_realm()
		var realm_name := "下一境界" if realm == null else realm.display_name
		_log("渡劫成功：%s，已晋入%s。" % [message, realm_name])
		EventBus.tribulation_finished.emit(true, message)
		EventBus.toast.emit("突破贺报：%s已渡，晋入%s！" % [from_name, realm_name])
	else:
		GameState.add_dao_heart_stack()
		var stacks := GameState.get_dao_heart_stacks()
		GameState.restore_hp(1.0)
		_log("渡劫失败：%s。修为未损，道心悟性 +1（当前 %d 层）。" % [message, stacks])
		EventBus.tribulation_finished.emit(false, message)
		EventBus.toast.emit("渡劫失败：修为未损，道心悟性 +1（当前 %d 层）" % stacks)
	EventBus.stats_changed.emit()
	SaveManager.save_game(false)


func _emit_trib_state() -> void:
	EventBus.tribulation_updated.emit(
		trib_elapsed,
		_trib_duration,
		GameState.current_hp,
		GameState.get_max_hp(),
		maxf(0.0, TRIB_INTERVAL * float(trib_index + 1) - trib_elapsed)
	)


# ---------------------------------------------------------------- 日志

func _log(line: String) -> void:
	# 双向隔离：镇魔塔战报入塔纪要缓冲，秘境纪要只收秘境战报
	if tower_floor > 0:
		_tower_log_lines.append(line)
		while _tower_log_lines.size() > MAX_LOG_LINES:
			_tower_log_lines.pop_front()
	else:
		_log_lines.append(line)
		while _log_lines.size() > MAX_LOG_LINES:
			_log_lines.pop_front()
	EventBus.combat_log.emit(line)




