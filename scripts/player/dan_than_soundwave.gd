class_name DanThanSoundwave
extends HitboxComponent
## Sóng âm lan rộng 4 frame từ Pháp bảo Đàn Thần: đẩy lùi hướng tâm, làm choáng quái (1.8s) và đánh rớt đạn quái.

const HIT_SPARK_SCENE: PackedScene = preload("res://scenes/vfx/HitSpark.tscn")
const FRAME_RADII: Array[float] = [18.0, 28.0, 38.0, 46.0]

@export var frame_duration: float = 0.09
@export var stun_duration: float = 1.8

@onready var wave_sprite: Sprite2D = $WaveSprite

var _elapsed: float = 0.0
var _finished: bool = false
var _dispelled_projectiles_count: int = 0


func _ready() -> void:
	collision_layer = 8   # Layer 4: PlayerHitbox
	collision_mask = 16   # Layer 5: EnemyHitbox (đánh rớt đạn quái)
	check_wall_obstruction = true
	continuous_contact = false
	knockback_from_source_center = true
	base_offset = Vector2.ZERO
	source_ray_offset = Vector2.ZERO
	super._ready()
	monitoring = true
	monitorable = true
	if not hit_landed.is_connected(_on_wave_hit_landed):
		hit_landed.connect(_on_wave_hit_landed)
	if not area_entered.is_connected(_on_area_entered_wave):
		area_entered.connect(_on_area_entered_wave)


func setup_wave(origin: Vector2, caster_facing: int, dmg: int, stun_sec: float = 1.8) -> void:
	global_position = Vector2(roundf(origin.x), roundf(origin.y))
	facing_direction = 1 if caster_facing >= 0 else -1
	base_offset = Vector2.ZERO
	damage = maxi(1, dmg)
	knockback_force = Vector2(165.0, -65.0)
	hitstop_duration = 0.04
	stun_duration = maxf(0.1, stun_sec)
	_elapsed = 0.0
	_finished = false
	_dispelled_projectiles_count = 0

	_apply_frame_visual(0)
	set_active(true)
	_dispel_overlapping_enemy_projectiles()


func _physics_process(delta: float) -> void:
	if _finished:
		return

	_elapsed += delta
	var total_duration: float = frame_duration * float(FRAME_RADII.size())
	if _elapsed >= total_duration:
		_finish_wave()
		return

	var idx: int = clampi(int(floorf(_elapsed / maxf(0.01, frame_duration))), 0, FRAME_RADII.size() - 1)
	_apply_frame_visual(idx)
	_dispel_overlapping_enemy_projectiles()


func _apply_frame_visual(frame_idx: int) -> void:
	if wave_sprite != null:
		wave_sprite.scale = Vector2.ONE
		wave_sprite.frame = frame_idx
	if collision_shape != null:
		var circle: CircleShape2D = collision_shape.shape as CircleShape2D
		if circle != null:
			circle.radius = FRAME_RADII[frame_idx]
		collision_shape.position = Vector2.ZERO


func _on_area_entered_wave(area: Area2D) -> void:
	_try_dispel_enemy_projectile(area)


func _dispel_overlapping_enemy_projectiles() -> void:
	if not monitoring or not is_inside_tree():
		return
	for area: Area2D in get_overlapping_areas():
		_try_dispel_enemy_projectile(area)


func _try_dispel_enemy_projectile(area: Area2D) -> void:
	if _finished or area == null or not is_instance_valid(area) or area.is_queued_for_deletion():
		return
	if not area.is_in_group(&"enemy_projectiles"):
		return
	if _is_point_obstructed_by_world(area.global_position):
		return

	_dispelled_projectiles_count += 1
	_spawn_spark(area.global_position)
	if area.has_method(&"dispel_by_relic"):
		area.call(&"dispel_by_relic")
	else:
		area.queue_free()


func _is_point_obstructed_by_world(target_pos: Vector2) -> bool:
	if not is_inside_tree() or global_position.distance_squared_to(target_pos) < 1.0:
		return false
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position, target_pos, 1)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var exclude_rids: Array[RID] = []
	for _attempt: int in range(4):
		query.exclude = exclude_rids
		var result: Dictionary = space_state.intersect_ray(query)
		if result.is_empty():
			return false
		var collider_node: Node = result.get("collider") as Node
		if collider_node != null and collider_node.is_in_group(&"one_way_platforms"):
			var hit_rid: RID = result.get("rid", RID()) as RID
			if hit_rid.is_valid() and not exclude_rids.has(hit_rid):
				exclude_rids.append(hit_rid)
				continue
		return true
	return false


func _on_wave_hit_landed(hurtbox: HurtboxComponent, _damage_dealt: int) -> void:
	AudioManager.play_sfx(&"hit_enemy", 0.96, 1.04)
	var impact_pos: Vector2 = hurtbox.get_hurtbox_center() if hurtbox != null else global_position
	_spawn_spark(impact_pos)
	if hurtbox != null and hurtbox.owner != null and hurtbox.owner.has_method(&"apply_stun"):
		hurtbox.owner.call(&"apply_stun", stun_duration)


func _spawn_spark(world_pos: Vector2) -> void:
	if HIT_SPARK_SCENE == null or get_parent() == null:
		return
	var spark: Node2D = HIT_SPARK_SCENE.instantiate() as Node2D
	if spark == null:
		return
	spark.global_position = Vector2(roundf(world_pos.x), roundf(world_pos.y))
	get_parent().add_child(spark)


func get_dispelled_projectiles_count() -> int:
	return _dispelled_projectiles_count


func _finish_wave() -> void:
	if _finished:
		return
	_finished = true
	set_active(false)
	queue_free()

