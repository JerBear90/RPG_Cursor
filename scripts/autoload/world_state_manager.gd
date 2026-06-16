extends Node
## Tracks location context, checkpoints, camps, and entry markers for death restarts.

const _RestartContext = preload("res://scripts/levels/level_restart_context.gd")
const _SpawnMarkerScript = preload("res://scripts/spawn_point.gd")

signal context_changed

var location_type: int = _RestartContext.LocationType.OUTDOOR_REGION
var region_id: StringName = &"darkpine_forest"
var town_id: StringName = &""
var dungeon_id: StringName = &""
var camp_id: StringName = &""
var checkpoint_id: StringName = &""
var waystone_id: StringName = &""
var entry_transition_id: StringName = &""
var entry_spawn_id: StringName = &""
var exterior_entrance_id: StringName = &""
var region_seed: int = 0
var last_safe_position: Vector3 = Vector3.ZERO
var dungeon_checkpoint_room: int = -1
var pending_fast_travel_id: StringName = &""
var _camp_context_locked: bool = false
var active_camp_position: Vector3 = Vector3.ZERO
var source_region_id: StringName = &""
var transition_active: bool = false
var exterior_return_active: bool = false
var last_exterior_placement: Dictionary = {}
var depleted_resource_nodes: Dictionary = {}
var destroyed_world_objects: Dictionary = {}

var _checkpoints: Dictionary = {}
var _camps: Dictionary = {}


func reset_for_new_game() -> void:
	_camp_context_locked = false
	_checkpoints.clear()
	_camps.clear()
	configure_new_game_start("darkpine_forest", "darkpine_forest")


func configure_new_game_start(region: String, town: String) -> void:
	location_type = _RestartContext.LocationType.TOWN
	region_id = StringName(region)
	town_id = StringName(town)
	dungeon_id = &""
	camp_id = &""
	checkpoint_id = &""
	waystone_id = &""
	entry_transition_id = &""
	entry_spawn_id = &""
	exterior_entrance_id = &""
	region_seed = 0
	last_safe_position = Vector3.ZERO
	dungeon_checkpoint_room = -1
	pending_fast_travel_id = &""
	active_camp_position = Vector3.ZERO
	source_region_id = &""
	transition_active = false
	exterior_return_active = false
	last_exterior_placement = {}
	depleted_resource_nodes = {}
	destroyed_world_objects = {}
	context_changed.emit()


func activate_camp(id: String, region: String, position: Vector3) -> void:
	register_camp(id, region, position)
	camp_id = StringName(id)
	active_camp_position = position
	location_type = _RestartContext.LocationType.CAMP
	_camp_context_locked = true
	context_changed.emit()


func begin_exterior_return(region: String) -> void:
	region_id = StringName(region)
	location_type = _RestartContext.LocationType.DUNGEON_EXTERIOR
	exterior_return_active = true
	context_changed.emit()


func complete_exterior_return(resolved_spawn_id: String = "", final_position: Vector3 = Vector3.ZERO, fallback_used: bool = false) -> void:
	exterior_return_active = false
	last_exterior_placement = {
		"requested_spawn_id": String(exterior_entrance_id),
		"resolved_spawn_id": resolved_spawn_id,
		"exterior_position": get_exterior_entrance_position(String(region_id)),
		"final_position": final_position,
		"fallback_used": fallback_used,
	}
	if exterior_entrance_id != &"":
		location_type = _RestartContext.LocationType.OUTDOOR_REGION
	else:
		location_type = _RestartContext.LocationType.TOWN
	context_changed.emit()


func begin_region_transition(
	source: String,
	destination: String,
	transition_id: String,
	arrival_spawn_id: String
) -> void:
	source_region_id = StringName(source)
	region_id = StringName(destination)
	set_entry_context(transition_id, arrival_spawn_id)
	context_changed.emit()


func complete_region_transition(_resolved_spawn_id: String = "") -> void:
	transition_active = false
	entry_transition_id = &""
	entry_spawn_id = &""
	source_region_id = &""
	location_type = _RestartContext.LocationType.OUTDOOR_REGION
	context_changed.emit()


func set_region(region: String, seed: int = 0) -> void:
	region_id = StringName(region)
	if seed != 0:
		region_seed = seed
	context_changed.emit()


