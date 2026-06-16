extends Node
## Reusable region-to-region transitions with arrival marker placement.

const _RestartContext = preload("res://scripts/levels/level_restart_context.gd")
const _SpawnHelpers = preload("res://scripts/utilities/spawn_helpers.gd")

var _transition_in_progress: bool = false


func is_transition_in_progress() -> bool:
	return _transition_in_progress


func request_region_transition(
	source_region_id: String,
	destination_region_id: String,
	transition_id: String,
	destination_scene_path: String,
	arrival_spawn_id: String
) -> void:
	if _transition_in_progress:
		return
	if destination_scene_path == "" or arrival_spawn_id == "":
		push_error("RegionTransitionManager: missing destination scene or arrival spawn")
		return
	_transition_in_progress = true
	GameManager.death_input_locked = true
	WorldStateManager.begin_region_transition(
		source_region_id,
		destination_region_id,
		transition_id,
		arrival_spawn_id
	)
	GameManager.pending_arrival_spawn_id = arrival_spawn_id
	var deadline := Time.get_ticks_msec() + 12000
	while GameManager.spawn_placement_in_progress and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	await _run_transition(destination_scene_path)
	await _wait_for_arrival_completion(25.0)


func _run_transition(destination_scene_path: String) -> void:
	var hud := _find_hud()
	if hud and hud.has_method("_fade_to_black"):
		await hud._fade_to_black(0.35)
	SceneTransitionManager.change_scene(destination_scene_path)


func _wait_for_arrival_completion(timeout_sec: float) -> void:
	var deadline := Time.get_ticks_msec() + int(timeout_sec * 1000.0)
	while Time.get_ticks_msec() < deadline:
		if not _transition_in_progress:
			return
		if GameManager.pending_arrival_spawn_id == "":
			return
		if not GameManager.spawn_placement_in_progress:
			var player := GameManager.get_player(0)
			if player and is_instance_valid(player) and player.is_on_floor():
				await get_tree().create_timer(0.35).timeout
				if GameManager.pending_arrival_spawn_id == "":
					return
		await get_tree().process_frame
	push_error("RegionTransitionManager: arrival placement timed out")
	cancel_transition()


func complete_arrival(player: Node, spawn_id: String) -> void:
	var transition_id := String(WorldStateManager.entry_transition_id)
	WorldStateManager.complete_region_transition(spawn_id)
	GameManager.pending_arrival_spawn_id = ""
	_transition_in_progress = false
	GameManager.death_input_locked = false
	GameManager.revive_all_dead_players(0.45)
	_place_coop_companions(player)
	GameManager.refresh_coop_camera()
	_apply_transition_quest_hooks(transition_id)
	if player is PlayerController:
		for rig in player.get_tree().get_nodes_in_group("camera_rig"):
			if rig.has_method("snap_to_player"):
				rig.snap_to_player(player as PlayerController)
	var hud := _find_hud()
	if hud and hud.has_method("_fade_from_black"):
		await hud._fade_from_black(0.35)


func cancel_transition() -> void:
	_transition_in_progress = false
	GameManager.pending_arrival_spawn_id = ""
	GameManager.death_input_locked = false


func _apply_transition_quest_hooks(transition_id: String) -> void:
	match transition_id:
		"hearthhold_to_rotfen":
			if QuestManager.active_quests.has("into_rotfen"):
				QuestManager.advance_objective("into_rotfen", "use_rotfen_gate", 1)
				QuestManager.advance_objective("into_rotfen", "enter_rotfen", 1)
		"darkpine_to_hearthhold", "hearthhold_to_darkpine", "rotfen_to_hearthhold":
			pass


func _find_hud() -> Node:
	for hud in get_tree().get_nodes_in_group("game_hud"):
		return hud
	return null


func _place_coop_companions(leader: Node) -> void:
	if not GameManager.is_local_coop() or not leader is Node3D:
		return
	var companion := GameManager.get_player(1)
	if companion == null or not is_instance_valid(companion) or companion == leader:
		return
	if not companion is CharacterBody3D:
		return
	var offset := _SpawnHelpers.get_party_offset(1, (leader as Node3D).rotation.y)
	var target := (leader as Node3D).global_position + offset
	await _SpawnHelpers.place_player_safely_on_ground(companion as CharacterBody3D, target, get_tree())
	companion.rotation.y = (leader as Node3D).rotation.y
