extends Node
## Recipe validation and crafting execution.

signal craft_completed(recipe_id: String)
signal craft_failed(reason: String)

var known_recipes: Array[String] = [
	"bandage", "purified_water", "iron_sword", "repair_kit", "camp_fire_meal",
	"leather_wrap", "sharpen_blade", "bogward_tonic", "rotfen_travel_supply", "upgrade_material_craft",
	"hydration_mixture", "sand_lung_remedy", "burn_salve_craft", "cooling_salve_craft", "desert_cleanse",
	"dread_tonic_craft", "shadow_cleanse_craft", "ward_candle_craft", "lantern_oil_craft", "dominion_cleanse",
	"cooked_meat", "fire_coating", "basic_weapon_upgrade", "armor_reinforcement", "pet_treat",
	"craft_ruby", "craft_sapphire", "craft_emerald",
]


func reset_for_new_game() -> void:
	known_recipes = [
		"bandage", "purified_water", "iron_sword", "repair_kit", "camp_fire_meal",
		"leather_wrap", "sharpen_blade", "bogward_tonic", "rotfen_travel_supply", "upgrade_material_craft",
		"hydration_mixture", "sand_lung_remedy", "burn_salve_craft", "cooling_salve_craft", "desert_cleanse",
		"dread_tonic_craft", "shadow_cleanse_craft", "ward_candle_craft", "lantern_oil_craft", "dominion_cleanse",
		"cooked_meat", "fire_coating", "basic_weapon_upgrade", "armor_reinforcement", "pet_treat",
		"craft_ruby", "craft_sapphire", "craft_emerald",
	]


func get_recipe_station(recipe_id: String) -> String:
	return _get_recipe(recipe_id).get("station", "")


func can_craft(recipe_id: String, station_id: String = "") -> Dictionary:
	var recipe := _get_recipe(recipe_id)
	if recipe.is_empty():
		return {"ok": false, "reason": "Unknown recipe"}
	if recipe.station != "" and recipe.station != station_id:
		return {"ok": false, "reason": "Requires %s" % recipe.station}
	var station_level := BaseManager.get_station_level(recipe.station)
	if recipe.station == "apothecary":
		station_level = maxi(station_level, 1)
	if recipe.get("station_level", 1) > station_level:
		return {"ok": false, "reason": "%s Level %d Required" % [recipe.station.capitalize(), int(recipe.get("station_level", 1))]}
	for req in recipe.materials:
		if InventoryManager.get_combined_count(req.id) < req.quantity:
			return {"ok": false, "reason": "Missing %s x%d" % [ItemDatabase.get_display_name(req.id), int(req.quantity)]}
	if recipe.get("copper_cost", 0) > 0:
		if not CurrencyManager.can_afford_copper(recipe.copper_cost):
			return {"ok": false, "reason": _format_copper_shortfall(int(recipe.copper_cost))}
	return {"ok": true, "reason": ""}


func _format_copper_shortfall(total_copper: int) -> String:
	var need := total_copper - CurrencyManager.get_total_copper()
	if need <= 0:
		return "Not enough currency"
	if total_copper >= CurrencyManager.COPPER_PER_SILVER and total_copper % CurrencyManager.COPPER_PER_SILVER == 0:
		return "Need %d Silver" % (total_copper / CurrencyManager.COPPER_PER_SILVER)
	return "Need %d Copper" % need


