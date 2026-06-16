class_name LevelRestartTests
extends RefCounted

const _RestartContext = preload("res://scripts/levels/level_restart_context.gd")
const _SpawnResolver = preload("res://scripts/levels/spawn_resolver.gd")
const _SpawnMarker = preload("res://scripts/spawn_point.gd")


static func run(runner: Node) -> void:
	await runner.get_tree().process_frame
	_test_location_types(runner)
	_test_context_capture(runner)
	_test_outdoor_restart_priority(runner)
	_test_town_restart_priority(runner)
	_test_camp_restart_priority(runner)
	_test_dungeon_restart_priority(runner)
	_test_boss_restart_priority(runner)
	_test_fast_travel_restart_priority(runner)
	_test_transition_restart_priority(runner)
	_test_exterior_entrance_priority(runner)
	_test_marker_facing_and_clear_radius(runner)
	_test_dungeon_seed_preservation(runner)
	_test_region_seed_in_context(runner)
	_test_world_state_persistence(runner)
	_test_no_zero_fallback_without_marker(runner)
	_test_save_point_priority(runner)
	_test_last_safe_fallback(runner)
	_test_spawn_marker_registry_groups(runner)
	_test_clear_radius_by_type(runner)
	_test_hud_death_text_labels(runner)


static func _make_marker_root(runner: Node) -> Node3D:
	var root := Node3D.new()
	root.name = "RestartTestMarkers"
	runner.add_child(root)
	return root


static func _ctx(type: int, region: String = "darkpine_forest"):
	var ctx = _RestartContext.new()
	ctx.location_type = type
	ctx.region_id = StringName(region)
	ctx.dungeon_id = &"procedural_dungeon"
	return ctx


static func _test_location_types(runner: Node) -> void:
	runner._assert(_RestartContext.LocationType.OUTDOOR_REGION == 0, "OUTDOOR_REGION enum value")
	runner._assert(_RestartContext.LocationType.FAST_TRAVEL_DESTINATION == 8, "FAST_TRAVEL enum value")


static func _test_context_capture(runner: Node) -> void:
	WorldStateManager.reset_for_new_game()
	WorldStateManager.set_region("darkpine_forest", 4242)
	WorldStateManager.register_camp("test_camp", "darkpine_forest", Vector3(6, 0.1, -7))
	WorldStateManager.set_location_type(_RestartContext.LocationType.CAMP)
	var ctx = WorldStateManager.capture_death_context("res://scenes/levels/darkpine_forest/darkpine_forest.tscn")
	runner._assert(ctx.region_id == &"darkpine_forest", "context captures region id")
	runner._assert(ctx.region_seed == 4242, "context captures region seed")
	runner._assert(ctx.camp_id == &"test_camp", "context captures camp id")
	runner._assert(ctx.location_type == _RestartContext.LocationType.CAMP, "context captures camp location type")


static func _test_outdoor_restart_priority(runner: Node) -> void:
	var root := _make_marker_root(runner)
	_SpawnMarker.create_runtime(root, "region_start_darkpine_forest", _SpawnMarker.MarkerType.REGION_START_SPAWN, Vector3(0, 0.1, 0), 0.0, "darkpine_forest", 6.5)
	WorldStateManager.register_checkpoint("wild_checkpoint", "darkpine_forest", Vector3(10, 0.1, 10))
	var ctx = _ctx(_RestartContext.LocationType.OUTDOOR_REGION)
	ctx.checkpoint_id = &"wild_checkpoint"
	var result := _SpawnResolver.resolve(ctx, runner.get_tree())
	runner._assert(result.get("spawn_id", "") == "wild_checkpoint", "outdoor prefers activated checkpoint")
	await runner.get_tree().process_frame
	root.free()


static func _test_town_restart_priority(runner: Node) -> void:
	var root := _make_marker_root(runner)
	_SpawnMarker.create_runtime(root, "town_darkpine_forest", _SpawnMarker.MarkerType.TOWN_SPAWN, Vector3(-5, 0.1, 4), 180.0, "darkpine_forest", 5.0)
	var ctx = _ctx(_RestartContext.LocationType.TOWN)
	ctx.town_id = &"darkpine_forest"
	var result := _SpawnResolver.resolve(ctx, runner.get_tree())
	runner._assert(result.get("spawn_id", "") == "town_darkpine_forest", "town restart uses town spawn marker")
	runner._assert(absf(rad_to_deg(float(result.get("rotation_y", 0.0))) - 180.0) < 1.0, "town marker facing preserved")
	root.free()


static func _test_camp_restart_priority(runner: Node) -> void:
	var root := _make_marker_root(runner)
	_SpawnMarker.create_runtime(root, "camp_darkpine_forest", _SpawnMarker.MarkerType.CAMP_SPAWN, Vector3(6, 0.1, -7.5), 0.0, "darkpine_forest", 4.0)
	var ctx = _ctx(_RestartContext.LocationType.CAMP)
	ctx.camp_id = &"camp_darkpine_forest"
	var result := _SpawnResolver.resolve(ctx, runner.get_tree())
	runner._assert(result.get("spawn_id", "") == "camp_darkpine_forest", "camp restart uses camp marker")
	root.free()


