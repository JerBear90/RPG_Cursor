extends Node
## Tracks dungeon runs, return positions, and entry/exit flow.

signal dungeon_entered(layout: Dictionary)
signal dungeon_cleared()
signal dungeon_exited()

const DUNGEON_SCENE := "res://scenes/dungeons/procedural_dungeon.tscn"

var in_dungeon: bool = false
var depth: int = 0
var seed: int = 0
var dungeon_name: String = ""
var tier: int = 1
var layout: Dictionary = {}

var return_scene_path: String = ""
var return_position: Vector3 = Vector3.ZERO
var entrance_region_id: String = "darkpine_forest"
var boss_defeated: bool = false


func reset_for_new_game() -> void:
	in_dungeon = false
	depth = 0
	seed = 0
	dungeon_name = ""
	layout = {}
	return_scene_path = ""
	return_position = Vector3.ZERO
	boss_defeated = false


func can_enter(players_near_entrance: bool) -> bool:
	if in_dungeon:
		return false
	return players_near_entrance or GameManager.get_alive_players().size() == 1


func enter_dungeon(from_region: String, return_scene: String, return_pos: Vector3) -> void:
	if in_dungeon:
		return
	entrance_region_id = from_region
	return_scene_path = return_scene
	return_position = return_pos
	depth += 1
	seed = randi()
	tier = mini(depth, 3)
	layout = DungeonGenerator.generate(seed, tier)
	dungeon_name = layout.get("name", "Unknown Depths")
	in_dungeon = true
	boss_defeated = false
	MapManager.discover_region("procedural_dungeon")
	MapManager.add_icon("dungeon", Vector2.ZERO, dungeon_name)
	QuestManager.start_quest("clear_dungeon")
	dungeon_entered.emit(layout)
	SceneTransitionManager.change_scene(DUNGEON_SCENE)


func on_boss_defeated() -> void:
	if boss_defeated:
		return
	boss_defeated = true
	QuestManager.advance_objective("clear_dungeon", "defeat_boss", 1)
	AchievementManager.unlock("dungeon_delver")
	DialogueManager.start_dialogue("dungeon_victory", [
		{"speaker": "Echo", "text": "The crypt falls silent. Treasure awaits — find the exit seal."},
	])
	dungeon_cleared.emit()


func exit_dungeon() -> void:
	if not in_dungeon:
		return
	in_dungeon = false
	var scene_path := return_scene_path
	var pos := return_position
	dungeon_exited.emit()
	SceneTransitionManager.change_scene(scene_path)
	call_deferred("_restore_players", pos)


func _restore_players(pos: Vector3) -> void:
	await get_tree().process_frame
	for p in GameManager.get_alive_players():
		if is_instance_valid(p):
			p.global_position = pos + Vector3(p.player_index * 2.0, 0.0, 0.0)


func get_floor_display() -> String:
	if not in_dungeon:
		return ""
	return "Depth %d — %s" % [depth, dungeon_name]
