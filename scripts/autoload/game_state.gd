extends Node
## Trạng thái phiên chơi toàn cục (GameState Autoload): chỉ số RPG, túi đai lưng, rương làng và story_flags.

const WEAPON_PATHS: Dictionary = {
	"weapon_wooden_mallet": "res://data/weapons/weapon_wooden_mallet.tres",
	"weapon_iron_hammer": "res://data/weapons/weapon_iron_hammer.tres",
	"weapon_bronze_axe": "res://data/weapons/weapon_bronze_axe.tres",
	"weapon_short_blade": "res://data/weapons/weapon_short_blade.tres",
	"weapon_bamboo_spear": "res://data/weapons/weapon_bamboo_spear.tres",
}

const ITEM_PATHS: Dictionary = {
	"item_hp_pot": "res://data/items/item_hp_pot.tres",
	"item_mp_pot": "res://data/items/item_mp_pot.tres",
	"mat_hard_wood": "res://data/items/mat_hard_wood.tres",
	"mat_iron_ore": "res://data/items/mat_iron_ore.tres",
}

const STAGE_PATHS: Dictionary = {
	"hub_loc_tri": "res://scenes/levels/hub_loc_tri.tscn",
	"test_sandbox": "res://scenes/levels/test_sandbox.tscn",
	"stage_01": "res://scenes/levels/stages/stage_01_rung_ven_lang.tscn",
}

var has_active_session: bool = false
var ui_modal_open: bool = false
var modal_input_cooldown_frames: int = 0

# Chỉ số cơ bản (Baseline Stats Lv.1 theo GDD.md)
var level: int = 1
var current_exp: int = 0
var max_hp: int = 100
var current_hp: int = 100
var max_mp: int = 50
var current_mp: int = 50
var base_atk: int = 5

# Kinh tế 2 lớp (Vàng mang theo vs Vàng cất Rương an toàn)
var pocket_gold: int = 100
var stash_gold: int = 0

# Túi Đai Lưng giới hạn + Rương Làng + Niêu Cơm Thần
var max_belt_hp: int = 3
var max_belt_mp: int = 2
var belt_hp_count: int = 2
var belt_mp_count: int = 1
var stash_hp_count: int = 0
var stash_mp_count: int = 0
var max_gourd_charges: int = 2
var gourd_charges: int = 2
var gourd_heal_ratio: float = 0.50

# Vũ khí, nguyên liệu & tiến độ thế giới (ID chuỗi ổn định)
var equipped_weapon_id: StringName = &"weapon_wooden_mallet"
var owned_weapons: Array[StringName] = [&"weapon_wooden_mallet"]
var materials: Dictionary = {}
var opened_chests: Array[String] = []
var unlocked_stages: Array[String] = ["hub_loc_tri", "test_sandbox", "stage_01"]
var story_flags: Dictionary = {
	"met_ly_thong": false,
	"met_tien_ong": false,
	"defeated_chan_tinh": false,
}
var current_stage_id: String = "test_sandbox"
var last_spawn_id: StringName = &"default"

var _weapon_cache: Dictionary = {}
var _item_cache: Dictionary = {}


func _ready() -> void:
	_preload_registries()


func _physics_process(_delta: float) -> void:
	if modal_input_cooldown_frames > 0:
		modal_input_cooldown_frames -= 1


func _preload_registries() -> void:
	for wid: String in WEAPON_PATHS.keys():
		var path_str: String = String(WEAPON_PATHS[wid])
		if ResourceLoader.exists(path_str):
			var w: WeaponData = load(path_str) as WeaponData
			if w != null:
				_weapon_cache[StringName(wid)] = w

	for iid: String in ITEM_PATHS.keys():
		var path_str: String = String(ITEM_PATHS[iid])
		if ResourceLoader.exists(path_str):
			var item: ItemData = load(path_str) as ItemData
			if item != null:
				_item_cache[StringName(iid)] = item


func has_weapon_id(weapon_id: StringName) -> bool:
	return WEAPON_PATHS.has(String(weapon_id))


