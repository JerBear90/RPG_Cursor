extends Node
## Demo onboarding: opening copy, hearthhold guidance, demo completion, milestone hooks.

const _Registry := preload("res://scripts/autoload/npc_mission_registry.gd")

var opening_shown: bool = false
var hearthhold_welcomed: bool = false
var blacksmith_hint_shown: bool = false
var demo_complete_shown: bool = false
var _spawn_hook_pending: bool = false


func _ready() -> void:
	GameManager.region_changed.connect(_on_region_changed)
	GameManager.player_spawned.connect(_on_player_spawned)
	QuestManager.quest_started.connect(_on_quest_started)
	QuestManager.quest_completed.connect(_on_quest_completed)


func reset_for_new_game() -> void:
	opening_shown = false
	hearthhold_welcomed = false
	blacksmith_hint_shown = false
	demo_complete_shown = false
	_spawn_hook_pending = true


func on_level_players_ready() -> void:
	if not _spawn_hook_pending:
		return
	_spawn_hook_pending = false
	call_deferred("_show_opening_sequence")


func _show_opening_sequence() -> void:
	if opening_shown:
		return
	opening_shown = true
	var intro := "You are an Exiled Survivor. Hearthhold Camp is the last safe fire in this region."
	var sub := "Gather what you can. The Hollowing does not wait."
	if GameManager.is_local_coop():
		sub = "Survive together. The Hollowing does not wait."
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("show_toast"):
			hud.show_toast(intro, 5.0, sub, "notification", "", 2)
			break
	TutorialPromptManager.try_show_delayed("movement", 3.0)
	TutorialPromptManager.try_show_delayed("camera", 5.5)
	if GameManager.is_local_coop():
		TutorialPromptManager.try_show_delayed("coop_revive", 8.0)


func _on_player_spawned(_player: Node, _index: int) -> void:
	pass


func _on_region_changed(region_id: String) -> void:
	if region_id == "hearthhold_camp":
		_on_hearthhold_arrival()
	if QuestManager.active_quests.has("find_wolf_crest"):
		QuestManager.advance_objective("find_wolf_crest", "reach_hearthhold", 1)


func _on_hearthhold_arrival() -> void:
	if hearthhold_welcomed:
		return
	hearthhold_welcomed = true
	SaveManager.try_milestone_autosave("hearthhold_arrival")
	if not blacksmith_hint_shown:
		blacksmith_hint_shown = true
		call_deferred("_toast", "Speak with Old Blacksmith at the forge to begin rebuilding.", 4.0)


func _on_quest_started(quest_id: String) -> void:
	if quest_id in _Registry.MISSIONS:
		SaveManager.try_milestone_autosave("mission_accepted")
	if quest_id == "rebuild_the_forge":
		QuestManager.track_quest(quest_id)
		TutorialPromptManager.try_show_delayed("gather", 1.0)
		TutorialPromptManager.try_show_delayed("destructible", 2.0)


func _on_quest_completed(quest_id: String) -> void:
	SaveManager.try_milestone_autosave("quest_complete")
	if quest_id == "find_wolf_crest":
		call_deferred("_toast", "Hearthhold is linked. Visit Old Blacksmith for your first mission.", 4.5)
	elif quest_id in ["wake_the_stone", "clear_bandit_path", "rebuild_the_forge"]:
		_check_demo_complete(quest_id)


func notify_milestone(milestone_id: String) -> void:
	_check_demo_complete(milestone_id)


func _check_demo_complete(trigger_id: String) -> void:
	if demo_complete_shown:
		return
	var ready := false
	var message := ""
	match trigger_id:
		"wake_the_stone":
			ready = true
			message = "The Waystone hums awake. Higher-level regions now call to you."
		"clear_bandit_path":
			ready = true
			message = "Demo Objective Complete: The bandit path is clear. Hearthhold is safer."
		"bandit_captain":
			ready = true
			message = "Demo Objective Complete: The Bandit Captain falls. Hearthhold is safer."
		"rebuild_the_forge":
			ready = true
			message = "Demo Objective Complete: Hearthhold is stronger. The path to the next region is open."
		"find_wolf_crest":
			return
	if not ready:
		return
	demo_complete_shown = true
	call_deferred("_toast", message, 5.0)


func _toast(text: String, duration: float = 3.5) -> void:
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("show_toast"):
			hud.show_toast(text, duration, "", "notification", "", 2)
			return


func serialize() -> Dictionary:
	return {
		"opening_shown": opening_shown,
		"hearthhold_welcomed": hearthhold_welcomed,
		"blacksmith_hint_shown": blacksmith_hint_shown,
		"demo_complete_shown": demo_complete_shown,
	}


func deserialize(data: Dictionary) -> void:
	opening_shown = bool(data.get("opening_shown", false))
	hearthhold_welcomed = bool(data.get("hearthhold_welcomed", false))
	blacksmith_hint_shown = bool(data.get("blacksmith_hint_shown", false))
	demo_complete_shown = bool(data.get("demo_complete_shown", false))
	_spawn_hook_pending = false
