extends Node
## Memory masks unlocked by quests and equipped at the Mask Stand.

signal mask_equipped(mask_id: String)
signal mask_unlocked(mask_id: String)

const MASKS: Dictionary = {
	"wolf_mask": {
		"name": "Wolf Crest Mask",
		"unlock_quest": "find_wolf_crest",
		"health": 15.0,
		"focus": 10.0,
		"desc": "The crest's spirit lends endurance.",
	},
	"exile_mask": {
		"name": "Exile's Resolve",
		"unlock_quest": "merchant_errand",
		"stamina": 15.0,
		"desc": "Hardship tempered into grit.",
	},
	"warden_mask": {
		"name": "Grove Warden Visage",
		"unlock_quest": "defeat_warden",
		"damage": 8.0,
		"desc": "Hollow power bound to your will.",
	},
}

var unlocked_masks: Array[String] = []
var equipped_mask: String = ""


func reset_for_new_game() -> void:
	unlocked_masks.clear()
	equipped_mask = ""


func sync_unlocks_from_quests() -> void:
	for mask_id in MASKS.keys():
		var quest_id: String = MASKS[mask_id].unlock_quest
		if quest_id in QuestManager.completed_quests and mask_id not in unlocked_masks:
			unlocked_masks.append(mask_id)
			mask_unlocked.emit(mask_id)


func get_available_masks() -> Array[String]:
	sync_unlocks_from_quests()
	return unlocked_masks.duplicate()


func equip_mask(mask_id: String, player: Node) -> bool:
	if mask_id != "" and mask_id not in unlocked_masks:
		return false
	equipped_mask = mask_id
	if player:
		PlayerProgress.apply_mask_bonuses(player)
	mask_equipped.emit(mask_id)
	return true


func get_mask_summary(mask_id: String) -> String:
	if not MASKS.has(mask_id):
		return ""
	var data: Dictionary = MASKS[mask_id]
	var parts: PackedStringArray = [data.name, data.desc]
	if data.has("health"):
		parts.append("+%d max health" % int(data.health))
	if data.has("stamina"):
		parts.append("+%d max stamina" % int(data.stamina))
	if data.has("focus"):
		parts.append("+%d max focus" % int(data.focus))
	if data.has("damage"):
		parts.append("+%d physical damage" % int(data.damage))
	return "\n".join(parts)


func get_stat_bonuses() -> Dictionary:
	if equipped_mask == "" or not MASKS.has(equipped_mask):
		return {}
	var data: Dictionary = MASKS[equipped_mask]
	return {
		"health": float(data.get("health", 0.0)),
		"stamina": float(data.get("stamina", 0.0)),
		"focus": float(data.get("focus", 0.0)),
		"damage": float(data.get("damage", 0.0)),
	}


func serialize() -> Dictionary:
	return {"unlocked": unlocked_masks.duplicate(), "equipped": equipped_mask}


func deserialize(data: Dictionary) -> void:
	unlocked_masks.clear()
	for entry in data.get("unlocked", []):
		unlocked_masks.append(str(entry))
	equipped_mask = str(data.get("equipped", ""))
