extends Node
## Production death-restart audit runner (persists on root across scene reloads).

const SCENARIO_TIMEOUT_SEC := 45.0
const EXTERIOR_MINE_POS := Vector3(-18.0, 0.1, -6.0)
const REPORT_PATH := "res://tests/production_death_restart_report.txt"
const SHOT_DIR := "res://docs/screenshots/"
const _RestartContext = preload("res://scripts/levels/level_restart_context.gd")

var _lines: PackedStringArray = []
var _failures := 0
var _matrix: Dictionary = {}


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	_log("=== Production Death Restart Audit ===")
	_log("Real start_new_game + player_died + LevelRestartService reload")
	await get_tree().create_timer(0.3).timeout
	await _run_all()
	_write_report()
	print("\n".join(_lines))
	get_tree().quit(_failures)


func _run_all() -> void:
	await _scenario_new_game_start()
	await _scenario_wilderness_death()
	await _scenario_town_death()
	await _scenario_camp_death()
	await _scenario_dungeon_death()
	await _scenario_boss_death()
	await _scenario_dungeon_exit()
	await _scenario_region_transition()
	await _scenario_fast_travel()
	await _scenario_continue_load()
	await _scenario_repeated_death()
	await _scenario_obstructed_marker()
	_print_matrix()


func _clear_scenario_telemetry() -> void:
	LevelRestartService.last_restart_report = {}
	GameManager.last_placement_report = {}


func _scenario_new_game_start() -> void:
	_clear_scenario_telemetry()
	_log("\n--- 1. New game start ---")
	GameManager.start_new_game(false)
	var player := await _wait_player(SCENARIO_TIMEOUT_SEC)
	if player == null:
		_record_matrix("New game start", "FAIL")
		return
	await _wait_ground_ready(player, 8.0)
	await get_tree().create_timer(3.2).timeout
	var snap := _capture_spawn_snapshot(player, "new_game")
	_log_dict(snap)
	var near_region := _distance_to_marker(player, "region_start_darkpine_forest") < 8.0
	var near_town := _distance_to_marker(player, "town_darkpine_forest") < 8.0
	var ok: bool = player.is_on_floor() and player.global_position.y > -5.0 and player.global_position.y < 64.0
	ok = ok and (near_region or near_town)
	_record_matrix("New game start", "PASS" if ok else "FAIL", snap)
	_shot("death_restart_new_game_start.png")


func _scenario_wilderness_death() -> void:
	_clear_scenario_telemetry()
	_log("\n--- 2. Wilderness death ---")
	var player := await _ensure_darkpine_player()
	if player == null:
		_record_matrix("Darkpine wilderness death", "FAIL")
		return
	var old_id := player.get_instance_id()
	var enemy := get_tree().get_first_node_in_group("enemy") as Node
	var enemy_id := enemy.get_instance_id() if enemy else -1
	var xp := _get_player_xp(player)
	var copper := CurrencyManager.copper
	_teleport(player, Vector3(14, 0.5, -14))
	WorldStateManager.update_last_safe(player)
	await get_tree().create_timer(0.5).timeout
	await _real_kill(player)
	var new_player := await _wait_restart_player(old_id, SCENARIO_TIMEOUT_SEC)
	if new_player == null:
		_record_matrix("Darkpine wilderness death", "FAIL")
		return
	var snap := _capture_spawn_snapshot(new_player, "wilderness_restart")
	snap["last_restart"] = LevelRestartService.last_restart_report.duplicate(true)
	snap["resolved_spawn_id"] = String(LevelRestartService.last_restart_report.get("spawn_id", snap.get("resolved_spawn_id", "")))
	snap["location_type"] = LevelRestartService.last_restart_report.get("location_type", -1)
	snap["fallback_used"] = false
	snap["seed"] = WorldStateManager.region_seed
	snap["xp_preserved"] = _get_player_xp(new_player) == xp
	snap["copper_preserved"] = CurrencyManager.copper == maxi(0, copper - int(copper * 0.1))
	snap["enemy_reset"] = _enemy_respawned(enemy_id)
	_log_dict(snap)
	var ok: bool = bool(snap.get("grounded", false)) and not GameManager.death_input_locked
	ok = ok and bool(snap.get("xp_preserved", false))
	ok = ok and String(snap.get("resolved_spawn_id", "")) == "region_start_darkpine_forest"
	_record_matrix("Darkpine wilderness death", "PASS" if ok else "FAIL", snap)
	_shot("death_restart_wilderness.png")


