class_name UiInputLabels
extends RefCounted
## Resolves human-readable binding labels from the InputMap.

const JOYPAD_LABELS := {
	JOY_BUTTON_A: "A",
	JOY_BUTTON_B: "B",
	JOY_BUTTON_X: "X",
	JOY_BUTTON_Y: "Y",
	JOY_BUTTON_LEFT_SHOULDER: "LB",
	JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_LEFT_STICK: "L3",
	JOY_BUTTON_RIGHT_STICK: "R3",
	JOY_BUTTON_START: "Start",
	JOY_BUTTON_BACK: "Back",
	JOY_BUTTON_DPAD_UP: "D-Up",
	JOY_BUTTON_DPAD_DOWN: "D-Down",
	JOY_BUTTON_DPAD_LEFT: "D-Left",
	JOY_BUTTON_DPAD_RIGHT: "D-Right",
}

const MOUSE_LABELS := {
	MOUSE_BUTTON_LEFT: "LMB",
	MOUSE_BUTTON_RIGHT: "RMB",
	MOUSE_BUTTON_MIDDLE: "MMB",
}


static func get_action_label(action: String, prefer_keyboard: bool = true) -> String:
	if not InputMap.has_action(action):
		return ""
	var keyboard := ""
	var gamepad := ""
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var key_event := event as InputEventKey
			keyboard = _key_label(key_event)
		elif event is InputEventMouseButton:
			var mouse_event := event as InputEventMouseButton
			keyboard = MOUSE_LABELS.get(mouse_event.button_index, "M%d" % mouse_event.button_index)
		elif event is InputEventJoypadButton:
			var pad_event := event as InputEventJoypadButton
			gamepad = JOYPAD_LABELS.get(pad_event.button_index, "Btn%d" % pad_event.button_index)
	if prefer_keyboard and keyboard != "":
		return keyboard
	if gamepad != "":
		return gamepad
	return keyboard


static func get_action_tooltip(action: String, action_name: String) -> String:
	var kb := get_action_label(action, true)
	var pad := get_action_label(action, false)
	if kb != "" and pad != "" and kb != pad:
		return "%s\nKeyboard: %s\nController: %s" % [action_name, kb, pad]
	if kb != "":
		return "%s (%s)" % [action_name, kb]
	if pad != "":
		return "%s (%s)" % [action_name, pad]
	return action_name


static func _key_label(event: InputEventKey) -> String:
	if event.physical_keycode != 0:
		var label := OS.get_keycode_string(event.physical_keycode)
		if label != "":
			return label
	if event.keycode != 0:
		return OS.get_keycode_string(event.keycode)
	return "?"
