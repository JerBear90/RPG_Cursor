class_name ItemData
extends Resource
## Base item resource for future expansion.

enum ItemCategory {
	WEAPON, ARMOR, SHIELD, RING, CHARM, MASK, PET_GEAR, GEM,
	CONSUMABLE, FOOD, WATER, RESOURCE, CURRENCY, RELIC, KEY_ITEM, QUEST_ITEM,
}

enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

@export var item_id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var category: ItemCategory = ItemCategory.RESOURCE
@export var rarity: Rarity = Rarity.COMMON
@export var max_stack: int = 99
@export var icon: Texture2D
