class_name HubLocTri
extends Node2D
## Cảnh Hub Làng Lộc Trĩ: tự nạp save ở lần khởi động đầu, giữ thông số ngày/đêm & SpawnPoint.

@export var auto_load_save_on_boot: bool = true


func _enter_tree() -> void:
	if auto_load_save_on_boot and not GameState.has_active_session and SaveManager.has_save():
		SaveManager.load_game()
	if not GameState.has_active_session:
		GameState.reset_new_game()


func _ready() -> void:
	if not GameState.has_active_session:
		GameState.reset_new_game()
	GameState.current_stage_id = "hub_loc_tri"
	GameState.set_ui_modal_open(false)
	AudioManager.sync_stage_audio("hub_loc_tri")

