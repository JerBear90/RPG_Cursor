class_name CathedralGenerator
extends RefCounted
## Generates Blightspire Cathedral room graph with cathedral-specific critical path.

const _Room := preload("res://scripts/dungeons/cathedral_room.gd")

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

	rooms.append(_room(_Room.RoomType.ENTRANCE, grid_x, index, "Cathedral Entrance"))
	index += 1
	grid_x += ROOM_CELLS.x
	rooms.append(_passage(grid_x, index))
	index += 1
	grid_x += PASSAGE_CELLS

	var nave := _room(_Room.RoomType.ROOTBOUND_NAVE, grid_x, index, "Rootbound Nave")
	nave.enemy_count = rng.randi_range(1, 2)
	rooms.append(nave)
	index += 1
	grid_x += ROOM_CELLS.x
	rooms.append(_passage(grid_x, index))
	index += 1
	grid_x += PASSAGE_CELLS

	var transept := _room(_Room.RoomType.COLLAPSED_TRANSEPT, grid_x, index, "Collapsed Transept")
	transept.enemy_count = rng.randi_range(1, 2)
	rooms.append(transept)
	index += 1

	var cloister := _room(_Room.RoomType.FUNGAL_CLOISTER, grid_x, index, "Fungal Cloister")
	cloister.grid_origin = Vector2i(grid_x, SIDE_ROW)
	cloister.size_cells = SMALL_CELLS
	cloister.enemy_count = rng.randi_range(1, 2)
	cloister.room_index = index
	rooms.append(cloister)
	index += 1

	grid_x += ROOM_CELLS.x
	rooms.append(_passage(grid_x, index))
	index += 1
	grid_x += PASSAGE_CELLS

	var purification := _room(_Room.RoomType.PURIFICATION_CHAMBER, grid_x, index, "Purification Chamber")
	rooms.append(purification)
	index += 1

	var resource := _room(_Room.RoomType.RESOURCE_CRYPT, grid_x, index, "Resource Crypt")
	resource.grid_origin = Vector2i(grid_x, SIDE_ROW)
	resource.size_cells = SMALL_CELLS
	resource.room_index = index
	rooms.append(resource)
	index += 1

	grid_x += ROOM_CELLS.x
	rooms.append(_passage(grid_x, index))
	index += 1
	grid_x += PASSAGE_CELLS

	var checkpoint := _room(_Room.RoomType.CHECKPOINT, grid_x, index, "Checkpoint Sanctuary")
	rooms.append(checkpoint)
	index += 1

	var library := _room(_Room.RoomType.CORRUPTED_LIBRARY, grid_x, index, "Corrupted Library")
	library.grid_origin = Vector2i(grid_x, SIDE_ROW)
	library.size_cells = SMALL_CELLS
	library.enemy_count = rng.randi_range(1, 2)
	library.room_index = index
	rooms.append(library)
	index += 1

	grid_x += ROOM_CELLS.x
	rooms.append(_passage(grid_x, index))
	index += 1
	grid_x += PASSAGE_CELLS

	var maze := _room(_Room.RoomType.ROOT_MAZE, grid_x, index, "Root Maze")
	maze.enemy_count = rng.randi_range(2, 3)
	rooms.append(maze)
	index += 1
	grid_x += ROOM_CELLS.x
	rooms.append(_passage(grid_x, index))
	index += 1
	grid_x += PASSAGE_CELLS

	var bell_hall := _room(_Room.RoomType.BLIGHTED_BELL_HALL, grid_x, index, "Blighted Bell Hall")
	bell_hall.enemy_count = rng.randi_range(1, 2)
	rooms.append(bell_hall)
	index += 1

	var baptistry := _room(_Room.RoomType.BLIGHTED_BAPTISTRY, grid_x, index, "Blighted Baptistry")
	baptistry.grid_origin = Vector2i(grid_x, SIDE_ROW)
	baptistry.size_cells = SMALL_CELLS
	baptistry.enemy_count = 1
	baptistry.room_index = index
	rooms.append(baptistry)
	index += 1

	var tower := _room(_Room.RoomType.BELL_TOWER_INTERIOR, grid_x, index, "Bell Tower Interior")
	tower.grid_origin = Vector2i(grid_x + SMALL_CELLS.x, SIDE_ROW)
	tower.size_cells = Vector2i(6, 6)
	tower.room_index = index
	rooms.append(tower)
	index += 1

	grid_x += ROOM_CELLS.x
	rooms.append(_passage(grid_x, index))
	index += 1
	grid_x += PASSAGE_CELLS

	var central := _room(_Room.RoomType.CENTRAL_NAVE, grid_x, index, "Central Nave")
	central.enemy_count = rng.randi_range(2, 3)
	rooms.append(central)
	index += 1
	grid_x += ROOM_CELLS.x
	rooms.append(_passage(grid_x, index))
	index += 1
	grid_x += PASSAGE_CELLS

	var choir := _room(_Room.RoomType.CHOIR_APPROACH, grid_x, index, "Choir Approach")
	choir.enemy_count = rng.randi_range(1, 2)
	rooms.append(choir)
	index += 1

	var elite := _room(_Room.RoomType.ELITE_GUARDIAN_CHAPEL, grid_x, index, "Elite Guardian Chapel")
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

	var antechamber := _room(_Room.RoomType.BOSS_ANTECHAMBER, grid_x, index, "Boss Antechamber")
	antechamber.enemy_count = rng.randi_range(1, 2)
	rooms.append(antechamber)
	index += 1
	grid_x += ROOM_CELLS.x
	rooms.append(_passage(grid_x, index))
	index += 1
	grid_x += PASSAGE_CELLS

	var heart := _room(_Room.RoomType.HEART_CHAMBER, grid_x, index, "Heart Chamber")
	heart.enemy_count = 0
	rooms.append(heart)
	index += 1
	grid_x += ROOM_CELLS.x
	rooms.append(_passage(grid_x, index))
	index += 1
	grid_x += PASSAGE_CELLS

	var exit_room := _room(_Room.RoomType.EXIT_CLOISTER, grid_x, index, "Exit Cloister")
	rooms.append(exit_room)

	return {
		"seed": seed_value,
		"dungeon_id": "blightspire_cathedral",
		"rooms": rooms,
		"name": "Blightspire Cathedral",
		"cell_size": CELL_SIZE,
	}


static func _room(type: int, grid_x: int, index: int, category: String) -> Resource:
	var room = _Room.new()
	room.room_type = type
	room.room_category = category
	room.grid_origin = Vector2i(grid_x, 0)
	room.size_cells = ROOM_CELLS if type != _Room.RoomType.RESOURCE_CRYPT else SMALL_CELLS
	room.room_index = index
	return room


static func _passage(grid_x: int, index: int) -> Resource:
	var room = _Room.new()
	room.room_type = _Room.RoomType.PASSAGE
	room.room_category = "Crypt Passage"
	room.grid_origin = Vector2i(grid_x, 0)
	room.size_cells = Vector2i(PASSAGE_CELLS, ROOM_CELLS.y)
	room.room_index = index
	return room
