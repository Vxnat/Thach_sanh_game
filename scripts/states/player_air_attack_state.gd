class_name PlayerAirAttackState
extends PlayerState
## Trạng thái Không chiến tách biệt 4 dòng: Air Slam (Búa/Rìu), Air Stall (Đao), Pogo Bounce (Thương).

enum AirMode { STANDARD, AIR_STALL_COMBO, AIR_SLAM_WINDUP, AIR_SLAM_PLUNGE, AIR_SLAM_LAND, POLE_POGO }

var _mode: AirMode = AirMode.STANDARD
var _air_step: int = 0
var _phase_timer: float = 0.0
var _step_elapsed: float = 0.0
var _queued_next: bool = false
var _is_blade_down: bool = false
var _used_stall_here: bool = false
var _pogo_connected: bool = false


func enter(_prev_state: StringName, _msg: Dictionary = {}) -> void:
	player.consume_attack_buffer()
	player.reset_combo()
	_air_step = 0
	_phase_timer = 0.0
	_step_elapsed = 0.0
	_queued_next = false
	_is_blade_down = false
	_used_stall_here = false
	_pogo_connected = false

	var combo: WeaponComboProfile = player.equipped_weapon.combo_profile if player.equipped_weapon != null else null
	var anim_profile: WeaponAnimProfile = player.equipped_weapon.animation_profile if player.equipped_weapon != null else null
	var down_held: bool = Input.is_action_pressed("move_down")

	if down_held and combo != null and combo.has_air_slam:
		_enter_air_slam()
	elif down_held and combo != null and combo.has_pogo_bounce:
		_enter_pogo()
	elif not down_held and combo != null and combo.has_air_stall:
		_enter_air_stall_step(0)
	else:
		_mode = AirMode.STANDARD
		_is_blade_down = (
			down_held
			and anim_profile != null
			and anim_profile.weapon_group == WeaponAnimProfile.WeaponGroup.BLADE
		)
		var anim_name: StringName = player.prepare_air_attack(down_held, 0)
		_play_attack_anim(anim_name)


func exit() -> void:
	if _pogo_connected and player.melee_hit_landed.is_connected(_on_pogo_hit_landed):
		player.melee_hit_landed.disconnect(_on_pogo_hit_landed)
	_pogo_connected = false
	if _used_stall_here:
		player.mark_air_stall_used()
	player.reset_combat_state()


func _enter_air_slam() -> void:
	_mode = AirMode.AIR_SLAM_WINDUP
	_phase_timer = 0.05
	player.velocity.x = 0.0
	player.velocity.y = minf(player.velocity.y, -20.0)
	var anim_name: StringName = player.prepare_air_attack(true, 0)
	_play_attack_anim(anim_name)
	if player.hitbox_component != null:
		player.hitbox_component.set_active(false)


func _enter_pogo() -> void:
	_mode = AirMode.POLE_POGO
	if not player.melee_hit_landed.is_connected(_on_pogo_hit_landed):
		player.melee_hit_landed.connect(_on_pogo_hit_landed)
	_pogo_connected = true
	var anim_name: StringName = player.prepare_air_attack(true, 0)
	_play_attack_anim(anim_name)


func _enter_air_stall_step(step_idx: int) -> void:
	_mode = AirMode.AIR_STALL_COMBO
	_air_step = step_idx
	_step_elapsed = 0.0
	_queued_next = false

	if player.hitbox_component != null:
		player.hitbox_component.set_active(false)
		player.hitbox_component.clear_hit_targets()

	if not player.has_used_air_stall():
		_used_stall_here = true
		player.velocity.y = clampf(player.velocity.y * 0.2, -20.0, 14.0)

	var anim_name: StringName = player.prepare_air_attack(false, step_idx)
	_play_attack_anim(anim_name)


func _play_attack_anim(anim_name: StringName) -> void:
	if player.animation_player != null and player.animation_player.has_animation(anim_name):
		player.animation_player.stop()
		player.animation_player.play(anim_name)
	else:
		push_warning("Thiếu animation không chiến: %s" % String(anim_name))


func physics_update(delta: float) -> void:
	_step_elapsed += delta
	var combo: WeaponComboProfile = player.equipped_weapon.combo_profile if player.equipped_weapon != null else null
	var cancel_after: float = combo.cancel_to_dash_after_sec if combo != null else 0.04

	if _mode != AirMode.AIR_SLAM_LAND and _step_elapsed >= cancel_after and player.has_buffered_dash() and player.can_dash():
		state_machine.transition_to(&"Dash")
		return

	match _mode:
		AirMode.AIR_SLAM_WINDUP:
			_update_air_slam_windup(delta, combo)
		AirMode.AIR_SLAM_PLUNGE:
			_update_air_slam_plunge(delta, combo)
		AirMode.AIR_SLAM_LAND:
			_update_air_slam_land(delta)
		AirMode.POLE_POGO:
			_update_pogo(delta)
		AirMode.AIR_STALL_COMBO:
			_update_air_stall_combo(delta, combo)
		AirMode.STANDARD:
			_update_standard(delta)


func _update_air_slam_windup(delta: float, combo: WeaponComboProfile) -> void:
	_phase_timer -= delta
	player.velocity.x = 0.0
	player.apply_gravity(delta, 0.35)
	player.move_and_slide()

	if player.is_on_floor():
		_start_slam_land_recovery(combo)
		return

	if _phase_timer <= 0.0:
		_mode = AirMode.AIR_SLAM_PLUNGE
		if player.hitbox_component != null:
			player.hitbox_component.set_active(true)


