extends Node
## Headless test runner — validates core systems without a display.

const LOG_PATH := "res://tests/last_run.log"
const DUNGEON_ROOM := preload("res://scripts/dungeons/dungeon_room.gd")
var _log: PackedStringArray = []
var _passed := 0
var _failed := 0


func _ready() -> void:
	_log_line("=== Exiled Survivors Test Runner ===")
	_log_line("Godot %s" % Engine.get_version_info().string)
	_run_all()
	_flush_log()
	_log_line("")
	_log_line("Results: %d passed, %d failed" % [_passed, _failed])
	get_tree().quit(_failed)


func _test_autoloads() -> void:
	_assert(_get_autoload("GameManager") != null, "GameManager autoload")
	_assert(_get_autoload("InputManager") != null, "InputManager autoload")
	_assert(_get_autoload("InventoryManager") != null, "InventoryManager autoload")
	_assert(_get_autoload("CurrencyManager") != null, "CurrencyManager autoload")
	_assert(_get_autoload("QuestManager") != null, "QuestManager autoload")


func _test_currency() -> void:
	var currency := _get_autoload("CurrencyManager")
	currency.reset_for_new_game()
	_assert(currency.copper >= 50, "starter copper")
	currency.add_copper(150)
	_assert(currency.silver >= 1, "copper converts to silver")


func _test_quests() -> void:
	var quests := _get_autoload("QuestManager")
	quests.reset_for_new_game()
	_assert(quests.active_quests.has("find_wolf_crest"), "starter quest active")
	_assert(quests.get_tracked_objective_text() != "", "tracked objective text")


func _test_inventory() -> void:
	var inventory := _get_autoload("InventoryManager")
	inventory.reset_for_new_game()
	_assert(inventory.has_item("rusty_sword"), "starter sword")
	_assert(inventory.add_item("wood", 5), "add wood")


func _test_player_scene() -> void:
	var scene := load("res://scenes/player/player.tscn")
	_assert(scene != null, "player scene loads")
	if scene:
		var player: Node = scene.instantiate()
		_assert(player is PlayerController, "player is PlayerController")
		if player:
			player.free()


func _test_enemy_scene() -> void:
	var scene := load("res://scenes/enemies/enemy_base.tscn")
	_assert(scene != null, "enemy_base scene loads")
	if scene:
		var enemy: Node = scene.instantiate()
		_assert(enemy is EnemyBase, "enemy is EnemyBase")
		if enemy:
			enemy.free()


func _test_dungeon_generator() -> void:
	var layout := DungeonGenerator.generate(4242, 1)
	_assert(layout.has("rooms"), "dungeon layout has rooms")
	var rooms: Array = layout.get("rooms", [])
	_assert(rooms.size() >= 4, "dungeon generates enough rooms")
	_assert(layout.has("name"), "dungeon has generated name")
	var boss_found := false
	for room in rooms:
		if room.get_script() == DUNGEON_ROOM and room.room_type == DUNGEON_ROOM.RoomType.BOSS:
			boss_found = true
	_assert(boss_found, "dungeon has boss room")


func _test_dungeon_scene_exists() -> void:
	_assert(ResourceLoader.exists("res://scenes/dungeons/procedural_dungeon.tscn"), "procedural_dungeon.tscn exists")
	_assert(_get_autoload("DungeonManager") != null, "DungeonManager autoload")


func _test_main_scene_exists() -> void:
	_assert(ResourceLoader.exists("res://scenes/main_menu/main_menu.tscn"), "main_menu.tscn exists")
	_assert(ResourceLoader.exists("res://scenes/levels/darkpine_forest/darkpine_forest.tscn"), "darkpine_forest.tscn exists")
	var menu := load("res://scenes/main_menu/main_menu.tscn")
	_assert(menu != null, "main_menu loads")


func _get_autoload(name: String) -> Node:
	return get_tree().root.get_node_or_null(name)


func _run_all() -> void:
	_test_autoloads()
	_test_currency()
	_test_quests()
	_test_inventory()
	_test_player_scene()
	_test_enemy_scene()
	_test_dungeon_generator()
	_test_dungeon_scene_exists()
	_test_main_scene_exists()


func _assert(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
		_log_line("[PASS] %s" % label)
	else:
		_failed += 1
		_log_line("[FAIL] %s" % label)


func _log_line(text: String) -> void:
	_log.append(text)
	print(text)


func _flush_log() -> void:
	var path := ProjectSettings.globalize_path(LOG_PATH)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string("\n".join(_log))
		file.close()
