class_name ShadowPoolZone
extends Area3D
## Shadow pools that build Shadow Exposure.

const _StatusEffects := preload("res://scripts/combat/status_effects_component.gd")
const _DamageData := preload("res://scripts/combat/damage_data.gd")

@export var tick_damage: float = 3.0
var _cooldowns: Dictionary = {}


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	add_to_group("shadow_pool")
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)


func _process(delta: float) -> void:
	for key in _cooldowns.keys():
		_cooldowns[key] = maxf(_cooldowns[key] - delta, 0.0)


func _on_enter(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	if body.has_node("StatusEffectsComponent"):
		var status := body.get_node("StatusEffectsComponent") as _StatusEffects
		status.set_in_shadow_pool(true)
		status.add_shadow_buildup(6.0)
	var id := body.get_instance_id()
	if _cooldowns.get(id, 0.0) <= 0.0 and body.has_node("HealthComponent"):
		_cooldowns[id] = 0.9
		body.get_node("HealthComponent").apply_damage(_DamageData.create_physical(tick_damage, null))


func _on_exit(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	if body.has_node("StatusEffectsComponent"):
		(body.get_node("StatusEffectsComponent") as _StatusEffects).set_in_shadow_pool(false)
