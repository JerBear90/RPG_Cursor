extends Node3D
## Spawns players and camera inside a procedural dungeon instance.

const _SpawnHelpers = preload("res://scripts/utilities/spawn_helpers.gd")
const _SpawnMarker = preload("res://scripts/spawn_point.gd")
const _RestartContext = preload("res://scripts/levels/level_restart_context.gd")

@onready var players_container: Node3D = $Players
@onready var camera_rig: Node3D = $CameraRig


func _ready() -> void:
	GameManager.set_region("procedural_dungeon")
	WorldStateManager.set_region("procedural_dungeon")
	WorldStateManager.set_location_type(_RestartContext.LocationType.DUNGEON)
	call_deferred("_begin_dungeon")


func _begin_dungeon() -> void:
	var ready := await _await_dungeon_collision_ready()
	if not ready:
		push_error("DungeonLevel: dungeon collision never became ready")
	_register_dungeon_markers()
	await _spawn_players()


func _await_dungeon_collision_ready() -> bool:
	var builder := get_node_or_null("Environment/DungeonBuilder")
	if builder == null:
		return false
	if builder.has_method("is_build_complete"):
		if not builder.is_build_complete():
			var deadline := Time.get_ticks_msec() + 12000
			while not builder.is_build_complete() and Time.get_ticks_msec() < deadline:
				await get_tree().process_frame
			if not builder.is_build_complete():
				return false
	for _i in 4:
		await get_tree().physics_frame
	return true


func _register_dungeon_markers() -> void:
	var existing := get_node_or_null("RestartMarkers")
	if existing:
		existing.queue_free()
	var root := Node3D.new()
	root.name = "RestartMarkers"
	add_child(root)
	var layout: Dictionary = DungeonManager.layout
	var rooms: Array = layout.get("rooms", [])
	var cell_size: float = layout.get("cell_size", 2.0)
	var pre_boss_center := Vector3.ZERO
	for room in rooms:
		if room is DungeonRoom:
			if room.room_type == DungeonRoom.RoomType.SPAWN:
				var center = room.get_world_center(cell_size)
				_SpawnMarker.create_runtime(root, "dungeon_spawn", _SpawnMarker.MarkerType.DUNGEON_ENTRY_SPAWN, center, 0.0, "procedural_dungeon", 3.5)
				_SpawnMarker.create_runtime(root, "dungeon_entry_procedural_dungeon", _SpawnMarker.MarkerType.DUNGEON_ENTRY_SPAWN, center, 0.0, "procedural_dungeon", 3.5)
				WorldStateManager.dungeon_checkpoint_room = room.room_index
			elif room.room_type == DungeonRoom.RoomType.COMBAT and pre_boss_center == Vector3.ZERO:
				pre_boss_center = room.get_world_center(cell_size)
				_SpawnMarker.create_runtime(
					root,
					"dungeon_checkpoint_room_%d" % room.room_index,
					_SpawnMarker.MarkerType.DUNGEON_CHECKPOINT_SPAWN,
					pre_boss_center,
					0.0,
					"procedural_dungeon",
					4.0
				)
	if pre_boss_center != Vector3.ZERO:
		_SpawnMarker.create_runtime(
			root,
			"preboss_abandoned_mine",
			_SpawnMarker.MarkerType.BOSS_CHECKPOINT_SPAWN,
			pre_boss_center,
			180.0,
			"procedural_dungeon",
			5.0
		)
		_SpawnMarker.create_runtime(
			root,
			"boss_checkpoint_procedural_dungeon",
			_SpawnMarker.MarkerType.BOSS_CHECKPOINT_SPAWN,
			pre_boss_center,
			180.0,
			"procedural_dungeon",
			5.0
		)


func _spawn_players() -> void:
	var player_scene := GameManager.get_player_scene()
	if player_scene == null:
		return
	var spawn_pos := _get_spawn_position()
	var count := GameManager.active_player_count if GameManager.game_started else 1
	var restarting := GameManager.pending_restart_context != null
	for i in count:
		var player := player_scene.instantiate() as PlayerController
		player.player_index = i
		player.name = "Player%d" % (i + 1)
		players_container.add_child(player)
		var pos := spawn_pos + Vector3(i * 2.0, 0.0, 0)
		GameManager.spawn_placement_in_progress = true
		if i == 0 and restarting:
			player.global_position = pos
		else:
			await _SpawnHelpers.place_player_safely_on_ground(player, pos, get_tree())
		if i == 0:
			if not GameManager.pending_player_progress.is_empty():
				PlayerProgress.apply(player, GameManager.pending_player_progress)
				GameManager.pending_player_progress = {}
			if restarting:
				var ctx = GameManager.pending_restart_context
				await LevelRestartService.finalize_player_restart(
					player,
					ctx.restore_needs,
					ctx.death_message
				)
			else:
				for rig in get_tree().get_nodes_in_group("camera_rig"):
					if rig.has_method("snap_to_player"):
						rig.snap_to_player(player)
				call_deferred("_bind_hud_to_player", player)
		GameManager.spawn_placement_in_progress = false
		PetManager.try_spawn_for_player(player)


func _bind_hud_to_player(player: Node) -> void:
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("bind_production_player"):
			hud.bind_production_player(player)


func _get_spawn_position() -> Vector3:
	var layout: Dictionary = DungeonManager.layout
	var rooms: Array = layout.get("rooms", [])
	for room in rooms:
		if room is DungeonRoom and room.room_type == DungeonRoom.RoomType.SPAWN:
			return room.get_world_center(layout.get("cell_size", 2.0))
	return Vector3(5, 0.1, 5)
