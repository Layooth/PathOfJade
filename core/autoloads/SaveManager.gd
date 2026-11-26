extends Node
## JSON 存档读写（user://save_data.json）+ 解析式离线收益引擎
## + 移动端生命周期（切后台 / 锁屏 / 回前台）补算。

const SAVE_PATH: String = "user://save_data.json"
const BACKUP_PATH: String = "user://save_data.backup.json"
const EXPORT_PATH: String = "user://jade_codex_export.json"
const AUTOSAVE_INTERVAL: float = 20.0
const OFFLINE_REPORT_THRESHOLD: float = 60.0
## 备份刷新节流：只保留同一份 .bak 覆盖写，且最多每 5 分钟刷新一次
const BACKUP_REFRESH_INTERVAL: float = 300.0
## 曲线版本：v1 极旧档 / v2 = 0.50·0.45 且池 900·1.0 / v3 = 15 天飞升节奏 / v4 = 31 境·150 级
## （v4：技能/火候上限 150、divisor 9.2·9.5、火候 -0.20%/级）；低于 4 的旧档逐级补迁移
const EXP_CURVE_VERSION: int = 4
## ---- 历史口径快照：只供旧档迁移使用，新玩法路径不得调用 ----
## v2 火候获取倍率（v1→v2 迁移按此缩放旧池）
const V2_MASTERY_EXP_GLOBAL_MULT: float = 0.45
## v2 悟道池单动作容量（2000 × 0.45）
const V2_POOL_CAPACITY_PER_ACTION: float = 900.0
## v2 各境界修为需求：v2→v3 迁移按「旧需求占比」等比换算到新需求
const V2_REALM_REQUIREMENTS: Dictionary = {
	"qi_1": 100.0, "qi_2": 220.0, "qi_3": 400.0, "qi_4": 680.0, "qi_5": 1050.0,
	"qi_6": 1550.0, "qi_7": 2200.0, "qi_8": 3000.0, "qi_9": 4200.0,
	"foundation_early": 12000.0, "foundation_mid": 26000.0, "foundation_late": 48000.0,
	"core_early": 120000.0, "core_mid": 260000.0, "core_late": 480000.0,
	"nascent_early": 900000.0, "nascent_mid": 1800000.0, "nascent_late": 3200000.0,
	"magnificent": 0.0,
}
## v3 各境界修为需求：v3→v4 迁移同样按「旧需求占比」换算
const V3_REALM_REQUIREMENTS: Dictionary = {
	"qi_1": 200.0, "qi_2": 600.0, "qi_3": 1500.0, "qi_4": 3500.0, "qi_5": 7500.0,
	"qi_6": 15000.0, "qi_7": 28000.0, "qi_8": 48000.0, "qi_9": 75700.0,
	"foundation_early": 400000.0, "foundation_mid": 800000.0, "foundation_late": 1400000.0,
	"core_early": 5000000.0, "core_mid": 11000000.0, "core_late": 18000000.0,
	"nascent_early": 50000000.0, "nascent_mid": 100000000.0, "nascent_late": 170000000.0,
	"magnificent": 0.0,
}
## v3 各 tier 的技能等级上限（v4 下调为 20/40/60/80）：还原旧等级时必须用旧上限
const V3_SKILL_CAPS: Dictionary = {0: 20, 1: 45, 2: 75, 3: 99}
## v3 各技能的动作用量：v4 新增大量动作会让悟道池容量变大，必须按旧容量换算百分比
const V3_ACTION_COUNTS: Dictionary = {
	"herbalism": 7, "woodcutting": 6, "mining": 6, "alchemy": 12,
	"forging": 12, "talisman": 7, "cultivation": 4, "combat": 0,
}
## 短切后台的静默补算门槛（秒）
const RESUME_SETTLE_MIN: float = 5.0
const POTION_HEAL: float = 35.0

var last_offline_report: Dictionary = {}
## 最近一次成功写盘的系统时间（Unix 秒）
var last_saved_unix: float = 0.0

var _autosave_timer: float = 0.0
var _loaded: bool = false
## 上次覆盖 .bak 的系统时间（Unix 秒）
var _last_backup_unix: float = 0.0

# ---- 生命周期 / 防重复结算 ----
var _processed_seconds: float = 0.0
var _suspend_wall_unix: float = 0.0
var _suspend_processed: float = 0.0
var _resume_guard: bool = false
var _last_settle_wall_unix: float = 0.0
var _was_focused: bool = true


func _ready() -> void:
	set_process(true)
	_was_focused = DisplayServer.window_is_focused()
	# 境界突破即时落盘（大小境界切换均发 realm_changed），不等 20s 定时档
	EventBus.realm_changed.connect(_on_realm_changed)


func _on_realm_changed(_realm_id: String, _realm_name: String) -> void:
	if _loaded:
		save_game(false)


func _process(delta: float) -> void:
	_track_focus()
	if not _loaded:
		return

	# 兜底：某些机型不派发 RESUMED 通知时，用「超长帧」识别后台空档
	if delta > RESUME_SETTLE_MIN:
		var gap_start := Time.get_unix_time_from_system() - delta
		if gap_start >= _last_settle_wall_unix:
			_settle_offline(delta)
		_processed_seconds += 0.5
	else:
		_processed_seconds += delta

	_autosave_timer += delta
	if _autosave_timer >= AUTOSAVE_INTERVAL:
		_autosave_timer = 0.0
		save_game(false)


func _notification(what: int) -> void:
	match what:
		MainLoop.NOTIFICATION_APPLICATION_PAUSED, \
		MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT, \
		NOTIFICATION_WM_CLOSE_REQUEST, \
		NOTIFICATION_WM_GO_BACK_REQUEST, \
		NOTIFICATION_EXIT_TREE:
			_handle_suspend()
		MainLoop.NOTIFICATION_APPLICATION_RESUMED, \
		MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN:
			_handle_resume()


