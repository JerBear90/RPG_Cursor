extends SceneTree
## Boot Darkpine via start_new_game, verify unpause + player movement, save screenshot.

const OUTPUT := "res://docs/screenshots/gameplay_boot.png"


func _initialize() -> void:
	call_deferred("_run")


func _gm() -> Node:
	return get_root().get_node("GameManager")


func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 800))
	var t0 := Time.get_ticks_msec()
	_gm().start_new_game(false)
	await process_frame
	print("frame0 paused=%s game_started=%s" % [paused, _gm().game_started])
	var player: Node = null
	for i in 180:
		await process_frame
		player = _gm().get_player(0)
		if i in [0, 1, 5, 15, 30, 60, 119, 179]:
			var terrain := get_root().find_child("IslandTerrain", true, false)
			var props := 0
			if terrain:
				var props_node = terrain.get_node_or_null("Props")
				if props_node:
					props = props_node.get_child_count()
			var hud_menu := ""
			for hud in get_nodes_in_group("game_hud"):
				if "_active_menu" in hud:
					hud_menu = str(hud._active_menu)
			var pos := Vector3.ZERO
			if player and is_instance_valid(player):
				pos = player.global_position
			print(
				"frame=%d paused=%s player=%s pos=%s props=%d overlay=%s menu=%s"
				% [i, paused, player != null, pos, props, _overlay_visible(), hud_menu]
			)
	if player == null or not is_instance_valid(player):
		push_error("VERIFY_FAIL: no player spawned")
		quit(1)
		return
	var start_pos: Vector3 = player.global_position
	for _n in 45:
		var ev := InputEventKey.new()
		ev.pressed = true
		ev.physical_keycode = KEY_W
		Input.parse_input_event(ev)
		await process_frame
	var ev_up := InputEventKey.new()
	ev_up.pressed = false
	ev_up.physical_keycode = KEY_W
	Input.parse_input_event(ev_up)
	await process_frame
	await process_frame
	var end_pos: Vector3 = player.global_position
	var moved := start_pos.distance_to(end_pos)
	print("movement_delta=%.3f paused=%s" % [moved, paused])
	if paused:
		push_error("VERIFY_FAIL: tree still paused")
		quit(2)
		return
	if moved < 0.05:
		push_error("VERIFY_FAIL: player did not move (delta=%.3f)" % moved)
		quit(3)
		return
	if DisplayServer.get_name() != "headless":
		await create_timer(0.5).timeout
		var image: Image = get_root().get_viewport().get_texture().get_image()
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/screenshots"))
		var path := ProjectSettings.globalize_path(OUTPUT)
		var err: Error = image.save_png(path)
		print("Screenshot %s: %s" % ["saved" if err == OK else "failed", path])
	print("VERIFY_OK elapsed=%dms" % (Time.get_ticks_msec() - t0))
	quit(0)


func _overlay_visible() -> bool:
	for hud in get_nodes_in_group("game_hud"):
		if "_overlay" in hud and hud._overlay:
			return hud._overlay.visible
	return false
