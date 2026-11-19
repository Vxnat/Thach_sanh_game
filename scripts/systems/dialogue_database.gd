class_name DialogueDatabase
extends RefCounted
## Bộ nạp và chọn nhánh hội thoại JSON dựa theo TimeManager.is_night() và GameState.story_flags.

const DEFAULT_JSON_PATH: String = "res://data/dialogues/loc_tri_npcs.json"


static func resolve_dialogue(dialogue_id: String, json_path: String = DEFAULT_JSON_PATH) -> Dictionary:
	var fallback: Dictionary = {
		"found": false,
		"dialogue_id": dialogue_id,
		"branch_id": "",
		"speaker_name": "",
		"greeting": "",
		"lines": PackedStringArray(),
		"set_flags": {},
	}
	if dialogue_id.is_empty() or not FileAccess.file_exists(json_path):
		return fallback

	var file: FileAccess = FileAccess.open(json_path, FileAccess.READ)
	if file == null:
		return fallback
	var raw_text: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	if json.parse(raw_text) != OK:
		push_warning("DialogueDatabase: lỗi phân tích JSON tại %s: %s" % [json_path, json.get_error_message()])
		return fallback
	if not (json.data is Dictionary):
		return fallback

	var root_dict: Dictionary = json.data as Dictionary
	var dialogues_dict: Dictionary = root_dict.get("dialogues", {}) as Dictionary
	if not dialogues_dict.has(dialogue_id):
		return fallback

	var entry: Dictionary = dialogues_dict[dialogue_id] as Dictionary
	var speaker_name: String = String(entry.get("speaker_name", ""))
	var branches: Array = entry.get("branches", []) as Array

	for branch_var: Variant in branches:
		if not (branch_var is Dictionary):
			continue
		var branch: Dictionary = branch_var as Dictionary
		if not _branch_matches_conditions(branch):
			continue

		var lines_arr: PackedStringArray = PackedStringArray()
		var raw_lines: Array = branch.get("lines", []) as Array
		for line_var: Variant in raw_lines:
			lines_arr.append(String(line_var))

		var raw_set_flags: Dictionary = branch.get("set_flags", {}) as Dictionary
		return {
			"found": true,
			"dialogue_id": dialogue_id,
			"branch_id": String(branch.get("id", "")),
			"speaker_name": speaker_name,
			"greeting": String(branch.get("greeting", "")),
			"lines": lines_arr,
			"set_flags": raw_set_flags.duplicate(true),
		}

	return fallback


static func get_greeting(dialogue_id: String, json_path: String = DEFAULT_JSON_PATH) -> String:
	var data: Dictionary = resolve_dialogue(dialogue_id, json_path)
	if not bool(data.get("found", false)):
		return ""
	var greeting: String = String(data.get("greeting", ""))
	if not greeting.is_empty():
		return greeting
	var lines: PackedStringArray = data.get("lines", PackedStringArray()) as PackedStringArray
	if lines.size() > 0:
		return lines[0]
	return ""


static func _branch_matches_conditions(branch: Dictionary) -> bool:
	if branch.has("require_night"):
		var want_night: bool = bool(branch.get("require_night", false))
		if TimeManager.is_night() != want_night:
			return false

	var req_flags: Dictionary = branch.get("require_flags", {}) as Dictionary
	for flag_key_var: Variant in req_flags.keys():
		var flag_key: String = String(flag_key_var)
		var expected_val: Variant = req_flags[flag_key_var]
		var current_val: Variant = GameState.get_story_flag(flag_key, false)
		if current_val != expected_val:
			return false

	return true

