extends Node
## Dialogue presentation with explicit state machine and centralized input routing.

enum DialogueState {
	CLOSED,
	OPENING,
	DISPLAYING_LINE,
	WAITING_FOR_CONTINUE,
	DISPLAYING_CHOICES,
	WAITING_FOR_CONFIRMATION,
	CLOSING,
}

enum DialogueEndReason {
	NONE,
	CONFIRMED,
	CANCELLED,
	COMPLETED,
	INTERRUPTED,
	FAILED,
}

signal dialogue_started(npc_id: String)
signal dialogue_line_shown(speaker: String, text: String)
signal dialogue_choices_shown(options: Array[String])
signal dialogue_footer_labels(confirm_label: String, cancel_label: String)
signal dialogue_focus_choice(delta: int)
signal dialogue_ended
signal dialogue_choice_selected(index: int)
signal dialogue_finished(npc_id: String, reason: DialogueEndReason, choice_index: int)

const OPEN_DEBOUNCE_SEC := 0.25
const CONFIRMATION_DEBOUNCE_MSEC := 200

var state: DialogueState = DialogueState.CLOSED
var last_end_reason: DialogueEndReason = DialogueEndReason.NONE
var last_choice_index: int = -1
var _npc_id: String = ""
var _lines: Array[Dictionary] = []
var _choices: Array[String] = []
var _index: int = 0
var _opened_at: float = 0.0
var _opened_from_interact: bool = false
var _waiting_for_interact_release: bool = false
var _waiting_for_advance_release: bool = false
var _confirm_enabled_at_msec: int = 0
var _confirm_label: String = ""
var _cancel_label: String = ""
var _last_confirm_frame: int = -1
var _last_cancel_frame: int = -1
var _dialogue_panel: Control = null
var ended_by_cancel: bool = false


func bind_panel(panel: Control) -> void:
	_dialogue_panel = panel


func _ready() -> void:
	set_process(true)


