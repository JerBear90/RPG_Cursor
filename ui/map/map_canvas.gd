extends Control
class_name MapCanvas
## Simple region map canvas — draws layout, icons, and players.

const _MapIcon := preload("res://scripts/navigation/map_icon.gd")
const _MapRegionData := preload("res://scripts/navigation/map_region_data.gd")

var region_id: String = ""
var _icons: Array[Dictionary] = []


func set_region(new_region_id: String) -> void:
	region_id = new_region_id
	_icons = ObjectiveRouter.collect_map_icons(get_tree(), region_id)
	queue_redraw()


func _draw() -> void:
	var rect := get_local_bounding_rect()
	var center := rect.get_center()
	var radius := minf(rect.size.x, rect.size.y) * 0.42
	draw_circle(center, radius, Color(0.08, 0.1, 0.12, 0.95))
	draw_arc(center, radius, 0.0, TAU, 64, Color(0.35, 0.32, 0.28, 0.9), 2.0)
	var layout := MapManager.get_region_layout(region_id)
	var world_r := float(layout.get("radius", 28.0))
	var scale := radius / maxf(world_r, 1.0)
	for icon in _icons:
		var pos: Vector3 = icon.get("position", Vector3.ZERO)
		var mp := center + Vector2(pos.x, pos.z) * scale
		var col: Color = icon.get("color", Color.WHITE)
		var r := 5.0 if int(icon.get("icon_type", 0)) in [_MapIcon.IconType.PLAYER_P1, _MapIcon.IconType.PLAYER_P2] else 4.0
		draw_circle(mp, r, col)
		if int(icon.get("icon_type", -1)) == _MapIcon.IconType.OBJECTIVE_ACTIVE:
			draw_arc(mp, r + 3.0, 0.0, TAU, 24, Color(1.0, 0.85, 0.25, 0.8), 1.5)
	var state := MapManager.get_region_state(region_id)
	var label := _MapRegionData.get_region_summary(region_id)
	var state_label := _MapRegionData.get_state_label(state)
	draw_string(ThemeDB.fallback_font, Vector2(8, 18), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.9, 0.88, 0.82))
	draw_string(ThemeDB.fallback_font, Vector2(8, 36), state_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.65, 0.65, 0.7))
