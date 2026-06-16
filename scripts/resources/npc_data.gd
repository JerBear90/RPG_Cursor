class_name NpcData
extends Resource
## Named NPC definition resource.

@export var npc_id: String = ""
@export var display_name: String = ""
@export var role: String = ""
@export var faction: String = "exiles"
@export var is_merchant: bool = false
@export var is_quest_giver: bool = false
@export var available_missions: Array[String] = []
@export var shop_inventory_id: String = ""
@export var dialogue_set_id: String = ""
