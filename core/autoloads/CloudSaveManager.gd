extends Node
## 玉简云篆：仙籍登录态、本地凭证、云存档上传/取回、自动同步与冲突仲裁。
##
## 约定：
## - HTTP 超时统一 5.0s（健康探针 2.5s）；字段与 server/save.go 完全一致；
## - is_offline_mode = true 或未持 token 时，所有云端检查/上传静默跳过；
## - _is_syncing 防并发；_conflict_paused 在玩家抉择前暂停后台自动上传；
## - 本地凭证 user://cloud_auth.json 保存 device_id / token / uid / username /
##   is_guest / local_save_rev / last_sync_at，不写进 save_data.json。

const SERVER_BASE_URL: String = "https://allplayer.cn:28474"
const AUTH_PATH: String = "user://cloud_auth.json"
const PATCH_STATE_PATH: String = "user://patch_state.json"
const HTTP_TIMEOUT: float = 5.0
const HEALTH_TIMEOUT: float = 2.5
## 天道榜拉取独立超时 8s（榜单非关键路径，避免慢网拖住界面）
const LEADERBOARD_TIMEOUT: float = 8.0
const PING_TIMEOUT: float = 6.0
const MAIL_TIMEOUT: float = 6.0
const MAX_PAYLOAD_BYTES: int = 512 * 1024
const AUTO_SYNC_INTERVAL: float = 300.0
const HEARTBEAT_INTERVAL: float = 60.0
const BREAKTHROUGH_DEBOUNCE: float = 1.5
## 归属未确认时禁止后台自动上传的硬锁时长
const OWNER_GUARD_SECONDS: float = 300.0

signal auth_changed
signal health_checked(ok: bool)
## 云端版本高于本地：等待玩家二选一（读取云端 / 本地覆盖云端）
signal save_conflict_detected(local_summary: Dictionary, cloud_summary: Dictionary)
## 新账号云端无档、但本地有他号/离线进度：等待「重头修行 / 继承上云」
signal new_account_choice_required(local_summary: Dictionary)
## 设置页「拉取云端」：先展示对比确认，再决定是否覆盖本地
signal save_pull_requested(local_summary: Dictionary, cloud_summary: Dictionary)
## 一次成功上传/下载后广播（save_rev 为最新版本）
signal cloud_synced(save_rev: int, uploaded: bool)
## 天道榜拉取结果（离线/未登录也会触发，message 为面向玩家的友好提示）
signal leaderboard_loaded(ok: bool, board_type: String, data: Dictionary, message: String)
## 服务端判定 JWT 过期：携带发起请求的 token，避免旧 401 误伤新登录态
signal auth_expired(expired_token: String)
## 轻量心跳解析出的未读传书数（登录会话内推送）
signal mail_unread_changed(count: int)
## 仙盟传书列表与领取结果
signal mail_list_loaded(ok: bool, mails: Array, message: String)
signal mail_claimed(ok: bool, mail_id: int, reward: Dictionary, message: String)

var is_offline_mode: bool = false
var unread_mail_count: int = 0
var skip_boot_overlay: bool = false
var auth: Dictionary = {}
var last_meta: Dictionary = {}
var server_reachable: bool = false

var _device_id: String = ""
var _is_syncing: bool = false
var _conflict_paused: bool = false
var _auto_sync_active: bool = false
var _auto_sync_accum: float = 0.0
var _heartbeat_accum: float = 0.0
var _heartbeat_busy: bool = false
var _breakthrough_delay: float = -1.0
var _auth_expired_notified: bool = false
## 归属待确认时的后台上传锁定截止时间（Unix 秒）
var _owner_guard_until: float = 0.0


func _ready() -> void:
	_load_auth()
	auth_expired.connect(_on_auth_expired)
	EventBus.realm_changed.connect(_on_realm_changed)


func _process(delta: float) -> void:
	if not _auto_sync_active:
		return
	if is_offline_mode or not has_token():
		return
	# 轻量心跳不参与存档同步锁；独立计时，60 秒一次，静默容错
	_heartbeat_accum += delta
	if _heartbeat_accum >= HEARTBEAT_INTERVAL:
		_heartbeat_accum = 0.0
		_ping_once()
	if _conflict_paused or is_owner_sync_blocked() or _is_syncing:
		return
	if _breakthrough_delay >= 0.0:
		_breakthrough_delay -= delta
		if _breakthrough_delay <= 0.0:
			_breakthrough_delay = -1.0
			_auto_upload()
	_auto_sync_accum += delta
	if _auto_sync_accum >= AUTO_SYNC_INTERVAL:
		_auto_sync_accum = 0.0
		_auto_upload()


