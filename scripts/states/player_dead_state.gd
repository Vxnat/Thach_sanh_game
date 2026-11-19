class_name PlayerDeadState
extends PlayerState
## Trạng thái Thất bại (0 HP): khóa di chuyển & đòn đánh, bàn giao SceneRouter xử lý hồi sinh/về Làng.

var _respawn_timer: float = 1.1
var _cause: StringName = &"unknown"
var _handled_defeat: bool = false


func enter(_prev_state: StringName, msg: Dictionary = {}) -> void:
	player.reset_combat_state()
	player.reset_combo()
	player.velocity = Vector2.ZERO
	_cause = msg.get("cause", &"unknown") as StringName
	_respawn_timer = player.sandbox_dead_respawn_delay
	_handled_defeat = false
	player.play_locomotion_anim(&"dead")
	print("[Sandbox] Thạch Sanh 0 HP (%s) -> Dead." % String(_cause))


func physics_update(delta: float) -> void:
	player.velocity.x = 0.0
	if _cause == &"hazard":
		player.velocity = Vector2.ZERO
	else:
		player.apply_gravity(delta)
		player.move_and_slide()

	if player.auto_respawn_in_sandbox and not _handled_defeat:
		_respawn_timer -= delta
		if _respawn_timer <= 0.0:
			_handled_defeat = true
			SceneRouter.handle_player_defeat(player)
