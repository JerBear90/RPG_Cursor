extends Node
## Interact with world objects, NPCs, stations; drives HUD prompts.

const _CoopUiCopy := preload("res://scripts/ui/coop_ui_copy.gd")

var _player: PlayerController
var _interact_area: Area3D
var _current_interactable: Node = null
var _interact_cooldown_until_msec: int = 0


func _ready() -> void:
	_player = get_parent() as PlayerController
	_interact_area = _player.get_node("InteractArea")
	_interact_area.area_entered.connect(_on_area_entered)
	_interact_area.area_exited.connect(_on_area_exited)
	if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	if not MerchantManager.shop_closed.is_connected(_on_shop_closed):
		MerchantManager.shop_closed.connect(_on_shop_closed)


func _process(_delta: float) -> void:
	_update_prompt()
	if Time.get_ticks_msec() < _interact_cooldown_until_msec:
		return
	if InputManager.gameplay_input_blocked():
		return
	if _is_menu_blocking_interact():
		return
	if InputManager.is_action_just_pressed("interact", _player.player_index):
		_try_interact()


func _update_prompt() -> void:
	var hud := get_tree().get_first_node_in_group("game_hud")
	if hud == null:
		return
	var coop_prompt := GameManager.get_coop_player_prompt(_player.player_index)
	if coop_prompt != "":
		if _player.player_index == 0:
			hud.set_interact_prompt(coop_prompt)
		return
	if _is_menu_blocking_interact():
		if _player.player_index == 0:
			hud.set_interact_prompt("")
		return
	if DialogueManager.is_active() or MerchantManager.is_shop_open:
		if _player.player_index == GameManager.interacting_player_index:
			hud.set_interact_prompt("")
		return
	if _current_interactable and is_instance_valid(_current_interactable):
		if GameManager.is_local_coop() and not _owns_interact_prompt():
			return
		var prompt := _CoopUiCopy.press_prompt(
			_player.player_index,
			_get_prompt(_current_interactable),
			"interact"
		)
		hud.set_interact_prompt(prompt)
	elif _player.player_index == 0:
		hud.set_interact_prompt("")


func _is_menu_blocking_interact() -> bool:
	var hud := get_tree().get_first_node_in_group("game_hud")
	if hud and hud.has_method("is_fullscreen_menu_open"):
		return hud.is_fullscreen_menu_open()
	return GameManager.is_paused and not DialogueManager.is_active()


func _owns_interact_prompt() -> bool:
	if _current_interactable == null:
		return false
	var best: Node = null
	var best_dist := INF
	for p in GameManager.get_alive_players():
		if p is Node3D:
			var d: float = (p as Node3D).global_position.distance_to(_current_interactable.global_position)
			if d < best_dist:
				best_dist = d
				best = p
	return best == _player


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


func _on_dialogue_ended() -> void:
	_interact_cooldown_until_msec = Time.get_ticks_msec() + 300


func _on_shop_closed() -> void:
	_interact_cooldown_until_msec = Time.get_ticks_msec() + 300


func _try_interact() -> void:
	if get_tree().paused or InputManager.gameplay_input_blocked():
		return
	if _is_menu_blocking_interact():
		return
	if _current_interactable and _current_interactable.has_method("interact"):
		GameManager.interacting_player_index = _player.player_index
		TutorialPromptManager.try_show("interact")
		_current_interactable.interact(_player)
