extends EnemyBase
## Snow ambush predator — brief burrow telegraph.

var _burrow_cooldown: float = 0.0


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_burrow_cooldown = maxf(_burrow_cooldown - delta, 0.0)
	if _target == null or _burrow_cooldown > 0.0:
		return
	if global_position.distance_to(_target.global_position) > 6.0 and global_position.distance_to(_target.global_position) < 14.0:
		if randf() < 0.008:
			_burrow_cooldown = 4.0
			global_position = _target.global_position + Vector3(randf_range(-2, 2), 0.1, randf_range(-2, 2))
