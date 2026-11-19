class_name ForgeUI
extends CanvasLayer
## Giao diện Lò Rèn Anh Thợ Rèn: xem 5 vũ khí, mua bằng Vàng, rèn từ nguyên liệu và trang bị ngay.

const WEAPON_ORDER: Array[StringName] = [
	&"weapon_wooden_mallet",
	&"weapon_short_blade",
	&"weapon_bamboo_spear",
	&"weapon_bronze_axe",
	&"weapon_iron_hammer",
]

const GROUP_AIR_SKILL_VI: Dictionary = {
	WeaponAnimProfile.WeaponGroup.HAMMER: "HAMMER -> Air Slam dậm đất",
	WeaponAnimProfile.WeaponGroup.AXE: "AXE -> Air Slam bổ xoáy",
	WeaponAnimProfile.WeaponGroup.BLADE: "BLADE -> Air Stall lơ lửng",
	WeaponAnimProfile.WeaponGroup.POLEARM: "POLEARM -> Pogo Bounce bật nảy",
}

@onready var _resource_label: Label = $RootControl/CenterPanel/VBox/HeaderRow/ResourceLabel
@onready var _greeting_label: Label = $RootControl/CenterPanel/VBox/GreetingLabel
@onready var _weapon_list: VBoxContainer = $RootControl/CenterPanel/VBox/BodyRow/WeaponList
@onready var _weapon_icon: TextureRect = $RootControl/CenterPanel/VBox/BodyRow/DetailBox/WeaponTopRow/WeaponIcon
@onready var _weapon_title_label: Label = $RootControl/CenterPanel/VBox/BodyRow/DetailBox/WeaponTopRow/TitleCol/WeaponTitleLabel
@onready var _weapon_group_label: Label = $RootControl/CenterPanel/VBox/BodyRow/DetailBox/WeaponTopRow/TitleCol/WeaponGroupLabel
@onready var _weapon_stats_label: Label = $RootControl/CenterPanel/VBox/BodyRow/DetailBox/WeaponStatsLabel
@onready var _weapon_desc_label: Label = $RootControl/CenterPanel/VBox/BodyRow/DetailBox/WeaponDescLabel
@onready var _cost_recipe_label: Label = $RootControl/CenterPanel/VBox/BodyRow/DetailBox/CostOrRecipeLabel
@onready var _btn_primary: Button = $RootControl/CenterPanel/VBox/BodyRow/DetailBox/ActionRow/BtnPrimaryAction
@onready var _btn_craft: Button = $RootControl/CenterPanel/VBox/BodyRow/DetailBox/ActionRow/BtnCraftAction
@onready var _btn_talk: Button = $RootControl/CenterPanel/VBox/HeaderRow/BtnTalk
@onready var _btn_close: Button = $RootControl/CenterPanel/VBox/HeaderRow/BtnClose

var _selected_weapon_id: StringName = &"weapon_wooden_mallet"
var _weapon_buttons: Dictionary = {}


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not is_in_group(&"forge_ui"):
		add_to_group(&"forge_ui")
	visible = false

	for wid: StringName in WEAPON_ORDER:
		var btn: Button = _weapon_list.get_node_or_null("BtnWeapon_%s" % String(wid)) as Button
		if btn != null:
			_weapon_buttons[wid] = btn
			btn.pressed.connect(func() -> void:
				select_weapon(wid)
			)

	_btn_primary.pressed.connect(_on_primary_action_pressed)
	_btn_craft.pressed.connect(_on_craft_action_pressed)
	_btn_talk.pressed.connect(_on_talk_pressed)
	_btn_close.pressed.connect(close_forge)

	if not EventBus.gold_changed.is_connected(_on_state_updated):
		EventBus.gold_changed.connect(_on_state_updated)
	if not EventBus.inventory_updated.is_connected(_on_inventory_updated):
		EventBus.inventory_updated.connect(_on_inventory_updated)
	if not EventBus.weapon_changed.is_connected(_on_weapon_changed):
		EventBus.weapon_changed.connect(_on_weapon_changed)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close_forge()


func open_forge() -> void:
	visible = true
	GameState.set_ui_modal_open(true)
	if not WEAPON_ORDER.has(_selected_weapon_id):
		_selected_weapon_id = GameState.equipped_weapon_id
	_refresh_view()
	var first_btn: Button = _weapon_buttons.get(_selected_weapon_id) as Button
	if first_btn != null:
		first_btn.grab_focus()


func close_forge() -> void:
	visible = false
	GameState.set_ui_modal_open(false)


func select_weapon(weapon_id: StringName) -> void:
	if GameState.has_weapon_id(weapon_id):
		_selected_weapon_id = weapon_id
		_refresh_view()


func _on_talk_pressed() -> void:
	close_forge()
	EventBus.dialogue_requested.emit("tho_ren", null)


func _on_state_updated(_p: int, _s: int) -> void:
	if visible:
		_refresh_view()


func _on_inventory_updated() -> void:
	if visible:
		_refresh_view()


func _on_weapon_changed(_weapon_id: StringName) -> void:
	if visible:
		_refresh_view()


