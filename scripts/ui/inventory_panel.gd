extends PanelContainer
## Grid inventory with equipment slots and item actions.

signal closed

const _ItemUiTheme = preload("res://scripts/ui/item_ui_theme.gd")

const EQUIPMENT_SLOTS: Array[String] = [
	"helmet", "chest", "gloves", "boots",
	"main_weapon", "offhand", "ring_1", "ring_2", "charm", "mask",
]

var _player: Node
var _item_grid: GridContainer
var _equip_grid: GridContainer
var _detail_label: Label
var _action_use: Button
var _action_equip: Button
var _action_unequip: Button
var _selected_item_id: String = ""
var _selected_instance_id: String = ""
var _selected_slot: String = ""


func _ready() -> void:
	custom_minimum_size = Vector2(720, 480)
	_build_ui()
	InventoryManager.inventory_changed.connect(_refresh)
	InventoryManager.equipment_changed.connect(func(_s): _refresh())


func open(player: Node) -> void:
	_player = player
	_selected_item_id = ""
	_selected_instance_id = ""
	_selected_slot = ""
	_refresh()
	visible = true


func close() -> void:
	visible = false
	closed.emit()


func _build_ui() -> void:
	var root := HBoxContainer.new()
	add_child(root)
	var equip_col := VBoxContainer.new()
	equip_col.custom_minimum_size = Vector2(200, 0)
	root.add_child(equip_col)
	var equip_title := Label.new()
	equip_title.text = "Equipment"
	equip_title.add_theme_font_size_override("font_size", 20)
	equip_col.add_child(equip_title)
	_equip_grid = GridContainer.new()
	_equip_grid.columns = 2
	equip_col.add_child(_equip_grid)
	var inv_col := VBoxContainer.new()
	inv_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(inv_col)
	var inv_title := Label.new()
	inv_title.text = "Inventory"
	inv_title.add_theme_font_size_override("font_size", 20)
	inv_col.add_child(inv_title)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(480, 300)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inv_col.add_child(scroll)
	_item_grid = GridContainer.new()
	_item_grid.columns = 5
	scroll.add_child(_item_grid)
	_detail_label = Label.new()
	_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_label.custom_minimum_size = Vector2(0, 72)
	inv_col.add_child(_detail_label)
	var actions := HBoxContainer.new()
	inv_col.add_child(actions)
	_action_use = Button.new()
	_action_use.text = "Use"
	_action_use.pressed.connect(_on_use_pressed)
	actions.add_child(_action_use)
	_action_equip = Button.new()
	_action_equip.text = "Equip"
	_action_equip.pressed.connect(_on_equip_pressed)
	actions.add_child(_action_equip)
	_action_unequip = Button.new()
	_action_unequip.text = "Unequip"
	_action_unequip.pressed.connect(_on_unequip_pressed)
	actions.add_child(_action_unequip)
	var close_btn := Button.new()
	close_btn.text = "Close (B)"
	close_btn.pressed.connect(close)
	inv_col.add_child(close_btn)


func _refresh() -> void:
	_rebuild_equipment()
	_rebuild_inventory()
	_update_detail()


func _rebuild_equipment() -> void:
	for child in _equip_grid.get_children():
		child.queue_free()
	for slot in EQUIPMENT_SLOTS:
		var btn := Button.new()
		var entry := EquipmentManager.get_equipped_instance(slot)
		var label := slot.replace("_", " ").capitalize()
		if not entry.is_empty():
			label += "\n%s" % EquipmentManager.get_display_name(entry)
		btn.text = label
		btn.custom_minimum_size = Vector2(90, 56)
		btn.pressed.connect(_on_equip_slot_pressed.bind(slot))
		_equip_grid.add_child(btn)


func _rebuild_inventory() -> void:
	for child in _item_grid.get_children():
		child.queue_free()
	for entry in InventoryManager.items:
		var item_id: String = entry.id
		var instance_id: String = str(entry.get("instance_id", ""))
		var btn := Button.new()
		var label := _ItemUiTheme.format_item_button(item_id, entry.quantity)
		if EquipmentManager.supports_durability(item_id):
			label = "%s\n%d/%d" % [
				EquipmentManager.get_display_name(entry),
				int(entry.get("current_durability", 0)),
				int(entry.get("max_durability", 0)),
			]
		btn.text = label
		btn.toggle_mode = true
		btn.button_pressed = instance_id != "" and instance_id == _selected_instance_id
		btn.custom_minimum_size = Vector2(96, 68)
		_ItemUiTheme.style_item_button(btn, item_id, btn.button_pressed)
		btn.pressed.connect(_on_item_pressed.bind(item_id, instance_id))
		_item_grid.add_child(btn)


