extends Node
## Quest tracking and objective progress.

signal quest_started(quest_id: String)
signal quest_updated(quest_id: String)
signal quest_completed(quest_id: String)
signal quest_rewarded(quest_id: String, summary: String)
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
	_grant_quest_rewards(quest_id)
	quest_completed.emit(quest_id)
	if tracked_quest_id == quest_id:
		tracked_quest_id = active_quests.keys()[0] if active_quests.size() > 0 else ""
		tracked_quest_changed.emit(tracked_quest_id)
	if quest_id == "first_blood":
		AchievementManager.unlock("first_blood")
	_chain_next_quest(quest_id)


func get_active_quest_list() -> Array[String]:
	var ids: Array[String] = []
	for quest_id in active_quests.keys():
		ids.append(quest_id)
	return ids


func get_quest_summary(quest_id: String) -> String:
	if not active_quests.has(quest_id):
		return ""
	var objectives: Array = active_quests[quest_id]
	var parts: PackedStringArray = []
	for obj in objectives:
		var status := "done" if obj.completed else "%d/%d" % [obj.current, obj.target]
		parts.append("%s (%s)" % [obj.description, status])
	return "%s: %s" % [quest_id.replace("_", " ").capitalize(), ", ".join(parts)]


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
		"first_blood":
			return [{"id": "kill_enemy", "description": "Slay your first foe", "current": 0, "target": 1, "completed": false}]
		"defeat_warden":
			return [{"id": "kill_warden", "description": "Defeat the Hollow Grove Warden", "current": 0, "target": 1, "completed": false}]
		_:
			return [{"id": "default", "description": quest_id, "current": 0, "target": 1, "completed": false}]


func serialize() -> Dictionary:
	return {
		"active": active_quests.duplicate(true),
		"completed": completed_quests.duplicate(),
		"tracked": tracked_quest_id,
	}


func _grant_quest_rewards(quest_id: String) -> void:
	var summary := ""
	match quest_id:
		"find_wolf_crest":
			CurrencyManager.add_copper(50)
			InventoryManager.add_item("herb_bundle", 2)
			summary = "+50 copper, herb bundles"
		"merchant_errand":
			CurrencyManager.add_copper(80)
			InventoryManager.add_item("dried_rations", 3)
			summary = "+80 copper, rations"
		"clear_dungeon":
			CurrencyManager.add_copper(100)
			InventoryManager.add_item("iron_scrap", 3)
			summary = "+100 copper, iron scrap"
		"first_blood":
			CurrencyManager.add_copper(15)
			summary = "+15 copper"
		"defeat_warden":
			CurrencyManager.add_silver(2)
			InventoryManager.add_item("iron_scrap", 5)
			summary = "+2 silver, iron scrap"
			var player := GameManager.get_player(0)
			if player and player.has_node("Spellcaster"):
				(player.get_node("Spellcaster") as Node).unlock_spell("shadow_lash")
	if summary != "":
		quest_rewarded.emit(quest_id, summary)
		AudioManager.play_sfx("quest")


func _chain_next_quest(quest_id: String) -> void:
	match quest_id:
		"find_wolf_crest":
			WaystoneManager.hearthhold_unlocked = true
			if "hearthhold_camp" not in WaystoneManager.discovered:
				WaystoneManager.discovered.append("hearthhold_camp")
			start_quest("merchant_errand")
			DialogueManager.start_dialogue("quest_wolf_done", [
				{"speaker": "Quest", "text": "The Wolf Crest is yours. Hearthhold is linked. A wounded scout may need herb bundles."},
			])
		"merchant_errand":
			start_quest("defeat_warden")
			DialogueManager.start_dialogue("quest_errand_done", [
				{"speaker": "Quest", "text": "The merchant owes you a favor. The Hollow Grove Warden must fall."},
			])


func deserialize(data: Dictionary) -> void:
	active_quests = data.get("active", {})
	completed_quests = data.get("completed", [])
	tracked_quest_id = data.get("tracked", "")
