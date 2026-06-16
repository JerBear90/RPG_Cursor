class_name SpellRegistry
extends RefCounted
## Static spell definitions used by SpellCaster and UI.

static func get_all_spell_ids() -> Array[String]:
	return ["ember_bolt", "healing_mist", "venom_dart", "shadow_lash"]


static func get_spell(spell_id: String) -> Dictionary:
	match spell_id:
		"ember_bolt":
			return {
				"id": "ember_bolt", "display_name": "Ember Bolt", "school": "fire",
				"description": "Fire projectile. Scales with Intelligence.",
				"spell_type": "projectile", "focus_cost": 15.0, "cooldown": 1.2,
				"cast_time": 0.0, "range": 18.0, "damage": 12.0, "speed": 18.0,
				"scaling_stat": "intelligence", "required_skill_node": "ember_bolt",
				"sfx_path": "spell",
			}
		"healing_mist":
			return {
				"id": "healing_mist", "display_name": "Healing Mist", "school": "water",
				"description": "Heals caster and nearby ally.",
				"spell_type": "area", "focus_cost": 25.0, "cooldown": 8.0,
				"cast_time": 0.0, "range": 4.0, "radius": 4.0, "heal_amount": 20.0,
				"scaling_stat": "spirit", "required_skill_node": "healing_mist",
				"sfx_path": "spell",
			}
		"venom_dart":
			return {
				"id": "venom_dart", "display_name": "Venom Dart", "school": "poison",
				"description": "Poison projectile with damage-over-time.",
				"spell_type": "projectile", "focus_cost": 18.0, "cooldown": 2.0,
				"cast_time": 0.0, "range": 18.0, "damage": 8.0, "speed": 22.0,
				"status_effect": "poison", "status_tick_damage": 3.0,
				"status_tick_count": 4, "status_tick_interval": 1.0,
				"scaling_stat": "intelligence", "required_skill_node": "venom_dart",
				"sfx_path": "spell",
			}
		"shadow_lash":
			return {
				"id": "shadow_lash", "display_name": "Shadow Lash", "school": "dark",
				"description": "Short-range dark strike in front of caster.",
				"spell_type": "cone", "focus_cost": 22.0, "cooldown": 4.0,
				"cast_time": 0.0, "range": 5.0, "damage": 18.0,
				"scaling_stat": "intelligence", "required_skill_node": "shadow_lash",
				"sfx_path": "spell",
			}
		_:
			return {
				"id": spell_id, "display_name": spell_id.capitalize(), "school": "fire",
				"spell_type": "projectile", "focus_cost": 10.0, "cooldown": 1.0,
				"damage": 10.0, "speed": 15.0, "scaling_stat": "intelligence",
			}


static func get_display_name(spell_id: String) -> String:
	return str(get_spell(spell_id).get("display_name", spell_id.replace("_", " ").capitalize()))
