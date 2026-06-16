class_name ReliquaryRoom
extends Resource
## Room in the Sunken Reliquary dungeon graph.

enum RoomType {
	ENTRANCE, CORRIDOR, FLOODED, COMBAT, CHECKPOINT, PUZZLE, TRAP,
	RESOURCE, LOOT, ELITE, BOSS_APPROACH, BOSS, EXIT,
}

@export var room_type: RoomType = RoomType.COMBAT
@export var room_category: String = ""
@export var grid_origin: Vector2i = Vector2i.ZERO
@export var size_cells: Vector2i = Vector2i(10, 10)
@export var enemy_count: int = 0
@export var room_index: int = 0
@export var connector_north: bool = false
@export var connector_south: bool = false


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
		RoomType.ENTRANCE: return "Entrance Hall"
		RoomType.FLOODED: return "Flooded Corridor"
		RoomType.CHECKPOINT: return "Checkpoint Sanctuary"
		RoomType.PUZZLE: return "Bell Chamber"
		RoomType.TRAP: return "Trap Hall"
		RoomType.ELITE: return "Elite Chamber"
		RoomType.BOSS_APPROACH: return "Boss Approach"
		RoomType.BOSS: return "Bellkeeper Arena"
		RoomType.RESOURCE: return "Resource Alcove"
		RoomType.LOOT: return "Loot Chamber"
		RoomType.COMBAT: return "Combat Room"
		RoomType.CORRIDOR: return "Corridor"
		_: return room_category if room_category != "" else "Unknown"