func _auto_upload() -> void:
	if is_offline_mode or _conflict_paused or is_owner_sync_blocked() \
			or _is_syncing or not has_token():
		return
	upload_save(false)


func _on_auth_expired(expired_token: String) -> void:
	# 期间玩家可能已重新登录：仅当当前 token 仍是过期凭证时才清态回登录页
	if String(auth.get("token", "")) != expired_token:
		return
	if is_offline_mode:
		return
	EventBus.toast.emit("仙籍凭证已过期，请重验密令")
	# 保留本机玉简，只清凭证；避免闭关玩家因云端 401 丢失本地进度
	call_deferred("logout_and_clear_local", false, "仙籍凭证已过期，请重验密令")


func _on_realm_changed(_realm_id: String, _realm_name: String) -> void:
	# 大小境界突破后防抖 1.5s 再传，避免连跳时连发多次请求；
	# _is_syncing 期间（如下载导入触发的境界变化）绝不排程，防止刚拉回的玉简被反向覆写
	if not _auto_sync_active or is_offline_mode or _conflict_paused \
			or is_owner_sync_blocked() or _is_syncing or not has_token():
		return
	_breakthrough_delay = BREAKTHROUGH_DEBOUNCE


# ---------------------------------------------------------------- 凭证

func _load_auth() -> void:
	auth = {}
	if FileAccess.file_exists(AUTH_PATH):
		var file := FileAccess.open(AUTH_PATH, FileAccess.READ)
		if file != null:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			file.close()
			if typeof(parsed) == TYPE_DICTIONARY:
				auth = parsed
	_device_id = String(auth.get("device_id", "")).strip_edges()
	if _device_id == "":
		_device_id = Crypto.new().generate_random_bytes(12).hex_encode()
	auth["device_id"] = _device_id
	auth["token"] = String(auth.get("token", ""))
	auth["uid"] = int(auth.get("uid", 0))
	auth["username"] = String(auth.get("username", ""))
	auth["is_guest"] = bool(auth.get("is_guest", true))
	auth["local_save_rev"] = int(auth.get("local_save_rev", 0))
	auth["last_sync_at"] = int(auth.get("last_sync_at", 0))
	# 旧版无此字段：按 0（离线/未绑定）处理，不破坏旧档读取
	auth["last_save_owner_uid"] = int(auth.get("last_save_owner_uid", 0))
	if not FileAccess.file_exists(AUTH_PATH):
		_save_auth()


func _save_auth() -> void:
	var file := FileAccess.open(AUTH_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(auth))
	file.close()
	auth_changed.emit()


func get_device_id() -> String:
	return _device_id


## 天道演化：本地已挂载的最新补丁卷号（无档/损坏一律回 0）
func get_current_patch_rev() -> int:
	if not FileAccess.file_exists(PATCH_STATE_PATH):
		return 0
	var file := FileAccess.open(PATCH_STATE_PATH, FileAccess.READ)
	if file == null:
		return 0
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return 0
	return maxi(0, int((parsed as Dictionary).get("current_patch_rev", 0)))


func has_token() -> bool:
	return String(auth.get("token", "")) != ""


func get_save_owner_uid() -> int:
	return maxi(0, int(auth.get("last_save_owner_uid", 0)))


func set_save_owner_uid(uid: int) -> void:
	auth["last_save_owner_uid"] = maxi(0, uid)
	_save_auth()


func is_owner_sync_blocked() -> bool:
	return _owner_guard_until > Time.get_unix_time_from_system()


func _block_owner_sync() -> void:
	_conflict_paused = true
	_owner_guard_until = Time.get_unix_time_from_system() + OWNER_GUARD_SECONDS
	_auto_sync_accum = 0.0
	_breakthrough_delay = -1.0


func _release_owner_sync_guard() -> void:
	_owner_guard_until = 0.0
	_auto_sync_accum = 0.0


