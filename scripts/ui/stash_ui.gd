class_name StashUI
extends CanvasLayer
## Giao diện Rương Nhà Tranh: cất/rút Vàng và nạp/cất bình HP/MP giữa Đai Lưng và Rương.

@onready var _root_control: Control = $RootControl
@onready var _gold_info_label: Label = $RootControl/CenterPanel/VBox/GoldInfoLabel
@onready var _potion_info_label: Label = $RootControl/CenterPanel/VBox/PotionInfoLabel
@onready var _btn_deposit_25: Button = $RootControl/CenterPanel/VBox/GoldButtons/BtnDeposit25
@onready var _btn_deposit_all: Button = $RootControl/CenterPanel/VBox/GoldButtons/BtnDepositAll
@onready var _btn_withdraw_25: Button = $RootControl/CenterPanel/VBox/GoldButtons/BtnWithdraw25
@onready var _btn_withdraw_all: Button = $RootControl/CenterPanel/VBox/GoldButtons/BtnWithdrawAll
@onready var _btn_refill_belt: Button = $RootControl/CenterPanel/VBox/PotionButtons/BtnRefillBelt
@onready var _btn_store_hp: Button = $RootControl/CenterPanel/VBox/PotionButtons/BtnStoreHp
@onready var _btn_store_mp: Button = $RootControl/CenterPanel/VBox/PotionButtons/BtnStoreMp
@onready var _btn_close: Button = $RootControl/CenterPanel/VBox/BtnClose


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not is_in_group(&"stash_ui"):
		add_to_group(&"stash_ui")
	visible = false

	_btn_deposit_25.pressed.connect(func() -> void:
		GameState.deposit_gold_to_stash(25)
		_refresh_view()
	)
	_btn_deposit_all.pressed.connect(func() -> void:
		GameState.deposit_gold_to_stash(GameState.pocket_gold)
		_refresh_view()
	)
	_btn_withdraw_25.pressed.connect(func() -> void:
		GameState.withdraw_gold_from_stash(25)
		_refresh_view()
	)
	_btn_withdraw_all.pressed.connect(func() -> void:
		GameState.withdraw_gold_from_stash(GameState.stash_gold)
		_refresh_view()
	)
	_btn_refill_belt.pressed.connect(func() -> void:
		GameState.refill_belt_from_stash()
		_refresh_view()
	)
	_btn_store_hp.pressed.connect(func() -> void:
		GameState.store_belt_potion_to_stash(true)
		_refresh_view()
	)
	_btn_store_mp.pressed.connect(func() -> void:
		GameState.store_belt_potion_to_stash(false)
		_refresh_view()
	)
	_btn_close.pressed.connect(close_stash)

	if not EventBus.gold_changed.is_connected(_on_state_changed):
		EventBus.gold_changed.connect(_on_state_changed)
	if not EventBus.inventory_updated.is_connected(_on_inventory_updated):
		EventBus.inventory_updated.connect(_on_inventory_updated)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close_stash()


func open_stash() -> void:
	visible = true
	GameState.set_ui_modal_open(true)
	_refresh_view()
	if _btn_deposit_25 != null:
		_btn_deposit_25.grab_focus()


func close_stash() -> void:
	visible = false
	GameState.set_ui_modal_open(false)


func _on_state_changed(_p: int, _s: int) -> void:
	if visible:
		_refresh_view()


func _on_inventory_updated() -> void:
	if visible:
		_refresh_view()


func _refresh_view() -> void:
	if _gold_info_label != null:
		_gold_info_label.text = "Túi mang theo: %d Vàng   |   Trong Rương (An toàn): %d Vàng" % [
			GameState.pocket_gold,
			GameState.stash_gold,
		]
	if _potion_info_label != null:
		_potion_info_label.text = "Đai Lưng: Đỏ %d/%d, Thảo %d/%d   |   Rương: Đỏ %d, Thảo %d" % [
			GameState.belt_hp_count,
			GameState.max_belt_hp,
			GameState.belt_mp_count,
			GameState.max_belt_mp,
			GameState.stash_hp_count,
			GameState.stash_mp_count,
		]

	if _btn_deposit_25 != null:
		_btn_deposit_25.disabled = (GameState.pocket_gold <= 0)
		_btn_deposit_all.disabled = (GameState.pocket_gold <= 0)
		_btn_withdraw_25.disabled = (GameState.stash_gold <= 0)
		_btn_withdraw_all.disabled = (GameState.stash_gold <= 0)
		var can_refill: bool = (
			(GameState.belt_hp_count < GameState.max_belt_hp and GameState.stash_hp_count > 0)
			or (GameState.belt_mp_count < GameState.max_belt_mp and GameState.stash_mp_count > 0)
		)
		_btn_refill_belt.disabled = not can_refill
		_btn_store_hp.disabled = (GameState.belt_hp_count <= 0)
		_btn_store_mp.disabled = (GameState.belt_mp_count <= 0)

