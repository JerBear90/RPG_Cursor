extends Node
## Recipe validation and crafting execution.

signal craft_completed(recipe_id: String)
signal craft_failed(reason: String)

var known_recipes: Array[String] = [
	"bandage", "purified_water", "iron_sword", "repair_kit", "camp_fire_meal",
]


func reset_for_new_game() -> void:
	known_recipes = ["bandage", "purified_water", "repair_kit", "camp_fire_meal"]


func can_craft(recipe_id: String, station_id: String = "") -> Dictionary:
	var recipe := _get_recipe(recipe_id)
	if recipe.is_empty():
		return {"ok": false, "reason": "Unknown recipe"}
	if recipe.station != "" and recipe.station != station_id:
		return {"ok": false, "reason": "Requires %s" % recipe.station}
	if recipe.get("station_level", 1) > BaseManager.get_station_level(recipe.station):
		return {"ok": false, "reason": "Station level too low"}
	for req in recipe.materials:
		if InventoryManager.get_item_count(req.id) < req.quantity:
			return {"ok": false, "reason": "Missing %s" % req.id}
	if recipe.get("copper_cost", 0) > 0:
		if not CurrencyManager.can_afford_copper(recipe.copper_cost):
			return {"ok": false, "reason": "Not enough currency"}
	return {"ok": true, "reason": ""}


func craft(recipe_id: String, station_id: String = "") -> bool:
	var check := can_craft(recipe_id, station_id)
	if not check.ok:
		craft_failed.emit(check.reason)
		return false
	var recipe := _get_recipe(recipe_id)
	for req in recipe.materials:
		InventoryManager.remove_item(req.id, req.quantity)
	if recipe.get("copper_cost", 0) > 0:
		CurrencyManager.spend_copper(recipe.copper_cost)
	for result in recipe.results:
		InventoryManager.add_item(result.id, result.quantity)
	craft_completed.emit(recipe_id)
	return true


func _get_recipe(recipe_id: String) -> Dictionary:
	match recipe_id:
		"bandage":
			return {
				"id": "bandage", "station": "workbench", "station_level": 1, "copper_cost": 0,
				"materials": [{"id": "cloth_scrap", "quantity": 2}, {"id": "herb_bundle", "quantity": 1}],
				"results": [{"id": "bandage", "quantity": 2}],
			}
		"repair_kit":
			return {
				"id": "repair_kit", "station": "workbench", "station_level": 1, "copper_cost": 10,
				"materials": [{"id": "iron_scrap", "quantity": 2}, {"id": "cloth_scrap", "quantity": 1}],
				"results": [{"id": "repair_kit", "quantity": 1}],
			}
		"purified_water":
			return {
				"id": "purified_water", "station": "forge", "station_level": 1, "copper_cost": 0,
				"materials": [{"id": "waterskin", "quantity": 1}],
				"results": [{"id": "purified_water", "quantity": 1}],
			}
		"iron_sword":
			return {
				"id": "iron_sword", "station": "forge", "station_level": 2, "copper_cost": 50,
				"materials": [{"id": "iron_scrap", "quantity": 5}, {"id": "wood", "quantity": 2}],
				"results": [{"id": "iron_sword", "quantity": 1}],
			}
		_:
			return {}
