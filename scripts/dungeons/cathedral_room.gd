class_name CathedralRoom
extends Resource
## Room in the Blightspire Cathedral dungeon graph.

enum RoomType {
	ENTRANCE, PASSAGE, ROOTBOUND_NAVE, COLLAPSED_TRANSEPT, FUNGAL_CLOISTER,
	CORRUPTED_LIBRARY, BLIGHTED_BAPTISTRY, RESOURCE_CRYPT, PURIFICATION_CHAMBER,
	ROOT_MAZE, BELL_TOWER_INTERIOR, BLIGHTED_BELL_HALL, CHECKPOINT,
	ELITE_GUARDIAN_CHAPEL, CENTRAL_NAVE, CHOIR_APPROACH, BOSS_ANTECHAMBER,
	HEART_CHAMBER, EXIT_CLOISTER,
}

@export var room_type: RoomType = RoomType.ROOTBOUND_NAVE
@export var room_category: String = ""
@export var grid_origin: Vector2i = Vector2i.ZERO
@export var size_cells: Vector2i = Vector2i(10, 10)
@export var enemy_count: int = 0
@export var room_index: int = 0


func get_world_origin(cell_size: float) -> Vector3:
	return Vector3(grid_origin.x * cell_size, 0.0, grid_origin.y * cell_size)


func get_world_center(cell_size: float) -> Vector3:
	var origin := get_world_origin(cell_size)
	return origin + Vector3(
		size_cells.x * cell_size * 0.5,
		0.1,
		size_cells.y * cell_size * 0.5
	)


func get_world_size(cell_size: float) -> Vector3:
	return Vector3(size_cells.x * cell_size, 0.2, size_cells.y * cell_size)


func get_display_name() -> String:
	match room_type:
		RoomType.ENTRANCE: return "Cathedral Entrance"
		RoomType.PASSAGE: return "Crypt Passage"
		RoomType.ROOTBOUND_NAVE: return "Rootbound Nave"
		RoomType.COLLAPSED_TRANSEPT: return "Collapsed Transept"
		RoomType.FUNGAL_CLOISTER: return "Fungal Cloister"
		RoomType.CORRUPTED_LIBRARY: return "Corrupted Library"
		RoomType.BLIGHTED_BAPTISTRY: return "Blighted Baptistry"
		RoomType.RESOURCE_CRYPT: return "Resource Crypt"
		RoomType.PURIFICATION_CHAMBER: return "Purification Chamber"
		RoomType.ROOT_MAZE: return "Root Maze"
		RoomType.BELL_TOWER_INTERIOR: return "Bell Tower Interior"
		RoomType.BLIGHTED_BELL_HALL: return "Blighted Bell Hall"
		RoomType.CHECKPOINT: return "Checkpoint Sanctuary"
		RoomType.ELITE_GUARDIAN_CHAPEL: return "Elite Guardian Chapel"
		RoomType.CENTRAL_NAVE: return "Central Nave"
		RoomType.CHOIR_APPROACH: return "Choir Approach"
		RoomType.BOSS_ANTECHAMBER: return "Boss Antechamber"
		RoomType.HEART_CHAMBER: return "Heart Chamber"
		RoomType.EXIT_CLOISTER: return "Exit Cloister"
		_: return room_category if room_category != "" else "Unknown"
