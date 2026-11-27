extends Node
## 零外部素材的古风程序化音效引擎 + 双 BGM 播放器（日常平静 / 秘境战斗）。
## SFX 启动时合成 16-bit / 单声道 / 22050Hz AudioStreamWAV 并缓存，6 个播放器轮询；
## BGM 由两个交替接管 Music 总线的播放器实现 1.2s 交叉淡入淡出：
## 日常 bgm.ogg 与战斗 bgm_battle.ogg 互不打断，支持「随境而变 / 轮流雅奏」两种编排。

const SAMPLE_RATE: int = 22050
const PLAYER_POOL: int = 6
const BGM_BASE_DB: float = -4.0
## 交叉淡入淡出时长：新曲自 -30dB 渐至目标音量，旧曲同步渐至 -30dB 后停止
const BGM_CROSSFADE_SEC: float = 1.2
const BGM_CROSSFADE_FLOOR_DB: float = -30.0
## 全局音乐开关关闭时的收尾时长（不做交叉，短促收干净）
const BGM_FADE_OUT_SEC: float = 0.4
## 两曲等响补偿（唯一钩子）：按母带 EBU R128 实测
## 日常 bgm.ogg -15.8 LUFS / 战斗 bgm_battle.ogg -17.8 LUFS，
## 战斗曲源本低 2dB，此处 +2dB 拉平，切曲听感音量一致；
## 更换任一曲目后须重测并按差值调整此常量，勿在别处再叠音量差
const BATTLE_BGM_DB_OFFSET: float = 2.0

## 曲目键：calm = 日常平静 / battle = 秘境与镇魔塔
const BGM_TRACK_CALM: String = "calm"
const BGM_TRACK_BATTLE: String = "battle"
## 播放模式：0 随境而变（默认）/ 1 轮流雅奏
const BGM_MODE_AMBIENT: int = 0
const BGM_MODE_ROTATE: int = 1
## 曲目候选路径：优先根目录，其次 assets/audio；导出包内走 ResourceLoader
const BGM_TRACK_PATHS: Dictionary = {
	BGM_TRACK_CALM: [
		"res://bgm.ogg",
		"res://audio/bgm.ogg",
		"res://assets/bgm.ogg",
		"res://assets/audio/bgm.ogg",
	],
	BGM_TRACK_BATTLE: [
		"res://bgm_battle.ogg",
		"res://audio/bgm_battle.ogg",
		"res://assets/bgm_battle.ogg",
		"res://assets/audio/bgm_battle.ogg",
	],
}
## 轮流雅奏的曲尾检测间隔（秒）
const BGM_ROTATE_POLL_SEC: float = 0.25
## 随境而变的兜底校准间隔（秒）：自动复活 / 读档续战等无信号路径
const BGM_CONTEXT_POLL_SEC: float = 1.0
const REAL_SFX_VOLUME_DB: float = -4.0
const REAL_SFX_COOLDOWN_SEC: float = 0.08
const REAL_SFX_FADE_IN_SEC: float = 0.035
const SFX_FADE_IN_SEC: float = 0.012
const SFX_FADE_OUT_SEC: float = 0.12

## ---- 高频循环拟音防叠音（采集 / 制造 / 普攻 / 收竿） ----
## 同一音效 ID 的最短重复间隔
const LOOP_SFX_COOLDOWN_SEC: float = 0.35
## 全局最小间隔：0.18s 内最多放行一条循环拟音，多槽同帧完成只响一次
const LOOP_SFX_MIN_GAP_MS: int = 180
## 同时发声的短音效声部上限（含真实拟音与程序化兜底）
const MAX_SFX_VOICES: int = 4
## 循环拟音音量层级：比 UI 点击(-5) / 突破(-1.5) / 稀有掉落(-1.5) / 渡劫(-2) 低 4~6dB
const LOOP_SFX_VOLUME_DB: float = -9.0
const LOOP_GATHER_DB: float = -16.0
const LOOP_CRAFT_DB: float = -10.5
const LOOP_COMBAT_DB: float = -9.5
## 前台节奏页：玩家正在看这些页面时，后台百艺循环拟音整体静默
const FOREGROUND_RHYTHM_PAGES: Array[String] = [
	"combat", "tower", "fishing_tea", "tribulation",
]
## 战斗节奏音页：离开秘境 / 镇魔塔后，普攻与引雷不再在后台作响
const COMBAT_SFX_PAGES: Array[String] = ["combat", "tower"]
var _last_loop_msec: int = -100000

## 真实百艺拟音：显式路径，保证导出 APK 后不依赖目录扫描
const SKILL_SFX: Dictionary = {
	"skill_herb": {
		"paths": [
			"res://assets/audio/sfx/sfx_herb.ogg",
			"res://assets/audio/sfx/sfx_herb_01.ogg",
		],
		"fallback": "gather_tick",
	},
	"skill_wood": {
		"paths": ["res://assets/audio/sfx/sfx_wood.ogg"],
		"fallback": "gather_tick",
	},
	"skill_mine": {
		"paths": ["res://assets/audio/sfx/sfx_mine.ogg"],
		"fallback": "gather_tick",
	},
	"skill_alchemy": {
		"paths": ["res://assets/audio/sfx/sfx_alchemy.ogg"],
		"fallback": "craft_success",
	},
	"skill_talisman": {
		"paths": ["res://assets/audio/sfx/sfx_talisman.ogg"],
		"fallback": "craft_success",
	},
	"skill_forge": {
		"paths": [
			"res://assets/audio/sfx/sfx_forge.ogg",
			"res://assets/audio/sfx/sfx_forge_01.ogg",
		],
		"fallback": "craft_success",
	},
	"thunder_hit": {
		"paths": ["res://assets/audio/sfx/sfx_thunder.ogg"],
		"fallback": "thunder_hit",
	},
	"combat_sword": {
		"paths": [
			"res://assets/audio/sfx/sfx_sword.ogg",
			"res://assets/audio/sfx/sfx_sword_01.ogg",
		],
		"fallback": "ui_tap",
	},
	"coin_chime": {
		"paths": ["res://assets/audio/sfx/sfx_coin.ogg"],
		"fallback": "coin_chime",
	},
	"breakthrough": {
		"paths": ["res://assets/audio/sfx/sfx_breakthrough.ogg"],
		"fallback": "breakthrough",
	},
	"skill_meditate": {
		"paths": ["res://assets/audio/sfx/sfx_meditate.ogg"],
		"fallback": "gather_tick",
	},
	"farm_action": {
		"paths": ["res://assets/audio/sfx/sfx_farm.ogg"],
		"fallback": "craft_success",
	},
	"item_use": {
		"paths": ["res://assets/audio/sfx/sfx_equip.ogg"],
		"fallback": "ui_tap",
	},
	"equip_puton": {
		"paths": ["res://assets/audio/sfx/sfx_puton.ogg"],
		"fallback": "ui_tap",
	},
	"ui_paper": {
		"paths": ["res://assets/audio/sfx/sfx_paper.ogg"],
		"fallback": "ui_paper",
	},
}

