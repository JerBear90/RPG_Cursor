class_name HearthholdNpc
extends NpcController
## Hearthhold hub NPCs with quest-aware dialogue, missions, and relationship repair.

const _MISSION_NPCS: Dictionary = {
	"bram_ironhand": "rebuild_the_forge",
	"old_blacksmith": "rebuild_the_forge",
	"wounded_scout": "clear_bandit_path",
	"quartermaster_vale": "build_the_basics",
	"beast_handler": "a_hound_in_the_ash",
	"waystone_keeper": "wake_the_stone",
}


func _ready() -> void:
	super._ready()
	call_deferred("_sync_anger_from_save")


func _sync_anger_from_save() -> void:
	anger_state = NpcStateManager.get_anger(npc_id)


func interact(player: Node) -> void:
	if player is PlayerController:
		GameManager.interacting_player_index = (player as PlayerController).player_index
	if anger_state == "hostile":
		super.interact(player)
		return
	if _try_relationship_repair():
		return
	if _MISSION_NPCS.has(npc_id):
		if _try_npc_mission_dialogue():
			return
	if is_merchant:
		_handle_merchant(player)
		return
	if is_quest_giver:
		_handle_quest_giver(player)
		return
	var greet := DialogueManager.get_npc_greeting(npc_id)
	DialogueManager.start_dialogue(npc_id, greet, [], _INTERACT_OPTS)


func _try_relationship_repair() -> bool:
	var anger := NpcStateManager.get_anger(npc_id)
	if anger == "calm":
		return false
	if anger == "hostile" and not NpcStateManager.can_use_service(npc_id):
		DialogueManager.start_dialogue(npc_id, [
			{"speaker": _speaker_label(), "text": NpcStateManager.get_service_block_reason(npc_id)},
		], ["Pay Fine", "Leave"], _INTERACT_OPTS)
		if DialogueManager.is_active():
			_await_repair_choice(["fine"])
		return true
	if anger in ["annoyed", "angry"]:
		DialogueManager.start_dialogue(npc_id, [
			{"speaker": _speaker_label(), "text": "%s — %s" % [display_name, NpcStateManager.get_relationship_label(npc_id)]},
			{"speaker": _speaker_label(), "text": NpcStateManager.get_service_block_reason(npc_id)},
		], ["Pay Fine", "Offer Gift", "Leave"], _INTERACT_OPTS)
		if DialogueManager.is_active():
			_await_repair_choice(["fine", "gift"])
		return true
	return false


func _await_repair_choice(actions: Array[String]) -> void:
	var payload: Array = await DialogueManager.dialogue_finished
	if str(payload[0]) != npc_id:
		return
	if payload[1] != DialogueManager.DialogueEndReason.CONFIRMED:
		return
	var choice_idx := int(payload[2]) if payload.size() > 2 else DialogueManager.last_choice_index
	if choice_idx < 0 or choice_idx >= actions.size():
		return
	match actions[choice_idx]:
		"fine":
			var result := NpcStateManager.try_pay_fine(npc_id)
			if not result.ok:
				_show_npc_toast(str(result.reason))
			else:
				_deescalate_from_hostile()
			_sync_anger_from_save()
		"gift":
			var gift := _pick_gift_item()
			if gift == "":
				_show_npc_toast("Gift refused")
				return
			var gift_result := NpcStateManager.try_gift(npc_id, gift)
			if not gift_result.ok:
				_show_npc_toast(str(gift_result.reason))
			else:
				_deescalate_from_hostile()
			_sync_anger_from_save()


func _deescalate_from_hostile() -> void:
	if anger_state != "hostile":
		return
	anger_state = NpcStateManager.get_anger(npc_id)
	remove_from_group("lockable_enemy")
	if _health:
		_health.reset_health()
	velocity = Vector3.ZERO


func _pick_gift_item() -> String:
	for item_id in NpcStateManager.GIFT_ITEMS.keys():
		if InventoryManager.has_item(item_id):
			return item_id
	return ""


