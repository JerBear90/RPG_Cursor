extends Node
## Quick spell and spell wheel casting.

const ALL_SPELLS: Array[String] = ["ember_bolt", "healing_mist", "venom_dart", "shadow_lash"]

signal spell_changed(spell_id: String)
signal spell_cast(spell_id: String, display_name: String)
signal cast_failed(reason: String)

var _player: PlayerController
var _focus: FocusComponent
var _tree: SpellTreeController = SpellTreeController.new()
var _cooldowns: SpellCooldownManager = SpellCooldownManager.new()
var _spell_wheel_open: bool = false


func _ready() -> void:
	_player = get_parent() as PlayerController
	_focus = _player.get_node("FocusComponent")
	_tree.refresh_equipped()
	if not _tree.get_active_spell_id().is_empty():
		spell_changed.emit(_tree.get_active_spell_id())


func _process(delta: float) -> void:
	_cooldowns.tick(delta)
	if _player == null or not _player.is_alive() or InputManager.gameplay_input_blocked() or get_tree().paused:
		return
	var idx := _player.player_index
	if InputManager.is_action_just_pressed("quick_spell", idx):
		cast_spell(_tree.get_active_spell_id())
	if InputManager.is_action_just_pressed("cycle_quick_left", idx):
		_cycle_spell(-1)
	if InputManager.is_action_just_pressed("cycle_quick_right", idx):
		_cycle_spell(1)
	_handle_spell_wheel(idx)


func unlock_spell(spell_id: String) -> bool:
	if _tree.unlock(spell_id, ALL_SPELLS):
		spell_changed.emit(_tree.get_active_spell_id())
		return true
	return false


func is_spell_unlocked(spell_id: String) -> bool:
	return spell_id in _tree.unlocked_spells


func _cycle_spell(direction: int) -> void:
	_tree.cycle(direction)
	spell_changed.emit(_tree.get_active_spell_id())


func _handle_spell_wheel(player_index: int) -> void:
	var holding := InputManager.is_action_pressed("open_spell_wheel", player_index)
	if holding and not _spell_wheel_open:
		_spell_wheel_open = true
		for hud in get_tree().get_nodes_in_group("game_hud"):
			hud.open_spell_wheel_menu(_tree.equipped_spells, _tree.quick_spell_index)
	elif not holding and _spell_wheel_open:
		_spell_wheel_open = false
		for hud in get_tree().get_nodes_in_group("game_hud"):
			hud.close_spell_wheel_menu()


func select_spell_from_wheel(index: int) -> void:
	_tree.select_index(index)
	spell_changed.emit(_tree.get_active_spell_id())


func get_active_spell_id() -> String:
	return _tree.get_active_spell_id()


func get_active_spell_label() -> String:
	var spell_id := get_active_spell_id()
	if spell_id == "":
		return "None"
	return SpellRegistry.get_display_name(spell_id)


func get_cooldown_remaining(spell_id: String) -> float:
	return _cooldowns.get_remaining(spell_id)


func get_cooldown_ratio(spell_id: String) -> float:
	var base_cd := float(SpellRegistry.get_spell(spell_id).get("cooldown", 1.0))
	if _player.has_node("SkillTree"):
		base_cd *= (_player.get_node("SkillTree") as Node).get_spell_cooldown_multiplier(spell_id)
	return _cooldowns.get_ratio(spell_id, base_cd)


func get_spell_focus_cost(spell_id: String) -> int:
	if _player == null:
		return int(SpellRegistry.get_spell(spell_id).get("focus_cost", 0.0))
	var skill_tree := _player.get_node("SkillTree") if _player.has_node("SkillTree") else null
	return int(round(SpellCaster.get_focus_cost(_player, spell_id, skill_tree, _focus.focus_cost_multiplier)))


func cast_spell(spell_id: String) -> bool:
	if spell_id == "":
		cast_failed.emit("none")
		return false
	if spell_id not in _tree.unlocked_spells:
		cast_failed.emit("locked")
		return false
	var base_data := SpellRegistry.get_spell(spell_id)
	var cooldown := float(base_data.get("cooldown", 1.0))
	if _player.has_node("SkillTree"):
		cooldown *= (_player.get_node("SkillTree") as Node).get_spell_cooldown_multiplier(spell_id)
	if not _cooldowns.is_ready(spell_id):
		cast_failed.emit("cooldown")
		return false
	var skill_tree := _player.get_node("SkillTree") if _player.has_node("SkillTree") else null
	var data := SpellCaster.resolve_spell(_player, spell_id, skill_tree)
	var focus_cost := float(data.get("focus_cost", 0.0))
	if not _focus.can_spend(focus_cost):
		cast_failed.emit("focus")
		return false
	if not _focus.spend(focus_cost):
		cast_failed.emit("focus")
		return false
	SpellCaster.execute(_player, data)
	_cooldowns.start(spell_id, cooldown)
	TutorialPromptManager.try_show("spellcasting")
	var display_name := str(data.get("display_name", SpellRegistry.get_display_name(spell_id)))
	spell_cast.emit(spell_id, display_name)
	AchievementManager.unlock("spellbound")
	return true


func serialize() -> Dictionary:
	return _tree.serialize()


func deserialize(data: Dictionary) -> void:
	_tree.deserialize(data, ALL_SPELLS)
	spell_changed.emit(_tree.get_active_spell_id())
