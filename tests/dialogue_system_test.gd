extends Node
## Comprehensive dialogue system tests using production DialogueManager.

const DialoguePanelScene = preload("res://ui/dialogue/dialogue_panel.tscn")

var _passed := 0
var _failed := 0
var _choice_index := -1
var _ended := false
var _end_count := 0
var _panel: Control


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	await get_tree().process_frame
	_panel = DialoguePanelScene.instantiate() as Control
	add_child(_panel)
	DialogueManager.bind_panel(_panel)
	DialogueManager.dialogue_choice_selected.connect(_on_choice)
	DialogueManager.dialogue_ended.connect(_on_ended)

	await _test_input_actions()
	await _test_single_line_confirm()
	await _test_single_line_cancel()
	await _test_multiline_advance()
	await _test_held_key_protection()
	await _test_choice_keyboard()
	await _test_choice_cancel()
	await _test_confirmation_debounce()
	await _test_duplicate_input_guard()
	await _test_empty_dialogue_recovery()
	await _test_footer_labels()
	await _test_merchant_trade_confirmation()
	await _test_gameplay_lock()
	await _test_auto_open_no_interact_gate()

	print("Dialogue system tests: %d passed, %d failed" % [_passed, _failed])
	get_tree().quit(_failed)


func _test_input_actions() -> void:
	_assert(InputMap.has_action("dialogue_confirm"), "dialogue_confirm exists")
	_assert(InputMap.has_action("dialogue_cancel"), "dialogue_cancel exists")
	_assert(InputMap.has_action("dialogue_continue"), "dialogue_continue exists")
	_assert(InputMap.has_action("ui_accept"), "ui_accept exists")
	_assert(InputMap.has_action("ui_cancel"), "ui_cancel exists")


func _test_single_line_confirm() -> void:
	_reset_tracking()
	DialogueManager.start_dialogue("silent_merchant", [
		{"speaker": "Silent Merchant", "text": "Coins talk. I don't."},
	], [], {"from_interact": true})
	_assert(DialogueManager.is_active(), "single-line opens")
	await _wait_confirm_ready()
	DialogueManager.try_confirm_input()
	await get_tree().process_frame
	_assert(_ended, "single-line confirm closes")


func _test_single_line_cancel() -> void:
	_reset_tracking()
	DialogueManager.start_dialogue("silent_merchant", [
		{"speaker": "Silent Merchant", "text": "Coins talk. I don't."},
	], [], {"from_interact": true})
	await get_tree().process_frame
	DialogueManager.try_cancel_input()
	await get_tree().process_frame
	_assert(_ended, "single-line cancel closes")
	_assert(DialogueManager.ended_by_cancel, "single-line cancel flagged")


func _test_multiline_advance() -> void:
	_reset_tracking()
	DialogueManager.start_dialogue("wolf_crest_shrine", [
		{"speaker": "Shrine", "text": "Line one."},
		{"speaker": "Shrine", "text": "Line two."},
	], [], {"from_interact": true})
	await _wait_confirm_ready()
	DialogueManager.try_confirm_input()
	await get_tree().process_frame
	_assert(DialogueManager.is_active(), "multiline still active after first advance")
	_assert(DialogueManager.state == DialogueManager.DialogueState.DISPLAYING_LINE, "second line displaying")
	await _wait_confirm_ready()
	DialogueManager.try_confirm_input()
	await get_tree().process_frame
	_assert(_ended, "multiline closes after final line")


func _test_held_key_protection() -> void:
	_reset_tracking()
	DialogueManager.start_dialogue("wolf_crest_shrine", [
		{"speaker": "Shrine", "text": "Line one."},
		{"speaker": "Shrine", "text": "Line two."},
	], [], {"from_interact": true})
	await _wait_confirm_ready()
	_simulate_action_press("dialogue_confirm")
	DialogueManager.try_confirm_input()
	await get_tree().process_frame
	var idx_after_first := DialogueManager.get_line_index()
	DialogueManager.try_confirm_input()
	await get_tree().process_frame
	_assert(DialogueManager.get_line_index() == idx_after_first, "held confirm does not skip extra lines")
	_simulate_action_release("dialogue_confirm")
	await get_tree().process_frame


func _test_choice_keyboard() -> void:
	_reset_tracking()
	DialogueManager.start_dialogue("dungeon_enter", [
		{"speaker": "ENTER DUNGEON", "text": "Enter?"},
	], ["Enter", "Cancel"], {"from_interact": true})
	await _wait_confirm_ready()
	DialogueManager.try_confirm_input()
	await get_tree().process_frame
	_assert(_choice_index == 0, "confirmation confirm selects first choice")


