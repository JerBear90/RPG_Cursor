class_name Hitbox
extends Area3D
## Active attack volume during combat animations.

@export var team: String = "player"
@export var base_damage: float = 10.0
@export var stagger: float = 10.0
@export var active: bool = false

var damage: DamageData
var _hit_targets: Array[int] = []
var _source: Node


func _ready() -> void:
	collision_layer = 8   # hitbox
	collision_mask = 16   # hurtbox
	monitoring = false
	monitorable = false
	area_entered.connect(_on_area_entered)
	_source = _find_combat_owner()


func enable() -> void:
	active = true
	monitoring = true
	_hit_targets.clear()
	damage = DamageData.create_physical(base_damage, _source)
	damage.stagger = stagger


func disable() -> void:
	active = false
	monitoring = false


func get_source() -> Node:
	return _source


func _on_area_entered(area: Area3D) -> void:
	if not active or not area is Hurtbox:
		return
	var id := area.get_instance_id()
	if id in _hit_targets:
		return
	_hit_targets.append(id)


func _find_combat_owner() -> Node:
	var node: Node = self
	while node:
		if node.has_method("receive_damage") or node.is_in_group("player") or node.is_in_group("enemy"):
			return node
		node = node.get_parent()
	return get_parent()
