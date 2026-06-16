extends Node
## Hearthhold Camp station levels and upgrades.

signal station_upgraded(station_id: String, level: int)

const _CoopUiCopy := preload("res://scripts/ui/coop_ui_copy.gd")
const TRACKED_STATIONS: Array[String] = [
	"workbench", "forge", "water_collector", "garden_plot", "pet_shelter", "mask_stand",
]

const _VisualFactory := preload("res://scripts/resources/resource_node_visual_factory.gd")

var station_levels: Dictionary = {
	"memory_altar": 1,
	"item_box": 1,
	"workbench": 1,
	"forge": 1,
	"pet_shelter": 0,
	"mask_stand": 0,
	"water_collector": 0,
	"garden_plot": 0,
}

var _last_progress_toast: Dictionary = {}
var _completion_announced: Dictionary = {}
var _station_cooldown_until_msec: Dictionary = {}


func reset_for_new_game() -> void:
	station_levels = {
		"memory_altar": 1,
		"item_box": 1,
		"workbench": 1,
		"forge": 1,
		"pet_shelter": 0,
		"mask_stand": 0,
		"water_collector": 0,
		"garden_plot": 0,
	}
	_last_progress_toast.clear()
	_completion_announced.clear()
	_station_cooldown_until_msec.clear()


func get_station_level(station_id: String) -> int:
	return int(station_levels.get(station_id, 0))


func is_station_unlocked(station_id: String) -> bool:
	return get_station_level(station_id) > 0


func is_buildable_station(station_id: String) -> bool:
	return station_id in ["water_collector", "garden_plot", "pet_shelter", "mask_stand"]


func can_upgrade(station_id: String) -> bool:
	var level := get_station_level(station_id)
	var cost := _upgrade_cost(station_id, level + 1)
	if cost.is_empty():
		return false
	for mat in cost.materials:
		if InventoryManager.get_combined_count(mat.id) < int(mat.quantity):
			return false
	return CurrencyManager.can_afford_copper(int(cost.get("copper", 0)))


func upgrade_station(station_id: String) -> bool:
	if not can_upgrade(station_id):
		return false
	var next_level := get_station_level(station_id) + 1
	var cost := _upgrade_cost(station_id, next_level)
	for mat in cost.materials:
		if not InventoryManager.consume_combined(mat.id, int(mat.quantity)):
			return false
	if int(cost.get("copper", 0)) > 0:
		CurrencyManager.spend_copper(int(cost.copper))
	station_levels[station_id] = next_level
	station_upgraded.emit(station_id, next_level)
	if station_id == "forge":
		AchievementManager.unlock("forge_friend")
	_completion_announced.erase(station_id)
	for key in _last_progress_toast.keys():
		if str(key).begins_with(station_id):
			_last_progress_toast.erase(key)
	return true


func get_station_progress_label(station_id: String) -> String:
	var next_level := get_station_level(station_id) + 1
	var cost := _upgrade_cost(station_id, next_level)
	if cost.is_empty():
		return ""
	return "%s L%d" % [_station_title(station_id), next_level]


func get_tracked_upgrade_summary(station_id: String = "") -> String:
	var target := station_id if station_id != "" else _first_incomplete_station()
	if target == "":
		return ""
	var next_level := get_station_level(target) + 1
	var cost := _upgrade_cost(target, next_level)
	if cost.is_empty():
		return ""
	var parts: PackedStringArray = []
	for mat in cost.materials:
		var have := InventoryManager.get_combined_count(mat.id)
		var need := int(mat.quantity)
		parts.append("%s %d/%d" % [ItemDatabase.get_display_name(mat.id), have, need])
	return "%s: %s" % [get_station_progress_label(target), ", ".join(parts)]


func get_missing_materials_summary(station_id: String) -> String:
	var next_level := get_station_level(station_id) + 1
	var cost := _upgrade_cost(station_id, next_level)
	if cost.is_empty():
		return "Max level reached"
	var missing: PackedStringArray = []
	for mat in cost.materials:
		var have := InventoryManager.get_combined_count(mat.id)
		var need := int(mat.quantity)
		if have < need:
			missing.append("%s x%d" % [ItemDatabase.get_display_name(mat.id), need - have])
	var copper_need := int(cost.get("copper", 0))
	if copper_need > 0 and not CurrencyManager.can_afford_copper(copper_need):
		missing.append(_format_copper_need(copper_need))
	if missing.is_empty():
		return "Ready to upgrade"
	return "Missing: %s" % ", ".join(missing)


func notify_tracked_material_pickup(item_id: String, quantity: int) -> void:
	notify_tracked_material_change(item_id, quantity, -1)


func notify_tracked_material_change(item_id: String, _quantity: int, player_index: int = -1) -> void:
	for station_id in TRACKED_STATIONS:
		if can_upgrade(station_id):
			_maybe_announce_complete(station_id)
			continue
		if not _upgrade_needs_item(station_id, item_id):
			continue
		if _upgrade_cost(station_id, get_station_level(station_id) + 1).is_empty():
			continue
		_maybe_toast_station_progress(station_id, item_id, player_index)


func notify_inventory_or_storage_changed() -> void:
	for station_id in TRACKED_STATIONS:
		if can_upgrade(station_id):
			_maybe_announce_complete(station_id)


func is_station_on_cooldown(station_id: String) -> bool:
	return Time.get_ticks_msec() < int(_station_cooldown_until_msec.get(station_id, 0))


