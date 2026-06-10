extends Node
## In-game achievements (Steam-ready hooks).

signal achievement_unlocked(id: String)

const DISPLAY_NAMES: Dictionary = {
	"two_exiles_one_fate": "Two Exiles, One Fate",
	"waystone_awakened": "Waystone Awakened",
	"spellbound": "Spellbound",
	"stay_down": "Stay Down",
	"angry_vendor": "Angry Vendor",
	"break_everything": "Break Everything",
	"first_blood": "First Blood",
	"hollow_grove_broken": "Hollow Grove Broken",
	"forge_friend": "Forge Friend",
	"not_just_a_box": "Not Just a Box",
	"loyal_companion": "Loyal Companion",
	"dungeon_delver": "Dungeon Delver",
}

var unlocked: Array[String] = []


func get_display_name(achievement_id: String) -> String:
	return DISPLAY_NAMES.get(achievement_id, achievement_id.replace("_", " ").capitalize())


func reset_for_new_game() -> void:
	unlocked.clear()


func unlock(achievement_id: String) -> void:
	if achievement_id in unlocked:
		return
	unlocked.append(achievement_id)
	achievement_unlocked.emit(achievement_id)
	# Steam hook placeholder: Steam.setAchievement(achievement_id)


func is_unlocked(achievement_id: String) -> bool:
	return achievement_id in unlocked


func serialize() -> Dictionary:
	return {"unlocked": unlocked.duplicate()}


func deserialize(data: Dictionary) -> void:
	unlocked = data.get("unlocked", [])