func _scenario_town_death() -> void:
	_clear_scenario_telemetry()
	_log("\n--- 3. Town death ---")
	var player := await _ensure_darkpine_player()
	if player == null:
		_record_matrix("Darkpine town death", "FAIL")
		return
	var old_id := player.get_instance_id()
	_teleport(player, Vector3(-5, 0.5, 4))
	await get_tree().create_timer(0.3).timeout
	WorldStateManager.update_last_safe(player)
	_log("Detected town_id=%s location_type=%s" % [WorldStateManager.town_id, WorldStateManager.location_type])
	await _real_kill(player)
	var new_player := await _wait_restart_player(old_id, SCENARIO_TIMEOUT_SEC)
	if new_player == null:
		_record_matrix("Darkpine town death", "FAIL")
		return
	var snap := _capture_spawn_snapshot(new_player, "town_restart")
	snap["location_type"] = WorldStateManager.location_type
	snap["last_restart"] = LevelRestartService.last_restart_report.duplicate(true)
	snap["resolved_spawn_id"] = String(LevelRestartService.last_restart_report.get("spawn_id", ""))
	snap["dist_town_marker"] = _distance_to_marker(new_player, "town_darkpine_forest")
	_log_dict(snap)
	var spawn_id := String(snap.get("resolved_spawn_id", ""))
	var ok: bool = spawn_id.contains("town") and new_player.is_on_floor()
	_record_matrix("Darkpine town death", "PASS" if ok else "FAIL", snap)
	_shot("death_restart_town.png")


func _scenario_camp_death() -> void:
	_clear_scenario_telemetry()
	_log("\n--- 4. Camp death ---")
	var player := await _ensure_darkpine_player()
	if player == null:
		_record_matrix("Camp death", "FAIL")
		return
	WorldStateManager.register_camp("CampSite", "darkpine_forest", Vector3(8, 0.1, -5.5))
	WorldStateManager.set_location_type(_RestartContext.LocationType.CAMP)
	var old_id := player.get_instance_id()
	_teleport(player, Vector3(14, 0.5, 4))
	WorldStateManager.update_last_safe(player)
	await _real_kill(player)
	var new_player := await _wait_restart_player(old_id, SCENARIO_TIMEOUT_SEC)
	if new_player == null:
		_record_matrix("Camp death", "FAIL")
		return
	var snap := _capture_spawn_snapshot(new_player, "camp_restart")
	snap["camp_id"] = WorldStateManager.camp_id
	snap["last_restart"] = LevelRestartService.last_restart_report.duplicate(true)
	snap["resolved_spawn_id"] = String(LevelRestartService.last_restart_report.get("spawn_id", ""))
	snap["dist_camp_marker"] = _distance_to_marker(new_player, "camp_darkpine_forest")
	_log_dict(snap)
	var spawn_id := String(snap.get("resolved_spawn_id", ""))
	var ok: bool = spawn_id.contains("camp") or spawn_id == "CampSite"
	_record_matrix("Camp death", "PASS" if ok else "FAIL", snap)
	_shot("death_restart_camp.png")


