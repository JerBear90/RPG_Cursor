extends Node3D
## Spawns players, camera, and manages level lifecycle.

const _TownBuilder = preload("res://scripts/levels/town_builder.gd")
const _SpawnMarker = preload("res://scripts/spawn_point.gd")

@export var region_id: String = "darkpine_forest"
@export var spawn_points: Array[NodePath] = []
@export var enable_co_op: bool = false

const _SpawnHelpers = preload("res://scripts/utilities/spawn_helpers.gd")
const _SpawnResolver = preload("res://scripts/levels/spawn_resolver.gd")
const _RegionTransitionGate = preload("res://scripts/levels/region_transition_gate.gd")
const _RestartContext = preload("res://scripts/levels/level_restart_context.gd")

@onready var players_container: Node3D = $Players
@onready var camera_rig: Node3D = $CameraRig

func _ready() -> void:
	GameManager.set_region(_get_region_id())
	WorldStateManager.set_region(_get_region_id())
	MapManager.discover_region(_get_region_id())
	_TownBuilder.spawn(self, _get_region_id())
	RegionContent.populate(self)
	call_deferred("_finish_region_setup")


func _finish_region_setup() -> void:
	_register_restart_markers()
	RegionContent.start_region_quests(_get_region_id())
	MaskManager.sync_unlocks_from_quests()
	_play_region_music(_get_region_id())
	if region_id == "hearthhold_camp":
		WorldStateManager.location_type = _RestartContext.LocationType.TOWN
		WorldStateManager.town_id = &"hearthhold_camp"
	elif region_id == "ashfall_highlands":
		WorldStateManager.location_type = _RestartContext.LocationType.SETTLEMENT
		WorldStateManager.town_id = &"stonewatch"
	elif region_id == "frostgrave_expanse":
		WorldStateManager.location_type = _RestartContext.LocationType.SETTLEMENT
		WorldStateManager.town_id = &"frostwatch"
	elif region_id == "shattered_coast":
		WorldStateManager.location_type = _RestartContext.LocationType.SETTLEMENT
		WorldStateManager.town_id = &"tidewatch"
	elif region_id == "blightreach":
		WorldStateManager.location_type = _RestartContext.LocationType.SETTLEMENT
		WorldStateManager.town_id = &"lastwall"
	elif region_id == "ember_wastes":
		WorldStateManager.location_type = _RestartContext.LocationType.SETTLEMENT
		WorldStateManager.town_id = &"cinderhold"
	elif region_id == "sunless_dominion":
		WorldStateManager.location_type = _RestartContext.LocationType.SETTLEMENT
		WorldStateManager.town_id = &"dawnwatch"
	await _await_world_ground()
	if GameManager.pending_restart_context != null:
		await get_tree().create_timer(1.2).timeout
		for _i in 20:
			await get_tree().physics_frame
	elif GameManager.pending_spawn_id != "" or GameManager.pending_arrival_spawn_id != "":
		await get_tree().create_timer(0.8).timeout
		for _i in 15:
			await get_tree().physics_frame
	elif GameManager.pending_continue_spawn:
		await get_tree().create_timer(0.5).timeout
		for _i in 10:
			await get_tree().physics_frame
	await _spawn_players()


