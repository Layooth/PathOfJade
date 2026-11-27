extends Control
## 天道演化：启动时先挂载本地灵纹补丁 → 查询增量 → 下载 → SHA256 校验 → 挂载 → 进入仙籍登录。
## 本场景只依赖 ThemeBuilder / CloudSaveManager，不加载任何业务面板，确保 .pck 能覆盖 Login/MainShell。

const BG_COLOR: Color = Color("#F7F3E8")
const LOGIN_SCENE: String = "res://ui/LoginScene.tscn"
const PATCH_DIR: String = "user://patches"
const PATCH_STATE_PATH: String = "user://patch_state.json"
## 当前源码底包已内置的补丁卷数。导出新 APK 前按实际内置内容递增。
const BASE_PATCH_REV: int = 2
const VERSION_TIMEOUT: float = 3.0
## .pck 下载不设总超时；仅在连续 20 秒没有新字节写入时中断
const DOWNLOAD_STALL_TIMEOUT_MS: int = 20000
const HTTP_CHUNKS_PER_FRAME: int = 24
const PROGRESS_TWEEN_TIME: float = 0.25
const FINISH_HOLD_TIME: float = 0.20
const UPDATE_RETRY_TEXT: String = "天道卷册摹录中断，请重连后重试"

enum DownloadPhase { IDLE, CONNECTING, REQUESTING, BODY, DONE }

var _progress: ProgressBar
var _progress_tween: Tween
var _status: Label
var _retry_button: Button
var _version_label: Label

var _state: Dictionary = {}
## 版本清单确认有补丁后进入强制更新态，任何下载/校验/挂载失败都不得自动进游
var _pending_patches: Array = []
var _retrying: bool = false
var _last_error: String = ""
## 收尾阶段禁止任何非 100% 的进度写入打断正在等待的满格 Tween
var _finishing: bool = false
## 本次启动是否至少成功挂载过 1 个本地/新下载 PCK
var _loaded_patch_this_boot: bool = false
var _static_reload_done: bool = false

## HTTPClient 分块下载状态（不挂节点，_process 中逐帧 poll）
var _downloading: bool = false
var _download_client: HTTPClient
var _download_file: FileAccess
var _download_phase: DownloadPhase = DownloadPhase.IDLE
var _download_done: bool = false
var _download_ok: bool = false
var _download_stalled: bool = false
var _download_patch: Dictionary = {}
var _download_url: String = ""
var _download_path: String = ""
var _download_meta_path: String = ""
var _download_tmp: String = ""
var _download_expected: int = 0
var _download_total: int = 0
var _download_written: int = 0
var _download_resume_from: int = 0
var _download_request_path: String = ""
var _download_request_headers: PackedStringArray = PackedStringArray()
var _download_seen_body: bool = false
var _download_active_msec: int = 0
var _download_base: float = 0.0
var _download_span: float = 0.0
var _download_label: String = ""


