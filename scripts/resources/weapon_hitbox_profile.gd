class_name WeaponHitboxProfile
extends Resource
## Cấu hình kích thước, độ lệch vị trí, đẩy lùi và hitstop cho từng nhịp đánh của vũ khí.

@export var step_sizes: Array[Vector2] = [Vector2(22.0, 22.0)]
@export var step_offsets: Array[Vector2] = [Vector2(15.0, -13.0)]
@export var step_knockbacks: Array[Vector2] = [Vector2(115.0, -45.0)]
@export var step_hitstops: PackedFloat32Array = PackedFloat32Array([0.04])

@export var air_size: Vector2 = Vector2(22.0, 20.0)
@export var air_offset: Vector2 = Vector2(14.0, -14.0)
@export var air_knockback: Vector2 = Vector2(105.0, -35.0)
@export var air_hitstop: float = 0.035

@export var air_down_size: Vector2 = Vector2(24.0, 22.0)
@export var air_down_offset: Vector2 = Vector2(6.0, 4.0)
@export var air_down_knockback: Vector2 = Vector2(125.0, -60.0)
@export var air_down_hitstop: float = 0.05


func get_step_size(step_index: int) -> Vector2:
	if step_sizes.is_empty():
		return Vector2(22.0, 20.0)
	return step_sizes[clampi(step_index, 0, step_sizes.size() - 1)]


func get_step_offset(step_index: int) -> Vector2:
	if step_offsets.is_empty():
		return Vector2(15.0, -13.0)
	return step_offsets[clampi(step_index, 0, step_offsets.size() - 1)]


func get_step_knockback(step_index: int) -> Vector2:
	if step_knockbacks.is_empty():
		return Vector2(115.0, -45.0)
	return step_knockbacks[clampi(step_index, 0, step_knockbacks.size() - 1)]


func get_step_hitstop(step_index: int) -> float:
	if step_hitstops.is_empty():
		return 0.04
	return step_hitstops[clampi(step_index, 0, step_hitstops.size() - 1)]

