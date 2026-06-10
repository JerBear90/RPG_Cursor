extends Node
## Immediate scene changes (no blocking fade await).

signal transition_started
signal transition_finished

var _changing: bool = false


func change_scene(path: String, spawn_point: String = "") -> void:
	if _changing:
		return
	_changing = true
	transition_started.emit()
	var tree := get_tree()
	if tree == null:
		_changing = false
		push_error("SceneTransitionManager: no scene tree")
		return
	GameManager.clear_players()
	var err := tree.change_scene_to_file(path)
	if err != OK:
		push_error("SceneTransitionManager: failed to load %s (error %d)" % [path, err])
	tree.paused = false
	GameManager.is_paused = false
	_changing = false
	transition_finished.emit()
	if spawn_point != "" and err == OK:
		call_deferred("_apply_spawn", spawn_point)


func _apply_spawn(spawn_id: String) -> void:
	for node in get_tree().get_nodes_in_group("spawn_points"):
		if node.has_method("get_spawn_id") and node.get_spawn_id() == spawn_id:
			for p in GameManager.get_alive_players():
				p.global_position = node.global_position
			return
