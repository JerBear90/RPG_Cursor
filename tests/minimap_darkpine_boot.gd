extends SceneTree
## Boot Darkpine Forest and verify minimap wiring without gameplay changes.

const LEVEL := "res://scenes/levels/darkpine_forest/darkpine_forest.tscn"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var scene := load(LEVEL) as PackedScene
	var level: Node = scene.instantiate()
	root.add_child(level)
	await process_frame
	await process_frame
	await create_timer(1.0).timeout
	var hud := level.get_node_or_null("GameHUD")
	var minimap = null
	if hud:
		minimap = hud.get_node_or_null("HudRoot/SafeArea/Shell/TopRight/RightSideContainer/MinimapPanel/MinimapWidget")
	var ok := hud != null and minimap != null
	print("[", "PASS" if ok else "FAIL", "] Darkpine minimap wiring hud=", hud != null, " minimap=", minimap != null)
	level.queue_free()
	quit(0 if ok else 1)