# ---------------------------------------------------------------- 生命周期

func _track_focus() -> void:
	var focused := DisplayServer.window_is_focused()
	if _was_focused and not focused:
		_handle_suspend()
	elif not _was_focused and focused:
		_handle_resume()
	_was_focused = focused


## 切后台 / 锁屏 / 失焦 / 退出：立即落盘
func _handle_suspend() -> void:
	if not _loaded:
		return
	if _suspend_wall_unix > 0.0:
		return
	_suspend_wall_unix = Time.get_unix_time_from_system()
	_suspend_processed = _processed_seconds
	save_game(false)


## 回前台：按「墙钟时间 - 实际跑过的游戏时间」算真正的挂机空档，避免桌面端双倍收益
func _handle_resume() -> void:
	if not _loaded or _resume_guard:
		return
	if _suspend_wall_unix <= 0.0:
		return
	var now := Time.get_unix_time_from_system()
	var wall_gap := maxf(0.0, now - _suspend_wall_unix)
	var played := maxf(0.0, _processed_seconds - _suspend_processed)
	var idle_gap := maxf(0.0, wall_gap - played)
	_suspend_wall_unix = 0.0
	if idle_gap < RESUME_SETTLE_MIN:
		return
	_settle_offline(idle_gap)


func _settle_offline(seconds: float) -> void:
	if seconds < RESUME_SETTLE_MIN:
		return
	if _resume_guard:
		return
	_resume_guard = true
	var report := _run_offline_quiet(seconds)
	_last_settle_wall_unix = Time.get_unix_time_from_system()
	save_game(false)
	# 零收益闭关：不弹「闭关收益玉简」阻塞弹窗——超 1 分钟只一句温和轻提示，
	# 不足 1 分钟完全静默（避免空窗空文案）
	if seconds >= OFFLINE_REPORT_THRESHOLD:
		if report_has_gains(report):
			EventBus.offline_report_ready.emit(report)
		else:
			EventBus.toast.emit("闭关归来，静心养神")
	elif report_has_gains(report):
		EventBus.resume_settled.emit(seconds)
	_resume_guard = false


# ---------------------------------------------------------------- 存档读写

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func _mark_save_unowned() -> void:
	if CloudSaveManager != null:
		CloudSaveManager.set_save_owner_uid(0)


## 本地是否存在真正的游玩进度（区别于自动生成的初始空白档）。
## 仅读 user://save_data.json，不修改既有字段或运行态。
func has_meaningful_progress() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var payload: Dictionary = parsed
	var state_value: Variant = payload.get("state", payload)
	if typeof(state_value) != TYPE_DICTIONARY:
		return false
	var state: Dictionary = state_value
	if String(state.get("realm_id", "qi_1")) != "qi_1":
		return true
	if float(state.get("cultivation_xp", 0.0)) > 0.5:
		return true
	var stats_value: Variant = state.get("stats", {})
	if typeof(stats_value) == TYPE_DICTIONARY \
			and float((stats_value as Dictionary).get("play_seconds", 0.0)) > 30.0:
		return true
	var inventory_value: Variant = state.get("inventory", {})
	if typeof(inventory_value) == TYPE_DICTIONARY:
		for count in (inventory_value as Dictionary).values():
			if int(count) > 0:
				return true
	var farm_value: Variant = state.get("farm_plots", [])
	var plots_value: Variant = farm_value
	if typeof(farm_value) == TYPE_DICTIONARY:
		plots_value = (farm_value as Dictionary).get("plots", [])
	if typeof(plots_value) == TYPE_ARRAY:
		for plot_value in plots_value:
			if typeof(plot_value) == TYPE_DICTIONARY \
					and String((plot_value as Dictionary).get("seed_id", "")) != "":
				return true
	for key in ["skill_xp", "action_mastery_xp", "mastery_pool"]:
		var progress_value: Variant = state.get(key, {})
		if typeof(progress_value) == TYPE_DICTIONARY:
			for value in (progress_value as Dictionary).values():
				if float(value) > 0.5:
					return true
	var slots_value: Variant = state.get("active_slots", [])
	if typeof(slots_value) == TYPE_ARRAY:
		for slot in slots_value:
			if String(slot) != "":
				return true
	var equipment_value: Variant = state.get("equipment", {})
	if typeof(equipment_value) == TYPE_DICTIONARY:
		for entry in (equipment_value as Dictionary).values():
			if typeof(entry) == TYPE_DICTIONARY \
					and String((entry as Dictionary).get("id", "")) != "":
				return true
	for key in ["discovered_items", "discovered_enemies", "defeated_enemies"]:
		var discovered: Variant = state.get(key, {})
		if typeof(discovered) == TYPE_DICTIONARY and not (discovered as Dictionary).is_empty():
			return true
	if int(state.get("tower_highest_floor", 0)) > 0 \
			or int(state.get("alliance_points", 0)) > 0 \
			or int(state.get("bounties_done", 0)) > 0 \
			or int(state.get("crimson_fruit_eaten", 0)) > 0:
		return true
	var bounties_value: Variant = state.get("active_bounties", [])
	if typeof(bounties_value) == TYPE_ARRAY and not (bounties_value as Array).is_empty():
		return true
	return false


func get_save_path() -> String:
	return ProjectSettings.globalize_path(SAVE_PATH)


func get_export_path() -> String:
	return ProjectSettings.globalize_path(EXPORT_PATH)


## 当前完整存档字典（与写盘结构一致）；云篆上传直接复用，避免读旧文件漏掉刚产出的进度
func build_save_payload() -> Dictionary:
	var saved_at := Time.get_unix_time_from_system()
	return {
		"version": 1,
		"exp_curve_version": EXP_CURVE_VERSION,
		"saved_at": saved_at,
		"saved_at_text": Time.get_datetime_string_from_system(),
		"state": GameState.to_dict(),
	}


