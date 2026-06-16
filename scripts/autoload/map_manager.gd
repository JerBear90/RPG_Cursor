extends Node
## Fog-of-war map and region discovery.

const _TownLayouts = preload("res://scripts/levels/town_layouts.gd")
const _MinimapSettings = preload("res://ui/map/minimap_settings.gd")
const _ReliquaryRoom = preload("res://scripts/dungeons/reliquary_room.gd")
const _FoundryRoom = preload("res://scripts/dungeons/foundry_room.gd")
const _CryptRoom = preload("res://scripts/dungeons/crypt_room.gd")
const _CitadelRoom = preload("res://scripts/dungeons/citadel_room.gd")
const _CathedralRoom = preload("res://scripts/dungeons/cathedral_room.gd")
const _PyreheartRoom = preload("res://scripts/dungeons/pyreheart_room.gd")
const _EclipseRoom = preload("res://scripts/dungeons/eclipse_sanctum_room.gd")
const _BUILDING_HINTS := ["tent", "platform", "statue", "fence_gate", "campfire"]
signal map_updated(region_id: String)

enum RegionState { UNDISCOVERED, DISCOVERED, EXPLORED, CLEARED, DANGEROUS }

var regions: Dictionary = {}
var region_layout: Dictionary = {
	"darkpine_forest": {
		"kind": "island", "radius": 28.0, "water_extent": 52.0,
		"scatter_trees": 32, "scatter_rocks": 20, "scatter_grass": 60, "scatter_bushes": 18,
	},
	"hearthhold_camp": {
		"kind": "camp", "radius": 18.0,
		"scatter_trees": 4, "scatter_rocks": 6, "scatter_grass": 16, "scatter_bushes": 6,
	},
		"rotfen_marsh": {
		"kind": "swamp", "radius": 34.0, "water_extent": 48.0,
		"land_tile": "ground_pathRocks.glb",
		"scatter_trees": 18, "scatter_rocks": 14, "scatter_grass": 24, "scatter_bushes": 16,
		"tree_pool": ["tree_simple_dark.glb", "tree_tall_dark.glb", "tree_detailed.glb", "stump_oldTall.glb"],
		"bush_pool": ["mushroom_red.glb", "mushroom_tan.glb", "plant_bushDetailed.glb", "hanging_moss.glb"],
	},
	"ashfall_highlands": {
		"kind": "volcanic", "radius": 38.0, "water_extent": 0.0,
		"land_tile": "ground_pathRocks.glb",
		"scatter_trees": 8, "scatter_rocks": 28, "scatter_grass": 10, "scatter_bushes": 6,
		"tree_pool": ["stump_oldTall.glb", "stump_old.glb", "tree_simple_dark.glb", "tree_tall_dark.glb"],
		"rock_pool": ["rock_largeA.glb", "rock_largeB.glb", "rock_tallA.glb", "cliff_block_rock.glb", "stone_largeA.glb"],
	},
	"frostgrave_expanse": {
		"kind": "frozen", "radius": 40.0, "water_extent": 0.0,
		"land_tile": "ground_pathStraight.glb",
		"scatter_trees": 10, "scatter_rocks": 22, "scatter_grass": 6, "scatter_bushes": 4,
		"tree_pool": ["tree_simple_dark.glb", "tree_tall_dark.glb", "stump_oldTall.glb", "stump_old.glb"],
		"rock_pool": ["rock_largeA.glb", "rock_largeB.glb", "cliff_block_stone.glb", "cliff_block_rock.glb", "stone_largeA.glb"],
	},
	"shattered_coast": {
		"kind": "coastal", "radius": 42.0, "water_extent": 52.0,
		"land_tile": "ground_pathRocks.glb",
		"scatter_trees": 6, "scatter_rocks": 26, "scatter_grass": 8, "scatter_bushes": 6,
		"tree_pool": ["stump_oldTall.glb", "stump_old.glb"],
		"rock_pool": ["rock_largeA.glb", "rock_largeB.glb", "cliff_block_rock.glb", "cliff_block_stone.glb", "stone_largeA.glb"],
	},
	"blightreach": {
		"kind": "blighted", "radius": 42.0, "water_extent": 0.0,
		"land_tile": "ground_pathRocks.glb",
		"scatter_trees": 18, "scatter_rocks": 14, "scatter_grass": 22, "scatter_bushes": 16,
		"tree_pool": ["tree_simple_dark.glb", "tree_tall_dark.glb", "stump_oldTall.glb", "stump_old.glb"],
		"rock_pool": ["cliff_block_stone.glb", "statue_columnDamaged.glb", "rock_largeA.glb"],
		"bush_pool": ["mushroom_red.glb", "mushroom_tan.glb", "plant_bushLarge.glb", "plant_bushDetailed.glb"],
	},
	"ember_wastes": {
		"kind": "desert", "radius": 44.0, "water_extent": 0.0,
		"land_tile": "ground_pathRocks.glb",
		"scatter_trees": 6, "scatter_rocks": 22, "scatter_grass": 0, "scatter_bushes": 4,
		"tree_pool": ["stump_oldTall.glb", "stump_old.glb", "tree_simple_dark.glb"],
		"rock_pool": ["rock_largeA.glb", "rock_largeB.glb", "rock_tallA.glb", "statue_columnDamaged.glb", "statue_obelisk.glb"],
		"bush_pool": ["plant_bushSmall.glb"],
	},
	"sunless_dominion": {
		"kind": "desert", "radius": 44.0, "water_extent": 0.0,
		"land_tile": "ground_pathRocks.glb",
		"scatter_trees": 4, "scatter_rocks": 24, "scatter_grass": 0, "scatter_bushes": 2,
		"tree_pool": ["stump_oldTall.glb", "tree_simple_dark.glb"],
		"rock_pool": ["rock_largeA.glb", "rock_largeB.glb", "statue_columnDamaged.glb", "statue_block.glb"],
		"bush_pool": ["plant_bushSmall.glb"],
	},
	"blightspire_cathedral": {
		"kind": "dungeon", "radius": 160.0, "water_extent": 0.0,
	},
	"pyreheart_ziggurat": {
		"kind": "dungeon", "radius": 160.0, "water_extent": 0.0,
	},
	"eclipse_sanctum": {
		"kind": "dungeon", "radius": 160.0, "water_extent": 0.0,
	},
	"drowned_citadel": {
		"kind": "dungeon", "radius": 140.0, "water_extent": 0.0,
	},
	"sunken_reliquary": {
		"kind": "dungeon", "radius": 120.0, "water_extent": 0.0,
	},
	"blackvein_foundry": {
		"kind": "dungeon", "radius": 140.0, "water_extent": 0.0,
	},
	"paleheart_crypt": {
		"kind": "dungeon", "radius": 140.0, "water_extent": 0.0,
	},
	"ruined_watchtower": {
		"kind": "island", "radius": 18.0, "water_extent": 30.0,
		"scatter_trees": 10, "scatter_rocks": 12, "scatter_grass": 35, "scatter_bushes": 8,
		"tree_pool": ["tree_pineDefaultA.glb", "tree_pineTallA.glb", "tree_simple.glb", "tree_tall.glb"],
	},
	"bandit_camp": {
		"kind": "island", "radius": 20.0, "water_extent": 34.0,
		"scatter_trees": 12, "scatter_rocks": 10, "scatter_grass": 40, "scatter_bushes": 10,
	},
	"crystal_cave": {
		"kind": "island", "radius": 16.0, "water_extent": 0.0,
		"land_tile": "platform_stone.glb",
		"scatter_trees": 2, "scatter_rocks": 22, "scatter_grass": 8, "scatter_bushes": 4,
		"rock_pool": ["rock_largeA.glb", "rock_largeB.glb", "rock_tallA.glb", "stone_largeA.glb", "cliff_block_stone.glb"],
	},
	"hollow_grove_shrine": {
		"kind": "island", "radius": 22.0, "water_extent": 38.0,
		"scatter_trees": 26, "scatter_rocks": 8, "scatter_grass": 45, "scatter_bushes": 20,
		"tree_pool": [
			"tree_oak.glb", "tree_detailed.glb", "tree_tall_dark.glb", "tree_simple_dark.glb",
			"tree_pineRoundA.glb", "tree_pineTallA.glb",
		],
		"bush_pool": ["plant_bushDetailed.glb", "plant_bushLarge.glb", "mushroom_red.glb", "mushroom_tan.glb", "flower_purpleA.glb"],
	},
}
var icons: Array[Dictionary] = []
var player_positions: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
var explored_cells: Dictionary = {}
var discovered_locations: Dictionary = {}
var waypoint: Dictionary = {}
const CELL_SIZE: float = 8.0


