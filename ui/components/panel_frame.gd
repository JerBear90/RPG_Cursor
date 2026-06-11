extends PanelContainer
class_name PanelFrame
## Styled panel wrapper with optional title.

@export var panel_title: String = ""

@onready var _title: Label = %FrameTitle


func _ready() -> void:
	add_theme_stylebox_override("panel", ArpgTheme.make_panel())
	if _title:
		if panel_title.is_empty():
			_title.visible = false
		else:
			_title.text = panel_title
			ArpgTheme.style_label(_title, UiMetrics.FONT_SM, UiColors.TEXT_QUEST)