func save_game(notify: bool = true) -> bool:
	var payload := build_save_payload()
	var saved_at := float(payload.get("saved_at", 0.0))
	# 紧凑序列化（不带缩进）：同一份状态体积约为美化格式的 1/2~1/3
	var text := JSON.stringify(payload)
	var tmp_path := SAVE_PATH + ".tmp"
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		push_error("无法写入存档：%s" % FileAccess.get_open_error())
		return false
	file.store_string(text)
	file.flush()
	file.close()
	# 原子覆盖：先写 .tmp 再重命名；备份只有一份 .bak，且低频刷新避免反复整盘复制
	if FileAccess.file_exists(SAVE_PATH):
		var backup_due := not FileAccess.file_exists(BACKUP_PATH) \
			or saved_at - _last_backup_unix >= BACKUP_REFRESH_INTERVAL
		if backup_due and DirAccess.copy_absolute(SAVE_PATH, BACKUP_PATH) == OK:
			_last_backup_unix = saved_at
	var rename_error := DirAccess.rename_absolute(tmp_path, SAVE_PATH)
	if rename_error != OK:
		push_error("存档写入失败：%s" % error_string(rename_error))
		return false
	last_saved_unix = saved_at
	_loaded = true
	if notify:
		EventBus.game_saved.emit(get_save_path())
		EventBus.toast.emit("道途已刻入玉简")
	return true


## 读档 / 云导入后的槽位恢复：只清实时计时进度，不清空合法运转槽。
## 离线收益已按完整时长结算，进度归零避免重新在线时与离线折算重复计时；
## 仅当动作无效、原料不足或吐纳已圆满/渡劫瓶颈时静默停掉该槽（不弹 toast）。
func _prepare_actions_after_load() -> void:
	if ActionRunner != null:
		for slot in range(GameState.SLOT_COUNT):
			ActionRunner.reset_progress(slot)
	for slot in range(GameState.SLOT_COUNT):
		var action_id := GameState.active_slots[slot]
		if action_id == "":
			continue
		var action := DataRegistry.get_action(action_id)
		if action == null:
			GameState.stop_action(slot)
			continue
		if action.is_meditate():
			if GameState.get_realm_requirement() <= 0.0 or GameState.is_cultivation_locked():
				GameState.stop_action(slot)
			continue
		if not action.inputs.is_empty() and not GameState.has_items(action.inputs):
			GameState.stop_action(slot)


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		GameState.reset()
		GameState.stop_all_actions()
		_loaded = true
		_last_settle_wall_unix = Time.get_unix_time_from_system()
		EventBus.game_loaded.emit()
		EventBus.toast.emit("初入道途，先炼气一层")
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("无法读取存档：%s" % FileAccess.get_open_error())
		GameState.reset()
		_loaded = true
		EventBus.game_loaded.emit()
		return false
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("存档格式损坏，尝试读取备份")
		return _load_backup()
	var data: Dictionary = parsed
	var state_variant: Variant = data.get("state", {})
	if typeof(state_variant) != TYPE_DICTIONARY:
		state_variant = data
	var state: Dictionary = state_variant
	GameState.from_dict(state)
	# 旧存档曲线迁移：必须在离线补算与 UI 刷新之前完成
	_migrate_save_curves(int(data.get("exp_curve_version", 0)))
	# 旧存档没有 farm_plots：FarmManager 会安全初始化为"首块已开垦"
	FarmManager.from_dict(state.get("farm_plots", []))
	var saved_at := float(data.get("saved_at", 0.0))
	last_saved_unix = saved_at
	var now := Time.get_unix_time_from_system()
	var delta := maxf(0.0, now - saved_at)
	if bool(state.get("combat_active", false)):
		CombatEngine.resume_from_save(GameState.selected_enemy_id)
	# 离线聚合必须早于清进度：_run_offline 依赖 from_dict 恢复的 active_slots
	var report: Dictionary = {}
	if delta > 1.0:
		report = _run_offline_quiet(delta)
		_last_settle_wall_unix = Time.get_unix_time_from_system()
	# 离线已按完整时长折算；只归零实时计时进度，保留仍可继续的运转槽
	_prepare_actions_after_load()
	_loaded = true
	save_game(false)
	EventBus.game_loaded.emit()
	if not report.is_empty():
		# 与 _settle_offline 同口径：零收益不弹模态窗，超 1 分钟轻提示、不足则静默
		if delta >= OFFLINE_REPORT_THRESHOLD:
			if report_has_gains(report):
				EventBus.offline_report_ready.emit(report)
			else:
				EventBus.toast.emit("闭关归来，静心养神")
		elif report_has_gains(report):
			EventBus.toast.emit("神游片刻，已纳 %s 闭关所得" % GameFormulas.format_duration(delta))
	return true


func _load_backup() -> bool:
	if not FileAccess.file_exists(BACKUP_PATH):
		GameState.reset()
		_loaded = true
		EventBus.game_loaded.emit()
		return false
	var file := FileAccess.open(BACKUP_PATH, FileAccess.READ)
	if file == null:
		GameState.reset()
		_loaded = true
		EventBus.game_loaded.emit()
		return false
	var text := file.get_as_text()
	file.close()
	return import_save_json(text)


func reset_save() -> void:
	_mark_save_unowned()
	GameState.stop_all_actions()
	if CombatEngine.is_active():
		CombatEngine.stop_combat("道途重启")
	GameState.reset()
	FarmManager.from_dict([])
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	_loaded = true
	_last_settle_wall_unix = Time.get_unix_time_from_system()
	save_game(false)
	EventBus.game_loaded.emit()
	EventBus.toast.emit("已重开道途，一切归元")


