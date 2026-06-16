class_name BlockComponent
extends Node
## Blocking damage reduction and stamina drain.

signal block_started
signal block_ended
signal block_hit(damage: DamageData, absorbed: float)

@export var block_efficiency: float = 0.7
@export var stamina_cost_per_hit: float = 15.0

var is_blocking: bool = false
var _stamina: StaminaComponent


func setup(stamina: StaminaComponent) -> void:
	_stamina = stamina


func start_block() -> void:
	is_blocking = true
	block_started.emit()


func stop_block() -> void:
	is_blocking = false
	block_ended.emit()


func process_block(damage: DamageData) -> float:
	if not is_blocking:
		return damage.amount
	if _stamina:
		var cost := stamina_cost_per_hit
		if get_parent().has_node("SkillTree"):
			cost *= (get_parent().get_node("SkillTree") as Node).get_block_stamina_multiplier()
		if not _stamina.can_spend(cost):
			stop_block()
			return damage.amount
		_stamina.spend(cost)
	var absorbed := damage.amount * block_efficiency
	var remaining := damage.amount - absorbed
	block_hit.emit(damage, absorbed)
	return remaining
