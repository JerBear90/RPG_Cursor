extends TextureProgressBar
class_name ThinBar
## Themed thin progress bar — no Kenney textures, no default Godot styling.

@export var bar_fill: Color = UiColors.HEALTH_FILL
@export var bar_height: float = 6.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	fill_mode = FILL_LEFT_TO_RIGHT
	_apply()


func set_bar_color(color: Color) -> void:
	bar_fill = color
	_apply()


func set_bar_height(height: float) -> void:
	bar_height = height
	_apply()


func _apply() -> void:
	custom_minimum_size = Vector2(48, bar_height)
	ArpgTheme.style_progress_bar(self, bar_fill, bar_height)
