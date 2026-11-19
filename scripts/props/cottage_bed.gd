class_name CottageBed
extends Node2D
## Giường Nhà Tranh Thạch Sanh: ngủ đổi Sáng <-> Đêm, hồi đầy sức và lưu game qua SaveManager.

@export var save_slot_override: String = ""

@onready var _interactable: InteractableArea = $InteractableArea


func _ready() -> void:
	if _interactable != null and not _interactable.interacted.is_connected(_on_interacted):
		_interactable.interacted.connect(_on_interacted)


func _on_interacted(player_node: Node2D) -> void:
	TimeManager.sleep_toggle_day_night()
	GameState.rest_at_village()

	if player_node != null:
		var hc: HealthComponent = player_node.get_node_or_null("HealthComponent") as HealthComponent
		if hc != null:
			hc.revive_full()
		if player_node is Player:
			var p: Player = player_node as Player
			p.current_mp = p.max_mp
			p.mp_changed.emit(p.current_mp, p.max_mp)

	GameState.current_stage_id = "hub_loc_tri"
	GameState.last_spawn_id = &"cottage_bed"
	var slot: String = save_slot_override if save_slot_override != "" else SaveManager.DEFAULT_SAVE_BASE
	var saved_ok: bool = SaveManager.save_game(slot)
	if saved_ok:
		EventBus.notification_requested.emit("Đã nghỉ tới %s — Hồi đầy sức & Lưu game!" % TimeManager.get_phase_name_vi())
	else:
		EventBus.notification_requested.emit("Đã nghỉ tới %s (Lưu game thất bại)." % TimeManager.get_phase_name_vi())

