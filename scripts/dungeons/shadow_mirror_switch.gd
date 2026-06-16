class_name ShadowMirrorSwitch
extends InteractableBase

@export var ward_id: String = "ward_a"
@export var controller_path: NodePath

var _controller: ShadowMirrorPuzzle
var _light: OmniLight3D


func _ready() -> void:
	super._ready()
	prompt_text = "Activate shadow ward"
	add_to_group("shadow_mirror_switch")
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
	_light.light_color = Color(0.45, 0.55, 0.95)
	_light.light_energy = 0.0
	_light.omni_range = 3.5
	add_child(_light)
	call_deferred("_resolve_controller")
	call_deferred("_sync_visual")


func _resolve_controller() -> void:
	if controller_path != NodePath():
		_controller = get_node_or_null(controller_path) as ShadowMirrorPuzzle


func _sync_visual() -> void:
	var active := _is_ward_active()
	if _light:
		_light.light_energy = 1.2 if active else 0.0
	prompt_text = "Shadow ward active" if active else "Activate shadow ward"


func _is_ward_active() -> bool:
	match ward_id:
		"ward_a": return EclipseSanctumState.ward_a
		"ward_b": return EclipseSanctumState.ward_b
		"ward_c": return EclipseSanctumState.ward_c
	return false


func _on_interact(_player: Node) -> void:
	if _controller == null:
		_controller = get_parent() as ShadowMirrorPuzzle
	if _controller == null:
		DialogueManager.start_dialogue("eclipse_ward_stuck", [
			{"speaker": "Shadow Ward", "text": "Umbral gears refuse to turn the ward frame."},
		], [], {"from_interact": true})
		return
	_controller.toggle_ward(ward_id)
	_sync_visual()
