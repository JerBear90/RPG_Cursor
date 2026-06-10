class_name SharedScreenCamera
extends Camera3D
## Shared-screen co-op camera — over-the-shoulder orbit behind players.

@export var min_distance: float = 4.0
@export var max_distance: float = 14.0
@export var base_distance: float = 6.5
@export var height_offset: float = 2.2
@export var shoulder_offset: float = 0.6
@export var look_ahead: float = 1.5
@export var follow_speed: float = 8.0
@export var max_separation: float = 12.0
@export var camera_fov: float = 70.0
@export var mouse_sensitivity: float = 0.003

var _collision: CameraCollision
var _yaw: float = 0.0
var _pitch: float = -0.25


func _ready() -> void:
	fov = camera_fov
	_collision = get_node_or_null("CameraCollision")


func _physics_process(delta: float) -> void:
	var players := GameManager.get_alive_players()
	if players.is_empty():
		return

	var midpoint := Vector3.ZERO
	for p in players:
		midpoint += p.global_position
	midpoint /= players.size()

	var separation := 0.0
	if players.size() > 1:
		separation = players[0].global_position.distance_to(players[1].global_position)
		_apply_soft_tether(players, separation, delta)

	var distance := clampf(base_distance + separation * 0.35, min_distance, max_distance)
	var pivot := midpoint + Vector3(0, look_ahead, 0)

	# Orbit behind pivot: Godot forward is -Z, so "behind" is +Z in yaw-local space.
	var orbit_basis := Basis.from_euler(Vector3(_pitch, _yaw, 0))
	var cam_offset := orbit_basis * Vector3(shoulder_offset, height_offset, distance)
	var desired_pos := pivot + cam_offset

	if _collision:
		desired_pos = _collision.resolve_collision(pivot, desired_pos)

	global_position = global_position.lerp(desired_pos, follow_speed * delta)
	look_at(pivot, Vector3.UP)


func add_look_input(look: Vector2) -> void:
	_yaw -= look.x
	_pitch = clampf(_pitch - look.y, -0.6, 0.35)


func get_planar_forward() -> Vector3:
	var forward := -global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.001:
		return Vector3.FORWARD
	return forward.normalized()


func get_planar_right() -> Vector3:
	return Vector3.UP.cross(get_planar_forward()).normalized()


func _apply_soft_tether(players: Array[Node], separation: float, delta: float) -> void:
	if separation <= max_separation:
		return
	var p0 := players[0] as Node3D
	var p1 := players[1] as Node3D
	var dir := (p0.global_position - p1.global_position).normalized()
	var pull := (separation - max_separation) * 0.5 * delta
	p0.global_position -= dir * pull
	p1.global_position += dir * pull
