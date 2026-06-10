class_name DungeonTreasureChest
extends InteractableBase

var _opened: bool = false


func _ready() -> void:
	super._ready()
	prompt_text = "Open Treasure Chest"


func _on_interact(_player: Node) -> void:
	if _opened:
		return
	_opened = true
	LootManager.drop_loot_table("dungeon_treasure", global_position)
	LootManager.drop_currency(50 + DungeonManager.depth * 25, global_position + Vector3(0.5, 0, 0))
	prompt_text = "Empty Chest"
	AchievementManager.unlock("not_just_a_box")