func _try_npc_mission_dialogue() -> bool:
	var quest_id: String = _MISSION_NPCS[npc_id]
	if QuestManager.completed_quests.has(quest_id):
		var choices: Array[String] = ["Leave"]
		if is_merchant and NpcStateManager.can_use_service(npc_id):
			choices = ["Trade", "Leave"]
		DialogueManager.start_dialogue(npc_id, _mission_complete_lines(quest_id), choices, _INTERACT_OPTS)
		if DialogueManager.is_active() and is_merchant:
			_await_merchant_after_mission()
		return true
	if QuestManager.active_quests.has(quest_id):
		if NpcMissionHooks.try_turn_in(npc_id, quest_id):
			DialogueManager.start_dialogue(npc_id, _mission_turn_in_lines(quest_id), [], _INTERACT_OPTS)
			return true
		var progress_choices: Array[String] = ["Leave"]
		if is_merchant and NpcStateManager.can_use_service(npc_id):
			progress_choices = ["Trade", "Leave"]
		DialogueManager.start_dialogue(npc_id, _mission_progress_lines(quest_id), progress_choices, _INTERACT_OPTS)
		if DialogueManager.is_active() and is_merchant:
			_await_merchant_after_mission()
		return true
	if not NpcStateManager.can_use_service(npc_id):
		return _try_relationship_repair()
	DialogueManager.start_dialogue(npc_id, _mission_offer_lines(quest_id), ["Accept Mission", "Leave"], _INTERACT_OPTS)
	if DialogueManager.is_active():
		_await_mission_offer(quest_id)
	return true


func _await_merchant_after_mission() -> void:
	var payload: Array = await DialogueManager.dialogue_finished
	if str(payload[0]) != npc_id:
		return
	if payload[1] != DialogueManager.DialogueEndReason.CONFIRMED:
		return
	if int(payload[2]) != 0:
		return
	_begin_merchant_trade_dialogue()


func _await_mission_offer(quest_id: String) -> void:
	var payload: Array = await DialogueManager.dialogue_finished
	if str(payload[0]) != npc_id:
		return
	if payload[1] == DialogueManager.DialogueEndReason.CONFIRMED:
		QuestManager.start_quest(quest_id)
		QuestManager.track_quest(quest_id)
		NpcMissionHooks.sync_inventory_missions()
		_sync_station_missions(quest_id)


func _sync_station_missions(quest_id: String) -> void:
	if quest_id == "build_the_basics":
		var wb := BaseManager.get_station_level("workbench")
		if wb >= 2:
			QuestManager.advance_objective(quest_id, "upgrade_workbench", 1)
		if BaseManager.get_station_level("water_collector") >= 1:
			QuestManager.advance_objective(quest_id, "build_water", 1)
		if BaseManager.get_station_level("garden_plot") >= 1:
			QuestManager.advance_objective(quest_id, "build_garden", 1)
	if quest_id == "a_hound_in_the_ash":
		NpcMissionHooks.check_beast_bond_skill()
		if BaseManager.get_station_level("pet_shelter") >= 1:
			QuestManager.advance_objective(quest_id, "upgrade_pet_shelter", 1)
		if PetManager.has_adopted_pet("ash_hound"):
			QuestManager.advance_objective(quest_id, "adopt_hound", 1)


func _offer_trade_after_mission() -> void:
	pass


func _speaker_label() -> String:
	var rel := NpcStateManager.get_relationship_label(npc_id)
	if NpcStateManager.get_anger(npc_id) != "calm":
		return "%s — %s" % [display_name, rel]
	return display_name


func _mission_offer_lines(quest_id: String) -> Array[Dictionary]:
	match quest_id:
		"rebuild_the_forge":
			return [
				{"speaker": _speaker_label(), "text": "Need steel, stitches, or a reason not to die? Pick one."},
				{"speaker": _speaker_label(), "text": "Forge is choking on rust. Bring me scraps and fire resin, and I'll make it breathe again."},
			]
		"clear_bandit_path":
			return [
				{"speaker": _speaker_label(), "text": "Bandits turned the forest path into a butcher shop. Clear five of them and report back."},
			]
		"build_the_basics":
			return [
				{"speaker": _speaker_label(), "text": "Camp won't survive on good intentions. Upgrade the workbench, water collector, and garden — then talk to me."},
			]
		"a_hound_in_the_ash":
			return [
				{"speaker": _speaker_label(), "text": "Animals know this land better than we do. Mostly because they complain less."},
				{"speaker": _speaker_label(), "text": "Build a shelter, earn its trust, and maybe the Ash Hound won't bite your favorite leg."},
			]
		"wake_the_stone":
			return [
				{"speaker": _speaker_label(), "text": "Waystones sleep until fed crystal and courage. Find one, wake it, bring proof."},
			]
		_:
			return [{"speaker": display_name, "text": "I've got work if you're not dead yet."}]


func _mission_progress_lines(quest_id: String) -> Array[Dictionary]:
	match quest_id:
		"rebuild_the_forge":
			return [{"speaker": _speaker_label(), "text": "Still waiting on those scraps. The Forge won't fix itself. Lazy bastard."}]
		"clear_bandit_path":
			return [{"speaker": _speaker_label(), "text": "Bandits still breathing out there. Fix that before you waste my time."}]
		"build_the_basics":
			return [{"speaker": _speaker_label(), "text": "Workbench, water, garden — basics first. Even refugees should know that."}]
		"a_hound_in_the_ash":
			return [{"speaker": _speaker_label(), "text": "Beast Bond, shelter, bones, hound. In that order. Don't skip steps."}]
		"wake_the_stone":
			return [{"speaker": _speaker_label(), "text": "Find the stone, gather shards, wake it. The path won't open itself."}]
		_:
			return [{"speaker": display_name, "text": "Finish what you started."}]


