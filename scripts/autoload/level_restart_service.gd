extends Node
## Unified death flow: capture context, reload level, place player at correct marker.

const _SpawnResolver = preload("res://scripts/levels/spawn_resolver.gd")
const _RestartContext = preload("res://scripts/levels/level_restart_context.gd")
const _SpawnHelpers = preload("res://scripts/utilities/spawn_helpers.gd")

var _handling_death: bool = false
var _restart_in_progress: bool = false
var last_restart_report: Dictionary = {}


func _ready() -> void:
	if not GameManager.player_died.is_connected(_on_player_died):
		GameManager.player_died.connect(_on_player_died)


func _on_player_died(player: Node, index: int) -> void:
	if _restart_in_progress:
		return
	if GameManager.is_local_coop() and not GameManager.are_all_players_dead():
		_handle_coop_single_death(player, index)
		return
	_handling_death = true
	_restart_in_progress = true
	GameManager.death_input_locked = true
	await _run_death_restart(player)
	_reset_restart_state()


func _handle_coop_single_death(player: Node, index: int) -> void:
	var hud := _find_hud()
	if hud and hud.has_method("show_toast"):
		hud.show_toast("Exile %d fell" % (index + 1), 3.0, "Revive at camp, checkpoint, or transition")
	for rig in get_tree().get_nodes_in_group("camera_rig"):
		if rig.has_method("_refresh_attachment"):
			rig.call_deferred("_refresh_attachment")


func _run_death_restart(player: Node) -> void:
	var ctx = WorldStateManager.capture_death_context(_current_scene_path())
	if is_instance_valid(player):
		if player.has_node("Combat") and player.get_node("Combat").has_method("force_release_combat_state"):
			player.get_node("Combat").force_release_combat_state()
	var use_water := SaveManager.consume_water_respawn()
	if use_water:
		ctx.restore_needs = false
		ctx.copper_penalty = 0
		ctx.death_message = "Drowned — returned to your last save point"
		ctx.preferred_spawn_ids = PackedStringArray(["save_point"])
	else:
		ctx.copper_penalty = int(CurrencyManager.copper * 0.1)
		ctx.death_message = "You fell in battle — the level restarts"
	_apply_death_penalties(ctx, use_water)
	if is_instance_valid(player):
		GameManager.pending_player_progress = PlayerProgress.collect(player)
	var hud := _find_hud()
	if hud:
		await hud.begin_death_sequence()
		if hud.has_method("hold_death_blackout"):
			await hud.hold_death_blackout()
	GameManager.pending_restart_context = ctx
	if ctx.inside_dungeon and ctx.in_boss_encounter:
		GameManager.in_boss_fight = false
	if ctx.inside_dungeon:
		_reload_dungeon(ctx)
	else:
		_reload_overworld(ctx)
	await _wait_for_restart_finalize()
	_restart_in_progress = false
	_handling_death = false
	if hud and hud.has_method("finish_death_sequence"):
		await hud.finish_death_sequence()


func _apply_death_penalties(ctx, water_death: bool) -> void:
	if water_death:
		return
	if ctx.copper_penalty > 0:
		CurrencyManager.spend_copper(ctx.copper_penalty)


func _reload_overworld(ctx) -> void:
	var path = ctx.level_scene_path
	if path == "":
		path = "res://scenes/levels/%s/%s.tscn" % [ctx.region_id, ctx.region_id]
	if SaveManager.has_respawn_point() and ctx.preferred_spawn_ids.has("save_point"):
		var target_region := SaveManager.respawn_region
		if target_region != String(ctx.region_id):
			path = "res://scenes/levels/%s/%s.tscn" % [target_region, target_region]
			ctx.region_id = StringName(target_region)
	SceneTransitionManager.reload_scene(path)


func _reload_dungeon(ctx) -> void:
	DungeonManager.reload_dungeon_preserve_seed()
	SceneTransitionManager.reload_scene(DungeonManager.get_active_scene())


