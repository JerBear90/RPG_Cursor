extends Node
## Quest tracking and objective progress.

const NpcMissionRegistry := preload("res://scripts/autoload/npc_mission_registry.gd")

signal quest_started(quest_id: String)
signal quest_updated(quest_id: String)
signal quest_completed(quest_id: String)
signal quest_rewarded(quest_id: String, summary: String)
signal tracked_quest_changed(quest_id: String)

var active_quests: Dictionary = {}
var completed_quests: Array[String] = []
var tracked_quest_id: String = ""


func reset_for_new_game() -> void:
	active_quests.clear()
	completed_quests.clear()
	tracked_quest_id = ""
	start_quest("find_wolf_crest")


func start_quest(quest_id: String) -> void:
	if quest_id in completed_quests or active_quests.has(quest_id):
		return
	active_quests[quest_id] = _default_objectives(quest_id)
	quest_started.emit(quest_id)
	if tracked_quest_id == "":
		track_quest(quest_id)


func track_quest(quest_id: String) -> void:
	if active_quests.has(quest_id):
		tracked_quest_id = quest_id
		tracked_quest_changed.emit(quest_id)
		if quest_id in NpcMissionRegistry.MISSIONS:
			_notify_tracked_mission(quest_id)


func _notify_tracked_mission(quest_id: String) -> void:
	var title := NpcMissionRegistry.get_mission_title(quest_id)
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("show_toast"):
			hud.show_toast("Tracked Mission: %s" % title, 2.0, "", "notification", "", 1)
			return


func advance_objective(quest_id: String, objective_id: String, amount: int = 1) -> void:
	if not active_quests.has(quest_id):
		return
	var objectives: Array = active_quests[quest_id]
	for obj in objectives:
		if obj.id == objective_id and not obj.completed:
			obj.current = mini(obj.current + amount, obj.target)
			if obj.current >= obj.target:
				obj.completed = true
			quest_updated.emit(quest_id)
			if quest_id == "stormcallers" and objective_id == "recover_seals" and obj.completed:
				for other in objectives:
					if other.id == "unlock_citadel" and not other.completed:
						other.current = other.target
						other.completed = true
						quest_updated.emit(quest_id)
			if _all_complete(objectives):
				complete_quest(quest_id)
			elif quest_id in NpcMissionRegistry.MISSIONS:
				NpcMissionHooks.check_mission_ready_quest(quest_id)
			return


func complete_quest(quest_id: String) -> void:
	if not active_quests.has(quest_id):
		return
	active_quests.erase(quest_id)
	completed_quests.append(quest_id)
	_grant_quest_rewards(quest_id)
	quest_completed.emit(quest_id)
	if tracked_quest_id == quest_id:
		tracked_quest_id = active_quests.keys()[0] if active_quests.size() > 0 else ""
		tracked_quest_changed.emit(tracked_quest_id)
	if quest_id == "first_blood":
		AchievementManager.unlock("first_blood")
	_chain_next_quest(quest_id)


func get_active_quest_list() -> Array[String]:
	var ids: Array[String] = []
	for quest_id in active_quests.keys():
		ids.append(quest_id)
	return ids


func get_quest_summary(quest_id: String) -> String:
	if not active_quests.has(quest_id):
		return ""
	var objectives: Array = active_quests[quest_id]
	var parts: PackedStringArray = []
	for obj in objectives:
		var status := "done" if obj.completed else "%d/%d" % [obj.current, obj.target]
		parts.append("%s (%s)" % [obj.description, status])
	return "%s: %s" % [quest_id.replace("_", " ").capitalize(), ", ".join(parts)]


func get_tracked_objective_text() -> String:
	if tracked_quest_id == "" or not active_quests.has(tracked_quest_id):
		return ""
	var objectives: Array = active_quests[tracked_quest_id]
	for obj in objectives:
		if not obj.completed:
			return "%s — %d/%d" % [obj.description, obj.current, obj.target]
	return ""


func get_tracked_display_title() -> String:
	if tracked_quest_id == "":
		return ""
	if tracked_quest_id in NpcMissionRegistry.MISSIONS:
		return NpcMissionRegistry.get_mission_title(tracked_quest_id)
	return tracked_quest_id.replace("_", " ").capitalize()


func get_current_objective(quest_id: String = "") -> Dictionary:
	var qid := quest_id if quest_id != "" else tracked_quest_id
	if qid == "" or not active_quests.has(qid):
		return {}
	for obj in active_quests[qid]:
		if not obj.completed:
			return obj
	return {}


func get_quest_status(quest_id: String) -> String:
	if quest_id in completed_quests:
		return "Completed"
	if active_quests.has(quest_id):
		if NpcMissionHooks.can_turn_in_quest(quest_id):
			return "Ready to Turn In"
		return "Active"
	if quest_id in NpcMissionRegistry.MISSIONS:
		return "Available"
	return "Locked"


func get_giver_npc_id(quest_id: String) -> String:
	if quest_id in NpcMissionRegistry.MISSIONS:
		return str(NpcMissionRegistry.MISSIONS[quest_id].get("giver", ""))
	return ""


func get_reward_preview_text(quest_id: String) -> String:
	return _REWARD_PREVIEWS.get(quest_id, "See quest log")


func cycle_tracked_quest(direction: int = 1) -> void:
	var ids := get_active_quest_list()
	if ids.is_empty():
		clear_tracked_quest()
		return
	if tracked_quest_id == "" or tracked_quest_id not in ids:
		track_quest(ids[0])
		return
	var idx := ids.find(tracked_quest_id)
	idx = (idx + direction) % ids.size()
	if idx < 0:
		idx += ids.size()
	track_quest(ids[idx])


func clear_tracked_quest() -> void:
	if tracked_quest_id == "":
		return
	tracked_quest_id = ""
	tracked_quest_changed.emit("")


func get_tracked_hud_lines() -> Dictionary:
	if tracked_quest_id == "" or not active_quests.has(tracked_quest_id):
		return {}
	var obj := get_current_objective(tracked_quest_id)
	if obj.is_empty():
		return {"title": get_tracked_display_title(), "objective": "", "progress": "", "distance": ""}
	var progress := ""
	if int(obj.target) > 1 and not obj.completed:
		progress = "%d / %d" % [int(obj.current), int(obj.target)]
	return {
		"title": get_tracked_display_title(),
		"objective": str(obj.description),
		"progress": progress,
		"distance": "",
	}


const _REWARD_PREVIEWS: Dictionary = {
	"rebuild_the_forge": "Repair Kit, 75 Copper, Blacksmith +Relationship",
	"clear_bandit_path": "1 Silver, Bandages, Scout +Relationship",
	"build_the_basics": "Seeds, Wood, Nails, Camp Builder +Relationship",
	"a_hound_in_the_ash": "Ash Collar, Pet Treats, Beast Handler +Relationship",
	"wake_the_stone": "Crystal Dust, Amethyst, Waystone Keeper +Relationship",
	"find_wolf_crest": "50 Copper, Herb Bundles",
	"merchant_errand": "80 Copper, Rations",
	"defeat_warden": "2 Silver, Iron Scrap, Shadow Lash spell",
}


func _all_complete(objectives: Array) -> bool:
	for obj in objectives:
		if not obj.completed:
			return false
	return true