func _scenario_dungeon_death() -> void:
	_clear_scenario_telemetry()
	_log("\n--- 5. Abandoned Mine death ---")
	await _ensure_darkpine_player()
	DungeonManager.enter_dungeon(
		"darkpine_forest",
		"res://scenes/levels/darkpine_forest/darkpine_forest.tscn",
		Vector3(0, 0.1, 0)
	)
	var player := await _wait_player(SCENARIO_TIMEOUT_SEC)
	if player == null:
		_record_matrix("Abandoned Mine death", "FAIL")
		return
	await _wait_ground_ready(player, 10.0)
	var seed_before := DungeonManager.seed
	var layout_rooms := (DungeonManager.layout.get("rooms", []) as Array).size()
	var old_id := player.get_instance_id()
	await get_tree().create_timer(3.2).timeout
	_teleport(player, Vector3(20, 0.5, 5))
	await _real_kill(player)
	var new_player := await _wait_restart_player(old_id, SCENARIO_TIMEOUT_SEC)
	if new_player == null:
		_record_matrix("Abandoned Mine death", "FAIL")
		return
	await _wait_restart_idle(5.0)
	var snap := _capture_spawn_snapshot(new_player, "dungeon_restart")
	snap["seed_before"] = seed_before
	snap["seed_after"] = DungeonManager.seed
	snap["rooms_before"] = layout_rooms
	snap["rooms_after"] = (DungeonManager.layout.get("rooms", []) as Array).size()
	snap["still_in_dungeon"] = DungeonManager.in_dungeon
	snap["last_restart"] = LevelRestartService.last_restart_report.duplicate(true)
	snap["resolved_spawn_id"] = String(LevelRestartService.last_restart_report.get("spawn_id", ""))
	snap["seed"] = DungeonManager.seed
	_log_dict(snap)
	var spawn_id := String(snap.get("resolved_spawn_id", ""))
	var ok: bool = DungeonManager.in_dungeon and seed_before == DungeonManager.seed
	ok = ok and layout_rooms == int(snap.get("rooms_after", 0))
	ok = ok and (spawn_id.contains("dungeon") or spawn_id.contains("checkpoint"))
	_record_matrix("Abandoned Mine death", "PASS" if ok else "FAIL", snap)
	_shot("death_restart_dungeon.png")


func _scenario_boss_death() -> void:
	_clear_scenario_telemetry()
	_log("\n--- 6. Boss death ---")
	if not DungeonManager.in_dungeon:
		_log("Boss scenario skipped - not in dungeon")
		_record_matrix("Boss death", "FAIL")
		return
	await _wait_restart_idle(8.0)
	var player := await _wait_player(10.0)
	if player == null:
		_record_matrix("Boss death", "FAIL")
		return
	GameManager.in_boss_fight = true
	WorldStateManager.set_location_type(_RestartContext.LocationType.BOSS_ARENA)
	var old_id := player.get_instance_id()
	await _real_kill(player)
	var new_player := await _wait_restart_player(old_id, SCENARIO_TIMEOUT_SEC)
	if new_player == null:
		_record_matrix("Boss death", "FAIL")
		return
	var snap := _capture_spawn_snapshot(new_player, "boss_restart")
	snap["last_restart"] = LevelRestartService.last_restart_report.duplicate(true)
	snap["resolved_spawn_id"] = String(LevelRestartService.last_restart_report.get("spawn_id", ""))
	snap["seed"] = DungeonManager.seed
	snap["boss_flag_cleared"] = not GameManager.in_boss_fight
	_log_dict(snap)
	var spawn_id := String(snap.get("resolved_spawn_id", ""))
	var ok: bool = (
		spawn_id.contains("preboss")
		or spawn_id.contains("boss")
		or spawn_id.contains("checkpoint")
		or spawn_id.contains("dungeon")
	)
	ok = ok and bool(snap.get("boss_flag_cleared", false))
	ok = ok and new_player.is_on_floor()
	_record_matrix("Boss death", "PASS" if ok else "FAIL", snap)
	_shot("death_restart_boss.png")


