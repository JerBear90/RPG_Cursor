class_name MinimapIconRegistry
extends RefCounted
## Draw helpers for minimap marker shapes — original procedural icons.


static func draw_marker(canvas: Control, pos: Vector2, category: MinimapRegistry.Category, scale: float = 1.0) -> void:
	var def := MinimapRegistry.get_def(category)
	var color: Color = def.get("color", UiColors.TEXT_SECONDARY)
	var sz: float = float(def.get("size", 4.0)) * scale
	match str(def.get("shape", "circle")):
		"diamond":
			_draw_diamond(canvas, pos, sz, color)
		"square":
			canvas.draw_rect(Rect2(pos - Vector2(sz * 0.5, sz * 0.4), Vector2(sz, sz * 0.8)), color)
		"triangle":
			var tri := PackedVector2Array([
				pos + Vector2(0, -sz),
				pos + Vector2(sz * 0.7, sz * 0.5),
				pos + Vector2(-sz * 0.7, sz * 0.5),
			])
			canvas.draw_colored_polygon(tri, color)
		"pin":
			canvas.draw_circle(pos + Vector2(0, sz * 0.15), sz * 0.45, color)
			var pin := PackedVector2Array([
				pos + Vector2(0, -sz),
				pos + Vector2(sz * 0.35, sz * 0.2),
				pos + Vector2(-sz * 0.35, sz * 0.2),
			])
			canvas.draw_colored_polygon(pin, color)
		"arrow":
			_draw_arrow(canvas, pos, 0.0, sz, color)
		"dot":
			canvas.draw_circle(pos, sz * 0.35, color)
		_:
			canvas.draw_circle(pos, sz * 0.45, color)


static func draw_player_arrow(canvas: Control, pos: Vector2, yaw: float, size: float = 8.0) -> void:
	_draw_arrow(canvas, pos, yaw, size, Color(0.95, 0.95, 0.98, 1.0), Color(0.08, 0.10, 0.14, 1.0))


static func _draw_diamond(canvas: Control, pos: Vector2, sz: float, color: Color) -> void:
	var diamond := PackedVector2Array([
		pos + Vector2(0, -sz),
		pos + Vector2(sz * 0.65, 0),
		pos + Vector2(0, sz),
		pos + Vector2(-sz * 0.65, 0),
	])
	canvas.draw_colored_polygon(diamond, color)
	canvas.draw_polyline(diamond + PackedVector2Array([diamond[0]]), UiColors.PANEL_BG_DEEP, 1.0)


static func _draw_arrow(canvas: Control, pos: Vector2, yaw: float, size: float, fill: Color, outline: Color = Color(0.08, 0.10, 0.14, 1.0)) -> void:
	var dir := Vector2(sin(yaw), -cos(yaw))
	var tip := pos + dir * size
	var back := pos - dir * size * 0.5
	var wing := Vector2(-dir.y, dir.x) * size * 0.55
	var tri := PackedVector2Array([tip, back + wing, back - wing])
	canvas.draw_colored_polygon(tri, fill)
	canvas.draw_polyline(tri + PackedVector2Array([tri[0]]), outline, 1.5)
