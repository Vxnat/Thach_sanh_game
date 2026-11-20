class_name StageEnemy
extends CharacterBody2D
## Lớp nền chung cho Quái: đồng bộ EnemyData, StatsComponent ngày/đêm, Choáng (Stun), Hazard, EXP & LootPickup.

const STUN_STARS_TEX: Texture2D = preload("res://assets/sprites/vfx/stun_stars.png")

@export var enemy_data: EnemyData
@export var patrol_enabled: bool = true
@export var gravity: float = 980.0
@export var knockback_friction: float = 650.0
@export var abyss_kill_y: float = 420.0
@export var hp_bar_max_width: float = 16.0
@export var ledge_ray_offset_x: float = 10.0
@export var stun_stars_offset: Vector2 = Vector2(0.0, -28.0)

@onready var visual_root: Node2D = $VisualRoot
@onready var body_sprite: Sprite2D = $VisualRoot/BodySprite
@onready var health_component: HealthComponent = $HealthComponent
@onready var stats_component: StatsComponent = $StatsComponent
@onready var hurtbox_component: HurtboxComponent = $HurtboxComponent
@onready var enemy_hitbox: HitboxComponent = $EnemyHitbox
@onready var hp_bar_fill: ColorRect = $HpBarBg/HpBarFill
@onready var ledge_ray: RayCast2D = $LedgeRay
@onready var hazard_detector: Area2D = $HazardDetector

var _spawn_x: float = 0.0
var _facing_dir: int = -1
var _knockback_lock_timer: float = 0.0
var _hitstop_timer: float = 0.0
var _stun_timer: float = 0.0
var _stun_anim_timer: float = 0.0
var _attack_cooldown_timer: float = 0.0
var _state_timer: float = 0.0
var _anim_timer: float = 0.0
var _is_dead: bool = false
var _drowned_in_hazard: bool = false
var _flash_tween: Tween = null
var _stun_indicator: Sprite2D = null


func _ready() -> void:
	collision_layer = 4  # Layer 3: EnemyBody
	collision_mask = 1   # Layer 1: World (xuyên thân PlayerBody)
	_spawn_x = global_position.x
	_anim_timer = fmod(absf(global_position.x * 0.019), 0.45)

	if enemy_data != null:
		if stats_component != null:
			stats_component.configure_from_enemy_data(enemy_data)
		if health_component != null:
			health_component.max_hp = maxi(1, enemy_data.max_hp)
			health_component.revive_full()

	if stats_component != null and not stats_component.stats_recalculated.is_connected(_on_stats_recalculated):
		stats_component.stats_recalculated.connect(_on_stats_recalculated)
	if hurtbox_component != null and not hurtbox_component.hurt.is_connected(_on_hurt):
		hurtbox_component.hurt.connect(_on_hurt)
	if health_component != null:
		if not health_component.hp_changed.is_connected(_on_hp_changed):
			health_component.hp_changed.connect(_on_hp_changed)
		if not health_component.died.is_connected(_on_died):
			health_component.died.connect(_on_died)
	if hazard_detector != null:
		hazard_detector.collision_layer = 0
		hazard_detector.collision_mask = 64  # Layer 7: Hazard
		hazard_detector.monitoring = true
		hazard_detector.monitorable = false
		if not hazard_detector.area_entered.is_connected(_on_hazard_entered):
			hazard_detector.area_entered.connect(_on_hazard_entered)

	_apply_facing(_facing_dir)
	_update_hp_bar()
	if stats_component != null:
		_on_stats_recalculated(
			stats_component.get_effective_atk(),
			stats_component.get_effective_move_speed(),
			stats_component.is_night_buff_active()
		)
	if enemy_hitbox != null:
		enemy_hitbox.set_active(true)


func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	if global_position.y >= abyss_kill_y:
		_kill_by_hazard()
		return
	if hazard_detector != null and not hazard_detector.get_overlapping_areas().is_empty():
		_kill_by_hazard()
		return

	if _hitstop_timer > 0.0:
		_hitstop_timer = maxf(0.0, _hitstop_timer - delta)
		return

	if _attack_cooldown_timer > 0.0:
		_attack_cooldown_timer = maxf(0.0, _attack_cooldown_timer - delta)
	if _state_timer > 0.0:
		_state_timer = maxf(0.0, _state_timer - delta)

	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, 360.0)

	if _stun_timer > 0.0:
		_stun_timer = maxf(0.0, _stun_timer - delta)
		_stun_anim_timer += delta
		if _stun_indicator != null:
			_stun_indicator.visible = true
			if _stun_anim_timer >= 0.16:
				_stun_anim_timer = fmod(_stun_anim_timer, 0.16)
				_stun_indicator.frame = 1 if _stun_indicator.frame == 0 else 0
		if _knockback_lock_timer > 0.0:
			_knockback_lock_timer = maxf(0.0, _knockback_lock_timer - delta)
		velocity.x = move_toward(velocity.x, 0.0, knockback_friction * delta)
		move_and_slide()
		if _stun_timer <= 0.0:
			if _stun_indicator != null:
				_stun_indicator.visible = false
			if enemy_hitbox != null and not _is_dead:
				enemy_hitbox.set_active(true)
		return

	if _knockback_lock_timer > 0.0:
		_knockback_lock_timer = maxf(0.0, _knockback_lock_timer - delta)
		velocity.x = move_toward(velocity.x, 0.0, knockback_friction * delta)
	else:
		_step_ai(delta)

	move_and_slide()


