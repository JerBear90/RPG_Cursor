extends RefCounted
class_name NpcMissionRegistry
## Static NPC mission metadata — quest_id links to QuestManager.

const MISSIONS: Dictionary = {
	"rebuild_the_forge": {
		"quest_id": "rebuild_the_forge", "giver": "bram_ironhand", "title": "Rebuild the Forge",
	},
	"clear_bandit_path": {
		"quest_id": "clear_bandit_path", "giver": "wounded_scout", "title": "Clear the Bandit Path",
	},
	"build_the_basics": {
		"quest_id": "build_the_basics", "giver": "quartermaster_vale", "title": "Build the Basics",
	},
	"a_hound_in_the_ash": {
		"quest_id": "a_hound_in_the_ash", "giver": "beast_handler", "title": "A Hound in the Ash",
	},
	"wake_the_stone": {
		"quest_id": "wake_the_stone", "giver": "waystone_keeper", "title": "Wake the Stone",
	},
}

const NPC_MISSIONS: Dictionary = {
	"bram_ironhand": ["rebuild_the_forge"],
	"old_blacksmith": ["rebuild_the_forge"],
	"wounded_scout": ["clear_bandit_path"],
	"quartermaster_vale": ["build_the_basics"],
	"beast_handler": ["a_hound_in_the_ash"],
	"waystone_keeper": ["wake_the_stone"],
}


static func get_mission_quest(mission_id: String) -> String:
	return str(MISSIONS.get(mission_id, {}).get("quest_id", mission_id))


static func get_mission_title(mission_id: String) -> String:
	return str(MISSIONS.get(mission_id, {}).get("title", mission_id.replace("_", " ").capitalize()))


static func get_npc_missions(npc_id: String) -> Array[String]:
	var ids: Array[String] = []
	for mid in NPC_MISSIONS.get(npc_id, []):
		ids.append(str(mid))
	return ids
