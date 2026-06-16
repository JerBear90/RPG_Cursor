extends Node
## Shared party inventory and equipment.

const _StatusEffects := preload("res://scripts/combat/status_effects_component.gd")

signal inventory_changed
signal equipment_changed(slot: String)

enum EquipmentSlot {
	MAIN_WEAPON, OFFHAND, HELMET, CHEST, GLOVES, BOOTS,
	RING_1, RING_2, CHARM, MASK, PET_GEAR,
}

var items: Array[Dictionary] = []
var equipment: Dictionary = {}
var quick_slots: Array[String] = ["", "", "", ""]
var base_storage: Array[Dictionary] = []
const MAX_STACK := 99
const MAX_UNIQUE_SLOTS := 40


func _ready() -> void:
	reset_for_new_game()


func reset_for_new_game() -> void:
	items.clear()
	equipment.clear()
	base_storage.clear()
	quick_slots = ["", "", "", ""]
	EquipmentManager.reset_for_new_game()
	_add_starter_gear()
	inventory_changed.emit()


func _add_starter_gear() -> void:
	add_item("rusty_sword", 1)
	add_item("traveler_cloak", 1)
	add_item("bandage", 2)
	add_item("dried_rations", 3)
	add_item("waterskin", 2)
	add_item("wood", 10)
	add_item("stone", 5)
	equip("rusty_sword", "main_weapon")
	equip("traveler_cloak", "chest")
	if has_item("bandage"):
		quick_slots[0] = "bandage"


func add_item(item_id: String, quantity: int = 1) -> bool:
	var check := can_add_item(item_id, quantity)
	if not check.get("ok", false):
		return false
	for entry in items:
		if entry.id == item_id and _is_stackable(item_id):
			entry.quantity = mini(entry.quantity + quantity, MAX_STACK)
			inventory_changed.emit()
			return true
	items.append(EquipmentManager.create_gear_entry(item_id) if EquipmentManager.supports_durability(item_id) else {"id": item_id, "quantity": quantity, "durability": 100.0, "locked": false})
	inventory_changed.emit()
	return true


func can_add_item(item_id: String, quantity: int = 1) -> Dictionary:
	if quantity <= 0:
		return {"ok": false, "reason": "Invalid quantity"}
	if _is_stackable(item_id):
		for entry in items:
			if entry.id == item_id:
				if entry.quantity + quantity <= MAX_STACK:
					return {"ok": true}
				return {"ok": false, "reason": "Inventory full"}
		if _unique_slot_count() >= MAX_UNIQUE_SLOTS:
			return {"ok": false, "reason": "Inventory full"}
		return {"ok": true}
	for _i in range(quantity):
		if _unique_slot_count() >= MAX_UNIQUE_SLOTS:
			return {"ok": false, "reason": "Inventory full"}
	return {"ok": true}


func get_max_add_quantity(item_id: String) -> int:
	if not _is_stackable(item_id):
		var slots := MAX_UNIQUE_SLOTS - _unique_slot_count()
		return maxi(slots, 0)
	for entry in items:
		if entry.id == item_id:
			return MAX_STACK - int(entry.quantity)
	if _unique_slot_count() >= MAX_UNIQUE_SLOTS:
		return 0
	return MAX_STACK


func is_equipped(item_id: String) -> bool:
	for slot in equipment.keys():
		var val: String = str(equipment[slot])
		if val == item_id:
			return true
		var entry := EquipmentManager.find_entry_by_instance(val)
		if not entry.is_empty() and entry.id == item_id:
			return true
	return false


func is_item_locked(item_id: String) -> bool:
	for entry in items:
		if entry.id == item_id and entry.get("locked", false):
			return true
	return false


func get_sellable_quantity(item_id: String) -> Dictionary:
	if ItemDatabase.is_quest_item(item_id):
		return {"ok": false, "reason": "Quest item", "quantity": 0}
	if is_equipped(item_id):
		return {"ok": false, "reason": "Currently equipped", "quantity": 0}
	if is_item_locked(item_id):
		return {"ok": false, "reason": "Item is locked", "quantity": 0}
	var owned := get_item_count(item_id)
	if owned <= 0:
		return {"ok": false, "reason": "Not owned", "quantity": 0}
	return {"ok": true, "reason": "", "quantity": owned}


func _unique_slot_count() -> int:
	return items.size()


func remove_item(item_id: String, quantity: int = 1) -> bool:
	for i in items.size():
		if items[i].id == item_id:
			if items[i].quantity < quantity:
				return false
			items[i].quantity -= quantity
			if items[i].quantity <= 0:
				items.remove_at(i)
			inventory_changed.emit()
			return true
	return false


