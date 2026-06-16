class_name BurialSealPuzzle
extends Node3D
## Restore four burial seals to unlock the throne antechamber.

signal puzzle_completed

@export var gate_node_path: NodePath

var _completed: bool = false


func _ready() -> void:
	if CryptState.puzzle_completed:
		_completed = true
		_open_gate()


func activate_seal(id: String) -> void:
	if _completed or CryptState.puzzle_completed:
		return
	match id:
		"north":
			CryptState.seal_north = true
		"south":
			CryptState.seal_south = true
		"east":
			CryptState.seal_east = true
		"west":
			CryptState.seal_west = true
	AudioManager.play_sfx("seal_activate")
	if CryptState.seal_north and CryptState.seal_south and CryptState.seal_east and CryptState.seal_west:
		_complete_puzzle()
	else:
		var done := 0
		if CryptState.seal_north: done += 1
		if CryptState.seal_south: done += 1
		if CryptState.seal_east: done += 1
		if CryptState.seal_west: done += 1
		DialogueManager.start_dialogue("crypt_seal", [
			{"speaker": "Burial Seals", "text": "Seal engaged (%d/4). Restore all four burial seals." % done},
		], [], {"from_interact": false})


func _complete_puzzle() -> void:
	_completed = true
	CryptState.puzzle_completed = true
	CryptState.save_state()
	puzzle_completed.emit()
	_open_gate()
	if QuestManager.active_quests.has("the_pale_heart"):
		QuestManager.advance_objective("the_pale_heart", "restore_seals", 1)
	DialogueManager.start_dialogue("crypt_seal_done", [
		{"speaker": "Burial Seals", "text": "Frost sigils flare across the crypt. The sealed gate to the throne antechamber crumbles."},
	], [], {"from_interact": false})


func _open_gate() -> void:
	var gate := get_node_or_null(gate_node_path)
	if gate and is_instance_valid(gate):
		gate.queue_free()
