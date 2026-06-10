class_name GltfCharacterAnim
extends Node
## Plays embedded Quaternius GLTF clips on any rigged character.

const IDLE_NAMES := ["Idle", "Idle_Gun"]
const WALK_NAMES := ["Walk", "Walk_Gun"]
const RUN_NAMES := ["Run", "Run_Gun", "Run_Slash"]
const ATTACK_NAMES := ["Slash", "Punch", "Stab", "Idle_Attack", "Run_Attack"]
const HIT_NAMES := ["HitReact"]
const DEATH_NAMES := ["Death"]
const BLOCK_NAMES := ["Duck"]

var _anim_player: AnimationPlayer
var _current: String = ""


func is_ready() -> bool:
	return _anim_player != null


func setup_from_node(root: Node) -> void:
	_anim_player = _find_animation_player(root)
	if _anim_player == null:
		return
	_anim_player.active = true
	play_idle()


func play_idle() -> void:
	_play_first(IDLE_NAMES)


func play_walk() -> void:
	_play_first(WALK_NAMES)


func play_run() -> void:
	_play_first(RUN_NAMES)


func play_attack() -> void:
	_play_first(ATTACK_NAMES)


func play_hit() -> void:
	_play_first(HIT_NAMES)


func play_block() -> void:
	_play_first(BLOCK_NAMES)


func play_death() -> void:
	_play_first(DEATH_NAMES)


func update_locomotion(horizontal_speed: float, running: bool = false) -> void:
	if _anim_player == null:
		return
	if horizontal_speed <= 0.15:
		if _current not in IDLE_NAMES:
			play_idle()
	elif running or horizontal_speed > 4.0:
		if _current not in RUN_NAMES:
			play_run()
	else:
		if _current not in WALK_NAMES:
			play_walk()


func _play_first(names: Array) -> void:
	if _anim_player == null:
		return
	for anim_name in names:
		if _has_animation(anim_name):
			if _current == anim_name and _anim_player.is_playing():
				return
			_current = anim_name
			_anim_player.play(anim_name)
			return


func _has_animation(anim_name: String) -> bool:
	for lib_name in _anim_player.get_animation_library_list():
		if _anim_player.get_animation_library(lib_name).has_animation(anim_name):
			return true
	return false


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found:
			return found
	return null
