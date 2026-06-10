class_name CampChest
extends InteractableBase

@export var tier: int = 1  # 1=basic deposit, 2=limited withdraw, 3=full


func _ready() -> void:
	super._ready()
	prompt_text = "Camp Chest — Send to Base"


func _on_interact(_player: Node) -> void:
	# Prototype: send first wood stack to base
	if InventoryManager.has_item("wood"):
		InventoryManager.send_to_base("wood", 1)
		AchievementManager.unlock("not_just_a_box")
