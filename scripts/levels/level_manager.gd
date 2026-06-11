extends Node3D
## Spawns players, camera, and manages level lifecycle.

const _TownBuilder = preload("res://scripts/levels/town_builder.gd")

@export var region_id: String = "darkpine_forest"
@export var spawn_points: Array[NodePath] = []
@export var enable_co_op: bool = false

const _SpawnHelpers = preload("res://scripts/utilities/spawn_helpers.gd")

@onready var players_container: Node3D = $Players
@onready var camera_rig: Node3D = $CameraRig

func _ready() -> void:
	GameManager.set_region(_get_region_id())
	call_deferred("_spawn_players")
	MapManager.discover_region(_get_region_id())
	_TownBuilder.spawn(self, _get_region_id())
	RegionContent.populate(self)
	call_deferred("_finish_region_setup")


func _finish_region_setup() -> void:
	RegionContent.start_region_quests(_get_region_id())
	MaskManager.sync_unlocks_from_quests()
	_play_region_music(_get_region_id())
	if not GameManager.player_died.is_connected(_on_player_died):
		GameManager.player_died.connect(_on_player_died)
	if region_id == "hearthhold_camp":
		_unlock_pet_shelter()


func _spawn_players() -> void:
	var player_scene := GameManager.get_player_scene()
	if player_scene == null:
		push_error("LevelManager: player scene missing")
		return
	await _await_world_ground()
	var default_spawn := _get_default_spawn_position()
	var count := GameManager.active_player_count if GameManager.game_started else 1
	for i in count:
		var player := player_scene.instantiate() as PlayerController
		player.player_index = i
		player.name = "Player%d" % (i + 1)
		players_container.add_child(player)
		var spawn_pos := _resolve_player_spawn_position(i, default_spawn)
		if i == 1:
			spawn_pos.x += 2.0
		spawn_pos = _SpawnHelpers.sanitize_spawn_position(spawn_pos, default_spawn)
		await _SpawnHelpers.place_player_on_ground(player, spawn_pos, get_tree())
		if i == 0:
			var saved_pos := player.global_position
			if not SaveManager.has_respawn_point():
				SaveManager.set_respawn_point(_get_region_id(), saved_pos)
			elif SaveManager.current_slot >= 0 and SaveManager.respawn_region == _get_region_id():
				SaveManager.set_respawn_point(_get_region_id(), saved_pos)
			if not GameManager.pending_player_progress.is_empty():
				PlayerProgress.apply(player, GameManager.pending_player_progress)
				GameManager.pending_player_progress = {}
			if GameManager.pending_death_message != "":
				_finalize_respawn(player, GameManager.pending_death_message)
				GameManager.pending_death_message = ""
		PetManager.try_spawn_for_player(player)
		if i == 0:
			call_deferred("_bind_hud_to_player", player)


func _bind_hud_to_player(player: Node) -> void:
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("bind_production_player"):
			hud.bind_production_player(player)


func _resolve_player_spawn_position(index: int, default_spawn: Vector3) -> Vector3:
	if GameManager.pending_respawn_active and index == 0:
		GameManager.pending_respawn_active = false
		return GameManager.pending_respawn_position
	if index == 0 and SaveManager.has_respawn_point() and SaveManager.respawn_region == _get_region_id():
		if SaveManager.current_slot >= 0:
			return SaveManager.respawn_position
	if index < spawn_points.size():
		var sp := get_node(spawn_points[index]) as Node3D
		return sp.global_position
	if spawn_points.size() > 0:
		return (get_node(spawn_points[0]) as Node3D).global_position
	return default_spawn


func _get_default_spawn_position() -> Vector3:
	if spawn_points.size() > 0:
		var sp := get_node_or_null(spawn_points[0]) as Node3D
		if sp:
			return sp.global_position
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


