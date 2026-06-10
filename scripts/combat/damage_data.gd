class_name DamageData
extends Resource
## Describes a single damage instance.

enum DamageType { PHYSICAL, FIRE, WATER, POISON, DARK }

@export var amount: float = 10.0
@export var damage_type: DamageType = DamageType.PHYSICAL
@export var stagger: float = 10.0
@export var poise_damage: float = 5.0
@export var can_be_blocked: bool = true
@export var can_be_parried: bool = false
var source: Node = null
@export var knockback_force: float = 2.0
@export var status_effect_id: String = ""
@export var is_execution: bool = false


static func create_physical(amount: float, source: Node = null) -> DamageData:
	var d := DamageData.new()
	d.amount = amount
	d.source = source
	return d
