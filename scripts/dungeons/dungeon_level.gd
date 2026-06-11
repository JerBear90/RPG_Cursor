extends Node3D
## Spawns players and camera inside a procedural dungeon instance.

const _SpawnHelpers = preload("res://scripts/utilities/spawn_helpers.gd")

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
		var pos := spawn_pos + Vector3(i * 2.0, 0.0, 0)
		await _SpawnHelpers.place_player_safely_on_ground(player, pos, get_tree())
		if i == 0 and not GameManager.pending_player_progress.is_empty():
			PlayerProgress.apply(player, GameManager.pending_player_progress)
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
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("begin_death_sequence"):
			await hud.begin_death_sequence()
	if not is_instance_valid(player):
		return
	var spawn_pos := _get_spawn_position()
	if player is CharacterBody3D:
		await _SpawnHelpers.place_player_safely_on_ground(player as CharacterBody3D, spawn_pos, get_tree())
	if player.has_node("HealthComponent"):
		(player.get_node("HealthComponent") as HealthComponent).reset_health()
	if player is PlayerController:
		var pc := player as PlayerController
		pc.current_state = PlayerController.State.IDLE
		pc.refresh_spawn_protection()
		pc.velocity = Vector3.ZERO
		var lock_on := pc.get_node_or_null("LockOnController")
		if lock_on and lock_on.has_method("release_lock"):
			lock_on.release_lock()
		if camera_rig and camera_rig.has_method("snap_to_player"):
			camera_rig.snap_to_player(pc)
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("finish_death_sequence"):
			await hud.finish_death_sequence()
