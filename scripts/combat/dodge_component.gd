class_name DodgeComponent
extends Node
## Dodge roll with i-frames.

signal dodge_started
signal dodge_ended

@export var dodge_stamina_cost: float = 20.0
@export var dodge_duration: float = 0.5
@export var iframe_start: float = 0.05
@export var iframe_end: float = 0.35
@export var dodge_speed: float = 8.0

var is_dodging: bool = false
var iframes_active: bool = false
var _timer: float = 0.0
var _stamina: StaminaComponent


func setup(stamina: StaminaComponent) -> void:
	_stamina = stamina


func can_dodge() -> bool:
	return not is_dodging and _stamina and _stamina.can_spend(dodge_stamina_cost)


func start_dodge() -> bool:
	if not can_dodge():
		return false
	_stamina.spend(dodge_stamina_cost)
	is_dodging = true
	_timer = 0.0
	iframes_active = false
	dodge_started.emit()
	return true


func _process(delta: float) -> void:
	if not is_dodging:
		return
	_timer += delta
	if _timer >= iframe_start and _timer <= iframe_end:
		iframes_active = true
	else:
		iframes_active = false
	if _timer >= dodge_duration:
		is_dodging = false
		iframes_active = false
		dodge_ended.emit()
