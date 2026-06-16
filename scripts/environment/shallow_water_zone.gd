class_name ShallowWaterZone
extends Area3D
## Walkable shallow water — slows movement, splash on enter.

@export var speed_multiplier: float = 0.85

var _players_inside: Dictionary = {}


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	add_to_group("shallow_water_zone")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	_players_inside[body.get_instance_id()] = true
	if body.has_node("EnvironmentMovementModifier"):
		(body.get_node("EnvironmentMovementModifier") as EnvironmentMovementModifier).set_shallow_water(true, speed_multiplier)
	AudioManager.play_sfx("footstep")


func _on_body_exited(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	_players_inside.erase(body.get_instance_id())
	if body.has_node("EnvironmentMovementModifier"):
		(body.get_node("EnvironmentMovementModifier") as EnvironmentMovementModifier).set_shallow_water(false)
