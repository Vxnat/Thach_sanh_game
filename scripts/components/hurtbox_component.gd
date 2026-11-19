class_name HurtboxComponent
extends Area2D
## Vùng nhận sát thương lắng nghe HitboxComponent khác phe và chuyển tiếp vào HealthComponent.

signal hurt(hitbox: HitboxComponent, actual_damage: int, knockback: Vector2)

@export var health_component: HealthComponent

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	monitoring = true
	monitorable = false
	area_entered.connect(_on_area_entered)


func get_hurtbox_center() -> Vector2:
	if collision_shape != null:
		return collision_shape.global_position
	return global_position


func _physics_process(_delta: float) -> void:
	if not monitoring or health_component == null or health_component.is_dead or health_component.is_invincible:
		return
	for area: Area2D in get_overlapping_areas():
		_try_receive_hit(area)
		if health_component.is_dead or health_component.is_invincible:
			break


func _on_area_entered(area: Area2D) -> void:
	_try_receive_hit.call_deferred(area)


func _try_receive_hit(area: Area2D) -> void:
	if health_component == null or health_component.is_dead:
		return

	var hitbox: HitboxComponent = area as HitboxComponent
	if hitbox == null:
		return
	if not hitbox.can_hit_target(self):
		return

	var knockback: Vector2 = hitbox.get_directed_knockback_for(self)
	var source_node: Node2D = hitbox.owner as Node2D
	var incoming_damage: int = hitbox.damage
	if owner != null and owner.has_method(&"modify_incoming_damage"):
		incoming_damage = int(owner.call(&"modify_incoming_damage", hitbox, incoming_damage))
	if incoming_damage <= 0:
		return
	var dealt: int = health_component.take_damage(incoming_damage, knockback, source_node)
	if dealt > 0:
		hitbox.register_hit(self, dealt)
		hurt.emit(hitbox, dealt, knockback)