func _step_ai(delta: float) -> void:
	if patrol_enabled:
		var spd: float = stats_component.get_effective_move_speed() if stats_component != null else 45.0
		_move_patrol(spd)
	else:
		velocity.x = move_toward(velocity.x, 0.0, knockback_friction * delta)


func update_patrol_idle_anim(delta: float, move_interval: float = 0.17, idle_interval: float = 0.48) -> void:
	if body_sprite == null:
		return
	var interval: float = move_interval if absf(velocity.x) > 2.0 else idle_interval
	_anim_timer += delta
	if _anim_timer >= interval:
		_anim_timer = fmod(_anim_timer, interval)
		body_sprite.frame = 1 if body_sprite.frame == 0 else 0


func _move_patrol(speed: float) -> void:
	if not is_on_floor():
		return
	var patrol_dist: float = enemy_data.patrol_distance if enemy_data != null else 32.0
	if is_on_wall() or _is_at_ledge():
		_facing_dir = -_facing_dir
		_apply_facing(_facing_dir)
	elif global_position.x >= _spawn_x + patrol_dist:
		_apply_facing(-1)
	elif global_position.x <= _spawn_x - patrol_dist:
		_apply_facing(1)

	if _is_at_ledge():
		velocity.x = 0.0
	else:
		velocity.x = float(_facing_dir) * speed


func _move_toward_x(target_x: float, speed: float) -> void:
	var dx: float = target_x - global_position.x
	if absf(dx) <= 4.0:
		velocity.x = 0.0
		return
	_apply_facing(1 if dx > 0.0 else -1)
	if is_on_floor() and _is_at_ledge():
		velocity.x = 0.0
	else:
		velocity.x = float(_facing_dir) * speed


func _is_at_ledge() -> bool:
	if ledge_ray == null:
		return false
	ledge_ray.position.x = ledge_ray_offset_x * float(_facing_dir)
	ledge_ray.force_raycast_update()
	return not ledge_ray.is_colliding()


func _apply_facing(dir: int) -> void:
	_facing_dir = 1 if dir >= 0 else -1
	if visual_root != null:
		visual_root.scale.x = float(_facing_dir)
	if ledge_ray != null:
		ledge_ray.position.x = ledge_ray_offset_x * float(_facing_dir)


func _find_alive_player() -> Node2D:
	var list: Array[Node] = get_tree().get_nodes_in_group(&"player")
	for node: Node in list:
		var p: Node2D = node as Node2D
		if p == null:
			continue
		var hc: HealthComponent = p.get_node_or_null("HealthComponent") as HealthComponent
		if hc != null and hc.is_dead:
			continue
		return p
	return null


func modify_incoming_damage(_hitbox: HitboxComponent, raw_damage: int) -> int:
	return raw_damage


func _interrupt_ai_on_hurt() -> bool:
	return true


func _on_hurt_interrupted() -> void:
	pass


func apply_hitstop(duration: float) -> void:
	if duration > 0.0 and not _is_dead:
		_hitstop_timer = maxf(_hitstop_timer, duration)


func is_stunned() -> bool:
	return _stun_timer > 0.0 and not _is_dead


func apply_stun(duration: float) -> void:
	if duration <= 0.0 or _is_dead:
		return
	_stun_timer = maxf(_stun_timer, duration)
	_stun_anim_timer = 0.0
	_on_stun_applied()
	if enemy_hitbox != null:
		enemy_hitbox.set_active(false)
	var ind: Sprite2D = _ensure_stun_indicator()
	if ind != null:
		ind.visible = true
		ind.frame = 0


func _on_stun_applied() -> void:
	_on_hurt_interrupted()


