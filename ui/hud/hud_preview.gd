extends Control
## Standalone HUD showcase — F6 this scene only. Does not affect gameplay.

func _ready() -> void:
	var hud := get_node_or_null("PlayerHud") as PlayerHud
	if hud == null:
		return
	await get_tree().process_frame
	await get_tree().process_frame
	_seed_showcase(hud)


func _seed_showcase(hud: PlayerHud) -> void:
	hud.set_hp_values(68, 100)
	hud.set_stamina_values(72, 100)
	hud.set_mp_values(24, 50)
	hud.set_level(7)
	hud.set_xp_values(3500, 7000)
	hud.update_quest(
		"Ashes Beneath Darkpine",
		PackedStringArray(["Investigate the corrupted grove", " (2/5)"]),
		"148 m",
		"MAIN QUEST"
	)
	hud.show_toast("Quest complete:", 4.0, "First Blood - (+15 copper)", "notification")
	hud.set_skill_highlight(2, true)
	hud.set_slot_cooldown(2, 0.45, 2.3)
	hud.set_slot_locked(4, true)
	var region := hud.get_node_or_null("%RegionLabel") as Label
	if region:
		region.text = "Darkpine Forest"
	var currency := hud.get_node_or_null("%CurrencyLabel") as Label
	if currency:
		currency.text = "50 Copper"
	# Showcase interaction styling only — gameplay hides until interactable.
	hud.set_interact_prompt("E: Search Body")
	var minimap_panel := hud.get_node_or_null("%MinimapPanel") as Control
	if minimap_panel:
		minimap_panel.visible = true
	var minimap := hud.get_node_or_null("%MinimapWidget") as Minimap
	if minimap:
		var player := Node3D.new()
		player.name = "PreviewPlayer"
		player.add_to_group("player")
		hud.add_child(player)
		minimap.bind_player(player)
		minimap.refresh_landmarks()
		MapManager.set_waypoint(Vector3(0, 0, 22), "Far Point")