func get_weapon_data(weapon_id: StringName) -> WeaponData:
	if _weapon_cache.has(weapon_id):
		return _weapon_cache[weapon_id] as WeaponData
	var key: String = String(weapon_id)
	if WEAPON_PATHS.has(key):
		var w: WeaponData = load(String(WEAPON_PATHS[key])) as WeaponData
		if w != null:
			_weapon_cache[weapon_id] = w
		return w
	return null


func get_item_data(item_id: StringName) -> ItemData:
	if _item_cache.has(item_id):
		return _item_cache[item_id] as ItemData
	var key: String = String(item_id)
	if ITEM_PATHS.has(key):
		var item: ItemData = load(String(ITEM_PATHS[key])) as ItemData
		if item != null:
			_item_cache[item_id] = item
		return item
	return null


func get_stage_scene_path(stage_id: String) -> String:
	if STAGE_PATHS.has(stage_id):
		var path_str: String = String(STAGE_PATHS[stage_id])
		if ResourceLoader.exists(path_str):
			return path_str
	return String(STAGE_PATHS["test_sandbox"])


func reset_new_game() -> void:
	has_active_session = true
	ui_modal_open = false
	modal_input_cooldown_frames = 0
	level = 1
	current_exp = 0
	max_hp = 100
	current_hp = 100
	max_mp = 50
	current_mp = 50
	base_atk = 5
	pocket_gold = 100
	stash_gold = 0
	max_belt_hp = 3
	max_belt_mp = 2
	belt_hp_count = 2
	belt_mp_count = 1
	stash_hp_count = 0
	stash_mp_count = 0
	max_gourd_charges = 2
	gourd_charges = 2
	gourd_heal_ratio = 0.50
	equipped_weapon_id = &"weapon_wooden_mallet"
	owned_weapons = [&"weapon_wooden_mallet"]
	materials.clear()
	opened_chests.clear()
	unlocked_stages = ["hub_loc_tri", "test_sandbox", "stage_01"]
	story_flags = {
		"met_ly_thong": false,
		"met_tien_ong": false,
		"defeated_chan_tinh": false,
	}
	current_stage_id = "test_sandbox"
	last_spawn_id = &"default"
	emit_all_state_signals()


func emit_all_state_signals() -> void:
	EventBus.player_hp_changed.emit(current_hp, max_hp)
	EventBus.player_mp_changed.emit(current_mp, max_mp)
	EventBus.player_level_changed.emit(level, current_exp, get_exp_for_next_level())
	EventBus.gold_changed.emit(pocket_gold, stash_gold)
	EventBus.belt_updated.emit(belt_hp_count, max_belt_hp, belt_mp_count, max_belt_mp, gourd_charges, max_gourd_charges)
	EventBus.inventory_updated.emit()
	EventBus.weapon_changed.emit(equipped_weapon_id)


func get_exp_for_next_level() -> int:
	return 50 * maxi(1, level)


func add_exp(amount: int) -> void:
	if amount <= 0:
		return
	current_exp += amount
	var leveled_up: bool = false
	while current_exp >= get_exp_for_next_level():
		current_exp -= get_exp_for_next_level()
		level += 1
		max_hp += 12
		max_mp += 6
		base_atk += 2
		current_hp = max_hp
		current_mp = max_mp
		leveled_up = true

	EventBus.player_level_changed.emit(level, current_exp, get_exp_for_next_level())
	if leveled_up:
		EventBus.player_hp_changed.emit(current_hp, max_hp)
		EventBus.player_mp_changed.emit(current_mp, max_mp)


func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	pocket_gold += amount
	EventBus.gold_changed.emit(pocket_gold, stash_gold)


func spend_gold(amount: int) -> bool:
	if amount < 0 or pocket_gold < amount:
		return false
	pocket_gold -= amount
	EventBus.gold_changed.emit(pocket_gold, stash_gold)
	return true


func deposit_gold_to_stash(amount: int) -> int:
	var moved: int = clampi(amount, 0, pocket_gold)
	if moved > 0:
		pocket_gold -= moved
		stash_gold += moved
		EventBus.gold_changed.emit(pocket_gold, stash_gold)
	return moved


