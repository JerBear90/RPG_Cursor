extends Control
class_name InteractionPrompt
## Floating prompt above the ability bar — keycap, action, optional hold progress.

@onready var _root: PanelContainer = %PromptRoot
@onready var _icon: TextureRect = %PromptIcon
@onready var _key_badge: PanelContainer = %KeyBadge
@onready var _key: Label = %KeyLabel
@onready var _action: Label = %ActionLabel
@onready var _hold_bar: ThinBar = %HoldBar

var _shown: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _root:
		_root.add_theme_stylebox_override("panel", ArpgTheme.make_panel())
	if _key_badge:
		_key_badge.add_theme_stylebox_override("panel", ArpgTheme.make_keycap())
	if _icon:
		_icon.texture = UiIconRegistry.get_icon("interaction")
		_icon.custom_minimum_size = Vector2(18, 18)
		_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ArpgTheme.style_label(_key, UiMetrics.FONT_SM, UiColors.TEXT_PRIMARY)
	ArpgTheme.style_label(_action, UiMetrics.FONT_MD, UiColors.TEXT_PRIMARY)
	if _hold_bar:
		_hold_bar.set_bar_color(UiColors.TEXT_QUEST)
		_hold_bar.set_bar_height(3.0)
		_hold_bar.visible = false
	visible = false
	modulate.a = 0.0


func show_prompt(key_text: String, action_text: String, target_text: String = "", hold_ratio: float = -1.0) -> void:
	if action_text.is_empty():
		hide_prompt()
		return
	var key := key_text.trim_prefix("[").trim_suffix("]")
	if _key:
		_key.text = key
	var line := action_text
	if target_text != "":
		line = "%s %s" % [action_text, target_text]
	if _action:
		_action.text = line
	if _hold_bar:
		if hold_ratio >= 0.0:
			_hold_bar.visible = true
			_hold_bar.max_value = 1.0
			_hold_bar.value = clampf(hold_ratio, 0.0, 1.0)
		else:
			_hold_bar.visible = false
	if _shown:
		return
	_shown = true
	visible = true
	position.y = 8.0
	modulate.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.14)
	tween.tween_property(self, "position:y", 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func hide_prompt() -> void:
	if not _shown and not visible:
		return
	_shown = false
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.14)
	tween.tween_property(self, "position:y", 6.0, 0.14)
	tween.chain().tween_callback(func(): visible = false)


func parse_legacy_prompt(raw: String) -> void:
	if raw.is_empty():
		hide_prompt()
		return
	var hold := raw.begins_with("Hold ")
	var body := raw.substr(5) if hold else raw
	var parts := body.split(": ", false, 1)
	if parts.size() >= 2:
		show_prompt(parts[0], ("Hold " if hold else "") + parts[1])
	else:
		show_prompt("E", ("Hold " if hold else "") + body)
