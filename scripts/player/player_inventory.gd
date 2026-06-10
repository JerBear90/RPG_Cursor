extends Node
## Per-player inventory hooks (delegates to InventoryManager for co-op shared stash).

var _player: PlayerController


func _ready() -> void:
	_player = get_parent() as PlayerController
	InventoryManager.inventory_changed.connect(_on_inventory_changed)


func _on_inventory_changed() -> void:
	pass
