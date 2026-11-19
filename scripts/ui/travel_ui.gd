class_name TravelUI
extends CanvasLayer
## Giao diện bản đồ dịch chuyển nhanh của Anh Xa Phu giữa Làng Lộc Trĩ và các màn chơi.

const STAGE_LABELS_VI: Dictionary = {
	"hub_loc_tri": "Làng Lộc Trĩ",
	"test_sandbox": "Bìa Rừng Tập Luyện",
	"stage_01": "Màn 1: Rừng Ven Làng",
	"stage_02": "Màn 2: Nhị Trụ Tùng",
}

@export var travel_fade_duration: float = 0.16

@onready var _location_label: Label = $RootControl/CenterPanel/VBox/LocationLabel
@onready var _greeting_label: Label = $RootControl/CenterPanel/VBox/GreetingLabel
@onready var _btn_hub: Button = $RootControl/CenterPanel/VBox/RouteBox/BtnTravel_hub_loc_tri
@onready var _btn_sandbox: Button = $RootControl/CenterPanel/VBox/RouteBox/BtnTravel_test_sandbox
@onready var _btn_stage_01: Button = $RootControl/CenterPanel/VBox/RouteBox/BtnTravel_stage_01
@onready var _btn_stage_02: Button = $RootControl/CenterPanel/VBox/RouteBox/BtnTravel_stage_02
@onready var _btn_talk: Button = $RootControl/CenterPanel/VBox/HeaderRow/BtnTalk
@onready var _btn_close: Button = $RootControl/CenterPanel/VBox/HeaderRow/BtnClose


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not is_in_group(&"travel_ui"):
		add_to_group(&"travel_ui")
	visible = false

	_btn_hub.pressed.connect(func() -> void:
		_travel_to("hub_loc_tri")
	)
	_btn_sandbox.pressed.connect(func() -> void:
		_travel_to("test_sandbox")
	)
	_btn_stage_01.pressed.connect(func() -> void:
		_travel_to_spawn("stage_01", &"xa_phu")
	)
	_btn_stage_02.pressed.connect(_on_stage_02_pressed)
	_btn_talk.pressed.connect(_on_talk_pressed)
	_btn_close.pressed.connect(close_travel)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close_travel()


func open_travel() -> void:
	visible = true
	GameState.set_ui_modal_open(true)
	_refresh_view()
	if not _btn_stage_01.disabled:
		_btn_stage_01.grab_focus()
	elif not _btn_stage_02.disabled:
		_btn_stage_02.grab_focus()
	elif not _btn_hub.disabled:
		_btn_hub.grab_focus()
	elif not _btn_sandbox.disabled:
		_btn_sandbox.grab_focus()


func close_travel() -> void:
	visible = false
	GameState.set_ui_modal_open(false)


func _on_talk_pressed() -> void:
	close_travel()
	EventBus.dialogue_requested.emit("xa_phu", null)


func _on_stage_02_pressed() -> void:
	if not GameState.is_stage_unlocked("stage_02"):
		return
	var stage02_path: String = String(GameState.STAGE_PATHS.get("stage_02", ""))
	if stage02_path != "" and ResourceLoader.exists(stage02_path):
		_travel_to_spawn("stage_02", &"xa_phu")
	else:
		_travel_to_spawn("stage_01", &"east_outpost")


func _travel_to(target_stage_id: String) -> void:
	_travel_to_spawn(target_stage_id, &"xa_phu")


func _travel_to_spawn(target_stage_id: String, target_spawn_id: StringName) -> void:
	if target_stage_id == GameState.current_stage_id:
		if target_stage_id != "stage_01":
			return
		var at_east: bool = _is_at_stage_01_east()
		if (target_spawn_id == &"east_outpost" and at_east) or (target_spawn_id != &"east_outpost" and not at_east):
			return

	var scene_path: String = String(GameState.STAGE_PATHS.get(target_stage_id, ""))
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		return
	close_travel()
	SceneRouter.transition_to_stage(target_stage_id, target_spawn_id, travel_fade_duration)


func _is_at_stage_01_east() -> bool:
	if GameState.current_stage_id != "stage_01":
		return false
	for n: Node in get_tree().get_nodes_in_group(&"player"):
		var p2d: Node2D = n as Node2D
		if p2d != null and p2d.is_inside_tree():
			return p2d.global_position.x >= 2100.0
	return GameState.last_spawn_id == &"east_outpost"


func _refresh_view() -> void:
	var cur_id: String = GameState.current_stage_id
	var at_stage_01_east: bool = _is_at_stage_01_east()
	var cur_name: String = "Đèo Nhị Trụ Tùng (Cuối Màn 1)" if at_stage_01_east else (STAGE_LABELS_VI.get(cur_id, cur_id) as String)
	if _location_label != null:
		_location_label.text = "Vị trí hiện tại: %s" % cur_name
	if _greeting_label != null:
		_greeting_label.text = "\"%s\"" % DialogueDatabase.get_greeting("xa_phu")

	if _btn_hub != null:
		var in_hub: bool = (cur_id == "hub_loc_tri")
		_btn_hub.text = "Làng Lộc Trĩ (Khu An Toàn)" + (" — Đang ở đây" if in_hub else "")
		_btn_hub.disabled = in_hub

	if _btn_sandbox != null:
		var in_sandbox: bool = (cur_id == "test_sandbox")
		_btn_sandbox.text = "Bìa Rừng Tập Luyện (Sandbox)" + (" — Đang ở đây" if in_sandbox else "")
		_btn_sandbox.disabled = in_sandbox

	if _btn_stage_01 != null:
		var stage01_path: String = String(GameState.STAGE_PATHS.get("stage_01", ""))
		var stage01_ready: bool = GameState.is_stage_unlocked("stage_01") and stage01_path != "" and ResourceLoader.exists(stage01_path)
		var in_stage_01_west: bool = (cur_id == "stage_01" and not at_stage_01_east)
		if not stage01_ready:
			_btn_stage_01.text = "Màn 1: Rừng Ven Làng (Chưa mở)"
			_btn_stage_01.disabled = true
		elif in_stage_01_west:
			_btn_stage_01.text = "Màn 1: Rừng Ven Làng — Đang ở đây"
			_btn_stage_01.disabled = true
		else:
			_btn_stage_01.text = "Màn 1: Rừng Ven Làng (Đầu Rừng)"
			_btn_stage_01.disabled = false

	if _btn_stage_02 != null:
		var stage02_unlocked: bool = GameState.is_stage_unlocked("stage_02")
		var stage02_path: String = String(GameState.STAGE_PATHS.get("stage_02", ""))
		var stage02_scene_ready: bool = stage02_path != "" and ResourceLoader.exists(stage02_path)
		if not stage02_unlocked:
			_btn_stage_02.text = "Đèo Nhị Trụ Tùng (Khóa — Diệt quái gác cổng)"
			_btn_stage_02.disabled = true
		elif stage02_scene_ready:
			var in_stage_02: bool = (cur_id == "stage_02")
			_btn_stage_02.text = "Màn 2: Nhị Trụ Tùng" + (" — Đang ở đây" if in_stage_02 else "")
			_btn_stage_02.disabled = in_stage_02
		elif at_stage_01_east:
			_btn_stage_02.text = "Đèo Nhị Trụ Tùng — Đang ở đây"
			_btn_stage_02.disabled = true
		else:
			_btn_stage_02.text = "Đèo Nhị Trụ Tùng (Trạm Cuối Màn 1)"
			_btn_stage_02.disabled = false

