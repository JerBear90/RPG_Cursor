extends Node
## Skill tree progression with unlockable ranked nodes.

const SKILL_NODES: Dictionary = {
	# Legacy nodes (preserved for older saves)
	"survivor_vitality": {"name": "Survivor Vitality", "desc": "+10 max health", "branch": "survival_instinct", "pos": Vector2(300, 20), "requires": [], "max_rank": 1, "cost": 1},
	"blade_training": {"name": "Blade Training", "desc": "+5% physical damage", "branch": "combat_mastery", "pos": Vector2(120, 100), "requires": ["survivor_vitality"], "max_rank": 1, "cost": 1, "passive": "weapon_damage_pct", "value_per_rank": 0.05},
	"iron_skin": {"name": "Iron Skin", "desc": "+5% block efficiency", "branch": "combat_mastery", "pos": Vector2(480, 100), "requires": ["survivor_vitality"], "max_rank": 1, "cost": 1, "passive": "block_efficiency", "value_per_rank": 0.05},
	"enduring_spirit": {"name": "Enduring Spirit", "desc": "+15 max stamina", "branch": "survival_instinct", "pos": Vector2(120, 200), "requires": ["blade_training"], "max_rank": 1, "cost": 1},
	"quick_recovery": {"name": "Quick Recovery", "desc": "Faster stamina regen", "branch": "survival_instinct", "pos": Vector2(300, 200), "requires": ["enduring_spirit"], "max_rank": 1, "cost": 1},
	"arcane_focus": {"name": "Arcane Focus", "desc": "+10 max focus", "branch": "arcane_relics", "pos": Vector2(480, 200), "requires": ["iron_skin"], "max_rank": 1, "cost": 1},
	"ember_mastery": {"name": "Ember Mastery", "desc": "Ember Bolt +20% damage", "branch": "fire", "pos": Vector2(120, 360), "requires": ["arcane_focus"], "max_rank": 1, "cost": 1, "passive": "ember_bolt_damage", "value_per_rank": 0.2},
	"mist_weaver": {"name": "Mist Weaver", "desc": "Unlock Healing Mist", "branch": "water", "pos": Vector2(300, 360), "requires": ["ember_mastery"], "max_rank": 1, "cost": 1, "unlock_spell": "healing_mist"},
	"venom_study": {"name": "Venom Study", "desc": "Unlock Venom Dart", "branch": "poison", "pos": Vector2(480, 360), "requires": ["arcane_focus"], "max_rank": 1, "cost": 1, "unlock_spell": "venom_dart"},
	"wolf_bond": {"name": "Wolf Bond", "desc": "Legacy Beast Bond unlock", "branch": "beast_bond", "pos": Vector2(300, 120), "requires": ["quick_recovery", "mist_weaver"], "max_rank": 1, "cost": 1, "passive": "beast_bond_access"},
	"beast_bond": {"name": "Beast Bond", "desc": "Unlock pet system access", "branch": "beast_bond", "pos": Vector2(300, 40), "requires": [], "required_level": 3, "max_rank": 1, "cost": 1, "passive": "beast_bond_access"},
	"loyal_companion": {"name": "Loyal Companion", "desc": "+10 pet max HP per rank", "branch": "beast_bond", "pos": Vector2(120, 40), "requires": ["beast_bond"], "max_rank": 2, "cost": 1, "passive": "pet_hp_bonus", "value_per_rank": 10.0},
	"scavenger_nose": {"name": "Scavenger Nose", "desc": "+10% pet resource find per rank", "branch": "beast_bond", "pos": Vector2(480, 40), "requires": ["beast_bond"], "max_rank": 2, "cost": 1, "passive": "pet_resource_discovery", "value_per_rank": 0.1},
	"pack_tactics": {"name": "Pack Tactics", "desc": "+5% pet damage vs shared target per rank", "branch": "beast_bond", "pos": Vector2(120, 120), "requires": ["loyal_companion"], "max_rank": 2, "cost": 1, "passive": "pet_damage_pct", "value_per_rank": 0.05},
	"quick_recall": {"name": "Quick Recall", "desc": "Pet recalls faster", "branch": "beast_bond", "pos": Vector2(480, 120), "requires": ["scavenger_nose"], "max_rank": 1, "cost": 1, "passive": "pet_recall_speed", "value_per_rank": 0.35},
	# Prototype pass nodes
	"sharpened_strikes": {"name": "Sharpened Strikes", "desc": "+5% weapon damage per rank", "branch": "combat_mastery", "pos": Vector2(20, 100), "requires": [], "max_rank": 3, "cost": 1, "passive": "weapon_damage_pct", "value_per_rank": 0.05},
	"guard_discipline": {"name": "Guard Discipline", "desc": "-10% block stamina cost per rank", "branch": "combat_mastery", "pos": Vector2(20, 180), "requires": ["sharpened_strikes"], "max_rank": 2, "cost": 1, "passive": "block_stamina_reduction", "value_per_rank": 0.1},
	"scavenger_eye": {"name": "Scavenger Eye", "desc": "+10% resource discovery per rank", "branch": "survival_instinct", "pos": Vector2(600, 20), "requires": [], "max_rank": 2, "cost": 1, "passive": "resource_discovery", "value_per_rank": 0.1},
	"field_dressing": {"name": "Field Dressing", "desc": "Healing spells +10% per rank", "branch": "survival_instinct", "pos": Vector2(600, 100), "requires": ["scavenger_eye"], "max_rank": 2, "cost": 1, "passive": "healing_bonus", "value_per_rank": 0.1},
	"efficient_repairs": {"name": "Efficient Repairs", "desc": "Repair costs -10% per rank", "branch": "crafting", "pos": Vector2(600, 180), "requires": [], "max_rank": 2, "cost": 1, "passive": "repair_cost_reduction", "value_per_rank": 0.1},
	"socket_apprentice": {"name": "Socket Apprentice", "desc": "Socket prep cost -15%", "branch": "crafting", "pos": Vector2(600, 260), "requires": ["efficient_repairs"], "max_rank": 1, "cost": 1, "passive": "socket_prep_reduction", "value_per_rank": 0.15},
	"ember_bolt": {"name": "Ember Bolt", "desc": "Unlock Ember Bolt spell", "branch": "fire", "pos": Vector2(20, 360), "requires": ["arcane_focus"], "max_rank": 1, "cost": 1, "unlock_spell": "ember_bolt"},
	"ember_control": {"name": "Ember Control", "desc": "Fire spell Focus cost -10% per rank", "branch": "fire", "pos": Vector2(20, 440), "requires": ["ember_bolt"], "max_rank": 2, "cost": 1, "passive": "fire_focus_reduction", "value_per_rank": 0.1},
	"healing_mist": {"name": "Healing Mist", "desc": "Unlock Healing Mist spell", "branch": "water", "pos": Vector2(300, 440), "requires": ["mist_weaver"], "max_rank": 1, "cost": 1, "unlock_spell": "healing_mist"},
	"soothing_flow": {"name": "Soothing Flow", "desc": "Healing spells +10% per rank", "branch": "water", "pos": Vector2(300, 520), "requires": ["healing_mist"], "max_rank": 2, "cost": 1, "passive": "healing_bonus", "value_per_rank": 0.1},
	"venom_dart": {"name": "Venom Dart", "desc": "Unlock Venom Dart spell", "branch": "poison", "pos": Vector2(480, 440), "requires": ["venom_study"], "max_rank": 1, "cost": 1, "unlock_spell": "venom_dart"},
	"toxic_handling": {"name": "Toxic Handling", "desc": "Poison spell cooldown -10% per rank", "branch": "poison", "pos": Vector2(480, 520), "requires": ["venom_dart"], "max_rank": 2, "cost": 1, "passive": "poison_cooldown_reduction", "value_per_rank": 0.1},
	"shadow_lash": {"name": "Shadow Lash", "desc": "Unlock Shadow Lash spell", "branch": "dark", "pos": Vector2(120, 520), "requires": ["arcane_focus"], "max_rank": 1, "cost": 1, "unlock_spell": "shadow_lash"},
	"hollow_focus": {"name": "Hollow Focus", "desc": "Dark spells +10% damage per rank", "branch": "dark", "pos": Vector2(120, 600), "requires": ["shadow_lash"], "max_rank": 2, "cost": 1, "passive": "dark_spell_damage", "value_per_rank": 0.1},
	"revivers_resolve": {"name": "Reviver's Resolve", "desc": "Field revive hold -15%", "branch": "coop_support", "pos": Vector2(600, 340), "requires": [], "max_rank": 1, "cost": 1, "passive": "revive_hold_reduction", "value_per_rank": 0.15},
	"shared_recovery": {"name": "Shared Recovery", "desc": "Camp rest restores +10% HP/Focus", "branch": "coop_support", "pos": Vector2(600, 420), "requires": ["revivers_resolve"], "max_rank": 1, "cost": 1, "passive": "camp_rest_bonus", "value_per_rank": 0.1},
}

