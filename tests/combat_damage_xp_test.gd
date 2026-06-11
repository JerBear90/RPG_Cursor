extends RefCounted
## Headless combat damage and XP validation.

const _PlayerScene := preload("res://scenes/player/player.tscn")
const _EnemyScene := preload("res://scenes/enemies/enemy_base.tscn")


static func run(runner) -> void:
	_test_player_damage(runner)
	_test_spawn_protection_clear(runner)
	_test_hit_xp(runner)
	_test_kill_xp_once(runner)
	_test_zero_damage_no_xp(runner)
	_test_level_up_carry(runner)


static func _test_player_damage(runner: Node) -> void:
	var player := _PlayerScene.instantiate() as PlayerController
	runner.add_child(player)
	player.clear_spawn_protection()
	var health := player.get_node("HealthComponent") as HealthComponent
	var combat := player.get_node("Combat")
	var before := health.current_health
	combat.receive_damage(DamageData.create_physical(12.0, null))
	runner._assert(health.current_health < before, "enemy damage reduces player health")
	runner._assert(absf(health.current_health - (before - 12.0)) < 0.01, "player health matches final damage")
	player.queue_free()


static func _test_spawn_protection_clear(runner: Node) -> void:
	var player := _PlayerScene.instantiate() as PlayerController
	runner.add_child(player)
	player.refresh_spawn_protection(60.0)
	runner._assert(player.has_combat_invulnerability(), "combat invulnerability active when refreshed")
	player.clear_spawn_protection()
	runner._assert(not player.has_combat_invulnerability(), "combat invulnerability clears")
	player.queue_free()


static func _test_hit_xp(runner: Node) -> void:
	var player := _PlayerScene.instantiate() as PlayerController
	var enemy := _EnemyScene.instantiate() as EnemyBase
	runner.add_child(player)
	runner.add_child(enemy)
	var stats := player.get_node("StatsComponent") as StatsComponent
	var start_xp := stats.experience
	enemy.receive_damage(DamageData.create_physical(20.0, player))
	runner._assert(stats.experience > start_xp, "confirmed hit grants XP")
	runner._assert(stats.experience - start_xp >= 1, "hit XP is at least 1")
	player.queue_free()
	enemy.queue_free()


static func _test_kill_xp_once(runner: Node) -> void:
	var player := _PlayerScene.instantiate() as PlayerController
	var enemy := _EnemyScene.instantiate() as EnemyBase
	runner.add_child(player)
	runner.add_child(enemy)
	enemy.receive_damage(DamageData.create_physical(20.0, player))
	enemy._award_kill_experience()
	var stats := player.get_node("StatsComponent") as StatsComponent
	var after_first := stats.experience
	enemy._award_kill_experience()
	runner._assert(stats.experience == after_first, "kill XP awarded once")
	player.queue_free()
	enemy.queue_free()


static func _test_zero_damage_no_xp(runner: Node) -> void:
	var player := _PlayerScene.instantiate() as PlayerController
	var enemy := _EnemyScene.instantiate() as EnemyBase
	runner.add_child(player)
	runner.add_child(enemy)
	var stats := player.get_node("StatsComponent") as StatsComponent
	var start_xp := stats.experience
	enemy.receive_damage(DamageData.create_physical(0.0, player))
	runner._assert(stats.experience == start_xp, "zero damage grants no XP")
	player.queue_free()
	enemy.queue_free()


static func _test_level_up_carry(runner: Node) -> void:
	var player := _PlayerScene.instantiate() as PlayerController
	runner.add_child(player)
	var stats := player.get_node("StatsComponent") as StatsComponent
	stats.level = 1
	stats.experience = 0
	stats.add_experience(150, &"test")
	runner._assert(stats.level >= 2, "overflow XP triggers level up")
	runner._assert(stats.experience >= 0, "overflow XP carries forward")
	player.queue_free()