func reset_for_new_game() -> void:
	regions = {
		"hearthhold_camp": RegionState.DISCOVERED,
		"darkpine_forest": RegionState.DISCOVERED,
		"ruined_watchtower": RegionState.UNDISCOVERED,
		"bandit_camp": RegionState.UNDISCOVERED,
		"crystal_cave": RegionState.UNDISCOVERED,
		"hollow_grove_shrine": RegionState.UNDISCOVERED,
		"rotfen_marsh": RegionState.UNDISCOVERED,
		"ashfall_highlands": RegionState.UNDISCOVERED,
		"sunken_reliquary": RegionState.UNDISCOVERED,
		"blackvein_foundry": RegionState.UNDISCOVERED,
		"paleheart_crypt": RegionState.UNDISCOVERED,
		"shattered_coast": RegionState.UNDISCOVERED,
		"blightreach": RegionState.UNDISCOVERED,
		"drowned_citadel": RegionState.UNDISCOVERED,
		"blightspire_cathedral": RegionState.UNDISCOVERED,
		"ember_wastes": RegionState.UNDISCOVERED,
		"pyreheart_ziggurat": RegionState.UNDISCOVERED,
		"sunless_dominion": RegionState.UNDISCOVERED,
		"eclipse_sanctum": RegionState.UNDISCOVERED,
		"procedural_dungeon": RegionState.UNDISCOVERED,
	}
	icons.clear()
	discovered_locations.clear()
	waypoint.clear()
	map_updated.emit("darkpine_forest")