const SKILL_ID_TO_SFX: Dictionary = {
	"herbalism": "skill_herb",
	"woodcutting": "skill_wood",
	"mining": "skill_mine",
	"alchemy": "skill_alchemy",
	"talisman": "skill_talisman",
	"forging": "skill_forge",
	"cultivation": "skill_meditate",
}

## 五声音阶（宫商角徵羽）
const NOTE_C4: float = 261.63
const NOTE_G4: float = 392.00
const NOTE_C5: float = 523.25
const NOTE_D5: float = 587.33
const NOTE_E5: float = 659.25
const NOTE_G5: float = 783.99
const NOTE_A5: float = 880.00
const GATHER_NOTES: Array[float] = [NOTE_C5, NOTE_D5, NOTE_E5, NOTE_G5, NOTE_A5]

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _cursor: int = 0
var _last_played: Dictionary = {}
var _backgrounded: bool = false
var _rng := RandomNumberGenerator.new()

var _sfx_bus: int = -1
var _music_bus: int = -1
var _skill_streams: Dictionary = {}
var _skill_players: Dictionary = {}
var _last_skill_variant: Dictionary = {}
## 双 BGM 播放器（A/B 交替接管），每台各持一支独立淡变 Tween
var _bgm_players: Array[AudioStreamPlayer] = []
var _bgm_streams: Dictionary = {}
var _bgm_paths: Dictionary = {}
## 当前发声的播放器索引（-1 = 静默）与曲目键
var _bgm_active: int = -1
var _bgm_track: String = ""
var _bgm_rotate_accum: float = 0.0
var _bgm_context_accum: float = 0.0


func _ready() -> void:
	_rng.randomize()
	_ensure_audio_buses()
	_build_pool()
	_generate_streams()
	_load_skill_sfx()
	_load_bgm()
	EventBus.skill_level_up.connect(_on_skill_level_up)
	EventBus.mastery_level_up.connect(_on_mastery_level_up)
	EventBus.action_completed.connect(_on_action_completed)
	EventBus.action_started.connect(_on_action_started)
	EventBus.action_stopped.connect(_on_action_stopped)
	EventBus.combat_player_attack.connect(_on_combat_player_attack)
	EventBus.combat_thunder_talisman.connect(_on_combat_thunder_talisman)
	EventBus.tribulation_thunder.connect(_on_tribulation_thunder)
	EventBus.tribulation_finished.connect(_on_tribulation_finished)
	EventBus.farm_harvested.connect(_on_farm_harvested)
	EventBus.game_loaded.connect(_on_game_loaded)
	EventBus.combat_started.connect(_on_bgm_combat_started)
	EventBus.combat_stopped.connect(_on_bgm_combat_stopped)
	sync_bus_mute()


func _build_pool() -> void:
	for i in range(PLAYER_POOL):
		var player := AudioStreamPlayer.new()
		player.name = "SfxPlayer%d" % i
		player.bus = "SFX" if _sfx_bus >= 0 else "Master"
		add_child(player)
		_players.append(player)
	if _music_bus >= 0:
		for i in range(2):
			var bgm := AudioStreamPlayer.new()
			bgm.name = "BgmPlayerA" if i == 0 else "BgmPlayerB"
			bgm.bus = "Music"
			add_child(bgm)
			bgm.finished.connect(_on_bgm_player_finished.bind(i))
			_bgm_players.append(bgm)


func _ensure_audio_buses() -> void:
	_sfx_bus = _ensure_bus("SFX")
	_music_bus = _ensure_bus("Music")


## 真实百艺拟音：显式路径加载，缺少文件时保留空表以回退程序化音效
func _load_skill_sfx() -> void:
	for key in SKILL_SFX.keys():
		var definition: Dictionary = SKILL_SFX[key]
		var streams: Array[AudioStream] = []
		for path in definition.get("paths", []):
			var path_text := String(path)
			if not ResourceLoader.exists(path_text):
				continue
			var loaded := load(path_text)
			if loaded is AudioStreamOggVorbis:
				(loaded as AudioStreamOggVorbis).loop = false
			elif loaded is AudioStreamMP3:
				(loaded as AudioStreamMP3).loop = false
			elif loaded is AudioStreamWAV:
				(loaded as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_DISABLED
			if loaded is AudioStream:
				streams.append(loaded as AudioStream)
		if streams.is_empty():
			continue
		_skill_streams[key] = streams
		var player := AudioStreamPlayer.new()
		player.name = "SkillSfx_%s" % key
		player.bus = "SFX" if _sfx_bus >= 0 else "Master"
		add_child(player)
		_skill_players[key] = player


func _play_skill(key: String, volume_db: float = REAL_SFX_VOLUME_DB,
		cooldown_sec: float = REAL_SFX_COOLDOWN_SEC,
		pitch_min: float = 0.95, pitch_max: float = 1.05,
		important: bool = false) -> bool:
	var streams: Array = _skill_streams.get(key, [])
	if streams.is_empty():
		return false
	# 音频关闭时不播，但视为“真实音效已接管”，不触发程序化兜底
	if not is_enabled():
		return true
	var now := Time.get_ticks_msec()
	var lock_key := "real_%s" % key
	if now - int(_last_played.get(lock_key, -100000)) < int(cooldown_sec * 1000.0):
		return true
	_last_played[lock_key] = now
	var index := _rng.randi_range(0, streams.size() - 1)
	if streams.size() > 1:
		var last_index := int(_last_skill_variant.get(key, -1))
		if index == last_index:
			index = (index + 1) % streams.size()
	_last_skill_variant[key] = index
	var player: AudioStreamPlayer = _skill_players.get(key, null)
	if player == null:
		return false
	# 每个技能仅一个播放器：长音效未播完时直接顶替，避免挂机叠音
	if player.playing:
		player.stop()
	_ensure_voice_room(player)
	player.stream = streams[index]
	player.pitch_scale = _rng.randf_range(pitch_min, pitch_max)
	_start_player_fade(player, volume_db + linear_to_db(get_volume()),
		REAL_SFX_FADE_IN_SEC, 18.0, important)
	return true


func _play_skill_with_fallback(key: String, volume_db: float = REAL_SFX_VOLUME_DB,
		cooldown_sec: float = REAL_SFX_COOLDOWN_SEC, important: bool = false) -> void:
	if _play_skill(key, volume_db, cooldown_sec, 0.95, 1.05, important):
		return
	var definition: Dictionary = SKILL_SFX.get(key, {})
	_play_procedural_fallback(String(definition.get("fallback", "gather_tick")))


## 程序化兜底：调用方（循环拟音闸门 / 主动交互）已完成节流，此处只发声不再二次闸门
func _play_procedural_fallback(key: String) -> void:
	match key:
		"craft_success":
			_play_craft_raw()
		"coin_chime":
			_play("coin_chime", -7.0, "coin_chime", 0.07, true)
		"thunder_hit":
			_play("thunder_hit", -3.0, "thunder_hit", 0.10, true)
		"breakthrough":
			_play("breakthrough", -4.0, "breakthrough", 0.40, true)
		"ui_paper":
			_play("ui_paper", -13.0, "ui_paper", 0.08)
		"gather_tick":
			_play_gather_tick_raw()
		_:
			play_tap()


func _ensure_bus(bus_name: String) -> int:
	var index := AudioServer.get_bus_index(bus_name)
	if index >= 0:
		return index
	AudioServer.add_bus()
	index = AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, "Master")
	return index


