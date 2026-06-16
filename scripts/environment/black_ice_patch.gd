class_name BlackIcePatch
extends Area3D
## Temporary black-ice hazard — telegraphed frost damage with cooldown.

const _DamageData := preload("res://scripts/combat/damage_data.gd")

@export var damage: float = 10.0
@export var tick_interval: float = 1.2
@export var lifetime: float = 8.0

var _tick: float = 0.0
var _life: float = 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	_life = lifetime
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 1.6
	shape.height = 0.4
	col.shape = shape
	add_child(col)
	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.5
	cyl.bottom_radius = 1.5
	cyl.height = 0.08
	mesh.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.12, 0.22)
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.45, 0.75)
	mat.emission_energy_multiplier = 0.35
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
			dmg.stagger = 6.0
			(body.get_node("HealthComponent") as HealthComponent).apply_damage(dmg)
		if body.has_node("StatusEffectsComponent"):
			(body.get_node("StatusEffectsComponent") as StatusEffectsComponent).add_cold_buildup(8.0)
