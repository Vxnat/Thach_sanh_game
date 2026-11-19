class_name StagePortal
extends Node2D
## Điểm chuyển cảnh tương tác đưa Thạch Sanh đi tới màn chơi đích qua SceneRouter.

@export var target_stage_id: String = "test_sandbox"
@export var target_spawn_id: StringName = &"default"
@export var portal_prompt: String = "[E] Lên đường"
@export var fade_duration: float = 0.16

@onready var _interactable: InteractableArea = $InteractableArea


func _ready() -> void:
	if _interactable != null:
		_interactable.set_prompt_text(portal_prompt)
		if not _interactable.interacted.is_connected(_on_interacted):
			_interactable.interacted.connect(_on_interacted)


func _on_interacted(_player_node: Node2D) -> void:
	SceneRouter.transition_to_stage(target_stage_id, target_spawn_id, fade_duration)

