extends Node3D
## Instantiates a GLTF/OBJ mesh via MeshLoader.

signal visual_ready

const _Tint = preload("res://scripts/utilities/kenney_material_tint.gd")

@export var gltf_path: String = ""
@export var mesh_yaw_degrees: float = 0.0
@export var mesh_offset: Vector3 = Vector3.ZERO
@export var mesh_scale: Vector3 = Vector3.ONE
@export var apply_dark_tint: bool = true
@export var is_water: bool = false
@export var fallback_kind: String = "prop"

var _loaded: bool = false


func _ready() -> void:
	_setup_visual()


func _setup_visual() -> void:
	if gltf_path == "":
		return
	for child in get_children():
		child.queue_free()
	var yaw := mesh_yaw_degrees
	if yaw == 0.0 and _needs_character_yaw(gltf_path):
		yaw = 180.0
	var resolved := MeshLoader.normalize_asset_path(gltf_path)
	var visual := MeshLoader.instantiate(resolved, self, yaw, mesh_offset, mesh_scale)
	if visual == null:
		push_warning("GltfVisual: failed to load %s — using fallback" % gltf_path)
		var kind := fallback_kind
		if kind == "prop" and resolved.contains("tree"):
			kind = "tree"
		elif kind == "prop" and resolved.contains("rock"):
			kind = "rock"
		MeshLoader.create_fallback_prop(kind, self, mesh_offset, mesh_scale)
		_loaded = true
		visual_ready.emit()
		return
	if is_water:
		for child in visual.get_children():
			if child is MeshInstance3D:
				_Tint.apply_water_material(child as MeshInstance3D)
	_loaded = true
	visual_ready.emit()


func is_loaded() -> bool:
	return _loaded


func _needs_character_yaw(path: String) -> bool:
	var lower := path.to_lower()
	return lower.contains("/characters/") or lower.contains("player")
