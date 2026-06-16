class_name CoopUiCopy
extends RefCounted
## Unified co-op prompt labels — P1/P2 tags, Player 1/2 long form, input bindings.

const _UiInputLabels := preload("res://ui/themes/ui_input_labels.gd")


static func player_tag(index: int) -> String:
	return "P%d" % (index + 1)


static func player_long(index: int) -> String:
	return "Player %d" % (index + 1)


static func binding(action: String, player_index: int, device_override: int = -1) -> String:
	var mapped := action
	if player_index > 0 and not action.begins_with("p2_"):
		mapped = "p2_%s" % action
	var device := device_override
	if device < 0:
		device = InputManager.DEVICE_GAMEPAD if player_index > 0 else InputManager.current_device
	var key := _UiInputLabels.get_primary_binding_text(StringName(mapped), device)
	if key != "":
		return key
	match mapped:
		"interact": return "E"
		"p2_interact": return "A"
		"confirm": return "A"
		"p2_confirm": return "A"
		"cancel": return "B"
		"p2_cancel": return "B"
		"p2_light_attack": return "X"
		"p2_heavy_attack": return "Y"
		"p2_quick_spell": return "RB"
		"p2_dodge": return "B"
		"pause": return "Start"
		"p2_pause": return "Start"
		_: return "?"


static func press_prompt(player_index: int, verb: String, action: String = "interact") -> String:
	return "%s: Press %s — %s" % [player_tag(player_index), binding(action, player_index), verb]


static func hold_prompt(player_index: int, verb: String, action: String = "interact") -> String:
	return "%s: Hold %s — %s" % [player_tag(player_index), binding(action, player_index), verb]


static func revive_hold_prompt(reviver_index: int, target_index: int) -> String:
	return "%s: Hold %s to Revive %s" % [
		player_tag(reviver_index),
		binding("interact", reviver_index),
		player_long(target_index),
	]


static func revive_progress(reviver_index: int, target_index: int, percent: float) -> String:
	return "%s reviving %s — %.0f%%" % [player_tag(reviver_index), player_long(target_index), percent]


static func downed_waiting(index: int) -> String:
	return "%s Downed | Waiting for Revive" % player_tag(index)


static func menu_owner_line(owner_index: int) -> String:
	if not GameManager.is_local_coop():
		return ""
	return "%s Menu" % player_tag(owner_index)


static func menu_controlled_by(owner_index: int) -> String:
	if not GameManager.is_local_coop():
		return ""
	return "Controlled by %s" % player_tag(owner_index)


static func menu_footer(owner_index: int) -> String:
	var confirm := binding("confirm", owner_index)
	var cancel := binding("cancel", owner_index)
	if GameManager.is_local_coop():
		return "%s Confirm | %s Cancel" % [confirm, cancel]
	return "%s Confirm | %s Cancel" % [confirm, cancel]


static func revive_canceled(reason: String) -> String:
	return "Revive Canceled: %s" % reason


static func revive_complete(target_index: int) -> String:
	return "%s Revived" % player_long(target_index)