func _default_objectives(quest_id: String) -> Array:
	match quest_id:
		"find_wolf_crest":
			return [
				{"id": "reach_hearthhold", "description": "Reach Hearthhold Camp", "current": 0, "target": 1, "completed": false},
				{"id": "reach_shrine", "description": "Find the Wolf Crest Shrine", "current": 0, "target": 1, "completed": false},
			]
		"merchant_errand":
			return [{"id": "deliver_herbs", "description": "Deliver herb bundles", "current": 0, "target": 3, "completed": false}]
		"clear_dungeon":
			return [{"id": "defeat_boss", "description": "Clear the sunken crypt", "current": 0, "target": 1, "completed": false}]
		"first_blood":
			return [{"id": "kill_enemy", "description": "Slay your first foe", "current": 0, "target": 1, "completed": false}]
		"defeat_warden":
			return [{"id": "kill_warden", "description": "Slay the Hollow Grove Warden", "current": 0, "target": 1, "completed": false}]
		"watchtower_sweep":
			return [{"id": "clear_hostiles", "description": "Clear watchtower hostiles", "current": 0, "target": 3, "completed": false}]
		"raid_bandit_camp":
			return [
				{"id": "kill_captain", "description": "Defeat the Bandit Captain", "current": 0, "target": 1, "completed": false},
				{"id": "clear_camp", "description": "Rout the bandit camp", "current": 0, "target": 2, "completed": false},
			]
		"crystal_echoes":
			return [{"id": "clear_crystal", "description": "Silence the crystal cave", "current": 0, "target": 2, "completed": false}]
		"the_rot_below":
			return [
				{"id": "speak_mara", "description": "Speak with Mara Fen", "current": 0, "target": 1, "completed": false},
				{"id": "inspect_caravan", "description": "Inspect the damaged caravan", "current": 0, "target": 1, "completed": false},
				{"id": "report_captain", "description": "Return to Captain Voss", "current": 0, "target": 1, "completed": false},
			]
		"supplies_for_marsh":
			return [
				{"id": "have_tonic", "description": "Obtain Bogward Tonic", "current": 0, "target": 1, "completed": false},
				{"id": "have_bandages", "description": "Obtain Bandages", "current": 0, "target": 1, "completed": false},
				{"id": "speak_mara_gate", "description": "Speak with Mara Fen at the Rotfen gate", "current": 0, "target": 1, "completed": false},
			]
		"into_rotfen":
			return [
				{"id": "use_rotfen_gate", "description": "Use the Rotfen gate", "current": 0, "target": 1, "completed": false},
				{"id": "enter_rotfen", "description": "Enter Rotfen Marsh", "current": 0, "target": 1, "completed": false},
				{"id": "reach_marshwatch", "description": "Reach Marshwatch Camp", "current": 0, "target": 1, "completed": false},
				{"id": "activate_waystone", "description": "Activate the Rotfen waystone", "current": 0, "target": 1, "completed": false},
			]
		"the_missing_caravan":
			return [
				{"id": "reach_caravan", "description": "Reach the abandoned caravan", "current": 0, "target": 1, "completed": false},
				{"id": "defeat_hounds", "description": "Defeat marsh predators", "current": 0, "target": 2, "completed": false},
				{"id": "recover_ledger", "description": "Recover the caravan ledger", "current": 0, "target": 1, "completed": false},
				{"id": "return_scout", "description": "Return to Marshwatch Camp", "current": 0, "target": 1, "completed": false},
			]
		"the_sunken_bells":
			return [
				{"id": "inspect_shrine", "description": "Investigate ruined shrines", "current": 0, "target": 3, "completed": false},
				{"id": "defeat_cultists", "description": "Defeat Rotfen Cultists", "current": 0, "target": 3, "completed": false},
				{"id": "recover_seals", "description": "Recover reliquary seals", "current": 0, "target": 3, "completed": false},
			]
		"gather_bog_herbs":
			return [{"id": "collect_herbs", "description": "Gather Bog Herbs", "current": 0, "target": 5, "completed": false}]
		"rescue_trapped_scout":
			return [{"id": "free_scout", "description": "Rescue the trapped scout", "current": 0, "target": 1, "completed": false}]
		"destroy_corruption":
			return [{"id": "burn_growths", "description": "Destroy corrupted growths", "current": 0, "target": 4, "completed": false}]
		"hunt_spore_brute":
			return [{"id": "kill_brute", "description": "Slay the Spore Brute", "current": 0, "target": 1, "completed": false}]
		"depths_of_reliquary":
			return [
				{"id": "reach_checkpoint", "description": "Reach the sanctuary checkpoint", "current": 0, "target": 1, "completed": false},
				{"id": "solve_bells", "description": "Ring the ancient bells in order", "current": 0, "target": 1, "completed": false},
				{"id": "defeat_bellkeeper", "description": "Defeat the Drowned Bellkeeper", "current": 0, "target": 1, "completed": false},
			]
		"through_the_ash":
			return [
				{"id": "enter_ashfall", "description": "Enter Ashfall Highlands", "current": 0, "target": 1, "completed": false},
				{"id": "reach_stonewatch", "description": "Reach Stonewatch Outpost", "current": 0, "target": 1, "completed": false},
				{"id": "activate_waystone", "description": "Activate the Ashfall waystone", "current": 0, "target": 1, "completed": false},
				{"id": "speak_commander", "description": "Speak with the Stonewatch commander", "current": 0, "target": 1, "completed": false},
			]
		"the_broken_rail":
			return [
				{"id": "investigate_rail", "description": "Investigate the collapsed rail line", "current": 0, "target": 1, "completed": false},
				{"id": "defeat_raiders", "description": "Defeat Ash Raiders", "current": 0, "target": 3, "completed": false},
				{"id": "recover_manifests", "description": "Recover mining manifests", "current": 0, "target": 1, "completed": false},
				{"id": "clear_route", "description": "Clear the rail route", "current": 0, "target": 1, "completed": false},
			]
		"fires_below":
			return [
				{"id": "investigate_blackvein", "description": "Investigate Blackvein activity", "current": 0, "target": 1, "completed": false},
				{"id": "defeat_construct", "description": "Defeat a Furnace Construct", "current": 0, "target": 1, "completed": false},
				{"id": "recover_key", "description": "Recover foundry access key", "current": 0, "target": 1, "completed": false},
				{"id": "unlock_exterior", "description": "Unlock Blackvein Foundry exterior", "current": 0, "target": 1, "completed": false},
			]
		"gather_cinder_ore":
			return [{"id": "collect_ore", "description": "Gather Cinder Ore", "current": 0, "target": 6, "completed": false}]
		"heart_of_blackvein":
			return [
				{"id": "enter_foundry", "description": "Enter Blackvein Foundry", "current": 0, "target": 1, "completed": false},
				{"id": "reach_checkpoint", "description": "Reach the workshop checkpoint", "current": 0, "target": 1, "completed": false},
				{"id": "restore_mechanisms", "description": "Restore the forge mechanisms", "current": 0, "target": 1, "completed": false},
				{"id": "defeat_crucible", "description": "Defeat the Iron Crucible", "current": 0, "target": 1, "completed": false},
				{"id": "recover_core", "description": "Recover the Foundry Core", "current": 0, "target": 1, "completed": false},
			]
		"rescue_trapped_miners":
			return [{"id": "rescue_miners", "description": "Rescue trapped miners", "current": 0, "target": 1, "completed": false}]
		"clear_wolf_dens":
			return [{"id": "clear_den", "description": "Destroy Cinder Wolf dens", "current": 0, "target": 2, "completed": false}]
		"hunt_ironbound_elite":
			return [{"id": "slay_elite", "description": "Slay the Ironbound Elite", "current": 0, "target": 1, "completed": false}]
		"recover_machine_parts":
			return [{"id": "recover_parts", "description": "Recover lost machine parts", "current": 0, "target": 3, "completed": false}]
		"shut_down_vents":
			return [{"id": "shut_vent", "description": "Shut down unstable heat vents", "current": 0, "target": 2, "completed": false}]
		"into_the_white":
			return [
				{"id": "enter_frostgrave", "description": "Enter Frostgrave Expanse", "current": 0, "target": 1, "completed": false},
				{"id": "reach_frostwatch", "description": "Reach Frostwatch Bastion", "current": 0, "target": 1, "completed": false},
				{"id": "activate_waystone", "description": "Activate the Frostgrave waystone", "current": 0, "target": 1, "completed": false},
				{"id": "speak_commander", "description": "Speak with Commander Ysra Vale", "current": 0, "target": 1, "completed": false},
			]
		"the_buried_village":
			return [
				{"id": "investigate_village", "description": "Investigate the abandoned village", "current": 0, "target": 1, "completed": false},
				{"id": "defeat_raiders", "description": "Defeat Rimebound Raiders", "current": 0, "target": 3, "completed": false},
				{"id": "recover_records", "description": "Recover survivor records", "current": 0, "target": 1, "completed": false},
				{"id": "rescue_survivors", "description": "Rescue remaining survivors", "current": 0, "target": 1, "completed": false},
			]
		"gravewind_rising":
			return [
				{"id": "investigate_graves", "description": "Investigate grave sites", "current": 0, "target": 3, "completed": false},
				{"id": "defeat_wraiths", "description": "Defeat Gravewind Wraiths", "current": 0, "target": 3, "completed": false},
				{"id": "recover_seals", "description": "Recover ritual seals", "current": 0, "target": 1, "completed": false},
				{"id": "unlock_crypt", "description": "Unlock Paleheart Crypt", "current": 0, "target": 1, "completed": false},
			]
		"the_pale_heart":
			return [
				{"id": "enter_crypt", "description": "Enter Paleheart Crypt", "current": 0, "target": 1, "completed": false},
				{"id": "reach_checkpoint", "description": "Reach the sanctum checkpoint", "current": 0, "target": 1, "completed": false},
				{"id": "restore_seals", "description": "Align the burial seals", "current": 0, "target": 1, "completed": false},
				{"id": "defeat_king", "description": "Defeat the Hollow King", "current": 0, "target": 1, "completed": false},
				{"id": "recover_relic", "description": "Recover the Paleheart Relic", "current": 0, "target": 1, "completed": false},
			]
		"gather_rime_ore":
			return [{"id": "collect_ore", "description": "Gather Rime Ore", "current": 0, "target": 6, "completed": false}]
		"hunt_frostfang_packs":
			return [{"id": "clear_packs", "description": "Hunt Frostfang packs", "current": 0, "target": 3, "completed": false}]
		"rescue_lost_hunter":
			return [{"id": "rescue_hunter", "description": "Rescue the lost hunter", "current": 0, "target": 1, "completed": false}]
		"destroy_black_ice":
			return [{"id": "destroy_ice", "description": "Destroy black ice growths", "current": 0, "target": 2, "completed": false}]
		"hunt_frostbound_giant":
			return [{"id": "slay_giant", "description": "Defeat the Frostbound Giant", "current": 0, "target": 1, "completed": false}]
		"recover_supply_caches":
			return [{"id": "recover_caches", "description": "Recover frozen supply caches", "current": 0, "target": 3, "completed": false}]
		"into_the_storm":
			return [
				{"id": "enter_coast", "description": "Enter The Shattered Coast", "current": 0, "target": 1, "completed": false},
				{"id": "reach_tidewatch", "description": "Reach Tidewatch Refuge", "current": 0, "target": 1, "completed": false},
				{"id": "activate_waystone", "description": "Activate the Shattered Coast waystone", "current": 0, "target": 1, "completed": false},
				{"id": "speak_admiral", "description": "Speak with Admiral Serah Vane", "current": 0, "target": 1, "completed": false},
			]
		"wrecks_on_the_shore":
			return [
				{"id": "investigate_wrecks", "description": "Investigate shipwrecks", "current": 0, "target": 3, "completed": false},
				{"id": "defeat_reavers", "description": "Defeat Tide Reavers", "current": 0, "target": 3, "completed": false},
				{"id": "recover_manifests", "description": "Recover shipping manifests", "current": 0, "target": 3, "completed": false},
			]
		"the_drowned_village":
			return [
				{"id": "enter_village", "description": "Enter the drowned settlement", "current": 0, "target": 1, "completed": false},
				{"id": "defeat_mariners", "description": "Defeat Drowned Mariners", "current": 0, "target": 3, "completed": false},
				{"id": "recover_records", "description": "Recover survivor records", "current": 0, "target": 1, "completed": false},
				{"id": "rescue_survivors", "description": "Rescue trapped survivors", "current": 0, "target": 1, "completed": false},
			]
		"stormcallers":
			return [
				{"id": "investigate_shrines", "description": "Investigate storm shrines", "current": 0, "target": 3, "completed": false},
				{"id": "defeat_wraiths", "description": "Defeat Storm Wraiths and Cultists", "current": 0, "target": 3, "completed": false},
				{"id": "recover_seals", "description": "Recover storm seals", "current": 0, "target": 3, "completed": false},
				{"id": "unlock_citadel", "description": "Unlock Drowned Citadel", "current": 0, "target": 1, "completed": false},
			]
		"the_sunken_crown":
			return [
				{"id": "enter_citadel", "description": "Enter Drowned Citadel", "current": 0, "target": 1, "completed": false},
				{"id": "reach_checkpoint", "description": "Reach the storm shelter checkpoint", "current": 0, "target": 1, "completed": false},
				{"id": "stabilize_conduits", "description": "Stabilize the storm conduits", "current": 0, "target": 1, "completed": false},
				{"id": "reach_throne", "description": "Reach the Tidebound Throne", "current": 0, "target": 1, "completed": false},
				{"id": "defeat_sovereign", "description": "Defeat the Tidebound Sovereign", "current": 0, "target": 1, "completed": false},
				{"id": "recover_crown", "description": "Recover the Tidebound Crown", "current": 0, "target": 1, "completed": false},
				{"id": "exit_citadel", "description": "Exit the Drowned Citadel", "current": 0, "target": 1, "completed": false},
			]
		"gather_stormglass":
			return [{"id": "collect_glass", "description": "Gather Stormglass", "current": 0, "target": 6, "completed": false}]
		"hunt_shellback_brutes":
			return [{"id": "slay_brutes", "description": "Hunt Shellback Brutes", "current": 0, "target": 2, "completed": false}]
		"recover_lost_cargo":
			return [{"id": "recover_cargo", "description": "Recover lost cargo", "current": 0, "target": 3, "completed": false}]
		"rescue_stranded_scout":
			return [{"id": "rescue_scout", "description": "Rescue the stranded scout", "current": 0, "target": 1, "completed": false}]
		"destroy_storm_shrines":
			return [{"id": "destroy_shrines", "description": "Destroy storm shrines", "current": 0, "target": 2, "completed": false}]
		"hunt_tidebound_colossus":
			return [{"id": "slay_colossus", "description": "Defeat the Tidebound Colossus", "current": 0, "target": 1, "completed": false}]
		"recover_leviathan_bones":
			return [{"id": "recover_bones", "description": "Recover Leviathan bones", "current": 0, "target": 2, "completed": false}]
		"into_the_blight":
			return [
				{"id": "enter_blightreach", "description": "Enter Blightreach", "current": 0, "target": 1, "completed": false},
				{"id": "reach_lastwall", "description": "Reach Lastwall Enclave", "current": 0, "target": 1, "completed": false},
				{"id": "activate_waystone", "description": "Activate the Blightreach waystone", "current": 0, "target": 1, "completed": false},
				{"id": "speak_warden", "description": "Speak with Warden Mara Kest", "current": 0, "target": 1, "completed": false},
			]
		"the_withered_fields":
			return [
				{"id": "investigate_farms", "description": "Investigate abandoned farms", "current": 0, "target": 3, "completed": false},
				{"id": "defeat_raiders", "description": "Defeat Rootbound Raiders", "current": 0, "target": 3, "completed": false},
				{"id": "recover_records", "description": "Recover survivor records", "current": 0, "target": 1, "completed": false},
				{"id": "destroy_growths", "description": "Destroy corruption growths", "current": 0, "target": 3, "completed": false},
			]
		"spores_in_the_wind":
			return [
				{"id": "investigate_spores", "description": "Investigate spore zones", "current": 0, "target": 3, "completed": false},
				{"id": "defeat_sporecasters", "description": "Defeat Sporecasters", "current": 0, "target": 2, "completed": false},
				{"id": "recover_samples", "description": "Recover fungal samples", "current": 0, "target": 3, "completed": false},
				{"id": "obtain_filter", "description": "Obtain a spore filter", "current": 0, "target": 1, "completed": false},
			]
		"the_fallen_abbey":
			return [
				{"id": "reach_abbey", "description": "Reach the ruined abbey", "current": 0, "target": 1, "completed": false},
				{"id": "defeat_wraiths", "description": "Defeat Corruption Wraiths", "current": 0, "target": 3, "completed": false},
				{"id": "restore_braziers", "description": "Restore purification braziers", "current": 0, "target": 3, "completed": false},
				{"id": "recover_seal", "description": "Recover the Blightspire seal", "current": 0, "target": 1, "completed": false},
			]
		"heart_of_the_blight":
			return [
				{"id": "enter_cathedral", "description": "Enter Blightspire Cathedral", "current": 0, "target": 1, "completed": false},
				{"id": "reach_checkpoint", "description": "Activate the cathedral checkpoint", "current": 0, "target": 1, "completed": false},
				{"id": "purify_roots", "description": "Kindle all three purification braziers", "current": 0, "target": 1, "completed": false},
				{"id": "reach_nave", "description": "Reach the Central Nave", "current": 0, "target": 1, "completed": false},
				{"id": "prepare_boss", "description": "Reach the Boss Antechamber", "current": 0, "target": 1, "completed": false},
				{"id": "enter_heart_chamber", "description": "Enter the Heart Chamber", "current": 0, "target": 1, "completed": false},
				{"id": "defeat_blightheart", "description": "Defeat The Blightheart", "current": 0, "target": 1, "completed": false},
				{"id": "recover_blightheart_core", "description": "Recover the Blightheart Core", "current": 0, "target": 1, "completed": false},
				{"id": "purify_blightspire", "description": "Purify Blightspire Cathedral", "current": 0, "target": 1, "completed": false},
				{"id": "exit_blightspire", "description": "Exit Blightspire Cathedral", "current": 0, "target": 1, "completed": false},
			]
		"gather_sporecaps":
			return [{"id": "collect_sporecaps", "description": "Gather Sporecaps", "current": 0, "target": 6, "completed": false}]
		"rescue_infected_survivors":
			return [{"id": "rescue_survivors", "description": "Rescue infected survivors", "current": 0, "target": 2, "completed": false}]
		"destroy_blight_hound_dens":
			return [{"id": "clear_dens", "description": "Destroy Blight Hound dens", "current": 0, "target": 2, "completed": false}]
		"recover_research_notes":
			return [{"id": "recover_notes", "description": "Recover research notes", "current": 0, "target": 3, "completed": false}]
		"defeat_root_titan":
			return [{"id": "slay_titan", "description": "Defeat the Root Titan", "current": 0, "target": 1, "completed": false}]
		"clear_corrupted_wells":
			return [{"id": "clear_wells", "description": "Clear corrupted wells", "current": 0, "target": 2, "completed": false}]
		"harvest_viridian_crystal":
			return [{"id": "harvest_crystal", "description": "Harvest Viridian Crystal", "current": 0, "target": 4, "completed": false}]
		"into_the_ember":
			return [
				{"id": "enter_ember_wastes", "description": "Enter The Ember Wastes", "current": 0, "target": 1, "completed": false},
				{"id": "reach_cinderhold", "description": "Reach Cinderhold Outpost", "current": 0, "target": 1, "completed": false},
				{"id": "activate_waystone", "description": "Activate the Ember Wastes waystone", "current": 0, "target": 1, "completed": false},
				{"id": "speak_commander", "description": "Speak with Warden Ilyra Voss", "current": 0, "target": 1, "completed": false},
			]
		"the_dry_road":
			return [
				{"id": "investigate_trail", "description": "Investigate the dry road trail", "current": 0, "target": 1, "completed": false},
				{"id": "defeat_raiders", "description": "Defeat Dune Raiders", "current": 0, "target": 3, "completed": false},
				{"id": "clear_obstacles", "description": "Clear trail obstacles", "current": 0, "target": 1, "completed": false},
				{"id": "reach_glass_dune", "description": "Reach the glass dune", "current": 0, "target": 1, "completed": false},
			]
		"glass_beneath_the_sand":
			return [
				{"id": "investigate_dune", "description": "Investigate the glass dune", "current": 0, "target": 1, "completed": false},
				{"id": "defeat_glass_husks", "description": "Defeat Glass Husks", "current": 0, "target": 2, "completed": false},
				{"id": "recover_fragments", "description": "Recover glass fragments", "current": 0, "target": 3, "completed": false},
				{"id": "catalog_findings", "description": "Catalog the buried glass field", "current": 0, "target": 1, "completed": false},
			]
		"the_burning_obelisks":
			return [
				{"id": "investigate_obelisks", "description": "Investigate burning obelisks", "current": 0, "target": 3, "completed": false},
				{"id": "defeat_cultists", "description": "Defeat Pyre Cultists", "current": 0, "target": 2, "completed": false},
				{"id": "align_mirrors", "description": "Align the obelisk mirrors", "current": 0, "target": 1, "completed": false},
				{"id": "recover_fragment", "description": "Recover the ancient obelisk fragment", "current": 0, "target": 1, "completed": false},
			]
		"heart_of_the_wastes":
			return [
				{"id": "enter_ziggurat", "description": "Enter Pyreheart Ziggurat", "current": 0, "target": 1, "completed": false},
				{"id": "reach_checkpoint", "description": "Activate the oasis checkpoint", "current": 0, "target": 1, "completed": false},
				{"id": "align_mirrors", "description": "Restore the ancient cooling channels", "current": 0, "target": 1, "completed": false},
				{"id": "reach_inner_pyramid", "description": "Reach the Inner Pyramid", "current": 0, "target": 1, "completed": false},
				{"id": "prepare_solar_heart", "description": "Prepare for the Solar Heart encounter", "current": 0, "target": 1, "completed": false},
				{"id": "enter_solar_heart", "description": "Enter the Solar Heart chamber", "current": 0, "target": 1, "completed": false},
				{"id": "defeat_solar_tyrant", "description": "Defeat The Solar Tyrant", "current": 0, "target": 1, "completed": false},
				{"id": "recover_solar_heart_core", "description": "Recover the Solar Heart Core", "current": 0, "target": 1, "completed": false},
				{"id": "stabilize_pyreheart", "description": "Stabilize Pyreheart Ziggurat", "current": 0, "target": 1, "completed": false},
				{"id": "exit_pyreheart_ziggurat", "description": "Exit Pyreheart Ziggurat", "current": 0, "target": 1, "completed": false},
			]
		"gather_scorched_sand":
			return [{"id": "collect_sand", "description": "Gather Scorched Sand", "current": 0, "target": 6, "completed": false}]
		"hunt_ashscale_packs":
			return [{"id": "clear_den", "description": "Destroy Ashscale Hound dens", "current": 0, "target": 2, "completed": false}]
		"rescue_stranded_caravan":
			return [{"id": "rescue_caravan", "description": "Rescue the stranded caravan", "current": 0, "target": 1, "completed": false}]
		"harvest_sunstone":
			return [{"id": "harvest_shard", "description": "Harvest Sunstone Shards", "current": 0, "target": 4, "completed": false}]
		"defeat_sunscar_behemoth":
			return [{"id": "slay_behemoth", "description": "Defeat the Sunscar Behemoth", "current": 0, "target": 1, "completed": false}]
		"into_the_dominion":
			return [
				{"id": "enter_sunless_dominion", "description": "Enter the Sunless Dominion", "current": 0, "target": 1, "completed": false},
				{"id": "reach_dawnwatch", "description": "Reach Dawnwatch Camp", "current": 0, "target": 1, "completed": false},
				{"id": "activate_waystone", "description": "Activate the Sunless Dominion waystone", "current": 0, "target": 1, "completed": false},
				{"id": "speak_commander", "description": "Speak with Commander Alaric Vane", "current": 0, "target": 1, "completed": false},
			]
		"the_forsaken_hamlet":
			return [
				{"id": "investigate_hamlet", "description": "Investigate the forsaken hamlet", "current": 0, "target": 1, "completed": false},
				{"id": "defeat_raiders", "description": "Defeat Nightbound Raiders", "current": 0, "target": 3, "completed": false},
				{"id": "recover_records", "description": "Recover survivor records", "current": 0, "target": 1, "completed": false},
				{"id": "rescue_survivors", "description": "Rescue hamlet survivors", "current": 0, "target": 1, "completed": false},
			]
		"graves_without_rest":
			return [
				{"id": "investigate_graves", "description": "Investigate royal grave sites", "current": 0, "target": 3, "completed": false},
				{"id": "defeat_wraiths", "description": "Defeat Grave Wraiths", "current": 0, "target": 2, "completed": false},
				{"id": "recover_seals", "description": "Recover ward seals", "current": 0, "target": 1, "completed": false},
			]
		"the_dark_observatory":
			return [
				{"id": "investigate_observatory", "description": "Investigate the Dark Observatory", "current": 0, "target": 1, "completed": false},
				{"id": "defeat_cultists", "description": "Defeat Eclipse Cultists", "current": 0, "target": 2, "completed": false},
				{"id": "recover_eclipse_shard", "description": "Recover the eclipse shard", "current": 0, "target": 1, "completed": false},
			]
		"throne_beneath_the_eclipse":
			return [
				{"id": "enter_sanctum", "description": "Enter Eclipse Sanctum", "current": 0, "target": 1, "completed": false},
				{"id": "reach_checkpoint", "description": "Activate the ward checkpoint", "current": 0, "target": 1, "completed": false},
				{"id": "align_shadow_mirrors", "description": "Align the shadow wards", "current": 0, "target": 1, "completed": false},
				{"id": "reach_inner_spire", "description": "Reach the Inner Spire", "current": 0, "target": 1, "completed": false},
				{"id": "prepare_eclipse_throne", "description": "Prepare for the sealed throne", "current": 0, "target": 1, "completed": false},
			]
		"gather_moonstone":
			return [{"id": "collect_moonstone", "description": "Gather Moonstone", "current": 0, "target": 4, "completed": false}]
		"rescue_lost_patrol":
			return [{"id": "rescue_patrol", "description": "Rescue the lost patrol", "current": 0, "target": 1, "completed": false}]
		"destroy_gloom_hound_dens":
			return [{"id": "clear_den", "description": "Destroy Gloom Hound dens", "current": 0, "target": 2, "completed": false}]
		"recover_royal_relics":
			return [{"id": "recover_relics", "description": "Recover royal relics", "current": 0, "target": 3, "completed": false}]
		"defeat_dominion_executioner":
			return [{"id": "slay_executioner", "description": "Defeat the Dominion Executioner", "current": 0, "target": 1, "completed": false}]
		"purify_shadow_wells":
			return [{"id": "purify_wells", "description": "Purify shadow wells", "current": 0, "target": 2, "completed": false}]
		"collect_nightglass":
			return [{"id": "collect_nightglass", "description": "Collect Nightglass", "current": 0, "target": 4, "completed": false}]
		"rebuild_the_forge":
			return [
				{"id": "gather_scrap", "description": "Gather Metal Scraps", "current": 0, "target": 6, "completed": false},
				{"id": "gather_resin", "description": "Gather Fire Resin", "current": 0, "target": 1, "completed": false},
				{"id": "report_blacksmith", "description": "Return to Old Blacksmith", "current": 0, "target": 1, "completed": false},
			]
		"clear_bandit_path":
			return [
				{"id": "kill_bandits", "description": "Defeat bandits", "current": 0, "target": 5, "completed": false},
				{"id": "report_scout", "description": "Return to Wounded Scout", "current": 0, "target": 1, "completed": false},
			]
		"build_the_basics":
			return [
				{"id": "upgrade_workbench", "description": "Upgrade Workbench to Level 2", "current": 0, "target": 1, "completed": false},
				{"id": "build_water", "description": "Build Water Collector Level 1", "current": 0, "target": 1, "completed": false},
				{"id": "build_garden", "description": "Build Garden Plot Level 1", "current": 0, "target": 1, "completed": false},
				{"id": "report_builder", "description": "Return to Camp Builder", "current": 0, "target": 1, "completed": false},
			]
		"a_hound_in_the_ash":
			return [
				{"id": "unlock_beast_bond", "description": "Unlock Beast Bond", "current": 0, "target": 1, "completed": false},
				{"id": "upgrade_pet_shelter", "description": "Upgrade Pet Shelter to Level 1", "current": 0, "target": 1, "completed": false},
				{"id": "gather_bone", "description": "Gather Bone", "current": 0, "target": 3, "completed": false},
				{"id": "adopt_hound", "description": "Adopt Ash Hound", "current": 0, "target": 1, "completed": false},
				{"id": "report_handler", "description": "Return to Beast Handler", "current": 0, "target": 1, "completed": false},
			]
		"wake_the_stone":
			return [
				{"id": "find_waystone", "description": "Find a Waystone", "current": 0, "target": 1, "completed": false},
				{"id": "gather_crystal", "description": "Gather Crystal Shards", "current": 0, "target": 3, "completed": false},
				{"id": "activate_waystone", "description": "Activate a Waystone", "current": 0, "target": 1, "completed": false},
				{"id": "report_keeper", "description": "Return to Waystone Keeper", "current": 0, "target": 1, "completed": false},
			]
		_:
			return [{"id": "default", "description": quest_id, "current": 0, "target": 1, "completed": false}]


