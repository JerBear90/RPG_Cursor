class_name RoomDiscoveryZone
extends Area3D
## Marks a dungeon room discovered when the player enters its bounds.

@export var room_index: int = 0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	if DungeonManager.current_dungeon_id == "blackvein_foundry":
		FoundryState.discover_room(room_index)
	elif DungeonManager.current_dungeon_id == "paleheart_crypt":
		CryptState.discover_room(room_index)
	elif DungeonManager.current_dungeon_id == "drowned_citadel":
		CitadelState.discover_room(room_index)
	elif DungeonManager.current_dungeon_id == "blightspire_cathedral":
		CathedralState.discover_room(room_index)
	elif DungeonManager.current_dungeon_id == "pyreheart_ziggurat":
		PyreheartState.discover_room(room_index)
	elif DungeonManager.current_dungeon_id == "eclipse_sanctum":
		EclipseSanctumState.discover_room(room_index)
	else:
		ReliquaryState.discover_room(room_index)
	MapManager.map_updated.emit(GameManager.current_region_id)