static func _test_dungeon_restart_priority(runner: Node) -> void:
	var root := _make_marker_root(runner)
	_SpawnMarker.create_runtime(root, "dungeon_entry_procedural_dungeon", _SpawnMarker.MarkerType.DUNGEON_ENTRY_SPAWN, Vector3(5, 0.1, 5), 90.0, "procedural_dungeon", 3.5)
	_SpawnMarker.create_runtime(root, "dungeon_checkpoint_room_2", _SpawnMarker.MarkerType.DUNGEON_CHECKPOINT_SPAWN, Vector3(20, 0.1, 5), 0.0, "procedural_dungeon", 4.0)
	var ctx = _ctx(_RestartContext.LocationType.DUNGEON, "procedural_dungeon")
	ctx.dungeon_checkpoint_room = 2
	var result := _SpawnResolver.resolve(ctx, runner.get_tree())
	runner._assert(result.get("spawn_id", "") == "dungeon_checkpoint_room_2", "dungeon prefers latest checkpoint room")
	root.free()


static func _test_boss_restart_priority(runner: Node) -> void:
	var root := _make_marker_root(runner)
	_SpawnMarker.create_runtime(root, "boss_checkpoint_procedural_dungeon", _SpawnMarker.MarkerType.BOSS_CHECKPOINT_SPAWN, Vector3(30, 0.1, 5), 0.0, "procedural_dungeon", 5.0)
	_SpawnMarker.create_runtime(root, "dungeon_entry_procedural_dungeon", _SpawnMarker.MarkerType.DUNGEON_ENTRY_SPAWN, Vector3(5, 0.1, 5), 0.0, "procedural_dungeon", 3.5)
	var ctx = _ctx(_RestartContext.LocationType.BOSS_ARENA, "procedural_dungeon")
	ctx.in_boss_encounter = true
	var result := _SpawnResolver.resolve(ctx, runner.get_tree())
	runner._assert(result.get("spawn_id", "") == "boss_checkpoint_procedural_dungeon", "boss death prefers pre-boss checkpoint")
	root.free()


static func _test_fast_travel_restart_priority(runner: Node) -> void:
	var root := _make_marker_root(runner)
	_SpawnMarker.create_runtime(root, "waystone_darkpine_forest", _SpawnMarker.MarkerType.FAST_TRAVEL_SPAWN, Vector3(-3, 0.1, 12), 180.0, "darkpine_forest", 5.0)
	var ctx = _ctx(_RestartContext.LocationType.FAST_TRAVEL_DESTINATION)
	ctx.waystone_id = &"darkpine_forest"
	var result := _SpawnResolver.resolve(ctx, runner.get_tree())
	runner._assert(result.get("spawn_id", "") == "waystone_darkpine_forest", "fast travel uses waystone arrival marker")
	root.free()


static func _test_transition_restart_priority(runner: Node) -> void:
	var root := _make_marker_root(runner)
	_SpawnMarker.create_runtime(root, "transition_east_entry", _SpawnMarker.MarkerType.TRANSITION_ARRIVAL_SPAWN, Vector3(40, 0.1, 0), 270.0, "rocky_highlands", 5.0)
	var ctx = _ctx(_RestartContext.LocationType.REGION_TRANSITION, "rocky_highlands")
	ctx.entry_spawn_id = &"transition_east_entry"
	var result := _SpawnResolver.resolve(ctx, runner.get_tree())
	runner._assert(result.get("spawn_id", "") == "transition_east_entry", "region transition uses entry spawn marker")
	root.free()


static func _test_exterior_entrance_priority(runner: Node) -> void:
	var root := _make_marker_root(runner)
	_SpawnMarker.create_runtime(root, "exterior_abandoned_mine", _SpawnMarker.MarkerType.EXTERIOR_RETURN_SPAWN, Vector3(12, 0.1, 8), 0.0, "darkpine_forest", 4.0)
	_SpawnMarker.create_runtime(root, "region_start_darkpine_forest", _SpawnMarker.MarkerType.REGION_START_SPAWN, Vector3(0, 0.1, 0), 0.0, "darkpine_forest", 6.5)
	var ctx = _ctx(_RestartContext.LocationType.OUTDOOR_REGION)
	ctx.exterior_entrance_id = &"exterior_abandoned_mine"
	ctx.preferred_spawn_ids = PackedStringArray(["exterior_abandoned_mine"])
	var result := _SpawnResolver.resolve(ctx, runner.get_tree())
	runner._assert(result.get("spawn_id", "") == "exterior_abandoned_mine", "dungeon exterior return marker used")
	root.free()


static func _test_marker_facing_and_clear_radius(runner: Node) -> void:
	var root := _make_marker_root(runner)
	var marker = _SpawnMarker.create_runtime(root, "facing_test", _SpawnMarker.MarkerType.TOWN_SPAWN, Vector3(1, 0.1, 1), 90.0, "darkpine_forest", 5.5)
	runner._assert(absf(marker.get_facing_yaw() - deg_to_rad(90.0)) < 0.01, "marker facing yaw from rotation")
	runner._assert(marker.get_clear_radius() == 5.5, "marker explicit clear radius")
	root.free()


