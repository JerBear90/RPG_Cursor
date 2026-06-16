extends Node
## Durability, repair, upgrade, reinforcement, and socket prep for gear instances.

signal gear_changed(instance_id: String)

const _CoopUiCopy := preload("res://scripts/ui/coop_ui_copy.gd")

const MAX_UPGRADE_LEVEL := 3
const MAX_REINFORCE_LEVEL := 3
const BROKEN_EFFECTIVENESS := 0.5
const DAMAGED_EFFECTIVENESS := 0.75
const REPAIR_KIT_FLAT := 35.0
const UPGRADE_DAMAGE_BONUS := 0.12
const REINFORCE_ARMOR_BONUS := 0.12
const UPGRADE_DURABILITY_BONUS := 5.0

var _instance_counter: int = 0


func reset_for_new_game() -> void:
	_instance_counter = 0


func next_instance_id() -> String:
	_instance_counter += 1
	return "gear_%04d" % _instance_counter


func supports_durability(item_id: String) -> bool:
	if item_id == "" or ItemDatabase.is_quest_item(item_id):
		return false
	return ItemDatabase.get_item(item_id).get("type") in ["weapon", "armor"]


func create_gear_entry(item_id: String) -> Dictionary:
	var max_dur := ItemDatabase.get_max_durability(item_id)
	return {
		"id": item_id,
		"quantity": 1,
		"instance_id": next_instance_id(),
		"current_durability": max_dur,
		"max_durability": max_dur,
		"upgrade_level": 0,
		"reinforcement_level": 0,
		"socket_count": 0,
		"max_socket_count": ItemDatabase.get_max_sockets(item_id),
		"socket_prep_level": 0,
		"socketed_gems": [],
		"is_broken": false,
		"locked": false,
	}


func normalize_entry(entry: Dictionary) -> Dictionary:
	var item_id: String = str(entry.get("id", ""))
	if not supports_durability(item_id):
		return entry
	if not entry.has("instance_id") or str(entry.instance_id) == "":
		entry.instance_id = next_instance_id()
	var max_dur := float(entry.get("max_durability", ItemDatabase.get_max_durability(item_id)))
	entry.max_durability = max_dur
	entry.current_durability = clampf(float(entry.get("current_durability", max_dur)), 0.0, max_dur)
	entry.upgrade_level = int(entry.get("upgrade_level", 0))
	entry.reinforcement_level = int(entry.get("reinforcement_level", 0))
	entry.socket_count = int(entry.get("socket_count", 0))
	entry.max_socket_count = int(entry.get("max_socket_count", ItemDatabase.get_max_sockets(item_id)))
	entry.socket_prep_level = int(entry.get("socket_prep_level", 0))
	if not entry.has("socketed_gems"):
		entry.socketed_gems = []
	entry.socketed_gems = _sync_socket_array(entry)
	entry.is_broken = entry.current_durability <= 0.0
	_apply_durability_cap_from_gems(entry)
	return entry


func _sync_socket_array(entry: Dictionary) -> Array:
	var prepared := int(entry.get("socket_count", 0))
	var gems: Array = entry.get("socketed_gems", []).duplicate()
	while gems.size() < prepared:
		gems.append("")
	while gems.size() > prepared:
		gems.pop_back()
	return gems


func normalize_all_items() -> void:
	for i in InventoryManager.items.size():
		InventoryManager.items[i] = normalize_entry(InventoryManager.items[i])


func migrate_equipment_slots() -> void:
	var migrated: Dictionary = {}
	for slot in InventoryManager.equipment.keys():
		var val: String = str(InventoryManager.equipment[slot])
		if val == "":
			continue
		if val.begins_with("gear_"):
			migrated[slot] = val
			continue
		var instance_id := find_first_instance_id(val)
		if instance_id != "":
			migrated[slot] = instance_id
		else:
			migrated[slot] = val
	InventoryManager.equipment = migrated


func find_entry_by_instance(instance_id: String) -> Dictionary:
	for entry in InventoryManager.items:
		if str(entry.get("instance_id", "")) == instance_id:
			return entry
	return {}


