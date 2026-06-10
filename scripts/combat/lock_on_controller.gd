class_name LockOnController
extends Node
## Lock-on targeting for combat camera and attacks.

signal target_changed(target: Node3D)
signal lock_released

@export var lock_range: float = 12.0
@export var break_range: float = 18.0

var is_locked: bool = false
var current_target: Node3D = null
var _owner: Node3D


func setup(owner_node: Node3D) -> void:
	_owner = owner_node


func toggle_lock() -> void:
	if is_locked:
		release_lock()
	else:
		_acquire_nearest()


func switch_target(direction: int) -> void:
	if not is_locked:
		return
	var candidates := _get_targets_in_range()
	if candidates.size() <= 1:
		return
	var idx := candidates.find(current_target)
	idx = (idx + direction) % candidates.size()
	_set_target(candidates[idx])


func release_lock() -> void:
	is_locked = false
	current_target = null
	lock_released.emit()


func _physics_process(_delta: float) -> void:
	if not is_locked or not is_instance_valid(current_target):
		release_lock()
		return
	if _owner.global_position.distance_to(current_target.global_position) > break_range:
		release_lock()


func _acquire_nearest() -> void:
	var candidates := _get_targets_in_range()
	if candidates.is_empty():
		return
	var nearest: Node3D = candidates[0]
	var best_dist := _owner.global_position.distance_to(nearest.global_position)
	for t in candidates:
		var d := _owner.global_position.distance_to(t.global_position)
		if d < best_dist:
			best_dist = d
			nearest = t
	_set_target(nearest)


func _set_target(target: Node3D) -> void:
	current_target = target
	is_locked = true
	target_changed.emit(target)


func _get_targets_in_range() -> Array[Node3D]:
	var result: Array[Node3D] = []
	for node in get_tree().get_nodes_in_group("lockable_enemy"):
		if node is Node3D and _owner.global_position.distance_to(node.global_position) <= lock_range:
			if node.has_method("is_alive") and node.is_alive():
				result.append(node)
	return result
