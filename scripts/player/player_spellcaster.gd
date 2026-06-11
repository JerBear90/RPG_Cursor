extends Node
## Quick spell and spell wheel casting.

const SPELL_PROJECTILE := preload("res://scenes/weapons/spell_projectile.tscn")
const ALL_SPELLS: Array[String] = ["ember_bolt", "healing_mist", "venom_dart", "shadow_lash"]

signal spell_changed(spell_id: String)
signal cast_failed(reason: String)

var _player: PlayerController
var _focus: FocusComponent
var unlocked_spells: Array[String] = ["ember_bolt"]
var equipped_spells: Array[String] = ["ember_bolt"]
var quick_spell_index: int = 0
var _cooldowns: Dictionary = {}
var _spell_wheel_open: bool = false


func _ready() -> void:
	_player = get_parent() as PlayerController
	_focus = _player.get_node("FocusComponent")
	_refresh_equipped_spells()
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


func unlock_spell(spell_id: String) -> bool:
	if spell_id not in ALL_SPELLS or spell_id in unlocked_spells:
		return false
	unlocked_spells.append(spell_id)
	_refresh_equipped_spells()
	spell_changed.emit(equipped_spells[quick_spell_index])
	return true


func is_spell_unlocked(spell_id: String) -> bool:
	return spell_id in unlocked_spells


func _refresh_equipped_spells() -> void:
	equipped_spells = unlocked_spells.duplicate()
	if equipped_spells.is_empty():
		equipped_spells = ["ember_bolt"]
	if quick_spell_index >= equipped_spells.size():
		quick_spell_index = 0


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


func get_cooldown_remaining(spell_id: String) -> float:
	return float(_cooldowns.get(spell_id, 0.0))


func get_cooldown_ratio(spell_id: String) -> float:
	var remaining := get_cooldown_remaining(spell_id)
	if remaining <= 0.0:
		return 0.0
	var cooldown := float(_get_spell_data(spell_id).get("cooldown", 1.0))
	return remaining / cooldown if cooldown > 0.0 else 0.0


func get_spell_focus_cost(spell_id: String) -> int:
	return int(_get_spell_data(spell_id).get("focus_cost", 0.0))


func cast_spell(spell_id: String) -> bool:
	if spell_id not in unlocked_spells:
		return false
	if _cooldowns.get(spell_id, 0.0) > 0.0:
		return false
	var data := _get_spell_data(spell_id)
	if not _focus.spend(data.focus_cost):
		cast_failed.emit("focus")
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
	var data: Dictionary
	match spell_id:
		"ember_bolt":
			data = {"id": "ember_bolt", "school": "fire", "focus_cost": 8.0, "cooldown": 1.0, "damage": 15.0, "speed": 18.0}
		"healing_mist":
			data = {"id": "healing_mist", "school": "water", "focus_cost": 12.0, "cooldown": 5.0, "damage": 25.0, "speed": 0.0}
		"venom_dart":
			data = {"id": "venom_dart", "school": "poison", "focus_cost": 6.0, "cooldown": 0.8, "damage": 8.0, "speed": 22.0}
		"shadow_lash":
			data = {"id": "shadow_lash", "school": "dark", "focus_cost": 10.0, "cooldown": 1.5, "damage": 20.0, "speed": 25.0}
		_:
			data = {"id": spell_id, "school": "fire", "focus_cost": 10.0, "cooldown": 1.0, "damage": 10.0, "speed": 15.0}
	if _player.has_node("StatsComponent"):
		data.damage = float(data.damage) + (_player.get_node("StatsComponent") as StatsComponent).get_spell_power_bonus()
	if _player.has_node("SkillTree"):
		data.damage = float(data.damage) * (_player.get_node("SkillTree") as Node).get_spell_damage_multiplier(spell_id)
	return data


func serialize() -> Dictionary:
	return {"unlocked": unlocked_spells.duplicate(), "quick_index": quick_spell_index}


func deserialize(data: Dictionary) -> void:
	var saved: Array = data.get("unlocked", ["ember_bolt"])
	unlocked_spells.clear()
	for entry in saved:
		var spell_id := str(entry)
		if spell_id in ALL_SPELLS:
			unlocked_spells.append(spell_id)
	if unlocked_spells.is_empty():
		unlocked_spells = ["ember_bolt"]
	quick_spell_index = int(data.get("quick_index", 0))
	_refresh_equipped_spells()