func _mission_turn_in_lines(quest_id: String) -> Array[Dictionary]:
	match quest_id:
		"rebuild_the_forge":
			return [{"speaker": _speaker_label(), "text": "There. Hear that? That's the sound of metal remembering it used to be useful."}]
		"clear_bandit_path":
			return [{"speaker": _speaker_label(), "text": "Path's quieter. For now. Take your pay before more show up."}]
		"build_the_basics":
			return [{"speaker": _speaker_label(), "text": "Camp looks less like a graveyard. Good. Keep building."}]
		"a_hound_in_the_ash":
			return [{"speaker": _speaker_label(), "text": "Good. You've got a companion now. Try not to get it killed. It'll make us both look bad."}]
		"wake_the_stone":
			return [{"speaker": _speaker_label(), "text": "Stone's awake. Routes open. Try not to die somewhere stupid."}]
		_:
			return [{"speaker": display_name, "text": "Done. Here's your due."}]


func _mission_complete_lines(quest_id: String) -> Array[Dictionary]:
	match quest_id:
		"rebuild_the_forge":
			var discount := int(NpcStateManager.get_repair_discount(npc_id) * 100.0)
			var extra := " Repair Discount: %d%%" % discount if discount > 0 else ""
			return [{"speaker": _speaker_label(), "text": "Forge runs hot. Bring me scrap anytime.%s" % extra}]
		"clear_bandit_path":
			return [{"speaker": _speaker_label(), "text": "You kept someone breathing. The forest owes you."}]
		"build_the_basics":
			return [{"speaker": _speaker_label(), "text": "Camp basics are covered. Upgrade discount noted — build smart."}]
		"a_hound_in_the_ash":
			return [{"speaker": _speaker_label(), "text": "Hound's yours. Treat it better than you treat yourself."}]
		"wake_the_stone":
			return [{"speaker": _speaker_label(), "text": "Stones remember travelers who feed them crystal."}]
		_:
			return [{"speaker": display_name, "text": "Appreciate the help."}]


func _show_npc_toast(message: String) -> void:
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("show_toast"):
			hud.show_toast(message, 2.5)
			return


func _handle_merchant(_player: Node) -> void:
	_try_quest_delivery()
	if DialogueManager.is_active() or _merchant_dialogue_active:
		return
	if not NpcStateManager.can_use_service(npc_id):
		_try_relationship_repair()
		return
	_begin_merchant_trade_dialogue()


func _open_merchant_shop_once() -> void:
	if _merchant_shop_open_requested:
		return
	if not is_instance_valid(self):
		return
	_merchant_shop_open_requested = true
	await get_tree().process_frame
	if not is_instance_valid(self):
		_merchant_shop_open_requested = false
		return
	if MerchantManager.is_shop_open:
		_merchant_shop_open_requested = false
		return
	var anger := NpcStateManager.get_anger(npc_id)
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("open_merchant_menu"):
			hud.open_merchant_menu(npc_id, anger)
			break
	if not MerchantManager.is_shop_open:
		_merchant_shop_open_requested = false


func receive_friendly_fire() -> void:
	var msg := NpcStateManager.on_npc_hit(npc_id, GameManager.interacting_player_index)
	anger_state = NpcStateManager.get_anger(npc_id)
	DialogueManager.start_dialogue(npc_id, [{"speaker": _speaker_label(), "text": msg}], [], {"from_interact": false})
	if anger_state == "hostile":
		_enable_combat_mode()
	elif anger_state == "annoyed":
		AchievementManager.unlock("angry_vendor")


func _handle_quest_giver(_player: Node) -> void:
	match npc_id:
		"captain_elira_voss":
			_dialogue_captain_elira()
		"mara_fen":
			_dialogue_mara_fen()
		"sister_anwen":
			_dialogue_sister_anwen()
		_:
			var greet := DialogueManager.get_npc_greeting(npc_id)
			DialogueManager.start_dialogue(npc_id, greet, [], _INTERACT_OPTS)


