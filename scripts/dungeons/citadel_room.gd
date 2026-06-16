class_name CitadelRoom
extends Resource
## Room in the Drowned Citadel dungeon graph.

enum RoomType {
	ENTRANCE, PASSAGE, FLOODED_GALLERY, BROKEN_SEA_HALL, SALT_CORRIDOR, TIDAL_TRAP,
	DROWNED_BARRACKS, RESOURCE, TREASURE_HOLD, CHECKPOINT, PUZZLE,
	ELITE, BOSS_APPROACH, BOSS, EXIT,
}

@export var room_type: RoomType = RoomType.FLOODED_GALLERY
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
		RoomType.ENTRANCE: return "Citadel Entrance"
		RoomType.PASSAGE: return "Flooded Passage"
		RoomType.FLOODED_GALLERY: return "Flooded Gallery"
		RoomType.BROKEN_SEA_HALL: return "Broken Sea Hall"
		RoomType.SALT_CORRIDOR: return "Salt-Crusted Corridor"
		RoomType.TIDAL_TRAP: return "Tidal Trap Corridor"
		RoomType.DROWNED_BARRACKS: return "Drowned Barracks"
		RoomType.CHECKPOINT: return "Checkpoint Sanctuary"
		RoomType.PUZZLE: return "Storm Conduit Chamber"
		RoomType.ELITE: return "Elite Guardian Hall"
		RoomType.BOSS_APPROACH: return "Throne Approach"
		RoomType.BOSS: return "Tidebound Throne"
		RoomType.RESOURCE: return "Resource Vault"
		RoomType.TREASURE_HOLD: return "Treasure Hold"
		RoomType.EXIT: return "Exit Harbor"
		_: return room_category if room_category != "" else "Unknown"
