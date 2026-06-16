class_name CitadelGenerator
extends RefCounted
## Generates Drowned Citadel room graph (12–14 rooms).

const _Room := preload("res://scripts/dungeons/citadel_room.gd")

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

	rooms.append(_room(_Room.RoomType.ENTRANCE, grid_x, index, "Citadel Entrance"))
	index += 1
	grid_x += ROOM_CELLS.x
	rooms.append(_passage(grid_x, index))
	index += 1
	grid_x += PASSAGE_CELLS

	var gallery := _room(_Room.RoomType.FLOODED_GALLERY, grid_x, index, "Flooded Gallery")
	gallery.enemy_count = rng.randi_range(1, 2)
	rooms.append(gallery)
	index += 1
	grid_x += ROOM_CELLS.x
	rooms.append(_passage(grid_x, index))
	index += 1
	grid_x += PASSAGE_CELLS

	var sea_hall := _room(_Room.RoomType.BROKEN_SEA_HALL, grid_x, index, "Broken Sea Hall")
	sea_hall.enemy_count = rng.randi_range(1, 2)
	rooms.append(sea_hall)
	index += 1
	grid_x += ROOM_CELLS.x
	rooms.append(_passage(grid_x, index))
	index += 1
	grid_x += PASSAGE_CELLS

	var checkpoint := _room(_Room.RoomType.CHECKPOINT, grid_x, index, "Checkpoint Sanctuary")
	rooms.append(checkpoint)
	index += 1
	grid_x += ROOM_CELLS.x
	rooms.append(_passage(grid_x, index))
	index += 1
	grid_x += PASSAGE_CELLS

	var puzzle := _room(_Room.RoomType.PUZZLE, grid_x, index, "Storm Conduit Chamber")
	rooms.append(puzzle)
	index += 1

	var vault := _room(_Room.RoomType.RESOURCE, grid_x - ROOM_CELLS.x, index, "Resource Vault")
	vault.grid_origin = Vector2i(puzzle.grid_origin.x, ROOM_CELLS.y + PASSAGE_CELLS)
	vault.size_cells = SMALL_CELLS
	vault.room_index = index
	rooms.append(vault)
	index += 1

	var treasure := _room(_Room.RoomType.TREASURE_HOLD, grid_x - ROOM_CELLS.x, index, "Treasure Hold")
	treasure.grid_origin = Vector2i(puzzle.grid_origin.x + SMALL_CELLS.x + 2, ROOM_CELLS.y + PASSAGE_CELLS)
	treasure.size_cells = SMALL_CELLS
	treasure.room_index = index
	rooms.append(treasure)
	index += 1

	grid_x += ROOM_CELLS.x
	rooms.append(_passage(grid_x, index))
	index += 1
	grid_x += PASSAGE_CELLS

	var barracks := _room(_Room.RoomType.DROWNED_BARRACKS, grid_x, index, "Drowned Barracks")
	barracks.enemy_count = rng.randi_range(2, 3)
	rooms.append(barracks)
	index += 1
	grid_x += ROOM_CELLS.x
	rooms.append(_passage(grid_x, index))
	index += 1
	grid_x += PASSAGE_CELLS

	var tidal := _room(_Room.RoomType.TIDAL_TRAP, grid_x, index, "Tidal Trap Corridor")
	tidal.enemy_count = 1
	rooms.append(tidal)
	index += 1
	grid_x += ROOM_CELLS.x
	rooms.append(_passage(grid_x, index))
	index += 1
	grid_x += PASSAGE_CELLS

	var elite := _room(_Room.RoomType.ELITE, grid_x, index, "Elite Guardian Hall")
	elite.enemy_count = 2
	rooms.append(elite)
	index += 1
	grid_x += ROOM_CELLS.x
	rooms.append(_passage(grid_x, index))
	index += 1
	grid_x += PASSAGE_CELLS

	var approach := _room(_Room.RoomType.BOSS_APPROACH, grid_x, index, "Throne Approach")
	approach.enemy_count = rng.randi_range(1, 2)
	rooms.append(approach)
	index += 1
	grid_x += ROOM_CELLS.x
	rooms.append(_passage(grid_x, index))
	index += 1
	grid_x += PASSAGE_CELLS

	var boss := _room(_Room.RoomType.BOSS, grid_x, index, "Tidebound Throne")
	boss.enemy_count = 0
	rooms.append(boss)
	index += 1
	grid_x += ROOM_CELLS.x
	rooms.append(_passage(grid_x, index))
	index += 1
	grid_x += PASSAGE_CELLS

	var exit_room := _room(_Room.RoomType.EXIT, grid_x, index, "Exit Harbor")
	rooms.append(exit_room)

	return {
		"seed": seed_value,
		"dungeon_id": "drowned_citadel",
		"rooms": rooms,
		"name": "Drowned Citadel",
		"cell_size": CELL_SIZE,
	}


static func _room(type: int, grid_x: int, index: int, category: String) -> Resource:
	var room = _Room.new()
	room.room_type = type
	room.room_category = category
	room.grid_origin = Vector2i(grid_x, 0)
	room.size_cells = ROOM_CELLS if type not in [_Room.RoomType.RESOURCE, _Room.RoomType.TREASURE_HOLD] else SMALL_CELLS
	room.room_index = index
	return room


static func _passage(grid_x: int, index: int) -> Resource:
	var room = _Room.new()
	room.room_type = _Room.RoomType.PASSAGE
	room.room_category = "Flooded Passage"
	room.grid_origin = Vector2i(grid_x, 0)
	room.size_cells = Vector2i(PASSAGE_CELLS, ROOM_CELLS.y)
	room.room_index = index
	return room
