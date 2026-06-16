class_name SealedSolarHeartDoor
extends InteractableBase
## Sealed Solar Heart — opens after mirror puzzle completion.

func _ready() -> void:
	super._ready()
	prompt_text = "Sealed Solar Heart"
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
		box.size = Vector3(4.0, 3.0, 1.0)
		body_col.shape = box
		body_col.position = Vector3(0, 1.5, 0)
		add_child(body_col)


func _puzzle_ready() -> bool:
	return PyreheartState.puzzle_completed and PyreheartState.mirror_a \
		and PyreheartState.mirror_b and PyreheartState.mirror_c \
		and PyreheartState.cooling_channels_active


func _on_interact(_player: Node) -> void:
	if PyreheartState.boss_defeated_persistent:
		DialogueManager.start_dialogue("pyreheart_heart_victory", [
			{"speaker": "Solar Heart", "text": "The heart is cooled. The terrace exit awaits beyond the ascent."},
		], [], {"from_interact": true})
		return
	if not _puzzle_ready():
		DialogueManager.start_dialogue("pyreheart_heart_sealed", [
			{"speaker": "Sealed Solar Heart", "text": "Blazing heat seals the solar heart. Align all three mirrors to cool the buried channels."},
		], [], {"from_interact": true})
		return
	for node in get_tree().get_nodes_in_group("pyreheart_builder"):
		if node.has_method("unlock_solar_heart_chamber"):
			node.unlock_solar_heart_chamber()
	DialogueManager.start_dialogue("pyreheart_heart_open", [
		{"speaker": "Sealed Solar Heart", "text": "Cooling channels stabilize. The seal retracts — ancient fire awaits within."},
	], [], {"from_interact": true})
