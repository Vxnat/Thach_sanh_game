class_name InteractableArea
extends Area2D
## Vùng tương tác chuẩn Layer 6 (Interactable), tự hiển thị nhãn [E] khi Thạch Sanh tới gần.

signal interacted(player: Node2D)

@export var prompt_text: String = "[E] Tương tác"
@export var prompt_offset: Vector2 = Vector2(0.0, -36.0)
@export var interaction_enabled: bool = true

var _prompt_label: Label = null
var _is_highlighted: bool = false


func _ready() -> void:
	collision_layer = 32  # Layer 6: Interactable
	collision_mask = 2    # Layer 2: PlayerBody
	monitoring = true
	monitorable = true

	_prompt_label = Label.new()
	_prompt_label.name = "PromptLabel"
	_prompt_label.text = prompt_text
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.custom_minimum_size = Vector2(140.0, 14.0)
	_prompt_label.position = prompt_offset + Vector2(-70.0, -7.0)
	_prompt_label.z_index = 20
	_prompt_label.visible = false
	var ui_theme: Theme = load("res://assets/ui/pixel_ui_theme.tres") as Theme
	if ui_theme != null:
		_prompt_label.theme = ui_theme
	_prompt_label.add_theme_font_size_override("font_size", 8)
	_prompt_label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.72, 1.0))
	_prompt_label.add_theme_color_override("font_outline_color", Color(0.08, 0.06, 0.08, 1.0))
	_prompt_label.add_theme_constant_override("outline_size", 3)
	add_child(_prompt_label)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func set_prompt_text(new_text: String) -> void:
	prompt_text = new_text
	if _prompt_label != null:
		_prompt_label.text = prompt_text


func set_highlighted(highlighted: bool) -> void:
	_is_highlighted = highlighted
	if _prompt_label != null:
		_prompt_label.text = prompt_text
		_prompt_label.visible = highlighted and interaction_enabled


func trigger_interact(player: Node2D) -> void:
	if not interaction_enabled:
		return
	interacted.emit(player)


func _on_body_entered(body: Node2D) -> void:
	if body != null and body.is_in_group(&"player") and body.has_method(&"register_interactable"):
		body.call(&"register_interactable", self)


func _on_body_exited(body: Node2D) -> void:
	if body != null and body.is_in_group(&"player") and body.has_method(&"unregister_interactable"):
		body.call(&"unregister_interactable", self)
	if _is_highlighted:
		set_highlighted(false)