func find_first_instance_id(item_id: String) -> String:
	for entry in InventoryManager.items:
		if entry.id == item_id and entry.has("instance_id"):
			return str(entry.instance_id)
	return ""


func get_equipped_instance(slot: String) -> Dictionary:
	var instance_id: String = str(InventoryManager.equipment.get(slot, ""))
	if instance_id == "":
		return {}
	if instance_id.begins_with("gear_"):
		return find_entry_by_instance(instance_id)
	return find_entry_by_instance(find_first_instance_id(instance_id))


func get_equipped_item_id(slot: String) -> String:
	var entry := get_equipped_instance(slot)
	if not entry.is_empty():
		return str(entry.id)
	return str(InventoryManager.equipment.get(slot, ""))


func resolve_slot_name(raw_slot: String) -> String:
	return ItemDatabase.normalize_equipment_slot(raw_slot)


func equip_instance(instance_id: String, slot: String) -> bool:
	var entry := find_entry_by_instance(instance_id)
	if entry.is_empty():
		return false
	InventoryManager.equipment[slot] = instance_id
	InventoryManager.equipment_changed.emit(slot)
	InventoryManager.inventory_changed.emit()
	return true


func get_display_name(entry: Dictionary) -> String:
	if entry.is_empty():
		return ""
	var base := ItemDatabase.get_display_name(str(entry.id))
	var upgrade := int(entry.get("upgrade_level", 0))
	var reinforce := int(entry.get("reinforcement_level", 0))
	if upgrade > 0:
		return "%s +%d" % [base, upgrade]
	if reinforce > 0:
		return "%s +%d" % [base, reinforce]
	return base


func get_effective_weapon_damage(entry: Dictionary) -> float:
	if entry.is_empty():
		return 0.0
	var base := ItemDatabase.get_weapon_damage(str(entry.id))
	var upgrade := int(entry.get("upgrade_level", 0))
	base *= 1.0 + upgrade * UPGRADE_DAMAGE_BONUS
	var mods := GemEffectManager.get_gear_gem_modifiers(entry)
	base += float(mods.get("flat_damage", 0.0))
	base += float(mods.get("fire_damage", 0.0))
	base += float(mods.get("poison_damage", 0.0))
	base += float(mods.get("dark_damage", 0.0))
	base *= _durability_multiplier(entry)
	return base


func get_effective_armor_bonus(entry: Dictionary) -> float:
	if entry.is_empty():
		return 0.0
	var base := ItemDatabase.get_armor_health_bonus(str(entry.id))
	var reinforce := int(entry.get("reinforcement_level", 0))
	base *= 1.0 + reinforce * REINFORCE_ARMOR_BONUS
	var mods := GemEffectManager.get_gear_gem_modifiers(entry)
	base += float(mods.get("armor_hp", 0.0))
	base *= 1.0 + float(mods.get("defense_bonus", 0.0))
	base *= _durability_multiplier(entry)
	return base


func get_shield_block_efficiency(entry: Dictionary) -> float:
	var base := 0.7
	if not entry.is_empty():
		base += ItemDatabase.get_shield_block_bonus(str(entry.id))
		var mods := GemEffectManager.get_gear_gem_modifiers(entry)
		base += float(mods.get("block_bonus", 0.0))
	return base * _durability_multiplier(entry)


func get_effective_max_durability(entry: Dictionary) -> float:
	var base := float(entry.get("max_durability", ItemDatabase.get_max_durability(str(entry.get("id", "")))))
	var mods := GemEffectManager.get_gear_gem_modifiers(entry)
	return base + float(mods.get("durability_bonus", 0.0))


func _durability_multiplier(entry: Dictionary) -> float:
	if bool(entry.get("is_broken", false)) or float(entry.get("current_durability", 1.0)) <= 0.0:
		return BROKEN_EFFECTIVENESS
	var max_dur := float(entry.get("max_durability", 1.0))
	var current := float(entry.get("current_durability", max_dur))
	if max_dur > 0.0 and current / max_dur <= 0.25:
		return DAMAGED_EFFECTIVENESS
	return 1.0


