class_name PyreheartGenerator
extends RefCounted
## Generates Pyreheart Ziggurat room graph with desert-themed critical path.

const _Room := preload("res://scripts/dungeons/pyreheart_room.gd")

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

	rooms.append(_room(_Room.RoomType.ENTRANCE, grid_x, index, "Ziggurat Entrance"))
	index += 1
	grid_x += ROOM_CELLS.x
	rooms.append(_passage(grid_x, index))
	index += 1
	grid_x += PASSAGE_CELLS

	var nave := _room(_Room.RoomType.SCORCHED_NAVE, grid_x, index, "Scorched Nave")
	nave.enemy_count = rng.randi_range(1, 2)
	rooms.append(nave)
	index += 1
	grid_x += ROOM_CELLS.x
	rooms.append(_passage(grid_x, index))
	index += 1
	grid_x += PASSAGE_CELLS

	var arch := _room(_Room.RoomType.COLLAPSED_ARCHWAY, grid_x, index, "Collapsed Archway")
	arch.enemy_count = rng.randi_range(1, 2)
	rooms.append(arch)
	index += 1

	var cloister := _room(_Room.RoomType.SAND_CLOISTER, grid_x, index, "Sand Cloister")
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

	var mirror := _room(_Room.RoomType.MIRROR_CHAMBER, grid_x, index, "Mirror Chamber")
	rooms.append(mirror)
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

	var checkpoint := _room(_Room.RoomType.CHECKPOINT, grid_x, index, "Oasis Checkpoint")
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

	var maze := _room(_Room.RoomType.HEAT_MAZE, grid_x, index, "Heat Maze")
	maze.enemy_count = rng.randi_range(2, 3)
	rooms.append(maze)
	index += 1
	grid_x += ROOM_CELLS.x
	rooms.append(_passage(grid_x, index))
	index += 1
	grid_x += PASSAGE_CELLS

	var glass_hall := _room(_Room.RoomType.GLASS_HALL, grid_x, index, "Glass Hall")
	glass_hall.enemy_count = rng.randi_range(1, 2)
	rooms.append(glass_hall)
	index += 1

	var baptistry := _room(_Room.RoomType.EMBER_BAPTISTRY, grid_x, index, "Ember Baptistry")
	baptistry.grid_origin = Vector2i(grid_x, SIDE_ROW)
	baptistry.size_cells = SMALL_CELLS
	baptistry.enemy_count = 1
	baptistry.room_index = index
	rooms.append(baptistry)
	index += 1

	var tower := _room(_Room.RoomType.OBELISK_TOWER, grid_x, index, "Obelisk Tower")
	tower.grid_origin = Vector2i(grid_x + SMALL_CELLS.x, SIDE_ROW)
	tower.size_cells = Vector2i(6, 6)
	tower.room_index = index
	rooms.append(tower)
	index += 1

	grid_x += ROOM_CELLS.x
	rooms.append(_passage(grid_x, index))
	index += 1
	grid_x += PASSAGE_CELLS

	var central := _room(_Room.RoomType.CENTRAL_ZIGGURAT, grid_x, index, "Central Ziggurat")
	central.enemy_count = rng.randi_range(2, 3)
	rooms.append(central)
	index += 1
	grid_x += ROOM_CELLS.x
	rooms.append(_passage(grid_x, index))
	index += 1
	grid_x += PASSAGE_CELLS

	var ascent := _room(_Room.RoomType.ASCENT_APPROACH, grid_x, index, "Ascent Approach")
	ascent.enemy_count = rng.randi_range(1, 2)
	rooms.append(ascent)
	index += 1

	var elite := _room(_Room.RoomType.ELITE_PYRE_CHAPEL, grid_x, index, "Elite Pyre Chapel")
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

	var antechamber := _room(_Room.RoomType.SOLAR_ANTECHAMBER, grid_x, index, "Solar Antechamber")
	antechamber.enemy_count = rng.randi_range(1, 2)
	rooms.append(antechamber)
	index += 1
	grid_x += ROOM_CELLS.x
	rooms.append(_passage(grid_x, index))
	index += 1
	grid_x += PASSAGE_CELLS

	var heart := _room(_Room.RoomType.SEALED_HEART_CHAMBER, grid_x, index, "Sealed Solar Heart")
	heart.enemy_count = 0
	rooms.append(heart)
	index += 1
	grid_x += ROOM_CELLS.x
	rooms.append(_passage(grid_x, index))
	index += 1
	grid_x += PASSAGE_CELLS

	var exit_room := _room(_Room.RoomType.EXIT_TERRACE, grid_x, index, "Exit Terrace")
	rooms.append(exit_room)

	return {
		"seed": seed_value,
		"dungeon_id": "pyreheart_ziggurat",
		"rooms": rooms,
		"name": "Pyreheart Ziggurat",
		"cell_size": CELL_SIZE,
	}


static func _room(type: int, grid_x: int, index: int, category: String) -> Resource:
	var room = _Room.new()
	room.room_type = type
	room.room_category = category
	room.grid_origin = Vector2i(grid_x, 0)
	room.size_cells = ROOM_CELLS if type != _Room.RoomType.RESOURCE_VAULT else SMALL_CELLS
	room.room_index = index
	return room


static func _passage(grid_x: int, index: int) -> Resource:
	var room = _Room.new()
	room.room_type = _Room.RoomType.PASSAGE
	room.room_category = "Sand Passage"
	room.grid_origin = Vector2i(grid_x, 0)
	room.size_cells = Vector2i(PASSAGE_CELLS, ROOM_CELLS.y)
	room.room_index = index
	return room
