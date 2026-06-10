extends SceneTree

const _Kenney = preload("res://scripts/utilities/kenney_paths.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var root := Node3D.new()
	get_root().add_child(root)

	# Control: bright red cube (must render if 3D pipeline works)
	var cube_mi := MeshInstance3D.new()
	var cube_mesh := BoxMesh.new()
	cube_mesh.size = Vector3(2, 2, 2)
	cube_mi.mesh = cube_mesh
	var cube_mat := StandardMaterial3D.new()
	cube_mat.albedo_color = Color.RED
	cube_mi.material_override = cube_mat
	cube_mi.position = Vector3(-4, 1, 0)
	root.add_child(cube_mi)

	var grass_path: String = _Kenney.nature("ground_grass.glb")
	var tree_path: String = _Kenney.nature("tree_pineDefaultA.glb")
	var grass: Node3D = MeshLoader.instantiate(grass_path, root, 0, Vector3(0, 0, 0), Vector3(2.15, 1, 2.15))
	var tree: Node3D = MeshLoader.instantiate(tree_path, root, 0, Vector3(4, 0, 0), Vector3.ONE)

	_dump_node("grass", grass)
	_dump_node("tree", tree)

	var packed := load("res://scenes/levels/darkpine_forest/darkpine_forest.tscn") as PackedScene
	var level: Node3D = packed.instantiate()
	get_root().add_child(level)
	for i in 120:
		await process_frame
	var terrain := get_root().find_child("IslandTerrain", true, false)
	if terrain:
		var land := terrain.get_node("Land")
		var props := terrain.get_node("Props")
		print("terrain land_children=", land.get_child_count(), " props_children=", props.get_child_count())
		for child in land.get_children():
			if child is Node3D and not child is StaticBody3D and not child is MeshInstance3D:
				_dump_node("land_child_%s" % child.name, child as Node3D)
				break
		for child in props.get_children():
			if child is Node3D and not child is StaticBody3D:
				_dump_node("prop_%s" % child.name, child as Node3D)
				break
	if DisplayServer.get_name() != "headless":
		await create_timer(0.3).timeout
		var img: Image = get_root().get_viewport().get_texture().get_image()
		var out := ProjectSettings.globalize_path("res://docs/screenshots/mesh_diagnose.png")
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/screenshots"))
		img.save_png(out)
		print("screenshot=", out)
	quit(0)


func _dump_node(label: String, node: Node3D) -> void:
	if node == null:
		print("%s: NULL" % label)
		return
	print("%s: in_tree=%s visible=%s pos=%s scale=%s child_count=%d" % [
		label, node.is_inside_tree(), node.visible, node.position, node.scale, node.get_child_count()
	])
	for child in node.get_children():
		print("  child %s type=%s" % [child.name, child.get_class()])
		if child is MeshInstance3D:
			var mi := child as MeshInstance3D
			var m := mi.mesh
			var surfaces := m.get_surface_count() if m else 0
			var aabb := m.get_aabb() if m else AABB()
			print("  MI %s mesh=%s surfaces=%d aabb=%s mat_override=%s visible=%s" % [
				mi.name, m, surfaces, aabb, mi.material_override != null, mi.visible
			])
