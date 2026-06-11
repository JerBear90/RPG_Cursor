extends SceneTree

const _Kenney = preload("res://scripts/utilities/kenney_paths.gd")
const _ObjLoader = preload("res://scripts/utilities/obj_loader.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var path: String = _Kenney.nature("ground_grass.glb")
	print("path=", path)
	print("ResourceLoader.exists=", ResourceLoader.exists(path))
	var parsed := _ObjLoader._parse_obj(path)
	print("parsed groups=", parsed.size())
	if parsed.size() > 0:
		print("  group0 mesh surfaces=", parsed[0].mesh.get_surface_count())
		var root := Node3D.new()
		var mi := MeshInstance3D.new()
		mi.mesh = parsed[0].mesh
		root.add_child(mi)
		print("manual root children=", root.get_child_count())
		var manual := PackedScene.new()
		print("manual pack err=", manual.pack(root))
		var manual_inst := manual.instantiate()
		print("manual inst children=", manual_inst.get_child_count())
		var root2 := Node3D.new()
		var mi2 := MeshInstance3D.new()
		mi2.mesh = BoxMesh.new()
		root2.add_child(mi2)
		var box_packed := PackedScene.new()
		box_packed.pack(root2)
		print("box inst children=", box_packed.instantiate().get_child_count())
	if ResourceLoader.exists(path):
		var res: Resource = load(path)
		print("load type=", res.get_class() if res else "null")
		if res is PackedScene:
			var n := (res as PackedScene).instantiate()
			print("imported scene child_count=", n.get_child_count())
			for c in n.get_children():
				print("  ", c.name, c.get_class())
	var obj_scene := _ObjLoader.load_packed_scene(path)
	print("ObjLoader scene=", obj_scene)
	if obj_scene:
		var st := obj_scene.get_state()
		print("packed node_count=", st.get_node_count())
		for i in st.get_node_count():
			print("  node ", i, " name=", st.get_node_name(i), " type=", st.get_node_type(i), " parent=", st.get_node_path(i))
		var n2 := obj_scene.instantiate()
		print("obj scene child_count=", n2.get_child_count())
	quit(0)