func _ready() -> void:
	theme = ThemeBuilder.build_theme()
	_build_ui()
	await get_tree().process_frame
	_run_boot()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = BG_COLOR
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# 极轻量宣纸微尘：单节点 _draw + 14 粒固定池，无 Shader / 粒子 / 贴图依赖
	var aura := AmbientAuraLayer.new()
	aura.name = "BootAmbientAura"
	aura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aura.modulate = Color(1.0, 1.0, 1.0, 0.45)
	add_child(aura)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 70)
	add_child(margin)

	var column := ThemeBuilder.vbox(10)
	margin.add_child(column)

	var top_space := Control.new()
	top_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	top_space.size_flags_stretch_ratio = 0.42
	column.add_child(top_space)

	# 标题 + 朱砂小印：整组水平居中，印章紧凑不抢主标题
	var title_row := ThemeBuilder.hbox(10)
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	title_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(title_row)
	var title := ThemeBuilder.title_label("玉简问道", 34)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeBuilder.apply_brush_kai(title)
	title_row.add_child(title)
	var seal := ThemeBuilder.create_seal_badge("问道", "cinnabar")
	# create_seal_badge 内置 10 号字，这里提升到 FONT_CAPTION 13 红线以上
	for child in seal.get_children():
		if child is Label:
			ThemeBuilder.apply_font_size(child as Label, ThemeBuilder.FONT_CAPTION)
	title_row.add_child(seal)

	# 标题与副标题之间的 48×1 鎏金短线，透明度 0.45
	var rule := ColorRect.new()
	rule.color = Color(ThemeBuilder.COLOR_TEXT_GOLD, 0.45)
	rule.custom_minimum_size = Vector2(48, 1)
	rule.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(rule)

	var subtitle := ThemeBuilder.wrap_label("一卷青简问长生，半盏清茶悟天道",
		ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_SECONDARY)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(subtitle)

	var mid_space := Control.new()
	mid_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid_space.size_flags_stretch_ratio = 0.58
	column.add_child(mid_space)

	_progress = ThemeBuilder.progress_bar(ThemeBuilder.COLOR_JADE, 5)
	_progress.custom_minimum_size = Vector2(240, 5)
	_progress.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_progress.show_percentage = false
	_progress.max_value = 100.0
	_progress.value = 0.0
	column.add_child(_progress)

	_status = ThemeBuilder.wrap_label("正在感应天道演化...",
		ThemeBuilder.FONT_CAPTION, ThemeBuilder.COLOR_TEXT_SECONDARY)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.custom_minimum_size = Vector2(0, 38)
	column.add_child(_status)

	# 强制更新失败后的唯一主操作：居中、44 高、鎏金主按钮
	_retry_button = ThemeBuilder.button("重试更新", true)
	ThemeBuilder.apply_font_size(_retry_button, ThemeBuilder.FONT_BODY_SUB)
	_retry_button.custom_minimum_size = Vector2(150, ThemeBuilder.TOUCH_MIN)
	_retry_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_retry_button.visible = false
	_retry_button.pressed.connect(_on_retry_pressed)
	column.add_child(_retry_button)
	ThemeBuilder.prepare_touch(_retry_button)

	# 右下版本号：与 LoginScene 完全同款贴角逻辑（右 14 / 底 14，按字号行高反推顶部）
	_version_label = ThemeBuilder.label(_version_text(), ThemeBuilder.FONT_CAPTION,
		ThemeBuilder.COLOR_TEXT_SECONDARY)
	ThemeBuilder.apply_font_size(_version_label, ThemeBuilder.FONT_CAPTION)
	_version_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_version_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_version_label.anchor_left = 1.0
	_version_label.anchor_right = 1.0
	_version_label.anchor_top = 1.0
	_version_label.anchor_bottom = 1.0
	_version_label.offset_left = -160
	_version_label.offset_right = -14
	add_child(_version_label)
	var badge_h := maxf(18.0, _version_label.get_combined_minimum_size().y)
	_version_label.custom_minimum_size = Vector2(0, badge_h)
	_version_label.offset_top = -14.0 - badge_h
	_version_label.offset_bottom = -14.0


func _run_boot() -> void:
	if _is_editor_debug():
		# 编辑器 F5 永远跑当前本地源码：不拉清单、不下载、不挂载任何历史 .pck
		_status.text = "本地调试"
		if _version_label != null:
			_version_label.text = _editor_version_text()
		_set_progress(100.0)
		await _finish("本地调试，径直入世")
		return
	_ensure_patch_dir()
	_load_state()
	await _mount_local_patches()
	_set_progress(10.0)
	_status.text = "正在感应天道演化..."
	await get_tree().create_timer(0.15).timeout

	var data := await _fetch_version()
	if data.is_empty():
		# 3 秒网络检测超时 / 请求失败：保持不阻断进游
		await _finish("灵脉暂阻，径直入世")
		return
	var patches_variant: Variant = data.get("patches", [])
	var patches: Array = patches_variant if typeof(patches_variant) == TYPE_ARRAY else []
	# 成功拿到清单就先落一份「热更志」：即使本次已是最新、无需下载，也能在设置里回看
	if not patches.is_empty():
		CloudSaveManager.record_patch_notes_in_state(_state, patches)
		_save_state()
	# 清单含多卷时也只拉 rev 最大的最新全量包，不逐卷下载中间版本
	var latest_patch := _pick_latest_patch(patches)
	if latest_patch.is_empty() or not _needs_download(int(latest_patch.get("rev", 0))):
		await _finish("天道卷册已是最新")
		return
	_pending_patches = [latest_patch]
	await _apply_pending_patches()


