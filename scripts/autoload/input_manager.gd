extends Node
## Controller-first input helpers and device detection.

signal device_changed(device: int)

var current_device: int = DEVICE_KEYBOARD
var deadzone: float = 0.2
var invert_look_y: bool = false
var invert_look_x: bool = false
var camera_sensitivity: float = 1.0

const DEVICE_KEYBOARD := 0
const DEVICE_GAMEPAD := 1


func _ready() -> void:
	Input.joy_connection_changed.connect(_on_joy_changed)
	_detect_device()


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if current_device != DEVICE_GAMEPAD:
			current_device = DEVICE_GAMEPAD
			device_changed.emit(current_device)
	elif event is InputEventKey or event is InputEventMouse:
		if current_device != DEVICE_KEYBOARD:
			current_device = DEVICE_KEYBOARD
			device_changed.emit(current_device)


func _on_joy_changed(_device: int, _connected: bool) -> void:
	_detect_device()


func _detect_device() -> void:
	if Input.get_connected_joypads().size() > 0:
		current_device = DEVICE_GAMEPAD
	else:
		current_device = DEVICE_KEYBOARD


func get_move_vector(player_index: int = 0) -> Vector2:
	var prefix := "p%d_" % (player_index + 1) if player_index > 0 else ""
	var x := Input.get_action_strength(prefix + "move_right") - Input.get_action_strength(prefix + "move_left")
	var y := Input.get_action_strength(prefix + "move_back") - Input.get_action_strength(prefix + "move_forward")
	var vec := Vector2(x, y)
	if vec.length() < deadzone:
		return Vector2.ZERO
	return vec.normalized() * minf(vec.length(), 1.0)


func get_look_vector(player_index: int = 0) -> Vector2:
	var prefix := "p%d_" % (player_index + 1) if player_index > 0 else ""
	var x := Input.get_action_strength(prefix + "look_right") - Input.get_action_strength(prefix + "look_left")
	var y := Input.get_action_strength(prefix + "look_down") - Input.get_action_strength(prefix + "look_up")
	if invert_look_x:
		x = -x
	if invert_look_y:
		y = -y
	var vec := Vector2(x, y) * camera_sensitivity
	if vec.length() < deadzone:
		return Vector2.ZERO
	return vec


func is_action_just_pressed(action: String, player_index: int = 0) -> bool:
	return Input.is_action_just_pressed(_player_action(action, player_index))


func is_action_pressed(action: String, player_index: int = 0) -> bool:
	return Input.is_action_pressed(_player_action(action, player_index))


func _player_action(action: String, player_index: int) -> String:
	if player_index <= 0:
		return action
	return "p%d_%s" % [player_index + 1, action]
