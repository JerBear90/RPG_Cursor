class_name BaseStation
extends InteractableBase
## Hearthhold Camp crafting/upgrade station.

@export var station_id: String = "workbench"
@export var display_name: String = "Workbench"


func _ready() -> void:
	super._ready()
	prompt_text = "Use %s" % display_name


func _on_interact(player: Node) -> void:
	if not BaseManager.is_station_unlocked(station_id):
		DialogueManager.start_dialogue(station_id, [
			{"speaker": display_name, "text": "This station is not built yet."},
		])
		return
	if station_id == "memory_altar":
		SaveManager.save_game(0)
		DialogueManager.start_dialogue("memory_altar", [
			{"speaker": "Memory Altar", "text": "Your exile is etched into the stone. Progress saved."},
		])
		return
	if station_id in ["workbench", "forge"]:
		for hud in get_tree().get_nodes_in_group("game_hud"):
			hud.open_crafting_menu(station_id)
		return
	if station_id == "item_box":
		for hud in get_tree().get_nodes_in_group("game_hud"):
			hud.open_storage_menu()
		return
	if station_id == "pet_shelter":
		PetManager.unlock_ash_hound_from_shelter()
		DialogueManager.start_dialogue("pet_shelter", [
			{"speaker": display_name, "text": "The Ash Hound stirs from the shelter and joins your exile."},
		])
		return
	if station_id == "mask_stand":
		for hud in get_tree().get_nodes_in_group("game_hud"):
			if hud.has_method("open_mask_menu"):
				hud.open_mask_menu(player)
		return
