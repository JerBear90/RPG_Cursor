extends SceneTree
## Spawn audit + HUD fix screenshots for Darkpine Forest.

const OUTPUT_SPAWN := "res://tests/spawn_ground_1920.png"
const OUTPUT_CURRENCY := "res://tests/currency_row_1920.png"
const OUTPUT_QUEST := "res://tests/quest_tracker_1920.png"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var win := Window.new()
	win.size = Vector2i(1920, 1080)
	root.add_child(win)
	await process_frame

	var scene := load("res://scenes/levels/darkpine_forest/darkpine_forest.tscn") as PackedScene
	var level: Node = scene.instantiate()
	win.add_child(level)

	for _i in 90:
		await process_frame

	var spawn := level.get_node_or_null("Level/SpawnPoints/Spawn1") as Node3D
	var player := level.get_node_or_null("Level/Players/Player1") as CharacterBody3D
	var terrain := level.get_node_or_null("Level/Environment/IslandTerrain") as Node

	print("=== Spawn audit ===")
	print("Spawn node path: Level/SpawnPoints/Spawn1")
	if spawn:
		print("Spawn1 global_position: %s" % spawn.global_position)
	if player:
		print("Player global_position: %s" % player.global_position)
		print("Player velocity: %s" % player.velocity)
		print("Player is_on_floor: %s" % player.is_on_floor())
		var world := player.get_world_3d()
		var ground_y := SpawnHelpers.query_ground_at_xz(world, spawn.global_position if spawn else player.global_position)
		print("Ground raycast Y at spawn xz: %.3f" % ground_y)
		print("Player collision layer/mask: %d / %d" % [player.collision_layer, player.collision_mask])
	if terrain:
		var collider := level.get_node_or_null("Level/Environment/IslandTerrain/Land/GroundCollider") as StaticBody3D
		if collider:
			print("Terrain GroundCollider collision_layer: %d" % collider.collision_layer)

	var hud := level.get_node_or_null("GameHUD/HudRoot") as PlayerHud
	if hud:
		var region := hud.get_node_or_null("%RegionLabel") as Label
		var currency := hud.get_node_or_null("%CurrencyLabel") as Label
		var tracker := hud.get_node_or_null("%QuestTracker") as QuestTrackerPanel
		print("Region label: '%s'" % (region.text if region else ""))
		if tracker:
			var objective := tracker.get_node_or_null("Margin/VBox/ObjectiveLabel") as Label
			var progress := tracker.get_node_or_null("Margin/VBox/ProgressDistanceRow/ProgressLabel") as Label
			var title := tracker.get_node_or_null("Margin/VBox/QuestTitleLabel") as Label
			print("Quest title: '%s'" % (title.text if title else ""))
			print("Quest objective visible/text: %s / '%s'" % [objective.visible if objective else false, objective.text if objective else ""])
			print("Quest progress: '%s'" % (progress.text if progress else ""))

	# Full scene + top-right crops for currency and quest tracker
	var img := win.get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUTPUT_SPAWN))
	var top_right := img.get_region(Rect2i(1580, 0, 340, 420))
	top_right.save_png(ProjectSettings.globalize_path(OUTPUT_CURRENCY))
	top_right.save_png(ProjectSettings.globalize_path(OUTPUT_QUEST))
	print("Saved spawn screenshot: %s" % OUTPUT_SPAWN)
	print("Saved currency crop: %s" % OUTPUT_CURRENCY)
	print("Saved quest crop: %s" % OUTPUT_QUEST)

	level.queue_free()
	win.queue_free()
	quit(0)
