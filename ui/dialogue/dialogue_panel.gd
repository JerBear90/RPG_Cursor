extends Control
class_name DialoguePanel
## Bottom-center dialogue panel — visual UI and button callbacks only.

@onready var _speaker: Label = %SpeakerName
@onready var _divider: ColorRect = %Divider
@onready var _body: Label = %DialogueText
@onready var _choices: VBoxContainer = %ChoicesContainer
@onready var _confirm_button: Button = %ConfirmButton
@onready var _cancel_button: Button = %CancelButton

var _confirm_action_label: String = "Continue"
var _cancel_action_label: String = "Leave"
var _choice_buttons: Array[Button] = []
var _choice_options: Array[String] = []
var _focused_choice_index: int = 0


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_apply_theme()
	if _confirm_button:
		_confirm_button.pressed.connect(_on_confirm_pressed)
		_confirm_button.focus_entered.connect(_refresh_button_focus)
	if _cancel_button:
		_cancel_button.pressed.connect(_on_cancel_pressed)
		_cancel_button.focus_entered.connect(_refresh_button_focus)
	if InputManager.has_signal("device_changed"):
		InputManager.device_changed.connect(func(_device: int) -> void:
			_refresh_prompts()
		)


func _apply_theme() -> void:
	var panel := get_node_or_null("DialogueSafeArea/CenterAnchor/DialoguePanel") as PanelContainer
	if panel:
		panel.add_theme_stylebox_override("panel", ArpgTheme.make_panel(UiColors.PANEL_BG_DEEP, UiColors.BORDER_BRONZE, UiMetrics.RADIUS_MD))
		panel.custom_minimum_size.x = 560.0
		panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	get_viewport().size_changed.connect(_clamp_panel_width)
	call_deferred("_clamp_panel_width")
	if _speaker:
		ArpgTheme.style_label(_speaker, UiMetrics.FONT_LG, UiColors.TEXT_PRIMARY)
	if _body:
		ArpgTheme.style_label(_body, UiMetrics.FONT_MD, UiColors.TEXT_PRIMARY)
		_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_footer_button(_confirm_button, true)
	_style_footer_button(_cancel_button, false)


func show_line(speaker: String, text: String, show_continue: bool = true, show_leave: bool = true) -> void:
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	if _speaker:
		_speaker.text = speaker
	if _body:
		_body.text = text
	_clear_choice_buttons()
	_set_footer_visible(show_continue, show_leave)
	_refresh_prompts()
	call_deferred("_grab_dialogue_focus")


func apply_footer_labels(confirm_label: String, cancel_label: String) -> void:
	_confirm_action_label = confirm_label
	_cancel_action_label = cancel_label
	_refresh_prompts()


func show_confirmation_footer(confirm_label: String, cancel_label: String = "Cancel") -> void:
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_clear_choice_buttons()
	_confirm_action_label = confirm_label
	_cancel_action_label = cancel_label
	_set_footer_visible(true, true)
	_refresh_prompts()
	call_deferred("_grab_dialogue_focus")


func get_focused_choice_index() -> int:
	return clampi(_focused_choice_index, 0, maxi(_choice_options.size() - 1, 0))


func show_choices(options: Array[String]) -> void:
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_choice_options = options.duplicate()
	if options.size() == 2:
		show_confirmation_footer(options[0], options[1])
		return
	_clear_choice_buttons()
	_choices.visible = options.size() > 0
	for i in options.size():
		var btn := Button.new()
		btn.focus_mode = Control.FOCUS_ALL
		btn.text = "[%s] %s" % [_choice_key_label(i), options[i]]
		btn.pressed.connect(_on_choice_pressed.bind(i))
		btn.focus_entered.connect(func() -> void:
			_focused_choice_index = i
			_refresh_button_focus_for_choice(i)
		)
		_style_footer_button(btn, i == 0)
		_choices.add_child(btn)
		_choice_buttons.append(btn)
	_set_footer_visible(false, false)
	call_deferred("_grab_dialogue_focus")


func hide_panel() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clear_choice_buttons()
	if _confirm_button:
		_confirm_button.release_focus()
	if _cancel_button:
		_cancel_button.release_focus()


func focus_choice(delta: int) -> void:
	if _choices.visible and _choice_buttons.size() > 0:
		var focused_idx := 0
		for i in _choice_buttons.size():
			if _choice_buttons[i].has_focus():
				focused_idx = i
				break
		var next := clampi(focused_idx + delta, 0, _choice_buttons.size() - 1)
		_choice_buttons[next].grab_focus()
		return
	if _confirm_button and _confirm_button.visible and _cancel_button and _cancel_button.visible:
		if delta > 0:
			_cancel_button.grab_focus()
		else:
			_confirm_button.grab_focus()
		_refresh_button_focus()


