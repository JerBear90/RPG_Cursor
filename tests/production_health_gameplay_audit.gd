extends SceneTree
## Production gameplay health audit — Darkpine Forest, apply damage, verify HUD.

const OUTPUT := "res://tests/production_health_hit.png"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	GameManager.game_started = true
	GameManager.active_player_count = 1

	var win := Window.new()
	win.size = Vector2i(1920, 1080)
	root.add_child(win)
	await process_frame

	var scene := load("res://scenes/levels/darkpine_forest/darkpine_forest.tscn") as PackedScene
	var level: Node = scene.instantiate()
	win.add_child(level)

	for _i in 120:
		await process_frame

	var player := level.get_node_or_null("Level/Players/Player1") as PlayerController
	var game_hud := level.get_node_or_null("GameHUD")
	var player_hud := level.get_node_or_null("GameHUD/HudRoot") as PlayerHud

	print("=== Production health audit ===")
	if player == null:
		push_error("Player1 missing")
		quit(1)
		return

	var health := player.get_node("HealthComponent") as HealthComponent
	print("Player path/id: %s / %d" % [player.get_path(), player.get_instance_id()])
	print("Health path/id: %s / %d" % [health.get_path(), health.get_instance_id()])
	print("Health before damage: %.1f / %.1f" % [health.current_health, health.max_health])

	if game_hud and game_hud.has_method("bind_production_player"):
		game_hud.bind_production_player(player)

	if player_hud:
		print("HUD bound player id: %d" % player_hud.get_bound_player_id())
		print("HUD bound health id: %d" % player_hud.get_bound_health_id())
		print("HUD text before: '%s'" % player_hud.get_displayed_health_text())

	health.apply_damage(DamageData.create_physical(12.0, player))
	await process_frame

	print("Health after 12 damage: %.1f" % health.current_health)
	if player_hud:
		print("HUD text after hit: '%s'" % player_hud.get_displayed_health_text())
		print("Primary bar: %.1f" % player_hud.health_frame.get_primary_bar_value())

	var ok := is_equal_approx(health.current_health, 88.0)
	if player_hud:
		ok = ok and player_hud.get_displayed_health_text() == "88 / 100"

	var img := win.get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUTPUT))
	print("Screenshot: %s" % OUTPUT)
	print("Audit result: %s" % ("PASS" if ok else "FAIL"))

	level.queue_free()
	win.queue_free()
	quit(0 if ok else 1)
