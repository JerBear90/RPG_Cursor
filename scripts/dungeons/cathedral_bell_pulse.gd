class_name CathedralBellPulse
extends Node3D
## Corrupted bell shockwave hazard in Blighted Bell Hall.

@export var pulse_interval: float = 6.0

var _timer: float = 3.0
var _disabled: bool = false


func _ready() -> void:
	add_to_group("cathedral_bell_pulse")
	if CathedralState.brazier_c and CathedralState.puzzle_completed:
		_disabled = true


func disable_pulse() -> void:
	_disabled = true


func _process(delta: float) -> void:
	if _disabled:
		return
	_timer -= delta
	if _timer <= 0.0:
		_timer = pulse_interval
		_fire_pulse()


func _fire_pulse() -> void:
	AudioManager.play_sfx("corrupted_bell")
	for player in GameManager.get_alive_players():
		if not player is Node3D:
			continue
		if global_position.distance_to((player as Node3D).global_position) > 12.0:
			continue
		if player.has_node("StatusEffectsComponent"):
			player.get_node("StatusEffectsComponent").add_blight_buildup(8.0)