func serialize() -> Dictionary:
	return {
		"active": active_quests.duplicate(true),
		"completed": completed_quests.duplicate(),
		"tracked": tracked_quest_id,
	}


func _grant_quest_rewards(quest_id: String) -> void:
	var summary := ""
	match quest_id:
		"find_wolf_crest":
			CurrencyManager.add_copper(50)
			InventoryManager.add_item("herb_bundle", 2)
			summary = "+50 copper, herb bundles"
		"merchant_errand":
			CurrencyManager.add_copper(80)
			InventoryManager.add_item("dried_rations", 3)
			summary = "+80 copper, rations"
		"clear_dungeon":
			CurrencyManager.add_copper(100)
			InventoryManager.add_item("iron_scrap", 3)
			summary = "+100 copper, iron scrap"
		"first_blood":
			CurrencyManager.add_copper(15)
			summary = "+15 copper"
		"defeat_warden":
			CurrencyManager.add_silver(2)
			InventoryManager.add_item("iron_scrap", 5)
			summary = "+2 silver, iron scrap"
			MaskManager.sync_unlocks_from_quests()
			var player := GameManager.get_player(0)
			if player and player.has_node("Spellcaster"):
				(player.get_node("Spellcaster") as Node).unlock_spell("shadow_lash")
		"watchtower_sweep":
			CurrencyManager.add_copper(60)
			InventoryManager.add_item("iron_scrap", 2)
			summary = "+60 copper, iron scrap"
		"raid_bandit_camp":
			CurrencyManager.add_silver(1)
			InventoryManager.add_item("iron_sword", 1)
			summary = "+1 silver, iron sword"
		"crystal_echoes":
			CurrencyManager.add_copper(90)
			InventoryManager.add_item("stone", 5)
			summary = "+90 copper, stone"
		"the_rot_below":
			CurrencyManager.add_copper(75)
			InventoryManager.add_item("bogward_tonic", 1)
			summary = "+75 copper, Bogward Tonic"
		"supplies_for_marsh":
			CurrencyManager.add_copper(40)
			summary = "+40 copper"
		"into_rotfen":
			CurrencyManager.add_copper(100)
			WaystoneManager.discover("rotfen_marsh")
			summary = "+100 copper, Rotfen waypoint"
		"the_missing_caravan":
			CurrencyManager.add_copper(80)
			InventoryManager.add_item("swamp_iron", 2)
			summary = "+80 copper, swamp iron"
			if not QuestManager.active_quests.has("the_sunken_bells") and "the_sunken_bells" not in QuestManager.completed_quests:
				QuestManager.start_quest("the_sunken_bells")
		"the_sunken_bells":
			CurrencyManager.add_silver(1)
			InventoryManager.add_item("reliquary_seal", 1)
			summary = "+1 silver, reliquary seal"
		"gather_bog_herbs":
			CurrencyManager.add_copper(35)
			InventoryManager.add_item("bog_herb", 3)
			summary = "+35 copper, bog herbs"
		"rescue_trapped_scout":
			CurrencyManager.add_copper(50)
			summary = "+50 copper"
		"destroy_corruption":
			CurrencyManager.add_copper(60)
			summary = "+60 copper"
		"hunt_spore_brute":
			CurrencyManager.add_copper(120)
			InventoryManager.add_item("mire_crystal", 1)
			summary = "+120 copper, mire crystal"
		"depths_of_reliquary":
			CurrencyManager.add_copper(150)
			summary = "+150 copper"
		"through_the_ash":
			CurrencyManager.add_copper(100)
			summary = "+100 copper"
		"the_broken_rail":
			CurrencyManager.add_copper(90)
			summary = "+90 copper"
		"fires_below":
			CurrencyManager.add_silver(1)
			summary = "+1 silver"
		"gather_cinder_ore":
			CurrencyManager.add_copper(45)
			summary = "+45 copper"
		"heart_of_blackvein":
			CurrencyManager.add_copper(200)
			if not InventoryManager.has_item("crucible_hammer"):
				InventoryManager.add_item("crucible_hammer", 1)
			summary = "+200 copper, Crucible Hammer"
		"rescue_trapped_miners":
			CurrencyManager.add_copper(55)
			summary = "+55 copper"
		"clear_wolf_dens":
			CurrencyManager.add_copper(70)
			InventoryManager.add_item("burned_hide", 2)
			summary = "+70 copper, burned hide"
		"hunt_ironbound_elite":
			CurrencyManager.add_copper(90)
			InventoryManager.add_item("blackvein_iron", 2)
			summary = "+90 copper, blackvein iron"
		"recover_machine_parts":
			CurrencyManager.add_copper(65)
			InventoryManager.add_item("machine_scrap", 3)
			summary = "+65 copper, machine scrap"
		"shut_down_vents":
			CurrencyManager.add_copper(50)
			summary = "+50 copper"
		"into_the_white":
			CurrencyManager.add_copper(100)
			summary = "+100 copper"
		"the_buried_village":
			CurrencyManager.add_copper(90)
			summary = "+90 copper"
		"gravewind_rising":
			CurrencyManager.add_silver(1)
			summary = "+1 silver"
		"the_pale_heart":
			CurrencyManager.add_copper(200)
			if not InventoryManager.has_item("hollow_king_blade"):
				InventoryManager.add_item("hollow_king_blade", 1)
			summary = "+200 copper, Hollow King Blade"
		"gather_rime_ore":
			CurrencyManager.add_copper(45)
			summary = "+45 copper"
		"hunt_frostfang_packs":
			CurrencyManager.add_copper(70)
			summary = "+70 copper"
		"rescue_lost_hunter":
			CurrencyManager.add_copper(55)
			summary = "+55 copper"
		"destroy_black_ice":
			CurrencyManager.add_copper(60)
			summary = "+60 copper"
		"hunt_frostbound_giant":
			CurrencyManager.add_copper(95)
			summary = "+95 copper"
		"recover_supply_caches":
			CurrencyManager.add_copper(65)
			summary = "+65 copper"
		"into_the_storm":
			CurrencyManager.add_copper(100)
			summary = "+100 copper"
		"wrecks_on_the_shore":
			CurrencyManager.add_copper(90)
			summary = "+90 copper"
		"the_drowned_village":
			CurrencyManager.add_copper(95)
			summary = "+95 copper"
		"stormcallers":
			CurrencyManager.add_silver(1)
			summary = "+1 silver"
		"the_sunken_crown":
			CurrencyManager.add_copper(200)
			if not InventoryManager.has_item("stormwake_charm"):
				InventoryManager.add_item("stormwake_charm", 1)
			summary = "+200 copper, Stormwake Charm"
		"gather_stormglass":
			CurrencyManager.add_copper(45)
			summary = "+45 copper"
		"hunt_shellback_brutes":
			CurrencyManager.add_copper(75)
			summary = "+75 copper"
		"recover_lost_cargo":
			CurrencyManager.add_copper(60)
			summary = "+60 copper"
		"rescue_stranded_scout":
			CurrencyManager.add_copper(55)
			summary = "+55 copper"
		"destroy_storm_shrines":
			CurrencyManager.add_copper(70)
			summary = "+70 copper"
		"hunt_tidebound_colossus":
			CurrencyManager.add_copper(100)
			summary = "+100 copper"
		"recover_leviathan_bones":
			CurrencyManager.add_copper(65)
			summary = "+65 copper"
		"into_the_blight":
			CurrencyManager.add_copper(100)
			summary = "+100 copper"
		"the_withered_fields":
			CurrencyManager.add_copper(90)
			summary = "+90 copper"
		"spores_in_the_wind":
			CurrencyManager.add_copper(95)
			if not InventoryManager.has_item("spore_filter"):
				InventoryManager.add_item("spore_filter", 1)
			summary = "+95 copper, Spore Filter"
		"the_fallen_abbey":
			CurrencyManager.add_silver(1)
			if not InventoryManager.has_item("blightspire_seal"):
				InventoryManager.add_item("blightspire_seal", 1)
			summary = "+1 silver, Blightspire Seal"
		"heart_of_the_blight":
			CurrencyManager.add_copper(120)
			if not InventoryManager.has_item("viridian_crystal"):
				InventoryManager.add_item("viridian_crystal", 2)
			summary = "+120 copper, Viridian Crystal"
		"into_the_ember":
			CurrencyManager.add_copper(100)
			summary = "+100 copper"
		"the_dry_road":
			CurrencyManager.add_copper(90)
			summary = "+90 copper"
		"glass_beneath_the_sand":
			CurrencyManager.add_copper(95)
			summary = "+95 copper"
		"the_burning_obelisks":
			CurrencyManager.add_silver(1)
			if not InventoryManager.has_item("ancient_obelisk_fragment"):
				InventoryManager.add_item("ancient_obelisk_fragment", 1)
			summary = "+1 silver, Ancient Obelisk Fragment"
		"heart_of_the_wastes":
			CurrencyManager.add_copper(120)
			if not InventoryManager.has_item("sunstone_shard"):
				InventoryManager.add_item("sunstone_shard", 2)
			summary = "+120 copper, Sunstone Shard"
		"gather_scorched_sand":
			CurrencyManager.add_copper(45)
			summary = "+45 copper"
		"hunt_ashscale_packs":
			CurrencyManager.add_copper(60)
			summary = "+60 copper"
		"rescue_stranded_caravan":
			CurrencyManager.add_copper(55)
			summary = "+55 copper"
		"harvest_sunstone":
			CurrencyManager.add_copper(50)
			summary = "+50 copper"
		"defeat_sunscar_behemoth":
			CurrencyManager.add_copper(70)
			summary = "+70 copper"
		"into_the_dominion":
			CurrencyManager.add_copper(100)
			summary = "+100 copper"
		"the_forsaken_hamlet":
			CurrencyManager.add_copper(90)
			summary = "+90 copper"
		"graves_without_rest":
			CurrencyManager.add_copper(95)
			summary = "+95 copper"
		"the_dark_observatory":
			CurrencyManager.add_silver(1)
			if not InventoryManager.has_item("eclipse_shard"):
				InventoryManager.add_item("eclipse_shard", 1)
			summary = "+1 silver, Eclipse Shard"
		"throne_beneath_the_eclipse":
			CurrencyManager.add_copper(120)
			if not InventoryManager.has_item("sanctum_sigil"):
				InventoryManager.add_item("sanctum_sigil", 1)
			summary = "+120 copper, Sanctum Sigil"
		"rebuild_the_forge":
			CurrencyManager.add_copper(75)
			InventoryManager.add_item("repair_kit", 1)
			summary = "+75 copper, repair kit"
		"clear_bandit_path":
			CurrencyManager.add_silver(1)
			InventoryManager.add_item("bandage", 2)
			summary = "+1 silver, bandages"
		"build_the_basics":
			InventoryManager.add_item("seeds", 3)
			InventoryManager.add_item("wood", 5)
			InventoryManager.add_item("nails", 3)
			summary = "seeds, wood, nails"
		"a_hound_in_the_ash":
			InventoryManager.add_item("ash_collar", 1)
			InventoryManager.add_item("pet_treat", 2)
			summary = "Ash Collar, pet treats"
		"wake_the_stone":
			InventoryManager.add_item("crystal_dust", 2)
			if not InventoryManager.has_item("gem_amethyst"):
				InventoryManager.add_item("gem_amethyst", 1)
			summary = "crystal dust, amethyst"
		"gather_moonstone":
			CurrencyManager.add_copper(50)
			summary = "+50 copper"
		"rescue_lost_patrol":
			CurrencyManager.add_copper(55)
			summary = "+55 copper"
		"destroy_gloom_hound_dens":
			CurrencyManager.add_copper(60)
			summary = "+60 copper"
		"recover_royal_relics":
			CurrencyManager.add_copper(65)
			summary = "+65 copper"
		"defeat_dominion_executioner":
			CurrencyManager.add_copper(100)
			summary = "+100 copper"
		"purify_shadow_wells":
			CurrencyManager.add_copper(65)
			summary = "+65 copper"
		"collect_nightglass":
			CurrencyManager.add_copper(55)
			summary = "+55 copper"
		"gather_sporecaps":
			CurrencyManager.add_copper(45)
			summary = "+45 copper"
		"rescue_infected_survivors":
			CurrencyManager.add_copper(55)
			summary = "+55 copper"
		"destroy_blight_hound_dens":
			CurrencyManager.add_copper(60)
			summary = "+60 copper"
		"recover_research_notes":
			CurrencyManager.add_copper(50)
			summary = "+50 copper"
		"defeat_root_titan":
			CurrencyManager.add_copper(100)
			summary = "+100 copper"
		"clear_corrupted_wells":
			CurrencyManager.add_copper(65)
			summary = "+65 copper"
		"harvest_viridian_crystal":
			CurrencyManager.add_copper(55)
			summary = "+55 copper"
	if summary != "":
		quest_rewarded.emit(quest_id, summary)
		AudioManager.play_sfx("quest")


