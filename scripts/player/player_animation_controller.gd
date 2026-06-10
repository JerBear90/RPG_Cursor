extends Node
## Procedural AnimationPlayer + AnimationTree state machine for the player mesh.

signal anim_state_changed(state: String)

const STATE_IDLE := "idle"
const STATE_MOVE := "move"
const STATE_SPRINT := "sprint"
const STATE_ATTACK_LIGHT := "attack_light"
const STATE_ATTACK_HEAVY := "attack_heavy"
const STATE_BLOCK := "block"
const STATE_DODGE := "dodge"
const STATE_STAGGER := "stagger"

var _player: PlayerController
var _mesh_root: Node3D
var _anim_target: Node3D
var _anim_player: AnimationPlayer
var _anim_tree: AnimationTree
var _state_playback: AnimationNodeStateMachinePlayback
var _current_anim_state: String = STATE_IDLE
var _attack_heavy: bool = false
var _built: bool = false


func _ready() -> void:
	_player = get_parent() as PlayerController
	_mesh_root = _player.get_node_or_null("MeshRoot") as Node3D
	if _mesh_root == null:
		return
	if DisplayServer.get_name() == "headless":
		return
	var char_visual := _mesh_root.get_node_or_null("CharacterVisual")
	if char_visual and char_visual.has_signal("visual_ready"):
		char_visual.visual_ready.connect(_on_visual_ready, CONNECT_ONE_SHOT)
	else:
		call_deferred("_build_animation_system")
	if not _player.state_changed.is_connected(_on_player_state_changed):
		_player.state_changed.connect(_on_player_state_changed)
	var combat := _player.get_node_or_null("Combat")
	if combat and combat.has_signal("attack_phase_changed"):
		combat.attack_phase_changed.connect(_on_attack_phase_changed)


func _on_visual_ready() -> void:
	call_deferred("_build_animation_system")


func _build_animation_system() -> void:
	if _built or _mesh_root == null:
		return
	_built = true
	_anim_target = _pick_animation_target()
	_anim_player = AnimationPlayer.new()
	_anim_player.name = "AnimationPlayer"
	_anim_player.root_node = NodePath("..")
	add_child(_anim_player)
	if not _try_import_gltf_animations():
		_create_procedural_animations()
	_build_state_machine()
	_travel(STATE_IDLE)


func _pick_animation_target() -> Node3D:
	var char_visual := _mesh_root.get_node_or_null("CharacterVisual")
	if char_visual and char_visual.get_child_count() > 0:
		var child := char_visual.get_child(0) as Node3D
		if child:
			return child
	return _mesh_root


func _track_path(target: Node3D) -> NodePath:
	return _anim_player.get_path_to(target)


func _try_import_gltf_animations() -> bool:
	var source := _find_animation_player(_mesh_root)
	if source == null:
		return false
	if not _anim_player.has_animation_library("locomotion"):
		_anim_player.add_animation_library("locomotion", AnimationLibrary.new())
	var lib := _anim_player.get_animation_library("locomotion")
	var imported := false
	for lib_name in source.get_animation_library_list():
		var source_lib := source.get_animation_library(lib_name)
		for anim_name in source_lib.get_animation_list():
			var mapped := _map_gltf_anim_name(anim_name)
			if mapped == "":
				continue
			var anim := source_lib.get_animation(anim_name)
			if lib.has_animation(mapped):
				lib.remove_animation(mapped)
			lib.add_animation(mapped, anim.duplicate())
			imported = true
	return imported


func _map_gltf_anim_name(name: String) -> String:
	var lower := name.to_lower()
	if lower.contains("idle"):
		return STATE_IDLE
	if lower.contains("run") or lower.contains("sprint"):
		return STATE_SPRINT
	if lower.contains("walk"):
		return STATE_MOVE
	if lower.contains("attack") and lower.contains("heavy"):
		return STATE_ATTACK_HEAVY
	if lower.contains("attack"):
		return STATE_ATTACK_LIGHT
	if lower.contains("block"):
		return STATE_BLOCK
	if lower.contains("dodge") or lower.contains("roll"):
		return STATE_DODGE
	if lower.contains("hit") or lower.contains("stagger"):
		return STATE_STAGGER
	return ""


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found:
			return found
	return null


func _build_state_machine() -> void:
	_anim_tree = AnimationTree.new()
	_anim_tree.name = "AnimationTree"
	_anim_tree.anim_player = NodePath("AnimationPlayer")
	var state_machine := AnimationNodeStateMachine.new()
	var states := [
		STATE_IDLE, STATE_MOVE, STATE_SPRINT, STATE_ATTACK_LIGHT,
		STATE_ATTACK_HEAVY, STATE_BLOCK, STATE_DODGE, STATE_STAGGER,
	]
	for state_name in states:
		if not _anim_player.get_animation_library("locomotion").has_animation(state_name):
			continue
		var node := AnimationNodeAnimation.new()
		node.animation = "locomotion/%s" % state_name
		state_machine.add_node(state_name, node)
	if state_machine.get_node_list().is_empty():
		return
	for from_state in state_machine.get_node_list():
		for to_state in [STATE_IDLE, STATE_MOVE, STATE_SPRINT]:
			if from_state == to_state or not state_machine.has_node(to_state):
				continue
			var tr := AnimationNodeStateMachineTransition.new()
			tr.switch_mode = AnimationNodeStateMachineTransition.SwitchMode.SWITCH_MODE_IMMEDIATE
			state_machine.add_transition(from_state, to_state, tr)
	state_machine.start_node = STATE_IDLE
	_anim_tree.tree_root = state_machine
	add_child(_anim_tree)
	_anim_tree.active = true
	_state_playback = _anim_tree["parameters/playback"] as AnimationNodeStateMachinePlayback


