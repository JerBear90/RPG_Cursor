extends Node
## Waystone discovery and fast travel network.

signal waystone_discovered(waystone_id: String)
signal fast_travel_started(destination_id: String)

var discovered: Array[String] = []
var hearthhold_unlocked: bool = false
var last_waystone_position: Vector3 = Vector3.ZERO


func reset_for_new_game() -> void:
	discovered.clear()
	hearthhold_unlocked = false


func discover(waystone_id: String, world_position: Vector3 = Vector3.ZERO) -> void:
	if waystone_id in discovered:
		return
	discovered.append(waystone_id)
	waystone_discovered.emit(waystone_id)
	if world_position != Vector3.ZERO:
		MapManager.add_icon("waystone", Vector2(world_position.x, world_position.z), waystone_id)
		MapManager.discover_location(waystone_id, waystone_id.replace("_", " ").capitalize(), world_position, "fast_travel", GameManager.current_region_id, true)
	else:
		MapManager.add_icon("waystone", Vector2.ZERO, waystone_id)
	AchievementManager.unlock("waystone_awakened")


func can_fast_travel(destination_id: String) -> bool:
	if GameManager.in_combat or GameManager.in_boss_fight:
		return false
	if DialogueManager.is_active() or GameManager.is_paused:
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
	if GameManager.is_local_coop():
		var leader := GameManager.get_player(0)
		var yaw: float = (leader as Node3D).rotation.y if leader is Node3D else 0.0
		GameManager.pull_distant_companions(last_waystone_position, yaw, GameManager.COOP_TRAVEL_RADIUS)
	fast_travel_started.emit(destination_id)
	WorldStateManager.set_fast_travel_destination(destination_id)
	var scene_path := "res://scenes/levels/%s/%s.tscn" % [destination_id, destination_id]
	SceneTransitionManager.change_scene(scene_path, "waystone_%s" % destination_id)
	return true


func serialize() -> Dictionary:
	return {"discovered": discovered.duplicate(), "hearthhold_unlocked": hearthhold_unlocked}


func deserialize(data: Dictionary) -> void:
	discovered = data.get("discovered", [])
	hearthhold_unlocked = data.get("hearthhold_unlocked", false)
