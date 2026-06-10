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
var _anim_player: AnimationPlayer
var _anim_tree: AnimationTree
var _state_playback: AnimationNodeStateMachinePlayback
var _current_anim_state: String = STATE_IDLE
var _attack_heavy: bool = false


func _ready() -> void:
	_player = get_parent() as PlayerController
	_mesh_root = _player.get_node_or_null("MeshRoot") as Node3D
	if _mesh_root == null:
		return
	if DisplayServer.get_name() == "headless":
		return
	call_deferred("_build_animation_system")
	if not _player.state_changed.is_connected(_on_player_state_changed):
		_player.state_changed.connect(_on_player_state_changed)
	var combat := _player.get_node_or_null("Combat")
	if combat and combat.has_signal("attack_phase_changed"):
		combat.attack_phase_changed.connect(_on_attack_phase_changed)


func _build_animation_system() -> void:
	_anim_player = AnimationPlayer.new()
	_anim_player.name = "AnimationPlayer"
	add_child(_anim_player)
	_create_procedural_animations()
	_anim_tree = AnimationTree.new()
	_anim_tree.name = "AnimationTree"
	_anim_tree.anim_player = NodePath("AnimationPlayer")
	var state_machine := AnimationNodeStateMachine.new()
	var states := [
		STATE_IDLE, STATE_MOVE, STATE_SPRINT, STATE_ATTACK_LIGHT,
		STATE_ATTACK_HEAVY, STATE_BLOCK, STATE_DODGE, STATE_STAGGER,
	]
	for state_name in states:
		var node := AnimationNodeAnimation.new()
		node.animation = "locomotion/%s" % state_name
		state_machine.add_node(state_name, node)
	state_machine.add_transition(STATE_IDLE, STATE_MOVE, AnimationNodeStateMachineTransition.new())
	state_machine.add_transition(STATE_MOVE, STATE_IDLE, AnimationNodeStateMachineTransition.new())
	state_machine.add_transition(STATE_MOVE, STATE_SPRINT, AnimationNodeStateMachineTransition.new())
	state_machine.add_transition(STATE_SPRINT, STATE_MOVE, AnimationNodeStateMachineTransition.new())
	state_machine.add_transition(STATE_IDLE, STATE_ATTACK_LIGHT, AnimationNodeStateMachineTransition.new())
	state_machine.add_transition(STATE_MOVE, STATE_ATTACK_LIGHT, AnimationNodeStateMachineTransition.new())
	state_machine.add_transition(STATE_IDLE, STATE_ATTACK_HEAVY, AnimationNodeStateMachineTransition.new())
	state_machine.add_transition(STATE_MOVE, STATE_ATTACK_HEAVY, AnimationNodeStateMachineTransition.new())
	state_machine.add_transition(STATE_IDLE, STATE_BLOCK, AnimationNodeStateMachineTransition.new())
	state_machine.add_transition(STATE_MOVE, STATE_BLOCK, AnimationNodeStateMachineTransition.new())
	state_machine.add_transition(STATE_IDLE, STATE_DODGE, AnimationNodeStateMachineTransition.new())
	state_machine.add_transition(STATE_MOVE, STATE_DODGE, AnimationNodeStateMachineTransition.new())
	for from_state in states:
		for to_state in [STATE_IDLE, STATE_MOVE]:
			if from_state != to_state:
				var back := AnimationNodeStateMachineTransition.new()
				back.switch_mode = AnimationNodeStateMachineTransition.SwitchMode.SWITCH_MODE_AT_END
				back.advance_mode = AnimationNodeStateMachineTransition.AdvanceMode.ADVANCE_MODE_AUTO
				state_machine.add_transition(from_state, to_state, back)
	state_machine.start_node = STATE_IDLE
	_anim_tree.tree_root = state_machine
	add_child(_anim_tree)
	_anim_tree.active = true
	_state_playback = _anim_tree["parameters/playback"] as AnimationNodeStateMachinePlayback
	_travel(STATE_IDLE)


func _create_procedural_animations() -> void:
	var path := _mesh_root.get_path()
	_add_anim(STATE_IDLE, 1.2, _mesh_root, [
		{"t": 0.0, "y": 0.0, "pitch": 0.0},
		{"t": 0.6, "y": 0.03, "pitch": 0.02},
		{"t": 1.2, "y": 0.0, "pitch": 0.0},
	], true)
	_add_anim(STATE_MOVE, 0.45, _mesh_root, [
		{"t": 0.0, "y": 0.0, "pitch": 0.04},
		{"t": 0.22, "y": 0.06, "pitch": -0.02},
		{"t": 0.45, "y": 0.0, "pitch": 0.04},
	], true)
	_add_anim(STATE_SPRINT, 0.28, _mesh_root, [
		{"t": 0.0, "y": 0.0, "pitch": 0.08},
		{"t": 0.14, "y": 0.1, "pitch": -0.06},
		{"t": 0.28, "y": 0.0, "pitch": 0.08},
	], true)
	_add_attack_anim(STATE_ATTACK_LIGHT, 0.38, 28.0)
	_add_attack_anim(STATE_ATTACK_HEAVY, 0.62, 42.0)
	_add_anim(STATE_BLOCK, 0.5, _mesh_root, [
		{"t": 0.0, "y": 0.0, "pitch": 0.0},
		{"t": 0.15, "y": -0.04, "pitch": -0.12},
		{"t": 0.5, "y": -0.04, "pitch": -0.12},
	], false)
	_add_anim(STATE_DODGE, 0.35, _mesh_root, [
		{"t": 0.0, "y": 0.0, "pitch": 0.0},
		{"t": 0.12, "y": 0.15, "pitch": 0.35},
		{"t": 0.35, "y": 0.0, "pitch": 0.0},
	], false)
	_add_anim(STATE_STAGGER, 0.4, _mesh_root, [
		{"t": 0.0, "y": 0.0, "pitch": 0.0},
		{"t": 0.1, "y": -0.08, "pitch": -0.2},
		{"t": 0.4, "y": 0.0, "pitch": 0.0},
	], false)


func _add_anim(anim_name: String, length: float, target: Node3D, keys: Array, loop: bool) -> void:
	var anim := Animation.new()
	anim.length = length
	anim.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	var pos_track := anim.add_track(Animation.TYPE_POSITION_3D)
	anim.track_set_path(pos_track, target.get_path())
	var rot_track := anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(rot_track, target.get_path())
	for key in keys:
		var t: float = key.t
		anim.track_insert_key(pos_track, t, Vector3(0, key.y, 0))
		anim.track_insert_key(rot_track, t, Quaternion.from_euler(Vector3(key.pitch, 0, 0)))
	_register_anim(anim_name, anim)


func _add_attack_anim(anim_name: String, length: float, swing_deg: float) -> void:
	var anim := Animation.new()
	anim.length = length
	anim.loop_mode = Animation.LOOP_NONE
	var rot_track := anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(rot_track, _mesh_root.get_path())
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
	_anim_player.get_animation_library("locomotion").add_animation(anim_name, anim)


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
			_anim_tree.active = false


func _on_attack_phase_changed(phase: String, heavy: bool) -> void:
	_attack_heavy = heavy
	if phase == "windup" or phase == "active":
		_travel(STATE_ATTACK_HEAVY if heavy else STATE_ATTACK_LIGHT)


func _travel(state_name: String) -> void:
	if _state_playback == null or _current_anim_state == state_name:
		return
	_current_anim_state = state_name
	_state_playback.travel(state_name)
	anim_state_changed.emit(state_name)
