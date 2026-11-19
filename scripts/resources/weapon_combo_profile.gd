class_name WeaponComboProfile
extends Resource
## Cấu hình nhịp combo mặt đất và thông số vật lý không chiến riêng từng nhóm vũ khí.

@export var max_steps: int = 3
@export var step_damage_multipliers: PackedFloat32Array = PackedFloat32Array([1.0, 1.15, 1.4])
@export var step_lunge_speeds: PackedFloat32Array = PackedFloat32Array([0.0, 55.0, 75.0])
@export var combo_window_sec: float = 0.25
@export var input_buffer_sec: float = 0.12
@export var cancel_to_dash_after_sec: float = 0.12

@export_group("Thông số Không chiến (Bước 1.4)")
@export var air_damage_multiplier: float = 1.0
@export var air_down_damage_multiplier: float = 1.25
@export var has_air_slam: bool = false
@export var air_slam_speed: float = 340.0
@export var air_slam_horizontal_speed: float = 0.0
@export var air_slam_recovery_sec: float = 0.12
@export var has_air_stall: bool = false
@export var air_stall_gravity_scale: float = 0.25
@export var has_pogo_bounce: bool = false
@export var pogo_bounce_velocity: float = -265.0


func get_step_damage_multiplier(step_index: int) -> float:
	if step_damage_multipliers.is_empty():
		return 1.0
	return step_damage_multipliers[clampi(step_index, 0, step_damage_multipliers.size() - 1)]


func get_step_lunge_speed(step_index: int) -> float:
	if step_lunge_speeds.is_empty():
		return 0.0
	return step_lunge_speeds[clampi(step_index, 0, step_lunge_speeds.size() - 1)]

