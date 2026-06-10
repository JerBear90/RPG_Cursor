extends Node
## Save/load with 3 slots via JSON.

signal save_completed(slot: int)
signal load_completed(slot: int)

const SAVE_DIR := "user://saves/"
const MAX_SLOTS := 3

var current_slot: int = -1


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func save_game(slot: int) -> bool:
	if slot < 0 or slot >= MAX_SLOTS:
		return false
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


func _collect_save_data() -> Dictionary:
	var player_progress := {}
	var player := GameManager.get_player(0)
	if player:
		player_progress = PlayerProgress.collect(player)
	return {
		"version": 2,
		"timestamp": Time.get_unix_time_from_system(),
		"region": GameManager.current_region_id,
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
		"dungeon": DungeonManager.serialize(),
		"co_op": GameManager.active_player_count > 1,
		"settings": SettingsManager.serialize(),
	}


func _apply_save_data(data: Dictionary) -> void:
	if data.has("region"):
		GameManager.current_region_id = data.region
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
	if data.has("dungeon"):
		DungeonManager.deserialize(data.dungeon)
	if data.has("player_progress"):
		GameManager.pending_player_progress = data.player_progress
	if data.has("co_op"):
		GameManager.active_player_count = 2 if data.co_op else 1
