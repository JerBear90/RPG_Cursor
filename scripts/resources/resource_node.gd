class_name ResourceNode
extends InteractableBase

@export var resource_id: String = "wood"
@export var yield_amount: int = 3
@export var requires_tool: bool = false

var _depleted: bool = false


func _ready() -> void:
	super._ready()
	prompt_text = "Gather"


func _on_interact(_player: Node) -> void:
	if _depleted:
		return
	InventoryManager.add_item(resource_id, yield_amount)
	_depleted = true
	visible = false