func _register_restart_markers() -> void:
	var root := get_node_or_null("SpawnPoints") as Node3D
	if root == null:
		root = Node3D.new()
		root.name = "RestartMarkers"
		add_child(root)
	match region_id:
		"darkpine_forest":
			WorldStateManager.town_id = &"darkpine_forest"
			_SpawnMarker.create_runtime(root, "region_start_darkpine_forest", _SpawnMarker.MarkerType.REGION_START_SPAWN, Vector3(0, 0.1, 0), 0.0, region_id, 6.5)
			_SpawnMarker.create_runtime(root, "new_game_start_darkpine_outpost", _SpawnMarker.MarkerType.TOWN_SPAWN, Vector3(-5, 0.1, 4), 180.0, region_id, 5.0)
			_SpawnMarker.create_runtime(root, "town_darkpine_forest", _SpawnMarker.MarkerType.TOWN_SPAWN, Vector3(-5, 0.1, 4), 180.0, region_id, 5.0)
			_SpawnMarker.create_runtime(root, "camp_darkpine_forest", _SpawnMarker.MarkerType.CAMP_SPAWN, Vector3(6.5, 0.1, -7.5), 0.0, region_id, 4.0)
			_SpawnMarker.create_runtime(root, "CampSite", _SpawnMarker.MarkerType.CAMP_SPAWN, Vector3(6.5, 0.1, -7.5), 0.0, region_id, 4.0)
			_SpawnMarker.create_runtime(root, "waystone_darkpine_forest", _SpawnMarker.MarkerType.FAST_TRAVEL_SPAWN, Vector3(-5, 0.1, 9), 180.0, region_id, 5.0)
			_SpawnMarker.create_runtime(root, "hearthhold_return_darkpine", _SpawnMarker.MarkerType.TRANSITION_ARRIVAL_SPAWN, Vector3(16, 0.1, 10), 225.0, region_id, 6.0)
			_set_marker_transition_id(root, "hearthhold_return_darkpine", "hearthhold_to_darkpine")
			_register_exterior_marker(root)
			_spawn_region_gates()
		"hearthhold_camp":
			WorldStateManager.town_id = &"hearthhold_camp"
			_SpawnMarker.create_runtime(root, "region_start_hearthhold_camp", _SpawnMarker.MarkerType.REGION_START_SPAWN, Vector3(0, 0.1, 0), 0.0, region_id, 6.0)
			_SpawnMarker.create_runtime(root, "town_hearthhold", _SpawnMarker.MarkerType.TOWN_SPAWN, Vector3(0, 0.1, 0), 0.0, region_id, 6.0)
			_SpawnMarker.create_runtime(root, "town_hearthhold_camp", _SpawnMarker.MarkerType.TOWN_SPAWN, Vector3(0, 0.1, 0), 0.0, region_id, 5.0)
			_SpawnMarker.create_runtime(root, "new_arrival_hearthhold", _SpawnMarker.MarkerType.TOWN_SPAWN, Vector3(0, 0.1, -10), 0.0, region_id, 6.0)
			_SpawnMarker.create_runtime(root, "checkpoint_hearthhold", _SpawnMarker.MarkerType.CHECKPOINT_SPAWN, Vector3(0, 0.1, 0), 0.0, region_id, 5.0)
			_SpawnMarker.create_runtime(root, "waystone_hearthhold", _SpawnMarker.MarkerType.FAST_TRAVEL_SPAWN, Vector3(-2, 0.1, 5), 180.0, region_id, 6.0)
			_SpawnMarker.create_runtime(root, "waystone_hearthhold_camp", _SpawnMarker.MarkerType.FAST_TRAVEL_SPAWN, Vector3(-2, 0.1, 5), 180.0, region_id, 5.0)
			_SpawnMarker.create_runtime(root, "darkpine_arrival_hearthhold", _SpawnMarker.MarkerType.TRANSITION_ARRIVAL_SPAWN, Vector3(0, 0.1, -11), 0.0, region_id, 6.0)
			_SpawnMarker.create_runtime(root, "rotfen_departure_hearthhold", _SpawnMarker.MarkerType.TRANSITION_ARRIVAL_SPAWN, Vector3(0, 0.1, 13), 180.0, region_id, 6.0)
			_SpawnMarker.create_runtime(root, "rotfen_return_hearthhold", _SpawnMarker.MarkerType.TRANSITION_ARRIVAL_SPAWN, Vector3(0, 0.1, -11), 0.0, region_id, 6.0)
			_set_marker_transition_id(root, "darkpine_arrival_hearthhold", "darkpine_to_hearthhold")
			_set_marker_transition_id(root, "rotfen_return_hearthhold", "rotfen_to_hearthhold")
			_spawn_region_gates()
		"rotfen_marsh":
			WorldStateManager.town_id = &""
			_SpawnMarker.create_runtime(root, "region_start_rotfen", _SpawnMarker.MarkerType.REGION_START_SPAWN, Vector3(0, 0.1, -18), 0.0, region_id, 6.5)
			_SpawnMarker.create_runtime(root, "hearthhold_arrival_rotfen", _SpawnMarker.MarkerType.TRANSITION_ARRIVAL_SPAWN, Vector3(0, 0.1, -18), 0.0, region_id, 6.0)
			_SpawnMarker.create_runtime(root, "checkpoint_rotfen", _SpawnMarker.MarkerType.CHECKPOINT_SPAWN, Vector3(-8, 0.1, 4), 0.0, region_id, 5.0)
			_SpawnMarker.create_runtime(root, "camp_marshwatch", _SpawnMarker.MarkerType.CAMP_SPAWN, Vector3(-8, 0.1, 4), 90.0, region_id, 5.0)
			_SpawnMarker.create_runtime(root, "MarshwatchCamp", _SpawnMarker.MarkerType.CAMP_SPAWN, Vector3(-8, 0.1, 4), 90.0, region_id, 5.0)
			_SpawnMarker.create_runtime(root, "waystone_rotfen", _SpawnMarker.MarkerType.FAST_TRAVEL_SPAWN, Vector3(-6, 0.1, 6), 180.0, region_id, 6.0)
			_SpawnMarker.create_runtime(root, "sunken_reliquary_exterior", _SpawnMarker.MarkerType.EXTERIOR_RETURN_SPAWN, Vector3(0, 0.1, 28), 180.0, region_id, 5.0)
			_SpawnMarker.create_runtime(root, "exterior_sunken_reliquary", _SpawnMarker.MarkerType.EXTERIOR_RETURN_SPAWN, Vector3(0, 0.1, 28), 180.0, region_id, 5.0)
			_SpawnMarker.create_runtime(root, "ashfall_departure_rotfen", _SpawnMarker.MarkerType.TRANSITION_ARRIVAL_SPAWN, Vector3(14, 0.1, 22), 225.0, region_id, 6.0)
			_SpawnMarker.create_runtime(root, "rotfen_return_hearthhold", _SpawnMarker.MarkerType.TRANSITION_ARRIVAL_SPAWN, Vector3(0, 0.1, -20), 0.0, "hearthhold_camp", 6.0)
			_set_marker_transition_id(root, "hearthhold_arrival_rotfen", "hearthhold_to_rotfen")
			_spawn_region_gates()
		"ashfall_highlands":
			WorldStateManager.town_id = &"stonewatch"
			_SpawnMarker.create_runtime(root, "region_start_ashfall", _SpawnMarker.MarkerType.REGION_START_SPAWN, Vector3(-18, 0.1, 0), 90.0, region_id, 6.5)
			_SpawnMarker.create_runtime(root, "rotfen_arrival_ashfall", _SpawnMarker.MarkerType.TRANSITION_ARRIVAL_SPAWN, Vector3(-18, 0.1, 0), 90.0, region_id, 6.0)
			_SpawnMarker.create_runtime(root, "checkpoint_ashfall", _SpawnMarker.MarkerType.CHECKPOINT_SPAWN, Vector3(0, 0.1, 2), 0.0, region_id, 5.0)
			_SpawnMarker.create_runtime(root, "camp_stonewatch", _SpawnMarker.MarkerType.CAMP_SPAWN, Vector3(0, 0.1, 2), 0.0, region_id, 5.0)
			_SpawnMarker.create_runtime(root, "town_stonewatch", _SpawnMarker.MarkerType.SETTLEMENT_SPAWN, Vector3(0, 0.1, 0), 0.0, region_id, 6.0)
			_SpawnMarker.create_runtime(root, "waystone_ashfall", _SpawnMarker.MarkerType.FAST_TRAVEL_SPAWN, Vector3(2, 0.1, 4), 180.0, region_id, 6.0)
			_SpawnMarker.create_runtime(root, "blackvein_foundry_exterior", _SpawnMarker.MarkerType.EXTERIOR_RETURN_SPAWN, Vector3(22, 0.1, 18), 225.0, region_id, 5.0)
			_SpawnMarker.create_runtime(root, "exterior_blackvein_foundry", _SpawnMarker.MarkerType.EXTERIOR_RETURN_SPAWN, Vector3(22, 0.1, 18), 225.0, region_id, 5.0)
			_SpawnMarker.create_runtime(root, "ashfall_return_rotfen", _SpawnMarker.MarkerType.TRANSITION_ARRIVAL_SPAWN, Vector3(-20, 0.1, -4), 270.0, region_id, 6.0)
			_SpawnMarker.create_runtime(root, "future_region_departure_ashfall", _SpawnMarker.MarkerType.TRANSITION_ARRIVAL_SPAWN, Vector3(30, 0.1, 0), 90.0, region_id, 6.0)
			_SpawnMarker.create_runtime(root, "frostgrave_return_ashfall", _SpawnMarker.MarkerType.TRANSITION_ARRIVAL_SPAWN, Vector3(30, 0.1, 0), 270.0, region_id, 6.0)
			_set_marker_transition_id(root, "rotfen_arrival_ashfall", "rotfen_to_ashfall")
			_set_marker_transition_id(root, "ashfall_return_rotfen", "ashfall_to_rotfen")
			_set_marker_transition_id(root, "frostgrave_return_ashfall", "frostgrave_to_ashfall")
			_spawn_region_gates()
		"frostgrave_expanse":
			WorldStateManager.town_id = &"frostwatch"
			_SpawnMarker.create_runtime(root, "region_start_frostgrave", _SpawnMarker.MarkerType.REGION_START_SPAWN, Vector3(-18, 0.1, 0), 90.0, region_id, 6.5)
			_SpawnMarker.create_runtime(root, "ashfall_arrival_frostgrave", _SpawnMarker.MarkerType.TRANSITION_ARRIVAL_SPAWN, Vector3(-18, 0.1, 0), 90.0, region_id, 6.0)
			_SpawnMarker.create_runtime(root, "checkpoint_frostgrave", _SpawnMarker.MarkerType.CHECKPOINT_SPAWN, Vector3(0, 0.1, 2), 0.0, region_id, 5.0)
			_SpawnMarker.create_runtime(root, "camp_frostwatch", _SpawnMarker.MarkerType.CAMP_SPAWN, Vector3(0, 0.1, 2), 0.0, region_id, 5.0)
			_SpawnMarker.create_runtime(root, "town_frostwatch", _SpawnMarker.MarkerType.SETTLEMENT_SPAWN, Vector3(0, 0.1, 0), 0.0, region_id, 6.0)
			_SpawnMarker.create_runtime(root, "waystone_frostgrave", _SpawnMarker.MarkerType.FAST_TRAVEL_SPAWN, Vector3(2, 0.1, 4), 180.0, region_id, 6.0)
			_SpawnMarker.create_runtime(root, "paleheart_crypt_exterior", _SpawnMarker.MarkerType.EXTERIOR_RETURN_SPAWN, Vector3(22, 0.1, 18), 225.0, region_id, 5.0)
			_SpawnMarker.create_runtime(root, "exterior_paleheart_crypt", _SpawnMarker.MarkerType.EXTERIOR_RETURN_SPAWN, Vector3(22, 0.1, 18), 225.0, region_id, 5.0)
			_SpawnMarker.create_runtime(root, "future_region_departure_frostgrave", _SpawnMarker.MarkerType.TRANSITION_ARRIVAL_SPAWN, Vector3(30, 0.1, 0), 90.0, region_id, 6.0)
			_set_marker_transition_id(root, "ashfall_arrival_frostgrave", "ashfall_to_frostgrave")
			_spawn_region_gates()
		"shattered_coast":
			WorldStateManager.town_id = &"tidewatch"
			_SpawnMarker.create_runtime(root, "region_start_shattered_coast", _SpawnMarker.MarkerType.REGION_START_SPAWN, Vector3(-18, 0.1, 0), 90.0, region_id, 6.5)
			_SpawnMarker.create_runtime(root, "frostgrave_arrival_shattered_coast", _SpawnMarker.MarkerType.TRANSITION_ARRIVAL_SPAWN, Vector3(-18, 0.1, 0), 90.0, region_id, 6.0)
			_SpawnMarker.create_runtime(root, "checkpoint_shattered_coast", _SpawnMarker.MarkerType.CHECKPOINT_SPAWN, Vector3(0, 0.1, 2), 0.0, region_id, 5.0)
			_SpawnMarker.create_runtime(root, "camp_tidewatch", _SpawnMarker.MarkerType.CAMP_SPAWN, Vector3(0, 0.1, 2), 0.0, region_id, 5.0)
			_SpawnMarker.create_runtime(root, "town_tidewatch", _SpawnMarker.MarkerType.SETTLEMENT_SPAWN, Vector3(0, 0.1, 0), 0.0, region_id, 6.0)
			_SpawnMarker.create_runtime(root, "waystone_shattered_coast", _SpawnMarker.MarkerType.FAST_TRAVEL_SPAWN, Vector3(2, 0.1, 4), 180.0, region_id, 6.0)
			_SpawnMarker.create_runtime(root, "drowned_citadel_exterior", _SpawnMarker.MarkerType.EXTERIOR_RETURN_SPAWN, Vector3(22, 0.1, 18), 225.0, region_id, 5.0)
			_SpawnMarker.create_runtime(root, "exterior_drowned_citadel", _SpawnMarker.MarkerType.EXTERIOR_RETURN_SPAWN, Vector3(22, 0.1, 18), 225.0, region_id, 5.0)
			_SpawnMarker.create_runtime(root, "shattered_coast_return_frostgrave", _SpawnMarker.MarkerType.TRANSITION_ARRIVAL_SPAWN, Vector3(-20, 0.1, -4), 270.0, region_id, 6.0)
			_SpawnMarker.create_runtime(root, "future_region_departure_shattered_coast", _SpawnMarker.MarkerType.TRANSITION_ARRIVAL_SPAWN, Vector3(30, 0.1, 0), 90.0, region_id, 6.0)
			_set_marker_transition_id(root, "frostgrave_arrival_shattered_coast", "frostgrave_to_shattered_coast")
			_set_marker_transition_id(root, "shattered_coast_return_frostgrave", "shattered_coast_to_frostgrave")
			_register_exterior_marker(root)
			_spawn_region_gates()
		"blightreach":
			WorldStateManager.town_id = &"lastwall"
			_SpawnMarker.create_runtime(root, "region_start_blightreach", _SpawnMarker.MarkerType.REGION_START_SPAWN, Vector3(-18, 0.1, 0), 90.0, region_id, 6.5)
			_SpawnMarker.create_runtime(root, "shattered_coast_arrival_blightreach", _SpawnMarker.MarkerType.TRANSITION_ARRIVAL_SPAWN, Vector3(-18, 0.1, 0), 90.0, region_id, 6.0)
			_SpawnMarker.create_runtime(root, "checkpoint_blightreach", _SpawnMarker.MarkerType.CHECKPOINT_SPAWN, Vector3(0, 0.1, 2), 0.0, region_id, 5.0)
			_SpawnMarker.create_runtime(root, "camp_lastwall", _SpawnMarker.MarkerType.CAMP_SPAWN, Vector3(0, 0.1, 2), 0.0, region_id, 5.0)
			_SpawnMarker.create_runtime(root, "town_lastwall", _SpawnMarker.MarkerType.SETTLEMENT_SPAWN, Vector3(0, 0.1, 0), 0.0, region_id, 6.0)
			_SpawnMarker.create_runtime(root, "waystone_blightreach", _SpawnMarker.MarkerType.FAST_TRAVEL_SPAWN, Vector3(2, 0.1, 4), 180.0, region_id, 6.0)
			_SpawnMarker.create_runtime(root, "blightspire_cathedral_exterior", _SpawnMarker.MarkerType.EXTERIOR_RETURN_SPAWN, Vector3(22, 0.1, 18), 225.0, region_id, 5.0)
			_SpawnMarker.create_runtime(root, "exterior_blightspire_cathedral", _SpawnMarker.MarkerType.EXTERIOR_RETURN_SPAWN, Vector3(22, 0.1, 18), 225.0, region_id, 5.0)
			_SpawnMarker.create_runtime(root, "blightreach_return_shattered_coast", _SpawnMarker.MarkerType.TRANSITION_ARRIVAL_SPAWN, Vector3(-20, 0.1, -4), 270.0, region_id, 6.0)
			_SpawnMarker.create_runtime(root, "future_region_departure_blightreach", _SpawnMarker.MarkerType.TRANSITION_ARRIVAL_SPAWN, Vector3(30, 0.1, 0), 90.0, region_id, 6.0)
			_set_marker_transition_id(root, "shattered_coast_arrival_blightreach", "shattered_coast_to_blightreach")
			_set_marker_transition_id(root, "blightreach_return_shattered_coast", "blightreach_to_shattered_coast")
			_register_exterior_marker(root)
			_spawn_region_gates()
		"ember_wastes":
			WorldStateManager.town_id = &"cinderhold"
			_SpawnMarker.create_runtime(root, "region_start_ember_wastes", _SpawnMarker.MarkerType.REGION_START_SPAWN, Vector3(-18, 0.1, 0), 90.0, region_id, 6.5)
			_SpawnMarker.create_runtime(root, "blightreach_arrival_ember_wastes", _SpawnMarker.MarkerType.TRANSITION_ARRIVAL_SPAWN, Vector3(-18, 0.1, 0), 90.0, region_id, 6.0)
			_SpawnMarker.create_runtime(root, "checkpoint_ember_wastes", _SpawnMarker.MarkerType.CHECKPOINT_SPAWN, Vector3(0, 0.1, 2), 0.0, region_id, 5.0)
			_SpawnMarker.create_runtime(root, "camp_cinderhold", _SpawnMarker.MarkerType.CAMP_SPAWN, Vector3(0, 0.1, 2), 0.0, region_id, 5.0)
			_SpawnMarker.create_runtime(root, "town_cinderhold", _SpawnMarker.MarkerType.SETTLEMENT_SPAWN, Vector3(0, 0.1, 0), 0.0, region_id, 6.0)
			_SpawnMarker.create_runtime(root, "waystone_ember_wastes", _SpawnMarker.MarkerType.FAST_TRAVEL_SPAWN, Vector3(2, 0.1, 4), 180.0, region_id, 6.0)
			_SpawnMarker.create_runtime(root, "pyreheart_ziggurat_exterior", _SpawnMarker.MarkerType.EXTERIOR_RETURN_SPAWN, Vector3(22, 0.1, 18), 225.0, region_id, 5.0)
			_SpawnMarker.create_runtime(root, "exterior_pyreheart_ziggurat", _SpawnMarker.MarkerType.EXTERIOR_RETURN_SPAWN, Vector3(22, 0.1, 18), 225.0, region_id, 5.0)
			_SpawnMarker.create_runtime(root, "ember_wastes_return_blightreach", _SpawnMarker.MarkerType.TRANSITION_ARRIVAL_SPAWN, Vector3(-20, 0.1, -4), 270.0, region_id, 6.0)
			_SpawnMarker.create_runtime(root, "future_region_departure_ember_wastes", _SpawnMarker.MarkerType.TRANSITION_ARRIVAL_SPAWN, Vector3(30, 0.1, 0), 90.0, region_id, 6.0)
			_set_marker_transition_id(root, "blightreach_arrival_ember_wastes", "blightreach_to_ember_wastes")
			_set_marker_transition_id(root, "ember_wastes_return_blightreach", "ember_wastes_to_blightreach")
			_register_exterior_marker(root)
			_spawn_region_gates()
		"sunless_dominion":
			WorldStateManager.town_id = &"dawnwatch"
			_SpawnMarker.create_runtime(root, "region_start_sunless_dominion", _SpawnMarker.MarkerType.REGION_START_SPAWN, Vector3(-18, 0.1, 0), 90.0, region_id, 6.5)
			_SpawnMarker.create_runtime(root, "ember_wastes_arrival_sunless_dominion", _SpawnMarker.MarkerType.TRANSITION_ARRIVAL_SPAWN, Vector3(-18, 0.1, 0), 90.0, region_id, 6.0)
			_SpawnMarker.create_runtime(root, "checkpoint_sunless_dominion", _SpawnMarker.MarkerType.CHECKPOINT_SPAWN, Vector3(0, 0.1, 2), 0.0, region_id, 5.0)
			_SpawnMarker.create_runtime(root, "camp_dawnwatch", _SpawnMarker.MarkerType.CAMP_SPAWN, Vector3(0, 0.1, 2), 0.0, region_id, 5.0)
			_SpawnMarker.create_runtime(root, "town_dawnwatch", _SpawnMarker.MarkerType.SETTLEMENT_SPAWN, Vector3(0, 0.1, 0), 0.0, region_id, 6.0)
			_SpawnMarker.create_runtime(root, "waystone_sunless_dominion", _SpawnMarker.MarkerType.FAST_TRAVEL_SPAWN, Vector3(2, 0.1, 4), 180.0, region_id, 6.0)
			_SpawnMarker.create_runtime(root, "eclipse_sanctum_exterior", _SpawnMarker.MarkerType.EXTERIOR_RETURN_SPAWN, Vector3(22, 0.1, 18), 225.0, region_id, 5.0)
			_SpawnMarker.create_runtime(root, "exterior_eclipse_sanctum", _SpawnMarker.MarkerType.EXTERIOR_RETURN_SPAWN, Vector3(22, 0.1, 18), 225.0, region_id, 5.0)
			_SpawnMarker.create_runtime(root, "sunless_dominion_return_ember_wastes", _SpawnMarker.MarkerType.TRANSITION_ARRIVAL_SPAWN, Vector3(-20, 0.1, -4), 270.0, region_id, 6.0)
			_SpawnMarker.create_runtime(root, "future_region_departure_sunless_dominion", _SpawnMarker.MarkerType.TRANSITION_ARRIVAL_SPAWN, Vector3(30, 0.1, 0), 90.0, region_id, 6.0)
			_set_marker_transition_id(root, "ember_wastes_arrival_sunless_dominion", "ember_wastes_to_sunless_dominion")
			_set_marker_transition_id(root, "sunless_dominion_return_ember_wastes", "sunless_dominion_to_ember_wastes")
			_register_exterior_marker(root)
			_spawn_region_gates()


