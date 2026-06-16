class_name FallingRockHazard
extends Node3D
## Telegraph falling rocks with warning shadow then delayed impact.

@export var damage: float = 22.0
@export var telegraph_time: float = 1.4
@export var interval: float = 8.0
@export var radius: float = 2.5

var _timer: float = 3.0
var _warning: MeshInstance3D


func _ready() -> void:
	add_to_group("falling_rock_hazard")
	_warning = MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = radius
	disc.bottom_radius = radius
	disc.height = 0.08
	_warning.mesh = disc
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.12, 0.1, 0.55)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_warning.material_override = mat
	_warning.visible = false
	_warning.position = Vector3(0, 0.05, 0)
	add_child(_warning)


func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer = interval + randf_range(2.0, 5.0)
		_trigger_fall()


func _trigger_fall() -> void:
	_warning.visible = true
	var tween := create_tween()
	tween.tween_property(_warning, "scale", Vector3(1.15, 1.0, 1.15), telegraph_time * 0.85)
	await get_tree().create_timer(telegraph_time).timeout
	_warning.visible = false
	_warning.scale = Vector3.ONE
	AudioManager.play_sfx("hit")
	for body in get_tree().get_nodes_in_group("player"):
		if body is Node3D and body.global_position.distance_to(global_position) <= radius + 0.5:
			if body.has_node("HealthComponent"):
				var dmg := DamageData.create_physical(damage, self)
				(body.get_node("HealthComponent") as HealthComponent).apply_damage(dmg)
