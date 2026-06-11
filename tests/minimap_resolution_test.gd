extends SceneTree
## Validates minimap fits TopRight safe area across resolutions.


const RESOLUTIONS := [
	Vector2i(1280, 720),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3440, 1440),
]
const MAX_TOP_RIGHT_WIDTH := 360.0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var pass_count := 0
	for res in RESOLUTIONS:
		if await _test_resolution(res):
			pass_count += 1
	print("[PASS] Minimap resolution tests %d/%d" % [pass_count, RESOLUTIONS.size()])
	quit(0 if pass_count == RESOLUTIONS.size() else 1)


func _test_resolution(res: Vector2i) -> bool:
	for c in root.get_children():
		if c is Window:
			c.queue_free()
	await process_frame
	var win := Window.new()
	win.size = res
	root.add_child(win)
	await process_frame
	var hud_scene := load("res://ui/hud/player_hud.tscn") as PackedScene
	var hud: Control = hud_scene.instantiate()
	win.add_child(hud)
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := hud.get_node_or_null("%MinimapPanel") as Control
	if panel:
		panel.visible = true
	await process_frame
	await process_frame
	var top_right := hud.get_node_or_null("SafeArea/Shell/TopRight") as Control
	var minimap := hud.get_node_or_null("%MinimapWidget") as Control
	var safe := hud.get_node_or_null("SafeArea") as MarginContainer
	if top_right == null or minimap == null or safe == null:
		print("[FAIL] Missing nodes at ", res)
		win.queue_free()
		return false
	var mr := safe.get_theme_constant("margin_right")
	var map_right := minimap.get_global_rect().end.x
	var safe_right := safe.get_global_rect().end.x - mr
	var width_ok := top_right.size.x <= MAX_TOP_RIGHT_WIDTH + 1.0
	var margin_ok := map_right <= safe_right + 1.0
	var ok := width_ok and margin_ok and minimap.size.x >= 180.0
	if ok:
		print("[PASS] %s top_right=%s minimap=%s safe_right=%.0f" % [res, top_right.size, minimap.size, safe_right])
	else:
		print("[FAIL] %s top_right=%s minimap=%s map_right=%.0f safe_right=%.0f" % [
			res, top_right.size, minimap.size, map_right, safe_right
		])
	win.queue_free()
	await process_frame
	return ok
