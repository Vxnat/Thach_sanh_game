class_name DayNightLight
extends CanvasModulate
## Đồng bộ màu ánh sáng toàn cảnh (Bình Minh / Ban Ngày / Hoàng Hôn / Ban Đêm) theo TimeManager.

const SKY_DAWN: Color = Color(0.84, 0.65, 0.62, 1.0)
const SKY_DAY: Color = Color(0.53, 0.76, 0.90, 1.0)
const SKY_DUSK: Color = Color(0.62, 0.42, 0.56, 1.0)
const SKY_NIGHT: Color = Color(0.11, 0.14, 0.27, 1.0)

@export var sky_rect_path: NodePath

var _sky_rect: ColorRect = null


func _ready() -> void:
	if not sky_rect_path.is_empty():
		_sky_rect = get_node_or_null(sky_rect_path) as ColorRect
	_apply_colors()
	if not EventBus.time_tick.is_connected(_on_time_tick):
		EventBus.time_tick.connect(_on_time_tick)
	if not EventBus.time_phase_changed.is_connected(_on_phase_changed):
		EventBus.time_phase_changed.connect(_on_phase_changed)


func _on_time_tick(_day_progress: float, _phase: int) -> void:
	_apply_colors()


func _on_phase_changed(_phase: int, _phase_name: String) -> void:
	_apply_colors()


func _apply_colors() -> void:
	color = TimeManager.get_ambient_color()
	if _sky_rect != null:
		match TimeManager.get_current_phase():
			TimeManager.TimePhase.DAWN:
				_sky_rect.color = SKY_DAWN
			TimeManager.TimePhase.DAY:
				_sky_rect.color = SKY_DAY
			TimeManager.TimePhase.DUSK:
				_sky_rect.color = SKY_DUSK
			TimeManager.TimePhase.NIGHT:
				_sky_rect.color = SKY_NIGHT