## 登录页快捷续途态判定：本地凭证有 token + 道号，且未处于主动退出后的空凭证态。
## 明文密令从不写入 cloud_auth.json，故此处无需也无法校验密码。
func has_saved_identity() -> bool:
	return has_token() and String(auth.get("username", "")).strip_edges() != ""


func is_guest_account() -> bool:
	return bool(auth.get("is_guest", true))


func is_syncing() -> bool:
	return _is_syncing


func is_conflict_paused() -> bool:
	return _conflict_paused


func display_name() -> String:
	var name := String(auth.get("username", ""))
	if name == "":
		return "无名散修"
	return name + ("（散修）" if is_guest_account() else "")


func set_offline_mode(value: bool) -> void:
	is_offline_mode = value
	if value:
		_auto_sync_active = false
		_heartbeat_accum = 0.0
		_heartbeat_busy = false
		unread_mail_count = 0
		mail_unread_changed.emit(0)
	auth_changed.emit()


func clear_conflict() -> void:
	_conflict_paused = false
	_auto_sync_accum = 0.0


## 退出仙籍：清空登录态（保留道号供登录页回填），可选清空本机玉简。
## 云端存档永远不动；清本机后下次同号登录应重拉云端。
func logout_and_clear_local(clear_local_save: bool = true,
		reason_text: String = "收摄心神，重返山门……") -> void:
	_auto_sync_active = false
	_breakthrough_delay = -1.0
	_auto_sync_accum = 0.0
	_heartbeat_accum = 0.0
	_heartbeat_busy = false
	unread_mail_count = 0
	mail_unread_changed.emit(0)
	_conflict_paused = false
	_auth_expired_notified = false
	var remembered_username := String(auth.get("username", ""))
	auth["token"] = ""
	auth["uid"] = 0
	auth["username"] = remembered_username
	auth["is_guest"] = true
	auth["local_save_rev"] = 0
	auth["last_sync_at"] = 0
	# 退出仙籍后本地进度即脱离账号归属；离线续玩保持 0，换号登录时必须确认
	auth["last_save_owner_uid"] = 0
	_release_owner_sync_guard()
	if clear_local_save:
		SaveManager.clear_local_save()
	else:
		# 仅退出登录：先把本机进度刻入玉简，再离开
		SaveManager.save_game(false)
	_save_auth()
	is_offline_mode = false
	SceneTransition.transition_to_scene("res://ui/LoginScene.tscn", reason_text)


func _apply_auth(data: Dictionary) -> void:
	_auth_expired_notified = false
	var previous_uid := int(auth.get("uid", 0))
	if data.has("token"):
		auth["token"] = String(data.get("token", ""))
	if data.has("uid"):
		auth["uid"] = int(data.get("uid", 0))
	if data.has("username"):
		auth["username"] = String(data.get("username", ""))
	if data.has("is_guest"):
		auth["is_guest"] = bool(data.get("is_guest", true))
	if previous_uid > 0 and previous_uid != int(auth.get("uid", 0)):
		# 直接换号时不可沿用上一账号的版本号；归属仍由 last_save_owner_uid 仲裁
		auth["local_save_rev"] = 0
		auth["last_sync_at"] = 0
	_save_auth()


# ---------------------------------------------------------------- HTTP

