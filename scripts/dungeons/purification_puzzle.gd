class_name PurificationPuzzle
extends Node3D
## Light three purification braziers — each cleanses part of the cathedral.

signal puzzle_completed
signal brazier_activated(id: String)

@export var gate_node_path: NodePath

var _completed: bool = false
var _switches: Array[PurificationBrazierSwitch] = []


func _ready() -> void:
	if CathedralState.puzzle_completed:
		_completed = true
		_open_nave_gate()
		_apply_all_brazier_effects()
	call_deferred("_refresh_switches")


func _refresh_switches() -> void:
	_switches.clear()
	for node in get_tree().get_nodes_in_group("purification_brazier_switch"):
		if node is PurificationBrazierSwitch:
			_switches.append(node)


func toggle_brazier(id: String) -> void:
	if _completed or CathedralState.puzzle_completed:
		return
	if _brazier_lit(id):
		return
	match id:
		"brazier_a":
			CathedralState.brazier_a = true
		"brazier_b":
			CathedralState.brazier_b = true
		"brazier_c":
			CathedralState.brazier_c = true
	_on_brazier_lit(id)
	_refresh_switch_visuals(id)
	CathedralState.save_state()
	if CathedralState.brazier_a and CathedralState.brazier_b and CathedralState.brazier_c:
		_complete_puzzle()
	else:
		var done := 0
		if CathedralState.brazier_a: done += 1
		if CathedralState.brazier_b: done += 1
		if CathedralState.brazier_c: done += 1
		DialogueManager.start_dialogue("cathedral_brazier", [
			{"speaker": "Purification Braziers", "text": "Sacred flame flickers (%d/3 lit). Kindle all three braziers to purify the cathedral." % done},
		], [], {"from_interact": false})


func activate_brazier(id: String) -> void:
	if not _brazier_lit(id):
		toggle_brazier(id)


func _on_brazier_lit(id: String) -> void:
	AudioManager.play_sfx("purification_ignite")
	await get_tree().create_timer(0.15).timeout
	AudioManager.play_sfx("purification_wave")
	brazier_activated.emit(id)
	match id:
		"brazier_a":
			_effect_brazier_a()
		"brazier_b":
			_effect_brazier_b()
		"brazier_c":
			_effect_brazier_c()
	if QuestManager.active_quests.has("heart_of_the_blight"):
		MapManager.map_updated.emit(GameManager.current_region_id)


func _effect_brazier_a() -> void:
	for node in get_tree().get_nodes_in_group("cathedral_root_barrier_a"):
		if is_instance_valid(node):
			node.queue_free()
	_add_cleansing_light(global_position + Vector3(-8, 1.5, 0), Color(0.95, 0.72, 0.35))
	if _should_show_brazier_dialogue():
		DialogueManager.start_dialogue("cathedral_brazier_a", [
			{"speaker": "Purification Braziers", "text": "Amber fire washes the entrance nave. Nearby fungal corruption shrivels and a root barrier retracts."},
		], [], {"from_interact": false})


func _effect_brazier_b() -> void:
	for node in get_tree().get_nodes_in_group("cathedral_root_barrier_b"):
		if is_instance_valid(node):
			node.queue_free()
	for node in get_tree().get_nodes_in_group("cathedral_spore_vent"):
		if node.has_method("disable_vent"):
			node.disable_vent()
	_add_cleansing_light(global_position + Vector3(0, 1.5, 6), Color(0.88, 0.55, 0.95))
	if _should_show_brazier_dialogue():
		DialogueManager.start_dialogue("cathedral_brazier_b", [
			{"speaker": "Purification Braziers", "text": "Purifying flame cleanses the cloister vents. Spore clouds dissipate as roots pull back."},
		], [], {"from_interact": false})


func _effect_brazier_c() -> void:
	for node in get_tree().get_nodes_in_group("cathedral_bell_pulse"):
		if node.has_method("disable_pulse"):
			node.disable_pulse()
	_open_nave_gate()
	_add_cleansing_light(global_position + Vector3(8, 1.5, 0), Color(0.45, 0.88, 0.42))
	if _should_show_brazier_dialogue():
		DialogueManager.start_dialogue("cathedral_brazier_c", [
			{"speaker": "Purification Braziers", "text": "The corrupted bell falls silent. The Central Nave gate unlocks as violet-green fire cleanses the cathedral heart."},
		], [], {"from_interact": false})


func _should_show_brazier_dialogue() -> bool:
	var done := 0
	if CathedralState.brazier_a: done += 1
	if CathedralState.brazier_b: done += 1
	if CathedralState.brazier_c: done += 1
	return done < 3


func _apply_all_brazier_effects() -> void:
	if CathedralState.brazier_a:
		for node in get_tree().get_nodes_in_group("cathedral_root_barrier_a"):
			if is_instance_valid(node):
				node.queue_free()
	if CathedralState.brazier_b:
		for node in get_tree().get_nodes_in_group("cathedral_root_barrier_b"):
			if is_instance_valid(node):
				node.queue_free()
		for node in get_tree().get_nodes_in_group("cathedral_spore_vent"):
			if node.has_method("disable_vent"):
				node.disable_vent()
	if CathedralState.brazier_c:
		for node in get_tree().get_nodes_in_group("cathedral_bell_pulse"):
			if node.has_method("disable_pulse"):
				node.disable_pulse()
		_open_nave_gate()


func _add_cleansing_light(pos: Vector3, color: Color) -> void:
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 1.1
	light.omni_range = 12.0
	light.position = pos
	get_tree().current_scene.add_child(light)
	var tween := light.create_tween()
	tween.tween_property(light, "light_energy", 0.0, 4.5)


func _brazier_lit(id: String) -> bool:
	match id:
		"brazier_a": return CathedralState.brazier_a
		"brazier_b": return CathedralState.brazier_b
		"brazier_c": return CathedralState.brazier_c
	return false


func _refresh_switch_visuals(_id: String) -> void:
	for sw in _switches:
		if sw.has_method("_sync_visual"):
			sw._sync_visual()


func _complete_puzzle() -> void:
	_completed = true
	CathedralState.puzzle_completed = true
	CathedralState.retracted_roots = true
	CathedralState.save_state()
	if QuestManager.active_quests.has("heart_of_the_blight"):
		QuestManager.advance_objective("heart_of_the_blight", "purify_roots", 1)
	puzzle_completed.emit()
	_open_nave_gate()
	_apply_all_brazier_effects()
	AudioManager.play_sfx("purification_wave")
	DialogueManager.start_dialogue("cathedral_brazier_done", [
		{"speaker": "Purification Braziers", "text": "Violet-green fire washes the chamber. Living roots shrivel back — the Heart Chamber awaits beyond the choir."},
	], [], {"from_interact": false})


func _open_nave_gate() -> void:
	var gate := get_node_or_null(gate_node_path)
	if gate and is_instance_valid(gate):
		gate.queue_free()
		return
	for node in get_tree().get_nodes_in_group("central_nave_root_gate"):
		if is_instance_valid(node):
			node.queue_free()
