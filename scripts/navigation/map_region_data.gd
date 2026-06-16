class_name MapRegionData
extends RefCounted
## Region danger, level bands, and display labels for map/HUD.

const REGIONS: Dictionary = {
	"hearthhold_camp": {
		"display_name": "Hearthhold Camp",
		"level_min": 1, "level_max": 3,
		"danger": "Safe",
		"hint": "Hub camp — merchants, crafting, and missions",
	},
	"darkpine_forest": {
		"display_name": "Darkpine Forest",
		"level_min": 2, "level_max": 5,
		"danger": "Moderate",
		"hint": "Starting wilds — bandits and scrap",
	},
	"ruined_watchtower": {
		"display_name": "Ruined Watchtower",
		"level_min": 4, "level_max": 7,
		"danger": "Dangerous",
		"hint": "Hostiles on the tower island",
	},
	"bandit_camp": {
		"display_name": "Bandit Camp",
		"level_min": 6, "level_max": 9,
		"danger": "Dangerous",
		"hint": "Bandit Captain and raiders",
	},
	"crystal_cave": {
		"display_name": "Crystal Cave",
		"level_min": 7, "level_max": 10,
		"danger": "Dangerous",
		"hint": "Crystal shards and cave hostiles",
	},
	"hollow_grove_shrine": {
		"display_name": "Hollow Grove Shrine",
		"level_min": 10, "level_max": 12,
		"danger": "Deadly",
		"hint": "Warden boss shrine",
	},
	"rotfen_marsh": {
		"display_name": "Rotfen Marsh",
		"level_min": 8, "level_max": 14,
		"danger": "Dangerous",
		"hint": "Poison marsh — stock tonics",
	},
	"ashfall_highlands": {
		"display_name": "Ashfall Highlands",
		"level_min": 12, "level_max": 18,
		"danger": "Deadly",
		"hint": "Heat and raiders",
	},
	"frostgrave_expanse": {
		"display_name": "Frostgrave Expanse",
		"level_min": 14, "level_max": 20,
		"danger": "Deadly",
		"hint": "Gravewind and frost",
	},
	"shattered_coast": {
		"display_name": "Shattered Coast",
		"level_min": 16, "level_max": 22,
		"danger": "Deadly",
		"hint": "Storm coast and wrecks",
	},
	"blightreach": {
		"display_name": "Blightreach",
		"level_min": 18, "level_max": 24,
		"danger": "Deadly",
		"hint": "Corruption fields",
	},
	"ember_wastes": {
		"display_name": "Ember Wastes",
		"level_min": 20, "level_max": 26,
		"danger": "Deadly",
		"hint": "Desert heat and cultists",
	},
	"sunless_dominion": {
		"display_name": "Sunless Dominion",
		"level_min": 22, "level_max": 28,
		"danger": "Deadly",
		"hint": "Eclipse lands",
	},
}


static func get_display_name(region_id: String) -> String:
	return str(REGIONS.get(region_id, {}).get("display_name", region_id.replace("_", " ").capitalize()))


static func get_level_label(region_id: String) -> String:
	var data: Dictionary = REGIONS.get(region_id, {})
	var lo := int(data.get("level_min", 1))
	var hi := int(data.get("level_max", lo))
	if lo == hi:
		return "Level %d" % lo
	return "Level %d–%d" % [lo, hi]


static func get_danger_label(region_id: String) -> String:
	return str(REGIONS.get(region_id, {}).get("danger", "Unknown"))


static func get_region_summary(region_id: String) -> String:
	var name := get_display_name(region_id)
	var danger := get_danger_label(region_id)
	var levels := get_level_label(region_id)
	if danger == "Safe":
		return "%s — %s" % [name, danger]
	return "%s — %s" % [name, levels]


static func get_state_label(state: int) -> String:
	match state:
		MapManager.RegionState.UNDISCOVERED: return "Undiscovered"
		MapManager.RegionState.DISCOVERED: return "Discovered"
		MapManager.RegionState.EXPLORED: return "Explored"
		MapManager.RegionState.CLEARED: return "Cleared"
		MapManager.RegionState.DANGEROUS: return "Dangerous"
		_: return "Unknown"
