class_name MirrorPuzzle
extends Node3D
## Align three solar mirrors to cool the ziggurat channels.

signal puzzle_completed
signal mirror_activated(id: String)

@export var gate_node_path: NodePath

var _completed: bool = false
var _switches: Array[MirrorSwitch] = []


func _ready() -> void:
	if PyreheartState.puzzle_completed:
		_completed = true
		_open_ziggurat_gate()
		_apply_all_mirror_effects()
	call_deferred("_refresh_switches")


func _refresh_switches() -> void:
	_switches.clear()
	for node in get_tree().get_nodes_in_group("mirror_switch"):
		if node is MirrorSwitch:
			_switches.append(node)


func toggle_mirror(id: String) -> void:
	if _completed or PyreheartState.puzzle_completed:
		return
	if _mirror_aligned(id):
		return
	match id:
		"mirror_a":
			PyreheartState.mirror_a = true
		"mirror_b":
			PyreheartState.mirror_b = true
		"mirror_c":
			PyreheartState.mirror_c = true
	_on_mirror_aligned(id)
	_refresh_switch_visuals(id)
	PyreheartState.save_state()
	if PyreheartState.mirror_a and PyreheartState.mirror_b and PyreheartState.mirror_c:
		_complete_puzzle()
	else:
		var done := 0
		if PyreheartState.mirror_a: done += 1
		if PyreheartState.mirror_b: done += 1
		if PyreheartState.mirror_c: done += 1
		DialogueManager.start_dialogue("pyreheart_mirror", [
			{"speaker": "Solar Mirrors", "text": "Reflected sunlight flickers (%d/3 aligned). Align all three mirrors to cool the channels." % done},
		], [], {"from_interact": false})


func activate_mirror(id: String) -> void:
	if not _mirror_aligned(id):
		toggle_mirror(id)


func _on_mirror_aligned(id: String) -> void:
	AudioManager.play_sfx("seal_activate")
	await get_tree().create_timer(0.15).timeout
	AudioManager.play_sfx("purification_wave")
	mirror_activated.emit(id)
	match id:
		"mirror_a":
			_effect_mirror_a()
		"mirror_b":
			_effect_mirror_b()
		"mirror_c":
			_effect_mirror_c()
	if QuestManager.active_quests.has("heart_of_the_wastes"):
		MapManager.map_updated.emit(GameManager.current_region_id)


func _effect_mirror_a() -> void:
	for node in get_tree().get_nodes_in_group("pyreheart_sand_barrier_a"):
		if is_instance_valid(node):
			node.queue_free()
	_add_cooling_light(global_position + Vector3(-8, 1.5, 0), Color(0.95, 0.72, 0.35))


func _effect_mirror_b() -> void:
	for node in get_tree().get_nodes_in_group("pyreheart_heat_vent"):
		if node.has_method("disable_vent"):
			node.disable_vent()
	for node in get_tree().get_nodes_in_group("pyreheart_sand_barrier_b"):
		if is_instance_valid(node):
			node.queue_free()
	_add_cooling_light(global_position + Vector3(0, 1.5, 6), Color(0.88, 0.55, 0.45))


func _effect_mirror_c() -> void:
	for node in get_tree().get_nodes_in_group("pyreheart_glass_pulse"):
		if node.has_method("disable_pulse"):
			node.disable_pulse()
	_open_ziggurat_gate()
	_add_cooling_light(global_position + Vector3(8, 1.5, 0), Color(0.95, 0.55, 0.28))


func _apply_all_mirror_effects() -> void:
	if PyreheartState.mirror_a:
		for node in get_tree().get_nodes_in_group("pyreheart_sand_barrier_a"):
			if is_instance_valid(node):
				node.queue_free()
	if PyreheartState.mirror_b:
		for node in get_tree().get_nodes_in_group("pyreheart_sand_barrier_b"):
			if is_instance_valid(node):
				node.queue_free()
		for node in get_tree().get_nodes_in_group("pyreheart_heat_vent"):
			if node.has_method("disable_vent"):
				node.disable_vent()
	if PyreheartState.mirror_c:
		for node in get_tree().get_nodes_in_group("pyreheart_glass_pulse"):
			if node.has_method("disable_pulse"):
				node.disable_pulse()
		_open_ziggurat_gate()


func _add_cooling_light(pos: Vector3, color: Color) -> void:
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 1.1
	light.omni_range = 12.0
	light.position = pos
	get_tree().current_scene.add_child(light)
	var tween := light.create_tween()
	tween.tween_property(light, "light_energy", 0.0, 4.5)


func _mirror_aligned(id: String) -> bool:
	match id:
		"mirror_a": return PyreheartState.mirror_a
		"mirror_b": return PyreheartState.mirror_b
		"mirror_c": return PyreheartState.mirror_c
	return false


func _refresh_switch_visuals(_id: String) -> void:
	for sw in _switches:
		if sw.has_method("_sync_visual"):
			sw._sync_visual()


func _complete_puzzle() -> void:
	_completed = true
	PyreheartState.puzzle_completed = true
	PyreheartState.cooling_channels_active = true
	PyreheartState.save_state()
	if QuestManager.active_quests.has("heart_of_the_wastes"):
		QuestManager.advance_objective("heart_of_the_wastes", "align_mirrors", 1)
	puzzle_completed.emit()
	_open_ziggurat_gate()
	_apply_all_mirror_effects()
	AudioManager.play_sfx("purification_wave")
	DialogueManager.start_dialogue("pyreheart_mirror_done", [
		{"speaker": "Solar Mirrors", "text": "Reflected sunlight cools the buried channels. The Sealed Solar Heart awaits beyond the ascent."},
	], [], {"from_interact": false})
	for node in get_tree().get_nodes_in_group("pyreheart_builder"):
		if node.has_method("unlock_solar_heart_chamber"):
			node.unlock_solar_heart_chamber()


func _open_ziggurat_gate() -> void:
	var gate := get_node_or_null(gate_node_path)
	if gate and is_instance_valid(gate):
		gate.queue_free()
		return
	for node in get_tree().get_nodes_in_group("central_ziggurat_sand_gate"):
		if is_instance_valid(node):
			node.queue_free()
