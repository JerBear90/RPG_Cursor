extends RefCounted
## Validates signal-driven player health HUD binding (no polling).

const _PlayerHudScene := preload("res://ui/hud/player_hud.tscn")


static func run(runner: Node) -> void:
	_test_signal_updates_vital_frame(runner)
	_test_rebind_no_duplicate_connections(runner)
	_test_heal_and_reset(runner)
	_test_set_values_before_ready(runner)


static func _spawn_health(runner: Node) -> HealthComponent:
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	runner.add_child(health)
	return health


static func _spawn_hud(runner: Node) -> PlayerHud:
	var hud := _PlayerHudScene.instantiate() as PlayerHud
	runner.add_child(hud)
	return hud


static func _test_signal_updates_vital_frame(runner: Node) -> void:
	var hud := _spawn_hud(runner)
	var health := _spawn_health(runner)
	var emissions: Array = [0]
	health.health_changed.connect(func(_c, _m): emissions[0] += 1)
	hud.bind_health_component(health)
	var last_vital: Array = [-1.0, -1.0]
	hud.health_frame.value_updated.connect(func(c, m):
		last_vital[0] = c
		last_vital[1] = m
	)
	health.apply_damage(DamageData.create_physical(12.0, null))
	runner._assert(health.current_health == 88.0, "health component stores damage")
	runner._assert(emissions[0] == 1, "one health_changed emission per damage")
	runner._assert(is_equal_approx(last_vital[0], 88.0), "vital frame synced via signal")
	runner._assert(is_equal_approx(last_vital[1], health.max_health), "vital frame max synced")
	health.apply_damage(DamageData.create_physical(8.0, null))
	runner._assert(emissions[0] == 2, "consecutive hits each emit once")
	runner._assert(is_equal_approx(last_vital[0], 80.0), "vital frame tracks consecutive damage")
	hud.queue_free()
	health.queue_free()


static func _test_rebind_no_duplicate_connections(runner: Node) -> void:
	var hud := _spawn_hud(runner)
	var health := _spawn_health(runner)
	hud.bind_health_component(health)
	hud.bind_health_component(health)
	var hud_connections := _count_hud_health_connections(health, hud)
	runner._assert(hud_connections == 1, "rebind keeps a single hud health_changed connection")
	hud.queue_free()
	health.queue_free()


static func _test_heal_and_reset(runner: Node) -> void:
	var hud := _spawn_hud(runner)
	var health := _spawn_health(runner)
	hud.bind_health_component(health)
	var last_vital: Array = [-1.0, -1.0]
	hud.health_frame.value_updated.connect(func(c, m):
		last_vital[0] = c
		last_vital[1] = m
	)
	health.apply_damage(DamageData.create_physical(25.0, null))
	health.heal(10.0)
	runner._assert(is_equal_approx(last_vital[0], 85.0), "heal updates display via health_changed")
	health.reset_health()
	runner._assert(is_equal_approx(last_vital[0], health.max_health), "reset restores display via signal")
	hud.queue_free()
	health.queue_free()


static func _test_set_values_before_ready(runner: Node) -> void:
	var frame := VitalFrame.new()
	frame.stat_kind = "health"
	frame.set_values(72.0, 100.0, false)
	runner._assert(is_equal_approx(frame.pending_current, 72.0), "pending current stored before ready")
	var synced: Array = [0.0, 0.0]
	frame.value_updated.connect(func(c, m):
		synced[0] = c
		synced[1] = m
	)
	runner.add_child(frame)
	runner._assert(is_equal_approx(synced[0], 72.0), "pending values applied after ready")
	frame.queue_free()


static func _count_hud_health_connections(health: HealthComponent, hud: PlayerHud) -> int:
	var count := 0
	for conn in health.health_changed.get_connections():
		if conn.callable.get_object() == hud:
			count += 1
	return count
