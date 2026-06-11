class_name MinimapControl
extends Control
## Circular minimap canvas — terrain, markers, player, compass ring.

const REF_INNER_SIZE := 268.0

var _player: Node3D = null
var _markers: Array[Dictionary] = []
var _display_yaw: float = 0.0
var _smooth_player_map: Vector2 = Vector2.ZERO
var _has_smooth: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	refresh_markers()


func bind_player(player: Node3D) -> void:
	_player = player
	_has_smooth = false


func refresh_markers() -> void:
	_markers = MinimapMarkerService.collect_markers(get_tree())


func refresh_landmarks() -> void:
	refresh_markers()


func get_markers() -> Array[Dictionary]:
	return _markers


func get_ui_scale() -> float:
	if size.x <= 0.0 or size.y <= 0.0:
		return 0.5
	return minf(size.x, size.y) / REF_INNER_SIZE


func _process(delta: float) -> void:
	if _player and is_instance_valid(_player):
		var forward := -_player.global_transform.basis.z
		var target_yaw := atan2(forward.x, forward.z)
		_display_yaw = lerp_angle(_display_yaw, target_yaw, clampf(delta * 8.0, 0.0, 1.0))
	queue_redraw()


func _draw() -> void:
	var ui_scale := get_ui_scale()
	var margin := 6.0 * ui_scale
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.5 - margin
	if radius <= 8.0 * ui_scale:
		return

	var region_id := GameManager.current_region_id
	var layout := MapManager.get_region_layout(region_id)
	var island_r: float = float(layout.get("radius", 28.0))
	var view_r := island_r * MinimapSettings.world_view_radius_scale
	if MinimapSettings.minimap_world_radius > 0.0:
		view_r = minf(view_r, MinimapSettings.minimap_world_radius)
	var map_scale := radius / maxf(view_r, 1.0)
	var land_r := radius * 0.92
	var map_rotation := 0.0
	if MinimapSettings.rotation_mode == MinimapSettings.MinimapRotationMode.ROTATE_WITH_PLAYER:
		map_rotation = -_display_yaw

	draw_circle(center, radius + 1.5 * ui_scale, Color(0.02, 0.03, 0.04, 0.65))
	draw_circle(center, radius, UiColors.MAP_WATER)
	draw_circle(center, land_r, UiColors.MAP_LAND)
	draw_arc(center, land_r, 0.0, TAU, 96, Color(0.10, 0.18, 0.09, 0.85), maxf(1.0, 2.0 * ui_scale))

	if MinimapSettings.fog_of_war_enabled:
		draw_circle(center, land_r, Color(0.04, 0.05, 0.06, 0.42))

	var trail_half := 1.5 * ui_scale
	var trail_sz := 3.0 * ui_scale
	for pos in MapManager.get_trail_markers(region_id):
		var mp := _world_to_map(pos, center, map_scale, map_rotation)
		if mp.distance_to(center) <= land_r:
			draw_rect(Rect2(mp - Vector2(trail_half, trail_half), Vector2(trail_sz, trail_sz)), Color(0.38, 0.34, 0.28, 0.55))

	var cell_half := 2.0 * ui_scale
	var cell_sz := 4.0 * ui_scale
	var cells: Array = MapManager.explored_cells.get(region_id, [])
	var cell_size := MapManager.CELL_SIZE
	for key in cells:
		var parts: PackedStringArray = String(key).split(",")
		if parts.size() < 2:
			continue
		var wx := float(parts[0]) * cell_size + cell_size * 0.5
		var wz := float(parts[1]) * cell_size + cell_size * 0.5
		var mp := _world_to_map(Vector3(wx, 0.0, wz), center, map_scale, map_rotation)
		if mp.distance_to(center) <= land_r:
			draw_rect(Rect2(mp - Vector2(cell_half, cell_half), Vector2(cell_sz, cell_sz)), Color(0.28, 0.5, 0.22, 0.45))

	for m in _markers:
		if m.get("edge", false):
			continue
		var cat: int = int(m.get("category", MinimapRegistry.Category.UNKNOWN))
		if cat == MinimapRegistry.Category.PLAYER:
			continue
		var pos: Vector3 = m.get("pos", Vector3.ZERO)
		var mp := _world_to_map(pos, center, map_scale, map_rotation)
		if mp.distance_to(center) > land_r - 2.0 * ui_scale:
			continue
		var def := MinimapRegistry.get_def(cat)
		if bool(def.get("undiscovered", false)) and m.get("source") != "dev_test":
			if not MapManager.is_cell_explored(pos, region_id):
				continue
		MinimapIconRegistry.draw_marker(self, mp, cat, ui_scale)

	if _player and is_instance_valid(_player):
		var pp := _world_to_map(_player.global_position, center, map_scale, map_rotation)
		if not _has_smooth:
			_smooth_player_map = pp
			_has_smooth = true
		else:
			_smooth_player_map = _smooth_player_map.lerp(pp, 0.35)
		if _smooth_player_map.distance_to(center) <= land_r:
			var arrow_yaw := 0.0 if MinimapSettings.rotation_mode == MinimapSettings.MinimapRotationMode.ROTATE_WITH_PLAYER else _display_yaw
			MinimapIconRegistry.draw_player_arrow(self, _smooth_player_map, arrow_yaw, 8.0 * ui_scale)

	draw_arc(center, land_r * 0.98, -0.6, 0.6, 24, Color(1, 1, 1, 0.04), maxf(1.5, 3.0 * ui_scale))
	draw_arc(center, radius, 0.0, TAU, 96, UiColors.BORDER_BRONZE, maxf(1.0, 2.0 * ui_scale))
	draw_arc(center, radius - 1.0 * ui_scale, 0.0, TAU, 96, Color(0.04, 0.05, 0.06, 0.55), maxf(0.5, 1.0 * ui_scale))

	_draw_compass(center, radius, map_rotation, ui_scale)


