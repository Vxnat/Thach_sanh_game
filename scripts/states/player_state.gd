class_name PlayerState
extends Node
## Base class cho mọi trạng thái của nhân vật Player trong StateMachine.

var player: Player = null
var state_machine: PlayerStateMachine = null


func enter(_prev_state: StringName, _msg: Dictionary = {}) -> void:
	pass


func exit() -> void:
	pass


func physics_update(_delta: float) -> void:
	pass


func frame_update(_delta: float) -> void:
	pass