const BRANCH_LABELS: Dictionary = {
	"combat_mastery": "Combat Mastery",
	"survival_instinct": "Survival Instinct",
	"crafting": "Crafting & Weapons",
	"base_builder": "Base Builder",
	"shadow_mobility": "Shadow & Mobility",
	"arcane_relics": "Arcane & Relics",
	"coop_support": "Co-op Support",
	"beast_bond": "Beast Bond",
	"fire": "Fire",
	"water": "Water",
	"poison": "Poison",
	"dark": "Dark",
}

var unlocked_nodes: Array[String] = []
var node_ranks: Dictionary = {}


func get_node_layout(node_id: String) -> Dictionary:
	var data: Dictionary = SKILL_NODES.get(node_id, {})
	return {
		"pos": data.get("pos", Vector2.ZERO),
		"requires": data.get("requires", []),
		"branch": data.get("branch", ""),
		"max_rank": int(data.get("max_rank", 1)),
	}


func get_all_node_ids() -> Array[String]:
	var ids: Array[String] = []
	for key in SKILL_NODES.keys():
		ids.append(key)
	return ids


func get_node_rank(node_id: String) -> int:
	return int(node_ranks.get(node_id, 0))


func get_node_display(node_id: String) -> String:
	var data: Dictionary = SKILL_NODES.get(node_id, {})
	if data.is_empty():
		return node_id
	var rank := get_node_rank(node_id)
	var max_r := int(data.get("max_rank", 1))
	return "%s (%d/%d) — %s" % [str(data.get("name", node_id)), rank, max_r, str(data.get("desc", ""))]


