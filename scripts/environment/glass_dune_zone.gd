class_name GlassDuneZone
extends Area3D
## Glass dunes — traction reduction and reflected heat.

const _StatusEffects := preload("res://scripts/combat/status_effects_component.gd")

@export var heat_multiplier: float = 1.35


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	add_to_group("glass_dune")
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)


func _on_enter(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	if body is CharacterBody3D:
		(body as CharacterBody3D).floor_snap_length = 0.05
	if body.has_node("StatusEffectsComponent"):
		var status := body.get_node("StatusEffectsComponent") as _StatusEffects
		status.set_glass_dune(true)
		status.add_heat_buildup(4.0 * heat_multiplier)


func _on_exit(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	if body is CharacterBody3D:
		(body as CharacterBody3D).floor_snap_length = 0.1
	if body.has_node("StatusEffectsComponent"):
		(body.get_node("StatusEffectsComponent") as _StatusEffects).set_glass_dune(false)
