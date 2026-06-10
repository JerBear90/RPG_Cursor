extends Node
## Captures a main-menu screenshot for docs/preview verification.

const OUTPUT := "res://docs/screenshots/preview.png"


func _ready() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 800))
	call_deferred("_capture")


func _capture() -> void:
	for _i in 8:
		await get_tree().process_frame
	await get_tree().create_timer(1.5).timeout
	var texture: ViewportTexture = get_viewport().get_texture()
	var image: Image = texture.get_image()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/screenshots"))
	var path := ProjectSettings.globalize_path(OUTPUT)
	var err: Error = image.save_png(path)
	print("Screenshot %s: %s" % ["saved" if err == OK else "failed", path])
	get_tree().quit(0 if err == OK else 1)
