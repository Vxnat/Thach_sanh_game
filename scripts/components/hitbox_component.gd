class_name HitboxComponent
extends Area2D
## Vùng gây sát thương tái sử dụng cho Player và Quái, điều khiển bật/tắt theo timeline.

signal hit_landed(hurtbox: HurtboxComponent, damage_dealt: int)

@export var damage: int = 15
@export var knockback_force: Vector2 = Vector2(115.0, -45.0)
@export var hitstop_duration: float = 0.04
@export var base_offset: Vector2 = Vector2(15.0, -13.0)
@export var source_ray_offset: Vector2 = Vector2(0.0, -13.0)
@export var check_wall_obstruction: bool = true
@export var continuous_contact: bool = false
@export var knockback_from_source_center: bool = false
@export var active: bool = false: set = set_active

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var facing_direction: int = 1
var _hit_targets: Array[int] = []


func _ready() -> void:
	monitoring = false
	monitorable = true
	set_facing_direction(facing_direction)
	set_active(active)


func set_active(value: bool) -> void:
	var was_active: bool = active
	active = value
	if active and not was_active:
		_hit_targets.clear()
	if collision_shape != null:
		collision_shape.set_deferred(&"disabled", not active)


func set_facing_direction(dir: int) -> void:
	facing_direction = 1 if dir >= 0 else -1
	if collision_shape != null:
		collision_shape.position = Vector2(base_offset.x * float(facing_direction), base_offset.y)


func configure_hitbox(
	hit_size: Vector2,
	offset_vec: Vector2,
	kb: Vector2,
	hitstop: float,
	dmg: int
) -> void:
	damage = dmg
	knockback_force = kb
	hitstop_duration = hitstop
	base_offset = offset_vec

	if collision_shape != null:
		var rect: RectangleShape2D = collision_shape.shape as RectangleShape2D
		if rect == null:
			rect = RectangleShape2D.new()
			rect.resource_local_to_scene = true
			collision_shape.shape = rect
		elif not rect.resource_local_to_scene:
			rect = rect.duplicate() as RectangleShape2D
			rect.resource_local_to_scene = true
			collision_shape.shape = rect
		rect.size = hit_size

	set_facing_direction(facing_direction)


func clear_hit_targets() -> void:
	_hit_targets.clear()


func get_directed_knockback() -> Vector2:
	return Vector2(knockback_force.x * float(facing_direction), knockback_force.y)


func get_directed_knockback_for(hurtbox: HurtboxComponent) -> Vector2:
	if not knockback_from_source_center or hurtbox == null:
		return get_directed_knockback()
	var dx: float = hurtbox.get_hurtbox_center().x - global_position.x
	var dir: float = 1.0 if dx > 0.5 else (-1.0 if dx < -0.5 else float(facing_direction))
	return Vector2(knockback_force.x * dir, knockback_force.y)


func can_hit_target(hurtbox: HurtboxComponent) -> bool:
	if not active or hurtbox == null:
		return false

	var target_id: int = hurtbox.get_instance_id()
	if not continuous_contact and _hit_targets.has(target_id):
		return false

	if owner != null and hurtbox.owner == owner:
		return false

	if check_wall_obstruction and _is_obstructed_by_world(hurtbox):
		return false

	return true


func register_hit(hurtbox: HurtboxComponent, damage_dealt: int) -> void:
	if hurtbox == null:
		return
	var target_id: int = hurtbox.get_instance_id()
	if not _hit_targets.has(target_id):
		_hit_targets.append(target_id)
	hit_landed.emit(hurtbox, damage_dealt)


func _is_obstructed_by_world(hurtbox: HurtboxComponent) -> bool:
	var source_node: Node2D = owner as Node2D
	var origin: Vector2 = (
		source_node.global_position + source_ray_offset
		if source_node != null
		else global_position
	)
	var target_pos: Vector2 = hurtbox.get_hurtbox_center()
	if origin.distance_squared_to(target_pos) < 1.0:
		return false

	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(origin, target_pos, 1)
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

