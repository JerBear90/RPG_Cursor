extends Control
## Radial spell wheel overlay (hold to select, release to confirm).

signal spell_selected(index: int)

const SLOT_RADIUS := 120.0
const SLOT_SIZE := Vector2(100, 48)

var _spells: Array[String] = []
var _selected_index: int = 0
var _center: Vector2
var _slot_buttons: Array[Button] = []
var _title_label: Label
var _slot_container: Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_slot_container = Control.new()
	_slot_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_slot_container)
	_title_label = Label.new()
	_title_label.text = "Spell Wheel"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_title_label.offset_top = -200
	_title_label.custom_minimum_size = Vector2(200, 28)
	add_child(_title_label)
	_center = size * 0.5
	resized.connect(_on_resized)


func _on_resized() -> void:
	_center = size * 0.5
	_layout_slots()


func show_wheel(spells: Array[String], selected_index: int) -> void:
	_spells = spells
	_selected_index = selected_index
	_rebuild_slots()
	visible = true


func hide_wheel() -> void:
	visible = false


func update_selection(index: int) -> void:
	_selected_index = index
	for i in _slot_buttons.size():
		_slot_buttons[i].button_pressed = i == _selected_index


func _rebuild_slots() -> void:
	for btn in _slot_buttons:
		btn.queue_free()
	_slot_buttons.clear()
	var count := _spells.size()
	if count == 0:
		return
	for i in count:
		var angle := (TAU * float(i) / float(count)) - PI * 0.5
		var offset := Vector2(cos(angle), sin(angle)) * SLOT_RADIUS
		var btn := Button.new()
		btn.text = _spells[i].replace("_", " ").capitalize()
		btn.toggle_mode = true
		btn.button_pressed = i == _selected_index
		btn.custom_minimum_size = SLOT_SIZE
		btn.position = _center + offset - SLOT_SIZE * 0.5
		btn.pressed.connect(_on_slot_pressed.bind(i))
		_slot_container.add_child(btn)
		_slot_buttons.append(btn)


func _layout_slots() -> void:
	if _spells.is_empty():
		return
	_rebuild_slots()


func _on_slot_pressed(index: int) -> void:
	_selected_index = index
	spell_selected.emit(index)