func on_player_weapon_hit(source: Node) -> void:
	if source == null:
		return
	var slot := "main_weapon"
	var entry := get_equipped_instance(slot)
	if entry.is_empty():
		return
	_apply_durability_loss(entry, 1.0)
	_notify_broken_if_needed(entry, slot)


func on_shield_block(blocked_amount: float) -> void:
	var entry := get_equipped_instance("offhand")
	if entry.is_empty():
		entry = get_equipped_instance("off_hand")
	if entry.is_empty():
		return
	var loss := 1.0
	if blocked_amount >= 20.0:
		loss = 3.0
	elif blocked_amount >= 10.0:
		loss = 2.0
	_apply_durability_loss(entry, loss)
	_notify_broken_if_needed(entry, "offhand")


func on_armor_damaged() -> void:
	var slots: Array[String] = ["helmet", "chest", "gloves", "boots"]
	var slot := slots[randi() % slots.size()]
	var entry := get_equipped_instance(slot)
	if entry.is_empty():
		for s in slots:
			entry = get_equipped_instance(s)
			if not entry.is_empty():
				slot = s
				break
	if entry.is_empty():
		return
	_apply_durability_loss(entry, 1.0)
	_notify_broken_if_needed(entry, slot)


func on_tool_used(instance_id: String = "") -> void:
	var entry: Dictionary = {}
	if instance_id != "":
		entry = find_entry_by_instance(instance_id)
	if entry.is_empty():
		entry = get_equipped_instance("main_weapon")
	if entry.is_empty():
		return
	_apply_durability_loss(entry, 1.0)


func _apply_durability_loss(entry: Dictionary, amount: float) -> void:
	if not supports_durability(str(entry.id)):
		return
	entry.current_durability = maxf(0.0, float(entry.current_durability) - amount)
	entry.is_broken = entry.current_durability <= 0.0
	gear_changed.emit(str(entry.instance_id))
	InventoryManager.inventory_changed.emit()
	_refresh_equipped_players()


func _refresh_equipped_players() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	for player in GameManager.get_alive_players():
		PlayerProgress._apply_equipment_stats(player)


func _notify_broken_if_needed(entry: Dictionary, slot: String) -> void:
	if not bool(entry.get("is_broken", false)):
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var name := get_display_name(entry)
	var slot_label := slot.replace("_", " ")
	for hud in tree.get_nodes_in_group("game_hud"):
		if hud.has_method("show_toast"):
			if ItemDatabase.get_item(str(entry.id)).get("type") == "weapon":
				hud.show_toast("%s broke — damage reduced" % name, 2.5, "", "notification", "", NotificationToast.Priority.IMPORTANT)
			elif slot in ["offhand", "off_hand"]:
				hud.show_toast("Shield broke — block reduced", 2.5, name, "notification", "", NotificationToast.Priority.IMPORTANT)
			else:
				hud.show_toast("%s is badly damaged" % name, 2.5, "Armor protection reduced", "notification", "", NotificationToast.Priority.IMPORTANT)
			return


func get_repair_materials(entry: Dictionary, cost_multiplier: float = 1.0) -> Array:
	if entry.is_empty() or not supports_durability(str(entry.id)):
		return []
	var missing := float(entry.max_durability) - float(entry.current_durability)
	if missing <= 0.0:
		return []
	var item_type: String = str(ItemDatabase.get_item(str(entry.id)).get("type", ""))
	var slot: String = ItemDatabase.normalize_equipment_slot(str(ItemDatabase.get_item(str(entry.id)).get("slot", "")))
	var mats: Array = []
	match item_type:
		"weapon":
			mats = [
				{"id": "iron_scrap", "quantity": clampi(int(missing / 15.0) + 1, 1, 3)},
				{"id": "wood", "quantity": clampi(int(missing / 30.0), 0, 2)},
			]
		"armor":
			if slot == "offhand":
				mats = [
					{"id": "wood", "quantity": 2},
					{"id": "iron_scrap", "quantity": 2},
					{"id": "nails", "quantity": 1},
				]
			else:
				mats = [
					{"id": "cloth_scrap", "quantity": 1},
					{"id": "hide", "quantity": 1},
					{"id": "iron_scrap", "quantity": clampi(int(missing / 20.0) + 1, 1, 3)},
				]
	if cost_multiplier >= 0.999:
		return mats
	var scaled: Array = []
	for mat in mats:
		var qty := maxi(1, int(ceil(float(mat.quantity) * cost_multiplier)))
		scaled.append({"id": mat.id, "quantity": qty})
	return scaled


