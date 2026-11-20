class_name Player
extends CharacterBody2D
## Controller chính cho Thạch Sanh (Bước 1.1–1.4: Di chuyển, Hand-Socket 3 lớp, Combo, Không chiến 4 dòng, Dash, Hurt, Hitstop).

signal mp_changed(current_mp: int, max_mp: int)
signal weapon_equipped(weapon: WeaponData)
signal melee_hit_landed(hurtbox: HurtboxComponent, damage_dealt: int)
signal hazard_resolved(damage_taken: int, died: bool)

const DEFAULT_DEBUG_WEAPON_PATHS: PackedStringArray = [
	"res://data/weapons/weapon_wooden_mallet.tres",
	"res://data/weapons/weapon_bronze_axe.tres",
	"res://data/weapons/weapon_short_blade.tres",
	"res://data/weapons/weapon_bamboo_spear.tres",
	"res://data/weapons/weapon_iron_hammer.tres",
]

const RELIC_NIEU_COM_TEX: Texture2D = preload("res://assets/sprites/relics/relic_nieu_com.png")
const RELIC_CUNG_TEN_TEX: Texture2D = preload("res://assets/sprites/relics/relic_cung_ten_vang.png")
const RELIC_DAN_THAN_TEX: Texture2D = preload("res://assets/sprites/relics/relic_dan_than.png")

@export_group("Di chuyển ngang")
@export var move_speed: float = 120.0
@export var ground_accel: float = 1200.0
@export var ground_decel: float = 1440.0
@export var air_accel: float = 850.0
@export var air_decel: float = 600.0

@export_group("Nhảy & Trọng lực")
@export var jump_velocity: float = -295.0
@export var jump_gravity: float = 820.0
@export var fall_gravity: float = 1080.0
@export var max_fall_speed: float = 360.0
@export_range(0.1, 1.0, 0.05) var jump_cut_multiplier: float = 0.45

@export_group("Độ nhạy Platformer")
@export var coyote_time_duration: float = 0.10
@export var jump_buffer_duration: float = 0.10
@export var drop_through_offset_px: float = 3.0

@export_group("Chiến đấu & Vũ khí (Hand-Socket)")
@export var max_mp: int = 50
@export var initial_mp: int = 50
@export var base_atk: int = 5
@export var weapon_atk: int = 10
@export var mp_gain_per_hit: int = 3
@export var attack_buffer_duration: float = 0.12
@export var equipped_weapon: WeaponData
@export var debug_weapon_pool: Array[WeaponData] = []

@export_group("Lướt né & Bị thương (Bước 1.4)")
@export var dash_speed: float = 300.0
@export var dash_duration: float = 0.17
@export var dash_iframes_duration: float = 0.22
@export var dash_cooldown: float = 0.55
@export var dash_buffer_duration: float = 0.10
@export var hurt_stun_duration: float = 0.22
@export var hit_spark_scene: PackedScene = preload("res://scenes/vfx/HitSpark.tscn")

@export_group("Sông sâu & SafeAnchor (Bước 1.5)")
@export var hazard_safe_margin_px: float = 14.0
@export var auto_respawn_in_sandbox: bool = true
@export var sandbox_dead_respawn_delay: float = 1.1

@export_group("Pháp bảo Cổ Tích (Bước 4.1)")
@export var sandbox_allow_unowned_relics: bool = false
@export var relic_buffer_duration: float = 0.12
@export var relic_bow_mp_cost: int = 12
@export var relic_bow_cooldown: float = 0.38
@export var relic_lute_mp_cost: int = 16
@export var relic_lute_cooldown: float = 0.90
@export var golden_arrow_scene: PackedScene = preload("res://scenes/player/GoldenArrowProjectile.tscn")
@export var dan_than_wave_scene: PackedScene = preload("res://scenes/player/DanThanSoundwave.tscn")

@onready var visual_root: Node2D = $VisualRoot
@onready var body_base_sprite: Sprite2D = $VisualRoot/BodyBaseSprite
@onready var weapon_pivot: Marker2D = $VisualRoot/WeaponPivot
@onready var weapon_sprite: Sprite2D = $VisualRoot/WeaponPivot/WeaponSprite
@onready var front_arm_sprite: Sprite2D = $VisualRoot/FrontArmSprite
@onready var slash_vfx_sprite: Sprite2D = $VisualRoot/SlashVFXSprite
@onready var relic_visual: Node2D = $VisualRoot/RelicVisual
@onready var relic_sprite: Sprite2D = get_node_or_null("VisualRoot/RelicVisual/RelicSprite") as Sprite2D
@onready var state_machine: PlayerStateMachine = $StateMachine
@onready var camera: Camera2D = $Camera2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var health_component: HealthComponent = $HealthComponent
@onready var hitbox_component: HitboxComponent = $HitboxComponent
@onready var hurtbox_component: HurtboxComponent = $HurtboxComponent
@onready var safe_ray_left: RayCast2D = $SafeRayLeft
@onready var safe_ray_right: RayCast2D = $SafeRayRight

var facing_direction: int = 1
var current_mp: int = 50
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _attack_buffer_timer: float = 0.0
var _dash_buffer_timer: float = 0.0
var _dash_cooldown_timer: float = 0.0
var _air_dash_available: bool = true
var _air_stall_used: bool = false

var _combo_next_step: int = 0
var _combo_window_timer: float = 0.0

var _buffered_relic_id: StringName = &""
var _relic_buffer_timer: float = 0.0
var _relic_bow_cd_timer: float = 0.0
var _relic_lute_cd_timer: float = 0.0
var _relic_fail_toast_cd: float = 0.0
var _relic_visual_tween: Tween = null

var _hitstop_timer: float = 0.0
var _saved_anim_speed_scale: float = 1.0
var _suppress_next_hitstop: bool = false

var _shake_timer: float = 0.0
var _shake_duration: float = 0.0
var _shake_intensity: float = 0.0
var _shake_dir: Vector2 = Vector2.ZERO

var _default_vfx_offset: Vector2 = Vector2(12.0, -18.0)
var _default_vfx_rot: float = 0.0
var _hurt_flash_tween: Tween = null
var _iframes_blink_elapsed: float = 0.0

var _initial_spawn_pos: Vector2 = Vector2.ZERO
var _safe_anchor_pos: Vector2 = Vector2.ZERO
var _safe_ground_frames: int = 0
var _is_resolving_hazard: bool = false
var _pending_hazard_teleport: bool = false
var _hazard_unlock_frames: int = 0
var _hazard_margin_query: PhysicsShapeQueryParameters2D = null
var _hazard_body_query: PhysicsShapeQueryParameters2D = null
var _nearby_interactables: Array[InteractableArea] = []
var _focused_interactable: InteractableArea = null


