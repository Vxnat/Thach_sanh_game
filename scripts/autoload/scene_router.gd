extends Node
## Điều phối chuyển cảnh mượt (fade đen), đặt SpawnPoint và xử lý 0 HP (SceneRouter Autoload).

var _fade_layer: CanvasLayer = null
var _fade_rect: ColorRect = null
var _is_transitioning: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fade_layer = CanvasLayer.new()
	_fade_layer.name = "SceneRouterFadeLayer"
	_fade_layer.layer = 100
	add_child(_fade_layer)

	_fade_rect = ColorRect.new()
	_fade_rect.name = "FadeRect"
	_fade_rect.color = Color(0.0, 0.0, 0.0, 1.0)
	_fade_rect.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_layer.add_child(_fade_rect)


func is_transitioning() -> bool:
	return _is_transitioning


func transition_to_stage(stage_id: String, spawn_id: StringName = &"default", fade_duration: float = 0.16) -> bool:
	if _is_transitioning:
		return false
	_is_transitioning = true

	var scene_path: String = GameState.get_stage_scene_path(stage_id)
	var old_player: Node = _find_player_in_current_scene()
	if old_player != null:
		var hc: Node = old_player.get_node_or_null("HealthComponent")
		if hc != null and not bool(hc.get("is_dead")):
			GameState.current_hp = int(hc.get("current_hp"))
			GameState.current_mp = int(old_player.get("current_mp"))

	if fade_duration > 0.0 and _fade_rect != null:
		var tw_out: Tween = create_tween()
		tw_out.tween_property(_fade_rect, "modulate:a", 1.0, fade_duration)
		await tw_out.finished
	elif _fade_rect != null:
		_fade_rect.modulate.a = 1.0

	var err: Error = get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_warning("SceneRouter không thể mở cảnh: %s" % scene_path)
		if _fade_rect != null:
			_fade_rect.modulate.a = 0.0
		_is_transitioning = false
		return false

	await get_tree().process_frame
	await get_tree().process_frame

	GameState.current_stage_id = stage_id
	GameState.last_spawn_id = spawn_id

	var target_spawn: SpawnPoint = _find_spawn_point(spawn_id)
	var new_player: Node = _find_player_in_current_scene()
	if new_player != null and target_spawn != null and new_player.has_method(&"set_spawn_origin"):
		new_player.call(&"set_spawn_origin", target_spawn.global_position, target_spawn.facing_dir)

	if fade_duration > 0.0 and _fade_rect != null:
		var tw_in: Tween = create_tween()
		tw_in.tween_property(_fade_rect, "modulate:a", 0.0, fade_duration)
		await tw_in.finished
	elif _fade_rect != null:
		_fade_rect.modulate.a = 0.0

	_is_transitioning = false
	return true


func handle_player_defeat(active_player: Node = null) -> void:
	var lost_gold: int = GameState.apply_defeat_gold_penalty(0.15)
	GameState.rest_at_village()
	if lost_gold > 0:
		EventBus.notification_requested.emit("Tỉnh dậy tại Làng Lộc Trĩ (rớt %d Vàng)." % lost_gold)

	var hub_path: String = String(GameState.STAGE_PATHS.get("hub_loc_tri", ""))
	if hub_path != "" and ResourceLoader.exists(hub_path):
		await transition_to_stage("hub_loc_tri", &"cottage_bed", 0.20)
	elif active_player != null and is_instance_valid(active_player) and active_player.has_method(&"respawn_at_sandbox_start"):
		active_player.call(&"respawn_at_sandbox_start")


func _find_player_in_current_scene() -> Node:
	var cs: Node = get_tree().current_scene
	if cs == null:
		return null
	var p: Node = cs.get_node_or_null("Player")
	if p != null:
		return p
	for node: Node in get_tree().get_nodes_in_group(&"player"):
		if cs.is_ancestor_of(node):
			return node
	return null


func _find_spawn_point(spawn_id: StringName) -> SpawnPoint:
	var fallback: SpawnPoint = null
	for node: Node in get_tree().get_nodes_in_group(&"spawn_points"):
		var sp: SpawnPoint = node as SpawnPoint
		if sp == null:
			continue
		if fallback == null:
			fallback = sp
		if sp.spawn_id == spawn_id:
			return sp
	return fallback
