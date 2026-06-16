class_name FocusComponent
extends Node
## Magic Focus resource for spellcasting.

signal focus_changed(current: float, maximum: float)

@export var max_focus: float = 50.0
@export var regen_rate: float = 5.0
@export var focus_regen_delay: float = 2.0
@export var focus_cost_multiplier: float = 1.0

var current_focus: float = 50.0
var _regen_delay_remaining: float = 0.0
var _restore_from_save: bool = false


func _ready() -> void:
	if not _restore_from_save:
		current_focus = max_focus
	focus_changed.emit(current_focus, max_focus)


func _process(delta: float) -> void:
	if current_focus >= max_focus:
		return
	if _regen_delay_remaining > 0.0:
		_regen_delay_remaining = maxf(_regen_delay_remaining - delta, 0.0)
		return
	restore(regen_rate * delta)


func can_spend(amount: float) -> bool:
	return current_focus >= amount * focus_cost_multiplier


func spend(amount: float) -> bool:
	var cost := amount * focus_cost_multiplier
	if not can_spend(amount):
		return false
	current_focus -= cost
	_regen_delay_remaining = focus_regen_delay
	focus_changed.emit(current_focus, max_focus)
	return true


func restore(amount: float) -> void:
	current_focus = minf(current_focus + amount, max_focus)
	focus_changed.emit(current_focus, max_focus)


func serialize() -> Dictionary:
	return {
		"current_focus": current_focus,
		"max_focus": max_focus,
		"regen_rate": regen_rate,
		"focus_regen_delay": focus_regen_delay,
		"focus_cost_multiplier": focus_cost_multiplier,
	}


func deserialize(data: Dictionary) -> void:
	_restore_from_save = true
	max_focus = float(data.get("max_focus", max_focus))
	regen_rate = float(data.get("regen_rate", regen_rate))
	focus_regen_delay = float(data.get("focus_regen_delay", focus_regen_delay))
	focus_cost_multiplier = float(data.get("focus_cost_multiplier", focus_cost_multiplier))
	current_focus = clampf(float(data.get("current_focus", current_focus)), 0.0, max_focus)
	focus_changed.emit(current_focus, max_focus)


func apply_saved_current(saved_current: float) -> void:
	current_focus = clampf(saved_current, 0.0, max_focus)
	focus_changed.emit(current_focus, max_focus)
