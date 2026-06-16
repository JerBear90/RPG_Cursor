class_name CinderholdNpc
extends NpcController
## Cinderhold hub NPCs with quest-aware dialogue and services.

const _INTERACT_OPTS := {"from_interact": true}


func interact(player: Node) -> void:
	if anger_state == "hostile":
		super.interact(player)
		return
	match npc_id:
		"warden_ilyra_voss":
			_dialogue_warden_ilyra()
		"dagan_sunforge":
			_handle_merchant(player)
		"nima_dareth":
			_handle_merchant(player)
		"doctor_sol_marr":
			_dialogue_doctor_sol()
		"scout_kera_ash":
			_dialogue_scout_kera()
		_:
			var greet := DialogueManager.get_npc_greeting(npc_id)
			DialogueManager.start_dialogue(npc_id, greet, [], _INTERACT_OPTS)


func _handle_merchant(_player: Node) -> void:
	_try_quest_delivery()
	if DialogueManager.is_active() or _merchant_dialogue_active:
		return
	_begin_merchant_trade_dialogue()


func _dialogue_warden_ilyra() -> void:
	if QuestManager.completed_quests.has("heart_of_the_wastes"):
		DialogueManager.start_dialogue(npc_id, [
			{"speaker": "Warden Ilyra Voss", "text": "The Solar Heart is cooled. Cinderhold stands — but the Sunless Dominion waits beyond the sealed road."},
		], [], _INTERACT_OPTS)
		return
	if QuestManager.active_quests.has("heart_of_the_wastes"):
		DialogueManager.start_dialogue(npc_id, [
			{"speaker": "Warden Ilyra Voss", "text": "The Pyreheart Ziggurat holds the Solar Heart. Align the mirrors, cool the channels, and end what burns beneath the sand."},
		], [], _INTERACT_OPTS)
		return
	if QuestManager.completed_quests.has("the_burning_obelisks"):
		if not QuestManager.active_quests.has("heart_of_the_wastes") and "heart_of_the_wastes" not in QuestManager.completed_quests:
			QuestManager.start_quest("heart_of_the_wastes")
		DialogueManager.start_dialogue(npc_id, [
			{"speaker": "Warden Ilyra Voss", "text": "The obelisk fragment opens the ziggurat. Take the sigil you've earned and descend — the heart of the wastes must be stilled."},
		], [], _INTERACT_OPTS)
		return
	if QuestManager.active_quests.has("the_burning_obelisks"):
		DialogueManager.start_dialogue(npc_id, [
			{"speaker": "Warden Ilyra Voss", "text": "Burning obelisks mark cult territory east of camp. Break their mirrors and recover the fragment that unlocks Pyreheart."},
		], [], _INTERACT_OPTS)
		return
	if QuestManager.completed_quests.has("glass_beneath_the_sand"):
		if not QuestManager.active_quests.has("the_burning_obelisks") and "the_burning_obelisks" not in QuestManager.completed_quests:
			QuestManager.start_quest("the_burning_obelisks")
		DialogueManager.start_dialogue(npc_id, [
			{"speaker": "Warden Ilyra Voss", "text": "The glass field is catalogued. Pyre cultists gather at the burning obelisks — investigate before they summon worse."},
		], [], _INTERACT_OPTS)
		return
	if QuestManager.active_quests.has("glass_beneath_the_sand"):
		DialogueManager.start_dialogue(npc_id, [
			{"speaker": "Warden Ilyra Voss", "text": "The glass dune hides volcanic shards. Clear the husks and recover enough fragments for our records."},
		], [], _INTERACT_OPTS)
		return
	if QuestManager.completed_quests.has("the_dry_road"):
		if not QuestManager.active_quests.has("glass_beneath_the_sand") and "glass_beneath_the_sand" not in QuestManager.completed_quests:
			QuestManager.start_quest("glass_beneath_the_sand")
		DialogueManager.start_dialogue(npc_id, [
			{"speaker": "Warden Ilyra Voss", "text": "The dry road is open. The buried glass field lies beyond — scout Kera marked the dune if you need bearings."},
		], [], _INTERACT_OPTS)
		return
	if QuestManager.active_quests.has("the_dry_road"):
		DialogueManager.start_dialogue(npc_id, [
			{"speaker": "Warden Ilyra Voss", "text": "Dune raiders choke the dry road. Clear them and reopen the trail to the glass dune."},
		], [], _INTERACT_OPTS)
		return
	if QuestManager.completed_quests.has("into_the_ember"):
		if not QuestManager.active_quests.has("the_dry_road") and "the_dry_road" not in QuestManager.completed_quests:
			QuestManager.start_quest("the_dry_road")
		DialogueManager.start_dialogue(npc_id, [
			{"speaker": "Warden Ilyra Voss", "text": "Cinderhold holds for now. Push the dry road when you're supplied — raiders won't wait."},
		], [], _INTERACT_OPTS)
		return
	if QuestManager.active_quests.has("into_the_ember"):
		QuestManager.advance_objective("into_the_ember", "speak_commander", 1)
		DialogueManager.start_dialogue(npc_id, [
			{"speaker": "Warden Ilyra Voss", "text": "Exile, welcome to Cinderhold. Heat kills faster than raiders out here."},
			{"speaker": "Warden Ilyra Voss", "text": "Activate our waystone, then speak with Nima and Sol Marr before you march the wastes."},
		], [], _INTERACT_OPTS)
		return
	if "into_the_ember" not in QuestManager.completed_quests:
		QuestManager.start_quest("into_the_ember")
	QuestManager.advance_objective("into_the_ember", "speak_commander", 1)
	DialogueManager.start_dialogue(npc_id, [
		{"speaker": "Warden Ilyra Voss", "text": "You crossed from Blightreach — good. Cinderhold is the last shade for leagues."},
		{"speaker": "Warden Ilyra Voss", "text": "Stock water and heat tonic. The Ember Wastes do not forgive thirst."},
	], [], _INTERACT_OPTS)