func _dialogue_captain_elira() -> void:
	if QuestManager.completed_quests.has("the_rot_below"):
		DialogueManager.start_dialogue(npc_id, [
			{"speaker": "Captain Elira Voss", "text": "The Rotfen route is open. Keep your tonic close and your blade closer."},
		], [], _INTERACT_OPTS)
		return
	if QuestManager.active_quests.has("the_rot_below"):
		var objs: Array = QuestManager.active_quests["the_rot_below"]
		var caravan_done := false
		var mara_done := false
		for obj in objs:
			if obj.id == "inspect_caravan" and obj.completed:
				caravan_done = true
			if obj.id == "speak_mara" and obj.completed:
				mara_done = true
		if caravan_done and mara_done:
			QuestManager.advance_objective("the_rot_below", "report_captain", 1)
			DialogueManager.start_dialogue(npc_id, [
				{"speaker": "Captain Elira Voss", "text": "The caravan was a warning. Rotfen opens when you're supplied — speak with Mara at the south gate."},
			], [], _INTERACT_OPTS)
			return
	QuestManager.start_quest("the_rot_below")
	QuestManager.track_quest("the_rot_below")
	DialogueManager.start_dialogue(npc_id, [
		{"speaker": "Captain Elira Voss", "text": "Exile, welcome to Hearthhold. Mara Fen knows the marsh routes — speak with her first."},
		{"speaker": "Captain Elira Voss", "text": "Then inspect the damaged caravan north of the gate and report back."},
	], [], _INTERACT_OPTS)


func _dialogue_mara_fen() -> void:
	if QuestManager.active_quests.has("supplies_for_marsh"):
		if QuestManager.has_required_items("supplies_for_marsh"):
			QuestManager.advance_objective("supplies_for_marsh", "speak_mara_gate", 1)
			DialogueManager.start_dialogue(npc_id, [
				{"speaker": "Mara Fen", "text": "You're stocked for the marsh. The south gate is yours when you're ready."},
			], [], _INTERACT_OPTS)
			return
		DialogueManager.start_dialogue(npc_id, [
			{"speaker": "Mara Fen", "text": "Bring a Bogward Tonic and bandages. Buy, craft, or use what you already carry."},
		], [], _INTERACT_OPTS)
		return
	if QuestManager.completed_quests.has("into_rotfen"):
		DialogueManager.start_dialogue(npc_id, [
			{"speaker": "Mara Fen", "text": "Marshwatch holds — don't wander the deep water alone."},
		], [], _INTERACT_OPTS)
		return
	if QuestManager.completed_quests.has("the_rot_below"):
		if not QuestManager.active_quests.has("supplies_for_marsh") and not QuestManager.completed_quests.has("supplies_for_marsh"):
			QuestManager.start_quest("supplies_for_marsh")
		DialogueManager.start_dialogue(npc_id, [
			{"speaker": "Mara Fen", "text": "Rotfen poisons everything it touches. Stock Bogward Tonic and bandages, then meet me at the south gate."},
		], [], _INTERACT_OPTS)
		return
	if QuestManager.active_quests.has("the_rot_below"):
		QuestManager.advance_objective("the_rot_below", "speak_mara", 1)
		DialogueManager.start_dialogue(npc_id, [
			{"speaker": "Mara Fen", "text": "Stick to the boardwalks. Shallow water slows you — deep water kills."},
			{"speaker": "Mara Fen", "text": "The damaged caravan is north of the Darkpine gate. Captain Voss wants your report after."},
		], [], _INTERACT_OPTS)
		return


func _dialogue_sister_anwen() -> void:
	DialogueManager.start_dialogue(npc_id, [
		{"speaker": "Sister Anwen", "text": "Poison takes root quickly in Rotfen. Visit the chapel infirmary if you need cleansing."},
	], ["Seek healing", "Leave"], _INTERACT_OPTS)
	if DialogueManager.is_active():
		_await_healer_choice()


func _await_healer_choice() -> void:
	var payload: Array = await DialogueManager.dialogue_finished
	if str(payload[0]) != npc_id:
		return
	if payload[1] == DialogueManager.DialogueEndReason.CONFIRMED:
		var player := GameManager.get_player(0)
		if player and player.has_node("HealthComponent"):
			(player.get_node("HealthComponent") as HealthComponent).heal(40.0)
		if player and player.has_node("SurvivalNeedsComponent"):
			var needs := player.get_node("SurvivalNeedsComponent") as SurvivalNeedsComponent
			needs.hunger = minf(needs.hunger + 20.0, needs.max_hunger)
			needs.thirst = minf(needs.thirst + 20.0, needs.max_thirst)
		_show_npc_toast("Sister Anwen restores your strength.")


func _try_quest_delivery() -> void:
	super._try_quest_delivery()
	if QuestManager.active_quests.has("supplies_for_marsh"):
		QuestManager.sync_inventory_objectives("supplies_for_marsh")
