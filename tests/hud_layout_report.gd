extends SceneTree
## Headless HUD layout geometry report — loads player_hud under a Window per resolution.

const RESOLUTIONS := [
	Vector2i(1280, 720),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
]

const HudScene := preload("res://ui/hud/player_hud.tscn")

const LAYOUT_PATHS := [
	".",
	"SafeArea",
	"SafeArea/Shell",
	"SafeArea/Shell/TopCenter",
	"SafeArea/Shell/TopRight",
	"SafeArea/Shell/BottomLeft",
	"SafeArea/Shell/BottomCenter",
	"SafeArea/Shell/BottomRight",
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for res in RESOLUTIONS:
		await _test_resolution(res)
	quit()


func _test_resolution(res: Vector2i) -> void:
	for c in root.get_children():
		c.queue_free()
	await process_frame

	var win := Window.new()
	win.title = "HUD Layout Test"
	win.size = res
	win.unresizable = true
	root.add_child(win)
	await process_frame

	var hud: Control = HudScene.instantiate()
	win.add_child(hud)
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.offset_left = 0.0
	hud.offset_top = 0.0
	hud.offset_right = 0.0
	hud.offset_bottom = 0.0
	await process_frame

	_print_geometry(hud, "ready @ %s" % res)
	await process_frame
	_print_geometry(hud, "frame+1 @ %s" % res)
	await process_frame
	_print_geometry(hud, "frame+2 @ %s" % res)

	win.queue_free()
	await process_frame


func _print_geometry(hud: Control, tag: String) -> void:
	var vp := hud.get_viewport_rect().size
	print("=== HUD layout [%s] viewport=%s ===" % [tag, vp])
	for rel in LAYOUT_PATHS:
		var node: Control = hud if rel == "." else hud.get_node_or_null(rel) as Control
		if node == null:
			print("  MISSING: %s" % rel)
			continue
		var parent_size: Vector2 = node.get_parent().size if node.get_parent() is Control else Vector2.ZERO
		print(
			"  %s (%s) layout=%d anchors=(%.2f,%.2f,%.2f,%.2f) offsets=(%.0f,%.0f,%.0f,%.0f) pos=%s size=%s min=%s flags=(%d,%d) parent_size=%s"
			% [
				rel,
				node.get_class(),
				node.layout_mode,
				node.anchor_left,
				node.anchor_top,
				node.anchor_right,
				node.anchor_bottom,
				node.offset_left,
				node.offset_top,
				node.offset_right,
				node.offset_bottom,
				node.position,
				node.size,
				node.custom_minimum_size,
				node.size_flags_horizontal,
				node.size_flags_vertical,
				parent_size,
			]
		)
	var safe := hud.get_node_or_null("SafeArea") as MarginContainer
	var shell := hud.get_node_or_null("SafeArea/Shell") as Control
	if safe and shell:
		var ml := safe.get_theme_constant("margin_left")
		var mr := safe.get_theme_constant("margin_right")
		var mt := safe.get_theme_constant("margin_top")
		var mb := safe.get_theme_constant("margin_bottom")
		var expected := Vector2(safe.size.x - ml - mr, safe.size.y - mt - mb)
		print("  Shell expected=%s actual=%s match=%s" % [expected, shell.size, shell.size == expected])
