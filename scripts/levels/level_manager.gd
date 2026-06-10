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
		if GameManager.pending_respawn_active and i == 0:
			spawn_pos = GameManager.pending_respawn_position
			GameManager.pending_respawn_active = false
		elif i < spawn_points.size():
			var sp := get_node(spawn_points[i]) as Node3D
			spawn_pos = sp.global_position
		elif spawn_points.size() > 0:
			spawn_pos = (get_node(spawn_points[0]) as Node3D).global_position
		if i == 1:
			spawn_pos += Vector3(2, 0, 0)
		player.global_position = spawn_pos
		if i == 0:
			if not SaveManager.has_respawn_point():
				SaveManager.set_respawn_point(_get_region_id(), spawn_pos)
			if not GameManager.pending_player_progress.is_empty():
				PlayerProgress.apply(player, GameManager.pending_player_progress)
				GameManager.pending_player_progress = {}
			if GameManager.pending_death_message != "":
				_finalize_respawn(player, GameManager.pending_death_message)
				GameManager.pending_death_message = ""
		PetManager.try_spawn_for_player(player)


func _on_player_died(player: Node, _index: int) -> void:
	if not is_instance_valid(player):
		return
	var use_save_point := SaveManager.consume_water_respawn()
	var copper_drop := 0
	if not use_save_point:
		copper_drop = int(CurrencyManager.copper * 0.1)
		if copper_drop > 0:
			CurrencyManager.spend_copper(copper_drop)
	await get_tree().create_timer(GameManager.respawn_delay).timeout
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
		player.global_position = spawn_pos
	if player.has_node("HealthComponent"):
		var health := player.get_node("HealthComponent") as HealthComponent
		health.reset_health()
	if player is PlayerController:
		(player as PlayerController).current_state = PlayerController.State.IDLE
	if restore_needs and player.has_node("SurvivalNeedsComponent"):
		var needs := player.get_node("SurvivalNeedsComponent") as SurvivalNeedsComponent
		needs.hunger = minf(needs.hunger + 25.0, needs.max_hunger)
		needs.thirst = minf(needs.thirst + 25.0, needs.max_thirst)
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("show_toast"):
			hud.show_toast(toast)


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
