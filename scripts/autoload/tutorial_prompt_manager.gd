extends Node
## One-time tutorial toasts — seen state persists through save/load.

const _UiInputLabels := preload("res://ui/themes/ui_input_labels.gd")

var seen: Dictionary = {}


func reset_for_new_game() -> void:
	seen.clear()


func has_seen(prompt_id: String) -> bool:
	return bool(seen.get(prompt_id, false))


func mark_seen(prompt_id: String) -> void:
	seen[prompt_id] = true


func try_show(prompt_id: String, delay_sec: float = 0.0) -> bool:
	if has_seen(prompt_id):
		return false
	var text := _prompt_text(prompt_id)
	if text == "":
		return false
	mark_seen(prompt_id)
	if delay_sec > 0.0:
		get_tree().create_timer(delay_sec).timeout.connect(func(): _display(text), CONNECT_ONE_SHOT)
	else:
		_display(text)
	return true


func try_show_delayed(prompt_id: String, delay_sec: float) -> bool:
	return try_show(prompt_id, delay_sec)


func _display(text: String) -> void:
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("show_toast"):
			hud.show_toast(text, 4.0, "", "notification", "", 0)
			return


func _dual(kb_action: String, pad_action: String = "") -> String:
	var pad := pad_action if pad_action != "" else kb_action
	var kb_label := _UiInputLabels.get_action_label(kb_action, true)
	var pad_label := _UiInputLabels.get_action_label(pad, false)
	if kb_label != "" and pad_label != "" and kb_label != pad_label:
		return "%s / %s" % [kb_label, pad_label]
	return kb_label if kb_label != "" else pad_label


func _prompt_text(prompt_id: String) -> String:
	match prompt_id:
		"movement":
			return "Move with WASD / Left Stick"
		"camera":
			return "Look with Mouse / Right Stick"
		"interact":
			return "Press %s to Interact" % _dual("interact")
		"combat":
			return "Attack with %s" % _dual("light_attack")
		"heavy_attack":
			return "Heavy Attack with %s" % _dual("heavy_attack")
		"dodge":
			return "Dodge with %s" % _dual("dodge")
		"block":
			return "Block with %s" % _dual("block")
		"gather":
			return "Gather resources from highlighted nodes"
		"destructible":
			return "Break crates and scrap piles for materials"
		"inventory":
			return "Open Inventory to view gear and resources (%s)" % _dual("open_inventory")
		"crafting":
			return "Use the Workbench to craft and repair"
		"quest_tracker":
			return "Track missions from the quest screen"
		"map":
			return "Open the map to find objectives and Waystones (%s)" % _dual("open_map")
		"waystone":
			return "Activate Waystones to travel between discovered locations"
		"camp_rest":
			return "Rest at camps to recover and revive allies"
		"coop_revive":
			return "Hold %s near a downed ally to revive them" % _dual("interact")
		"pet":
			return "Use the Pet Shelter to adopt and manage your companion"
		"spellcasting":
			return "Cast selected spell with %s" % _dual("quick_spell")
		_:
			return ""


func serialize() -> Dictionary:
	return {"seen": seen.duplicate()}


func deserialize(data: Dictionary) -> void:
	seen = data.get("seen", {})
