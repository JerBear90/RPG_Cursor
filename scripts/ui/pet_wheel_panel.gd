extends Control
## Radial pet command wheel.

signal command_selected(command_id: String)

const COMMANDS: Array[Dictionary] = [
	{"id": "follow", "label": "Follow"},
	{"id": "stay", "label": "Stay"},
	{"id": "attack", "label": "Attack"},
	{"id": "defend", "label": "Defend"},
	{"id": "recall", "label": "Recall"},
]

var _buttons: Array[Button] = []
var _selected_index: int = 0
var _title: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title = Label.new()
	_title.text = "Pet Commands"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_title.offset_top = -180
	add_child(_title)
	_rebuild()


func show_wheel(selected_index: int = 0) -> void:
	_selected_index = clampi(selected_index, 0, COMMANDS.size() - 1)
	_update_selection()
	visible = true


func hide_wheel() -> void:
	visible = false


func cycle_selection(delta: int) -> void:
	if COMMANDS.is_empty():
		return
	_selected_index = (_selected_index + delta) % COMMANDS.size()
	if _selected_index < 0:
		_selected_index += COMMANDS.size()
	_update_selection()


func confirm_selection() -> void:
	if not visible or COMMANDS.is_empty():
		return
	command_selected.emit(COMMANDS[_selected_index].id)


func get_command_label(command_id: String) -> String:
	for cmd in COMMANDS:
		if cmd.id == command_id:
			return str(cmd.label)
	return command_id.capitalize()


func _rebuild() -> void:
	for btn in _buttons:
		btn.queue_free()
	_buttons.clear()
	var center := size * 0.5 if size.length_squared() > 1.0 else Vector2(640, 400)
	for i in COMMANDS.size():
		var cmd: Dictionary = COMMANDS[i]
		var btn := Button.new()
		btn.text = cmd.label
		btn.toggle_mode = true
		btn.custom_minimum_size = Vector2(120, 44)
		var angle := TAU * float(i) / float(COMMANDS.size()) - PI * 0.5
		btn.position = center + Vector2(cos(angle), sin(angle)) * 110.0 - btn.custom_minimum_size * 0.5
		btn.pressed.connect(_on_pressed.bind(i))
		add_child(btn)
		_buttons.append(btn)
	_update_selection()


func _update_selection() -> void:
	for i in _buttons.size():
		_buttons[i].button_pressed = i == _selected_index
	if _title and _selected_index < COMMANDS.size():
		_title.text = "Pet: %s" % COMMANDS[_selected_index].label


func _on_pressed(index: int) -> void:
	_selected_index = index
	_update_selection()
	confirm_selection()