## 退出仙籍并清空本机残留：删除本地玉简与备份，不写盘、不动云端；
## 运行态回到初始，方便换号后直接从云端重拉。
func clear_local_save() -> void:
	_mark_save_unowned()
	GameState.stop_all_actions()
	if CombatEngine.is_active():
		CombatEngine.stop_combat("散功重修")
	GameState.reset()
	FarmManager.from_dict([])
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	if FileAccess.file_exists(BACKUP_PATH):
		DirAccess.remove_absolute(BACKUP_PATH)
	_loaded = true
	_last_settle_wall_unix = Time.get_unix_time_from_system()
	EventBus.game_loaded.emit()


func export_save_json() -> String:
	var payload := {
		"version": 1,
		"exp_curve_version": EXP_CURVE_VERSION,
		"saved_at": Time.get_unix_time_from_system(),
		"saved_at_text": Time.get_datetime_string_from_system(),
		"state": GameState.to_dict(),
	}
	var text := JSON.stringify(payload)
	var file := FileAccess.open(EXPORT_PATH, FileAccess.WRITE)
	if file == null:
		EventBus.toast.emit("导出失败：无法写入文件")
		return ""
	file.store_string(text)
	file.close()
	DisplayServer.clipboard_set(text)
	EventBus.toast.emit("存档已导出并复制到剪贴板")
	return ProjectSettings.globalize_path(EXPORT_PATH)


func import_save_json(text: String) -> bool:
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		EventBus.toast.emit("导入失败：JSON 格式不正确")
		return false
	var data: Dictionary = parsed
	var state_variant: Variant = data.get("state", data)
	if typeof(state_variant) != TYPE_DICTIONARY:
		EventBus.toast.emit("导入失败：缺少 state 字段")
		return false
	_mark_save_unowned()
	GameState.stop_all_actions()
	GameState.from_dict(state_variant)
	# 导入的旧档同样执行一次保级迁移
	_migrate_save_curves(int(data.get("exp_curve_version", 0)))
	var imported: Dictionary = state_variant
	FarmManager.from_dict(imported.get("farm_plots", []))
	# 云导入恢复出 active_slots 后同样只清计时进度并校验可运转条件，
	# 绝不在这里把恢复出来的槽位再次清零
	_prepare_actions_after_load()
	_loaded = true
	_last_settle_wall_unix = Time.get_unix_time_from_system()
	save_game(false)
	EventBus.game_loaded.emit()
	EventBus.toast.emit("存档导入成功")
	return true


func import_save_from_file(path: String) -> bool:
	if not FileAccess.file_exists(path):
		EventBus.toast.emit("导入失败：文件不存在")
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		EventBus.toast.emit("导入失败：无法读取文件")
		return false
	var text := file.get_as_text()
	file.close()
	return import_save_json(text)


# ---------------------------------------------------------------- 旧档曲线迁移

## 统一入口：按存档顶层 exp_curve_version 依次补齐缺失的迁移步骤。
## v1（极旧）→ v2（0.50 / 0.45、池 900）→ v3（0.42 / 0.32、池 3000×0.55、新修为阶梯）
## → v4（31 境、上限 150、divisor 9.2 / 9.5）。
## 只执行比存档版本更新的步骤，已迁移过的档不会被二次缩放；写盘时顶层会写入当前版本。
func _migrate_save_curves(saved_version: int) -> void:
	if saved_version < 2:
		_migrate_exp_curve_v1_to_v2()
	if saved_version < 3:
		_migrate_curves_v2_to_v3()
	if saved_version < 4:
		_migrate_curves_v3_to_v4()
	# 境界技能上限锁经验：迁移后（含无迁移的当前版本档）统一钳制，
	# 越界/暂存的溢出经验直接舍弃——必须在旧档曲线换算完成之后做，
	# 否则旧曲线的累计经验会被新曲线误截，破坏旧档兼容。
	GameState.clamp_skill_xp_to_cap()


## v1 → v2：旧档只记录累计经验（skill_xp / action_mastery_xp），不记录等级。为绝对保级且无损：
## 1) 用改版前曲线还原旧等级与该级内已积累经验（residual）；
## 2) 把累计经验抬到新曲线该等级起点，并原样保留 residual；
##    （新曲线单级步长恒大于旧曲线，residual 不会越级）
## 3) 再做一次溢出钳制，确保进度条不越界、不会连跳。
func _migrate_exp_curve_v1_to_v2() -> void:
	var cap := GameState.get_skill_level_cap()
	for skill_id in DataRegistry.skill_order:
		var saved := GameState.get_skill_xp(skill_id)
		var old_level := GameFormulas.legacy_skill_level_for_xp(saved, cap)
		var residual := maxf(0.0, saved - GameFormulas.legacy_skill_xp_for_level(old_level))
		var value := GameFormulas.xp_for_level(old_level) + residual
		var level := GameFormulas.level_for_xp(value, cap)
		if level < cap:
			value = minf(value, GameFormulas.xp_for_level(level + 1) - 1.0)
		GameState.skill_xp[skill_id] = maxf(0.0, value)

	for action_key in GameState.action_mastery_xp.keys():
		var action_id := String(action_key)
		var saved := GameState.get_mastery_xp(action_id)
		var old_level := GameFormulas.legacy_mastery_level_for_xp(saved)
		var residual := maxf(0.0, saved - GameFormulas.legacy_mastery_xp_for_level(old_level))
		var value := GameFormulas.mastery_xp_for_level(old_level) + residual
		var level := GameFormulas.mastery_level_for_xp(value)
		if level < GameFormulas.MAX_MASTERY_LEVEL:
			value = minf(value, GameFormulas.mastery_xp_for_level(level + 1) - 1.0)
		GameState.action_mastery_xp[action_id] = maxf(0.0, value)

	# v1 池容量为 2000×动作数，v2 为 900×动作数：按 v2 倍率等比缩放，保持池进度百分比；
	# 注意这里用快照常量 V2_MASTERY_EXP_GLOBAL_MULT，不能用当前 MASTERY_EXP_GLOBAL_MULT（v3 已改 0.32）。
	for skill_id in DataRegistry.skill_order:
		var capacity := GameState.get_pool_capacity(skill_id)
		var scaled := GameState.get_pool_current(skill_id) * V2_MASTERY_EXP_GLOBAL_MULT
		GameState.mastery_pool[skill_id] = clampf(scaled, 0.0, capacity)

	GameState.current_hp = clampi(GameState.current_hp, 0, GameState.get_max_hp())


