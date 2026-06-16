class_name WaveHazard
extends Area3D
## Shoreline wave push — telegraphed, applies Soaked.

const _StatusEffects := preload("res://scripts/combat/status_effects_component.gd")

@export var push_force: float = 8.0
@export var cooldown: float = 6.0
@export var telegraph_time: float = 1.2

var _timer: float = 3.0
var _telegraphing: bool = false
var _bodies: Array[Node3D] = []


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	add_to_group("wave_hazard")
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)
	_timer = randf_range(2.0, cooldown)


func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= telegraph_time and not _telegraphing:
		_telegraphing = true
		AudioManager.play_sfx("wave_crash", 0.7)
	if _timer <= 0.0:
		_slam_wave()
		_timer = cooldown + randf_range(-1.0, 1.5)
		_telegraphing = false


func _on_enter(body: Node3D) -> void:
	if body.is_in_group("player") and body not in _bodies:
		_bodies.append(body)


func _on_exit(body: Node3D) -> void:
	_bodies.erase(body)


func _slam_wave() -> void:
	for body in _bodies:
		if not is_instance_valid(body):
			continue
		var away := (body.global_position - global_position)
		away.y = 0.0
		if away.length_squared() < 0.01:
			away = Vector3(0, 0, 1)
		away = away.normalized()
		if body is CharacterBody3D:
			(body as CharacterBody3D).velocity += away * push_force + Vector3(0, 1.5, 0)
		if body.has_node("StatusEffectsComponent"):
			(body.get_node("StatusEffectsComponent") as _StatusEffects).apply_soaked()
