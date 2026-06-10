class_name Hurtbox
extends Area3D
## Receives hits from Hitboxes and forwards damage to owner.

signal hit_received(damage: DamageData, hitbox: Hitbox)

@export var team: String = "neutral"
@export var damage_multiplier: float = 1.0

var _owner: Node


func _ready() -> void:
	collision_layer = 16  # hurtbox layer 5 = bit 4 = 16
	collision_mask = 8    # hitbox layer 4 = bit 3 = 8
	_owner = get_parent()
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area3D) -> void:
	if area is Hitbox:
		var hitbox := area as Hitbox
		if hitbox.team == team:
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
