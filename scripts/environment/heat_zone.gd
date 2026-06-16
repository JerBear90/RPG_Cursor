class_name HeatZone
extends Area3D
## Environmental heat — buildup via StatusEffectsComponent.

@export var buildup_multiplier: float = 1.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	add_to_group("heat_zone")
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)


func _on_enter(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	if body.has_node("StatusEffectsComponent"):
		(body.get_node("StatusEffectsComponent") as StatusEffectsComponent).set_in_heat_zone(true)


func _on_exit(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	if body.has_node("StatusEffectsComponent"):
		(body.get_node("StatusEffectsComponent") as StatusEffectsComponent).set_in_heat_zone(false)