func _register_exterior_marker(root: Node3D) -> void:
	var ext_id := String(WorldStateManager.exterior_entrance_id)
	if ext_id == "" and GameManager.pending_spawn_id != "":
		ext_id = GameManager.pending_spawn_id
	if ext_id == "":
		return
	var ext_pos := WorldStateManager.get_exterior_entrance_position(region_id)
	if ext_pos == Vector3.ZERO and DungeonManager.return_position != Vector3.ZERO:
		ext_pos = DungeonManager.return_position
	if ext_pos == Vector3.ZERO:
		return
	_SpawnMarker.create_runtime(root, ext_id, _SpawnMarker.MarkerType.EXTERIOR_RETURN_SPAWN, ext_pos, 180.0, region_id, 4.0)


func _spawn_region_gates() -> void:
	var interactables := get_node_or_null("Interactables") as Node3D
	if interactables == null:
		interactables = Node3D.new()
		interactables.name = "Interactables"
		add_child(interactables)
	match region_id:
		"darkpine_forest":
			_add_region_gate(
				interactables,
				Vector3(18, 0.1, 12),
				"darkpine_to_hearthhold",
				"darkpine_forest",
				"hearthhold_camp",
				"darkpine_arrival_hearthhold",
				"Travel to Hearthhold"
			)
		"hearthhold_camp":
			_add_region_gate(
				interactables,
				Vector3(0, 0.1, -14),
				"hearthhold_to_darkpine",
				"hearthhold_camp",
				"darkpine_forest",
				"hearthhold_return_darkpine",
				"Return to Darkpine Forest"
			)
			_add_region_gate(
				interactables,
				Vector3(0, 0.1, 14.5),
				"hearthhold_to_rotfen",
				"hearthhold_camp",
				"rotfen_marsh",
				"hearthhold_arrival_rotfen",
				"Travel to Rotfen Marsh",
				"res://scenes/levels/rotfen_marsh/rotfen_marsh.tscn",
				"the_rot_below",
				"completed",
				"The Rotfen route is still sealed.\nSpeak with Captain Voss."
			)
		"rotfen_marsh":
			_add_region_gate(
				interactables,
				Vector3(0, 0.1, -20),
				"rotfen_to_hearthhold",
				"rotfen_marsh",
				"hearthhold_camp",
				"rotfen_return_hearthhold",
				"Return to Hearthhold",
				"res://scenes/levels/hearthhold_camp/hearthhold_camp.tscn"
			)
			_add_region_gate(
				interactables,
				Vector3(14, 0.1, 22),
				"rotfen_to_ashfall",
				"rotfen_marsh",
				"ashfall_highlands",
				"rotfen_arrival_ashfall",
				"Travel to Ashfall Highlands",
				"res://scenes/levels/ashfall_highlands/ashfall_highlands.tscn",
				"depths_of_reliquary",
				"completed",
				"The Ashfall pass remains sealed.\nObtain the Marsh Sigil from the Sunken Reliquary."
			)
		"ashfall_highlands":
			_add_region_gate(
				interactables,
				Vector3(-20, 0.1, -4),
				"ashfall_to_rotfen",
				"ashfall_highlands",
				"rotfen_marsh",
				"ashfall_return_rotfen",
				"Return to Rotfen Marsh",
				"res://scenes/levels/rotfen_marsh/rotfen_marsh.tscn"
			)
			_add_region_gate(
				interactables,
				Vector3(30, 0.1, 0),
				"ashfall_to_frostgrave",
				"ashfall_highlands",
				"frostgrave_expanse",
				"ashfall_arrival_frostgrave",
				"Travel to Frostgrave Expanse",
				"res://scenes/levels/frostgrave_expanse/frostgrave_expanse.tscn",
				"heart_of_blackvein",
				"completed",
				"The mountain pass is sealed.\nComplete the Heart of Blackvein quest first."
			)
		"frostgrave_expanse":
			_add_region_gate(
				interactables,
				Vector3(-18, 0.1, 0),
				"frostgrave_to_ashfall",
				"frostgrave_expanse",
				"ashfall_highlands",
				"frostgrave_return_ashfall",
				"Return to Ashfall Highlands",
				"res://scenes/levels/ashfall_highlands/ashfall_highlands.tscn"
			)
			_add_region_gate(
				interactables,
				Vector3(30, 0.1, 0),
				"frostgrave_to_shattered_coast",
				"frostgrave_expanse",
				"shattered_coast",
				"frostgrave_arrival_shattered_coast",
				"Travel to The Shattered Coast",
				"res://scenes/levels/shattered_coast/shattered_coast.tscn",
				"the_pale_heart",
				"completed",
				"The coastal road is sealed.\nComplete The Pale Heart and claim the Paleheart Relic."
			)
		"shattered_coast":
			_add_region_gate(
				interactables,
				Vector3(-20, 0.1, -4),
				"shattered_coast_to_frostgrave",
				"shattered_coast",
				"frostgrave_expanse",
				"shattered_coast_return_frostgrave",
				"Return to Frostgrave Expanse",
				"res://scenes/levels/frostgrave_expanse/frostgrave_expanse.tscn"
			)
			_add_region_gate(
				interactables,
				Vector3(30, 0.1, 0),
				"shattered_coast_to_blightreach",
				"shattered_coast",
				"blightreach",
				"shattered_coast_arrival_blightreach",
				"Travel to Blightreach",
				"res://scenes/levels/blightreach/blightreach.tscn",
				"the_sunken_crown",
				"completed",
				"The inland route is sealed.\nComplete The Sunken Crown and claim the Tidebound Crown."
			)
		"blightreach":
			_add_region_gate(
				interactables,
				Vector3(-20, 0.1, -4),
				"blightreach_to_shattered_coast",
				"blightreach",
				"shattered_coast",
				"blightreach_return_shattered_coast",
				"Return to The Shattered Coast",
				"res://scenes/levels/shattered_coast/shattered_coast.tscn"
			)
			_add_region_gate(
				interactables,
				Vector3(30, 0.1, 0),
				"blightreach_to_ember_wastes",
				"blightreach",
				"ember_wastes",
				"blightreach_arrival_ember_wastes",
				"Travel to The Ember Wastes",
				"res://scenes/levels/ember_wastes/ember_wastes.tscn",
				"heart_of_the_blight",
				"completed",
				"The Ember Wastes route is sealed.\nComplete Heart of the Blight and claim the Ember Wastes Pass."
			)
		"ember_wastes":
			_add_region_gate(
				interactables,
				Vector3(-20, 0.1, -4),
				"ember_wastes_to_blightreach",
				"ember_wastes",
				"blightreach",
				"ember_wastes_return_blightreach",
				"Return to Blightreach",
				"res://scenes/levels/blightreach/blightreach.tscn"
			)
			_add_region_gate(
				interactables,
				Vector3(30, 0.1, 0),
				"ember_wastes_to_sunless_dominion",
				"ember_wastes",
				"sunless_dominion",
				"ember_wastes_arrival_sunless_dominion",
				"Travel to the Sunless Dominion",
				"res://scenes/levels/sunless_dominion/sunless_dominion.tscn",
				"heart_of_the_wastes",
				"completed",
				"The buried road remains sealed by the Solar Heart.\nComplete Heart of the Wastes and claim the Sunless Dominion Pass."
			)
		"sunless_dominion":
			_add_region_gate(
				interactables,
				Vector3(-20, 0.1, -4),
				"sunless_dominion_to_ember_wastes",
				"sunless_dominion",
				"ember_wastes",
				"sunless_dominion_return_ember_wastes",
				"Return to the Ember Wastes",
				"res://scenes/levels/ember_wastes/ember_wastes.tscn"
			)


