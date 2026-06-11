extends Node
## Awards combat XP from confirmed damage and kills.

signal combat_xp_gained(amount: int, label: String, is_kill: bool)

@export var hit_xp_multiplier: float = 0.05
@export var min_hit_xp: int = 1


func resolve_player_owner(source: Node) -> Node:
	if source == null or not is_instance_valid(source):
		return null
	if source.is_in_group("player"):
		return source
	if source.is_in_group("pet"):
		for player in GameManager.get_alive_players():
			if player and is_instance_valid(player):
				return player
	var node: Node = source
	while node:
		if node.is_in_group("player"):
			return node
		node = node.get_parent()
	return null


func try_award_hit_xp(attacker: Node, final_damage: float, _victim: Node) -> void:
	if attacker == null or not is_instance_valid(attacker):
		return
	if final_damage <= 0.0:
		return
	if not attacker.has_node("StatsComponent"):
		return
	var xp := maxi(min_hit_xp, int(final_damage * hit_xp_multiplier))
	var stats := attacker.get_node("StatsComponent") as StatsComponent
	stats.add_experience(xp, &"combat_hit")
	combat_xp_gained.emit(xp, "+%d XP" % xp, false)


func try_award_kill_xp(killer: Node, amount: int, enemy_name: String = "") -> void:
	if killer == null or not is_instance_valid(killer) or amount <= 0:
		return
	if not killer.has_node("StatsComponent"):
		return
	var stats := killer.get_node("StatsComponent") as StatsComponent
	stats.add_experience(amount, &"combat_kill")
	var label := "+%d XP — Enemy Defeated" % amount
	if enemy_name != "":
		label = "+%d XP — %s" % [amount, enemy_name]
	combat_xp_gained.emit(amount, label, true)
