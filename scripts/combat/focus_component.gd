class_name FocusComponent
extends Node
## Magic Focus resource for spellcasting.

signal focus_changed(current: float, maximum: float)

@export var max_focus: float = 50.0
@export var regen_rate: float = 5.0

var current_focus: float = 50.0


func _ready() -> void:
	current_focus = max_focus


func _process(delta: float) -> void:
	if current_focus < max_focus:
		restore(regen_rate * delta)


func can_spend(amount: float) -> bool:
	return current_focus >= amount


func spend(amount: float) -> bool:
	if not can_spend(amount):
		return false
	current_focus -= amount
	focus_changed.emit(current_focus, max_focus)
	return true


func restore(amount: float) -> void:
	current_focus = minf(current_focus + amount, max_focus)
	focus_changed.emit(current_focus, max_focus)
