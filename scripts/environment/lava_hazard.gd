class_name LavaHazard
extends Area3D
## Visible lava pool — instant buildup spike with damage cooldown.

@export var damage: float = 18.0
@export var cooldown: float = 1.2

var _cooldowns: Dictionary = {}


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	add_to_group("lava_hazard")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_build_visual()


func _build_visual() -> void:
	var mesh := MeshInstance3D.new()
	var plane := BoxMesh.new()
	plane.size = Vector3(4, 0.15, 4)
	mesh.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.35, 0.08)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.4, 0.05)
	mat.emission_energy_multiplier = 1.8
	mat.roughness = 0.35
	mesh.material_override = mat
	mesh.position = Vector3(0, -0.05, 0)
	add_child(mesh)


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	if body.has_node("StatusEffectsComponent"):
		var status := body.get_node("StatusEffectsComponent") as StatusEffectsComponent
		status.add_heat_buildup(40.0)
	_apply_damage(body)


func _on_body_exited(body: Node3D) -> void:
	pass


func _apply_damage(body: Node3D) -> void:
	var pid := body.get_instance_id()
	var now := Time.get_ticks_msec()
	if _cooldowns.get(pid, 0) > now:
		return
	_cooldowns[pid] = now + int(cooldown * 1000.0)
	if body.has_node("HealthComponent"):
		var dmg := DamageData.create_physical(damage, self)
		dmg.damage_type = DamageData.DamageType.FIRE
		(body.get_node("HealthComponent") as HealthComponent).apply_damage(dmg)
	if body is CharacterBody3D:
		var away := (body.global_position - global_position).normalized()
		away.y = 0.4
		(body as CharacterBody3D).velocity += away * 6.0