func withdraw_gold_from_stash(amount: int) -> int:
	var moved: int = clampi(amount, 0, stash_gold)
	if moved > 0:
		stash_gold -= moved
		pocket_gold += moved
		EventBus.gold_changed.emit(pocket_gold, stash_gold)
	return moved


func apply_defeat_gold_penalty(ratio: float = 0.15) -> int:
	if pocket_gold <= 0:
		return 0
	var lost: int = mini(pocket_gold, int(floorf(float(pocket_gold) * clampf(ratio, 0.0, 1.0))))
	if lost > 0:
		pocket_gold -= lost
		EventBus.gold_changed.emit(pocket_gold, stash_gold)
	return lost


func add_potions(is_hp: bool, amount: int) -> Dictionary:
	if amount <= 0:
		return {"to_belt": 0, "to_stash": 0}
	var to_belt: int = 0
	var to_stash: int = 0
	if is_hp:
		var free_slots: int = maxi(0, max_belt_hp - belt_hp_count)
		to_belt = mini(amount, free_slots)
		to_stash = amount - to_belt
		belt_hp_count += to_belt
		stash_hp_count += to_stash
	else:
		var free_slots: int = maxi(0, max_belt_mp - belt_mp_count)
		to_belt = mini(amount, free_slots)
		to_stash = amount - to_belt
		belt_mp_count += to_belt
		stash_mp_count += to_stash

	EventBus.belt_updated.emit(belt_hp_count, max_belt_hp, belt_mp_count, max_belt_mp, gourd_charges, max_gourd_charges)
	EventBus.inventory_updated.emit()
	return {"to_belt": to_belt, "to_stash": to_stash}


func refill_belt_from_stash() -> void:
	var need_hp: int = maxi(0, max_belt_hp - belt_hp_count)
	var take_hp: int = mini(need_hp, stash_hp_count)
	belt_hp_count += take_hp
	stash_hp_count -= take_hp

	var need_mp: int = maxi(0, max_belt_mp - belt_mp_count)
	var take_mp: int = mini(need_mp, stash_mp_count)
	belt_mp_count += take_mp
	stash_mp_count -= take_mp

	EventBus.belt_updated.emit(belt_hp_count, max_belt_hp, belt_mp_count, max_belt_mp, gourd_charges, max_gourd_charges)
	EventBus.inventory_updated.emit()


func set_ui_modal_open(is_open: bool) -> void:
	if is_open:
		ui_modal_open = true
		modal_input_cooldown_frames = 0
	else:
		if ui_modal_open:
			modal_input_cooldown_frames = 2
		ui_modal_open = false


func is_gameplay_locked() -> bool:
	return ui_modal_open or modal_input_cooldown_frames > 0


func store_belt_potion_to_stash(is_hp: bool) -> bool:
	if is_hp:
		if belt_hp_count <= 0:
			return false
		belt_hp_count -= 1
		stash_hp_count += 1
	else:
		if belt_mp_count <= 0:
			return false
		belt_mp_count -= 1
		stash_mp_count += 1

	EventBus.belt_updated.emit(belt_hp_count, max_belt_hp, belt_mp_count, max_belt_mp, gourd_charges, max_gourd_charges)
	EventBus.inventory_updated.emit()
	return true


func consume_belt_hp() -> int:
	if belt_hp_count <= 0:
		return 0
	belt_hp_count -= 1
	var item: ItemData = get_item_data(&"item_hp_pot")
	var heal_amt: int = item.heal_amount if item != null and item.heal_amount > 0 else 45
	EventBus.belt_updated.emit(belt_hp_count, max_belt_hp, belt_mp_count, max_belt_mp, gourd_charges, max_gourd_charges)
	EventBus.inventory_updated.emit()
	return heal_amt


func consume_belt_mp() -> int:
	if belt_mp_count <= 0:
		return 0
	belt_mp_count -= 1
	var item: ItemData = get_item_data(&"item_mp_pot")
	var mp_amt: int = item.heal_amount if item != null and item.heal_amount > 0 else 30
	EventBus.belt_updated.emit(belt_hp_count, max_belt_hp, belt_mp_count, max_belt_mp, gourd_charges, max_gourd_charges)
	EventBus.inventory_updated.emit()
	return mp_amt