func _get_repair_cost_multiplier() -> float:
	for player in GameManager.get_all_registered_players():
		if player.has_node("SkillTree"):
			return (player.get_node("SkillTree") as Node).get_repair_cost_multiplier()
	return 1.0


func _get_socket_prep_cost_multiplier() -> float:
	for player in GameManager.get_all_registered_players():
		if player.has_node("SkillTree"):
			return (player.get_node("SkillTree") as Node).get_socket_prep_cost_multiplier()
	return 1.0


func can_repair_with_resources(instance_id: String) -> Dictionary:
	var entry := find_entry_by_instance(instance_id)
	if entry.is_empty():
		return {"ok": false, "reason": "Invalid item"}
	if not supports_durability(str(entry.id)):
		return {"ok": false, "reason": "This item cannot be repaired"}
	if float(entry.current_durability) >= float(entry.max_durability):
		return {"ok": false, "reason": "Item is already fully repaired"}
	for mat in get_repair_materials(entry, _get_repair_cost_multiplier()):
		if InventoryManager.get_combined_count(mat.id) < int(mat.quantity):
			return {"ok": false, "reason": "Missing %s x%d" % [ItemDatabase.get_display_name(mat.id), int(mat.quantity)]}
	return {"ok": true, "reason": ""}


func repair_with_resources(instance_id: String) -> Dictionary:
	var check := can_repair_with_resources(instance_id)
	if not check.ok:
		return check
	var entry := find_entry_by_instance(instance_id)
	for mat in get_repair_materials(entry, _get_repair_cost_multiplier()):
		if not InventoryManager.consume_combined(mat.id, int(mat.quantity)):
			return {"ok": false, "reason": "Missing materials"}
	entry.current_durability = float(entry.max_durability)
	entry.is_broken = false
	gear_changed.emit(instance_id)
	InventoryManager.inventory_changed.emit()
	_refresh_equipped_players()
	return {"ok": true, "reason": "", "name": get_display_name(entry)}


func use_repair_kit(instance_id: String) -> Dictionary:
	var entry := find_entry_by_instance(instance_id)
	if entry.is_empty():
		return {"ok": false, "reason": "No valid target"}
	if not supports_durability(str(entry.id)):
		return {"ok": false, "reason": "This item cannot be repaired"}
	if float(entry.current_durability) >= float(entry.max_durability):
		return {"ok": false, "reason": "Item is already fully repaired"}
	if not InventoryManager.has_item("repair_kit"):
		return {"ok": false, "reason": "No Repair Kit"}
	var restore := maxf(REPAIR_KIT_FLAT, float(entry.max_durability) * 0.4)
	entry.current_durability = minf(float(entry.max_durability), float(entry.current_durability) + restore)
	entry.is_broken = entry.current_durability <= 0.0
	if not InventoryManager.remove_item("repair_kit", 1):
		return {"ok": false, "reason": "Repair Kit use failed"}
	gear_changed.emit(instance_id)
	InventoryManager.inventory_changed.emit()
	_refresh_equipped_players()
	return {"ok": true, "reason": "", "name": get_display_name(entry)}


