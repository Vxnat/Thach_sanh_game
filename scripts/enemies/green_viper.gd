class_name GreenViper
extends StageEnemy
## Rắn Lục (Màn 1): thân thấp 16x12, trườn/rình (frame 0-1), cuộn mình 0.25s (frame 2) rồi phóng đớp (frame 3).

enum AIState { PATROL, COIL_WINDUP, STRIKE }

@export var windup_duration: float = 0.25
@export var strike_duration: float = 0.16
@export var strike_speed: float = 190.0
@export var strike_cooldown: float = 0.9

var _ai_state: AIState = AIState.PATROL


func get_ai_state_name() -> StringName:
	match _ai_state:
		AIState.PATROL:
			return &"PATROL"
		AIState.COIL_WINDUP:
			return &"COIL_WINDUP"
		AIState.STRIKE:
			return &"STRIKE"
	return &"PATROL"


func _step_ai(delta: float) -> void:
	var spd: float = stats_component.get_effective_move_speed() if stats_component != null else 54.0
	var p: Node2D = _find_alive_player()
	var atk_range: float = enemy_data.attack_range if enemy_data != null else 42.0
	var aggro_range: float = enemy_data.aggro_range if enemy_data != null else 96.0

	match _ai_state:
		AIState.PATROL:
			update_patrol_idle_anim(delta, 0.18, 0.50)
			if p != null:
				var dx: float = p.global_position.x - global_position.x
				var dy: float = p.global_position.y - global_position.y
				var dist_x: float = absf(dx)
				if is_on_floor() and _attack_cooldown_timer <= 0.0 and dist_x <= atk_range and absf(dy) <= 28.0:
					_apply_facing(1 if dx >= 0.0 else -1)
					_ai_state = AIState.COIL_WINDUP
					_state_timer = windup_duration
					velocity.x = 0.0
					if body_sprite != null:
						body_sprite.frame = 2
					return
				if patrol_enabled and dist_x <= aggro_range and absf(dy) <= 36.0:
					_move_toward_x(p.global_position.x, spd * 1.15)
					return

			if patrol_enabled:
				_move_patrol(spd)
			else:
				velocity.x = move_toward(velocity.x, 0.0, knockback_friction * delta)

		AIState.COIL_WINDUP:
			velocity.x = 0.0
			if body_sprite != null:
				body_sprite.frame = 2
			if p != null:
				_apply_facing(1 if p.global_position.x >= global_position.x else -1)
			if _state_timer <= 0.0:
				_ai_state = AIState.STRIKE
				_state_timer = strike_duration
				velocity.x = float(_facing_dir) * strike_speed
				if body_sprite != null:
					body_sprite.frame = 3

		AIState.STRIKE:
			if body_sprite != null:
				body_sprite.frame = 3
			if is_on_floor() and _is_at_ledge():
				velocity.x = 0.0
			else:
				velocity.x = float(_facing_dir) * strike_speed
			if _state_timer <= 0.0 or is_on_wall():
				_ai_state = AIState.PATROL
				_attack_cooldown_timer = strike_cooldown
				velocity.x = 0.0
				if body_sprite != null:
					body_sprite.frame = 0


func _on_hurt_interrupted() -> void:
	_ai_state = AIState.PATROL
	_state_timer = 0.0
	_attack_cooldown_timer = maxf(_attack_cooldown_timer, 0.45)
	if body_sprite != null:
		body_sprite.frame = 0