func _add_region_gate(
	parent: Node3D,
	pos: Vector3,
	transition_id: String,
	source: String,
	destination: String,
	arrival_spawn_id: String,
	prompt: String,
	dest_scene: String = "",
	required_quest: String = "",
	required_quest_state: String = "completed",
	locked_message: String = ""
) -> void:
	var gate := _RegionTransitionGate.new()
	gate.name = "Gate_%s" % transition_id
	gate.transition_id = transition_id
	gate.source_region_id = source
	gate.destination_region_id = destination
	gate.destination_spawn_id = arrival_spawn_id
	gate.prompt_override = prompt
	if dest_scene != "":
		gate.destination_scene_path = dest_scene
	if required_quest != "":
		gate.required_quest_id = required_quest
		gate.required_quest_state = required_quest_state
		gate.locked_message = locked_message
	gate.position = pos
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(3.0, 2.5, 3.0)
	col.shape = shape
	gate.add_child(col)
	parent.add_child(gate)


func _spawn_players() -> void:
	var player_scene := GameManager.get_player_scene()
	if player_scene == null:
		push_error("LevelManager: player scene missing")
		return
	await _await_world_ground()
	var default_spawn := _get_default_spawn_position()
	var count := GameManager.active_player_count if GameManager.game_started else 1
	var leader: PlayerController = null
	for i in count:
		var player := player_scene.instantiate() as PlayerController
		player.player_index = i
		player.name = "Player%d" % (i + 1)
		players_container.add_child(player)
		var spawn_pos := _resolve_player_spawn_position(i, default_spawn)
		spawn_pos = _SpawnHelpers.sanitize_spawn_position(spawn_pos, default_spawn)
		GameManager.spawn_placement_in_progress = true
		var placed := false
		var placement_report: Dictionary = {}
		if i == 0:
			if _needs_context_spawn():
				placement_report = await _spawn_player_at_context_marker(player)
				placed = not placement_report.is_empty()
				if not placed and GameManager.pending_spawn_id != "":
					await get_tree().create_timer(0.5).timeout
					for _f in 10:
						await get_tree().physics_frame
					placement_report = await _spawn_player_at_context_marker(player)
					placed = not placement_report.is_empty()
				if not placed and GameManager.pending_arrival_spawn_id != "":
					await get_tree().create_timer(0.5).timeout
					for _f in 10:
						await get_tree().physics_frame
					placement_report = await _spawn_player_at_context_marker(player)
					placed = not placement_report.is_empty()
			if not placed and GameManager.pending_spawn_id != "":
				var ext_pos := WorldStateManager.get_exterior_entrance_position(_get_region_id())
				if ext_pos == Vector3.ZERO:
					ext_pos = DungeonManager.return_position
				if ext_pos != Vector3.ZERO:
					placed = await _SpawnHelpers.place_player_on_ground(player, ext_pos, get_tree())
					if placed:
						placement_report = {
							"spawn_id": GameManager.pending_spawn_id,
							"position": ext_pos,
							"final_position": player.global_position,
							"grounded": player.is_on_floor(),
							"fallback_used": true,
						}
			if not placed and GameManager.pending_continue_spawn:
				var save_pos := SaveManager.respawn_position if SaveManager.has_respawn_point() else spawn_pos
				placed = await _SpawnHelpers.place_player_on_ground(player, save_pos, get_tree())
				if placed:
					placement_report = {
						"spawn_id": "save_point",
						"position": save_pos,
						"final_position": player.global_position,
						"grounded": player.is_on_floor(),
						"fallback_used": false,
					}
			var block_generic_fallback := (
				GameManager.pending_spawn_id != ""
				or GameManager.pending_arrival_spawn_id != ""
				or GameManager.pending_continue_spawn
			)
			if not placed and not block_generic_fallback:
				placed = await _SpawnHelpers.place_player_on_ground(player, spawn_pos, get_tree())
				if placed:
					placement_report = {
						"spawn_id": _nearest_spawn_id(player.global_position),
						"requested_position": spawn_pos,
						"final_position": player.global_position,
						"grounded": player.is_on_floor(),
						"fallback_used": true,
					}
		elif leader != null:
			var offset := _SpawnHelpers.get_party_offset(i, leader.rotation.y)
			var companion_pos := leader.global_position + offset
			if GameManager.pending_continue_spawn and i < GameManager.pending_coop_positions.size():
				var pos_arr: Array = GameManager.pending_coop_positions[i]
				if pos_arr.size() >= 3:
					companion_pos = Vector3(pos_arr[0], pos_arr[1], pos_arr[2])
			placed = await _SpawnHelpers.place_player_safely_on_ground(player, companion_pos, get_tree())
			if placed:
				player.rotation.y = leader.rotation.y
		else:
			placed = await _SpawnHelpers.place_player_on_ground(player, spawn_pos, get_tree())
		GameManager.spawn_placement_in_progress = false
		if i == 0:
			if GameManager.pending_restart_context != null:
				var ctx = GameManager.pending_restart_context
				await LevelRestartService.finalize_player_restart(
					player,
					ctx.restore_needs,
					ctx.death_message
				)
			elif GameManager.pending_spawn_id != "":
				if placed:
					var resolved_id := String(placement_report.get("spawn_id", GameManager.pending_spawn_id))
					var used_fallback := resolved_id != GameManager.pending_spawn_id
					WorldStateManager.complete_exterior_return(resolved_id, player.global_position, used_fallback)
					GameManager.pending_spawn_id = ""
					GameManager.death_input_locked = false
					_record_placement_report(placement_report, WorldStateManager.location_type)
				else:
					push_error("LevelManager: exterior return placement failed for %s" % GameManager.pending_spawn_id)
					GameManager.death_input_locked = false
			elif GameManager.pending_arrival_spawn_id != "":
				if placed:
					RegionTransitionManager.complete_arrival(
						player,
						String(placement_report.get("spawn_id", GameManager.pending_arrival_spawn_id))
					)
					_record_placement_report(placement_report, _RestartContext.LocationType.REGION_TRANSITION)
				else:
					var arrival_marker: Node3D = _find_spawn_marker(GameManager.pending_arrival_spawn_id)
					if arrival_marker:
						placed = await _SpawnHelpers.place_player_on_ground(player, arrival_marker.global_position, get_tree())
						if placed:
							placement_report = {
								"spawn_id": GameManager.pending_arrival_spawn_id,
								"position": arrival_marker.global_position,
								"final_position": player.global_position,
								"grounded": player.is_on_floor(),
								"fallback_used": true,
							}
							RegionTransitionManager.complete_arrival(player, GameManager.pending_arrival_spawn_id)
							_record_placement_report(placement_report, _RestartContext.LocationType.REGION_TRANSITION)
						else:
							RegionTransitionManager.cancel_transition()
					else:
						RegionTransitionManager.cancel_transition()
			elif GameManager.pending_continue_spawn:
				GameManager.pending_continue_spawn = false
				GameManager.death_input_locked = false
				if placed:
					if placement_report.is_empty():
						placement_report = {
							"spawn_id": "save_point",
							"position": SaveManager.respawn_position,
							"final_position": player.global_position,
							"grounded": player.is_on_floor(),
							"fallback_used": false,
						}
					_record_placement_report(placement_report, WorldStateManager.location_type)
				var hud := get_tree().get_first_node_in_group("game_hud")
				if hud and hud.has_method("_fade_from_black"):
					await hud._fade_from_black(0.35)
			elif _is_new_game_start() or GameManager.pending_new_game_spawn:
				GameManager.pending_new_game_spawn = false
				WorldStateManager.location_type = _RestartContext.LocationType.TOWN
				WorldStateManager.town_id = &"darkpine_forest"
				SaveManager.set_respawn_point(_get_region_id(), player.global_position)
			elif not SaveManager.has_respawn_point():
				SaveManager.set_respawn_point(_get_region_id(), player.global_position)
			elif SaveManager.current_slot >= 0 and SaveManager.respawn_region == _get_region_id():
				SaveManager.set_respawn_point(_get_region_id(), player.global_position)
			if i < GameManager.pending_coop_player_progress.size():
				var prog: Variant = GameManager.pending_coop_player_progress[i]
				if prog is Dictionary:
					PlayerProgress.apply(player, prog)
			elif i == 0 and not GameManager.pending_player_progress.is_empty():
				PlayerProgress.apply(player, GameManager.pending_player_progress)
			if i == GameManager.active_player_count - 1:
				GameManager.pending_coop_player_progress = []
				GameManager.pending_coop_positions = []
				GameManager.pending_player_progress = {}
				if GameManager.is_local_coop():
					GameManager.refresh_coop_camera()
		PetManager.try_spawn_for_player(player)
		if i == 0:
			leader = player
			call_deferred("_bind_hud_to_player", player)
	if leader:
		call_deferred("_notify_vertical_slice_ready")


