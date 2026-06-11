extends Control
class_name StatusBar
## Thin labeled progress bar for stamina, hunger, thirst, XP, boss health.

@export var bar_color: Color = UiColors.STAMINA_FILL
@export var bar_height: float = UiMetrics.STAT_BAR_HEIGHT
@export var show_label: bool = true

@onready var _label: Label = %BarLabel
@onready var _bar: TextureProgressBar = %BarFill


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _bar:
		ArpgTheme.style_progress_bar(_bar, bar_color, bar_height)
	if _label and not show_label:
		_label.visible = false


func set_label(text: String) -> void:
	if _label:
		_label.text = text
		ArpgTheme.style_label(_label, UiMetrics.FONT_XS, UiColors.TEXT_MUTED)


func set_values(current: float, maximum: float, animate: bool = true) -> void:
	if _bar == null:
		return
	_bar.max_value = maximum
	if animate:
		var tween := create_tween()
		tween.tween_property(_bar, "value", current, 0.18)
	else:
		_bar.value = current


func get_bar() -> TextureProgressBar:
	return _bar
