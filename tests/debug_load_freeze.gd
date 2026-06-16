extends SceneTree
## Diagnose post-load freeze: pause state, player spawn, terrain build timing.

const LEVEL := "res://scenes/levels/darkpine_forest/darkpine_forest.tscn"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var t0 := Time.get_ticks_msec()
	GameManager.start_new_game(false)
	await process_frame
	print("After start_new_game frame: paused=", paused)
	var t1 := Time.get_ticks_msec()
	for i in 120:
		await process_frame
		if i in [0, 1, 5, 30, 60, 119]:
			var player := GameManager.get_player(0)
			var terrain := get_root().find_child("IslandTerrain", true, false)
			var props := 0
			if terrain:
				var props_node = terrain.get_node_or_null("Props")
				if props_node:
					props = props_node.get_child_count()
			print(
				"frame=%d paused=%s player=%s props=%d dialogue=%s menu=%s elapsed=%dms"
				% [
					i,
					paused,
					player != null,
					props,
					DialogueManager.is_active(),
					_get_hud_menu(),
					Time.get_ticks_msec() - t1,
				]
			)
	print("TOTAL_MS=", Time.get_ticks_msec() - t0)
	quit(0)


func _get_hud_menu() -> String:
	for hud in get_root().get_nodes_in_group("game_hud"):
		if "_active_menu" in hud:
			return str(hud._active_menu)
	return ""