func _ready() -> void:
	collision_layer = 2  # Layer 2: PlayerBody
	collision_mask = 1   # Layer 1: World (không va chạm cứng EnemyBody)
	if not is_in_group(&"player"):
		add_to_group(&"player")

	_initial_spawn_pos = global_position
	_safe_anchor_pos = global_position
	_init_hazard_queries()
	_configure_pixel_camera()

	current_mp = clampi(initial_mp, 0, max_mp)
	mp_changed.emit(current_mp, max_mp)

	if hitbox_component != null:
		hitbox_component.set_facing_direction(facing_direction)
		if not hitbox_component.hit_landed.is_connected(_on_hitbox_hit_landed):
			hitbox_component.hit_landed.connect(_on_hitbox_hit_landed)

	_ensure_debug_weapon_pool()
	_sync_with_game_state_on_ready()

	if health_component != null:
		if not health_component.damaged.is_connected(_on_player_damaged):
			health_component.damaged.connect(_on_player_damaged)
		if not health_component.hp_changed.is_connected(_on_health_component_hp_changed):
			health_component.hp_changed.connect(_on_health_component_hp_changed)
	if not mp_changed.is_connected(_on_player_mp_changed_sync):
		mp_changed.connect(_on_player_mp_changed_sync)
	if not EventBus.weapon_changed.is_connected(_on_global_weapon_changed):
		EventBus.weapon_changed.connect(_on_global_weapon_changed)
	if not EventBus.player_level_changed.is_connected(_on_global_level_changed):
		EventBus.player_level_changed.connect(_on_global_level_changed)

	if equipped_weapon != null:
		equip_weapon(equipped_weapon)

	if get_parent() != null and get_parent().name == &"TestSandbox":
		sandbox_allow_unowned_relics = true
		current_mp = max_mp
		GameState.current_mp = current_mp
		mp_changed.emit(current_mp, max_mp)

	_ensure_relic_cast_state()
	reset_combat_state()
	clear_relic_visual()
	if state_machine != null:
		state_machine.start()
	EventBus.relics_updated.emit.call_deferred()


func _ensure_relic_cast_state() -> void:
	if state_machine == null:
		return
	if state_machine.get_node_or_null("RelicCast") != null:
		return
	var relic_state: PlayerRelicCastState = PlayerRelicCastState.new()
	relic_state.name = "RelicCast"
	relic_state.player = self
	relic_state.state_machine = state_machine
	state_machine.add_child(relic_state)


func _ensure_debug_weapon_pool() -> void:
	if debug_weapon_pool.is_empty():
		for path_str: String in DEFAULT_DEBUG_WEAPON_PATHS:
			var w: WeaponData = load(path_str) as WeaponData
			if w != null:
				debug_weapon_pool.append(w)
	else:
		var iron_hammer: WeaponData = load("res://data/weapons/weapon_iron_hammer.tres") as WeaponData
		if iron_hammer != null and not debug_weapon_pool.has(iron_hammer):
			debug_weapon_pool.append(iron_hammer)

	if equipped_weapon == null and not debug_weapon_pool.is_empty():
		equipped_weapon = debug_weapon_pool[0]


func _sync_with_game_state_on_ready() -> void:
	if GameState.has_active_session:
		base_atk = GameState.base_atk
		if health_component != null:
			health_component.max_hp = GameState.max_hp
			health_component.current_hp = clampi(GameState.current_hp, 1, GameState.max_hp)
			health_component.is_dead = false
			health_component.hp_changed.emit(health_component.current_hp, health_component.max_hp)
		max_mp = GameState.max_mp
		current_mp = clampi(GameState.current_mp, 0, max_mp)
		mp_changed.emit(current_mp, max_mp)
		var global_weapon: WeaponData = GameState.get_weapon_data(GameState.equipped_weapon_id)
		if global_weapon != null:
			equipped_weapon = global_weapon
	else:
		GameState.has_active_session = true
		GameState.base_atk = base_atk
		if health_component != null:
			GameState.max_hp = health_component.max_hp
			GameState.current_hp = health_component.current_hp
		GameState.max_mp = max_mp
		GameState.current_mp = current_mp
		if equipped_weapon != null and GameState.has_weapon_id(equipped_weapon.id):
			GameState.equipped_weapon_id = equipped_weapon.id
			if not GameState.owned_weapons.has(equipped_weapon.id):
				GameState.owned_weapons.append(equipped_weapon.id)
		GameState.emit_all_state_signals()


func _process(delta: float) -> void:
	if not GameState.is_gameplay_locked():
		if Input.is_action_just_pressed("debug_cycle_weapon") and not debug_weapon_pool.is_empty():
			cycle_debug_weapon()
		if Input.is_action_just_pressed("debug_toggle"):
			_handle_debug_relic_helper()

		_handle_quick_consumables()
		_handle_interact_input()

	_update_focused_interactable()
	_update_iframes_blink(delta)

	if _hitstop_timer <= 0.0 and state_machine != null:
		state_machine.step_frame(delta)


func _physics_process(delta: float) -> void:
	_update_timers(delta)
	_update_camera_shake(delta)

	if _pending_hazard_teleport:
		return

	if _is_resolving_hazard and (state_machine == null or state_machine.get_current_state_name() != &"Dead"):
		_hazard_unlock_frames += 1
		if _hazard_unlock_frames >= 2 and not _is_overlapping_any_hazard():
			_is_resolving_hazard = false
			_hazard_unlock_frames = 0

	if _hitstop_timer > 0.0:
		var state_name: StringName = state_machine.get_current_state_name() if state_machine != null else &""
		var can_cancel_with_dash: bool = (state_name == &"Attack" or state_name == &"AirAttack") and has_buffered_dash() and can_dash()
		if can_cancel_with_dash:
			cancel_hitstop()
		else:
			_hitstop_timer = maxf(0.0, _hitstop_timer - delta)
			if _hitstop_timer <= 0.0 and animation_player != null:
				animation_player.speed_scale = _saved_anim_speed_scale if _saved_anim_speed_scale > 0.0 else 1.0
			return

	if state_machine != null:
		state_machine.step_physics(delta)

	_update_safe_anchor()


func _update_timers(delta: float) -> void:
	if GameState.is_gameplay_locked():
		_jump_buffer_timer = 0.0
		_attack_buffer_timer = 0.0
		_dash_buffer_timer = 0.0
		_relic_buffer_timer = 0.0
		_buffered_relic_id = &""
	else:
		if Input.is_action_just_pressed("jump"):
			_jump_buffer_timer = jump_buffer_duration
		elif _jump_buffer_timer > 0.0:
			_jump_buffer_timer = maxf(0.0, _jump_buffer_timer - delta)

		var atk_buf: float = attack_buffer_duration
		if equipped_weapon != null and equipped_weapon.combo_profile != null:
			atk_buf = maxf(atk_buf, equipped_weapon.combo_profile.input_buffer_sec)

		if Input.is_action_just_pressed("attack"):
			_attack_buffer_timer = atk_buf
		elif _attack_buffer_timer > 0.0:
			_attack_buffer_timer = maxf(0.0, _attack_buffer_timer - delta)

		if Input.is_action_just_pressed("dash"):
			_dash_buffer_timer = dash_buffer_duration
		elif _dash_buffer_timer > 0.0:
			_dash_buffer_timer = maxf(0.0, _dash_buffer_timer - delta)

		if Input.is_action_just_pressed("relic_1"):
			_buffered_relic_id = &"relic_cung_ten_vang"
			_relic_buffer_timer = relic_buffer_duration
		elif Input.is_action_just_pressed("relic_2"):
			_buffered_relic_id = &"relic_dan_than"
			_relic_buffer_timer = relic_buffer_duration
		elif _relic_buffer_timer > 0.0:
			_relic_buffer_timer = maxf(0.0, _relic_buffer_timer - delta)
			if _relic_buffer_timer <= 0.0:
				_buffered_relic_id = &""

	if _dash_cooldown_timer > 0.0:
		_dash_cooldown_timer = maxf(0.0, _dash_cooldown_timer - delta)
	if _relic_bow_cd_timer > 0.0:
		_relic_bow_cd_timer = maxf(0.0, _relic_bow_cd_timer - delta)
	if _relic_lute_cd_timer > 0.0:
		_relic_lute_cd_timer = maxf(0.0, _relic_lute_cd_timer - delta)
	if _relic_fail_toast_cd > 0.0:
		_relic_fail_toast_cd = maxf(0.0, _relic_fail_toast_cd - delta)

	if is_on_floor():
		_coyote_timer = coyote_time_duration
		_air_dash_available = true
		_air_stall_used = false
	elif _coyote_timer > 0.0:
		_coyote_timer = maxf(0.0, _coyote_timer - delta)

	var current_state_name: StringName = state_machine.get_current_state_name() if state_machine != null else &""
	if current_state_name != &"Attack" and _combo_window_timer > 0.0:
		_combo_window_timer = maxf(0.0, _combo_window_timer - delta)
		if _combo_window_timer <= 0.0:
			_combo_next_step = 0


