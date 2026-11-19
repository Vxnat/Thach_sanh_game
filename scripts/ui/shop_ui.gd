class_name ShopUI
extends CanvasLayer
## Giao diện Quầy Cô Bé Tạp Hóa: mua bình HP/MP vào Đai Lưng (dư chuyển vào Rương Làng) & mua nguyên liệu sơ cấp.

@onready var _gold_label: Label = $RootControl/CenterPanel/VBox/HeaderRow/GoldLabel
@onready var _greeting_label: Label = $RootControl/CenterPanel/VBox/GreetingLabel
@onready var _capacity_label: Label = $RootControl/CenterPanel/VBox/CapacityLabel
@onready var _hp_item_label: Label = $RootControl/CenterPanel/VBox/HpRow/HpItemLabel
@onready var _btn_buy_hp_1: Button = $RootControl/CenterPanel/VBox/HpRow/BtnBuyHp1
@onready var _btn_buy_hp_3: Button = $RootControl/CenterPanel/VBox/HpRow/BtnBuyHp3
@onready var _mp_item_label: Label = $RootControl/CenterPanel/VBox/MpRow/MpItemLabel
@onready var _btn_buy_mp_1: Button = $RootControl/CenterPanel/VBox/MpRow/BtnBuyMp1
@onready var _btn_buy_mp_3: Button = $RootControl/CenterPanel/VBox/MpRow/BtnBuyMp3
@onready var _mat_stock_label: Label = $RootControl/CenterPanel/VBox/MatRow/MatStockLabel
@onready var _btn_buy_wood: Button = $RootControl/CenterPanel/VBox/MatRow/BtnBuyWood
@onready var _btn_buy_ore: Button = $RootControl/CenterPanel/VBox/MatRow/BtnBuyOre
@onready var _feedback_label: Label = $RootControl/CenterPanel/VBox/FeedbackLabel
@onready var _btn_talk: Button = $RootControl/CenterPanel/VBox/HeaderRow/BtnTalk
@onready var _btn_close: Button = $RootControl/CenterPanel/VBox/HeaderRow/BtnClose


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not is_in_group(&"shop_ui"):
		add_to_group(&"shop_ui")
	visible = false

	_btn_buy_hp_1.pressed.connect(func() -> void:
		_buy_potion(true, 1)
	)
	_btn_buy_hp_3.pressed.connect(func() -> void:
		_buy_potion(true, 3)
	)
	_btn_buy_mp_1.pressed.connect(func() -> void:
		_buy_potion(false, 1)
	)
	_btn_buy_mp_3.pressed.connect(func() -> void:
		_buy_potion(false, 3)
	)
	_btn_buy_wood.pressed.connect(func() -> void:
		_buy_material(&"mat_hard_wood", 1)
	)
	_btn_buy_ore.pressed.connect(func() -> void:
		_buy_material(&"mat_iron_ore", 1)
	)
	_btn_talk.pressed.connect(_on_talk_pressed)
	_btn_close.pressed.connect(close_shop)

	if not EventBus.gold_changed.is_connected(_on_state_changed):
		EventBus.gold_changed.connect(_on_state_changed)
	if not EventBus.inventory_updated.is_connected(_on_inventory_updated):
		EventBus.inventory_updated.connect(_on_inventory_updated)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close_shop()


func open_shop() -> void:
	visible = true
	GameState.set_ui_modal_open(true)
	if _feedback_label != null:
		_feedback_label.text = "Đai lưng đầy thì phần dư sẽ tự gửi về Rương Nhà Tranh."
	_refresh_view()
	if _btn_buy_hp_1 != null:
		_btn_buy_hp_1.grab_focus()


func close_shop() -> void:
	visible = false
	GameState.set_ui_modal_open(false)


func _on_talk_pressed() -> void:
	close_shop()
	EventBus.dialogue_requested.emit("tap_hoa", null)


func _on_state_changed(_p: int, _s: int) -> void:
	if visible:
		_refresh_view()


func _on_inventory_updated() -> void:
	if visible:
		_refresh_view()


func _get_item_price(item_id: StringName, fallback_price: int) -> int:
	var item: ItemData = GameState.get_item_data(item_id)
	if item != null and item.buy_price > 0:
		return item.buy_price
	return fallback_price


