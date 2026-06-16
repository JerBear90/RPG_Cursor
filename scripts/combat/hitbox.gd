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
var _attack_serial: int = 0


func _ready() -> void:
	add_to_group("combat_hitbox")
	collision_layer = 8   # hitbox
	collision_mask = 16   # hurtbox
	monitoring = false
	monitorable = false
	area_entered.connect(_on_area_entered)
	_source = _find_combat_owner()


func enable() -> void:
	active = true
	_attack_serial += 1
	set_meta("attack_serial", _attack_serial)
	monitoring = true
	monitorable = true
	_hit_targets.clear()
	damage = DamageData.create_physical(base_damage, _source)
	damage.stagger = stagger
	call_deferred("_flush_overlaps")
	if is_inside_tree():
		_flush_overlaps_after_physics()


func disable() -> void:
	active = false
	monitoring = false
	monitorable = false


func landed_any_hit() -> bool:
	return not _hit_targets.is_empty()


func get_source() -> Node:
	return _source


func _flush_overlaps_after_physics() -> void:
	await get_tree().physics_frame
	_flush_overlaps()
	await get_tree().physics_frame
	_flush_overlaps()


func _flush_overlaps() -> void:
	if not active:
		return
	for area in get_overlapping_areas():
		_on_area_entered(area)


func _on_area_entered(area: Area3D) -> void:
	if not active or not area is Hurtbox:
		return
	var hurtbox := area as Hurtbox
	var id := hurtbox.get_instance_id()
	if id in _hit_targets:
		return
	_hit_targets.append(id)
	hurtbox.apply_hit(self)
	if team == "player" and _source != null:
		EquipmentManager.on_player_weapon_hit(_source)


func _find_combat_owner() -> Node:
	var node: Node = self
	while node:
		if node.has_method("receive_damage") or node.is_in_group("player") or node.is_in_group("enemy"):
			return node
		node = node.get_parent()
	return get_parent()
