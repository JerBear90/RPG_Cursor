class_name MinimapMarkerService
extends RefCounted
## Collects world markers from groups, MapManager, and quest state.


static func collect_markers(tree: SceneTree) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var region_id := GameManager.current_region_id
	_append_group_markers(tree, out)
	_append_buildings(out, region_id)
	_append_discovered(out, region_id)
	_append_waypoint(out)
	_append_enemies(tree, out)
	MinimapDevData.append_markers(out, region_id)
	_apply_quest_priority(out, tree)
	return out


static func _append_group_markers(tree: SceneTree, out: Array[Dictionary]) -> void:
	for group in MinimapRegistry.GROUP_TO_CATEGORY.keys():
		var cat: int = MinimapRegistry.GROUP_TO_CATEGORY[group]
		for node in tree.get_nodes_in_group(group):
			if not (node is Node3D) or not is_instance_valid(node):
				continue
			if node.is_in_group("player"):
				continue
			out.append({
				"category": cat,
				"pos": (node as Node3D).global_position,
				"label": node.name,
				"source": "group",
				"instance_id": node.get_instance_id(),
			})


static func _append_buildings(out: Array[Dictionary], region_id: String) -> void:
	for pos in MapManager.get_building_markers(region_id):
		out.append({
			"category": MinimapRegistry.Category.BUILDING,
			"pos": pos,
			"label": "",
			"source": "layout",
			"instance_id": -1,
		})


static func _append_discovered(out: Array[Dictionary], region_id: String) -> void:
	for entry in MapManager.get_discovered_locations_for_region(region_id):
		var cat_name := str(entry.get("category", "unknown"))
		var cat := _category_from_string(cat_name)
		out.append({
			"category": cat,
			"pos": entry.get("position", Vector3.ZERO),
			"label": str(entry.get("name", "")),
			"source": "discovery",
			"instance_id": -1,
		})


static func _append_waypoint(out: Array[Dictionary]) -> void:
	if MapManager.has_waypoint():
		out.append({
			"category": MinimapRegistry.Category.WAYPOINT,
			"pos": MapManager.get_waypoint_position(),
			"label": MapManager.get_waypoint_label(),
			"source": "waypoint",
			"instance_id": -1,
		})


static func _append_enemies(tree: SceneTree, out: Array[Dictionary]) -> void:
	var player := _get_player(tree)
	if player == null:
		return
	var in_combat := GameManager.in_combat
	for group in ["boss", "lockable_enemy", "enemy"]:
		var cat := MinimapRegistry.category_from_group(group)
		for node in tree.get_nodes_in_group(group):
			if not (node is Node3D) or not is_instance_valid(node):
				continue
			if node.has_node("HealthComponent"):
				var hp := node.get_node("HealthComponent")
				if hp.has_method("get") and hp.get("current_health") != null and float(hp.current_health) <= 0.0:
					continue
			var pos := (node as Node3D).global_position
			var dist := player.global_position.distance_to(pos)
			var max_dist: float = float(MinimapRegistry.get_def(cat).get("max_distance", 36.0))
			if dist > float(max_dist) and not in_combat:
				continue
			out.append({
				"category": cat,
				"pos": pos,
				"label": node.name,
				"source": "enemy",
				"instance_id": node.get_instance_id(),
			})


static func _apply_quest_priority(out: Array[Dictionary], tree: SceneTree) -> void:
	if QuestManager.tracked_quest_id == "":
		return
	for m in out:
		if m.get("source") == "group" and int(m.get("category")) == MinimapRegistry.Category.MAIN_QUEST:
			m["category"] = MinimapRegistry.Category.TRACKED_OBJECTIVE


static func _category_from_string(name: String) -> int:
	match name:
		"town": return MinimapRegistry.Category.TOWN
		"village": return MinimapRegistry.Category.VILLAGE
		"merchant": return MinimapRegistry.Category.MERCHANT
		"camp": return MinimapRegistry.Category.CAMP
		"fast_travel", "waystone": return MinimapRegistry.Category.FAST_TRAVEL
		"dungeon": return MinimapRegistry.Category.DUNGEON
		"cave": return MinimapRegistry.Category.CAVE
		_: return MinimapRegistry.Category.UNKNOWN


static func _get_player(tree: SceneTree) -> Node3D:
	for node in tree.get_nodes_in_group("player"):
		if node is Node3D:
			return node as Node3D
	return null


static func get_tracked_objective_position(tree: SceneTree) -> Vector3:
	return ObjectiveRouter.get_tracked_position(tree)
