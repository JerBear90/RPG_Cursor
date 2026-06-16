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
var last_loaded_version: int = 3
var last_load_used_p2_fallback: bool = false
var _last_milestone_autosave_ms: int = 0
const _MILESTONE_AUTOSAVE_MS := 3000


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func save_game(slot: int) -> bool:
	if slot < 0 or slot >= MAX_SLOTS:
		return false
	var positions: Array = []
	var progress_all: Array = []
	for i in GameManager.active_player_count:
		var p := GameManager.get_player(i)
		if p is Node3D:
			var pos := (p as Node3D).global_position
			positions.append([pos.x, pos.y, pos.z])
		if p:
			progress_all.append(PlayerProgress.collect(p))
	if not positions.is_empty():
		var p0 := GameManager.get_player(0)
		if p0 is Node3D:
			set_respawn_point(GameManager.current_region_id, (p0 as Node3D).global_position)
	var data := _collect_save_data(positions, progress_all)
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
	var co_op := bool(data.get("co_op", false))
	var p1_level := _preview_level_from_progress(data, 0)
	var p2_level_known: bool = co_op and data.has("player_progress_all") \
			and typeof(data.player_progress_all) == TYPE_ARRAY \
			and data.player_progress_all.size() > 1
	var p2_level := _preview_level_from_progress(data, 1) if co_op else 0
	return {
		"region": region,
		"timestamp": ts,
		"co_op": co_op,
		"save_version": int(data.get("version", 2)),
		"p1_level": p1_level,
		"p2_level": p2_level,
		"p2_level_known": p2_level_known,
		"players": 2 if co_op else 1,
	}


func _preview_level_from_progress(data: Dictionary, index: int) -> int:
	if data.has("player_progress_all"):
		var all: Array = data.player_progress_all
		if index < all.size() and typeof(all[index]) == TYPE_DICTIONARY:
			return _level_from_progress(all[index])
	if index == 0 and data.has("player_progress"):
		return _level_from_progress(data.player_progress)
	return 1 if index == 0 else 0


func _level_from_progress(prog: Dictionary) -> int:
	if prog.has("stats") and typeof(prog.stats) == TYPE_DICTIONARY:
		return int(prog.stats.get("level", 1))
	return 1


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


func try_milestone_autosave(_reason: String = "") -> void:
	if not GameManager.game_started:
		return
	if GameManager.spawn_placement_in_progress:
		return
	if RegionTransitionManager.is_transition_in_progress():
		return
	if GameManager.in_combat or GameManager.in_boss_fight:
		return
	var now := Time.get_ticks_msec()
	if now - _last_milestone_autosave_ms < _MILESTONE_AUTOSAVE_MS:
		return
	_last_milestone_autosave_ms = now
	var slot := current_slot if current_slot >= 0 else 0
	save_game(slot)


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


func _collect_save_data(positions: Array = [], progress_all: Array = []) -> Dictionary:
	var player_progress := {}
	var player := GameManager.get_player(0)
	if player:
		player_progress = PlayerProgress.collect(player)
	if progress_all.is_empty() and player:
		progress_all = [player_progress]
	return {
		"version": 3,
		"timestamp": Time.get_unix_time_from_system(),
		"region": GameManager.current_region_id,
		"respawn_region": respawn_region,
		"respawn_position": [respawn_position.x, respawn_position.y, respawn_position.z],
		"player_positions": positions,
		"player_progress_all": progress_all,
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
		"reliquary": ReliquaryState.serialize(),
		"foundry": FoundryState.serialize(),
		"crypt": CryptState.serialize(),
		"citadel": CitadelState.serialize(),
		"cathedral": CathedralState.serialize(),
		"pyreheart": PyreheartState.serialize(),
		"eclipse_sanctum": EclipseSanctumState.serialize(),
		"merchants": MerchantManager.serialize(),
		"npc_states": NpcStateManager.serialize(),
		"world_state": WorldStateManager.serialize(),
		"tutorial": TutorialPromptManager.serialize(),
		"vertical_slice": VerticalSliceFlow.serialize(),
		"co_op": GameManager.active_player_count > 1,
		"settings": SettingsManager.serialize(),
	}


func reset_load_metadata() -> void:
	last_loaded_version = 3
	last_load_used_p2_fallback = false


func _apply_save_data(data: Dictionary) -> void:
	last_loaded_version = int(data.get("version", 2))
	last_load_used_p2_fallback = false
	if data.has("region"):
		GameManager.current_region_id = data.region
	if data.has("respawn_region") and data.has("respawn_position"):
		var pos_arr: Array = data.respawn_position
		if pos_arr.size() >= 3:
			var loaded := Vector3(pos_arr[0], pos_arr[1], pos_arr[2])
			set_respawn_point(data.respawn_region, loaded)
	if data.has("players"):
		var raw_players: Array = data.players
		var typed_players: Array[Dictionary] = []
		for entry in raw_players:
			typed_players.append(entry if entry is Dictionary else {})
		GameManager.player_data = typed_players
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
	if data.has("reliquary"):
		ReliquaryState.deserialize(data.reliquary)
	if data.has("foundry"):
		FoundryState.deserialize(data.foundry)
	if data.has("crypt"):
		CryptState.deserialize(data.crypt)
	if data.has("citadel"):
		CitadelState.deserialize(data.citadel)
	if data.has("cathedral"):
		CathedralState.deserialize(data.cathedral)
	if data.has("pyreheart"):
		PyreheartState.deserialize(data.pyreheart)
	if data.has("eclipse_sanctum"):
		EclipseSanctumState.deserialize(data.eclipse_sanctum)
	if data.has("merchants"):
		MerchantManager.deserialize(data.merchants)
	if data.has("npc_states"):
		NpcStateManager.deserialize(data.npc_states)
	if data.has("world_state"):
		WorldStateManager.deserialize(data.world_state)
	if data.has("tutorial"):
		TutorialPromptManager.deserialize(data.tutorial)
	if data.has("vertical_slice"):
		VerticalSliceFlow.deserialize(data.vertical_slice)
	if data.has("player_progress"):
		GameManager.pending_player_progress = data.player_progress
	if data.has("player_progress_all"):
		GameManager.pending_coop_player_progress = data.player_progress_all
	elif data.has("player_progress"):
		var p1_progress: Dictionary = data.player_progress
		GameManager.pending_coop_player_progress = [p1_progress]
		if bool(data.get("co_op", false)):
			# v2 co-op: P1 progress only — P2 spawns with default stats at party offset.
			last_load_used_p2_fallback = true
			if OS.is_debug_build():
				print("Save v2 loaded: applying safe co-op fallback for P2")
	if data.has("player_positions"):
		GameManager.pending_coop_positions = data.player_positions
	elif bool(data.get("co_op", false)) and last_loaded_version < 3:
		GameManager.pending_coop_positions = []
	if data.has("co_op"):
		GameManager.active_player_count = 2 if data.co_op else 1
		GameManager.coop_mode = GameManager.CoopMode.LOCAL_COOP_TWO_PLAYER if data.co_op else GameManager.CoopMode.SINGLE_PLAYER
