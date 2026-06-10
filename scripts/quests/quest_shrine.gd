class_name QuestShrine
extends InteractableBase

@export var quest_id: String = "find_wolf_crest"
@export var objective_id: String = "reach_shrine"
@export var reward_item_id: String = "wolf_crest"


func _ready() -> void:
	add_to_group("quest_destination")
	super._ready()
	prompt_text = "Inspect Shrine"


func _on_interact(_player: Node) -> void:
	if QuestManager.completed_quests.has(quest_id):
		DialogueManager.start_dialogue("wolf_crest_shrine", [
			{"speaker": "Ancient Shrine", "text": "The crest is gone. Only cold stone remains."},
		])
		return
	QuestManager.advance_objective(quest_id, objective_id)
	if reward_item_id != "":
		InventoryManager.add_item(reward_item_id, 1)
	WaystoneManager.discover("darkpine_forest")
	MapManager.explore_region("darkpine_forest")
	DialogueManager.start_dialogue("wolf_crest_shrine", [
		{"speaker": "Ancient Shrine", "text": "A wolf crest is set into the cracked stone. You pry it free."},
		{"speaker": "Ancient Shrine", "text": "The forest seems to exhale. Something ancient has noticed you."},
	])