func _bind_hud_to_player(player: Node) -> void:
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("bind_production_player"):
			hud.bind_production_player(player)


func _notify_vertical_slice_ready() -> void:
	VerticalSliceFlow.on_level_players_ready()


func _resolve_player_spawn_position(index: int, default_spawn: Vector3) -> Vector3:
	if GameManager.pending_arrival_spawn_id != "" and index == 0:
		var arrival: Node3D = _find_spawn_marker(GameManager.pending_arrival_spawn_id)
		if arrival:
			return arrival.global_position
	if GameManager.pending_continue_spawn and index == 0:
		if SaveManager.has_respawn_point():
			return SaveManager.respawn_position
	if GameManager.pending_spawn_id != "" and index == 0:
		var marker: Node3D = _find_spawn_marker(GameManager.pending_spawn_id)
		if marker:
			return marker.global_position
	if (_is_new_game_start() or GameManager.pending_new_game_spawn) and index == 0:
		var town_marker: Node3D = _find_spawn_marker("new_game_start_darkpine_outpost")
		if town_marker:
			return town_marker.global_position
		town_marker = _find_spawn_marker("town_%s" % _get_region_id())
		if town_marker:
			return town_marker.global_position
	if GameManager.pending_respawn_active and index == 0:
		GameManager.pending_respawn_active = false
		return GameManager.pending_respawn_position
	if index == 0 and SaveManager.has_respawn_point() and SaveManager.respawn_region == _get_region_id():
		if SaveManager.current_slot >= 0 and GameManager.pending_restart_context == null and not GameManager.pending_continue_spawn:
			return SaveManager.respawn_position
	if index < spawn_points.size():
		var sp := get_node(spawn_points[index]) as Node3D
		return sp.global_position
	if spawn_points.size() > 0:
		return (get_node(spawn_points[0]) as Node3D).global_position
	return default_spawn


