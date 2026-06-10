extends Node
## Global game state: players, co-op, combat flags, region.

signal player_spawned(player: Node, index: int)
signal player_died(player: Node, index: int)
signal region_changed(region_id: String)
signal combat_state_changed(in_combat: bool)

const MAX_PLAYERS := 2
const PLAYER_SCENE_PATH := "res://scenes/player/player.tscn"

var players: Array[Node] = []
var active_player_count: int = 1
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
var pending_respawn_position: Vector3 = Vector3.ZERO
var pending_respawn_active: bool = false
var pending_death_message: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func start_new_game(co_op: bool = false) -> void:
	active_player_count = 2 if co_op else 1
	game_started = true
	is_paused = false
	pending_player_progress = {}
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
	SaveManager.reset_respawn_point()
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


func all_players_near(position: Vector3, radius: float) -> bool:
	for p in get_alive_players():
		if p.global_position.distance_to(position) > radius:
			return false
	return not get_alive_players().is_empty()