func mark_station_used(station_id: String, cooldown_sec: float = 45.0) -> void:
	_station_cooldown_until_msec[station_id] = Time.get_ticks_msec() + int(cooldown_sec * 1000.0)


func collect_water(player_index: int) -> bool:
	if get_station_level("water_collector") < 1:
		return false
	if is_station_on_cooldown("water_collector"):
		return false
	var item_id := "purified_water" if get_station_level("water_collector") >= 2 else "dirty_water"
	if not InventoryManager.add_item(item_id, 1):
		return false
	mark_station_used("water_collector")
	ResourceFeedbackManager.notify_player_pickup(player_index, item_id, 1)
	return true


func harvest_garden(player_index: int) -> bool:
	if get_station_level("garden_plot") < 1:
		return false
	if is_station_on_cooldown("garden_plot"):
		return false
	var item_id := "berries" if get_station_level("garden_plot") >= 2 else "herb_bundle"
	if not InventoryManager.add_item(item_id, 1):
		return false
	mark_station_used("garden_plot")
	ResourceFeedbackManager.notify_player_pickup(player_index, item_id, 1)
	return true


func _first_incomplete_station() -> String:
	for station_id in TRACKED_STATIONS:
		if not _upgrade_cost(station_id, get_station_level(station_id) + 1).is_empty():
			return station_id
	return ""


func _upgrade_needs_item(station_id: String, item_id: String) -> bool:
	var cost := _upgrade_cost(station_id, get_station_level(station_id) + 1)
	for mat in cost.get("materials", []):
		if mat.id == item_id:
			return true
	return false


func _station_title(station_id: String) -> String:
	return station_id.replace("_", " ").capitalize()


func _format_copper_need(copper: int) -> String:
	if copper >= CurrencyManager.COPPER_PER_SILVER:
		var silver := copper / CurrencyManager.COPPER_PER_SILVER
		if copper % CurrencyManager.COPPER_PER_SILVER == 0:
			return "Need %d Silver" % silver
	return "Need %d Copper" % copper


func _maybe_toast_station_progress(station_id: String, item_id: String, player_index: int) -> void:
	var summary := get_tracked_upgrade_summary(station_id)
	if summary == "":
		return
	var toast_key := "%s:%s" % [station_id, summary]
	if _last_progress_toast.get(toast_key, false):
		return
	_last_progress_toast[toast_key] = true
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var item_name := _VisualFactory.gather_label(item_id)
	var progress := get_station_progress_label(station_id)
	var have_need := summary.split(": ", false, 1)
	var counts := have_need[1] if have_need.size() > 1 else summary
	var message := "%s — %s %s" % [progress, item_name, counts.split(",")[0].strip_edges()]
	if player_index >= 0:
		message = "%s gathered %s — %s" % [
			_CoopUiCopy.player_tag(player_index),
			item_name,
			counts.split(",")[0].strip_edges(),
		]
	for hud in tree.get_nodes_in_group("game_hud"):
		if hud.has_method("show_toast"):
			hud.show_toast(message, 2.0, "", "notification", "", NotificationToast.Priority.NORMAL)
			return


func _maybe_announce_complete(station_id: String) -> void:
	if _completion_announced.get(station_id, false):
		return
	_completion_announced[station_id] = true
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var label := "%s materials complete" % _station_title(station_id)
	for hud in tree.get_nodes_in_group("game_hud"):
		if hud.has_method("show_toast"):
			hud.show_toast(label, 2.5, "Return to Hearthhold Camp", "notification", "", NotificationToast.Priority.IMPORTANT)
			return


func _upgrade_cost(station_id: String, level: int) -> Dictionary:
	match station_id:
		"workbench":
			if level == 2:
				return {
					"materials": [
						{"id": "wood", "quantity": 10},
						{"id": "iron_scrap", "quantity": 6},
						{"id": "nails", "quantity": 4},
					],
					"copper": 50,
				}
		"forge":
			if level == 2:
				return {
					"materials": [
						{"id": "stone", "quantity": 10},
						{"id": "iron_scrap", "quantity": 12},
						{"id": "fire_resin", "quantity": 2},
						{"id": "silver_ore", "quantity": 2},
					],
					"copper": 50,
				}
		"water_collector":
			if level == 1:
				return {
					"materials": [
						{"id": "wood", "quantity": 6},
						{"id": "cloth_scrap", "quantity": 3},
						{"id": "rope", "quantity": 2},
					],
					"copper": 15,
				}
		"garden_plot":
			if level == 1:
				return {
					"materials": [
						{"id": "wood", "quantity": 4},
						{"id": "seeds", "quantity": 3},
						{"id": "purified_water", "quantity": 2},
						{"id": "fiber", "quantity": 2},
					],
					"copper": 10,
				}
		"pet_shelter":
			if level == 1:
				return {
					"materials": [
						{"id": "wood", "quantity": 8},
						{"id": "cloth_scrap", "quantity": 4},
						{"id": "hide", "quantity": 2},
						{"id": "bone", "quantity": 3},
					],
					"copper": 20,
				}
		"mask_stand":
			if level == 1:
				return {
					"materials": [
						{"id": "wood", "quantity": 6},
						{"id": "nails", "quantity": 2},
						{"id": "cloth_scrap", "quantity": 2},
					],
					"copper": 10,
				}
		_:
			pass
	return {}


func serialize() -> Dictionary:
	return {"station_levels": station_levels.duplicate()}


func deserialize(data: Dictionary) -> void:
	if data.has("station_levels"):
		station_levels = data.station_levels