func _dialogue_doctor_sol() -> void:
	if DialogueManager.is_active():
		return
	DialogueManager.start_dialogue(npc_id, [
		{"speaker": "Doctor Sol Marr", "text": "Heat, sand, and glass dust — I brew remedies for all three. Craft here or buy what you cannot make."},
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
		npc_id = "doctor_sol_marr"
		_begin_merchant_trade_dialogue()
		is_merchant = false


func _dialogue_scout_kera() -> void:
	if QuestManager.completed_quests.has("defeat_sunscar_behemoth"):
		DialogueManager.start_dialogue(npc_id, [
			{"speaker": "Scout Kera Ash", "text": "The Sunscar Behemoth is down. The deep dunes are safer — for now."},
		], [], _INTERACT_OPTS)
		return
	if QuestManager.active_quests.has("defeat_sunscar_behemoth"):
		DialogueManager.start_dialogue(npc_id, [
			{"speaker": "Scout Kera Ash", "text": "The behemoth sun-scars the eastern dunes. Bring heat tonic and strike when it rears."},
		], [], _INTERACT_OPTS)
		return
	if not QuestManager.active_quests.has("defeat_sunscar_behemoth") and "defeat_sunscar_behemoth" not in QuestManager.completed_quests:
		QuestManager.start_quest("defeat_sunscar_behemoth")
	if not QuestManager.active_quests.has("hunt_ashscale_packs") and "hunt_ashscale_packs" not in QuestManager.completed_quests:
		QuestManager.start_quest("hunt_ashscale_packs")
	if not QuestManager.active_quests.has("harvest_sunstone") and "harvest_sunstone" not in QuestManager.completed_quests:
		QuestManager.start_quest("harvest_sunstone")
	if not QuestManager.active_quests.has("gather_scorched_sand") and "gather_scorched_sand" not in QuestManager.completed_quests:
		QuestManager.start_quest("gather_scorched_sand")
	DialogueManager.start_dialogue(npc_id, [
		{"speaker": "Scout Kera Ash", "text": "I map dens, behemoths, and buried trap fields. Ashscale packs nest northwest — collapse their dens."},
		{"speaker": "Scout Kera Ash", "text": "Sunstone shards glitter south of the glass dune. A lost researcher was last seen near the obelisks — watch for cultists."},
		{"speaker": "Scout Kera Ash", "text": "Pyre crystals only form inside the ziggurat. Collect them if you reach the inner pyramid."},
	], [], _INTERACT_OPTS)


func _try_quest_delivery() -> void:
	super._try_quest_delivery()