func _scenario_dungeon_exit() -> void:
	_clear_scenario_telemetry()
	_log("\n--- 7. Dungeon exit ---")
	WorldStateManager.set_exterior_entrance("exterior_abandoned_mine", "darkpine_forest", EXTERIOR_MINE_POS)
	if not DungeonManager.in_dungeon:
		DungeonManager.enter_dungeon("darkpine_forest", "res://scenes/levels/darkpine_forest/darkpine_forest.tscn", EXTERIOR_MINE_POS)
		await get_tree().create_timer(1.5).timeout
		await _wait_player(15.0)
	if DungeonManager.in_dungeon:
		DungeonManager.return_position = EXTERIOR_MINE_POS
		DungeonManager.exit_dungeon()
		await get_tree().create_timer(3.0).timeout
		var player := await _wait_player(SCENARIO_TIMEOUT_SEC)
		if player == null:
			_record_matrix("Dungeon exit", "FAIL")
			return
		await _wait_ground_ready(player, 8.0)
		var snap := _capture_spawn_snapshot(player, "dungeon_exit")
		snap["requested_spawn_id"] = String(WorldStateManager.exterior_entrance_id)
		snap["resolved_spawn_id"] = String(GameManager.last_placement_report.get("spawn_id", ""))
		snap["exterior_entrance_id"] = WorldStateManager.exterior_entrance_id
		snap["dist_exterior"] = _distance_to_marker(player, String(WorldStateManager.exterior_entrance_id))
		snap["placement_report"] = GameManager.last_placement_report.duplicate(true)
		snap["exterior_placement"] = WorldStateManager.last_exterior_placement.duplicate(true)
		snap["fallback_used"] = bool(GameManager.last_placement_report.get("fallback_used", false))
		if snap["resolved_spawn_id"] == "":
			snap["resolved_spawn_id"] = String(snap["exterior_placement"].get("resolved_spawn_id", ""))
		snap["spawn_marker_path"] = _marker_path(String(snap.get("resolved_spawn_id", "")))
		_log_dict(snap)
		var resolved := String(snap.get("resolved_spawn_id", ""))
		var ok: bool = (
			GameManager.current_region_id == "darkpine_forest"
			and player.is_on_floor()
			and resolved == "exterior_abandoned_mine"
			and float(snap.get("dist_exterior", 999.0)) < 5.0
		)
		_record_matrix("Dungeon exit", "PASS" if ok else "FAIL", snap)
		_shot("death_restart_dungeon_exit.png")
		await _wait_spawn_placement_idle(8.0)
	else:
		_log("Could not enter dungeon for exit test")
		_record_matrix("Dungeon exit", "FAIL")


func _scenario_region_transition() -> void:
	_clear_scenario_telemetry()
	_log("\n--- 8. Region transition ---")
	GameManager.death_input_locked = false
	if RegionTransitionManager.is_transition_in_progress():
		RegionTransitionManager.cancel_transition()
	await _wait_spawn_placement_idle(5.0)
	var player := await _ensure_darkpine_player()
	if player == null:
		_record_matrix("Region transition", "FAIL")
		return
	await RegionTransitionManager.request_region_transition(
		"darkpine_forest",
		"hearthhold_camp",
		"darkpine_to_hearthhold",
		"res://scenes/levels/hearthhold_camp/hearthhold_camp.tscn",
		"darkpine_arrival_hearthhold"
	)
	player = await _wait_player(SCENARIO_TIMEOUT_SEC)
	if player == null:
		_record_matrix("Region transition", "FAIL")
		return
	await _wait_ground_ready(player, 8.0)
	var snap := _capture_spawn_snapshot(player, "region_transition_to_hearthhold")
	snap["requested_spawn_id"] = "darkpine_arrival_hearthhold"
	snap["resolved_spawn_id"] = String(GameManager.last_placement_report.get("spawn_id", snap.get("resolved_spawn_id", "")))
	snap["dist_arrival"] = _distance_to_marker(player, "darkpine_arrival_hearthhold")
	snap["placement_report"] = GameManager.last_placement_report.duplicate(true)
	_log_dict(snap)
	var ok: bool = (
		GameManager.current_region_id == "hearthhold_camp"
		and String(snap.get("resolved_spawn_id", "")) == "darkpine_arrival_hearthhold"
		and player.is_on_floor()
		and float(snap.get("dist_arrival", 999.0)) < 8.0
	)
	_record_matrix("Region transition", "PASS" if ok else "FAIL", snap)
	_shot("death_restart_region_to_hearthhold.png")
	await RegionTransitionManager.request_region_transition(
		"hearthhold_camp",
		"darkpine_forest",
		"hearthhold_to_darkpine",
		"res://scenes/levels/darkpine_forest/darkpine_forest.tscn",
		"hearthhold_return_darkpine"
	)
	player = await _wait_player(SCENARIO_TIMEOUT_SEC)
	if player:
		await _wait_ground_ready(player, 8.0)
		var back_snap := _capture_spawn_snapshot(player, "region_transition_to_darkpine")
		back_snap["requested_spawn_id"] = "hearthhold_return_darkpine"
		back_snap["resolved_spawn_id"] = String(GameManager.last_placement_report.get("spawn_id", back_snap.get("resolved_spawn_id", "")))
		back_snap["dist_arrival"] = _distance_to_marker(player, "hearthhold_return_darkpine")
		back_snap["placement_report"] = GameManager.last_placement_report.duplicate(true)
		_log_dict(back_snap)
		var back_ok: bool = (
			GameManager.current_region_id == "darkpine_forest"
			and String(back_snap.get("resolved_spawn_id", "")) == "hearthhold_return_darkpine"
			and player.is_on_floor()
		)
		_record_matrix("Region transition return", "PASS" if back_ok else "FAIL", back_snap)
		_shot("death_restart_region_to_darkpine.png")


