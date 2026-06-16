class_name SpawnResolver
extends RefCounted
## Resolves context-specific restart markers with safe-ground placement.

const _SpawnHelpers = preload("res://scripts/utilities/spawn_helpers.gd")
const _SpawnMarker = preload("res://scripts/spawn_point.gd")
const _RestartContext = preload("res://scripts/levels/level_restart_context.gd")

const CLEAR_RADIUS := {
	_SpawnMarker.MarkerType.TOWN_SPAWN: 5.0,
	_SpawnMarker.MarkerType.SETTLEMENT_SPAWN: 5.0,
	_SpawnMarker.MarkerType.REGION_START_SPAWN: 6.5,
	_SpawnMarker.MarkerType.CAMP_SPAWN: 4.0,
	_SpawnMarker.MarkerType.CHECKPOINT_SPAWN: 4.0,
	_SpawnMarker.MarkerType.DUNGEON_ENTRY_SPAWN: 3.5,
	_SpawnMarker.MarkerType.DUNGEON_CHECKPOINT_SPAWN: 4.0,
	_SpawnMarker.MarkerType.DUNGEON_EXIT_SPAWN: 4.0,
	_SpawnMarker.MarkerType.EXTERIOR_RETURN_SPAWN: 4.0,
	_SpawnMarker.MarkerType.BOSS_CHECKPOINT_SPAWN: 5.0,
	_SpawnMarker.MarkerType.FAST_TRAVEL_SPAWN: 5.0,
	_SpawnMarker.MarkerType.TRANSITION_ARRIVAL_SPAWN: 5.0,
	_SpawnMarker.MarkerType.PLAYER_SPAWN: 4.0,
}


static func resolve(context, tree: SceneTree) -> Dictionary:
	var candidates := _collect_candidates(context, tree)
	if candidates.is_empty():
		push_error("SpawnResolver: no valid restart marker for region %s" % context.region_id)
		return {}
	return candidates[0]


static func resolve_and_place(context, player: CharacterBody3D, tree: SceneTree) -> Dictionary:
	if player == null or not is_instance_valid(player):
		return {}
	var candidates := _collect_candidates(context, tree)
	for attempt in 2:
		if not is_instance_valid(player):
			return {}
		await _await_world_ground(tree)
		for result in candidates:
			if not is_instance_valid(player):
				return {}
			if await place_player_at_result(player, result, tree):
				result["placement_ok"] = true
				return result
		await tree.create_timer(0.2).timeout
	if candidates.is_empty():
		return {}
	var fallback: Dictionary = candidates[0]
	if await _place_player_loose(player, fallback, tree):
		fallback["placement_ok"] = true
		return fallback
	return {}


static func _place_player_loose(player: CharacterBody3D, result: Dictionary, tree: SceneTree) -> bool:
	if player == null or result.is_empty():
		return false
	var pos: Vector3 = result.get("position", Vector3.ZERO)
	if pos == Vector3.ZERO:
		return false
	await tree.physics_frame
	await tree.physics_frame
	var world := player.get_world_3d()
	if world == null:
		return false
	var candidates := _SpawnHelpers._build_fallback_candidates(pos)
	var feet := _SpawnHelpers.get_feet_offset(player)
	for candidate in candidates:
		var hit := _SpawnHelpers._raycast_ground(world, candidate, player.get_rid())
		if hit.is_empty():
			continue
		var ground_normal: Vector3 = hit.normal
		if ground_normal.dot(Vector3.UP) < _SpawnHelpers.MIN_WALKABLE_GROUND_DOT:
			continue
		var ground_y: float = hit.position.y
		if ground_y > 3.0 and pos.y < 2.0:
			continue
		var target := Vector3(candidate.x, ground_y - feet + _SpawnHelpers.GROUND_LIFT, candidate.z)
		player.global_position = target
		player.velocity = Vector3.ZERO
		if result.has("rotation_y"):
			player.rotation.y = float(result.rotation_y)
		for _attempt in 10:
			await tree.physics_frame
			player.velocity = Vector3.ZERO
			player.move_and_slide()
			if player.is_on_floor() and player.global_position.y < 3.5:
				return true
			ground_y = _SpawnHelpers.query_ground_at_xz(world, player.global_position, player.get_rid())
			player.global_position = Vector3(
				player.global_position.x,
				ground_y - feet + _SpawnHelpers.GROUND_LIFT,
				player.global_position.z
			)
	return false


