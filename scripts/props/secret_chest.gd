class_name SecretChest
extends Node2D
## Rương bí mật mở 1 lần duy nhất (lưu qua GameState.opened_chests & SaveManager), văng Vàng + nguyên liệu vật lý.

@export var chest_id: String = "stage_01_chest_01"
@export var gold_reward: int = 35
@export var item_reward_id: StringName = &"mat_iron_ore"
@export var item_reward_count: int = 1

@onready var _chest_sprite: Sprite2D = $ChestSprite
@onready var _interactable: InteractableArea = $InteractableArea


func _ready() -> void:
	if _interactable != null and not _interactable.interacted.is_connected(_on_interacted):
		_interactable.interacted.connect(_on_interacted)
	_apply_opened_visual(is_opened())


func is_opened() -> bool:
	return chest_id != "" and GameState.is_chest_opened(chest_id)


func _apply_opened_visual(opened: bool) -> void:
	if _chest_sprite != null:
		_chest_sprite.frame = 1 if opened else 0
	if _interactable != null:
		_interactable.interaction_enabled = not opened
		if opened:
			_interactable.set_highlighted(false)


func _on_interacted(_player_node: Node2D) -> void:
	if is_opened():
		_apply_opened_visual(true)
		return

	GameState.mark_chest_opened(chest_id)
	_apply_opened_visual(true)
	AudioManager.play_sfx(&"chest_open", 0.98, 1.03)

	var spawn_parent: Node = get_parent() if get_parent() != null else self
	LootDropSystem.spawn_burst(
		spawn_parent,
		global_position + Vector2(0.0, -10.0),
		gold_reward,
		item_reward_id,
		item_reward_count,
		26.0
	)
	EventBus.notification_requested.emit("Đã mở Rương Bí Mật!")

