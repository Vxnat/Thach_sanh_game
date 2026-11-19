class_name GameHud
extends CanvasLayer
## HUD chính thức của game trên CanvasLayer riêng (không bị tối theo CanvasModulate ban đêm).

const WEAPON_DISPLAY_NAMES_VI: Dictionary = {
	&"weapon_wooden_mallet": "Búa Gỗ",
	&"weapon_iron_hammer": "Búa Sắt",
	&"weapon_bronze_axe": "Rìu Đồng",
	&"weapon_short_blade": "Đoản Đao",
	&"weapon_bamboo_spear": "Mác Tre",
}

const HP_BAR_MAX_WIDTH: float = 68.0
const MP_BAR_MAX_WIDTH: float = 68.0
const EXP_BAR_MAX_WIDTH: float = 48.0

@onready var _level_label: Label = $RootControl/StatsPanel/VBox/TopRow/LevelLabel
@onready var _exp_fill: ColorRect = $RootControl/StatsPanel/VBox/TopRow/ExpBg/ExpFill
@onready var _hp_fill: ColorRect = $RootControl/StatsPanel/VBox/HpRow/HpBg/HpFill
@onready var _hp_label: Label = $RootControl/StatsPanel/VBox/HpRow/HpLabel
@onready var _mp_fill: ColorRect = $RootControl/StatsPanel/VBox/MpRow/MpBg/MpFill
@onready var _mp_label: Label = $RootControl/StatsPanel/VBox/MpRow/MpLabel

@onready var _belt_label: Label = $RootControl/BeltPanel/VBox/BeltLabel
@onready var _weapon_label: Label = $RootControl/BeltPanel/VBox/WeaponLabel

@onready var _gold_label: Label = $RootControl/WorldPanel/VBox/GoldLabel
@onready var _phase_dot: ColorRect = $RootControl/WorldPanel/VBox/PhaseRow/PhaseDot
@onready var _phase_label: Label = $RootControl/WorldPanel/VBox/PhaseRow/PhaseLabel

@onready var _toast_panel: PanelContainer = $RootControl/ToastPanel
@onready var _toast_label: Label = $RootControl/ToastPanel/ToastLabel

var _toast_tween: Tween = null


func _ready() -> void:
	layer = 10
	if _toast_panel != null:
		_toast_panel.visible = false
		_toast_panel.modulate.a = 0.0

	_connect_signals()
	refresh_all()


func _connect_signals() -> void:
	if not EventBus.player_hp_changed.is_connected(_on_hp_changed):
		EventBus.player_hp_changed.connect(_on_hp_changed)
	if not EventBus.player_mp_changed.is_connected(_on_mp_changed):
		EventBus.player_mp_changed.connect(_on_mp_changed)
	if not EventBus.player_level_changed.is_connected(_on_level_changed):
		EventBus.player_level_changed.connect(_on_level_changed)
	if not EventBus.gold_changed.is_connected(_on_gold_changed):
		EventBus.gold_changed.connect(_on_gold_changed)
	if not EventBus.belt_updated.is_connected(_on_belt_updated):
		EventBus.belt_updated.connect(_on_belt_updated)
	if not EventBus.weapon_changed.is_connected(_on_weapon_changed):
		EventBus.weapon_changed.connect(_on_weapon_changed)
	if not EventBus.time_phase_changed.is_connected(_on_time_phase_changed):
		EventBus.time_phase_changed.connect(_on_time_phase_changed)
	if not EventBus.notification_requested.is_connected(_on_notification_requested):
		EventBus.notification_requested.connect(_on_notification_requested)
	if not EventBus.save_completed.is_connected(_on_save_completed):
		EventBus.save_completed.connect(_on_save_completed)


func refresh_all() -> void:
	_on_hp_changed(GameState.current_hp, GameState.max_hp)
	_on_mp_changed(GameState.current_mp, GameState.max_mp)
	_on_level_changed(GameState.level, GameState.current_exp, GameState.get_exp_for_next_level())
	_on_gold_changed(GameState.pocket_gold, GameState.stash_gold)
	_on_belt_updated(
		GameState.belt_hp_count,
		GameState.max_belt_hp,
		GameState.belt_mp_count,
		GameState.max_belt_mp,
		GameState.gourd_charges,
		GameState.max_gourd_charges
	)
	_on_weapon_changed(GameState.equipped_weapon_id)
	_on_time_phase_changed(TimeManager.get_current_phase(), TimeManager.get_phase_name_vi())


