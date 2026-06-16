class_name EclipseStormController
extends Node
## Staged eclipse weather for the Sunless Dominion.

enum StormPhase { TWILIGHT, SHADOW_FOG, ECLIPSE_SURGE, UMBRAL_STORM, CLEARING }

signal phase_changed(phase: StormPhase)

@export var cycle_duration: float = 120.0

var _phase: StormPhase = StormPhase.TWILIGHT
var _timer: float = 0.0
var _surge_active: bool = false


func _ready() -> void:
	add_to_group("eclipse_storm")
	_timer = cycle_duration * 0.25


func is_surge_active() -> bool:
	return _surge_active


func _process(delta: float) -> void:
	if GameManager.current_region_id != "sunless_dominion":
		return
	_timer -= delta
	if _timer > 0.0:
		return
	match _phase:
		StormPhase.TWILIGHT:
			_set_phase(StormPhase.SHADOW_FOG, cycle_duration * 0.2)
		StormPhase.SHADOW_FOG:
			_set_phase(StormPhase.ECLIPSE_SURGE, cycle_duration * 0.15)
		StormPhase.ECLIPSE_SURGE:
			_set_phase(StormPhase.UMBRAL_STORM, cycle_duration * 0.12)
		StormPhase.UMBRAL_STORM:
			_set_phase(StormPhase.CLEARING, cycle_duration * 0.1)
		StormPhase.CLEARING:
			_set_phase(StormPhase.TWILIGHT, cycle_duration * 0.43)


func _set_phase(next: StormPhase, duration: float) -> void:
	_phase = next
	_timer = duration
	_surge_active = next in [StormPhase.ECLIPSE_SURGE, StormPhase.UMBRAL_STORM]
	for node in get_tree().get_nodes_in_group("player"):
		if node.has_node("StatusEffectsComponent"):
			(node.get_node("StatusEffectsComponent") as StatusEffectsComponent).set_eclipse_surge(_surge_active)
	phase_changed.emit(_phase)
