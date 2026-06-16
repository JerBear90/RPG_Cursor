extends EnemyBase
## Ranged wraith with telegraphed short-range teleport.

var _teleport_cd: float = 0.0


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_teleport_cd = maxf(_teleport_cd - delta, 0.0)
	if current_state == AIState.CHASE and _target and _teleport_cd <= 0.0:
		if global_position.distance_to(_target.global_position) > attack_range * 1.2:
			if global_position.distance_to(_target.global_position) < detection_range:
				_teleport_cd = 6.0
				global_position = _target.global_position + Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
				call_deferred("_snap_to_ground")