func get_move_input_axis() -> float:
	if GameState.is_gameplay_locked():
		return 0.0
	return Input.get_axis("move_left", "move_right")


func update_facing(direction: float) -> void:
	if direction > 0.01:
		facing_direction = 1
		visual_root.scale.x = 1.0
	elif direction < -0.01:
		facing_direction = -1
		visual_root.scale.x = -1.0

	if hitbox_component != null:
		hitbox_component.set_facing_direction(facing_direction)


func apply_horizontal_movement(axis: float, accel: float, decel: float, delta: float) -> void:
	var target_vx: float = axis * move_speed
	var rate: float = accel if absf(axis) > 0.01 else decel
	velocity.x = move_toward(velocity.x, target_vx, rate * delta)


func apply_gravity(delta: float, gravity_scale: float = 1.0, max_fall_override: float = -1.0) -> void:
	var g: float = (jump_gravity if velocity.y < 0.0 else fall_gravity) * gravity_scale
	var fall_cap: float = max_fall_override if max_fall_override > 0.0 else max_fall_speed
	velocity.y = minf(velocity.y + g * delta, fall_cap)


func can_jump() -> bool:
	return is_on_floor() or _coyote_timer > 0.0


func has_buffered_jump() -> bool:
	return _jump_buffer_timer > 0.0


func consume_jump() -> void:
	velocity.y = jump_velocity
	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0


func has_buffered_attack() -> bool:
	return _attack_buffer_timer > 0.0


func consume_attack_buffer() -> void:
	_attack_buffer_timer = 0.0


func has_buffered_dash() -> bool:
	return _dash_buffer_timer > 0.0


func can_dash() -> bool:
	return _dash_cooldown_timer <= 0.0 and (is_on_floor() or _air_dash_available)


func consume_dash() -> void:
	_dash_buffer_timer = 0.0
	_dash_cooldown_timer = dash_cooldown
	if not is_on_floor():
		_air_dash_available = false


func get_dash_cooldown_left() -> float:
	return _dash_cooldown_timer


func has_used_air_stall() -> bool:
	return _air_stall_used


func mark_air_stall_used() -> void:
	_air_stall_used = true


func refresh_air_actions_on_pogo() -> void:
	_air_dash_available = true
	_air_stall_used = false
	_coyote_timer = 0.0


func get_next_combo_step() -> int:
	if _combo_window_timer <= 0.0:
		_combo_next_step = 0
	return _combo_next_step


func advance_or_wrap_combo(completed_step: int) -> void:
	var max_steps: int = 1
	var window_sec: float = 0.25
	if equipped_weapon != null and equipped_weapon.combo_profile != null:
		max_steps = maxi(1, equipped_weapon.combo_profile.max_steps)
		window_sec = equipped_weapon.combo_profile.combo_window_sec

	if completed_step + 1 < max_steps:
		_combo_next_step = completed_step + 1
		_combo_window_timer = window_sec
	else:
		_combo_next_step = 0
		_combo_window_timer = 0.0


func reset_combo() -> void:
	_combo_next_step = 0
	_combo_window_timer = 0.0


func get_basic_attack_damage(step_index: int = 0) -> int:
	var bonus: int = equipped_weapon.bonus_atk if equipped_weapon != null else weapon_atk
	var raw_dmg: float = float(base_atk + bonus)
	if equipped_weapon != null and equipped_weapon.combo_profile != null:
		raw_dmg *= equipped_weapon.combo_profile.get_step_damage_multiplier(step_index)
	return maxi(1, int(roundf(raw_dmg)))


func get_air_attack_damage(is_down_attack: bool) -> int:
	var bonus: int = equipped_weapon.bonus_atk if equipped_weapon != null else weapon_atk
	var raw_dmg: float = float(base_atk + bonus)
	if equipped_weapon != null and equipped_weapon.combo_profile != null:
		var mult: float = (
			equipped_weapon.combo_profile.air_down_damage_multiplier
			if is_down_attack
			else equipped_weapon.combo_profile.air_damage_multiplier
		)
		raw_dmg *= mult
	return maxi(1, int(roundf(raw_dmg)))


func equip_weapon(weapon: WeaponData) -> void:
	if weapon == null:
		return
	equipped_weapon = weapon
	weapon_atk = weapon.bonus_atk
	reset_combo()

	if weapon_sprite != null:
		weapon_sprite.centered = false
		weapon_sprite.texture = weapon.weapon_texture
		weapon_sprite.offset = -Vector2(weapon.grip_point_px)
		weapon_sprite.rotation_degrees = weapon.base_rotation_deg
		weapon_sprite.scale = Vector2.ONE

	if slash_vfx_sprite != null and weapon.slash_vfx_profile != null:
		var vfx: SlashVfxProfile = weapon.slash_vfx_profile
		if vfx.vfx_texture != null:
			slash_vfx_sprite.texture = vfx.vfx_texture
		slash_vfx_sprite.hframes = vfx.hframes
		slash_vfx_sprite.vframes = vfx.vframes
		slash_vfx_sprite.modulate = vfx.tint_color
		_default_vfx_offset = vfx.local_offset
		_default_vfx_rot = vfx.rotation_deg
		slash_vfx_sprite.position = _default_vfx_offset
		slash_vfx_sprite.rotation_degrees = _default_vfx_rot
		slash_vfx_sprite.flip_v = false
		slash_vfx_sprite.scale = Vector2.ONE

	_apply_hitbox_for_step(0)
	if weapon.id != &"" and GameState.has_weapon_id(weapon.id) and GameState.equipped_weapon_id != weapon.id:
		GameState.equip_weapon_by_id(weapon.id, true)
	weapon_equipped.emit(weapon)


func cycle_debug_weapon() -> void:
	if debug_weapon_pool.is_empty():
		return
	if state_machine != null:
		var s: StringName = state_machine.get_current_state_name()
		if s == &"Attack" or s == &"AirAttack":
			reset_combat_state()
			state_machine.transition_to(&"Idle" if is_on_floor() else &"Fall")

	var current_idx: int = debug_weapon_pool.find(equipped_weapon)
	var next_idx: int = (current_idx + 1) % debug_weapon_pool.size()
	equip_weapon(debug_weapon_pool[next_idx])