func discover_region(region_id: String) -> void:
	if not regions.has(region_id):
		regions[region_id] = RegionState.DISCOVERED
	elif regions[region_id] == RegionState.UNDISCOVERED:
		regions[region_id] = RegionState.DISCOVERED
	map_updated.emit(region_id)


func explore_region(region_id: String) -> void:
	if regions.has(region_id) and regions[region_id] < RegionState.EXPLORED:
		regions[region_id] = RegionState.EXPLORED
		map_updated.emit(region_id)


func clear_region(region_id: String) -> void:
	if regions.has(region_id):
		regions[region_id] = RegionState.CLEARED
		map_updated.emit(region_id)


func mark_region_dangerous(region_id: String) -> void:
	if regions.has(region_id) and regions[region_id] < RegionState.DANGEROUS:
		regions[region_id] = RegionState.DANGEROUS
		map_updated.emit(region_id)


func add_icon(icon_type: String, position: Vector2, label: String = "") -> void:
	icons.append({"type": icon_type, "position": position, "label": label})
	map_updated.emit(GameManager.current_region_id)


func set_waypoint(world_position: Vector3, label: String = "") -> void:
	waypoint = {"position": world_position, "label": label}
	map_updated.emit(GameManager.current_region_id)


func clear_waypoint() -> void:
	if waypoint.is_empty():
		return
	waypoint.clear()
	map_updated.emit(GameManager.current_region_id)


func has_waypoint() -> bool:
	return not waypoint.is_empty()


func get_waypoint_position() -> Vector3:
	return waypoint.get("position", Vector3.ZERO) as Vector3


