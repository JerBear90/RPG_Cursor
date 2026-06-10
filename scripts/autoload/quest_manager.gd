extends Node
## Quest tracking and objective progress.

signal quest_started(quest_id: String)
signal quest_updated(quest_id: String)
signal quest_completed(quest_id: String)
signal tracked_quest_changed(quest_id: String)

var active_quests: Dictionary = {}
var completed_quests: Array[String] = []
var tracked_quest_id: String = ""


func reset_for_new_game() -> void:
	active_quests.clear()
	completed_quests.clear()
	tracked_quest_id = ""
	start_quest("find_wolf_crest")


func start_quest(quest_id: String) -> void:
	if quest_id in completed_quests or active_quests.has(quest_id):
		return
	active_quests[quest_id] = _default_objectives(quest_id)
	quest_started.emit(quest_id)
	if tracked_quest_id == "":
		track_quest(quest_id)


func track_quest(quest_id: String) -> void:
	if active_quests.has(quest_id):
		tracked_quest_id = quest_id
		tracked_quest_changed.emit(quest_id)


func advance_objective(quest_id: String, objective_id: String, amount: int = 1) -> void:
	if not active_quests.has(quest_id):
		return
	var objectives: Array = active_quests[quest_id]
	for obj in objectives:
		if obj.id == objective_id and not obj.completed:
			obj.current = mini(obj.current + amount, obj.target)
			if obj.current >= obj.target:
				obj.completed = true
			quest_updated.emit(quest_id)
			if _all_complete(objectives):
				complete_quest(quest_id)
			return


func complete_quest(quest_id: String) -> void:
	if not active_quests.has(quest_id):
		return
	active_quests.erase(quest_id)
	completed_quests.append(quest_id)
	quest_completed.emit(quest_id)
	if tracked_quest_id == quest_id:
		tracked_quest_id = active_quests.keys()[0] if active_quests.size() > 0 else ""
		tracked_quest_changed.emit(tracked_quest_id)
	if quest_id == "first_blood":
		AchievementManager.unlock("first_blood")


func get_tracked_objective_text() -> String:
	if tracked_quest_id == "" or not active_quests.has(tracked_quest_id):
		return ""
	var objectives: Array = active_quests[tracked_quest_id]
	for obj in objectives:
		if not obj.completed:
			return "%s — %d/%d" % [obj.description, obj.current, obj.target]
	return ""


func _all_complete(objectives: Array) -> bool:
	for obj in objectives:
		if not obj.completed:
			return false
	return true


func _default_objectives(quest_id: String) -> Array:
	match quest_id:
		"find_wolf_crest":
			return [{"id": "reach_shrine", "description": "Find the Wolf Crest", "current": 0, "target": 1, "completed": false}]
		"merchant_errand":
			return [{"id": "deliver_herbs", "description": "Deliver herb bundles", "current": 0, "target": 3, "completed": false}]
		"clear_dungeon":
			return [{"id": "defeat_boss", "description": "Clear the sunken crypt", "current": 0, "target": 1, "completed": false}]
		_:
			return [{"id": "default", "description": quest_id, "current": 0, "target": 1, "completed": false}]


func serialize() -> Dictionary:
	return {
		"active": active_quests.duplicate(true),
		"completed": completed_quests.duplicate(),
		"tracked": tracked_quest_id,
	}


func deserialize(data: Dictionary) -> void:
	active_quests = data.get("active", {})
	completed_quests = data.get("completed", [])
	tracked_quest_id = data.get("tracked", "")
