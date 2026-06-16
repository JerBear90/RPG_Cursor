extends Node
## Input helpers, saved bindings, device detection, and default scheme management.

signal device_changed(device: int)
signal bindings_changed

var current_device: int = DEVICE_KEYBOARD
var deadzone: float = 0.2
var invert_look_y: bool = false
var invert_look_x: bool = false
var camera_sensitivity: float = 1.0
var _gameplay_suppressed_until_msec: int = 0

const DEVICE_KEYBOARD := 0
const DEVICE_GAMEPAD := 1
const STICK_DEVICE_THRESHOLD := 0.35
const CONTROLS_PATH := "user://controls.cfg"

const CO_OP_ACTIONS: Array[String] = [
	"move_left", "move_right", "move_forward", "move_back",
	"look_left", "look_right", "look_up", "look_down",
	"light_attack", "heavy_attack", "dodge", "jump", "block", "sprint",
	"lock_on", "switch_target_left", "switch_target_right",
	"interact", "quick_spell", "use_quick_item", "quick_heal",
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

const P2_MENU_KEYBOARD: Dictionary = {
	"pause": KEY_BACKSPACE,
}
const P2_MENU_ACTIONS: Array[String] = [
	"pause", "open_inventory", "open_map", "open_skill_tree", "open_quest_tracker",
	"confirm", "cancel",
]
## Gameplay menu actions checked for duplicate controller bindings.
const _MENU_GAMEPAD_ACTIONS: Array[String] = ["pause", "open_inventory", "open_map"]


func _ready() -> void:
	Input.joy_connection_changed.connect(_on_joy_changed)
	ensure_default_control_scheme()
	load_saved_controls()
	_validate_critical_conflicts()
	_remove_obsolete_actions()
	_setup_player2_inputs()
	_detect_device()
	if not DialogueManager.dialogue_ended.is_connected(_on_modal_closed):
		DialogueManager.dialogue_ended.connect(_on_modal_closed)
	if not MerchantManager.shop_closed.is_connected(_on_modal_closed):
		MerchantManager.shop_closed.connect(_on_modal_closed)


func ensure_default_control_scheme() -> void:
	for action in InputDefaults.MANAGED_ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action, InputDefaults.default_deadzone(action))
		var existing := InputMap.action_get_events(action)
		if existing.is_empty():
			_apply_default_events(action, false)


func reset_controls_to_defaults() -> void:
	for action in InputDefaults.MANAGED_ACTIONS:
		_apply_default_events(action, true)
	if FileAccess.file_exists(CONTROLS_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(CONTROLS_PATH))
	save_controls()
	bindings_changed.emit()


func load_saved_controls() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(CONTROLS_PATH) != OK:
		return false
	var version: int = cfg.get_value("meta", "version", 0)
	if version != InputDefaults.SCHEME_VERSION:
		return false
	for action in InputDefaults.MANAGED_ACTIONS:
		if not cfg.has_section_key("bindings", action):
			continue
		var serialized: Array = cfg.get_value("bindings", action, [])
		_clear_action_events(action)
		for entry in serialized:
			if entry is Dictionary:
				var ev := _dict_to_event(entry)
				if ev != null:
					InputMap.action_add_event(action, ev)
	bindings_changed.emit()
	return true


func save_controls() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "version", InputDefaults.SCHEME_VERSION)
	for action in InputDefaults.MANAGED_ACTIONS:
		var serialized: Array = []
		for event in InputMap.action_get_events(action):
			var entry := _event_to_dict(event)
			if not entry.is_empty():
				serialized.append(entry)
		cfg.set_value("bindings", action, serialized)
	cfg.save(CONTROLS_PATH)


func remap_action(action: String, events: Array) -> void:
	if action not in InputDefaults.MANAGED_ACTIONS:
		push_warning("InputManager: cannot remap unmanaged action %s" % action)
		return
	_clear_action_events(action)
	for event in events:
		InputMap.action_add_event(action, event)
	save_controls()
	_validate_critical_conflicts()
	bindings_changed.emit()


func _on_modal_closed(_a: Variant = null) -> void:
	suppress_gameplay_input_ms(180)


func suppress_gameplay_input_ms(ms: int = 180) -> void:
	_gameplay_suppressed_until_msec = Time.get_ticks_msec() + ms


