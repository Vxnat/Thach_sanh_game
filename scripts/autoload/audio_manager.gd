extends Node
## Trung tâm điều phối âm thanh toàn cục (AudioManager Autoload): BGM, SFX đa âm & Ambience qua 3 bus riêng biệt.

const SFX_POOL_SIZE: int = 8
const BGM_DEFAULT_DB: float = -6.0
const AMBIENCE_DEFAULT_DB: float = -9.0

const BGM_PATHS: Dictionary = {
	&"bgm_loc_tri_village": "res://assets/audio/bgm/bgm_loc_tri_village.wav",
	&"bgm_rung_ven_lang": "res://assets/audio/bgm/bgm_rung_ven_lang.wav",
}

const AMBIENCE_PATHS: Dictionary = {
	&"amb_forest_day": "res://assets/audio/sfx/amb_forest_day.wav",
	&"amb_night_crickets": "res://assets/audio/sfx/amb_night_crickets.wav",
	&"amb_stream_flow": "res://assets/audio/sfx/amb_stream_flow.wav",
}

const SFX_PATHS: Dictionary = {
	&"swing_heavy": "res://assets/audio/sfx/sfx_swing_heavy.wav",
	&"swing_light": "res://assets/audio/sfx/sfx_swing_light.wav",
	&"hit_enemy": "res://assets/audio/sfx/sfx_hit_enemy.wav",
	&"slam_impact": "res://assets/audio/sfx/sfx_slam_impact.wav",
	&"jump": "res://assets/audio/sfx/sfx_jump.wav",
	&"dash": "res://assets/audio/sfx/sfx_dash.wav",
	&"player_hurt": "res://assets/audio/sfx/sfx_player_hurt.wav",
	&"water_splash": "res://assets/audio/sfx/sfx_water_splash.wav",
	&"pickup_gold": "res://assets/audio/sfx/sfx_pickup_gold.wav",
	&"pickup_item": "res://assets/audio/sfx/sfx_pickup_item.wav",
	&"chest_open": "res://assets/audio/sfx/sfx_chest_open.wav",
}

var _stream_cache: Dictionary = {}
var _bgm_player: AudioStreamPlayer = null
var _ambience_player: AudioStreamPlayer = null
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_pool_idx: int = 0

var _current_bgm_id: StringName = &""
var _current_ambience_id: StringName = &""
var _bgm_tween: Tween = null
var _ambience_tween: Tween = null
var _sfx_play_counts: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus_layout()
	_setup_players()
	_preload_streams()

	if not EventBus.time_phase_changed.is_connected(_on_time_phase_changed):
		EventBus.time_phase_changed.connect(_on_time_phase_changed)
	call_deferred(&"_sync_initial_scene_audio")


func _sync_initial_scene_audio() -> void:
	if _current_bgm_id != &"":
		return
	var cs: Node = get_tree().current_scene
	if cs == null:
		return
	var target_stage: String = "hub_loc_tri" if cs.name == "HubLocTri" else GameState.current_stage_id
	sync_stage_audio(target_stage)


func _ensure_bus_layout() -> void:
	if AudioServer.get_bus_index(&"BGM") < 0 and ResourceLoader.exists("res://default_bus_layout.tres"):
		var layout: AudioBusLayout = load("res://default_bus_layout.tres") as AudioBusLayout
		if layout != null:
			AudioServer.set_bus_layout(layout)


func _setup_players() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.name = "BgmPlayer"
	_bgm_player.bus = &"BGM"
	_bgm_player.volume_db = BGM_DEFAULT_DB
	_bgm_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_bgm_player)

	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.name = "AmbiencePlayer"
	_ambience_player.bus = &"Ambience"
	_ambience_player.volume_db = AMBIENCE_DEFAULT_DB
	_ambience_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_ambience_player)

	_sfx_pool.clear()
	for i: int in range(SFX_POOL_SIZE):
		var sfx_p: AudioStreamPlayer = AudioStreamPlayer.new()
		sfx_p.name = "SfxPlayer_%d" % i
		sfx_p.bus = &"SFX"
		sfx_p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(sfx_p)
		_sfx_pool.append(sfx_p)


func _preload_streams() -> void:
	for bgm_id: Variant in BGM_PATHS.keys():
		_load_and_cache(StringName(String(bgm_id)), String(BGM_PATHS[bgm_id]), true)
	for amb_id: Variant in AMBIENCE_PATHS.keys():
		_load_and_cache(StringName(String(amb_id)), String(AMBIENCE_PATHS[amb_id]), true)
	for sfx_id: Variant in SFX_PATHS.keys():
		_load_and_cache(StringName(String(sfx_id)), String(SFX_PATHS[sfx_id]), false)


func _load_and_cache(sound_id: StringName, path_str: String, should_loop: bool) -> AudioStream:
	if _stream_cache.has(sound_id):
		return _stream_cache[sound_id] as AudioStream
	if path_str == "" or not ResourceLoader.exists(path_str):
		return null
	var stream: AudioStream = load(path_str) as AudioStream
	if stream == null:
		return null
	if should_loop:
		var wav: AudioStreamWAV = stream as AudioStreamWAV
		if wav != null:
			wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
			wav.loop_begin = 0
			var bytes_per_frame: int = (2 if wav.format == AudioStreamWAV.FORMAT_16_BITS else 1) * (2 if wav.stereo else 1)
			@warning_ignore("integer_division")
			var total_frames: int = wav.data.size() / maxi(1, bytes_per_frame)
			wav.loop_end = maxi(1, total_frames)
	_stream_cache[sound_id] = stream
	return stream