static func _collect_candidates(context, tree: SceneTree) -> Array:
	var results: Array = []
	var seen: Dictionary = {}
	if context.preferred_spawn_ids.has("save_point") and SaveManager.has_respawn_point():
		results.append({
			"spawn_id": "save_point",
			"position": SaveManager.respawn_position,
			"rotation_y": 0.0,
			"clear_radius": 5.0,
		})
	var spawn_ids := _build_priority_list(context)
	for spawn_id in spawn_ids:
		if seen.has(spawn_id):
			continue
		seen[spawn_id] = true
		var marker = _find_marker(tree, spawn_id)
		if marker != null:
			results.append(_marker_result(marker, spawn_id))
			continue
		var world_pos = _world_state_position(spawn_id, context)
		if world_pos != Vector3.ZERO:
			results.append({
				"spawn_id": spawn_id,
				"position": world_pos,
				"rotation_y": 0.0,
				"clear_radius": 4.0,
			})
	if context.last_safe_position != Vector3.ZERO and context.location_type == _RestartContext.LocationType.OUTDOOR_REGION:
		results.append({
			"spawn_id": "last_safe_position",
			"position": context.last_safe_position,
			"rotation_y": 0.0,
			"clear_radius": 4.0,
		})
	if _restricts_generic_fallback(context):
		return results
	var fallback = _find_marker(tree, "region_start") \
		or _find_marker(tree, "default") \
		or _first_level_spawn(tree)
	if fallback != null and fallback is Node3D:
		var sid = fallback.get_spawn_id() if fallback.has_method("get_spawn_id") else "default"
		results.append(_marker_result(fallback as Node3D, sid))
	return results


static func place_player_at_result(
	player: CharacterBody3D,
	result: Dictionary,
	tree: SceneTree
) -> bool:
	if player == null or result.is_empty():
		return false
	var pos: Vector3 = result.get("position", Vector3.ZERO)
	if pos == Vector3.ZERO and not result.has("position"):
		push_error("SpawnResolver: refusing Vector3.ZERO placement")
		return false
	var placed := await _SpawnHelpers.place_player_safely_on_ground(player, pos, tree)
	if placed and result.has("rotation_y"):
		player.rotation.y = float(result.rotation_y)
	return placed


