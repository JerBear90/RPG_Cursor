extends PanelContainer
## Visual skill tree with node grid and stat allocation.

signal closed

const NODE_SIZE := Vector2(140, 72)

var _player: Node
var _canvas: Control
var _stat_row: HBoxContainer
var _points_label: Label
var _detail_label: Label
var _selected_node: String = ""


func _ready() -> void:
	custom_minimum_size = Vector2(760, 520)
	_build_ui()


func open(player: Node) -> void:
	_player = player
	_selected_node = ""
	_refresh()
	visible = true


func close() -> void:
	visible = false
	closed.emit()


func _build_ui() -> void:
	var root := VBoxContainer.new()
	add_child(root)
	_points_label = Label.new()
	_points_label.add_theme_font_size_override("font_size", 18)
	root.add_child(_points_label)
	_canvas = Control.new()
	_canvas.custom_minimum_size = Vector2(740, 340)
	_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_canvas.draw.connect(_draw_connections)
	root.add_child(_canvas)
	_stat_row = HBoxContainer.new()
	root.add_child(_stat_row)
	_detail_label = Label.new()
	_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_label.custom_minimum_size = Vector2(0, 72)
	root.add_child(_detail_label)
	var actions := HBoxContainer.new()
	root.add_child(actions)
	var unlock_btn := Button.new()
	unlock_btn.text = "Unlock / Rank Up"
	unlock_btn.pressed.connect(_on_unlock_pressed)
	actions.add_child(unlock_btn)
	var close_btn := Button.new()
	close_btn.text = "Close (B)"
	close_btn.pressed.connect(close)
	actions.add_child(close_btn)


func _refresh() -> void:
	for child in _canvas.get_children():
		child.queue_free()
	for child in _stat_row.get_children():
		child.queue_free()
	if _player == null or not _player.has_node("SkillTree"):
		_points_label.text = "No skill tree"
		return
	var tree := _player.get_node("SkillTree")
	var stats := _player.get_node("StatsComponent") as StatsComponent
	_points_label.text = "Skill Points: %d  |  Stat Points: %d  |  Lv %d" % [
		stats.unspent_skill_points, stats.unspent_stat_points, stats.level,
	]
	for node_id in tree.get_all_node_ids():
		_add_node_button(tree, node_id)
	if stats.unspent_stat_points > 0:
		for stat_name in ["strength", "vitality", "dexterity", "intelligence", "endurance", "spirit"]:
			var btn := Button.new()
			btn.text = "+1 %s (%d)" % [stat_name.capitalize(), _get_stat_value(stats, stat_name)]
			btn.pressed.connect(_on_stat_pressed.bind(stat_name))
			_stat_row.add_child(btn)
	_canvas.queue_redraw()
	_update_detail()


func _get_stat_value(stats: StatsComponent, stat_name: String) -> int:
	match stat_name:
		"strength": return stats.strength
		"vitality": return stats.vitality
		"dexterity": return stats.dexterity
		"intelligence": return stats.intelligence
		"endurance": return stats.endurance
		"spirit": return stats.spirit
	return 0


func _add_node_button(tree: Node, node_id: String) -> void:
	var layout: Dictionary = tree.get_node_layout(node_id)
	var pos: Vector2 = layout.get("pos", Vector2.ZERO)
	var data: Dictionary = tree.SKILL_NODES.get(node_id, {})
	var rank := tree.get_node_rank(node_id) if tree.has_method("get_node_rank") else (1 if node_id in tree.unlocked_nodes else 0)
	var max_r := int(data.get("max_rank", 1))
	var btn := Button.new()
	var prefix := "[%d/%d] " % [rank, max_r] if rank > 0 else "[ ] "
	btn.text = prefix + str(data.get("name", node_id))
	btn.position = pos
	btn.size = NODE_SIZE
	btn.toggle_mode = true
	btn.button_pressed = node_id == _selected_node
	btn.pressed.connect(_on_node_pressed.bind(node_id))
	_canvas.add_child(btn)


func _draw_connections() -> void:
	if _player == null or not _player.has_node("SkillTree"):
		return
	var tree := _player.get_node("SkillTree")
	for node_id in tree.get_all_node_ids():
		var layout: Dictionary = tree.get_node_layout(node_id)
		var requires: Array = layout.get("requires", [])
		var from_pos: Vector2 = layout.get("pos", Vector2.ZERO) + NODE_SIZE * 0.5
		for req in requires:
			var req_layout: Dictionary = tree.get_node_layout(str(req))
			var to_pos: Vector2 = req_layout.get("pos", Vector2.ZERO) + NODE_SIZE * 0.5
			var met := tree.get_node_rank(str(req)) > 0 if tree.has_method("get_node_rank") else str(req) in tree.unlocked_nodes
			var color := Color(0.4, 0.7, 0.9) if met else Color(0.3, 0.3, 0.35)
			_canvas.draw_line(from_pos, to_pos, color, 2.0)


func _on_node_pressed(node_id: String) -> void:
	_selected_node = node_id
	_refresh()


func _on_stat_pressed(stat_name: String) -> void:
	if _player == null:
		return
	var stats := _player.get_node("StatsComponent") as StatsComponent
	if stats.unspent_stat_points <= 0:
		return
	stats.unspent_stat_points -= 1
	match stat_name:
		"strength":
			stats.strength += 1
		"vitality":
			stats.vitality += 1
		"dexterity":
			stats.dexterity += 1
		"intelligence":
			stats.intelligence += 1
		"endurance":
			stats.endurance += 1
		"spirit":
			stats.spirit += 1
	stats.stat_changed.emit()
	if _player.has_node("SkillTree"):
		(_player.get_node("SkillTree")).refresh_derived_stats()
	_refresh()


func _on_unlock_pressed() -> void:
	if _player == null or _selected_node == "":
		return
	var tree := _player.get_node("SkillTree")
	if tree.unlock_node(_selected_node):
		_refresh()


func _update_detail() -> void:
	if _selected_node == "" or _player == null:
		_detail_label.text = "Select a skill node to view details."
		return
	var tree := _player.get_node("SkillTree")
	var data: Dictionary = tree.SKILL_NODES.get(_selected_node, {})
	var branch_id := str(data.get("branch", ""))
	var branch := tree.BRANCH_LABELS.get(branch_id, branch_id.replace("_", " ").capitalize())
	var rank := tree.get_node_rank(_selected_node) if tree.has_method("get_node_rank") else 0
	var max_r := int(data.get("max_rank", 1))
	var can := tree.can_unlock(_selected_node)
	var req_text := "Requirements met" if can else "Missing requirements or skill points"
	_detail_label.text = "%s\nBranch: %s\nRank: %d / %d  |  Cost: %d SP\n%s\n%s" % [
		str(data.get("name", _selected_node)),
		branch,
		rank, max_r,
		int(data.get("cost", 1)),
		str(data.get("desc", "")),
		req_text,
	]
