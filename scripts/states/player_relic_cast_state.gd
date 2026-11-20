class_name PlayerRelicCastState
extends PlayerState
## Trạng thái thi triển Pháp bảo (Cung Tên Vàng, Đàn Thần): giữ nguyên vũ khí trên WeaponPivot, triệu hồi linh ảnh trên RelicVisual.

const CAST_DURATION: float = 0.28
const RELEASE_TIME: float = 0.08
const CANCEL_TO_DASH_TIME: float = 0.12

var _relic_id: StringName = &"relic_cung_ten_vang"
var _elapsed: float = 0.0
var _released: bool = false
var _aim_up: bool = false


func enter(_prev_state: StringName, msg: Dictionary = {}) -> void:
	_relic_id = msg.get("relic_id", &"relic_cung_ten_vang") as StringName
	_elapsed = 0.0
	_released = false
	_aim_up = Input.is_action_pressed("move_up")

	var axis: float = player.get_move_input_axis()
	if absf(axis) > 0.01:
		player.update_facing(axis)

	player.reset_combat_state()
	player.reset_combo()

	if not player.is_on_floor():
		player.velocity.y = clampf(player.velocity.y * 0.35, -30.0, 20.0)

	if player.animation_player != null and player.animation_player.has_animation(&"relic_cast"):
		player.animation_player.speed_scale = 1.0
		player.animation_player.stop()
		player.animation_player.play(&"relic_cast")

	player.begin_relic_cast_visual(_relic_id, _aim_up)
	EventBus.relic_cast_started.emit(_relic_id)


func exit() -> void:
	if not _released:
		player.clear_relic_visual()
	else:
		player.fade_out_relic_visual(0.12)

	if player.animation_player != null and player.animation_player.current_animation == "relic_cast":
		player.reset_combat_state()


func physics_update(delta: float) -> void:
	_elapsed += delta
	if not _released and Input.is_action_pressed("move_up"):
		_aim_up = true

	if not _released and _elapsed >= RELEASE_TIME:
		_released = true
		player.advance_relic_cast_visual_release(_relic_id, _aim_up)
		player.execute_relic_effect(_relic_id, _aim_up)

	if _elapsed >= CANCEL_TO_DASH_TIME and player.has_buffered_dash() and player.can_dash():
		state_machine.transition_to(&"Dash")
		return

	var axis: float = player.get_move_input_axis()
	if player.is_on_floor():
		player.apply_horizontal_movement(0.0, player.ground_accel, player.ground_decel * 1.2, delta)
		player.apply_gravity(delta)
	else:
		player.apply_horizontal_movement(axis * 0.5, player.air_accel, player.air_decel, delta)
		player.apply_gravity(delta, 0.45)

	player.move_and_slide()

	var anim_done: bool = player.animation_player == null or not player.animation_player.is_playing()
	if _elapsed >= CAST_DURATION or anim_done:
		if not player.is_on_floor():
			state_machine.transition_to(&"Fall")
		elif absf(player.get_move_input_axis()) > 0.01:
			state_machine.transition_to(&"Run")
		else:
			state_machine.transition_to(&"Idle")
