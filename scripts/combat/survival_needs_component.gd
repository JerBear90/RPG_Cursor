class_name SurvivalNeedsComponent
extends Node
## Hunger and thirst survival meters.

signal hunger_changed(value: float)
signal thirst_changed(value: float)
signal starving
signal dehydrated

@export var max_hunger: float = 100.0
@export var max_thirst: float = 100.0
@export var hunger_decay_rate: float = 0.5
@export var thirst_decay_rate: float = 0.8

var hunger: float = 100.0
var thirst: float = 100.0
var _starvation_timer: float = 0.0
var _dehydration_timer: float = 0.0


func _process(delta: float) -> void:
	hunger = maxf(hunger - hunger_decay_rate * delta, 0.0)
	thirst = maxf(thirst - thirst_decay_rate * delta, 0.0)
	hunger_changed.emit(hunger)
	thirst_changed.emit(thirst)
	if hunger <= 0.0:
		_starvation_timer += delta
		if _starvation_timer >= 2.0:
			_starvation_timer = 0.0
			starving.emit()
	if thirst <= 0.0:
		_dehydration_timer += delta
		if _dehydration_timer >= 1.5:
			_dehydration_timer = 0.0
			dehydrated.emit()


func eat(amount: float) -> void:
	hunger = minf(hunger + amount, max_hunger)
	hunger_changed.emit(hunger)


func drink(amount: float) -> void:
	thirst = minf(thirst + amount, max_thirst)
	thirst_changed.emit(thirst)


func get_stamina_regen_multiplier() -> float:
	if thirst < 20.0:
		return 0.5
	if hunger < 20.0:
		return 0.7
	return 1.0


func get_health_regen_multiplier() -> float:
	if hunger < 10.0:
		return 0.0
	if hunger < 30.0:
		return 0.5
	return 1.0


func rest_at_camp() -> void:
	hunger = minf(hunger + 40.0, max_hunger)
	thirst = minf(thirst + 40.0, max_thirst)
	hunger_changed.emit(hunger)
	thirst_changed.emit(thirst)