static func _build_priority_list(context) -> PackedStringArray:
	var ids: PackedStringArray = PackedStringArray()
	for id in context.preferred_spawn_ids:
		if id != "" and id not in ids:
			ids.append(id)
	match context.location_type:
		_RestartContext.LocationType.BOSS_ARENA:
			_append_unique(ids, "preboss_abandoned_mine")
			_append_unique(ids, "preboss_%s" % context.dungeon_id)
			_append_unique(ids, "boss_checkpoint_%s" % context.dungeon_id)
			_append_unique(ids, "boss_checkpoint_procedural_dungeon")
			if context.dungeon_id == "sunken_reliquary":
				_append_unique(ids, "preboss_sunken_reliquary")
				_append_unique(ids, "dungeon_checkpoint_sunken_reliquary")
				_append_unique(ids, "dungeon_spawn_sunken_reliquary")
			if context.dungeon_id == "blackvein_foundry":
				_append_unique(ids, "preboss_blackvein_foundry")
				_append_unique(ids, "dungeon_checkpoint_blackvein_foundry")
				_append_unique(ids, "dungeon_spawn_blackvein_foundry")
			if context.dungeon_id == "paleheart_crypt":
				_append_unique(ids, "preboss_paleheart_crypt")
				_append_unique(ids, "dungeon_checkpoint_paleheart_crypt")
				_append_unique(ids, "dungeon_spawn_paleheart_crypt")
			if context.dungeon_id == "drowned_citadel":
				_append_unique(ids, "preboss_drowned_citadel")
				_append_unique(ids, "dungeon_checkpoint_drowned_citadel")
				_append_unique(ids, "dungeon_spawn_drowned_citadel")
			if context.dungeon_id == "blightspire_cathedral":
				_append_unique(ids, "preboss_blightspire_cathedral")
				_append_unique(ids, "dungeon_checkpoint_blightspire_cathedral")
				_append_unique(ids, "dungeon_spawn_blightspire_cathedral")
			if context.dungeon_id == "pyreheart_ziggurat":
				_append_unique(ids, "preboss_pyreheart_ziggurat")
				_append_unique(ids, "dungeon_checkpoint_pyreheart_ziggurat")
				_append_unique(ids, "dungeon_spawn_pyreheart_ziggurat")
			if context.dungeon_id == "eclipse_sanctum":
				_append_unique(ids, "preboss_eclipse_sanctum")
				_append_unique(ids, "dungeon_checkpoint_eclipse_sanctum")
				_append_unique(ids, "dungeon_spawn_eclipse_sanctum")
			if context.dungeon_checkpoint_room >= 0:
				_append_unique(ids, "dungeon_checkpoint_room_%d" % context.dungeon_checkpoint_room)
			_append_unique(ids, "dungeon_entry_%s" % context.dungeon_id)
			_append_unique(ids, "dungeon_spawn")
		_RestartContext.LocationType.DUNGEON:
			if context.checkpoint_id != &"":
				_append_unique(ids, String(context.checkpoint_id))
			if context.dungeon_id == "sunken_reliquary":
				_append_unique(ids, "dungeon_checkpoint_sunken_reliquary")
				_append_unique(ids, "dungeon_spawn_sunken_reliquary")
			if context.dungeon_id == "blackvein_foundry":
				_append_unique(ids, "dungeon_checkpoint_blackvein_foundry")
				_append_unique(ids, "dungeon_spawn_blackvein_foundry")
			if context.dungeon_id == "paleheart_crypt":
				_append_unique(ids, "dungeon_checkpoint_paleheart_crypt")
				_append_unique(ids, "dungeon_spawn_paleheart_crypt")
			if context.dungeon_id == "drowned_citadel":
				_append_unique(ids, "dungeon_checkpoint_drowned_citadel")
				_append_unique(ids, "dungeon_spawn_drowned_citadel")
			if context.dungeon_id == "blightspire_cathedral":
				_append_unique(ids, "dungeon_checkpoint_blightspire_cathedral")
				_append_unique(ids, "dungeon_spawn_blightspire_cathedral")
			if context.dungeon_id == "pyreheart_ziggurat":
				_append_unique(ids, "dungeon_checkpoint_pyreheart_ziggurat")
				_append_unique(ids, "dungeon_spawn_pyreheart_ziggurat")
			if context.dungeon_id == "eclipse_sanctum":
				_append_unique(ids, "dungeon_checkpoint_eclipse_sanctum")
				_append_unique(ids, "dungeon_spawn_eclipse_sanctum")
			if context.dungeon_checkpoint_room >= 0:
				_append_unique(ids, "dungeon_checkpoint_room_%d" % context.dungeon_checkpoint_room)
			_append_unique(ids, "dungeon_entry_%s" % context.dungeon_id)
			_append_unique(ids, "dungeon_spawn")
		_RestartContext.LocationType.CAMP:
			if context.camp_id != &"":
				_append_unique(ids, String(context.camp_id))
			_append_unique(ids, "camp_%s" % context.region_id)
			if context.town_id != &"":
				_append_unique(ids, "town_%s" % context.town_id)
			_append_unique(ids, "region_start_%s" % context.region_id)
		_RestartContext.LocationType.DUNGEON_EXTERIOR:
			if context.exterior_entrance_id != &"":
				_append_unique(ids, String(context.exterior_entrance_id))
			if context.town_id != &"":
				_append_unique(ids, "town_%s" % context.town_id)
			_append_unique(ids, "region_start_%s" % context.region_id)
		_RestartContext.LocationType.TOWN, _RestartContext.LocationType.SETTLEMENT:
			if context.checkpoint_id != &"":
				_append_unique(ids, String(context.checkpoint_id))
			if context.town_id != &"":
				_append_unique(ids, "town_%s" % context.town_id)
				_append_unique(ids, "town_spawn_%s" % context.town_id)
			_append_unique(ids, "town_%s" % context.region_id)
		_RestartContext.LocationType.FAST_TRAVEL_DESTINATION:
			if context.waystone_id != &"":
				_append_unique(ids, "waystone_%s" % context.waystone_id)
			_append_unique(ids, "waystone_spawn")
		_RestartContext.LocationType.REGION_TRANSITION:
			if context.entry_spawn_id != &"":
				_append_unique(ids, String(context.entry_spawn_id))
			if context.entry_transition_id != &"":
				_append_unique(ids, "transition_%s" % context.entry_transition_id)
		_:
			if context.checkpoint_id != &"":
				_append_unique(ids, String(context.checkpoint_id))
			if context.camp_id != &"":
				_append_unique(ids, String(context.camp_id))
				_append_unique(ids, "camp_%s" % context.region_id)
			if context.town_id != &"" and (
				context.inside_town
				or context.location_type in [
					_RestartContext.LocationType.TOWN,
					_RestartContext.LocationType.SETTLEMENT,
				]
			):
				_append_unique(ids, "town_%s" % context.town_id)
			_append_unique(ids, "region_start_%s" % context.region_id)
			_append_unique(ids, "region_start")
	if context.exterior_entrance_id != &"" and context.location_type != _RestartContext.LocationType.DUNGEON_EXTERIOR:
		_append_unique(ids, String(context.exterior_entrance_id))
	if not _restricts_generic_fallback(context):
		_append_unique(ids, "region_start_%s" % context.region_id)
		_append_unique(ids, "region_start")
		_append_unique(ids, "default")
	return ids


