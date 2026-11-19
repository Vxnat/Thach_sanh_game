extends Node
## Hệ thống Lưu/Tải JSON an toàn (SaveManager Autoload): save_version, ID ổn định, ghi .tmp, backup .bak.

const CURRENT_SAVE_VERSION: int = 1
const DEFAULT_SAVE_BASE: String = "user://save_slot_1"


func get_json_path(slot_base: String = DEFAULT_SAVE_BASE) -> String:
	return slot_base + ".json"


func get_tmp_path(slot_base: String = DEFAULT_SAVE_BASE) -> String:
	return slot_base + ".tmp"


func get_bak_path(slot_base: String = DEFAULT_SAVE_BASE) -> String:
	return slot_base + ".bak"


func has_save(slot_base: String = DEFAULT_SAVE_BASE) -> bool:
	return FileAccess.file_exists(get_json_path(slot_base)) or FileAccess.file_exists(get_bak_path(slot_base))


func delete_save_files(slot_base: String) -> void:
	for p: String in [get_json_path(slot_base), get_tmp_path(slot_base), get_bak_path(slot_base)]:
		var abs_p: String = ProjectSettings.globalize_path(p)
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(abs_p)


func migrate_save_data(data: Dictionary) -> Dictionary:
	if not data.has("save_version"):
		return {}
	var raw_ver: Variant = data.get("save_version")
	if not (raw_ver is int or raw_ver is float):
		return {}
	var ver: int = int(raw_ver)
	if float(raw_ver) != float(ver):
		return {}
	if ver <= 0 or ver > CURRENT_SAVE_VERSION:
		return {}

	var migrated: Dictionary = data.duplicate(true)
	while ver < CURRENT_SAVE_VERSION:
		# Chỗ nâng cấp tuần tự khi CURRENT_SAVE_VERSION tăng trong tương lai (v1 -> v2 -> ...)
		ver += 1
		migrated["save_version"] = ver

	return migrated


func _validate_save_dict(data: Dictionary) -> bool:
	if data.is_empty():
		return false
	if int(data.get("save_version", -1)) != CURRENT_SAVE_VERSION:
		return false
	if not (data.get("player") is Dictionary) or not (data.get("inventory") is Dictionary) or not (data.get("world") is Dictionary):
		return false

	var player_d: Dictionary = data["player"] as Dictionary
	var inv_d: Dictionary = data["inventory"] as Dictionary
	var world_d: Dictionary = data["world"] as Dictionary

	for req_p: String in ["level", "max_hp", "max_mp", "pocket_gold", "equipped_weapon_id"]:
		if not player_d.has(req_p):
			return false
	for req_i: String in ["owned_weapons", "materials", "belt_hp_count", "belt_mp_count"]:
		if not inv_d.has(req_i):
			return false
	for req_w: String in ["opened_chests", "unlocked_stages", "story_flags", "current_stage_id"]:
		if not world_d.has(req_w):
			return false

	var eq_id: StringName = StringName(String(player_d.get("equipped_weapon_id", "")))
	if not GameState.has_weapon_id(eq_id):
		return false

	# Cấm lưu đường dẫn res:// trong file save theo AGENTS.md §4.1.4
	if JSON.stringify(data).find("res://") != -1:
		return false

	return true


func _build_save_payload() -> Dictionary:
	var payload: Dictionary = {
		"save_version": CURRENT_SAVE_VERSION,
		"saved_at_unix": int(Time.get_unix_time_from_system()),
		"time_seconds": TimeManager.get_time_seconds(),
	}
	var state_dict: Dictionary = GameState.to_save_dict()
	for k: Variant in state_dict.keys():
		payload[k] = state_dict[k]
	return payload


func _try_read_valid_save(path_str: String) -> Dictionary:
	if not FileAccess.file_exists(path_str):
		return {}
	var file: FileAccess = FileAccess.open(path_str, FileAccess.READ)
	if file == null:
		return {}
	var raw_text: String = file.get_as_text()
	file.close()
	if raw_text.strip_edges().is_empty():
		return {}

	var json: JSON = JSON.new()
	if json.parse(raw_text) != OK:
		return {}
	var parsed: Variant = json.data
	if not (parsed is Dictionary):
		return {}

	var migrated: Dictionary = migrate_save_data(parsed as Dictionary)
	if not _validate_save_dict(migrated):
		return {}
	return migrated