func _on_primary_action_pressed() -> void:
	var w: WeaponData = GameState.get_weapon_data(_selected_weapon_id)
	if w == null:
		return
	var owned: bool = GameState.owned_weapons.has(_selected_weapon_id)
	if owned:
		if GameState.equipped_weapon_id != _selected_weapon_id and GameState.equip_weapon_by_id(_selected_weapon_id):
			EventBus.notification_requested.emit("Đã trang bị %s." % w.display_name)
	else:
		if GameState.spend_gold(w.buy_price):
			GameState.equip_weapon_by_id(_selected_weapon_id, true)
			EventBus.notification_requested.emit("Đã mua và trang bị %s!" % w.display_name)
	_refresh_view()


func _on_craft_action_pressed() -> void:
	var w: WeaponData = GameState.get_weapon_data(_selected_weapon_id)
	if w == null or GameState.owned_weapons.has(_selected_weapon_id) or w.craft_recipe.is_empty():
		return
	if GameState.consume_materials(w.craft_recipe):
		GameState.equip_weapon_by_id(_selected_weapon_id, true)
		EventBus.notification_requested.emit("Đã rèn và trang bị %s!" % w.display_name)
	_refresh_view()


func _refresh_view() -> void:
	var wood_cnt: int = GameState.get_material_count(&"mat_hard_wood")
	var ore_cnt: int = GameState.get_material_count(&"mat_iron_ore")
	if _resource_label != null:
		_resource_label.text = "Vàng: %d | Gỗ: %d | Sắt: %d" % [GameState.pocket_gold, wood_cnt, ore_cnt]
	if _greeting_label != null:
		_greeting_label.text = "\"%s\"" % DialogueDatabase.get_greeting("tho_ren")

	for wid: StringName in WEAPON_ORDER:
		var btn: Button = _weapon_buttons.get(wid) as Button
		var w_item: WeaponData = GameState.get_weapon_data(wid)
		if btn == null or w_item == null:
			continue
		var is_eq: bool = GameState.equipped_weapon_id == wid
		var is_owned: bool = GameState.owned_weapons.has(wid)
		var mark: String = "> " if wid == _selected_weapon_id else ""
		if is_eq:
			btn.text = "%s[Đeo] %s" % [mark, w_item.display_name]
		elif is_owned:
			btn.text = "%s[Có] %s" % [mark, w_item.display_name]
		else:
			btn.text = "%s%s (%dV)" % [mark, w_item.display_name, w_item.buy_price]

	var sel: WeaponData = GameState.get_weapon_data(_selected_weapon_id)
	if sel == null:
		return

	if _weapon_icon != null:
		_weapon_icon.texture = sel.weapon_texture
	if _weapon_title_label != null:
		_weapon_title_label.text = sel.display_name
	if _weapon_group_label != null:
		var grp_txt: String = "Cận chiến"
		if sel.animation_profile != null:
			grp_txt = GROUP_AIR_SKILL_VI.get(sel.animation_profile.weapon_group, sel.animation_profile.get_group_label()) as String
		_weapon_group_label.text = grp_txt
	if _weapon_stats_label != null:
		var total_atk: int = GameState.base_atk + sel.bonus_atk
		var crit_pct: int = int(roundf(sel.crit_chance * 100.0))
		_weapon_stats_label.text = "Công: +%d (Tổng %d) | Chí mạng: %d%%" % [sel.bonus_atk, total_atk, crit_pct]
	if _weapon_desc_label != null:
		_weapon_desc_label.text = sel.description

	var owned_sel: bool = GameState.owned_weapons.has(_selected_weapon_id)
	var equipped_sel: bool = GameState.equipped_weapon_id == _selected_weapon_id
	if _cost_recipe_label != null:
		if owned_sel:
			_cost_recipe_label.text = "Trạng thái: Đã sở hữu — đổi trang bị miễn phí."
		else:
			var recipe_text: String = _format_recipe(sel.craft_recipe)
			if recipe_text == "":
				_cost_recipe_label.text = "Giá mua: %d Vàng" % sel.buy_price
			else:
				_cost_recipe_label.text = "Mua: %d Vàng  |  Rèn: %s" % [sel.buy_price, recipe_text]

	if _btn_primary != null:
		if owned_sel:
			_btn_primary.text = "Đang Trang Bị" if equipped_sel else "Trang Bị"
			_btn_primary.disabled = equipped_sel
		else:
			_btn_primary.text = "Mua (%dV)" % sel.buy_price
			_btn_primary.disabled = (GameState.pocket_gold < sel.buy_price)

	if _btn_craft != null:
		var show_craft: bool = (not owned_sel) and (not sel.craft_recipe.is_empty())
		_btn_craft.visible = show_craft
		if show_craft:
			_btn_craft.disabled = not GameState.has_materials(sel.craft_recipe)


func _format_recipe(recipe: Dictionary) -> String:
	if recipe.is_empty():
		return ""
	var parts: PackedStringArray = PackedStringArray()
	for k: Variant in recipe.keys():
		var item_id: StringName = StringName(String(k))
		var item: ItemData = GameState.get_item_data(item_id)
		var label_name: String = item.display_name if item != null else String(k)
		var req: int = int(recipe[k])
		var cur: int = GameState.get_material_count(item_id)
		parts.append("%s %d/%d" % [label_name, cur, req])
	return ", ".join(parts)

