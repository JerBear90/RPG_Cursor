class_name FutureSunlessDominionGate
extends InteractableBase
## Future Sunless Dominion route shell — dialogue only, never loads unfinished region.


func _ready() -> void:
	super._ready()
	prompt_text = "Road to the Sunless Dominion"
	add_to_group("region_transition_gate")
	if get_node_or_null("InteractionArea") == null:
		var area := Area3D.new()
		area.name = "InteractionArea"
		var col := CollisionShape3D.new()
		var sp := SphereShape3D.new()
		sp.radius = 3.0
		col.shape = sp
		area.add_child(col)
		add_child(area)


func _on_interact(_player: Node) -> void:
	var has_pass := InventoryManager.has_item("sunless_dominion_pass")
	var boss_done := PyreheartState.boss_defeated_persistent
	if not has_pass and not boss_done:
		DialogueManager.start_dialogue("sunless_dominion_blocked", [
			{"speaker": "The Sunless Dominion", "text": "The buried road remains sealed by the Solar Heart."},
		], [], {"from_interact": true})
		return
	DialogueManager.start_dialogue("sunless_dominion_unbuilt", [
		{"speaker": "The Sunless Dominion", "text": "The road to the Sunless Dominion is open, but the region is not yet accessible."},
	], [], {"from_interact": true})
