class_name GoldenArrowProjectile
extends HitboxComponent
## Đạn mũi tên ánh sáng vàng từ Pháp bảo Cung Tên Vàng (Layer 4 PlayerHitbox, không hoàn MP cận chiến).

const HIT_SPARK_SCENE: PackedScene = preload("res://scenes/vfx/HitSpark.tscn")

@export var speed: float = 320.0
@export var max_lifetime: float = 1.25
@export var max_pierce_targets: int = 2

@onready var arrow_sprite: Sprite2D = $ArrowSprite

var _direction_vec: Vector2 = Vector2.RIGHT
var _pierced_count: int = 0
var _elapsed: float = 0.0
var _anim_timer: float = 0.0
var _finished: bool = false


func _ready() -> void:
	collision_layer = 8   # Layer 4: PlayerHitbox
	collision_mask = 0
	check_wall_obstruction = false
	continuous_contact = false
	super._ready()
	if not hit_landed.is_connected(_on_arrow_hit_landed):
		hit_landed.connect(_on_arrow_hit_landed)


func setup_arrow(
	origin: Vector2,
	dir_vec: Vector2,
	dmg: int,
	kb: Vector2 = Vector2(135.0, -35.0),
	caster_chest_pos: Vector2 = Vector2.INF
) -> void:
	_direction_vec = dir_vec.normalized() if dir_vec.length_squared() > 0.001 else Vector2.RIGHT
	facing_direction = 1 if _direction_vec.x >= 0.0 else -1
	base_offset = Vector2.ZERO
	damage = maxi(1, dmg)
	knockback_force = Vector2(absf(kb.x), kb.y)
	hitstop_duration = 0.03
	_pierced_count = 0
	_elapsed = 0.0
	_anim_timer = 0.0
	_finished = false

	global_position = Vector2(roundf(origin.x), roundf(origin.y))
	rotation = _direction_vec.angle()
	if arrow_sprite != null:
		arrow_sprite.scale = Vector2.ONE
		arrow_sprite.flip_v = (_direction_vec.x < 0.0)
		arrow_sprite.frame = 0

	if caster_chest_pos != Vector2.INF and is_inside_tree():
		var wall_hit: Vector2 = _find_solid_world_hit(caster_chest_pos, global_position)
		if wall_hit != Vector2.INF:
			_spawn_impact_spark(wall_hit)
			_finish_projectile()
			return

	set_active(true)


func _physics_process(delta: float) -> void:
	if _finished:
		return

	_elapsed += delta
	_anim_timer += delta
	if arrow_sprite != null and _anim_timer >= 0.07:
		_anim_timer = fmod(_anim_timer, 0.07)
		arrow_sprite.frame = 1 if arrow_sprite.frame == 0 else 0

	if _elapsed >= max_lifetime:
		_finish_projectile()
		return

	var next_pos: Vector2 = global_position + _direction_vec * speed * delta
	var wall_hit: Vector2 = _find_solid_world_hit(global_position, next_pos)
	if wall_hit != Vector2.INF:
		_spawn_impact_spark(wall_hit)
		_finish_projectile()
		return

	global_position = next_pos


func _find_solid_world_hit(from_pos: Vector2, to_pos: Vector2) -> Vector2:
	if not is_inside_tree() or from_pos.distance_squared_to(to_pos) < 0.04:
		return Vector2.INF

	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(from_pos, to_pos, 1)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.hit_from_inside = true

	var exclude_rids: Array[RID] = []
	for _attempt: int in range(4):
		query.exclude = exclude_rids
		var result: Dictionary = space_state.intersect_ray(query)
		if result.is_empty():
			return Vector2.INF

		var collider_node: Node = result.get("collider") as Node
		if collider_node != null and collider_node.is_in_group(&"one_way_platforms"):
			var hit_rid: RID = result.get("rid", RID()) as RID
			if hit_rid.is_valid() and not exclude_rids.has(hit_rid):
				exclude_rids.append(hit_rid)
				continue
		return result.get("position", to_pos) as Vector2

	return Vector2.INF


func _on_arrow_hit_landed(hurtbox: HurtboxComponent, _damage_dealt: int) -> void:
	AudioManager.play_sfx(&"hit_enemy", 1.02, 1.10)
	var impact_pos: Vector2 = hurtbox.get_hurtbox_center() if hurtbox != null else global_position
	_spawn_impact_spark(impact_pos)
	_pierced_count += 1
	if _pierced_count >= maxi(1, max_pierce_targets):
		_finish_projectile()


func _spawn_impact_spark(world_pos: Vector2) -> void:
	if HIT_SPARK_SCENE == null or get_parent() == null:
		return
	var spark: Node2D = HIT_SPARK_SCENE.instantiate() as Node2D
	if spark == null:
		return
	spark.global_position = Vector2(roundf(world_pos.x), roundf(world_pos.y))
	get_parent().add_child(spark)


func _finish_projectile() -> void:
	if _finished:
		return
	_finished = true
	set_active(false)
	queue_free()


func get_direction_vector() -> Vector2:
	return _direction_vec


func get_velocity() -> Vector2:
	return _direction_vec * speed