func gameplay_input_blocked() -> bool:
	if Time.get_ticks_msec() < _gameplay_suppressed_until_msec:
		return true
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and tree.paused:
		return true
	return DialogueManager.blocks_gameplay() \
		or MerchantManager.is_shop_open \
		or GameManager.is_paused


func _apply_default_events(action: String, force: bool) -> void:
	if force:
		_clear_action_events(action)
	elif not InputMap.action_get_events(action).is_empty():
		return
	for event in InputDefaults.default_events(action):
		InputMap.action_add_event(action, event)


func _remove_obsolete_actions() -> void:
	for obsolete in [
		"switch_target", "execute", "weapon_skill", "salvage", "track_objective",
	]:
		if InputMap.has_action(obsolete):
			InputMap.erase_action(obsolete)


func _validate_critical_conflicts() -> void:
	var pad_map: Dictionary = {}
	for action in _MENU_GAMEPAD_ACTIONS:
		for event in InputMap.action_get_events(action):
			if event is InputEventJoypadButton:
				var btn: int = (event as InputEventJoypadButton).button_index
				if pad_map.has(btn):
					push_warning(
						"InputManager: controller button %d bound to both %s and %s"
						% [btn, pad_map[btn], action]
					)
				else:
					pad_map[btn] = action


func _clear_action_events(action: String) -> void:
	if not InputMap.has_action(action):
		return
	for event in InputMap.action_get_events(action).duplicate():
		InputMap.action_erase_event(action, event)


func _event_to_dict(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		return {"t": "key", "code": (event as InputEventKey).physical_keycode}
	if event is InputEventMouseButton:
		return {"t": "mouse", "button": (event as InputEventMouseButton).button_index}
	if event is InputEventJoypadButton:
		return {"t": "pad_btn", "button": (event as InputEventJoypadButton).button_index}
	if event is InputEventJoypadMotion:
		var motion := event as InputEventJoypadMotion
		return {"t": "pad_motion", "axis": motion.axis, "value": motion.axis_value}
	return {}


func _dict_to_event(data: Dictionary) -> InputEvent:
	match String(data.get("t", "")):
		"key":
			return InputDefaults.event_from_key(data.get("code", 0) as Key)
		"mouse":
			return InputDefaults.event_from_mouse(data.get("button", 0) as MouseButton)
		"pad_btn":
			return InputDefaults.event_from_pad_button(data.get("button", 0) as JoyButton)
		"pad_motion":
			return InputDefaults.event_from_trigger(
				data.get("axis", 0) as JoyAxis,
				float(data.get("value", 0.0))
			)
	return null


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed:
		_set_device(DEVICE_GAMEPAD)
	elif event is InputEventJoypadMotion:
		var motion := event as InputEventJoypadMotion
		if motion.axis in [0, 1, 4, 5] and absf(motion.axis_value) >= STICK_DEVICE_THRESHOLD:
			_set_device(DEVICE_GAMEPAD)
	elif event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion:
		_set_device(DEVICE_KEYBOARD)


func _set_device(device: int) -> void:
	if current_device == device:
		return
	current_device = device
	device_changed.emit(current_device)


func _setup_player2_inputs() -> void:
	var all_actions: Array[String] = []
	all_actions.append_array(CO_OP_ACTIONS)
	all_actions.append_array(P2_MENU_ACTIONS)
	for action in all_actions:
		var p2_action := "p2_%s" % action
		if InputMap.has_action(p2_action):
			continue
		InputMap.add_action(p2_action)
		if P2_KEYBOARD.has(action):
			var key := InputEventKey.new()
			key.physical_keycode = P2_KEYBOARD[action]
			InputMap.action_add_event(p2_action, key)
		elif P2_MENU_KEYBOARD.has(action):
			var menu_key := InputEventKey.new()
			menu_key.physical_keycode = P2_MENU_KEYBOARD[action]
			InputMap.action_add_event(p2_action, menu_key)
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


func _on_joy_changed(_device: int, connected: bool) -> void:
	if not connected:
		_notify_players_release_block()
	_detect_device()


func _notify_players_release_block() -> void:
	var tree := get_tree()
	if tree == null:
		return
	for player in tree.get_nodes_in_group("player"):
		var combat := player.get_node_or_null("Combat")
		if combat and combat.has_method("force_release_combat_state"):
			combat.force_release_combat_state()


func _detect_device() -> void:
	if Input.get_connected_joypads().size() > 0:
		_set_device(DEVICE_GAMEPAD)
	else:
		_set_device(DEVICE_KEYBOARD)


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
