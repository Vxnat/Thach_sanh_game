class_name DummyEnemy
extends CharacterBody2D
## Bia tập / quái khối thử nghiệm cho Bước 1.2 (Baseline Stats: 45 HP, xuyên thân Player).

@export var patrol_enabled: bool = false
@export var patrol_distance: float = 28.0
@export var patrol_speed: float = 32.0
@export var knockback_friction: float = 650.0
@export var gravity: float = 980.0
@export var contact_damage_enabled: bool = false
@export var contact_damage: int = 12

@onready var visual_root: Node2D = $VisualRoot
@onready var body_poly: Polygon2D = $VisualRoot/BodyPoly
@onready var crest_poly: Polygon2D = $VisualRoot/CrestPoly
@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox_component: HurtboxComponent = $HurtboxComponent
@onready var enemy_hitbox: HitboxComponent = $EnemyHitbox
@onready var hp_bar_fill: ColorRect = $HpBarBg/HpBarFill

var _spawn_x: float = 0.0
var _patrol_dir: int = 1
var _knockback_lock_timer: float = 0.0
var _hitstop_timer: float = 0.0
var _is_dead: bool = false
var _flash_tween: Tween = null


func _ready() -> void:
	collision_layer = 4  # Layer 3: EnemyBody
	collision_mask = 1   # Layer 1: World (xuyên thân PlayerBody)
	_spawn_x = position.x
	_update_hp_bar()

	if enemy_hitbox != null:
		enemy_hitbox.damage = contact_damage
		enemy_hitbox.set_active(contact_damage_enabled)
	if contact_damage_enabled:
		if body_poly != null:
			body_poly.color = Color(0.45, 0.16, 0.22, 1.0)
		if crest_poly != null:
			crest_poly.color = Color(0.75, 0.22, 0.26, 1.0)

	if hurtbox_component != null:
		hurtbox_component.hurt.connect(_on_hurt)
	if health_component != null:
		health_component.hp_changed.connect(_on_hp_changed)
		health_component.died.connect(_on_died)


func _physics_process(delta: float) -> void:
	if _is_dead:
		return
	if _hitstop_timer > 0.0:
		_hitstop_timer = maxf(0.0, _hitstop_timer - delta)
		return

	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, 360.0)

	if _knockback_lock_timer > 0.0:
		_knockback_lock_timer = maxf(0.0, _knockback_lock_timer - delta)
		velocity.x = move_toward(velocity.x, 0.0, knockback_friction * delta)
	elif patrol_enabled and is_on_floor():
		velocity.x = float(_patrol_dir) * patrol_speed
		if position.x >= _spawn_x + patrol_distance:
			_patrol_dir = -1
		elif position.x <= _spawn_x - patrol_distance:
			_patrol_dir = 1
		if visual_root != null:
			visual_root.scale.x = float(_patrol_dir)
	else:
		velocity.x = move_toward(velocity.x, 0.0, knockback_friction * delta)

	move_and_slide()


func apply_hitstop(duration: float) -> void:
	if duration > 0.0 and not _is_dead:
		_hitstop_timer = maxf(_hitstop_timer, duration)


func _on_hurt(hitbox: HitboxComponent, _actual_damage: int, knockback: Vector2) -> void:
	if _is_dead:
		return

	velocity = knockback
	_knockback_lock_timer = 0.16
	if hitbox != null and hitbox.hitstop_duration > 0.0:
		apply_hitstop(hitbox.hitstop_duration)
	_play_hit_flash()


func _on_hp_changed(_current_hp: int, _max_hp: int) -> void:
	_update_hp_bar()


func _update_hp_bar() -> void:
	if hp_bar_fill == null or health_component == null:
		return
	var ratio: float = float(health_component.current_hp) / float(maxi(1, health_component.max_hp))
	hp_bar_fill.size.x = 16.0 * clampf(ratio, 0.0, 1.0)


func _play_hit_flash() -> void:
	if visual_root == null:
		return
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	visual_root.modulate = Color(2.6, 2.6, 2.6, 1.0)
	_flash_tween = create_tween()
	_flash_tween.tween_property(visual_root, "modulate", Color.WHITE, 0.12)


func _on_died() -> void:
	if _is_dead:
		return
	_is_dead = true
	_hitstop_timer = 0.0
	velocity = Vector2.ZERO
	if enemy_hitbox != null:
		enemy_hitbox.set_active(false)
	if hurtbox_component != null:
		hurtbox_component.set_deferred(&"monitoring", false)
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()

	if visual_root != null:
		var death_tween: Tween = create_tween()
		death_tween.set_parallel(true)
		death_tween.tween_property(visual_root, "modulate:a", 0.0, 0.12)
		death_tween.tween_property(visual_root, "scale", Vector2(0.8 * visual_root.scale.x, 0.2), 0.12)
		death_tween.set_parallel(false)
		death_tween.tween_callback(queue_free)
	else:
		queue_free()