func _write_text_file(path_str: String, content: String) -> bool:
	var file: FileAccess = FileAccess.open(path_str, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(content)
	file.flush()
	file.close()
	return true


func save_game(slot_base: String = DEFAULT_SAVE_BASE) -> bool:
	var tmp_path: String = get_tmp_path(slot_base)
	var json_path: String = get_json_path(slot_base)
	var bak_path: String = get_bak_path(slot_base)

	var payload: Dictionary = _build_save_payload()
	if not _validate_save_dict(payload):
		EventBus.save_completed.emit(false, "Dữ liệu lưu không hợp lệ.")
		return false

	var json_text: String = JSON.stringify(payload, "\t")
	if not _write_text_file(tmp_path, json_text):
		EventBus.save_completed.emit(false, "Không thể ghi file tạm .tmp.")
		return false

	# Xác minh bản .tmp mới ghi hợp lệ 100% trước khi xoay vòng backup & thay file chính
	var verified_tmp: Dictionary = _try_read_valid_save(tmp_path)
	if verified_tmp.is_empty():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp_path))
		EventBus.save_completed.emit(false, "Xác minh file .tmp thất bại.")
		return false

	if FileAccess.file_exists(json_path):
		var old_valid: Dictionary = _try_read_valid_save(json_path)
		if not old_valid.is_empty():
			var old_file: FileAccess = FileAccess.open(json_path, FileAccess.READ)
			if old_file != null:
				var old_text: String = old_file.get_as_text()
				old_file.close()
				_write_text_file(bak_path, old_text)

	var abs_tmp: String = ProjectSettings.globalize_path(tmp_path)
	var abs_json: String = ProjectSettings.globalize_path(json_path)
	var rename_err: Error = DirAccess.rename_absolute(abs_tmp, abs_json)
	if rename_err != OK:
		if FileAccess.file_exists(json_path):
			DirAccess.remove_absolute(abs_json)
			rename_err = DirAccess.rename_absolute(abs_tmp, abs_json)
	if rename_err != OK:
		EventBus.save_completed.emit(false, "Không thể ghi đè file save chính.")
		return false

	EventBus.save_completed.emit(true, "Đã lưu game an toàn.")
	return true


func load_game(slot_base: String = DEFAULT_SAVE_BASE) -> Dictionary:
	var json_path: String = get_json_path(slot_base)
	var bak_path: String = get_bak_path(slot_base)

	var main_data: Dictionary = _try_read_valid_save(json_path)
	if not main_data.is_empty() and GameState.from_save_dict(main_data):
		TimeManager.set_time_seconds(float(main_data.get("time_seconds", TimeManager.PHASE_DAWN_END)))
		return {
			"ok": true,
			"recovered_from_backup": false,
			"used_default": false,
			"error": "",
		}

	var bak_data: Dictionary = _try_read_valid_save(bak_path)
	if not bak_data.is_empty() and GameState.from_save_dict(bak_data):
		TimeManager.set_time_seconds(float(bak_data.get("time_seconds", TimeManager.PHASE_DAWN_END)))
		var bak_file: FileAccess = FileAccess.open(bak_path, FileAccess.READ)
		if bak_file != null:
			var bak_text: String = bak_file.get_as_text()
			bak_file.close()
			_write_text_file(json_path, bak_text)
		EventBus.notification_requested.emit("File save chính bị lỗi, đã tự khôi phục từ bản sao lưu (.bak).")
		return {
			"ok": true,
			"recovered_from_backup": true,
			"used_default": false,
			"error": "recovered_from_backup",
		}

	GameState.reset_new_game()
	TimeManager.set_time_seconds(TimeManager.PHASE_DAWN_END)
	EventBus.notification_requested.emit("File save hỏng hoặc phiên bản không tương thích. Đã tạo lại dữ liệu mới.")
	return {
		"ok": false,
		"recovered_from_backup": false,
		"used_default": true,
		"error": "invalid_or_corrupted",
	}
