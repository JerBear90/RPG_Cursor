extends Node
## Focused health HUD tests only — skips Kenney manifest and procedural tests.

const _HudHealthTests = preload("res://tests/hud_health_signal_test.gd")
const _GameHudScene = preload("res://scenes/ui/game_hud.tscn")

var _passed := 0
var _failed := 0


func _ready() -> void:
	print("=== Focused Health Test Runner ===")
	var game_hud_script := load("res://scripts/ui/game_hud.gd") as Script
	_assert(game_hud_script != null, "game_hud.gd loads without parse errors")
	_HudHealthTests.run(self)
	await _run_production_integration()
	print("Results: %d passed, %d failed" % [_passed, _failed])
	get_tree().quit(_failed)


func _run_production_integration() -> void:
	var hud_scene := _GameHudScene as PackedScene
	var hud_layer: CanvasLayer = hud_scene.instantiate()
	add_child(hud_layer)
	await get_tree().process_frame
	await get_tree().process_frame

	var game_hud_script: Script = hud_layer.get_script()
	_assert(game_hud_script != null, "production GameHUD script attached at runtime")

	var player_hud := hud_layer.get_node("HudRoot") as PlayerHud
	_assert(player_hud != null, "production GameHUD PlayerHud exists")
	_assert(player_hud._ensure_health_frame() != null, "production HealthOrb resolved")

	var health := HealthComponent.new()
	health.name = "HealthComponent"
	var proxy := Node.new()
	proxy.name = "PlayerProxy"
	proxy.add_child(health)
	add_child(proxy)
	await get_tree().process_frame

	player_hud.bind_player_health(proxy)
	await get_tree().process_frame
	_assert(player_hud.get_displayed_health_text() == "100 / 100", "initial HUD = 100 / 100")
	_assert(player_hud.get_bound_health_id() == health.get_instance_id(), "HUD bound to player HealthComponent")

	health.apply_damage(DamageData.create_physical(12.0, null))
	await get_tree().process_frame
	_assert(is_equal_approx(health.current_health, 88.0), "authoritative health = 88 after 12 damage")
	_assert(player_hud.get_displayed_health_text() == "88 / 100", "visible label = 88 / 100 after hit")
	_assert(is_equal_approx(player_hud.health_frame.get_primary_bar_value(), 88.0), "primary bar = 88 after hit")

	for i in 30:
		await get_tree().process_frame
	_assert(
		player_hud.get_displayed_health_text() == "88 / 100",
		"visible label still 88 / 100 after 30 frames"
	)

	health.apply_damage(DamageData.create_physical(12.0, null))
	await get_tree().process_frame
	_assert(is_equal_approx(health.current_health, 76.0), "authoritative health = 76 after second hit")
	_assert(player_hud.get_displayed_health_text() == "76 / 100", "visible label = 76 / 100")

	health.heal(4.0)
	await get_tree().process_frame
	_assert(is_equal_approx(health.current_health, 80.0), "authoritative health = 80 after heal")
	_assert(player_hud.get_displayed_health_text() == "80 / 100", "visible label = 80 / 100 after heal")

	var connections := _count_hud_connections(health, player_hud)
	player_hud.bind_player_health(proxy)
	_assert(_count_hud_connections(health, player_hud) == 1, "single health_changed connection after rebind")
	_assert(_count_hud_connections(health, player_hud) == connections or connections <= 1, "no duplicate callbacks")

	hud_layer.queue_free()
	proxy.queue_free()


func _count_hud_connections(health: HealthComponent, hud: PlayerHud) -> int:
	var count := 0
	for conn in health.health_changed.get_connections():
		if conn.callable.get_object() == hud:
			count += 1
	return count


func _assert(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
		print("[PASS] %s" % label)
	else:
		_failed += 1
		print("[FAIL] %s" % label)
