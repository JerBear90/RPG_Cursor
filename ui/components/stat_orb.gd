@tool
extends Control
class_name StatOrb
## Compact vital stat bar with animated fill, damage flash, and low-health pulse.

signal value_updated(current: float, maximum: float)

@export var title: String = "HEALTH"
@export var fill_color: Color = UiColors.HEALTH_FILL
@export var is_health: bool = true
@export var low_health_threshold: float = 0.25

@onready var _title_label: Label = %TitleLabel
@onready var _fill_bar: TextureProgressBar = %FillBar
@onready var _value_label: Label = %ValueLabel
@onready var _flash: ColorRect = %FlashOverlay

var _display_value: float = 100.0
var _target_value: float = 100.0
var _max_value: float = 100.0
var _flash_tween: Tween
var _pulse_time: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _title_label:
		_title_label.text = title
		ArpgTheme.style_label(_title_label, UiMetrics.FONT_XS, UiColors.TEXT_MUTED)
	if _value_label:
		ArpgTheme.style_label(_value_label, UiMetrics.FONT_MD, UiColors.TEXT_PRIMARY)
	if _fill_bar:
		var h := UiMetrics.STAT_BAR_HEIGHT_HP if is_health else UiMetrics.STAT_BAR_HEIGHT
		ArpgTheme.style_progress_bar(_fill_bar, fill_color, h)
	if _flash:
		_flash.color = Color(UiColors.HEALTH_FLASH.r, UiColors.HEALTH_FLASH.g, UiColors.HEALTH_FLASH.b, 0.0)
		_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_values(current: float, maximum: float, animate: bool = true) -> void:
	var prev := _target_value
	_max_value = maxf(maximum, 1.0)
	_target_value = clampf(current, 0.0, _max_value)
	if is_health and _target_value < prev:
		_flash_damage()
	if not animate:
		_display_value = _target_value
		_apply_bar()
	else:
		_start_value_tween()
	value_updated.emit(_target_value, _max_value)


func _start_value_tween() -> void:
	var tween := create_tween()
	tween.tween_method(_set_display_value, _display_value, _target_value, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _set_display_value(v: float) -> void:
	_display_value = v
	_apply_bar()


func _apply_bar() -> void:
	if _fill_bar:
		_fill_bar.max_value = _max_value
		_fill_bar.value = _display_value
	if _value_label:
		_value_label.text = "%d / %d" % [int(_display_value), int(_max_value)]


func flash_damage() -> void:
	if _flash == null:
		return
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash_tween = create_tween()
	_flash.color.a = 0.0
	_flash_tween.tween_property(_flash, "color:a", 0.55, 0.06)
	_flash_tween.tween_property(_flash, "color:a", 0.0, 0.28)


func _process(delta: float) -> void:
	if not is_health or _max_value <= 0.0:
		modulate = Color.WHITE
		return
	var pct := _display_value / _max_value
	if pct <= low_health_threshold and pct > 0.0:
		_pulse_time += delta * 3.5
		var pulse := 0.88 + sin(_pulse_time) * 0.12
		modulate = Color(pulse, pulse * 0.92, pulse * 0.92, 1.0)
	else:
		modulate = Color.WHITE
		_pulse_time = 0.0
