class_name FallingIceHazard
extends Node3D
## Telegraph + delayed ice chunk impact.

const _DamageData := preload("res://scripts/combat/damage_data.gd")

@export var warning_time: float = 1.4
@export var damage: float = 14.0
@export var cooldown: float = 2.5
@export var interval_min: float = 8.0
@export var interval_max: float = 16.0

var _timer: float = 3.0
var _cooldown: float = 0.0
var _warning: bool = false


func _ready() -> void:
	_timer = randf_range(2.0, 6.0)
	add_to_group("environment_hazard")


func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
		return
	if _warning:
		_timer -= delta
		if _timer <= 0.0:
			_impact()
		return
	_timer -= delta
	if _timer <= 0.0:
		_begin_warning()


func _begin_warning() -> void:
	_warning = true
	_timer = warning_time
	AudioManager.play_sfx("footstep")
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("show_toast"):
			hud.show_toast("Ice overhead!", 1.2, "", "notification")


func _impact() -> void:
	_warning = false
	_cooldown = cooldown
	_timer = randf_range(interval_min, interval_max)
	var area := get_node_or_null("ImpactArea") as Area3D
	if area == null:
		area = Area3D.new()
		area.name = "ImpactArea"
		area.collision_layer = 0
		area.collision_mask = 2
		area.monitoring = false
		var col := CollisionShape3D.new()
		var sp := SphereShape3D.new()
		sp.radius = 2.2
		col.shape = sp
		area.add_child(col)
		add_child(area)
	area.monitoring = true
	await get_tree().physics_frame
	for body in area.get_overlapping_bodies():
		if body.is_in_group("player") and body.has_node("HealthComponent"):
			var dmg := _DamageData.create_physical(damage, self)
			dmg.damage_type = _DamageData.DamageType.FROST
			(body.get_node("HealthComponent") as HealthComponent).apply_damage(dmg)
	area.monitoring = false