func play_locomotion_anim(anim_name: StringName) -> void:
	if animation_player == null or not animation_player.has_animation(anim_name):
		return
	animation_player.speed_scale = 1.0
	if animation_player.current_animation != anim_name or not animation_player.is_playing():
		animation_player.play(anim_name)


func prepare_ground_attack_step(step_index: int) -> StringName:
	if slash_vfx_sprite != null:
		slash_vfx_sprite.position = _default_vfx_offset
		slash_vfx_sprite.rotation_degrees = _default_vfx_rot
		slash_vfx_sprite.flip_v = (step_index % 2 == 1)

	_apply_hitbox_for_step(step_index)
	var anim_name: StringName = &"hammer_atk_1"
	var speed_scale: float = 1.0
	if equipped_weapon != null and equipped_weapon.animation_profile != null:
		anim_name = equipped_weapon.animation_profile.get_combo_anim(step_index)
		speed_scale = equipped_weapon.animation_profile.anim_speed_scale

	if animation_player != null:
		animation_player.speed_scale = speed_scale
	play_weapon_swing_sfx(step_index)
	return anim_name


func prepare_air_attack(is_down_attack: bool, air_step: int = 0) -> StringName:
	_apply_hitbox_for_air(is_down_attack)

	var anim_name: StringName = &"hammer_air"
	var speed_scale: float = 1.0
	var group: WeaponAnimProfile.WeaponGroup = WeaponAnimProfile.WeaponGroup.HAMMER

	if equipped_weapon != null and equipped_weapon.animation_profile != null:
		var ap: WeaponAnimProfile = equipped_weapon.animation_profile
		group = ap.weapon_group
		speed_scale = ap.anim_speed_scale
		anim_name = ap.air_down_attack_anim if is_down_attack else ap.get_air_combo_anim(air_step)

	if slash_vfx_sprite != null:
		if is_down_attack:
			match group:
				WeaponAnimProfile.WeaponGroup.POLEARM:
					slash_vfx_sprite.position = Vector2(2.0, 2.0)
					slash_vfx_sprite.rotation_degrees = 90.0
					slash_vfx_sprite.flip_v = false
				WeaponAnimProfile.WeaponGroup.BLADE:
					slash_vfx_sprite.position = Vector2(12.0, -6.0)
					slash_vfx_sprite.rotation_degrees = 40.0
					slash_vfx_sprite.flip_v = false
				_:
					slash_vfx_sprite.position = Vector2(6.0, -8.0)
					slash_vfx_sprite.rotation_degrees = 55.0
					slash_vfx_sprite.flip_v = false
		else:
			slash_vfx_sprite.position = _default_vfx_offset
			slash_vfx_sprite.rotation_degrees = _default_vfx_rot
			slash_vfx_sprite.flip_v = (air_step % 2 == 1)

	if animation_player != null:
		animation_player.speed_scale = speed_scale
	play_weapon_swing_sfx(air_step)
	return anim_name


func play_weapon_swing_sfx(step_index: int = 0) -> void:
	var group: WeaponAnimProfile.WeaponGroup = WeaponAnimProfile.WeaponGroup.HAMMER
	if equipped_weapon != null and equipped_weapon.animation_profile != null:
		group = equipped_weapon.animation_profile.weapon_group
	if group == WeaponAnimProfile.WeaponGroup.HAMMER or group == WeaponAnimProfile.WeaponGroup.AXE:
		var base_pitch: float = 0.94 + float(step_index) * 0.04
		AudioManager.play_sfx(&"swing_heavy", base_pitch, base_pitch + 0.06)
	else:
		var base_pitch: float = 0.96 + float(step_index) * 0.05
		AudioManager.play_sfx(&"swing_light", base_pitch, base_pitch + 0.07)


func _apply_hitbox_for_step(step_index: int) -> void:
	if hitbox_component == null:
		return
	var dmg: int = get_basic_attack_damage(step_index)
	if equipped_weapon != null and equipped_weapon.hitbox_profile != null:
		var hp: WeaponHitboxProfile = equipped_weapon.hitbox_profile
		hitbox_component.configure_hitbox(
			hp.get_step_size(step_index),
			hp.get_step_offset(step_index),
			hp.get_step_knockback(step_index),
			hp.get_step_hitstop(step_index),
			dmg
		)
	else:
		hitbox_component.damage = dmg
		hitbox_component.set_facing_direction(facing_direction)


func _apply_hitbox_for_air(is_down_attack: bool) -> void:
	if hitbox_component == null:
		return
	var dmg: int = get_air_attack_damage(is_down_attack)
	if equipped_weapon != null and equipped_weapon.hitbox_profile != null:
		var hp: WeaponHitboxProfile = equipped_weapon.hitbox_profile
		if is_down_attack:
			hitbox_component.configure_hitbox(
				hp.air_down_size,
				hp.air_down_offset,
				hp.air_down_knockback,
				hp.air_down_hitstop,
				dmg
			)
		else:
			hitbox_component.configure_hitbox(
				hp.air_size,
				hp.air_offset,
				hp.air_knockback,
				hp.air_hitstop,
				dmg
			)
	else:
		hitbox_component.damage = dmg
		hitbox_component.set_facing_direction(facing_direction)


func restore_mp(amount: int) -> void:
	if amount <= 0:
		return
	var next_mp: int = mini(max_mp, current_mp + amount)
	if next_mp != current_mp:
		current_mp = next_mp
		mp_changed.emit(current_mp, max_mp)


func spend_mp(amount: int) -> bool:
	if amount < 0 or current_mp < amount:
		return false
	current_mp -= amount
	mp_changed.emit(current_mp, max_mp)
	return true


func can_use_relic(relic_id: StringName) -> bool:
	return GameState.has_relic(relic_id) or sandbox_allow_unowned_relics


func get_relic_mp_cost(relic_id: StringName) -> int:
	if relic_id == &"relic_cung_ten_vang":
		return maxi(0, relic_bow_mp_cost)
	if relic_id == &"relic_dan_than":
		return maxi(0, relic_lute_mp_cost)
	return 0


func get_relic_bow_damage() -> int:
	var bonus: int = equipped_weapon.bonus_atk if equipped_weapon != null else weapon_atk
	return maxi(18, int(roundf(float(base_atk + bonus) * 1.35)))


func get_relic_lute_damage() -> int:
	var bonus: int = equipped_weapon.bonus_atk if equipped_weapon != null else weapon_atk
	return maxi(10, int(roundf(float(base_atk + bonus) * 0.80)))


func try_consume_buffered_relic() -> StringName:
	if _relic_buffer_timer <= 0.0 or _buffered_relic_id == &"":
		return &""

	var candidate: StringName = _buffered_relic_id
	_relic_buffer_timer = 0.0
	_buffered_relic_id = &""

	if not can_use_relic(candidate):
		var relic_title: String = "Cung Tên Vàng" if candidate == &"relic_cung_ten_vang" else "Đàn Thần"
		_notify_relic_unavailable("Chưa mở khóa Pháp bảo %s!" % relic_title)
		return &""

	if candidate == &"relic_cung_ten_vang" and _relic_bow_cd_timer > 0.0:
		return &""
	if candidate == &"relic_dan_than" and _relic_lute_cd_timer > 0.0:
		return &""

	var cost: int = get_relic_mp_cost(candidate)
	if current_mp < cost:
		_notify_relic_unavailable("Không đủ MP (%d/%d) để dùng Pháp bảo!" % [current_mp, cost])
		return &""

	if not spend_mp(cost):
		return &""

	if candidate == &"relic_cung_ten_vang":
		_relic_bow_cd_timer = relic_bow_cooldown
	elif candidate == &"relic_dan_than":
		_relic_lute_cd_timer = relic_lute_cooldown

	return candidate


