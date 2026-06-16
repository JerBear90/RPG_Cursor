class_name DungeonExitPortal
extends InteractableBase

var _active: bool = false
var _exiting: bool = false
var _pending_exit: bool = false


func _ready() -> void:
	super._ready()
	prompt_text = "Leave Dungeon"
	visible = false
	set_process(false)
	for child in get_children():
		if child is CollisionShape3D:
			child.disabled = true
		if child is Area3D:
			child.monitoring = false
	if not DialogueManager.dialogue_choice_selected.is_connected(_on_dialogue_choice):
		DialogueManager.dialogue_choice_selected.connect(_on_dialogue_choice)
	if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


func reveal() -> void:
	_active = true
	visible = true
	for child in get_children():
		if child is CollisionShape3D:
			child.disabled = false
		if child is Area3D:
			child.monitoring = true


func _on_interact(_player: Node) -> void:
	if not _active or not DungeonManager.boss_defeated or _exiting:
		return
	_pending_exit = true
	DialogueManager.start_dialogue("dungeon_exit", [
		{
			"speaker": "EXIT DUNGEON",
			"text": "Return to the surface?",
		},
	], ["Exit", "Stay"], {
		"from_interact": true,
		"confirm_label": "Exit",
		"cancel_label": "Stay",
	})


func _on_dialogue_choice(index: int) -> void:
	if not _pending_exit or _exiting or not _active:
		return
	_pending_exit = false
	if index != 0:
		return
	_exiting = true
	_exit_sequence()


func _on_dialogue_ended() -> void:
	_pending_exit = false


func _exit_sequence() -> void:
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("_fade_to_black"):
			await hud._fade_to_black(0.35)
	if QuestManager.active_quests.has("the_sunken_crown"):
		QuestManager.advance_objective("the_sunken_crown", "exit_citadel", 1)
	if QuestManager.active_quests.has("heart_of_the_blight"):
		QuestManager.advance_objective("heart_of_the_blight", "exit_blightspire", 1)
	if QuestManager.active_quests.has("heart_of_the_wastes"):
		QuestManager.advance_objective("heart_of_the_wastes", "exit_pyreheart_ziggurat", 1)
	DungeonManager.exit_dungeon()
