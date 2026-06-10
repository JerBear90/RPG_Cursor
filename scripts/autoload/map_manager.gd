extends Node
## Fog-of-war map and region discovery.

signal map_updated(region_id: String)

enum RegionState { UNDISCOVERED, DISCOVERED, EXPLORED, CLEARED, DANGEROUS }

var regions: Dictionary = {}
var icons: Array[Dictionary] = []
var player_positions: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]


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


func add_icon(icon_type: String, position: Vector2, label: String = "") -> void:
	icons.append({"type": icon_type, "position": position, "label": label})
	map_updated.emit(GameManager.current_region_id)


func update_player_position(index: int, world_pos: Vector3) -> void:
	while player_positions.size() <= index:
		player_positions.append(Vector2.ZERO)
	player_positions[index] = Vector2(world_pos.x, world_pos.z)


func get_region_state(region_id: String) -> RegionState:
	return regions.get(region_id, RegionState.UNDISCOVERED)


func serialize() -> Dictionary:
	return {"regions": regions.duplicate(), "icons": icons.duplicate(true)}


func deserialize(data: Dictionary) -> void:
	if data.has("regions"):
		regions = data.regions
	if data.has("icons"):
		icons = data.icons