func _request(method: int, path: String, body: Variant = null, token: String = "",
		timeout: float = HTTP_TIMEOUT) -> Dictionary:
	var http := HTTPRequest.new()
	http.timeout = timeout
	add_child(http)
	var headers := PackedStringArray(["Content-Type: application/json"])
	if token != "":
		headers.append("Authorization: Bearer " + token)
	var payload := ""
	if body != null:
		payload = JSON.stringify(body)
	var err := http.request(SERVER_BASE_URL + path, headers, method, payload)
	if err != OK:
		http.queue_free()
		return {"ok": false, "http": 0, "code": -1, "message": "灵脉未通，请稍后再试", "data": {}}

	var response: Array = await http.request_completed
	http.queue_free()
	var result_code := int(response[0])
	var http_code := int(response[1])
	var raw: PackedByteArray = response[3]
	var text := raw.get_string_from_utf8()
	var parsed: Variant = JSON.parse_string(text) if text != "" else null
	var envelope: Dictionary = parsed if typeof(parsed) == TYPE_DICTIONARY else {}
	var data_variant: Variant = envelope.get("data", {})
	var data: Dictionary = data_variant if typeof(data_variant) == TYPE_DICTIONARY else {}

	var ok := result_code == HTTPRequest.RESULT_SUCCESS \
		and http_code >= 200 and http_code < 300 \
		and int(envelope.get("code", 0)) == 0
	var message := String(envelope.get("message", ""))
	# 服务端 Bearer 鉴权统一返回 401：只对「确实带了旧凭证」的请求判为过期，
	# 避免 /api/auth/login 的密码错误或管理接口的 401 误伤登录态。
	if token != "" and http_code == 401 and not _auth_expired_notified:
		_auth_expired_notified = true
		message = "仙籍凭证已过期，请重验密令"
		auth_expired.emit(token)
	if not ok and message == "":
		if result_code == HTTPRequest.RESULT_TIMEOUT:
			message = "灵脉未能回应，请稍后再试"
		elif result_code != HTTPRequest.RESULT_SUCCESS:
			message = "灵脉未通，可先行闭关独修"
		else:
			message = "感应灵脉失败（%d）" % http_code
	return {"ok": ok, "http": http_code, "code": int(envelope.get("code", 0)),
		"message": message, "data": data}


func probe_server(timeout: float = HEALTH_TIMEOUT) -> void:
	var result := await _request(HTTPClient.METHOD_GET, "/api/health", null, "", timeout)
	server_reachable = bool(result.get("ok", false))
	health_checked.emit(server_reachable)


# ---------------------------------------------------------------- 仙籍

func guest_login() -> Dictionary:
	var result := await _request(HTTPClient.METHOD_POST, "/api/auth/guest",
		{"device_id": _device_id})
	if bool(result.get("ok", false)):
		_apply_auth(result.get("data", {}))
		is_offline_mode = false
	return result


func register(username: String, password: String) -> Dictionary:
	var guest := await guest_login()
	if not bool(guest.get("ok", false)):
		return guest
	var result := await _request(HTTPClient.METHOD_POST, "/api/auth/bind",
		{"username": username, "password": password}, String(auth.get("token", "")))
	if bool(result.get("ok", false)):
		_apply_auth(result.get("data", {}))
		is_offline_mode = false
	return result


func login(username: String, password: String) -> Dictionary:
	var result := await _request(HTTPClient.METHOD_POST, "/api/auth/login",
		{"username": username, "password": password})
	if bool(result.get("ok", false)):
		_apply_auth(result.get("data", {}))
		is_offline_mode = false
	return result


# ---------------------------------------------------------------- 摘要

## 当前本地玉简摘要（字段与 server/save.go 的 saveMeta 对齐）
func local_summary() -> Dictionary:
	var realm := GameState.get_realm()
	var realm_name := "初入道途"
	if realm != null:
		realm_name = String(realm.display_name).split(" · ")[0]
	return {
		"realm_name": realm_name,
		"spirit_stones": GameFormulas.format_num(
			float(GameState.get_item_count(DataRegistry.SPIRIT_STONE))),
		"play_seconds": int(float(GameState.stats.get("play_seconds", 0.0))),
		"save_rev": int(auth.get("local_save_rev", 0)),
		"updated_at": int(auth.get("last_sync_at", 0)),
	}


func cloud_summary_from_meta(data: Dictionary) -> Dictionary:
	return {
		"realm_name": String(data.get("realm_name", "未知境界")),
		"spirit_stones": String(data.get("spirit_stones", "0")),
		"play_seconds": int(data.get("play_seconds", 0)),
		"save_rev": int(data.get("save_rev", 0)),
		"updated_at": int(data.get("updated_at", 0)),
	}


# ---------------------------------------------------------------- 云篆

func begin_session() -> void:
	_auto_sync_active = true
	_auto_sync_accum = 0.0
	_heartbeat_accum = 0.0
	_breakthrough_delay = -1.0
	if is_offline_mode or not has_token():
		return
	await check_cloud_meta()
	# 会话初始化完成后立即同步一次未读传书；失败静默，不阻断进入主界面
	await _ping_once()


func end_session() -> void:
	_auto_sync_active = false
	_heartbeat_accum = 0.0
	_heartbeat_busy = false
	unread_mail_count = 0
	mail_unread_changed.emit(0)


