extends Node3D
## Spawns players, camera, and manages level lifecycle.

@export var region_id: String = "darkpine_forest"
@export var spawn_points: Array[NodePath] = []
@export var enable_co_op: bool = false

@onready var players_container: Node3D = $Players
@onready var camera_rig: Node3D = $CameraRig

func _ready() -> void:
	GameManager.set_region(_get_region_id())
	call_deferred("_spawn_players")
	MapManager.discover_region(_get_region_id())
	if not GameManager.player_died.is_connected(_on_player_died):
		GameManager.player_died.connect(_on_player_died)
	if region_id == "hearthhold_camp":
		_unlock_pet_shelter()


func _spawn_players() -> void:
	var player_scene := GameManager.get_player_scene()
	if player_scene == null:
		push_error("LevelManager: player scene missing")
		return
	var count := GameManager.active_player_count if GameManager.game_started else 1
	for i in count:
		var player := player_scene.instantiate() as PlayerController
		player.player_index = i
		player.name = "Player%d" % (i + 1)
		players_container.add_child(player)
		var spawn_pos := Vector3.ZERO
		if i < spawn_points.size():
			var sp := get_node(spawn_points[i]) as Node3D
			spawn_pos = sp.global_position
		elif spawn_points.size() > 0:
			spawn_pos = (get_node(spawn_points[0]) as Node3D).global_position
		if i == 1:
			spawn_pos += Vector3(2, 0, 0)
		player.global_position = spawn_pos
		PetManager.try_spawn_for_player(player)


func _on_player_died(player: Node, _index: int) -> void:
	if not is_instance_valid(player):
		return
	var copper_drop := int(CurrencyManager.copper * 0.1)
	if copper_drop > 0:
		CurrencyManager.spend_copper(copper_drop)
	await get_tree().create_timer(GameManager.respawn_delay).timeout
	if not is_instance_valid(player):
		return
	_respawn_player(player)


func _respawn_player(player: Node) -> void:
	var spawn_pos := _get_respawn_position()
	player.global_position = spawn_pos
	if player.has_node("HealthComponent"):
		var health := player.get_node("HealthComponent") as HealthComponent
		health.reset_health()
	if player is PlayerController:
		(player as PlayerController).current_state = PlayerController.State.IDLE


func _get_respawn_position() -> Vector3:
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
