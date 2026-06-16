class_name EclipseSanctumEntrance
extends InteractableBase
## Eclipse Sanctum exterior entrance.

@export var exterior_marker_id: String = "exterior_eclipse_sanctum"
@export var entrance_region_id: String = "sunless_dominion"
@export var return_scene_path: String = "res://scenes/levels/sunless_dominion/sunless_dominion.tscn"

var _pending_confirm: bool = false
var _entering: bool = false


func _ready() -> void:
	super._ready()
	prompt_text = "Eclipse Sanctum"
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
		DialogueManager.start_dialogue("eclipse_sanctum_locked", [
			{"speaker": "Sanctum Gate", "text": "Umbral seals bar the sanctum. Complete The Dark Observatory and recover the eclipse shard."},
		], [], {"from_interact": true})
		return
	_pending_confirm = true
	DialogueManager.start_dialogue("eclipse_sanctum_enter", [
		{"speaker": "Eclipse Sanctum", "text": "Shadow fog coils above buried wards and moon-scored stone.\n\nEnter Eclipse Sanctum?"},
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
	if QuestManager.active_quests.has("throne_beneath_the_eclipse"):
		QuestManager.advance_objective("throne_beneath_the_eclipse", "enter_sanctum", 1)
	DungeonManager.enter_eclipse_sanctum(entrance_region_id, return_scene_path, global_position)
	_entering = false


func _is_unlocked() -> bool:
	return InventoryManager.has_item("eclipse_shard") \
		or "the_dark_observatory" in QuestManager.completed_quests \
		or "throne_beneath_the_eclipse" in QuestManager.active_quests