func _buy_potion(is_hp: bool, qty: int) -> void:
	var item_id: StringName = &"item_hp_pot" if is_hp else &"item_mp_pot"
	var item: ItemData = GameState.get_item_data(item_id)
	var item_name: String = item.display_name if item != null else ("Bình Thuốc Đỏ" if is_hp else "Bình Linh Thảo")
	var unit_price: int = _get_item_price(item_id, 25 if is_hp else 30)
	var total_cost: int = unit_price * qty

	if not GameState.spend_gold(total_cost):
		if _feedback_label != null:
			_feedback_label.text = "Không đủ %d Vàng để mua %d %s." % [total_cost, qty, item_name]
		_refresh_view()
		return

	var res: Dictionary = GameState.add_potions(is_hp, qty)
	var to_belt: int = int(res.get("to_belt", 0))
	var to_stash: int = int(res.get("to_stash", 0))
	var msg: String = ""
	if to_belt > 0 and to_stash > 0:
		msg = "Mua %d %s: +%d Đai Lưng, +%d dư gửi về Rương Làng!" % [qty, item_name, to_belt, to_stash]
	elif to_belt == 0 and to_stash > 0:
		msg = "Đai Lưng đầy! Đã gửi %d %s về Rương Nhà Tranh." % [to_stash, item_name]
	else:
		msg = "Đã nạp %d %s vào Đai Lưng." % [to_belt, item_name]

	if _feedback_label != null:
		_feedback_label.text = msg
	EventBus.notification_requested.emit(msg)
	_refresh_view()


func _buy_material(item_id: StringName, qty: int) -> void:
	var item: ItemData = GameState.get_item_data(item_id)
	var item_name: String = item.display_name if item != null else String(item_id)
	var unit_price: int = _get_item_price(item_id, 15)
	var total_cost: int = unit_price * qty
	if not GameState.spend_gold(total_cost):
		if _feedback_label != null:
			_feedback_label.text = "Không đủ %d Vàng mua %s." % [total_cost, item_name]
		_refresh_view()
		return

	GameState.add_material(item_id, qty)
	var msg: String = "Đã mua %d %s (tổng: %d)." % [qty, item_name, GameState.get_material_count(item_id)]
	if _feedback_label != null:
		_feedback_label.text = msg
	_refresh_view()


func _refresh_view() -> void:
	var hp_price: int = _get_item_price(&"item_hp_pot", 25)
	var mp_price: int = _get_item_price(&"item_mp_pot", 30)
	var wood_price: int = _get_item_price(&"mat_hard_wood", 15)
	var ore_price: int = _get_item_price(&"mat_iron_ore", 25)
	var hp_item: ItemData = GameState.get_item_data(&"item_hp_pot")
	var mp_item: ItemData = GameState.get_item_data(&"item_mp_pot")

	if _gold_label != null:
		_gold_label.text = "Vàng: %d" % GameState.pocket_gold
	if _greeting_label != null:
		_greeting_label.text = "\"%s\"" % DialogueDatabase.get_greeting("tap_hoa")
	if _capacity_label != null:
		_capacity_label.text = "Đai Lưng: Đỏ %d/%d, Thảo %d/%d  |  Rương: Đỏ %d, Thảo %d" % [
			GameState.belt_hp_count,
			GameState.max_belt_hp,
			GameState.belt_mp_count,
			GameState.max_belt_mp,
			GameState.stash_hp_count,
			GameState.stash_mp_count,
		]

	if _hp_item_label != null:
		var hp_heal: int = hp_item.heal_amount if hp_item != null else 45
		_hp_item_label.text = "Bình Thuốc Đỏ (+%d HP)" % hp_heal
	if _mp_item_label != null:
		var mp_heal: int = mp_item.heal_amount if mp_item != null else 30
		_mp_item_label.text = "Bình Linh Thảo (+%d MP)" % mp_heal
	if _mat_stock_label != null:
		_mat_stock_label.text = "Nguyên liệu (Gỗ: %d, Sắt: %d)" % [
			GameState.get_material_count(&"mat_hard_wood"),
			GameState.get_material_count(&"mat_iron_ore"),
		]

	if _btn_buy_hp_1 != null:
		_btn_buy_hp_1.text = "Mua 1 (%dV)" % hp_price
		_btn_buy_hp_1.disabled = (GameState.pocket_gold < hp_price)
	if _btn_buy_hp_3 != null:
		_btn_buy_hp_3.text = "Mua 3 (%dV)" % (hp_price * 3)
		_btn_buy_hp_3.disabled = (GameState.pocket_gold < hp_price * 3)
	if _btn_buy_mp_1 != null:
		_btn_buy_mp_1.text = "Mua 1 (%dV)" % mp_price
		_btn_buy_mp_1.disabled = (GameState.pocket_gold < mp_price)
	if _btn_buy_mp_3 != null:
		_btn_buy_mp_3.text = "Mua 3 (%dV)" % (mp_price * 3)
		_btn_buy_mp_3.disabled = (GameState.pocket_gold < mp_price * 3)
	if _btn_buy_wood != null:
		_btn_buy_wood.text = "Gỗ Lim (%dV)" % wood_price
		_btn_buy_wood.disabled = (GameState.pocket_gold < wood_price)
	if _btn_buy_ore != null:
		_btn_buy_ore.text = "Quặng Sắt (%dV)" % ore_price
		_btn_buy_ore.disabled = (GameState.pocket_gold < ore_price)

