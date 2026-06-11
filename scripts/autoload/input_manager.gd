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

const CO_OP_ACTIONS: Array[String] = [
	"move_left", "move_right", "move_forward", "move_back",
	"look_left", "look_right", "look_up", "look_down",
	"light_attack", "heavy_attack", "dodge", "jump", "block", "sprint",
	"lock_on", "interact", "quick_spell", "use_quick_item", "quick_heal",
	"cycle_quick_left", "cycle_quick_right", "open_spell_wheel",
]

const P2_KEYBOARD: Dictionary = {
	"move_left": KEY_LEFT,
	"move_right": KEY_RIGHT,
	"move_forward": KEY_UP,
	"move_back": KEY_DOWN,
	"light_attack": KEY_U,
	"heavy_attack": KEY_O,
	"dodge": KEY_P,
	"interact": KEY_ENTER,
	"sprint": KEY_SHIFT,
	"quick_spell": KEY_8,
	"use_quick_item": KEY_9,
	"quick_heal": KEY_0,
}


func _ready() -> void:
	Input.joy_connection_changed.connect(_on_joy_changed)
	_setup_mouse_combat_bindings()
	_setup_player2_inputs()
	_detect_device()


func _setup_mouse_combat_bindings() -> void:
	_bind_mouse_button("light_attack", MOUSE_BUTTON_LEFT)
	_bind_mouse_button("heavy_attack", MOUSE_BUTTON_RIGHT)


func _bind_mouse_button(action: String, button: MouseButton) -> void:
	if not InputMap.has_action(action):
		return
	for event in InputMap.action_get_events(action):
		if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == button:
			return
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if current_device != DEVICE_GAMEPAD:
			current_device = DEVICE_GAMEPAD
			device_changed.emit(current_device)
	elif event is InputEventKey or event is InputEventMouse:
		if current_device != DEVICE_KEYBOARD:
			current_device = DEVICE_KEYBOARD
			device_changed.emit(current_device)


func _setup_player2_inputs() -> void:
	for action in CO_OP_ACTIONS:
		var p2_action := "p2_%s" % action
		if InputMap.has_action(p2_action):
			continue
		InputMap.add_action(p2_action)
		if P2_KEYBOARD.has(action):
			var key := InputEventKey.new()
			key.physical_keycode = P2_KEYBOARD[action]
			InputMap.action_add_event(p2_action, key)
		if InputMap.has_action(action):
			for event in InputMap.action_get_events(action):
				if event is InputEventJoypadButton:
					var btn := event.duplicate() as InputEventJoypadButton
					btn.device = 1
					InputMap.action_add_event(p2_action, btn)
				elif event is InputEventJoypadMotion:
					var motion := event.duplicate() as InputEventJoypadMotion
					motion.device = 1
					InputMap.action_add_event(p2_action, motion)


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
	return "p2_%s" % action
