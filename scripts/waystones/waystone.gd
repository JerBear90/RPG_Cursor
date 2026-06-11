class_name Waystone
extends InteractableBase

@export var waystone_id: String = "darkpine_forest"


func _ready() -> void:
	add_to_group("waystone")
	super._ready()
	prompt_text = "Use Waystone"


func _on_interact(_player: Node) -> void:
	if waystone_id not in WaystoneManager.discovered:
		WaystoneManager.discover(waystone_id, global_position)
		DialogueManager.start_dialogue(waystone_id, [
			{"speaker": "Waystone", "text": "Cold blue fire ignites along the runes. A path opens in your mind."},
		])
	MapManager.explore_region(GameManager.current_region_id)
	for hud in get_tree().get_nodes_in_group("game_hud"):
		hud.open_waystone_menu()
