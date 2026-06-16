extends Node
## Data-driven merchant buy/sell catalogs, stock, and atomic transactions.

signal shop_opened(npc_id: String)
signal shop_closed
signal transaction_completed(result: RefCounted)

const ShopTransactionResultScript = preload("res://scripts/shop/shop_transaction_result.gd")

var active_npc_id: String = "silent_merchant"
var is_shop_open: bool = false
var sell_price_multiplier: float = 0.5

var _stock: Dictionary = {}

const CATALOGS: Dictionary = {
	"silent_merchant": {
		"display_name": "Silent Merchant",
		"sell_price_multiplier": 0.5,
		"buys": [
			{"item_id": "dried_rations", "price": 10, "stock": -1},
			{"item_id": "waterskin", "price": 8, "stock": -1},
			{"item_id": "bandage", "price": 15, "stock": 20},
			{"item_id": "herb_bundle", "price": 12, "stock": 15},
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
		"sell_price_multiplier": 0.5,
		"buys": [
			{"item_id": "dried_rations", "price": 8, "stock": -1},
			{"item_id": "purified_water", "price": 12, "stock": -1},
			{"item_id": "repair_kit", "price": 25, "stock": 5},
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
	"herbalist": {
		"display_name": "Herbalist",
		"sell_price_multiplier": 0.45,
		"buys": [
			{"item_id": "herb_bundle", "price": 14, "stock": 10},
		],
		"sells": [
			{"item_id": "herb_bundle", "price": 5},
			{"item_id": "bandage", "price": 10},
			{"item_id": "purified_water", "price": 12},
			{"item_id": "dried_rations", "price": 7},
		],
	},
	"old_blacksmith": {
		"display_name": "Old Blacksmith",
		"sell_price_multiplier": 0.55,
		"buys": [
			{"item_id": "iron_scrap", "price": 6, "stock": -1},
			{"item_id": "wood", "price": 2, "stock": -1},
		],
		"sells": [
			{"item_id": "iron_scrap", "price": 8},
			{"item_id": "repair_kit", "price": 28},
			{"item_id": "wood", "price": 3},
			{"item_id": "stone", "price": 3},
		],
	},
	"tool_vendor": {
		"display_name": "Tool Vendor",
		"sell_price_multiplier": 0.5,
		"buys": [
			{"item_id": "wood", "price": 3, "stock": -1},
			{"item_id": "stone", "price": 3, "stock": -1},
			{"item_id": "cloth_scrap", "price": 4, "stock": -1},
		],
		"sells": [
			{"item_id": "wood", "price": 2},
			{"item_id": "stone", "price": 2},
			{"item_id": "cloth_scrap", "price": 5},
			{"item_id": "repair_kit", "price": 32},
			{"item_id": "waterskin", "price": 6},
		],
	},
	"tomas_reed": {
		"display_name": "Tomas Reed",
		"sell_price_multiplier": 0.5,
		"buys": [
			{"item_id": "dried_rations", "price": 8, "stock": -1},
			{"item_id": "waterskin", "price": 6, "stock": -1},
			{"item_id": "bandage", "price": 12, "stock": 20},
			{"item_id": "herb_bundle", "price": 10, "stock": 15},
			{"item_id": "bogward_tonic", "price": 22, "stock": 8},
		],
		"sells": [
			{"item_id": "dried_rations", "price": 6},
			{"item_id": "waterskin", "price": 5},
			{"item_id": "bandage", "price": 10},
			{"item_id": "herb_bundle", "price": 4},
			{"item_id": "bogward_tonic", "price": 28},
			{"item_id": "torch", "price": 8},
			{"item_id": "wood", "price": 2},
			{"item_id": "cloth_scrap", "price": 4},
			{"item_id": "iron_scrap", "price": 6},
		],
	},
	"weapon_armorer": {
		"display_name": "Arms Dealer",
		"sell_price_multiplier": 0.45,
		"buys": [
			{"item_id": "iron_scrap", "price": 5, "stock": -1},
			{"item_id": "rusty_sword", "price": 8, "stock": 3},
		],
		"sells": [
			{"item_id": "steel_dagger", "price": 45},
			{"item_id": "leather_armor", "price": 55},
			{"item_id": "wooden_shield", "price": 35},
			{"item_id": "iron_sword", "price": 80},
			{"item_id": "upgrade_material", "price": 25},
		],
	},
	"bram_ironhand": {
		"display_name": "Bram Ironhand",
		"sell_price_multiplier": 0.55,
		"buys": [
			{"item_id": "iron_scrap", "price": 6, "stock": -1},
			{"item_id": "swamp_iron", "price": 8, "stock": -1},
			{"item_id": "wood", "price": 2, "stock": -1},
		],
		"sells": [
			{"item_id": "iron_scrap", "price": 8},
			{"item_id": "repair_kit", "price": 26},
			{"item_id": "upgrade_material", "price": 30},
			{"item_id": "wood", "price": 3},
			{"item_id": "stone", "price": 3},
		],
	},
	"quartermaster_vale": {
		"display_name": "Quartermaster Vale",
		"sell_price_multiplier": 0.5,
		"buys": [
			{"item_id": "wood", "price": 3, "stock": -1},
			{"item_id": "stone", "price": 3, "stock": -1},
			{"item_id": "drowned_scrap", "price": 4, "stock": -1},
		],
		"sells": [
			{"item_id": "wood", "price": 2},
			{"item_id": "stone", "price": 2},
			{"item_id": "nails", "price": 4},
			{"item_id": "repair_kit", "price": 30},
			{"item_id": "cloth_scrap", "price": 5},
			{"item_id": "waterskin", "price": 6},
		],
	},
	"marsh_scout_vendor": {
		"display_name": "Marsh Scout",
		"sell_price_multiplier": 0.5,
		"buys": [
			{"item_id": "bog_herb", "price": 6, "stock": 10},
			{"item_id": "poison_gland", "price": 8, "stock": 5},
		],
		"sells": [
			{"item_id": "bandage", "price": 14},
			{"item_id": "bogward_tonic", "price": 32},
			{"item_id": "dried_rations", "price": 8},
			{"item_id": "waterskin", "price": 6},
		],
	},
	"stonewatch_merchant": {
		"display_name": "Merrin Slate",
		"sell_price_multiplier": 0.5,
		"buys": [
			{"item_id": "dried_rations", "price": 9, "stock": -1},
			{"item_id": "waterskin", "price": 7, "stock": -1},
			{"item_id": "bandage", "price": 14, "stock": 25},
			{"item_id": "heat_resistance_tonic", "price": 26, "stock": 10},
			{"item_id": "ash_filter_mask", "price": 18, "stock": 8},
			{"item_id": "repair_kit", "price": 28, "stock": 6},
		],
		"sells": [
			{"item_id": "dried_rations", "price": 7},
			{"item_id": "waterskin", "price": 6},
			{"item_id": "bandage", "price": 12},
			{"item_id": "heat_resistance_tonic", "price": 32},
			{"item_id": "ash_filter_mask", "price": 22},
			{"item_id": "cinder_ore", "price": 6},
			{"item_id": "blackvein_iron", "price": 10},
			{"item_id": "machine_scrap", "price": 5},
			{"item_id": "wood", "price": 2},
			{"item_id": "iron_scrap", "price": 6},
		],
	},
	"stonewatch_forge": {
		"display_name": "Hesta Coalhand",
		"sell_price_multiplier": 0.55,
		"buys": [
			{"item_id": "cinder_ore", "price": 7, "stock": -1},
			{"item_id": "blackvein_iron", "price": 12, "stock": -1},
			{"item_id": "machine_scrap", "price": 6, "stock": -1},
			{"item_id": "furnace_core", "price": 40, "stock": 3},
			{"item_id": "iron_scrap", "price": 6, "stock": -1},
		],
		"sells": [
			{"item_id": "iron_sword", "price": 85},
			{"item_id": "leather_armor", "price": 60},
			{"item_id": "upgrade_material", "price": 35},
			{"item_id": "repair_kit", "price": 30},
			{"item_id": "heat_resistance_tonic", "price": 30},
			{"item_id": "blackvein_iron", "price": 12},
		],
	},
	"frostwatch_merchant": {
		"display_name": "Elen Marr",
		"sell_price_multiplier": 0.5,
		"buys": [
			{"item_id": "dried_rations", "price": 9, "stock": -1},
			{"item_id": "waterskin", "price": 7, "stock": -1},
			{"item_id": "bandage", "price": 14, "stock": 25},
			{"item_id": "warming_tonic", "price": 26, "stock": 10},
			{"item_id": "torch", "price": 8, "stock": 12},
			{"item_id": "repair_kit", "price": 28, "stock": 6},
		],
		"sells": [
			{"item_id": "dried_rations", "price": 7},
			{"item_id": "waterskin", "price": 6},
			{"item_id": "bandage", "price": 12},
			{"item_id": "warming_tonic", "price": 32},
			{"item_id": "torch", "price": 10},
			{"item_id": "wood", "price": 2},
			{"item_id": "rime_ore", "price": 7},
			{"item_id": "frostwood", "price": 4},
			{"item_id": "iron_scrap", "price": 6},
		],
	},
	"frostwatch_forge": {
		"display_name": "Orik Frosthand",
		"sell_price_multiplier": 0.55,
		"buys": [
			{"item_id": "rime_ore", "price": 8, "stock": -1},
			{"item_id": "black_ice", "price": 14, "stock": -1},
			{"item_id": "glacial_crystal", "price": 18, "stock": -1},
			{"item_id": "frostwood", "price": 5, "stock": -1},
			{"item_id": "frozen_hide", "price": 7, "stock": -1},
			{"item_id": "iron_scrap", "price": 6, "stock": -1},
		],
		"sells": [
			{"item_id": "iron_sword", "price": 85},
			{"item_id": "frostguard_armor", "price": 95},
			{"item_id": "upgrade_material", "price": 35},
			{"item_id": "repair_kit", "price": 30},
			{"item_id": "warming_tonic", "price": 28},
			{"item_id": "black_ice", "price": 16},
			{"item_id": "glacial_crystal", "price": 20},
		],
	},
	"tidewatch_merchant": {
		"display_name": "Maela Shore",
		"sell_price_multiplier": 0.5,
		"buys": [
			{"item_id": "dried_rations", "price": 9, "stock": -1},
			{"item_id": "waterskin", "price": 7, "stock": -1},
			{"item_id": "bandage", "price": 14, "stock": 25},
			{"item_id": "storm_resistance_tonic", "price": 28, "stock": 10},
			{"item_id": "torch", "price": 8, "stock": 12},
			{"item_id": "repair_kit", "price": 28, "stock": 6},
		],
		"sells": [
			{"item_id": "dried_rations", "price": 7},
			{"item_id": "waterskin", "price": 6},
			{"item_id": "bandage", "price": 12},
			{"item_id": "storm_resistance_tonic", "price": 34},
			{"item_id": "torch", "price": 10},
			{"item_id": "driftwood", "price": 3},
			{"item_id": "salt_iron", "price": 8},
			{"item_id": "kelp_fiber", "price": 4},
			{"item_id": "iron_scrap", "price": 6},
		],
	},
	"tidewatch_forge": {
		"display_name": "Garrick Hull",
		"sell_price_multiplier": 0.55,
		"buys": [
			{"item_id": "salt_iron", "price": 9, "stock": -1},
			{"item_id": "stormglass", "price": 14, "stock": -1},
			{"item_id": "barnacle_plate", "price": 12, "stock": -1},
			{"item_id": "driftwood", "price": 4, "stock": -1},
			{"item_id": "drowned_relic", "price": 22, "stock": -1},
			{"item_id": "iron_scrap", "price": 6, "stock": -1},
		],
		"sells": [
			{"item_id": "iron_sword", "price": 85},
			{"item_id": "tideguard_armor", "price": 95},
			{"item_id": "upgrade_material", "price": 35},
			{"item_id": "repair_kit", "price": 30},
			{"item_id": "storm_resistance_tonic", "price": 30},
			{"item_id": "stormglass", "price": 16},
			{"item_id": "barnacle_plate", "price": 14},
		],
	},
	"lastwall_merchant": {
		"display_name": "Tessa Thorn",
		"sell_price_multiplier": 0.5,
		"buys": [
			{"item_id": "dried_rations", "price": 9, "stock": -1},
			{"item_id": "waterskin", "price": 7, "stock": -1},
			{"item_id": "bandage", "price": 14, "stock": 25},
			{"item_id": "blight_resistance_tonic", "price": 28, "stock": 10},
			{"item_id": "spore_filter", "price": 32, "stock": 8},
			{"item_id": "cleansing_salve", "price": 18, "stock": 12},
			{"item_id": "torch", "price": 8, "stock": 12},
		],
		"sells": [
			{"item_id": "dried_rations", "price": 7},
			{"item_id": "waterskin", "price": 6},
			{"item_id": "bandage", "price": 12},
			{"item_id": "blight_resistance_tonic", "price": 34},
			{"item_id": "spore_filter", "price": 38},
			{"item_id": "cleansing_salve", "price": 22},
			{"item_id": "torch", "price": 10},
			{"item_id": "iron_scrap", "price": 6},
			{"item_id": "blightwood", "price": 4},
			{"item_id": "sporecap", "price": 5},
		],
	},
	"lastwall_apothecary": {
		"display_name": "Doctor Eldric Venn",
		"sell_price_multiplier": 0.55,
		"buys": [
			{"item_id": "sporecap", "price": 6, "stock": -1},
			{"item_id": "fungal_gland", "price": 10, "stock": -1},
			{"item_id": "corrupted_fiber", "price": 5, "stock": -1},
		],
		"sells": [
			{"item_id": "blight_resistance_tonic", "price": 32},
			{"item_id": "spore_antidote", "price": 28},
			{"item_id": "corruption_cleanse", "price": 36},
			{"item_id": "regeneration_salve", "price": 30},
			{"item_id": "cleansing_salve", "price": 20},
		],
	},
	"lastwall_blightsmith": {
		"display_name": "Garran Rootbreaker",
		"sell_price_multiplier": 0.55,
		"buys": [
			{"item_id": "blightwood", "price": 5, "stock": -1},
			{"item_id": "root_iron", "price": 10, "stock": -1},
			{"item_id": "viridian_crystal", "price": 14, "stock": -1},
			{"item_id": "purified_resin", "price": 12, "stock": -1},
			{"item_id": "corrupted_fiber", "price": 6, "stock": -1},
		],
		"sells": [
			{"item_id": "iron_sword", "price": 85},
			{"item_id": "leather_armor", "price": 55},
			{"item_id": "upgrade_material", "price": 35},
			{"item_id": "repair_kit", "price": 30},
			{"item_id": "blight_resistance_tonic", "price": 32},
			{"item_id": "root_iron", "price": 12},
			{"item_id": "purified_resin", "price": 14},
		],
	},
	"nima_dareth": {
		"display_name": "Nima Dareth",
		"sell_price_multiplier": 0.5,
		"buys": [
			{"item_id": "dried_rations", "price": 9, "stock": -1},
			{"item_id": "waterskin", "price": 7, "stock": -1},
			{"item_id": "bandage", "price": 14, "stock": 25},
			{"item_id": "scorched_sand", "price": 4, "stock": -1},
			{"item_id": "glass_fragment", "price": 6, "stock": -1},
			{"item_id": "pyre_dust", "price": 5, "stock": -1},
		],
		"sells": [
			{"item_id": "dried_rations", "price": 7},
			{"item_id": "waterskin", "price": 6},
			{"item_id": "bandage", "price": 12},
			{"item_id": "hydration_salts", "price": 14},
			{"item_id": "heat_resistance_tonic", "price": 34},
			{"item_id": "cooling_salve", "price": 22},
			{"item_id": "torch", "price": 10},
			{"item_id": "scorched_sand", "price": 5},
			{"item_id": "sunstone_shard", "price": 8},
			{"item_id": "cactus_fiber", "price": 4},
		],
	},
	"dagan_sunforge": {
		"display_name": "Dagan Sunforge",
		"sell_price_multiplier": 0.55,
		"buys": [
			{"item_id": "scorched_sand", "price": 5, "stock": -1},
			{"item_id": "glass_fragment", "price": 7, "stock": -1},
			{"item_id": "sunstone_shard", "price": 10, "stock": -1},
			{"item_id": "pyre_dust", "price": 6, "stock": -1},
			{"item_id": "desert_glass", "price": 14, "stock": -1},
			{"item_id": "pyre_crystal", "price": 16, "stock": -1},
		],
		"sells": [
			{"item_id": "iron_sword", "price": 85},
			{"item_id": "leather_armor", "price": 55},
			{"item_id": "upgrade_material", "price": 35},
			{"item_id": "repair_kit", "price": 30},
			{"item_id": "heat_resistance_tonic", "price": 32},
			{"item_id": "desert_glass", "price": 12},
			{"item_id": "pyre_crystal", "price": 14},
		],
	},
	"doctor_sol_marr": {
		"display_name": "Doctor Sol Marr",
		"sell_price_multiplier": 0.55,
		"buys": [
			{"item_id": "cactus_fiber", "price": 5, "stock": -1},
			{"item_id": "pyre_dust", "price": 6, "stock": -1},
			{"item_id": "glass_fragment", "price": 6, "stock": -1},
		],
		"sells": [
			{"item_id": "heat_resistance_tonic", "price": 32},
			{"item_id": "hydration_salts", "price": 14},
			{"item_id": "cooling_salve", "price": 20},
			{"item_id": "burn_salve", "price": 24},
			{"item_id": "sand_lung_remedy", "price": 28},
		],
	},
	"mira_sol": {
		"display_name": "Mira Sol",
		"sell_price_multiplier": 0.5,
		"buys": [
			{"item_id": "dried_rations", "price": 9, "stock": -1},
			{"item_id": "waterskin", "price": 7, "stock": -1},
			{"item_id": "bandage", "price": 14, "stock": 25},
			{"item_id": "moonstone", "price": 8, "stock": -1},
			{"item_id": "nightglass", "price": 7, "stock": -1},
			{"item_id": "grave_dust", "price": 5, "stock": -1},
		],
		"sells": [
			{"item_id": "dried_rations", "price": 7},
			{"item_id": "waterskin", "price": 6},
			{"item_id": "bandage", "price": 12},
			{"item_id": "dread_resistance_tonic", "price": 36},
			{"item_id": "shadow_cleanse", "price": 26},
			{"item_id": "torch", "price": 10},
			{"item_id": "ward_candle", "price": 8},
			{"item_id": "lantern_oil", "price": 12},
			{"item_id": "moonstone", "price": 9},
			{"item_id": "silverwood", "price": 5},
		],
	},
	"selene_nightforge": {
		"display_name": "Selene Nightforge",
		"sell_price_multiplier": 0.55,
		"buys": [
			{"item_id": "umbral_ore", "price": 8, "stock": -1},
			{"item_id": "shadow_hide", "price": 7, "stock": -1},
			{"item_id": "nightglass", "price": 8, "stock": -1},
			{"item_id": "moonstone", "price": 10, "stock": -1},
			{"item_id": "silverwood", "price": 5, "stock": -1},
		],
		"sells": [
			{"item_id": "iron_sword", "price": 85},
			{"item_id": "leather_armor", "price": 55},
			{"item_id": "upgrade_material", "price": 35},
			{"item_id": "repair_kit", "price": 30},
			{"item_id": "dread_resistance_tonic", "price": 34},
			{"item_id": "umbral_ore", "price": 10},
			{"item_id": "ward_candle", "price": 9},
		],
	},
	"doctor_corvin_hale": {
		"display_name": "Doctor Corvin Hale",
		"sell_price_multiplier": 0.55,
		"buys": [
			{"item_id": "grave_dust", "price": 5, "stock": -1},
			{"item_id": "nightglass", "price": 7, "stock": -1},
			{"item_id": "silverwood", "price": 4, "stock": -1},
		],
		"sells": [
			{"item_id": "dread_resistance_tonic", "price": 34},
			{"item_id": "shadow_cleanse", "price": 24},
			{"item_id": "lantern_oil", "price": 14},
			{"item_id": "ward_candle", "price": 8},
		],
	},
}


func _ready() -> void:
	reset_for_new_game()


func reset_for_new_game() -> void:
	_stock.clear()
	_init_stock_from_catalogs()
	is_shop_open = false


func notify_shop_opened(npc_id: String) -> void:
	active_npc_id = npc_id
	is_shop_open = true
	shop_opened.emit(npc_id)


func notify_shop_closed() -> void:
	is_shop_open = false
	shop_closed.emit()


func set_active_npc(npc_id: String) -> void:
	active_npc_id = npc_id


func get_display_name(npc_id: String = "") -> String:
	var id := npc_id if npc_id != "" else active_npc_id
	return str(CATALOGS.get(id, {}).get("display_name", id.replace("_", " ").capitalize()))


func get_sell_multiplier(npc_id: String = "") -> float:
	var id := npc_id if npc_id != "" else active_npc_id
	return float(CATALOGS.get(id, {}).get("sell_price_multiplier", sell_price_multiplier))


func get_price_multiplier_for_anger(anger_state: String) -> float:
	match anger_state:
		"annoyed":
			return 1.5
		"angry", "hostile":
			return 2.0
		_:
			return 1.0


func get_buy_list(npc_id: String = "", price_multiplier: float = 1.0) -> Array:
	return _scaled_buy_entries(npc_id, price_multiplier)


func get_sell_list(npc_id: String = "", price_multiplier: float = 1.0) -> Array:
	return _scaled_sell_entries(npc_id, price_multiplier)


func get_stock(npc_id: String, item_id: String) -> int:
	var key := _stock_key(npc_id, item_id)
	if not _stock.has(key):
		return -1
	return int(_stock[key])


func get_buy_unit_price(npc_id: String, item_id: String, price_multiplier: float = 1.0) -> int:
	for entry in get_buy_list(npc_id, price_multiplier):
		if entry.item_id == item_id:
			return int(entry.price)
	return 0


func get_sell_unit_price(npc_id: String, item_id: String, price_multiplier: float = 1.0) -> int:
	for entry in get_sell_list(npc_id, price_multiplier):
		if entry.item_id == item_id:
			return int(entry.price)
	return 0


func get_max_buy_quantity(npc_id: String, item_id: String, price_multiplier: float = 1.0) -> int:
	var stock := get_stock(npc_id, item_id)
	var cap := InventoryManager.get_max_add_quantity(item_id)
	var unit := get_buy_unit_price(npc_id, item_id, price_multiplier)
	if unit <= 0:
		return 0
	var affordable := CurrencyManager.get_total_copper() / unit if unit > 0 else 0
	var max_q := mini(cap, affordable)
	if stock >= 0:
		max_q = mini(max_q, stock)
	return maxi(max_q, 0)


func get_max_sell_quantity(npc_id: String, item_id: String) -> int:
	var check := InventoryManager.get_sellable_quantity(item_id)
	if not check.get("ok", false):
		return 0
	return int(check.get("quantity", 0))


func get_buy_disabled_reason(npc_id: String, item_id: String, quantity: int, price_multiplier: float) -> String:
	if get_buy_unit_price(npc_id, item_id, price_multiplier) <= 0:
		return "Unavailable"
	var stock := get_stock(npc_id, item_id)
	if stock == 0:
		return "Out of stock"
	if quantity <= 0:
		return "Invalid quantity"
	var total := get_buy_unit_price(npc_id, item_id, price_multiplier) * quantity
	if not CurrencyManager.can_afford_copper(total):
		return "Not enough Copper"
	var add_check := InventoryManager.can_add_item(item_id, quantity)
	if not add_check.get("ok", false):
		return str(add_check.get("reason", "Inventory full"))
	return ""


func get_sell_disabled_reason(npc_id: String, item_id: String, quantity: int) -> String:
	var check := InventoryManager.get_sellable_quantity(item_id)
	if not check.get("ok", false):
		return str(check.get("reason", "Cannot sell"))
	if quantity <= 0 or quantity > int(check.get("quantity", 0)):
		return "Invalid quantity"
	if get_sell_unit_price(npc_id, item_id) <= 0:
		return "Merchant won't buy this"
	return ""


func buy_item(npc_id: String, item_id: String, quantity: int, price_multiplier: float = 1.0) -> RefCounted:
	var result := ShopTransactionResultScript.new()
	result.is_buy = true
	result.item_id = StringName(item_id)
	result.quantity = quantity
	result.unit_price = get_buy_unit_price(npc_id, item_id, price_multiplier)
	result.total_price = result.unit_price * quantity
	result.currency_before = CurrencyManager.get_total_copper()
	var reason := get_buy_disabled_reason(npc_id, item_id, quantity, price_multiplier)
	if reason != "":
		result.success = false
		result.message = reason
		result.currency_after = result.currency_before
		return result
	if not CurrencyManager.spend_copper(result.total_price):
		result.success = false
		result.message = "Not enough Copper"
		result.currency_after = result.currency_before
		return result
	if not InventoryManager.add_item(item_id, quantity):
		CurrencyManager.add_copper(result.total_price)
		result.success = false
		result.message = "Inventory full"
		result.currency_after = CurrencyManager.get_total_copper()
		return result
	_decrement_stock(npc_id, item_id, quantity)
	result.success = true
	result.currency_after = CurrencyManager.get_total_copper()
	result.message = "Purchased %d %s\n-%d Copper" % [
		quantity,
		ItemDatabase.get_display_name(item_id),
		result.total_price,
	]
	transaction_completed.emit(result)
	return result


func sell_item(npc_id: String, item_id: String, quantity: int, price_multiplier: float = 1.0) -> RefCounted:
	var result := ShopTransactionResultScript.new()
	result.is_buy = false
	result.item_id = StringName(item_id)
	result.quantity = quantity
	result.unit_price = get_sell_unit_price(npc_id, item_id, price_multiplier)
	result.total_price = result.unit_price * quantity
	result.currency_before = CurrencyManager.get_total_copper()
	var reason := get_sell_disabled_reason(npc_id, item_id, quantity)
	if reason != "":
		result.success = false
		result.message = reason
		result.currency_after = result.currency_before
		return result
	if not InventoryManager.remove_item(item_id, quantity):
		result.success = false
		result.message = "Item no longer available"
		result.currency_after = result.currency_before
		return result
	CurrencyManager.add_copper(result.total_price)
	result.success = true
	result.currency_after = CurrencyManager.get_total_copper()
	result.message = "Sold %d %s\n+%d Copper" % [
		quantity,
		ItemDatabase.get_display_name(item_id),
		result.total_price,
	]
	transaction_completed.emit(result)
	return result


func serialize() -> Dictionary:
	return {"stock": _stock.duplicate(true)}


func deserialize(data: Dictionary) -> void:
	if data.has("stock"):
		_stock = data.stock


func _init_stock_from_catalogs() -> void:
	for npc_id in CATALOGS.keys():
		var catalog: Dictionary = CATALOGS[npc_id]
		for entry in catalog.get("buys", []):
			var item_id: String = entry.item_id
			var stock_val: int = int(entry.get("stock", -1))
			if stock_val >= 0:
				_stock[_stock_key(npc_id, item_id)] = stock_val


func _scaled_buy_entries(npc_id: String, multiplier: float) -> Array:
	var id := npc_id if npc_id != "" else active_npc_id
	var catalog: Dictionary = CATALOGS.get(id, CATALOGS.silent_merchant)
	var result: Array = []
	for entry in catalog.get("buys", []):
		var item_id: String = entry.item_id
		var scaled: Dictionary = {
			"item_id": item_id,
			"price": maxi(1, int(ceil(float(entry.price) * multiplier))),
			"stock": get_stock(id, item_id),
		}
		result.append(scaled)
	return result


func _scaled_sell_entries(npc_id: String, multiplier: float) -> Array:
	var id := npc_id if npc_id != "" else active_npc_id
	var catalog: Dictionary = CATALOGS.get(id, CATALOGS.silent_merchant)
	var sell_mult := get_sell_multiplier(id)
	var result: Array = []
	for entry in catalog.get("sells", []):
		var merchant_buy: int = maxi(1, int(ceil(float(entry.price) * multiplier)))
		var scaled: Dictionary = {
			"item_id": entry.item_id,
			"price": maxi(1, int(floor(float(merchant_buy) * sell_mult))),
		}
		result.append(scaled)
	return result


func _stock_key(npc_id: String, item_id: String) -> String:
	return "%s:%s" % [npc_id, item_id]


func _decrement_stock(npc_id: String, item_id: String, quantity: int) -> void:
	var key := _stock_key(npc_id, item_id)
	if not _stock.has(key):
		return
	_stock[key] = maxi(0, int(_stock[key]) - quantity)