## 登录后首次检查：空云端静默建首版；云端更新则弹冲突；本地更新则补传。
func check_cloud_meta() -> Dictionary:
	if is_offline_mode or not has_token():
		return {"ok": false, "message": ""}
	if _is_syncing:
		return {"ok": false, "message": "正在同步"}
	_is_syncing = true
	var meta := await fetch_meta()
	_is_syncing = false
	if not bool(meta.get("ok", false)):
		return meta
	var data: Dictionary = meta.get("data", {})
	last_meta = data
	var current_uid := int(auth.get("uid", 0))
	var owner_uid := get_save_owner_uid()
	var local_has_progress := SaveManager.has_meaningful_progress()
	if not bool(data.get("exists", false)):
		# 云端为空：仅同号或本地本就空白时才允许静默建首版
		if local_has_progress and owner_uid != current_uid:
			_block_owner_sync()
			new_account_choice_required.emit(local_summary())
			return {"ok": true, "conflict": true, "owner_mismatch": true,
				"message": "需确认本地进度归属"}
		return await upload_save(false)
	# 云端有档但归属不是当前账号：绝不能拿 A 的本地档覆盖 B 的云端
	if owner_uid != current_uid:
		_block_owner_sync()
		save_conflict_detected.emit(local_summary(), cloud_summary_from_meta(data))
		return {"ok": true, "conflict": true, "owner_mismatch": true,
			"message": "本地玉简归属与当前仙籍不一致"}
	var cloud_rev := int(data.get("save_rev", 0))
	var local_rev := int(auth.get("local_save_rev", 0))
	if cloud_rev > local_rev:
		# 退出仙籍并清本机后（本地无玉简）直接重拉云端；
		# 本地仍有进度则弹冲突二选一，绝不自动覆盖
		if local_rev <= 0 and not SaveManager.has_save():
			return await download_save()
		_conflict_paused = true
		save_conflict_detected.emit(local_summary(), cloud_summary_from_meta(data))
		return {"ok": true, "conflict": true, "message": "云端玉简较新"}
	if local_rev > cloud_rev:
		return await upload_save(false)
	return {"ok": true, "conflict": false, "message": ""}


func fetch_meta() -> Dictionary:
	if not has_token():
		return {"ok": false, "message": "尚未登录仙籍", "data": {}}
	var result := await _request(HTTPClient.METHOD_GET, "/api/save/meta", null,
		String(auth.get("token", "")))
	if bool(result.get("ok", false)):
		last_meta = result.get("data", {})
	return result


func upload_save(force: bool = false) -> Dictionary:
	if is_offline_mode:
		return {"ok": false, "http": 0, "code": -2, "message": "当前为离线单机模式", "data": {}}
	if not has_token():
		return {"ok": false, "http": 0, "code": -3, "message": "尚未登录仙籍", "data": {}}
	if not force and is_owner_sync_blocked():
		return {"ok": false, "http": 0, "code": -7,
			"message": "本地玉简归属待确认，已暂缓自动上传", "data": {}}
	if _is_syncing:
		return {"ok": false, "http": 0, "code": -6, "message": "正在同步", "data": {}}

	_is_syncing = true
	# 先本地落盘再打包：保证「立即上传」时云端与本地玉简完全一致
	SaveManager.save_game(false)
	# 取当前完整存档字典（与 SaveManager 写盘结构一致），保证界面刚产生的进度也入包
	var payload_text := JSON.stringify(SaveManager.build_save_payload())
	var bytes := payload_text.to_utf8_buffer()
	var compressed := bytes.compress(FileAccess.COMPRESSION_GZIP)
	if compressed.size() > MAX_PAYLOAD_BYTES:
		_is_syncing = false
		return {"ok": false, "http": 0, "code": -5,
			"message": "本地玉简超出 512KB，暂不能上云", "data": {}}

	var summary := local_summary()
	var body := {
		"base_rev": int(auth.get("local_save_rev", 0)),
		"force": force,
		"realm_name": summary["realm_name"],
		"spirit_stones": summary["spirit_stones"],
		"play_seconds": summary["play_seconds"],
		# 天道榜排序字段：境界下标 0~30 / 当前修为 / 镇魔塔历史最高层
		"realm_order": clampi(GameState.get_realm_index(), 0, 30),
		"cultivation_xp": maxf(0.0, float(GameState.cultivation_xp)),
		"tower_floor": maxi(0, int(GameState.tower_highest_floor)),
		"payload_gzip_b64": Marshalls.raw_to_base64(compressed),
	}
	var result := await _request(HTTPClient.METHOD_POST, "/api/save/upload", body,
		String(auth.get("token", "")))
	_is_syncing = false

	if bool(result.get("ok", false)):
		var data: Dictionary = result.get("data", {})
		auth["local_save_rev"] = int(data.get("save_rev", int(auth.get("local_save_rev", 0))))
		auth["last_sync_at"] = int(data.get("updated_at", Time.get_unix_time_from_system()))
		auth["last_save_owner_uid"] = int(auth.get("uid", 0))
		_save_auth()
		_conflict_paused = false
		_release_owner_sync_guard()
		_breakthrough_delay = -1.0
		cloud_synced.emit(int(auth["local_save_rev"]), true)
		return result

	if int(result.get("http", 0)) == 409:
		# 服务端已把云端摘要放在 data 中；缺失时退回最近一次 meta
		var cloud_data: Dictionary = result.get("data", {})
		if cloud_data.is_empty():
			cloud_data = last_meta
		_conflict_paused = true
		save_conflict_detected.emit(local_summary(), cloud_summary_from_meta(cloud_data))
	return result


