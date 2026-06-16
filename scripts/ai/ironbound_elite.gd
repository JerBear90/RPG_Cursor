extends EnemyBase
## Armored gate guardian — drops foundry access key once.

var _key_dropped: bool = false


func _on_died() -> void:
	if not _key_dropped and enemy_id == "ironbound_elite":
		_key_dropped = true
		if QuestManager.active_quests.has("fires_below"):
			QuestManager.advance_objective("fires_below", "recover_key", 1)
		if not InventoryManager.has_item("blackvein_access_key"):
			InventoryManager.add_item("blackvein_access_key", 1)
	super._on_died()