func _is_new_game_start() -> bool:
	return (
		GameManager.pending_new_game_spawn
		or (
			GameManager.game_started
			and SaveManager.current_slot < 0
			and GameManager.pending_restart_context == null
			and WorldStateManager.location_type == _RestartContext.LocationType.TOWN
			and GameManager.pending_spawn_id == ""
		)
	)


func _needs_context_spawn() -> bool:
	return (
		_is_new_game_start()
		or GameManager.pending_spawn_id != ""
		or GameManager.pending_arrival_spawn_id != ""
		or GameManager.pending_continue_spawn
	)


func _spawn_player_at_context_marker(player: PlayerController) -> Dictionary:
	var ctx = _RestartContext.new()
	ctx.region_id = StringName(_get_region_id())
	if _is_new_game_start():
		ctx.town_id = WorldStateManager.town_id
		ctx.location_type = _RestartContext.LocationType.TOWN
		ctx.inside_town = true
		ctx.preferred_spawn_ids = PackedStringArray(["new_game_start_darkpine_outpost", "town_%s" % _get_region_id()])
	elif GameManager.pending_spawn_id != "":
		ctx.exterior_entrance_id = StringName(GameManager.pending_spawn_id)
		ctx.location_type = _RestartContext.LocationType.DUNGEON_EXTERIOR
		ctx.town_id = WorldStateManager.town_id
		ctx.preferred_spawn_ids = PackedStringArray([GameManager.pending_spawn_id])
	elif GameManager.pending_arrival_spawn_id != "":
		ctx.entry_spawn_id = StringName(GameManager.pending_arrival_spawn_id)
		ctx.entry_transition_id = WorldStateManager.entry_transition_id
		ctx.location_type = _RestartContext.LocationType.REGION_TRANSITION
		ctx.preferred_spawn_ids = PackedStringArray([GameManager.pending_arrival_spawn_id])
	elif GameManager.pending_continue_spawn:
		var save_pos := SaveManager.respawn_position if SaveManager.has_respawn_point() else Vector3.ZERO
		if save_pos == Vector3.ZERO:
			return {}
		var placed_save := await _SpawnHelpers.place_player_safely_on_ground(player, save_pos, get_tree())
		if not placed_save:
			return {}
		return {
			"spawn_id": "save_point",
			"position": save_pos,
			"final_position": player.global_position,
			"grounded": player.is_on_floor(),
			"location_type": WorldStateManager.location_type,
		}
	else:
		return {}
	var result := await _SpawnResolver.resolve_and_place(ctx, player, get_tree())
	if result.is_empty():
		return {}
	result["final_position"] = player.global_position
	result["grounded"] = player.is_on_floor()
	result["location_type"] = ctx.location_type
	return result


