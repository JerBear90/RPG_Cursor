extends Node
## Item metadata for use, equip, and combat bonuses.

const ITEMS: Dictionary = {
	"dried_rations": {"type": "consumable", "use": "eat", "amount": 35.0, "label": "Eat"},
	"waterskin": {"type": "consumable", "use": "drink", "amount": 30.0, "label": "Drink"},
	"purified_water": {"type": "consumable", "use": "drink", "amount": 50.0, "label": "Drink"},
	"bandage": {"type": "consumable", "use": "heal", "amount": 25.0, "label": "Use"},
	"herb_bundle": {"type": "consumable", "use": "heal", "amount": 15.0, "label": "Use"},
	"rusty_sword": {"type": "weapon", "slot": "main_weapon", "damage": 12.0, "label": "Equip"},
	"iron_sword": {"type": "weapon", "slot": "main_weapon", "damage": 22.0, "label": "Equip"},
	"epic_blade": {"type": "weapon", "slot": "main_weapon", "damage": 35.0, "label": "Equip"},
	"traveler_cloak": {"type": "armor", "slot": "chest", "health": 10.0, "label": "Equip"},
	"wolf_crest": {"type": "quest", "label": "Quest item"},
	"wood": {"type": "material"},
	"stone": {"type": "material"},
	"cloth_scrap": {"type": "material"},
	"iron_scrap": {"type": "material"},
	"nails": {"type": "material"},
	"grove_heart": {"type": "material"},
	"repair_kit": {"type": "consumable", "use": "repair", "amount": 30.0, "label": "Use"},
}


static func get_item(item_id: String) -> Dictionary:
	return ITEMS.get(item_id, {})


static func can_use(item_id: String) -> bool:
	var data := get_item(item_id)
	return data.get("type") == "consumable" and data.has("use")


static func can_equip(item_id: String) -> bool:
	var data := get_item(item_id)
	return data.get("type") in ["weapon", "armor"]


static func get_weapon_damage(item_id: String) -> float:
	return float(get_item(item_id).get("damage", 0.0))


static func get_armor_health_bonus(item_id: String) -> float:
	return float(get_item(item_id).get("health", 0.0))
