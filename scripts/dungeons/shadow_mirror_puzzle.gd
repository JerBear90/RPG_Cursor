class_name ShadowMirrorPuzzle
extends Node3D
## Align three shadow wards to open the sanctum spire.

signal puzzle_completed
signal ward_activated(id: String)

@export var gate_node_path: NodePath

var _completed: bool = false
var _switches: Array[ShadowMirrorSwitch] = []


func _ready() -> void:
	if EclipseSanctumState.puzzle_completed:
		_completed = true
		_open_spire_gate()
		_apply_all_ward_effects()
	call_deferred("_refresh_switches")


func _refresh_switches() -> void:
	_switches.clear()
	for node in get_tree().get_nodes_in_group("shadow_mirror_switch"):
		if node is ShadowMirrorSwitch:
			_switches.append(node)


func toggle_ward(id: String) -> void:
	if _completed or EclipseSanctumState.puzzle_completed:
		return
	if _ward_active(id):
		return
	match id:
		"ward_a":
			EclipseSanctumState.ward_a = true
		"ward_b":
			EclipseSanctumState.ward_b = true
		"ward_c":
			EclipseSanctumState.ward_c = true
	_on_ward_activated(id)
	_refresh_switch_visuals(id)
	EclipseSanctumState.save_state()
	if EclipseSanctumState.ward_a and EclipseSanctumState.ward_b and EclipseSanctumState.ward_c:
		_complete_puzzle()
	else:
		var done := 0
		if EclipseSanctumState.ward_a: done += 1
		if EclipseSanctumState.ward_b: done += 1
		if EclipseSanctumState.ward_c: done += 1
		DialogueManager.start_dialogue("eclipse_ward", [
			{"speaker": "Shadow Wards", "text": "Ward light flickers (%d/3 active). Align all three wards to open the spire." % done},
		], [], {"from_interact": false})


func activate_ward(id: String) -> void:
	if not _ward_active(id):
		toggle_ward(id)


func _on_ward_activated(id: String) -> void:
	AudioManager.play_sfx("ward_activation")
	await get_tree().create_timer(0.15).timeout
	AudioManager.play_sfx("purification_wave")
	ward_activated.emit(id)
	match id:
		"ward_a":
			_effect_ward_a()
		"ward_b":
			_effect_ward_b()
		"ward_c":
			_effect_ward_c()
	if QuestManager.active_quests.has("throne_beneath_the_eclipse"):
		MapManager.map_updated.emit(GameManager.current_region_id)


func _effect_ward_a() -> void:
	for node in get_tree().get_nodes_in_group("eclipse_shadow_barrier_a"):
		if is_instance_valid(node):
			node.queue_free()
	_add_ward_light(global_position + Vector3(-8, 1.5, 0), Color(0.45, 0.55, 0.95))


func _effect_ward_b() -> void:
	for node in get_tree().get_nodes_in_group("eclipse_shadow_barrier_b"):
		if is_instance_valid(node):
			node.queue_free()
	_add_ward_light(global_position + Vector3(0, 1.5, 6), Color(0.55, 0.45, 0.88))


func _effect_ward_c() -> void:
	_open_spire_gate()
	_add_ward_light(global_position + Vector3(8, 1.5, 0), Color(0.38, 0.48, 0.92))


func _apply_all_ward_effects() -> void:
	if EclipseSanctumState.ward_a:
		for node in get_tree().get_nodes_in_group("eclipse_shadow_barrier_a"):
			if is_instance_valid(node):
				node.queue_free()
	if EclipseSanctumState.ward_b:
		for node in get_tree().get_nodes_in_group("eclipse_shadow_barrier_b"):
			if is_instance_valid(node):
				node.queue_free()
	if EclipseSanctumState.ward_c:
		_open_spire_gate()


func _add_ward_light(pos: Vector3, color: Color) -> void:
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 1.1
	light.omni_range = 12.0
	light.position = pos
	get_tree().current_scene.add_child(light)
	var tween := light.create_tween()
	tween.tween_property(light, "light_energy", 0.0, 4.5)


func _ward_active(id: String) -> bool:
	match id:
		"ward_a": return EclipseSanctumState.ward_a
		"ward_b": return EclipseSanctumState.ward_b
		"ward_c": return EclipseSanctumState.ward_c
	return false


func _refresh_switch_visuals(_id: String) -> void:
	for sw in _switches:
		if sw.has_method("_sync_visual"):
			sw._sync_visual()


func _complete_puzzle() -> void:
	_completed = true
	EclipseSanctumState.puzzle_completed = true
	EclipseSanctumState.wards_active = true
	EclipseSanctumState.save_state()
	if QuestManager.active_quests.has("throne_beneath_the_eclipse"):
		QuestManager.advance_objective("throne_beneath_the_eclipse", "align_shadow_mirrors", 1)
	puzzle_completed.emit()
	_open_spire_gate()
	_apply_all_ward_effects()
	AudioManager.play_sfx("purification_wave")
	DialogueManager.start_dialogue("eclipse_ward_done", [
		{"speaker": "Shadow Wards", "text": "Ward light steadies the sanctum channels. The sealed throne awaits beyond the ascent."},
	], [], {"from_interact": false})
	for node in get_tree().get_nodes_in_group("eclipse_builder"):
		if node.has_method("unlock_throne_approach"):
			node.unlock_throne_approach()


func _open_spire_gate() -> void:
	var gate := get_node_or_null(gate_node_path)
	if gate and is_instance_valid(gate):
		gate.queue_free()
		return
	for node in get_tree().get_nodes_in_group("central_spire_shadow_gate"):
		if is_instance_valid(node):
			node.queue_free()