## v2 → v3：修为阶梯、技能/火候获取倍率、悟道池容量同时改版，必须无损保级。
## 1) 境界不回退：境界内修为按「旧需求占比」等比换算到新需求；渡劫瓶颈满值保持满值，
##    非渡劫境界不能停在满值（from_dict 的卡死自检此时已跑过），留 1 点余量交给下一次吐纳；
## 2) 技能/火候的**阈值曲线没有改**（只改了获取倍率），等级与级内比例天然保持，
##    这里再做一次区间钳制，兜住浮点误差与手改存档，确保零掉级；
## 3) 悟道池按「旧池当前值 / 旧池容量」换算到新容量，10/25/50/95% 里程碑百分比原样保留。
func _migrate_curves_v2_to_v3() -> void:
	var realm := GameState.get_realm()
	if realm != null and realm.cultivation_required > 0.0:
		var old_required := float(V2_REALM_REQUIREMENTS.get(realm.id, realm.cultivation_required))
		var new_required := realm.cultivation_required
		var ratio := clampf(GameState.cultivation_xp / maxf(1.0, old_required), 0.0, 1.0)
		var value := ratio * new_required
		if value >= new_required and not realm.requires_tribulation:
			value = maxf(0.0, new_required - 1.0)
		GameState.cultivation_xp = clampf(value, 0.0, new_required)

	var cap := GameState.get_skill_level_cap()
	for skill_id in DataRegistry.skill_order:
		GameState.skill_xp[skill_id] = _clamp_to_level_band(GameState.get_skill_xp(skill_id), cap)
	for action_key in GameState.action_mastery_xp.keys():
		var action_id := String(action_key)
		GameState.action_mastery_xp[action_id] = _clamp_to_level_band(
			GameState.get_mastery_xp(action_id), GameFormulas.MAX_MASTERY_LEVEL, true)

	for skill_id in DataRegistry.skill_order:
		var old_capacity := V2_POOL_CAPACITY_PER_ACTION \
			* float(DataRegistry.get_skill_action_count(skill_id))
		var new_capacity := GameState.get_pool_capacity(skill_id)
		var ratio := clampf(GameState.get_pool_current(skill_id) / maxf(1.0, old_capacity), 0.0, 1.0)
		GameState.mastery_pool[skill_id] = clampf(ratio * new_capacity, 0.0, new_capacity)

	GameState.current_hp = clampi(GameState.current_hp, 0, GameState.get_max_hp())


## 把累计经验钳制在「当前等级起点 ~ 下一级起点 −1」区间：
## 阈值曲线未改时对正常存档是恒等变换，仅用于保证等级与级内比例不被越界数据带走。
func _clamp_to_level_band(xp: float, cap: int, mastery: bool = false) -> float:
	var value := maxf(0.0, xp)
	var level := 1
	var floor_xp := 0.0
	var next_xp := 0.0
	if mastery:
		level = GameFormulas.mastery_level_for_xp(value)
		floor_xp = GameFormulas.mastery_xp_for_level(level)
		next_xp = GameFormulas.mastery_xp_for_level(mini(level + 1, GameFormulas.MAX_MASTERY_LEVEL))
	else:
		level = GameFormulas.level_for_xp(value, cap)
		floor_xp = GameFormulas.xp_for_level(level)
		next_xp = GameFormulas.xp_for_level(mini(level + 1, cap))
	if next_xp <= floor_xp:
		return floor_xp
	return clampf(value, floor_xp, next_xp - 1.0)


