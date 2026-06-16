class_name CryptRoom
extends Resource
## Room in the Paleheart Crypt dungeon graph.

enum RoomType {
	ENTRANCE, PASSAGE, BURIAL_HALL, COLLAPSED, BLACK_ICE, RESOURCE, CHECKPOINT, PUZZLE,
	ELITE, BOSS_APPROACH, BOSS, EXIT,
}

@export var room_type: RoomType = RoomType.BURIAL_HALL
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
		RoomType.ENTRANCE: return "Crypt Entrance"
		RoomType.PASSAGE: return "Catacomb Passage"
		RoomType.BURIAL_HALL: return "Burial Hall"
		RoomType.COLLAPSED: return "Collapsed Crypt"
		RoomType.BLACK_ICE: return "Black Ice Vault"
		RoomType.CHECKPOINT: return "Sanctum Rest"
		RoomType.PUZZLE: return "Burial Seal Chamber"
		RoomType.ELITE: return "Elite Tomb"
		RoomType.BOSS_APPROACH: return "Throne Antechamber"
		RoomType.BOSS: return "Hollow King's Throne"
		RoomType.RESOURCE: return "Relic Vault"
		_: return room_category if room_category != "" else "Unknown"