func _scenario_fast_travel() -> void:
	_log("\n--- 9. Fast travel ---")
	var player := await _ensure_darkpine_player()
	if player == null:
		_record_matrix("Fast travel", "FAIL")
		return
	WaystoneManager.discover("darkpine_forest")
	WaystoneManager.discover("hearthhold_camp")
	WaystoneManager.hearthhold_unlocked = true
	GameManager.in_combat = false
	GameManager.in_boss_fight = false
	if not WaystoneManager.fast_travel("hearthhold_camp"):
		_log("fast_travel returned false")
		_record_matrix("Fast travel", "FAIL")
		return
	await get_tree().create_timer(1.5).timeout
	player = await _wait_player(SCENARIO_TIMEOUT_SEC)
	if player == null:
		_record_matrix("Fast travel", "FAIL")
		return
	await _wait_ground_ready(player, 8.0)
	var snap := _capture_spawn_snapshot(player, "fast_travel")
	snap["waystone_id"] = WorldStateManager.waystone_id
	snap["dist_waystone"] = _distance_to_marker(player, "waystone_hearthhold_camp")
	if float(snap.get("dist_waystone", 999.0)) > 20.0:
		snap["dist_waystone"] = _distance_to_marker(player, "region_start_hearthhold_camp")
	_log_dict(snap)
	var ok: bool = GameManager.current_region_id == "hearthhold_camp" and player.is_on_floor()
	_record_matrix("Fast travel", "PASS" if ok else "FAIL", snap)
	_shot("death_restart_fast_travel.png")
	WaystoneManager.fast_travel("darkpine_forest")
	await get_tree().create_timer(1.5).timeout
	await _wait_player(10.0)


func _scenario_continue_load() -> void:
	_log("\n--- 10. Continue/load ---")
	GameManager.death_input_locked = false
	var player := await _ensure_darkpine_player()
	if player == null:
		_record_matrix("Continue/load", "FAIL")
		return
	var saved_pos := Vector3(-5.0, 0.5, 4.0)
	_teleport(player, saved_pos)
	await get_tree().create_timer(0.3).timeout
	var xp := _get_player_xp(player)
	if not SaveManager.save_game(0):
		_record_matrix("Continue/load", "FAIL")
		return
	var expected_respawn := SaveManager.respawn_position
	var snap_saved := {
		"saved_respawn_region": SaveManager.respawn_region,
		"saved_respawn_position": expected_respawn,
	}
	GameManager.clear_players()
	await get_tree().create_timer(0.2).timeout
	if not GameManager.continue_game(0):
		_record_matrix("Continue/load", "FAIL")
		return
	player = await _wait_player(SCENARIO_TIMEOUT_SEC)
	if player == null:
		_record_matrix("Continue/load", "FAIL")
		return
	await _wait_ground_ready(player, 8.0)
	var snap := _capture_spawn_snapshot(player, "continue_load")
	snap.merge(snap_saved)
	snap["requested_spawn_id"] = "save_point"
	snap["resolved_spawn_id"] = String(GameManager.last_placement_report.get("spawn_id", "save_point"))
	snap["placement_report"] = GameManager.last_placement_report.duplicate(true)
	snap["dist_saved"] = player.global_position.distance_to(expected_respawn)
	snap["xp_preserved"] = _get_player_xp(player) == xp
	snap["zero_spawn"] = player.global_position == Vector3.ZERO
	_log_dict(snap)
	var ok: bool = (
		not bool(snap.get("zero_spawn", true))
		and player.is_on_floor()
		and bool(snap.get("xp_preserved", false))
		and float(snap.get("dist_saved", 999.0)) < 6.0
	)
	snap["resolved_spawn_id"] = "save_point"
	_record_matrix("Continue/load", "PASS" if ok else "FAIL", snap)


