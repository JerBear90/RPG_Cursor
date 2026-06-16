class_name SealedHeartDoor
extends InteractableBase
## Heart Chamber entrance — opens after purification puzzle completion.

func _ready() -> void:
	super._ready()
	_update_state()
	if get_node_or_null("InteractionArea") == null:
		var area := Area3D.new()
		area.name = "InteractionArea"
		var col := CollisionShape3D.new()
		var sp := SphereShape3D.new()
		sp.radius = 3.0
		col.shape = sp
		area.add_child(col)
		add_child(area)
	if get_node_or_null("CollisionShape3D") == null and not CathedralState.puzzle_completed:
		var body_col := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(4.0, 3.0, 1.0)
		body_col.shape = box
		body_col.position = Vector3(0, 1.5, 0)
		add_child(body_col)


func _update_state() -> void:
	if CathedralState.puzzle_completed or CathedralState.retracted_roots:
		prompt_text = "Enter Heart Chamber"
		for child in get_children():
			if child is CollisionShape3D and child.name != "InteractionArea":
				child.disabled = true
	else:
		prompt_text = "Sealed Heart Chamber"


func _on_interact(_player: Node) -> void:
	if CathedralState.puzzle_completed or CathedralState.retracted_roots:
		DialogueManager.start_dialogue("cathedral_heart_open", [
			{"speaker": "Heart Chamber", "text": "Purified roots withdraw. The Blightheart pulses within — prepare yourself."},
		], [], {"from_interact": true})
		return
	DialogueManager.start_dialogue("cathedral_heart_sealed", [
		{"speaker": "Heart Chamber", "text": "Living corruption seals the Heart Chamber. Kindle all three purification braziers to retract the roots."},
	], [], {"from_interact": true})
