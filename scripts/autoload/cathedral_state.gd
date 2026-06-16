extends Node
## Persists Blightspire Cathedral dungeon state.

var puzzle_completed: bool = false
var checkpoint_activated: bool = false
var boss_defeated_persistent: bool = false
var opened_chests: Array[String] = []
var discovered_rooms: Array[int] = []
var dungeon_seed: int = 0
var brazier_a: bool = false
var brazier_b: bool = false
var brazier_c: bool = false
var retracted_roots: bool = false


func reset_for_new_game() -> void:
	puzzle_completed = false
	checkpoint_activated = false
	boss_defeated_persistent = false
	opened_chests.clear()
	discovered_rooms.clear()
	dungeon_seed = 0
	brazier_a = false
	brazier_b = false
	brazier_c = false
	retracted_roots = false


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
		"brazier_a": brazier_a,
		"brazier_b": brazier_b,
		"brazier_c": brazier_c,
		"retracted_roots": retracted_roots,
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
	brazier_a = bool(data.get("brazier_a", false))
	brazier_b = bool(data.get("brazier_b", false))
	brazier_c = bool(data.get("brazier_c", false))
	retracted_roots = bool(data.get("retracted_roots", false))
