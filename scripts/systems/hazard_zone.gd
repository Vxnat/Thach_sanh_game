class_name HazardZone
extends Area2D
## Vùng nguy hiểm môi trường (Sông sâu / Vực thẳm, Layer 7) gây 80% Max HP và đưa Player về SafeAnchor.

@export_range(0.1, 1.0, 0.05) var max_hp_damage_ratio: float = 0.80
@export var respawn_iframes_duration: float = 1.2
@export var hazard_size: Vector2 = Vector2(48.0, 32.0)

@onready var _collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	collision_layer = 64  # Layer 7: Hazard
	collision_mask = 2    # Layer 2: PlayerBody
	monitoring = true
	monitorable = true
	if not is_in_group(&"hazards"):
		add_to_group(&"hazards")

	if _collision_shape != null:
		var rect: RectangleShape2D = _collision_shape.shape as RectangleShape2D
		if rect == null:
			rect = RectangleShape2D.new()
			rect.resource_local_to_scene = true
			_collision_shape.shape = rect
		elif not rect.resource_local_to_scene:
			rect = rect.duplicate() as RectangleShape2D
			rect.resource_local_to_scene = true
			_collision_shape.shape = rect
		rect.size = hazard_size

	body_entered.connect(_on_body_entered)


func contains_player_body(player: Player) -> bool:
	if player == null:
		return false
	var center: Vector2 = _collision_shape.global_position if _collision_shape != null else global_position
	var hazard_rect: Rect2 = Rect2(center - hazard_size * 0.5, hazard_size)
	var player_rect: Rect2 = Rect2(player.global_position + Vector2(-6.0, -26.0), Vector2(12.0, 26.0))
	return hazard_rect.intersects(player_rect)


func _physics_process(_delta: float) -> void:
	if not monitoring:
		return
	for body: Node2D in get_overlapping_bodies():
		var player: Player = body as Player
		if player != null and contains_player_body(player):
			player.notify_hazard_contact(self)


func _on_body_entered(body: Node2D) -> void:
	var player: Player = body as Player
	if player != null and contains_player_body(player):
		player.notify_hazard_contact(self)
