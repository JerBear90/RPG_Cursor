extends Node3D
## Instantiates a GLTF mesh via MeshLoader.

@export var gltf_path: String = ""
@export var mesh_yaw_degrees: float = 0.0
@export var mesh_offset: Vector3 = Vector3.ZERO
@export var mesh_scale: Vector3 = Vector3.ONE

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


func is_loaded() -> bool:
	return _loaded
