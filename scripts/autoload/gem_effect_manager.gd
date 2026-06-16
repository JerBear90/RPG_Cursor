extends Node
## Central gem definitions, compatibility, and modifier aggregation.

const GEM_IDS: Array[String] = [
	"gem_ruby", "gem_sapphire", "gem_emerald", "gem_onyx", "gem_topaz",
	"gem_amethyst", "gem_diamond", "gem_garnet",
]

const REMOVAL_COST_COMMON := 50
const REMOVAL_COST_RARE := 100


func get_gem_item_ids() -> Array[String]:
	return GEM_IDS.duplicate()


func is_gem_item(item_id: String) -> bool:
	return ItemDatabase.get_item(item_id).get("type") == "gem"


func get_gem_core_id(gem_item_id: String) -> String:
	return str(ItemDatabase.get_item(gem_item_id).get("gem_id", gem_item_id.replace("gem_", "")))


func get_display_name(gem_item_id: String) -> String:
	var data := ItemDatabase.get_item(gem_item_id)
	if data.is_empty():
		return "Unknown Gem"
	return str(data.get("display_name", ItemDatabase.get_display_name(gem_item_id)))


func get_rarity(gem_item_id: String) -> String:
	return str(ItemDatabase.get_item(gem_item_id).get("rarity", "common"))


func is_compatible(gem_item_id: String, gear_entry: Dictionary) -> bool:
	if gear_entry.is_empty() or not is_gem_item(gem_item_id):
		return false
	var gear_id := str(gear_entry.id)
	var gear_data := ItemDatabase.get_item(gear_id)
	var gear_type := str(gear_data.get("type", ""))
	if gear_type not in ["weapon", "armor"]:
		return false
	var allowed: Array = ItemDatabase.get_item(gem_item_id).get("allowed_gear_types", ["weapon", "armor"])
	if gear_type not in allowed:
		return false
	var slot := ItemDatabase.normalize_equipment_slot(str(gear_data.get("slot", "")))
	if slot == "offhand" and "shield" not in allowed and gear_type == "armor":
		return ItemDatabase.get_item(gem_item_id).get("allow_shield", true)
	return true


func get_effect_description(gem_item_id: String, gear_entry: Dictionary) -> String:
	var mods := get_modifiers_for_gear(gem_item_id, gear_entry)
	return str(mods.get("description", "Gem effect"))


func get_modifiers_for_gear(gem_item_id: String, gear_entry: Dictionary) -> Dictionary:
	var data := ItemDatabase.get_item(gem_item_id)
	if data.is_empty():
		return {}
	var gear_data := ItemDatabase.get_item(str(gear_entry.get("id", "")))
	var gear_type := str(gear_data.get("type", "weapon"))
	var slot := ItemDatabase.normalize_equipment_slot(str(gear_data.get("slot", "")))
	var key := gear_type
	if gear_type == "armor" and slot == "offhand":
		key = "shield"
	var effect_map: Dictionary = data.get("effects", {})
	if effect_map.has(key):
		return effect_map[key].duplicate()
	if effect_map.has(gear_type):
		return effect_map[gear_type].duplicate()
	if effect_map.has("utility"):
		return effect_map["utility"].duplicate()
	return {}


func merge_modifiers(into: Dictionary, add: Dictionary) -> Dictionary:
	for key in add.keys():
		if key == "description":
			continue
		if key.ends_with("_bonus") or key.ends_with("_resist") or key.ends_with("_chance") or key.ends_with("_efficiency"):
			into[key] = float(into.get(key, 0.0)) + float(add[key])
		elif typeof(add[key]) in [TYPE_INT, TYPE_FLOAT]:
			into[key] = float(into.get(key, 0.0)) + float(add[key])
		else:
			into[key] = add[key]
	return into


func get_gear_gem_modifiers(gear_entry: Dictionary) -> Dictionary:
	var total: Dictionary = {}
	if gear_entry.is_empty():
		return total
	for gem_item_id in gear_entry.get("socketed_gems", []):
		var gid := str(gem_item_id)
		if gid == "":
			continue
		if not ItemDatabase.get_item(gid).is_empty():
			merge_modifiers(total, get_modifiers_for_gear(gid, gear_entry))
		else:
			total["unknown_gems"] = int(total.get("unknown_gems", 0)) + 1
	return total


func get_player_passive_modifiers() -> Dictionary:
	var total: Dictionary = {}
	for slot in InventoryManager.equipment.keys():
		var entry := EquipmentManager.get_equipped_instance(str(slot))
		if entry.is_empty():
			continue
		merge_modifiers(total, get_gear_gem_modifiers(entry))
	return total


func get_removal_cost_copper(gem_item_id: String, recover: bool) -> int:
	if not recover:
		return 0
	if get_rarity(gem_item_id) in ["rare", "epic", "legendary"]:
		return REMOVAL_COST_RARE
	return REMOVAL_COST_COMMON


func random_common_gem_id() -> String:
	var pool: Array[String] = ["gem_ruby", "gem_sapphire", "gem_emerald", "gem_topaz", "gem_garnet"]
	return pool[randi() % pool.size()]


func format_socket_lines(gear_entry: Dictionary) -> PackedStringArray:
	var lines: PackedStringArray = []
	var prepared := int(gear_entry.get("socket_count", 0))
	var max_s := int(gear_entry.get("max_socket_count", 0))
	if max_s <= 0 and prepared <= 0:
		return lines
	lines.append("Sockets: %d / %d" % [prepared, max_s])
	var gems: Array = gear_entry.get("socketed_gems", [])
	for i in mini(gems.size(), prepared):
		var gem_id := str(gems[i])
		if gem_id == "":
			lines.append("[Empty Socket]")
		elif ItemDatabase.get_item(gem_id).is_empty():
			lines.append("[Unknown Gem]")
		else:
			var desc := get_effect_description(gem_id, gear_entry)
			lines.append("[%s] %s" % [get_display_name(gem_id), desc])
	return lines
