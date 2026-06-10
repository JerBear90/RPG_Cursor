class_name DungeonExitPortal
extends InteractableBase

var _active: bool = false


func _ready() -> void:
	super._ready()
	prompt_text = "Leave Dungeon"
	visible = false
	set_process(false)
	for child in get_children():
		if child is CollisionShape3D:
			child.disabled = true
		if child is Area3D:
			child.monitoring = false


func reveal() -> void:
	_active = true
	visible = true
	for child in get_children():
		if child is CollisionShape3D:
			child.disabled = false
		if child is Area3D:
			child.monitoring = true


func _on_interact(_player: Node) -> void:
	if not _active or not DungeonManager.boss_defeated:
		return
	DungeonManager.exit_dungeon()
