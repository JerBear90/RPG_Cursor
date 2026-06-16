class_name InputControlSchemeTests
extends RefCounted
## Validates default ARPG control scheme bindings and HUD slot alignment.

const InputLabels := preload("res://ui/themes/ui_input_labels.gd")

const SLOT_ACTIONS: Array[String] = [
	"light_attack", "heavy_attack", "quick_spell", "dodge", "block", "interact",
]

const REQUIRED_ACTIONS: Array[String] = [
	"move_left", "move_right", "move_forward", "move_back",
	"look_left", "look_right", "look_up", "look_down",
	"light_attack", "heavy_attack", "dodge", "jump", "block", "sprint",
	"lock_on", "switch_target_left", "switch_target_right",
	"interact", "quick_spell", "open_inventory", "open_map", "pause",
]


static func run(runner: Node) -> void:
	await runner.get_tree().process_frame
	if FileAccess.file_exists(ProjectSettings.globalize_path(InputManager.CONTROLS_PATH)):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(InputManager.CONTROLS_PATH))
	InputManager.reset_controls_to_defaults()
	_test_required_actions(runner)
	_test_jump_on_space_not_dodge(runner)
	_test_block_keyboard(runner)
	_test_interact_not_on_jump_button(runner)
	_test_lock_on_separate_from_switch(runner)
	_test_ability_slot_labels(runner)
	_test_no_space_on_dodge(runner)
	_test_device_label_refresh(runner)


static func _test_required_actions(runner: Node) -> void:
	for action in REQUIRED_ACTIONS:
		runner._assert(InputMap.has_action(action), "action exists: %s" % action)


static func _test_jump_on_space_not_dodge(runner: Node) -> void:
	var jump_kb := InputLabels.get_primary_binding_text("jump", InputLabels.DEVICE_KEYBOARD)
	runner._assert(jump_kb == "Space", "jump keyboard is Space (%s)" % jump_kb)
	runner._assert(
		InputLabels.get_primary_binding_text("jump", InputLabels.DEVICE_GAMEPAD) == "A",
		"jump controller is A"
	)
	runner._assert(_has_key("jump", KEY_SPACE), "jump bound to Space key")
	runner._assert(_has_joypad_button("jump", JOY_BUTTON_A), "jump bound to A")


static func _test_no_space_on_dodge(runner: Node) -> void:
	runner._assert(not _has_key("dodge", KEY_SPACE), "dodge does not use Space")
	var dodge_kb := InputLabels.get_primary_binding_text("dodge", InputLabels.DEVICE_KEYBOARD)
	runner._assert("Ctrl" in dodge_kb, "dodge keyboard shows Ctrl (%s)" % dodge_kb)
	runner._assert(
		InputLabels.get_primary_binding_text("dodge", InputLabels.DEVICE_GAMEPAD) == "B",
		"dodge controller is B"
	)


static func _test_block_keyboard(runner: Node) -> void:
	runner._assert(_has_key("block", KEY_F), "block bound to F")
	runner._assert(
		InputLabels.get_primary_binding_text("block", InputLabels.DEVICE_KEYBOARD) == "F",
		"block keyboard label is F"
	)
	runner._assert(
		InputLabels.get_primary_binding_text("block", InputLabels.DEVICE_GAMEPAD) == "LB",
		"block controller is LB"
	)


static func _test_interact_not_on_jump_button(runner: Node) -> void:
	runner._assert(_has_joypad_button("interact", JOY_BUTTON_X), "interact on X")
	runner._assert(not _has_joypad_button("interact", JOY_BUTTON_A), "interact not on A")
	runner._assert(
		InputLabels.get_primary_binding_text("interact", InputLabels.DEVICE_GAMEPAD) == "X",
		"interact controller label is X"
	)


static func _test_lock_on_separate_from_switch(runner: Node) -> void:
	runner._assert(InputMap.has_action("switch_target_left"), "switch_target_left exists")
	runner._assert(InputMap.has_action("switch_target_right"), "switch_target_right exists")
	runner._assert(_has_joypad_button("lock_on", JOY_BUTTON_RIGHT_STICK), "lock_on on R3")
	runner._assert(
		not _has_joypad_button("switch_target_left", JOY_BUTTON_RIGHT_STICK),
		"switch left not on R3"
	)
	runner._assert(
		InputLabels.get_primary_binding_text("lock_on", InputLabels.DEVICE_GAMEPAD) == "R3",
		"lock_on label is R3"
	)
	var lock_kb := InputLabels.get_primary_binding_text("lock_on", InputLabels.DEVICE_KEYBOARD)
	runner._assert("MMB" in lock_kb and "R" in lock_kb, "lock_on keyboard MMB / R (%s)" % lock_kb)


static func _test_ability_slot_labels(runner: Node) -> void:
	var expected_kb := {
		"light_attack": ["LMB", "J"],
		"heavy_attack": ["RMB", "K"],
		"quick_spell": ["Q", "3"],
		"dodge": ["Ctrl"],
		"block": ["F"],
		"interact": ["E"],
	}
	var expected_pad := {
		"light_attack": "RT",
		"heavy_attack": "RB",
		"quick_spell": "LT",
		"dodge": "B",
		"block": "LB",
		"interact": "X",
	}
	for i in SLOT_ACTIONS.size():
		var action: String = SLOT_ACTIONS[i]
		var kb := InputLabels.get_primary_binding_text(action, InputLabels.DEVICE_KEYBOARD)
		for part in expected_kb[action]:
			runner._assert(part in kb, "slot %d %s keyboard contains %s (%s)" % [i + 1, action, part, kb])
		var pad := InputLabels.get_primary_binding_text(action, InputLabels.DEVICE_GAMEPAD)
		runner._assert(pad == expected_pad[action], "slot %d %s pad is %s (%s)" % [i + 1, action, expected_pad[action], pad])


static func _test_device_label_refresh(runner: Node) -> void:
	var prev := InputManager.current_device
	InputManager._set_device(InputManager.DEVICE_GAMEPAD)
	var pad := InputLabels.get_primary_binding_text("light_attack", InputLabels.DEVICE_GAMEPAD)
	runner._assert(pad == "RT", "gamepad device shows RT for light attack")
	InputManager._set_device(InputManager.DEVICE_KEYBOARD)
	var kb := InputLabels.get_primary_binding_text("light_attack", InputLabels.DEVICE_KEYBOARD)
	runner._assert("LMB" in kb, "keyboard device shows LMB for light attack")
	InputManager._set_device(prev)


static func _has_key(action: String, keycode: Key) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey and (event as InputEventKey).physical_keycode == keycode:
			return true
	return false


static func _has_joypad_button(action: String, button: JoyButton) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and (event as InputEventJoypadButton).button_index == button:
			return true
	return false