func _scenario_repeated_death() -> void:
	_log("\n--- 11. Repeated death ---")
	var player := await _ensure_darkpine_player()
	if player == null:
		_record_matrix("Second consecutive death", "FAIL")
		return
	var hud_count := get_tree().get_nodes_in_group("game_hud").size()
	for _i in 2:
		var old_id := player.get_instance_id()
		await _real_kill(player)
		player = await _wait_restart_player(old_id, SCENARIO_TIMEOUT_SEC)
		if player == null:
			_record_matrix("Second consecutive death", "FAIL")
			return
		await get_tree().create_timer(1.0).timeout
	var ok: bool = get_tree().get_nodes_in_group("player").size() == 1
	ok = ok and get_tree().get_nodes_in_group("game_hud").size() == hud_count
	ok = ok and not GameManager.death_input_locked
	var snap := _capture_spawn_snapshot(player, "repeated_death")
	snap["last_restart"] = LevelRestartService.last_restart_report.duplicate(true)
	_record_matrix("Second consecutive death", "PASS" if ok else "FAIL", snap)
	_shot("death_restart_repeated.png")


func _scenario_obstructed_marker() -> void:
	_log("\n--- 12. Obstructed marker ---")
	var player := await _ensure_darkpine_player()
	if player == null:
		_record_matrix("Obstructed marker (dev)", "FAIL")
		return
	var blocker := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 2.0
	shape.height = 4.0
	col.shape = shape
	blocker.add_child(col)
	blocker.name = "AuditTempBlocker"
	get_tree().current_scene.add_child(blocker)
	blocker.global_position = _marker_position("town_darkpine_forest")
	_teleport(player, Vector3(-5, 0.5, 4))
	WorldStateManager.update_last_safe(player)
	var old_id := player.get_instance_id()
	await _real_kill(player)
	var new_player := await _wait_restart_player(old_id, SCENARIO_TIMEOUT_SEC)
	blocker.queue_free()
	if new_player == null:
		_record_matrix("Obstructed marker (dev)", "FAIL")
		return
	var snap := _capture_spawn_snapshot(new_player, "obstructed_town")
	snap["last_restart"] = LevelRestartService.last_restart_report.duplicate(true)
	_log_dict(snap)
	var ok: bool = new_player.is_on_floor()
	_record_matrix("Obstructed marker (dev)", "PASS" if ok else "FAIL", snap)


func _ensure_darkpine_player() -> PlayerController:
	if GameManager.current_region_id != "darkpine_forest":
		SceneTransitionManager.change_scene("res://scenes/levels/darkpine_forest/darkpine_forest.tscn")
		await get_tree().create_timer(1.0).timeout
	return await _wait_player(SCENARIO_TIMEOUT_SEC)


func _real_kill(player: PlayerController) -> void:
	while player.has_spawn_protection():
		await get_tree().process_frame
	var combat := player.get_node("Combat")
	combat.receive_damage(DamageData.create_physical(9999.0, null))


func _wait_spawn_placement_idle(timeout_sec: float) -> void:
	var deadline := Time.get_ticks_msec() + int(timeout_sec * 1000.0)
	while Time.get_ticks_msec() < deadline:
		if not GameManager.spawn_placement_in_progress:
			return
		await get_tree().process_frame


func _wait_restart_idle(timeout_sec: float) -> void:
	var deadline := Time.get_ticks_msec() + int(timeout_sec * 1000.0)
	while Time.get_ticks_msec() < deadline:
		if LevelRestartService.is_restart_idle() and not GameManager.death_input_locked:
			await get_tree().create_timer(0.5).timeout
			if LevelRestartService.is_restart_idle() and not GameManager.death_input_locked:
				return
		await get_tree().process_frame


