class_name ElectrifiedWaterZone
extends Area3D
## Temporary electrified water in the Tidebound Sovereign arena.

const _DamageData := preload("res://scripts/combat/damage_data.gd")
const _StatusEffects := preload("res://scripts/combat/status_effects_component.gd")

@export var damage: float = 9.0
@export var tick_interval: float = 1.0
@export var lifetime: float = 7.0

var _tick: float = 0.0
var _life: float = 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	add_to_group("boss_hazard")
	_life = lifetime
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(3.2, 0.3, 3.2)
	col.shape = shape
	add_child(col)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(3.0, 0.06, 3.0)
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.35, 0.55, 0.75)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.35, 0.65, 1.0)
	mat.emission_energy_multiplier = 0.55
	mesh.material_override = mat
	add_child(mesh)


func _process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		queue_free()
		return
	_tick -= delta
	if _tick > 0.0:
		return
	_tick = tick_interval
	for body in get_overlapping_bodies():
		if not body.is_in_group("player"):
			continue
		if body.has_node("HealthComponent"):
			var dmg := _DamageData.create_physical(damage, self)
			dmg.damage_type = _DamageData.DamageType.FROST
			(body.get_node("HealthComponent") as HealthComponent).apply_damage(dmg)
		if body.has_node("StatusEffectsComponent"):
			(body.get_node("StatusEffectsComponent") as _StatusEffects).add_storm_buildup(14.0)