func _notify_relic_unavailable(message: String) -> void:
	if _relic_fail_toast_cd > 0.0:
		return
	_relic_fail_toast_cd = 0.9
	EventBus.notification_requested.emit(message)


func _handle_debug_relic_helper() -> void:
	var in_sandbox: bool = get_parent() != null and get_parent().name == &"TestSandbox"
	if in_sandbox:
		sandbox_allow_unowned_relics = true
		restore_mp(max_mp)
		GameState.gourd_charges = GameState.max_gourd_charges
		EventBus.belt_updated.emit(GameState.belt_hp_count, GameState.max_belt_hp, GameState.belt_mp_count, GameState.max_belt_mp, GameState.gourd_charges, GameState.max_gourd_charges)
		EventBus.relics_updated.emit()
		EventBus.notification_requested.emit("[Debug F3] Đã hồi đầy MP & Niêu Cơm Thần!")
		return

	sandbox_allow_unowned_relics = not sandbox_allow_unowned_relics
	if sandbox_allow_unowned_relics:
		restore_mp(max_mp)
		GameState.gourd_charges = GameState.max_gourd_charges
		EventBus.belt_updated.emit(GameState.belt_hp_count, GameState.max_belt_hp, GameState.belt_mp_count, GameState.max_belt_mp, GameState.gourd_charges, GameState.max_gourd_charges)
		EventBus.notification_requested.emit("[Debug F3] Đã mở thử 3 Pháp bảo + hồi đầy MP!")
	else:
		EventBus.notification_requested.emit("[Debug F3] Đã tắt chế độ mở thử Pháp bảo.")
	EventBus.relics_updated.emit()


func _ensure_relic_sprite() -> Sprite2D:
	if relic_visual == null:
		return null
	if relic_sprite == null or not is_instance_valid(relic_sprite):
		relic_sprite = relic_visual.get_node_or_null("RelicSprite") as Sprite2D
	if relic_sprite == null:
		var spr: Sprite2D = Sprite2D.new()
		spr.name = "RelicSprite"
		spr.hframes = 2
		spr.scale = Vector2.ONE
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		relic_visual.add_child(spr)
		relic_sprite = spr
	return relic_sprite


func begin_relic_cast_visual(relic_id: StringName, aim_up: bool = false) -> void:
	if relic_visual == null:
		return
	if _relic_visual_tween != null and _relic_visual_tween.is_valid():
		_relic_visual_tween.kill()

	var spr: Sprite2D = _ensure_relic_sprite()
	if spr == null:
		return

	var shoot_up: bool = aim_up or Input.is_action_pressed("move_up")
	if relic_id == &"relic_cung_ten_vang":
		spr.texture = RELIC_CUNG_TEN_TEX
		relic_visual.position = Vector2(15.0, -18.0)
		relic_visual.rotation_degrees = -28.0 if shoot_up else 0.0
	elif relic_id == &"relic_dan_than":
		spr.texture = RELIC_DAN_THAN_TEX
		relic_visual.position = Vector2(12.0, -24.0)
		relic_visual.rotation_degrees = 0.0
	else:
		spr.texture = RELIC_NIEU_COM_TEX
		relic_visual.position = Vector2(10.0, -26.0)
		relic_visual.rotation_degrees = 0.0

	spr.hframes = 2
	spr.frame = 0
	spr.scale = Vector2.ONE
	relic_visual.scale = Vector2.ONE
	relic_visual.modulate = Color(1.25, 1.15, 0.78, 1.0)
	relic_visual.visible = true
	_relic_visual_tween = create_tween()
	_relic_visual_tween.tween_property(relic_visual, "modulate", Color.WHITE, 0.10)


func advance_relic_cast_visual_release(relic_id: StringName, aim_up: bool = false) -> void:
	var spr: Sprite2D = _ensure_relic_sprite()
	if spr != null:
		spr.frame = 1
	if relic_visual != null:
		relic_visual.visible = true
		relic_visual.scale = Vector2.ONE
		var shoot_up: bool = aim_up or Input.is_action_pressed("move_up")
		if relic_id == &"relic_cung_ten_vang" and shoot_up:
			relic_visual.rotation_degrees = -28.0
		relic_visual.modulate = Color(1.35, 1.25, 0.85, 1.0)


func show_gourd_relic_visual() -> void:
	if relic_visual == null:
		return
	if _relic_visual_tween != null and _relic_visual_tween.is_valid():
		_relic_visual_tween.kill()

	var spr: Sprite2D = _ensure_relic_sprite()
	if spr != null:
		spr.texture = RELIC_NIEU_COM_TEX
		spr.hframes = 2
		spr.frame = 0
		spr.scale = Vector2.ONE

	relic_visual.position = Vector2(10.0, -26.0)
	relic_visual.rotation_degrees = 0.0
	relic_visual.scale = Vector2.ONE
	relic_visual.modulate = Color(1.25, 1.18, 0.80, 1.0)
	relic_visual.visible = true

	_relic_visual_tween = create_tween()
	_relic_visual_tween.tween_property(relic_visual, "modulate", Color.WHITE, 0.14)
	_relic_visual_tween.tween_callback(func() -> void:
		if is_instance_valid(relic_sprite):
			relic_sprite.frame = 1
	)
	_relic_visual_tween.tween_interval(0.16)
	_relic_visual_tween.tween_property(relic_visual, "modulate:a", 0.0, 0.12)
	_relic_visual_tween.tween_callback(clear_relic_visual)


func fade_out_relic_visual(duration: float = 0.12) -> void:
	if relic_visual == null or not relic_visual.visible:
		return
	if _relic_visual_tween != null and _relic_visual_tween.is_valid():
		_relic_visual_tween.kill()
	_relic_visual_tween = create_tween()
	_relic_visual_tween.tween_property(relic_visual, "modulate:a", 0.0, maxf(0.02, duration))
	_relic_visual_tween.tween_callback(clear_relic_visual)


func clear_relic_visual() -> void:
	if _relic_visual_tween != null and _relic_visual_tween.is_valid():
		_relic_visual_tween.kill()
	_relic_visual_tween = null
	if relic_visual != null:
		relic_visual.visible = false
		relic_visual.rotation_degrees = 0.0
		relic_visual.scale = Vector2.ONE
		relic_visual.modulate = Color.WHITE
	if relic_sprite != null and is_instance_valid(relic_sprite):
		relic_sprite.frame = 0
		relic_sprite.scale = Vector2.ONE


