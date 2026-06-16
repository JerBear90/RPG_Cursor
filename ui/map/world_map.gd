extends Control
class_name WorldMapPanel
## Functional world/region map — regions, danger, icons, players.

const _MapCanvas := preload("res://ui/map/map_canvas.gd")
const _MapIcon := preload("res://scripts/navigation/map_icon.gd")
const _MapRegionData := preload("res://scripts/navigation/map_region_data.gd")

@onready var _title: Label = %MapTitle
@onready var _region_list: ItemList = %RegionList
@onready var _legend: VBoxContainer = %Legend
@onready var _detail: Label = %RegionDetail
@onready var _canvas_host: Control = %MapCanvasHost

var _canvas: Control
var _view_region_id: String = ""


func _ready() -> void:
	ArpgTheme.apply_to(self)
	if _title:
		ArpgTheme.style_label(_title, UiMetrics.FONT_LG, UiColors.TEXT_QUEST)
	if _detail:
		ArpgTheme.style_label(_detail, UiMetrics.FONT_SM, UiColors.TEXT_SECONDARY)
	_populate_legend()
	if _canvas_host:
		_canvas = _MapCanvas.new()
		_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
		_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_canvas_host.add_child(_canvas)
	if _region_list:
		_region_list.item_selected.connect(_on_region_selected)


func refresh() -> void:
	if _region_list == null:
		return
	_region_list.clear()
	for region_id in MapManager.regions.keys():
		var state: int = MapManager.regions[region_id]
		if state == MapManager.RegionState.UNDISCOVERED:
			continue
		var summary := _MapRegionData.get_region_summary(region_id)
		var state_name := _MapRegionData.get_state_label(state)
		var idx := _region_list.add_item("%s — %s" % [summary, state_name])
		_region_list.set_item_metadata(idx, region_id)
	if _view_region_id == "" or MapManager.get_region_state(_view_region_id) == MapManager.RegionState.UNDISCOVERED:
		_view_region_id = GameManager.current_region_id
	var select_idx := 0
	for i in _region_list.item_count:
		if str(_region_list.get_item_metadata(i)) == _view_region_id:
			select_idx = i
			break
	if _region_list.item_count > 0:
		_region_list.select(select_idx)
		_on_region_selected(select_idx)


func _on_region_selected(index: int) -> void:
	var rid: Variant = _region_list.get_item_metadata(index)
	if rid == null:
		return
	_view_region_id = str(rid)
	if _canvas:
		_canvas.set_region(_view_region_id)
	if _detail:
		var data: Dictionary = _MapRegionData.REGIONS.get(_view_region_id, {})
		var hint := str(data.get("hint", ""))
		var waystone := "Waystone: discovered" if _view_region_id in WaystoneManager.discovered else "Waystone: locked"
		_detail.text = "%s\n%s" % [hint, waystone]


func _populate_legend() -> void:
	if _legend == null:
		return
	for child in _legend.get_children():
		child.queue_free()
	var entries := [
		[_MapIcon.IconType.PLAYER_P1, "Player 1"],
		[_MapIcon.IconType.PLAYER_P2, "Player 2"],
		[_MapIcon.IconType.PET, "Pet"],
		[_MapIcon.IconType.OBJECTIVE_ACTIVE, "Objective"],
		[_MapIcon.IconType.MISSION_TURN_IN, "Turn In"],
		[_MapIcon.IconType.WAYSTONE, "Waystone"],
		[_MapIcon.IconType.BOSS, "Boss"],
		[_MapIcon.IconType.REGION_EXIT, "Exit"],
	]
	for entry in entries:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var swatch := ColorRect.new()
		swatch.custom_minimum_size = Vector2(10, 10)
		swatch.color = _MapIcon.get_color(entry[0])
		row.add_child(swatch)
		var lbl := Label.new()
		lbl.text = entry[1]
		ArpgTheme.style_label(lbl, UiMetrics.FONT_META, UiColors.TEXT_SECONDARY)
		row.add_child(lbl)
		_legend.add_child(row)
