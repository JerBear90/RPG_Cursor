class_name SpellAreaEffect
extends RefCounted
## Instant area heal/support for spells like Healing Mist.

static func apply_heal_radius(
	center: Vector3,
	radius: float,
	heal_amount: float,
	source: Node,
	heal_multiplier: float = 1.0
) -> Array[Node]:
	var healed: Array[Node] = []
	var amount := heal_amount * heal_multiplier
	for node in source.get_tree().get_nodes_in_group("player"):
		if not is_instance_valid(node):
			continue
		if node.global_position.distance_to(center) > radius:
			continue
		if not node.has_node("HealthComponent"):
			continue
		var health := node.get_node("HealthComponent") as HealthComponent
		if health.current_health <= 0.0:
			continue
		health.heal(amount)
		healed.append(node)
	CombatVfx.spawn_spell(center)
	return healed