## v3 → v4：境界从 19 扩到 31、等级上限 99→150、曲线分母 6.2/6.5 → 9.2/9.5。
## 1) 境界不回退，境界内修为按「旧需求占比」换算（前 18 境需求再次重排，magnificent 需求仍为 0）；
##    旧档停在 magnificent（真仙）时需求为 0，原样保留，不会被打回。
## 2) 技能/火候：用 v3 旧阈值曲线还原等级与级内残值，再抬到 v4 曲线的同级起点；
##    技能上限下调的 tier（20/40/60/80）按新上限钳制，其余等级完整保留。
## 3) 悟道池：单动作容量仍为 3000，只需按新上限钳一次。
func _migrate_curves_v3_to_v4() -> void:
	var realm := GameState.get_realm()
	if realm != null and realm.cultivation_required > 0.0:
		var old_required := float(V3_REALM_REQUIREMENTS.get(realm.id, realm.cultivation_required))
		var new_required := realm.cultivation_required
		var ratio := clampf(GameState.cultivation_xp / maxf(1.0, old_required), 0.0, 1.0)
		var value := ratio * new_required
		if value >= new_required and not realm.requires_tribulation:
			value = maxf(0.0, new_required - 1.0)
		GameState.cultivation_xp = clampf(value, 0.0, new_required)

	var cap := GameState.get_skill_level_cap()
	var tier := 0 if realm == null else realm.tier
	var old_cap := int(V3_SKILL_CAPS.get(tier, cap))
	for skill_id in DataRegistry.skill_order:
		var saved := GameState.get_skill_xp(skill_id)
		# 用旧上限还原真实旧等级（v4 下调了前三个大境的 cap）
		var old_level := GameFormulas.v3_skill_level_for_xp(saved, maxi(old_cap, cap))
		var level := mini(old_level, cap)
		# 级内进度按「比例」搬运：旧曲线步长更大，直接搬残值会白送等级
		var old_floor := GameFormulas.v3_skill_xp_for_level(old_level)
		var old_span := maxf(1.0, GameFormulas.v3_skill_xp_for_level(old_level + 1) - old_floor)
		var ratio := clampf((saved - old_floor) / old_span, 0.0, 0.9999)
		var new_floor := GameFormulas.xp_for_level(level)
		var new_span := maxf(1.0, GameFormulas.xp_for_level(mini(level + 1, cap)) - new_floor)
		var value := new_floor + ratio * new_span
		if level >= cap:
			value = GameFormulas.xp_for_level(cap)
		GameState.skill_xp[skill_id] = maxf(0.0, value)

	for action_key in GameState.action_mastery_xp.keys():
		var action_id := String(action_key)
		var saved := GameState.get_mastery_xp(action_id)
		var level := GameFormulas.v3_mastery_level_for_xp(saved)
		var old_floor := GameFormulas.v3_mastery_xp_for_level(level)
		var old_span := maxf(1.0, GameFormulas.v3_mastery_xp_for_level(level + 1) - old_floor)
		var ratio := clampf((saved - old_floor) / old_span, 0.0, 0.9999)
		var new_floor := GameFormulas.mastery_xp_for_level(level)
		var new_span := maxf(1.0,
			GameFormulas.mastery_xp_for_level(mini(level + 1, GameFormulas.MAX_MASTERY_LEVEL)) - new_floor)
		var value := new_floor + ratio * new_span
		if level >= GameFormulas.MAX_MASTERY_LEVEL:
			value = GameFormulas.mastery_xp_for_level(GameFormulas.MAX_MASTERY_LEVEL)
		GameState.action_mastery_xp[action_id] = maxf(0.0, value)

	# 悟道池：v4 每个技能都新增了动作 → 容量变大，必须按「旧池 / 旧容量」换算，
	# 否则同一个池值会因为分母变大而掉档（例如采药 84% 会变成 49%）。
	for skill_id in DataRegistry.skill_order:
		var old_count := int(V3_ACTION_COUNTS.get(skill_id, 0))
		var old_capacity := GameFormulas.POOL_CAPACITY_PER_ACTION * float(maxi(1, old_count))
		var new_capacity := GameState.get_pool_capacity(skill_id)
		var ratio := clampf(GameState.get_pool_current(skill_id) / maxf(1.0, old_capacity), 0.0, 1.0)
		GameState.mastery_pool[skill_id] = clampf(ratio * new_capacity, 0.0, new_capacity)

	GameState.current_hp = clampi(GameState.current_hp, 0, GameState.get_max_hp())


# ---------------------------------------------------------------- 离线收益（解析式）

## 调试：模拟一次「切后台 N 秒后回前台」，走与真实生命周期完全相同的补算路径。
## 桌面端失焦后引擎仍在跑逻辑，不会天然产生空档，故提供此入口验收。
func debug_suspend_resume(seconds: float) -> void:
	if not _loaded:
		return
	_handle_suspend()
	if _suspend_wall_unix <= 0.0:
		return
	_suspend_wall_unix -= maxf(0.0, seconds)
	_suspend_processed = _processed_seconds
	_handle_resume()


func simulate_offline(hours: float) -> Dictionary:
	var seconds := maxf(1.0, hours * 3600.0)
	# 调试联动：灵田按同样的时间跨度成熟
	FarmManager.shift_planted(seconds)
	var report := _run_offline_quiet(seconds)
	report["simulated"] = true
	save_game(false)
	# 推演闭关走同一口径：零收益不弹模态窗，只一句温和轻提示
	if report_has_gains(report):
		EventBus.offline_report_ready.emit(report)
	else:
		EventBus.toast.emit("闭关归来，静心养神")
	return report


## 离线聚合统一静音震动：挂机回来只弹结算，不在结算过程中连震
func _run_offline_quiet(delta_seconds: float) -> Dictionary:
	if GameState.offline_settling:
		return _run_offline(delta_seconds)
	GameState.offline_settling = true
	var report := _run_offline(delta_seconds)
	GameState.offline_settling = false
	return report


## 闭关结算是否产生实际收益：决定弹不弹「闭关收益玉简」模态窗。
## 只认真实进账——修为 / 百艺熟练度 / 物品（灵石与战利品）/ 秘境击杀 / 灵田成熟；
## 注记（闭关上限截断、聚气丹耗尽等）只是情况说明，不算收益。
func report_has_gains(report: Dictionary) -> bool:
	if int(report.get("cultivation", 0)) > 0:
		return true
	for row in report.get("skills", []):
		if typeof(row) == TYPE_DICTIONARY and float((row as Dictionary).get("xp", 0.0)) > 0.0:
			return true
	for row in report.get("items", []):
		if typeof(row) == TYPE_DICTIONARY and int((row as Dictionary).get("amount", 0)) > 0:
			return true
	var combat: Variant = report.get("combat", {})
	if typeof(combat) == TYPE_DICTIONARY and int((combat as Dictionary).get("kills", 0)) > 0:
		return true
	if String(report.get("farm_note", "")) != "":
		return true
	return false


