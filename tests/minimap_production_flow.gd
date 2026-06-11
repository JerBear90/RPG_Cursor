extends SceneTree
## Production-path smoke test: main menu -> Solo New Game -> Darkpine Forest.

const MAIN_MENU := "res://scenes/main_menu/main_menu.tscn"
const OUTPUT := "res://tests/minimap_production_flow_1920.png"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var win := Window.new()
	win.size = Vector2i(1920, 1080)
	win.title = "Exiled Survivors"
	root.add_child(win)
	await process_frame
	var menu_scene := load(MAIN_MENU) as PackedScene
	win.add_child(menu_scene.instantiate())
	await process_frame
	await process_frame
	print("PRODUCTION FLOW: main menu loaded")
	print("PROJECT PATH: ", ProjectSettings.globalize_path("res://"))
	var gm := root.get_node("GameManager")
	gm.call("start_new_game", false)
	await process_frame
	await process_frame
	await create_timer(3.0).timeout
	var current: Node = current_scene
	print("PRODUCTION FLOW: current_scene=", current.scene_file_path if current else "none")
	var hud := current.get_node_or_null("GameHUD") if current else null
	var panel = null
	if hud:
		panel = hud.get_node_or_null("HudRoot/SafeArea/Shell/TopRight/RightSideContainer/MinimapPanel")
		print("PRODUCTION FLOW: minimap_panel visible=", panel.visible if panel else "missing")
	var img := win.get_viewport().get_texture().get_image()
	if img:
		img.save_png(ProjectSettings.globalize_path(OUTPUT))
		print("Saved ", OUTPUT)
	quit()
