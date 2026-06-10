class_name DungeonEntrance
extends InteractableBase

@export var entrance_region_id: String = "darkpine_forest"
@export var return_scene_path: String = "res://scenes/levels/darkpine_forest/darkpine_forest.tscn"
@export var co_op_radius: float = 6.0


func _ready() -> void:
	super._ready()
	prompt_text = "Enter Procedural Dungeon"
	add_to_group("dungeon_entrance")


func _on_interact(_player: Node) -> void:
	var nearby := GameManager.all_players_near(global_position, co_op_radius)
	if not DungeonManager.can_enter(nearby):
		DialogueManager.start_dialogue("dungeon_blocked", [
			{"speaker": "Ruined Hatch", "text": "Wait for your ally — both exiles must stand at the hatch."},
		])
		return
	DungeonManager.enter_dungeon(entrance_region_id, return_scene_path, global_position)
