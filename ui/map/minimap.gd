extends Control
class_name Minimap
## Top-right minimap widget — viewport canvas, compass, edge markers, distance readout.

const MarkerScene := preload("res://ui/map/minimap_marker.tscn")

@onready var _frame: PanelContainer = %MinimapFrame
@onready var _viewport: Control = %MinimapViewport
@onready var _canvas: MinimapControl = %MinimapCanvas
@onready var _marker_layer: Control = %MarkerLayer
@onready var _distance: Label = %DistanceReadout

var _edge_markers: Array[MinimapMarker] = []
var _marker_timer: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_scale_for_viewport()
	if _frame:
		_frame.add_theme_stylebox_override("panel", ArpgTheme.make_panel(UiColors.PANEL_BG_DEEP, UiColors.BORDER_BRONZE, UiMetrics.RADIUS_LG))
	if _distance:
		ArpgTheme.style_label(_distance, UiMetrics.FONT_META, UiColors.TEXT_QUEST)
		_distance.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_distance.visible = false
	if not get_viewport().size_changed.is_connected(_on_viewport_resized):
		get_viewport().size_changed.connect(_on_viewport_resized)
	if not MapManager.map_updated.is_connected(_on_map_updated):
		MapManager.map_updated.connect(_on_map_updated)
	if not QuestManager.tracked_quest_changed.is_connected(_on_quest_changed):
		QuestManager.tracked_quest_changed.connect(_on_quest_changed)
		QuestManager.quest_updated.connect(func(_id): _on_quest_changed(""))
	call_deferred("_refresh_all")


func bind_player(player: Node3D) -> void:
	if _canvas:
		_canvas.bind_player(player)


func refresh_landmarks() -> void:
	_refresh_all()


func _on_viewport_resized() -> void:
	_apply_scale_for_viewport()


func _apply_scale_for_viewport() -> void:
	var map_sz := UiMetrics.get_minimap_size(get_viewport_rect().size.x)
	var pad := float(UiMetrics.MINIMAP_FRAME_PAD)
	custom_minimum_size = Vector2(map_sz, UiMetrics.get_minimap_widget_height(get_viewport_rect().size.x))
	if _viewport:
		_viewport.custom_minimum_size = Vector2(map_sz - pad * 2.0, map_sz - pad * 2.0)


func _process(delta: float) -> void:
	_marker_timer += delta
	if _marker_timer >= MinimapSettings.marker_update_interval:
		_marker_timer = 0.0
		_update_edge_markers()
		_update_distance_readout()
		if _player_near_waypoint():
			MapManager.clear_waypoint()


func _on_map_updated(_region_id: String) -> void:
	_refresh_all()


func _on_quest_changed(_id: String = "") -> void:
	_refresh_all()


func _refresh_all() -> void:
	if _canvas:
		_canvas.refresh_markers()
	_update_edge_markers()
	_update_distance_readout()


func _ui_scale() -> float:
	if _canvas:
		return _canvas.get_ui_scale()
	return 0.5


func _update_edge_markers() -> void:
	if _canvas == null or _marker_layer == null:
		return
	var ui_scale := _ui_scale()
	var center := _canvas.get_map_center()
	var land_r := _canvas.get_land_radius()
	var edge_inset := 10.0 * ui_scale
	var marker_sz := maxf(14.0, 28.0 * ui_scale)
	var targets := _collect_edge_targets()
	while _edge_markers.size() < targets.size():
		var m := MarkerScene.instantiate() as MinimapMarker
		_marker_layer.add_child(m)
		_edge_markers.append(m)
	for i in _edge_markers.size():
		var marker := _edge_markers[i]
		if i >= targets.size():
			marker.visible = false
			continue
		var t: Dictionary = targets[i]
		var world: Vector3 = t.get("pos", Vector3.ZERO)
		var map_pos := _canvas.world_to_map_point(world)
		var to_target := map_pos - center
		var dist_world := _get_player_distance(world)
		var clamped := center
		if to_target.length() > land_r - edge_inset:
			clamped = center + to_target.normalized() * (land_r - edge_inset)
		marker.custom_minimum_size = Vector2(marker_sz, marker_sz)
		marker.visible = true
		marker.position = clamped - marker.size * 0.5
		marker.rotation = to_target.angle() + PI * 0.5
		marker.configure(int(t.get("category", MinimapRegistry.Category.TRACKED_OBJECTIVE)), "%d m" % int(dist_world), ui_scale)


func _collect_edge_targets() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if _canvas == null:
		return out
	var center := _canvas.get_map_center()
	var land_r := _canvas.get_land_radius()
	var on_map_inset := 12.0 * _ui_scale()
	for m in _canvas.get_markers():
		var cat: int = int(m.get("category", MinimapRegistry.Category.UNKNOWN))
		var def := MinimapRegistry.get_def(cat)
		if not bool(def.get("edge_clamp", false)):
			continue
		var pos: Vector3 = m.get("pos", Vector3.ZERO)
		var map_pos := _canvas.world_to_map_point(pos)
		if map_pos.distance_to(center) <= land_r - on_map_inset:
			continue
		out.append(m)
	out.sort_custom(func(a, b):
		var pa: int = MinimapRegistry.get_def(int(a.get("category"))).get("priority", 99)
		var pb: int = MinimapRegistry.get_def(int(b.get("category"))).get("priority", 99)
		return pa < pb
	)
	if out.size() > 3:
		out = out.slice(0, 3) as Array[Dictionary]
	return out


func _update_distance_readout() -> void:
	if _distance == null:
		return
	var player := _get_player()
	if player == null:
		_distance.visible = false
		return
	var target := MinimapMarkerService.get_tracked_objective_position(get_tree())
	if target == Vector3.ZERO:
		_distance.visible = false
		return
	var dist := player.global_position.distance_to(target)
	_distance.text = "%d m" % int(dist)
	_distance.visible = true
	if MapManager.has_waypoint():
		_distance.add_theme_color_override("font_color", UiColors.TEXT_WAYPOINT)
	else:
		_distance.add_theme_color_override("font_color", UiColors.TEXT_QUEST)


func _get_player_distance(world: Vector3) -> float:
	var player := _get_player()
	if player == null:
		return 0.0
	return player.global_position.distance_to(world)


func _get_player() -> Node3D:
	for node in get_tree().get_nodes_in_group("player"):
		if node is Node3D:
			return node as Node3D
	return null


func _player_near_waypoint() -> bool:
	var player := _get_player()
	if player == null or not MapManager.has_waypoint():
		return false
	return player.global_position.distance_to(MapManager.get_waypoint_position()) <= MinimapSettings.waypoint_reach_distance