func can_upgrade_weapon(instance_id: String, use_kit: bool = false) -> Dictionary:
	var entry := find_entry_by_instance(instance_id)
	if entry.is_empty():
		return {"ok": false, "reason": "Invalid weapon"}
	if ItemDatabase.get_item(str(entry.id)).get("type") != "weapon":
		return {"ok": false, "reason": "Not a weapon"}
	if int(entry.upgrade_level) >= MAX_UPGRADE_LEVEL:
		return {"ok": false, "reason": "Maximum upgrade reached"}
	var next := int(entry.upgrade_level) + 1
	if next == 1 and BaseManager.get_station_level("workbench") < 2:
		return {"ok": false, "reason": "Workbench Level 2 Required"}
	if next >= 2 and BaseManager.get_station_level("forge") < 2:
		return {"ok": false, "reason": "Forge Level 2 Required"}
	if use_kit:
		if not InventoryManager.has_item("weapon_upgrade_kit"):
			return {"ok": false, "reason": "Missing Weapon Upgrade Kit"}
		return {"ok": true, "reason": ""}
	var mats := [
		{"id": "iron_scrap", "quantity": 5},
		{"id": "weapon_parts", "quantity": 1},
	]
	for mat in mats:
		if InventoryManager.get_combined_count(mat.id) < int(mat.quantity):
			return {"ok": false, "reason": "Missing %s x%d" % [ItemDatabase.get_display_name(mat.id), int(mat.quantity)]}
	if not CurrencyManager.can_afford_copper(25):
		return {"ok": false, "reason": "Need 25 Copper"}
	return {"ok": true, "reason": ""}


func upgrade_weapon(instance_id: String, use_kit: bool = false) -> Dictionary:
	var check := can_upgrade_weapon(instance_id, use_kit)
	if not check.ok:
		return check
	var entry := find_entry_by_instance(instance_id)
	if use_kit:
		if not InventoryManager.remove_item("weapon_upgrade_kit", 1):
			return {"ok": false, "reason": "Missing Weapon Upgrade Kit"}
	else:
		if not InventoryManager.consume_combined("iron_scrap", 5):
			return {"ok": false, "reason": "Missing Metal Scraps x5"}
		if not InventoryManager.consume_combined("weapon_parts", 1):
			return {"ok": false, "reason": "Missing Weapon Parts x1"}
		if not CurrencyManager.spend_copper(25):
			return {"ok": false, "reason": "Not enough currency"}
	entry.upgrade_level = int(entry.upgrade_level) + 1
	entry.max_durability = float(entry.max_durability) + UPGRADE_DURABILITY_BONUS
	entry.current_durability = minf(float(entry.current_durability) + UPGRADE_DURABILITY_BONUS, float(entry.max_durability))
	entry.is_broken = entry.current_durability <= 0.0
	gear_changed.emit(instance_id)
	InventoryManager.inventory_changed.emit()
	_refresh_equipped_players()
	return {"ok": true, "reason": "", "name": get_display_name(entry), "level": int(entry.upgrade_level)}


func can_reinforce_armor(instance_id: String, use_kit: bool = false) -> Dictionary:
	var entry := find_entry_by_instance(instance_id)
	if entry.is_empty():
		return {"ok": false, "reason": "Invalid armor"}
	if ItemDatabase.get_item(str(entry.id)).get("type") != "armor":
		return {"ok": false, "reason": "Not armor"}
	if int(entry.reinforcement_level) >= MAX_REINFORCE_LEVEL:
		return {"ok": false, "reason": "Maximum reinforcement reached"}
	if BaseManager.get_station_level("forge") < 2:
		return {"ok": false, "reason": "Forge Level 2 Required"}
	if use_kit:
		if not InventoryManager.has_item("armor_reinforcement_kit"):
			return {"ok": false, "reason": "Missing Armor Reinforcement Kit"}
		return {"ok": true, "reason": ""}
	var mats := [
		{"id": "hide", "quantity": 2},
		{"id": "armor_plates", "quantity": 1},
		{"id": "iron_scrap", "quantity": 3},
	]
	for mat in mats:
		if InventoryManager.get_combined_count(mat.id) < int(mat.quantity):
			return {"ok": false, "reason": "Missing %s x%d" % [ItemDatabase.get_display_name(mat.id), int(mat.quantity)]}
	return {"ok": true, "reason": ""}


