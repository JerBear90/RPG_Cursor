extends Node
## Waystone discovery and fast travel network.

signal waystone_discovered(waystone_id: String)
signal fast_travel_started(destination_id: String)

var discovered: Array[String] = []
var hearthhold_unlocked: bool = false


func reset_for_new_game() -> void:
	discovered.clear()
	if hearthhold_unlocked:
		discovered.append("hearthhold_camp")


func discover(waystone_id: String) -> void:
	if waystone_id in discovered:
		return
	discovered.append(waystone_id)
	waystone_discovered.emit(waystone_id)
	MapManager.add_icon("waystone", Vector2.ZERO, waystone_id)
	AchievementManager.unlock("waystone_awakened")


func can_fast_travel(destination_id: String) -> bool:
	if GameManager.in_combat or GameManager.in_boss_fight:
		return false
	if destination_id not in discovered:
		return false
	if destination_id == "hearthhold_camp" and not hearthhold_unlocked:
		return false
	if destination_id == GameManager.current_region_id:
		return false
	return true


func fast_travel(destination_id: String) -> bool:
	if not can_fast_travel(destination_id):
		return false
	fast_travel_started.emit(destination_id)
	var scene_path := "res://scenes/levels/%s/%s.tscn" % [destination_id, destination_id]
	SceneTransitionManager.change_scene(scene_path, "waystone_spawn")
	return true


func serialize() -> Dictionary:
	return {"discovered": discovered.duplicate(), "hearthhold_unlocked": hearthhold_unlocked}


func deserialize(data: Dictionary) -> void:
	discovered = data.get("discovered", [])
	hearthhold_unlocked = data.get("hearthhold_unlocked", false)