func _test_choice_cancel() -> void:
	_reset_tracking()
	DialogueManager.start_dialogue("dungeon_exit", [
		{"speaker": "EXIT DUNGEON", "text": "Leave?"},
	], ["Exit", "Stay"], {"from_interact": true})
	await _wait_confirm_ready()
	DialogueManager.try_cancel_input()
	await get_tree().process_frame
	_assert(_choice_index == 1, "confirmation cancel selects second choice")


func _test_confirmation_debounce() -> void:
	_reset_tracking()
	DialogueManager.start_dialogue("dungeon_enter", [
		{"speaker": "ENTER DUNGEON", "text": "Enter?"},
	], ["Enter", "Cancel"], {"from_interact": true})
	_assert(not DialogueManager.can_accept_confirm(), "confirmation debounce blocks immediate confirm")
	await _wait_confirm_ready()
	_assert(DialogueManager.can_accept_confirm(), "confirmation accept after debounce")


func _test_duplicate_input_guard() -> void:
	_reset_tracking()
	DialogueManager.start_dialogue("dungeon_enter", [
		{"speaker": "ENTER DUNGEON", "text": "Enter?"},
	], ["Enter", "Cancel"], {"from_interact": true})
	await _wait_confirm_ready()
	DialogueManager.try_confirm_input()
	DialogueManager.try_confirm_input()
	await get_tree().process_frame
	_assert(_end_count == 1, "duplicate confirm produces one close")


func _test_empty_dialogue_recovery() -> void:
	_reset_tracking()
	DialogueManager.start_dialogue("empty_test", [], [], {"from_interact": false})
	_assert(not DialogueManager.is_active(), "empty dialogue does not open")


func _test_footer_labels() -> void:
	_reset_tracking()
	DialogueManager.start_dialogue("silent_merchant", [
		{"speaker": "Silent Merchant", "text": "Coins talk."},
	], [], {"from_interact": true, "confirm_label": "Trade", "cancel_label": "Leave"})
	var labels := DialogueManager.get_footer_labels()
	_assert(labels.confirm == "Trade", "merchant confirm label")
	_assert(labels.cancel == "Leave", "merchant cancel label")
	DialogueManager.end_dialogue()


func _test_merchant_trade_confirmation() -> void:
	_reset_tracking()
	DialogueManager.start_dialogue("silent_merchant", [
		{"speaker": "Silent Merchant", "text": "Coins talk. I don't."},
	], ["Trade", "Leave"], {"from_interact": true, "confirm_label": "Trade", "cancel_label": "Leave"})
	_assert(DialogueManager.is_waiting_for_confirmation(), "merchant uses confirmation state")
	await _wait_confirm_ready()
	DialogueManager.try_confirm_input()
	await get_tree().process_frame
	_assert(_choice_index == 0, "Trade confirm selects index 0")
	_assert(_ended, "Trade confirm closes dialogue")
	_assert(DialogueManager.last_end_reason == DialogueManager.DialogueEndReason.CONFIRMED, "Trade confirm reason")
	_assert(not DialogueManager.ended_by_cancel, "Trade confirm is not cancel")


func _test_gameplay_lock() -> void:
	_reset_tracking()
	_assert(not DialogueManager.blocks_gameplay(), "gameplay unlocked when closed")
	DialogueManager.start_dialogue("silent_merchant", [
		{"speaker": "Silent Merchant", "text": "Coins talk."},
	], [], {"from_interact": false})
	_assert(DialogueManager.blocks_gameplay(), "gameplay locked during dialogue")
	DialogueManager.end_dialogue()
	await get_tree().process_frame
	_assert(not DialogueManager.blocks_gameplay(), "gameplay restored after dialogue")


func _test_auto_open_no_interact_gate() -> void:
	_reset_tracking()
	DialogueManager.start_dialogue("quest_wolf_done", [
		{"speaker": "Quest", "text": "Quest complete."},
	], [], {"from_interact": false})
	_assert(not DialogueManager.is_waiting_for_interact_release(), "auto dialogue skips interact release gate")
	DialogueManager.end_dialogue()


func _wait_confirm_ready() -> void:
	var deadline := Time.get_ticks_msec() + 500
	while not DialogueManager.can_accept_confirm() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame


func _reset_tracking() -> void:
	if DialogueManager.is_active():
		DialogueManager.end_dialogue()
	_choice_index = -1
	_ended = false
	_end_count = 0
	await get_tree().process_frame


func _on_choice(index: int) -> void:
	_choice_index = index


func _on_ended() -> void:
	_ended = true
	_end_count += 1


func _simulate_action_press(action: String) -> void:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var copy := event.duplicate()
			copy.pressed = true
			Input.parse_input_event(copy)
			return


func _simulate_action_release(action: String) -> void:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var copy := event.duplicate()
			copy.pressed = false
			Input.parse_input_event(copy)
			return


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