## 加载日常 / 战斗两首 BGM；缺一首时自动降级为单曲循环，两首都缺则静默不用 BGM
func _load_bgm() -> void:
	_bgm_streams.clear()
	_bgm_paths.clear()
	for track in [BGM_TRACK_CALM, BGM_TRACK_BATTLE]:
		var track_key := String(track)
		var path := _find_bgm_path(track_key)
		if path == "":
			continue
		var loaded := _load_bgm_stream(path)
		if loaded == null:
			continue
		_apply_bgm_loop(loaded, true)
		_bgm_streams[track_key] = loaded
		_bgm_paths[track_key] = path
	# 缺曲属可预期情况（如战斗曲尚未随包），只用调试级日志，不报错
	if _bgm_streams.size() < 2:
		print_verbose("[PathOfJade] BGM 可用曲目 %d 首，按单曲循环运行" % _bgm_streams.size())
	if _bgm_players.size() < 2:
		print_verbose("[PathOfJade] 未创建双 BGM 播放器，BGM 播放停用")


## 按候选路径查找曲目；全部不存在时递归 res:// 兜底扫描同名文件
func _find_bgm_path(track: String) -> String:
	var candidates: Array = BGM_TRACK_PATHS.get(track, [])
	for candidate in candidates:
		var path := String(candidate)
		if ResourceLoader.exists(path) or FileAccess.file_exists(path):
			return path
	var file_name := "bgm_battle.ogg" if track == BGM_TRACK_BATTLE else "bgm.ogg"
	return _find_bgm_in_dir("res://", file_name)