func has_item(item_id: String, quantity: int = 1) -> bool:
	var total := 0
	for entry in items:
		if entry.id == item_id:
			total += entry.quantity
	return total >= quantity


func get_item_count(item_id: String) -> int:
	var total := 0
	for entry in items:
		if entry.id == item_id:
			total += entry.quantity
	return total


func get_base_count(item_id: String) -> int:
	var total := 0
	for entry in base_storage:
		if entry.id == item_id:
			total += entry.quantity
	return total


func get_combined_count(item_id: String) -> int:
	return get_item_count(item_id) + get_base_count(item_id)


func consume_combined(item_id: String, quantity: int) -> bool:
	if get_combined_count(item_id) < quantity:
		return false
	var remaining := quantity
	var from_inventory := mini(remaining, get_item_count(item_id))
	if from_inventory > 0:
		remove_item(item_id, from_inventory)
		remaining -= from_inventory
	if remaining > 0 and not _remove_from_base_only(item_id, remaining):
		return false
	inventory_changed.emit()
	return true


func _remove_from_base_only(item_id: String, quantity: int) -> bool:
	if get_base_count(item_id) < quantity:
		return false
	var remaining := quantity
	var i := 0
	while i < base_storage.size() and remaining > 0:
		if base_storage[i].id != item_id:
			i += 1
			continue
		var take := mini(remaining, int(base_storage[i].quantity))
		base_storage[i].quantity -= take
		remaining -= take
		if base_storage[i].quantity <= 0:
			base_storage.remove_at(i)
		else:
			i += 1
	return remaining <= 0


func can_deposit_to_base(item_id: String) -> Dictionary:
	return get_sellable_quantity(item_id)


func try_send_to_base(item_id: String, quantity: int = 1) -> Dictionary:
	var check := can_deposit_to_base(item_id)
	if not check.ok:
		return check
	var qty := mini(quantity, int(check.quantity))
	if qty <= 0:
		return {"ok": false, "reason": "Nothing to store", "quantity": 0}
	if not send_to_base(item_id, qty):
		return {"ok": false, "reason": "Deposit failed", "quantity": 0}
	return {"ok": true, "reason": "", "quantity": qty, "id": item_id}


func deposit_all_eligible_materials() -> Dictionary:
	var deposited: Array[Dictionary] = []
	var ids: Array[String] = []
	for entry in items:
		if entry.id not in ids:
			ids.append(entry.id)
	for item_id in ids:
		if str(ItemDatabase.get_item(item_id).get("type", "")) != "material":
			continue
		var check := can_deposit_to_base(item_id)
		if not check.ok:
			continue
		var result := try_send_to_base(item_id, int(check.quantity))
		if result.ok:
			deposited.append({"id": item_id, "quantity": int(result.quantity)})
	return {"ok": not deposited.is_empty(), "items": deposited}


func send_to_base(item_id: String, quantity: int = 1) -> bool:
	var check := can_deposit_to_base(item_id)
	if not check.ok:
		return false
	var qty := mini(quantity, int(check.quantity))
	if qty <= 0:
		return false
	if not remove_item(item_id, qty):
		return false
	for entry in base_storage:
		if entry.id == item_id:
			entry.quantity += qty
			inventory_changed.emit()
			return true
	base_storage.append({"id": item_id, "quantity": qty})
	inventory_changed.emit()
	return true


func equip(item_id: String, slot: String) -> void:
	if not has_item(item_id):
		return
	slot = ItemDatabase.normalize_equipment_slot(slot)
	var instance_id := EquipmentManager.find_first_instance_id(item_id)
	if instance_id != "":
		equipment[slot] = instance_id
	else:
		equipment[slot] = item_id
	equipment_changed.emit(slot)
	inventory_changed.emit()


