extends Node
## Skill tree progression with unlockable nodes.

const SKILL_NODES: Dictionary = {
	"survivor_vitality": {"name": "Survivor Vitality", "desc": "+10 max health"},
	"blade_training": {"name": "Blade Training", "desc": "+5% physical damage"},
	"arcane_focus": {"name": "Arcane Focus", "desc": "+10 max focus"},
	"enduring_spirit": {"name": "Enduring Spirit", "desc": "+15 max stamina"},
	"quick_recovery": {"name": "Quick Recovery", "desc": "Faster stamina regen"},
	"ember_mastery": {"name": "Ember Mastery", "desc": "Ember Bolt +20% damage"},
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
	return true


func _apply_node_bonus(node_id: String) -> void:
	var player := get_parent()
	match node_id:
		"survivor_vitality":
			var health := player.get_node("HealthComponent") as HealthComponent
			health.max_health += 10.0
			health.current_health += 10.0
		"wolf_bond":
			PetManager.unlock_pet("ash_hound")