func reinforce_armor(instance_id: String, use_kit: bool = false) -> Dictionary:
	var check := can_reinforce_armor(instance_id, use_kit)
	if not check.ok:
		return check
	var entry := find_entry_by_instance(instance_id)
	if use_kit:
		if not InventoryManager.remove_item("armor_reinforcement_kit", 1):
			return {"ok": false, "reason": "Missing Armor Reinforcement Kit"}
	else:
		if not InventoryManager.consume_combined("hide", 2):
			return {"ok": false, "reason": "Missing Hide x2"}
		if not InventoryManager.consume_combined("armor_plates", 1):
			return {"ok": false, "reason": "Missing Armor Plates x1"}
		if not InventoryManager.consume_combined("iron_scrap", 3):
			return {"ok": false, "reason": "Missing Metal Scraps x3"}
	entry.reinforcement_level = int(entry.reinforcement_level) + 1
	entry.max_durability = float(entry.max_durability) + UPGRADE_DURABILITY_BONUS
	entry.current_durability = minf(float(entry.current_durability) + UPGRADE_DURABILITY_BONUS, float(entry.max_durability))
	entry.is_broken = entry.current_durability <= 0.0
	gear_changed.emit(instance_id)
	InventoryManager.inventory_changed.emit()
	_refresh_equipped_players()
	return {"ok": true, "reason": "", "name": get_display_name(entry), "level": int(entry.reinforcement_level)}


func can_prepare_socket(instance_id: String) -> Dictionary:
	var entry := find_entry_by_instance(instance_id)
	if entry.is_empty():
		return {"ok": false, "reason": "Invalid item"}
	if not ItemDatabase.can_have_sockets(str(entry.id)):
		return {"ok": false, "reason": "This item cannot have sockets"}
	if int(entry.socket_count) >= int(entry.max_socket_count):
		return {"ok": false, "reason": "Maximum sockets reached"}
	if BaseManager.get_station_level("forge") < 2:
		return {"ok": false, "reason": "Forge Level 2 Required"}
	if InventoryManager.get_combined_count("crystal_shard") < 2:
		return {"ok": false, "reason": "Missing Crystal Shards x2"}
	if InventoryManager.get_combined_count("iron_scrap") < 2:
		return {"ok": false, "reason": "Missing Metal Scraps x2"}
	if not CurrencyManager.can_afford_copper(int(ceil(100 * _get_socket_prep_cost_multiplier()))):
		return {"ok": false, "reason": "Need 1 Silver"}
	return {"ok": true, "reason": ""}


func prepare_socket(instance_id: String) -> Dictionary:
	var check := can_prepare_socket(instance_id)
	if not check.ok:
		return check
	var entry := find_entry_by_instance(instance_id)
	if not InventoryManager.consume_combined("crystal_shard", 2):
		return {"ok": false, "reason": "Missing Crystal Shards x2"}
	if not InventoryManager.consume_combined("iron_scrap", 2):
		return {"ok": false, "reason": "Missing Metal Scraps x2"}
	var copper_cost := int(ceil(100 * _get_socket_prep_cost_multiplier()))
	if not CurrencyManager.spend_copper(copper_cost):
		return {"ok": false, "reason": "Need 1 Silver"}
	entry.socket_count = int(entry.socket_count) + 1
	entry.socket_prep_level = int(entry.socket_prep_level) + 1
	entry.socketed_gems = _sync_socket_array(entry)
	entry.socketed_gems[int(entry.socket_count) - 1] = ""
	gear_changed.emit(instance_id)
	InventoryManager.inventory_changed.emit()
	_refresh_equipped_players()
	return {"ok": true, "reason": "", "name": get_display_name(entry)}


func get_empty_socket_index(entry: Dictionary) -> int:
	var gems: Array = entry.get("socketed_gems", [])
	for i in gems.size():
		if str(gems[i]) == "":
			return i
	return -1