func consume_gourd() -> int:
	if gourd_charges <= 0:
		return 0
	gourd_charges -= 1
	var heal_amt: int = maxi(1, int(ceil(float(max_hp) * gourd_heal_ratio)))
	EventBus.belt_updated.emit(belt_hp_count, max_belt_hp, belt_mp_count, max_belt_mp, gourd_charges, max_gourd_charges)
	return heal_amt


func rest_at_village() -> void:
	current_hp = max_hp
	current_mp = max_mp
	gourd_charges = max_gourd_charges
	refill_belt_from_stash()
	EventBus.player_hp_changed.emit(current_hp, max_hp)
	EventBus.player_mp_changed.emit(current_mp, max_mp)


func unlock_weapon(weapon_id: StringName) -> bool:
	if not has_weapon_id(weapon_id):
		return false
	if not owned_weapons.has(weapon_id):
		owned_weapons.append(weapon_id)
		EventBus.inventory_updated.emit()
	return true


func equip_weapon_by_id(weapon_id: StringName, force_unlock: bool = false) -> bool:
	if not has_weapon_id(weapon_id):
		return false
	if not owned_weapons.has(weapon_id):
		if force_unlock:
			owned_weapons.append(weapon_id)
		else:
			return false
	equipped_weapon_id = weapon_id
	EventBus.weapon_changed.emit(equipped_weapon_id)
	EventBus.inventory_updated.emit()
	return true


func add_material(item_id: StringName, amount: int) -> void:
	if amount <= 0:
		return
	var key: String = String(item_id)
	materials[key] = int(materials.get(key, 0)) + amount
	EventBus.inventory_updated.emit()


func get_material_count(item_id: StringName) -> int:
	return int(materials.get(String(item_id), 0))


func has_materials(recipe: Dictionary) -> bool:
	for k: Variant in recipe.keys():
		var req: int = int(recipe[k])
		if get_material_count(StringName(String(k))) < req:
			return false
	return true


func consume_materials(recipe: Dictionary) -> bool:
	if not has_materials(recipe):
		return false
	for k: Variant in recipe.keys():
		var key: String = String(k)
		var left: int = int(materials.get(key, 0)) - int(recipe[k])
		if left > 0:
			materials[key] = left
		else:
			materials.erase(key)
	EventBus.inventory_updated.emit()
	return true


func is_chest_opened(chest_id: String) -> bool:
	return opened_chests.has(chest_id)


func mark_chest_opened(chest_id: String) -> void:
	if chest_id != "" and not opened_chests.has(chest_id):
		opened_chests.append(chest_id)


func set_story_flag(flag_key: String, value: Variant) -> void:
	story_flags[flag_key] = value
	EventBus.story_flag_updated.emit(flag_key, value)


func get_story_flag(flag_key: String, default_value: Variant = false) -> Variant:
	return story_flags.get(flag_key, default_value)


func to_save_dict() -> Dictionary:
	var owned_arr: Array[String] = []
	for w: StringName in owned_weapons:
		owned_arr.append(String(w))

	return {
		"player": {
			"level": level,
			"current_exp": current_exp,
			"max_hp": max_hp,
			"current_hp": current_hp,
			"max_mp": max_mp,
			"current_mp": current_mp,
			"base_atk": base_atk,
			"pocket_gold": pocket_gold,
			"stash_gold": stash_gold,
			"equipped_weapon_id": String(equipped_weapon_id),
		},
		"inventory": {
			"max_belt_hp": max_belt_hp,
			"max_belt_mp": max_belt_mp,
			"belt_hp_count": belt_hp_count,
			"belt_mp_count": belt_mp_count,
			"stash_hp_count": stash_hp_count,
			"stash_mp_count": stash_mp_count,
			"max_gourd_charges": max_gourd_charges,
			"gourd_charges": gourd_charges,
			"gourd_heal_ratio": gourd_heal_ratio,
			"owned_weapons": owned_arr,
			"materials": materials.duplicate(true),
		},
		"world": {
			"opened_chests": opened_chests.duplicate(),
			"unlocked_stages": unlocked_stages.duplicate(),
			"story_flags": story_flags.duplicate(true),
			"current_stage_id": current_stage_id,
			"last_spawn_id": String(last_spawn_id),
		},
	}


