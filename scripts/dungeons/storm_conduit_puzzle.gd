class_name StormConduitPuzzle

extends Node3D

## Restore three storm conduits to unlock the sovereign antechamber.



signal puzzle_completed



@export var gate_node_path: NodePath



var _completed: bool = false

var _switches: Array[StormConduitSwitch] = []





func _ready() -> void:

	if CitadelState.puzzle_completed:

		_completed = true

		_open_gate()

	call_deferred("_refresh_switches")





func _refresh_switches() -> void:

	_switches.clear()

	for node in get_tree().get_nodes_in_group("storm_conduit_switch"):

		if node is StormConduitSwitch:

			_switches.append(node)





func toggle_conduit(id: String) -> void:

	if _completed or CitadelState.puzzle_completed:

		return

	match id:

		"conduit_a":

			CitadelState.conduit_a = not CitadelState.conduit_a

		"conduit_b":

			CitadelState.conduit_b = not CitadelState.conduit_b

		"conduit_c":

			CitadelState.conduit_c = not CitadelState.conduit_c

	AudioManager.play_sfx("conduit_hum" if _conduit_active(id) else "seal_activate")

	_refresh_switch_visuals(id)

	if CitadelState.conduit_a and CitadelState.conduit_b and CitadelState.conduit_c:

		_complete_puzzle()

	else:

		var done := 0

		if CitadelState.conduit_a: done += 1

		if CitadelState.conduit_b: done += 1

		if CitadelState.conduit_c: done += 1

		DialogueManager.start_dialogue("citadel_conduit", [

			{"speaker": "Storm Conduits", "text": "Conduit state updated (%d/3 powered). Route power through all three conduits." % done},

		], [], {"from_interact": false})





func activate_conduit(id: String) -> void:

	if not _conduit_active(id):

		toggle_conduit(id)





func _conduit_active(id: String) -> bool:

	match id:

		"conduit_a": return CitadelState.conduit_a

		"conduit_b": return CitadelState.conduit_b

		"conduit_c": return CitadelState.conduit_c

	return false





func _refresh_switch_visuals(_id: String) -> void:

	for sw in _switches:

		if sw.has_method("_sync_visual"):

			sw._sync_visual()





func _complete_puzzle() -> void:

	_completed = true

	CitadelState.puzzle_completed = true

	CitadelState.save_state()

	puzzle_completed.emit()

	_open_gate()

	AudioManager.play_sfx("seal_activate")

	if QuestManager.active_quests.has("the_sunken_crown"):

		QuestManager.advance_objective("the_sunken_crown", "stabilize_conduits", 1)

	DialogueManager.start_dialogue("citadel_conduit_done", [

		{"speaker": "Storm Conduits", "text": "Lightning arcs across the flooded halls. The sealed gate to the sovereign antechamber collapses."},

	], [], {"from_interact": false})





func _open_gate() -> void:

	var gate := get_node_or_null(gate_node_path)

	if gate and is_instance_valid(gate):

		gate.queue_free()

