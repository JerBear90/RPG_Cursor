class_name LightningStrikeZone
extends Area3D
## Telegraph lightning strike hazard.

const _StatusEffects := preload("res://scripts/combat/status_effects_component.gd")

@export var damage: float = 18.0
@export var interval: float = 8.0
@export var telegraph_time: float = 1.5

var _timer: float = 4.0
var _warned: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	add_to_group("lightning_strike_zone")
	_timer = randf_range(2.0, interval)


func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= telegraph_time and not _warned:
		_warned = true
		AudioManager.play_sfx("lightning_warn", 0.85)
	if _timer <= 0.0:
		_strike()
		_timer = interval + randf_range(-2.0, 2.0)
		_warned = false


func _strike() -> void:
	AudioManager.play_sfx("lightning_strike", 1.0)
	for body in get_overlapping_bodies():
		if not body.is_in_group("player"):
			continue
		if body.has_node("HealthComponent"):
			var dmg := DamageData.create_physical(damage, body)
			dmg.damage_type = DamageData.DamageType.FROST
			(body.get_node("HealthComponent") as HealthComponent).apply_damage(dmg)
		if body.has_node("StatusEffectsComponent"):
			(body.get_node("StatusEffectsComponent") as _StatusEffects).add_storm_buildup(35.0)
