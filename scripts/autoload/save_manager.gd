extends Node
## Save/load with 3 slots via JSON.

const _SpawnHelpers = preload("res://scripts/utilities/spawn_helpers.gd")

signal save_completed(slot: int)
signal load_completed(slot: int)

const SAVE_DIR := "user://saves/"
const MAX_SLOTS := 3

var current_slot: int = -1
var respawn_region: String = "darkpine_forest"
var respawn_position: Vector3 = Vector3.ZERO
var _respawn_initialized: bool = false
var pending_water_respawn: bool = false


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func save_game(slot: int) -> bool:
	if slot < 0 or slot >= MAX_SLOTS:
		return false
	var player := GameManager.get_player(0)
	if player:
		set_respawn_point(GameManager.current_region_id, player.global_position)
	var data := _collect_save_data()
	var path := SAVE_DIR + "slot_%d.json" % slot
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: cannot write %s" % path)
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	current_slot = slot
	save_completed.emit(slot)
	return true


func load_game(slot: int) -> bool:
	var path := SAVE_DIR + "slot_%d.json" % slot
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return false
	_apply_save_data(json.data)
	current_slot = slot
	load_completed.emit(slot)
	return true


func has_save(slot: int) -> bool:
	return FileAccess.file_exists(SAVE_DIR + "slot_%d.json" % slot)


func get_save_preview(slot: int) -> Dictionary:
	var path := SAVE_DIR + "slot_%d.json" % slot
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return {}
	var data: Dictionary = json.data
	var region: String = str(data.get("region", "unknown")).replace("_", " ").capitalize()
	var ts: int = int(data.get("timestamp", 0))
	return {
		"region": region,
		"timestamp": ts,
		"co_op": bool(data.get("co_op", false)),
	}


func set_respawn_point(region: String, position: Vector3) -> void:
	respawn_region = region
	var world := _get_active_world()
	var ground_y := _SpawnHelpers.query_ground_at_xz(world, position)
	if not _SpawnHelpers.is_saved_position_plausible(position, ground_y):
		position = Vector3(position.x, ground_y, position.z)
	respawn_position = position
	_respawn_initialized = true


func _get_active_world() -> World3D:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	for node in tree.get_nodes_in_group("player"):
		if node is Node3D:
			return (node as Node3D).get_world_3d()
	var root := tree.current_scene
	if root is Node3D:
		return (root as Node3D).get_world_3d()
	return null


func has_respawn_point() -> bool:
	return _respawn_initialized


func mark_water_death() -> void:
	pending_water_respawn = true


func consume_water_respawn() -> bool:
	var use_save := pending_water_respawn
	pending_water_respawn = false
	return use_save


func reset_respawn_point() -> void:
	respawn_region = "darkpine_forest"
	respawn_position = Vector3.ZERO
	_respawn_initialized = false
	pending_water_respawn = false


func _collect_save_data() -> Dictionary:
	var player_progress := {}
	var player := GameManager.get_player(0)
	if player:
		player_progress = PlayerProgress.collect(player)
	return {
		"version": 2,
		"timestamp": Time.get_unix_time_from_system(),
		"region": GameManager.current_region_id,
		"respawn_region": respawn_region,
		"respawn_position": [respawn_position.x, respawn_position.y, respawn_position.z],
		"players": GameManager.player_data,
		"player_progress": player_progress,
		"inventory": InventoryManager.serialize(),
		"currency": CurrencyManager.serialize(),
		"quests": QuestManager.serialize(),
		"map": MapManager.serialize(),
		"base": BaseManager.serialize(),
		"waystones": WaystoneManager.serialize(),
		"achievements": AchievementManager.serialize(),
		"pets": PetManager.serialize(),
		"masks": MaskManager.serialize(),
		"dungeon": DungeonManager.serialize(),
		"co_op": GameManager.active_player_count > 1,
		"settings": SettingsManager.serialize(),
	}


func _apply_save_data(data: Dictionary) -> void:
	if data.has("region"):
		GameManager.current_region_id = data.region
	if data.has("respawn_region") and data.has("respawn_position"):
		var pos_arr: Array = data.respawn_position
		if pos_arr.size() >= 3:
			var loaded := Vector3(pos_arr[0], pos_arr[1], pos_arr[2])
			set_respawn_point(data.respawn_region, loaded)
	if data.has("players"):
		GameManager.player_data = data.players
	if data.has("inventory"):
		InventoryManager.deserialize(data.inventory)
	if data.has("currency"):
		CurrencyManager.deserialize(data.currency)
	if data.has("quests"):
		QuestManager.deserialize(data.quests)
	if data.has("map"):
		MapManager.deserialize(data.map)
	if data.has("base"):
		BaseManager.deserialize(data.base)
	if data.has("waystones"):
		WaystoneManager.deserialize(data.waystones)
	if data.has("achievements"):
		AchievementManager.deserialize(data.achievements)
	if data.has("pets"):
		PetManager.deserialize(data.pets)
	if data.has("masks"):
		MaskManager.deserialize(data.masks)
	if data.has("dungeon"):
		DungeonManager.deserialize(data.dungeon)
	if data.has("player_progress"):
		GameManager.pending_player_progress = data.player_progress
	if data.has("co_op"):
		GameManager.active_player_count = 2 if data.co_op else 1
