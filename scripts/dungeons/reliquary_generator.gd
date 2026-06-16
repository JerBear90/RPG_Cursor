class_name ReliquaryGenerator
extends RefCounted
## Generates the Sunken Reliquary room graph (8–12 rooms, one optional branch).

const _Room := preload("res://scripts/dungeons/reliquary_room.gd")

const CELL_SIZE := 2.0
const ROOM_CELLS := Vector2i(10, 10)
const CORRIDOR_CELLS := 3
const SMALL_CELLS := Vector2i(8, 8)


static func generate(seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var rooms: Array = []
	var grid_x := 0
	var index := 0

	rooms.append(_room(_Room.RoomType.ENTRANCE, grid_x, index, "Entrance Hall"))
	index += 1
	grid_x += ROOM_CELLS.x

	rooms.append(_corridor(grid_x, index))
	index += 1
	grid_x += CORRIDOR_CELLS

	var flooded := _room(_Room.RoomType.FLOODED, grid_x, index, "Flooded Corridor")
	flooded.enemy_count = rng.randi_range(1, 2)
	rooms.append(flooded)
	index += 1
	grid_x += ROOM_CELLS.x

	rooms.append(_corridor(grid_x, index))
	index += 1
	grid_x += CORRIDOR_CELLS

	var checkpoint := _room(_Room.RoomType.CHECKPOINT, grid_x, index, "Checkpoint Sanctuary")
	rooms.append(checkpoint)
	index += 1
	grid_x += ROOM_CELLS.x

	rooms.append(_corridor(grid_x, index))
	index += 1
	grid_x += CORRIDOR_CELLS

	var puzzle := _room(_Room.RoomType.PUZZLE, grid_x, index, "Bell Chamber")
	rooms.append(puzzle)
	index += 1
	grid_x += ROOM_CELLS.x

	if rng.randf() > 0.3:
		var branch_z := ROOM_CELLS.y + CORRIDOR_CELLS
		var resource := _room(_Room.RoomType.RESOURCE, grid_x - ROOM_CELLS.x, index, "Resource Alcove")
		resource.grid_origin = Vector2i(puzzle.grid_origin.x, branch_z)
		resource.size_cells = SMALL_CELLS
		resource.room_index = index
		rooms.append(resource)
		index += 1

	rooms.append(_corridor(grid_x, index))
	index += 1
	grid_x += CORRIDOR_CELLS

	var trap := _room(_Room.RoomType.TRAP, grid_x, index, "Trap Hall")
	rooms.append(trap)
	index += 1
	grid_x += ROOM_CELLS.x

	rooms.append(_corridor(grid_x, index))
	index += 1
	grid_x += CORRIDOR_CELLS

	var combat := _room(_Room.RoomType.COMBAT, grid_x, index, "Combat Room")
	combat.enemy_count = rng.randi_range(2, 3)
	rooms.append(combat)
	index += 1
	grid_x += ROOM_CELLS.x

	if rng.randf() > 0.4:
		rooms.append(_corridor(grid_x, index))
		index += 1
		grid_x += CORRIDOR_CELLS
		var elite := _room(_Room.RoomType.ELITE, grid_x, index, "Elite Chamber")
		elite.enemy_count = 1
		rooms.append(elite)
		index += 1
		grid_x += ROOM_CELLS.x

	rooms.append(_corridor(grid_x, index))
	index += 1
	grid_x += CORRIDOR_CELLS

	var approach := _room(_Room.RoomType.BOSS_APPROACH, grid_x, index, "Boss Approach")
	rooms.append(approach)
	index += 1
	grid_x += ROOM_CELLS.x

	rooms.append(_corridor(grid_x, index))
	index += 1
	grid_x += CORRIDOR_CELLS

	var boss := _room(_Room.RoomType.BOSS, grid_x, index, "Bellkeeper Arena")
	boss.enemy_count = 1
	rooms.append(boss)

	return {
		"seed": seed_value,
		"dungeon_id": "sunken_reliquary",
		"rooms": rooms,
		"name": "Sunken Reliquary",
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


static func _corridor(grid_x: int, index: int) -> Resource:
	var room = _Room.new()
	room.room_type = _Room.RoomType.CORRIDOR
	room.room_category = "Corridor"
	room.grid_origin = Vector2i(grid_x, 0)
	room.size_cells = Vector2i(CORRIDOR_CELLS, ROOM_CELLS.y)
	room.room_index = index
	return room
