extends Node
## Shared NPC relationship, anger, and service state — persisted across saves.

signal relationship_changed(npc_id: String)
signal anger_changed(npc_id: String, anger_state: String)

const ANGER_ORDER: Array[String] = ["calm", "annoyed", "angry", "hostile"]
const FINE_COSTS: Dictionary = {"annoyed": 25, "angry": 50, "hostile": 100}
const GIFT_ITEMS: Dictionary = {
	"herb_bundle": 1, "bandage": 1, "pet_treat": 1, "dried_rations": 1,
	"repair_kit": 1, "gem_ruby": 1, "gem_sapphire": 1, "gem_emerald": 1,
}

var _states: Dictionary = {}


func reset_for_new_game() -> void:
	_states.clear()


func _default_state() -> Dictionary:
	return {"relationship": 1, "anger": "calm", "rewards_claimed": []}


func get_state(npc_id: String) -> Dictionary:
	if not _states.has(npc_id):
		_states[npc_id] = _default_state()
	return _states[npc_id]


func get_anger(npc_id: String) -> String:
	return str(get_state(npc_id).get("anger", "calm"))


func set_anger(npc_id: String, anger: String) -> void:
	var st := get_state(npc_id)
	st.anger = anger
	anger_changed.emit(npc_id, anger)


func get_relationship_score(npc_id: String) -> int:
	return int(get_state(npc_id).get("relationship", 1))


func get_relationship_label(npc_id: String) -> String:
	var score := get_relationship_score(npc_id)
	if get_anger(npc_id) in ["angry", "hostile"]:
		return "Angry" if get_anger(npc_id) == "angry" else "Hostile"
	match score:
		-2, -1: return "Hostile"
		0: return "Wary"
		1: return "Neutral"
		2: return "Friendly"
		_: return "Trusted"


func adjust_relationship(npc_id: String, delta: int) -> void:
	var st := get_state(npc_id)
	st.relationship = clampi(int(st.relationship) + delta, -2, 3)
	relationship_changed.emit(npc_id)


func on_npc_hit(npc_id: String, _player_index: int = 0) -> String:
	var anger := get_anger(npc_id)
	var msg := ""
	match anger:
		"calm":
			set_anger(npc_id, "annoyed")
			msg = "Oi! Swing that thing at me again and I'll charge you double."
		"annoyed":
			set_anger(npc_id, "angry")
			msg = "You trying to kill me or just embarrass yourself?"
		"angry":
			set_anger(npc_id, "hostile")
			msg = "We're done talking until you make this right."
		_:
			msg = "You wanted a fight. Now you've got one."
	return msg


func can_use_service(npc_id: String) -> bool:
	if get_anger(npc_id) == "hostile":
		return false
	return true


func get_service_block_reason(npc_id: String) -> String:
	if get_anger(npc_id) == "hostile":
		return "Service unavailable: NPC is angry"
	if get_anger(npc_id) == "angry":
		return "Angry — Pay Fine or Offer Gift"
	return ""


func get_price_multiplier(npc_id: String, base_anger: String = "") -> float:
	var anger := base_anger if base_anger != "" else get_anger(npc_id)
	var mult := 1.0
	match anger:
		"annoyed": mult = 1.25
		"angry", "hostile": mult = 1.5
	var rel := get_relationship_score(npc_id)
	if rel >= 3:
		mult *= 0.85
	elif rel >= 2:
		mult *= 0.9
	return mult


func get_repair_discount(npc_id: String) -> float:
	if get_relationship_score(npc_id) >= 2 and get_anger(npc_id) == "calm":
		return 0.1
	return 0.0


func get_relationship_price_multiplier(npc_id: String) -> float:
	if get_anger(npc_id) != "calm":
		return 1.0
	var rel := get_relationship_score(npc_id)
	if rel >= 3:
		return 0.85
	if rel >= 2:
		return 0.9
	return 1.0


func try_pay_fine(npc_id: String) -> Dictionary:
	var anger := get_anger(npc_id)
	if anger == "calm":
		return {"ok": false, "reason": "No fine owed"}
	var cost := int(FINE_COSTS.get(anger, 50))
	if not CurrencyManager.can_afford_copper(cost):
		if cost >= 100:
			return {"ok": false, "reason": "Need 1 Silver to pay fine"}
		return {"ok": false, "reason": "Need %d Copper to pay fine" % cost}
	if not CurrencyManager.spend_copper(cost):
		return {"ok": false, "reason": "Not enough currency"}
	if anger == "hostile":
		set_anger(npc_id, "angry")
	else:
		set_anger(npc_id, "calm")
	adjust_relationship(npc_id, 1)
	_notify("Relationship repaired")
	_notify("Paid fine: %d Copper" % cost)
	return {"ok": true, "reason": ""}


func try_gift(npc_id: String, item_id: String) -> Dictionary:
	if get_anger(npc_id) == "calm":
		return {"ok": false, "reason": "Gift not needed"}
	if item_id not in GIFT_ITEMS:
		return {"ok": false, "reason": "Gift refused"}
	if not InventoryManager.has_item(item_id):
		return {"ok": false, "reason": "Missing %s" % ItemDatabase.get_display_name(item_id)}
	if not InventoryManager.remove_item(item_id, 1):
		return {"ok": false, "reason": "Missing item"}
	var anger := get_anger(npc_id)
	if anger == "hostile":
		set_anger(npc_id, "annoyed")
	elif anger == "annoyed":
		set_anger(npc_id, "calm")
	else:
		set_anger(npc_id, "calm")
	adjust_relationship(npc_id, 1)
	_notify("Gift accepted")
	return {"ok": true, "reason": ""}


func on_mission_completed(npc_id: String) -> void:
	adjust_relationship(npc_id, 1)
	if get_anger(npc_id) == "annoyed":
		set_anger(npc_id, "calm")


func serialize() -> Dictionary:
	return _states.duplicate(true)


func deserialize(data: Dictionary) -> void:
	_states = data.duplicate(true)


func _notify(message: String) -> void:
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("show_toast"):
			hud.show_toast(message, 2.5)
			return
