class_name FutureAstralRiftGate
extends InteractableBase
## Future Astral Rift route shell — dialogue only, never loads unfinished region.


func _ready() -> void:
	super._ready()
	prompt_text = "Road to the Astral Rift"
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
	DialogueManager.start_dialogue("astral_rift_unbuilt", [
		{"speaker": "The Astral Rift", "text": "Beyond the sanctum, the sky tears open — but the Astral Rift is not yet accessible."},
	], [], {"from_interact": true})
