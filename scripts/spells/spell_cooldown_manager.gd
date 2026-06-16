class_name SpellCooldownManager
extends RefCounted
## Per-caster spell cooldown tracking.

var _cooldowns: Dictionary = {}


func tick(delta: float) -> void:
	for spell_id in _cooldowns.keys():
		_cooldowns[spell_id] = maxf(float(_cooldowns[spell_id]) - delta, 0.0)


func is_ready(spell_id: String) -> bool:
	return float(_cooldowns.get(spell_id, 0.0)) <= 0.0


func start(spell_id: String, duration: float) -> void:
	_cooldowns[spell_id] = maxf(duration, 0.0)


func get_remaining(spell_id: String) -> float:
	return float(_cooldowns.get(spell_id, 0.0))


func get_ratio(spell_id: String, base_cooldown: float) -> float:
	var remaining := get_remaining(spell_id)
	if remaining <= 0.0 or base_cooldown <= 0.0:
		return 0.0
	return remaining / base_cooldown


func clear_all() -> void:
	_cooldowns.clear()