func execute_relic_effect(relic_id: StringName, aim_up: bool = false) -> void:
	var spawn_parent: Node = get_parent()
	if spawn_parent == null:
		return

	if relic_id == &"relic_cung_ten_vang":
		if golden_arrow_scene == null:
			return
		var arrow: GoldenArrowProjectile = golden_arrow_scene.instantiate() as GoldenArrowProjectile
		if arrow == null:
			return
		var shoot_up: bool = aim_up or Input.is_action_pressed("move_up")
		var shoot_dir: Vector2 = (
			Vector2(float(facing_direction), -0.50).normalized()
			if shoot_up
			else Vector2(float(facing_direction), 0.0)
		)
		var chest_pos: Vector2 = global_position + Vector2(0.0, -16.0)
		var origin_pos: Vector2 = global_position + Vector2(float(facing_direction) * 14.0, -16.0)
		spawn_parent.add_child(arrow)
		arrow.setup_arrow(origin_pos, shoot_dir, get_relic_bow_damage(), Vector2(135.0, -35.0), chest_pos)
		AudioManager.play_sfx(&"relic_bow", 0.97, 1.04)
		trigger_camera_shake(Vector2(float(facing_direction), 0.0), 1.5, 0.07)

	elif relic_id == &"relic_dan_than":
		if dan_than_wave_scene == null:
			return
		var wave: DanThanSoundwave = dan_than_wave_scene.instantiate() as DanThanSoundwave
		if wave == null:
			return
		spawn_parent.add_child(wave)
		wave.setup_wave(global_position + Vector2(0.0, -14.0), facing_direction, get_relic_lute_damage(), 1.8)
		AudioManager.play_sfx(&"relic_lute", 0.98, 1.03)
		trigger_camera_shake(Vector2(0.0, 1.0), 2.0, 0.10)


func apply_hitstop(duration: float) -> void:
	if duration <= 0.0:
		return
	if _hitstop_timer <= 0.0 and animation_player != null:
		_saved_anim_speed_scale = animation_player.speed_scale if animation_player.speed_scale > 0.0 else 1.0
		animation_player.speed_scale = 0.0
	_hitstop_timer = maxf(_hitstop_timer, duration)


func cancel_hitstop() -> void:
	if _hitstop_timer <= 0.0:
		return
	_hitstop_timer = 0.0
	if animation_player != null:
		animation_player.speed_scale = _saved_anim_speed_scale if _saved_anim_speed_scale > 0.0 else 1.0


func suppress_current_hitstop() -> void:
	_suppress_next_hitstop = true


func is_in_hitstop() -> bool:
	return _hitstop_timer > 0.0


func trigger_camera_shake(direction: Vector2, intensity_px: float, duration: float) -> void:
	if camera == null or intensity_px <= 0.0 or duration <= 0.0:
		return
	_shake_dir = direction.normalized() if direction.length_squared() > 0.001 else Vector2(1.0, 0.0)
	_shake_intensity = maxf(_shake_intensity, intensity_px)
	_shake_duration = maxf(_shake_duration, duration)
	_shake_timer = maxf(_shake_timer, duration)


func _update_camera_shake(delta: float) -> void:
	if camera == null:
		return
	if _shake_timer <= 0.0:
		if camera.offset != Vector2.ZERO:
			camera.offset = Vector2.ZERO
		return

	_shake_timer = maxf(0.0, _shake_timer - delta)
	if _shake_timer <= 0.0:
		_shake_intensity = 0.0
		_shake_duration = 0.0
		camera.offset = Vector2.ZERO
		return

	var ratio: float = _shake_timer / maxf(0.001, _shake_duration)
	var sign_wave: float = 1.0 if int(floorf(_shake_timer * 60.0)) % 2 == 0 else -1.0
	var raw_offset: Vector2 = _shake_dir * (_shake_intensity * ratio * sign_wave)
	camera.offset = Vector2(roundf(raw_offset.x), roundf(raw_offset.y))


func spawn_hit_spark(world_pos: Vector2) -> void:
	if hit_spark_scene == null or get_parent() == null:
		return
	var spark: Node2D = hit_spark_scene.instantiate() as Node2D
	if spark == null:
		return
	spark.global_position = Vector2(roundf(world_pos.x), roundf(world_pos.y))
	get_parent().add_child(spark)


func spawn_dash_afterimage() -> void:
	if get_parent() == null or body_base_sprite == null or body_base_sprite.texture == null:
		return
	var ghost: Node2D = Node2D.new()
	ghost.global_position = Vector2(roundf(global_position.x), roundf(global_position.y))
	ghost.scale = Vector2(float(facing_direction), 1.0)
	ghost.z_index = -1

	var ghost_body: Sprite2D = Sprite2D.new()
	ghost_body.texture = body_base_sprite.texture
	ghost_body.hframes = body_base_sprite.hframes
	ghost_body.frame = body_base_sprite.frame
	ghost_body.centered = body_base_sprite.centered
	ghost_body.offset = body_base_sprite.offset
	ghost_body.modulate = Color(0.55, 0.85, 1.0, 0.55)
	ghost.add_child(ghost_body)

	get_parent().add_child(ghost)
	var tw: Tween = ghost.create_tween()
	tw.tween_property(ghost_body, "modulate:a", 0.0, 0.14)
	tw.tween_callback(ghost.queue_free)


func reset_combat_state() -> void:
	cancel_hitstop()
	if hitbox_component != null:
		hitbox_component.set_active(false)
	if animation_player != null:
		animation_player.speed_scale = 1.0
		if animation_player.has_animation(&"RESET"):
			animation_player.play(&"RESET")
			animation_player.advance(0.0)
	if slash_vfx_sprite != null:
		slash_vfx_sprite.visible = false
		slash_vfx_sprite.flip_v = false
		slash_vfx_sprite.position = _default_vfx_offset
		slash_vfx_sprite.rotation_degrees = _default_vfx_rot


func _on_hitbox_hit_landed(hurtbox: HurtboxComponent, damage_dealt: int) -> void:
	restore_mp(mp_gain_per_hit)
	AudioManager.play_sfx(&"hit_enemy", 0.94, 1.06)
	var impact_pos: Vector2 = (
		hurtbox.get_hurtbox_center()
		if hurtbox != null
		else global_position + Vector2(float(facing_direction) * 14.0, -14.0)
	)
	spawn_hit_spark(impact_pos)

	_suppress_next_hitstop = false
	melee_hit_landed.emit(hurtbox, damage_dealt)

	if not _suppress_next_hitstop and hitbox_component != null and hitbox_component.hitstop_duration > 0.0:
		apply_hitstop(hitbox_component.hitstop_duration)
	if not _suppress_next_hitstop:
		trigger_camera_shake(Vector2(float(facing_direction), 0.25), 1.5, 0.07)


func _on_player_damaged(_amount: int, knockback: Vector2, _source: Node2D) -> void:
	reset_combat_state()
	clear_relic_visual()
	reset_combo()
	_relic_buffer_timer = 0.0
	_buffered_relic_id = &""
	_play_hurt_flash()

	if _is_resolving_hazard:
		trigger_camera_shake(Vector2(0.0, 1.0), 3.0, 0.14)
		return

	AudioManager.play_sfx(&"player_hurt", 0.96, 1.04)
	spawn_hit_spark(global_position + Vector2(0.0, -14.0))
	trigger_camera_shake(Vector2(0.0, 1.0), 2.5, 0.12)
	if state_machine != null:
		if health_component != null and health_component.is_dead:
			state_machine.transition_to(&"Dead", {"cause": &"combat"})
		else:
			state_machine.transition_to(&"Hurt", {"knockback": knockback})


func notify_hazard_contact(hazard: HazardZone) -> void:
	if hazard == null or _is_resolving_hazard:
		return
	if health_component != null and health_component.is_dead:
		return
	if not hazard.contains_player_body(self):
		return

	_is_resolving_hazard = true
	_pending_hazard_teleport = true
	_hazard_unlock_frames = 0
	_execute_hazard_resolution.call_deferred(hazard)


