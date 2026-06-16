class_name SealedEclipseThroneDoor
extends InteractableBase
## Sealed Eclipse Throne — dialogue only, no boss encounter.


func _ready() -> void:
	super._ready()
	prompt_text = "Sealed Eclipse Throne"
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


func _on_interact(_player: Node) -> void:
	AudioManager.play_sfx("sealed_throne_heartbeat")
	DialogueManager.start_dialogue("eclipse_throne_sealed", [
		{"speaker": "Sealed Eclipse Throne", "text": "A sovereign shadow waits beyond the sealed throne."},
	], [], {"from_interact": true})
