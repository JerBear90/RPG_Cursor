extends SceneTree
## Captures HUD showcase screenshot at 1920x1080.

const OUTPUT := "res://tests/hud_showcase_1920.png"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var win := Window.new()
	win.title = "HUD Showcase"
	win.size = Vector2i(1920, 1080)
	win.unresizable = true
	root.add_child(win)
	await process_frame
	var scene := load("res://ui/hud/hud_preview.tscn") as PackedScene
	var preview: Node = scene.instantiate()
	win.add_child(preview)
	await process_frame
	await process_frame
	await process_frame
	var img := win.get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUTPUT))
	print("Saved showcase to ", OUTPUT)
	win.queue_free()
	quit()
