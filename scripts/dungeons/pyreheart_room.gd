class_name PyreheartRoom
extends Resource
## Room in the Pyreheart Ziggurat dungeon graph.

enum RoomType {
	ENTRANCE, PASSAGE, SCORCHED_NAVE, COLLAPSED_ARCHWAY, SAND_CLOISTER,
	BURIED_ARCHIVE, EMBER_BAPTISTRY, RESOURCE_VAULT, MIRROR_CHAMBER,
	HEAT_MAZE, OBELISK_TOWER, GLASS_HALL, CHECKPOINT,
	ELITE_PYRE_CHAPEL, CENTRAL_ZIGGURAT, ASCENT_APPROACH, SOLAR_ANTECHAMBER,
	SEALED_HEART_CHAMBER, EXIT_TERRACE,
}

@export var room_type: RoomType = RoomType.SCORCHED_NAVE
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
		RoomType.ENTRANCE: return "Ziggurat Entrance"
		RoomType.PASSAGE: return "Sand Passage"
		RoomType.SCORCHED_NAVE: return "Scorched Nave"
		RoomType.COLLAPSED_ARCHWAY: return "Collapsed Archway"
		RoomType.SAND_CLOISTER: return "Sand Cloister"
		RoomType.BURIED_ARCHIVE: return "Buried Archive"
		RoomType.EMBER_BAPTISTRY: return "Ember Baptistry"
		RoomType.RESOURCE_VAULT: return "Resource Vault"
		RoomType.MIRROR_CHAMBER: return "Mirror Chamber"
		RoomType.HEAT_MAZE: return "Heat Maze"
		RoomType.OBELISK_TOWER: return "Obelisk Tower"
		RoomType.GLASS_HALL: return "Glass Hall"
		RoomType.CHECKPOINT: return "Oasis Checkpoint"
		RoomType.ELITE_PYRE_CHAPEL: return "Elite Pyre Chapel"
		RoomType.CENTRAL_ZIGGURAT: return "Central Ziggurat"
		RoomType.ASCENT_APPROACH: return "Ascent Approach"
		RoomType.SOLAR_ANTECHAMBER: return "Solar Antechamber"
		RoomType.SEALED_HEART_CHAMBER: return "Sealed Solar Heart"
		RoomType.EXIT_TERRACE: return "Exit Terrace"
		_: return room_category if room_category != "" else "Unknown"
