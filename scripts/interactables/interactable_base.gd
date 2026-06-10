class_name InteractableBase
extends StaticBody3D
## Base for interactable world objects.

@export var prompt_text: String = "Interact"
@export var interaction_id: String = ""

signal interacted(player: Node)


func _ready() -> void:
	add_to_group("interactable")


func interact(player: Node) -> void:
	interacted.emit(player)
	_on_interact(player)


func _on_interact(_player: Node) -> void:
	pass