func _pick_latest_patch(patches: Array) -> Dictionary:
	var latest_rev := 0
	var latest_patch: Dictionary = {}
	for patch_value in patches:
		if typeof(patch_value) != TYPE_DICTIONARY:
			continue
		var patch: Dictionary = patch_value
		var rev := int(patch.get("rev", 0))
		if rev > 0 and rev > latest_rev:
			latest_rev = rev
			latest_patch = patch
	return latest_patch


## 仅下载最新全量卷；失败留在 BootScene 等待「重试更新」，重试直接复用 .tmp 续传
func _apply_pending_patches() -> void:
	if _pending_patches.is_empty() or _finishing:
		return
	_retry_button.visible = false
	_last_error = ""
	_set_progress(18.0)
	var patch: Dictionary = _pending_patches[0]
	var rev := int(patch.get("rev", 0))
	_set_status("正在摹录天道第 %d 卷…" % rev)
	var ok := await _download_and_mount(patch, 1, 1)
	if not ok:
		_show_update_failure(_last_error if _last_error != "" else UPDATE_RETRY_TEXT)
		return
	await _finish("灵纹校验无误，正在融入天地...")


func _show_update_failure(message: String) -> void:
	_finishing = false
	_downloading = false
	_last_error = message
	_set_status(message)
	if _retry_button != null:
		_retry_button.text = "重试更新"
		_retry_button.disabled = false
		_retry_button.visible = true
		ThemeBuilder.apply_font_size(_retry_button, ThemeBuilder.FONT_BODY_SUB)


func _on_retry_pressed() -> void:
	if _retrying or _finishing or _pending_patches.is_empty():
		return
	if AudioManager != null:
		AudioManager.play_tap()
	_retrying = true
	_retry_button.visible = false
	_set_status("重新接引天道卷册...")
	await _apply_pending_patches()
	_retrying = false


func _finish(message: String) -> void:
	_finishing = true
	_status.text = message
	var tween := _set_progress(100.0)
	# 必须等平滑动画真正拉满，再停留 0.2s，避免切场时进度条还在爬
	if tween != null and tween.is_valid():
		await tween.finished
	await get_tree().create_timer(FINISH_HOLD_TIME).timeout
	if not is_inside_tree():
		return
	# 仅在本次确实挂载过 PCK 时刷新静态表；失败只跳过，绝不阻塞进入登录页
	if _loaded_patch_this_boot:
		_refresh_static_data_after_patch()
	# 走全局水墨过渡，与登录页↔主界面切换风格一致；提示语沿用当前状态文案
	SceneTransition.transition_to_scene(LOGIN_SCENE, message)


## PCK 挂载后静态配置热刷新：DataRegistry 全量重建 + IconLibrary 缓存重建。
## 只在 BootScene 进入 LoginScene 前执行一次，不加载任何业务面板。
func _refresh_static_data_after_patch() -> void:
	if _static_reload_done:
		return
	_static_reload_done = true
	if DataRegistry != null:
		var new_data_script: Script = _load_fresh_script(
			"res://core/autoloads/DataRegistry.gd")
		if new_data_script != null:
			DataRegistry.set_script(new_data_script)
			if DataRegistry.has_method("rebuild_registries"):
				DataRegistry.call("rebuild_registries")
			elif DataRegistry.has_method("_ready"):
				DataRegistry.call("_ready")
	if IconLibrary != null:
		# IconLibrary 本身的脚本不强制替换；重建缓存时会从 PCK 源码重读 IconSvgPack 常量。
		if IconLibrary.has_method("rebuild_cache"):
			IconLibrary.call("rebuild_cache")
		elif IconLibrary.has_method("clear_cache"):
			IconLibrary.call("clear_cache")


## CACHE_MODE_REPLACE 对已加载 Autoload 仍可能返回旧缓存；再从 PCK 文件文本编译一次。
## 失败时回退 ResourceLoader 结果；均无效则返回 null，调用方安全跳过。
func _load_fresh_script(path: String) -> Script:
	var loaded: Script = ResourceLoader.load(path, "Script",
		ResourceLoader.CACHE_MODE_REPLACE) as Script
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return loaded
	var source := file.get_as_text()
	file.close()
	if source.strip_edges() == "":
		return loaded
	var fresh := GDScript.new()
	fresh.source_code = source
	if fresh.reload() != OK:
		return loaded
	return fresh