func _chain_next_quest(quest_id: String) -> void:
	match quest_id:
		"find_wolf_crest":
			WaystoneManager.hearthhold_unlocked = true
			if "hearthhold_camp" not in WaystoneManager.discovered:
				WaystoneManager.discovered.append("hearthhold_camp")
			MaskManager.sync_unlocks_from_quests()
			start_quest("merchant_errand")
			DialogueManager.start_dialogue("quest_wolf_done", [
				{"speaker": "Quest", "text": "The Wolf Crest is yours. Hearthhold is linked. A wounded scout may need herb bundles."},
			])
		"merchant_errand":
			start_quest("defeat_warden")
			if "hollow_grove_shrine" not in WaystoneManager.discovered:
				WaystoneManager.discover("hollow_grove_shrine")
			MaskManager.sync_unlocks_from_quests()
			DialogueManager.start_dialogue("quest_errand_done", [
				{"speaker": "Quest", "text": "The merchant owes you a favor. Travel to the Hollow Grove Shrine and slay the Warden."},
			])
		"the_rot_below":
			if not active_quests.has("supplies_for_marsh"):
				start_quest("supplies_for_marsh")
		"supplies_for_marsh":
			if not active_quests.has("into_rotfen"):
				start_quest("into_rotfen")
		"into_rotfen":
			if "rotfen_marsh" not in WaystoneManager.discovered:
				WaystoneManager.discover("rotfen_marsh")
		"through_the_ash":
			if not active_quests.has("the_broken_rail") and "the_broken_rail" not in completed_quests:
				start_quest("the_broken_rail")
		"the_broken_rail":
			if not active_quests.has("fires_below") and "fires_below" not in completed_quests:
				start_quest("fires_below")
		"heart_of_blackvein":
			if not active_quests.has("into_the_white") and "into_the_white" not in completed_quests:
				start_quest("into_the_white")
		"into_the_white":
			if not active_quests.has("the_buried_village") and "the_buried_village" not in completed_quests:
				start_quest("the_buried_village")
		"the_buried_village":
			if not active_quests.has("gravewind_rising") and "gravewind_rising" not in completed_quests:
				start_quest("gravewind_rising")
		"gravewind_rising":
			if not active_quests.has("the_pale_heart") and "the_pale_heart" not in completed_quests:
				start_quest("the_pale_heart")
		"the_pale_heart":
			if not active_quests.has("into_the_storm") and "into_the_storm" not in completed_quests:
				start_quest("into_the_storm")
		"into_the_storm":
			if not active_quests.has("wrecks_on_the_shore") and "wrecks_on_the_shore" not in completed_quests:
				start_quest("wrecks_on_the_shore")
		"wrecks_on_the_shore":
			if not active_quests.has("the_drowned_village") and "the_drowned_village" not in completed_quests:
				start_quest("the_drowned_village")
		"the_drowned_village":
			if not active_quests.has("stormcallers") and "stormcallers" not in completed_quests:
				start_quest("stormcallers")
		"stormcallers":
			if not active_quests.has("the_sunken_crown") and "the_sunken_crown" not in completed_quests:
				start_quest("the_sunken_crown")
		"the_sunken_crown":
			if not active_quests.has("into_the_blight") and "into_the_blight" not in completed_quests:
				start_quest("into_the_blight")
		"into_the_blight":
			if not active_quests.has("the_withered_fields") and "the_withered_fields" not in completed_quests:
				start_quest("the_withered_fields")
		"the_withered_fields":
			if not active_quests.has("spores_in_the_wind") and "spores_in_the_wind" not in completed_quests:
				start_quest("spores_in_the_wind")
		"spores_in_the_wind":
			if not active_quests.has("the_fallen_abbey") and "the_fallen_abbey" not in completed_quests:
				start_quest("the_fallen_abbey")
		"the_fallen_abbey":
			if not active_quests.has("heart_of_the_blight") and "heart_of_the_blight" not in completed_quests:
				start_quest("heart_of_the_blight")
		"heart_of_the_blight":
			if not active_quests.has("into_the_ember") and "into_the_ember" not in completed_quests:
				start_quest("into_the_ember")
		"into_the_ember":
			if not active_quests.has("the_dry_road") and "the_dry_road" not in completed_quests:
				start_quest("the_dry_road")
		"the_dry_road":
			if not active_quests.has("glass_beneath_the_sand") and "glass_beneath_the_sand" not in completed_quests:
				start_quest("glass_beneath_the_sand")
		"glass_beneath_the_sand":
			if not active_quests.has("the_burning_obelisks") and "the_burning_obelisks" not in completed_quests:
				start_quest("the_burning_obelisks")
		"the_burning_obelisks":
			if not active_quests.has("heart_of_the_wastes") and "heart_of_the_wastes" not in completed_quests:
				start_quest("heart_of_the_wastes")
		"heart_of_the_wastes":
			if not active_quests.has("into_the_dominion") and "into_the_dominion" not in completed_quests:
				start_quest("into_the_dominion")
		"into_the_dominion":
			if not active_quests.has("the_forsaken_hamlet") and "the_forsaken_hamlet" not in completed_quests:
				start_quest("the_forsaken_hamlet")
		"the_forsaken_hamlet":
			if not active_quests.has("graves_without_rest") and "graves_without_rest" not in completed_quests:
				start_quest("graves_without_rest")
		"graves_without_rest":
			if not active_quests.has("the_dark_observatory") and "the_dark_observatory" not in completed_quests:
				start_quest("the_dark_observatory")
		"the_dark_observatory":
			if not active_quests.has("throne_beneath_the_eclipse") and "throne_beneath_the_eclipse" not in completed_quests:
				start_quest("throne_beneath_the_eclipse")


