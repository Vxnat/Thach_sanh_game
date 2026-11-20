class_name WildSquirrel
extends StageEnemy
## Sóc Dại (Màn 1): tuần tra nhanh (frame 0-1), gồng 0.26s (frame 2) rồi nhảy vồ vòng cung (frame 3).

enum AIState { PATROL, WINDUP, POUNCE }

@export var windup_duration: float = 0.26
@export var pounce_vx: float = 155.0
@export var pounce_vy: float = -185.0
@export var pounce_cooldown: float = 1.1

var _ai_state: AIState = AIState.PATROL
var _pounce_air_time: float = 0.0


func get_ai_state_name() -> StringName:
	match _ai_state:
		AIState.PATROL:
			return &"PATROL"
		AIState.WINDUP:
			return &"WINDUP"
		AIState.POUNCE:
			return &"POUNCE"
	return &"PATROL"


func _step_ai(delta: float) -> void:
	var spd: float = stats_component.get_effective_move_speed() if stats_component != null else 68.0
	var p: Node2D = _find_alive_player()
	var atk_range: float = enemy_data.attack_range if enemy_data != null else 64.0
	var aggro_range: float = enemy_data.aggro_range if enemy_data != null else 115.0

	match _ai_state:
		AIState.PATROL:
			update_patrol_idle_anim(delta, 0.15, 0.46)
			if p != null:
				var dx: float = p.global_position.x - global_position.x
				var dy: float = p.global_position.y - global_position.y
				var dist_x: float = absf(dx)
				if is_on_floor() and _attack_cooldown_timer <= 0.0 and dist_x <= atk_range and absf(dy) <= 44.0:
					_apply_facing(1 if dx >= 0.0 else -1)
					_ai_state = AIState.WINDUP
					_state_timer = windup_duration
					velocity.x = 0.0
					if body_sprite != null:
						body_sprite.frame = 2
					return
				if patrol_enabled and dist_x <= aggro_range and absf(dy) <= 48.0:
					_move_toward_x(p.global_position.x, spd)
					return

			if patrol_enabled:
				_move_patrol(spd)
			else:
				velocity.x = move_toward(velocity.x, 0.0, knockback_friction * delta)

		AIState.WINDUP:
			velocity.x = 0.0
			if body_sprite != null:
				body_sprite.frame = 2
			if p != null:
				_apply_facing(1 if p.global_position.x >= global_position.x else -1)
			if _state_timer <= 0.0:
				_ai_state = AIState.POUNCE
				_pounce_air_time = 0.0
				velocity.x = float(_facing_dir) * pounce_vx
				velocity.y = pounce_vy
				if body_sprite != null:
					body_sprite.frame = 3

		AIState.POUNCE:
			_pounce_air_time += delta
			if body_sprite != null:
				body_sprite.frame = 3
			if is_on_wall():
				velocity.x = 0.0
			if is_on_floor() and _pounce_air_time >= 0.12:
				_ai_state = AIState.PATROL
				_attack_cooldown_timer = pounce_cooldown
				velocity.x = 0.0
				if body_sprite != null:
					body_sprite.frame = 0


func _on_hurt_interrupted() -> void:
	_ai_state = AIState.PATROL
	_state_timer = 0.0
	_attack_cooldown_timer = maxf(_attack_cooldown_timer, 0.45)
	if body_sprite != null:
		body_sprite.frame = 0