# ---------------------------------------------------------------- 本地补丁

func _ensure_patch_dir() -> void:
	var absolute := ProjectSettings.globalize_path(PATCH_DIR)
	if not DirAccess.dir_exists_absolute(absolute):
		DirAccess.make_dir_recursive_absolute(absolute)


func _load_state() -> void:
	_state = CloudSaveManager.patch_state_defaults()
	if FileAccess.file_exists(PATCH_STATE_PATH):
		var file := FileAccess.open(PATCH_STATE_PATH, FileAccess.READ)
		if file != null:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			file.close()
			if typeof(parsed) == TYPE_DICTIONARY:
				_state = CloudSaveManager.normalize_patch_state(parsed as Dictionary)
	# 底包基准并入有效卷数；旧档只升不降，字段结构不变
	_state["current_patch_rev"] = _effective_patch_rev()


func _save_state() -> void:
	# 统一由 CloudSaveManager 归一化：补 notes / last_seen_notes_rev，旧档字段原样保留
	_state = CloudSaveManager.normalize_patch_state(_state)
	var file := FileAccess.open(PATCH_STATE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(_state))
	file.close()
	if _version_label != null:
		_version_label.text = _version_text()


func _mount_local_patches() -> void:
	_set_status("正在唤醒本地灵纹...")
	_set_progress(4.0)
	var files := _scan_patch_files()
	for i in range(files.size()):
		var entry: Dictionary = files[i]
		var rev := int(entry["rev"])
		var path := String(entry["path"])
		if not _should_mount_local_rev(rev):
			# 已并入底包的旧卷：直接清理，避免旧 .pck 反向覆盖新 APK 源码
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
			_forget_installed(rev)
			_set_status("旧卷已并入底包，已清去残卷")
			continue
		if ProjectSettings.load_resource_pack(path, true):
			_loaded_patch_this_boot = true
			_remember_installed(rev, String(entry["name"]))
			_set_progress(4.0 + 5.0 * float(i + 1) / float(maxi(1, files.size())))
		else:
			# 损坏包：删除并从已安装清单回退，绝不挂载
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
			_forget_installed(rev)
			_status.text = "本地灵纹有损，已清去残卷"
	_recompute_current_rev()
	_save_state()


func _scan_patch_files() -> Array:
	var entries: Array = []
	var dir := DirAccess.open(PATCH_DIR)
	if dir == null:
		return entries
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if not dir.current_is_dir() and name.begins_with("patch_") and name.ends_with(".pck"):
			var mid := name.substr(6, name.length() - 10)
			if mid.is_valid_int():
				entries.append({"rev": int(mid), "name": name,
					"path": PATCH_DIR + "/" + name})
		name = dir.get_next()
	dir.list_dir_end()
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["rev"]) < int(b["rev"]))
	return entries


func _remember_installed(rev: int, filename: String) -> void:
	var installed: Array = _state.get("installed_patches", [])
	if not installed.has(filename):
		installed.append(filename)
	_state["installed_patches"] = installed
	_state["current_patch_rev"] = maxi(int(_state.get("current_patch_rev", 0)), rev)


func _forget_installed(rev: int) -> void:
	var installed: Array = _state.get("installed_patches", [])
	var kept: Array = []
	for name in installed:
		var n := String(name)
		var mid := n.substr(6, n.length() - 10) if n.begins_with("patch_") \
			and n.ends_with(".pck") else ""
		if mid.is_valid_int() and int(mid) == rev:
			continue
		kept.append(n)
	_state["installed_patches"] = kept


func _recompute_current_rev() -> void:
	var installed: Array = _state.get("installed_patches", [])
	var highest := BASE_PATCH_REV
	for name in installed:
		var n := String(name)
		if n.begins_with("patch_") and n.ends_with(".pck"):
			var mid := n.substr(6, n.length() - 10)
			if mid.is_valid_int():
				highest = maxi(highest, int(mid))
	_state["current_patch_rev"] = highest


# ---------------------------------------------------------------- 版本清单