func has_required_items(quest_id: String) -> bool:
	match quest_id:
		"supplies_for_marsh":
			return InventoryManager.has_item("bogward_tonic") and InventoryManager.has_item("bandage")
		_:
			return true


func sync_inventory_objectives(quest_id: String) -> void:
	if not active_quests.has(quest_id):
		return
	match quest_id:
		"supplies_for_marsh":
			if InventoryManager.has_item("bogward_tonic"):
				_set_objective_current(quest_id, "have_tonic", 1)
			if InventoryManager.get_item_count("bandage") >= 1:
				_set_objective_current(quest_id, "have_bandages", 1)


func _set_objective_current(quest_id: String, objective_id: String, value: int) -> void:
	if not active_quests.has(quest_id):
		return
	var objectives: Array = active_quests[quest_id]
	for obj in objectives:
		if obj.id == objective_id and not obj.completed:
			if obj.current < value:
				obj.current = value
				if obj.current >= obj.target:
					obj.completed = true
				quest_updated.emit(quest_id)
			if _all_complete(objectives):
				complete_quest(quest_id)
			elif quest_id in NpcMissionRegistry.MISSIONS:
				NpcMissionHooks.check_mission_ready_quest(quest_id)
			return


func deserialize(data: Dictionary) -> void:
	active_quests = data.get("active", {})
	completed_quests = data.get("completed", [])
	tracked_quest_id = str(data.get("tracked", ""))
	tracked_quest_changed.emit(tracked_quest_id)