static func _test_dungeon_seed_preservation(runner: Node) -> void:
	DungeonManager.reset_for_new_game()
	DungeonManager.seed = 98765
	DungeonManager.tier = 2
	var before := DungeonGenerator.generate(DungeonManager.seed, DungeonManager.tier)
	DungeonManager.layout = before
	DungeonManager.in_dungeon = true
	DungeonManager.reload_dungeon_preserve_seed()
	runner._assert(DungeonManager.seed == 98765, "dungeon seed preserved on reload")
	var after_rooms: Array = DungeonManager.layout.get("rooms", [])
	var before_rooms: Array = before.get("rooms", [])
	runner._assert(after_rooms.size() == before_rooms.size(), "dungeon layout room count stable after seed reload")


static func _test_region_seed_in_context(runner: Node) -> void:
	WorldStateManager.set_region("darkpine_forest", 777)
	var ctx = WorldStateManager.capture_death_context("")
	runner._assert(ctx.region_seed == 777, "region seed stored in restart context")


static func _test_world_state_persistence(runner: Node) -> void:
	WorldStateManager.reset_for_new_game()
	WorldStateManager.register_checkpoint("cp1", "darkpine_forest", Vector3(1, 0.1, 2))
	WorldStateManager.register_camp("camp1", "darkpine_forest", Vector3(3, 0.1, 4))
	var data := WorldStateManager.serialize()
	WorldStateManager.reset_for_new_game()
	WorldStateManager.deserialize(data)
	runner._assert(WorldStateManager.checkpoint_id == &"cp1", "checkpoint id restored from save")
	runner._assert(WorldStateManager.camp_id == &"camp1", "camp id restored from save")
	runner._assert(WorldStateManager.get_checkpoint_position("darkpine_forest") == Vector3(1, 0.1, 2), "checkpoint position restored")


static func _test_no_zero_fallback_without_marker(runner: Node) -> void:
	var ctx = _ctx(_RestartContext.LocationType.OUTDOOR_REGION, "missing_region_xyz")
	ctx.last_safe_position = Vector3.ZERO
	var result := _SpawnResolver.resolve(ctx, runner.get_tree())
	runner._assert(result.is_empty(), "no silent Vector3.ZERO fallback when no markers exist")


static func _test_save_point_priority(runner: Node) -> void:
	SaveManager.reset_respawn_point()
	SaveManager.set_respawn_point("darkpine_forest", Vector3(8, 0.2, 9))
	var ctx = _RestartContext.new()
	ctx.preferred_spawn_ids = PackedStringArray(["save_point"])
	var result := _SpawnResolver.resolve(ctx, runner.get_tree())
	runner._assert(result.get("spawn_id", "") == "save_point", "save point preferred for water death")
	runner._assert(result.get("position", Vector3.ZERO) == Vector3(8, 0.2, 9), "save point position used")
	SaveManager.reset_respawn_point()


static func _test_last_safe_fallback(runner: Node) -> void:
	var ctx = _ctx(_RestartContext.LocationType.OUTDOOR_REGION, "no_markers_region")
	ctx.last_safe_position = Vector3(15, 0.1, 20)
	var result := _SpawnResolver.resolve(ctx, runner.get_tree())
	runner._assert(result.get("spawn_id", "") == "last_safe_position", "last safe position fallback when no markers")
	runner._assert(result.get("position", Vector3.ZERO) == Vector3(15, 0.1, 20), "last safe position value preserved")


static func _test_spawn_marker_registry_groups(runner: Node) -> void:
	var root := _make_marker_root(runner)
	var marker = _SpawnMarker.create_runtime(root, "group_test", _SpawnMarker.MarkerType.PLAYER_SPAWN, Vector3.ZERO, 0.0, "darkpine_forest", 4.0)
	runner._assert(marker.is_in_group("spawn_markers"), "runtime marker in spawn_markers group")
	runner._assert(marker.is_in_group("spawn_points"), "runtime marker in spawn_points group")
	root.free()


static func _test_clear_radius_by_type(runner: Node) -> void:
	runner._assert(_SpawnResolver.CLEAR_RADIUS[_SpawnMarker.MarkerType.TOWN_SPAWN] == 5.0, "town clear radius table")
	runner._assert(_SpawnResolver.CLEAR_RADIUS[_SpawnMarker.MarkerType.DUNGEON_ENTRY_SPAWN] == 3.5, "dungeon entry clear radius table")
	runner._assert(_SpawnResolver.CLEAR_RADIUS[_SpawnMarker.MarkerType.BOSS_CHECKPOINT_SPAWN] == 5.0, "boss checkpoint clear radius table")


static func _test_hud_death_text_labels(runner: Node) -> void:
	var hud := runner.get_tree().get_first_node_in_group("game_hud")
	if hud == null:
		runner._assert(true, "hud death text labels skipped without scene hud")
		return
	runner._assert(hud.has_method("hold_death_blackout"), "game hud exposes hold_death_blackout")
	runner._assert(hud.has_method("begin_death_sequence"), "game hud exposes begin_death_sequence")