static func _restricts_generic_fallback(context) -> bool:
	return context.location_type in [
		_RestartContext.LocationType.DUNGEON_EXTERIOR,
		_RestartContext.LocationType.REGION_TRANSITION,
		_RestartContext.LocationType.FAST_TRAVEL_DESTINATION,
		_RestartContext.LocationType.BOSS_ARENA,
		_RestartContext.LocationType.DUNGEON,
	]


static func _append_unique(ids: PackedStringArray, value: String) -> void:
	if value != "" and value not in ids:
		ids.append(value)


static func _world_state_position(spawn_id: String, context) -> Vector3:
	var region := String(context.region_id)
	if spawn_id == String(context.exterior_entrance_id):
		var ext := WorldStateManager.get_checkpoint_position(region)
		if ext != Vector3.ZERO:
			return ext
	if spawn_id == String(context.checkpoint_id) or spawn_id.begins_with("checkpoint") or spawn_id.begins_with("exterior_"):
		var cp := WorldStateManager.get_checkpoint_position(region)
		if cp != Vector3.ZERO:
			return cp
	if spawn_id == String(context.camp_id) or spawn_id.begins_with("camp_"):
		var camp := WorldStateManager.get_camp_position(region)
		if camp != Vector3.ZERO:
			return camp
	return Vector3.ZERO


static func _find_marker(tree: SceneTree, spawn_id: String):
	if spawn_id == "":
		return null
	for node in tree.get_nodes_in_group("spawn_markers"):
		if node.has_method("get_spawn_id") and node.get_spawn_id() == spawn_id:
			return node
	for node in tree.get_nodes_in_group("spawn_points"):
		if node.has_method("get_spawn_id") and node.get_spawn_id() == spawn_id:
			return node
	return null


static func _first_level_spawn(tree: SceneTree):
	for node in tree.get_nodes_in_group("spawn_markers"):
		if node.has_method("get_spawn_id"):
			return node
	for node in tree.get_nodes_in_group("spawn_points"):
		if node.has_method("get_spawn_id"):
			return node
	return null


static func _marker_result(marker: Node3D, spawn_id: String) -> Dictionary:
	return {
		"spawn_id": spawn_id,
		"position": marker.global_position,
		"rotation_y": marker.get_facing_yaw(),
		"clear_radius": marker.get_clear_radius(),
	}


static func _await_world_ground(tree: SceneTree) -> void:
	if tree == null:
		return
	for node in tree.get_nodes_in_group("dungeon_builder"):
		if node.has_method("is_build_complete"):
			if node.is_build_complete():
				await tree.physics_frame
				await tree.physics_frame
				return
			var deadline := Time.get_ticks_msec() + 12000
			while not node.is_build_complete() and Time.get_ticks_msec() < deadline:
				await tree.process_frame
			await tree.physics_frame
			await tree.physics_frame
			return
	var terrain: Node = null
	for node in tree.get_nodes_in_group("island_terrain"):
		terrain = node
		break
	if terrain == null and tree.current_scene:
		var env := tree.current_scene.get_node_or_null("Level/Environment")
		if env:
			terrain = env.get_node_or_null("IslandTerrain")
	if terrain and terrain.has_signal("ground_ready"):
		if terrain.has_method("is_ground_ready") and terrain.is_ground_ready():
			await tree.physics_frame
			return
		await terrain.ground_ready
	await tree.physics_frame
	await tree.physics_frame
	await tree.physics_frame
