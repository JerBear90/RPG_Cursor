@tool
extends Control
class_name OrbMeter
## Circular health / mana orb drawn with _draw (no square texture artifacts).

@export var fill_color: Color = Color(0.78, 0.16, 0.14, 0.95)
@export var track_color: Color = Color(0.12, 0.1, 0.14, 0.92)
@export var ring_color: Color = Color(0.82, 0.68, 0.32, 0.95)
@export var inner_glow: Color = Color(0, 0, 0, 0.35)

var value: float = 100.0
var max_value: float = 100.0


func _ready() -> void:
	custom_minimum_size = Vector2(80, 80)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func set_values(current: float, maximum: float) -> void:
	value = current
	max_value = maximum
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.5 - 10.0
	if radius <= 4.0:
		return
	# Outer gold ring
	draw_arc(center, radius + 7.0, 0.0, TAU, 72, ring_color, 2.5, true)
	# Track disk
	draw_circle(center, radius, track_color)
	draw_circle(center, radius - 3.0, inner_glow)
	# Fill wedge (starts at top, clockwise)
	var pct := clampf(value / max_value, 0.0, 1.0) if max_value > 0.0 else 0.0
	if pct > 0.001:
		_draw_wedge(center, radius - 2.0, pct, fill_color)
	# Inner highlight ring
	draw_arc(center, radius - 5.0, 0.0, TAU, 48, Color(1, 1, 1, 0.08), 1.0, true)


func _draw_wedge(center: Vector2, radius: float, pct: float, color: Color) -> void:
	var segments := maxi(24, int(64 * pct))
	var points := PackedVector2Array()
	points.append(center)
	var start := -PI * 0.5
	var end := start + TAU * pct
	for i in segments + 1:
		var t := start + (end - start) * float(i) / float(segments)
		points.append(center + Vector2(cos(t), sin(t)) * radius)
	draw_colored_polygon(points, color)
