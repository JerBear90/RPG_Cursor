extends RefCounted
class_name PlayerHealthDebug
## Production health diagnostics — toggle DEBUG_PLAYER_HEALTH for runtime traces.

const DEBUG_PLAYER_HEALTH := false


static func log_damage_trace(
	player: Node,
	combat: Node,
	health: HealthComponent,
	damage: DamageData,
	result,
	hud: PlayerHud,
	reject_reason: String = "",
	floating_damage: bool = false
) -> void:
	if not DEBUG_PLAYER_HEALTH:
		return
	var lines: PackedStringArray = []
	lines.append("=== PLAYER DAMAGE TRACE ===")
	if damage and damage.source:
		lines.append("Attack source: %s id=%d" % [damage.source.get_path(), damage.source.get_instance_id()])
	else:
		lines.append("Attack source: <unknown>")
	if player and is_instance_valid(player):
		lines.append("Active player path: %s" % player.get_path())
		lines.append("Active player instance ID: %d" % player.get_instance_id())
		if player.has_method("has_spawn_protection"):
			lines.append("Spawn protection active: %s" % player.has_spawn_protection())
		if player.has_method("has_combat_invulnerability"):
			lines.append("Combat invulnerability active: %s" % player.has_combat_invulnerability())
	else:
		lines.append("Active player: <missing>")
	if combat and is_instance_valid(combat):
		lines.append("PlayerCombat instance ID: %d" % combat.get_instance_id())
	if health and is_instance_valid(health):
		lines.append("HealthComponent path: %s" % health.get_path())
		lines.append("HealthComponent instance ID: %d" % health.get_instance_id())
	if reject_reason != "":
		lines.append("Damage rejected because: %s" % reject_reason)
	lines.append("Raw incoming damage: %s" % (damage.amount if damage else "?"))
	if result:
		lines.append("Final accepted damage: %s" % str(result.get("final_damage", 0)))
		lines.append("Health before: %s" % str(result.get("health_before", "?")))
		lines.append("Health after: %s" % str(result.get("health_after", health.current_health if health else "?")))
		lines.append("health_changed emitted: %s" % ("yes" if result.get("accepted", false) else "no"))
	else:
		lines.append("Final accepted damage: 0")
		if health:
			lines.append("Health before: %s" % health.current_health)
			lines.append("Health after: %s" % health.current_health)
		lines.append("health_changed emitted: no")
	lines.append("Floating damage displayed: %s" % floating_damage)
	if hud and is_instance_valid(hud):
		lines.append("HUD-bound player ID: %d" % hud.get_bound_player_id())
		lines.append("HUD-bound health ID: %d" % hud.get_bound_health_id())
		lines.append("HUD displayed text: %s" % hud.get_displayed_health_text())
	lines.append("===========================")
	print("\n".join(lines))


static func log_hud_update(stage: String, current: float, maximum: float, extra: String = "") -> void:
	if not DEBUG_PLAYER_HEALTH:
		return
	var suffix := "" if extra == "" else " | %s" % extra
	print("[HEALTH HUD] %s: %.0f / %.0f%s" % [stage, current, maximum, suffix])
