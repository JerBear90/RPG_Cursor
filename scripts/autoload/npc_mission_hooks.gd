extends Node
## Hooks mission objectives to gameplay events (shared co-op quest state).

const _Registry := preload("res://scripts/autoload/npc_mission_registry.gd")


func _ready() -> void:
	ResourceFeedbackManager.resources_obtained.connect(_on_resources_obtained)
	BaseManager.station_upgraded.connect(_on_station_upgraded)
	PetManager.pet_adopted.connect(_on_pet_adopted)
	WaystoneManager.waystone_discovered.connect(_on_waystone_discovered)
	QuestManager.quest_completed.connect(_on_quest_completed)
	QuestManager.quest_started.connect(_on_quest_started)
	if not InventoryManager.inventory_changed.is_connected(sync_inventory_missions):
		InventoryManager.inventory_changed.connect(sync_inventory_missions)
	call_deferred("_sync_loaded_missions")


func _sync_loaded_missions() -> void:
	sync_inventory_missions()
	check_beast_bond_skill()
	if QuestManager.active_quests.has("build_the_basics"):
		var quest_id := "build_the_basics"
		if BaseManager.get_station_level("workbench") >= 2:
			QuestManager.advance_objective(quest_id, "upgrade_workbench", 1)
		if BaseManager.get_station_level("water_collector") >= 1:
			QuestManager.advance_objective(quest_id, "build_water", 1)
		if BaseManager.get_station_level("garden_plot") >= 1:
			QuestManager.advance_objective(quest_id, "build_garden", 1)
	if QuestManager.active_quests.has("a_hound_in_the_ash"):
		if BaseManager.get_station_level("pet_shelter") >= 1:
			QuestManager.advance_objective("a_hound_in_the_ash", "upgrade_pet_shelter", 1)
		if PetManager.has_adopted_pet("ash_hound"):
			QuestManager.advance_objective("a_hound_in_the_ash", "adopt_hound", 1)


func on_enemy_killed(enemy_id: String) -> void:
	if "bandit" not in enemy_id:
		return
	if QuestManager.active_quests.has("clear_bandit_path"):
		QuestManager.advance_objective("clear_bandit_path", "kill_bandits", 1)
	if enemy_id == "bandit_captain":
		VerticalSliceFlow.notify_milestone("bandit_captain")


func can_turn_in_quest(quest_id: String) -> bool:
	return _can_turn_in(quest_id)


func try_turn_in(npc_id: String, quest_id: String) -> bool:
	if not QuestManager.active_quests.has(quest_id):
		return false
	if not _can_turn_in(quest_id):
		return false
	if quest_id == "rebuild_the_forge":
		if InventoryManager.get_combined_count("iron_scrap") < 6 or InventoryManager.get_combined_count("fire_resin") < 1:
			return false
		if not InventoryManager.consume_combined("iron_scrap", 6):
			return false
		if not InventoryManager.consume_combined("fire_resin", 1):
			return false
	match quest_id:
		"rebuild_the_forge":
			QuestManager.advance_objective(quest_id, "report_blacksmith", 1)
		"clear_bandit_path":
			QuestManager.advance_objective(quest_id, "report_scout", 1)
		"build_the_basics":
			QuestManager.advance_objective(quest_id, "report_builder", 1)
		"a_hound_in_the_ash":
			QuestManager.advance_objective(quest_id, "report_handler", 1)
		"wake_the_stone":
			QuestManager.advance_objective(quest_id, "report_keeper", 1)
	NpcStateManager.on_mission_completed(npc_id)
	return true


func _can_turn_in(quest_id: String) -> bool:
	match quest_id:
		"rebuild_the_forge":
			return _objective_done(quest_id, "gather_scrap") and _objective_done(quest_id, "gather_resin")
		"clear_bandit_path":
			return _objective_done(quest_id, "kill_bandits")
		"build_the_basics":
			return _objective_done(quest_id, "upgrade_workbench") \
				and _objective_done(quest_id, "build_water") \
				and _objective_done(quest_id, "build_garden")
		"a_hound_in_the_ash":
			return _objective_done(quest_id, "unlock_beast_bond") \
				and _objective_done(quest_id, "upgrade_pet_shelter") \
				and _objective_done(quest_id, "gather_bone") \
				and _objective_done(quest_id, "adopt_hound")
		"wake_the_stone":
			return _objective_done(quest_id, "gather_crystal") \
				and _objective_done(quest_id, "activate_waystone")
	return false


func _objective_done(quest_id: String, objective_id: String) -> bool:
	if not QuestManager.active_quests.has(quest_id):
		return false
	for obj in QuestManager.active_quests[quest_id]:
		if obj.id == objective_id:
			return bool(obj.completed)
	return false


func _on_resources_obtained(_rewards: Dictionary) -> void:
	sync_inventory_missions()


