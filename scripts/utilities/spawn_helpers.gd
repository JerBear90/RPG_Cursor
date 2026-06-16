class_name SpawnHelpers
extends RefCounted
## Snap spawned characters onto world collision.

const GROUND_COLLISION_MASK := 1
const BLOCKING_COLLISION_MASK := 9
const MIN_WALKABLE_GROUND_DOT := 0.7
const FALLBACK_SEARCH_RADIUS := 8.0
const FALLBACK_SEARCH_RINGS := 4
const MAX_VALID_SPAWN_Y := 64.0
const MIN_VALID_SPAWN_Y := -32.0
const FALLBACK_GROUND_Y := 0.05
const RAY_CAST_UP := 50.0
const RAY_CAST_DOWN := 200.0
const GROUND_LIFT := 0.05


static func sanitize_spawn_position(pos: Vector3, fallback: Vector3) -> Vector3:
	if not is_finite(pos.x) or not is_finite(pos.y) or not is_finite(pos.z):
		return fallback
	return Vector3(pos.x, pos.y, pos.z)


static func is_saved_position_plausible(pos: Vector3, ground_y: float) -> bool:
	if pos.y > MAX_VALID_SPAWN_Y or pos.y < MIN_VALID_SPAWN_Y:
		return false
	return absf(pos.y - ground_y) <= 12.0


static func query_ground_y(world: World3D, origin: Vector3, exclude: RID = RID()) -> float:
	return query_ground_at_xz(world, origin, exclude)


static func query_ground_at_xz(world: World3D, xz: Vector3, exclude: RID = RID()) -> float:
	if world == null:
		return FALLBACK_GROUND_Y
	var space := world.direct_space_state
	var best := INF
	var offsets := [
		Vector2.ZERO,
		Vector2(0.45, 0.0),
		Vector2(-0.45, 0.0),
		Vector2(0.0, 0.45),
		Vector2(0.0, -0.45),
	]
	for off in offsets:
		var sample_x: float = xz.x + off.x
		var sample_z: float = xz.z + off.y
		var from := Vector3(sample_x, RAY_CAST_UP, sample_z)
		var to := Vector3(sample_x, -RAY_CAST_DOWN, sample_z)
		var query := PhysicsRayQueryParameters3D.create(from, to)
		query.collision_mask = GROUND_COLLISION_MASK
		if exclude.is_valid():
			query.exclude = [exclude]
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			continue
		var y := float(hit.position.y)
		if y <= MAX_VALID_SPAWN_Y and y >= MIN_VALID_SPAWN_Y and y < best:
			best = y
	if best < INF:
		return best
	return FALLBACK_GROUND_Y


static func get_feet_offset(body: CharacterBody3D) -> float:
	var lowest := 0.0
	for child in body.get_children():
		if child is CollisionShape3D:
			var col := child as CollisionShape3D
			var shape := col.shape
			var bottom := col.position.y
			if shape is CapsuleShape3D:
				bottom -= (shape as CapsuleShape3D).height * 0.5
			elif shape is BoxShape3D:
				bottom -= (shape as BoxShape3D).size.y * 0.5
			elif shape is SphereShape3D:
				bottom -= (shape as SphereShape3D).radius
			lowest = minf(lowest, bottom)
	return lowest


static func resolve_spawn_position(
	world: World3D,
	desired: Vector3,
	fallback: Vector3,
	exclude: RID = RID()
) -> Vector3:
	var xz := Vector3(desired.x, 0.0, desired.z)
	if not is_finite(desired.x) or not is_finite(desired.z):
		xz = Vector3(fallback.x, 0.0, fallback.z)
	var ground_y := query_ground_at_xz(world, xz, exclude)
	var resolved := Vector3(xz.x, ground_y, xz.z)
	if is_saved_position_plausible(desired, ground_y):
		return Vector3(desired.x, desired.y, desired.z)
	return resolved


static func place_player_on_ground(body: CharacterBody3D, desired: Vector3, tree: SceneTree) -> bool:
	return await place_player_safely_on_ground(body, desired, tree)


static func place_player_safely_on_ground(body: CharacterBody3D, desired: Vector3, tree: SceneTree) -> bool:
	if body == null or not is_instance_valid(body) or tree == null:
		return false
	await tree.physics_frame
	await tree.physics_frame
	var world := body.get_world_3d()
	if world == null:
		return false
	var candidates := _build_fallback_candidates(desired)
	for candidate in candidates:
		var hit := _raycast_ground(world, candidate, body.get_rid())
		if hit.is_empty():
			continue
		var ground_normal: Vector3 = hit.normal
		if ground_normal.dot(Vector3.UP) < MIN_WALKABLE_GROUND_DOT:
			continue
		var ground_position: Vector3 = hit.position
		var feet := get_feet_offset(body)
		var target := Vector3(candidate.x, ground_position.y - feet + GROUND_LIFT, candidate.z)
		if not _is_position_clear(world, body, target):
			continue
		body.global_position = target
		body.velocity = Vector3.ZERO
		for _attempt in 8:
			await tree.physics_frame
			body.velocity = Vector3.ZERO
			body.move_and_slide()
			if body.is_on_floor():
				return true
			var retry_y := query_ground_at_xz(world, body.global_position, body.get_rid())
			body.global_position = Vector3(body.global_position.x, retry_y - feet + GROUND_LIFT, body.global_position.z)
	push_error("SpawnHelpers: no valid ground placement near %s" % str(desired))
	return false


