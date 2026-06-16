class_name DawnwatchNpc
extends NpcController
## Dawnwatch hub NPCs with quest-aware dialogue and services.

const _INTERACT_OPTS := {"from_interact": true}


func interact(player: Node) -> void:
	if anger_state == "hostile":
		super.interact(player)
		return
	match npc_id:
		"commander_alaric_vane":
			_dialogue_commander_alaric()
		"selene_nightforge":
			_handle_merchant(player)
		"mira_sol":
			_handle_merchant(player)
		"doctor_corvin_hale":
			_dialogue_doctor_corvin()
		"scout_nyra_vale":
			_dialogue_scout_nyra()
		_:
			var greet := DialogueManager.get_npc_greeting(npc_id)
			DialogueManager.start_dialogue(npc_id, greet, [], _INTERACT_OPTS)


func _handle_merchant(_player: Node) -> void:
	_try_quest_delivery()
	if DialogueManager.is_active() or _merchant_dialogue_active:
		return
	_begin_merchant_trade_dialogue()


func _dialogue_commander_alaric() -> void:
	if QuestManager.completed_quests.has("throne_beneath_the_eclipse"):
		DialogueManager.start_dialogue(npc_id, [
			{"speaker": "Commander Alaric Vane", "text": "The sealed throne holds — for now. Dawnwatch endures while the sovereign shadow waits beyond."},
		], [], _INTERACT_OPTS)
		return
	if QuestManager.active_quests.has("throne_beneath_the_eclipse"):
		DialogueManager.start_dialogue(npc_id, [
			{"speaker": "Commander Alaric Vane", "text": "Eclipse Sanctum opens to those who bear the shard. Align the shadow mirrors and reach the throne antechamber — do not trust what waits beyond the seal."},
		], [], _INTERACT_OPTS)
		return
	if QuestManager.completed_quests.has("the_dark_observatory"):
		if not QuestManager.active_quests.has("throne_beneath_the_eclipse") and "throne_beneath_the_eclipse" not in QuestManager.completed_quests:
			QuestManager.start_quest("throne_beneath_the_eclipse")
		DialogueManager.start_dialogue(npc_id, [
			{"speaker": "Commander Alaric Vane", "text": "The eclipse shard is yours. Descend into the sanctum and still what stirs beneath the observatory."},
		], [], _INTERACT_OPTS)
		return
	if QuestManager.active_quests.has("the_dark_observatory"):
		DialogueManager.start_dialogue(npc_id, [
			{"speaker": "Commander Alaric Vane", "text": "The Dark Observatory crowns the eastern bluff. Cultists gather there — recover the eclipse shard before they complete their rite."},
		], [], _INTERACT_OPTS)
		return
	if QuestManager.completed_quests.has("graves_without_rest"):
		if not QuestManager.active_quests.has("the_dark_observatory") and "the_dark_observatory" not in QuestManager.completed_quests:
			QuestManager.start_quest("the_dark_observatory")
		DialogueManager.start_dialogue(npc_id, [
			{"speaker": "Commander Alaric Vane", "text": "The gravewind is sealed. Push to the observatory — its lenses still track the eclipse."},
		], [], _INTERACT_OPTS)
		return
	if QuestManager.active_quests.has("graves_without_rest"):
		DialogueManager.start_dialogue(npc_id, [
			{"speaker": "Commander Alaric Vane", "text": "Royal graves stir without rest east of camp. Break the wraiths and recover the ward seals."},
		], [], _INTERACT_OPTS)
		return
	if QuestManager.completed_quests.has("the_forsaken_hamlet"):
		if not QuestManager.active_quests.has("graves_without_rest") and "graves_without_rest" not in QuestManager.completed_quests:
			QuestManager.start_quest("graves_without_rest")
		DialogueManager.start_dialogue(npc_id, [
			{"speaker": "Commander Alaric Vane", "text": "The hamlet is catalogued. Grave sites beyond still pulse with nightbound malice."},
		], [], _INTERACT_OPTS)
		return
	if QuestManager.active_quests.has("the_forsaken_hamlet"):
		DialogueManager.start_dialogue(npc_id, [
			{"speaker": "Commander Alaric Vane", "text": "The forsaken hamlet lies northwest. Clear the nightbound and recover survivor records."},
		], [], _INTERACT_OPTS)
		return
	if QuestManager.completed_quests.has("into_the_dominion"):
		if not QuestManager.active_quests.has("the_forsaken_hamlet") and "the_forsaken_hamlet" not in QuestManager.completed_quests:
			QuestManager.start_quest("the_forsaken_hamlet")
		DialogueManager.start_dialogue(npc_id, [
			{"speaker": "Commander Alaric Vane", "text": "Dawnwatch holds. Scout the forsaken hamlet when your wards are stocked."},
		], [], _INTERACT_OPTS)
		return
	if QuestManager.active_quests.has("into_the_dominion"):
		QuestManager.advance_objective("into_the_dominion", "speak_commander", 1)
		DialogueManager.start_dialogue(npc_id, [
			{"speaker": "Commander Alaric Vane", "text": "Exile, welcome to Dawnwatch. Dread kills slower than steel — but it always wins."},
			{"speaker": "Commander Alaric Vane", "text": "Activate our waystone, then speak with Mira Sol and Doctor Hale before you march the dominion."},
		], [], _INTERACT_OPTS)
		return
	if "into_the_dominion" not in QuestManager.completed_quests:
		QuestManager.start_quest("into_the_dominion")
	QuestManager.advance_objective("into_the_dominion", "speak_commander", 1)
	DialogueManager.start_dialogue(npc_id, [
		{"speaker": "Commander Alaric Vane", "text": "You crossed from Cinderhold — good. Dawnwatch is the last warded light for leagues."},
		{"speaker": "Commander Alaric Vane", "text": "Stock ward candles and dread tonic. The Sunless Dominion does not forgive fear."},
	], [], _INTERACT_OPTS)