func _update_air_slam_plunge(_delta: float, combo: WeaponComboProfile) -> void:
	var slam_vy: float = combo.air_slam_speed if combo != null else 340.0
	var slam_vx: float = combo.air_slam_horizontal_speed if combo != null else 0.0
	player.velocity.x = float(player.facing_direction) * slam_vx
	player.velocity.y = slam_vy
	if player.hitbox_component != null and not player.hitbox_component.active:
		player.hitbox_component.set_active(true)
	player.move_and_slide()

	if player.is_on_floor():
		_start_slam_land_recovery(combo)


func _start_slam_land_recovery(combo: WeaponComboProfile) -> void:
	_mode = AirMode.AIR_SLAM_LAND
	player.velocity = Vector2.ZERO
	var rec_sec: float = combo.air_slam_recovery_sec if combo != null else 0.12
	_phase_timer = rec_sec

	var is_hammer: bool = true
	var land_anim: StringName = &""
	if player.equipped_weapon != null and player.equipped_weapon.animation_profile != null:
		var ap: WeaponAnimProfile = player.equipped_weapon.animation_profile
		is_hammer = (ap.weapon_group == WeaponAnimProfile.WeaponGroup.HAMMER)
		land_anim = ap.air_slam_land_anim

	player.trigger_camera_shake(Vector2(0.0, 1.0), 3.0 if is_hammer else 2.5, 0.14)
	AudioManager.play_sfx(&"slam_impact", 0.95, 1.03)
	if land_anim != &"" and player.animation_player != null and player.animation_player.has_animation(land_anim):
		player.animation_player.stop(true)
		player.animation_player.play(land_anim)


func _update_air_slam_land(delta: float) -> void:
	_phase_timer -= delta
	player.velocity.x = 0.0
	player.apply_gravity(delta)
	player.move_and_slide()

	if _phase_timer <= 0.0:
		_finish_to_locomotion()


func _update_pogo(delta: float) -> void:
	var axis: float = player.get_move_input_axis()
	player.apply_horizontal_movement(axis, player.air_accel, player.air_decel, delta)
	player.apply_gravity(delta)
	player.move_and_slide()

	if state_machine.get_current_state_name() != &"AirAttack":
		return
	if player.is_on_floor():
		_finish_to_locomotion()
	elif player.animation_player == null or not player.animation_player.is_playing():
		state_machine.transition_to(&"Fall")


func _on_pogo_hit_landed(_hurtbox: HurtboxComponent, _damage_dealt: int) -> void:
	if _mode != AirMode.POLE_POGO:
		return
	var bounce_vy: float = -265.0
	if player.equipped_weapon != null and player.equipped_weapon.combo_profile != null:
		bounce_vy = player.equipped_weapon.combo_profile.pogo_bounce_velocity
	player.velocity.y = bounce_vy
	player.refresh_air_actions_on_pogo()
	player.suppress_current_hitstop()
	player.trigger_camera_shake(Vector2(0.0, -1.0), 1.5, 0.08)
	state_machine.transition_to(&"Jump", {"from_pogo": true})


func _update_air_stall_combo(delta: float, combo: WeaponComboProfile) -> void:
	var anim_profile: WeaponAnimProfile = player.equipped_weapon.animation_profile if player.equipped_weapon != null else null
	var air_max_steps: int = anim_profile.get_air_combo_count() if anim_profile != null else 1
	if _step_elapsed >= 0.03 and _air_step + 1 < air_max_steps and player.has_buffered_attack():
		_queued_next = true
		player.consume_attack_buffer()

	var axis: float = player.get_move_input_axis()
	player.apply_horizontal_movement(axis, player.air_accel * 0.9, player.air_decel, delta)

	if not player.has_used_air_stall() and combo != null:
		player.apply_gravity(delta, combo.air_stall_gravity_scale, 48.0)
	else:
		player.apply_gravity(delta)

	player.move_and_slide()

	if player.is_on_floor():
		_finish_to_locomotion()
	elif player.animation_player == null or not player.animation_player.is_playing():
		if _queued_next and _air_step + 1 < air_max_steps:
			_enter_air_stall_step(_air_step + 1)
			return
		state_machine.transition_to(&"Fall")


func _update_standard(delta: float) -> void:
	var axis: float = player.get_move_input_axis()
	player.apply_horizontal_movement(axis, player.air_accel, player.air_decel, delta)
	var grav_scale: float = 0.6 if _is_blade_down else 1.0
	player.apply_gravity(delta, grav_scale)
	player.move_and_slide()

	if player.is_on_floor():
		_finish_to_locomotion()
	elif player.animation_player == null or not player.animation_player.is_playing():
		state_machine.transition_to(&"Fall")


func _finish_to_locomotion() -> void:
	if not player.is_on_floor():
		state_machine.transition_to(&"Fall")
	elif absf(player.get_move_input_axis()) > 0.01:
		state_machine.transition_to(&"Run")
	else:
		state_machine.transition_to(&"Idle")


func get_air_mode_name() -> StringName:
	match _mode:
		AirMode.AIR_SLAM_WINDUP:
			return &"AIR_SLAM_WINDUP"
		AirMode.AIR_SLAM_PLUNGE:
			return &"AIR_SLAM_PLUNGE"
		AirMode.AIR_SLAM_LAND:
			return &"AIR_SLAM_LAND"
		AirMode.POLE_POGO:
			return &"POLE_POGO"
		AirMode.AIR_STALL_COMBO:
			return &"AIR_STALL_COMBO"
	return &"STANDARD"
