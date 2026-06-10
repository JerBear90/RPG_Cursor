extends Node
## Hearthhold Camp station levels and upgrades.

signal station_upgraded(station_id: String, level: int)

var station_levels: Dictionary = {
	"memory_altar": 1,
	"item_box": 1,
	"workbench": 1,
	"forge": 1,
	"pet_shelter": 0,
	"mask_stand": 0,
}


func reset_for_new_game() -> void:
	station_levels = {
		"memory_altar": 1,
		"item_box": 1,
		"workbench": 1,
		"forge": 1,
		"pet_shelter": 0,
		"mask_stand": 0,
	}


func get_station_level(station_id: String) -> int:
	return station_levels.get(station_id, 0)


func is_station_unlocked(station_id: String) -> bool:
	return get_station_level(station_id) > 0


func can_upgrade(station_id: String) -> bool:
	var level := get_station_level(station_id)
	var cost := _upgrade_cost(station_id, level + 1)
	if cost.is_empty():
		return false
	for mat in cost.materials:
		if InventoryManager.get_item_count(mat.id) < mat.quantity:
			return false
	return CurrencyManager.can_afford_copper(cost.get("copper", 0))


func upgrade_station(station_id: String) -> bool:
	if not can_upgrade(station_id):
		return false
	var next_level := get_station_level(station_id) + 1
	var cost := _upgrade_cost(station_id, next_level)
	for mat in cost.materials:
		InventoryManager.remove_item(mat.id, mat.quantity)
	if cost.get("copper", 0) > 0:
		CurrencyManager.spend_copper(cost.copper)
	station_levels[station_id] = next_level
	station_upgraded.emit(station_id, next_level)
	if station_id == "forge":
		AchievementManager.unlock("forge_friend")
	return true


func _upgrade_cost(station_id: String, level: int) -> Dictionary:
	match station_id:
		"workbench":
			if level == 2:
				return {"materials": [{"id": "wood", "quantity": 15}, {"id": "iron_scrap", "quantity": 5}], "copper": 25}
		"forge":
			if level == 2:
				return {"materials": [{"id": "iron_scrap", "quantity": 10}, {"id": "stone", "quantity": 10}], "copper": 50}
		_:
			pass
	return {}


func serialize() -> Dictionary:
	return {"station_levels": station_levels.duplicate()}


func deserialize(data: Dictionary) -> void:
	if data.has("station_levels"):
		station_levels = data.station_levels
