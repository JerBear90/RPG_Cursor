extends Control
class_name WorldMapPanel
## Themed world map overlay — preserves MapManager data.

@onready var _title: Label = %MapTitle
@onready var _region_list: ItemList = %RegionList
@onready var _legend: VBoxContainer = %Legend


func _ready() -> void:
	ArpgTheme.apply_to(self)
	if _title:
		ArpgTheme.style_label(_title, UiMetrics.FONT_LG, UiColors.TEXT_QUEST)
	_populate_legend()


func refresh() -> void:
	if _region_list == null:
		return
	_region_list.clear()
	for region_id in MapManager.regions.keys():
		var label := region_id.replace("_", " ").capitalize()
		_region_list.add_item(label)


func _populate_legend() -> void:
	if _legend == null:
		return
	for child in _legend.get_children():
		child.queue_free()
	var entries := [
		["Player", UiColors.TEXT_PRIMARY],
		["Quest", UiColors.TEXT_QUEST],
		["Waystone", UiColors.MANA_FILL],
		["Building", UiColors.TEXT_SECONDARY],
	]
	for entry in entries:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var swatch := ColorRect.new()
		swatch.custom_minimum_size = Vector2(10, 10)
		swatch.color = entry[1]
		row.add_child(swatch)
		var lbl := Label.new()
		lbl.text = entry[0]
		ArpgTheme.style_label(lbl, UiMetrics.FONT_XS, UiColors.TEXT_SECONDARY)
		row.add_child(lbl)
		_legend.add_child(row)
