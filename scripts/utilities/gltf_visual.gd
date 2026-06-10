extends Node3D
## Instantiates a GLTF mesh via MeshLoader.

const _Tint = preload("res://scripts/utilities/kenney_material_tint.gd")

@export var gltf_path: String = ""
@export var mesh_yaw_degrees: float = 0.0
@export var mesh_offset: Vector3 = Vector3.ZERO
@export var mesh_scale: Vector3 = Vector3.ONE
@export var apply_dark_tint: bool = true
@export var is_water: bool = false

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
	if is_water:
		for child in visual.get_children():
			if child is MeshInstance3D:
				_Tint.apply_water_material(child as MeshInstance3D)
	_loaded = true


func is_loaded() -> bool:
	return _loaded