func download_save() -> Dictionary:
	if is_offline_mode:
		return {"ok": false, "message": "闭关独修时不取云端存档", "data": {}}
	if not has_token():
		return {"ok": false, "message": "尚未登录仙籍", "data": {}}
	if _is_syncing:
		return {"ok": false, "message": "正在同步", "data": {}}

	_is_syncing = true
	var result := await _request(HTTPClient.METHOD_GET, "/api/save/download", null,
		String(auth.get("token", "")))
	if not bool(result.get("ok", false)):
		_is_syncing = false
		return result
	var data: Dictionary = result.get("data", {})
	var b64 := String(data.get("payload_gzip_b64", ""))
	var compressed := Marshalls.base64_to_raw(b64)
	if compressed.is_empty():
		_is_syncing = false
		return {"ok": false, "message": "云端玉简为空", "data": {}}
	var raw := compressed.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)
	if raw.is_empty():
		_is_syncing = false
		return {"ok": false, "message": "云端玉简解压失败", "data": {}}
	var text := raw.get_string_from_utf8()
	# import_save_json 内部完成 GameState/FarmManager 热刷新、落盘并广播 game_loaded
	if not SaveManager.import_save_json(text):
		_is_syncing = false
		return {"ok": false, "message": "云端玉简格式不被识别", "data": {}}
	auth["local_save_rev"] = int(data.get("save_rev", 0))
	auth["last_sync_at"] = int(data.get("updated_at", Time.get_unix_time_from_system()))
	auth["last_save_owner_uid"] = int(auth.get("uid", 0))
	_conflict_paused = false
	_release_owner_sync_guard()
	_breakthrough_delay = -1.0
	_save_auth()
	_is_syncing = false
	cloud_synced.emit(int(auth["local_save_rev"]), false)
	return {"ok": true, "save_rev": int(auth["local_save_rev"]),
		"updated_at": int(auth["last_sync_at"]), "data": {}}


## 新号首档二选一：reset_local=true 重头修行，否则继承本地进度。
func resolve_new_account_choice(reset_local: bool) -> Dictionary:
	if not has_token():
		return {"ok": false, "message": "尚未登录仙籍", "data": {}}
	if reset_local:
		SaveManager.reset_save()
		auth["local_save_rev"] = 0
		auth["last_sync_at"] = 0
		auth["last_save_owner_uid"] = 0
		_save_auth()
	var result := await upload_save(true)
	if bool(result.get("ok", false)):
		_conflict_paused = false
		_release_owner_sync_guard()
	return result