func _on_item_pressed(item_id: String, instance_id: String) -> void:
	_selected_item_id = item_id
	_selected_instance_id = instance_id
	_selected_slot = ""
	_rebuild_inventory()
	_update_detail()


func _on_equip_slot_pressed(slot: String) -> void:
	_selected_slot = slot
	var entry := EquipmentManager.get_equipped_instance(slot)
	_selected_item_id = str(entry.get("id", ""))
	_selected_instance_id = str(entry.get("instance_id", ""))
	_update_detail()


func _update_detail() -> void:
	if _selected_item_id == "" and _selected_slot == "":
		_detail_label.text = "Select an item or equipment slot."
		_set_actions(false, false, false)
		return
	var entry := _find_selected_entry()
	if entry.is_empty() and _selected_item_id != "":
		entry = {"id": _selected_item_id}
	if entry.is_empty() and _selected_slot != "":
		_detail_label.text = "Empty slot: %s" % _selected_slot.replace("_", " ")
		_set_actions(false, false, false)
		return
	var item_id := str(entry.get("id", _selected_item_id))
	var data := ItemDatabase.get_item(item_id)
	var lines: PackedStringArray = []
	if EquipmentManager.supports_durability(item_id):
		lines = EquipmentManager.format_gear_detail(entry).split("\n")
	else:
		lines.append(item_id.replace("_", " ").capitalize())
		lines.append("Type: %s" % str(data.get("type", "unknown")))
		if data.has("damage"):
			lines.append("Damage: +%d" % int(data.damage))
		if data.has("health"):
			lines.append("Health: +%d" % int(data.health))
	if EquipmentManager.supports_durability(item_id):
		var preview := EquipmentManager.get_repair_materials(entry)
		if not preview.is_empty():
			var parts: PackedStringArray = []
			for mat in preview:
				parts.append("%s x%d" % [ItemDatabase.get_display_name(mat.id), int(mat.quantity)])
			lines.append("Repair: %s" % ", ".join(parts))
	if data.has("label") and not EquipmentManager.supports_durability(item_id):
		lines.append("Action: %s" % data.label)
	_detail_label.text = "\n".join(lines)
	var can_use := ItemDatabase.can_use(item_id)
	var can_equip := ItemDatabase.can_equip(item_id)
	var is_equipped := _is_instance_equipped(_selected_instance_id, item_id)
	_set_actions(can_use, can_equip and not is_equipped, is_equipped or _selected_slot != "")


func _find_selected_entry() -> Dictionary:
	if _selected_instance_id != "":
		return EquipmentManager.find_entry_by_instance(_selected_instance_id)
	for entry in InventoryManager.items:
		if entry.id == _selected_item_id:
			return entry
	return {}


func _is_instance_equipped(instance_id: String, item_id: String) -> bool:
	if instance_id != "":
		for slot in InventoryManager.equipment.keys():
			if str(InventoryManager.equipment[slot]) == instance_id:
				return true
	return InventoryManager.is_equipped(item_id)


func _set_actions(use: bool, equip: bool, unequip: bool) -> void:
	_action_use.visible = use
	_action_equip.visible = equip
	_action_unequip.visible = unequip


func _on_use_pressed() -> void:
	if _player and _selected_item_id != "":
		InventoryManager.use_item(_selected_item_id, _player)


func _on_equip_pressed() -> void:
	if _player and _selected_item_id != "":
		if _selected_instance_id != "":
			var slot := ItemDatabase.normalize_equipment_slot(str(ItemDatabase.get_item(_selected_item_id).get("slot", "main_weapon")))
			EquipmentManager.equip_instance(_selected_instance_id, slot)
			PlayerProgress._apply_equipment_stats(_player)
		else:
			InventoryManager.equip_item(_selected_item_id, _player)


func _on_unequip_pressed() -> void:
	var slot := _selected_slot
	if slot == "":
		for s in InventoryManager.equipment.keys():
			if str(InventoryManager.equipment[s]) == _selected_instance_id:
				slot = s
				break
	if slot != "" and InventoryManager.equipment.has(slot):
		InventoryManager.equipment.erase(slot)
		InventoryManager.equipment_changed.emit(slot)
		if _player:
			PlayerProgress._apply_equipment_stats(_player)
		_selected_item_id = ""
		_selected_instance_id = ""
		_selected_slot = ""
		_refresh()
