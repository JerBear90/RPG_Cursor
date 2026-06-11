extends Node
## Focused health HUD tests only — skips Kenney manifest and procedural tests.

const _HudHealthTests = preload("res://tests/hud_health_signal_test.gd")
const _GameHudScene = preload("res://scenes/ui/game_hud.tscn")

var _passed := 0
var _failed := 0


func _ready() -> void:
	print("=== Focused Health Test Runner ===")
	_HudHealthTests.run(self)
	await _run_production_integration()
	print("Results: %d passed, %d failed" % [_passed, _failed])
	get_tree().quit(_failed)


func _run_production_integration() -> void:
	var hud_scene := _GameHudScene as PackedScene
	if hud_scene == null:
		_assert(false, "production GameHUD scene loads")
		return
	var hud_layer: CanvasLayer = hud_scene.instantiate()
	add_child(hud_layer)
	await get_tree().process_frame
	await get_tree().process_frame

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

	if hud_layer.has_method("bind_production_player"):
		hud_layer.bind_production_player(proxy)
	else:
		player_hud.bind_player_health(proxy)
	await get_tree().process_frame

	health.apply_damage(DamageData.create_physical(12.0, null))
	await get_tree().process_frame
	_assert(is_equal_approx(health.current_health, 88.0), "production bind: authoritative health 88")
	_assert(player_hud.get_displayed_health_text() == "88 / 100", "production bind: HUD text 88 / 100")
	_assert(is_equal_approx(player_hud.health_frame.get_primary_bar_value(), 88.0), "production bind: bar 88")

	health.apply_damage(DamageData.create_physical(12.0, null))
	await get_tree().process_frame
	_assert(is_equal_approx(health.current_health, 76.0), "production bind: authoritative health 76")
	_assert(player_hud.get_displayed_health_text() == "76 / 100", "production bind: HUD text 76 / 100")

	health.heal(4.0)
	await get_tree().process_frame
	_assert(is_equal_approx(health.current_health, 80.0), "production bind: authoritative health 80")
	_assert(player_hud.get_displayed_health_text() == "80 / 100", "production bind: HUD text 80 / 100")

	var connections := _count_hud_connections(health, player_hud)
	player_hud.bind_player_health(proxy)
	_assert(_count_hud_connections(health, player_hud) == 1, "production bind: single signal connection")
	_assert(_count_hud_connections(health, player_hud) == connections or connections <= 1, "production bind: no duplicate callbacks")

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