func sync_inventory_missions() -> void:
	if QuestManager.active_quests.has("rebuild_the_forge"):
		var scrap := mini(InventoryManager.get_combined_count("iron_scrap"), 6)
		_set_objective_progress("rebuild_the_forge", "gather_scrap", scrap, 6)
		var resin := mini(InventoryManager.get_combined_count("fire_resin"), 1)
		_set_objective_progress("rebuild_the_forge", "gather_resin", resin, 1)
	if QuestManager.active_quests.has("a_hound_in_the_ash"):
		var bones := mini(InventoryManager.get_combined_count("bone"), 3)
		_set_objective_progress("a_hound_in_the_ash", "gather_bone", bones, 3)
	if QuestManager.active_quests.has("wake_the_stone"):
		var shards := mini(InventoryManager.get_combined_count("crystal_shard"), 3)
		_set_objective_progress("wake_the_stone", "gather_crystal", shards, 3)


func _on_station_upgraded(station_id: String, level: int) -> void:
	if QuestManager.active_quests.has("build_the_basics"):
		if station_id == "workbench" and level >= 2:
			QuestManager.advance_objective("build_the_basics", "upgrade_workbench", 1)
		if station_id == "water_collector" and level >= 1:
			QuestManager.advance_objective("build_the_basics", "build_water", 1)
		if station_id == "garden_plot" and level >= 1:
			QuestManager.advance_objective("build_the_basics", "build_garden", 1)
	if QuestManager.active_quests.has("rebuild_the_forge") and station_id == "forge" and level >= 2:
		_notify("Objective Complete: Forge upgraded")
	if QuestManager.active_quests.has("a_hound_in_the_ash") and station_id == "pet_shelter" and level >= 1:
		QuestManager.advance_objective("a_hound_in_the_ash", "upgrade_pet_shelter", 1)


func _on_pet_adopted(pet_id: String) -> void:
	if pet_id == "ash_hound" and QuestManager.active_quests.has("a_hound_in_the_ash"):
		QuestManager.advance_objective("a_hound_in_the_ash", "adopt_hound", 1)


func _on_waystone_discovered(_waystone_id: String) -> void:
	if QuestManager.active_quests.has("wake_the_stone"):
		QuestManager.advance_objective("wake_the_stone", "find_waystone", 1)


func on_waystone_activated(_waystone_id: String) -> void:
	if QuestManager.active_quests.has("wake_the_stone"):
		QuestManager.advance_objective("wake_the_stone", "activate_waystone", 1)


func check_beast_bond_skill() -> void:
	if not QuestManager.active_quests.has("a_hound_in_the_ash"):
		return
	if PetManager.has_beast_bond_access():
		QuestManager.advance_objective("a_hound_in_the_ash", "unlock_beast_bond", 1)


func _on_quest_started(quest_id: String) -> void:
	var title := _Registry.get_mission_title(quest_id)
	if quest_id in _Registry.MISSIONS:
		_notify("Mission Accepted: %s" % title, 3.0, 2)


func _on_quest_completed(quest_id: String) -> void:
	var title := _Registry.get_mission_title(quest_id)
	if quest_id in _Registry.MISSIONS:
		_notify("Mission Complete: %s" % title, 3.5, 2)


func _set_objective_progress(quest_id: String, objective_id: String, current: int, target: int) -> void:
	if not QuestManager.active_quests.has(quest_id):
		return
	for obj in QuestManager.active_quests[quest_id]:
		if obj.id == objective_id and not obj.completed:
			var prev := int(obj.current)
			obj.current = current
			if obj.current >= target:
				obj.completed = true
				_toast_objective(quest_id, objective_id)
				check_mission_ready_quest(quest_id)
			elif obj.current != prev:
				if _should_emit_progress_toast(int(obj.current), target):
					_notify("Objective Updated: %s — %d / %d" % [obj.description, obj.current, target], 2.5, 1)
				QuestManager.quest_updated.emit(quest_id)
			return


func _should_emit_progress_toast(current: int, target: int) -> bool:
	if target <= 1:
		return true
	var half := int(ceil(float(target) / 2.0))
	return current == 1 or current == half or current >= target - 1


func _toast_objective(quest_id: String, objective_id: String) -> void:
	if not QuestManager.active_quests.has(quest_id):
		return
	for obj in QuestManager.active_quests[quest_id]:
		if obj.id == objective_id:
			_notify("Objective Complete: %s" % obj.description)
			return


func check_mission_ready_quest(quest_id: String) -> void:
	if not QuestManager.active_quests.has(quest_id):
		return
	if not _can_turn_in(quest_id):
		return
	var title := _Registry.get_mission_title(quest_id)
	_notify("Mission Ready: %s" % title, 3.0, 2)


func _notify(message: String, duration: float = 2.5, priority: int = 1) -> void:
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("show_toast"):
			hud.show_toast(message, duration, "", "notification", "", priority)
			return
