class_name FoundryRoom
extends Resource
## Room in the Blackvein Foundry dungeon graph.

enum RoomType {
	ENTRANCE, CORRIDOR, SMELTING, WORKSHOP, STORAGE, COLLAPSED, MOLTEN,
	VENT_CONTROL, COMBAT, RESOURCE, CHECKPOINT, MECHANISM, ELITE,
	BOSS_APPROACH, BOSS, EXIT,
}

@export var room_type: RoomType = RoomType.COMBAT
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
		RoomType.ENTRANCE: return "Foundry Entrance"
		RoomType.SMELTING: return "Smelting Hall"
		RoomType.WORKSHOP: return "Machine Workshop"
		RoomType.STORAGE: return "Ore Storage"
		RoomType.COLLAPSED: return "Collapsed Tunnel"
		RoomType.MOLTEN: return "Molten Channel"
		RoomType.VENT_CONTROL: return "Vent Control"
		RoomType.CHECKPOINT: return "Checkpoint Workshop"
		RoomType.MECHANISM: return "Forge Regulator"
		RoomType.ELITE: return "Elite Forge"
		RoomType.BOSS_APPROACH: return "Core Access Hall"
		RoomType.BOSS: return "Foundry Core Arena"
		RoomType.COMBAT: return "Combat Chamber"
		RoomType.RESOURCE: return "Resource Room"
		RoomType.CORRIDOR: return "Rail Corridor"
		_: return room_category if room_category != "" else "Unknown"
