extends Node
## Persists Pyreheart Ziggurat dungeon state.

var puzzle_completed: bool = false
var checkpoint_activated: bool = false
var boss_defeated_persistent: bool = false
var opened_chests: Array[String] = []
var discovered_rooms: Array[int] = []
var dungeon_seed: int = 0
var mirror_a: bool = false
var mirror_b: bool = false
var mirror_c: bool = false
var cooling_channels_active: bool = false


func reset_for_new_game() -> void:
	puzzle_completed = false
	checkpoint_activated = false
	boss_defeated_persistent = false
	opened_chests.clear()
	discovered_rooms.clear()
	dungeon_seed = 0
	mirror_a = false
	mirror_b = false
	mirror_c = false
	cooling_channels_active = false


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
		"mirror_a": mirror_a,
		"mirror_b": mirror_b,
		"mirror_c": mirror_c,
		"cooling_channels_active": cooling_channels_active,
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
	mirror_a = bool(data.get("mirror_a", false))
	mirror_b = bool(data.get("mirror_b", false))
	mirror_c = bool(data.get("mirror_c", false))
	cooling_channels_active = bool(data.get("cooling_channels_active", false))