func get_waypoint_label() -> String:
	return str(waypoint.get("label", ""))


func get_waypoint_distance(from: Vector3) -> float:
	if waypoint.is_empty():
		return -1.0
	return from.distance_to(get_waypoint_position())


func discover_location(
	location_id: String,
	display_name: String,
	world_position: Vector3,
	category: String,
	region_id: String = "",
	fast_travel: bool = false
) -> void:
	if discovered_locations.has(location_id):
		return
	discovered_locations[location_id] = {
		"id": location_id,
		"name": display_name,
		"position": world_position,
		"category": category,
		"region_id": region_id if region_id != "" else GameManager.current_region_id,
		"discovered": true,
		"fast_travel": fast_travel,
	}
	map_updated.emit(GameManager.current_region_id)
	_notify_location_discovered(display_name)


func _notify_location_discovered(display_name: String) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	for hud in tree.get_nodes_in_group("game_hud"):
		if hud.has_method("show_toast"):
			hud.show_toast("Location Discovered", 3.5, display_name, "notification")


func is_location_discovered(location_id: String) -> bool:
	return discovered_locations.has(location_id)


func get_discovered_locations_for_region(region_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for key in discovered_locations.keys():
		var entry: Dictionary = discovered_locations[key]
		if str(entry.get("region_id", "")) == region_id:
			out.append(entry)
	return out


func is_cell_explored(world_pos: Vector3, region_id: String) -> bool:
	var cells: Array = explored_cells.get(region_id, [])
	var cell_key := "%d,%d" % [int(floor(world_pos.x / CELL_SIZE)), int(floor(world_pos.z / CELL_SIZE))]
	return cell_key in cells


func update_player_position(index: int, world_pos: Vector3) -> void:
	while player_positions.size() <= index:
		player_positions.append(Vector2.ZERO)
	player_positions[index] = Vector2(world_pos.x, world_pos.z)
	var region_id := GameManager.current_region_id
	if region_id == "":
		return
	if not explored_cells.has(region_id):
		explored_cells[region_id] = []
	var cell_key := "%d,%d" % [int(floor(world_pos.x / CELL_SIZE)), int(floor(world_pos.z / CELL_SIZE))]
	var cells: Array = explored_cells[region_id]
	if cell_key not in cells:
		cells.append(cell_key)
		explored_cells[region_id] = cells
		explore_region(region_id)
		map_updated.emit(region_id)
	if has_waypoint() and world_pos.distance_to(get_waypoint_position()) <= _MinimapSettings.waypoint_reach_distance:
		clear_waypoint()


func get_region_state(region_id: String) -> RegionState:
	return regions.get(region_id, RegionState.UNDISCOVERED)


func get_region_layout(region_id: String) -> Dictionary:
	return region_layout.get(region_id, {})


func get_map_position_label(world_pos: Vector3) -> String:
	var layout := get_region_layout(GameManager.current_region_id)
	if layout.get("kind") == "island":
		var dist := Vector2(world_pos.x, world_pos.z).length()
		var radius: float = layout.get("radius", 28.0)
		if dist > radius:
			return "Off island (%.0fm)" % dist
		return "On island (%.0f, %.0f)" % [world_pos.x, world_pos.z]
	return "(%.0f, %.0f)" % [world_pos.x, world_pos.z]


func get_fog_grid_lines(region_id: String, grid_radius: int = 4) -> PackedStringArray:
	var lines: PackedStringArray = []
	var cells: Array = explored_cells.get(region_id, [])
	var player_cell := Vector2i.ZERO
	if player_positions.size() > 0:
		var pos := player_positions[0]
		player_cell = Vector2i(int(floor(pos.x / CELL_SIZE)), int(floor(pos.y / CELL_SIZE)))
	for z in range(-grid_radius, grid_radius + 1):
		var row := ""
		for x in range(-grid_radius, grid_radius + 1):
			var key := "%d,%d" % [player_cell.x + x, player_cell.y + z]
			if x == 0 and z == 0:
				row += "@"
			elif key in cells:
				row += "."
			elif regions.get(region_id, RegionState.UNDISCOVERED) == RegionState.UNDISCOVERED:
				row += "#"
			else:
				row += "?"
		lines.append(row)
	return lines


func get_building_markers(region_id: String) -> Array[Vector3]:
	var markers: Array[Vector3] = []
	var layout := _TownLayouts.get_layout(region_id)
	for entry in layout.get("props", []):
		if not entry is Dictionary:
			continue
		var mesh: String = str(entry.get("m", ""))
		if not _mesh_is_building(mesh):
			continue
		var pos: Vector3 = entry.get("p", Vector3.ZERO)
		markers.append(pos)
	return markers


func get_trail_markers(region_id: String) -> Array[Vector3]:
	var markers: Array[Vector3] = []
	var layout := _TownLayouts.get_layout(region_id)
	for entry in layout.get("props", []):
		if not entry is Dictionary:
			continue
		var mesh: String = str(entry.get("m", ""))
		if "ground_path" not in mesh:
			continue
		markers.append(entry.get("p", Vector3.ZERO))
	return markers


func _mesh_is_building(mesh_name: String) -> bool:
	for hint in _BUILDING_HINTS:
		if hint in mesh_name:
			return true
	return false


func get_region_radius(region_id: String) -> float:
	return float(get_region_layout(region_id).get("radius", 28.0))


func get_dungeon_room_markers(region_id: String) -> Array[Dictionary]:
	if region_id not in ["sunken_reliquary", "blackvein_foundry", "paleheart_crypt", "drowned_citadel", "blightspire_cathedral", "pyreheart_ziggurat", "eclipse_sanctum"]:
		return []
	var out: Array[Dictionary] = []
	var layout: Dictionary = DungeonManager.layout
	if layout.is_empty():
		return out
	var cell_size: float = float(layout.get("cell_size", 2.0))
	var discovered: Array = ReliquaryState.discovered_rooms
	if region_id == "blackvein_foundry":
		discovered = FoundryState.discovered_rooms
	elif region_id == "paleheart_crypt":
		discovered = CryptState.discovered_rooms
	elif region_id == "drowned_citadel":
		discovered = CitadelState.discovered_rooms
	elif region_id == "blightspire_cathedral":
		discovered = CathedralState.discovered_rooms
	elif region_id == "pyreheart_ziggurat":
		discovered = PyreheartState.discovered_rooms
	elif region_id == "eclipse_sanctum":
		discovered = EclipseSanctumState.discovered_rooms
	for room in layout.get("rooms", []):
		var room_index := -1
		var center := Vector3.ZERO
		var category := "room"
		var display_name := "Room"
		if room is _ReliquaryRoom:
			room_index = room.room_index
			if room.room_type == _ReliquaryRoom.RoomType.CORRIDOR:
				continue
			center = room.get_world_center(cell_size)
			display_name = room.get_display_name()
			match room.room_type:
				_ReliquaryRoom.RoomType.ENTRANCE: category = "entrance"
				_ReliquaryRoom.RoomType.CHECKPOINT: category = "checkpoint"
				_ReliquaryRoom.RoomType.BOSS: category = "boss"
				_ReliquaryRoom.RoomType.PUZZLE: category = "quest"
		elif room is _FoundryRoom:
			room_index = room.room_index
			if room.room_type == _FoundryRoom.RoomType.CORRIDOR:
				continue
			center = room.get_world_center(cell_size)
			display_name = room.get_display_name()
			match room.room_type:
				_FoundryRoom.RoomType.ENTRANCE: category = "entrance"
				_FoundryRoom.RoomType.CHECKPOINT: category = "checkpoint"
				_FoundryRoom.RoomType.BOSS: category = "boss"
				_FoundryRoom.RoomType.MECHANISM: category = "quest"
		elif room is _CryptRoom:
			room_index = room.room_index
			if room.room_type == _CryptRoom.RoomType.PASSAGE:
				continue
			center = room.get_world_center(cell_size)
			display_name = room.get_display_name()
			match room.room_type:
				_CryptRoom.RoomType.ENTRANCE: category = "entrance"
				_CryptRoom.RoomType.CHECKPOINT: category = "checkpoint"
				_CryptRoom.RoomType.BOSS: category = "boss"
				_CryptRoom.RoomType.PUZZLE: category = "quest"
		elif room is _CitadelRoom:
			room_index = room.room_index
			if room.room_type == _CitadelRoom.RoomType.PASSAGE:
				continue
			center = room.get_world_center(cell_size)
			display_name = room.get_display_name()
			match room.room_type:
				_CitadelRoom.RoomType.ENTRANCE: category = "entrance"
				_CitadelRoom.RoomType.CHECKPOINT: category = "checkpoint"
				_CitadelRoom.RoomType.BOSS: category = "boss"
				_CitadelRoom.RoomType.PUZZLE: category = "quest"
				_CitadelRoom.RoomType.EXIT: category = "exit"
		elif room is _CathedralRoom:
			room_index = room.room_index
			if room.room_type == _CathedralRoom.RoomType.PASSAGE:
				continue
			center = room.get_world_center(cell_size)
			display_name = room.get_display_name()
			match room.room_type:
				_CathedralRoom.RoomType.ENTRANCE: category = "entrance"
				_CathedralRoom.RoomType.CHECKPOINT: category = "checkpoint"
				_CathedralRoom.RoomType.HEART_CHAMBER: category = "boss"
				_CathedralRoom.RoomType.PURIFICATION_CHAMBER: category = "quest"
				_CathedralRoom.RoomType.EXIT_CLOISTER: category = "exit"
		elif room is _PyreheartRoom:
			room_index = room.room_index
			if room.room_type == _PyreheartRoom.RoomType.PASSAGE:
				continue
			center = room.get_world_center(cell_size)
			display_name = room.get_display_name()
			match room.room_type:
				_PyreheartRoom.RoomType.ENTRANCE: category = "entrance"
				_PyreheartRoom.RoomType.CHECKPOINT: category = "checkpoint"
				_PyreheartRoom.RoomType.SEALED_HEART_CHAMBER: category = "boss"
				_PyreheartRoom.RoomType.MIRROR_CHAMBER: category = "quest"
				_PyreheartRoom.RoomType.EXIT_TERRACE: category = "exit"
		elif room is _EclipseRoom:
			room_index = room.room_index
			if room.room_type == _EclipseRoom.RoomType.PASSAGE:
				continue
			center = room.get_world_center(cell_size)
			display_name = room.get_display_name()
			match room.room_type:
				_EclipseRoom.RoomType.ENTRANCE: category = "entrance"
				_EclipseRoom.RoomType.CHECKPOINT: category = "checkpoint"
				_EclipseRoom.RoomType.SEALED_THRONE_CHAMBER: category = "boss"
				_EclipseRoom.RoomType.WARD_CHAMBER: category = "quest"
				_EclipseRoom.RoomType.EXIT_TERRACE: category = "exit"
		else:
			continue
		if room_index not in discovered:
			continue
		out.append({"position": center, "category": category, "name": display_name})
	return out


func serialize() -> Dictionary:
	return {
		"regions": regions.duplicate(),
		"icons": icons.duplicate(true),
		"explored_cells": explored_cells.duplicate(true),
		"discovered_locations": discovered_locations.duplicate(true),
		"waypoint": waypoint.duplicate(true),
	}


func deserialize(data: Dictionary) -> void:
	if data.has("regions"):
		regions = data.regions
	if data.has("icons"):
		icons = data.icons
	if data.has("explored_cells"):
		explored_cells = data.explored_cells
	if data.has("discovered_locations"):
		discovered_locations = data.discovered_locations
	if data.has("waypoint"):
		waypoint = data.waypoint
