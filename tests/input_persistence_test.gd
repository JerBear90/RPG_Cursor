class_name InputPersistenceTests
extends RefCounted

const InputLabels := preload("res://ui/themes/ui_input_labels.gd")


static func run(runner: Node) -> void:
	await runner.get_tree().process_frame
	_test_map_pause_no_conflict(runner)
	await _test_remap_persists(runner)
	await _test_reset_restores_defaults(runner)
	await _test_startup_preserves_saved_remap(runner)


static func _test_map_pause_no_conflict(runner: Node) -> void:
	runner._assert(
		not _share_gamepad_button("open_map", "pause"),
		"open_map and pause use different controller buttons"
	)
	runner._assert(_has_pad_button("open_map", JOY_BUTTON_DPAD_UP), "open_map uses D-pad Up")
	runner._assert(_has_pad_button("pause", JOY_BUTTON_START), "pause uses Start")
	runner._assert(not _has_pad_button("open_map", JOY_BUTTON_START), "open_map does not use Start")


static func _test_remap_persists(runner: Node) -> void:
	InputManager.remap_action("jump", [InputDefaults.event_from_key(KEY_V)])
	runner._assert(
		InputLabels.get_primary_binding_text("jump", InputLabels.DEVICE_KEYBOARD) == "V",
		"remapped jump label is V"
	)
	InputManager.load_saved_controls()
	runner._assert(
		InputLabels.get_primary_binding_text("jump", InputLabels.DEVICE_KEYBOARD) == "V",
		"remapped jump survives load_saved_controls"
	)
	InputManager.reset_controls_to_defaults()
	runner._assert(
		InputLabels.get_primary_binding_text("jump", InputLabels.DEVICE_KEYBOARD) == "Space",
		"reset restores Space for jump"
	)
	runner._assert(not _has_key("jump", KEY_V), "reset removes temporary V binding")


static func _test_reset_restores_defaults(runner: Node) -> void:
	InputManager.reset_controls_to_defaults()
	runner._assert(_has_key("block", KEY_F), "reset keeps block on F")
	runner._assert(
		InputLabels.get_primary_binding_text("light_attack", InputLabels.DEVICE_GAMEPAD) == "RT",
		"reset keeps RT for light attack"
	)


static func _test_startup_preserves_saved_remap(runner: Node) -> void:
	InputManager.remap_action("dodge", [InputDefaults.event_from_key(KEY_P)])
	var label_before := InputLabels.get_primary_binding_text("dodge", InputLabels.DEVICE_KEYBOARD)
	InputManager.ensure_default_control_scheme()
	InputManager.load_saved_controls()
	runner._assert(
		InputLabels.get_primary_binding_text("dodge", InputLabels.DEVICE_KEYBOARD) == label_before,
		"ensure_default_control_scheme does not overwrite saved dodge remap"
	)
	InputManager.reset_controls_to_defaults()


static func _share_gamepad_button(action_a: String, action_b: String) -> bool:
	for a in InputMap.action_get_events(action_a):
		if a is InputEventJoypadButton:
			for b in InputMap.action_get_events(action_b):
				if b is InputEventJoypadButton and (b as InputEventJoypadButton).button_index == (a as InputEventJoypadButton).button_index:
					return true
	return false


static func _has_pad_button(action: String, button: JoyButton) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and (event as InputEventJoypadButton).button_index == button:
			return true
	return false


static func _has_key(action: String, keycode: Key) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey and (event as InputEventKey).physical_keycode == keycode:
			return true
	return false