func _execute_hazard_resolution(hazard: HazardZone) -> void:
	_pending_hazard_teleport = false
	if not is_inside_tree() or health_component == null:
		_is_resolving_hazard = false
		return

	reset_combat_state()
	clear_relic_visual()
	reset_combo()
	_jump_buffer_timer = 0.0
	_coyote_timer = 0.0
	_attack_buffer_timer = 0.0
	_dash_buffer_timer = 0.0
	_relic_buffer_timer = 0.0
	_buffered_relic_id = &""
	velocity = Vector2.ZERO

	var ratio: float = hazard.max_hp_damage_ratio if is_instance_valid(hazard) else 0.80
	var hazard_dmg: int = int(ceil(float(health_component.max_hp) * ratio))
	AudioManager.play_sfx(&"water_splash", 0.95, 1.05)
	var actual_dmg: int = health_component.take_damage(hazard_dmg, Vector2.ZERO, hazard, true)

	if health_component.current_hp <= 0 or health_component.is_dead:
		if state_machine != null:
			state_machine.transition_to(&"Dead", {"cause": &"hazard"})
		hazard_resolved.emit(actual_dmg, true)
		return

	var target_anchor: Vector2 = _safe_anchor_pos if _safe_anchor_pos != Vector2.ZERO else _initial_spawn_pos
	global_position = target_anchor
	velocity = Vector2.ZERO
	reset_physics_interpolation()
	if state_machine != null:
		state_machine.transition_to(&"Idle")

	var iframes_sec: float = hazard.respawn_iframes_duration if is_instance_valid(hazard) else 1.2
	health_component.start_invincibility(iframes_sec)
	_hazard_unlock_frames = 0
	hazard_resolved.emit(actual_dmg, false)


func respawn_at_sandbox_start() -> void:
	reset_combat_state()
	clear_relic_visual()
	reset_combo()
	_relic_buffer_timer = 0.0
	_buffered_relic_id = &""
	_relic_bow_cd_timer = 0.0
	_relic_lute_cd_timer = 0.0
	_is_resolving_hazard = false
	_pending_hazard_teleport = false
	_hazard_unlock_frames = 0
	_safe_ground_frames = 0
	if health_component != null:
		health_component.revive_full()
	current_mp = max_mp
	mp_changed.emit(current_mp, max_mp)
	global_position = _initial_spawn_pos
	_safe_anchor_pos = _initial_spawn_pos
	velocity = Vector2.ZERO
	reset_physics_interpolation()
	if visual_root != null:
		visual_root.modulate = Color.WHITE
	if state_machine != null:
		state_machine.transition_to(&"Idle")


func _configure_pixel_camera() -> void:
	if camera == null:
		return
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	camera.position_smoothing_enabled = false
	camera.drag_horizontal_enabled = true
	camera.drag_vertical_enabled = true
	camera.drag_left_margin = 0.0625
	camera.drag_right_margin = 0.0625
	camera.drag_top_margin = 16.0 / 108.0
	camera.drag_bottom_margin = 12.0 / 108.0


func _init_hazard_queries() -> void:
	var margin_shape: RectangleShape2D = RectangleShape2D.new()
	margin_shape.size = Vector2(12.0 + hazard_safe_margin_px * 2.0, 40.0)
	_hazard_margin_query = PhysicsShapeQueryParameters2D.new()
	_hazard_margin_query.shape = margin_shape
	_hazard_margin_query.collision_mask = 64  # Layer 7: Hazard
	_hazard_margin_query.collide_with_areas = true
	_hazard_margin_query.collide_with_bodies = false

	var body_shape: RectangleShape2D = RectangleShape2D.new()
	body_shape.size = Vector2(12.0, 26.0)
	_hazard_body_query = PhysicsShapeQueryParameters2D.new()
	_hazard_body_query.shape = body_shape
	_hazard_body_query.collision_mask = 64  # Layer 7: Hazard
	_hazard_body_query.collide_with_areas = true
	_hazard_body_query.collide_with_bodies = false


func _update_safe_anchor() -> void:
	if _is_resolving_hazard or (health_component != null and health_component.is_dead):
		_safe_ground_frames = 0
		return

	var current_state: StringName = state_machine.get_current_state_name() if state_machine != null else &""
	if current_state == &"Hurt" or current_state == &"Dead" or current_state == &"Dash" or current_state == &"AirAttack" or current_state == &"RelicCast":
		_safe_ground_frames = 0
		return

	if not is_on_floor() or absf(velocity.y) > 1.0:
		_safe_ground_frames = 0
		return

	if not _is_ray_on_static_ground(safe_ray_left) or not _is_ray_on_static_ground(safe_ray_right):
		_safe_ground_frames = 0
		return

	if _is_near_hazard_margin():
		_safe_ground_frames = 0
		return

	_safe_ground_frames += 1
	if _safe_ground_frames >= 2:
		_safe_anchor_pos = Vector2(roundf(global_position.x), roundf(global_position.y))


func _is_ray_on_static_ground(ray: RayCast2D) -> bool:
	if ray == null:
		return false
	ray.force_raycast_update()
	if not ray.is_colliding():
		return false

	var collider_node: Node = ray.get_collider() as Node
	if collider_node == null:
		return false
	if (
		collider_node.is_in_group(&"one_way_platforms")
		or collider_node.is_in_group(&"moving_platforms")
		or collider_node.is_in_group(&"crumbling_platforms")
	):
		return false
	if not (collider_node is TileMapLayer):
		return false

	var layer: TileMapLayer = collider_node as TileMapLayer
	var hit_pos: Vector2 = layer.to_local(ray.get_collision_point() + Vector2(0.0, 2.0))
	var coords: Vector2i = layer.local_to_map(hit_pos)
	var tile_data: TileData = layer.get_cell_tile_data(coords)
	if tile_data == null or tile_data.get_collision_polygons_count(0) <= 0:
		return false
	if tile_data.is_collision_polygon_one_way(0, 0):
		return false
	return true


func _is_near_hazard_margin() -> bool:
	if _hazard_margin_query == null or not is_inside_tree():
		return false
	var rect: RectangleShape2D = _hazard_margin_query.shape as RectangleShape2D
	if rect != null:
		var target_size: Vector2 = Vector2(12.0 + hazard_safe_margin_px * 2.0, 40.0)
		if not rect.size.is_equal_approx(target_size):
			rect.size = target_size
	_hazard_margin_query.transform = Transform2D(0.0, global_position + Vector2(0.0, 8.0))
	var hits: Array[Dictionary] = get_world_2d().direct_space_state.intersect_shape(_hazard_margin_query, 1)
	return not hits.is_empty()


func _is_overlapping_any_hazard() -> bool:
	if _hazard_body_query == null or not is_inside_tree():
		return false
	_hazard_body_query.transform = Transform2D(0.0, global_position + Vector2(0.0, -13.0))
	var hits: Array[Dictionary] = get_world_2d().direct_space_state.intersect_shape(_hazard_body_query, 1)
	return not hits.is_empty()


func _update_iframes_blink(delta: float) -> void:
	if visual_root == null:
		return
	if _hurt_flash_tween != null and _hurt_flash_tween.is_valid() and _hurt_flash_tween.is_running():
		return
	var current_state: StringName = state_machine.get_current_state_name() if state_machine != null else &""
	if health_component != null and health_component.is_invincible and not health_component.is_dead and current_state != &"Dash":
		_iframes_blink_elapsed += delta
		var blink_on: bool = int(floorf(_iframes_blink_elapsed * 16.0)) % 2 == 0
		visual_root.modulate.a = 0.45 if blink_on else 1.0
	else:
		_iframes_blink_elapsed = 0.0
		if not is_equal_approx(visual_root.modulate.a, 1.0):
			visual_root.modulate.a = 1.0


