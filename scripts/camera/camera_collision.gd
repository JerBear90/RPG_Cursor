class_name CameraCollision
extends Node
## Raycast-based camera wall collision.

@export var collision_mask: int = 1
@export var sphere_radius: float = 0.3

var _camera: Camera3D


func _ready() -> void:
	_camera = get_parent() as Camera3D


func resolve_collision(target: Vector3, desired: Vector3) -> Vector3:
	if _camera == null:
		return desired
	var space := _camera.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(target, desired, collision_mask)
	query.collide_with_areas = false
	var result := space.intersect_ray(query)
	if result.is_empty():
		return desired
	return result.position + result.normal * sphere_radius
