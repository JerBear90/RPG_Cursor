extends Node
## Drives skeletal GLTF clips (Quaternius rig) or procedural fallback on the player mesh.

signal anim_state_changed(state: String)

const STATE_IDLE := "idle"
const STATE_MOVE := "move"
const STATE_SPRINT := "sprint"
const STATE_ATTACK_LIGHT := "attack_light"
const STATE_ATTACK_HEAVY := "attack_heavy"
const STATE_BLOCK := "block"
const STATE_DODGE := "dodge"
const STATE_AIRBORNE := "airborne"
const STATE_STAGGER := "stagger"
const STATE_DEAD := "dead"

const GLTF_STATE_MAP := {
	STATE_IDLE: "Idle",
	STATE_MOVE: "Walk",
	STATE_SPRINT: "Run",
	STATE_ATTACK_LIGHT: "Slash",
	STATE_ATTACK_HEAVY: "Stab",
	STATE_BLOCK: "Duck",
	STATE_DODGE: "Jump",
	STATE_STAGGER: "HitReact",
	STATE_DEAD: "Death",
}

const GLTF_ALIASES := {
	"idle": ["Idle", "Idle_Gun"],
	"move": ["Walk", "Walk_Gun"],
	"sprint": ["Run", "Run_Gun", "Run_Slash", "Run_Stab"],
	"attack_light": ["Slash", "Punch", "Idle_Attack", "Run_Slash", "Run_Attack"],
	"attack_heavy": ["Slash", "Run_Slash", "Stab", "Run_Stab"],
	"block": ["Idle", "Duck"],
	"dodge": ["Run", "Jump", "Jump_Land"],
	"airborne": ["Jump", "Jump_Land", "Idle"],
	"stagger": ["Idle", "HitReact"],
	"dead": ["Death"],
}

const LOCOMOTION_STATES := [STATE_IDLE, STATE_MOVE, STATE_SPRINT]
const PLAYER_ACTION_STATES := [STATE_ATTACK_LIGHT, STATE_ATTACK_HEAVY, STATE_DODGE]
const DISABLED_PLAYER_STATES := [STATE_BLOCK, STATE_STAGGER, STATE_DEAD]

const ONE_SHOT_STATES := [
	STATE_ATTACK_LIGHT, STATE_ATTACK_HEAVY, STATE_DODGE, STATE_STAGGER,
]

var _player: PlayerController
var _mesh_root: Node3D
var _anim_target: Node3D
var _anim_player: AnimationPlayer
var _anim_tree: AnimationTree
var _state_playback: AnimationNodeStateMachinePlayback
var _current_anim_state: String = STATE_IDLE
var _using_skeletal: bool = false
var _resolved_gltf: Dictionary = {}
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
	var dodge := _player.get_node_or_null("DodgeComponent") as DodgeComponent
	if dodge:
		dodge.dodge_ended.connect(_sync_locomotion_from_player)
	if not _player.is_on_floor():
		set_process(true)


func _process(_delta: float) -> void:
	if _player == null or not _built:
		return
	if _player.current_state in [PlayerController.State.DEAD, PlayerController.State.ATTACK, PlayerController.State.DODGE]:
		return
	var airborne := not _player.is_on_floor() or _player.velocity.y > 0.05
	if airborne:
		_travel(STATE_AIRBORNE)
	else:
		_sync_locomotion_from_player()


func _on_visual_ready() -> void:
	call_deferred("_build_animation_system")


func _build_animation_system() -> void:
	if _built or _mesh_root == null:
		return
	_built = true
	_anim_player = _find_animation_player(_mesh_root)
	if _anim_player != null:
		_using_skeletal = _setup_skeletal_player()
	if not _using_skeletal:
		_anim_target = _pick_animation_target()
		_anim_player = AnimationPlayer.new()
		_anim_player.name = "AnimationPlayer"
		_anim_player.root_node = NodePath("..")
		add_child(_anim_player)
		_create_procedural_animations()
	_build_state_machine()
	_sync_locomotion_from_player()


