class_name WorldMapData
extends RefCounted
## Read-only facade over MapManager for minimap and future world map UI.


static func get_region_id() -> String:
	return GameManager.current_region_id


static func get_region_layout(region_id: String = "") -> Dictionary:
	var rid := region_id if region_id != "" else get_region_id()
	return MapManager.get_region_layout(rid)


static func get_island_radius(region_id: String = "") -> float:
	return MapManager.get_region_radius(region_id if region_id != "" else get_region_id())


static func get_building_markers(region_id: String = "") -> Array[Vector3]:
	return MapManager.get_building_markers(region_id if region_id != "" else get_region_id())


static func get_trail_markers(region_id: String = "") -> Array[Vector3]:
	return MapManager.get_trail_markers(region_id if region_id != "" else get_region_id())


static func get_discovered_locations(region_id: String = "") -> Array[Dictionary]:
	return MapManager.get_discovered_locations_for_region(region_id if region_id != "" else get_region_id())


static func has_waypoint() -> bool:
	return MapManager.has_waypoint()


static func get_waypoint() -> Vector3:
	return MapManager.get_waypoint_position()


static func get_waypoint_label() -> String:
	return MapManager.get_waypoint_label()


static func is_cell_explored(world_pos: Vector3, region_id: String = "") -> bool:
	return MapManager.is_cell_explored(world_pos, region_id if region_id != "" else get_region_id())
