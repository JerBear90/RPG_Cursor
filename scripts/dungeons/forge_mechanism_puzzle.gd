class_name ForgeMechanismPuzzle
extends Node3D
## Restore vent, rail, and furnace regulators to unlock core access.

signal puzzle_completed

@export var gate_node_path: NodePath

var _completed: bool = false


func _ready() -> void:
	if FoundryState.puzzle_completed:
		_completed = true
		_open_gate()


func activate_mechanism(id: String) -> void:
	if _completed or FoundryState.puzzle_completed:
		return
	match id:
		"vent":
			FoundryState.vent_active = true
		"rail":
			FoundryState.rail_active = true
		"furnace":
			FoundryState.furnace_active = true
	AudioManager.play_sfx("footstep")
	if FoundryState.vent_active and FoundryState.rail_active and FoundryState.furnace_active:
		_complete_puzzle()
	else:
		var done := 0
		if FoundryState.vent_active: done += 1
		if FoundryState.rail_active: done += 1
		if FoundryState.furnace_active: done += 1
		DialogueManager.start_dialogue("foundry_mechanism", [
			{"speaker": "Forge Systems", "text": "Mechanism engaged (%d/3). Restore all three regulators." % done},
		], [], {"from_interact": false})


func _complete_puzzle() -> void:
	_completed = true
	FoundryState.puzzle_completed = true
	FoundryState.save_state()
	puzzle_completed.emit()
	_open_gate()
	if QuestManager.active_quests.has("heart_of_blackvein"):
		QuestManager.advance_objective("heart_of_blackvein", "restore_mechanisms", 1)
	DialogueManager.start_dialogue("foundry_mechanism_done", [
		{"speaker": "Forge Systems", "text": "Power surges through the foundry. Molten flow redirects — the core access gate opens."},
	], [], {"from_interact": false})


func _open_gate() -> void:
	var gate := get_node_or_null(gate_node_path)
	if gate and is_instance_valid(gate):
		gate.queue_free()