func _on_hp_changed(cur_hp: int, m_hp: int) -> void:
	var ratio: float = clampf(float(cur_hp) / float(maxi(1, m_hp)), 0.0, 1.0)
	if _hp_fill != null:
		_hp_fill.custom_minimum_size.x = roundf(HP_BAR_MAX_WIDTH * ratio)
		_hp_fill.size.x = _hp_fill.custom_minimum_size.x
	if _hp_label != null:
		_hp_label.text = "%d/%d" % [cur_hp, m_hp]


func _on_mp_changed(cur_mp: int, m_mp: int) -> void:
	var ratio: float = clampf(float(cur_mp) / float(maxi(1, m_mp)), 0.0, 1.0)
	if _mp_fill != null:
		_mp_fill.custom_minimum_size.x = roundf(MP_BAR_MAX_WIDTH * ratio)
		_mp_fill.size.x = _mp_fill.custom_minimum_size.x
	if _mp_label != null:
		_mp_label.text = "%d/%d" % [cur_mp, m_mp]


func _on_level_changed(lvl: int, cur_exp: int, next_exp: int) -> void:
	if _level_label != null:
		_level_label.text = "Cấp %d" % lvl
	var ratio: float = clampf(float(cur_exp) / float(maxi(1, next_exp)), 0.0, 1.0)
	if _exp_fill != null:
		_exp_fill.custom_minimum_size.x = roundf(EXP_BAR_MAX_WIDTH * ratio)
		_exp_fill.size.x = _exp_fill.custom_minimum_size.x


func _on_gold_changed(pocket: int, _stash: int) -> void:
	if _gold_label != null:
		_gold_label.text = "Vàng: %d" % pocket


func _on_belt_updated(bhp: int, mbhp: int, bmp: int, mbmp: int, gourd: int, mgourd: int) -> void:
	if _belt_label != null:
		_belt_label.text = "[Q]Niêu:%d/%d [1]Đỏ:%d/%d [2]Thảo:%d/%d" % [gourd, mgourd, bhp, mbhp, bmp, mbmp]


func _on_weapon_changed(weapon_id: StringName) -> void:
	var w: WeaponData = GameState.get_weapon_data(weapon_id)
	var w_name: String = WEAPON_DISPLAY_NAMES_VI.get(weapon_id, w.display_name if w != null else "Tay không") as String
	var atk_val: int = GameState.base_atk + (w.bonus_atk if w != null else 0)
	if _weapon_label != null:
		_weapon_label.text = "Vũ khí: %s (Công %d)" % [w_name, atk_val]


func _on_time_phase_changed(phase: int, phase_name: String) -> void:
	if _phase_label != null:
		_phase_label.text = phase_name
	if _phase_dot != null:
		match phase:
			TimeManager.TimePhase.DAWN:
				_phase_dot.color = Color("ffd7ba")
			TimeManager.TimePhase.DAY:
				_phase_dot.color = Color("ffe66d")
			TimeManager.TimePhase.DUSK:
				_phase_dot.color = Color("e89f71")
			TimeManager.TimePhase.NIGHT:
				_phase_dot.color = Color("7b94e8")


func _on_notification_requested(message: String) -> void:
	show_toast(message)


func _on_save_completed(_success: bool, message: String) -> void:
	if message != "":
		show_toast(message)


func show_toast(message: String) -> void:
	if _toast_panel == null or _toast_label == null:
		return
	_toast_label.text = message
	_toast_panel.visible = true
	_toast_panel.modulate.a = 1.0
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.8)
	_toast_tween.tween_property(_toast_panel, "modulate:a", 0.0, 0.35)
	_toast_tween.tween_callback(func() -> void:
		if _toast_panel != null:
			_toast_panel.visible = false
	)


func get_summary_snapshot() -> Dictionary:
	return {
		"level": _level_label.text if _level_label != null else "",
		"hp": _hp_label.text if _hp_label != null else "",
		"mp": _mp_label.text if _mp_label != null else "",
		"belt": _belt_label.text if _belt_label != null else "",
		"weapon": _weapon_label.text if _weapon_label != null else "",
		"gold": _gold_label.text if _gold_label != null else "",
		"phase": _phase_label.text if _phase_label != null else "",
	}

