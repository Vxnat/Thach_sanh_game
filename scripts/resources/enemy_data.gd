class_name EnemyData
extends Resource
## Dữ liệu chỉ số và phần thưởng cho từng loại quái (tách rời code, dùng chung cho StatsComponent & LootDrop).

@export var id: StringName = &""
@export var display_name: String = ""

@export_group("Chỉ số chiến đấu")
@export var max_hp: int = 35
@export var base_atk: int = 12
@export var move_speed: float = 50.0
@export var aggro_range: float = 96.0
@export var attack_range: float = 36.0
@export var patrol_distance: float = 32.0
@export_range(0.0, 0.9, 0.05) var knockback_resistance: float = 0.0

@export_group("Phần thưởng & Rơi đồ")
@export var exp_reward: int = 15
@export var gold_min: int = 5
@export var gold_max: int = 9
@export var drop_item_id: StringName = &""
@export_range(0.0, 1.0, 0.05) var drop_chance_day: float = 0.35
@export_range(0.0, 1.0, 0.05) var drop_chance_night: float = 0.60