func _setup_skeletal_player() -> bool:
	_resolved_gltf.clear()
	var available := _collect_gltf_animation_names()
	if available.is_empty():
		return false
	for logical_state in GLTF_ALIASES.keys():
		for candidate in GLTF_ALIASES[logical_state]:
			if candidate in available:
				_resolved_gltf[logical_state] = candidate
				break
	if not _resolved_gltf.has(STATE_IDLE):
		return false
	_anim_player.active = true
	return true


func _collect_gltf_animation_names() -> PackedStringArray:
	var names := PackedStringArray()
	if _anim_player == null:
		return names
	for lib_name in _anim_player.get_animation_library_list():
		var lib := _anim_player.get_animation_library(lib_name)
		for anim_name in lib.get_animation_list():
			names.append(anim_name)
	return names


func _pick_animation_target() -> Node3D:
	var char_visual := _mesh_root.get_node_or_null("CharacterVisual")
	if char_visual and char_visual.get_child_count() > 0:
		var child := char_visual.get_child(0) as Node3D
		if child:
			return child
	return _mesh_root


func _track_path(target: Node3D) -> NodePath:
	return _anim_player.get_path_to(target)


func _build_state_machine() -> void:
	if _anim_tree:
		_anim_tree.queue_free()
		_anim_tree = null
	_anim_tree = AnimationTree.new()
	_anim_tree.name = "AnimationTree"
	add_child(_anim_tree)
	var state_machine := AnimationNodeStateMachine.new()
	var locomotion_states: Array[String] = [STATE_IDLE, STATE_MOVE, STATE_SPRINT]
	if _using_skeletal:
		var one_shot_states: Array[String] = []
		for one_shot_state in PLAYER_ACTION_STATES:
			if _resolved_gltf.has(one_shot_state):
				one_shot_states.append(one_shot_state)
		for logical_state in _resolved_gltf.keys():
			if logical_state in DISABLED_PLAYER_STATES:
				continue
			var gltf_name: String = _resolved_gltf[logical_state]
			var node := AnimationNodeAnimation.new()
			node.animation = gltf_name
			state_machine.add_node(StringName(gltf_name), node)
		for from_logical in _resolved_gltf.keys():
			if from_logical in DISABLED_PLAYER_STATES:
				continue
			var from_name: String = _resolved_gltf[from_logical]
			for to_logical in _resolved_gltf.keys():
				if to_logical in DISABLED_PLAYER_STATES:
					continue
				var to_name: String = _resolved_gltf[to_logical]
				if from_name == to_name:
					continue
				if from_logical in one_shot_states and to_logical not in LOCOMOTION_STATES:
					continue
				if to_logical in one_shot_states and from_logical not in LOCOMOTION_STATES:
					continue
				var tr := AnimationNodeStateMachineTransition.new()
				if from_logical in one_shot_states:
					tr.switch_mode = AnimationNodeStateMachineTransition.SwitchMode.SWITCH_MODE_AT_END
					tr.advance_mode = AnimationNodeStateMachineTransition.AdvanceMode.ADVANCE_MODE_AUTO
				else:
					tr.switch_mode = AnimationNodeStateMachineTransition.SwitchMode.SWITCH_MODE_IMMEDIATE
				state_machine.add_transition(StringName(from_name), StringName(to_name), tr)
	else:
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
			for to_state in state_machine.get_node_list():
				if from_state == to_state:
					continue
				var tr := AnimationNodeStateMachineTransition.new()
				if from_state in ONE_SHOT_STATES:
					tr.switch_mode = AnimationNodeStateMachineTransition.SwitchMode.SWITCH_MODE_AT_END
					tr.advance_mode = AnimationNodeStateMachineTransition.AdvanceMode.ADVANCE_MODE_AUTO
				else:
					tr.switch_mode = AnimationNodeStateMachineTransition.SwitchMode.SWITCH_MODE_IMMEDIATE
				state_machine.add_transition(from_state, to_state, tr)
	_anim_tree.tree_root = state_machine
	_anim_tree.anim_player = _anim_tree.get_path_to(_anim_player)
	_anim_tree.active = true
	_state_playback = _anim_tree["parameters/playback"] as AnimationNodeStateMachinePlayback
	var initial_state := STATE_IDLE
	if _using_skeletal and _resolved_gltf.has(STATE_IDLE):
		initial_state = _resolved_gltf[STATE_IDLE]
	elif not state_machine.get_node_list().is_empty():
		initial_state = state_machine.get_node_list()[0]
	if _state_playback:
		_state_playback.start(initial_state)
		_current_anim_state = initial_state


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
		{"t": 0.15, "y": 0.0, "pitch": -0.06, "roll": 0.0},
		{"t": 0.5, "y": 0.0, "pitch": -0.06, "roll": 0.0},
	], false)
	_add_anim(STATE_DODGE, 0.35, _anim_target, [
		{"t": 0.0, "y": 0.0, "pitch": 0.0, "roll": 0.0},
		{"t": 0.12, "y": 0.18, "pitch": 0.4, "roll": 0.15},
		{"t": 0.35, "y": 0.0, "pitch": 0.0, "roll": 0.0},
	], false)
	_add_anim(STATE_AIRBORNE, 0.6, _anim_target, [
		{"t": 0.0, "y": 0.0, "pitch": 0.0, "roll": 0.0},
		{"t": 0.3, "y": 0.14, "pitch": -0.08, "roll": 0.0},
		{"t": 0.6, "y": 0.0, "pitch": 0.0, "roll": 0.0},
	], true)
	_add_anim(STATE_STAGGER, 0.4, _anim_target, [
		{"t": 0.0, "y": 0.0, "pitch": 0.0, "roll": 0.0},
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
		"ATTACK":
			pass
		"BLOCK":
			_sync_locomotion_from_player()
		"DODGE":
			_travel(STATE_DODGE)
		"STAGGER":
			_sync_locomotion_from_player()
		"DEAD":
			_sync_locomotion_from_player()


func _on_attack_phase_changed(phase: String, heavy: bool) -> void:
	if phase == "windup" or phase == "active":
		_travel(STATE_ATTACK_HEAVY if heavy else STATE_ATTACK_LIGHT)
	elif phase == "none":
		call_deferred("_reset_after_attack")


func sync_locomotion() -> void:
	_sync_locomotion_from_player()


func _reset_after_attack() -> void:
	_force_idle_pose()
	_sync_locomotion_from_player()


func _force_idle_pose() -> void:
	if _anim_target:
		_anim_target.position = Vector3.ZERO
		_anim_target.rotation = Vector3.ZERO
	if _using_skeletal and _state_playback and _resolved_gltf.has(STATE_IDLE):
		var idle_name: String = _resolved_gltf[STATE_IDLE]
		_state_playback.start(idle_name)
		_current_anim_state = idle_name


func _sync_locomotion_from_player() -> void:
	if _player == null or not _player.is_alive():
		return
	match _player.current_state:
		PlayerController.State.SPRINT:
			_travel(STATE_SPRINT)
		PlayerController.State.MOVE:
			_travel(STATE_MOVE)
		_:
			_travel(STATE_IDLE)
	if _anim_target and not _using_skeletal:
		_anim_target.position = Vector3.ZERO
		_anim_target.rotation = Vector3.ZERO


func _travel(logical_state: String) -> void:
	if _state_playback == null:
		return
	var target_state := logical_state
	if _using_skeletal:
		if not _resolved_gltf.has(logical_state):
			if logical_state == STATE_SPRINT and _resolved_gltf.has(STATE_MOVE):
				logical_state = STATE_MOVE
			elif logical_state == STATE_MOVE and _resolved_gltf.has(STATE_IDLE):
				logical_state = STATE_IDLE
			else:
				return
		target_state = _resolved_gltf[logical_state]
	elif not _anim_player.get_animation_library("locomotion").has_animation(logical_state):
		return
	if _current_anim_state == target_state:
		if logical_state in ONE_SHOT_STATES:
			_state_playback.start(target_state)
			anim_state_changed.emit(logical_state)
		return
	_current_anim_state = target_state
	_state_playback.travel(target_state)
	anim_state_changed.emit(logical_state)


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found:
			return found
	return null
