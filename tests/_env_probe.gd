extends SceneTree

const _Kenney = preload("res://scripts/utilities/kenney_paths.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var grass_path: String = _Kenney.nature("ground_grass.glb")
	var tree_path: String = _Kenney.nature("tree_pineDefaultA.glb")
	print("grass_path=", grass_path, " exists=", FileAccess.file_exists(grass_path))
	var root := Node3D.new()
	get_root().add_child(root)
	var g: Node3D = MeshLoader.instantiate(grass_path, root, 0, Vector3.ZERO, Vector3.ONE)
	var t: Node3D = MeshLoader.instantiate(tree_path, root, 0, Vector3(3, 0, 0), Vector3.ONE)
	print("grass_ok=", g != null, " tree_ok=", t != null)
	var packed := load("res://scenes/levels/darkpine_forest/darkpine_forest.tscn") as PackedScene
	var level: Node3D = packed.instantiate()
	get_root().add_child(level)
	var props_count := 0
	var land_count := 0
	for i in 360:
		await process_frame
		var terrain := get_root().find_child("IslandTerrain", true, false) as Node3D
		if terrain:
			land_count = terrain.get_node("Land").get_child_count()
			props_count = terrain.get_node("Props").get_child_count()
	print("final land=", land_count, " props=", props_count)
	var town := get_root().find_child("TownProps", true, false) as Node3D
	print("town=", town.get_child_count() if town else 0)
	quit(0 if g != null and t != null and props_count > 40 else 1)
