class_name WeaponAnimProfile
extends Resource
## Cấu hình nhóm chuyển động & chuỗi AnimationPlayer cho từng dòng vũ khí.

enum WeaponGroup { HAMMER, AXE, BLADE, POLEARM }

@export var weapon_group: WeaponGroup = WeaponGroup.HAMMER
@export var ground_combo_anims: Array[StringName] = [&"hammer_atk_1"]
@export var air_attack_anim: StringName = &"hammer_air"
@export var air_combo_anims: Array[StringName] = []
@export var air_down_attack_anim: StringName = &"hammer_slam"
@export var air_slam_land_anim: StringName = &""
@export_range(0.4, 2.5, 0.05) var anim_speed_scale: float = 1.0


func get_combo_anim(step_index: int) -> StringName:
	if ground_combo_anims.is_empty():
		return &"hammer_atk_1"
	var clamped: int = clampi(step_index, 0, ground_combo_anims.size() - 1)
	return ground_combo_anims[clamped]


func get_air_combo_count() -> int:
	if not air_combo_anims.is_empty():
		return air_combo_anims.size()
	return 1 if air_attack_anim != &"" else 0


func get_air_combo_anim(step_index: int) -> StringName:
	if not air_combo_anims.is_empty():
		var clamped: int = clampi(step_index, 0, air_combo_anims.size() - 1)
		return air_combo_anims[clamped]
	if air_attack_anim != &"":
		return air_attack_anim
	return &"hammer_air"


func get_group_label() -> String:
	match weapon_group:
		WeaponGroup.HAMMER:
			return "HAMMER"
		WeaponGroup.AXE:
			return "AXE"
		WeaponGroup.BLADE:
			return "BLADE"
		WeaponGroup.POLEARM:
			return "POLEARM"
	return "UNKNOWN"

