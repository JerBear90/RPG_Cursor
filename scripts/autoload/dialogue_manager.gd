extends Node
## Dialogue presentation with explicit state machine and input debounce.

enum DialogueState {
	CLOSED,
	OPENING,
	DISPLAYING_LINE,
	WAITING_FOR_INPUT,
	DISPLAYING_CHOICES,
	CLOSING,
}

signal dialogue_started(npc_id: String)
signal dialogue_line_shown(speaker: String, text: String)
signal dialogue_choices_shown(options: Array[String])
signal dialogue_ended
signal dialogue_choice_selected(index: int)

const OPEN_DEBOUNCE_SEC := 0.25

var state: DialogueState = DialogueState.CLOSED
var _npc_id: String = ""
var _lines: Array[Dictionary] = []
var _choices: Array[String] = []
var _index: int = 0
var _opened_at: float = 0.0
var _consume_next_confirm: bool = false
var _pending_choice_callback: Callable = Callable()
var ended_by_cancel: bool = false


func start_dialogue(npc_id: String, lines: Array[Dictionary], choices: Array[String] = []) -> void:
	if state != DialogueState.CLOSED:
		return
	ended_by_cancel = false
	state = DialogueState.OPENING
	_npc_id = npc_id
	_lines = lines
	_choices = choices
	_index = 0
	_opened_at = Time.get_ticks_msec() / 1000.0
	_consume_next_confirm = true
	dialogue_started.emit(npc_id)
	state = DialogueState.DISPLAYING_LINE
	_show_current()


func start_confirmation(title: String, body: String, confirm_label: String = "Enter", cancel_label: String = "Cancel") -> void:
	start_dialogue("confirmation", [
		{"speaker": title, "text": body, "confirm": confirm_label, "cancel": cancel_label},
	], [confirm_label, cancel_label])


func advance() -> void:
	if state == DialogueState.CLOSED or state == DialogueState.CLOSING:
		return
	if _consume_next_confirm:
		return
	if state == DialogueState.DISPLAYING_CHOICES:
		select_choice(0)
		return
	if state == DialogueState.DISPLAYING_LINE or state == DialogueState.WAITING_FOR_INPUT:
		_index += 1
		if _index >= _lines.size():
			if _choices.size() > 0:
				_show_choices()
			else:
				end_dialogue()
		else:
			state = DialogueState.DISPLAYING_LINE
			_show_current()


func cancel() -> void:
	if state == DialogueState.CLOSED:
		return
	if state == DialogueState.DISPLAYING_CHOICES and _choices.size() > 1:
		select_choice(1)
		return
	ended_by_cancel = true
	end_dialogue()


func select_choice(index: int) -> void:
	if state != DialogueState.DISPLAYING_CHOICES and _choices.is_empty():
		return
	dialogue_choice_selected.emit(index)
	end_dialogue()


func end_dialogue() -> void:
	if state == DialogueState.CLOSED:
		return
	state = DialogueState.CLOSING
	_lines.clear()
	_choices.clear()
	_index = 0
	_npc_id = ""
	_consume_next_confirm = false
	state = DialogueState.CLOSED
	dialogue_ended.emit()


func is_active() -> bool:
	return state != DialogueState.CLOSED


func blocks_gameplay() -> bool:
	return is_active()


func get_current_npc_id() -> String:
	return _npc_id


func can_accept_advance() -> bool:
	return is_active() and not _consume_next_confirm and (
		state == DialogueState.WAITING_FOR_INPUT
		or state == DialogueState.DISPLAYING_LINE
		or state == DialogueState.DISPLAYING_CHOICES
	)


func _process(_delta: float) -> void:
	if not is_active():
		return
	var elapsed := Time.get_ticks_msec() / 1000.0 - _opened_at
	if _consume_next_confirm and elapsed >= OPEN_DEBOUNCE_SEC:
		_consume_next_confirm = false
		state = DialogueState.WAITING_FOR_INPUT


func _show_current() -> void:
	if _index < _lines.size():
		var line := _lines[_index]
		dialogue_line_shown.emit(line.get("speaker", ""), line.get("text", ""))


func _show_choices() -> void:
	state = DialogueState.DISPLAYING_CHOICES
	dialogue_choices_shown.emit(_choices)


func get_npc_greeting(npc_id: String) -> Array[Dictionary]:
	if QuestManager.active_quests.has("merchant_errand") and npc_id == "wounded_scout":
		return [{"speaker": "Wounded Scout", "text": "Bring me herb bundles — three will do. The merchant pays well."}]
	if QuestManager.completed_quests.has("find_wolf_crest") and npc_id == "silent_merchant":
		return [{"speaker": "Silent Merchant", "text": "You carry the wolf's mark now. Prices stay the same."}]
	match npc_id:
		"silent_merchant":
			return [{"speaker": "Silent Merchant", "text": "Coins talk. I don't."}]
		"wounded_scout":
			if QuestManager.completed_quests.has("merchant_errand"):
				return [{"speaker": "Wounded Scout", "text": "You kept someone breathing. The forest owes you."}]
			return [{"speaker": "Wounded Scout", "text": "The grove... something watches from the roots."}]
		"old_blacksmith":
			return [{"speaker": "Old Blacksmith", "text": "Bring me scrap and I'll make it bite."}]
		"camp_vendor":
			return [{"speaker": "Camp Vendor", "text": "Supplies for survivors — fair prices, no questions."}]
		"herbalist":
			return [{"speaker": "Herbalist", "text": "Roots and leaves keep you breathing out here."}]
		"tool_vendor":
			return [{"speaker": "Tool Vendor", "text": "Wood, stone, and patch kits — everything a builder needs."}]
		_:
			return [{"speaker": "Survivor", "text": "..."}]