func use_item(item_id: String, player: Node) -> bool:
	if not has_item(item_id) or player == null:
		return false
	var data := ItemDatabase.get_item(item_id)
	if not ItemDatabase.can_use(item_id):
		return false
	match data.get("use"):
		"eat":
			if player.has_node("SurvivalNeedsComponent"):
				(player.get_node("SurvivalNeedsComponent") as SurvivalNeedsComponent).eat(float(data.amount))
				remove_item(item_id, 1)
				return true
		"drink":
			if player.has_node("SurvivalNeedsComponent"):
				(player.get_node("SurvivalNeedsComponent") as SurvivalNeedsComponent).drink(float(data.amount))
				remove_item(item_id, 1)
				return true
		"heal":
			if player.has_node("HealthComponent"):
				(player.get_node("HealthComponent") as HealthComponent).heal(float(data.amount))
				remove_item(item_id, 1)
				return true
		"repair_kit":
			return _use_repair_kit(player)
		"weapon_upgrade_kit":
			return _use_weapon_upgrade_kit(player)
		"armor_reinforcement_kit":
			return _use_armor_reinforcement_kit(player)
		"antidote":
			if player.has_node("HealthComponent"):
				(player.get_node("HealthComponent") as HealthComponent).heal(float(data.amount))
			if player.has_node("StatusEffectsComponent"):
				var status := player.get_node("StatusEffectsComponent") as _StatusEffects
				status.clear_poison()
				status.apply_resistance_bonus(90.0)
			remove_item(item_id, 1)
			return true
		"heat_resist":
			if player.has_node("HealthComponent"):
				(player.get_node("HealthComponent") as HealthComponent).heal(float(data.amount))
			if player.has_node("StatusEffectsComponent"):
				var heat_status := player.get_node("StatusEffectsComponent") as _StatusEffects
				heat_status.clear_environmental()
				heat_status.apply_heat_resistance_bonus(90.0)
			remove_item(item_id, 1)
			return true
		"cold_resist":
			if player.has_node("HealthComponent"):
				(player.get_node("HealthComponent") as HealthComponent).heal(float(data.amount))
			if player.has_node("StatusEffectsComponent"):
				var cold_status := player.get_node("StatusEffectsComponent") as _StatusEffects
				cold_status.clear_cold()
				cold_status.apply_cold_resistance_bonus(90.0)
			remove_item(item_id, 1)
			return true
		"blight_resist":
			if player.has_node("HealthComponent"):
				(player.get_node("HealthComponent") as HealthComponent).heal(float(data.amount))
			if player.has_node("StatusEffectsComponent"):
				var blight_status := player.get_node("StatusEffectsComponent") as _StatusEffects
				blight_status.clear_blight_exposure()
				blight_status.apply_blight_resistance_bonus(90.0)
			remove_item(item_id, 1)
			return true
		"spore_resist":
			if player.has_node("StatusEffectsComponent"):
				var spore_status := player.get_node("StatusEffectsComponent") as _StatusEffects
				spore_status.clear_spore()
				spore_status.apply_blight_resistance_bonus(90.0)
			remove_item(item_id, 1)
			return true
		"dread_resist":
			if player.has_node("HealthComponent"):
				(player.get_node("HealthComponent") as HealthComponent).heal(float(data.amount))
			if player.has_node("StatusEffectsComponent"):
				var dread_status := player.get_node("StatusEffectsComponent") as _StatusEffects
				dread_status.clear_dread()
				dread_status.apply_dread_resistance_bonus(90.0)
			remove_item(item_id, 1)
			return true
		"shadow_cleanse":
			if player.has_node("HealthComponent"):
				(player.get_node("HealthComponent") as HealthComponent).heal(float(data.amount))
			if player.has_node("StatusEffectsComponent"):
				var shadow_status := player.get_node("StatusEffectsComponent") as _StatusEffects
				shadow_status.clear_dominion_exposure()
			remove_item(item_id, 1)
			return true
	return false


func equip_item(item_id: String, player: Node) -> bool:
	if not has_item(item_id) or not ItemDatabase.can_equip(item_id):
		return false
	var data := ItemDatabase.get_item(item_id)
	var slot: String = ItemDatabase.normalize_equipment_slot(str(data.get("slot", "main_weapon")))
	var instance_id := EquipmentManager.find_first_instance_id(item_id)
	if instance_id != "":
		EquipmentManager.equip_instance(instance_id, slot)
	else:
		equip(item_id, slot)
	if player:
		PlayerProgress._apply_equipment_stats(player)
	return true


func withdraw_from_base(item_id: String, quantity: int = 1) -> bool:
	for i in base_storage.size():
		if base_storage[i].id == item_id:
			if base_storage[i].quantity < quantity:
				return false
			base_storage[i].quantity -= quantity
			if base_storage[i].quantity <= 0:
				base_storage.remove_at(i)
			add_item(item_id, quantity)
			return true
	return false


func deposit_to_base(item_id: String, quantity: int = 1) -> bool:
	return send_to_base(item_id, quantity)