func can_unlock(node_id: String) -> bool:
	if node_id not in SKILL_NODES:
		return false
	var data: Dictionary = SKILL_NODES[node_id]
	var max_r := int(data.get("max_rank", 1))
	if get_node_rank(node_id) >= max_r:
		return false
	var stats := get_parent().get_node("StatsComponent") as StatsComponent
	if stats.unspent_skill_points < int(data.get("cost", 1)):
		return false
	if data.has("required_level") and stats.level < int(data.required_level):
		return false
	for req in get_node_layout(node_id).get("requires", []):
		if get_node_rank(str(req)) <= 0:
			return false
	return true


func unlock_node(node_id: String) -> bool:
	if not can_unlock(node_id):
		return false
	var data: Dictionary = SKILL_NODES[node_id]
	var stats := get_parent().get_node("StatsComponent") as StatsComponent
	stats.unspent_skill_points -= int(data.get("cost", 1))
	node_ranks[node_id] = get_node_rank(node_id) + 1
	if node_id not in unlocked_nodes:
		unlocked_nodes.append(node_id)
	_apply_node_bonus(node_id)
	refresh_derived_stats()
	return true


func reapply_all_bonuses() -> void:
	refresh_derived_stats()
	for node_id in node_ranks.keys():
		if get_node_rank(node_id) > 0:
			_apply_node_bonus(node_id)
	for node_id in unlocked_nodes:
		if get_node_rank(node_id) <= 0:
			node_ranks[node_id] = 1
			_apply_node_bonus(node_id)


func migrate_legacy_unlocks() -> void:
	for node_id in unlocked_nodes:
		if get_node_rank(node_id) <= 0:
			node_ranks[node_id] = 1


func serialize_ranks() -> Dictionary:
	return node_ranks.duplicate()


func deserialize_ranks(data: Dictionary) -> void:
	node_ranks = data.duplicate()
	migrate_legacy_unlocks()


