class_name SpellCaster
extends RefCounted
## Resolves spell stats and executes cast effects for a player.

const _SpellRegistry := preload("res://scripts/spells/spell_registry.gd")
const _SpellAreaEffect := preload("res://scripts/spells/spell_area_effect.gd")
const _SpellProjectileScene := preload("res://scenes/weapons/spell_projectile.tscn")
const _StatusEffects := preload("res://scripts/combat/status_effects_component.gd")


static func resolve_spell(player: Node, spell_id: String, skill_tree: Node) -> Dictionary:
	var data: Dictionary = _SpellRegistry.get_spell(spell_id).duplicate()
	if player.has_node("StatsComponent"):
		var stats := player.get_node("StatsComponent") as StatsComponent
		data.damage = float(data.get("damage", 0.0)) + stats.get_spell_power_bonus()
		if data.has("heal_amount"):
			data.heal_amount = float(data.heal_amount) + stats.spirit * 0.4
	if skill_tree and skill_tree.has_method("get_spell_damage_multiplier"):
		data.damage = float(data.damage) * skill_tree.get_spell_damage_multiplier(spell_id)
	if skill_tree and skill_tree.has_method("get_spell_heal_multiplier"):
		data.heal_amount = float(data.get("heal_amount", 0.0)) * skill_tree.get_spell_heal_multiplier(spell_id)
	if skill_tree and skill_tree.has_method("get_spell_focus_cost_multiplier"):
		data.focus_cost = float(data.get("focus_cost", 0.0)) * skill_tree.get_spell_focus_cost_multiplier(spell_id, str(data.get("school", "")))
	return data


static func get_focus_cost(player: Node, spell_id: String, skill_tree: Node, focus_multiplier: float) -> float:
	var data := resolve_spell(player, spell_id, skill_tree)
	return float(data.get("focus_cost", 0.0)) * focus_multiplier


static func execute(player: Node, data: Dictionary) -> void:
	match str(data.get("spell_type", "projectile")):
		"area":
			_cast_area(player, data)
		"cone":
			_cast_cone(player, data)
		_:
			_cast_projectile(player, data)


static func _cast_projectile(player: Node, data: Dictionary) -> void:
	var cast_point := player.get_node("SpellCastPoint") as Node3D
	var projectile := _SpellProjectileScene.instantiate()
	projectile.global_position = cast_point.global_position
	var dir := -player.global_transform.basis.z
	projectile.setup(data, dir, player)
	player.get_tree().current_scene.add_child(projectile)


static func _cast_area(player: Node, data: Dictionary) -> void:
	_SpellAreaEffect.apply_heal_radius(
		player.global_position,
		float(data.get("radius", 4.0)),
		float(data.get("heal_amount", 20.0)),
		player,
		1.0
	)
	AudioManager.play_sfx(str(data.get("sfx_path", "spell")), randf_range(0.95, 1.05))


static func _cast_cone(player: Node, data: Dictionary) -> void:
	var origin := player.global_position + Vector3(0.0, 1.0, 0.0)
	var forward := -player.global_transform.basis.z.normalized()
	var range := float(data.get("range", 5.0))
	var damage := float(data.get("damage", 10.0))
	var dtype := DamageData.DamageType.DARK
	var hit_any := false
	for node in player.get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(node):
			continue
		var to_target := node.global_position - origin
		to_target.y = 0.0
		if to_target.length() > range:
			continue
		if forward.dot(to_target.normalized()) < 0.5:
			continue
		if not node.has_node("Hurtbox"):
			continue
		var hurtbox := node.get_node("Hurtbox") as Hurtbox
		if hurtbox.team == "player":
			continue
		var dmg := DamageData.new()
		dmg.amount = damage
		dmg.damage_type = dtype
		dmg.source = player
		hurtbox.hit_received.emit(dmg, player)
		hit_any = true
	if hit_any:
		CombatVfx.spawn_spell(origin + forward * (range * 0.5))
		AudioManager.play_sfx(str(data.get("sfx_path", "spell")), randf_range(0.9, 1.05))
