class_name StormChargedZone
extends Area3D
## Lightning and storm exposure zones.

const _StatusEffects := preload("res://scripts/combat/status_effects_component.gd")

@export var buildup_rate: float = 22.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	add_to_group("storm_charged_zone")
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)


func _on_enter(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	if body.has_node("StatusEffectsComponent"):
		(body.get_node("StatusEffectsComponent") as _StatusEffects).set_in_storm_zone(true)


func _on_exit(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	if body.has_node("StatusEffectsComponent"):
		(body.get_node("StatusEffectsComponent") as _StatusEffects).set_in_storm_zone(false)
