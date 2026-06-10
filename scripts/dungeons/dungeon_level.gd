extends Node3D
## Spawns players and camera inside a procedural dungeon instance.

@onready var players_container: Node3D = $Players
@onready var camera_rig: Node3D = $CameraRig


func _ready() -> void:
	GameManager.set_region("procedural_dungeon")
	call_deferred("_spawn_players")
	if not GameManager.player_died.is_connected(_on_player_died):
		GameManager.player_died.connect(_on_player_died)


func _spawn_players() -> void:
	var player_scene := GameManager.get_player_scene()
	if player_scene == null:
		return
	var spawn_pos := _get_spawn_position()
	var count := GameManager.active_player_count if GameManager.game_started else 1
	for i in count:
		var player := player_scene.instantiate() as PlayerController
		player.player_index = i
		player.name = "Player%d" % (i + 1)
		players_container.add_child(player)
		player.global_position = spawn_pos + Vector3(i * 2.0, 0.1, 0)
		PetManager.try_spawn_for_player(player)


func _get_spawn_position() -> Vector3:
	var layout: Dictionary = DungeonManager.layout
	var rooms: Array = layout.get("rooms", [])
	for room in rooms:
		if room is DungeonRoom and room.room_type == DungeonRoom.RoomType.SPAWN:
			return room.get_world_center(layout.get("cell_size", 2.0))
	return Vector3(5, 0.1, 5)


func _on_player_died(player: Node, _index: int) -> void:
	if not is_instance_valid(player):
		return
	await get_tree().create_timer(GameManager.respawn_delay).timeout
	if not is_instance_valid(player):
		return
	player.global_position = _get_spawn_position()
	if player.has_node("HealthComponent"):
		(player.get_node("HealthComponent") as HealthComponent).reset_health()
	if player is PlayerController:
		(player as PlayerController).current_state = PlayerController.State.IDLE
