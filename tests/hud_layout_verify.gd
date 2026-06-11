extends SceneTree
## Verifies HUD layout: minimap scale, vitals alignment, distance label placement.

const OUTPUT_1920 := "res://tests/hud_layout_1920.png"
const RESOLUTIONS := [
	Vector2i(1280, 720),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3440, 1440),
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var all_ok := true
	for res in RESOLUTIONS:
		var ok := await _verify_resolution(res)
		all_ok = all_ok and ok
	quit(0 if all_ok else 1)


func _verify_resolution(size: Vector2i) -> bool:
	var win := Window.new()
	win.size = size
	root.add_child(win)
	await process_frame

	var scene := load("res://scenes/levels/darkpine_forest/darkpine_forest.tscn") as PackedScene
	var level: Node = scene.instantiate()
	win.add_child(level)

	for _i in 90:
		await process_frame

	var hud := level.get_node_or_null("GameHUD/HudRoot") as PlayerHud
	if hud == null:
		print("[FAIL %s] HudRoot not found" % size)
		level.queue_free()
		win.queue_free()
		return false

	hud.ensure_minimap_visible()
	hud.call("_align_bottom_vitals")
	await process_frame

	var vp_w := float(size.x)
	var expected_map := UiMetrics.get_minimap_size(vp_w)
	var minimap_panel := hud.get_node_or_null("%MinimapPanel") as Control
	var minimap_widget := hud.get_node_or_null("%MinimapWidget") as Control
	var viewport_ctrl := hud.get_node_or_null("%MinimapViewport") as Control
	var legacy_dist := hud.get_node_or_null("%QuestDistanceLabel") as Label
	var distance_readout := hud.get_node_or_null("%DistanceReadout") as Label
	var health_panel := hud.get_node_or_null("SafeArea/Shell/BottomLeft") as Control
	var mana_panel := hud.get_node_or_null("SafeArea/Shell/BottomRight") as Control
	var top_right := hud.get_node_or_null("SafeArea/Shell/TopRight") as Control

	var map_w := minimap_widget.size.x if minimap_widget else 0.0
	var map_panel_w := minimap_panel.size.x if minimap_panel else 0.0
	var inner := viewport_ctrl.size if viewport_ctrl else Vector2.ZERO

	print("\n=== HUD verify %dx%d ===" % [size.x, size.y])
	print("  expected minimap: %.0f" % expected_map)
	print("  MinimapWidget size: %s" % minimap_widget.size if minimap_widget else "  missing")
	print("  MinimapPanel size: %s" % minimap_panel.size if minimap_panel else "  missing")
	print("  MinimapViewport size: %s" % inner)
	print("  TopRight offset_bottom: %.1f" % top_right.offset_bottom if top_right else "  missing")

	var ok := true
	if absf(map_w - expected_map) > 24.0:
		print("  [FAIL] MinimapWidget width %.0f vs expected %.0f" % [map_w, expected_map])
		ok = false
	if legacy_dist and legacy_dist.visible:
		print("  [FAIL] Legacy QuestDistanceLabel still visible at %s" % legacy_dist.global_position)
		ok = false
	else:
		print("  [OK] Legacy distance label hidden")

	if distance_readout:
		print("  DistanceReadout parent: %s visible=%s" % [distance_readout.get_parent().name, distance_readout.visible])
	else:
		print("  [WARN] DistanceReadout not found")

	if health_panel and mana_panel:
		var health_bottom := health_panel.global_position.y + health_panel.size.y
		var mana_bottom := mana_panel.global_position.y + mana_panel.size.y
		print("  HealthPanel global_pos=%s size=%s bottom=%.2f" % [health_panel.global_position, health_panel.size, health_bottom])
		print("  ManaPanel global_pos=%s size=%s bottom=%.2f" % [mana_panel.global_position, mana_panel.size, mana_bottom])
		if absf(health_bottom - mana_bottom) > 0.5:
			print("  [FAIL] Bottom edges differ by %.2f px" % absf(health_bottom - mana_bottom))
			ok = false
		else:
			print("  [OK] Health and mana bottom edges aligned")

	if size == Vector2i(1920, 1080):
		var img := win.get_viewport().get_texture().get_image()
		img.save_png(ProjectSettings.globalize_path(OUTPUT_1920))
		print("  Saved screenshot: %s" % OUTPUT_1920)

	level.queue_free()
	win.queue_free()
	await process_frame
	return ok
