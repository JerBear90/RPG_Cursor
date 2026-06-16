extends Node
## Immediate scene changes (no blocking fade await).

signal transition_started
signal transition_finished

var _changing: bool = false

const _SpawnHelpers = preload("res://scripts/utilities/spawn_helpers.gd")
const _SpawnMarker = preload("res://scripts/spawn_point.gd")


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


func reload_scene(path: String) -> void:
	if path == "":
		push_error("SceneTransitionManager: reload_scene called with empty path")
		return
	change_scene(path)


func _apply_spawn(spawn_id: String) -> void:
	var resolved := _resolve_spawn_id(spawn_id)
	for node in get_tree().get_nodes_in_group("spawn_markers"):
		if node.has_method("get_spawn_id") and node.get_spawn_id() == resolved:
			await _place_players_at_marker(node as Node3D)
			return
	for node in get_tree().get_nodes_in_group("spawn_points"):
		if node.has_method("get_spawn_id") and node.get_spawn_id() == resolved:
			if node.has_method("get_facing_yaw"):
				await _place_players_at_marker(node as Node3D)

			else:
				for p in GameManager.get_alive_players():
					if p is CharacterBody3D:
						await _SpawnHelpers.place_player_on_ground(p as CharacterBody3D, node.global_position, get_tree())
			return


func _resolve_spawn_id(spawn_id: String) -> String:
	if spawn_id == "waystone_spawn":
		var dest := WorldStateManager.consume_fast_travel_destination()
		if dest != &"":
			return "waystone_%s" % dest
		return "waystone_%s" % GameManager.current_region_id
	return spawn_id


func _place_players_at_marker(marker: Node3D) -> void:
	await _SpawnHelpers.place_party_at_marker(get_tree(), marker)
	GameManager.death_input_locked = false
	GameManager.refresh_coop_camera()
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("_fade_from_black"):
			await hud._fade_from_black(0.35)
			break
