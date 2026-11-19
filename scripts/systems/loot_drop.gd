class_name LootDropSystem
extends RefCounted
## Tiện ích sinh cụm LootPickup vật lý văng nảy trên đất khi hạ quái hoặc mở Rương bí mật.

const PICKUP_SCENE: PackedScene = preload("res://scenes/props/LootPickup.tscn")


static func spawn_loot_pickup(
	parent: Node,
	world_pos: Vector2,
	kind: int,
	amount: int,
	item_id: StringName = &"",
	impulse: Vector2 = Vector2.ZERO
) -> LootPickup:
	if parent == null or PICKUP_SCENE == null or amount <= 0:
		return null

	var pickup: LootPickup = PICKUP_SCENE.instantiate() as LootPickup
	if pickup == null:
		return null

	if parent is Node2D:
		pickup.position = (parent as Node2D).to_local(world_pos)
	else:
		pickup.position = world_pos
	parent.add_child(pickup)
	pickup.global_position = world_pos
	pickup.configure(kind, amount, item_id, impulse)
	return pickup


static func spawn_burst(
	parent: Node,
	world_pos: Vector2,
	total_gold: int,
	item_id: StringName = &"",
	item_count: int = 0,
	spread_x: float = 46.0
) -> Array[LootPickup]:
	var spawned: Array[LootPickup] = []
	if parent == null:
		return spawned

	if total_gold > 0:
		var pieces: int = 1 if total_gold < 4 else (2 if total_gold < 12 else 3)
		var base_share: int = total_gold / pieces
		var remainder: int = total_gold % pieces
		for i: int in range(pieces):
			var piece_amt: int = base_share + (1 if i < remainder else 0)
			if piece_amt <= 0:
				continue
			var t: float = 0.0 if pieces == 1 else (float(i) / float(pieces - 1)) * 2.0 - 1.0
			var vx: float = t * spread_x + (10.0 if i % 2 == 0 else -10.0)
			var vy: float = -125.0 - float((i % 2) * 20)
			var coin: LootPickup = spawn_loot_pickup(
				parent,
				world_pos,
				LootPickup.PickupKind.GOLD,
				piece_amt,
				&"",
				Vector2(vx, vy)
			)
			if coin != null:
				spawned.append(coin)

	if item_id != &"" and item_count > 0:
		for j: int in range(item_count):
			var sign_dir: float = 1.0 if j % 2 == 0 else -1.0
			var vx: float = sign_dir * clampf(spread_x * 0.65, 16.0, 48.0)
			var vy: float = -145.0 - float(j * 12)
			var mat: LootPickup = spawn_loot_pickup(
				parent,
				world_pos,
				LootPickup.PickupKind.MATERIAL,
				1,
				item_id,
				Vector2(vx, vy)
			)
			if mat != null:
				spawned.append(mat)

	return spawned

