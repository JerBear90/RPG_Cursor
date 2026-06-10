class_name SpawnHelpers
extends RefCounted
## Snap spawned characters onto world collision.


static func snap_character_to_ground(body: CharacterBody3D, lift: float = 0.05) -> bool:
	if body == null or not is_instance_valid(body):
		return false
	var world := body.get_world_3d()
	if world == null:
		return false
	var space := world.direct_space_state
	var origin := body.global_position
	var bottom_offset := _collision_bottom_offset(body)
	for height in [24.0, 12.0, 6.0]:
		var from := origin + Vector3(0.0, height, 0.0)
		var to := origin + Vector3(0.0, -64.0, 0.0)
		var query := PhysicsRayQueryParameters3D.create(from, to)
		query.collision_mask = 1
		query.exclude = [body.get_rid()]
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			continue
		var floor_y: float = hit.position.y + lift
		body.global_position = Vector3(origin.x, floor_y - bottom_offset, origin.z)
		body.velocity = Vector3.ZERO
		return true
	body.global_position = Vector3(origin.x, 2.0 - bottom_offset, origin.z)
	body.velocity = Vector3.ZERO
	return false


static func _collision_bottom_offset(body: CharacterBody3D) -> float:
	for child in body.get_children():
		if child is CollisionShape3D:
			var col := child as CollisionShape3D
			var shape := col.shape
			if shape is CapsuleShape3D:
				var cap := shape as CapsuleShape3D
				return col.position.y - cap.height * 0.5
			if shape is BoxShape3D:
				var box := shape as BoxShape3D
				return col.position.y - box.size.y * 0.5
	return 0.0