func _create_procedural_animations() -> void:
	if not _anim_player.has_animation_library("locomotion"):
		_anim_player.add_animation_library("locomotion", AnimationLibrary.new())
	_add_anim(STATE_IDLE, 1.2, _anim_target, [
		{"t": 0.0, "y": 0.0, "pitch": 0.0, "roll": 0.0},
		{"t": 0.6, "y": 0.04, "pitch": 0.02, "roll": 0.01},
		{"t": 1.2, "y": 0.0, "pitch": 0.0, "roll": 0.0},
	], true)
	_add_anim(STATE_MOVE, 0.42, _anim_target, [
		{"t": 0.0, "y": 0.0, "pitch": 0.05, "roll": 0.06},
		{"t": 0.21, "y": 0.08, "pitch": -0.04, "roll": -0.06},
		{"t": 0.42, "y": 0.0, "pitch": 0.05, "roll": 0.06},
	], true)
	_add_anim(STATE_SPRINT, 0.26, _anim_target, [
		{"t": 0.0, "y": 0.0, "pitch": 0.1, "roll": 0.1},
		{"t": 0.13, "y": 0.12, "pitch": -0.08, "roll": -0.1},
		{"t": 0.26, "y": 0.0, "pitch": 0.1, "roll": 0.1},
	], true)
	_add_attack_anim(STATE_ATTACK_LIGHT, 0.38, 28.0)
	_add_attack_anim(STATE_ATTACK_HEAVY, 0.62, 42.0)
	_add_anim(STATE_BLOCK, 0.5, _anim_target, [
		{"t": 0.0, "y": 0.0, "pitch": 0.0, "roll": 0.0},
		{"t": 0.15, "y": -0.05, "pitch": -0.14, "roll": 0.0},
		{"t": 0.5, "y": -0.05, "pitch": -0.14, "roll": 0.0},
	], false)
	_add_anim(STATE_DODGE, 0.35, _anim_target, [
		{"t": 0.0, "y": 0.0, "pitch": 0.0, "roll": 0.0},
		{"t": 0.12, "y": 0.18, "pitch": 0.4, "roll": 0.15},
		{"t": 0.35, "y": 0.0, "pitch": 0.0, "roll": 0.0},
	], false)
	_add_anim(STATE_STAGGER, 0.4, _anim_target, [
		{"t": 0.0, "y": 0.0, "pitch": 0.0, "roll": 0.0},
		{"t": 0.1, "y": -0.1, "pitch": -0.22, "roll": -0.08},
		{"t": 0.4, "y": 0.0, "pitch": 0.0, "roll": 0.0},
	], false)


func _add_anim(anim_name: String, length: float, target: Node3D, keys: Array, loop: bool) -> void:
	var anim := Animation.new()
	anim.length = length
	anim.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	var pos_track := anim.add_track(Animation.TYPE_POSITION_3D)
	anim.track_set_path(pos_track, _track_path(target))
	var rot_track := anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(rot_track, _track_path(target))
	for key in keys:
		var t: float = key.t
		anim.track_insert_key(pos_track, t, Vector3(0, key.y, 0))
		anim.track_insert_key(
			rot_track,
			t,
			Quaternion.from_euler(Vector3(key.pitch, 0, key.roll))
		)
	_register_anim(anim_name, anim)


func _add_attack_anim(anim_name: String, length: float, swing_deg: float) -> void:
	var anim := Animation.new()
	anim.length = length
	anim.loop_mode = Animation.LOOP_NONE
	var rot_track := anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(rot_track, _track_path(_anim_target))
	var windup := length * 0.35
	var active := length * 0.55
	anim.track_insert_key(rot_track, 0.0, Quaternion.IDENTITY)
	anim.track_insert_key(rot_track, windup, Quaternion.from_euler(Vector3(0.15, deg_to_rad(-swing_deg * 0.4), 0)))
	anim.track_insert_key(rot_track, active, Quaternion.from_euler(Vector3(0.1, deg_to_rad(swing_deg), 0)))
	anim.track_insert_key(rot_track, length, Quaternion.IDENTITY)
	_register_anim(anim_name, anim)


func _register_anim(anim_name: String, anim: Animation) -> void:
	if not _anim_player.has_animation_library("locomotion"):
		_anim_player.add_animation_library("locomotion", AnimationLibrary.new())
	var lib := _anim_player.get_animation_library("locomotion")
	if lib.has_animation(anim_name):
		lib.remove_animation(anim_name)
	lib.add_animation(anim_name, anim)


func _on_player_state_changed(state_name: String) -> void:
	match state_name:
		"IDLE":
			_travel(STATE_IDLE)
		"MOVE":
			_travel(STATE_MOVE)
		"SPRINT":
			_travel(STATE_SPRINT)
		"BLOCK":
			_travel(STATE_BLOCK)
		"DODGE":
			_travel(STATE_DODGE)
		"STAGGER":
			_travel(STATE_STAGGER)
		"DEAD":
			if _anim_tree:
				_anim_tree.active = false


func _on_attack_phase_changed(phase: String, heavy: bool) -> void:
	_attack_heavy = heavy
	if phase == "windup" or phase == "active":
		_travel(STATE_ATTACK_HEAVY if heavy else STATE_ATTACK_LIGHT)


func _travel(state_name: String) -> void:
	if _state_playback == null or _current_anim_state == state_name:
		return
	if not _anim_player.get_animation_library("locomotion").has_animation(state_name):
		return
	_current_anim_state = state_name
	_state_playback.travel(state_name)
	anim_state_changed.emit(state_name)
