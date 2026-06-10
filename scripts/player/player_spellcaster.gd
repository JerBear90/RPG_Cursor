extends Node
## Quick spell and spell wheel casting.

const SPELL_PROJECTILE := preload("res://scenes/weapons/spell_projectile.tscn")

signal spell_changed(spell_id: String)

var _player: PlayerController
var _focus: FocusComponent
var equipped_spells: Array[String] = ["ember_bolt", "healing_mist", "venom_dart", "shadow_lash"]
var quick_spell_index: int = 0
var _cooldowns: Dictionary = {}
var _spell_wheel_open: bool = false


func _ready() -> void:
	_player = get_parent() as PlayerController
	_focus = _player.get_node("FocusComponent")
	spell_changed.emit(equipped_spells[quick_spell_index])


func _process(delta: float) -> void:
	for spell_id in _cooldowns.keys():
		_cooldowns[spell_id] = maxf(_cooldowns[spell_id] - delta, 0.0)
	var idx := _player.player_index
	if InputManager.is_action_just_pressed("quick_spell", idx):
		cast_spell(equipped_spells[quick_spell_index])
	if InputManager.is_action_just_pressed("cycle_quick_left", idx):
		_select_spell((quick_spell_index - 1) % equipped_spells.size())
	if InputManager.is_action_just_pressed("cycle_quick_right", idx):
		_select_spell((quick_spell_index + 1) % equipped_spells.size())
	_handle_spell_wheel(idx)


func _handle_spell_wheel(player_index: int) -> void:
	var holding := InputManager.is_action_pressed("open_spell_wheel", player_index)
	if holding and not _spell_wheel_open:
		_spell_wheel_open = true
		for hud in get_tree().get_nodes_in_group("game_hud"):
			hud.open_spell_wheel_menu(equipped_spells, quick_spell_index)
	elif not holding and _spell_wheel_open:
		_spell_wheel_open = false
		for hud in get_tree().get_nodes_in_group("game_hud"):
			hud.close_spell_wheel_menu()


func select_spell_from_wheel(index: int) -> void:
	if index >= 0 and index < equipped_spells.size():
		_select_spell(index)


func _select_spell(index: int) -> void:
	quick_spell_index = index
	spell_changed.emit(equipped_spells[quick_spell_index])


func get_active_spell_id() -> String:
	return equipped_spells[quick_spell_index]


func get_active_spell_label() -> String:
	return equipped_spells[quick_spell_index].replace("_", " ").capitalize()


func cast_spell(spell_id: String) -> bool:
	if _cooldowns.get(spell_id, 0.0) > 0.0:
		return false
	var data := _get_spell_data(spell_id)
	if not _focus.spend(data.focus_cost):
		return false
	_spawn_spell(data)
	_cooldowns[spell_id] = data.cooldown
	AchievementManager.unlock("spellbound")
	return true


func _spawn_spell(data: Dictionary) -> void:
	var cast_point := _player.get_node("SpellCastPoint") as Node3D
	if data.school == "water" and data.id == "healing_mist":
		var health := _player.get_node("HealthComponent") as HealthComponent
		health.heal(data.damage)
		return
	var projectile := SPELL_PROJECTILE.instantiate()
	projectile.global_position = cast_point.global_position
	var dir := -_player.global_transform.basis.z
	projectile.setup(data, dir, _player)
	get_tree().current_scene.add_child(projectile)


func _get_spell_data(spell_id: String) -> Dictionary:
	match spell_id:
		"ember_bolt":
			return {"id": "ember_bolt", "school": "fire", "focus_cost": 8.0, "cooldown": 1.0, "damage": 15.0, "speed": 18.0}
		"healing_mist":
			return {"id": "healing_mist", "school": "water", "focus_cost": 12.0, "cooldown": 5.0, "damage": 25.0, "speed": 0.0}
		"venom_dart":
			return {"id": "venom_dart", "school": "poison", "focus_cost": 6.0, "cooldown": 0.8, "damage": 8.0, "speed": 22.0}
		"shadow_lash":
			return {"id": "shadow_lash", "school": "dark", "focus_cost": 10.0, "cooldown": 1.5, "damage": 20.0, "speed": 25.0}
		_:
			return {"id": spell_id, "school": "fire", "focus_cost": 10.0, "cooldown": 1.0, "damage": 10.0, "speed": 15.0}