static func _build_fallback_candidates(center: Vector3) -> Array[Vector3]:
	var results: Array[Vector3] = [center]
	var dirs := [
		Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1),
		Vector2(1, 1).normalized(), Vector2(-1, 1).normalized(),
		Vector2(1, -1).normalized(), Vector2(-1, -1).normalized(),
	]
	for ring in range(1, FALLBACK_SEARCH_RINGS + 1):
		var radius := float(ring) * (FALLBACK_SEARCH_RADIUS / float(FALLBACK_SEARCH_RINGS))
		for dir in dirs:
			results.append(Vector3(center.x + dir.x * radius, center.y, center.z + dir.y * radius))
	return results


static func _raycast_ground(world: World3D, xz: Vector3, exclude: RID) -> Dictionary:
	var space := world.direct_space_state
	var from := Vector3(xz.x, xz.y + RAY_CAST_UP, xz.z)
	var to := Vector3(xz.x, xz.y - RAY_CAST_DOWN, xz.z)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = GROUND_COLLISION_MASK
	if exclude.is_valid():
		query.exclude = [exclude]
	return space.intersect_ray(query)


static func _is_position_clear(world: World3D, body: CharacterBody3D, target: Vector3) -> bool:
	var space := world.direct_space_state
	var capsule := _get_player_capsule(body)
	if capsule == null:
		return true
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = capsule
	params.transform = Transform3D(Basis.IDENTITY, target)
	params.collision_mask = BLOCKING_COLLISION_MASK
	params.exclude = [body.get_rid()]
	return space.intersect_shape(params, 1).is_empty()


static func _get_player_capsule(body: CharacterBody3D) -> CapsuleShape3D:
	for child in body.get_children():
		if child is CollisionShape3D:
			var shape := (child as CollisionShape3D).shape
			if shape is CapsuleShape3D:
				return shape as CapsuleShape3D
	return null


static func snap_character_to_ground(body: CharacterBody3D, lift: float = GROUND_LIFT) -> bool:
	if body == null or not is_instance_valid(body):
		return false
	var world := body.get_world_3d()
	if world == null:
		return false
	var origin := body.global_position
	var feet := get_feet_offset(body)
	var floor_y := query_ground_at_xz(world, origin, body.get_rid()) + lift
	body.global_position = Vector3(origin.x, floor_y - feet, origin.z)
	body.velocity = Vector3.ZERO
	return true


static func get_party_offset(player_index: int, leader_yaw: float) -> Vector3:
	if player_index <= 0:
		return Vector3.ZERO
	var right := Vector3(cos(leader_yaw), 0.0, sin(leader_yaw))
	var forward := Vector3(-sin(leader_yaw), 0.0, cos(leader_yaw))
	if player_index == 1:
		return right * 2.2
	return (-forward * 1.6) + (right * 1.4)


static func place_party_at_marker(tree: SceneTree, marker: Node3D) -> void:
	if tree == null or marker == null:
		return
	var party: Array[Node] = []
	for p in GameManager.players:
		if p and is_instance_valid(p):
			party.append(p)
	if party.is_empty():
		return
	var yaw: float = marker.get_facing_yaw() if marker.has_method("get_facing_yaw") else 0.0
	var leader := party[0]
	if leader is CharacterBody3D:
		await place_player_safely_on_ground(leader as CharacterBody3D, marker.global_position, tree)
		if marker.has_method("get_facing_yaw"):
			leader.rotation.y = yaw
	for i in range(1, party.size()):
		var companion := party[i]
		if not companion is CharacterBody3D:
			continue
		var leader_yaw: float = yaw if marker.has_method("get_facing_yaw") else (leader as Node3D).rotation.y
		var offset: Vector3 = get_party_offset(i, leader_yaw)
		var target: Vector3 = (leader as Node3D).global_position + offset
		await place_player_safely_on_ground(companion as CharacterBody3D, target, tree)
		companion.rotation.y = leader.rotation.y
		if GameManager.is_local_coop() and companion.has_method("is_alive") and not companion.is_alive():
			GameManager.revive_player(companion, 0.45)
