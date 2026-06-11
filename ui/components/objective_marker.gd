extends Control
class_name ObjectiveMarker
## Small legend icon row for map UI.

@export var marker_label: String = "Quest"
@export var marker_color: Color = UiColors.TEXT_QUEST

@onready var _swatch: ColorRect = %Swatch
@onready var _label: Label = %MarkerLabel


func _ready() -> void:
	if _swatch:
		_swatch.color = marker_color
	if _label:
		_label.text = marker_label
		ArpgTheme.style_label(_label, UiMetrics.FONT_XS, UiColors.TEXT_SECONDARY)
