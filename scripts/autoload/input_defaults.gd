class_name InputDefaults
extends RefCounted
## Approved default InputMap events — shared by project.godot and runtime install/reset.

const SCHEME_VERSION := 2
const TRIGGER_DEADZONE := 0.5
const STICK_DEADZONE := 0.15

const MANAGED_ACTIONS: Array[String] = [
	"jump", "dodge", "block", "interact",
	"light_attack", "heavy_attack", "charged_attack", "quick_spell",
	"lock_on", "switch_target_left", "switch_target_right",
	"sprint", "open_inventory", "open_map", "pause",
]

const RESERVED_ACTIONS: Dictionary = {
	"charged_attack": "Hold-to-execute finisher; shares RB / RMB with heavy attack hold.",
	"open_quest_tracker": "Quest panel toggle; keyboard-only (no gamepad — avoids D-pad / Start conflicts).",
	"open_skill_tree": "Skill tree menu; keyboard-only until a dedicated binding is approved.",
	"open_spell_wheel": "Spell wheel hold; D-pad left/right cycles while wheel is open.",
	"open_pet_wheel": "Pet wheel; reserved for future pet system.",
	"cycle_quick_left": "Quick-slot / spell-wheel cycle left (D-pad left).",
	"cycle_quick_right": "Quick-slot / spell-wheel cycle right (D-pad right).",
	"use_quick_item": "Quick consumable; reserved.",
	"quick_heal": "Quick heal; reserved.",
}


static func event_from_key(keycode: Key) -> InputEventKey:
	return _key(keycode)


static func event_from_mouse(button: MouseButton) -> InputEventMouseButton:
	return _mouse(button)


static func event_from_pad_button(button: JoyButton) -> InputEventJoypadButton:
	return _pad_btn(button)


static func event_from_trigger(axis: JoyAxis, axis_value: float) -> InputEventJoypadMotion:
	return _trigger(axis, axis_value)


static func default_events(action: String) -> Array[InputEvent]:
	var out: Array[InputEvent] = []
	match action:
		"jump":
			out.append(_key(KEY_SPACE))
			out.append(_pad_btn(JOY_BUTTON_A))
		"dodge":
			out.append(_key(KEY_CTRL))
			out.append(_key(KEY_ALT))
			out.append(_pad_btn(JOY_BUTTON_B))
		"block":
			out.append(_key(KEY_F))
			out.append(_pad_btn(JOY_BUTTON_LEFT_SHOULDER))
		"interact":
			out.append(_key(KEY_E))
			out.append(_pad_btn(JOY_BUTTON_X))
		"light_attack":
			out.append(_mouse(MOUSE_BUTTON_LEFT))
			out.append(_key(KEY_J))
			out.append(_trigger(JOY_AXIS_TRIGGER_RIGHT, 1.0))
		"heavy_attack":
			out.append(_mouse(MOUSE_BUTTON_RIGHT))
			out.append(_key(KEY_K))
			out.append(_pad_btn(JOY_BUTTON_RIGHT_SHOULDER))
		"charged_attack":
			out.append(_mouse(MOUSE_BUTTON_RIGHT))
			out.append(_pad_btn(JOY_BUTTON_RIGHT_SHOULDER))
		"quick_spell":
			out.append(_key(KEY_Q))
			out.append(_key(KEY_3))
			out.append(_trigger(JOY_AXIS_TRIGGER_LEFT, -1.0))
		"lock_on":
			out.append(_mouse(MOUSE_BUTTON_MIDDLE))
			out.append(_key(KEY_R))
			out.append(_pad_btn(JOY_BUTTON_RIGHT_STICK))
		"switch_target_left":
			out.append(_mouse(MOUSE_BUTTON_WHEEL_UP))
		"switch_target_right":
			out.append(_mouse(MOUSE_BUTTON_WHEEL_DOWN))
		"sprint":
			out.append(_key(KEY_SHIFT))
			out.append(_pad_btn(JOY_BUTTON_LEFT_STICK))
		"open_inventory":
			out.append(_key(KEY_I))
			out.append(_pad_btn(JOY_BUTTON_BACK))
		"open_map":
			out.append(_key(KEY_M))
			out.append(_pad_btn(JOY_BUTTON_DPAD_UP))
		"open_skill_tree":
			out.append(_key(KEY_K))
		"pause":
			out.append(_key(KEY_ESCAPE))
			out.append(_pad_btn(JOY_BUTTON_START))
	return out


static func default_deadzone(action: String) -> float:
	if action in ["light_attack", "heavy_attack", "charged_attack", "quick_spell"]:
		return TRIGGER_DEADZONE
	if action in ["look_left", "look_right", "look_up", "look_down"]:
		return STICK_DEADZONE
	return 0.5


static func _key(keycode: Key) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	return ev


static func _mouse(button: MouseButton) -> InputEventMouseButton:
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	return ev


static func _pad_btn(button: JoyButton) -> InputEventJoypadButton:
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
	return ev


static func _trigger(axis: JoyAxis, axis_value: float) -> InputEventJoypadMotion:
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = axis_value
	return ev
