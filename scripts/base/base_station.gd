class_name BaseStation
extends InteractableBase
## Hearthhold Camp crafting/upgrade station.

const _CoopUiCopy := preload("res://scripts/ui/coop_ui_copy.gd")

@export var station_id: String = "workbench"
@export var display_name: String = "Workbench"


func _ready() -> void:
	super._ready()
	_refresh_prompt()
	BaseManager.station_upgraded.connect(_on_station_upgraded)


func _on_station_upgraded(upgraded_id: String, _level: int) -> void:
	if upgraded_id == station_id:
		_refresh_prompt()


func _refresh_prompt() -> void:
	match station_id:
		"water_collector":
			if not BaseManager.is_station_unlocked(station_id):
				prompt_text = "Build %s" % display_name
			elif BaseManager.is_station_on_cooldown(station_id):
				prompt_text = "Water Collector (cooldown)"
			else:
				prompt_text = "Collect Water"
		"garden_plot":
			if not BaseManager.is_station_unlocked(station_id):
				prompt_text = "Build %s" % display_name
			elif BaseManager.is_station_on_cooldown(station_id):
				prompt_text = "Garden Plot (cooldown)"
			else:
				prompt_text = "Harvest Herbs"
		_:
			prompt_text = "Use %s" % display_name


func _on_interact(player: Node) -> void:
	if player is PlayerController:
		GameManager.interacting_player_index = (player as PlayerController).player_index
	var player_index := GameManager.interacting_player_index
	if station_id in ["water_collector", "garden_plot"]:
		if not BaseManager.is_station_unlocked(station_id):
			for hud in get_tree().get_nodes_in_group("game_hud"):
				if hud.has_method("open_upgrade_menu"):
					hud.open_upgrade_menu(station_id)
			return
		if station_id == "water_collector":
			if BaseManager.is_station_on_cooldown(station_id):
				_show_station_toast("Water Collector cooling down", player_index)
				return
			if BaseManager.collect_water(player_index):
				_refresh_prompt()
				_show_station_toast("%s collected %s x1" % [
					_CoopUiCopy.player_tag(player_index),
					"Purified Water" if BaseManager.get_station_level(station_id) >= 2 else "Dirty Water",
				], player_index)
			return
		if station_id == "garden_plot":
			if BaseManager.is_station_on_cooldown(station_id):
				_show_station_toast("Garden Plot recovering", player_index)
				return
			if BaseManager.harvest_garden(player_index):
				_refresh_prompt()
				_show_station_toast("%s harvested %s x1" % [
					_CoopUiCopy.player_tag(player_index),
					"Berries" if BaseManager.get_station_level(station_id) >= 2 else "Herbs",
				], player_index)
			return
	if not BaseManager.is_station_unlocked(station_id):
		if BaseManager.is_buildable_station(station_id):
			for hud in get_tree().get_nodes_in_group("game_hud"):
				if hud.has_method("open_upgrade_menu"):
					hud.open_upgrade_menu(station_id)
			return
		DialogueManager.start_dialogue(station_id, [
			{"speaker": display_name, "text": "This station is not built yet."},
		], [], {"from_interact": true})
		return
	if station_id == "memory_altar":
		SaveManager.save_game(0)
		DialogueManager.start_dialogue("memory_altar", [
			{"speaker": "Memory Altar", "text": "Your exile is etched into the stone. Progress saved."},
		], [], {"from_interact": true})
		return
	if station_id in ["workbench", "forge"]:
		TutorialPromptManager.try_show("crafting")
		for hud in get_tree().get_nodes_in_group("game_hud"):
			hud.open_crafting_menu(station_id)
		return
	if station_id == "item_box":
		for hud in get_tree().get_nodes_in_group("game_hud"):
			hud.open_storage_menu()
		return
	if station_id == "pet_shelter":
		TutorialPromptManager.try_show("pet")
		_handle_pet_shelter_interact(player_index)
		return
	if station_id == "mask_stand":
		for hud in get_tree().get_nodes_in_group("game_hud"):
			if hud.has_method("open_mask_menu"):
				hud.open_mask_menu(player)
		return


func _show_station_toast(message: String, _player_index: int) -> void:
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("show_toast"):
			hud.show_toast(message, 2.5, "", "notification", "", NotificationToast.Priority.NORMAL)
			return


func _handle_pet_shelter_interact(player_index: int) -> void:
	var blocked := PetShelter.get_blocked_reason()
	if blocked != "" and not BaseManager.is_station_unlocked(station_id):
		if blocked == "Beast Bond Required":
			_show_station_toast("Beast Bond Required", player_index)
		for hud in get_tree().get_nodes_in_group("game_hud"):
			if hud.has_method("open_upgrade_menu"):
				hud.open_upgrade_menu(station_id)
		return
	if blocked == "Beast Bond Required":
		_show_station_toast("Beast Bond Required", player_index)
		return
	if BaseManager.get_station_level("pet_shelter") < 1:
		_show_station_toast("Pet Shelter Level 1 Required", player_index)
		for hud in get_tree().get_nodes_in_group("game_hud"):
			if hud.has_method("open_upgrade_menu"):
				hud.open_upgrade_menu(station_id)
		return
	var result := PetManager.adopt_ash_hound_from_shelter(player_index)
	if not result.ok:
		_show_station_toast(str(result.get("reason", "Cannot adopt pet")), player_index)
		return
	var tag := _CoopUiCopy.player_tag(player_index)
	if result.get("reason", "") == "adopted":
		_show_station_toast("%s adopted Ash Hound" % tag, player_index)
	else:
		_show_station_toast("Pet summoned", player_index)
	if not PetManager.has_adopted_pet("ash_hound") or PetManager.active_pet_instance == null:
		DialogueManager.start_dialogue("pet_shelter", [
			{"speaker": display_name, "text": "The Ash Hound stirs from the shelter and joins your exile."},
		], [], {"from_interact": true})
	else:
		PetManager.recover_party_pet(true)
		DialogueManager.start_dialogue("pet_shelter", [
			{"speaker": display_name, "text": "Your companion rests and recovers at the shelter."},
		], [], {"from_interact": true})
