class_name TravelUI
extends CanvasLayer
## Giao diện bản đồ dịch chuyển nhanh của Anh Xa Phu giữa Làng Lộc Trĩ và các màn chơi.

const STAGE_LABELS_VI: Dictionary = {
	"hub_loc_tri": "Làng Lộc Trĩ",
	"test_sandbox": "Bìa Rừng Tập Luyện",
	"stage_01": "Màn 1: Rừng Ven Làng",
}

@export var travel_fade_duration: float = 0.16

@onready var _location_label: Label = $RootControl/CenterPanel/VBox/LocationLabel
@onready var _greeting_label: Label = $RootControl/CenterPanel/VBox/GreetingLabel
@onready var _btn_hub: Button = $RootControl/CenterPanel/VBox/RouteBox/BtnTravel_hub_loc_tri
@onready var _btn_sandbox: Button = $RootControl/CenterPanel/VBox/RouteBox/BtnTravel_test_sandbox
@onready var _btn_stage_01: Button = $RootControl/CenterPanel/VBox/RouteBox/BtnTravel_stage_01
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
		_travel_to("stage_01")
	)
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
	if not _btn_sandbox.disabled:
		_btn_sandbox.grab_focus()
	elif not _btn_hub.disabled:
		_btn_hub.grab_focus()


func close_travel() -> void:
	visible = false
	GameState.set_ui_modal_open(false)


func _on_talk_pressed() -> void:
	close_travel()
	EventBus.dialogue_requested.emit("xa_phu", null)


func _travel_to(target_stage_id: String) -> void:
	if target_stage_id == GameState.current_stage_id:
		return
	var scene_path: String = String(GameState.STAGE_PATHS.get(target_stage_id, ""))
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		return
	close_travel()
	SceneRouter.transition_to_stage(target_stage_id, &"xa_phu", travel_fade_duration)


func _refresh_view() -> void:
	var cur_id: String = GameState.current_stage_id
	var cur_name: String = STAGE_LABELS_VI.get(cur_id, cur_id) as String
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
		var stage01_ready: bool = GameState.unlocked_stages.has("stage_01") and stage01_path != "" and ResourceLoader.exists(stage01_path)
		var in_stage_01: bool = (cur_id == "stage_01")
		if not stage01_ready:
			_btn_stage_01.text = "Màn 1: Rừng Ven Làng (Mở ở GĐ 3)"
			_btn_stage_01.disabled = true
		elif in_stage_01:
			_btn_stage_01.text = "Màn 1: Rừng Ven Làng — Đang ở đây"
			_btn_stage_01.disabled = true
		else:
			_btn_stage_01.text = "Màn 1: Rừng Ven Làng"
			_btn_stage_01.disabled = false

