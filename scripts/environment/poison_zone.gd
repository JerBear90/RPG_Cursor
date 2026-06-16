class_name PoisonZone
extends Area3D
## Poisonous bog — buildup via StatusEffectsComponent.

@export var buildup_multiplier: float = 1.0

var _inside: Dictionary = {}


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	add_to_group("poison_zone")
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)


func _on_enter(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	_inside[body.get_instance_id()] = true
	if body.has_node("StatusEffectsComponent"):
		(body.get_node("StatusEffectsComponent") as StatusEffectsComponent).set_in_poison_zone(true)


func _on_exit(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	_inside.erase(body.get_instance_id())
	if body.has_node("StatusEffectsComponent"):
		(body.get_node("StatusEffectsComponent") as StatusEffectsComponent).set_in_poison_zone(false)
