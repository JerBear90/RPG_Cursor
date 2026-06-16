class_name PaleheartEntrance
extends InteractableBase
## Paleheart Crypt exterior entrance.

@export var required_quest_id: String = "gravewind_rising"
@export var required_item_id: String = "paleheart_access_key"
@export var exterior_marker_id: String = "exterior_paleheart_crypt"
@export var entrance_region_id: String = "frostgrave_expanse"
@export var return_scene_path: String = "res://scenes/levels/frostgrave_expanse/frostgrave_expanse.tscn"

var _pending_confirm: bool = false
var _entering: bool = false


func _ready() -> void:
	super._ready()
	prompt_text = "Paleheart Crypt"
	add_to_group("dungeon_entrance")
	add_to_group("map_dungeon")
	if not DialogueManager.dialogue_choice_selected.is_connected(_on_dialogue_choice):
		DialogueManager.dialogue_choice_selected.connect(_on_dialogue_choice)
	if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


func _on_interact(_player: Node) -> void:
	if _entering:
		return
	if not _is_unlocked():
		DialogueManager.start_dialogue("crypt_locked", [
			{"speaker": "Crypt Gate", "text": "The crypt doors are sealed in black ice. Complete Gravewind Rising and recover the Paleheart access key."},
		], [], {"from_interact": true})
		return
	_pending_confirm = true
	DialogueManager.start_dialogue("crypt_enter", [
		{"speaker": "Paleheart Crypt", "text": "Gravewind moans from the crypt depths.\n\nEnter Paleheart Crypt?"},
	], ["Enter", "Cancel"], {"from_interact": true, "confirm_label": "Enter", "cancel_label": "Cancel"})


func _on_dialogue_choice(index: int) -> void:
	if not _pending_confirm or _entering:
		return
	_pending_confirm = false
	if index != 0:
		return
	_entering = true
	WorldStateManager.set_exterior_entrance(
		exterior_marker_id,
		entrance_region_id,
		global_position + Vector3(0, 0.1, 2.0)
	)
	_enter_sequence()


func _on_dialogue_ended() -> void:
	_pending_confirm = false


func _enter_sequence() -> void:
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("_fade_to_black"):
			await hud._fade_to_black(0.35)
	if QuestManager.active_quests.has("gravewind_rising"):
		QuestManager.advance_objective("gravewind_rising", "recover_seals", 1)
	if QuestManager.active_quests.has("the_pale_heart"):
		QuestManager.advance_objective("the_pale_heart", "enter_crypt", 1)
	DungeonManager.enter_crypt(entrance_region_id, return_scene_path, global_position)
	_entering = false


func _is_unlocked() -> bool:
	if required_quest_id in QuestManager.completed_quests:
		return true
	if InventoryManager.has_item(required_item_id):
		return true
	if QuestManager.active_quests.has(required_quest_id) and InventoryManager.has_item(required_item_id):
		return true
	return InventoryManager.has_item(required_item_id)
