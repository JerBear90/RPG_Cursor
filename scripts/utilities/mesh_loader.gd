class_name MeshLoader
extends RefCounted
## Loads GLTF/GLB scenes and instantiates Kenney/CC0 visuals.

const _Tint = preload("res://scripts/utilities/kenney_material_tint.gd")


static func load_scene(path: String) -> PackedScene:
	if path == "" or not ResourceLoader.exists(path):
		return null
	var res: Resource = load(path)
	if res is PackedScene:
		return res as PackedScene
	return null


static func instantiate(path: String, parent: Node3D, yaw_degrees: float = 0.0, offset: Vector3 = Vector3.ZERO, scale: Vector3 = Vector3.ONE) -> Node3D:
	var packed := load_scene(path)
	if packed == null:
		return null
	var visual: Node3D = packed.instantiate()
	parent.add_child(visual)
	visual.rotation_degrees = Vector3(0.0, yaw_degrees, 0.0)
	visual.position = offset
	visual.scale = scale
	if path.contains("kenney"):
		_Tint.apply_to_node(visual)
	return visual
