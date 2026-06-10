extends Node
## Briefly runs Darkpine Forest and captures a gameplay screenshot.

const OUTPUT := "res://docs/screenshots/level_preview.png"
const LEVEL := preload("res://scenes/levels/darkpine_forest/darkpine_forest.tscn")


func _ready() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 800))
	call_deferred("_run")


func _run() -> void:
	var level := LEVEL.instantiate()
	add_child(level)
	GameManager.active_player_count = 1
	GameManager.game_started = true
	for _i in 30:
		await get_tree().process_frame
	await get_tree().create_timer(2.0).timeout
	var texture: ViewportTexture = get_viewport().get_texture()
	var image: Image = texture.get_image()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/screenshots"))
	var path := ProjectSettings.globalize_path(OUTPUT)
	var err: Error = image.save_png(path)
	print("Level screenshot %s: %s" % ["saved" if err == OK else "failed", path])
	get_tree().quit(0 if err == OK else 1)
