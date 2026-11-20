class_name PlayerHurtState
extends PlayerState
## Trạng thái Bị thương (Hurt): ngắt đòn sạch sẽ, đẩy lùi và tự hồi phục sau thời gian choáng ngắn.

var _stun_timer: float = 0.0


func enter(_prev_state: StringName, msg: Dictionary = {}) -> void:
	player.reset_combat_state()
	player.clear_relic_visual()
	player.reset_combo()

	var kb: Vector2 = msg.get("knockback", Vector2.ZERO) as Vector2
	if kb.length_squared() < 1.0:
		kb = Vector2(-float(player.facing_direction) * 95.0, -110.0)
	player.velocity = kb
	_stun_timer = player.hurt_stun_duration
	player.play_locomotion_anim(&"hurt")


func exit() -> void:
	player.reset_combat_state()


func physics_update(delta: float) -> void:
	_stun_timer -= delta
	player.velocity.x = move_toward(player.velocity.x, 0.0, player.ground_decel * 0.45 * delta)
	player.apply_gravity(delta)
	player.move_and_slide()

	if _stun_timer <= 0.0:
		if not player.is_on_floor():
			state_machine.transition_to(&"Fall")
		elif absf(player.get_move_input_axis()) > 0.01:
			state_machine.transition_to(&"Run")
		else:
			state_machine.transition_to(&"Idle")

