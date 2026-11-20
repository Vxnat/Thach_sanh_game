class_name EliteBear
extends StageEnemy
## Tinh anh Gấu Đen Tà Khí (Bãi Đá Cổ Màn 1): đứng dựng 2 chân sau gầm gào rồi đập đất chấn động diện rộng.

enum AIState { PATROL, REAR_WINDUP, GROUND_SLAM, RECOVER }

@export var rear_windup_duration: float = 0.50
@export var slam_duration: float = 0.28
@export var recover_duration: float = 0.45
@export var slam_cooldown: float = 1.35

var _ai_state: AIState = AIState.PATROL
var _slam_frame_swapped: bool = false


func get_ai_state_name() -> StringName:
	match _ai_state:
		AIState.PATROL:
			return &"PATROL"
		AIState.REAR_WINDUP:
			return &"REAR_WINDUP"
		AIState.GROUND_SLAM:
			return &"GROUND_SLAM"
		AIState.RECOVER:
			return &"RECOVER"
	return &"PATROL"


func _apply_facing(dir: int) -> void:
	super._apply_facing(dir)
	if enemy_hitbox != null:
		enemy_hitbox.set_facing_direction(_facing_dir)


func _step_ai(delta: float) -> void:
	var spd: float = stats_component.get_effective_move_speed() if stats_component != null else 42.0
	var base_atk: int = stats_component.get_effective_atk() if stats_component != null else 24
	var p: Node2D = _find_alive_player()
	var atk_range: float = enemy_data.attack_range if enemy_data != null else 54.0
	var aggro_range: float = enemy_data.aggro_range if enemy_data != null else 148.0

	match _ai_state:
		AIState.PATROL:
			update_patrol_idle_anim(delta, 0.22, 0.52)
			if p != null:
				var dx: float = p.global_position.x - global_position.x
				var dy: float = p.global_position.y - global_position.y
				var dist_x: float = absf(dx)
				if is_on_floor() and _attack_cooldown_timer <= 0.0 and dist_x <= atk_range and absf(dy) <= 40.0:
					_apply_facing(1 if dx >= 0.0 else -1)
					_ai_state = AIState.REAR_WINDUP
					_state_timer = rear_windup_duration
					velocity.x = 0.0
					if body_sprite != null:
						body_sprite.frame = 2
					return
				if patrol_enabled and dist_x <= aggro_range and absf(dy) <= 44.0:
					_move_toward_x(p.global_position.x, spd)
					return

			if patrol_enabled:
				_move_patrol(spd)
			else:
				velocity.x = move_toward(velocity.x, 0.0, knockback_friction * delta)

		AIState.REAR_WINDUP:
			velocity.x = 0.0
			if body_sprite != null:
				body_sprite.frame = 2 if _state_timer > rear_windup_duration * 0.62 else 3
			if p != null and _state_timer > rear_windup_duration * 0.55:
				_apply_facing(1 if p.global_position.x >= global_position.x else -1)
			if _state_timer <= 0.0:
				_trigger_ground_slam(base_atk)

		AIState.GROUND_SLAM:
			velocity.x = 0.0
			if body_sprite != null and not _slam_frame_swapped and _state_timer <= slam_duration * 0.55:
				_slam_frame_swapped = true
				body_sprite.frame = 5
			if _state_timer <= 0.0:
				_enter_recover(base_atk)

		AIState.RECOVER:
			velocity.x = 0.0
			if body_sprite != null:
				body_sprite.frame = 0
			if _state_timer <= 0.0:
				_ai_state = AIState.PATROL
				_attack_cooldown_timer = slam_cooldown


func _trigger_ground_slam(base_atk: int) -> void:
	_ai_state = AIState.GROUND_SLAM
	_state_timer = slam_duration
	_slam_frame_swapped = false
	velocity.x = float(_facing_dir) * 24.0
	if body_sprite != null:
		body_sprite.frame = 4

	AudioManager.play_sfx(&"slam_impact", 0.86, 0.96, -1.0)
	if enemy_hitbox != null:
		var slam_dmg: int = maxi(base_atk, int(roundf(float(base_atk) * 1.25)))
		enemy_hitbox.configure_hitbox(Vector2(54.0, 24.0), Vector2(16.0, -12.0), Vector2(180.0, -140.0), 0.07, slam_dmg)
		enemy_hitbox.clear_hit_targets()
		enemy_hitbox.set_active(true)

	var p: Node2D = _find_alive_player()
	if p != null and global_position.distance_to(p.global_position) <= 170.0 and p.has_method(&"trigger_camera_shake"):
		p.call(&"trigger_camera_shake", Vector2(0.0, 1.0), 2.2, 0.12)


func _enter_recover(base_atk: int) -> void:
	_ai_state = AIState.RECOVER
	_state_timer = recover_duration
	velocity.x = 0.0
	if body_sprite != null:
		body_sprite.frame = 0
	if enemy_hitbox != null:
		enemy_hitbox.configure_hitbox(Vector2(28.0, 22.0), Vector2(2.0, -11.0), Vector2(130.0, -120.0), 0.05, base_atk)
		if not _is_dead and not is_stunned():
			enemy_hitbox.set_active(true)


func _interrupt_ai_on_hurt() -> bool:
	return _ai_state != AIState.REAR_WINDUP and _ai_state != AIState.GROUND_SLAM


func _on_hurt_interrupted() -> void:
	var base_atk: int = stats_component.get_effective_atk() if stats_component != null else 24
	_ai_state = AIState.PATROL
	_state_timer = 0.0
	if body_sprite != null:
		body_sprite.frame = 0
	if enemy_hitbox != null:
		enemy_hitbox.configure_hitbox(Vector2(28.0, 22.0), Vector2(2.0, -11.0), Vector2(130.0, -120.0), 0.05, base_atk)


func _on_stun_applied() -> void:
	_on_hurt_interrupted()
	_attack_cooldown_timer = maxf(_attack_cooldown_timer, 0.75)
	if enemy_hitbox != null:
		enemy_hitbox.set_active(false)