func _fetch_version() -> Dictionary:
	var http := HTTPRequest.new()
	http.timeout = VERSION_TIMEOUT
	add_child(http)
	var url := CloudSaveManager.SERVER_BASE_URL + "/api/version?patch_rev=" \
		+ str(_effective_patch_rev())
	var err := http.request(url)
	if err != OK:
		http.queue_free()
		return {}
	var response: Array = await http.request_completed
	http.queue_free()
	if int(response[0]) != HTTPRequest.RESULT_SUCCESS:
		return {}
	var code := int(response[1])
	if code < 200 or code >= 300:
		return {}
	var text := (response[3] as PackedByteArray).get_string_from_utf8()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var envelope: Dictionary = parsed
	if int(envelope.get("code", 0)) != 0:
		return {}
	var data_variant: Variant = envelope.get("data", {})
	return data_variant if typeof(data_variant) == TYPE_DICTIONARY else {}


# ---------------------------------------------------------------- 下载与校验

func _download_and_mount(patch: Dictionary, index: int, total: int) -> bool:
	_last_error = ""
	_download_patch = patch.duplicate(true)
	var rev := int(patch.get("rev", 0))
	var expected := String(patch.get("sha256", "")).strip_edges().to_lower()
	var filename := "patch_%d.pck" % rev
	var final_path := PATCH_DIR + "/" + filename
	var tmp_path := final_path + ".tmp"
	_download_tmp = tmp_path
	_download_meta_path = tmp_path + ".meta"
	_download_expected = maxi(0, int(patch.get("size", 0)))
	_download_base = 18.0 + 70.0 * float(index - 1) / float(maxi(1, total))
	_download_span = 70.0 / float(maxi(1, total))
	_download_label = "正在摹录天道第 %d 卷" % rev
	_set_status(_download_label + "…")

	# meta 只记录本次目标 rev 与 sha256；不匹配即视为陈旧残片，从 0 重下
	var resume := _resume_bytes(tmp_path, _download_meta_path, rev, expected)
	if _download_expected > 0 and resume >= _download_expected:
		var actual_existing := FileAccess.get_sha256(tmp_path).to_lower()
		if expected != "" and actual_existing == expected:
			_download_done = true
			_download_ok = true
			resume = _download_expected
		else:
			_remove_file(tmp_path)
			_remove_file(_download_meta_path)
			resume = 0
	_write_resume_meta(_download_meta_path, rev, expected)
	if not _download_done:
		_begin_download(resume)
	await _wait_download_done()
	_close_download_handles()
	_downloading = false
	if _download_stalled:
		# 保留 .tmp + .meta，重试时继续 Range 续传
		_last_error = UPDATE_RETRY_TEXT
		return false
	if not _download_ok:
		return false

	_status.text = "校验灵纹..."
	var actual := FileAccess.get_sha256(tmp_path).to_lower()
	if expected == "" or actual != expected:
		_remove_file(tmp_path)
		_remove_file(_download_meta_path)
		_last_error = "天道卷册校验未过，请重连后重试"
		return false

	if FileAccess.file_exists(final_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(final_path))
	var rename_error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(tmp_path),
		ProjectSettings.globalize_path(final_path))
	if rename_error != OK:
		_last_error = "天道卷册落卷失败，请重连后重试"
		return false

	if not ProjectSettings.load_resource_pack(final_path, true):
		_remove_file(final_path)
		_remove_file(_download_meta_path)
		_forget_installed(rev)
		_recompute_current_rev()
		_save_state()
		_last_error = "天道卷册融入失败，请重连后重试"
		return false

	_loaded_patch_this_boot = true
	# 最新全量卷即唯一已安装卷；物理清理所有旧 .pck 与 .tmp/.tmp.meta
	_state["installed_patches"] = [filename]
	_state["current_patch_rev"] = rev
	# 本次实际挂载的补丁说明一并入库（无 notes 时由归一化补修仙默认说明）
	CloudSaveManager.record_patch_notes_in_state(_state, [_download_patch])
	_save_state()
	_cleanup_patch_files(filename)
	_last_error = ""
	return true