func _input(event: InputEvent) -> void:
	if not is_active():
		return
	if not _is_dialogue_cancel_event(event):
		return
	if try_cancel_input():
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if not is_active():
		return
	if _is_dialogue_confirm_event(event):
		if try_confirm_input():
			get_viewport().set_input_as_handled()
		return
	if _is_dialogue_cancel_event(event):
		if try_cancel_input():
			get_viewport().set_input_as_handled()
		return
	if state == DialogueState.DISPLAYING_CHOICES and _choices.size() > 2:
		if event.is_action_pressed("ui_down"):
			dialogue_focus_choice.emit(1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_up"):
			dialogue_focus_choice.emit(-1)
			get_viewport().set_input_as_handled()
	elif _choices.size() == 2 and (
		state == DialogueState.WAITING_FOR_CONFIRMATION
		or state == DialogueState.DISPLAYING_CHOICES
	):
		if event.is_action_pressed("ui_right") or event.is_action_pressed("ui_down"):
			dialogue_focus_choice.emit(1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_left") or event.is_action_pressed("ui_up"):
			dialogue_focus_choice.emit(-1)
			get_viewport().set_input_as_handled()


func start_dialogue(
	npc_id: String,
	lines: Array[Dictionary],
	choices: Array[String] = [],
	options: Dictionary = {}
) -> void:
	if state != DialogueState.CLOSED:
		return
	if lines.is_empty():
		push_warning("DialogueManager.start_dialogue called with no lines for %s" % npc_id)
		return
	ended_by_cancel = false
	last_end_reason = DialogueEndReason.NONE
	last_choice_index = -1
	state = DialogueState.OPENING
	_npc_id = npc_id
	_lines = lines.duplicate()
	_choices = choices.duplicate()
	_index = 0
	_opened_at = Time.get_ticks_msec() / 1000.0
	_opened_from_interact = options.get("from_interact", false)
	GameManager.interacting_player_index = int(options.get("interacting_player_index", GameManager.interacting_player_index))
	_confirm_label = str(options.get("confirm_label", ""))
	_cancel_label = str(options.get("cancel_label", ""))
	_last_confirm_frame = -1
	_last_cancel_frame = -1
	_waiting_for_advance_release = false
	_waiting_for_interact_release = _opened_from_interact and _is_confirm_action_held()
	_confirm_enabled_at_msec = Time.get_ticks_msec()
	if _lines.size() == 1 and _choices.size() > 0:
		_confirm_enabled_at_msec += CONFIRMATION_DEBOUNCE_MSEC
	elif _opened_from_interact and _waiting_for_interact_release:
		_confirm_enabled_at_msec += CONFIRMATION_DEBOUNCE_MSEC
	dialogue_started.emit(npc_id)
	set_process_input(true)
	state = DialogueState.DISPLAYING_LINE
	_show_current()
	if _lines.size() == 1 and _choices.size() > 0:
		state = DialogueState.WAITING_FOR_CONFIRMATION
		_show_choices()


func start_confirmation(
	title: String,
	body: String,
	confirm_label: String = "Confirm",
	cancel_label: String = "Cancel",
	from_interact: bool = true
) -> void:
	start_dialogue(
		"confirmation",
		[{"speaker": title, "text": body}],
		[confirm_label, cancel_label],
		{"from_interact": from_interact, "confirm_label": confirm_label, "cancel_label": cancel_label}
	)


func start_dialogue_and_wait(
	npc_id: String,
	lines: Array[Dictionary],
	choices: Array[String] = [],
	options: Dictionary = {}
) -> Dictionary:
	start_dialogue(npc_id, lines, choices, options)
	if not is_active():
		return {
			"npc_id": npc_id,
			"reason": DialogueEndReason.FAILED,
			"choice_index": -1,
		}
	var payload: Array = await dialogue_finished
	return {
		"npc_id": str(payload[0]),
		"reason": payload[1],
		"choice_index": int(payload[2]),
	}


func advance() -> void:
	try_confirm_input()


func cancel() -> void:
	try_cancel_input()


func try_confirm_input() -> bool:
	if state == DialogueState.CLOSED or state == DialogueState.CLOSING:
		return false
	if not can_accept_confirm():
		return false
	var frame := Engine.get_process_frames()
	if frame == _last_confirm_frame:
		return false
	_last_confirm_frame = frame
	handle_confirm_input()
	return true


func try_cancel_input() -> bool:
	if state == DialogueState.CLOSED:
		return false
	if not can_accept_cancel():
		return false
	var frame := Engine.get_process_frames()
	if frame == _last_cancel_frame:
		return false
	_last_cancel_frame = frame
	handle_cancel_input()
	return true


func handle_confirm_input() -> void:
	if state == DialogueState.WAITING_FOR_CONFIRMATION:
		select_choice(_default_confirm_choice_index())
		return
	if state == DialogueState.DISPLAYING_CHOICES:
		var choice_idx := _default_confirm_choice_index()
		if _choices.size() > 2 and _dialogue_panel and _dialogue_panel.has_method("get_focused_choice_index"):
			choice_idx = _dialogue_panel.call("get_focused_choice_index")
		select_choice(choice_idx)
		return
	if state == DialogueState.DISPLAYING_LINE or state == DialogueState.WAITING_FOR_CONTINUE:
		_index += 1
		if _index >= _lines.size():
			if _choices.size() > 0:
				_show_choices()
			else:
				end_dialogue(DialogueEndReason.COMPLETED)
		else:
			state = DialogueState.DISPLAYING_LINE
			_show_current()
		_waiting_for_advance_release = _is_confirm_action_held()


func handle_cancel_input() -> void:
	if state == DialogueState.WAITING_FOR_CONFIRMATION or (
		state == DialogueState.DISPLAYING_CHOICES and _choices.size() > 1
	):
		select_choice(_default_cancel_choice_index())
		return
	end_dialogue(DialogueEndReason.CANCELLED)


func select_choice(index: int) -> void:
	if state != DialogueState.DISPLAYING_CHOICES and state != DialogueState.WAITING_FOR_CONFIRMATION:
		return
	if index < 0 or index >= _choices.size():
		return
	var reason := DialogueEndReason.CONFIRMED
	if _choices.size() > 1 and index == _default_cancel_choice_index():
		reason = DialogueEndReason.CANCELLED
	last_choice_index = index
	dialogue_choice_selected.emit(index)
	_close_dialogue(reason)


func end_dialogue(reason: DialogueEndReason = DialogueEndReason.COMPLETED) -> void:
	if state == DialogueState.CLOSED:
		return
	_close_dialogue(reason)


func _close_dialogue(reason: DialogueEndReason) -> void:
	if state == DialogueState.CLOSED:
		return
	var closing_npc_id := _npc_id
	var closing_choice := last_choice_index
	state = DialogueState.CLOSING
	_lines.clear()
	_choices.clear()
	_index = 0
	_npc_id = ""
	_confirm_label = ""
	_cancel_label = ""
	_waiting_for_interact_release = false
	_waiting_for_advance_release = false
	_opened_from_interact = false
	state = DialogueState.CLOSED
	set_process_input(false)
	last_end_reason = reason
	last_choice_index = closing_choice
	ended_by_cancel = reason == DialogueEndReason.CANCELLED
	dialogue_finished.emit(closing_npc_id, reason, closing_choice)
	dialogue_ended.emit()
	GameManager.interacting_player_index = 0


func is_active() -> bool:
	return state != DialogueState.CLOSED


func is_waiting_for_confirmation() -> bool:
	return state == DialogueState.WAITING_FOR_CONFIRMATION


func has_pending_choices() -> bool:
	return _choices.size() > 0


func blocks_gameplay() -> bool:
	return is_active()


func get_current_npc_id() -> String:
	return _npc_id


func get_line_index() -> int:
	return _index


func is_waiting_for_interact_release() -> bool:
	return _waiting_for_interact_release


func get_footer_labels() -> Dictionary:
	return {
		"confirm": _resolve_confirm_label(),
		"cancel": _resolve_cancel_label(),
	}


func can_accept_confirm() -> bool:
	if not is_active():
		return false
	if Time.get_ticks_msec() < _confirm_enabled_at_msec:
		return false
	if _waiting_for_interact_release or _waiting_for_advance_release:
		return false
	return state in [
		DialogueState.WAITING_FOR_CONTINUE,
		DialogueState.DISPLAYING_LINE,
		DialogueState.DISPLAYING_CHOICES,
		DialogueState.WAITING_FOR_CONFIRMATION,
	]


func can_accept_cancel() -> bool:
	return is_active()


func can_accept_advance() -> bool:
	return can_accept_confirm()


func _process(_delta: float) -> void:
	if not is_active():
		return
	if _waiting_for_interact_release and not _is_confirm_action_held():
		_waiting_for_interact_release = false
	if _waiting_for_advance_release and not _is_confirm_action_held():
		_waiting_for_advance_release = false
	if state == DialogueState.DISPLAYING_LINE and _choices.is_empty():
		var elapsed := Time.get_ticks_msec() / 1000.0 - _opened_at
		if elapsed >= OPEN_DEBOUNCE_SEC:
			state = DialogueState.WAITING_FOR_CONTINUE


func _show_current() -> void:
	if _index < _lines.size():
		var line := _lines[_index]
		dialogue_line_shown.emit(line.get("speaker", ""), line.get("text", ""))
		_emit_footer_labels()


func _show_choices() -> void:
	if state != DialogueState.WAITING_FOR_CONFIRMATION:
		state = DialogueState.DISPLAYING_CHOICES
	dialogue_choices_shown.emit(_choices)
	_emit_footer_labels()


func _emit_footer_labels() -> void:
	var labels := get_footer_labels()
	dialogue_footer_labels.emit(labels.confirm, labels.cancel)


func _resolve_confirm_label() -> String:
	if _confirm_label != "":
		return _confirm_label
	if _choices.size() >= 1 and state in [
		DialogueState.WAITING_FOR_CONFIRMATION,
		DialogueState.DISPLAYING_CHOICES,
	]:
		return _choices[0]
	match _npc_id:
		"dungeon_enter":
			return "Enter"
		"dungeon_exit":
			return "Exit"
		"camp_rest":
			return "Rest"
		"confirmation":
			return "Confirm"
		"silent_merchant", "camp_vendor", "tool_vendor", "herbalist", "old_blacksmith", "tomas_reed", "weapon_armorer", "bram_ironhand", "quartermaster_vale", "beast_handler", "waystone_keeper", "marsh_scout_vendor", "stonewatch_merchant", "stonewatch_forge", "frostwatch_merchant", "frostwatch_forge", "tidewatch_merchant", "tidewatch_forge", "nima_dareth", "dagan_sunforge", "doctor_sol_marr", "mira_sol", "selene_nightforge", "doctor_corvin_hale":
			return "Trade"
		_:
			return "Continue"


func _resolve_cancel_label() -> String:
	if _cancel_label != "":
		return _cancel_label
	if _choices.size() >= 2 and state in [
		DialogueState.WAITING_FOR_CONFIRMATION,
		DialogueState.DISPLAYING_CHOICES,
	]:
		return _choices[1]
	match _npc_id:
		"dungeon_enter", "camp_rest", "confirmation":
			return "Cancel"
		"dungeon_exit":
			return "Stay"
		"silent_merchant", "camp_vendor", "tool_vendor", "herbalist", "old_blacksmith", "tomas_reed", "weapon_armorer", "bram_ironhand", "quartermaster_vale", "beast_handler", "waystone_keeper", "marsh_scout_vendor", "stonewatch_merchant", "stonewatch_forge", "frostwatch_merchant", "frostwatch_forge", "tidewatch_merchant", "tidewatch_forge", "nima_dareth", "dagan_sunforge", "doctor_sol_marr", "mira_sol", "selene_nightforge", "doctor_corvin_hale":
			return "Leave"
		_:
			return "Leave"


func _default_confirm_choice_index() -> int:
	return 0


func _default_cancel_choice_index() -> int:
	return 1 if _choices.size() > 1 else 0


func _is_dialogue_confirm_event(event: InputEvent) -> bool:
	var idx := GameManager.interacting_player_index
	if idx > 0:
		if event.is_action_pressed("p2_interact"):
			return true
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			return event.device == 1
		return false
	if event.is_action_pressed("p2_interact"):
		return false
	return event.is_action_pressed("dialogue_confirm") \
		or event.is_action_pressed("dialogue_continue") \
		or event.is_action_pressed("confirm") \
		or event.is_action_pressed("ui_accept") \
		or event.is_action_pressed("interact")


func _is_dialogue_cancel_event(event: InputEvent) -> bool:
	return event.is_action_pressed("dialogue_cancel") \
		or event.is_action_pressed("cancel") \
		or event.is_action_pressed("ui_cancel")


func _is_confirm_action_held() -> bool:
	var idx := GameManager.interacting_player_index
	if idx > 0:
		return Input.is_action_pressed("p2_interact")
	if Input.is_action_pressed("p2_interact"):
		return false
	return Input.is_action_pressed("interact") \
		or Input.is_action_pressed("dialogue_confirm") \
		or Input.is_action_pressed("dialogue_continue") \
		or Input.is_action_pressed("confirm") \
		or Input.is_action_pressed("ui_accept")


func get_npc_greeting(npc_id: String) -> Array[Dictionary]:
	if QuestManager.active_quests.has("merchant_errand") and npc_id == "wounded_scout":
		return [{"speaker": "Wounded Scout", "text": "Bring me herb bundles — three will do. The merchant pays well."}]
	if QuestManager.completed_quests.has("find_wolf_crest") and npc_id == "silent_merchant":
		return [{"speaker": "Silent Merchant", "text": "You carry the wolf's mark now. Prices stay the same."}]
	match npc_id:
		"silent_merchant":
			return [{"speaker": "Silent Merchant", "text": "Coins talk. I don't."}]
		"old_blacksmith", "bram_ironhand":
			return [{"speaker": "Old Blacksmith", "text": "Need steel, stitches, or a reason not to die? Pick one."}]
		"camp_vendor":
			return [{"speaker": "Camp Vendor", "text": "Supplies for survivors — fair prices, no questions."}]
		"herbalist":
			return [{"speaker": "Herbalist", "text": "Roots and leaves keep you breathing out here."}]
		"tool_vendor":
			return [{"speaker": "Tool Vendor", "text": "Wood, stone, and patch kits — everything a builder needs."}]
		"tomas_reed":
			return [{"speaker": "Tomas Reed", "text": "Rations, bandages, and marsh tonics — stock up before Rotfen."}]
		"weapon_armorer":
			return [{"speaker": "Arms Dealer", "text": "Steel and leather for those who walk the wall."}]
		"quartermaster_vale":
			return [{"speaker": "Camp Builder", "text": "Camp won't survive on hope and mud. Build smart."}]
		"beast_handler":
			return [{"speaker": "Beast Handler", "text": "Animals know this land better than we do. Mostly because they complain less."}]
		"waystone_keeper":
			return [{"speaker": "Waystone Keeper", "text": "Stones sleep until fed crystal and courage."}]
		"wounded_scout":
			if QuestManager.completed_quests.has("clear_bandit_path"):
				return [{"speaker": "Wounded Scout", "text": "Path's quieter. For now."}]
			if QuestManager.completed_quests.has("merchant_errand"):
				return [{"speaker": "Wounded Scout", "text": "You kept someone breathing. The forest owes you."}]
			return [{"speaker": "Wounded Scout", "text": "Bandits turned the path into a butcher shop. Help if you can."}]
		"captain_elira_voss":
			return [{"speaker": "Captain Elira Voss", "text": "Hearthhold stands because we stand together."}]
		"mara_fen":
			return [{"speaker": "Mara Fen", "text": "The marsh remembers every misstep."}]
		"sister_anwen":
			return [{"speaker": "Sister Anwen", "text": "Poison and rot take root quickly. Come to the infirmary if you need cleansing."}]
		"hearthhold_guard":
			return [{"speaker": "Town Guard", "text": "Keep your weapons sheathed in the square."}]
		"marsh_scout_vendor":
			return [{"speaker": "Marsh Scout", "text": "Supplies are thin out here. Buy what you can carry."}]
		"stonewatch_merchant":
			if QuestManager.active_quests.has("the_broken_rail"):
				return [{"speaker": "Merrin Slate", "text": "Raiders hit the rail line again. Stock heat tonics if you're heading out."}]
			return [{"speaker": "Merrin Slate", "text": "Heat tonics, bandages, and mining supplies — Stonewatch keeps the highlands supplied."}]
		"stonewatch_forge":
			return [{"speaker": "Hesta Coalhand", "text": "Bring cinder ore and blackvein iron. I'll temper gear that won't melt on you."}]
		"frostwatch_merchant":
			if QuestManager.active_quests.has("the_buried_village"):
				return [{"speaker": "Elen Marr", "text": "The buried village lost contact days ago. Stock warming tonics before you march."}]
			return [{"speaker": "Elen Marr", "text": "Rations, bandages, and warming tonics — Frostwatch keeps the tundra supplied."}]
		"frostwatch_forge":
			return [{"speaker": "Orik Frosthand", "text": "Bring rime ore and black ice. I'll forge gear that won't shatter in the gravewind."}]
		"frostwatch_commander":
			if QuestManager.active_quests.has("into_the_white"):
				return [{"speaker": "Commander Ysra Vale", "text": "Paleheart Crypt breathes gravewind into the tundra. We need every blade at the bastion."}]
			if QuestManager.completed_quests.has("the_pale_heart"):
				return [{"speaker": "Commander Ysra Vale", "text": "The Hollow King is fallen. The coast road may yet be saved."}]
			return [{"speaker": "Commander Ysra Vale", "text": "Frostwatch holds the line. Speak when you're ready to push toward Paleheart."}]
		"hunter_rell":
			return [{"speaker": "Hunter Rell", "text": "Frostfang packs circle the pilgrim road. I can mark their dens if you hunt them."}]
		"tidewatch_merchant":
			return [{"speaker": "Maela Shore", "text": "Storm tonics, bandages, and coastal supplies — Tidewatch keeps survivors afloat."}]
		"tidewatch_forge":
			return [{"speaker": "Garrick Hull", "text": "Salt iron and stormglass make gear that laughs at the tide. Bring salvage from the wrecks."}]
		"tidewatch_commander":
			if QuestManager.active_quests.has("into_the_storm"):
				return [{"speaker": "Admiral Serah Vane", "text": "The Drowned Citadel swells with every storm. Tidewatch must hold until we break the Sovereign's crown."}]
			if QuestManager.completed_quests.has("the_sunken_crown"):
				return [{"speaker": "Admiral Serah Vane", "text": "The Sovereign is drowned. Blightreach waits beyond the inland gate."}]
			return [{"speaker": "Admiral Serah Vane", "text": "Tidewatch stands against the tide. Speak when you're ready to push toward the citadel."}]
		"scout_lysa":
			return [{"speaker": "Scout Lysa Marr", "text": "I map wreckshore caves and tidal hazards. Ask if you need a landmark."}]
		"nima_dareth":
			return [{"speaker": "Nima Dareth", "text": "Waterskins, rations, and desert supplies — stock up before the heat takes you."}]
		"dagan_sunforge":
			return [{"speaker": "Dagan Sunforge", "text": "Bring desert glass and pyre crystal. I'll forge gear that won't melt in the ziggurat."}]
		"doctor_sol_marr":
			return [{"speaker": "Doctor Sol Marr", "text": "Heat, sand, and glass dust — I brew remedies for all three."}]
		"warden_ilyra_voss":
			if QuestManager.completed_quests.has("heart_of_the_wastes"):
				return [{"speaker": "Warden Ilyra Voss", "text": "The Solar Heart is cooled. Cinderhold holds — for now."}]
			if QuestManager.active_quests.has("heart_of_the_wastes"):
				return [{"speaker": "Warden Ilyra Voss", "text": "Pyreheart awaits. Align the mirrors and end what burns beneath the sand."}]
			return [{"speaker": "Warden Ilyra Voss", "text": "Cinderhold stands against the Ember Wastes. Speak when you're ready to march."}]
		"scout_kera_ash":
			return [{"speaker": "Scout Kera Ash", "text": "I mark dens, behemoths, and buried traps. Ask if you need a landmark."}]
		"mira_sol":
			return [{"speaker": "Mira Sol", "text": "Ward candles, dread tonics, and dominion supplies — stock up before the shadow takes you."}]
		"selene_nightforge":
			return [{"speaker": "Selene Nightforge", "text": "Bring umbral ore and shadow hide. I'll forge gear that won't fail in the sanctum."}]
		"doctor_corvin_hale":
			return [{"speaker": "Doctor Corvin Hale", "text": "Dread, shadow, and umbral sickness — I brew remedies for all three."}]
		"commander_alaric_vane":
			if QuestManager.completed_quests.has("throne_beneath_the_eclipse"):
				return [{"speaker": "Commander Alaric Vane", "text": "The sealed throne holds. Dawnwatch endures — for now."}]
			if QuestManager.active_quests.has("throne_beneath_the_eclipse"):
				return [{"speaker": "Commander Alaric Vane", "text": "Eclipse Sanctum awaits. Align the shadow wards and reach the throne antechamber."}]
			return [{"speaker": "Commander Alaric Vane", "text": "Dawnwatch stands against the Sunless Dominion. Speak when you're ready to march."}]
		"scout_nyra_vale":
			return [{"speaker": "Scout Nyra Vale", "text": "I mark dens, executioners, and shadow wells. Ask if you need a landmark."}]
		_:
			return [{"speaker": "Survivor", "text": "..."}]
