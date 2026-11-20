class_name AmbientGroundCritter
extends Sprite2D
## Thú rừng & gia cầm nền quê không va chạm vật lý: đứng gặm cỏ / mổ thóc xen kẽ chạy hoặc bật nhảy ngắn.

@export var idle_frame_start: int = 0
@export var idle_frame_count: int = 4
@export var move_frame_start: int = 4
@export var move_frame_count: int = 4
@export var idle_frame_duration: float = 0.24
@export var move_frame_duration: float = 0.13
@export var move_speed: float = 22.0
@export var roam_radius: float = 28.0
@export var hop_height_px: float = 0.0
@export var hop_frequency: float = 4.2
@export var flee_from_player: bool = false
@export var flee_trigger_distance: float = 54.0
@export var initial_facing: int = 1

var _home_pos: Vector2 = Vector2.ZERO
var _facing_dir: int = 1
var _is_moving: bool = false
var _state_timer: float = 1.2
var _anim_timer: float = 0.0
var _local_frame_idx: int = 0
var _hop_phase: float = 0.0
var _pos_x: float = 0.0
var _rng_seed: int = 1


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	scale = Vector2.ONE
	_home_pos = position
	_pos_x = position.x
	_facing_dir = 1 if initial_facing >= 0 else -1
	flip_h = (_facing_dir < 0)
	_rng_seed = int(absf(_home_pos.x * 13.0 + _home_pos.y * 7.0)) + 17
	_state_timer = 0.6 + float(_rng_seed % 11) * 0.16
	frame = clampi(idle_frame_start, 0, maxi(0, hframes - 1))


func _process(delta: float) -> void:
	scale = Vector2.ONE
	var player: Node2D = _find_player() if flee_from_player else null
	var min_x: float = _home_pos.x - roam_radius
	var max_x: float = _home_pos.x + roam_radius

	if player != null and is_instance_valid(player):
		var dist: float = global_position.distance_to(player.global_position)
		if dist <= flee_trigger_distance:
			var away_dir: int = -1 if player.global_position.x > global_position.x else 1
			var at_edge: bool = (away_dir < 0 and _pos_x <= min_x + 1.0) or (away_dir > 0 and _pos_x >= max_x - 1.0)
			if not at_edge:
				_is_moving = true
				_facing_dir = away_dir
				_state_timer = 0.45

	if _state_timer > 0.0:
		_state_timer -= delta
	else:
		_rng_seed = (_rng_seed * 1103515245 + 12345) & 0x7fffffff
		_is_moving = (_rng_seed % 3) != 0
		if _is_moving:
			if _pos_x <= min_x + 2.0:
				_facing_dir = 1
			elif _pos_x >= max_x - 2.0:
				_facing_dir = -1
			else:
				_facing_dir = 1 if ((_rng_seed >> 4) % 2) == 0 else -1
			_state_timer = 0.65 + float((_rng_seed >> 8) % 9) * 0.15
		else:
			_state_timer = 1.1 + float((_rng_seed >> 8) % 13) * 0.18
			_hop_phase = 0.0

	if _is_moving and roam_radius > 0.5:
		_pos_x += float(_facing_dir) * move_speed * delta
		if _pos_x <= min_x:
			_pos_x = min_x
			_facing_dir = 1
		elif _pos_x >= max_x:
			_pos_x = max_x
			_facing_dir = -1

	flip_h = (_facing_dir < 0)

	var hop_offset_y: float = 0.0
	if _is_moving and hop_height_px > 0.0:
		_hop_phase += delta * hop_frequency * PI
		hop_offset_y = -absf(sin(_hop_phase)) * hop_height_px
	else:
		_hop_phase = 0.0

	position = Vector2(roundf(_pos_x), roundf(_home_pos.y + hop_offset_y))

	# Animation frames
	var f_start: int = move_frame_start if _is_moving else idle_frame_start
	var f_count: int = maxi(1, move_frame_count if _is_moving else idle_frame_count)
	var f_dur: float = move_frame_duration if _is_moving else idle_frame_duration
	_anim_timer += delta
	if _anim_timer >= f_dur:
		_anim_timer = fmod(_anim_timer, f_dur)
		_local_frame_idx = (_local_frame_idx + 1) % f_count
	frame = clampi(f_start + (_local_frame_idx % f_count), 0, maxi(0, hframes - 1))


func _find_player() -> Node2D:
	var nodes: Array[Node] = get_tree().get_nodes_in_group(&"player")
	if nodes.is_empty():
		return null
	return nodes[0] as Node2D

