class_name MinimapRegistry
extends RefCounted
## Central marker category definitions for minimap and future world map.

enum Category {
	PLAYER,
	MAIN_QUEST,
	SIDE_QUEST,
	TRACKED_OBJECTIVE,
	WAYPOINT,
	TOWN,
	VILLAGE,
	MERCHANT,
	CRAFT_VENDOR,
	CAMP,
	FAST_TRAVEL,
	DUNGEON,
	CAVE,
	INTERIOR,
	FRIENDLY_NPC,
	ENEMY,
	ELITE_ENEMY,
	BOSS,
	LOOT,
	INTERACTABLE,
	UNKNOWN,
	BUILDING,
	TRAIL,
}

const DEFS := {
	Category.PLAYER: {
		"id": "player", "priority": 100, "max_distance": 9999.0,
		"undiscovered": false, "fog_visible": true, "edge_clamp": false,
		"shape": "arrow", "size": 8.0,
	},
	Category.MAIN_QUEST: {
		"id": "main_quest", "priority": 1, "max_distance": 9999.0,
		"undiscovered": false, "fog_visible": true, "edge_clamp": true,
		"shape": "diamond", "size": 7.0, "color": UiColors.TEXT_QUEST,
	},
	Category.SIDE_QUEST: {
		"id": "side_quest", "priority": 3, "max_distance": 9999.0,
		"undiscovered": false, "fog_visible": true, "edge_clamp": true,
		"shape": "diamond", "size": 6.0, "color": Color(0.62, 0.58, 0.72, 1.0),
	},
	Category.TRACKED_OBJECTIVE: {
		"id": "tracked_objective", "priority": 2, "max_distance": 9999.0,
		"undiscovered": false, "fog_visible": true, "edge_clamp": true,
		"shape": "diamond", "size": 7.0, "color": UiColors.TEXT_QUEST,
	},
	Category.WAYPOINT: {
		"id": "waypoint", "priority": 2, "max_distance": 9999.0,
		"undiscovered": false, "fog_visible": true, "edge_clamp": true,
		"shape": "pin", "size": 6.0, "color": Color(0.42, 0.58, 0.78, 1.0),
	},
	Category.TOWN: {
		"id": "town", "priority": 5, "max_distance": 120.0,
		"undiscovered": true, "fog_visible": true, "edge_clamp": false,
		"shape": "square", "size": 5.0, "color": Color(0.72, 0.66, 0.48, 1.0),
	},
	Category.VILLAGE: {
		"id": "village", "priority": 5, "max_distance": 100.0,
		"undiscovered": true, "fog_visible": true, "edge_clamp": false,
		"shape": "square", "size": 4.5, "color": Color(0.68, 0.62, 0.44, 1.0),
	},
	Category.MERCHANT: {
		"id": "merchant", "priority": 6, "max_distance": 50.0,
		"undiscovered": true, "fog_visible": true, "edge_clamp": false,
		"shape": "circle", "size": 4.0, "color": Color(0.78, 0.68, 0.36, 1.0),
	},
	Category.CRAFT_VENDOR: {
		"id": "craft_vendor", "priority": 6, "max_distance": 50.0,
		"undiscovered": true, "fog_visible": true, "edge_clamp": false,
		"shape": "circle", "size": 4.0, "color": Color(0.62, 0.58, 0.48, 1.0),
	},
	Category.CAMP: {
		"id": "camp", "priority": 6, "max_distance": 60.0,
		"undiscovered": true, "fog_visible": true, "edge_clamp": false,
		"shape": "triangle", "size": 4.5, "color": Color(0.52, 0.62, 0.42, 1.0),
	},
	Category.FAST_TRAVEL: {
		"id": "fast_travel", "priority": 4, "max_distance": 9999.0,
		"undiscovered": true, "fog_visible": true, "edge_clamp": true,
		"shape": "circle", "size": 5.0, "color": Color(0.35, 0.75, 0.95, 1.0),
	},
	Category.DUNGEON: {
		"id": "dungeon", "priority": 7, "max_distance": 80.0,
		"undiscovered": true, "fog_visible": true, "edge_clamp": false,
		"shape": "square", "size": 5.0, "color": Color(0.58, 0.42, 0.62, 1.0),
	},
	Category.CAVE: {
		"id": "cave", "priority": 7, "max_distance": 70.0,
		"undiscovered": true, "fog_visible": true, "edge_clamp": false,
		"shape": "square", "size": 4.5, "color": Color(0.48, 0.44, 0.52, 1.0),
	},
	Category.INTERIOR: {
		"id": "interior", "priority": 8, "max_distance": 40.0,
		"undiscovered": true, "fog_visible": true, "edge_clamp": false,
		"shape": "square", "size": 4.0, "color": Color(0.55, 0.55, 0.58, 1.0),
	},
	Category.FRIENDLY_NPC: {
		"id": "friendly_npc", "priority": 9, "max_distance": 35.0,
		"undiscovered": false, "fog_visible": true, "edge_clamp": false,
		"shape": "circle", "size": 3.5, "color": Color(0.58, 0.72, 0.58, 1.0),
	},
	Category.ENEMY: {
		"id": "enemy", "priority": 10, "max_distance": 36.0,
		"undiscovered": false, "fog_visible": false, "edge_clamp": false,
		"shape": "circle", "size": 3.0, "color": Color(0.62, 0.18, 0.16, 1.0),
	},
	Category.ELITE_ENEMY: {
		"id": "elite_enemy", "priority": 10, "max_distance": 45.0,
		"undiscovered": false, "fog_visible": false, "edge_clamp": false,
		"shape": "diamond", "size": 4.0, "color": Color(0.72, 0.22, 0.18, 1.0),
	},
	Category.BOSS: {
		"id": "boss", "priority": 10, "max_distance": 60.0,
		"undiscovered": false, "fog_visible": false, "edge_clamp": false,
		"shape": "diamond", "size": 5.5, "color": Color(0.82, 0.28, 0.20, 1.0),
	},
	Category.LOOT: {
		"id": "loot", "priority": 11, "max_distance": 22.0,
		"undiscovered": false, "fog_visible": false, "edge_clamp": false,
		"shape": "circle", "size": 2.5, "color": Color(0.78, 0.72, 0.38, 1.0),
	},
	Category.INTERACTABLE: {
		"id": "interactable", "priority": 11, "max_distance": 25.0,
		"undiscovered": false, "fog_visible": false, "edge_clamp": false,
		"shape": "circle", "size": 2.5, "color": Color(0.68, 0.68, 0.72, 1.0),
	},
	Category.UNKNOWN: {
		"id": "unknown", "priority": 12, "max_distance": 40.0,
		"undiscovered": true, "fog_visible": true, "edge_clamp": false,
		"shape": "circle", "size": 3.0, "color": Color(0.52, 0.52, 0.55, 1.0),
	},
	Category.BUILDING: {
		"id": "building", "priority": 8, "max_distance": 80.0,
		"undiscovered": false, "fog_visible": true, "edge_clamp": false,
		"shape": "square", "size": 3.0, "color": Color(0.55, 0.48, 0.38, 0.95),
	},
	Category.TRAIL: {
		"id": "trail", "priority": 13, "max_distance": 9999.0,
		"undiscovered": false, "fog_visible": true, "edge_clamp": false,
		"shape": "dot", "size": 2.0, "color": Color(0.42, 0.38, 0.32, 0.75),
	},
}

const GROUP_TO_CATEGORY := {
	"quest_destination": Category.MAIN_QUEST,
	"map_side_quest": Category.SIDE_QUEST,
	"waystone": Category.FAST_TRAVEL,
	"map_camp": Category.CAMP,
	"map_merchant": Category.MERCHANT,
	"map_town": Category.TOWN,
	"dungeon_entrance": Category.DUNGEON,
	"map_cave": Category.CAVE,
	"map_interior": Category.INTERIOR,
	"npc": Category.FRIENDLY_NPC,
	"enemy": Category.ENEMY,
	"boss": Category.BOSS,
	"lockable_enemy": Category.ELITE_ENEMY,
	"map_loot": Category.LOOT,
	"interactable": Category.INTERACTABLE,
}


static func get_def(category: Category) -> Dictionary:
	return DEFS.get(category, DEFS[Category.UNKNOWN])


static func category_from_group(group: String) -> Category:
	return GROUP_TO_CATEGORY.get(group, Category.UNKNOWN)


static func category_color(category: Category) -> Color:
	var def: Dictionary = get_def(category)
	return def.get("color", UiColors.TEXT_SECONDARY) as Color