func _set_marker_transition_id(root: Node3D, marker_id: String, transition_id: String) -> void:
	var marker := root.get_node_or_null(marker_id)
	if marker:
		marker.set("transition_id", transition_id)


func _record_placement_report(result: Dictionary, location_type: int) -> void:
	GameManager.last_placement_report = {
		"spawn_id": String(result.get("spawn_id", "")),
		"requested_position": result.get("position", Vector3.ZERO),
		"final_position": result.get("final_position", Vector3.ZERO),
		"grounded": bool(result.get("grounded", false)),
		"location_type": location_type,
		"fallback_used": bool(result.get("fallback_used", false)),
	}


func _nearest_spawn_id(pos: Vector3) -> String:
	var best_id := ""
	var best_dist := INF
	for node in get_tree().get_nodes_in_group("spawn_markers"):
		if not node.has_method("get_spawn_id"):
			continue
		var d: float = pos.distance_to((node as Node3D).global_position)
		if d < best_dist:
			best_dist = d
			best_id = node.get_spawn_id()
	return best_id


func _find_spawn_marker(spawn_id: String) -> Node3D:
	for node in get_tree().get_nodes_in_group("spawn_markers"):
		if node.has_method("get_spawn_id") and node.get_spawn_id() == spawn_id:
			return node as Node3D
	return null


