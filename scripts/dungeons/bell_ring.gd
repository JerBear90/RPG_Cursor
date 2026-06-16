class_name BellRing
extends InteractableBase
## Single bell in the bell-chamber puzzle.

@export var bell_index: int = 1
@export var controller_path: NodePath

var _controller: BellPuzzle


func _ready() -> void:
	super._ready()
	prompt_text = "Ring bell"
	if get_node_or_null("InteractionArea") == null:
		var area := Area3D.new()
		area.name = "InteractionArea"
		var col := CollisionShape3D.new()
		var sp := SphereShape3D.new()
		sp.radius = 2.2
		col.shape = sp
		area.add_child(col)
		add_child(area)
	if get_node_or_null("CollisionShape3D") == null:
		var body_col := CollisionShape3D.new()
		var cyl := CylinderShape3D.new()
		cyl.radius = 0.6
		cyl.height = 2.0
		body_col.shape = cyl
		body_col.position = Vector3(0, 1.0, 0)
		add_child(body_col)
	call_deferred("_resolve_controller")


func _resolve_controller() -> void:
	if controller_path != NodePath():
		_controller = get_node_or_null(controller_path) as BellPuzzle


func _on_interact(_player: Node) -> void:
	if _controller == null:
		_controller = get_parent() as BellPuzzle
	if _controller:
		_controller.ring_bell(bell_index)
	else:
		DialogueManager.start_dialogue("bell", [
			{"speaker": "Bell", "text": "The bell tolls hollowly."},
		], [], {"from_interact": true})