func _ensure_stun_indicator() -> Sprite2D:
	if _stun_indicator != null and is_instance_valid(_stun_indicator):
		return _stun_indicator
	var spr: Sprite2D = Sprite2D.new()
	spr.name = "StunStars"
	spr.texture = STUN_STARS_TEX
	spr.hframes = 2
	spr.frame = 0
	spr.scale = Vector2.ONE
	spr.z_index = 5
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.position = stun_stars_offset
	spr.visible = false
	add_child(spr)
	_stun_indicator = spr
	return _stun_indicator


func _on_stats_recalculated(effective_atk: int, _effective_speed: float, is_night_buffed: bool) -> void:
	if enemy_hitbox != null:
		enemy_hitbox.damage = effective_atk
	_update_night_visual(is_night_buffed)


func _update_night_visual(is_night_buffed: bool) -> void:
	if body_sprite != null:
		body_sprite.modulate = Color(1.16, 1.02, 1.26, 1.0) if is_night_buffed else Color.WHITE


func _on_hurt(hitbox: HitboxComponent, _actual_damage: int, knockback: Vector2) -> void:
	if _is_dead:
		return

	var kb_res: float = clampf(enemy_data.knockback_resistance, 0.0, 0.9) if enemy_data != null else 0.0
	velocity = knockback * (1.0 - kb_res)
	if _interrupt_ai_on_hurt():
		_knockback_lock_timer = 0.16 * (1.0 - kb_res * 0.5)
		_on_hurt_interrupted()
	if hitbox != null and hitbox.hitstop_duration > 0.0:
		apply_hitstop(hitbox.hitstop_duration)
	_play_hit_flash()


func _on_hp_changed(_cur: int, _max_hp: int) -> void:
	_update_hp_bar()


func _update_hp_bar() -> void:
	if hp_bar_fill == null or health_component == null:
		return
	var ratio: float = float(health_component.current_hp) / float(maxi(1, health_component.max_hp))
	hp_bar_fill.size.x = hp_bar_max_width * clampf(ratio, 0.0, 1.0)


func _play_hit_flash() -> void:
	if visual_root == null:
		return
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	visual_root.modulate = Color(2.5, 2.5, 2.5, 1.0)
	_flash_tween = create_tween()
	_flash_tween.tween_property(visual_root, "modulate", Color.WHITE, 0.12)


func _on_hazard_entered(_area: Area2D) -> void:
	_kill_by_hazard()


func _kill_by_hazard() -> void:
	if _is_dead or health_component == null:
		return
	_drowned_in_hazard = true
	health_component.take_damage(health_component.max_hp * 10, Vector2.ZERO, null, true)


func _on_died() -> void:
	if _is_dead:
		return
	_is_dead = true
	_hitstop_timer = 0.0
	_stun_timer = 0.0
	if _stun_indicator != null and is_instance_valid(_stun_indicator):
		_stun_indicator.visible = false
	velocity = Vector2.ZERO

	if enemy_hitbox != null:
		enemy_hitbox.set_active(false)
	if hurtbox_component != null:
		hurtbox_component.set_deferred(&"monitoring", false)
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()

	var eid: StringName = enemy_data.id if enemy_data != null else &""
	var exp_gain: int = enemy_data.exp_reward if enemy_data != null else 10
	GameState.add_exp(exp_gain)

	var gold_amt: int = 0
	var mat_id: StringName = &""
	var mat_cnt: int = 0
	if enemy_data != null:
		gold_amt = stats_component.compute_gold_drop(enemy_data.gold_min, enemy_data.gold_max) if stats_component != null else enemy_data.gold_min
		var is_night: bool = stats_component != null and stats_component.is_night_buff_active()
		var drop_chance: float = enemy_data.drop_chance_night if is_night else enemy_data.drop_chance_day
		if enemy_data.drop_item_id != &"" and randf() <= drop_chance:
			mat_id = enemy_data.drop_item_id
			mat_cnt = 1

	if not _drowned_in_hazard:
		var spawn_parent: Node = get_parent() if get_parent() != null else null
		if spawn_parent != null:
			LootDropSystem.spawn_burst(spawn_parent, global_position + Vector2(0.0, -8.0), gold_amt, mat_id, mat_cnt, 42.0)

	EventBus.enemy_killed.emit(eid, exp_gain, gold_amt)

	if visual_root != null:
		var death_tween: Tween = create_tween()
		death_tween.set_parallel(true)
		death_tween.tween_property(visual_root, "modulate:a", 0.0, 0.12)
		death_tween.tween_property(visual_root, "scale", Vector2(0.8 * visual_root.scale.x, 0.2), 0.12)
		death_tween.set_parallel(false)
		death_tween.tween_callback(queue_free)
	else:
		queue_free()
