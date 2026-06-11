extends SceneTree
## Standalone production health HUD integration test (no Kenney manifest, no full player scene).

const _PlayerHudScene := preload("res://ui/hud/player_hud.tscn")
const _GameHudScene := preload("res://scenes/ui/game_hud.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: PackedStringArray = []
	var win := Window.new()
	win.size = Vector2i(1280, 720)
	root.add_child(win)
	await process_frame

	var hud_layer := _GameHudScene.instantiate()
	win.add_child(hud_layer)
	await process_frame
	await process_frame

	var player_hud := hud_layer.get_node("HudRoot") as PlayerHud
	_assert(player_hud != null, "PlayerHud exists", failures)
	_assert(player_hud._ensure_health_frame() != null, "HealthOrb resolved", failures)

	var health := HealthComponent.new()
	health.name = "HealthComponent"
	var proxy := Node.new()
	proxy.name = "PlayerProxy"
	proxy.add_child(health)
	win.add_child(proxy)
	await process_frame

	if hud_layer.has_method("bind_production_player"):
		hud_layer.bind_production_player(proxy)
	else:
		player_hud.bind_player_health(proxy)

	await process_frame

	health.apply_damage(DamageData.create_physical(12.0, null))
	await process_frame

	_assert(is_equal_approx(health.current_health, 88.0), "authoritative health 88 after 12 damage", failures)
	_assert_display(player_hud, 88.0, 100.0, failures)

	health.apply_damage(DamageData.create_physical(12.0, null))
	await process_frame
	_assert(is_equal_approx(health.current_health, 76.0), "authoritative health 76 after second hit", failures)
	_assert_display(player_hud, 76.0, 100.0, failures)

	health.heal(4.0)
	await process_frame
	_assert(is_equal_approx(health.current_health, 80.0), "authoritative health 80 after heal", failures)
	_assert_display(player_hud, 80.0, 100.0, failures)

	var connections := _count_hud_connections(health, player_hud)
	player_hud.bind_player_health(proxy)
	var connections_after := _count_hud_connections(health, player_hud)
	_assert(connections_after == 1, "rebind keeps single health_changed connection", failures)
	_assert(connections_after == connections or connections <= 1, "no duplicate callbacks after rebind", failures)

	hud_layer.queue_free()
	win.queue_free()

	if failures.is_empty():
		print("production_health_integration_test: PASS")
		quit(0)
	else:
		for f in failures:
			push_error(f)
		print("production_health_integration_test: FAIL (%d)" % failures.size())
		quit(1)


func _assert_display(hud: PlayerHud, current: float, maximum: float, failures: PackedStringArray) -> void:
	var text := hud.get_displayed_health_text()
	var expected := "%d / %d" % [int(current), int(maximum)]
	_assert(text == expected, "HUD text '%s' expected '%s'" % [text, expected], failures)
	var bar := hud.health_frame.get_primary_bar_value()
	_assert(is_equal_approx(bar, current), "primary bar %.1f expected %.1f" % [bar, current], failures)


func _assert(condition: bool, message: String, failures: PackedStringArray) -> void:
	if not condition:
		failures.append(message)


func _count_hud_connections(health: HealthComponent, hud: PlayerHud) -> int:
	var count := 0
	for conn in health.health_changed.get_connections():
		if conn.callable.get_object() == hud:
			count += 1
	return count
