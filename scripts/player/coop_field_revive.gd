extends Node
class_name CoopFieldRevive
## Hold-to-revive downed co-op partner in the field.

const _CoopUiCopy := preload("res://scripts/ui/coop_ui_copy.gd")

const HOLD_SEC := 2.0
const RANGE := 2.25
const REVIVE_HP_RATIO := 0.35

var _player: PlayerController
var _hold_time: float = 0.0
var _reviving_target: PlayerController = null
var _was_in_range: bool = false


func _get_hold_seconds() -> float:
	var mult := 1.0
	if _player and _player.has_node("SkillTree"):
		mult = (_player.get_node("SkillTree") as Node).get_revive_hold_multiplier()
	return HOLD_SEC * mult


func _ready() -> void:
	_player = get_parent() as PlayerController
	if _player and _player.has_node("HealthComponent"):
		var health := _player.get_node("HealthComponent") as HealthComponent
		if not health.damaged.is_connected(_on_reviver_damaged):
			health.damaged.connect(_on_reviver_damaged)


func _process(delta: float) -> void:
	if not GameManager.is_local_coop():
		_clear_prompt()
		return
	if not _player.is_alive():
		_cancel_revive("")
		_set_prompt(_CoopUiCopy.downed_waiting(_player.player_index))
		return
	if DialogueManager.is_active() or MerchantManager.is_shop_open or GameManager.is_paused \
			or GameManager.death_input_locked or LevelRestartService.is_handling_death():
		_cancel_revive("Interrupted")
		_clear_prompt()
		return
	if _player.is_input_locked() and not _reviving_target:
		_clear_prompt()
		return
	var partner := _get_downed_partner()
	if partner == null:
		_cancel_revive("")
		_clear_prompt()
		return
	var dist := _player.global_position.distance_to(partner.global_position)
	var in_range := dist <= RANGE
	if not in_range:
		_cancel_revive("Too Far" if _reviving_target != null else "")
		_clear_prompt()
		return
	if not _can_hold_revive():
		if _reviving_target != null:
			_cancel_revive("Interrupted")
		_set_prompt(_CoopUiCopy.revive_hold_prompt(_player.player_index, partner.player_index))
		return
	_was_in_range = true
	if InputManager.is_action_pressed("interact", _player.player_index):
		if _reviving_target != partner:
			_start_revive(partner)
		_hold_time += delta
		var progress := clampf(_hold_time / _get_hold_seconds(), 0.0, 1.0)
		GameManager.set_field_revive(_player.player_index, partner.player_index, progress, true)
		_set_prompt(_CoopUiCopy.revive_progress(_player.player_index, partner.player_index, progress * 100.0))
		if _hold_time >= _get_hold_seconds():
			_complete_revive(partner)
	else:
		if _reviving_target == partner:
			_cancel_revive("")
		_set_prompt(_CoopUiCopy.revive_hold_prompt(_player.player_index, partner.player_index))


func _start_revive(target: PlayerController) -> void:
	_reviving_target = target
	_hold_time = 0.0
	_was_in_range = true
	TutorialPromptManager.try_show("coop_revive")
	GameManager.set_field_revive(_player.player_index, target.player_index, 0.0, true)


func _cancel_revive(reason: String) -> void:
	var was_active := _reviving_target != null or _hold_time > 0.0
	if was_active:
		GameManager.set_field_revive(-1, -1, 0.0, false)
		if reason != "":
			_show_revive_feedback(_CoopUiCopy.revive_canceled(reason), true)
	_reviving_target = null
	_hold_time = 0.0
	_was_in_range = false


func _complete_revive(target: PlayerController) -> void:
	GameManager.revive_player(target, REVIVE_HP_RATIO)
	var target_idx := target.player_index
	_cancel_revive("")
	_clear_prompt()
	_show_revive_feedback(_CoopUiCopy.revive_complete(target_idx), true)
	if target.player_index == 1:
		var hud := _find_hud()
		if hud and hud.has_method("show_p2_feedback"):
			hud.show_p2_feedback("P2 Revived | +35% HP", 2.5)


func _show_revive_feedback(text: String, critical: bool) -> void:
	var hud := _find_hud()
	if hud and hud.has_method("show_toast"):
		var priority := NotificationToast.Priority.CRITICAL if critical else NotificationToast.Priority.IMPORTANT
		hud.show_toast(text, 2.5, "", "notification", "", priority)


func _can_hold_revive() -> bool:
	if InputManager.gameplay_input_blocked():
		return false
	if _player.current_state in [PlayerController.State.ATTACK, PlayerController.State.DODGE, PlayerController.State.BLOCK]:
		return false
	var idx := _player.player_index
	if InputManager.is_action_just_pressed("light_attack", idx) \
			or InputManager.is_action_just_pressed("heavy_attack", idx) \
			or InputManager.is_action_just_pressed("dodge", idx) \
			or InputManager.is_action_just_pressed("jump", idx) \
			or InputManager.is_action_just_pressed("quick_spell", idx):
		return false
	if _player.has_node("Combat"):
		var combat := _player.get_node("Combat")
		if combat.has_method("is_attacking") and combat.is_attacking():
			return false
	if _player.has_node("DodgeComponent"):
		var dodge := _player.get_node("DodgeComponent") as DodgeComponent
		if dodge.is_dodging:
			return false
	return true


func _on_reviver_damaged(_damage: DamageData, _remaining: float) -> void:
	if _reviving_target != null:
		_cancel_revive("Took Damage")


func _get_downed_partner() -> PlayerController:
	for p in GameManager.get_all_registered_players():
		if p == _player or not is_instance_valid(p):
			continue
		if p is PlayerController and not p.is_alive():
			return p as PlayerController
	return null


func _set_prompt(text: String) -> void:
	GameManager.set_coop_player_prompt(_player.player_index, text)


func _clear_prompt() -> void:
	GameManager.set_coop_player_prompt(_player.player_index, "")


func _find_hud() -> Node:
	for hud in get_tree().get_nodes_in_group("game_hud"):
		return hud
	return null
