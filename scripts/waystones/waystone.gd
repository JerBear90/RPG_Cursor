class_name Waystone
extends InteractableBase

@export var waystone_id: String = "darkpine_forest"


func _ready() -> void:
	add_to_group("waystone")
	super._ready()
	prompt_text = "Use Waystone"


func _on_interact(player: Node) -> void:
	if player is PlayerController:
		GameManager.interacting_player_index = (player as PlayerController).player_index
	WaystoneManager.last_waystone_position = global_position
	if waystone_id not in WaystoneManager.discovered:
		WaystoneManager.discover(waystone_id, global_position)
		TutorialPromptManager.try_show("waystone")
		SaveManager.try_milestone_autosave("waystone_unlocked")
		DialogueManager.start_dialogue(waystone_id, [
			{"speaker": "Waystone", "text": "Cold blue fire ignites along the runes. A path opens in your mind."},
		], [], {"from_interact": true, "confirm_label": "Continue", "cancel_label": "Leave", "interacting_player_index": GameManager.interacting_player_index})
		await DialogueManager.dialogue_ended
		if QuestManager.active_quests.has("into_rotfen") and waystone_id == "rotfen_marsh":
			QuestManager.advance_objective("into_rotfen", "activate_waystone", 1)
		if QuestManager.active_quests.has("through_the_ash") and waystone_id == "ashfall_highlands":
			QuestManager.advance_objective("through_the_ash", "activate_waystone", 1)
		if QuestManager.active_quests.has("into_the_white") and waystone_id == "frostgrave_expanse":
			QuestManager.advance_objective("into_the_white", "activate_waystone", 1)
		if QuestManager.active_quests.has("into_the_storm") and waystone_id == "shattered_coast":
			QuestManager.advance_objective("into_the_storm", "activate_waystone", 1)
		if QuestManager.active_quests.has("into_the_ember") and waystone_id == "ember_wastes":
			QuestManager.advance_objective("into_the_ember", "activate_waystone", 1)
		if QuestManager.active_quests.has("into_the_dominion") and waystone_id == "sunless_dominion":
			QuestManager.advance_objective("into_the_dominion", "activate_waystone", 1)
		NpcMissionHooks.on_waystone_activated(waystone_id)
	MapManager.explore_region(GameManager.current_region_id)
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("open_waystone_menu"):
			hud.open_waystone_menu()
