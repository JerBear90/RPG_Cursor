class_name CampChest
extends InteractableBase

@export var tier: int = 1  # 1=basic deposit, 2=limited withdraw, 3=full


func _ready() -> void:
	super._ready()
	prompt_text = "Camp Chest — Send to Base"


func _on_interact(player: Node) -> void:
	if player is PlayerController:
		GameManager.interacting_player_index = (player as PlayerController).player_index
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("open_camp_chest_menu"):
			hud.open_camp_chest_menu()
			return
