class_name PlayerAttackState
extends PlayerState
## Trạng thái đánh cận chiến dưới đất (Combo 2–3 nhịp, bước tiến theo nhịp, hủy đòn sang Dash).

var _current_step: int = 0
var _step_elapsed: float = 0.0
var _queued_next: bool = false


func enter(_prev_state: StringName, _msg: Dictionary = {}) -> void:
	var start_step: int = player.get_next_combo_step()
	_start_step(start_step)


func exit() -> void:
	player.reset_combat_state()


func _start_step(step_index: int) -> void:
	_current_step = step_index
	_step_elapsed = 0.0
	_queued_next = false
	player.consume_attack_buffer()

	var axis: float = player.get_move_input_axis()
	if absf(axis) > 0.01:
		player.update_facing(axis)

	if player.hitbox_component != null:
		player.hitbox_component.set_active(false)
		player.hitbox_component.clear_hit_targets()

	var lunge_speed: float = 0.0
	if player.equipped_weapon != null and player.equipped_weapon.combo_profile != null:
		lunge_speed = player.equipped_weapon.combo_profile.get_step_lunge_speed(step_index)
	if lunge_speed > 0.0:
		player.velocity.x = float(player.facing_direction) * lunge_speed

	var anim_name: StringName = player.prepare_ground_attack_step(step_index)
	if player.animation_player != null and player.animation_player.has_animation(anim_name):
		player.animation_player.stop()
		player.animation_player.play(anim_name)
	else:
		push_warning("Thiếu animation đánh: %s" % String(anim_name))


func physics_update(delta: float) -> void:
	_step_elapsed += delta

	var cancel_after: float = 0.04
	var max_steps: int = 1
	if player.equipped_weapon != null and player.equipped_weapon.combo_profile != null:
		cancel_after = player.equipped_weapon.combo_profile.cancel_to_dash_after_sec
		max_steps = maxi(1, player.equipped_weapon.combo_profile.max_steps)

	if _step_elapsed >= cancel_after and player.has_buffered_dash() and player.can_dash():
		state_machine.transition_to(&"Dash")
		return

	if _step_elapsed >= 0.03 and _current_step + 1 < max_steps and player.has_buffered_attack():
		_queued_next = true
		player.consume_attack_buffer()

	player.apply_horizontal_movement(0.0, player.ground_accel, player.ground_decel * 1.25, delta)
	player.apply_gravity(delta)
	player.move_and_slide()

	if player.animation_player == null or not player.animation_player.is_playing():
		if _queued_next and _current_step + 1 < max_steps and player.is_on_floor():
			_start_step(_current_step + 1)
			return

		player.advance_or_wrap_combo(_current_step)
		if not player.is_on_floor():
			state_machine.transition_to(&"Fall")
		elif absf(player.get_move_input_axis()) > 0.01:
			state_machine.transition_to(&"Run")
		else:
			state_machine.transition_to(&"Idle")


func get_current_step() -> int:
	return _current_step
