class_name BaseStation
extends InteractableBase
## Hearthhold Camp crafting/upgrade station.

@export var station_id: String = "workbench"
@export var display_name: String = "Workbench"


func _ready() -> void:
	super._ready()
	prompt_text = "Use %s" % display_name


func _on_interact(_player: Node) -> void:
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
		_open_storage_menu()


func _open_storage_menu() -> void:
	DialogueManager.start_dialogue("item_box", [
		{"speaker": "Item Box", "text": "Base storage holds %d item stacks." % InventoryManager.base_storage.size()},
		{"speaker": "Item Box", "text": "Deposit from camp chests in the field to access gear here."},
	])
