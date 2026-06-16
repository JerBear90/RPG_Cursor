class_name QuestPoi
extends InteractableBase
## Quest objective interactables (caravan, shrines, ledgers).

@export var poi_id: String = ""
@export var quest_id: String = ""
@export var objective_id: String = ""
@export var prompt_override: String = "Inspect"
@export var speaker: String = "Scene"
@export_multiline var inspect_text: String = "Nothing of note."

var _used: bool = false


func _ready() -> void:
	super._ready()
	if prompt_override != "":
		prompt_text = prompt_override
	add_to_group("quest_poi")
	if poi_id != "":
		add_to_group("poi_%s" % poi_id)


func _on_interact(_player: Node) -> void:
	if _used and objective_id != "inspect_shrine":
		return
	DialogueManager.start_dialogue(poi_id if poi_id != "" else name, [
		{"speaker": speaker, "text": inspect_text},
	], [], {"from_interact": true})
	if quest_id != "" and objective_id != "" and QuestManager.active_quests.has(quest_id):
		QuestManager.advance_objective(quest_id, objective_id, 1)
		if objective_id != "inspect_shrine":
			_used = true
		if objective_id == "recover_ledger" and not InventoryManager.has_item("caravan_ledger"):
			InventoryManager.add_item("caravan_ledger", 1)
