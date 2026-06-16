class_name SolarBossHazard
extends Area3D
## Temporary solar hazard in the Solar Tyrant arena.

const _DamageData := preload("res://scripts/combat/damage_data.gd")
const _StatusEffects := preload("res://scripts/combat/status_effects_component.gd")

@export var lifetime: float = 5.0
@export var tick_damage: float = 5.0
@export var heat_buildup: float = 8.0
@export var hazard_radius: float = 2.0
@export var hazard_color: Color = Color(0.95, 0.45, 0.12, 0.55)

var _timer: float = 0.0
var _cooldowns: Dictionary = {}


func _ready() -> void:
	add_to_group("boss_hazard")
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	body_entered.connect(_on_enter)
	var col := CollisionShape3D.new()
	var sp := SphereShape3D.new()
	sp.radius = hazard_radius
	col.shape = sp
	add_child(col)
	var mesh := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = hazard_radius - 0.1
	sm.height = 0.25
	mesh.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = hazard_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = hazard_color.lightened(0.3)
	mat.emission_energy_multiplier = 0.5
	mesh.material_override = mat
	mesh.position.y = 0.05
	add_child(mesh)


func _process(delta: float) -> void:
	_timer += delta
	if _timer >= lifetime:
		queue_free()
	for key in _cooldowns.keys():
		_cooldowns[key] = maxf(_cooldowns[key] - delta, 0.0)


func _on_enter(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	var id := body.get_instance_id()
	if _cooldowns.get(id, 0.0) > 0.0:
		return
	_cooldowns[id] = 0.75
	if body.has_node("HealthComponent"):
		body.get_node("HealthComponent").apply_damage(_DamageData.create_physical(tick_damage, null))
	if body.has_node("StatusEffectsComponent"):
		(body.get_node("StatusEffectsComponent") as _StatusEffects).add_heat_buildup(heat_buildup)
