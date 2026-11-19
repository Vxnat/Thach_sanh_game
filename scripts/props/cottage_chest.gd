class_name CottageChest
extends Node2D
## Rương Nhà Tranh: mở StashUI để cất/rút Vàng an toàn và nạp bình thuốc từ kho về Đai Lưng.

@export var stash_ui_path: NodePath

@onready var _interactable: InteractableArea = $InteractableArea


func _ready() -> void:
	if _interactable != null and not _interactable.interacted.is_connected(_on_interacted):
		_interactable.interacted.connect(_on_interacted)


func _on_interacted(_player_node: Node2D) -> void:
	var ui: StashUI = null
	if not stash_ui_path.is_empty():
		ui = get_node_or_null(stash_ui_path) as StashUI
	if ui == null:
		var list: Array[Node] = get_tree().get_nodes_in_group(&"stash_ui")
		if not list.is_empty():
			ui = list[0] as StashUI
	if ui != null:
		ui.open_stash()
	else:
		push_warning("CottageChest không tìm thấy StashUI để mở.")