func _on_confirm_pressed() -> void:
	DialogueManager.try_confirm_input()


func _on_cancel_pressed() -> void:
	DialogueManager.try_cancel_input()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if _is_dialogue_cancel_event(event):
		if DialogueManager.try_cancel_input():
			get_viewport().set_input_as_handled()


func _is_dialogue_cancel_event(event: InputEvent) -> bool:
	return event.is_action_pressed("dialogue_cancel") \
		or event.is_action_pressed("cancel") \
		or event.is_action_pressed("ui_cancel")


func _on_choice_pressed(index: int) -> void:
	if DialogueManager.is_active():
		DialogueManager.select_choice(index)


func _grab_dialogue_focus() -> void:
	if not visible:
		return
	if _confirm_button and _confirm_button.visible:
		_confirm_button.grab_focus()
	elif _choice_buttons.size() > 0:
		_choice_buttons[0].grab_focus()
	else:
		grab_focus()


func _clear_choice_buttons() -> void:
	_choice_buttons.clear()
	_choice_options.clear()
	if _choices:
		for c in _choices.get_children():
			c.queue_free()
		_choices.visible = false


func _set_footer_visible(show_confirm: bool, show_cancel: bool) -> void:
	if _confirm_button:
		_confirm_button.visible = show_confirm
	if _cancel_button:
		_cancel_button.visible = show_cancel


func _refresh_prompts() -> void:
	var confirm_key := _input_hint("dialogue_confirm")
	var cancel_key := _input_hint("dialogue_cancel")
	if _confirm_button and _confirm_button.visible:
		_confirm_button.text = "[%s] %s" % [confirm_key, _confirm_action_label]
	if _cancel_button and _cancel_button.visible:
		_cancel_button.text = "[%s] %s" % [cancel_key, _cancel_action_label]
	for i in _choice_buttons.size():
		var option_text := _choice_options[i] if i < _choice_options.size() else ""
		if option_text != "":
			_choice_buttons[i].text = "[%s] %s" % [_choice_key_label(i), option_text]


func _refresh_button_focus_for_choice(index: int) -> void:
	for i in _choice_buttons.size():
		_apply_button_focus(_choice_buttons[i], i == index)


func _refresh_button_focus() -> void:
	if _confirm_button and _confirm_button.has_focus():
		_apply_button_focus(_confirm_button, true)
		_apply_button_focus(_cancel_button, false)
	elif _cancel_button and _cancel_button.has_focus():
		_apply_button_focus(_confirm_button, false)
		_apply_button_focus(_cancel_button, true)


func _apply_button_focus(btn: Button, focused: bool) -> void:
	if btn == null:
		return
	var accent := btn == _confirm_button
	var color := UiColors.TEXT_QUEST if (focused and accent) else (
		UiColors.TEXT_SECONDARY if (focused and not accent) else (
			UiColors.TEXT_QUEST if accent else UiColors.TEXT_SECONDARY
		)
	)
	btn.add_theme_color_override("font_color", color)
	btn.add_theme_color_override("font_hover_color", color)
	btn.add_theme_color_override("font_focus_color", color)
	btn.add_theme_color_override("font_pressed_color", color)


func _style_footer_button(btn: Button, accent: bool) -> void:
	if btn == null:
		return
	btn.focus_mode = Control.FOCUS_ALL
	btn.flat = true
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT if accent else HORIZONTAL_ALIGNMENT_RIGHT
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", UiMetrics.FONT_SM)
	var empty := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty)
	btn.add_theme_stylebox_override("hover", empty)
	btn.add_theme_stylebox_override("pressed", empty)
	btn.add_theme_stylebox_override("focus", empty)
	btn.add_theme_stylebox_override("disabled", empty)
	_apply_button_focus(btn, false)


func _choice_key_label(index: int) -> String:
	if index == 0:
		return _input_hint("dialogue_confirm")
	return _input_hint("dialogue_cancel")


func _input_hint(action: String) -> String:
	if InputManager.current_device == InputManager.DEVICE_GAMEPAD:
		if action == "dialogue_confirm":
			return "A"
		if action == "dialogue_cancel":
			return "B"
	if action == "dialogue_confirm":
		return "E / Enter"
	return "Esc"


func _clamp_panel_width() -> void:
	var panel := get_node_or_null("DialogueSafeArea/CenterAnchor/DialoguePanel") as PanelContainer
	if panel == null:
		return
	var viewport_w := get_viewport().get_visible_rect().size.x
	var target_w := clampf(viewport_w * 0.47, 560.0, 900.0)
	panel.custom_minimum_size.x = target_w
