extends Node3D
## Instantiates a GLTF character/prop mesh; keeps placeholder visible on failure.

@export var gltf_path: String = ""
@export var mesh_yaw_degrees: float = 0.0
@export var mesh_offset: Vector3 = Vector3.ZERO
@export var mesh_scale: Vector3 = Vector3.ONE
@export var hide_mesh_node: NodePath = NodePath("../BodyMesh")

var _loaded: bool = false


func _ready() -> void:
	call_deferred("_setup_visual")


func _setup_visual() -> void:
	if gltf_path == "":
		return
	for child in get_children():
		child.queue_free()
	var visual := MeshLoader.instantiate(gltf_path, self, mesh_yaw_degrees, mesh_offset, mesh_scale)
	if visual == null:
		push_warning("GltfVisual: failed to load %s" % gltf_path)
		return
	_loaded = true
	if hide_mesh_node != NodePath():
		var mesh_node := get_node_or_null(hide_mesh_node)
		if mesh_node is MeshInstance3D:
			(mesh_node as MeshInstance3D).visible = false


func is_loaded() -> bool:
	return _loaded