func _run_offline(delta_seconds: float) -> Dictionary:
	var cap_hours := GameState.get_offline_cap_hours()
	var report: Dictionary = {
		"simulated": false,
		"seconds": int(maxf(0.0, delta_seconds)),
		"settled_seconds": 0,
		"duration_text": GameFormulas.format_duration(delta_seconds),
		"settled_text": "",
		"capped": false,
		"cap_hours": cap_hours,
		"items": [],
		"skills": [],
		"cultivation": 0,
		"notes": [],
		"withdrew": "",
		"combat": {},
		"realm_before": "",
		"realm_after": "",
		"farm_note": "",
	}
	if delta_seconds <= 1.0:
		return report
	var cap_seconds := GameFormulas.offline_cap_seconds(cap_hours)
	var settled := minf(delta_seconds, cap_seconds)
	report["settled_seconds"] = int(settled)
	report["settled_text"] = GameFormulas.format_duration(settled)
	report["capped"] = delta_seconds > cap_seconds + 1.0
	if bool(report["capped"]):
		report["notes"].append("闭关时长超出 %d 小时上限，仅折算 %s" % [int(cap_hours), report["settled_text"]])

	var realm_before := GameState.get_realm()
	report["realm_before"] = "" if realm_before == null else realm_before.display_name

	var skill_before: Dictionary = {}
	for skill_id in DataRegistry.skill_order:
		skill_before[skill_id] = GameState.get_skill_level(skill_id)

	var item_accum: Dictionary = {}
	var skill_accum: Dictionary = {}

	# 灵潭垂钓离线简算（最多补算 120 竿），产出并入统一离线报告。
	var fishing_report: Dictionary = FishingTeaSystem.settle_offline(settled)
	var fishing_items: Variant = fishing_report.get("items", {})
	if typeof(fishing_items) == TYPE_DICTIONARY:
		for item_id in (fishing_items as Dictionary).keys():
			item_accum[item_id] = int(item_accum.get(item_id, 0)) + int((fishing_items as Dictionary)[item_id])

	for slot in range(GameState.SLOT_COUNT):
		var action_id := GameState.active_slots[slot]
		if action_id == "":
			continue
		_offline_action(action_id, settled, item_accum, skill_accum, report)

	if CombatEngine.is_active():
		_offline_combat(settled, item_accum, skill_accum, report)

	var mature_plots := FarmManager.count_mature()
	if mature_plots > 0:
		report["farm_note"] = "有 %d 块灵田已成熟，可前往洞府收割" % mature_plots

	# ---- 汇总物品
	var item_rows: Array = []
	for item_id in item_accum.keys():
		var amount := int(item_accum[item_id])
		if amount <= 0:
			continue
		item_rows.append({
			"id": String(item_id),
			"name": DataRegistry.get_item_name(String(item_id)),
			"amount": amount,
		})
	item_rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["amount"]) > int(b["amount"])
	)
	report["items"] = item_rows

	# ---- 汇总技能等级变化
	var skill_rows: Array = []
	for skill_id in DataRegistry.skill_order:
		var gained := float(skill_accum.get(skill_id, 0.0))
		if gained <= 0.0:
			continue
		var before_level := int(skill_before.get(skill_id, 1))
		var after_level := GameState.get_skill_level(skill_id)
		skill_rows.append({
			"id": skill_id,
			"name": DataRegistry.get_skill_name(skill_id),
			"xp": gained,
			"from": before_level,
			"to": after_level,
		})
	skill_rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["xp"]) > float(b["xp"])
	)
	report["skills"] = skill_rows

	var realm_after := GameState.get_realm()
	report["realm_after"] = "" if realm_after == null else realm_after.display_name
	last_offline_report = report
	return report


## 离线单动作推演：按完整时长结算产出。
## 境界技能上限锁经验只锁「技能经验入账」，绝不截断次数/材料/成品——
## 满级挂机一整晚，灵草矿石丹药照常按完整时长累计；仅原料不足才缩短次数。
func _offline_action(action_id: String, seconds: float, item_accum: Dictionary,
		skill_accum: Dictionary, report: Dictionary) -> void:
	var action := DataRegistry.get_action(action_id)
	if action == null:
		return
	var interval := ActionRunner.get_effective_interval(action_id)
	var count := int(floor(seconds / interval))
	if count <= 0:
		return
	# 元婴「元婴出窍」：离线收益结算效率 +15%
	count = int(round(float(count) * GameState.get_offline_efficiency()))
	var double_chance := ActionRunner.get_double_chance(action_id)

	if action.is_meditate():
		var pill_id := action.pill_item_id
		var pill_iters := 0
		if pill_id != "" and bool(GameState.flags.get("auto_pill", true)):
			var pills := GameState.get_item_count(pill_id)
			if pills > 0:
				pill_iters = mini(count, pills)
				GameState.remove_item(pill_id, pill_iters)
				if pill_iters < count:
					var rest := count - pill_iters
					report["notes"].append("聚气丹耗尽，后 %d 次吐纳转为静坐（修为 %d）" % [rest, action.cultivation_gain])
		var gain := pill_iters * action.pill_cultivation_gain + (count - pill_iters) * action.cultivation_gain
		# 与在线同一口径：功法、灵茶、五行法则与灵根亲和共同提升吐纳修为
		gain = int(roundf(float(gain) * GameState.get_cultivation_multiplier()
			* (1.0 + GameFormulas.get_technique_bonus("meditate_xp")
			+ FishingTeaSystem.get_bonus("meditate_cultivation")
			+ FiveElementsSystem.get_bonus("meditate_cultivation")
			+ SpiritRootSystem.get_bonus("meditate_cultivation"))))
		GameState.add_cultivation(float(gain))
		report["cultivation"] = int(report.get("cultivation", 0)) + gain
		# 离线按“单次实际入账值 × 次数”聚合，前台/离线同一口径
		var med_skill_gain := GameState.get_action_skill_xp_gain(action_id) * count
		var med_mastery_gain := GameState.get_action_mastery_xp_gain(action_id) * count
		var applied_med := GameState.grant_skill_xp(action.skill_id, med_skill_gain)
		GameState.grant_mastery_xp(action_id, med_mastery_gain)
		skill_accum[action.skill_id] = float(skill_accum.get(action.skill_id, 0.0)) + float(applied_med)
		return

	if action.is_craft() and not action.inputs.is_empty():
		var affordable := GameState.max_affordable(action.inputs)
		if affordable < count:
			var used_seconds := float(affordable) * interval
			report["notes"].append("%s：原料仅够 %d 次，第 %s 停止" % [
				action.display_name, affordable, GameFormulas.format_duration(used_seconds)
			])
			count = affordable
		if count <= 0:
			return
		GameState.consume_many(action.inputs, count)

	for item_id in action.outputs.keys():
		var per := int(action.outputs[item_id])
		var base_total := per * count
		var extra := int(roundf(float(base_total) * double_chance))
		var total := base_total + extra
		GameState.add_item(String(item_id), total)
		item_accum[item_id] = int(item_accum.get(item_id, 0)) + total

	var seed_drop := DataRegistry.get_seed_drop(action_id)
	if not seed_drop.is_empty():
		var seed_id := String(seed_drop.get("seed_id", ""))
		var expected := int(roundf(float(count) * float(seed_drop.get("chance", 0.0))))
		if expected > 0:
			GameState.add_item(seed_id, expected)
			item_accum[seed_id] = int(item_accum.get(seed_id, 0)) + expected

	var skill_gain := GameState.get_action_skill_xp_gain(action_id) * count
	var mastery_gain := GameState.get_action_mastery_xp_gain(action_id) * count
	var applied_skill := GameState.grant_skill_xp(action.skill_id, skill_gain)
	GameState.grant_mastery_xp(action_id, mastery_gain)
	skill_accum[action.skill_id] = float(skill_accum.get(action.skill_id, 0.0)) + float(applied_skill)
	GameState.stats["actions_completed"] = int(GameState.stats.get("actions_completed", 0)) + count


