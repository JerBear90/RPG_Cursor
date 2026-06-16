extends Node
## Global game state: players, co-op, combat flags, region.

signal player_spawned(player: Node, index: int)
signal player_died(player: Node, index: int)
signal region_changed(region_id: String)
signal combat_state_changed(in_combat: bool)

const MAX_PLAYERS := 2
const PLAYER_SCENE_PATH := "res://scenes/player/player.tscn"
const _SpawnHelpers := preload("res://scripts/utilities/spawn_helpers.gd")

enum CoopMode { SINGLE_PLAYER, LOCAL_COOP_TWO_PLAYER }

var players: Array[Node] = []
var active_player_count: int = 1
var coop_mode: CoopMode = CoopMode.SINGLE_PLAYER
var interacting_player_index: int = 0
var menu_owner_index: int = 0
var current_region_id: String = "darkpine_forest"
var in_combat: bool = false
var in_boss_fight: bool = false
var is_paused: bool = false
var game_started: bool = false
var respawn_delay: float = 2.5

var player_data: Array[Dictionary] = [
	{"name": "Exile One", "class_id": "survivor", "body_preset": 0},
	{"name": "Exile Two", "class_id": "survivor", "body_preset": 1},
]
var pending_player_progress: Dictionary = {}
var pending_coop_player_progress: Array = []
var pending_coop_positions: Array = []
var pending_restart_context = null
var pending_respawn_position: Vector3 = Vector3.ZERO
var pending_respawn_active: bool = false
var pending_death_message: String = ""
var death_input_locked: bool = false
var spawn_placement_in_progress: bool = false
var pending_spawn_id: String = ""
var pending_arrival_spawn_id: String = ""
var pending_new_game_spawn: bool = false
var pending_continue_spawn: bool = false
var last_placement_report: Dictionary = {}

# Field revive HUD state (co-op gameplay layer)
var coop_player_prompts: Array[String] = ["", ""]
var coop_revive_active: bool = false
var coop_revive_reviver_index: int = -1
var coop_revive_target_index: int = -1
var coop_revive_progress: float = 0.0

const FIELD_REVIVE_HP_RATIO := 0.35
const FIELD_REVIVE_HOLD_SEC := 2.0
const FIELD_REVIVE_RANGE := 2.25


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func start_new_game(co_op: bool = false) -> void:
	active_player_count = 2 if co_op else 1
	coop_mode = CoopMode.LOCAL_COOP_TWO_PLAYER if co_op else CoopMode.SINGLE_PLAYER
	game_started = true
	is_paused = false
	pending_player_progress = {}
	pending_coop_player_progress = []
	pending_coop_positions = []
	pending_restart_context = null
	pending_respawn_position = Vector3.ZERO
	pending_respawn_active = false
	pending_death_message = ""
	death_input_locked = false
	spawn_placement_in_progress = false
	pending_spawn_id = ""
	pending_arrival_spawn_id = ""
	pending_continue_spawn = false
	last_placement_report = {}
	pending_new_game_spawn = true
	SaveManager.current_slot = -1
	SaveManager.reset_load_metadata()
	InventoryManager.reset_for_new_game()
	CurrencyManager.reset_for_new_game()
	QuestManager.reset_for_new_game()
	MapManager.reset_for_new_game()
	BaseManager.reset_for_new_game()
	WaystoneManager.reset_for_new_game()
	AchievementManager.reset_for_new_game()
	PetManager.reset_for_new_game()
	MaskManager.reset_for_new_game()
	DungeonManager.reset_for_new_game()
	ReliquaryState.reset_for_new_game()
	FoundryState.reset_for_new_game()
	CryptState.reset_for_new_game()
	CitadelState.reset_for_new_game()
	CathedralState.reset_for_new_game()
	PyreheartState.reset_for_new_game()
	SaveManager.reset_respawn_point()
	WorldStateManager.reset_for_new_game()
	NpcStateManager.reset_for_new_game()
	TutorialPromptManager.reset_for_new_game()
	VerticalSliceFlow.reset_for_new_game()
	SceneTransitionManager.change_scene("res://scenes/levels/darkpine_forest/darkpine_forest.tscn")
	call_deferred("_ensure_unpaused")
	AudioManager.play_music("ambient")


func _ensure_unpaused() -> void:
	is_paused = false
	if get_tree():
		get_tree().paused = false


func continue_game(slot: int = 0) -> bool:
	if not SaveManager.load_game(slot):
		return false
	game_started = true
	is_paused = false
	pending_respawn_position = Vector3.ZERO
	pending_respawn_active = false
	pending_death_message = ""
	pending_arrival_spawn_id = ""
	pending_continue_spawn = true
	last_placement_report = {}
	var region := current_region_id
	var path := "res://scenes/levels/%s/%s.tscn" % [region, region]
	SceneTransitionManager.change_scene(path)
	call_deferred("_ensure_unpaused")
	return true


func clear_players() -> void:
	players.clear()


func register_player(player: Node, index: int) -> void:
	while players.size() <= index:
		players.append(null)
	players[index] = player
	player_spawned.emit(player, index)


func unregister_player(player: Node) -> void:
	var idx := players.find(player)
	if idx >= 0:
		players[idx] = null


func get_player(index: int = 0) -> Node:
	if index < players.size():
		return players[index]
	return null


func get_alive_players() -> Array[Node]:
	var alive: Array[Node] = []
	for p in players:
		if p and is_instance_valid(p) and p.has_method("is_alive") and p.is_alive():
			alive.append(p)
	return alive


