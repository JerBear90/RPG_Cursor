extends Node
## Interact with world objects, NPCs, stations; drives HUD prompts.

var _player: PlayerController
var _interact_area: Area3D
var _current_interactable: Node = null


func _ready() -> void:
	_player = get_parent() as PlayerController
	_interact_area = _player.get_node("InteractArea")
	_interact_area.area_entered.connect(_on_area_entered)
	_interact_area.area_exited.connect(_on_area_exited)


func _process(_delta: float) -> void:
	_update_prompt()
	if InputManager.is_action_just_pressed("interact", _player.player_index):
		_try_interact()


func _update_prompt() -> void:
	var hud := get_tree().get_first_node_in_group("game_hud")
	if hud == null:
		return
	if DialogueManager.is_active():
		hud.set_interact_prompt("")
		return
	if _current_interactable and is_instance_valid(_current_interactable):
		var key := "E" if _player.player_index == 0 else "A"
		var prompt := "%s: %s" % [key, _get_prompt(_current_interactable)]
		hud.set_interact_prompt(prompt)
	else:
		hud.set_interact_prompt("")


func _get_prompt(target: Node) -> String:
	if "prompt_text" in target:
		return target.prompt_text
	return "Interact"


func _on_area_entered(area: Area3D) -> void:
	var parent := area.get_parent()
	if parent and (parent.is_in_group("interactable") or parent.is_in_group("npc")):
		_current_interactable = parent


func _on_area_exited(area: Area3D) -> void:
	var parent := area.get_parent()
	if parent == _current_interactable:
		_current_interactable = null


func _try_interact() -> void:
	if get_tree().paused or DialogueManager.is_active():
		return
	if _current_interactable and _current_interactable.has_method("interact"):
		_current_interactable.interact(_player)
