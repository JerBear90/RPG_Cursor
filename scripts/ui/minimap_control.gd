class_name MinimapControl
extends Control
## Circular minimap: island terrain, buildings, quest marker, player heading.

const MARGIN := 5.0

var _player: Node3D = null
var _landmarks: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	refresh_landmarks()


func bind_player(player: Node3D) -> void:
	_player = player


func refresh_landmarks() -> void:
	_landmarks.clear()
	var region_id := GameManager.current_region_id
	for pos in MapManager.get_building_markers(region_id):
		_landmarks.append({"type": "building", "pos": pos})
	for node in get_tree().get_nodes_in_group("quest_destination"):
		if node is Node3D:
			_landmarks.append({"type": "quest", "pos": (node as Node3D).global_position})
	for node in get_tree().get_nodes_in_group("waystone"):
		if node is Node3D:
			_landmarks.append({"type": "waystone", "pos": (node as Node3D).global_position})
	for icon in MapManager.icons:
		_landmarks.append({
			"type": str(icon.get("type", "icon")),
			"pos": Vector3(float(icon.position.x), 0.0, float(icon.position.y)),
		})


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.5 - MARGIN
	if radius <= 8.0:
		return

	var layout := MapManager.get_region_layout(GameManager.current_region_id)
	var island_r: float = float(layout.get("radius", 28.0))
	var map_scale := radius / island_r

	# Water ring
	draw_circle(center, radius, Color(0.06, 0.14, 0.28, 0.98))
	# Land mass
	var land_r := radius * 0.9
	draw_circle(center, land_r, Color(0.18, 0.36, 0.16, 1.0))
	draw_arc(center, land_r, 0.0, TAU, 96, Color(0.12, 0.26, 0.11, 0.85), 2.0)

	# Explored trail (fog-of-war cells)
	var region_id := GameManager.current_region_id
	var cells: Array = MapManager.explored_cells.get(region_id, [])
	var cell_size := MapManager.CELL_SIZE
	for key in cells:
		var parts: PackedStringArray = String(key).split(",")
		if parts.size() < 2:
			continue
		var wx := float(parts[0]) * cell_size + cell_size * 0.5
		var wz := float(parts[1]) * cell_size + cell_size * 0.5
		var mp := _world_to_map(Vector3(wx, 0.0, wz), center, map_scale)
		if mp.distance_to(center) <= land_r:
			draw_rect(Rect2(mp - Vector2(2.5, 2.5), Vector2(5.0, 5.0)), Color(0.28, 0.5, 0.22, 0.55))

	# Paths / buildings
	for lm in _landmarks:
		var pos: Vector3 = lm.pos
		var mp := _world_to_map(pos, center, map_scale)
		if mp.distance_to(center) > land_r - 2.0:
			continue
		match lm.type:
			"quest":
				_draw_quest_marker(mp)
			"waystone":
				draw_circle(mp, 3.0, Color(0.35, 0.75, 0.95, 0.95))
			"building":
				draw_rect(Rect2(mp - Vector2(2.5, 2.0), Vector2(5.0, 4.0)), Color(0.55, 0.48, 0.38, 0.95))
			_:
				draw_circle(mp, 2.0, Color(0.7, 0.7, 0.75, 0.85))

	if _player and is_instance_valid(_player):
		var pp := _world_to_map(_player.global_position, center, map_scale)
		if pp.distance_to(center) <= land_r:
			var forward := -_player.global_transform.basis.z
			var yaw := atan2(forward.x, forward.z)
			_draw_player_arrow(pp, yaw)

	# Gold compass ring
	draw_arc(center, radius, 0.0, TAU, 96, Color(0.78, 0.62, 0.28, 0.95), 2.5)
	var font := ThemeDB.fallback_font
	if font:
		draw_string(font, center + Vector2(-4.0, -radius + 12.0), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.92, 0.88, 0.75))


func _world_to_map(world: Vector3, center: Vector2, scale: float) -> Vector2:
	return center + Vector2(world.x, world.z) * scale


func _draw_quest_marker(pos: Vector2) -> void:
	var diamond := PackedVector2Array([
		pos + Vector2(0.0, -6.0),
		pos + Vector2(5.0, 0.0),
		pos + Vector2(0.0, 6.0),
		pos + Vector2(-5.0, 0.0),
	])
	draw_colored_polygon(diamond, Color(0.95, 0.82, 0.22, 1.0))
	draw_polyline(diamond + PackedVector2Array([diamond[0]]), Color(0.35, 0.25, 0.05, 1.0), 1.0)


func _draw_player_arrow(pos: Vector2, yaw: float) -> void:
	var dir := Vector2(sin(yaw), cos(yaw))
	var tip := pos + dir * 8.0
	var back := pos - dir * 4.0
	var wing := Vector2(-dir.y, dir.x) * 4.5
	var tri := PackedVector2Array([tip, back + wing, back - wing])
	draw_colored_polygon(tri, Color(0.95, 0.95, 0.98, 1.0))
	draw_polyline(tri + PackedVector2Array([tri[0]]), Color(0.08, 0.1, 0.14, 1.0), 1.5)