func set_location_type(type: int) -> void:
	location_type = type
	context_changed.emit()


func register_checkpoint(id: String, region: String, position: Vector3) -> void:
	if not _checkpoints.has(region):
		_checkpoints[region] = {}
	_checkpoints[region][id] = position
	checkpoint_id = StringName(id)
	SaveManager.set_respawn_point(region, position)
	context_changed.emit()


func register_camp(id: String, region: String, position: Vector3) -> void:
	if not _camps.has(region):
		_camps[region] = {}
	_camps[region][id] = position
	camp_id = StringName(id)
	context_changed.emit()


func get_camp_position(region: String) -> Vector3:
	if active_camp_position != Vector3.ZERO and String(region_id) == region:
		return active_camp_position
	if _camps.has(region):
		var camps: Dictionary = _camps[region]
		if camp_id != &"" and camps.has(String(camp_id)):
			return camps[String(camp_id)]
		for pos in camps.values():
			return pos
	return Vector3.ZERO


func get_checkpoint_position(region: String) -> Vector3:
	return get_exterior_entrance_position(region)


func get_exterior_entrance_position(region: String) -> Vector3:
	if exterior_entrance_id != &"" and _checkpoints.has(region):
		var cps: Dictionary = _checkpoints[region]
		var ext_key := String(exterior_entrance_id)
		if cps.has(ext_key):
			return _coerce_checkpoint_vector(cps[ext_key])
	if _checkpoints.has(region):
		var cps: Dictionary = _checkpoints[region]
		if checkpoint_id != &"" and cps.has(String(checkpoint_id)):
			return _coerce_checkpoint_vector(cps[String(checkpoint_id)])
		for pos in cps.values():
			var coerced := _coerce_checkpoint_vector(pos)
			if coerced != Vector3.ZERO:
				return coerced
	if SaveManager.has_respawn_point() and SaveManager.respawn_region == region:
		return SaveManager.respawn_position
	return Vector3.ZERO


func _coerce_checkpoint_vector(value) -> Vector3:
	if value is Vector3:
		return value
	if value is Array and value.size() >= 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	if value is Dictionary and value.has("x"):
		return Vector3(float(value.x), float(value.y), float(value.z))
	return Vector3.ZERO


