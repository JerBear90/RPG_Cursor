class_name HealthComponent
extends Node
## Health, damage reception, and death signals.

signal health_changed(current: float, maximum: float)
signal damaged(damage: DamageData, remaining: float)
signal died
signal healed(amount: float)

@export var max_health: float = 100.0
@export var regen_rate: float = 0.0
@export var regen_delay: float = 5.0

var current_health: float = 100.0
var _regen_timer: float = 0.0
var _dead: bool = false


func _ready() -> void:
	current_health = max_health


func _process(delta: float) -> void:
	if _dead or regen_rate <= 0.0:
		return
	_regen_timer -= delta
	if _regen_timer <= 0.0 and current_health < max_health:
		heal(regen_rate * delta)


func take_damage(damage: DamageData) -> float:
	if _dead:
		return 0.0
	var final_amount := damage.amount
	current_health = maxf(current_health - final_amount, 0.0)
	_regen_timer = regen_delay
	damaged.emit(damage, current_health)
	health_changed.emit(current_health, max_health)
	if current_health <= 0.0:
		_die()
	return final_amount


func heal(amount: float) -> void:
	if _dead:
		return
	var before := current_health
	current_health = minf(current_health + amount, max_health)
	var actual := current_health - before
	if actual > 0.0:
		healed.emit(actual)
		health_changed.emit(current_health, max_health)


func is_alive() -> bool:
	return not _dead


func is_near_death(threshold_percent: float = 0.15) -> bool:
	return current_health <= max_health * threshold_percent


func get_health_percent() -> float:
	return current_health / max_health if max_health > 0 else 0.0


func _die() -> void:
	_dead = true
	died.emit()


func reset_health() -> void:
	_dead = false
	current_health = max_health
	health_changed.emit(current_health, max_health)
