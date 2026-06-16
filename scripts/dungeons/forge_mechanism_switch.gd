class_name ForgeMechanismSwitch
extends InteractableBase

@export var mechanism_id: String = "vent"
@export var controller_path: NodePath

var _controller: ForgeMechanismPuzzle


func _ready() -> void:
	super._ready()
	prompt_text = "Activate mechanism"
	if get_node_or_null("InteractionArea") == null:
		var area := Area3D.new()
		area.name = "InteractionArea"
		var col := CollisionShape3D.new()
		var sp := SphereShape3D.new()
		sp.radius = 2.0
		col.shape = sp
		area.add_child(col)
		add_child(area)
	if get_node_or_null("CollisionShape3D") == null:
		var body_col := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(1.5, 2.0, 1.5)
		body_col.shape = box
		body_col.position = Vector3(0, 1.0, 0)
		add_child(body_col)
	call_deferred("_resolve_controller")


func _resolve_controller() -> void:
	if controller_path != NodePath():
		_controller = get_node_or_null(controller_path) as ForgeMechanismPuzzle


func _on_interact(_player: Node) -> void:
	if _controller == null:
		_controller = get_parent() as ForgeMechanismPuzzle
	if _controller:
		_controller.activate_mechanism(mechanism_id)
	else:
		DialogueManager.start_dialogue("mechanism", [
			{"speaker": "Machine", "text": "Rusty gears grind but nothing moves."},
		], [], {"from_interact": true})
