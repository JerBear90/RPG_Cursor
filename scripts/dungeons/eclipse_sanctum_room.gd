class_name EclipseSanctumRoom
extends Resource
## Room in the Eclipse Sanctum dungeon graph.

enum RoomType {
	ENTRANCE, PASSAGE, SHADOW_NAVE, MOON_CLOISTER, BURIED_ARCHIVE,
	WARD_CHAMBER, DREAD_MAZE, OBSERVATORY_HALL, RESOURCE_VAULT, CHECKPOINT,
	ELITE_SHADOW_CHAPEL, CENTRAL_SPIRE, ASCENT_APPROACH, ECLIPSE_ANTECHAMBER,
	SEALED_THRONE_CHAMBER, EXIT_TERRACE,
}

@export var room_type: RoomType = RoomType.SHADOW_NAVE
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
		RoomType.ENTRANCE: return "Sanctum Entrance"
		RoomType.PASSAGE: return "Shadow Passage"
		RoomType.SHADOW_NAVE: return "Shadow Nave"
		RoomType.MOON_CLOISTER: return "Moon Cloister"
		RoomType.BURIED_ARCHIVE: return "Buried Archive"
		RoomType.WARD_CHAMBER: return "Ward Chamber"
		RoomType.DREAD_MAZE: return "Dread Maze"
		RoomType.OBSERVATORY_HALL: return "Observatory Hall"
		RoomType.RESOURCE_VAULT: return "Resource Vault"
		RoomType.CHECKPOINT: return "Ward Checkpoint"
		RoomType.ELITE_SHADOW_CHAPEL: return "Elite Shadow Chapel"
		RoomType.CENTRAL_SPIRE: return "Central Spire"
		RoomType.ASCENT_APPROACH: return "Ascent Approach"
		RoomType.ECLIPSE_ANTECHAMBER: return "Eclipse Antechamber"
		RoomType.SEALED_THRONE_CHAMBER: return "Sealed Eclipse Throne"
		RoomType.EXIT_TERRACE: return "Exit Terrace"
		_: return room_category if room_category != "" else "Unknown"
