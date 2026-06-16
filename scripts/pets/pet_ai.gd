class_name PetAI
extends RefCounted
## Pet movement and target selection helpers.

static func get_party_center(tree: SceneTree) -> Vector3:
	var positions: Array[Vector3] = []
	for node in tree.get_nodes_in_group("player"):
		if is_instance_valid(node) and node is Node3D:
			positions.append((node as Node3D).global_position)
	if positions.is_empty():
		return Vector3.ZERO
	var sum := Vector3.ZERO
	for pos in positions:
		sum += pos
	return sum / float(positions.size())


static func find_nearest_enemy(origin: Vector3, tree: SceneTree, range_limit: float, ignore_downed: bool = true) -> Node3D:
	var nearest: Node3D = null
	var nearest_dist := range_limit
	for node in tree.get_nodes_in_group("lockable_enemy"):
		if not is_instance_valid(node):
			continue
		if ignore_downed and node.has_node("HealthComponent"):
			var health := node.get_node("HealthComponent") as HealthComponent
			if not health.is_alive():
				continue
		var dist := origin.distance_to(node.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = node
	return nearest


static func find_enemy_near_players(tree: SceneTree, radius: float) -> Node3D:
	for node in tree.get_nodes_in_group("player"):
		if not is_instance_valid(node):
			continue
		var target := find_nearest_enemy(node.global_position, tree, radius)
		if target:
			return target
	return null


static func steer_toward(current: Vector3, target: Vector3, speed: float, delta: float, stop_distance: float) -> Vector3:
	var to_target := target - current
	to_target.y = 0.0
	var dist := to_target.length()
	if dist <= stop_distance:
		return current
	var dir := to_target.normalized()
	return current + dir * speed * delta
