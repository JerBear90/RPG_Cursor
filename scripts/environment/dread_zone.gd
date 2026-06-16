class_name DreadZone
extends Area3D
## Deep darkness and haunted areas that build Dread exposure.

const _StatusEffects := preload("res://scripts/combat/status_effects_component.gd")


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	add_to_group("dread_zone")
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)


func _on_enter(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	if body.has_node("StatusEffectsComponent"):
		(body.get_node("StatusEffectsComponent") as _StatusEffects).set_in_dread_zone(true)


func _on_exit(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	if body.has_node("StatusEffectsComponent"):
		(body.get_node("StatusEffectsComponent") as _StatusEffects).set_in_dread_zone(false)
