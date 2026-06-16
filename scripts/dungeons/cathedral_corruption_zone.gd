class_name CathedralCorruptionZone
extends Area3D
## Temporary corruption bloom hazard in the Blightheart arena.

const _DamageData := preload("res://scripts/combat/damage_data.gd")
const _StatusEffects := preload("res://scripts/combat/status_effects_component.gd")

@export var lifetime: float = 5.0
@export var tick_damage: float = 4.0

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
	sp.radius = 2.2
	col.shape = sp
	add_child(col)
	var mesh := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 2.0
	sm.height = 0.3
	mesh.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.12, 0.45, 0.55)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.55, 0.2, 0.72)
	mat.emission_energy_multiplier = 0.4
	mesh.material_override = mat
	mesh.position.y = 0.05
	add_child(mesh)


func _process(delta: float) -> void:
	_timer += delta
	if _timer >= lifetime:
		queue_free()


func _on_enter(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	var id := body.get_instance_id()
	if _cooldowns.get(id, 0.0) > 0.0:
		return
	_cooldowns[id] = 0.8
	if body.has_node("HealthComponent"):
		body.get_node("HealthComponent").apply_damage(_DamageData.create_physical(tick_damage, null))
	if body.has_node("StatusEffectsComponent"):
		(body.get_node("StatusEffectsComponent") as _StatusEffects).add_blight_buildup(6.0)