func _offline_combat(seconds: float, item_accum: Dictionary, skill_accum: Dictionary, report: Dictionary) -> void:
	var enemy := CombatEngine.get_current_enemy()
	if enemy == null:
		return
	var stats := GameState.get_player_stats()
	var player_interval := maxf(0.55, float(stats["interval"]))
	var enemy_interval := maxf(0.5, enemy.attack_interval)
	var raw_accuracy := float(stats.get("raw_accuracy", stats.get("accuracy", 0.85)))
	var effective_accuracy := clampf(raw_accuracy - enemy.dodge, 0.35, 0.99)
	var player_dps := GameFormulas.expected_damage(int(stats["attack"]), enemy.defense) \
		* effective_accuracy / player_interval
	if player_dps <= 0.01:
		return
	var time_to_kill := float(maxi(1, enemy.max_hp)) / player_dps
	var enemy_dps := GameFormulas.expected_damage(enemy.attack, int(stats["defense"])) * 0.95 / enemy_interval

	var talismans := GameState.get_item_count(DataRegistry.EARTH_TALISMAN)
	var talisman_active := bool(GameState.flags.get("auto_talisman", true)) and talismans > 0
	var expected_hits := seconds / enemy_interval
	var reduction := 0.0
	var talismans_used := 0
	if talisman_active:
		talismans_used = int(minf(float(talismans), expected_hits))
		reduction = 0.4 * (float(talismans_used) / maxf(1.0, expected_hits))
	var effective_dps := enemy_dps * (1.0 - reduction)

	var potions := GameState.get_item_count(DataRegistry.HEAL_POWDER)
	var budget := float(GameState.current_hp) + float(potions) * POTION_HEAL
	var effective_seconds := seconds
	var withdrew := ""
	if effective_dps > 0.01 and effective_dps * seconds > budget:
		effective_seconds = budget / effective_dps
		withdrew = "第 %s 回春散耗尽，已遁出秘境" % GameFormulas.format_duration(effective_seconds)
		report["withdrew"] = withdrew
		report["notes"].append(withdrew)

	var damage_taken := effective_dps * effective_seconds
	var potions_used := int(minf(float(potions), ceilf(maxf(0.0, damage_taken - float(GameState.current_hp)) / POTION_HEAL)))
	if potions_used > 0:
		GameState.remove_item(DataRegistry.HEAL_POWDER, potions_used)
	if talismans_used > 0:
		GameState.remove_item(DataRegistry.EARTH_TALISMAN, talismans_used)
	GameState.current_hp = clampi(int(roundf(budget - damage_taken)), 1, GameState.get_max_hp())

	var kills := int(floor(effective_seconds / time_to_kill))
	if kills > 0 and BountyManager != null:
		BountyManager.add_offline_kills(enemy.id, kills)
	if kills <= 0:
		report["combat"] = {
			"enemy_name": enemy.display_name,
			"kills": 0,
			"potions_used": potions_used,
			"talismans_used": talismans_used,
		}
		return
	for entry in enemy.loot_table:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var dict: Dictionary = entry
		var item_id := String(dict.get("item_id", ""))
		if DataRegistry.get_item(item_id) == null:
			continue
		var chance := float(dict.get("chance", 1.0))
		var min_amount := int(dict.get("min", 1))
		var max_amount := maxi(min_amount, int(dict.get("max", min_amount)))
		var avg_amount := (float(min_amount) + float(max_amount)) * 0.5
		var total := int(roundf(float(kills) * chance * avg_amount))
		if total <= 0:
			continue
		GameState.add_item(item_id, total)
		item_accum[item_id] = int(item_accum.get(item_id, 0)) + total
	var kill_gain := GameState.get_skill_gain("combat", enemy.xp_reward)
	var applied_combat := GameState.grant_skill_xp("combat", kill_gain * kills)
	skill_accum["combat"] = float(skill_accum.get("combat", 0.0)) + float(applied_combat)
	GameState.stats["kills"] = int(GameState.stats.get("kills", 0)) + kills
	report["combat"] = {
		"enemy_name": enemy.display_name,
		"kills": kills,
		"potions_used": potions_used,
		"talismans_used": talismans_used,
		"time_to_kill": time_to_kill,
	}


