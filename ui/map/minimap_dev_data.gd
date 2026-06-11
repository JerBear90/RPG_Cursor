class_name MinimapDevData
extends RefCounted
## Isolated temporary test markers — debug builds only. Remove by setting MinimapSettings.use_dev_test_markers = false.

static func append_markers(out: Array[Dictionary], region_id: String) -> void:
	if not MinimapSettings.use_dev_test_markers or region_id != "darkpine_forest":
		return
	var entries := [
		{"category": MinimapRegistry.Category.TOWN, "pos": Vector3(-8, 0, 10), "label": "Darkpine Outpost"},
		{"category": MinimapRegistry.Category.MAIN_QUEST, "pos": Vector3(12, 0, -14), "label": "Corrupted Grove"},
		{"category": MinimapRegistry.Category.MERCHANT, "pos": Vector3(-3, 0, 6), "label": "Traveling Merchant"},
		{"category": MinimapRegistry.Category.CAMP, "pos": Vector3(5, 0, 8), "label": "Camp"},
		{"category": MinimapRegistry.Category.CAVE, "pos": Vector3(14, 0, 4), "label": "Cave Entrance"},
		{"category": MinimapRegistry.Category.FAST_TRAVEL, "pos": Vector3(-6, 0, -4), "label": "Waystone"},
		{"category": MinimapRegistry.Category.ENEMY, "pos": Vector3(8, 0, 2), "label": "Enemy A"},
		{"category": MinimapRegistry.Category.ENEMY, "pos": Vector3(-10, 0, -6), "label": "Enemy B"},
		{"category": MinimapRegistry.Category.WAYPOINT, "pos": Vector3(0, 0, 18), "label": "Dev Waypoint"},
	]
	for e in entries:
		out.append({
			"category": e.category,
			"pos": e.pos,
			"label": e.label,
			"source": "dev_test",
			"instance_id": -1,
		})
