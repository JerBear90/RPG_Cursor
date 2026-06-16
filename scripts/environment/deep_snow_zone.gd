class_name DeepSnowZone
extends Area3D
## Deep snow — movement slowdown via EnvironmentMovementModifier.

const _MovementMod := preload("res://scripts/player/environment_movement_modifier.gd")

@export var speed_multiplier: float = 0.72

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	add_to_group("deep_snow_zone")
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)


func _on_enter(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	if body.has_node("EnvironmentMovementModifier"):
		(body.get_node("EnvironmentMovementModifier") as _MovementMod).set_deep_snow(true, speed_multiplier)


func _on_exit(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	if body.has_node("EnvironmentMovementModifier"):
		(body.get_node("EnvironmentMovementModifier") as _MovementMod).set_deep_snow(false)
