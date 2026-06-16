class_name CathedralCheckpoint
extends InteractableBase
## Blightspire Cathedral sanctuary rest point.

var _pending: bool = false


func _ready() -> void:
	super._ready()
	prompt_text = "Rest at sanctuary"
	add_to_group("dungeon_checkpoint")
	if get_node_or_null("InteractionArea") == null:
		var area := Area3D.new()
		area.name = "InteractionArea"
		var col := CollisionShape3D.new()
		var sp := SphereShape3D.new()
		sp.radius = 2.5
		col.shape = sp
		area.add_child(col)
		add_child(area)
	if get_node_or_null("CollisionShape3D") == null:
		var body_col := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(2.5, 2.0, 2.5)
		body_col.shape = box
		body_col.position = Vector3(0, 1.0, 0)
		add_child(body_col)
	if not DialogueManager.dialogue_choice_selected.is_connected(_on_choice):
		DialogueManager.dialogue_choice_selected.connect(_on_choice)


func _on_interact(_player: Node) -> void:
	if GameManager.in_combat:
		return
	_pending = true
	DialogueManager.start_dialogue("cathedral_rest", [
		{"speaker": "Checkpoint Sanctuary", "text": "Violet light filters through the overgrown nave. Bind your path here?"},
	], ["Rest", "Cancel"], {"from_interact": true, "confirm_label": "Rest", "cancel_label": "Cancel"})


func _on_choice(index: int) -> void:
	if not _pending:
		return
	_pending = false
	if index != 0:
		return
	for p in GameManager.get_alive_players():
		if p.has_node("HealthComponent"):
			var hp := p.get_node("HealthComponent") as HealthComponent
			hp.heal(hp.max_health)
		if p.has_node("StaminaComponent"):
			var st := p.get_node("StaminaComponent") as StaminaComponent
			st.restore(st.max_stamina)
		if p.has_node("FocusComponent"):
			var focus := p.get_node("FocusComponent") as FocusComponent
			focus.restore(focus.max_focus)
		if p.has_node("StatusEffectsComponent"):
			var status := p.get_node("StatusEffectsComponent") as StatusEffectsComponent
			status.clear_environmental()
	var pos := global_position + Vector3(1.5, 0, 0)
	WorldStateManager.register_checkpoint("dungeon_checkpoint_blightspire_cathedral", "blightspire_cathedral", pos)
	WorldStateManager.dungeon_checkpoint_room = get_meta("room_index", 0)
	CathedralState.checkpoint_activated = true
	CathedralState.save_state()
	if QuestManager.active_quests.has("heart_of_the_blight"):
		QuestManager.advance_objective("heart_of_the_blight", "reach_checkpoint", 1)
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("show_toast"):
			hud.show_toast("Checkpoint bound at the sanctuary.")
