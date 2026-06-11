extends SceneTree
## Captures HUD layout screenshot with temporary debug overlays (test-only).

const HudScene := preload("res://ui/hud/player_hud.tscn")
const OUTPUT := "res://tests/hud_layout_screenshot.png"

const DEBUG_NODES := [
	[".", Color(1, 0, 0, 0.08)],
	["SafeArea", Color(0, 1, 0, 0.08)],
	["SafeArea/Shell", Color(0, 0.4, 1, 0.10)],
	["SafeArea/Shell/TopCenter", Color(1, 1, 0, 0.18)],
	["SafeArea/Shell/TopRight", Color(1, 0.5, 0, 0.18)],
	["SafeArea/Shell/BottomLeft", Color(0, 1, 0.5, 0.18)],
	["SafeArea/Shell/BottomCenter", Color(0.5, 0, 1, 0.18)],
	["SafeArea/Shell/BottomRight", Color(1, 0, 1, 0.18)],
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var win := Window.new()
	win.title = "HUD Layout Capture"
	win.size = Vector2i(1920, 1080)
	win.unresizable = true
	root.add_child(win)
	await process_frame

	var hud: Control = HudScene.instantiate()
	win.add_child(hud)
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await process_frame
	await process_frame

	for entry in DEBUG_NODES:
		_add_debug_rect(hud, entry[0], entry[1])
	await process_frame
	await process_frame

	var img := win.get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUTPUT))
	print("Saved HUD screenshot to ", OUTPUT)
	win.queue_free()
	quit()


func _add_debug_rect(hud: Control, rel_path: String, color: Color) -> void:
	var target: Control = hud if rel_path == "." else hud.get_node_or_null(rel_path) as Control
	if target == null:
		return
	var rect := ColorRect.new()
	rect.name = "DebugLayout_%s" % rel_path.replace("/", "_")
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	target.add_child(rect)
	target.move_child(rect, 0)
