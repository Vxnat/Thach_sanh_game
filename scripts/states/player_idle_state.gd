class_name PlayerIdleState
extends PlayerState
## Trạng thái đứng yên trên mặt đất.


func enter(_prev_state: StringName, _msg: Dictionary = {}) -> void:
	player.play_locomotion_anim(&"idle")


func physics_update(delta: float) -> void:
	if player.try_drop_through_one_way():
		state_machine.transition_to(&"Fall", {"step_delta": delta})
		return

	if player.has_buffered_jump() and player.can_jump():
		state_machine.transition_to(&"Jump", {"step_delta": delta})
		return

	if not player.is_on_floor():
		state_machine.transition_to(&"Fall", {"step_delta": delta})
		return

	var axis: float = player.get_move_input_axis()
	if absf(axis) > 0.01:
		player.update_facing(axis)

	if player.has_buffered_dash() and player.can_dash():
		state_machine.transition_to(&"Dash")
		return

	if player.has_buffered_attack() and player.is_on_floor():
		state_machine.transition_to(&"Attack")
		return

	if absf(axis) > 0.01:
		state_machine.transition_to(&"Run", {"step_delta": delta})
		return

	player.apply_horizontal_movement(0.0, player.ground_accel, player.ground_decel, delta)
	player.apply_gravity(delta)
	player.move_and_slide()

	if not player.is_on_floor():
		state_machine.transition_to(&"Fall")

