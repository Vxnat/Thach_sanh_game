class_name VillageNpc
extends Node2D
## NPC Làng Lộc Trĩ & Trạm Xe Ngựa: hiển thị sprite 2-frame, dấu '!' nhiệm vụ và mở thoại hoặc UI dịch vụ.

enum NpcRole { DIALOGUE_ONLY, FORGE, SHOP, TRAVEL }

const BREATH_INTERVAL_SEC: float = 0.55

@export var npc_name: String = "NPC"
@export var dialogue_id: String = "ly_thong"
@export var role: NpcRole = NpcRole.DIALOGUE_ONLY
@export var sprite_texture: Texture2D
@export var default_facing: int = 1
@export var prompt_label_text: String = "[E] Trò chuyện"
@export var quest_flag_to_hide_marker: String = ""
@export var target_ui_path: NodePath

@onready var _visual_root: Node2D = $VisualRoot
@onready var _body_sprite: Sprite2D = $VisualRoot/BodySprite
@onready var _name_tag: Label = $NameTag
@onready var _quest_marker: Label = $QuestMarker
@onready var _interactable: InteractableArea = $InteractableArea

var _breath_timer: float = 0.0
var _breath_interval: float = BREATH_INTERVAL_SEC


func _ready() -> void:
	_breath_interval = BREATH_INTERVAL_SEC + fmod(absf(global_position.x) * 0.003, 0.12) - 0.06
	_breath_timer = fmod(absf(global_position.x * 0.017 + global_position.y * 0.011), _breath_interval)
	if _body_sprite != null and sprite_texture != null:
		_body_sprite.texture = sprite_texture
	if _visual_root != null:
		_visual_root.scale.x = -1.0 if default_facing < 0 else 1.0
	if _name_tag != null:
		_name_tag.text = npc_name
	if _interactable != null:
		_interactable.set_prompt_text(prompt_label_text)
		if not _interactable.interacted.is_connected(_on_interacted):
			_interactable.interacted.connect(_on_interacted)

	if not EventBus.story_flag_updated.is_connected(_on_story_flag_updated):
		EventBus.story_flag_updated.connect(_on_story_flag_updated)
	_update_quest_marker()


func _process(delta: float) -> void:
	if _body_sprite != null and _body_sprite.hframes > 1:
		_breath_timer += delta
		if _breath_timer >= _breath_interval:
			_breath_timer = fmod(_breath_timer, _breath_interval)
			_body_sprite.frame = (_body_sprite.frame + 1) % _body_sprite.hframes


func is_quest_marker_visible() -> bool:
	return _quest_marker != null and _quest_marker.visible


func _on_story_flag_updated(_flag_key: String, _value: Variant) -> void:
	_update_quest_marker()


func _update_quest_marker() -> void:
	if _quest_marker == null:
		return
	if quest_flag_to_hide_marker == "":
		_quest_marker.visible = false
	else:
		_quest_marker.visible = not bool(GameState.get_story_flag(quest_flag_to_hide_marker, false))


func _on_interacted(player_node: Node2D) -> void:
	if player_node != null and _visual_root != null:
		var dx: float = player_node.global_position.x - global_position.x
		if absf(dx) > 2.0:
			_visual_root.scale.x = -1.0 if dx < 0.0 else 1.0

	match role:
		NpcRole.DIALOGUE_ONLY:
			EventBus.dialogue_requested.emit(dialogue_id, self)
		NpcRole.FORGE:
			var forge_ui: Node = _find_target_ui(&"forge_ui")
			if forge_ui != null and forge_ui.has_method(&"open_forge"):
				forge_ui.call(&"open_forge")
		NpcRole.SHOP:
			var shop_ui: Node = _find_target_ui(&"shop_ui")
			if shop_ui != null and shop_ui.has_method(&"open_shop"):
				shop_ui.call(&"open_shop")
		NpcRole.TRAVEL:
			var travel_ui: Node = _find_target_ui(&"travel_ui")
			if travel_ui != null and travel_ui.has_method(&"open_travel"):
				travel_ui.call(&"open_travel")


func _find_target_ui(group_name: StringName) -> Node:
	if not target_ui_path.is_empty():
		var direct: Node = get_node_or_null(target_ui_path)
		if direct != null:
			return direct
	var nodes: Array[Node] = get_tree().get_nodes_in_group(group_name)
	if not nodes.is_empty():
		return nodes[0]
	return null

