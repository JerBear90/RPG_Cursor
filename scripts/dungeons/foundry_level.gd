extends Node3D
## Blackvein Foundry dungeon level bootstrap.

const _SpawnHelpers = preload("res://scripts/utilities/spawn_helpers.gd")
const _SpawnMarker = preload("res://scripts/spawn_point.gd")
const _RestartContext = preload("res://scripts/levels/level_restart_context.gd")
const _Room := preload("res://scripts/dungeons/foundry_room.gd")

@onready var players_container: Node3D = $Players
@onready var camera_rig: Node3D = $CameraRig

const REGION_ID := "blackvein_foundry"


func _ready() -> void:
	GameManager.set_region(REGION_ID)
	WorldStateManager.set_region(REGION_ID)
	WorldStateManager.set_location_type(_RestartContext.LocationType.DUNGEON)
	MapManager.discover_region(REGION_ID)
	if not QuestManager.active_quests.has("heart_of_blackvein") and "heart_of_blackvein" not in QuestManager.completed_quests:
		if QuestManager.completed_quests.has("fires_below") or InventoryManager.has_item("blackvein_access_key"):
			QuestManager.start_quest("heart_of_blackvein")
	call_deferred("_begin_dungeon")


func _begin_dungeon() -> void:
	var ready := await _await_collision_ready()
	if not ready:
		push_error("FoundryLevel: collision never ready")
	_register_markers()
	await _spawn_players()
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("_fade_from_black"):
			await hud._fade_from_black(0.5)


func _await_collision_ready() -> bool:
	var builder := get_node_or_null("Environment/FoundryBuilder")
	if builder == null:
		return false
	if builder.has_method("is_build_complete"):
		var deadline := Time.get_ticks_msec() + 15000
		while not builder.is_build_complete() and Time.get_ticks_msec() < deadline:
			await get_tree().process_frame
		if not builder.is_build_complete():
			return false
	for _i in 6:
		await get_tree().physics_frame
	return true


func _register_markers() -> void:
	var existing := get_node_or_null("RestartMarkers")
	if existing:
		existing.queue_free()
	var root := Node3D.new()
	root.name = "RestartMarkers"
	add_child(root)
	var layout: Dictionary = DungeonManager.layout
	var cell_size: float = layout.get("cell_size", FoundryGenerator.CELL_SIZE)
	var entry_center := Vector3(5, 0.1, 5)
	var checkpoint_center := Vector3.ZERO
	var preboss_center := Vector3.ZERO
	for room in layout.get("rooms", []):
		if room is FoundryRoom:
			var center := room.get_world_center(cell_size)
			if room.room_type == _Room.RoomType.ENTRANCE:
				entry_center = center
				FoundryState.discover_room(room.room_index)
			elif room.room_type == _Room.RoomType.CHECKPOINT:
				checkpoint_center = center
			elif room.room_type == _Room.RoomType.BOSS_APPROACH:
				preboss_center = center
	_SpawnMarker.create_runtime(root, "dungeon_spawn_blackvein_foundry", _SpawnMarker.MarkerType.DUNGEON_ENTRY_SPAWN, entry_center, 0.0, REGION_ID, 4.0)
	_SpawnMarker.create_runtime(root, "dungeon_entry_blackvein_foundry", _SpawnMarker.MarkerType.DUNGEON_ENTRY_SPAWN, entry_center, 0.0, REGION_ID, 4.0)
	if checkpoint_center != Vector3.ZERO:
		_SpawnMarker.create_runtime(root, "dungeon_checkpoint_blackvein_foundry", _SpawnMarker.MarkerType.DUNGEON_CHECKPOINT_SPAWN, checkpoint_center, 0.0, REGION_ID, 5.0)
	if preboss_center != Vector3.ZERO:
		_SpawnMarker.create_runtime(root, "preboss_blackvein_foundry", _SpawnMarker.MarkerType.BOSS_CHECKPOINT_SPAWN, preboss_center, 180.0, REGION_ID, 5.0)
		_SpawnMarker.create_runtime(root, "boss_checkpoint_blackvein_foundry", _SpawnMarker.MarkerType.BOSS_CHECKPOINT_SPAWN, preboss_center, 180.0, REGION_ID, 5.0)


func _spawn_players() -> void:
	var player_scene := GameManager.get_player_scene()
	if player_scene == null:
		return
	var spawn_pos := _get_entry_position()
	var count := GameManager.active_player_count if GameManager.game_started else 1
	var restarting := GameManager.pending_restart_context != null
	for i in count:
		var player := player_scene.instantiate() as PlayerController
		player.player_index = i
		player.name = "Player%d" % (i + 1)
		players_container.add_child(player)
		var pos := spawn_pos + Vector3(i * 2.0, 0, 0)
		GameManager.spawn_placement_in_progress = true
		GameManager.death_input_locked = true
		if i == 0 and restarting:
			player.global_position = pos
		else:
			await _SpawnHelpers.place_player_safely_on_ground(player, pos, get_tree())
		if i == 0:
			if not GameManager.pending_player_progress.is_empty():
				PlayerProgress.apply(player, GameManager.pending_player_progress)
				GameManager.pending_player_progress = {}
			if restarting:
				await LevelRestartService.finalize_player_restart(
					player,
					GameManager.pending_restart_context.restore_needs if GameManager.pending_restart_context else true,
					GameManager.pending_restart_context.death_message if GameManager.pending_restart_context else ""
				)
			else:
				await _SpawnHelpers.place_player_on_ground(player, pos, get_tree())
				for rig in get_tree().get_nodes_in_group("camera_rig"):
					if rig.has_method("snap_to_player"):
						rig.snap_to_player(player)
				call_deferred("_bind_hud", player)
				GameManager.death_input_locked = false
		GameManager.spawn_placement_in_progress = false
		PetManager.try_spawn_for_player(player)


func _bind_hud(player: Node) -> void:
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("bind_production_player"):
			hud.bind_production_player(player)


func _get_entry_position() -> Vector3:
	for room in DungeonManager.layout.get("rooms", []):
		if room is FoundryRoom and room.room_type == _Room.RoomType.ENTRANCE:
			return room.get_world_center(DungeonManager.layout.get("cell_size", 2.0))
	return Vector3(5, 0.1, 5)