func _on_player_died(player: Node, _index: int) -> void:
	if not is_instance_valid(player):
		return
	var use_save_point := SaveManager.consume_water_respawn()
	var copper_drop := 0
	if not use_save_point:
		copper_drop = int(CurrencyManager.copper * 0.1)
		if copper_drop > 0:
			CurrencyManager.spend_copper(copper_drop)
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("begin_death_sequence"):
			await hud.begin_death_sequence()
	if use_save_point:
		var target_region: String = SaveManager.respawn_region
		var target_pos: Vector3 = SaveManager.respawn_position
		if target_region != _get_region_id():
			GameManager.pending_respawn_position = target_pos
			GameManager.pending_respawn_active = true
			GameManager.pending_death_message = "Drowned — returned to your last save point"
			var path := "res://scenes/levels/%s/%s.tscn" % [target_region, target_region]
			SceneTransitionManager.change_scene(path)
			return
		if is_instance_valid(player):
			_respawn_player(player, target_pos, "Drowned — returned to your last save point", false)
		return
	if not is_instance_valid(player):
		return
	_respawn_player(player, _get_respawn_position(), "Respawned — lost some coin, needs partially restored", true)


func _respawn_player(
	player: Node,
	spawn_pos: Vector3,
	toast: String,
	restore_needs: bool
) -> void:
	_finalize_respawn(player, toast, restore_needs, spawn_pos)


func _finalize_respawn(
	player: Node,
	toast: String,
	restore_needs: bool = false,
	spawn_pos: Vector3 = Vector3.INF
) -> void:
	if spawn_pos != Vector3.INF and is_instance_valid(player):
		var fallback := _get_default_spawn_position()
		spawn_pos = _SpawnHelpers.sanitize_spawn_position(spawn_pos, fallback)
		if player is CharacterBody3D:
			await _SpawnHelpers.place_player_on_ground(player as CharacterBody3D, spawn_pos, get_tree())
	if player is PlayerController:
		var pc := player as PlayerController
		pc.refresh_spawn_protection()
		pc.current_state = PlayerController.State.IDLE
		pc.velocity = Vector3.ZERO
		var lock_on := pc.get_node_or_null("LockOnController")
		if lock_on and lock_on.has_method("release_lock"):
			lock_on.release_lock()
		var combat := pc.get_node_or_null("Combat")
		if combat and combat.has_method("_cancel_attack"):
			combat._cancel_attack()
		for rig in get_tree().get_nodes_in_group("camera_rig"):
			if rig.has_method("snap_to_player"):
				rig.snap_to_player(pc)
		for hazard in get_tree().get_nodes_in_group("water_hazard"):
			if hazard.has_method("reset_player"):
				hazard.reset_player(pc)
	if player.has_node("HealthComponent"):
		var health := player.get_node("HealthComponent") as HealthComponent
		health.reset_health()
	call_deferred("_bind_hud_to_player", player)
	if restore_needs and player.has_node("SurvivalNeedsComponent"):
		var needs := player.get_node("SurvivalNeedsComponent") as SurvivalNeedsComponent
		needs.hunger = minf(needs.hunger + 25.0, needs.max_hunger)
		needs.thirst = minf(needs.thirst + 25.0, needs.max_thirst)
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("show_toast"):
			hud.show_toast(toast)
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("finish_death_sequence"):
			await hud.finish_death_sequence()


func _get_respawn_position() -> Vector3:
	if SaveManager.has_respawn_point():
		return SaveManager.respawn_position
	if WaystoneManager.discovered.has("hearthhold_camp"):
		for node in get_tree().get_nodes_in_group("spawn_points"):
			if node.has_method("get_spawn_id") and node.get_spawn_id() == "waystone_spawn":
				return node.global_position
	if spawn_points.size() > 0:
		var sp := get_node_or_null(spawn_points[0]) as Node3D
		if sp:
			return sp.global_position
	return Vector3.ZERO


func _unlock_pet_shelter() -> void:
	if BaseManager.get_station_level("pet_shelter") <= 0:
		BaseManager.station_levels["pet_shelter"] = 1
	if PetManager.has_pet("ash_hound") or BaseManager.is_station_unlocked("pet_shelter"):
		PetManager.unlock_ash_hound_from_shelter()


func _get_region_id() -> String:
	return region_id


func _play_region_music(region: String) -> void:
	match region:
		"hearthhold_camp":
			AudioManager.play_music("camp")
		"crystal_cave", "hollow_grove_shrine":
			AudioManager.play_music("explore")
		_:
			AudioManager.play_music("ambient")
