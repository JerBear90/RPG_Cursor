class_name DungeonGenerator
extends RefCounted
## Builds a linear room graph for procedural dungeons.

const _RoomData := preload("res://scripts/dungeons/dungeon_room.gd")

const CELL_SIZE := 2.0
const ROOM_CELLS := Vector2i(10, 10)
const CORRIDOR_CELLS := 3

const NAME_PARTS: Array[String] = [
	"Sunken", "Ruined", "Forgotten", "Ash", "Hollow", "Grim", "Lost", "Cursed",
]
const NAME_SUFFIXES: Array[String] = [
	"Catacombs", "Vault", "Warrens", "Depths", "Hollows", "Crypt", "Grotto",
]


static func generate(seed_value: int, tier: int = 1) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var combat_count := rng.randi_range(2, 4)
	var rooms: Array = []
	var grid_x := 0
	var index := 0

	rooms.append(_make_room(_RoomData.RoomType.SPAWN, Vector2i(grid_x, 0), index))
	index += 1
	grid_x += ROOM_CELLS.x

	for _i in combat_count:
		rooms.append(_make_corridor(Vector2i(grid_x, 0), index))
		index += 1
		grid_x += CORRIDOR_CELLS
		var combat = _make_room(_RoomData.RoomType.COMBAT, Vector2i(grid_x, 0), index)
		combat.enemy_count = rng.randi_range(1, 3)
		rooms.append(combat)
		index += 1
		grid_x += ROOM_CELLS.x

	if rng.randf() > 0.35:
		rooms.append(_make_corridor(Vector2i(grid_x, 0), index))
		index += 1
		grid_x += CORRIDOR_CELLS
		rooms.append(_make_room(_RoomData.RoomType.TREASURE, Vector2i(grid_x, 0), index))
		index += 1
		grid_x += ROOM_CELLS.x

	rooms.append(_make_corridor(Vector2i(grid_x, 0), index))
	index += 1
	grid_x += CORRIDOR_CELLS
	var boss = _make_room(_RoomData.RoomType.BOSS, Vector2i(grid_x, 0), index)
	boss.enemy_count = 1
	rooms.append(boss)

	return {
		"seed": seed_value,
		"tier": tier,
		"rooms": rooms,
		"name": _pick_name(rng),
		"cell_size": CELL_SIZE,
	}


static func _make_room(type: int, grid_origin: Vector2i, index: int):
	var room = _RoomData.new()
	room.room_type = type
	room.grid_origin = grid_origin
	room.size_cells = ROOM_CELLS
	room.room_index = index
	return room


static func _make_corridor(grid_origin: Vector2i, index: int):
	var room = _RoomData.new()
	room.room_type = _RoomData.RoomType.CORRIDOR
	room.grid_origin = grid_origin
	room.size_cells = Vector2i(CORRIDOR_CELLS, ROOM_CELLS.y)
	room.room_index = index
	return room


static func _pick_name(rng: RandomNumberGenerator) -> String:
	return "%s %s" % [
		NAME_PARTS[rng.randi() % NAME_PARTS.size()],
		NAME_SUFFIXES[rng.randi() % NAME_SUFFIXES.size()],
	]
