extends SceneTree
## Captures minimap HUD screenshots at 1920x1080.

const OUTPUT_NORMAL := "res://tests/minimap_1920.png"
const OUTPUT_QUEST := "res://tests/minimap_quest_1920.png"
const OUTPUT_EDGE := "res://tests/minimap_edge_1920.png"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var gm := get_root().get_node("GameManager")
	var mm := get_root().get_node("MapManager")
	gm.current_region_id = "darkpine_forest"
	mm.clear_waypoint()
	await _capture(OUTPUT_NORMAL, false)
	await _capture(OUTPUT_QUEST, true)
	mm.set_waypoint(Vector3(0, 0, 24), "Far Point")
	await _capture(OUTPUT_EDGE, true, true)
	print("Minimap captures complete.")
	quit()


func _capture(path: String, with_quest: bool, edge_only: bool = false) -> void:
	for c in root.get_children():
		if c is Window:
			c.queue_free()
	await process_frame
	var win := Window.new()
	win.size = Vector2i(1920, 1080)
	win.unresizable = true
	root.add_child(win)
	await process_frame
	var hud_scene := load("res://ui/hud/player_hud.tscn") as PackedScene
	var hud: Control = hud_scene.instantiate()
	win.add_child(hud)
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var player := Node3D.new()
	player.name = "CapturePlayer"
	player.add_to_group("player")
	hud.add_child(player)
	var panel := hud.get_node_or_null("%MinimapPanel") as Control
	if panel:
		panel.visible = true
	var minimap := hud.get_node_or_null("%MinimapWidget")
	if minimap:
		minimap.call("bind_player", player)
		minimap.call("refresh_landmarks")
	if with_quest and hud.has_method("update_quest"):
		hud.update_quest(
			"Ashes Beneath Darkpine",
			PackedStringArray(["Investigate the corrupted grove"]),
			"148 m",
			"MAIN QUEST"
		)
	var region := hud.get_node_or_null("%RegionLabel") as Label
	if region:
		region.text = "Darkpine Forest"
	await process_frame
	await process_frame
	await process_frame
	if edge_only and minimap:
		await create_timer(0.2).timeout
		minimap.call("refresh_landmarks")
		await process_frame
	var img := win.get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(path))
	print("Saved ", path)
	win.queue_free()
	await process_frame
