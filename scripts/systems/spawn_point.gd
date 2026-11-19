class_name SpawnPoint
extends Marker2D
## Điểm đặt nhân vật khi SceneRouter chuyển cảnh tới màn chơi.

@export var spawn_id: StringName = &"default"
@export_range(-1, 1) var facing_dir: int = 1


func _ready() -> void:
	if not is_in_group(&"spawn_points"):
		add_to_group(&"spawn_points")