func _dialogue_doctor_corvin() -> void:
	if DialogueManager.is_active():
		return
	DialogueManager.start_dialogue(npc_id, [
		{"speaker": "Doctor Corvin Hale", "text": "Shadow, dread, and umbral sickness — I brew remedies for all three. Craft here or buy what you cannot make."},
	], ["Craft remedies", "Browse supplies", "Leave"], _INTERACT_OPTS)
	_await_apothecary_choice()


func _await_apothecary_choice() -> void:
	var payload: Array = await DialogueManager.dialogue_finished
	if str(payload[0]) != npc_id:
		return
	if payload[1] != DialogueManager.DialogueEndReason.CONFIRMED:
		return
	var choice_idx: int = int(payload[2])
	if choice_idx == 2:
		return
	if choice_idx == 0:
		for hud in get_tree().get_nodes_in_group("game_hud"):
			if hud.has_method("open_crafting_menu"):
				hud.open_crafting_menu("apothecary")
	elif choice_idx == 1:
		is_merchant = true
		npc_id = "doctor_corvin_hale"
		_begin_merchant_trade_dialogue()
		is_merchant = false


func _dialogue_scout_nyra() -> void:
	if QuestManager.completed_quests.has("defeat_dominion_executioner"):
		DialogueManager.start_dialogue(npc_id, [
			{"speaker": "Scout Nyra Vale", "text": "The Dominion Executioner is down. The deep wards are safer — for now."},
		], [], _INTERACT_OPTS)
		return
	if QuestManager.active_quests.has("defeat_dominion_executioner"):
		DialogueManager.start_dialogue(npc_id, [
			{"speaker": "Scout Nyra Vale", "text": "The executioner patrols the eastern bluff. Bring dread tonic and strike when it turns from the light."},
		], [], _INTERACT_OPTS)
		return
	if not QuestManager.active_quests.has("defeat_dominion_executioner") and "defeat_dominion_executioner" not in QuestManager.completed_quests:
		QuestManager.start_quest("defeat_dominion_executioner")
	if not QuestManager.active_quests.has("destroy_gloom_hound_dens") and "destroy_gloom_hound_dens" not in QuestManager.completed_quests:
		QuestManager.start_quest("destroy_gloom_hound_dens")
	if not QuestManager.active_quests.has("gather_moonstone") and "gather_moonstone" not in QuestManager.completed_quests:
		QuestManager.start_quest("gather_moonstone")
	if not QuestManager.active_quests.has("collect_nightglass") and "collect_nightglass" not in QuestManager.completed_quests:
		QuestManager.start_quest("collect_nightglass")
	if not QuestManager.active_quests.has("rescue_lost_patrol") and "rescue_lost_patrol" not in QuestManager.completed_quests:
		QuestManager.start_quest("rescue_lost_patrol")
	if not QuestManager.active_quests.has("recover_royal_relics") and "recover_royal_relics" not in QuestManager.completed_quests:
		QuestManager.start_quest("recover_royal_relics")
	if not QuestManager.active_quests.has("purify_shadow_wells") and "purify_shadow_wells" not in QuestManager.completed_quests:
		QuestManager.start_quest("purify_shadow_wells")
	DialogueManager.start_dialogue(npc_id, [
		{"speaker": "Scout Nyra Vale", "text": "I map gloom hound dens, shadow wells, and lost patrol trails. Collapse their dens northwest."},
		{"speaker": "Scout Nyra Vale", "text": "Moonstone glitters south of the hamlet. Royal relics were last seen near the graves — watch for cultists."},
		{"speaker": "Scout Nyra Vale", "text": "Nightglass only forms near the observatory. Collect it if you reach the eastern bluff."},
	], [], _INTERACT_OPTS)


func _try_quest_delivery() -> void:
	super._try_quest_delivery()