func has_empty_socket(entry: Dictionary) -> bool:
	return get_empty_socket_index(entry) >= 0


func get_inventory_gems() -> Array[String]:
	var out: Array[String] = []
	for gem_id in GemEffectManager.get_gem_item_ids():
		if InventoryManager.get_item_count(gem_id) > 0:
			out.append(gem_id)
	return out


func can_insert_gem(instance_id: String, gem_item_id: String, socket_index: int = -1) -> Dictionary:
	if BaseManager.get_station_level("forge") < 2:
		return {"ok": false, "reason": "Forge Level 2 Required"}
	var entry := find_entry_by_instance(instance_id)
	if entry.is_empty():
		return {"ok": false, "reason": "Invalid item"}
	if int(entry.get("socket_count", 0)) <= 0:
		return {"ok": false, "reason": "No empty sockets"}
	entry.socketed_gems = _sync_socket_array(entry)
	if not GemEffectManager.is_compatible(gem_item_id, entry):
		return {"ok": false, "reason": "Gem cannot be used on this item"}
	if not InventoryManager.has_item(gem_item_id):
		return {"ok": false, "reason": "Missing gem"}
	var idx := socket_index
	if idx < 0:
		idx = get_empty_socket_index(entry)
	if idx < 0 or idx >= entry.socketed_gems.size():
		return {"ok": false, "reason": "No empty sockets"}
	if str(entry.socketed_gems[idx]) != "":
		return {"ok": false, "reason": "Socket already filled"}
	return {"ok": true, "reason": ""}


func insert_gem(instance_id: String, gem_item_id: String, socket_index: int = -1) -> Dictionary:
	var check := can_insert_gem(instance_id, gem_item_id, socket_index)
	if not check.ok:
		return check
	var entry := find_entry_by_instance(instance_id)
	var idx := socket_index if socket_index >= 0 else get_empty_socket_index(entry)
	if not InventoryManager.remove_item(gem_item_id, 1):
		return {"ok": false, "reason": "Missing gem"}
	entry.socketed_gems[idx] = gem_item_id
	_apply_durability_cap_from_gems(entry)
	gear_changed.emit(instance_id)
	InventoryManager.inventory_changed.emit()
	_refresh_equipped_players()
	return {
		"ok": true,
		"reason": "",
		"gear_name": get_display_name(entry),
		"gem_name": GemEffectManager.get_display_name(gem_item_id),
	}


func can_remove_gem(instance_id: String, socket_index: int, recover: bool = false) -> Dictionary:
	if BaseManager.get_station_level("forge") < 2:
		return {"ok": false, "reason": "Forge Level 2 Required"}
	var entry := find_entry_by_instance(instance_id)
	if entry.is_empty():
		return {"ok": false, "reason": "Invalid item"}
	entry.socketed_gems = _sync_socket_array(entry)
	if socket_index < 0 or socket_index >= entry.socketed_gems.size():
		return {"ok": false, "reason": "No gem in this socket"}
	var gem_id := str(entry.socketed_gems[socket_index])
	if gem_id == "":
		return {"ok": false, "reason": "No gem in this socket"}
	if recover:
		var cost := GemEffectManager.get_removal_cost_copper(gem_id, true)
		if not CurrencyManager.can_afford_copper(cost):
			if cost >= 100:
				return {"ok": false, "reason": "Need 1 Silver to recover gem"}
			return {"ok": false, "reason": "Need %d Copper to recover gem" % cost}
	return {"ok": true, "reason": "", "gem_id": gem_id}


