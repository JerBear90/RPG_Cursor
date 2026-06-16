extends Node
## HUD resource-gain notifications — driven by actual inventory grants.

signal resources_obtained(rewards: Dictionary)
signal pickup_toast(message: String)


func notify_granted(rewards: Dictionary) -> void:
	if rewards.is_empty():
		return
	resources_obtained.emit(rewards)


func show_pickup(item_id: String, amount: int = 1) -> void:
	notify_granted({item_id: amount})


func notify_player_pickup(player_index: int, item_id: String, quantity: int = 1) -> void:
	if item_id == "" or quantity <= 0:
		return
	var name := item_id.replace("_", " ").capitalize()
	pickup_toast.emit("P%d picked up %s" % [player_index + 1, name if quantity == 1 else "%s x%d" % [name, quantity]])
	notify_granted({item_id: quantity})


func notify_player_gathered(player_index: int, item_id: String, quantity: int = 1) -> void:
	if item_id == "" or quantity <= 0:
		return
	var name := item_id.replace("_", " ").capitalize()
	pickup_toast.emit("P%d gathered %s" % [player_index + 1, name if quantity == 1 else "%s x%d" % [name, quantity]])
	notify_granted({item_id: quantity})


func notify_player_currency(player_index: int, copper: int) -> void:
	if copper <= 0:
		return
	pickup_toast.emit("P%d picked up %d copper" % [player_index + 1, copper])
