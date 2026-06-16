class_name DungeonTrap
extends Area3D
## Telegraph trap — damage on cooldown via existing damage pipeline.

@export var damage_amount: float = 12.0
@export var telegraph_sec: float = 1.2
@export var cooldown_sec: float = 3.0
@export var poison: bool = false

var _armed: bool = true
var _cooldown: float = 0.0
var _telegraphing: bool = false

@onready var _mesh: MeshInstance3D = _find_mesh()


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	body_entered.connect(_on_body_entered)
	if _mesh:
		_mesh.visible = true


func _find_mesh() -> MeshInstance3D:
	for child in get_children():
		if child is MeshInstance3D:
			return child
	return null


func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
		if _cooldown <= 0.0:
			_armed = true
			if _mesh:
				_mesh.modulate = Color(1, 1, 1, 0.35)


func _on_body_entered(body: Node3D) -> void:
	if not _armed or _telegraphing:
		return
	if not body.is_in_group("player"):
		return
	_telegraphing = true
	if _mesh:
		_mesh.modulate = Color(1, 0.4, 0.2, 0.9)
	await get_tree().create_timer(telegraph_sec).timeout
	if not is_instance_valid(body):
		_telegraphing = false
		return
	if body.global_position.distance_to(global_position) < 2.5 and body.has_node("HealthComponent"):
		var dmg := DamageData.create_physical(damage_amount, self)
		if poison:
			dmg.damage_type = DamageData.DamageType.POISON
			dmg.status_effect_id = "poison"
		(body.get_node("HealthComponent") as HealthComponent).apply_damage(dmg)
		if body.has_node("StatusEffectsComponent"):
			(body.get_node("StatusEffectsComponent") as Node).call("add_poison_buildup", 15.0)
	_armed = false
	_telegraphing = false
	_cooldown = cooldown_sec
	if _mesh:
		_mesh.modulate = Color(0.5, 0.5, 0.5, 0.25)
