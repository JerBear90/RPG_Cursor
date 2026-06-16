class_name DungeonEntrance
extends InteractableBase

@export var entrance_region_id: String = "darkpine_forest"
@export var return_scene_path: String = "res://scenes/levels/darkpine_forest/darkpine_forest.tscn"
@export var co_op_radius: float = 6.0
@export var dungeon_display_name: String = "Abandoned Mine"

var _entering: bool = false
var _pending_confirm: bool = false
var _pending_npc_id: String = ""


func _ready() -> void:
	super._ready()
	prompt_text = "Enter Procedural Dungeon"
	add_to_group("dungeon_entrance")
	if not DialogueManager.dialogue_choice_selected.is_connected(_on_dialogue_choice):
		DialogueManager.dialogue_choice_selected.connect(_on_dialogue_choice)
	if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


const _INTERACT_OPTS := {"from_interact": true}


func _on_interact(_player: Node) -> void:
	if _entering:
		return
	var nearby := GameManager.all_players_near(global_position, co_op_radius)
	if not DungeonManager.can_enter(nearby):
		DialogueManager.start_dialogue("dungeon_blocked", [
			{"speaker": "Ruined Hatch", "text": "Wait for your ally — both exiles must stand at the hatch."},
		], [], _INTERACT_OPTS)
		return
	_pending_confirm = true
	_pending_npc_id = "dungeon_enter"
	DialogueManager.start_dialogue("dungeon_enter", [
		{
			"speaker": "ENTER DUNGEON",
			"text": "%s\n\nEnter this dungeon?" % dungeon_display_name,
		},
	], ["Enter", "Cancel"], {
		"from_interact": true,
		"confirm_label": "Enter",
		"cancel_label": "Cancel",
	})


func _on_dialogue_choice(index: int) -> void:
	var npc_id := _pending_npc_id if _pending_npc_id != "" else DialogueManager.get_current_npc_id()
	if not _pending_confirm or _entering:
		return
	if npc_id != "dungeon_enter":
		return
	_pending_confirm = false
	_pending_npc_id = ""
	if index != 0:
		return
	_entering = true
	WorldStateManager.set_exterior_entrance(
		"exterior_abandoned_mine",
		entrance_region_id,
		global_position + Vector3(0, 0.1, 2.0)
	)
	_enter_sequence()


func _on_dialogue_ended() -> void:
	_pending_confirm = false
	_pending_npc_id = ""


func _enter_sequence() -> void:
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("_fade_to_black"):
			await hud._fade_to_black(0.35)
	DungeonManager.enter_dungeon(entrance_region_id, return_scene_path, global_position)
