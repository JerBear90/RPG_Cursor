extends Node
## Production gameplay health audit — Darkpine Forest level, real HUD, apply damage.

const LEVEL_SCENE := preload("res://scenes/levels/darkpine_forest/darkpine_forest.tscn")
const OUTPUT_HIT := "res://tests/production_health_hit.png"
const OUTPUT_THREE := "res://tests/production_health_three_hits.png"
const OUTPUT_HEAL := "res://tests/production_health_heal.png"

var _passed := 0
var _failed := 0


func _ready() -> void:
	print("=== Production Health Gameplay Audit ===")
	GameManager.game_started = true
	GameManager.active_player_count = 1
	await _run_audit()
	print("Audit results: %d passed, %d failed" % [_passed, _failed])
	get_tree().quit(_failed)


func _run_audit() -> void:
	var level: Node = LEVEL_SCENE.instantiate()
	get_tree().root.call_deferred("add_child", level)
	for _i in 60:
		await get_tree().process_frame
		if level.is_inside_tree():
			break

	var player := await _wait_for_player(level, 300)
	if player == null:
		_assert(false, "player spawned in Darkpine Forest")
		level.queue_free()
		return
	_assert(true, "player spawned in Darkpine Forest")

	var game_hud := level.get_node_or_null("GameHUD")
	var player_hud := level.get_node_or_null("GameHUD/HudRoot") as PlayerHud
	_assert(game_hud != null and game_hud.get_script() != null, "GameHUD script attached at runtime")
	_assert(player_hud != null, "production PlayerHud exists")

	await get_tree().create_timer(3.1).timeout

	var health := player.get_node("HealthComponent") as HealthComponent
	var combat := player.get_node("Combat")

	print("Player path/id: %s / %d" % [player.get_path(), player.get_instance_id()])
	print("Health path/id: %s / %d" % [health.get_path(), health.get_instance_id()])
	print("HUD bound player id: %d" % player_hud.get_bound_player_id())
	print("HUD bound health id: %d" % player_hud.get_bound_health_id())
	print("Protection active: spawn=%s combat=%s" % [
		player.has_spawn_protection(), player.has_combat_invulnerability()
	])

	if player_hud.get_bound_health_id() != health.get_instance_id():
		if game_hud.has_method("bind_production_player"):
			game_hud.bind_production_player(player)
		await get_tree().process_frame
	_assert(player_hud.get_bound_health_id() == health.get_instance_id(), "HUD bound to active HealthComponent")
	_assert(player_hud.get_displayed_health_text() == "100 / 100", "initial HUD = 100 / 100")

	var dmg := DamageData.create_physical(12.0, player)
	combat.receive_damage(dmg)
	await get_tree().process_frame

	_assert(is_equal_approx(health.current_health, 88.0), "authoritative health = 88 after first hit")
	_assert(player_hud.get_displayed_health_text() == "88 / 100", "HUD = 88 / 100 after first hit")
	_assert(is_equal_approx(player_hud.health_frame.get_primary_bar_value(), 88.0), "primary bar = 88 after first hit")
	_save_screenshot(OUTPUT_HIT)

	for i in 30:
		await get_tree().process_frame
	_assert(player_hud.get_displayed_health_text() == "88 / 100", "HUD still 88 / 100 after 30 frames")

	combat.receive_damage(DamageData.create_physical(12.0, player))
	await get_tree().process_frame
	combat.receive_damage(DamageData.create_physical(12.0, player))
	await get_tree().process_frame

	_assert(is_equal_approx(health.current_health, 64.0), "authoritative health = 64 after three hits")
	_assert(player_hud.get_displayed_health_text() == "64 / 100", "HUD = 64 / 100 after three hits")
	_save_screenshot(OUTPUT_THREE)

	health.heal(4.0)
	await get_tree().process_frame
	_assert(is_equal_approx(health.current_health, 68.0), "authoritative health = 68 after heal")
	_assert(player_hud.get_displayed_health_text() == "68 / 100", "HUD = 68 / 100 after heal")
	_save_screenshot(OUTPUT_HEAL)

	level.queue_free()


func _wait_for_player(level: Node, max_frames: int) -> PlayerController:
	for _i in max_frames:
		var player := GameManager.get_player(0) as PlayerController
		if player == null:
			player = level.get_node_or_null("Level/Players/Player1") as PlayerController
		if player and is_instance_valid(player):
			return player
		await get_tree().process_frame
	return null


func _save_screenshot(path: String) -> void:
	var tex := get_viewport().get_texture()
	if tex == null:
		print("Screenshot skipped (headless): %s" % path)
		return
	var img := tex.get_image()
	if img == null or img.is_empty():
		print("Screenshot skipped (empty): %s" % path)
		return
	img.save_png(ProjectSettings.globalize_path(path))
	print("Screenshot saved: %s" % path)


func _assert(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
		print("[PASS] %s" % label)
	else:
		_failed += 1
		print("[FAIL] %s" % label)
