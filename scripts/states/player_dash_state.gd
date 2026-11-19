class_name PlayerDashState
extends PlayerState
## Trạng thái Lướt né (Dash) kèm i-frames xuyên hitbox quái và bóng mờ pixel.

var _elapsed: float = 0.0
var _spawned_mid_ghost: bool = false


func enter(_prev_state: StringName, _msg: Dictionary = {}) -> void:
	var axis: float = player.get_move_input_axis()
	if absf(axis) > 0.01:
		player.update_facing(axis)

	player.reset_combat_state()
	player.reset_combo()
	player.consume_dash()
	if player.health_component != null:
		player.health_component.start_invincibility(player.dash_iframes_duration)

	_elapsed = 0.0
	_spawned_mid_ghost = false
	player.velocity = Vector2(float(player.facing_direction) * player.dash_speed, 0.0)
	player.play_locomotion_anim(&"dash")
	AudioManager.play_sfx(&"dash", 0.96, 1.06)
	player.spawn_dash_afterimage()


func exit() -> void:
	player.velocity.x = float(player.facing_direction) * (player.move_speed * 0.75)


func physics_update(delta: float) -> void:
	_elapsed += delta
	if not _spawned_mid_ghost and _elapsed >= player.dash_duration * 0.5:
		_spawned_mid_ghost = true
		player.spawn_dash_afterimage()

	player.velocity = Vector2(float(player.facing_direction) * player.dash_speed, 0.0)
	player.move_and_slide()

	if _elapsed >= player.dash_duration:
		if not player.is_on_floor():
			state_machine.transition_to(&"Fall")
		elif absf(player.get_move_input_axis()) > 0.01:
			state_machine.transition_to(&"Run")
		else:
			state_machine.transition_to(&"Idle")

