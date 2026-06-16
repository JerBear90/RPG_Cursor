class_name EclipseGenerator
extends RefCounted
## Generates Eclipse Sanctum room graph with shadow-themed critical path.

const _Room := preload("res://scripts/dungeons/eclipse_sanctum_room.gd")

const CELL_SIZE := 2.0
const ROOM_CELLS := Vector2i(10, 10)
const PASSAGE_CELLS := 3
const SMALL_CELLS := Vector2i(8, 8)
const SIDE_ROW := ROOM_CELLS.y + PASSAGE_CELLS


static func generate(seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var rooms: Array = []
	var grid_x := 0
	var index := 0

	rooms.append(_room(_Room.RoomType.ENTRANCE, grid_x, index, "Sanctum Entrance"))
	index += 1
	grid_x += ROOM_CELLS.x
	rooms.append(_passage(grid_x, index))
	index += 1
	grid_x += PASSAGE_CELLS

	var nave := _room(_Room.RoomType.SHADOW_NAVE, grid_x, index, "Shadow Nave")
	nave.enemy_count = rng.randi_range(1, 2)
	rooms.append(nave)
	index += 1
	grid_x += ROOM_CELLS.x
	rooms.append(_passage(grid_x, index))
	index += 1
	grid_x += PASSAGE_CELLS

	var cloister := _room(_Room.RoomType.MOON_CLOISTER, grid_x, index, "Moon Cloister")
	cloister.enemy_count = rng.randi_range(1, 2)
	rooms.append(cloister)
	index += 1

	var ward := _room(_Room.RoomType.WARD_CHAMBER, grid_x, index, "Ward Chamber")
	ward.grid_origin = Vector2i(grid_x, SIDE_ROW)
	ward.size_cells = SMALL_CELLS
	ward.room_index = index
	rooms.append(ward)
	index += 1

	grid_x += ROOM_CELLS.x
	rooms.append(_passage(grid_x, index))
	index += 1
	grid_x += PASSAGE_CELLS

	var checkpoint := _room(_Room.RoomType.CHECKPOINT, grid_x, index, "Ward Checkpoint")
	rooms.append(checkpoint)
	index += 1

	var archive := _room(_Room.RoomType.BURIED_ARCHIVE, grid_x, index, "Buried Archive")
	archive.grid_origin = Vector2i(grid_x, SIDE_ROW)
	archive.size_cells = SMALL_CELLS
	archive.enemy_count = rng.randi_range(1, 2)
	archive.room_index = index
	rooms.append(archive)
	index += 1

	grid_x += ROOM_CELLS.x
	rooms.append(_passage(grid_x, index))
	index += 1
	grid_x += PASSAGE_CELLS

	var maze := _room(_Room.RoomType.DREAD_MAZE, grid_x, index, "Dread Maze")
	maze.enemy_count = rng.randi_range(2, 3)
	rooms.append(maze)
	index += 1
	grid_x += ROOM_CELLS.x
	rooms.append(_passage(grid_x, index))
	index += 1
	grid_x += PASSAGE_CELLS

	var observatory := _room(_Room.RoomType.OBSERVATORY_HALL, grid_x, index, "Observatory Hall")
	observatory.enemy_count = rng.randi_range(1, 2)
	rooms.append(observatory)
	index += 1

	var vault := _room(_Room.RoomType.RESOURCE_VAULT, grid_x, index, "Resource Vault")
	vault.grid_origin = Vector2i(grid_x, SIDE_ROW)
	vault.size_cells = SMALL_CELLS
	vault.room_index = index
	rooms.append(vault)
	index += 1

	grid_x += ROOM_CELLS.x
	rooms.append(_passage(grid_x, index))
	index += 1
	grid_x += PASSAGE_CELLS

	var spire := _room(_Room.RoomType.CENTRAL_SPIRE, grid_x, index, "Central Spire")
	spire.enemy_count = rng.randi_range(2, 3)
	rooms.append(spire)
	index += 1

	var elite := _room(_Room.RoomType.ELITE_SHADOW_CHAPEL, grid_x, index, "Elite Shadow Chapel")
	elite.grid_origin = Vector2i(grid_x, SIDE_ROW)
	elite.size_cells = SMALL_CELLS
	elite.enemy_count = 2
	elite.room_index = index
	rooms.append(elite)
	index += 1

	grid_x += ROOM_CELLS.x
	rooms.append(_passage(grid_x, index))
	index += 1
	grid_x += PASSAGE_CELLS

	var ascent := _room(_Room.RoomType.ASCENT_APPROACH, grid_x, index, "Ascent Approach")
	ascent.enemy_count = rng.randi_range(1, 2)
	rooms.append(ascent)
	index += 1
	grid_x += ROOM_CELLS.x
	rooms.append(_passage(grid_x, index))
	index += 1
	grid_x += PASSAGE_CELLS

	var antechamber := _room(_Room.RoomType.ECLIPSE_ANTECHAMBER, grid_x, index, "Eclipse Antechamber")
	antechamber.enemy_count = rng.randi_range(1, 2)
	rooms.append(antechamber)
	index += 1
	grid_x += ROOM_CELLS.x
	rooms.append(_passage(grid_x, index))
	index += 1
	grid_x += PASSAGE_CELLS

	var throne := _room(_Room.RoomType.SEALED_THRONE_CHAMBER, grid_x, index, "Sealed Eclipse Throne")
	throne.enemy_count = 0
	rooms.append(throne)
	index += 1
	grid_x += ROOM_CELLS.x
	rooms.append(_passage(grid_x, index))
	index += 1
	grid_x += PASSAGE_CELLS

	var exit_room := _room(_Room.RoomType.EXIT_TERRACE, grid_x, index, "Exit Terrace")
	rooms.append(exit_room)

	return {
		"seed": seed_value,
		"dungeon_id": "eclipse_sanctum",
		"rooms": rooms,
		"name": "Eclipse Sanctum",
		"cell_size": CELL_SIZE,
	}


static func _room(type: int, grid_x: int, index: int, category: String) -> Resource:
	var room = _Room.new()
	room.room_type = type
	room.room_category = category
	room.grid_origin = Vector2i(grid_x, 0)
	room.size_cells = ROOM_CELLS
	room.room_index = index
	return room


static func _passage(grid_x: int, index: int) -> Resource:
	var room = _Room.new()
	room.room_type = _Room.RoomType.PASSAGE
	room.room_category = "Shadow Passage"
	room.grid_origin = Vector2i(grid_x, 0)
	room.size_cells = Vector2i(PASSAGE_CELLS, ROOM_CELLS.y)
	room.room_index = index
	return room
