extends Node
## Quản lý chu kỳ Sáng - Chiều - Tối (TimeManager Autoload, ~14 phút/ngày đêm) & buff ban đêm.

enum TimePhase { DAWN = 0, DAY = 1, DUSK = 2, NIGHT = 3 }

const DAY_LENGTH_SECONDS: float = 840.0
const PHASE_DAWN_END: float = 120.0
const PHASE_DAY_END: float = 480.0
const PHASE_DUSK_END: float = 600.0

const COLOR_DAWN: Color = Color("ffd7ba")
const COLOR_DAY: Color = Color("ffffff")
const COLOR_DUSK_ORANGE: Color = Color("e89f71")
const COLOR_DUSK_PURPLE: Color = Color("b57ba6")
const COLOR_NIGHT: Color = Color("4a5685")

var time_paused: bool = false
var _elapsed_day_seconds: float = PHASE_DAWN_END
var _last_phase: int = TimePhase.DAY


func _ready() -> void:
	_last_phase = get_current_phase()


func _process(delta: float) -> void:
	if time_paused:
		return
	_elapsed_day_seconds = fposmod(_elapsed_day_seconds + delta, DAY_LENGTH_SECONDS)
	var phase: int = get_current_phase()
	if phase != _last_phase:
		_last_phase = phase
		EventBus.time_phase_changed.emit(phase, get_phase_name_vi())
	EventBus.time_tick.emit(get_day_progress(), phase)


func get_current_phase() -> int:
	if _elapsed_day_seconds < PHASE_DAWN_END:
		return TimePhase.DAWN
	if _elapsed_day_seconds < PHASE_DAY_END:
		return TimePhase.DAY
	if _elapsed_day_seconds < PHASE_DUSK_END:
		return TimePhase.DUSK
	return TimePhase.NIGHT


func get_phase_name_vi() -> String:
	match get_current_phase():
		TimePhase.DAWN:
			return "Bình Minh"
		TimePhase.DAY:
			return "Ban Ngày"
		TimePhase.DUSK:
			return "Hoàng Hôn"
		TimePhase.NIGHT:
			return "Ban Đêm"
	return "Ban Ngày"


func get_day_progress() -> float:
	return clampf(_elapsed_day_seconds / DAY_LENGTH_SECONDS, 0.0, 1.0)


func is_night() -> bool:
	return get_current_phase() == TimePhase.NIGHT


func are_lanterns_lit() -> bool:
	var dusk_mid: float = (PHASE_DAY_END + PHASE_DUSK_END) * 0.5
	return _elapsed_day_seconds >= dusk_mid or _elapsed_day_seconds < 15.0


func get_enemy_stat_multiplier() -> float:
	return 1.20 if is_night() else 1.0


func get_gold_drop_multiplier() -> float:
	return 1.35 if is_night() else 1.0


func get_ambient_color() -> Color:
	var t: float = _elapsed_day_seconds
	if t < PHASE_DAWN_END:
		if t < 20.0:
			return COLOR_NIGHT.lerp(COLOR_DAWN, t / 20.0)
		if t > PHASE_DAWN_END - 25.0:
			return COLOR_DAWN.lerp(COLOR_DAY, (t - (PHASE_DAWN_END - 25.0)) / 25.0)
		return COLOR_DAWN
	if t < PHASE_DAY_END:
		return COLOR_DAY
	if t < PHASE_DUSK_END:
		var u: float = (t - PHASE_DAY_END) / (PHASE_DUSK_END - PHASE_DAY_END)
		if u < 0.5:
			return COLOR_DAY.lerp(COLOR_DUSK_ORANGE, u * 2.0)
		return COLOR_DUSK_ORANGE.lerp(COLOR_DUSK_PURPLE, (u - 0.5) * 2.0)

	if t < PHASE_DUSK_END + 20.0:
		return COLOR_DUSK_PURPLE.lerp(COLOR_NIGHT, (t - PHASE_DUSK_END) / 20.0)
	if t > DAY_LENGTH_SECONDS - 15.0:
		return COLOR_NIGHT.lerp(COLOR_DAWN, (t - (DAY_LENGTH_SECONDS - 15.0)) / 15.0)
	return COLOR_NIGHT


func sleep_toggle_day_night() -> void:
	var phase: int = get_current_phase()
	if phase == TimePhase.DUSK or phase == TimePhase.NIGHT:
		set_time_seconds(PHASE_DAWN_END)
	else:
		set_time_seconds(PHASE_DUSK_END + 20.0)


func set_time_seconds(sec: float) -> void:
	_elapsed_day_seconds = fposmod(sec, DAY_LENGTH_SECONDS)
	var phase: int = get_current_phase()
	if phase != _last_phase:
		_last_phase = phase
		EventBus.time_phase_changed.emit(phase, get_phase_name_vi())
	EventBus.time_tick.emit(get_day_progress(), phase)


func get_time_seconds() -> float:
	return _elapsed_day_seconds