func get_stream(sound_id: StringName) -> AudioStream:
	if _stream_cache.has(sound_id):
		return _stream_cache[sound_id] as AudioStream
	if BGM_PATHS.has(sound_id):
		return _load_and_cache(sound_id, String(BGM_PATHS[sound_id]), true)
	if AMBIENCE_PATHS.has(sound_id):
		return _load_and_cache(sound_id, String(AMBIENCE_PATHS[sound_id]), true)
	if SFX_PATHS.has(sound_id):
		return _load_and_cache(sound_id, String(SFX_PATHS[sound_id]), false)
	return null


func play_bgm(bgm_id: StringName, fade_sec: float = 0.30) -> void:
	if _bgm_player == null:
		return
	if bgm_id == _current_bgm_id and _bgm_player.playing:
		return
	var stream: AudioStream = get_stream(bgm_id)
	if stream == null:
		return

	if _bgm_tween != null and _bgm_tween.is_valid():
		_bgm_tween.kill()

	_current_bgm_id = bgm_id
	_bgm_player.stream = stream
	if fade_sec > 0.0:
		_bgm_player.volume_db = -28.0
		_bgm_player.play()
		_bgm_tween = create_tween()
		_bgm_tween.tween_property(_bgm_player, "volume_db", BGM_DEFAULT_DB, fade_sec)
	else:
		_bgm_player.volume_db = BGM_DEFAULT_DB
		_bgm_player.play()


func stop_bgm(fade_sec: float = 0.20) -> void:
	if _bgm_player == null:
		return
	if _bgm_tween != null and _bgm_tween.is_valid():
		_bgm_tween.kill()
	_current_bgm_id = &""
	if not _bgm_player.playing:
		return
	if fade_sec > 0.0:
		_bgm_tween = create_tween()
		_bgm_tween.tween_property(_bgm_player, "volume_db", -40.0, fade_sec)
		_bgm_tween.tween_callback(_bgm_player.stop)
	else:
		_bgm_player.stop()


func play_ambience(amb_id: StringName, fade_sec: float = 0.35) -> void:
	if _ambience_player == null:
		return
	if amb_id == _current_ambience_id and _ambience_player.playing:
		return
	var stream: AudioStream = get_stream(amb_id)
	if stream == null:
		return

	if _ambience_tween != null and _ambience_tween.is_valid():
		_ambience_tween.kill()

	_current_ambience_id = amb_id
	_ambience_player.stream = stream
	if fade_sec > 0.0:
		_ambience_player.volume_db = -30.0
		_ambience_player.play()
		_ambience_tween = create_tween()
		_ambience_tween.tween_property(_ambience_player, "volume_db", AMBIENCE_DEFAULT_DB, fade_sec)
	else:
		_ambience_player.volume_db = AMBIENCE_DEFAULT_DB
		_ambience_player.play()


func play_sfx(
	sfx_id: StringName,
	pitch_min: float = 0.96,
	pitch_max: float = 1.04,
	volume_offset_db: float = 0.0
) -> void:
	var stream: AudioStream = get_stream(sfx_id)
	if stream == null or _sfx_pool.is_empty():
		return

	var player_node: AudioStreamPlayer = null
	for p: AudioStreamPlayer in _sfx_pool:
		if not p.playing:
			player_node = p
			break
	if player_node == null:
		player_node = _sfx_pool[_sfx_pool_idx]
		_sfx_pool_idx = (_sfx_pool_idx + 1) % _sfx_pool.size()

	player_node.stream = stream
	player_node.pitch_scale = randf_range(minf(pitch_min, pitch_max), maxf(pitch_min, pitch_max))
	player_node.volume_db = volume_offset_db
	player_node.play()

	_sfx_play_counts[sfx_id] = int(_sfx_play_counts.get(sfx_id, 0)) + 1


func sync_stage_audio(stage_id: String = "") -> void:
	var target_stage: String = stage_id if stage_id != "" else GameState.current_stage_id
	var target_bgm: StringName = &"bgm_loc_tri_village" if target_stage == "hub_loc_tri" else &"bgm_rung_ven_lang"
	play_bgm(target_bgm, 0.30)

	var target_amb: StringName = &"amb_night_crickets" if TimeManager.is_night() else &"amb_forest_day"
	play_ambience(target_amb, 0.35)


func _on_time_phase_changed(_phase: int, _phase_name: String) -> void:
	var target_amb: StringName = &"amb_night_crickets" if TimeManager.is_night() else &"amb_forest_day"
	if _current_ambience_id != &"" or (_ambience_player != null and _ambience_player.playing):
		play_ambience(target_amb, 0.35)


func set_bus_volume_linear(bus_name: StringName, linear_val: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	var clamped: float = clampf(linear_val, 0.0, 1.5)
	AudioServer.set_bus_mute(idx, clamped <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(clamped, 0.001)))


func get_bus_volume_linear(bus_name: StringName) -> float:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx < 0 or AudioServer.is_bus_mute(idx):
		return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(idx))


func get_current_bgm_id() -> StringName:
	return _current_bgm_id


func get_current_ambience_id() -> StringName:
	return _current_ambience_id


func get_sfx_play_count(sfx_id: StringName) -> int:
	return int(_sfx_play_counts.get(sfx_id, 0))


func reset_sfx_counters() -> void:
	_sfx_play_counts.clear()


func get_bgm_player() -> AudioStreamPlayer:
	return _bgm_player


func get_ambience_player() -> AudioStreamPlayer:
	return _ambience_player


func get_sfx_pool() -> Array[AudioStreamPlayer]:
	return _sfx_pool