func _get_default_spawn_position() -> Vector3:
	if spawn_points.size() > 0:
		var sp := get_node_or_null(spawn_points[0]) as Node3D
		if sp:
			return sp.global_position
	for node in get_tree().get_nodes_in_group("spawn_markers"):
		if node.has_method("get_spawn_id") and String(node.get("spawn_id")).begins_with("region_start"):
			return node.global_position
	return Vector3(0.0, 0.1, 0.0)


func _await_world_ground() -> void:
	var terrain := _find_island_terrain()
	if terrain and terrain.has_signal("ground_ready"):
		if terrain.has_method("is_ground_ready") and terrain.is_ground_ready():
			await get_tree().physics_frame
			return
		await terrain.ground_ready
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame


func _find_island_terrain() -> Node:
	for node in get_tree().get_nodes_in_group("island_terrain"):
		return node
	var env := get_node_or_null("Environment")
	if env:
		return env.get_node_or_null("IslandTerrain")
	return null


func _get_region_id() -> String:
	return region_id


func _play_region_music(region: String) -> void:
	match region:
		"hearthhold_camp":
			AudioManager.play_music("camp")
		"rotfen_marsh":
			AudioManager.play_music("explore")
		"ashfall_highlands":
			AudioManager.play_music("explore")
		"frostgrave_expanse":
			AudioManager.play_music("frostwatch_ambience")
		"shattered_coast":
			AudioManager.play_music("coastal_storm_ambience")
		"blightreach":
			AudioManager.play_music("blightreach_ambience")
		"ember_wastes":
			AudioManager.play_music("ember_wastes_ambience")
		"sunless_dominion":
			AudioManager.play_music("sunless_dominion_ambience")
		"crystal_cave", "hollow_grove_shrine":
			AudioManager.play_music("explore")
		_:
			AudioManager.play_music("ambient")
