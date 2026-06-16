class_name UiInputLabels
extends RefCounted
## Resolves human-readable binding labels from the InputMap.

const DEVICE_KEYBOARD := 0
const DEVICE_GAMEPAD := 1

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
}

const MOUSE_LABELS := {
	MOUSE_BUTTON_LEFT: "LMB",
	MOUSE_BUTTON_RIGHT: "RMB",
	MOUSE_BUTTON_MIDDLE: "MMB",
	MOUSE_BUTTON_WHEEL_UP: "Wheel Up",
	MOUSE_BUTTON_WHEEL_DOWN: "Wheel Down",
}

const KEYBOARD_DISPLAY_ORDER := [
	"LMB", "RMB", "MMB", "Wheel Up", "Wheel Down",
]


static func get_primary_binding_text(action: StringName, device_type: int) -> String:
	if not InputMap.has_action(action):
		return ""
	if device_type == DEVICE_GAMEPAD:
		return _collect_gamepad_label(action)
	return _collect_keyboard_label(action)


static func get_action_label(action: String, prefer_keyboard: bool = true) -> String:
	var device := DEVICE_KEYBOARD if prefer_keyboard else DEVICE_GAMEPAD
	return get_primary_binding_text(StringName(action), device)


static func get_action_tooltip(action: String, action_name: String) -> String:
	var kb := get_primary_binding_text(StringName(action), DEVICE_KEYBOARD)
	var pad := get_primary_binding_text(StringName(action), DEVICE_GAMEPAD)
	if kb != "" and pad != "" and kb != pad:
		return "%s\nKeyboard: %s\nController: %s" % [action_name, kb, pad]
	if kb != "":
		return "%s (%s)" % [action_name, kb]
	if pad != "":
		return "%s (%s)" % [action_name, pad]
	return action_name


static func _collect_keyboard_label(action: StringName) -> String:
	var mouse_parts: Array[String] = []
	var key_parts: Array[String] = []
	for event in InputMap.action_get_events(action):
		if event is InputEventMouseButton:
			var mouse_event := event as InputEventMouseButton
			var label: String = MOUSE_LABELS.get(mouse_event.button_index, "")
			if label != "" and label not in mouse_parts:
				mouse_parts.append(label)
		elif event is InputEventKey:
			var label := _key_label(event as InputEventKey)
			if label != "" and label not in key_parts:
				key_parts.append(label)
	mouse_parts.sort_custom(func(a: String, b: String) -> bool:
		return KEYBOARD_DISPLAY_ORDER.find(a) < KEYBOARD_DISPLAY_ORDER.find(b)
	)
	var combined: PackedStringArray = []
	for label in mouse_parts:
		combined.append(label)
	for label in key_parts:
		if combined.size() >= 2:
			break
		combined.append(label)
	return " / ".join(combined)


static func _collect_gamepad_label(action: StringName) -> String:
	var trigger := ""
	var button := ""
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion:
			var motion_label := _motion_label(event as InputEventJoypadMotion)
			if motion_label != "":
				trigger = motion_label
		elif event is InputEventJoypadButton:
			var pad_event := event as InputEventJoypadButton
			var motion_label: String = JOYPAD_LABELS.get(pad_event.button_index, "")
			if motion_label != "":
				button = motion_label
	if trigger != "":
		return trigger
	return button


static func _motion_label(event: InputEventJoypadMotion) -> String:
	if event.axis == JOY_AXIS_TRIGGER_LEFT and event.axis_value < 0.0:
		return "LT"
	if event.axis == JOY_AXIS_TRIGGER_RIGHT and event.axis_value > 0.0:
		return "RT"
	if event.axis == 4 and event.axis_value < 0.0:
		return "LT"
	if event.axis == 5 and event.axis_value > 0.0:
		return "RT"
	return ""


static func _key_label(event: InputEventKey) -> String:
	if event.physical_keycode == KEY_SPACE:
		return "Space"
	if event.physical_keycode == KEY_CTRL or event.physical_keycode == KEY_ALT:
		return "Ctrl" if event.physical_keycode == KEY_CTRL else "Alt"
	if event.physical_keycode != 0:
		var label := OS.get_keycode_string(event.physical_keycode)
		if label != "":
			return _normalize_key_label(label)
	if event.keycode != 0:
		return _normalize_key_label(OS.get_keycode_string(event.keycode))
	return "?"


static func _normalize_key_label(label: String) -> String:
	match label:
		"Left Ctrl", "Right Ctrl", "Control":
			return "Ctrl"
		"Left Shift", "Right Shift":
			return "Shift"
		"Left Alt", "Right Alt":
			return "Alt"
		_:
			return label
