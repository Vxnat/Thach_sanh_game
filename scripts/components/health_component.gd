class_name HealthComponent
extends Node
## Quản lý máu, trạng thái bất tử (i-frames) và cái chết cho Player/Quái.

signal hp_changed(current_hp: int, max_hp: int)
signal damaged(amount: int, knockback: Vector2, source: Node2D)
signal healed(amount: int)
signal died()

@export var max_hp: int = 100
@export var invincibility_duration: float = 0.0

var current_hp: int = 100
var is_invincible: bool = false
var is_dead: bool = false

var _invincibility_timer: float = 0.0


func _ready() -> void:
	current_hp = maxi(1, max_hp)
	is_dead = false
	is_invincible = false
	hp_changed.emit(current_hp, max_hp)


func _physics_process(delta: float) -> void:
	if is_invincible and _invincibility_timer > 0.0:
		_invincibility_timer = maxf(0.0, _invincibility_timer - delta)
		if _invincibility_timer <= 0.0:
			is_invincible = false


func take_damage(
	amount: int,
	knockback: Vector2 = Vector2.ZERO,
	source: Node2D = null,
	bypass_iframes: bool = false
) -> int:
	if is_dead or amount <= 0:
		return 0
	if is_invincible and not bypass_iframes:
		return 0

	var prev_hp: int = current_hp
	current_hp = maxi(0, current_hp - amount)
	var actual_damage: int = prev_hp - current_hp

	hp_changed.emit(current_hp, max_hp)
	damaged.emit(actual_damage, knockback, source)

	if current_hp <= 0:
		is_dead = true
		is_invincible = false
		_invincibility_timer = 0.0
		died.emit()
	elif invincibility_duration > 0.0 and not bypass_iframes:
		start_invincibility(invincibility_duration)

	return actual_damage


func heal(amount: int) -> int:
	if is_dead or amount <= 0:
		return 0

	var prev_hp: int = current_hp
	current_hp = mini(max_hp, current_hp + amount)
	var actual_heal: int = current_hp - prev_hp
	if actual_heal > 0:
		hp_changed.emit(current_hp, max_hp)
		healed.emit(actual_heal)
	return actual_heal


func start_invincibility(duration: float) -> void:
	if duration <= 0.0 or is_dead:
		return
	is_invincible = true
	_invincibility_timer = maxf(_invincibility_timer, duration)


func revive_full() -> void:
	is_dead = false
	is_invincible = false
	_invincibility_timer = 0.0
	current_hp = maxi(1, max_hp)
	hp_changed.emit(current_hp, max_hp)

