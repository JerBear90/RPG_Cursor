extends PanelContainer
class_name QuestTrackerPanel
## Upper-right quest panel — hides when empty, grows leftward.

@onready var _type: Label = %CategoryLabel
@onready var _title: Label = %QuestTitleLabel
@onready var _objective: Label = %ObjectiveLabel
@onready var _progress_row: HBoxContainer = %ProgressDistanceRow
@onready var _progress: Label = %ProgressLabel
@onready var _distance: Label = %DistanceLabel
@onready var _hint: Label = %HintLabel


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_horizontal = Control.SIZE_SHRINK_END
	custom_minimum_size = Vector2(UiMetrics.MINIMAP_SIZE, 0)
	add_theme_stylebox_override("panel", ArpgTheme.make_panel())
	ArpgTheme.style_label(_type, UiMetrics.FONT_META, UiColors.TEXT_QUEST)
	ArpgTheme.style_label(_title, UiMetrics.FONT_LG, UiColors.TEXT_PRIMARY)
	ArpgTheme.style_label(_objective, UiMetrics.FONT_SM, UiColors.TEXT_SECONDARY)
	ArpgTheme.style_label(_progress, UiMetrics.FONT_META, UiColors.TEXT_MUTED)
	ArpgTheme.style_label(_distance, UiMetrics.FONT_META, UiColors.TEXT_QUEST)
	if _hint:
		ArpgTheme.style_label(_hint, UiMetrics.FONT_META, UiColors.TEXT_MUTED)
	visible = false


func set_quest(
	quest_type: String,
	title: String,
	objective_text: String,
	progress_text: String = "",
	distance_text: String = ""
) -> void:
	if title.is_empty():
		clear()
		return
	visible = true
	if _type:
		_type.text = quest_type if quest_type != "" else "QUEST"
	if _title:
		_title.text = "Tracked: %s" % title
	var show_objective := should_show_objective(title, objective_text)
	if _objective:
		_objective.text = objective_text if show_objective else ""
		_objective.visible = show_objective
	var has_progress := progress_text != ""
	var has_distance := distance_text != ""
	if _progress_row:
		_progress_row.visible = has_progress or has_distance
	if _progress:
		_progress.visible = has_progress
		_progress.text = progress_text
	if _distance:
		_distance.visible = has_distance
		_distance.text = distance_text
	if _hint:
		_hint.visible = true
		_hint.text = "View: Map | D-pad: Cycle Mission"


func clear() -> void:
	visible = false
	if _title:
		_title.text = ""
	if _objective:
		_objective.text = ""
		_objective.visible = false
	if _progress_row:
		_progress_row.visible = false
	if _progress:
		_progress.visible = false
	if _distance:
		_distance.visible = false
	if _hint:
		_hint.visible = false


func set_from_objective_lines(title: String, lines: PackedStringArray, distance_text: String = "", quest_type: String = "QUEST") -> void:
	var objective := ""
	var progress := ""
	for line in lines:
		if line.begins_with("✓"):
			continue
		var stripped := line.replace("• ", "").replace("✓ ", "").strip_edges()
		var parsed := _parse_objective_line(stripped)
		if parsed.description != "" and objective == "":
			objective = parsed.description
		if parsed.progress != "":
			progress = parsed.progress
	if objective.is_empty() and lines.size() > 0:
		var fallback := lines[0].replace("• ", "").replace("✓ ", "").strip_edges()
		var parsed := _parse_objective_line(fallback)
		objective = parsed.description
		if progress == "":
			progress = parsed.progress
	set_quest(quest_type, title, objective, progress, distance_text)


static func should_show_objective(title: String, objective: String) -> bool:
	if objective.strip_edges().is_empty():
		return false
	return normalize_quest_text(title) != normalize_quest_text(objective)


static func normalize_quest_text(value: String) -> String:
	var normalized := value.strip_edges().to_lower()
	normalized = remove_progress_suffix(normalized)
	normalized = normalized.replace("the ", "")
	normalized = normalized.replace("_", " ")
	while normalized.contains("  "):
		normalized = normalized.replace("  ", " ")
	return normalized.strip_edges()


static func remove_progress_suffix(value: String) -> String:
	var idx := value.rfind("(")
	if idx >= 0 and value.ends_with(")"):
		return value.substr(0, idx).strip_edges()
	return value


static func _parse_objective_line(stripped: String) -> Dictionary:
	var description := stripped
	var progress := ""
	var open_idx := stripped.rfind("(")
	if open_idx >= 0 and stripped.ends_with(")"):
		var inner := stripped.substr(open_idx + 1, stripped.length() - open_idx - 2).strip_edges()
		description = stripped.substr(0, open_idx).strip_edges()
		if inner.contains("/"):
			var parts := inner.split("/")
			if parts.size() >= 2:
				progress = "%s / %s" % [parts[0].strip_edges(), parts[1].strip_edges()]
	return {"description": description, "progress": progress}
