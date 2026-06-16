class_name ToxicPoolZone
extends Area3D
## Toxic blight pools — damage and exposure on cooldown.

const _StatusEffects := preload("res://scripts/combat/status_effects_component.gd")
const _DamageData := preload("res://scripts/combat/damage_data.gd")

@export var damage: float = 6.0
@export var cooldown: float = 2.5

var _cooldowns: Dictionary = {}


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	add_to_group("toxic_pool")
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)


func _on_enter(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	_apply(body)


func _on_exit(body: Node3D) -> void:
	_cooldowns.erase(body.get_instance_id())


func _apply(body: Node3D) -> void:
	var id := body.get_instance_id()
	if _cooldowns.has(id) and _cooldowns[id] > 0.0:
		return
	_cooldowns[id] = cooldown
	if body.has_node("HealthComponent"):
		var health := body.get_node("HealthComponent")
		if health.has_method("take_damage"):
			health.take_damage(damage, _DamageData.DamageType.POISON)
	if body.has_node("StatusEffectsComponent"):
		var status := body.get_node("StatusEffectsComponent") as _StatusEffects
		status.add_blight_buildup(12.0)
		status.set_in_blight_zone(true)


func _process(delta: float) -> void:
	for id in _cooldowns.keys():
		_cooldowns[id] = maxf(float(_cooldowns[id]) - delta, 0.0)
