class_name PetStats
extends RefCounted
## Runtime pet combat stats with gear and skill modifiers.

var max_hp: float = 60.0
var current_hp: float = 60.0
var base_damage: float = 6.0
var downed: bool = false


func apply_data(data: Dictionary, modifiers: Dictionary) -> void:
	max_hp = float(data.get("max_hp", 60.0))
	max_hp += float(modifiers.get("hp_bonus", 0.0))
	max_hp += float(modifiers.get("gear_hp_bonus", 0.0))
	base_damage = float(data.get("base_damage", 6.0))
	base_damage += float(modifiers.get("damage_bonus", 0.0))
	base_damage += float(modifiers.get("gear_damage_bonus", 0.0))
	base_damage *= float(modifiers.get("damage_multiplier", 1.0))
	current_hp = clampf(current_hp if current_hp > 0.0 else max_hp, 0.0, max_hp)
	downed = current_hp <= 0.0


func take_damage(amount: float) -> void:
	if downed:
		return
	current_hp = maxf(current_hp - amount, 0.0)
	if current_hp <= 0.0:
		downed = true


func heal(amount: float) -> void:
	if downed and amount >= max_hp * 0.25:
		downed = false
	current_hp = minf(current_hp + amount, max_hp)
	if current_hp > 0.0:
		downed = false


func full_recover() -> void:
	current_hp = max_hp
	downed = false


func serialize() -> Dictionary:
	return {"current_hp": current_hp, "max_hp": max_hp, "downed": downed}


func deserialize(data: Dictionary) -> void:
	max_hp = float(data.get("max_hp", max_hp))
	current_hp = clampf(float(data.get("current_hp", max_hp)), 0.0, max_hp)
	downed = bool(data.get("downed", current_hp <= 0.0))
