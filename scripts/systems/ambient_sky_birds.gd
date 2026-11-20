class_name AmbientSkyBirds
extends Node2D
## Đàn chim sẻ bay ngang bầu trời vào Bình Minh và Ban Ngày (ẩn lúc Hoàng Hôn & Ban Đêm).

@export var spawn_min_x: float = -40.0
@export var spawn_max_x: float = 980.0
@export var fly_min_y: float = 34.0
@export var fly_max_y: float = 92.0
@export var bird_count: int = 4
@export var bird_texture: Texture2D = preload("res://assets/sprites/scenery/critter_bird_fly.png")

var _birds: Array[Sprite2D] = []
var _speeds: Array[float] = []
var _base_ys: Array[float] = []
var _phases: Array[float] = []
var _anim_timer: float = 0.0
var _elapsed: float = 0.0


func _ready() -> void:
	_spawn_birds()
	if not EventBus.time_phase_changed.is_connected(_on_time_changed):
		EventBus.time_phase_changed.connect(_on_time_changed)
	if not EventBus.time_tick.is_connected(_on_time_tick):
		EventBus.time_tick.connect(_on_time_tick)
	_refresh_visibility()


func _spawn_birds() -> void:
	if bird_texture == null:
		return
	var span_x: float = maxf(64.0, spawn_max_x - spawn_min_x)
	var span_y: float = maxf(16.0, fly_max_y - fly_min_y)
	for i: int in range(maxi(1, bird_count)):
		var spr: Sprite2D = Sprite2D.new()
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		spr.texture = bird_texture
		spr.hframes = 8
		spr.frame = i % 8
		var bx: float = spawn_min_x + (float(i) / float(maxi(1, bird_count))) * span_x
		var by: float = fly_min_y + fposmod(float(i) * 0.37, 1.0) * span_y
		spr.position = Vector2(roundf(bx), roundf(by))
		add_child(spr)

		_birds.append(spr)
		_speeds.append(24.0 + float(i % 3) * 6.0)
		_base_ys.append(by)
		_phases.append(float(i) * 1.45)


func _process(delta: float) -> void:
	if not visible:
		return
	_elapsed += delta
	_anim_timer += delta
	var advance_frame: bool = false
	if _anim_timer >= 0.10:
		_anim_timer = fmod(_anim_timer, 0.10)
		advance_frame = true

	for i: int in range(_birds.size()):
		var spr: Sprite2D = _birds[i]
		if not is_instance_valid(spr):
			continue
		var next_x: float = spr.position.x + _speeds[i] * delta
		if next_x > spawn_max_x:
			next_x = spawn_min_x
		var bob_y: float = _base_ys[i] + sin(_elapsed * 2.2 + _phases[i]) * 3.0
		spr.position = Vector2(roundf(next_x), roundf(bob_y))
		if advance_frame:
			spr.frame = (spr.frame + 1) % spr.hframes


func _on_time_changed(_phase: int, _phase_name: String) -> void:
	_refresh_visibility()


func _on_time_tick(_progress: float, _phase: int) -> void:
	_refresh_visibility()


func _refresh_visibility() -> void:
	var should_show: bool = not TimeManager.are_lanterns_lit()
	visible = should_show
	set_process(should_show)

