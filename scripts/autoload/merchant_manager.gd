extends Node
## Data-driven merchant buy/sell catalogs keyed by npc_id.

var active_npc_id: String = "silent_merchant"

const CATALOGS: Dictionary = {
	"silent_merchant": {
		"display_name": "Silent Merchant",
		"buys": [
			{"item_id": "dried_rations", "price": 10},
			{"item_id": "waterskin", "price": 8},
			{"item_id": "bandage", "price": 15},
			{"item_id": "herb_bundle", "price": 12},
		],
		"sells": [
			{"item_id": "wood", "price": 2},
			{"item_id": "cloth_scrap", "price": 3},
			{"item_id": "iron_scrap", "price": 5},
			{"item_id": "bandage", "price": 18},
			{"item_id": "purified_water", "price": 14},
			{"item_id": "repair_kit", "price": 30},
		],
	},
	"camp_vendor": {
		"display_name": "Camp Vendor",
		"buys": [
			{"item_id": "dried_rations", "price": 8},
			{"item_id": "purified_water", "price": 12},
			{"item_id": "repair_kit", "price": 25},
		],
		"sells": [
			{"item_id": "wood", "price": 2},
			{"item_id": "stone", "price": 2},
			{"item_id": "herb_bundle", "price": 4},
			{"item_id": "dried_rations", "price": 6},
			{"item_id": "waterskin", "price": 5},
			{"item_id": "bandage", "price": 12},
		],
	},
}


func set_active_npc(npc_id: String) -> void:
	active_npc_id = npc_id


func get_display_name(npc_id: String = "") -> String:
	var id := npc_id if npc_id != "" else active_npc_id
	return str(CATALOGS.get(id, {}).get("display_name", id.replace("_", " ").capitalize()))


func get_buy_list(npc_id: String = "", price_multiplier: float = 1.0) -> Array:
	return _scaled_entries(npc_id, "buys", price_multiplier)


func get_sell_list(npc_id: String = "", price_multiplier: float = 1.0) -> Array:
	return _scaled_entries(npc_id, "sells", price_multiplier)


func get_price_multiplier_for_anger(anger_state: String) -> float:
	match anger_state:
		"annoyed":
			return 1.5
		"angry", "hostile":
			return 2.0
		_:
			return 1.0


func _scaled_entries(npc_id: String, key: String, multiplier: float) -> Array:
	var id := npc_id if npc_id != "" else active_npc_id
	var catalog: Dictionary = CATALOGS.get(id, CATALOGS.silent_merchant)
	var entries: Array = catalog.get(key, [])
	var result: Array = []
	for entry in entries:
		var scaled: Dictionary = entry.duplicate()
		scaled.price = maxi(1, int(ceil(float(entry.price) * multiplier)))
		result.append(scaled)
	return result
