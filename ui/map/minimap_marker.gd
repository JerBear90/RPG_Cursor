extends Control
class_name MinimapMarker
## Edge-clamped minimap marker with optional distance label.

@onready var _icon: Control = %IconDraw
@onready var _distance: Label = %DistanceLabel

var category: int = MinimapRegistry.Category.UNKNOWN


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _distance:
		ArpgTheme.style_label(_distance, 10, UiColors.TEXT_PRIMARY)


func configure(cat: int, distance_text: String = "", ui_scale: float = 1.0) -> void:
	category = cat
	if _distance:
		var font_sz := maxi(8, int(round(10.0 * ui_scale)))
		ArpgTheme.style_label(_distance, font_sz, UiColors.TEXT_PRIMARY)
		_distance.text = distance_text
		_distance.visible = distance_text != ""


func _draw() -> void:
	MinimapIconRegistry.draw_marker(self, size * 0.5, category, 0.85)