func world_to_map_point(world: Vector3) -> Vector2:
	var ui_scale := get_ui_scale()
	var margin := 6.0 * ui_scale
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.5 - margin
	var island_r: float = float(MapManager.get_region_layout(GameManager.current_region_id).get("radius", 28.0))
	var view_r := island_r * MinimapSettings.world_view_radius_scale
	var map_scale := radius / maxf(view_r, 1.0)
	var rot := -_display_yaw if MinimapSettings.rotation_mode == MinimapSettings.MinimapRotationMode.ROTATE_WITH_PLAYER else 0.0
	return _world_to_map(world, center, map_scale, rot)


func get_land_radius() -> float:
	var ui_scale := get_ui_scale()
	return minf(size.x, size.y) * 0.5 - 6.0 * ui_scale - 2.0 * ui_scale


func get_map_center() -> Vector2:
	return size * 0.5


func _world_to_map(world: Vector3, center: Vector2, scale: float, rotation_rad: float) -> Vector2:
	var flat := Vector2(world.x, world.z) * scale
	if absf(rotation_rad) > 0.001:
		flat = flat.rotated(rotation_rad)
	return center + flat


func _draw_compass(center: Vector2, radius: float, map_rotation: float, ui_scale: float) -> void:
	var font := ThemeDB.fallback_font
	if font == null:
		return
	var labels := ["N", "E", "S", "W"]
	var angles := [0.0, PI * 0.5, PI, PI * 1.5]
	var font_sz := maxi(8, int(round(10.0 * ui_scale)))
	var label_offset := 4.0 * ui_scale
	var ring_inset := 10.0 * ui_scale
	for i in labels.size():
		var ang: float = angles[i] + map_rotation
		var pos := center + Vector2(sin(ang), -cos(ang)) * (radius - ring_inset)
		draw_string(font, pos + Vector2(-label_offset, label_offset), labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1, font_sz, UiColors.TEXT_MUTED)