func remove_gem(instance_id: String, socket_index: int, recover: bool = false) -> Dictionary:
	var check := can_remove_gem(instance_id, socket_index, recover)
	if not check.ok:
		return check
	var entry := find_entry_by_instance(instance_id)
	var gem_id := str(entry.socketed_gems[socket_index])
	var gem_name := GemEffectManager.get_display_name(gem_id)
	if recover:
		var cost := GemEffectManager.get_removal_cost_copper(gem_id, true)
		if not CurrencyManager.spend_copper(cost):
			return {"ok": false, "reason": "Not enough currency"}
		if not InventoryManager.add_item(gem_id, 1):
			return {"ok": false, "reason": "Inventory full"}
		entry.socketed_gems[socket_index] = ""
		_apply_durability_cap_from_gems(entry)
		gear_changed.emit(instance_id)
		InventoryManager.inventory_changed.emit()
		_refresh_equipped_players()
		return {"ok": true, "reason": "", "gem_name": gem_name, "gear_name": get_display_name(entry), "recovered": true}
	entry.socketed_gems[socket_index] = ""
	_apply_durability_cap_from_gems(entry)
	gear_changed.emit(instance_id)
	InventoryManager.inventory_changed.emit()
	_refresh_equipped_players()
	return {"ok": true, "reason": "", "gem_name": gem_name, "gear_name": get_display_name(entry), "recovered": false}


func _apply_durability_cap_from_gems(entry: Dictionary) -> void:
	var effective_max := get_effective_max_durability(entry)
	entry.max_durability = effective_max
	entry.current_durability = minf(float(entry.current_durability), effective_max)
	entry.is_broken = entry.current_durability <= 0.0


func get_repairable_instances() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var seen: Dictionary = {}
	for entry in InventoryManager.items:
		if not supports_durability(str(entry.id)):
			continue
		var iid := str(entry.get("instance_id", ""))
		if iid == "" or seen.has(iid):
			continue
		seen[iid] = true
		out.append(entry)
	for slot in InventoryManager.equipment.keys():
		var entry := get_equipped_instance(str(slot))
		if entry.is_empty():
			continue
		var iid := str(entry.get("instance_id", ""))
		if iid != "" and not seen.has(iid):
			seen[iid] = true
			out.append(entry)
	return out


func format_gear_detail(entry: Dictionary) -> String:
	if entry.is_empty():
		return ""
	var lines: PackedStringArray = [get_display_name(entry)]
	lines.append("Rarity: %s" % ItemDatabase.get_rarity_label(str(entry.id)))
	var cur := int(entry.get("current_durability", 0))
	var max_d := int(get_effective_max_durability(entry))
	lines.append("Durability %d / %d" % [cur, max_d])
	if bool(entry.get("is_broken", false)):
		lines.append("Broken")
	var upgrade := int(entry.get("upgrade_level", 0))
	var reinforce := int(entry.get("reinforcement_level", 0))
	if upgrade > 0:
		lines.append("Upgrade +%d" % upgrade)
	if reinforce > 0:
		lines.append("Reinforcement +%d" % reinforce)
	for socket_line in GemEffectManager.format_socket_lines(entry):
		lines.append(socket_line)
	var passives := GemEffectManager.get_gear_gem_modifiers(entry)
	if float(passives.get("resource_discovery_bonus", 0.0)) > 0.0:
		lines.append("Resource Discovery +%.0f%%" % (float(passives.resource_discovery_bonus) * 100.0))
	if float(passives.get("currency_gain_bonus", 0.0)) > 0.0:
		lines.append("Currency Gain +%.0f%%" % (float(passives.currency_gain_bonus) * 100.0))
	if float(passives.get("focus_max", 0.0)) > 0.0:
		lines.append("Focus Max +%.0f" % float(passives.focus_max))
	return "\n".join(lines)


func show_gear_toast(message: String, priority: int = NotificationToast.Priority.NORMAL) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var owner_idx := GameManager.menu_owner_index if GameManager.menu_owner_index >= 0 else GameManager.interacting_player_index
	var text := message
	if GameManager.is_local_coop() and owner_idx >= 0 and not message.begins_with("P"):
		text = "%s %s" % [_CoopUiCopy.player_tag(owner_idx), message]
	for hud in tree.get_nodes_in_group("game_hud"):
		if hud.has_method("show_toast"):
			hud.show_toast(text, 2.5, "", "notification", "", priority)
			return
