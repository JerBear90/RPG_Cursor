extends Node
## Loot rolls and drop spawning.

const LOOT_PICKUP_SCENE := preload("res://scenes/pickups/loot_pickup.tscn")
const CURRENCY_PICKUP_SCENE := preload("res://scenes/pickups/currency_pickup.tscn")

var _pool: Array[Node] = []


func drop_loot_table(table_id: String, position: Vector3) -> void:
	var drops := _roll_table(table_id)
	for drop in drops:
		_spawn_drop(drop, position + Vector3(randf_range(-0.5, 0.5), 0.5, randf_range(-0.5, 0.5)))


func drop_item(item_id: String, position: Vector3, quantity: int = 1) -> void:
	_spawn_drop({"type": "item", "id": item_id, "quantity": quantity}, position)


func drop_currency(copper: int, position: Vector3) -> void:
	if copper <= 0:
		return
	_spawn_drop({"type": "currency", "copper": copper}, position)


func _roll_table(table_id: String) -> Array:
	match table_id:
		"forest_bandit":
			var drops: Array = []
			if randf() < 0.6:
				drops.append({"type": "item", "id": "cloth_scrap", "quantity": randi_range(1, 3)})
			if randf() < 0.3:
				drops.append({"type": "currency", "copper": randi_range(2, 8)})
			if randf() < 0.1:
				drops.append({"type": "item", "id": "iron_scrap", "quantity": 1})
			return drops
		"boss_warden":
			return [
				{"type": "currency", "copper": 200},
				{"type": "item", "id": "grove_heart", "quantity": 1},
				{"type": "item", "id": "epic_blade", "quantity": 1},
			]
		"destructible_crate":
			if randf() < 0.5:
				return [{"type": "item", "id": "wood", "quantity": randi_range(1, 2)}]
			return [{"type": "item", "id": "nails", "quantity": 1}]
		"dungeon_boss":
			return [
				{"type": "currency", "copper": 120},
				{"type": "item", "id": "wolf_crest", "quantity": 1},
				{"type": "item", "id": "iron_scrap", "quantity": randi_range(2, 4)},
			]
		"dungeon_treasure":
			return [
				{"type": "currency", "copper": 80},
				{"type": "item", "id": "epic_blade", "quantity": 1},
				{"type": "item", "id": "cloth_scrap", "quantity": randi_range(3, 6)},
			]
		_:
			return [{"type": "currency", "copper": randi_range(1, 5)}]


func _spawn_drop(drop: Dictionary, position: Vector3) -> void:
	var scene: PackedScene
	if drop.type == "currency":
		scene = CURRENCY_PICKUP_SCENE
	else:
		scene = LOOT_PICKUP_SCENE
	var pickup := scene.instantiate() as Node3D
	pickup.global_position = position
	if pickup.has_method("setup"):
		pickup.setup(drop)
	var parent := get_tree().current_scene
	if parent:
		parent.add_child(pickup)