func refresh_derived_stats() -> void:
	var player := get_parent()
	if player.has_node("StatsComponent") and player.has_node("HealthComponent"):
		var stats := player.get_node("StatsComponent") as StatsComponent
		var health := player.get_node("HealthComponent") as HealthComponent
		health.max_health = 100.0 + stats.get_max_health_bonus()
		if get_node_rank("survivor_vitality") > 0:
			health.max_health += 10.0
		health.current_health = minf(health.current_health, health.max_health)
		health.health_changed.emit(health.current_health, health.max_health)
	if player.has_node("StatsComponent") and player.has_node("StaminaComponent"):
		var stats := player.get_node("StatsComponent") as StatsComponent
		var stamina := player.get_node("StaminaComponent") as StaminaComponent
		stamina.max_stamina = 100.0 + stats.get_max_stamina_bonus()
		if get_node_rank("enduring_spirit") > 0:
			stamina.max_stamina += 15.0
		stamina.regen_rate = 20.0 + (8.0 if get_node_rank("quick_recovery") > 0 else 0.0)
	if player.has_node("StatsComponent") and player.has_node("FocusComponent"):
		var stats := player.get_node("StatsComponent") as StatsComponent
		var focus := player.get_node("FocusComponent") as FocusComponent
		focus.max_focus = 50.0 + stats.get_max_focus_bonus()
		if get_node_rank("arcane_focus") > 0:
			focus.max_focus += 10.0
		focus.current_focus = minf(focus.current_focus, focus.max_focus)
		focus.focus_changed.emit(focus.current_focus, focus.max_focus)
	if player.has_node("BlockComponent"):
		var block := player.get_node("BlockComponent") as BlockComponent
		block.block_efficiency = 0.7 + _sum_passive("block_efficiency")
	PlayerProgress._apply_equipment_stats(player)


func _apply_node_bonus(node_id: String) -> void:
	var player := get_parent()
	var data: Dictionary = SKILL_NODES.get(node_id, {})
	var unlock_spell := str(data.get("unlock_spell", ""))
	if unlock_spell != "" and player.has_node("Spellcaster"):
		player.get_node("Spellcaster").unlock_spell(unlock_spell)
	if node_id in ["wolf_bond", "beast_bond"]:
		PetManager.grant_beast_bond_access()
		NpcMissionHooks.check_beast_bond_skill()
	# Legacy aliases
	if node_id == "mist_weaver" and player.has_node("Spellcaster"):
		player.get_node("Spellcaster").unlock_spell("healing_mist")
	elif node_id == "venom_study" and player.has_node("Spellcaster"):
		player.get_node("Spellcaster").unlock_spell("venom_dart")


func has_node_bonus(node_id: String) -> bool:
	return get_node_rank(node_id) > 0


func _sum_passive(passive_id: String) -> float:
	var total := 0.0
	for node_id in SKILL_NODES.keys():
		var data: Dictionary = SKILL_NODES[node_id]
		if str(data.get("passive", "")) != passive_id:
			continue
		total += float(data.get("value_per_rank", 0.0)) * float(get_node_rank(node_id))
	return total


func get_physical_damage_multiplier() -> float:
	return 1.0 + _sum_passive("weapon_damage_pct")


func get_weapon_damage_multiplier() -> float:
	return get_physical_damage_multiplier()


func get_spell_damage_multiplier(spell_id: String) -> float:
	var mult := 1.0
	if spell_id == "ember_bolt":
		mult += _sum_passive("ember_bolt_damage")
		if get_node_rank("ember_mastery") > 0:
			mult += 0.2
	if spell_id == "shadow_lash":
		mult += _sum_passive("dark_spell_damage")
	return mult


func get_spell_heal_multiplier(_spell_id: String) -> float:
	return 1.0 + _sum_passive("healing_bonus")


func get_spell_focus_cost_multiplier(_spell_id: String, school: String) -> float:
	if school == "fire":
		return maxf(1.0 - _sum_passive("fire_focus_reduction"), 0.5)
	return 1.0


func get_spell_cooldown_multiplier(spell_id: String) -> float:
	if spell_id == "venom_dart":
		return maxf(1.0 - _sum_passive("poison_cooldown_reduction"), 0.5)
	return 1.0


func get_block_stamina_multiplier() -> float:
	return maxf(1.0 - _sum_passive("block_stamina_reduction"), 0.5)


func get_repair_cost_multiplier() -> float:
	return maxf(1.0 - _sum_passive("repair_cost_reduction"), 0.5)


func get_socket_prep_cost_multiplier() -> float:
	return maxf(1.0 - _sum_passive("socket_prep_reduction"), 0.5)


func get_revive_hold_multiplier() -> float:
	return maxf(1.0 - _sum_passive("revive_hold_reduction"), 0.5)


func get_camp_rest_bonus_multiplier() -> float:
	return 1.0 + _sum_passive("camp_rest_bonus")


func get_resource_discovery_bonus() -> float:
	return _sum_passive("resource_discovery")
