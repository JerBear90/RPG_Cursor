extends Node
## Serialize and restore per-player progression (stats, skills, survival).

static func collect(player: Node) -> Dictionary:
	if player == null:
		return {}
	var data := {}
	if player.has_node("StatsComponent"):
		var stats := player.get_node("StatsComponent") as StatsComponent
		data["stats"] = {
			"level": stats.level,
			"experience": stats.experience,
			"strength": stats.strength,
			"dexterity": stats.dexterity,
			"intelligence": stats.intelligence,
			"vitality": stats.vitality,
			"endurance": stats.endurance,
			"spirit": stats.spirit,
			"unspent_stat_points": stats.unspent_stat_points,
			"unspent_skill_points": stats.unspent_skill_points,
		}
	if player.has_node("SkillTree"):
		var tree := player.get_node("SkillTree")
		data["skill_tree"] = {
			"unlocked": tree.unlocked_nodes.duplicate(),
			"ranks": tree.serialize_ranks() if tree.has_method("serialize_ranks") else {},
		}
	if player.has_node("SurvivalNeedsComponent"):
		var needs := player.get_node("SurvivalNeedsComponent") as SurvivalNeedsComponent
		data["survival"] = {"hunger": needs.hunger, "thirst": needs.thirst}
	if player.has_node("Spellcaster"):
		var spellcaster := player.get_node("Spellcaster")
		if spellcaster.has_method("serialize"):
			data["spells"] = spellcaster.serialize()
	if player.has_node("FocusComponent"):
		var focus := player.get_node("FocusComponent") as FocusComponent
		if focus.has_method("serialize"):
			data["focus"] = focus.serialize()
	return data


static func apply(player: Node, data: Dictionary) -> void:
	if player == null or data.is_empty():
		return
	if data.has("stats") and player.has_node("StatsComponent"):
		var stats := player.get_node("StatsComponent") as StatsComponent
		var s: Dictionary = data.stats
		stats.level = int(s.get("level", 1))
		stats.experience = int(s.get("experience", 0))
		stats.strength = int(s.get("strength", 5))
		stats.dexterity = int(s.get("dexterity", 5))
		stats.intelligence = int(s.get("intelligence", 5))
		stats.vitality = int(s.get("vitality", 5))
		stats.endurance = int(s.get("endurance", 5))
		stats.spirit = int(s.get("spirit", 5))
		stats.unspent_stat_points = int(s.get("unspent_stat_points", 0))
		stats.unspent_skill_points = int(s.get("unspent_skill_points", 0))
	if data.has("skill_tree") and player.has_node("SkillTree"):
		var tree := player.get_node("SkillTree")
		tree.unlocked_nodes = data.skill_tree.get("unlocked", []).duplicate()
		if data.skill_tree.has("ranks"):
			tree.deserialize_ranks(data.skill_tree.get("ranks", {}))
		else:
			tree.migrate_legacy_unlocks()
		if tree.has_method("reapply_all_bonuses"):
			tree.reapply_all_bonuses()
	if data.has("survival") and player.has_node("SurvivalNeedsComponent"):
		var needs := player.get_node("SurvivalNeedsComponent") as SurvivalNeedsComponent
		needs.hunger = float(data.survival.get("hunger", needs.hunger))
		needs.thirst = float(data.survival.get("thirst", needs.thirst))
	if data.has("spells") and player.has_node("Spellcaster"):
		var spellcaster := player.get_node("Spellcaster")
		if spellcaster.has_method("deserialize"):
			spellcaster.deserialize(data.spells)
	if data.has("focus") and player.has_node("FocusComponent"):
		var focus := player.get_node("FocusComponent") as FocusComponent
		if focus.has_method("deserialize"):
			var saved_current := float(data.focus.get("current_focus", -1.0))
			focus.deserialize(data.focus)
			if saved_current >= 0.0:
				focus.apply_saved_current(saved_current)
	_apply_equipment_stats(player)
	apply_mask_bonuses(player)
	if player.has_node("SkillTree"):
		var tree := player.get_node("SkillTree")
		if tree.has_method("refresh_derived_stats"):
			tree.refresh_derived_stats()
	if data.has("focus") and player.has_node("FocusComponent"):
		var focus := player.get_node("FocusComponent") as FocusComponent
		var saved_current := float(data.focus.get("current_focus", focus.current_focus))
		focus.apply_saved_current(saved_current)


static func apply_mask_bonuses(player: Node) -> void:
	if player == null:
		return
	var bonus := MaskManager.get_stat_bonuses()
	if player.has_node("HealthComponent"):
		var health := player.get_node("HealthComponent") as HealthComponent
		var base_max := 100.0
		if player.has_node("StatsComponent"):
			base_max += (player.get_node("StatsComponent") as StatsComponent).get_max_health_bonus()
		var chest_entry := EquipmentManager.get_equipped_instance("chest")
		if chest_entry.is_empty():
			base_max += ItemDatabase.get_armor_health_bonus(str(InventoryManager.equipment.get("chest", "")))
		else:
			base_max += EquipmentManager.get_effective_armor_bonus(chest_entry)
		base_max += float(bonus.get("health", 0.0))
		health.max_health = base_max
		health.current_health = minf(health.current_health, health.max_health)
		health.health_changed.emit(health.current_health, health.max_health)
	if player.has_node("StaminaComponent"):
		var stamina := player.get_node("StaminaComponent") as StaminaComponent
		stamina.max_stamina = 100.0 + float(bonus.get("stamina", 0.0))
		stamina.current_stamina = minf(stamina.current_stamina, stamina.max_stamina)
	if player.has_node("FocusComponent"):
		var focus := player.get_node("FocusComponent") as FocusComponent
		var gem_focus := float(GemEffectManager.get_player_passive_modifiers().get("focus_max", 0.0))
		focus.max_focus = 50.0 + float(bonus.get("focus", 0.0)) + gem_focus
		focus.current_focus = minf(focus.current_focus, focus.max_focus)


static func _apply_equipment_stats(player: Node) -> void:
	if not player.has_node("HealthComponent"):
		return
	var health := player.get_node("HealthComponent") as HealthComponent
	var base_max := 100.0
	if player.has_node("StatsComponent"):
		base_max += (player.get_node("StatsComponent") as StatsComponent).get_max_health_bonus()
	for slot in ["helmet", "chest", "gloves", "boots", "offhand"]:
		var entry := EquipmentManager.get_equipped_instance(slot)
		if entry.is_empty():
			continue
		base_max += EquipmentManager.get_effective_armor_bonus(entry)
	var mask_health := float(MaskManager.get_stat_bonuses().get("health", 0.0))
	base_max += mask_health
	health.max_health = base_max
	health.current_health = minf(health.current_health, health.max_health)
	health.health_changed.emit(health.current_health, health.max_health)
	if player.has_node("BlockComponent"):
		var shield := EquipmentManager.get_equipped_instance("offhand")
		var block := player.get_node("BlockComponent") as BlockComponent
		block.block_efficiency = EquipmentManager.get_shield_block_efficiency(shield)
	if player.has_node("FocusComponent"):
		var focus := player.get_node("FocusComponent") as FocusComponent
		var gem_focus := float(GemEffectManager.get_player_passive_modifiers().get("focus_max", 0.0))
		focus.max_focus = 50.0 + float(MaskManager.get_stat_bonuses().get("focus", 0.0)) + gem_focus
		focus.current_focus = minf(focus.current_focus, focus.max_focus)