func _coerce_checkpoints_dict(raw: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for region_key in raw.keys():
		var region := String(region_key)
		out[region] = {}
		var region_map = raw[region_key]
		if region_map is Dictionary:
			for checkpoint_key in region_map.keys():
				out[region][String(checkpoint_key)] = _coerce_checkpoint_vector(region_map[checkpoint_key])
	return out


func set_entry_context(transition_id: String, spawn_id: String) -> void:
	entry_transition_id = StringName(transition_id)
	entry_spawn_id = StringName(spawn_id)
	location_type = _RestartContext.LocationType.REGION_TRANSITION
	transition_active = true
	context_changed.emit()


func set_exterior_entrance(id: String, region: String, position: Vector3) -> void:
	exterior_entrance_id = StringName(id)
	register_checkpoint(id, region, position)


func set_fast_travel_destination(dest_id: String) -> void:
	pending_fast_travel_id = StringName(dest_id)
	waystone_id = StringName(dest_id)
	location_type = _RestartContext.LocationType.FAST_TRAVEL_DESTINATION
	context_changed.emit()


func consume_fast_travel_destination() -> StringName:
	var id := pending_fast_travel_id
	pending_fast_travel_id = &""
	return id


func update_last_safe(player: Node3D) -> void:
	if player == null or not is_instance_valid(player):
		return
	last_safe_position = player.global_position
	_update_location_from_position(player.global_position)


func _update_location_from_position(pos: Vector3) -> void:
	if GameManager.pending_new_game_spawn:
		return
	if transition_active or exterior_return_active:
		return
	if location_type in [
		_RestartContext.LocationType.DUNGEON,
		_RestartContext.LocationType.BOSS_ARENA,
		_RestartContext.LocationType.DUNGEON_EXTERIOR,
		_RestartContext.LocationType.FAST_TRAVEL_DESTINATION,
		_RestartContext.LocationType.REGION_TRANSITION,
	]:
		return
	if _camp_context_locked or (location_type == _RestartContext.LocationType.CAMP and camp_id != &""):
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	for node in tree.get_nodes_in_group("spawn_markers"):
		if node.has_method("get_spawn_id") and node.has_method("get_facing_yaw"):
			var marker_type: int = node.get("marker_type")
			if marker_type in [_SpawnMarkerScript.MarkerType.TOWN_SPAWN, _SpawnMarkerScript.MarkerType.SETTLEMENT_SPAWN]:
				if pos.distance_to((node as Node3D).global_position) < 22.0:
					location_type = _RestartContext.LocationType.TOWN
					var town := String(node.get("town_id"))
					var region := String(node.get("region_id"))
					town_id = StringName(town if town != "" else region)
					return
	if location_type != _RestartContext.LocationType.CAMP:
		location_type = _RestartContext.LocationType.OUTDOOR_REGION


func capture_death_context(level_scene_path: String):
	var ctx = _RestartContext.new()
	ctx.level_scene_path = level_scene_path
	ctx.level_id = StringName(level_scene_path.get_file().get_basename())
	ctx.region_id = region_id
	ctx.town_id = town_id
	ctx.dungeon_id = dungeon_id
	ctx.region_seed = region_seed
	ctx.dungeon_seed = DungeonManager.seed
	ctx.checkpoint_id = checkpoint_id
	ctx.camp_id = camp_id
	ctx.waystone_id = waystone_id
	ctx.entry_transition_id = entry_transition_id
	ctx.entry_spawn_id = entry_spawn_id
	ctx.exterior_entrance_id = exterior_entrance_id
	ctx.last_safe_position = last_safe_position
	ctx.location_type = location_type
	ctx.inside_dungeon = DungeonManager.in_dungeon
	ctx.inside_town = location_type in [
		_RestartContext.LocationType.TOWN,
		_RestartContext.LocationType.SETTLEMENT,
	]
	ctx.in_boss_encounter = GameManager.in_boss_fight
	ctx.dungeon_checkpoint_room = dungeon_checkpoint_room
	if ctx.inside_dungeon:
		ctx.location_type = _RestartContext.LocationType.BOSS_ARENA if ctx.in_boss_encounter else _RestartContext.LocationType.DUNGEON
		ctx.dungeon_id = StringName(DungeonManager.dungeon_name if DungeonManager.dungeon_name != "" else "procedural_dungeon")
	return ctx


func is_resource_depleted(persistence_id: String) -> bool:
	return persistence_id != "" and bool(depleted_resource_nodes.get(persistence_id, false))


func mark_resource_depleted(persistence_id: String) -> void:
	if persistence_id == "":
		return
	depleted_resource_nodes[persistence_id] = true


func is_object_destroyed(persistence_id: String) -> bool:
	return persistence_id != "" and bool(destroyed_world_objects.get(persistence_id, false))


func mark_object_destroyed(persistence_id: String) -> void:
	if persistence_id == "":
		return
	destroyed_world_objects[persistence_id] = true


func serialize() -> Dictionary:
	return {
		"location_type": location_type,
		"region_id": String(region_id),
		"town_id": String(town_id),
		"camp_id": String(camp_id),
		"checkpoint_id": String(checkpoint_id),
		"checkpoints": _checkpoints.duplicate(true),
		"camps": _camps.duplicate(true),
		"region_seed": region_seed,
		"dungeon_checkpoint_room": dungeon_checkpoint_room,
		"depleted_resource_nodes": depleted_resource_nodes.duplicate(true),
		"destroyed_world_objects": destroyed_world_objects.duplicate(true),
	}


func deserialize(data: Dictionary) -> void:
	location_type = int(data.get("location_type", location_type))
	region_id = StringName(data.get("region_id", String(region_id)))
	town_id = StringName(data.get("town_id", ""))
	camp_id = StringName(data.get("camp_id", ""))
	checkpoint_id = StringName(data.get("checkpoint_id", ""))
	_camps = data.get("camps", {})
	_checkpoints = _coerce_checkpoints_dict(data.get("checkpoints", {}))
	region_seed = int(data.get("region_seed", 0))
	dungeon_checkpoint_room = int(data.get("dungeon_checkpoint_room", -1))
	depleted_resource_nodes = data.get("depleted_resource_nodes", {})
	destroyed_world_objects = data.get("destroyed_world_objects", {})