func _resume_bytes(tmp_path: String, meta_path: String, rev: int,
		expected: String) -> int:
	if not FileAccess.file_exists(tmp_path):
		_remove_file(meta_path)
		return 0
	if not FileAccess.file_exists(meta_path):
		_remove_file(tmp_path)
		return 0
	var meta_file := FileAccess.open(meta_path, FileAccess.READ)
	if meta_file == null:
		_remove_file(tmp_path)
		_remove_file(meta_path)
		return 0
	var parsed: Variant = JSON.parse_string(meta_file.get_as_text())
	meta_file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		_remove_file(tmp_path)
		_remove_file(meta_path)
		return 0
	var meta: Dictionary = parsed
	if int(meta.get("rev", 0)) != rev \
			or String(meta.get("sha256", "")).strip_edges().to_lower() != expected:
		_remove_file(tmp_path)
		_remove_file(meta_path)
		return 0
	var tmp_file := FileAccess.open(tmp_path, FileAccess.READ)
	if tmp_file == null:
		_remove_file(tmp_path)
		_remove_file(meta_path)
		return 0
	var length := maxi(0, int(tmp_file.get_length()))
	tmp_file.close()
	return length


func _write_resume_meta(meta_path: String, rev: int, expected: String) -> void:
	var file := FileAccess.open(meta_path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({"rev": rev, "sha256": expected}))
	file.close()


func _absolute_patch_url(url: String) -> String:
	if url.begins_with("http://") or url.begins_with("https://"):
		return url
	return CloudSaveManager.SERVER_BASE_URL \
		+ ("" if url.begins_with("/") else "/") + url


func _parse_http_url(url: String) -> Dictionary:
	var scheme := "https"
	var rest := url
	var marker := url.find("://")
	if marker >= 0:
		scheme = url.substr(0, marker).to_lower()
		rest = url.substr(marker + 3)
	var slash := rest.find("/")
	var authority := rest if slash < 0 else rest.substr(0, slash)
	var path := "/" if slash < 0 else rest.substr(slash)
	var port := 443 if scheme == "https" else 80
	var host := authority
	var colon := authority.rfind(":")
	if colon >= 0:
		host = authority.substr(0, colon)
		port = maxi(1, authority.substr(colon + 1).to_int())
	return {"host": host, "port": port, "path": path, "tls": scheme == "https"}


func _begin_download(resume: int) -> void:
	_close_download_handles()
	_download_done = false
	_download_ok = false
	_download_stalled = false
	_download_seen_body = false
	_download_phase = DownloadPhase.CONNECTING
	_download_resume_from = maxi(0, resume)
	_download_written = _download_resume_from
	_download_total = _download_expected
	_download_active_msec = Time.get_ticks_msec()
	_download_request_path = ""
	_download_request_headers = PackedStringArray()
	_download_client = HTTPClient.new()

	var parsed := _parse_http_url(_absolute_patch_url(
		String(_download_patch.get("url", ""))))
	var host := String(parsed.get("host", ""))
	var port := int(parsed.get("port", 443))
	_download_request_path = String(parsed.get("path", "/"))
	_download_request_headers = PackedStringArray()
	if _download_resume_from > 0 and _download_expected > 0 \
			and _download_resume_from < _download_expected:
		_download_request_headers.append("Range: bytes=%d-" % _download_resume_from)

	var err: int = OK
	if bool(parsed.get("tls", false)):
		err = _download_client.connect_to_host(host, port, TLSOptions.client())
	else:
		err = _download_client.connect_to_host(host, port)
	if err != OK:
		_fail_download("天道卷册接引失败，请重连后重试")
		return
	_downloading = true
	_update_download_progress()


func _wait_download_done() -> void:
	while not _download_done:
		await get_tree().process_frame


func _fail_download(message: String) -> void:
	_close_download_handles()
	_downloading = false
	_download_phase = DownloadPhase.DONE
	_download_ok = false
	_download_done = true
	if _last_error == "":
		_last_error = message


func _complete_download_success() -> void:
	_close_download_handles()
	_downloading = false
	_download_phase = DownloadPhase.DONE
	_download_ok = true
	_download_done = true


func _close_download_handles() -> void:
	if _download_file != null:
		_download_file.flush()
		_download_file.close()
		_download_file = null
	if _download_client != null:
		_download_client.close()
		_download_client = null


