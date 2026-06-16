class_name SpellTreeController
extends RefCounted
## Quick-spell selection state for a caster.

var unlocked_spells: Array[String] = ["ember_bolt"]
var equipped_spells: Array[String] = ["ember_bolt"]
var quick_spell_index: int = 0


func refresh_equipped() -> void:
	equipped_spells = unlocked_spells.duplicate()
	if equipped_spells.is_empty():
		equipped_spells = []
	if quick_spell_index >= equipped_spells.size():
		quick_spell_index = 0


func unlock(spell_id: String, all_spells: Array[String]) -> bool:
	if spell_id not in all_spells or spell_id in unlocked_spells:
		return false
	unlocked_spells.append(spell_id)
	refresh_equipped()
	return true


func get_active_spell_id() -> String:
	if equipped_spells.is_empty():
		return ""
	return equipped_spells[quick_spell_index]


func select_index(index: int) -> void:
	if index >= 0 and index < equipped_spells.size():
		quick_spell_index = index


func cycle(direction: int) -> void:
	if equipped_spells.is_empty():
		return
	quick_spell_index = (quick_spell_index + direction) % equipped_spells.size()
	if quick_spell_index < 0:
		quick_spell_index += equipped_spells.size()


func serialize() -> Dictionary:
	return {"unlocked": unlocked_spells.duplicate(), "quick_index": quick_spell_index}


func deserialize(data: Dictionary, all_spells: Array[String]) -> void:
	unlocked_spells.clear()
	for entry in data.get("unlocked", ["ember_bolt"]):
		var spell_id := str(entry)
		if spell_id in all_spells:
			unlocked_spells.append(spell_id)
	if unlocked_spells.is_empty():
		unlocked_spells = ["ember_bolt"]
	quick_spell_index = int(data.get("quick_index", 0))
	refresh_equipped()
