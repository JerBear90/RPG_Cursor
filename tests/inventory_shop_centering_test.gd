extends Node
## Verify inventory panel is centered at common resolutions.

const HudScene := preload("res://scenes/ui/game_hud.tscn")
const PlayerScene := preload("res://scenes/player/player.tscn")

var _passed := 0
var _failed := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	await get_tree().process_frame
	GameManager.game_started = true
	var sizes := [
		Vector2i(1280, 720),
		Vector2i(1920, 1080),
		Vector2i(2560, 1440),
		Vector2i(3440, 1440),
	]
	for size in sizes:
		await _assert_centered_at(size)
	print("Inventory centering tests: %d passed, %d failed" % [_passed, _failed])
	get_tree().quit(_failed)


func _assert_centered_at(viewport_size: Vector2i) -> void:
	get_tree().root.size = viewport_size
	await get_tree().process_frame

	var hud: Node = HudScene.instantiate()
	add_child(hud)
	var player: Node = PlayerScene.instantiate()
	add_child(player)
	await get_tree().process_frame

	if hud.has_method("bind_production_player"):
		hud.bind_production_player(player)
	await get_tree().process_frame

	hud._open_inventory_panel()
	await get_tree().process_frame

	var panel := _find_panel(hud)
	_assert(panel != null and panel.visible, "inventory visible at %dx%d" % [viewport_size.x, viewport_size.y])
	if panel == null:
		hud.queue_free()
		player.queue_free()
		return

	var rect := panel.get_global_rect()
	var view := get_viewport().get_visible_rect()
	var panel_center := rect.get_center()
	var view_center := view.get_center()
	var tolerance_x := maxf(8.0, view.size.x * 0.01)
	_assert(
		absf(panel_center.x - view_center.x) <= tolerance_x,
		"horizontal center at %dx%d (delta %.1f)" % [viewport_size.x, viewport_size.y, panel_center.x - view_center.x]
	)
	_assert(rect.position.x >= UiMetrics.SPACE_SAFE - 1.0, "left safe margin at %dx%d" % [viewport_size.x, viewport_size.y])
	_assert(
		rect.position.x + rect.size.x <= view.size.x - UiMetrics.SPACE_SAFE + 1.0,
		"right safe margin at %dx%d" % [viewport_size.x, viewport_size.y]
	)

	panel.call("close")
	hud.queue_free()
	player.queue_free()
	await get_tree().process_frame


func _find_panel(node: Node) -> PanelContainer:
	for child in node.get_children():
		if child.get_script() and str(child.get_script().resource_path).ends_with("inventory_panel.gd"):
			return child as PanelContainer
		var nested := _find_panel(child)
		if nested:
			return nested
	return null


func _assert(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		push_error("FAIL: %s" % label)