func finalize_player_restart(player: Node, restore_needs: bool, toast: String) -> void:
	if not is_instance_valid(player):
		GameManager.pending_restart_context = null
		return
	var ctx = GameManager.pending_restart_context
	if ctx == null:
		ctx = WorldStateManager.capture_death_context(_current_scene_path())
	GameManager.spawn_placement_in_progress = true
	if player is CharacterBody3D:
		await _SpawnResolver._await_world_ground(get_tree())
	var result := await _SpawnResolver.resolve_and_place(ctx, player as CharacterBody3D, get_tree())
	GameManager.spawn_placement_in_progress = false
	if result.is_empty():
		push_error("LevelRestartService: failed to resolve restart marker")
		last_restart_report = {"error": "no_marker", "location_type": ctx.location_type, "placement_ok": false}
		GameManager.pending_restart_context = null
		GameManager.death_input_locked = true
		return
	last_restart_report = {
		"spawn_id": String(result.get("spawn_id", "")),
		"requested_position": result.get("position", Vector3.ZERO),
		"rotation_y": float(result.get("rotation_y", 0.0)),
		"clear_radius": float(result.get("clear_radius", 0.0)),
		"location_type": ctx.location_type,
		"region_id": String(ctx.region_id),
		"inside_dungeon": ctx.inside_dungeon,
		"placement_ok": true,
		"final_position": player.global_position if player is Node3D else Vector3.ZERO,
		"grounded": player.is_on_floor() if player is CharacterBody3D else false,
		"player_instance_id": player.get_instance_id() if is_instance_valid(player) else -1,
	}
	if player is PlayerController:
		var pc := player as PlayerController
		pc.refresh_spawn_protection()
		pc.current_state = PlayerController.State.IDLE
		pc.velocity = Vector3.ZERO
		if player.has_node("Combat") and player.get_node("Combat").has_method("force_release_combat_state"):
			player.get_node("Combat").force_release_combat_state()
		for rig in get_tree().get_nodes_in_group("camera_rig"):
			if rig.has_method("snap_to_player"):
				rig.snap_to_player(pc)
		for hazard in get_tree().get_nodes_in_group("water_hazard"):
			if hazard.has_method("reset_player"):
				hazard.reset_player(pc)
	if player.has_node("HealthComponent"):
		(player.get_node("HealthComponent") as HealthComponent).reset_health()
	if restore_needs and player.has_node("SurvivalNeedsComponent"):
		var needs := player.get_node("SurvivalNeedsComponent") as SurvivalNeedsComponent
		needs.hunger = minf(needs.hunger + 25.0, needs.max_hunger)
		needs.thirst = minf(needs.thirst + 25.0, needs.max_thirst)
	_bind_hud(player)
	var hud := _find_hud()
	if hud:
		if toast != "" and hud.has_method("show_toast"):
			hud.show_toast(toast)
	await _finalize_coop_companions(player, ctx)
	GameManager.pending_restart_context = null
	GameManager.in_boss_fight = false
	GameManager.death_input_locked = false
	InputManager.suppress_gameplay_input_ms(200)


func _finalize_coop_companions(leader: Node, ctx) -> void:
	if not GameManager.is_local_coop():
		return
	var companion := GameManager.get_player(1)
	if companion == null or not is_instance_valid(companion) or companion == leader:
		return
	if not companion is CharacterBody3D:
		return
	GameManager.spawn_placement_in_progress = true
	await _SpawnResolver._await_world_ground(get_tree())
	var placed := false
	if ctx != null:
		var result := await _SpawnResolver.resolve_and_place(ctx, companion as CharacterBody3D, get_tree())
		placed = not result.is_empty()
	if not placed and leader is Node3D:
		var offset := _SpawnHelpers.get_party_offset(1, (leader as Node3D).rotation.y)
		var target := (leader as Node3D).global_position + offset
		placed = await _SpawnHelpers.place_player_safely_on_ground(companion as CharacterBody3D, target, get_tree())
	if placed and companion is Node3D and leader is Node3D:
		(companion as Node3D).rotation.y = (leader as Node3D).rotation.y
	GameManager.revive_player(companion, 0.45)
	if companion is PlayerController:
		(companion as PlayerController).refresh_spawn_protection()
	GameManager.spawn_placement_in_progress = false


func _wait_for_restart_finalize() -> void:
	var frames := 0
	while GameManager.pending_restart_context != null and frames < 900:
		await get_tree().process_frame
		frames += 1
	if GameManager.pending_restart_context != null:
		var ctx = GameManager.pending_restart_context
		var reason := "pending_restart_context never cleared"
		if GameManager.spawn_placement_in_progress:
			reason = "spawn_placement_in_progress stuck"
		elif ctx.inside_dungeon:
			reason = "dungeon restart finalize stuck (generation/collision/marker placement)"
		push_error("LevelRestartService: restart finalize timed out — %s" % reason)
		last_restart_report = {
			"error": "finalize_timeout",
			"reason": reason,
			"location_type": ctx.location_type,
			"inside_dungeon": ctx.inside_dungeon,
			"in_boss_encounter": ctx.in_boss_encounter,
			"placement_ok": false,
		}
		GameManager.pending_restart_context = null
		GameManager.spawn_placement_in_progress = false
		GameManager.death_input_locked = false
		var hud := _find_hud()
		if hud and hud.has_method("force_reset_death_overlay"):
			hud.force_reset_death_overlay()


func is_restart_idle() -> bool:
	return not _restart_in_progress and GameManager.pending_restart_context == null


func is_handling_death() -> bool:
	return _handling_death or _restart_in_progress


func _reset_restart_state() -> void:
	_handling_death = false
	_restart_in_progress = false
	GameManager.spawn_placement_in_progress = false
	if GameManager.pending_restart_context == null:
		GameManager.death_input_locked = false


func _bind_hud(player: Node) -> void:
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("bind_production_player"):
			hud.bind_production_player(player)


func _find_hud() -> Node:
	for hud in get_tree().get_nodes_in_group("game_hud"):
		return hud
	return null


func _current_scene_path() -> String:
	var scene := get_tree().current_scene
	if scene and scene.scene_file_path != "":
		return scene.scene_file_path
	return ""
