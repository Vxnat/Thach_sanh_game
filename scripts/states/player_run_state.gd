class_name PlayerRunState
extends PlayerState
## Trạng thái chạy ngang trên mặt đất.


func enter(_prev_state: StringName, msg: Dictionary = {}) -> void:
	player.play_locomotion_anim(&"run")
	if msg.has("step_delta"):
		physics_update(float(msg["step_delta"]))


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

	if absf(axis) <= 0.01 and absf(player.velocity.x) <= 1.0:
		player.velocity.x = 0.0
		state_machine.transition_to(&"Idle")
		return

	player.apply_horizontal_movement(axis, player.ground_accel, player.ground_decel, delta)
	player.apply_gravity(delta)
	player.move_and_slide()

	if not player.is_on_floor():
		state_machine.transition_to(&"Fall")
	elif absf(axis) <= 0.01 and absf(player.velocity.x) <= 1.0:
		player.velocity.x = 0.0
		state_machine.transition_to(&"Idle")

