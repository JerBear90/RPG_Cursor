extends EnemyBase
## Elite frost guardian — drops crypt access key for Gravewind Rising.

var _key_dropped: bool = false


func _on_died() -> void:
	if not _key_dropped and enemy_id == "frostbound_giant":
		_key_dropped = true
		if QuestManager.active_quests.has("gravewind_rising"):
			QuestManager.advance_objective("gravewind_rising", "recover_seals", 1)
			QuestManager.advance_objective("gravewind_rising", "unlock_crypt", 1)
		if not InventoryManager.has_item("paleheart_access_key"):
			InventoryManager.add_item("paleheart_access_key", 1)
	super._on_died()
