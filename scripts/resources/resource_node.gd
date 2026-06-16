class_name ResourceNode
extends InteractableBase

const _VisualFactory := preload("res://scripts/resources/resource_node_visual_factory.gd")

@export var resource_id: String = "wood"
@export var yield_amount: int = 3
@export var requires_tool: String = ""
@export var node_kind: String = ""
@export var persistence_id: String = ""
@export var persist_depletion: bool = false

var _depleted: bool = false
var _gathering: bool = false


func _ready() -> void:
	super._ready()
	_ensure_interaction_area()
	_ensure_visual()
	if persist_depletion and persistence_id != "" and WorldStateManager.is_resource_depleted(persistence_id):
		_apply_depleted_state()
	else:
		_refresh_prompt()


func get_gather_prompt_text() -> String:
	if _depleted:
		return "Depleted"
	return "Gather %s" % _VisualFactory.gather_prompt_label(resource_id)


func _on_interact(player: Node) -> void:
	if _depleted or _gathering:
		return
	if requires_tool != "" and not _player_has_tool(player, requires_tool):
		var tool_label := requires_tool.replace("_", " ").capitalize()
		_show_tool_message(player, tool_label)
		return
	_gathering = true
	var player_index := 0
	if player is PlayerController:
		player_index = (player as PlayerController).player_index
	if not InventoryManager.add_item(resource_id, yield_amount):
		_gathering = false
		return
	if requires_tool != "":
		EquipmentManager.on_tool_used()
	_try_crystal_gem_bonus()
	ResourceFeedbackManager.notify_player_gathered(player_index, resource_id, yield_amount)
	BaseManager.notify_tracked_material_change(resource_id, yield_amount, player_index)
	RegionContent.on_resource_gathered(resource_id)
	_depleted = true
	if persist_depletion and persistence_id != "":
		WorldStateManager.mark_resource_depleted(persistence_id)
	_apply_depleted_state()
	_gathering = false


func _apply_depleted_state() -> void:
	_depleted = true
	prompt_text = "Depleted"
	_set_depleted_visual()


func _refresh_prompt() -> void:
	prompt_text = get_gather_prompt_text()


func _player_has_tool(_player: Node, tool_id: String) -> bool:
	if tool_id == "":
		return true
	if InventoryManager.has_item(tool_id):
		return true
	for slot in InventoryManager.equipment.values():
		if str(slot) == tool_id:
			return true
	match tool_id:
		"axe", "pickaxe", "knife":
			return InventoryManager.has_item("iron_sword") or InventoryManager.has_item("steel_dagger")
		"canteen":
			return InventoryManager.has_item("waterskin") or InventoryManager.has_item("purified_water")
	return false


func _show_tool_message(player: Node, tool_label: String) -> void:
	var hud := get_tree().get_first_node_in_group("game_hud")
	if hud and hud.has_method("show_toast"):
		var prefix := "P1"
		if player is PlayerController:
			prefix = "P%d" % ((player as PlayerController).player_index + 1)
		hud.show_toast("%s: Requires %s" % [prefix, tool_label], 2.0, "", "notification", "", NotificationToast.Priority.IMPORTANT)


func _ensure_interaction_area() -> void:
	if get_node_or_null("InteractionArea"):
		return
	var area := Area3D.new()
	area.name = "InteractionArea"
	area.collision_layer = 32
	area.collision_mask = 0
	var col := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.6
	col.shape = sphere
	area.add_child(col)
	add_child(area)
	if get_node_or_null("CollisionShape3D") == null:
		var body_col := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(1.0, 1.0, 1.0)
		body_col.shape = box
		body_col.position = Vector3(0.0, 0.5, 0.0)
		add_child(body_col)
	collision_layer = 1


func _ensure_visual() -> void:
	if get_node_or_null("Visual"):
		return
	var kind := node_kind if node_kind != "" else _VisualFactory.infer_kind(resource_id)
	_VisualFactory.build(self, kind)


func _set_depleted_visual() -> void:
	var visual := get_node_or_null("Visual")
	if visual:
		visual.visible = false


func _try_crystal_gem_bonus() -> void:
	if not resource_id.contains("crystal"):
		return
	if randf() >= 0.08:
		return
	InventoryManager.add_item(GemEffectManager.random_common_gem_id(), 1)
