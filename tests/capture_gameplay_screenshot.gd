extends SceneTree

const OUTPUT := "res://docs/screenshots/gameplay_boot.png"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 800))
	var gm := get_root().get_node("GameManager")
	gm.start_new_game(false)
	for i in 150:
		await process_frame
	var terrain := get_root().find_child("IslandTerrain", true, false)
	var props := 0
	var land := 0
	if terrain:
		land = terrain.get_node("Land").get_child_count()
		props = terrain.get_node("Props").get_child_count()
	print("land=%d props=%d" % [land, props])
	await create_timer(0.5).timeout
	var image: Image = get_root().get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/screenshots"))
	var path := ProjectSettings.globalize_path(OUTPUT)
	image.save_png(path)
	print("screenshot saved ", path)
	quit(0 if land > 100 and props > 40 else 1)
