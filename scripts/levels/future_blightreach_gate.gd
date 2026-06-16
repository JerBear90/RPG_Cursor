class_name FutureBlightreachGate

extends InteractableBase

## Blightreach transition shell — unlocks with Tidebound Crown. Does not load unfinished region.



@export var required_item_id: String = "tidebound_crown"





func _ready() -> void:

	super._ready()

	prompt_text = "Road to Blightreach"

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

	if not _is_unlocked():

		DialogueManager.start_dialogue("blightreach_locked", [

			{"speaker": "Inland Gate", "text": "The inland route is sealed by the storm."},

		], [], {"from_interact": true})

		return

	DialogueManager.start_dialogue("blightreach_unbuilt", [

		{"speaker": "Blightreach", "text": "The road to Blightreach is open, but the region is not yet accessible."},

	], [], {"from_interact": true})





func _is_unlocked() -> bool:

	return InventoryManager.has_item(required_item_id) or CitadelState.boss_defeated_persistent

