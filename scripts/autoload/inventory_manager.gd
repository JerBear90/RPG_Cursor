extends Node
## Shared party inventory and equipment.

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


func _ready() -> void:
	reset_for_new_game()


func reset_for_new_game() -> void:
	items.clear()
	equipment.clear()
	base_storage.clear()
	quick_slots = ["", "", "", ""]
	_add_starter_gear()
	inventory_changed.emit()


func _add_starter_gear() -> void:
	add_item("rusty_sword", 1)
	add_item("traveler_cloak", 1)
	add_item("dried_rations", 3)
	add_item("waterskin", 2)
	add_item("wood", 10)
	add_item("stone", 5)


func add_item(item_id: String, quantity: int = 1) -> bool:
	for entry in items:
		if entry.id == item_id and _is_stackable(item_id):
			entry.quantity = mini(entry.quantity + quantity, MAX_STACK)
			inventory_changed.emit()
			return true
	items.append({"id": item_id, "quantity": quantity, "durability": 100.0, "locked": false})
	inventory_changed.emit()
	return true


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


func send_to_base(item_id: String, quantity: int = 1) -> bool:
	if not remove_item(item_id, quantity):
		return false
	for entry in base_storage:
		if entry.id == item_id:
			entry.quantity += quantity
			inventory_changed.emit()
			return true
	base_storage.append({"id": item_id, "quantity": quantity})
	inventory_changed.emit()
	return true


func equip(item_id: String, slot: String) -> void:
	equipment[slot] = item_id
	equipment_changed.emit(slot)


func _is_stackable(item_id: String) -> bool:
	var consumables := ["wood", "stone", "copper", "dried_rations", "waterskin", "herb_bundle"]
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
	inventory_changed.emit()
