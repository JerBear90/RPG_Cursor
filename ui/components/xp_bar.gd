extends Control
class_name XpBar
## Experience bar beneath the ability row — framed, animated, hover detail.

## Matches SkillRow width: 6 slots @ 48px + 5 gaps @ 6px.
const OUTER_WIDTH := (
	UiMetrics.ABILITY_SLOT_SIZE * UiMetrics.ABILITY_SLOT_COUNT
	+ 6.0 * (UiMetrics.ABILITY_SLOT_COUNT - 1)
)
const FRAME_PAD_H := 12.0

@onready var _frame: PanelContainer = %XpFrame
@onready var _bar: ProgressBar = %XpFill
@onready var _hover_label: Label = %XpHoverLabel

var _display: float = 0.0
var _target: float = 0.0
var _max: float = 100.0
var _hover: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	custom_minimum_size = Vector2(OUTER_WIDTH, maxf(UiMetrics.BAR_XP + 8.0, 18.0))
	if _frame:
		var panel_style := ArpgTheme.make_panel(UiColors.PANEL_BG_DEEP, UiColors.BORDER_MUTED, UiMetrics.RADIUS_SM)
		panel_style.content_margin_left = 0
		panel_style.content_margin_top = 0
		panel_style.content_margin_right = 0
		panel_style.content_margin_bottom = 0
		_frame.add_theme_stylebox_override("panel", panel_style)
	_configure_fill_bar()
	if _hover_label:
		ArpgTheme.style_label(_hover_label, UiMetrics.FONT_META, UiColors.TEXT_QUEST)
		_hover_label.visible = false
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _configure_fill_bar() -> void:
	if _bar == null:
		return
	_bar.min_value = 0.0
	_bar.max_value = _max
	_bar.value = _display
	_bar.show_percentage = false
	_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bar.size_flags_vertical = Control.SIZE_FILL
	_bar.custom_minimum_size = Vector2(0, UiMetrics.BAR_XP)
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.08, 0.09, 0.11, 0.95)
	track.set_corner_radius_all(2)
	track.set_content_margin_all(0)
	var fill := StyleBoxFlat.new()
	fill.bg_color = UiColors.XP_FILL
	fill.set_corner_radius_all(2)
	fill.set_content_margin_all(0)
	_bar.add_theme_stylebox_override("background", track)
	_bar.add_theme_stylebox_override("fill", fill)


func get_outer_width() -> float:
	return size.x if size.x > 0.0 else OUTER_WIDTH


func get_inner_track_width() -> float:
	if _bar and _bar.size.x > 0.0:
		return _bar.size.x
	return maxf(OUTER_WIDTH - FRAME_PAD_H, 0.0)


func get_fill_width() -> float:
	var inner := get_inner_track_width()
	if _max <= 0.0:
		return 0.0
	return inner * clampf(_display / _max, 0.0, 1.0)


func set_values(current: float, maximum: float, animate: bool = true) -> void:
	var prev := _target
	_max = maxf(maximum, 1.0)
	_target = clampf(current, 0.0, _max)
	if _target > prev:
		_flash_gain()
	if not animate:
		_display = _target
		_apply_values()
	else:
		var tween := create_tween()
		tween.tween_method(_set_display, _display, _target, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_update_hover_text()


func _set_display(v: float) -> void:
	_display = v
	_apply_values()


func _apply_values() -> void:
	if _bar:
		_bar.max_value = _max
		_bar.value = _display
	_update_hover_text()


func _update_hover_text() -> void:
	if _hover_label == null:
		return
	var pct := (_display / _max * 100.0) if _max > 0.0 else 0.0
	_hover_label.text = "%.0f / %.0f  (%.0f%%)" % [_display, _max, pct]
	_hover_label.visible = _hover


func _on_mouse_entered() -> void:
	_hover = true
	_update_hover_text()


func _on_mouse_exited() -> void:
	_hover = false
	if _hover_label:
		_hover_label.visible = false


func _flash_gain() -> void:
	if _bar == null:
		return
	var tween := create_tween()
	_bar.modulate = Color(1.15, 1.05, 0.85, 1.0)
	tween.tween_property(_bar, "modulate", Color.WHITE, 0.45)
