@tool
extends TextureProgressBar
## Kenney UI Pack horizontal bar (track + fill).

@export var kenney_color: String = "Red":
	set(v):
		kenney_color = v
		_apply_textures()


func _ready() -> void:
	fill_mode = FILL_LEFT_TO_RIGHT
	custom_minimum_size = Vector2(220, 22)
	_apply_textures()


func _apply_textures() -> void:
	texture_under = KenneyUiPaths.load_tex(KenneyUiPaths.bar_track(kenney_color))
	texture_progress = KenneyUiPaths.load_tex(KenneyUiPaths.bar_fill(kenney_color))
	if texture_under == null:
		texture_under = KenneyUiPaths.solid_tex(Color(0.12, 0.12, 0.16, 0.95), Vector2i(256, 24))
	if texture_progress == null:
		texture_progress = KenneyUiPaths.solid_tex(_fill_color(kenney_color), Vector2i(256, 24))
	modulate = Color.WHITE


static func _fill_color(folder: String) -> Color:
	match folder:
		"Red":
			return Color(0.78, 0.18, 0.14)
		"Yellow":
			return Color(0.85, 0.72, 0.18)
		"Blue":
			return Color(0.22, 0.48, 0.82)
		"Green":
			return Color(0.22, 0.62, 0.28)
		_:
			return Color(0.55, 0.55, 0.6)
