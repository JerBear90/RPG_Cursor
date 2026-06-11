extends SceneTree
## Resolution validation for HUD layout chain — no anchor changes.

const RESOLUTIONS := [
	Vector2i(1280, 720),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3440, 1440),
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var pass_count := 0
	for res in RESOLUTIONS:
		if await _test_resolution(res):
			pass_count += 1
	print("[PASS] HUD resolution tests %d/%d" % [pass_count, RESOLUTIONS.size()])
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
	await process_frame
	await process_frame
	var shell := hud.get_node_or_null("SafeArea/Shell") as Control
	var safe := hud.get_node_or_null("SafeArea") as MarginContainer
	if shell == null or safe == null:
		print("[FAIL] Missing shell at ", res)
		win.queue_free()
		return false
	var ml := safe.get_theme_constant("margin_left")
	var mr := safe.get_theme_constant("margin_right")
	var mt := safe.get_theme_constant("margin_top")
	var mb := safe.get_theme_constant("margin_bottom")
	var expected := Vector2(safe.size.x - ml - mr, safe.size.y - mt - mb)
	var ok := shell.size == expected
	var corners := ["TopCenter", "TopRight", "BottomLeft", "BottomCenter", "BottomRight"]
	for corner in corners:
		var node := shell.get_node_or_null(corner) as Control
		if node == null or node.size.x < 8.0 or node.size.y < 8.0:
			ok = false
			print("[FAIL] Corner collapsed ", corner, " at ", res, " size=", node.size if node else Vector2.ZERO)
	if ok:
		print("[PASS] %s shell=%s expected=%s" % [res, shell.size, expected])
	else:
		print("[FAIL] %s shell=%s expected=%s" % [res, shell.size, expected])
	win.queue_free()
	await process_frame
	return ok