func from_save_dict(data: Dictionary) -> bool:
	var p: Dictionary = data.get("player", {}) as Dictionary
	var inv: Dictionary = data.get("inventory", {}) as Dictionary
	var w: Dictionary = data.get("world", {}) as Dictionary
	if p.is_empty() or inv.is_empty() or w.is_empty():
		return false

	level = maxi(1, int(p.get("level", 1)))
	current_exp = maxi(0, int(p.get("current_exp", 0)))
	max_hp = maxi(20, int(p.get("max_hp", 100)))
	current_hp = clampi(int(p.get("current_hp", max_hp)), 1, max_hp)
	max_mp = maxi(10, int(p.get("max_mp", 50)))
	current_mp = clampi(int(p.get("current_mp", max_mp)), 0, max_mp)
	base_atk = maxi(1, int(p.get("base_atk", 5)))
	pocket_gold = maxi(0, int(p.get("pocket_gold", 0)))
	stash_gold = maxi(0, int(p.get("stash_gold", 0)))

	max_belt_hp = maxi(1, int(inv.get("max_belt_hp", 3)))
	max_belt_mp = maxi(1, int(inv.get("max_belt_mp", 2)))
	belt_hp_count = clampi(int(inv.get("belt_hp_count", 0)), 0, max_belt_hp)
	belt_mp_count = clampi(int(inv.get("belt_mp_count", 0)), 0, max_belt_mp)
	stash_hp_count = maxi(0, int(inv.get("stash_hp_count", 0)))
	stash_mp_count = maxi(0, int(inv.get("stash_mp_count", 0)))
	max_gourd_charges = maxi(1, int(inv.get("max_gourd_charges", 2)))
	gourd_charges = clampi(int(inv.get("gourd_charges", max_gourd_charges)), 0, max_gourd_charges)
	gourd_heal_ratio = clampf(float(inv.get("gourd_heal_ratio", 0.50)), 0.1, 1.0)

	owned_weapons.clear()
	var raw_owned: Array = inv.get("owned_weapons", []) as Array
	for item_name: Variant in raw_owned:
		var wid: StringName = StringName(String(item_name))
		if has_weapon_id(wid) and not owned_weapons.has(wid):
			owned_weapons.append(wid)
	if owned_weapons.is_empty():
		owned_weapons.append(&"weapon_wooden_mallet")

	var loaded_eq: StringName = StringName(String(p.get("equipped_weapon_id", "weapon_wooden_mallet")))
	equipped_weapon_id = loaded_eq if has_weapon_id(loaded_eq) and owned_weapons.has(loaded_eq) else owned_weapons[0]

	materials.clear()
	var raw_mats: Dictionary = inv.get("materials", {}) as Dictionary
	for mk: Variant in raw_mats.keys():
		var cnt: int = int(raw_mats[mk])
		if cnt > 0:
			materials[String(mk)] = cnt

	opened_chests.clear()
	for cid: Variant in (w.get("opened_chests", []) as Array):
		var c_str: String = String(cid)
		if c_str != "" and not opened_chests.has(c_str):
			opened_chests.append(c_str)

	unlocked_stages.clear()
	for sid: Variant in (w.get("unlocked_stages", []) as Array):
		var s_str: String = String(sid)
		if s_str != "" and not unlocked_stages.has(s_str):
			unlocked_stages.append(s_str)
	if unlocked_stages.is_empty():
		unlocked_stages = ["hub_loc_tri", "test_sandbox", "stage_01"]

	story_flags = (w.get("story_flags", {}) as Dictionary).duplicate(true)
	current_stage_id = String(w.get("current_stage_id", "test_sandbox"))
	last_spawn_id = StringName(String(w.get("last_spawn_id", "default")))

	has_active_session = true
	emit_all_state_signals()
	return true

