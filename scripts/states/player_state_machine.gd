class_name PlayerStateMachine
extends Node
## Quản lý vòng đời và chuyển đổi trạng thái cho Player.

signal state_changed(from_state: StringName, to_state: StringName)

@export var initial_state: PlayerState

var current_state: PlayerState = null


func _ready() -> void:
	var owner_player: Player = get_parent() as Player
	assert(owner_player != null, "PlayerStateMachine phải là node con trực tiếp của Player.")

	for child: Node in get_children():
		var state: PlayerState = child as PlayerState
		if state != null:
			state.player = owner_player
			state.state_machine = self


func start() -> void:
	if current_state != null:
		return
	if initial_state != null:
		current_state = initial_state
		current_state.enter(&"")


func step_frame(delta: float) -> void:
	if current_state != null:
		current_state.frame_update(delta)


func step_physics(delta: float) -> void:
	if current_state != null:
		current_state.physics_update(delta)


func transition_to(target_state_name: StringName, msg: Dictionary = {}) -> void:
	var next_state: PlayerState = get_node_or_null(NodePath(target_state_name)) as PlayerState
	if next_state == null:
		push_warning("Không tìm thấy trạng thái PlayerState: %s" % String(target_state_name))
		return

	var prev_name: StringName = current_state.name if current_state != null else &""
	if current_state != null:
		current_state.exit()

	current_state = next_state
	current_state.enter(prev_name, msg)
	state_changed.emit(prev_name, target_state_name)


func get_current_state_name() -> StringName:
	return current_state.name if current_state != null else &""

