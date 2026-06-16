class_name ReliquaryCheckpoint
extends InteractableBase
## Dungeon sanctuary — rest and register checkpoint.

var _pending: bool = false


func _ready() -> void:
	super._ready()
	prompt_text = "Rest at shrine"
	add_to_group("dungeon_checkpoint")
	if not DialogueManager.dialogue_choice_selected.is_connected(_on_choice):
		DialogueManager.dialogue_choice_selected.connect(_on_choice)


func _on_interact(_player: Node) -> void:
	if GameManager.in_combat:
		return
	_pending = true
	DialogueManager.start_dialogue("reliquary_rest", [
		{"speaker": "Memory Shrine", "text": "Rest at the flooded sanctuary and bind your path?"},
	], ["Rest", "Cancel"], {"from_interact": true, "confirm_label": "Rest", "cancel_label": "Cancel"})


func _on_choice(index: int) -> void:
	if not _pending:
		return
	_pending = false
	if index != 0:
		return
	for p in GameManager.get_alive_players():
		if p.has_node("HealthComponent"):
			(p.get_node("HealthComponent") as HealthComponent).heal(
				(p.get_node("HealthComponent") as HealthComponent).max_health
			)
		if p.has_node("StaminaComponent"):
			(p.get_node("StaminaComponent") as StaminaComponent).restore(
				(p.get_node("StaminaComponent") as StaminaComponent).max_stamina
			)
		if p.has_node("StatusEffectsComponent"):
			(p.get_node("StatusEffectsComponent") as Node).call("clear_poison")
	var pos := global_position + Vector3(1.5, 0, 0)
	WorldStateManager.register_checkpoint("dungeon_checkpoint_sunken_reliquary", "sunken_reliquary", pos)
	WorldStateManager.dungeon_checkpoint_room = get_meta("room_index", 0)
	ReliquaryState.checkpoint_activated = true
	ReliquaryState.save_state()
	if QuestManager.active_quests.has("depths_of_reliquary"):
		QuestManager.advance_objective("depths_of_reliquary", "reach_checkpoint", 1)
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("show_toast"):
			hud.show_toast("Checkpoint bound at the sanctuary.")
