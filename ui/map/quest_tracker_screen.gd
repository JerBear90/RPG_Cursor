extends PanelContainer
class_name QuestTrackerScreen
## Full-screen quest tracker — mission list, status, rewards, track/clear.

const NpcMissionRegistry := preload("res://scripts/autoload/npc_mission_registry.gd")

signal closed
signal open_map_requested

@onready var _title: Label = %ScreenTitle
@onready var _mission_list: ItemList = %MissionList
@onready var _detail: RichTextLabel = %DetailText
@onready var _footer: Label = %FooterHint

var _entries: Array[String] = []


func _ready() -> void:
	ArpgTheme.apply_to(self)
	add_theme_stylebox_override("panel", ArpgTheme.make_panel())
	if _title:
		ArpgTheme.style_label(_title, UiMetrics.FONT_LG, UiColors.TEXT_QUEST)
	if _footer:
		ArpgTheme.style_label(_footer, UiMetrics.FONT_META, UiColors.TEXT_MUTED)
	if _mission_list:
		_mission_list.item_selected.connect(_on_item_selected)


func refresh() -> void:
	if _mission_list == null:
		return
	_mission_list.clear()
	_entries.clear()
	for quest_id in QuestManager.get_active_quest_list():
		_add_entry(quest_id)
	for quest_id in NpcMissionRegistry.MISSIONS.keys():
		if quest_id not in QuestManager.completed_quests and not QuestManager.active_quests.has(quest_id):
			_add_entry(str(quest_id))
	for quest_id in QuestManager.completed_quests:
		if quest_id in NpcMissionRegistry.MISSIONS:
			_add_entry(quest_id)
	if _entries.is_empty():
		_mission_list.add_item("(No missions)")
		_set_detail("(No active missions)")
		return
	var track_idx := _entries.find(QuestManager.tracked_quest_id)
	if track_idx >= 0:
		_mission_list.select(track_idx)
		_on_item_selected(track_idx)
	elif _entries.size() > 0:
		_mission_list.select(0)
		_on_item_selected(0)


func _add_entry(quest_id: String) -> void:
	var status := QuestManager.get_quest_status(quest_id)
	var title := quest_id
	if quest_id in NpcMissionRegistry.MISSIONS:
		title = NpcMissionRegistry.get_mission_title(quest_id)
	else:
		title = quest_id.replace("_", " ").capitalize()
	var prefix := "> " if quest_id == QuestManager.tracked_quest_id else "  "
	var idx := _mission_list.add_item("%s%s — [%s]" % [prefix, title, status])
	_mission_list.set_item_metadata(idx, quest_id)
	_entries.append(quest_id)


func _on_item_selected(index: int) -> void:
	if index < 0 or index >= _entries.size():
		return
	var quest_id: String = _entries[index]
	var lines: PackedStringArray = []
	lines.append("[b]%s[/b]" % (NpcMissionRegistry.get_mission_title(quest_id) if quest_id in NpcMissionRegistry.MISSIONS else quest_id.replace("_", " ").capitalize()))
	lines.append("Status: %s" % QuestManager.get_quest_status(quest_id))
	var giver := QuestManager.get_giver_npc_id(quest_id)
	if giver != "":
		lines.append("NPC: %s" % giver.replace("_", " ").capitalize())
	lines.append("Reward: %s" % QuestManager.get_reward_preview_text(quest_id))
	if QuestManager.active_quests.has(quest_id):
		lines.append("")
		lines.append("Objectives:")
		for obj in QuestManager.active_quests[quest_id]:
			var mark := "✓" if obj.completed else "•"
			var prog := "" if obj.completed else " (%d/%d)" % [obj.current, obj.target]
			lines.append("  %s %s%s" % [mark, obj.description, prog])
	elif quest_id in QuestManager.completed_quests:
		lines.append("")
		lines.append("Completed.")
	else:
		lines.append("")
		lines.append("Available at mission NPC.")
	var target := ObjectiveRouter.resolve_target(quest_id, str(QuestManager.get_current_objective(quest_id).get("id", "")), QuestManager.get_current_objective(quest_id))
	if target and target.region_hint != "":
		lines.append("Location: %s" % target.region_hint)
	_set_detail("\n".join(lines))


func _set_detail(text: String) -> void:
	if _detail:
		_detail.text = text


func get_selected_quest_id() -> String:
	var sel := _mission_list.get_selected_items()
	if sel.is_empty() or sel[0] >= _entries.size():
		return ""
	return _entries[sel[0]]


func handle_confirm() -> void:
	var qid := get_selected_quest_id()
	if qid == "":
		return
	if QuestManager.active_quests.has(qid):
		QuestManager.track_quest(qid)
		refresh()


func handle_clear_track() -> void:
	QuestManager.clear_tracked_quest()
	refresh()


func handle_open_map() -> void:
	open_map_requested.emit()