func _is_stackable(item_id: String) -> bool:
	if ItemDatabase.is_stackable(item_id):
		return true
	var consumables := ["wood", "stone", "copper", "dried_rations", "waterskin", "herb_bundle", "bandage", "purified_water", "repair_kit", "bogward_tonic", "heat_resistance_tonic", "ash_filter_mask", "warming_tonic", "storm_resistance_tonic", "blight_resistance_tonic", "spore_filter", "cleansing_salve", "spore_antidote", "corruption_cleanse", "regeneration_salve", "torch", "bog_herb", "cinder_ore", "ashwood", "blackvein_iron", "machine_scrap", "ember_crystal", "volcanic_glass", "furnace_core", "burned_hide", "swamp_iron", "mire_crystal", "poison_gland", "rotwood", "frostwood", "rime_ore", "black_ice", "glacial_crystal", "frozen_hide", "grave_dust", "paleheart_shard", "driftwood", "salt_iron", "stormglass", "abyssal_pearl", "kelp_fiber", "barnacle_plate", "drowned_relic", "leviathan_bone", "blightwood", "sporecap", "corrupted_fiber", "purified_resin", "root_iron", "viridian_crystal", "fungal_gland", "ancient_bark", "silverwood", "umbral_ore", "moonstone", "nightglass", "shadow_hide", "ward_candle", "dread_resistance_tonic", "shadow_cleanse", "lantern_oil", "scorched_sand", "sunstone_shard", "glass_fragment", "pyre_dust", "cactus_fiber", "hydration_salts", "cooling_salve", "burn_salve", "sand_lung_remedy", "desert_glass", "pyre_crystal"]
	return item_id in consumables


func serialize() -> Dictionary:
	return {
		"items": items.duplicate(true),
		"equipment": equipment.duplicate(),
		"quick_slots": quick_slots.duplicate(),
		"base_storage": base_storage.duplicate(true),
	}


func deserialize(data: Dictionary) -> void:
	if data.has("items"):
		items = data.items
	if data.has("equipment"):
		equipment = data.equipment
	if data.has("quick_slots"):
		quick_slots = data.quick_slots
	if data.has("base_storage"):
		base_storage = data.base_storage
	EquipmentManager.normalize_all_items()
	EquipmentManager.migrate_equipment_slots()
	inventory_changed.emit()


func _use_repair_kit(player: Node) -> bool:
	var target := _pick_repair_target()
	if target == "":
		EquipmentManager.show_gear_toast("No damaged gear to repair", NotificationToast.Priority.IMPORTANT)
		return false
	var result := EquipmentManager.use_repair_kit(target)
	if result.ok:
		EquipmentManager.show_gear_toast("used Repair Kit on %s" % result.name, NotificationToast.Priority.IMPORTANT)
		if player:
			PlayerProgress._apply_equipment_stats(player)
		return true
	if result.reason != "":
		EquipmentManager.show_gear_toast(result.reason, NotificationToast.Priority.IMPORTANT)
	return false


func _use_weapon_upgrade_kit(player: Node) -> bool:
	var entry := EquipmentManager.get_equipped_instance("main_weapon")
	if entry.is_empty():
		EquipmentManager.show_gear_toast("Equip a weapon first", NotificationToast.Priority.IMPORTANT)
		return false
	var result := EquipmentManager.upgrade_weapon(str(entry.instance_id), true)
	if result.ok:
		EquipmentManager.show_gear_toast("upgraded %s to +%d" % [result.name, int(result.level)], NotificationToast.Priority.IMPORTANT)
		if player:
			PlayerProgress._apply_equipment_stats(player)
		return true
	if result.reason != "":
		EquipmentManager.show_gear_toast(result.reason, NotificationToast.Priority.IMPORTANT)
	return false


func _use_armor_reinforcement_kit(player: Node) -> bool:
	var entry := EquipmentManager.get_equipped_instance("chest")
	if entry.is_empty():
		EquipmentManager.show_gear_toast("Equip chest armor first", NotificationToast.Priority.IMPORTANT)
		return false
	var result := EquipmentManager.reinforce_armor(str(entry.instance_id), true)
	if result.ok:
		EquipmentManager.show_gear_toast("reinforced %s to +%d" % [result.name, int(result.level)], NotificationToast.Priority.IMPORTANT)
		if player:
			PlayerProgress._apply_equipment_stats(player)
		return true
	if result.reason != "":
		EquipmentManager.show_gear_toast(result.reason, NotificationToast.Priority.IMPORTANT)
	return false


func _pick_repair_target() -> String:
	for slot in ["main_weapon", "offhand", "chest", "helmet", "gloves", "boots"]:
		var entry := EquipmentManager.get_equipped_instance(slot)
		if entry.is_empty():
			continue
		if float(entry.current_durability) < float(entry.max_durability):
			return str(entry.instance_id)
	for entry in items:
		if EquipmentManager.supports_durability(str(entry.id)):
			if float(entry.get("current_durability", 0.0)) < float(entry.get("max_durability", 0.0)):
				return str(entry.get("instance_id", ""))
	return ""
