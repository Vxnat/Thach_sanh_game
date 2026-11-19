class_name VillageLantern
extends Node2D
## Đèn lồng Làng Lộc Trĩ tự bật ánh sáng ấm (#FFBA69) lúc hoàng hôn và ban đêm.

@onready var _flame_core: ColorRect = $FlameCore
@onready var _point_light: PointLight2D = $PointLight2D


func _ready() -> void:
	if not EventBus.time_phase_changed.is_connected(_on_time_changed):
		EventBus.time_phase_changed.connect(_on_time_changed)
	if not EventBus.time_tick.is_connected(_on_time_tick):
		EventBus.time_tick.connect(_on_time_tick)
	_refresh_light_state()


func _process(_delta: float) -> void:
	if _point_light != null and _point_light.enabled:
		var t: float = float(Time.get_ticks_msec()) * 0.006 + global_position.x * 0.13
		_point_light.energy = 1.12 + 0.08 * sin(t)


func _on_time_changed(_phase: int, _phase_name: String) -> void:
	_refresh_light_state()


func _on_time_tick(_progress: float, _phase: int) -> void:
	_refresh_light_state()


func _refresh_light_state() -> void:
	var lit: bool = TimeManager.are_lanterns_lit()
	if _point_light != null:
		_point_light.enabled = lit
	if _flame_core != null:
		_flame_core.visible = lit

