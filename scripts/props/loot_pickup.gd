class_name LootPickup
extends CharacterBody2D
## Vật phẩm rơi vật lý (Layer 8 Pickup): nảy trên đất, tắt nam châm hút, chạm trực tiếp mới nhặt, rơi Hazard sẽ mất.

enum PickupKind { GOLD, MATERIAL }

const GOLD_TEXTURE: Texture2D = preload("res://assets/sprites/vfx/pickup_gold_coin.png")
const HARD_WOOD_TEXTURE: Texture2D = preload("res://assets/sprites/vfx/pickup_hard_wood.png")
const IRON_ORE_TEXTURE: Texture2D = preload("res://assets/sprites/vfx/pickup_iron_ore.png")

@export var kind: PickupKind = PickupKind.GOLD
@export var amount: int = 5
@export var item_id: StringName = &""
@export var gravity: float = 760.0
@export var bounce_factor: float = 0.36
@export var ground_friction: float = 280.0
@export var pickup_arm_delay: float = 0.18
@export var lifetime_sec: float = 45.0
@export var abyss_kill_y: float = 420.0

@onready var _icon_sprite: Sprite2D = $IconSprite
@onready var _pickup_sensor: Area2D = $PickupSensor
@onready var _hazard_detector: Area2D = $HazardDetector

var _age_sec: float = 0.0
var _bounced_once: bool = false
var _collected_or_lost: bool = false


func _ready() -> void:
	collision_layer = 128  # Layer 8: Pickup
	collision_mask = 1     # Layer 1: World (chỉ đứng trên đất/sàn, không đẩy Player/Quái)
	if not is_in_group(&"loot_pickups"):
		add_to_group(&"loot_pickups")

	_apply_visual()

	if _pickup_sensor != null:
		_pickup_sensor.collision_layer = 0
		_pickup_sensor.collision_mask = 2  # Layer 2: PlayerBody
		_pickup_sensor.monitoring = true
		_pickup_sensor.monitorable = false
		if not _pickup_sensor.body_entered.is_connected(_on_pickup_sensor_body_entered):
			_pickup_sensor.body_entered.connect(_on_pickup_sensor_body_entered)

	if _hazard_detector != null:
		_hazard_detector.collision_layer = 0
		_hazard_detector.collision_mask = 64  # Layer 7: Hazard
		_hazard_detector.monitoring = true
		_hazard_detector.monitorable = false
		if not _hazard_detector.area_entered.is_connected(_on_hazard_area_entered):
			_hazard_detector.area_entered.connect(_on_hazard_area_entered)


func configure(p_kind: int, p_amount: int, p_item_id: StringName = &"", initial_velocity: Vector2 = Vector2.ZERO) -> void:
	kind = p_kind as PickupKind
	amount = maxi(1, p_amount)
	item_id = p_item_id
	velocity = initial_velocity
	if is_inside_tree():
		_apply_visual()


func _physics_process(delta: float) -> void:
	if _collected_or_lost:
		return

	_age_sec += delta
	if global_position.y >= abyss_kill_y:
		_lose_to_hazard()
		return
	if _age_sec >= lifetime_sec:
		_collected_or_lost = true
		queue_free()
		return

	if _hazard_detector != null and not _hazard_detector.get_overlapping_areas().is_empty():
		_lose_to_hazard()
		return

	if lifetime_sec - _age_sec <= 4.0 and _icon_sprite != null:
		_icon_sprite.visible = (int(_age_sec * 10.0) % 2) == 0

	var pre_vy: float = velocity.y
	velocity.y = minf(velocity.y + gravity * delta, 360.0)
	move_and_slide()

	if is_on_floor():
		if not _bounced_once and pre_vy > 45.0:
			velocity.y = -pre_vy * bounce_factor
			_bounced_once = true
		velocity.x = move_toward(velocity.x, 0.0, ground_friction * delta)

	if _age_sec >= pickup_arm_delay and _pickup_sensor != null:
		for body: Node2D in _pickup_sensor.get_overlapping_bodies():
			_try_collect(body)
			if _collected_or_lost:
				break


func _apply_visual() -> void:
	if _icon_sprite == null:
		return
	_icon_sprite.scale = Vector2.ONE
	if kind == PickupKind.GOLD:
		_icon_sprite.texture = GOLD_TEXTURE
		return

	var item: ItemData = GameState.get_item_data(item_id)
	if item != null and item.icon != null:
		_icon_sprite.texture = item.icon
	elif item_id == &"mat_iron_ore":
		_icon_sprite.texture = IRON_ORE_TEXTURE
	else:
		_icon_sprite.texture = HARD_WOOD_TEXTURE


func _on_pickup_sensor_body_entered(body: Node2D) -> void:
	_try_collect(body)


func _on_hazard_area_entered(_area: Area2D) -> void:
	_lose_to_hazard()


func _try_collect(body: Node2D) -> void:
	if _collected_or_lost or _age_sec < pickup_arm_delay:
		return
	if body == null or not body.is_in_group(&"player"):
		return
	if _hazard_detector != null and not _hazard_detector.get_overlapping_areas().is_empty():
		_lose_to_hazard()
		return

	var hc: HealthComponent = body.get_node_or_null("HealthComponent") as HealthComponent
	if hc != null and hc.is_dead:
		return

	_collected_or_lost = true
	if kind == PickupKind.GOLD:
		GameState.add_gold(amount)
		AudioManager.play_sfx(&"pickup_gold", 0.97, 1.08)
	elif item_id != &"":
		GameState.add_material(item_id, amount)
		AudioManager.play_sfx(&"pickup_item", 0.96, 1.05)
		var item_data: ItemData = GameState.get_item_data(item_id)
		var label_name: String = item_data.display_name if item_data != null else String(item_id)
		EventBus.notification_requested.emit("Nhặt +%d %s." % [amount, label_name])

	queue_free()


func _lose_to_hazard() -> void:
	if _collected_or_lost:
		return
	_collected_or_lost = true
	if _hazard_detector != null and not _hazard_detector.get_overlapping_areas().is_empty():
		AudioManager.play_sfx(&"water_splash", 1.25, 1.35, -8.0)
	queue_free()

