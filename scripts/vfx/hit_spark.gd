class_name HitSpark
extends Node2D
## Hiệu ứng tia lửa 1:1 pixel khi đánh trúng hoặc nhận sát thương, tự giải phóng sau 0.12s.

@export var frame_duration: float = 0.04

@onready var _sprite: Sprite2D = $Sprite2D

var _elapsed: float = 0.0


func _ready() -> void:
	if _sprite != null:
		_sprite.scale = Vector2.ONE
		_sprite.frame = 0


func _process(delta: float) -> void:
	_elapsed += delta
	if _sprite != null:
		var frame_idx: int = int(floorf(_elapsed / maxf(0.01, frame_duration)))
		if frame_idx >= _sprite.hframes:
			queue_free()
			return
		_sprite.frame = frame_idx
	elif _elapsed >= frame_duration * 3.0:
		queue_free()

