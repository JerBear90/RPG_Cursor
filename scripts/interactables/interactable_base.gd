class_name InteractableBase
extends StaticBody3D
## Base for interactable world objects.

@export var prompt_text: String = "Interact"
@export var interaction_id: String = ""

signal interacted(player: Node)


func _ready() -> void:
	add_to_group("interactable")


func interact(player: Node) -> void:
	if player is PlayerController:
		GameManager.interacting_player_index = (player as PlayerController).player_index
	interacted.emit(player)
	_on_interact(player)


func _on_interact(_player: Node) -> void:
	pass
