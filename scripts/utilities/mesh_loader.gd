class_name MeshLoader
extends RefCounted
## Loads GLTF/GLB/OBJ scenes and instantiates Kenney/CC0 visuals.

const _Tint = preload("res://scripts/utilities/kenney_material_tint.gd")
const _ObjLoader = preload("res://scripts/utilities/obj_loader.gd")


static func load_scene(path: String) -> PackedScene:
	if path == "":
		return null
	path = normalize_asset_path(path)
	if ResourceLoader.exists(path):
		var res: Resource = load(path)
		if res is PackedScene:
			return res as PackedScene
	if FileAccess.file_exists(path):
		if path.ends_with(".gltf") or path.ends_with(".glb"):
			return _load_gltf_runtime(path)
		if path.ends_with(".obj"):
			return _ObjLoader.load_packed_scene(path)
	return null


static func normalize_asset_path(path: String) -> String:
	if path.contains("nature_kit") and path.contains("GLTF format"):
		path = path.replace("GLTF format", "OBJ format")
	if path.ends_with(".glb"):
		path = path.get_basename() + ".obj"
	return path


static func _load_gltf_runtime(path: String) -> PackedScene:
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if doc.append_from_file(path, state) != OK:
		return null
	var root: Node = doc.generate_scene(state)
	if root == null:
		return null
	var packed := PackedScene.new()
	if packed.pack(root) != OK:
		root.queue_free()
		return null
	root.queue_free()
	return packed


static func instantiate(path: String, parent: Node3D, yaw_degrees: float = 0.0, offset: Vector3 = Vector3.ZERO, scale: Vector3 = Vector3.ONE) -> Node3D:
	var packed := load_scene(path)
	if packed == null:
		return null
	var visual: Node3D = packed.instantiate()
	parent.add_child(visual)
	visual.rotation_degrees = Vector3(0.0, yaw_degrees, 0.0)
	visual.position = offset
	visual.scale = scale
	if path.contains("kenney") or path.contains("nature_kit"):
		_Tint.apply_to_node(visual)
	return visual
