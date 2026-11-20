class_name LoopingSprite
extends Sprite2D
## Sprite lặp frame đều nhẹ nhàng cho thú nuôi & chi tiết nền làng quê.

@export var frame_duration: float = 0.45

var _timer: float = 0.0


func _process(delta: float) -> void:
	if hframes <= 1:
		return
	_timer += delta
	if _timer >= frame_duration:
		_timer = fmod(_timer, frame_duration)
		frame = (frame + 1) % hframes

