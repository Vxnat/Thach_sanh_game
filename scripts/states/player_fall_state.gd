class_name PlayerFallState
extends PlayerState
## Trạng thái rơi xuống, hỗ trợ Coyote Time, Jump Buffer, Dash và AirAttack.


func enter(_prev_state: StringName, msg: Dictionary = {}) -> void:
	player.play_locomotion_anim(&"fall")
	if msg.has("step_delta"):
		physics_update(float(msg["step_delta"]))


func physics_update(delta: float) -> void:
	if player.has_buffered_jump() and player.can_jump():
		state_machine.transition_to(&"Jump", {"step_delta": delta})
		return

	var axis: float = player.get_move_input_axis()
	player.update_facing(axis)

	if player.has_buffered_dash() and player.can_dash():
		state_machine.transition_to(&"Dash")
		return

	if player.has_buffered_attack():
		state_machine.transition_to(&"AirAttack")
		return

	player.apply_horizontal_movement(axis, player.air_accel, player.air_decel, delta)
	player.apply_gravity(delta)
	player.move_and_slide()

	if player.is_on_floor():
		if player.has_buffered_jump():
			state_machine.transition_to(&"Jump")
		elif absf(axis) > 0.01:
			state_machine.transition_to(&"Run")
		else:
			state_machine.transition_to(&"Idle")