func _handle_range_not_satisfiable() -> void:
	var expected := String(_download_patch.get("sha256", "")).strip_edges().to_lower()
	if FileAccess.file_exists(_download_tmp) and expected != "" \
			and FileAccess.get_sha256(_download_tmp).to_lower() == expected:
		_complete_download_success()
		return
	_remove_file(_download_tmp)
	_remove_file(_download_meta_path)
	_write_resume_meta(_download_meta_path, int(_download_patch.get("rev", 0)), expected)
	_begin_download(0)


func _cleanup_patch_files(keep_filename: String) -> void:
	var dir := DirAccess.open(PATCH_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if not dir.current_is_dir() and name != keep_filename:
			var is_old_pck := name.begins_with("patch_") and name.ends_with(".pck")
			var is_temp := name.ends_with(".tmp") or name.ends_with(".tmp.meta")
			if is_old_pck or is_temp:
				DirAccess.remove_absolute(ProjectSettings.globalize_path(
					PATCH_DIR + "/" + name))
		name = dir.get_next()
	dir.list_dir_end()


func _remove_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


# ---------------------------------------------------------------- 进度 / 文案

func _process(_delta: float) -> void:
	if not _downloading or _download_client == null:
		return
	var now := Time.get_ticks_msec()
	if now - _download_active_msec >= DOWNLOAD_STALL_TIMEOUT_MS:
		_cancel_stalled_download()
		return

	_download_client.poll()
	var status := _download_client.get_status()
	match status:
		HTTPClient.STATUS_RESOLVING, HTTPClient.STATUS_CONNECTING:
			return
		HTTPClient.STATUS_CANT_RESOLVE, HTTPClient.STATUS_CANT_CONNECT, \
		HTTPClient.STATUS_CONNECTION_ERROR, HTTPClient.STATUS_TLS_HANDSHAKE_ERROR:
			_fail_download("天道卷册接引失败，请重连后重试")
			return
		HTTPClient.STATUS_CONNECTED:
			if _download_phase == DownloadPhase.CONNECTING:
				var err := _download_client.request(HTTPClient.METHOD_GET,
					_download_request_path, _download_request_headers)
				if err != OK:
					_fail_download("天道卷册接引失败，请重连后重试")
					return
				_download_phase = DownloadPhase.REQUESTING
			elif _download_phase == DownloadPhase.BODY:
				_complete_download_success()
			return
		HTTPClient.STATUS_REQUESTING:
			_download_phase = DownloadPhase.REQUESTING
			return
		HTTPClient.STATUS_BODY:
			if _download_phase != DownloadPhase.BODY:
				if not _begin_body():
					return
			_pump_body_chunks()
		HTTPClient.STATUS_DISCONNECTED:
			if _download_seen_body:
				_complete_download_success()
			elif _download_phase != DownloadPhase.CONNECTING:
				_fail_download("天道卷册接引失败，请重连后重试")
		_:
			return


func _begin_body() -> bool:
	var code := _download_client.get_response_code()
	if code == 416:
		_handle_range_not_satisfiable()
		return false
	if code < 200 or code >= 300:
		_fail_download("天道卷册下载未成，请重连后重试")
		return false

	var body_length := _download_client.get_response_body_length()
	if code == 206:
		# 206：仅追加到已缓存字节之后；总量以清单大小为准
		_download_file = FileAccess.open(_download_tmp, FileAccess.READ_WRITE)
		if _download_file == null:
			_fail_download("天道卷册接引失败，请重连后重试")
			return false
		_download_file.seek_end()
		_download_written = _resume_from_file()
		_download_total = _download_expected
		if _download_total <= 0 and body_length > 0:
			_download_total = _download_written + body_length
	else:
		# 200：服务端不支持续传，清空旧残片从 0 重写
		_download_resume_from = 0
		_download_written = 0
		_download_file = FileAccess.open(_download_tmp, FileAccess.WRITE)
		if _download_file == null:
			_fail_download("天道卷册接引失败，请重连后重试")
			return false
		_download_total = _download_expected
		if _download_total <= 0 and body_length > 0:
			_download_total = body_length
	_download_expected = _download_total
	_download_phase = DownloadPhase.BODY
	_download_seen_body = true
	_download_active_msec = Time.get_ticks_msec()
	_update_download_progress()
	return true


func _resume_from_file() -> int:
	var file := FileAccess.open(_download_tmp, FileAccess.READ)
	if file == null:
		return _download_resume_from
	var length := maxi(0, int(file.get_length()))
	file.close()
	return length


func _pump_body_chunks() -> void:
	for _i in range(HTTP_CHUNKS_PER_FRAME):
		var chunk := _download_client.read_response_body_chunk()
		if chunk.is_empty():
			break
		if _download_file == null:
			_fail_download("天道卷册接引失败，请重连后重试")
			return
		if not _download_file.store_buffer(chunk):
			_fail_download("天道卷册落卷失败，请重连后重试")
			return
		_download_written += chunk.size()
		_download_active_msec = Time.get_ticks_msec()
	_update_download_progress()
	if _download_total > 0 and _download_written >= _download_total:
		_complete_download_success()


func _update_download_progress() -> void:
	var size := _download_written
	var ratio := 0.0
	if _download_expected > 0:
		ratio = clampf(float(size) / float(_download_expected), 0.0, 1.0)
	_set_progress(_download_base + _download_span * ratio)
	_set_status(_download_status_text(size))


func _cancel_stalled_download() -> void:
	if not _downloading:
		return
	_download_stalled = true
	# 保留 .tmp + .meta：重试时直接用 Range 续传
	_fail_download(UPDATE_RETRY_TEXT)


## 下载量化文案（纯函数，便于验证；不含任何状态改写）
func _download_status_text(size: int) -> String:
	if _download_expected > 0:
		var ratio := clampf(float(size) / float(_download_expected), 0.0, 1.0)
		return "%s (%s / %s · %d%%)" % [_download_label,
			_format_size(size), _format_size(_download_expected), int(round(ratio * 100.0))]
	return "%s (已摹 %s)" % [_download_label, _format_size(size)]


func _format_size(bytes: int) -> String:
	if bytes >= 1024 * 1024:
		return "%.1f MB" % (float(bytes) / 1048576.0)
	if bytes >= 1024:
		return "%.0f KB" % (float(bytes) / 1024.0)
	return "%d B" % bytes


## 进度统一 0.25s EASE_OUT 缓动；返回 Tween 供 _finish 等真正拉满后再切场
func _set_progress(value: float) -> Tween:
	if _progress == null:
		return null
	var target := clampf(value, 0.0, 100.0)
	# 收尾时只接受满格；残留在途的下载轮询不得 kill 掉 _finish 正在 await 的 Tween
	if _finishing and not is_equal_approx(target, 100.0):
		return null
	if is_equal_approx(_progress.value, target):
		return null
	if _progress_tween != null and _progress_tween.is_valid():
		_progress_tween.kill()
	_progress_tween = create_tween()
	_progress_tween.tween_property(_progress, "value", target, PROGRESS_TWEEN_TIME) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	return _progress_tween


func _set_status(text_value: String) -> void:
	if _status != null:
		_status.text = text_value


## 编辑器 F5 调试：完全不碰热更，只展示本地源码版本
func _is_editor_debug() -> bool:
	return OS.has_feature("editor")


func _editor_version_text() -> String:
	return "v%s · 本地调试" % ThemeBuilder.APP_DISPLAY_VERSION


## 当前有效补丁卷数：底包基准与已安装本地卷取较大者
func _effective_patch_rev() -> int:
	return maxi(BASE_PATCH_REV, int(_state.get("current_patch_rev", 0)))


func _needs_download(latest_rev: int) -> bool:
	return latest_rev > _effective_patch_rev()


## 小于等于底包基准的旧 .pck 已无意义，禁止挂载并清理
func _should_mount_local_rev(rev: int) -> bool:
	return rev > BASE_PATCH_REV


func _version_text() -> String:
	if _is_editor_debug():
		return _editor_version_text()
	var rev := 0
	if _state.has("current_patch_rev"):
		rev = int(_state.get("current_patch_rev", 0))
	if rev <= 0:
		rev = CloudSaveManager.get_current_patch_rev()
	var patch_text := "天道初开" if rev <= 0 else "天道第 %d 卷" % rev
	return "v%s · %s" % [ThemeBuilder.APP_DISPLAY_VERSION, patch_text]
