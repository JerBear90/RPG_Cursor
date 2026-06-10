@tool
extends TextureProgressBar
## Kenney UI Pack horizontal bar (track + fill).

@export var kenney_color: String = "Red":
	set(v):
		kenney_color = v
		_apply_textures()


func _ready() -> void:
	fill_mode = FILL_LEFT_TO_RIGHT
	show_percentage = false
	custom_minimum_size = Vector2(220, 22)
	_apply_textures()


func _apply_textures() -> void:
	texture_under = KenneyUiPaths.load_tex(KenneyUiPaths.bar_track(kenney_color))
	texture_progress = KenneyUiPaths.load_tex(KenneyUiPaths.bar_fill(kenney_color))
