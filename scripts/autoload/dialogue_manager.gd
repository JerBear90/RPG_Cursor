extends Node
## Dialogue presentation and NPC conversation flow.

signal dialogue_started(npc_id: String)
signal dialogue_line_shown(speaker: String, text: String)
signal dialogue_ended

var _active: bool = false
var _lines: Array[Dictionary] = []
var _index: int = 0


func start_dialogue(npc_id: String, lines: Array[Dictionary]) -> void:
	if _active:
		return
	_active = true
	_lines = lines
	_index = 0
	dialogue_started.emit(npc_id)
	_show_current()


func advance() -> void:
	if not _active:
		return
	_index += 1
	if _index >= _lines.size():
		end_dialogue()
	else:
		_show_current()


func end_dialogue() -> void:
	_active = false
	_lines.clear()
	_index = 0
	dialogue_ended.emit()


func is_active() -> bool:
	return _active


func _show_current() -> void:
	if _index < _lines.size():
		var line := _lines[_index]
		dialogue_line_shown.emit(line.get("speaker", ""), line.get("text", ""))


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
		_:
			return [{"speaker": "Survivor", "text": "..."}]
