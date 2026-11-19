class_name StatsComponent
extends Node
## Quản lý chỉ số chiến đấu (ATK, tốc độ, tỷ lệ vàng) và tự động áp dụng buff ban đêm từ TimeManager.

signal stats_recalculated(effective_atk: int, effective_speed: float, is_night_buffed: bool)

@export var is_enemy: bool = true
@export var base_max_hp: int = 35
@export var base_atk: int = 12
@export var base_move_speed: float = 50.0


func _ready() -> void:
	if not EventBus.time_phase_changed.is_connected(_on_time_phase_changed):
		EventBus.time_phase_changed.connect(_on_time_phase_changed)
	recalculate_stats()


func configure_from_enemy_data(data: EnemyData) -> void:
	if data == null:
		return
	is_enemy = true
	base_max_hp = maxi(1, data.max_hp)
	base_atk = maxi(1, data.base_atk)
	base_move_speed = maxf(0.0, data.move_speed)
	recalculate_stats()


func is_night_buff_active() -> bool:
	return is_enemy and TimeManager.is_night()


func get_effective_atk() -> int:
	if is_enemy:
		return maxi(1, int(roundf(float(base_atk) * TimeManager.get_enemy_stat_multiplier())))
	return base_atk


func get_effective_move_speed() -> float:
	if is_enemy:
		return base_move_speed * TimeManager.get_enemy_stat_multiplier()
	return base_move_speed


func compute_gold_drop(min_gold: int, max_gold: int, rng: RandomNumberGenerator = null) -> int:
	var lo: int = mini(min_gold, max_gold)
	var hi: int = maxi(min_gold, max_gold)
	if hi <= 0:
		return 0
	var base_gold: int = rng.randi_range(lo, hi) if rng != null else randi_range(lo, hi)
	if base_gold <= 0:
		return 0
	return maxi(1, int(roundf(float(base_gold) * TimeManager.get_gold_drop_multiplier())))


func recalculate_stats() -> void:
	stats_recalculated.emit(get_effective_atk(), get_effective_move_speed(), is_night_buff_active())


func _on_time_phase_changed(_phase: int, _phase_name: String) -> void:
	recalculate_stats()

