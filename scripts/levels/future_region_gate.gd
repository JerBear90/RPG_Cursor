class_name FutureRegionGate
extends InteractableBase
## Frostgrave Expanse transition shell — unlocks with Foundry Core.

@export var required_item_id: String = "foundry_core"
@export var transition_id: String = "ashfall_to_frostgrave"
@export var destination_region_id: String = "frostgrave_expanse"
@export var destination_spawn_id: String = "ashfall_arrival_frostgrave"
@export var destination_scene_path: String = "res://scenes/levels/frostgrave_expanse/frostgrave_expanse.tscn"


func _ready() -> void:
	super._ready()
	prompt_text = "Frostgrave Pass"
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
	if get_node_or_null("CollisionShape3D") == null:
		var body_col := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(3, 3, 1)
		body_col.shape = box
		body_col.position = Vector3(0, 1.5, 0)
		add_child(body_col)


func _on_interact(_player: Node) -> void:
	if not _is_unlocked():
		DialogueManager.start_dialogue("frostgrave_locked", [
			{"speaker": "Mountain Pass", "text": "The road beyond is not yet accessible.\n\nDefeat the Iron Crucible and claim the Foundry Core."},
		], [], {"from_interact": true})
		return
	DialogueManager.start_dialogue("frostgrave_unbuilt", [
		{"speaker": "Frostgrave Pass", "text": "The road beyond is not yet accessible."},
	], [], {"from_interact": true})


func _is_unlocked() -> bool:
	return InventoryManager.has_item(required_item_id) or FoundryState.boss_defeated_persistent
