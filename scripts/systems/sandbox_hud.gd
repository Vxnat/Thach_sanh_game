class_name SandboxHud
extends CanvasLayer
## Hiển thị thông số debug tối giản cho Bước 1.1 trên màn hình 384x216.

@export var player_path: NodePath

@onready var _panel: PanelContainer = $DebugPanel
@onready var _info_label: Label = $DebugPanel/InfoLabel

var _player: Player = null
var _slow_mo_enabled: bool = false


func _ready() -> void:
	if not player_path.is_empty():
		_player = get_node_or_null(player_path) as Player


func _exit_tree() -> void:
	Engine.time_scale = 1.0


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("debug_toggle") and _panel != null:
		_panel.visible = not _panel.visible

	if Input.is_action_just_pressed("debug_slow_mo"):
		_slow_mo_enabled = not _slow_mo_enabled
		Engine.time_scale = 0.25 if _slow_mo_enabled else 1.0

	if _panel == null or not _panel.visible or _info_label == null or _player == null:
		return

	var state_name: String = String(_player.state_machine.get_current_state_name())
	var facing_str: String = "R" if _player.facing_direction > 0 else "L"
	var hp_cur: int = _player.health_component.current_hp if _player.health_component != null else 0
	var hp_max: int = _player.health_component.max_hp if _player.health_component != null else 0
	var weapon_name: String = "None"
	var group_name: String = "-"
	if _player.equipped_weapon != null:
		weapon_name = _player.equipped_weapon.display_name
		if _player.equipped_weapon.animation_profile != null:
			group_name = _player.equipped_weapon.animation_profile.get_group_label()

	var dash_cd: float = _player.get_dash_cooldown_left()
	var dash_str: String = "OK" if dash_cd <= 0.0 else ("%.2fs" % dash_cd)
	var anchor: Vector2 = _player.get_safe_anchor()

	_info_label.text = (
		"%s | Lv.%d | Vang:%d | %s(%s) | HP:%d/%d | MP:%d/%d | Q:%d HP:%d/%d MP:%d/%d | %s[%s] ATK:%d | x%.2f\n"
		+ "[A/D] Chay | [Space] Nhay | [Shift] Dash | [J] Danh | [U] Cung | [I] Dan | [Q/1/2] Hoi | [Tab] Doi (%s) | Anchor:(%d,%d)"
	) % [
		TimeManager.get_phase_name_vi(),
		GameState.level,
		GameState.pocket_gold,
		state_name,
		facing_str,
		hp_cur,
		hp_max,
		_player.current_mp,
		_player.max_mp,
		GameState.gourd_charges,
		GameState.belt_hp_count,
		GameState.max_belt_hp,
		GameState.belt_mp_count,
		GameState.max_belt_mp,
		weapon_name,
		group_name,
		_player.get_basic_attack_damage(),
		Engine.time_scale,
		dash_str,
		int(roundf(anchor.x)),
		int(roundf(anchor.y)),
	]

