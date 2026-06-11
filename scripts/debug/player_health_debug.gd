extends RefCounted
class_name PlayerHealthDebug
## Production health diagnostics — enable with DEBUG_PLAYER_HEALTH.

const DEBUG_PLAYER_HEALTH := false


static func log_hit(
	player: Node,
	health: HealthComponent,
	result,
	damage: DamageData,
	hud: PlayerHud = null,
	reject_reason: String = ""
) -> void:
	if not DEBUG_PLAYER_HEALTH:
		return
	var lines: PackedStringArray = []
	lines.append("=== PLAYER HEALTH HIT ===")
	if player and is_instance_valid(player):
		lines.append("Active player: %s id=%d" % [player.get_path(), player.get_instance_id()])
	else:
		lines.append("Active player: <missing>")
	if health and is_instance_valid(health):
		lines.append("Health component: %s id=%d" % [health.get_path(), health.get_instance_id()])
		lines.append("Health before: %s" % str(result.get("health_before") if result else "?"))
		lines.append("Raw damage: %s" % (damage.amount if damage else "?"))
		lines.append("Final accepted damage: %s" % str(result.get("final_damage") if result else "0"))
		lines.append("Health after: %s" % health.current_health)
		lines.append("HealthComponent current/max: %s / %s" % [health.current_health, health.max_health])
	else:
		lines.append("Health component: <missing>")
	if reject_reason != "":
		lines.append("Damage rejection reason: %s" % reject_reason)
	if hud and is_instance_valid(hud):
		lines.append("HUD-bound player ID: %s" % (
			hud.get_bound_player_id() if hud.has_method("get_bound_player_id") else "?"
		))
		lines.append("HUD-bound health ID: %s" % (
			hud.get_bound_health_id() if hud.has_method("get_bound_health_id") else "?"
		))
		lines.append("HUD displayed text: %s" % hud.get_displayed_health_text())
		if hud.health_frame:
			lines.append("VitalFrame path: %s" % hud.health_frame.get_path())
			lines.append("Label text: %s" % hud.health_frame.get_display_text())
			lines.append("Primary bar value: %s" % hud.health_frame.get_primary_bar_value())
			lines.append("Delayed bar value: %s" % hud.health_frame.get_delayed_bar_value())
	else:
		lines.append("HUD: <missing>")
	if health and is_instance_valid(health):
		lines.append("health_changed listeners: %d" % health.health_changed.get_connections().size())
	if player and player.has_method("has_combat_invulnerability"):
		lines.append("Spawn/combat invuln active: %s" % player.has_combat_invulnerability())
	lines.append("=========================")
	print("\n".join(lines))
