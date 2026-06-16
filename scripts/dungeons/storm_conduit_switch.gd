class_name StormConduitSwitch

extends InteractableBase



@export var conduit_id: String = "conduit_a"

@export var controller_path: NodePath



var _controller: StormConduitPuzzle

var _light: OmniLight3D





func _ready() -> void:

	super._ready()

	prompt_text = "Activate storm conduit"

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

	_light = OmniLight3D.new()

	_light.light_color = Color(0.45, 0.75, 1.0)

	_light.light_energy = 0.0

	_light.omni_range = 3.5

	add_child(_light)

	call_deferred("_resolve_controller")

	call_deferred("_sync_visual")





func _resolve_controller() -> void:

	if controller_path != NodePath():

		_controller = get_node_or_null(controller_path) as StormConduitPuzzle





func _sync_visual() -> void:

	var active := _is_conduit_active()

	if _light:

		_light.light_energy = 1.1 if active else 0.0

	prompt_text = "Storm conduit active" if active else "Activate storm conduit"





func _is_conduit_active() -> bool:

	match conduit_id:

		"conduit_a": return CitadelState.conduit_a

		"conduit_b": return CitadelState.conduit_b

		"conduit_c": return CitadelState.conduit_c

	return false





func _on_interact(_player: Node) -> void:

	if _controller == null:

		_controller = get_parent() as StormConduitPuzzle

	if _controller == null:

		DialogueManager.start_dialogue("citadel_conduit_stuck", [

			{"speaker": "Conduit", "text": "Salt-crusted machinery refuses to turn."},

		], [], {"from_interact": true})

		return

	_controller.toggle_conduit(conduit_id)

	_sync_visual()

