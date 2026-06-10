extends Node
## Skill tree progression with unlockable nodes.

const SKILL_NODES: Dictionary = {
	"survivor_vitality": {"name": "Survivor Vitality", "desc": "+10 max health"},
	"blade_training": {"name": "Blade Training", "desc": "+5% physical damage"},
	"arcane_focus": {"name": "Arcane Focus", "desc": "+10 max focus"},
	"enduring_spirit": {"name": "Enduring Spirit", "desc": "+15 max stamina"},
	"quick_recovery": {"name": "Quick Recovery", "desc": "Faster stamina regen"},
	"ember_mastery": {"name": "Ember Mastery", "desc": "Ember Bolt +20% damage"},
	"mist_weaver": {"name": "Mist Weaver", "desc": "Unlock Healing Mist"},
	"venom_study": {"name": "Venom Study", "desc": "Unlock Venom Dart"},
	"iron_skin": {"name": "Iron Skin", "desc": "+5% block efficiency"},
	"wolf_bond": {"name": "Wolf Bond", "desc": "Unlock Ash Hound at camp"},
}

var unlocked_nodes: Array[String] = []


func get_all_node_ids() -> Array[String]:
	var ids: Array[String] = []
	for key in SKILL_NODES.keys():
		ids.append(key)
	return ids


func get_node_display(node_id: String) -> String:
	var data: Dictionary = SKILL_NODES.get(node_id, {})
	if data.is_empty():
		return node_id
	return "%s — %s" % [str(data.get("name", node_id)), str(data.get("desc", ""))]


func can_unlock(node_id: String) -> bool:
	if node_id not in SKILL_NODES:
		return false
	var stats := get_parent().get_node("StatsComponent") as StatsComponent
	return stats.unspent_skill_points > 0 and node_id not in unlocked_nodes


func unlock_node(node_id: String) -> bool:
	if not can_unlock(node_id):
		return false
	var stats := get_parent().get_node("StatsComponent") as StatsComponent
	stats.unspent_skill_points -= 1
	unlocked_nodes.append(node_id)
	_apply_node_bonus(node_id)
	refresh_derived_stats()
	return true


func reapply_all_bonuses() -> void:
	refresh_derived_stats()
	for node_id in unlocked_nodes:
		_apply_node_bonus(node_id)


func refresh_derived_stats() -> void:
	var player := get_parent()
	if player.has_node("StatsComponent") and player.has_node("HealthComponent"):
		var stats := player.get_node("StatsComponent") as StatsComponent
		var health := player.get_node("HealthComponent") as HealthComponent
		health.max_health = 100.0 + stats.get_max_health_bonus()
		if "survivor_vitality" in unlocked_nodes:
			health.max_health += 10.0
		health.current_health = minf(health.current_health, health.max_health)
	if player.has_node("StatsComponent") and player.has_node("StaminaComponent"):
		var stats := player.get_node("StatsComponent") as StatsComponent
		var stamina := player.get_node("StaminaComponent") as StaminaComponent
		stamina.max_stamina = 100.0 + stats.get_max_stamina_bonus()
		if "enduring_spirit" in unlocked_nodes:
			stamina.max_stamina += 15.0
		stamina.regen_rate = 20.0 + (8.0 if "quick_recovery" in unlocked_nodes else 0.0)
	if player.has_node("StatsComponent") and player.has_node("FocusComponent"):
		var stats := player.get_node("StatsComponent") as StatsComponent
		var focus := player.get_node("FocusComponent")
		focus.max_focus = 50.0 + stats.get_max_focus_bonus()
		if "arcane_focus" in unlocked_nodes:
			focus.max_focus += 10.0
	if player.has_node("BlockComponent"):
		var block := player.get_node("BlockComponent") as BlockComponent
		block.block_efficiency = 0.7 + (0.05 if "iron_skin" in unlocked_nodes else 0.0)
	PlayerProgress._apply_equipment_stats(player)


func _apply_node_bonus(node_id: String) -> void:
	var player := get_parent()
	if node_id == "wolf_bond":
		PetManager.unlock_pet("ash_hound")
	elif node_id == "mist_weaver" and player.has_node("Spellcaster"):
		player.get_node("Spellcaster").unlock_spell("healing_mist")
	elif node_id == "venom_study" and player.has_node("Spellcaster"):
		player.get_node("Spellcaster").unlock_spell("venom_dart")


func has_node_bonus(node_id: String) -> bool:
	return node_id in unlocked_nodes


func get_physical_damage_multiplier() -> float:
	return 1.05 if "blade_training" in unlocked_nodes else 1.0


func get_spell_damage_multiplier(spell_id: String) -> float:
	if spell_id == "ember_bolt" and "ember_mastery" in unlocked_nodes:
		return 1.2
	return 1.0
