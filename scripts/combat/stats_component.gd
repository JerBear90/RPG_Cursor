class_name StatsComponent
extends Node
## Primary stats and derived combat values.

signal level_changed(level: int)
signal stat_changed

const MAX_LEVEL := 50

@export var level: int = 1
@export var experience: int = 0
@export var strength: int = 5
@export var dexterity: int = 5
@export var intelligence: int = 5
@export var vitality: int = 5
@export var endurance: int = 5
@export var spirit: int = 5

var unspent_stat_points: int = 0
var unspent_skill_points: int = 0


func get_exp_to_next_level() -> int:
	return level * 100


func add_experience(amount: int) -> void:
	experience += amount
	while experience >= get_exp_to_next_level() and level < MAX_LEVEL:
		experience -= get_exp_to_next_level()
		_level_up()


func _level_up() -> void:
	level += 1
	unspent_stat_points += 1
	unspent_skill_points += 1
	level_changed.emit(level)
	stat_changed.emit()


func get_max_health_bonus() -> float:
	return vitality * 8.0


func get_max_stamina_bonus() -> float:
	return endurance * 5.0


func get_max_focus_bonus() -> float:
	return spirit * 3.0


func get_physical_damage_bonus() -> float:
	return strength * 0.5


func get_crit_chance() -> float:
	return dexterity * 0.005


func get_spell_power_bonus() -> float:
	return intelligence * 0.6
