extends SceneTree
## Captures minimap from actual Darkpine Forest gameplay HUD.

const LEVEL := "res://scenes/levels/darkpine_forest/darkpine_forest.tscn"
const OUTPUT := "res://tests/minimap_gameplay_1920.png"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var win := Window.new()
	win.size = Vector2i(1920, 1080)
	win.unresizable = true
	root.add_child(win)
	await process_frame
	var level_scene := load(LEVEL) as PackedScene
	var level: Node = level_scene.instantiate()
	win.add_child(level)
	await process_frame
	await process_frame
	await create_timer(2.0).timeout
	var img := win.get_viewport().get_texture().get_image()
	if img:
		img.save_png(ProjectSettings.globalize_path(OUTPUT))
		print("Saved ", OUTPUT)
	else:
		print("Failed to capture texture")
	win.queue_free()
	quit()
