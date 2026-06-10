class_name StaminaComponent
extends Node
## Stamina consumption and recovery.

signal stamina_changed(current: float, maximum: float)
signal exhausted

@export var max_stamina: float = 100.0
@export var regen_rate: float = 20.0
@export var regen_delay: float = 1.0

var current_stamina: float = 100.0
var _regen_timer: float = 0.0


func _ready() -> void:
	current_stamina = max_stamina


func _process(delta: float) -> void:
	if _regen_timer > 0.0:
		_regen_timer -= delta
		return
	if current_stamina < max_stamina:
		var mult := _get_survival_multiplier()
		restore(regen_rate * delta * mult)


func _get_survival_multiplier() -> float:
	var parent := get_parent()
	if parent and parent.has_node("SurvivalNeedsComponent"):
		return (parent.get_node("SurvivalNeedsComponent") as SurvivalNeedsComponent).get_stamina_regen_multiplier()
	return 1.0


func can_spend(amount: float) -> bool:
	return current_stamina >= amount


func spend(amount: float) -> bool:
	if not can_spend(amount):
		exhausted.emit()
		return false
	current_stamina -= amount
	_regen_timer = regen_delay
	stamina_changed.emit(current_stamina, max_stamina)
	return true


func restore(amount: float) -> void:
	current_stamina = minf(current_stamina + amount, max_stamina)
	stamina_changed.emit(current_stamina, max_stamina)
