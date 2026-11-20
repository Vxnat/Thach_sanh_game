class_name PlayerJumpState
extends PlayerState
## Trạng thái nhảy lên với Variable Jump Height và hỗ trợ bật nảy từ Pogo Bounce.

var _jump_cut_applied: bool = false


func enter(_prev_state: StringName, msg: Dictionary = {}) -> void:
	if bool(msg.get("from_pogo", false)):
		_jump_cut_applied = true
		AudioManager.play_sfx(&"jump", 1.10, 1.16)
	else:
		_jump_cut_applied = false
		player.consume_jump()
		AudioManager.play_sfx(&"jump", 0.96, 1.05)
	player.reset_combo()
	player.play_locomotion_anim(&"jump")
	if msg.has("step_delta"):
		physics_update(float(msg["step_delta"]))


func physics_update(delta: float) -> void:
	var axis: float = player.get_move_input_axis()
	player.update_facing(axis)

	if player.has_buffered_dash() and player.can_dash():
		state_machine.transition_to(&"Dash")
		return

	var relic_id: StringName = player.try_consume_buffered_relic()
	if relic_id != &"":
		state_machine.transition_to(&"RelicCast", {"relic_id": relic_id})
		return

	if player.has_buffered_attack():
		state_machine.transition_to(&"AirAttack")
		return

	player.apply_horizontal_movement(axis, player.air_accel, player.air_decel, delta)

	if not Input.is_action_pressed("jump") and player.velocity.y < 0.0 and not _jump_cut_applied:
		player.velocity.y *= player.jump_cut_multiplier
		_jump_cut_applied = true

	player.apply_gravity(delta)
	player.move_and_slide()

	if player.is_on_floor() and player.velocity.y >= 0.0:
		if absf(axis) > 0.01:
			state_machine.transition_to(&"Run")
		else:
			state_machine.transition_to(&"Idle")
	elif player.velocity.y >= 0.0:
		state_machine.transition_to(&"Fall")
