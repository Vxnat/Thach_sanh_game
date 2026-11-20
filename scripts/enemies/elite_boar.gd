class_name EliteBoar
extends StageEnemy
## Tinh anh Lợn Rừng Nanh Thép (Hang Màn 1): cào đất gồng húc tốc độ cao; đâm vào vách đá tự choáng 1.4s.

enum AIState { PATROL, CHARGE_WINDUP, CHARGING }

@export var windup_duration: float = 0.42
@export var charge_duration: float = 1.15
@export var charge_speed: float = 225.0
@export var wall_stun_duration: float = 1.40
@export var charge_cooldown: float = 1.60

var _ai_state: AIState = AIState.PATROL
var _charge_anim_elapsed: float = 0.0
var _charge_step_elapsed: float = 0.0


func get_ai_state_name() -> StringName:
	match _ai_state:
		AIState.PATROL:
			return &"PATROL"
		AIState.CHARGE_WINDUP:
			return &"CHARGE_WINDUP"
		AIState.CHARGING:
			return &"CHARGING"
	return &"PATROL"


func is_charging() -> bool:
	return _ai_state == AIState.CHARGING


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not _is_dead and is_stunned() and body_sprite != null:
		body_sprite.frame = 5


func _apply_facing(dir: int) -> void:
	super._apply_facing(dir)
	if enemy_hitbox != null:
		enemy_hitbox.set_facing_direction(_facing_dir)


func _step_ai(delta: float) -> void:
	var spd: float = stats_component.get_effective_move_speed() if stats_component != null else 62.0
	var base_atk: int = stats_component.get_effective_atk() if stats_component != null else 20
	var p: Node2D = _find_alive_player()
	var atk_range: float = enemy_data.attack_range if enemy_data != null else 136.0
	var aggro_range: float = enemy_data.aggro_range if enemy_data != null else 152.0

	match _ai_state:
		AIState.PATROL:
			update_patrol_idle_anim(delta, 0.16, 0.48)
			if p != null:
				var dx: float = p.global_position.x - global_position.x
				var dy: float = p.global_position.y - global_position.y
				var dist_x: float = absf(dx)
				if is_on_floor() and _attack_cooldown_timer <= 0.0 and dist_x <= atk_range and absf(dy) <= 32.0:
					_apply_facing(1 if dx >= 0.0 else -1)
					_ai_state = AIState.CHARGE_WINDUP
					_state_timer = windup_duration
					velocity.x = 0.0
					if body_sprite != null:
						body_sprite.frame = 2
					return
				if patrol_enabled and dist_x <= aggro_range and absf(dy) <= 40.0:
					_move_toward_x(p.global_position.x, spd)
					return

			if patrol_enabled:
				_move_patrol(spd)
			else:
				velocity.x = move_toward(velocity.x, 0.0, knockback_friction * delta)

		AIState.CHARGE_WINDUP:
			velocity.x = 0.0
			if body_sprite != null:
				body_sprite.frame = 2
			if p != null and _state_timer > windup_duration * 0.45:
				_apply_facing(1 if p.global_position.x >= global_position.x else -1)
			if _state_timer <= 0.0:
				_enter_charging(base_atk)

		AIState.CHARGING:
			_charge_anim_elapsed += delta
			_charge_step_elapsed += delta
			if body_sprite != null:
				if _charge_anim_elapsed >= 0.09:
					_charge_anim_elapsed = fmod(_charge_anim_elapsed, 0.09)
					body_sprite.frame = 4 if body_sprite.frame == 3 else 3
			velocity.x = float(_facing_dir) * charge_speed

			# Đâm vào vách đá trong lúc lao húc -> Dội ngược & tự choáng 1.4s!
			if is_on_wall() and _charge_step_elapsed >= 0.05:
				_trigger_wall_crash_stun(base_atk)
				return

			# Hãm phanh nếu tới mép vực không có tường
			if is_on_floor() and _is_at_ledge():
				_finish_charge(base_atk, charge_cooldown * 0.85)
				return

			if _state_timer <= 0.0:
				_finish_charge(base_atk, charge_cooldown)


func _enter_charging(base_atk: int) -> void:
	_ai_state = AIState.CHARGING
	_state_timer = charge_duration
	_charge_anim_elapsed = 0.0
	_charge_step_elapsed = 0.0
	velocity.x = float(_facing_dir) * charge_speed
	if body_sprite != null:
		body_sprite.frame = 3
	if enemy_hitbox != null:
		var charge_dmg: int = maxi(base_atk, int(roundf(float(base_atk) * 1.2)))
		enemy_hitbox.configure_hitbox(Vector2(32.0, 18.0), Vector2(6.0, -9.0), Vector2(155.0, -135.0), 0.06, charge_dmg)
		enemy_hitbox.set_active(true)


func _finish_charge(base_atk: int, cooldown_sec: float) -> void:
	_ai_state = AIState.PATROL
	_state_timer = 0.0
	_attack_cooldown_timer = cooldown_sec
	velocity.x = 0.0
	if body_sprite != null:
		body_sprite.frame = 0
	if enemy_hitbox != null:
		enemy_hitbox.configure_hitbox(Vector2(28.0, 18.0), Vector2(3.0, -9.0), Vector2(125.0, -120.0), 0.05, base_atk)
		if not _is_dead and not is_stunned():
			enemy_hitbox.set_active(true)


func _trigger_wall_crash_stun(base_atk: int) -> void:
	AudioManager.play_sfx(&"slam_impact", 0.90, 1.02, -1.0)
	_finish_charge(base_atk, charge_cooldown)
	velocity = Vector2(-float(_facing_dir) * 58.0, -78.0)
	var p: Node2D = _find_alive_player()
	if p != null and global_position.distance_to(p.global_position) <= 180.0 and p.has_method(&"trigger_camera_shake"):
		p.call(&"trigger_camera_shake", Vector2(float(_facing_dir), 0.25), 2.0, 0.11)
	apply_stun(wall_stun_duration)
	if body_sprite != null:
		body_sprite.frame = 5


func _interrupt_ai_on_hurt() -> bool:
	return _ai_state != AIState.CHARGING


func _on_hurt_interrupted() -> void:
	var base_atk: int = stats_component.get_effective_atk() if stats_component != null else 20
	_finish_charge(base_atk, maxf(_attack_cooldown_timer, 0.65))


func _on_stun_applied() -> void:
	var base_atk: int = stats_component.get_effective_atk() if stats_component != null else 20
	_ai_state = AIState.PATROL
	_state_timer = 0.0
	_attack_cooldown_timer = maxf(_attack_cooldown_timer, 0.85)
	if enemy_hitbox != null:
		enemy_hitbox.configure_hitbox(Vector2(28.0, 18.0), Vector2(3.0, -9.0), Vector2(125.0, -120.0), 0.05, base_atk)
		enemy_hitbox.set_active(false)
	if body_sprite != null:
		body_sprite.frame = 5

