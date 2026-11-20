class_name HazardZone
extends Area2D
## Vùng nguy hiểm môi trường (Sông sâu / Vực thẳm, Layer 7) gây 80% Max HP và đưa Player về SafeAnchor.

const WATER_ANIM_INTERVAL_SEC: float = 0.28
const WATER_SLICE_WIDTH_PX: float = 48.0

@export_range(0.1, 1.0, 0.05) var max_hp_damage_ratio: float = 0.80
@export var respawn_iframes_duration: float = 1.2
@export var hazard_size: Vector2 = Vector2(48.0, 32.0)

@onready var _collision_shape: CollisionShape2D = $CollisionShape2D
@onready var _water_sprite: Sprite2D = get_node_or_null("WaterSprite") as Sprite2D
@onready var _stream_audio: AudioStreamPlayer2D = get_node_or_null("StreamAudio") as AudioStreamPlayer2D

var _water_sprites: Array[Sprite2D] = []
var _water_anim_timer: float = 0.0


func _ready() -> void:
	collision_layer = 64  # Layer 7: Hazard
	collision_mask = 2    # Layer 2: PlayerBody
	monitoring = true
	monitorable = true
	if not is_in_group(&"hazards"):
		add_to_group(&"hazards")

	if _collision_shape != null:
		var rect: RectangleShape2D = _collision_shape.shape as RectangleShape2D
		if rect == null:
			rect = RectangleShape2D.new()
			rect.resource_local_to_scene = true
			_collision_shape.shape = rect
		elif not rect.resource_local_to_scene:
			rect = rect.duplicate() as RectangleShape2D
			rect.resource_local_to_scene = true
			_collision_shape.shape = rect
		rect.size = hazard_size

	_setup_water_sprites()
	body_entered.connect(_on_body_entered)

	if _stream_audio != null:
		var flow_stream: AudioStream = AudioManager.get_stream(&"amb_stream_flow")
		if flow_stream != null:
			_stream_audio.stream = flow_stream
			if not _stream_audio.playing:
				_stream_audio.play()


func _setup_water_sprites() -> void:
	if _water_sprite == null:
		return
	_water_sprites.clear()
	if hazard_size.x <= WATER_SLICE_WIDTH_PX:
		_water_sprite.position = Vector2.ZERO
		_water_sprites.append(_water_sprite)
		return

	var slice_count: int = maxi(1, int(ceilf(hazard_size.x / WATER_SLICE_WIDTH_PX)))
	var step_x: float = hazard_size.x / float(slice_count)
	var start_x: float = -hazard_size.x * 0.5 + step_x * 0.5
	_water_sprite.position = Vector2(roundf(start_x), 0.0)
	_water_sprites.append(_water_sprite)
	for i: int in range(1, slice_count):
		var extra: Sprite2D = Sprite2D.new()
		extra.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		extra.texture = _water_sprite.texture
		extra.hframes = _water_sprite.hframes
		extra.frame = _water_sprite.frame
		extra.position = Vector2(roundf(start_x + float(i) * step_x), 0.0)
		add_child(extra)
		_water_sprites.append(extra)


func _process(delta: float) -> void:
	if _water_sprites.is_empty():
		return
	_water_anim_timer += delta
	if _water_anim_timer >= WATER_ANIM_INTERVAL_SEC:
		_water_anim_timer = fmod(_water_anim_timer, WATER_ANIM_INTERVAL_SEC)
		for spr: Sprite2D in _water_sprites:
			if is_instance_valid(spr) and spr.hframes > 1:
				spr.frame = (spr.frame + 1) % spr.hframes


func contains_player_body(player: Player) -> bool:
	if player == null:
		return false
	var center: Vector2 = _collision_shape.global_position if _collision_shape != null else global_position
	var hazard_rect: Rect2 = Rect2(center - hazard_size * 0.5, hazard_size)
	var player_rect: Rect2 = Rect2(player.global_position + Vector2(-6.0, -26.0), Vector2(12.0, 26.0))
	return hazard_rect.intersects(player_rect)


func _physics_process(_delta: float) -> void:
	if not monitoring:
		return
	for body: Node2D in get_overlapping_bodies():
		var player: Player = body as Player
		if player != null and contains_player_body(player):
			player.notify_hazard_contact(self)


func _on_body_entered(body: Node2D) -> void:
	var player: Player = body as Player
	if player != null and contains_player_body(player):
		player.notify_hazard_contact(self)
