class_name DialogueBox
extends CanvasLayer
## Hộp thoại đọc dữ liệu JSON từ DialogueDatabase, hỗ trợ phân nhánh theo story_flags & Ngày/Đêm.

@onready var _speaker_label: Label = $RootControl/DialogPanel/VBox/HeaderRow/SpeakerLabel
@onready var _page_label: Label = $RootControl/DialogPanel/VBox/HeaderRow/PageLabel
@onready var _text_label: Label = $RootControl/DialogPanel/VBox/DialogueTextLabel
@onready var _btn_next: Button = $RootControl/DialogPanel/VBox/FooterRow/BtnNext
@onready var _btn_skip: Button = $RootControl/DialogPanel/VBox/FooterRow/BtnSkip

var _active_dialogue_id: String = ""
var _active_branch_id: String = ""
var _active_speaker_name: String = ""
var _active_lines: PackedStringArray = PackedStringArray()
var _active_set_flags: Dictionary = {}
var _current_line_idx: int = 0
var _opened_process_frame: int = -1
var _last_advance_process_frame: int = -1


func _ready() -> void:
	layer = 22
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not is_in_group(&"dialogue_box"):
		add_to_group(&"dialogue_box")
	visible = false

	_btn_next.pressed.connect(advance_line)
	_btn_skip.pressed.connect(func() -> void:
		close_dialogue(true)
	)

	if not EventBus.dialogue_requested.is_connected(_on_dialogue_requested):
		EventBus.dialogue_requested.connect(_on_dialogue_requested)


func _process(_delta: float) -> void:
	if not visible:
		return
	var frame_now: int = Engine.get_process_frames()
	if frame_now <= _opened_process_frame or frame_now == _last_advance_process_frame:
		return
	if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("ui_accept"):
		advance_line()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if Engine.get_process_frames() <= _opened_process_frame:
		return
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close_dialogue(true)


func _on_dialogue_requested(dialogue_id: String, _speaker: Node) -> void:
	open_dialogue(dialogue_id)


func open_dialogue(dialogue_id: String) -> void:
	var resolved: Dictionary = DialogueDatabase.resolve_dialogue(dialogue_id)
	var lines: PackedStringArray = resolved.get("lines", PackedStringArray()) as PackedStringArray
	if not bool(resolved.get("found", false)) or lines.is_empty():
		push_warning("DialogueBox: không tìm thấy nội dung hội thoại hợp lệ cho ID '%s'." % dialogue_id)
		return

	_active_dialogue_id = String(resolved.get("dialogue_id", dialogue_id))
	_active_branch_id = String(resolved.get("branch_id", ""))
	_active_speaker_name = String(resolved.get("speaker_name", ""))
	_active_lines = lines
	_active_set_flags = (resolved.get("set_flags", {}) as Dictionary).duplicate(true)
	_current_line_idx = 0
	_opened_process_frame = Engine.get_process_frames()
	_last_advance_process_frame = -1

	visible = true
	GameState.set_ui_modal_open(true)
	_refresh_view()
	if _btn_next != null:
		_btn_next.grab_focus()


func advance_line() -> void:
	if not visible:
		return
	var frame_now: int = Engine.get_process_frames()
	if frame_now <= _opened_process_frame or frame_now == _last_advance_process_frame:
		return
	_last_advance_process_frame = frame_now

	if _current_line_idx + 1 < _active_lines.size():
		_current_line_idx += 1
		_refresh_view()
	else:
		close_dialogue(true)


func close_dialogue(apply_flags: bool = true) -> void:
	if not visible:
		return
	var finished_id: String = _active_dialogue_id
	var flags_to_apply: Dictionary = _active_set_flags.duplicate(true)

	visible = false
	_active_dialogue_id = ""
	_active_branch_id = ""
	_active_speaker_name = ""
	_active_lines = PackedStringArray()
	_active_set_flags.clear()
	_current_line_idx = 0

	if apply_flags:
		for flag_k: Variant in flags_to_apply.keys():
			GameState.set_story_flag(String(flag_k), flags_to_apply[flag_k])

	GameState.set_ui_modal_open(false)
	if finished_id != "":
		EventBus.dialogue_finished.emit(finished_id)


func _refresh_view() -> void:
	var total: int = _active_lines.size()
	if _speaker_label != null:
		_speaker_label.text = _active_speaker_name
	if _page_label != null:
		_page_label.text = "%d/%d" % [mini(_current_line_idx + 1, total), total]
	if _text_label != null:
		_text_label.text = _active_lines[_current_line_idx] if _current_line_idx < total else ""
	if _btn_next != null:
		_btn_next.text = "Xong ✓" if _current_line_idx + 1 >= total else "Tiếp ▶"


func is_open() -> bool:
	return visible


func get_current_speaker_name() -> String:
	return _active_speaker_name


func get_current_line_text() -> String:
	if _current_line_idx >= 0 and _current_line_idx < _active_lines.size():
		return _active_lines[_current_line_idx]
	return ""


func get_current_line_index() -> int:
	return _current_line_idx


func get_total_lines() -> int:
	return _active_lines.size()


func get_active_branch_id() -> String:
	return _active_branch_id