func get_safe_anchor() -> Vector2:
	return _safe_anchor_pos


func is_resolving_hazard() -> bool:
	return _is_resolving_hazard


func _play_hurt_flash() -> void:
	_flash_tint(Color(2.4, 0.65, 0.65, 1.0))


func _flash_tint(tint: Color) -> void:
	if visual_root == null:
		return
	if _hurt_flash_tween != null and _hurt_flash_tween.is_valid():
		_hurt_flash_tween.kill()
	visual_root.modulate = tint
	_hurt_flash_tween = create_tween()
	_hurt_flash_tween.tween_property(visual_root, "modulate", Color.WHITE, 0.16)


func _handle_quick_consumables() -> void:
	if health_component == null or health_component.is_dead:
		return
	var s: StringName = state_machine.get_current_state_name() if state_machine != null else &""
	if s == &"Hurt" or s == &"Dead":
		return

	if Input.is_action_just_pressed("heal_pot") and can_use_relic(&"relic_nieu_com"):
		if health_component.current_hp < health_component.max_hp:
			var heal_amt: int = GameState.consume_gourd()
			if heal_amt > 0:
				health_component.heal(heal_amt)
				_flash_tint(Color(1.2, 1.05, 0.45, 1.0))
				show_gourd_relic_visual()
				AudioManager.play_sfx(&"relic_gourd", 0.98, 1.04)
	elif Input.is_action_just_pressed("belt_hp"):
		if health_component.current_hp < health_component.max_hp:
			var heal_amt: int = GameState.consume_belt_hp()
			if heal_amt > 0:
				health_component.heal(heal_amt)
				_flash_tint(Color(0.55, 1.2, 0.55, 1.0))
				AudioManager.play_sfx(&"pickup_item", 1.02, 1.08)
	elif Input.is_action_just_pressed("belt_mp"):
		if current_mp < max_mp:
			var mp_amt: int = GameState.consume_belt_mp()
			if mp_amt > 0:
				restore_mp(mp_amt)
				_flash_tint(Color(0.55, 0.85, 1.25, 1.0))
				AudioManager.play_sfx(&"pickup_item", 1.02, 1.08)


func _on_health_component_hp_changed(new_hp: int, new_max_hp: int) -> void:
	GameState.max_hp = new_max_hp
	GameState.current_hp = new_hp
	EventBus.player_hp_changed.emit(new_hp, new_max_hp)


func _on_player_mp_changed_sync(new_mp: int, new_max_mp: int) -> void:
	GameState.max_mp = new_max_mp
	GameState.current_mp = new_mp
	EventBus.player_mp_changed.emit(new_mp, new_max_mp)


func _on_global_weapon_changed(weapon_id: StringName) -> void:
	if equipped_weapon != null and equipped_weapon.id == weapon_id:
		return
	var w: WeaponData = GameState.get_weapon_data(weapon_id)
	if w != null:
		equip_weapon(w)


func _on_global_level_changed(_new_level: int, _cur_exp: int, _next_exp: int) -> void:
	base_atk = GameState.base_atk
	max_mp = GameState.max_mp
	current_mp = GameState.current_mp
	mp_changed.emit(current_mp, max_mp)
	if health_component != null:
		health_component.max_hp = GameState.max_hp
		health_component.current_hp = GameState.current_hp
		health_component.hp_changed.emit(health_component.current_hp, health_component.max_hp)


func set_spawn_origin(world_pos: Vector2, dir: int = 1) -> void:
	global_position = world_pos
	_initial_spawn_pos = world_pos
	_safe_anchor_pos = world_pos
	velocity = Vector2.ZERO
	update_facing(float(dir))
	reset_physics_interpolation()


func register_interactable(area: InteractableArea) -> void:
	if area != null and not _nearby_interactables.has(area):
		_nearby_interactables.append(area)
		_update_focused_interactable()


func unregister_interactable(area: InteractableArea) -> void:
	if _nearby_interactables.has(area):
		_nearby_interactables.erase(area)
	if area != null and _focused_interactable == area:
		area.set_highlighted(false)
		_focused_interactable = null
	_update_focused_interactable()


func get_focused_interactable() -> InteractableArea:
	return _focused_interactable


func _update_focused_interactable() -> void:
	var best: InteractableArea = null
	var best_dist_sq: float = INF
	for i: int in range(_nearby_interactables.size() - 1, -1, -1):
		var item: InteractableArea = _nearby_interactables[i]
		if item == null or not is_instance_valid(item):
			_nearby_interactables.remove_at(i)
			continue
		if not item.interaction_enabled or GameState.ui_modal_open:
			continue
		var d_sq: float = global_position.distance_squared_to(item.global_position)
		if d_sq < best_dist_sq:
			best_dist_sq = d_sq
			best = item

	if _focused_interactable != best and _focused_interactable != null and is_instance_valid(_focused_interactable):
		_focused_interactable.set_highlighted(false)
	_focused_interactable = best
	if _focused_interactable != null:
		_focused_interactable.set_highlighted(not GameState.ui_modal_open)


func _handle_interact_input() -> void:
	if health_component == null or health_component.is_dead:
		return
	if not is_on_floor():
		return
	var current_state: StringName = state_machine.get_current_state_name() if state_machine != null else &""
	if current_state != &"Idle" and current_state != &"Run":
		return
	if Input.is_action_just_pressed("interact") and _focused_interactable != null and is_instance_valid(_focused_interactable):
		_focused_interactable.trigger_interact(self)


func try_drop_through_one_way() -> bool:
	if not is_on_floor():
		return false
	if not (Input.is_action_pressed("move_down") and Input.is_action_just_pressed("jump")):
		return false
	if not _is_standing_exclusively_on_one_way():
		return false

	position.y += drop_through_offset_px
	velocity.y = maxf(velocity.y, 45.0)
	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0
	return true


func _is_standing_exclusively_on_one_way() -> bool:
	var count: int = get_slide_collision_count()
	if count == 0:
		return false

	var found_floor_one_way: bool = false
	for i: int in range(count):
		var col: KinematicCollision2D = get_slide_collision(i)
		if col.get_normal().y >= -0.7:
			continue

		var collider_node: Node = col.get_collider() as Node
		if collider_node == null:
			return false

		if collider_node.is_in_group(&"one_way_platforms"):
			found_floor_one_way = true
		elif collider_node is TileMapLayer:
			var layer: TileMapLayer = collider_node as TileMapLayer
			var hit_pos: Vector2 = layer.to_local(col.get_position() + Vector2(0.0, 1.0))
			var coords: Vector2i = layer.local_to_map(hit_pos)
			var tile_data: TileData = layer.get_cell_tile_data(coords)
			if tile_data != null and tile_data.get_collision_polygons_count(0) > 0 and tile_data.is_collision_polygon_one_way(0, 0):
				found_floor_one_way = true
			else:
				return false
		else:
			return false

	return found_floor_one_way


func get_coyote_time_left() -> float:
	return _coyote_timer


func get_jump_buffer_left() -> float:
	return _jump_buffer_timer
