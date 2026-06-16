class_name BlightspireCathedralEntrance
extends InteractableBase
## Blightspire Cathedral exterior entrance.

@export var exterior_marker_id: String = "exterior_blightspire_cathedral"
@export var entrance_region_id: String = "blightreach"
@export var return_scene_path: String = "res://scenes/levels/blightreach/blightreach.tscn"

var _pending_confirm: bool = false
var _entering: bool = false


func _ready() -> void:
	super._ready()
	prompt_text = "Blightspire Cathedral"
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
		DialogueManager.start_dialogue("cathedral_locked", [
			{"speaker": "Cathedral Gate", "text": "Living roots seal the cathedral doors. Complete The Fallen Abbey and recover the Blightspire seal."},
		], [], {"from_interact": true})
		return
	_pending_confirm = true
	DialogueManager.start_dialogue("cathedral_enter", [
		{"speaker": "Blightspire Cathedral", "text": "Roots choke the broken spires. Fungal light pulses from the nave depths.\n\nEnter Blightspire Cathedral?"},
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
	if QuestManager.active_quests.has("heart_of_the_blight"):
		QuestManager.advance_objective("heart_of_the_blight", "enter_cathedral", 1)
	DungeonManager.enter_cathedral(entrance_region_id, return_scene_path, global_position)
	_entering = false


func _is_unlocked() -> bool:
	return InventoryManager.has_item("blightspire_seal") \
		or "the_fallen_abbey" in QuestManager.completed_quests