func craft(recipe_id: String, station_id: String = "") -> bool:
	var check := can_craft(recipe_id, station_id)
	if not check.ok:
		craft_failed.emit(check.reason)
		return false
	var recipe := _get_recipe(recipe_id)
	for req in recipe.materials:
		if not InventoryManager.consume_combined(req.id, int(req.quantity)):
			craft_failed.emit("Missing %s x%d" % [ItemDatabase.get_display_name(req.id), int(req.quantity)])
			return false
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
				"results": [{"id": "bandage", "quantity": 1}],
			}
		"repair_kit":
			return {
				"id": "repair_kit", "station": "workbench", "station_level": 1, "copper_cost": 10,
				"materials": [{"id": "iron_scrap", "quantity": 2}, {"id": "cloth_scrap", "quantity": 1}, {"id": "oil", "quantity": 1}],
				"results": [{"id": "repair_kit", "quantity": 1}],
			}
		"purified_water":
			return {
				"id": "purified_water", "station": "forge", "station_level": 1, "copper_cost": 0,
				"materials": [{"id": "dirty_water", "quantity": 1}, {"id": "charcoal", "quantity": 1}],
				"results": [{"id": "purified_water", "quantity": 1}],
			}
		"cooked_meat":
			return {
				"id": "cooked_meat", "station": "workbench", "station_level": 1, "copper_cost": 0,
				"materials": [{"id": "raw_meat", "quantity": 1}, {"id": "firewood", "quantity": 1}],
				"results": [{"id": "cooked_meat", "quantity": 1}],
			}
		"fire_coating":
			return {
				"id": "fire_coating", "station": "forge", "station_level": 1, "copper_cost": 0,
				"materials": [{"id": "fire_resin", "quantity": 1}, {"id": "oil", "quantity": 1}, {"id": "cloth_scrap", "quantity": 1}],
				"results": [{"id": "fire_coating", "quantity": 1}],
			}
		"basic_weapon_upgrade":
			return {
				"id": "basic_weapon_upgrade", "station": "workbench", "station_level": 2, "copper_cost": 25,
				"materials": [{"id": "iron_scrap", "quantity": 5}, {"id": "weapon_parts", "quantity": 1}],
				"results": [{"id": "weapon_upgrade_kit", "quantity": 1}],
			}
		"armor_reinforcement":
			return {
				"id": "armor_reinforcement", "station": "forge", "station_level": 2, "copper_cost": 0,
				"materials": [{"id": "hide", "quantity": 2}, {"id": "armor_plates", "quantity": 1}, {"id": "iron_scrap", "quantity": 3}],
				"results": [{"id": "armor_reinforcement_kit", "quantity": 1}],
			}
		"pet_treat":
			return {
				"id": "pet_treat", "station": "workbench", "station_level": 1, "copper_cost": 0,
				"materials": [{"id": "berries", "quantity": 2}, {"id": "herb_bundle", "quantity": 1}],
				"results": [{"id": "pet_treat", "quantity": 2}],
			}
		"craft_ruby":
			return {
				"id": "craft_ruby", "station": "forge", "station_level": 2, "copper_cost": 25,
				"materials": [{"id": "crystal_shard", "quantity": 2}, {"id": "fire_resin", "quantity": 1}],
				"results": [{"id": "gem_ruby", "quantity": 1}],
			}
		"craft_sapphire":
			return {
				"id": "craft_sapphire", "station": "forge", "station_level": 2, "copper_cost": 25,
				"materials": [{"id": "crystal_shard", "quantity": 2}, {"id": "purified_water", "quantity": 1}],
				"results": [{"id": "gem_sapphire", "quantity": 1}],
			}
		"craft_emerald":
			return {
				"id": "craft_emerald", "station": "forge", "station_level": 2, "copper_cost": 25,
				"materials": [{"id": "crystal_shard", "quantity": 2}, {"id": "poison_gland", "quantity": 1}],
				"results": [{"id": "gem_emerald", "quantity": 1}],
			}
		"iron_sword":
			return {
				"id": "iron_sword", "station": "forge", "station_level": 2, "copper_cost": 50,
				"materials": [{"id": "iron_scrap", "quantity": 5}, {"id": "wood", "quantity": 2}],
				"results": [{"id": "iron_sword", "quantity": 1}],
			}
		"camp_fire_meal":
			return {
				"id": "camp_fire_meal", "station": "workbench", "station_level": 1, "copper_cost": 0,
				"materials": [{"id": "wood", "quantity": 2}, {"id": "herb_bundle", "quantity": 1}],
				"results": [{"id": "dried_rations", "quantity": 2}],
			}
		"leather_wrap":
			return {
				"id": "leather_wrap", "station": "workbench", "station_level": 1, "copper_cost": 5,
				"materials": [{"id": "cloth_scrap", "quantity": 4}],
				"results": [{"id": "bandage", "quantity": 3}],
			}
		"sharpen_blade":
			return {
				"id": "sharpen_blade", "station": "forge", "station_level": 1, "copper_cost": 20,
				"materials": [{"id": "iron_scrap", "quantity": 3}, {"id": "stone", "quantity": 2}],
				"results": [{"id": "iron_sword", "quantity": 1}],
			}
		"bogward_tonic":
			return {
				"id": "bogward_tonic", "station": "workbench", "station_level": 1, "copper_cost": 5,
				"materials": [{"id": "herb_bundle", "quantity": 2}, {"id": "bog_herb", "quantity": 1}],
				"results": [{"id": "bogward_tonic", "quantity": 1}],
			}
		"rotfen_travel_supply":
			return {
				"id": "rotfen_travel_supply", "station": "workbench", "station_level": 1, "copper_cost": 0,
				"materials": [{"id": "cloth_scrap", "quantity": 2}, {"id": "wood", "quantity": 1}],
				"results": [{"id": "torch", "quantity": 2}, {"id": "bandage", "quantity": 1}],
			}
		"upgrade_material_craft":
			return {
				"id": "upgrade_material_craft", "station": "forge", "station_level": 1, "copper_cost": 15,
				"materials": [{"id": "iron_scrap", "quantity": 2}, {"id": "swamp_iron", "quantity": 1}],
				"results": [{"id": "upgrade_material", "quantity": 1}],
			}
		"hydration_mixture":
			return {
				"id": "hydration_mixture", "station": "apothecary", "station_level": 1, "copper_cost": 5,
				"materials": [{"id": "cactus_fiber", "quantity": 2}, {"id": "waterskin", "quantity": 1}],
				"results": [{"id": "hydration_salts", "quantity": 2}],
			}
		"sand_lung_remedy":
			return {
				"id": "sand_lung_remedy", "station": "apothecary", "station_level": 1, "copper_cost": 8,
				"materials": [{"id": "cactus_fiber", "quantity": 1}, {"id": "herb_bundle", "quantity": 2}],
				"results": [{"id": "sand_lung_remedy", "quantity": 1}],
			}
		"burn_salve_craft":
			return {
				"id": "burn_salve_craft", "station": "apothecary", "station_level": 1, "copper_cost": 6,
				"materials": [{"id": "cactus_fiber", "quantity": 1}, {"id": "pyre_dust", "quantity": 1}],
				"results": [{"id": "burn_salve", "quantity": 1}],
			}
		"cooling_salve_craft":
			return {
				"id": "cooling_salve_craft", "station": "apothecary", "station_level": 1, "copper_cost": 6,
				"materials": [{"id": "glass_fragment", "quantity": 1}, {"id": "herb_bundle", "quantity": 1}],
				"results": [{"id": "cooling_salve", "quantity": 1}],
			}
		"desert_cleanse":
			return {
				"id": "desert_cleanse", "station": "apothecary", "station_level": 1, "copper_cost": 10,
				"materials": [{"id": "hydration_salts", "quantity": 1}, {"id": "heat_resistance_tonic", "quantity": 1}],
				"results": [{"id": "cooling_salve", "quantity": 2}, {"id": "burn_salve", "quantity": 1}],
			}
		"dread_tonic_craft":
			return {
				"id": "dread_tonic_craft", "station": "apothecary", "station_level": 1, "copper_cost": 8,
				"materials": [{"id": "ward_candle", "quantity": 1}, {"id": "grave_dust", "quantity": 1}],
				"results": [{"id": "dread_resistance_tonic", "quantity": 1}],
			}
		"shadow_cleanse_craft":
			return {
				"id": "shadow_cleanse_craft", "station": "apothecary", "station_level": 1, "copper_cost": 8,
				"materials": [{"id": "silverwood", "quantity": 1}, {"id": "nightglass", "quantity": 1}],
				"results": [{"id": "shadow_cleanse", "quantity": 1}],
			}
		"ward_candle_craft":
			return {
				"id": "ward_candle_craft", "station": "apothecary", "station_level": 1, "copper_cost": 5,
				"materials": [{"id": "silverwood", "quantity": 2}, {"id": "torch", "quantity": 1}],
				"results": [{"id": "ward_candle", "quantity": 2}],
			}
		"lantern_oil_craft":
			return {
				"id": "lantern_oil_craft", "station": "apothecary", "station_level": 1, "copper_cost": 6,
				"materials": [{"id": "ward_candle", "quantity": 1}, {"id": "waterskin", "quantity": 1}],
				"results": [{"id": "lantern_oil", "quantity": 2}],
			}
		"dominion_cleanse":
			return {
				"id": "dominion_cleanse", "station": "apothecary", "station_level": 1, "copper_cost": 12,
				"materials": [{"id": "dread_resistance_tonic", "quantity": 1}, {"id": "shadow_cleanse", "quantity": 1}],
				"results": [{"id": "shadow_cleanse", "quantity": 2}, {"id": "dread_resistance_tonic", "quantity": 1}],
			}
		_:
			return {}