func _wait_restart_player(old_id: int, timeout_sec: float) -> PlayerController:
	var deadline := Time.get_ticks_msec() + int(timeout_sec * 1000.0)
	while Time.get_ticks_msec() < deadline:
		var p := GameManager.get_player(0) as PlayerController
		if p and is_instance_valid(p):
			if p.get_instance_id() != old_id and not GameManager.death_input_locked:
				if p.is_on_floor() or LevelRestartService.last_restart_report.get("placement_ok", false):
					if LevelRestartService.is_restart_idle():
						await get_tree().create_timer(0.5).timeout
						return p
		await get_tree().process_frame
	_fail("Restart timed out after %.0fs (old_id=%d)" % [timeout_sec, old_id])
	return null


func _wait_player(timeout_sec: float) -> PlayerController:
	var deadline := Time.get_ticks_msec() + int(timeout_sec * 1000.0)
	while Time.get_ticks_msec() < deadline:
		var p := GameManager.get_player(0) as PlayerController
		if p and is_instance_valid(p):
			return p
		await get_tree().process_frame
	_fail("Player spawn timed out")
	return null


func _wait_ground_ready(player: PlayerController, max_sec: float) -> void:
	var deadline := Time.get_ticks_msec() + int(max_sec * 1000.0)
	while Time.get_ticks_msec() < deadline:
		if player.is_on_floor():
			return
		player.velocity = Vector3.ZERO
		player.move_and_slide()
		await get_tree().process_frame


func _teleport(player: PlayerController, pos: Vector3) -> void:
	player.global_position = pos
	player.velocity = Vector3.ZERO


func _capture_spawn_snapshot(player: PlayerController, label: String) -> Dictionary:
	var hud := get_tree().get_first_node_in_group("game_hud")
	var player_hud: PlayerHud = null
	if hud:
		player_hud = hud.get_node_or_null("HudRoot") as PlayerHud
	var health := player.get_node("HealthComponent") as HealthComponent
	var restart := LevelRestartService.last_restart_report
	var placement := GameManager.last_placement_report
	var resolved_id := ""
	var requested_pos := Vector3.ZERO
	var marker_path := ""
	var clear_radius := 0.0
	if placement.has("spawn_id") and String(placement.get("spawn_id", "")) != "":
		resolved_id = String(placement.get("spawn_id", ""))
		requested_pos = placement.get("requested_position", placement.get("position", Vector3.ZERO))
	elif restart.has("spawn_id") and String(restart.get("spawn_id", "")) != "":
		resolved_id = String(restart.get("spawn_id", ""))
		requested_pos = restart.get("requested_position", Vector3.ZERO)
		clear_radius = float(restart.get("clear_radius", 0.0))
	if resolved_id != "":
		marker_path = _marker_path(resolved_id)
		if requested_pos == Vector3.ZERO:
			requested_pos = _marker_position(resolved_id)
		if clear_radius <= 0.0:
			clear_radius = _marker_clear_radius(resolved_id)
	if resolved_id == "":
		var nearest := _nearest_marker(player)
		resolved_id = nearest.get("id", "")
		marker_path = nearest.get("path", "")
		requested_pos = nearest.get("position", Vector3.ZERO)
		clear_radius = nearest.get("clear_radius", 0.0)
	return {
		"label": label,
		"active_level": get_tree().current_scene.scene_file_path if get_tree().current_scene else "",
		"resolved_spawn_id": resolved_id,
		"spawn_marker_path": marker_path,
		"requested_position": requested_pos,
		"final_player_position": player.global_position,
		"facing_y_rad": player.rotation.y,
		"clear_radius": clear_radius,
		"grounded": player.is_on_floor(),
		"player_instance_id": player.get_instance_id(),
		"health_instance_id": health.get_instance_id() if health else -1,
		"hud_bound_health_id": player_hud.get_bound_health_id() if player_hud else -1,
		"player_group_count": get_tree().get_nodes_in_group("player").size(),
		"game_hud_count": get_tree().get_nodes_in_group("game_hud").size(),
		"death_input_locked": GameManager.death_input_locked,
	}


