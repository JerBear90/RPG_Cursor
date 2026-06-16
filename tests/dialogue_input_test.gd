extends Node
## Validates dungeon confirmation dialogue input flow headlessly.

const DUNGEON_SCENE := "res://scenes/dungeons/procedural_dungeon.tscn"

var _passed := 0
var _failed := 0
var _choice_index := -1
var _ended := false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	await get_tree().process_frame
	_assert(InputMap.has_action("dialogue_confirm"), "dialogue_confirm action exists")
	_assert(InputMap.has_action("dialogue_cancel"), "dialogue_cancel action exists")
	_assert(InputMap.has_action("dialogue_continue"), "dialogue_continue action exists")
	_assert(_action_has_key("dialogue_confirm", KEY_E), "dialogue_confirm binds E")
	_assert(_action_has_key("dialogue_cancel", KEY_ESCAPE), "dialogue_cancel binds Escape")
	_assert(ResourceLoader.exists(DUNGEON_SCENE), "dungeon scene exists: %s" % DUNGEON_SCENE)

	DialogueManager.dialogue_choice_selected.connect(_on_choice)
	DialogueManager.dialogue_ended.connect(_on_ended)

	DialogueManager.start_dialogue("dungeon_enter", [
		{"speaker": "ENTER DUNGEON", "text": "Abandoned Mine\n\nEnter this dungeon?"},
	], ["Enter", "Cancel"], {"from_interact": true})
	_assert(DialogueManager.is_active(), "dialogue opens")
	_assert(
		DialogueManager.state == DialogueManager.DialogueState.WAITING_FOR_CONFIRMATION,
		"confirmation state active"
	)
	_assert(not DialogueManager.can_accept_confirm(), "open debounce blocks immediate confirm")

	var deadline := Time.get_ticks_msec() + 400
	while not DialogueManager.can_accept_confirm() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	_assert(DialogueManager.can_accept_confirm(), "confirm allowed after debounce")

	DialogueManager.try_confirm_input()
	await get_tree().process_frame
	_assert(_choice_index == 0, "confirm selects Enter")
	_assert(_ended, "dialogue closes after confirm")

	_choice_index = -1
	_ended = false
	DialogueManager.start_dialogue("dungeon_enter", [
		{"speaker": "ENTER DUNGEON", "text": "Abandoned Mine\n\nEnter this dungeon?"},
	], ["Enter", "Cancel"], {"from_interact": true})
	await get_tree().process_frame
	await _wait_confirm_ready()
	DialogueManager.try_cancel_input()
	await get_tree().process_frame
	_assert(_choice_index == 1, "cancel selects Cancel")
	_assert(_ended, "dialogue closes after cancel")

	print("Dialogue input tests: %d passed, %d failed" % [_passed, _failed])
	get_tree().quit(_failed)


func _wait_confirm_ready() -> void:
	var deadline := Time.get_ticks_msec() + 400
	while not DialogueManager.can_accept_confirm() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame


func _on_choice(index: int) -> void:
	_choice_index = index


func _on_ended() -> void:
	_ended = true


func _action_has_key(action: String, keycode: Key) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey and (event as InputEventKey).physical_keycode == keycode:
			return true
	return false


func _simulate_action_press(action: String) -> void:
	for event in InputMap.action_get_events(action):
		var copy := event.duplicate()
		copy.pressed = true
		Input.parse_input_event(copy)


func _simulate_action_release(action: String) -> void:
	for event in InputMap.action_get_events(action):
		var copy := event.duplicate()
		copy.pressed = false
		Input.parse_input_event(copy)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