## 天道榜：GET /api/leaderboard。离线/未登录不发请求，直接触发友好提示。
## 仅在面板打开或手动刷新时调用，内部不轮询。
func fetch_leaderboard(board_type: String = "realm", limit: int = 50) -> void:
	var kind := board_type.strip_edges()
	if kind != "realm" and kind != "tower" and kind != "stones":
		kind = "realm"
	var take := clampi(limit, 1, 100)
	if is_offline_mode:
		leaderboard_loaded.emit(false, kind, {},
			"当前为闭关独修，登录仙籍后可观览天道榜")
		return
	if not has_token():
		leaderboard_loaded.emit(false, kind, {},
			"当前为闭关独修，登录仙籍后可观览天道榜")
		return
	var path := "/api/leaderboard?type=%s&limit=%d" % [kind, take]
	var result := await _request(HTTPClient.METHOD_GET, path, null,
		String(auth.get("token", "")), LEADERBOARD_TIMEOUT)
	var message := String(result.get("message", ""))
	var data: Dictionary = result.get("data", {})
	if not bool(result.get("ok", false)):
		if message == "":
			message = "天道榜暂不可读，请稍后再试"
		leaderboard_loaded.emit(false, kind, {}, message)
		return
	leaderboard_loaded.emit(true, String(data.get("type", kind)), data, "")


# ---------------------------------------------------------------- 在线心跳 / 仙盟传书

const MAIL_OFFLINE_TEXT: String = "当前为闭关独修状态，登录仙籍后可收取仙盟传书"


func _is_mail_ready() -> bool:
	return not is_offline_mode and has_token()


## 60 秒心跳 + 会话初始化心跳；失败静默，不弹窗、不打断游戏。
func _ping_once() -> void:
	if _heartbeat_busy or not _is_mail_ready():
		return
	_heartbeat_busy = true
	var result := await _request(HTTPClient.METHOD_POST, "/api/ping", {},
		String(auth.get("token", "")), PING_TIMEOUT)
	_heartbeat_busy = false
	if not bool(result.get("ok", false)):
		return
	var data: Dictionary = result.get("data", {})
	unread_mail_count = maxi(0, int(data.get("unread_mail_count", 0)))
	mail_unread_changed.emit(unread_mail_count)


func fetch_mail_list() -> void:
	if not _is_mail_ready():
		mail_list_loaded.emit(false, [], MAIL_OFFLINE_TEXT)
		return
	var result := await _request(HTTPClient.METHOD_GET, "/api/mail/list", null,
		String(auth.get("token", "")), MAIL_TIMEOUT)
	var data: Dictionary = result.get("data", {})
	var mails_variant: Variant = data.get("mails", [])
	var mails: Array = mails_variant if typeof(mails_variant) == TYPE_ARRAY else []
	if not bool(result.get("ok", false)):
		var message := String(result.get("message", ""))
		if message == "":
			message = "仙盟传书暂不可读，请稍后再试"
		mail_list_loaded.emit(false, [], message)
		return
	mail_list_loaded.emit(true, mails, "")


func claim_mail(mail_id: int) -> void:
	if not _is_mail_ready():
		mail_claimed.emit(false, mail_id, {}, MAIL_OFFLINE_TEXT)
		return
	var result := await _request(HTTPClient.METHOD_POST, "/api/mail/claim",
		{"mail_id": mail_id}, String(auth.get("token", "")), MAIL_TIMEOUT)
	var data: Dictionary = result.get("data", {})
	var reward: Dictionary = {}
	if bool(result.get("ok", false)):
		reward = {
			"mail_id": int(data.get("mail_id", mail_id)),
			"spirit_stones": maxi(0, int(data.get("spirit_stones", 0))),
			"items": data.get("items", []),
		}
	mail_claimed.emit(bool(result.get("ok", false)), mail_id, reward,
		String(result.get("message", "")))


func set_unread_mail_count(value: int) -> void:
	unread_mail_count = maxi(0, value)
	mail_unread_changed.emit(unread_mail_count)


## 设置页「拉取云端」：先取 meta，有档则请求上层弹对比确认，不直接覆盖本地
func request_pull_confirm() -> Dictionary:
	if is_offline_mode or not has_token():
		return {"ok": false, "message": "当前不可读取云端"}
	if _is_syncing:
		return {"ok": false, "message": "正在同步"}
	var meta := await fetch_meta()
	if not bool(meta.get("ok", false)):
		return meta
	var data: Dictionary = meta.get("data", {})
	if not bool(data.get("exists", false)):
		return {"ok": true, "exists": false, "message": "云端暂无玉简"}
	save_pull_requested.emit(local_summary(), cloud_summary_from_meta(data))
	return {"ok": true, "exists": true, "message": ""}
