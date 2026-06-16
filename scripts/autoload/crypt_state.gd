extends Node
## Persists Paleheart Crypt dungeon state.

var puzzle_completed: bool = false
var checkpoint_activated: bool = false
var boss_defeated_persistent: bool = false
var opened_chests: Array[String] = []
var discovered_rooms: Array[int] = []
var dungeon_seed: int = 0
var seal_north: bool = false
var seal_south: bool = false
var seal_east: bool = false
var seal_west: bool = false


func reset_for_new_game() -> void:
	puzzle_completed = false
	checkpoint_activated = false
	boss_defeated_persistent = false
	opened_chests.clear()
	discovered_rooms.clear()
	dungeon_seed = 0
	seal_north = false
	seal_south = false
	seal_east = false
	seal_west = false


func discover_room(index: int) -> void:
	if index in discovered_rooms:
		return
	discovered_rooms.append(index)
	MapManager.map_updated.emit(GameManager.current_region_id)


func save_state() -> void:
	pass


func serialize() -> Dictionary:
	return {
		"puzzle_completed": puzzle_completed,
		"checkpoint_activated": checkpoint_activated,
		"boss_defeated": boss_defeated_persistent,
		"opened_chests": opened_chests.duplicate(),
		"discovered_rooms": discovered_rooms.duplicate(),
		"dungeon_seed": dungeon_seed,
		"seal_north": seal_north,
		"seal_south": seal_south,
		"seal_east": seal_east,
		"seal_west": seal_west,
	}


func deserialize(data: Dictionary) -> void:
	puzzle_completed = bool(data.get("puzzle_completed", false))
	checkpoint_activated = bool(data.get("checkpoint_activated", false))
	boss_defeated_persistent = bool(data.get("boss_defeated", false))
	opened_chests = []
	for item in data.get("opened_chests", []):
		opened_chests.append(str(item))
	discovered_rooms = []
	for item in data.get("discovered_rooms", []):
		discovered_rooms.append(int(item))
	dungeon_seed = int(data.get("dungeon_seed", 0))
	seal_north = bool(data.get("seal_north", false))
	seal_south = bool(data.get("seal_south", false))
	seal_east = bool(data.get("seal_east", false))
	seal_west = bool(data.get("seal_west", false))
