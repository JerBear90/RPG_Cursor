extends Control
class_name XpBar
## Experience bar beneath the ability row — framed, animated, hover detail.

@onready var _frame: PanelContainer = %XpFrame
@onready var _bar: ThinBar = %XpFill
@onready var _hover_label: Label = %XpHoverLabel
@onready var _glow: ColorRect = %XpGlow

var _display: float = 0.0
var _target: float = 0.0
var _max: float = 100.0
var _hover: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	custom_minimum_size = Vector2(UiMetrics.ABILITY_SLOT_SIZE * UiMetrics.ABILITY_SLOT_COUNT + UiMetrics.SPACE_SM * (UiMetrics.ABILITY_SLOT_COUNT - 1), 0)
	if _frame:
		_frame.add_theme_stylebox_override("panel", ArpgTheme.make_panel(UiColors.PANEL_BG_DEEP, UiColors.BORDER_MUTED, UiMetrics.RADIUS_SM))
	if _bar:
		_bar.set_bar_color(UiColors.XP_FILL)
		_bar.set_bar_height(UiMetrics.BAR_XP)
		_bar.max_value = _max
		_bar.value = _display
	if _hover_label:
		ArpgTheme.style_label(_hover_label, UiMetrics.FONT_META, UiColors.TEXT_QUEST)
		_hover_label.visible = false
	if _glow:
		_glow.color = Color(UiColors.XP_FILL.r, UiColors.XP_FILL.g, UiColors.XP_FILL.b, 0.0)
		_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


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
	if _glow == null:
		return
	var tween := create_tween()
	_glow.color = Color(UiColors.XP_FILL.r, UiColors.XP_FILL.g, UiColors.XP_FILL.b, 0.35)
	tween.tween_property(_glow, "color:a", 0.0, 0.45)
