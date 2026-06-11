extends SceneTree
## Runtime audit of minimap visibility in Darkpine Forest.

const LEVEL := "res://scenes/levels/darkpine_forest/darkpine_forest.tscn"
const OUTPUT := "res://tests/minimap_gameplay_audit.txt"

const PATHS := [
	"GameHUD",
	"GameHUD/HudRoot",
	"GameHUD/HudRoot/SafeArea",
	"GameHUD/HudRoot/SafeArea/Shell",
	"GameHUD/HudRoot/SafeArea/Shell/TopRight",
	"GameHUD/HudRoot/SafeArea/Shell/TopRight/RightSideContainer",
	"GameHUD/HudRoot/SafeArea/Shell/TopRight/RightSideContainer/MinimapPanel",
	"GameHUD/HudRoot/SafeArea/Shell/TopRight/RightSideContainer/MinimapPanel/MinimapWidget",
	"GameHUD/HudRoot/SafeArea/Shell/TopRight/RightSideContainer/MinimapPanel/MinimapWidget/MinimapFrame",
	"GameHUD/HudRoot/SafeArea/Shell/TopRight/RightSideContainer/MinimapPanel/MinimapWidget/MinimapFrame/VBox/MinimapViewport",
	"GameHUD/HudRoot/SafeArea/Shell/TopRight/RightSideContainer/MinimapPanel/MinimapWidget/MinimapFrame/VBox/MinimapViewport/MinimapCanvas",
	"GameHUD/HudRoot/SafeArea/Shell/TopRight/RightSideContainer/MinimapPanel/MinimapWidget/MinimapFrame/VBox/MinimapViewport/MarkerLayer",
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var scene := load(LEVEL) as PackedScene
	var level: Node = scene.instantiate()
	root.add_child(level)
	await process_frame
	await process_frame
	await create_timer(1.5).timeout
	var lines: PackedStringArray = []
	lines.append("=== Minimap Runtime Audit ===")
	for path in PATHS:
		var n := level.get_node_or_null(path) as Control
		if n == null:
			lines.append("[MISSING] %s" % path)
			continue
		var gr := n.get_global_rect()
		var parent_size := Vector2.ZERO
		if n.get_parent() is Control:
			parent_size = (n.get_parent() as Control).size
		lines.append("[OK] %s" % path)
		lines.append("  visible=%s is_visible_in_tree=%s modulate.a=%.2f self_modulate.a=%.2f" % [
			n.visible, n.is_visible_in_tree(), n.modulate.a, n.self_modulate.a
		])
		lines.append("  mouse_filter=%d clip_contents=%s z_index=%d top_level=%s" % [
			n.mouse_filter, n.clip_contents, n.z_index, n.top_level
		])
		lines.append("  custom_minimum_size=%s size=%s global_pos=%s global_rect=%s" % [
			n.custom_minimum_size, n.size, n.global_position, gr
		])
		lines.append("  parent_size=%s" % parent_size)
	var top := level.get_node_or_null("GameHUD/HudRoot/SafeArea/Shell/TopRight") as Control
	var panel := level.get_node_or_null("GameHUD/HudRoot/SafeArea/Shell/TopRight/RightSideContainer/MinimapPanel") as Control
	if top and panel:
		var tr := top.get_global_rect()
		var pr := panel.get_global_rect()
		lines.append("=== CLIP CHECK ===")
		lines.append("TopRight global_rect=%s" % tr)
		lines.append("MinimapPanel global_rect=%s" % pr)
		lines.append("panel_top < top_top: %s (clipped above)" % (pr.position.y < tr.position.y))
		lines.append("panel_bottom > top_bottom: %s" % (pr.end.y > tr.end.y))
	var text := "\n".join(lines)
	print(text)
	var f := FileAccess.open(OUTPUT, FileAccess.WRITE)
	if f:
		f.store_string(text)
		f.close()
	level.queue_free()
	quit()