## 优先走导入资源（导出 APK 可用）；编辑器内新加入、尚未生成 .import 时
## 回退直接解析磁盘 OGG，保证当场可听且零报错
func _load_bgm_stream(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		var loaded := load(path)
		if loaded is AudioStream:
			return loaded as AudioStream
	if not FileAccess.file_exists(path):
		return null
	if path.to_lower().ends_with(".ogg"):
		var ogg := AudioStreamOggVorbis.load_from_file(path)
		if ogg != null:
			return ogg
	return null


func _apply_bgm_loop(stream: AudioStream, looped: bool) -> void:
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = looped
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = looped
	elif stream is AudioStreamWAV:
		if looped:
			(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
		else:
			(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_DISABLED


func _find_bgm_in_dir(path: String, file_name: String) -> String:
	var dir := DirAccess.open(path)
	if dir == null:
		return ""
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if dir.current_is_dir():
			if not entry.begins_with(".") and entry != ".godot":
				var nested := _find_bgm_in_dir(path.path_join(entry), file_name)
				if nested != "":
					dir.list_dir_end()
					return nested
		elif entry.to_lower() == file_name:
			dir.list_dir_end()
			return path.path_join(entry)
		entry = dir.get_next()
	dir.list_dir_end()
	return ""


# ---------------------------------------------------------------- BGM 控制

func get_bgm_volume() -> float:
	return clampf(float(GameState.flags.get("bgm_volume", 0.10)), 0.0, 1.0)


func is_bgm_enabled() -> bool:
	return GameState.is_flag("bgm_enabled", true) and get_bgm_volume() > 0.001


## 0 随境而变（默认）/ 1 轮流雅奏；旧档缺字段按 0 处理
func get_bgm_mode() -> int:
	return clampi(int(GameState.flags.get("bgm_mode", BGM_MODE_AMBIENT)),
		BGM_MODE_AMBIENT, BGM_MODE_ROTATE)


## 是否处于秘境历练 / 镇魔塔战斗；天劫不计入，仍保持日常曲
func is_battle_scene() -> bool:
	if CombatEngine == null:
		return false
	return CombatEngine.active


func _track_target_db(track: String) -> float:
	var offset := BATTLE_BGM_DB_OFFSET if track == BGM_TRACK_BATTLE else 0.0
	return BGM_BASE_DB + linear_to_db(maxf(0.001, get_bgm_volume())) + offset


## 外部统一入口：音乐开关、模式切换、音量变化、读档后调用
func apply_bgm_state() -> void:
	_apply_bgm_state()


func _apply_bgm_state() -> void:
	if _bgm_streams.is_empty() or _bgm_players.is_empty():
		return
	if not is_bgm_enabled():
		fade_out_bgm()
		return
	_crossfade_to(_desired_track())


## 随境而变：战斗曲 / 日常曲；轮流雅奏：维持当前曲目，由曲尾轮转接管
func _desired_track() -> String:
	if get_bgm_mode() == BGM_MODE_ROTATE:
		if _bgm_track != "" and _bgm_active >= 0 and _bgm_players[_bgm_active].playing:
			return _bgm_track
		return _next_rotate_track("")
	return BGM_TRACK_BATTLE if is_battle_scene() else BGM_TRACK_CALM


## 轮转下一首；单曲兜底时永远返回唯一可用曲目
func _next_rotate_track(current: String) -> String:
	var has_calm := _bgm_streams.has(BGM_TRACK_CALM)
	var has_battle := _bgm_streams.has(BGM_TRACK_BATTLE)
	if not has_calm and not has_battle:
		return ""
	if not has_battle:
		return BGM_TRACK_CALM
	if not has_calm:
		return BGM_TRACK_BATTLE
	if current == "":
		return BGM_TRACK_CALM
	return BGM_TRACK_BATTLE if current == BGM_TRACK_CALM else BGM_TRACK_CALM


## 请求曲目 → 实际可用曲目：缺战斗曲用日常曲顶上，反之亦然
func _resolve_bgm_track(track: String) -> String:
	if _bgm_streams.has(track):
		return track
	if _bgm_streams.has(BGM_TRACK_CALM):
		return BGM_TRACK_CALM
	if _bgm_streams.has(BGM_TRACK_BATTLE):
		return BGM_TRACK_BATTLE
	return ""


## 核心：两台播放器交替接管，1.2s 交叉淡入淡出（新曲 -30dB 起，旧曲 -30dB 收）
func _crossfade_to(track: String, force_restart: bool = false) -> void:
	var resolved := _resolve_bgm_track(track)
	if resolved == "" or _bgm_players.size() < 2:
		return
	if _bgm_active >= 0 and not force_restart and resolved == _bgm_track and _bgm_players[_bgm_active].playing:
		_sync_bgm_volume()
		return
	var incoming_index := 0 if _bgm_active != 0 else 1
	var incoming := _bgm_players[incoming_index]

	_kill_bgm_player_tween(incoming)
	incoming.stream = _bgm_streams[resolved]
	incoming.set_meta("bgm_track", resolved)
	incoming.volume_db = BGM_CROSSFADE_FLOOR_DB
	incoming.play()
	var fade_in := incoming.create_tween()
	fade_in.tween_property(incoming, "volume_db", _track_target_db(resolved),
		BGM_CROSSFADE_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	incoming.set_meta("bgm_fade_tween", fade_in)

	# 其余仍在发声的播放器（旧曲 / 残留曲）统一淡出到 -30dB 后停止
	for index in range(_bgm_players.size()):
		if index == incoming_index:
			continue
		var fading := _bgm_players[index]
		if not fading.playing:
			continue
		_kill_bgm_player_tween(fading)
		var fade_out := fading.create_tween()
		fade_out.tween_property(fading, "volume_db", BGM_CROSSFADE_FLOOR_DB,
			BGM_CROSSFADE_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		fade_out.tween_callback(_stop_bgm_player_if_idle.bind(fading))
		fading.set_meta("bgm_fade_tween", fade_out)

	_bgm_active = incoming_index
	_bgm_track = resolved


## 淡出两台播放器（关闭音乐 / 音量为 0）
func fade_out_bgm() -> void:
	for index in range(_bgm_players.size()):
		var player := _bgm_players[index]
		if not player.playing:
			continue
		_kill_bgm_player_tween(player)
		var tween := player.create_tween()
		tween.tween_property(player, "volume_db", BGM_CROSSFADE_FLOOR_DB,
			BGM_FADE_OUT_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tween.tween_callback(_stop_bgm_player_if_idle.bind(player))
		player.set_meta("bgm_fade_tween", tween)
	_bgm_active = -1
	_bgm_track = ""


## 兼容旧入口：确保按当前模式起播（首帧 -30dB 起，1.2s 渐入）
func fade_in_bgm() -> void:
	_apply_bgm_state()


## 音量滑杆拖动：只同步当前曲目，正在淡出的旧曲继续走完自己的淡出
func set_bgm_volume(_value: float) -> void:
	if not GameState.is_flag("bgm_enabled", true):
		return
	_sync_bgm_volume()


func _sync_bgm_volume() -> void:
	if _bgm_active < 0 or _bgm_active >= _bgm_players.size() or _bgm_track == "":
		return
	var player := _bgm_players[_bgm_active]
	if not player.playing:
		return
	_kill_bgm_player_tween(player)
	player.volume_db = _track_target_db(_bgm_track)


func _kill_bgm_player_tween(player: AudioStreamPlayer) -> void:
	if not player.has_meta("bgm_fade_tween"):
		return
	var existing: Variant = player.get_meta("bgm_fade_tween")
	if existing is Tween and (existing as Tween).is_valid():
		(existing as Tween).kill()


func _kill_all_bgm_tweens() -> void:
	for player in _bgm_players:
		_kill_bgm_player_tween(player)


## 淡出结束后收尾：仅当该播放器已不是主唱时才停止，避免误杀刚接管的曲目
func _stop_bgm_player_if_idle(player: AudioStreamPlayer) -> void:
	if player == null or not is_instance_valid(player) or not player.playing:
		return
	if _bgm_players.find(player) != _bgm_active:
		player.stop()


## 每帧极轻量：轮流雅奏做曲尾轮转，随境而变做低频状态校准（无重建、无分配风暴）
func _process(delta: float) -> void:
	if _bgm_streams.size() < 2 or _bgm_players.size() < 2 or not is_bgm_enabled():
		return
	if get_bgm_mode() == BGM_MODE_ROTATE:
		_bgm_rotate_accum += delta
		if _bgm_rotate_accum < BGM_ROTATE_POLL_SEC:
			return
		_bgm_rotate_accum = 0.0
		_tick_bgm_rotation()
		return
	_bgm_context_accum += delta
	if _bgm_context_accum < BGM_CONTEXT_POLL_SEC:
		return
	_bgm_context_accum = 0.0
	var target := BGM_TRACK_BATTLE if is_battle_scene() else BGM_TRACK_CALM
	if _bgm_active >= 0 and target == _bgm_track and _bgm_players[_bgm_active].playing:
		return
	_crossfade_to(target)


## 轮流雅奏：在曲尾 1.2s 内交叉淡入下一首，听感上两曲首尾相衔不断流
func _tick_bgm_rotation() -> void:
	if get_bgm_mode() != BGM_MODE_ROTATE:
		return
	if _bgm_active < 0 or _bgm_active >= _bgm_players.size():
		_crossfade_to(_next_rotate_track(""))
		return
	var player := _bgm_players[_bgm_active]
	if not player.playing or player.stream == null:
		# 播放器被系统音频中断等异常：按当前编排自愈起播，不静默卡死
		_crossfade_to(_desired_track())
		return
	var length := player.stream.get_length()
	if length <= BGM_CROSSFADE_SEC + 0.5:
		return
	if player.get_playback_position() >= length - BGM_CROSSFADE_SEC:
		_crossfade_to(_next_rotate_track(_bgm_track))


## loop 关闭时的兜底（正常曲目均开启 loop，此路径仅防御异常素材）
func _on_bgm_player_finished(index: int) -> void:
	if index != _bgm_active or not is_bgm_enabled():
		return
	if get_bgm_mode() == BGM_MODE_ROTATE:
		_crossfade_to(_next_rotate_track(_bgm_track))
	else:
		_crossfade_to(_bgm_track, true)


func _on_bgm_combat_started(_enemy_id: String) -> void:
	if get_bgm_mode() != BGM_MODE_AMBIENT or not is_bgm_enabled():
		return
	# 延迟到本帧末统一取引擎真实状态：镇魔塔会先 stop_combat 再 start，
	# 同步切曲会造成「日常曲刚起就逆转」的来回交叉
	_apply_bgm_state.call_deferred()


func _on_bgm_combat_stopped(_reason: String) -> void:
	if get_bgm_mode() != BGM_MODE_AMBIENT or not is_bgm_enabled():
		return
	_apply_bgm_state.call_deferred()


func _on_game_loaded() -> void:
	sync_bus_mute()
	_apply_bgm_state()


# ---------------------------------------------------------------- 对外播放接口

## 启动过渡层调用：确保真实 SFX 与 BGM 在进入主界面前完成缓存
func prewarm() -> void:
	if _skill_streams.is_empty():
		_load_skill_sfx()
	if _bgm_streams.is_empty():
		_load_bgm()

func play_click() -> void:
	play_tap()


func play_tap() -> void:
	_play("ui_tap", -5.0, "ui_tap", 0.08)


func play_paper() -> void:
	_play_skill_with_fallback("ui_paper", -6.0, 0.08)


func play_gather_tick() -> void:
	if _loop_gate():
		_play_gather_tick_raw()


## 采集轻拨（不含全局闸门）：循环拟音调用方已统一过闸，避免二次拦截
func _play_gather_tick_raw() -> void:
	var index := _rng.randi_range(0, GATHER_NOTES.size() - 1)
	_play("gather_tick_%d" % index, LOOP_GATHER_DB, "gather_tick", LOOP_SFX_COOLDOWN_SEC)


## 灵潭收竿：与百艺循环拟音共用同一闸门，垂钓页优先但依旧不叠音
func play_fishing_catch() -> void:
	if _loop_gate():
		_play_gather_tick_raw()


func play_coin() -> void:
	_play_skill_with_fallback("coin_chime", -1.5, 0.08, true)


func play_craft() -> void:
	if _loop_gate():
		_play_craft_raw()


func _play_craft_raw() -> void:
	_play("craft_success", LOOP_CRAFT_DB, "craft_success", LOOP_SFX_COOLDOWN_SEC)


func play_level_up() -> void:
	# 技能升级复用突破钟声，但压低音量并略升音高，与大境界突破区分
	if not _play_skill("breakthrough", -6.0, 0.12, 1.0, 1.06, true):
		_play("level_up", -6.0, "level_up", 0.10, true)


func play_breakthrough() -> void:
	_play_skill_with_fallback("breakthrough", -1.5, 0.40, true)


func play_thunder() -> void:
	_play_skill_with_fallback("thunder_hit", -2.0, 0.10, true)


func play_combat_sword() -> void:
	if not _loop_gate():
		return
	_play_skill_with_fallback("combat_sword", LOOP_COMBAT_DB, LOOP_SFX_COOLDOWN_SEC)


func play_meditate() -> void:
	_play_skill_with_fallback("skill_meditate", -9.5, LOOP_SFX_COOLDOWN_SEC)


func play_farm_action() -> void:
	_play_skill_with_fallback("farm_action", -5.0, 0.08)


func play_equip_use() -> void:
	_play_skill_with_fallback("item_use", -4.0, 0.08)


## 法宝穿戴 / 卸下：与吞服丹药区分
func play_equip_puton() -> void:
	_play_skill_with_fallback("equip_puton", -4.0, 0.08)


func play_error() -> void:
	_play("error_soft", -14.0, "error_soft", 0.12)


## 兼容旧动作完成调用
func play_action_complete() -> void:
	play_gather_tick()


func is_enabled() -> bool:
	return GameState.is_flag("audio", true) and get_volume() > 0.001 \
		and not AudioServer.is_bus_mute(0) \
		and (_sfx_bus < 0 or not AudioServer.is_bus_mute(_sfx_bus))


func get_volume() -> float:
	return clampf(float(GameState.flags.get("audio_volume", 0.25)), 0.0, 1.0)


## 音效 / 音乐 / 后台静音分别落到独立总线，互不串扰
func sync_bus_mute() -> void:
	if AudioServer.get_bus_count() <= 0:
		return
	AudioServer.set_bus_mute(0, _backgrounded and GameState.is_flag("background_mute", true))
	if _sfx_bus >= 0:
		AudioServer.set_bus_mute(_sfx_bus, not GameState.is_flag("audio", true))


# ---------------------------------------------------------------- 震动反馈（四档强度）

## 0 关闭 / 1 轻柔 / 2 适中（默认）/ 3 强劲
const VIBRATION_LEVEL_DEFAULT: int = 2
const VIBRATION_LEVELS: Dictionary = {
	0: {"amp": 0.0, "light": 0, "medium": 0, "heavy": 0},
	1: {"amp": 0.45, "light": 22, "medium": 32, "heavy": 45},
	2: {"amp": 0.75, "light": 32, "medium": 48, "heavy": 65},
	3: {"amp": 1.00, "light": 42, "medium": 60, "heavy": 85},
}
const VIBRATION_COOLDOWN_MS: int = 120
const VIBRATE_PRIORITY_LIGHT: int = 1
const VIBRATE_PRIORITY_MEDIUM: int = 2
const VIBRATE_PRIORITY_HEAVY: int = 3

var _last_vibrate_msec: int = -100000
var _last_vibrate_priority: int = 0


func get_vibration_level() -> int:
	return clampi(int(GameState.flags.get("vibration_level", VIBRATION_LEVEL_DEFAULT)), 0, 3)


func play_vibrate_light() -> bool:
	return _vibrate(VIBRATE_PRIORITY_LIGHT, "light")


func play_vibrate_medium() -> bool:
	return _vibrate(VIBRATE_PRIORITY_MEDIUM, "medium")


func play_vibrate_heavy() -> bool:
	return _vibrate(VIBRATE_PRIORITY_HEAVY, "heavy")


## 大境界渡劫成功：中震 → 0.11s → 重震（异步不阻塞主线程）
func play_vibrate_breakthrough() -> void:
	if get_vibration_level() <= 0:
		return
	play_vibrate_medium()
	if not is_inside_tree():
		return
	await get_tree().create_timer(0.11).timeout
	if not is_inside_tree():
		return
	play_vibrate_heavy()


## 120ms 冷却 + 优先级锁：窗口内只放行更高优先级，避免多事件叠加震糊
func _vibrate(priority: int, tier: String) -> bool:
	var level := get_vibration_level()
	if level <= 0 or not _vibration_available():
		return false
	var data: Dictionary = VIBRATION_LEVELS[level]
	var duration := int(data.get(tier, 0))
	if duration <= 0:
		return false
	var now := Time.get_ticks_msec()
	if now - _last_vibrate_msec < VIBRATION_COOLDOWN_MS and priority <= _last_vibrate_priority:
		return false
	_last_vibrate_msec = now
	_last_vibrate_priority = priority
	Input.vibrate_handheld(duration, clampf(float(data.get("amp", 0.0)), 0.0, 1.0))
	return true


## 仅安卓/iOS 且前台激活时震动：后台挂起、最小化一律静默
func _vibration_available() -> bool:
	if not OS.has_feature("mobile"):
		return false
	if DisplayServer.get_name() == "headless":
		return false
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_MINIMIZED:
		return false
	return DisplayServer.window_is_focused()


## 当前正在发声的短音效声部数（程序化轮询池 + 各技能真实拟音单播放器）
func _active_voice_count(exclude: AudioStreamPlayer = null) -> int:
	var count := 0
	for player in _players:
		if player != exclude and player.playing:
			count += 1
	for key in _skill_players.keys():
		var player: AudioStreamPlayer = _skill_players[key]
		if player != exclude and player.playing:
			count += 1
	return count


## 并发上限：声部已满时优先停最早的低优先级循环音；
## 突破 / 稀有掉落 / 渡劫等重要音标记了 voice_important，最后才被淘汰。
func _ensure_voice_room(exclude: AudioStreamPlayer) -> void:
	var guard := 0
	while guard < 8 and _active_voice_count(exclude) >= MAX_SFX_VOICES:
		guard += 1
		var victim := _oldest_voice(exclude, false)
		if victim == null:
			victim = _oldest_voice(exclude, true)
		if victim == null:
			return
		victim.stop()


func _oldest_voice(exclude: AudioStreamPlayer, include_important: bool) -> AudioStreamPlayer:
	var oldest: AudioStreamPlayer = null
	var oldest_ms := 9223372036854775807
	for player in _players:
		if player == exclude or not player.playing:
			continue
		if not include_important and bool(player.get_meta("voice_important", false)):
			continue
		var started := int(player.get_meta("voice_start_msec", 0))
		if started < oldest_ms:
			oldest_ms = started
			oldest = player
	for key in _skill_players.keys():
		var player: AudioStreamPlayer = _skill_players[key]
		if player == exclude or not player.playing:
			continue
		if not include_important and bool(player.get_meta("voice_important", false)):
			continue
		var started := int(player.get_meta("voice_start_msec", 0))
		if started < oldest_ms:
			oldest_ms = started
			oldest = player
	return oldest


## 循环拟音全局闸门：0.18s 内最多放行一条，多槽同帧完成只响一次
func _loop_gate() -> bool:
	var now := Time.get_ticks_msec()
	if now - _last_loop_msec < LOOP_SFX_MIN_GAP_MS:
		return false
	_last_loop_msec = now
	return true


## 循环拟音发声权限：
##   秘境 / 镇魔塔 / 灵潭垂钓 / 渡劫页 → 只保留本页节奏音，百艺整体静默
##   其余页面：主修（槽 0）恒可发声；分神 / 化身仅当正在浏览对应百艺页
func _routine_sfx_allowed(slot: int, action: ActionData) -> bool:
	var page := EventBus.current_page
	if FOREGROUND_RHYTHM_PAGES.has(page):
		return false
	if slot <= 0:
		return true
	return action != null and page == action.skill_id


func _play(key: String, volume_db: float, cooldown_key: String = "",
		cooldown_sec: float = 0.08, important: bool = false) -> void:
	if not is_enabled():
		return
	var now := Time.get_ticks_msec()
	var lock_key := cooldown_key if cooldown_key != "" else key
	if now - int(_last_played.get(lock_key, -100000)) < int(cooldown_sec * 1000.0):
		return
	_last_played[lock_key] = now
	var stream: AudioStream = _streams.get(key, null)
	if stream == null or _players.is_empty():
		return
	var player := _players[_cursor]
	_cursor = (_cursor + 1) % _players.size()
	_ensure_voice_room(player)
	player.stream = stream
	player.pitch_scale = _rng.randf_range(0.95, 1.05)
	_start_player_fade(player, volume_db + linear_to_db(get_volume()),
		SFX_FADE_IN_SEC, 10.0, important)


func _start_player_fade(player: AudioStreamPlayer, target_db: float,
		fade_in: float, fade_depth: float, important: bool = false) -> void:
	_kill_player_tween(player)
	player.set_meta("voice_start_msec", Time.get_ticks_msec())
	player.set_meta("voice_important", important)
	player.volume_db = maxf(-60.0, target_db - fade_depth)
	player.play()
	var tween := player.create_tween()
	tween.tween_property(player, "volume_db", target_db, fade_in) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	player.set_meta("sfx_fade_tween", tween)


func _fade_out_and_stop(player: AudioStreamPlayer) -> void:
	if player == null or not player.playing:
		return
	_kill_player_tween(player)
	var tween := player.create_tween()
	tween.tween_property(player, "volume_db", -50.0, SFX_FADE_OUT_SEC) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		if player.playing:
			player.stop()
	)
	player.set_meta("sfx_fade_tween", tween)


func _kill_player_tween(player: AudioStreamPlayer) -> void:
	if not player.has_meta("sfx_fade_tween"):
		return
	var existing: Variant = player.get_meta("sfx_fade_tween")
	if existing is Tween and (existing as Tween).is_valid():
		(existing as Tween).kill()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			_backgrounded = true
			sync_bus_mute()
		NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_APPLICATION_RESUMED:
			_backgrounded = false
			sync_bus_mute()


func _exit_tree() -> void:
	_kill_all_bgm_tweens()
	for bgm in _bgm_players:
		bgm.stop()
		bgm.stream = null
	for player in _players:
		player.stop()
		player.stream = null
	for player in _skill_players.values():
		var skill_player: AudioStreamPlayer = player
		skill_player.stop()
		skill_player.stream = null
	_skill_streams.clear()
	_skill_players.clear()
	_bgm_streams.clear()
	_bgm_paths.clear()
	_streams.clear()


# ---------------------------------------------------------------- 信号联动

func _on_skill_level_up(_skill_id: String, _level: int) -> void:
	play_level_up()


func _on_mastery_level_up(_action_id: String, _level: int) -> void:
	play_level_up()


func _on_action_completed(slot: int, action_id: String, _gained: Dictionary) -> void:
	var action := DataRegistry.get_action(action_id)
	# 分神 / 化身后台结算默认静默；节奏页（秘境 / 镇魔塔 / 垂钓 / 渡劫）百艺整体静默
	if action != null and not _routine_sfx_allowed(slot, action):
		return
	# 全局 0.18s 闸门：多槽同帧完成只响一次
	if not _loop_gate():
		return
	if action == null:
		_play_gather_tick_raw()
		return
	var real_key := String(SKILL_ID_TO_SFX.get(action.skill_id, ""))
	if real_key != "":
		if real_key == "skill_meditate":
			_play_skill_with_fallback(real_key, LOOP_SFX_VOLUME_DB - 1.0,
				LOOP_SFX_COOLDOWN_SEC)
		else:
			_play_skill_with_fallback(real_key, LOOP_SFX_VOLUME_DB,
				LOOP_SFX_COOLDOWN_SEC)
		return
	# 其他动作保持程序化古风音效
	_play_gather_tick_raw()


## 点击开始运转时立即给一次轻反馈，不必等完整动作周期
func _on_action_started(slot: int, action_id: String) -> void:
	var action := DataRegistry.get_action(action_id)
	if action == null:
		return
	if not _routine_sfx_allowed(slot, action):
		return
	if not _loop_gate():
		return
	var real_key := String(SKILL_ID_TO_SFX.get(action.skill_id, ""))
	if real_key == "":
		return
	_play_skill_with_fallback(real_key, LOOP_SFX_VOLUME_DB - 0.5, LOOP_SFX_COOLDOWN_SEC)


## 停止运转时立刻收掉该技能的真实拟音，避免长音效继续拖尾
func _on_action_stopped(_slot: int, action_id: String) -> void:
	var action := DataRegistry.get_action(action_id)
	if action == null:
		return
	var real_key := String(SKILL_ID_TO_SFX.get(action.skill_id, ""))
	if real_key == "":
		return
	# 同技能仍有另一条线在运转时，不打断它
	for i in range(GameState.SLOT_COUNT):
		var other_id := GameState.get_active_action(i)
		if other_id == "":
			continue
		var other_action := DataRegistry.get_action(other_id)
		if other_action != null and other_action.skill_id == action.skill_id:
			return
	var player: AudioStreamPlayer = _skill_players.get(real_key, null)
	if player != null and player.playing:
		_fade_out_and_stop(player)


func _on_tribulation_thunder(_index: int, _damage: int, _warded: bool,
		_hp: int, _max_hp: int) -> void:
	play_thunder()


func _on_combat_player_attack(_damage: int, _crit: bool) -> void:
	# 离开秘境 / 镇魔塔页面后，战斗可在后台继续，但普攻声不再抢音轨
	if not COMBAT_SFX_PAGES.has(EventBus.current_page):
		return
	play_combat_sword()


func _on_combat_thunder_talisman(_damage: int) -> void:
	if not COMBAT_SFX_PAGES.has(EventBus.current_page):
		return
	play_thunder()


func _on_tribulation_finished(success: bool, _message: String) -> void:
	if success:
		play_breakthrough()


func _on_farm_harvested(_items: Dictionary) -> void:
	play_farm_action()


# ---------------------------------------------------------------- 波形合成

func _generate_streams() -> void:
	if not _streams.is_empty():
		return
	_streams["ui_tap"] = _make_tap()
	_streams["ui_paper"] = _make_paper()
	for i in range(GATHER_NOTES.size()):
		_streams["gather_tick_%d" % i] = _make_gather(GATHER_NOTES[i])
	_streams["coin_chime"] = _make_coin()
	_streams["craft_success"] = _make_craft()
	_streams["level_up"] = _make_level_up()
	_streams["breakthrough"] = _make_breakthrough()
	_streams["thunder_hit"] = _make_thunder()
	_streams["error_soft"] = _make_error()


func _build_stream(samples: PackedFloat32Array, gain: float = 1.0) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	var fade_count := maxi(1, int(SAMPLE_RATE * 0.004))
	for i in range(samples.size()):
		var fade := 1.0
		if i < fade_count:
			fade = float(i) / float(fade_count)
		elif i > samples.size() - fade_count:
			fade = float(samples.size() - i) / float(fade_count)
		var value := clampf(samples[i] * gain * fade, -1.0, 1.0)
		bytes.encode_s16(i * 2, int(roundf(value * 32767.0)))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = bytes
	return stream


## 35ms 玉石/木鱼轻点
func _make_tap() -> AudioStreamWAV:
	var count := int(SAMPLE_RATE * 0.035)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t := float(i) / float(SAMPLE_RATE)
		var env := exp(-t * 105.0) * (1.0 - exp(-t * 3200.0))
		var wood := sin(TAU * 176.0 * t) * 0.58 + sin(TAU * 296.0 * t) * 0.24 \
			+ sin(TAU * 512.0 * t) * 0.08
		var noise := (_rng.randf() * 2.0 - 1.0) * exp(-t * 420.0) * 0.15
		samples[i] = (wood + noise) * env
	return _build_stream(samples, 0.62)


## 50ms 宣纸轻翻：柔和带通噪声
func _make_paper() -> AudioStreamWAV:
	var count := int(SAMPLE_RATE * 0.05)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var lowpass := 0.0
	for i in range(count):
		var t := float(i) / float(SAMPLE_RATE)
		var noise := _rng.randf() * 2.0 - 1.0
		lowpass = lerpf(lowpass, noise, 0.16)
		var band := noise - lowpass
		var env := exp(-t * 42.0) * (1.0 - exp(-t * 2600.0))
		samples[i] = (lowpass * 0.75 + band * 0.28) * env
	return _build_stream(samples, 0.58)


## 105ms 古筝泛音拨弦
func _make_gather(freq: float) -> AudioStreamWAV:
	var count := int(SAMPLE_RATE * 0.105)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t := float(i) / float(SAMPLE_RATE)
		var env := exp(-t * 24.0) * (1.0 - exp(-t * 2400.0))
		var tone := sin(TAU * freq * t) * 0.55 \
			+ sin(TAU * freq * 2.0 * t) * 0.20 \
			+ sin(TAU * freq * 3.0 * t) * 0.07
		samples[i] = tone * env
	return _build_stream(samples, 0.5)


## 280ms 双谐波玉磬
func _make_coin() -> AudioStreamWAV:
	var count := int(SAMPLE_RATE * 0.28)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t := float(i) / float(SAMPLE_RATE)
		var env := exp(-t * 9.0)
		var tone := sin(TAU * 1046.5 * t) * 0.42 \
			+ sin(TAU * 1568.0 * t) * 0.30 \
			+ sin(TAU * 2093.0 * t) * 0.10
		samples[i] = tone * env
	return _build_stream(samples, 0.55)


## 430ms G4 → C5 温暖双音
func _make_craft() -> AudioStreamWAV:
	var count := int(SAMPLE_RATE * 0.43)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var notes: Array[float] = [NOTE_G4, NOTE_C5]
	for i in range(count):
		var t := float(i) / float(SAMPLE_RATE)
		var value := 0.0
		for k in range(notes.size()):
			var start := 0.11 * float(k)
			if t < start:
				continue
			var local := t - start
			var env := exp(-local * 9.5) * (1.0 - exp(-local * 1800.0))
			value += sin(TAU * notes[k] * local) * 0.48 * env
			value += sin(TAU * notes[k] * 2.0 * local) * 0.12 * env
		samples[i] = value
	return _build_stream(samples, 0.62)


## 540ms C5 → E5 → G5 三音琶音
func _make_level_up() -> AudioStreamWAV:
	var count := int(SAMPLE_RATE * 0.54)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var notes: Array[float] = [NOTE_C5, NOTE_E5, NOTE_G5]
	for i in range(count):
		var t := float(i) / float(SAMPLE_RATE)
		var value := 0.0
		for k in range(notes.size()):
			var start := 0.09 * float(k)
			if t < start:
				continue
			var local := t - start
			var env := exp(-local * 7.8) * (1.0 - exp(-local * 2200.0))
			value += sin(TAU * notes[k] * local) * 0.42 * env
			value += sin(TAU * notes[k] * 2.0 * local) * 0.12 * env
		samples[i] = value
	return _build_stream(samples, 0.58)


## 1.1s C4 → G4 → C5 → E5 编钟回响
func _make_breakthrough() -> AudioStreamWAV:
	var count := int(SAMPLE_RATE * 1.1)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var notes: Array[float] = [NOTE_C4, NOTE_G4, NOTE_C5, NOTE_E5]
	for i in range(count):
		var t := float(i) / float(SAMPLE_RATE)
		var value := 0.0
		for k in range(notes.size()):
			var start := 0.16 * float(k)
			if t < start:
				continue
			var local := t - start
			var env := exp(-local * 3.6) * (1.0 - exp(-local * 1800.0))
			value += sin(TAU * notes[k] * local) * 0.34 * env
			value += sin(TAU * notes[k] * 2.0 * local) * 0.10 * env
			value += sin(TAU * notes[k] * 3.0 * local) * 0.04 * env
		samples[i] = value
	return _build_stream(samples, 0.55)


## 500ms 低频滚雷 + 短促滤波噪点
func _make_thunder() -> AudioStreamWAV:
	var count := int(SAMPLE_RATE * 0.5)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var lowpass := 0.0
	for i in range(count):
		var t := float(i) / float(SAMPLE_RATE)
		var noise := _rng.randf() * 2.0 - 1.0
		lowpass = lerpf(lowpass, noise, 0.055)
		var rumble := sin(TAU * 45.0 * t) * 0.55 + sin(TAU * 72.0 * t) * 0.28
		var crack := 0.0
		if t < 0.045:
			crack = noise * 0.45 * exp(-t * 85.0)
		var env := exp(-t * 4.8)
		samples[i] = (lowpass * 0.9 + rumble + crack) * env
	return _build_stream(samples, 0.72)


## 140ms 闷木钝响（失败/原料不足）
func _make_error() -> AudioStreamWAV:
	var count := int(SAMPLE_RATE * 0.14)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t := float(i) / float(SAMPLE_RATE)
		var env := exp(-t * 21.0)
		var wood := sin(TAU * 148.0 * t) * 0.55 + sin(TAU * 92.0 * t) * 0.28
		var noise := (_rng.randf() * 2.0 - 1.0) * 0.06 * exp(-t * 60.0)
		samples[i] = (wood + noise) * env
	return _build_stream(samples, 0.5)
