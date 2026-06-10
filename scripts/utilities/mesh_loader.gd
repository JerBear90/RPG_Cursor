class_name MeshLoader
extends RefCounted
## Loads GLTF/GLB/OBJ scenes and instantiates Kenney/CC0 visuals.

const _Tint = preload("res://scripts/utilities/kenney_material_tint.gd")
const _ObjLoader = preload("res://scripts/utilities/obj_loader.gd")

static var _scene_cache: Dictionary = {}


static func clear_scene_cache() -> void:
	_scene_cache.clear()


static func load_scene(path: String) -> PackedScene:
	if path == "":
		return null
	path = normalize_asset_path(path)
	if _scene_cache.has(path):
		return _scene_cache[path] as PackedScene
	var packed: PackedScene = null
	if path.ends_with(".obj") and FileAccess.file_exists(path):
		packed = _ObjLoader.load_packed_scene(path)
	if packed == null and ResourceLoader.exists(path):
		var res: Resource = load(path)
		if res is PackedScene:
			packed = res as PackedScene
	if packed == null and FileAccess.file_exists(path):
		if path.ends_with(".gltf") or path.ends_with(".glb"):
			packed = _load_gltf_runtime(path)
		elif path.ends_with(".obj"):
			packed = _ObjLoader.load_packed_scene(path)
	if packed != null and not _packed_scene_has_mesh(packed):
		packed = null
	if packed != null:
		_scene_cache[path] = packed
	return packed


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
	_set_owner_recursive(root, root)
	var packed := PackedScene.new()
	if packed.pack(root) != OK:
		root.queue_free()
		return null
	root.queue_free()
	return packed


static func _set_owner_recursive(node: Node, owner: Node) -> void:
	for child in node.get_children():
		child.owner = owner
		_set_owner_recursive(child, owner)


static func _packed_scene_has_mesh(packed: PackedScene) -> bool:
	var probe: Node = packed.instantiate()
	var ok := _node_has_mesh(probe)
	probe.queue_free()
	return ok


static func _node_has_mesh(node: Node) -> bool:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		return true
	for child in node.get_children():
		if _node_has_mesh(child):
			return true
	return false


static func instantiate(path: String, parent: Node3D, yaw_degrees: float = 0.0, offset: Vector3 = Vector3.ZERO, scale: Vector3 = Vector3.ONE) -> Node3D:
	path = normalize_asset_path(path)
	var visual: Node3D = null
	if path.ends_with(".obj") and FileAccess.file_exists(path):
		visual = _ObjLoader.instantiate(path, parent)
	if visual == null:
		var packed := load_scene(path)
		if packed == null:
			return null
		visual = packed.instantiate()
		parent.add_child(visual)
	if visual == null or not _node_has_mesh(visual):
		if visual:
			visual.queue_free()
		return null
	visual.rotation_degrees = Vector3(0.0, yaw_degrees, 0.0)
	visual.position = offset
	visual.scale = scale
	if path.contains("kenney") or path.contains("nature_kit"):
		_Tint.apply_to_node(visual, 1.08, 1.0)
	return visual


static func create_fallback_prop(kind: String, parent: Node3D, offset: Vector3, scale: Vector3) -> Node3D:
	var root := Node3D.new()
	root.name = "Fallback_%s" % kind
	root.position = offset
	root.scale = scale
	var mi := MeshInstance3D.new()
	var mat := StandardMaterial3D.new()
	mat.roughness = 0.88
	match kind:
		"tree":
			var cone := CylinderMesh.new()
			cone.top_radius = 0.05
			cone.bottom_radius = 0.55
			cone.height = 1.6
			mi.mesh = cone
			mi.position = Vector3(0, 1.5, 0)
			mat.albedo_color = Color(0.22, 0.58, 0.28)
			var trunk := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.12
			cyl.bottom_radius = 0.16
			cyl.height = 0.7
			trunk.mesh = cyl
			trunk.position = Vector3(0, 0.35, 0)
			var bark := StandardMaterial3D.new()
			bark.albedo_color = Color(0.45, 0.3, 0.18)
			trunk.material_override = bark
			root.add_child(trunk)
		"rock":
			var sph := SphereMesh.new()
			sph.radius = 0.45
			sph.height = 0.5
			mi.mesh = sph
			mi.position = Vector3(0, 0.25, 0)
			mat.albedo_color = Color(0.42, 0.4, 0.38)
		"prop":
			var box := BoxMesh.new()
			box.size = Vector3(0.8, 0.8, 0.8)
			mi.mesh = box
			mi.position = Vector3(0, 0.4, 0)
			mat.albedo_color = Color(0.55, 0.42, 0.28)
		_:
			var plane := BoxMesh.new()
			plane.size = Vector3(1.8, 0.12, 1.8)
			mi.mesh = plane
			mi.position = Vector3(0, 0.06, 0)
			mat.albedo_color = Color(0.25, 0.62, 0.32)
	mi.material_override = mat
	root.add_child(mi)
	parent.add_child(root)
	return root
