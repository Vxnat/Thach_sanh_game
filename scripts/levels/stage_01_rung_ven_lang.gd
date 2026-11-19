class_name Stage01RungVenLang
extends Node2D
## Màn 1 — Rừng Ven Làng: đường chính, 2 ngách bí mật (Rương 1 lần), suối sâu -80% HP & bãi gác cổng mở đường lên Nhị Trụ Tùng.

@onready var _gatekeeper_group: Node2D = $GatekeeperGroup
@onready var _gate_barrier: StaticBody2D = $GateBarrier
@onready var _gate_barrier_shape: CollisionShape2D = $GateBarrier/CollisionShape2D
@onready var _outpost_xa_phu: VillageNpc = $OutpostXaPhu
@onready var _nhi_tru_gate_area: InteractableArea = $NhiTruTungGate/InteractableArea

var _exit_unlocked: bool = false


func _enter_tree() -> void:
	if not GameState.has_active_session:
		GameState.reset_new_game()


func _ready() -> void:
	if not GameState.has_active_session:
		GameState.reset_new_game()
	GameState.current_stage_id = "stage_01"
	GameState.set_ui_modal_open(false)
	AudioManager.sync_stage_audio("stage_01")

	if _nhi_tru_gate_area != null and not _nhi_tru_gate_area.interacted.is_connected(_on_nhi_tru_gate_interacted):
		_nhi_tru_gate_area.interacted.connect(_on_nhi_tru_gate_interacted)

	_connect_gatekeepers()

	if bool(GameState.get_story_flag("stage_01_cleared", false)):
		_unlock_stage_exit(false)
	else:
		_set_exit_locked_state()


func _physics_process(_delta: float) -> void:
	if not _exit_unlocked and get_alive_gatekeeper_count() == 0:
		_unlock_stage_exit(true)


func is_exit_unlocked() -> bool:
	return _exit_unlocked


func get_alive_gatekeeper_count() -> int:
	if _gatekeeper_group == null:
		return 0
	var count: int = 0
	for child: Node in _gatekeeper_group.get_children():
		var enemy: StageEnemy = child as StageEnemy
		if enemy == null or not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue
		var hc: HealthComponent = enemy.health_component if enemy.health_component != null else (enemy.get_node_or_null("HealthComponent") as HealthComponent)
		if hc != null and hc.is_dead:
			continue
		count += 1
	return count


func _connect_gatekeepers() -> void:
	if _gatekeeper_group == null:
		return
	for child: Node in _gatekeeper_group.get_children():
		var enemy: StageEnemy = child as StageEnemy
		if enemy == null:
			continue
		var hc: HealthComponent = enemy.health_component if enemy.health_component != null else (enemy.get_node_or_null("HealthComponent") as HealthComponent)
		if hc != null and not hc.died.is_connected(_on_gatekeeper_died):
			hc.died.connect(_on_gatekeeper_died)


func _on_gatekeeper_died() -> void:
	if not _exit_unlocked and get_alive_gatekeeper_count() == 0:
		_unlock_stage_exit(true)


func _set_exit_locked_state() -> void:
	_exit_unlocked = false
	if _gate_barrier_shape != null:
		_gate_barrier_shape.disabled = false
	if _gate_barrier != null:
		_gate_barrier.visible = true
		_gate_barrier.modulate.a = 1.0
	_set_interactable_enabled(_get_outpost_xa_phu_interactable(), false)
	_set_interactable_enabled(_nhi_tru_gate_area, false)


func _unlock_stage_exit(announce: bool) -> void:
	if _exit_unlocked:
		return
	_exit_unlocked = true

	if _gate_barrier_shape != null:
		if announce:
			_gate_barrier_shape.set_deferred(&"disabled", true)
		else:
			_gate_barrier_shape.disabled = true

	if _gate_barrier != null:
		if announce:
			var tw: Tween = create_tween()
			tw.tween_property(_gate_barrier, "modulate:a", 0.0, 0.35)
			tw.tween_callback(func() -> void:
				if is_instance_valid(_gate_barrier):
					_gate_barrier.visible = false
			)
		else:
			_gate_barrier.visible = false
			_gate_barrier.modulate.a = 0.0

	_set_interactable_enabled(_get_outpost_xa_phu_interactable(), true)
	_set_interactable_enabled(_nhi_tru_gate_area, true)

	if not bool(GameState.get_story_flag("stage_01_cleared", false)):
		GameState.set_story_flag("stage_01_cleared", true)
	GameState.unlock_stage("stage_02")

	if announce:
		AudioManager.play_sfx(&"chest_open", 0.98, 1.02)
		EventBus.notification_requested.emit("Đã dẹp nhóm quái gác cổng! Thông đường lên Nhị Trụ Tùng & mở Trạm Xe Ngựa!")


func _get_outpost_xa_phu_interactable() -> InteractableArea:
	if _outpost_xa_phu == null:
		return null
	return _outpost_xa_phu.get_node_or_null("InteractableArea") as InteractableArea


func _set_interactable_enabled(area: InteractableArea, enabled: bool) -> void:
	if area == null:
		return
	area.interaction_enabled = enabled
	if not enabled:
		area.set_highlighted(false)


func _on_nhi_tru_gate_interacted(_player_node: Node2D) -> void:
	if not _exit_unlocked:
		return
	var stage02_path: String = String(GameState.STAGE_PATHS.get("stage_02", ""))
	if stage02_path != "" and ResourceLoader.exists(stage02_path):
		SceneRouter.transition_to_stage("stage_02", &"from_stage_01", 0.16)
	else:
		EventBus.dialogue_requested.emit("nhi_tru_tung_gate", self)
