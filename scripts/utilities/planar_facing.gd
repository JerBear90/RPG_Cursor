class_name PlanarFacing
extends RefCounted
## Godot -Z forward facing helper (avoids look_at flipping).


static func face_direction(body: Node3D, direction: Vector3) -> void:
	if direction.length_squared() < 0.0001:
		return
	var flat := Vector3(direction.x, 0.0, direction.z)
	if flat.length_squared() < 0.0001:
		return
	body.rotation.y = atan2(-flat.x, -flat.z)


static func apply_floor(body: CharacterBody3D, delta: float, gravity: float) -> void:
	if body.is_on_floor():
		body.velocity.y = 0.0
	else:
		body.velocity.y -= gravity * delta
