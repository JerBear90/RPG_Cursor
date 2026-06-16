extends Node
## Full new-game flow health audit — mirrors Main Menu → Solo → Darkpine Forest.

const OUTPUT := "res://tests/production_new_game_health.png"

var _passed := 0
var _failed := 0


func _ready() -> void:
	print("=== New Game Health Audit (start_new_game flow) ===")
	GameManager.start_new_game(false)
	await _run()
	print("Results: %d passed, %d failed" % [_passed, _failed])
	get_tree().quit(_failed)


func _run() -> void:
	var player: PlayerController = null
	for _i in 360:
		player = GameManager.get_player(0) as PlayerController
		if player and is_instance_valid(player):
			break
		await get_tree().process_frame
	if player == null:
		_assert(false, "player spawned via start_new_game")
		return
	_assert(true, "player spawned via start_new_game")

	await get_tree().create_timer(3.1).timeout

	var game_hud: Node = null
	for hud in get_tree().get_nodes_in_group("game_hud"):
		game_hud = hud
		break
	var player_hud := game_hud.get_node_or_null("HudRoot") as PlayerHud if game_hud else null
	var health := player.get_node("HealthComponent") as HealthComponent
	var combat := player.get_node("Combat")

	_assert(game_hud != null and game_hud.get_script() != null, "GameHUD script loaded")
	_assert(player_hud != null, "PlayerHud resolved")

	var frame := player_hud._ensure_health_frame()
	var label := _get_stat_values_label(frame)
	_assert(frame != null, "HealthOrb VitalFrame resolved")
	_assert(label != null, "StatValues label resolved on VitalFrame")

	print("Player: %s id=%d" % [player.get_path(), player.get_instance_id()])
	print("HealthComponent: %s id=%d hp=%.1f" % [health.get_path(), health.get_instance_id(), health.current_health])
	print("HUD bound player=%d health=%d" % [player_hud.get_bound_player_id(), player_hud.get_bound_health_id()])
	print("Label path: %s id=%d text='%s'" % [label.get_path(), label.get_instance_id(), label.text])

	if player_hud.get_bound_health_id() != health.get_instance_id():
		if game_hud.has_method("bind_production_player"):
			game_hud.bind_production_player(player)
		await get_tree().process_frame
		label = _get_stat_values_label(player_hud._ensure_health_frame())

	_assert(player_hud.get_bound_health_id() == health.get_instance_id(), "HUD bound to player HealthComponent")
	_assert(label.text == "100 / 100", "label shows 100 / 100 initially")

	# Real combat path: PlayerCombat.receive_damage (same as Hurtbox → PlayerController)
	combat.receive_damage(DamageData.create_physical(12.0, player))
	await get_tree().process_frame

	print("After hit: auth=%.1f label='%s' bar=%.1f pending=%s" % [
		health.current_health,
		label.text,
		frame.get_primary_bar_value(),
		player_hud.get_displayed_health_text(),
	])

	_assert(is_equal_approx(health.current_health, 88.0), "authoritative health = 88")
	_assert(label.text == "88 / 100", "StatValues label = 88 / 100 (visible widget)")
	_assert(is_equal_approx(frame.get_primary_bar_value(), 88.0), "primary bar = 88")

	for i in [1, 2, 5, 30]:
		for _f in i:
			await get_tree().process_frame
		print("Frame +%d label='%s'" % [i, label.text])

	_assert(label.text == "88 / 100", "label still 88 / 100 after 30 frames")

	combat.receive_damage(DamageData.create_physical(12.0, player))
	await get_tree().process_frame
	combat.receive_damage(DamageData.create_physical(12.0, player))
	await get_tree().process_frame

	_assert(is_equal_approx(health.current_health, 64.0), "authoritative health = 64 after 3 hits")
	_assert(label.text == "64 / 100", "label = 64 / 100 after 3 hits")

	health.heal(4.0)
	await get_tree().process_frame
	_assert(is_equal_approx(health.current_health, 68.0), "authoritative health = 68 after heal")
	_assert(label.text == "68 / 100", "label = 68 / 100 after heal")

	_save_screenshot()


func _get_stat_values_label(frame: VitalFrame) -> Label:
	if frame == null:
		return null
	var lbl := frame.get_node_or_null("%StatValues") as Label
	if lbl == null:
		lbl = frame.get_node_or_null("Margin/HBox/VBox/HeaderRow/StatValues") as Label
	return lbl


func _save_screenshot() -> void:
	var tex := get_viewport().get_texture()
	if tex == null:
		return
	var img := tex.get_image()
	if img and not img.is_empty():
		img.save_png(ProjectSettings.globalize_path(OUTPUT))


func _assert(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
		print("[PASS] %s" % label)
	else:
		_failed += 1
		print("[FAIL] %s" % label)
