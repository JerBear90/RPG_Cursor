class_name CryptGenerator
extends RefCounted
## Generates Paleheart Crypt room graph (9–13 rooms).

const _Room := preload("res://scripts/dungeons/crypt_room.gd")

const CELL_SIZE := 2.0
const ROOM_CELLS := Vector2i(10, 10)
const PASSAGE_CELLS := 3
const SMALL_CELLS := Vector2i(8, 8)


static func generate(seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var rooms: Array = []
	var grid_x := 0
	var index := 0

	rooms.append(_room(_Room.RoomType.ENTRANCE, grid_x, index, "Crypt Entrance"))
	index += 1
	grid_x += ROOM_CELLS.x
	rooms.append(_passage(grid_x, index))
	index += 1
	grid_x += PASSAGE_CELLS

	var burial := _room(_Room.RoomType.BURIAL_HALL, grid_x, index, "Burial Hall")
	burial.enemy_count = rng.randi_range(1, 2)
	rooms.append(burial)
	index += 1
	grid_x += ROOM_CELLS.x
	rooms.append(_passage(grid_x, index))
	index += 1
	grid_x += PASSAGE_CELLS

	var checkpoint := _room(_Room.RoomType.CHECKPOINT, grid_x, index, "Sanctum Rest")
	rooms.append(checkpoint)
	index += 1
	grid_x += ROOM_CELLS.x
	rooms.append(_passage(grid_x, index))
	index += 1
	grid_x += PASSAGE_CELLS

	var puzzle := _room(_Room.RoomType.PUZZLE, grid_x, index, "Burial Seal Chamber")
	rooms.append(puzzle)
	index += 1
	grid_x += ROOM_CELLS.x

	if rng.randf() > 0.35:
		var resource := _room(_Room.RoomType.RESOURCE, grid_x - ROOM_CELLS.x, index, "Relic Vault")
		resource.grid_origin = Vector2i(puzzle.grid_origin.x, ROOM_CELLS.y + PASSAGE_CELLS)
		resource.size_cells = SMALL_CELLS
		resource.room_index = index
		rooms.append(resource)
		index += 1

	rooms.append(_passage(grid_x, index))
	index += 1
	grid_x += PASSAGE_CELLS

	var hazard_type := _Room.RoomType.BLACK_ICE if rng.randf() > 0.3 else _Room.RoomType.COLLAPSED
	var hazard := _room(hazard_type, grid_x, index, "Black Ice Vault" if hazard_type == _Room.RoomType.BLACK_ICE else "Collapsed Crypt")
	if hazard_type == _Room.RoomType.COLLAPSED:
		hazard.enemy_count = rng.randi_range(1, 2)
	rooms.append(hazard)
	index += 1
	grid_x += ROOM_CELLS.x

	if rng.randf() > 0.4:
		rooms.append(_passage(grid_x, index))
		index += 1
		grid_x += PASSAGE_CELLS
		var elite := _room(_Room.RoomType.ELITE, grid_x, index, "Elite Tomb")
		elite.enemy_count = 1
		rooms.append(elite)
		index += 1
		grid_x += ROOM_CELLS.x

	rooms.append(_passage(grid_x, index))
	index += 1
	grid_x += PASSAGE_CELLS

	var approach := _room(_Room.RoomType.BOSS_APPROACH, grid_x, index, "Throne Antechamber")
	rooms.append(approach)
	index += 1
	grid_x += ROOM_CELLS.x
	rooms.append(_passage(grid_x, index))
	index += 1
	grid_x += PASSAGE_CELLS

	var boss := _room(_Room.RoomType.BOSS, grid_x, index, "Hollow King's Throne")
	boss.enemy_count = 1
	rooms.append(boss)

	return {
		"seed": seed_value,
		"dungeon_id": "paleheart_crypt",
		"rooms": rooms,
		"name": "Paleheart Crypt",
		"cell_size": CELL_SIZE,
	}


static func _room(type: int, grid_x: int, index: int, category: String) -> Resource:
	var room = _Room.new()
	room.room_type = type
	room.room_category = category
	room.grid_origin = Vector2i(grid_x, 0)
	room.size_cells = ROOM_CELLS if type != _Room.RoomType.RESOURCE else SMALL_CELLS
	room.room_index = index
	return room


static func _passage(grid_x: int, index: int) -> Resource:
	var room = _Room.new()
	room.room_type = _Room.RoomType.PASSAGE
	room.room_category = "Catacomb Passage"
	room.grid_origin = Vector2i(grid_x, 0)
	room.size_cells = Vector2i(PASSAGE_CELLS, ROOM_CELLS.y)
	room.room_index = index
	return room
