class_name ThornBeetle
extends StageEnemy
## Bọ Gai (Màn 1): kháng đẩy lùi, cuộn vỏ gai SHELL_GUARD giảm 50% sát thương nhẹ, bị Búa/Rìu phá giáp gây 100%.

enum AIState { PATROL, GUARD_WINDUP, SHELL_GUARD }

@export var guard_trigger_range: float = 56.0
@export var windup_duration: float = 0.30
@export var shell_guard_duration: float = 1.1
@export var guard_cooldown: float = 1.4

var _ai_state: AIState = AIState.PATROL


func is_shell_guarded() -> bool:
	return _ai_state == AIState.SHELL_GUARD


func get_ai_state_name() -> StringName:
	match _ai_state:
		AIState.PATROL:
			return &"PATROL"
		AIState.GUARD_WINDUP:
			return &"GUARD_WINDUP"
		AIState.SHELL_GUARD:
			return &"SHELL_GUARD"
	return &"PATROL"


func _step_ai(delta: float) -> void:
	var spd: float = stats_component.get_effective_move_speed() if stats_component != null else 34.0
	var p: Node2D = _find_alive_player()
	var aggro_range: float = enemy_data.aggro_range if enemy_data != null else 88.0

	match _ai_state:
		AIState.PATROL:
			update_patrol_idle_anim(delta, 0.20, 0.52)
			if p != null:
				var dx: float = p.global_position.x - global_position.x
				var dy: float = p.global_position.y - global_position.y
				var dist_x: float = absf(dx)
				if is_on_floor() and _attack_cooldown_timer <= 0.0 and dist_x <= guard_trigger_range and absf(dy) <= 32.0:
					_apply_facing(1 if dx >= 0.0 else -1)
					_ai_state = AIState.GUARD_WINDUP
					_state_timer = windup_duration
					velocity.x = 0.0
					if body_sprite != null:
						body_sprite.frame = 2
					return
				if patrol_enabled and dist_x <= aggro_range and absf(dy) <= 36.0:
					_move_toward_x(p.global_position.x, spd)
					return

			if patrol_enabled:
				_move_patrol(spd)
			else:
				velocity.x = move_toward(velocity.x, 0.0, knockback_friction * delta)

		AIState.GUARD_WINDUP:
			velocity.x = 0.0
			if body_sprite != null:
				body_sprite.frame = 2
			if _state_timer <= 0.0:
				_ai_state = AIState.SHELL_GUARD
				_state_timer = shell_guard_duration
				if body_sprite != null:
					body_sprite.frame = 3

		AIState.SHELL_GUARD:
			velocity.x = 0.0
			if body_sprite != null:
				body_sprite.frame = 3
			if _state_timer <= 0.0:
				_exit_shell_guard(guard_cooldown)


func modify_incoming_damage(hitbox: HitboxComponent, raw_damage: int) -> int:
	if _ai_state != AIState.SHELL_GUARD:
		return raw_damage

	var is_armor_breaker: bool = _is_heavy_armor_breaker_hit(hitbox)
	if is_armor_breaker:
		AudioManager.play_sfx(&"slam_impact", 1.05, 1.12, -2.0)
		_exit_shell_guard(guard_cooldown + 0.4)
		return raw_damage

	return maxi(1, int(ceil(float(raw_damage) * 0.5)))


func _is_heavy_armor_breaker_hit(hitbox: HitboxComponent) -> bool:
	if hitbox == null or hitbox.owner == null:
		return false
	var eq: Variant = hitbox.owner.get(&"equipped_weapon")
	if eq == null or not (eq is WeaponData):
		return false
	var wd: WeaponData = eq as WeaponData
	if wd.animation_profile == null:
		return false
	var grp: int = wd.animation_profile.weapon_group
	return grp == WeaponAnimProfile.WeaponGroup.HAMMER or grp == WeaponAnimProfile.WeaponGroup.AXE


func _exit_shell_guard(cooldown_sec: float) -> void:
	_ai_state = AIState.PATROL
	_state_timer = 0.0
	_attack_cooldown_timer = cooldown_sec
	if body_sprite != null:
		body_sprite.frame = 0


func _interrupt_ai_on_hurt() -> bool:
	return _ai_state != AIState.SHELL_GUARD


func _on_hurt_interrupted() -> void:
	if _ai_state == AIState.GUARD_WINDUP:
		_ai_state = AIState.PATROL
		_state_timer = 0.0
		_attack_cooldown_timer = maxf(_attack_cooldown_timer, 0.5)
		if body_sprite != null:
			body_sprite.frame = 0


func _on_stun_applied() -> void:
	if _ai_state == AIState.SHELL_GUARD or _ai_state == AIState.GUARD_WINDUP:
		AudioManager.play_sfx(&"slam_impact", 1.05, 1.12, -2.0)
		_exit_shell_guard(guard_cooldown)
	else:
		_on_hurt_interrupted()

