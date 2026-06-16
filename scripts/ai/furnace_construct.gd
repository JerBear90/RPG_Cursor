extends EnemyBase
## Heavy armored construct with brief weak-point window after slam.

var _weak_point_open: bool = false
var _weak_timer: float = 0.0


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _weak_timer > 0.0:
		_weak_timer -= delta
		if _weak_timer <= 0.0:
			_weak_point_open = false


func _perform_attack() -> void:
	super._perform_attack()
	_weak_point_open = true
	_weak_timer = 2.5