func get_all_registered_players() -> Array[Node]:
	var registered: Array[Node] = []
	for p in players:
		if p and is_instance_valid(p):
			registered.append(p)
	return registered


func is_local_coop() -> bool:
	return coop_mode == CoopMode.LOCAL_COOP_TWO_PLAYER and active_player_count > 1


func are_all_players_dead() -> bool:
	var registered := get_all_registered_players()
	if registered.is_empty():
		return false
	for p in registered:
		if p.has_method("is_alive") and p.is_alive():
			return false
	return true


func get_nearest_living_player(world_pos: Vector3) -> Node:
	var best: Node = null
	var best_dist := INF
	for p in get_alive_players():
		if p is Node3D:
			var d: float = (p as Node3D).global_position.distance_to(world_pos)
			if d < best_dist:
				best_dist = d
				best = p
	return best if best else get_player(0)


func get_interacting_player() -> Node:
	return get_player(interacting_player_index)


func revive_player(player: Node, health_ratio: float = 0.45) -> void:
	if not is_instance_valid(player):
		return
	if player is PlayerController:
		var pc := player as PlayerController
		pc.current_state = PlayerController.State.IDLE
		pc.velocity = Vector3.ZERO
		pc.refresh_spawn_protection()
	if player.has_node("HealthComponent"):
		var health := player.get_node("HealthComponent") as HealthComponent
		health.reset_health()
		health.heal(health.max_health * health_ratio)
	if player.has_node("Combat") and player.get_node("Combat").has_method("force_release_combat_state"):
		player.get_node("Combat").force_release_combat_state()


func revive_all_dead_players(health_ratio: float = 0.45) -> void:
	for p in get_all_registered_players():
		if p.has_method("is_alive") and not p.is_alive():
			revive_player(p, health_ratio)


func set_coop_player_prompt(player_index: int, text: String) -> void:
	while coop_player_prompts.size() <= player_index:
		coop_player_prompts.append("")
	coop_player_prompts[player_index] = text


func get_coop_player_prompt(player_index: int) -> String:
	if player_index < 0 or player_index >= coop_player_prompts.size():
		return ""
	return coop_player_prompts[player_index]


func set_field_revive(reviver_index: int, target_index: int, progress: float, active: bool) -> void:
	coop_revive_active = active
	coop_revive_reviver_index = reviver_index
	coop_revive_target_index = target_index
	coop_revive_progress = progress


func get_downed_players() -> Array[Node]:
	var downed: Array[Node] = []
	for p in get_all_registered_players():
		if p.has_method("is_alive") and not p.is_alive():
			downed.append(p)
	return downed


func is_player_downed(player: Node) -> bool:
	return is_instance_valid(player) and player.has_method("is_alive") and not player.is_alive()


func set_combat_state(active: bool) -> void:
	if in_combat == active:
		return
	in_combat = active
	combat_state_changed.emit(active)


func set_region(region_id: String) -> void:
	current_region_id = region_id
	region_changed.emit(region_id)
	MapManager.discover_region(region_id)


func pause_game() -> void:
	is_paused = true
	get_tree().paused = true


func unpause_game() -> void:
	is_paused = false
	get_tree().paused = false


func get_player_scene() -> PackedScene:
	return load(PLAYER_SCENE_PATH) as PackedScene


const COOP_CAMP_RADIUS := 5.0
const COOP_TRAVEL_RADIUS := 8.0


func living_players_near(position: Vector3, radius: float) -> bool:
	var living := get_alive_players()
	if living.is_empty():
		return false
	for p in living:
		if p is Node3D and (p as Node3D).global_position.distance_to(position) > radius:
			return false
	return true


func pull_distant_companions(anchor: Vector3, leader_yaw: float, max_dist: float = COOP_TRAVEL_RADIUS) -> void:
	if not is_local_coop():
		return
	for i in range(1, active_player_count):
		var companion := get_player(i)
		if companion == null or not is_instance_valid(companion) or not companion is Node3D:
			continue
		if companion.has_method("is_alive") and not companion.is_alive():
			continue
		if (companion as Node3D).global_position.distance_to(anchor) <= max_dist:
			continue
		var offset := _SpawnHelpers.get_party_offset(i, leader_yaw)
		(companion as Node3D).global_position = anchor + offset
		if companion is CharacterBody3D:
			(companion as CharacterBody3D).velocity = Vector3.ZERO
		companion.rotation.y = leader_yaw


func get_distant_living_player_indices(anchor: Vector3, max_dist: float = COOP_TRAVEL_RADIUS) -> Array[int]:
	var out: Array[int] = []
	if not is_local_coop():
		return out
	for i in range(active_player_count):
		var p := get_player(i)
		if p == null or not is_instance_valid(p) or not p is Node3D:
			continue
		if p.has_method("is_alive") and not p.is_alive():
			continue
		if (p as Node3D).global_position.distance_to(anchor) > max_dist:
			out.append(i)
	return out


func refresh_coop_camera() -> void:
	if not is_local_coop():
		return
	var tree := get_tree()
	if tree == null:
		return
	for rig in tree.get_nodes_in_group("camera_rig"):
		if rig.has_method("detach_from_player"):
			rig.detach_from_player()
		if rig.has_method("_refresh_attachment"):
			rig.call_deferred("_refresh_attachment")


func all_players_near(position: Vector3, radius: float) -> bool:
	for p in get_alive_players():
		if p.global_position.distance_to(position) > radius:
			return false
	return not get_alive_players().is_empty()
