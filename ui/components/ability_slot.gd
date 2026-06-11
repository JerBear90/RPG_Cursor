extends Control
class_name AbilitySlot
## Styled ability slot — icon, keybind badge, cooldown sweep, mana cost, full state support.

@onready var _frame: PanelContainer = %SlotFrame
@onready var _icon: TextureRect = %AbilityIcon
@onready var _key_badge: PanelContainer = %KeyBadge
@onready var _key_label: Label = %KeyLabel
@onready var _mana_label: Label = %ManaCost
@onready var _cooldown_bar: TextureProgressBar = %CooldownSweep
@onready var _cooldown_text: Label = %CooldownText
@onready var _lock_overlay: ColorRect = %LockOverlay
@onready var _empty_label: Label = %EmptyLabel

var _active: bool = false
var _selected: bool = false
var _disabled: bool = false
var _locked: bool = false
var _empty: bool = false
var _insufficient: bool = false
var _was_on_cd: bool = false
var _display_name: String = ""
var _ability_id: String = ""


func _ready() -> void:
	custom_minimum_size = Vector2(UiMetrics.ABILITY_SLOT_SIZE, UiMetrics.ABILITY_SLOT_SIZE)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_frame()
	if _icon:
		_icon.texture = UiIconRegistry.get_ability_icon("")
		_icon.custom_minimum_size = Vector2(UiMetrics.ICON_SLOT, UiMetrics.ICON_SLOT)
		_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if _key_badge:
		_key_badge.add_theme_stylebox_override("panel", ArpgTheme.make_keycap())
	if _key_label:
		ArpgTheme.style_label(_key_label, 11, UiColors.TEXT_PRIMARY)
	if _mana_label:
		ArpgTheme.style_label(_mana_label, 10, UiColors.TEXT_MUTED)
		_mana_label.visible = false
	if _cooldown_text:
		ArpgTheme.style_label(_cooldown_text, UiMetrics.FONT_MD, UiColors.TEXT_PRIMARY)
		_cooldown_text.visible = false
	if _cooldown_bar:
		_cooldown_bar.visible = false
		_cooldown_bar.fill_mode = TextureProgressBar.FILL_BOTTOM_TO_TOP
		_cooldown_bar.max_value = 1.0
		ArpgTheme.style_progress_bar(_cooldown_bar, UiColors.OVERLAY_DARK, UiMetrics.ABILITY_SLOT_SIZE - 8)
		_cooldown_bar.modulate = Color(1, 1, 1, 0.82)
	if _lock_overlay:
		_lock_overlay.color = Color(0.04, 0.05, 0.06, 0.55)
		_lock_overlay.visible = false
		_lock_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _empty_label:
		ArpgTheme.style_label(_empty_label, UiMetrics.FONT_META, UiColors.TEXT_MUTED)
		_empty_label.text = "+"
		_empty_label.visible = false


func configure(display_name: String, key_text: String, ability_id: String = "", mana_cost: int = -1, pad_text: String = "") -> void:
	_display_name = display_name
	_ability_id = ability_id
	_empty = ability_id.is_empty() and display_name.is_empty()
	if _key_label:
		_key_label.text = key_text
	if _icon:
		if _empty:
			_icon.texture = UiIconRegistry.get_icon("ability_default")
			_icon.modulate = Color(0.55, 0.55, 0.58, 0.6)
		elif _locked:
			_icon.texture = UiIconRegistry.get_icon("ability_locked")
			_icon.modulate = Color(0.7, 0.7, 0.72, 0.85)
		else:
			_icon.texture = UiIconRegistry.get_ability_icon(ability_id)
			_icon.modulate = Color.WHITE
	if _mana_label:
		if mana_cost >= 0 and not _empty:
			_mana_label.text = "%d" % mana_cost
			_mana_label.visible = true
		else:
			_mana_label.visible = false
	if _empty_label:
		_empty_label.visible = _empty
	var tip := display_name
	if pad_text != "" and pad_text != key_text:
		tip = "%s\nKeyboard: %s\nController: %s" % [display_name, key_text, pad_text]
	elif key_text != "":
		tip = "%s (%s)" % [display_name, key_text]
	tooltip_text = tip
	_apply_frame()


func set_active(active: bool) -> void:
	_active = active
	_apply_frame()
	if active:
		var t := create_tween()
		t.tween_property(_frame, "scale", Vector2(1.06, 1.06), 0.07)
		t.tween_property(_frame, "scale", Vector2.ONE, 0.10)


func set_selected(selected: bool) -> void:
	_selected = selected
	_apply_frame()


func set_disabled(disabled: bool) -> void:
	_disabled = disabled
	_apply_frame()


func set_locked(locked: bool) -> void:
	_locked = locked
	if _lock_overlay:
		_lock_overlay.visible = locked
	if _icon and not _empty:
		_icon.texture = UiIconRegistry.get_icon("ability_locked") if locked else UiIconRegistry.get_ability_icon(_ability_id)
	_apply_frame()


func set_empty(empty: bool) -> void:
	_empty = empty
	if _empty_label:
		_empty_label.visible = empty
	_apply_frame()


func set_insufficient_resource(insufficient: bool) -> void:
	_insufficient = insufficient
	if insufficient:
		var t := create_tween()
		t.tween_property(_frame, "modulate", Color(0.55, 0.62, 0.78, 1.0), 0.06)
		t.tween_property(_frame, "modulate", Color.WHITE if not _disabled else Color(0.62, 0.62, 0.64, 1.0), 0.22)
	_apply_frame()


func set_cooldown(ratio: float, seconds_left: float = -1.0) -> void:
	var r := clampf(ratio, 0.0, 1.0)
	if _cooldown_bar:
		_cooldown_bar.visible = r > 0.001 and not _empty
		_cooldown_bar.value = r
	if _cooldown_text:
		if seconds_left > 0.05:
			_cooldown_text.visible = true
			_cooldown_text.text = "%.1f" % seconds_left if seconds_left >= 1.0 else "%.0f" % ceil(seconds_left)
		else:
			_cooldown_text.visible = false
	if r <= 0.001 and _was_on_cd:
		var t := create_tween()
		t.tween_property(_frame, "modulate", Color(1.12, 1.08, 0.94, 1.0), 0.08)
		t.tween_property(_frame, "modulate", Color.WHITE if not _disabled else Color(0.62, 0.62, 0.64, 1.0), 0.18)
	_was_on_cd = r > 0.001


func _apply_frame() -> void:
	if _frame == null:
		return
	var highlight := _active or _selected
	_frame.add_theme_stylebox_override("panel", ArpgTheme.make_ability_slot(highlight, _disabled or _locked or _empty))
	if _disabled or _locked:
		modulate = Color(0.62, 0.62, 0.64, 1.0)
	elif _insufficient:
		modulate = Color(0.78, 0.82, 0.92, 1.0)
	else:
		modulate = Color.WHITE
