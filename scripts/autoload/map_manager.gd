extends Node
## Fog-of-war map and region discovery.

const _TownLayouts = preload("res://scripts/levels/town_layouts.gd")
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
		"kind": "camp", "radius": 16.0,
		"scatter_trees": 6, "scatter_rocks": 4, "scatter_grass": 20, "scatter_bushes": 8,
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
const CELL_SIZE: float = 8.0


func reset_for_new_game() -> void:
	regions = {
		"hearthhold_camp": RegionState.DISCOVERED,
		"darkpine_forest": RegionState.DISCOVERED,
		"ruined_watchtower": RegionState.UNDISCOVERED,
		"bandit_camp": RegionState.UNDISCOVERED,
		"crystal_cave": RegionState.UNDISCOVERED,
		"hollow_grove_shrine": RegionState.UNDISCOVERED,
		"procedural_dungeon": RegionState.UNDISCOVERED,
	}
	icons.clear()
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


func _mesh_is_building(mesh_name: String) -> bool:
	for hint in _BUILDING_HINTS:
		if hint in mesh_name:
			return true
	return false


func get_region_radius(region_id: String) -> float:
	return float(get_region_layout(region_id).get("radius", 28.0))


func serialize() -> Dictionary:
	return {
		"regions": regions.duplicate(),
		"icons": icons.duplicate(true),
		"explored_cells": explored_cells.duplicate(true),
	}


func deserialize(data: Dictionary) -> void:
	if data.has("regions"):
		regions = data.regions
	if data.has("icons"):
		icons = data.icons
	if data.has("explored_cells"):
		explored_cells = data.explored_cells
