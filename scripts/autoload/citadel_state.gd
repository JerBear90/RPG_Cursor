extends Node
## Persists Drowned Citadel dungeon state.

var puzzle_completed: bool = false
var checkpoint_activated: bool = false
var boss_defeated_persistent: bool = false
var opened_chests: Array[String] = []
var discovered_rooms: Array[int] = []
var dungeon_seed: int = 0
var conduit_a: bool = false
var conduit_b: bool = false
var conduit_c: bool = false


func reset_for_new_game() -> void:
	puzzle_completed = false
	checkpoint_activated = false
	boss_defeated_persistent = false
	opened_chests.clear()
	discovered_rooms.clear()
	dungeon_seed = 0
	conduit_a = false
	conduit_b = false
	conduit_c = false


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
		"conduit_a": conduit_a,
		"conduit_b": conduit_b,
		"conduit_c": conduit_c,
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
	conduit_a = bool(data.get("conduit_a", false))
	conduit_b = bool(data.get("conduit_b", false))
	conduit_c = bool(data.get("conduit_c", false))