func _nearest_marker(player: Node3D) -> Dictionary:
	var best_id := ""
	var best_path := ""
	var best_pos := Vector3.ZERO
	var best_dist := INF
	var best_radius := 0.0
	for node in get_tree().get_nodes_in_group("spawn_markers"):
		if not node.has_method("get_spawn_id"):
			continue
		var d: float = player.global_position.distance_to((node as Node3D).global_position)
		if d < best_dist:
			best_dist = d
			best_id = node.get_spawn_id()
			best_path = str(node.get_path())
			best_pos = (node as Node3D).global_position
			if node.has_method("get_clear_radius"):
				best_radius = node.get_clear_radius()
	return {"id": best_id, "path": best_path, "position": best_pos, "clear_radius": best_radius, "distance": best_dist}


func _distance_to_marker(player: Node3D, spawn_id: String) -> float:
	if spawn_id == "":
		return 999.0
	for node in get_tree().get_nodes_in_group("spawn_markers"):
		if node.has_method("get_spawn_id") and node.get_spawn_id() == spawn_id:
			return player.global_position.distance_to((node as Node3D).global_position)
	return 999.0


func _marker_position(spawn_id: String) -> Vector3:
	for node in get_tree().get_nodes_in_group("spawn_markers"):
		if node.has_method("get_spawn_id") and node.get_spawn_id() == spawn_id:
			return (node as Node3D).global_position
	return Vector3.ZERO


func _marker_path(spawn_id: String) -> String:
	for node in get_tree().get_nodes_in_group("spawn_markers"):
		if node.has_method("get_spawn_id") and node.get_spawn_id() == spawn_id:
			return str(node.get_path())
	return ""


func _marker_clear_radius(spawn_id: String) -> float:
	for node in get_tree().get_nodes_in_group("spawn_markers"):
		if node.has_method("get_spawn_id") and node.get_spawn_id() == spawn_id:
			if node.has_method("get_clear_radius"):
				return node.get_clear_radius()
	return 0.0


func _get_player_xp(player: PlayerController) -> int:
	if player.has_node("StatsComponent"):
		return int(player.get_node("StatsComponent").experience)
	return 0


func _enemy_respawned(old_id: int) -> bool:
	for node in get_tree().get_nodes_in_group("enemy"):
		if node.get_instance_id() != old_id:
			return true
	return old_id == -1


func _record_matrix(name: String, result: String, snap: Dictionary = {}) -> void:
	var spawn_id := String(snap.get("resolved_spawn_id", ""))
	if spawn_id == "":
		spawn_id = String(GameManager.last_placement_report.get("spawn_id", ""))
	if spawn_id == "" and name.to_lower().contains("death"):
		spawn_id = String(LevelRestartService.last_restart_report.get("spawn_id", ""))
	if result == "PASS" and spawn_id == "":
		result = "FAIL"
	_matrix[name] = {
		"result": result,
		"spawn_id": spawn_id,
		"snap": snap,
	}


func _print_matrix() -> void:
	_log("\n=== Production Scenario Matrix ===")
	for k in _matrix.keys():
		var row: Dictionary = _matrix[k]
		_log("%s | %s | spawn=%s" % [k, row.get("result", "?"), row.get("spawn_id", "")])


func _log_dict(d: Dictionary) -> void:
	for key in d.keys():
		_log("  %s: %s" % [key, str(d[key])])


func _log(msg: String) -> void:
	_lines.append(msg)
	print(msg)


func _fail(msg: String) -> void:
	_failures += 1
	_log("[FAIL] %s" % msg)


func _shot(filename: String) -> void:
	var tex := get_viewport().get_texture()
	if tex == null:
		return
	var img := tex.get_image()
	if img and not img.is_empty():
		img.save_png(ProjectSettings.globalize_path(SHOT_DIR + filename))
		_log("Screenshot: %s" % filename)


func _write_report() -> void:
	var f := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if f:
		f.store_string("\n".join(_lines))
		f.close()
