class_name BellPuzzle
extends InteractableBase
## Three-bell sequence puzzle — order: left, center, right (1-2-3).

signal puzzle_completed

const CORRECT_ORDER := [1, 2, 3]

@export var gate_node_path: NodePath

var _sequence: Array[int] = []
var _completed: bool = false


func _ready() -> void:
	super._ready()
	prompt_text = "Ring bell"
	add_to_group("bell_puzzle")
	if ReliquaryState.puzzle_completed:
		_completed = true
		_open_gate()


func _on_interact(_player: Node) -> void:
	if _completed or ReliquaryState.puzzle_completed:
		DialogueManager.start_dialogue("bell_done", [
			{"speaker": "Bell Chamber", "text": "The reliquary gate stands open."},
		], [], {"from_interact": true})
		return
	_show_bell_menu()


func _show_bell_menu() -> void:
	DialogueManager.start_dialogue("bell_puzzle", [
		{"speaker": "Ancient Bells", "text": "Three bells hang over the flooded hall. Ring them in the order the carvings suggest: left, then center, then right."},
	], ["Left bell", "Center bell", "Right bell", "Cancel"], {"from_interact": true})


func ring_bell(index: int) -> void:
	if _completed:
		return
	_sequence.append(index)
	AudioManager.play_sfx("footstep")
	var step := _sequence.size()
	if step > CORRECT_ORDER.size() or _sequence[step - 1] != CORRECT_ORDER[step - 1]:
		_sequence.clear()
		DialogueManager.start_dialogue("bell_wrong", [
			{"speaker": "Ancient Bells", "text": "The bells clash discordantly. The sequence resets."},
		], [], {"from_interact": false})
		return
	if step >= CORRECT_ORDER.size():
		_complete_puzzle()


func _complete_puzzle() -> void:
	_completed = true
	ReliquaryState.puzzle_completed = true
	ReliquaryState.save_state()
	puzzle_completed.emit()
	_open_gate()
	if QuestManager.active_quests.has("depths_of_reliquary"):
		QuestManager.advance_objective("depths_of_reliquary", "solve_bells", 1)
	DialogueManager.start_dialogue("bell_success", [
		{"speaker": "Ancient Bells", "text": "The bells toll in harmony. A sealed gate grinds open."},
	], [], {"from_interact": false})


func _open_gate() -> void:
	var gate := get_node_or_null(gate_node_path)
	if gate and is_instance_valid(gate):
		gate.queue_free()
