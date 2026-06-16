class_name MirrorSwitch
extends InteractableBase

@export var mirror_id: String = "mirror_a"
@export var controller_path: NodePath

var _controller: MirrorPuzzle
var _light: OmniLight3D


func _ready() -> void:
	super._ready()
	prompt_text = "Align solar mirror"
	add_to_group("mirror_switch")
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
	_light.light_color = Color(0.95, 0.65, 0.28)
	_light.light_energy = 0.0
	_light.omni_range = 3.5
	add_child(_light)
	call_deferred("_resolve_controller")
	call_deferred("_sync_visual")


func _resolve_controller() -> void:
	if controller_path != NodePath():
		_controller = get_node_or_null(controller_path) as MirrorPuzzle


func _sync_visual() -> void:
	var active := _is_mirror_aligned()
	if _light:
		_light.light_energy = 1.2 if active else 0.0
	prompt_text = "Solar mirror aligned" if active else "Align solar mirror"


func _is_mirror_aligned() -> bool:
	match mirror_id:
		"mirror_a": return PyreheartState.mirror_a
		"mirror_b": return PyreheartState.mirror_b
		"mirror_c": return PyreheartState.mirror_c
	return false


func _on_interact(_player: Node) -> void:
	if _controller == null:
		_controller = get_parent() as MirrorPuzzle
	if _controller == null:
		DialogueManager.start_dialogue("pyreheart_mirror_stuck", [
			{"speaker": "Mirror", "text": "Sand-choked gears refuse to turn the mirror frame."},
		], [], {"from_interact": true})
		return
	_controller.toggle_mirror(mirror_id)
	_sync_visual()
