class_name NightFireflies
extends Node2D
## Đom đóm làng quê & rừng đêm phát sáng nhẹ vào Hoàng Hôn và Ban Đêm.

@export var area_size: Vector2 = Vector2(320.0, 72.0)
@export var firefly_count: int = 12

var _dots: Array[ColorRect] = []
var _base_positions: Array[Vector2] = []
var _phases: Array[float] = []
var _speeds: Array[float] = []
var _elapsed: float = 0.0
var _add_mat: CanvasItemMaterial = null


func _ready() -> void:
	_add_mat = CanvasItemMaterial.new()
	_add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_spawn_fireflies()

	if not EventBus.time_phase_changed.is_connected(_on_time_changed):
		EventBus.time_phase_changed.connect(_on_time_changed)
	if not EventBus.time_tick.is_connected(_on_time_tick):
		EventBus.time_tick.connect(_on_time_tick)
	_refresh_visibility()


func _spawn_fireflies() -> void:
	var half_x: float = area_size.x * 0.5
	var seed_offset: float = global_position.x * 0.037 + global_position.y * 0.019
	for i: int in range(maxi(1, firefly_count)):
		var rect: ColorRect = ColorRect.new()
		rect.size = Vector2(2.0, 2.0)
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.material = _add_mat
		var use_gold: bool = (i % 3 != 0)
		rect.color = Color(0.97, 0.84, 0.41, 1.0) if use_gold else Color(0.61, 0.83, 0.41, 1.0)

		var u: float = fposmod(float(i) * 0.6180339 + seed_offset, 1.0)
		var v: float = fposmod(float(i) * 0.381966 + seed_offset * 1.3, 1.0)
		var base_pos: Vector2 = Vector2(-half_x + u * area_size.x, -v * area_size.y)
		rect.position = Vector2(roundf(base_pos.x), roundf(base_pos.y))
		add_child(rect)

		_dots.append(rect)
		_base_positions.append(base_pos)
		_phases.append(float(i) * 1.15 + seed_offset)
		_speeds.append(1.1 + fposmod(float(i) * 0.37, 0.9))


func _process(delta: float) -> void:
	if not visible:
		return
	_elapsed += delta
	for i: int in range(_dots.size()):
		var dot: ColorRect = _dots[i]
		if not is_instance_valid(dot):
			continue
		var phase: float = _phases[i]
		var spd: float = _speeds[i]
		var base_p: Vector2 = _base_positions[i]
		var ox: float = sin(_elapsed * spd + phase) * 5.0
		var oy: float = cos(_elapsed * (spd * 1.25) + phase * 1.7) * 3.0
		dot.position = Vector2(roundf(base_p.x + ox), roundf(base_p.y + oy))
		dot.modulate.a = clampf(0.42 + 0.58 * (0.5 + 0.5 * sin(_elapsed * 2.8 + phase * 2.1)), 0.15, 1.0)


func _on_time_changed(_phase: int, _phase_name: String) -> void:
	_refresh_visibility()


func _on_time_tick(_progress: float, _phase: int) -> void:
	_refresh_visibility()


func _refresh_visibility() -> void:
	var should_show: bool = TimeManager.are_lanterns_lit()
	visible = should_show
	set_process(should_show)

