class_name Hurtbox
extends Area3D
## Receives hits from Hitboxes and forwards damage to owner.

signal hit_received(damage: DamageData, hitbox: Hitbox)

@export var team: String = "neutral"
@export var damage_multiplier: float = 1.0

var _owner: Node
var _recent_hitbox_ids: Dictionary = {}


func _ready() -> void:
	collision_layer = 16  # hurtbox layer 5 = bit 4 = 16
	collision_mask = 8    # hitbox layer 4 = bit 3 = 8
	monitoring = true
	monitorable = true
	_owner = get_parent()
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area3D) -> void:
	if area is Hitbox:
		apply_hit(area as Hitbox)


func apply_hit(hitbox: Hitbox) -> void:
	if hitbox == null or not hitbox.active:
		return
	var dedup_key := hitbox.get_instance_id() ^ int(hitbox.get_meta("attack_serial", 0))
	if _recent_hitbox_ids.has(dedup_key):
		return
	_recent_hitbox_ids[dedup_key] = true
	if _recent_hitbox_ids.size() > 64:
		_recent_hitbox_ids.clear()
	if hitbox.team == team:
		return
	var source := hitbox.get_source()
	if source != null and _owner and (source == _owner or _owner.is_ancestor_of(source)):
		return
	var damage := hitbox.damage.duplicate() if hitbox.damage else DamageData.create_physical(hitbox.base_damage)
	damage.amount *= damage_multiplier
	damage.source = hitbox.get_source()
	hit_received.emit(damage, hitbox)
	if hitbox.team == "player" and _owner and _owner.is_in_group("npc"):
		if _owner.has_method("receive_friendly_fire"):
			_owner.receive_friendly_fire()
		return
	if _owner and _owner.has_method("receive_damage"):
		_owner.receive_damage(damage)
	if _owner and _owner.is_in_group("player"):
		CombatVfx.spawn_blood(global_position + Vector3(0, 0.35, 0))
	if _owner and _owner.is_in_group("enemy"):
		return
	CombatVfx.spawn_hit(global_position)
