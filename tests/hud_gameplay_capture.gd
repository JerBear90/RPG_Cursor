extends SceneTree
## Captures gameplay HUD from Darkpine Forest at 1920x1080.

const OUTPUT := "res://tests/hud_layout_1920.png"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var win := Window.new()
	win.size = Vector2i(1920, 1080)
	root.add_child(win)
	await process_frame
	var scene := load("res://scenes/levels/darkpine_forest/darkpine_forest.tscn") as PackedScene
	var level: Node = scene.instantiate()
	win.add_child(level)
	for _i in 60:
		await process_frame
	var img := win.get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUTPUT))
	print("Saved gameplay HUD to ", OUTPUT)
	level.queue_free()
	win.queue_free()
	quit()
