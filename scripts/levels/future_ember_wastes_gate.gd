class_name FutureEmberWastesGate
extends InteractableBase
## Future Ember Wastes route shell — never loads an unfinished region scene.

@export var required_item_id: String = "ember_wastes_pass"


func _ready() -> void:
	super._ready()
	prompt_text = "Road to The Ember Wastes"
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
	var has_core := InventoryManager.has_item("blightheart_core")
	var has_pass := InventoryManager.has_item(required_item_id)
	if not has_core and not CathedralState.boss_defeated_persistent:
		DialogueManager.start_dialogue("ember_wastes_blocked", [
			{"speaker": "The Ember Wastes", "text": "The road is consumed by living corruption."},
		], [], {"from_interact": true})
		return
	if has_core or has_pass or CathedralState.boss_defeated_persistent:
		DialogueManager.start_dialogue("ember_wastes_unbuilt", [
			{"speaker": "The Ember Wastes", "text": "The corruption has receded, but the Ember Wastes are not yet accessible."},
		], [], {"from_interact": true})
		return
	DialogueManager.start_dialogue("ember_wastes_blocked", [
		{"speaker": "The Ember Wastes", "text": "The road is consumed by living corruption."},
	], [], {"from_interact": true})
