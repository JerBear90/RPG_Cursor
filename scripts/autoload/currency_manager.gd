extends Node
## Copper / Silver / Gold wallet (shared co-op).

signal currency_changed

var copper: int = 0
var silver: int = 0
var gold: int = 0

const COPPER_PER_SILVER := 100
const SILVER_PER_GOLD := 100


func reset_for_new_game() -> void:
	copper = 50
	silver = 0
	gold = 0
	currency_changed.emit()


func add_copper(amount: int) -> void:
	copper += amount
	_normalize()
	currency_changed.emit()


func add_silver(amount: int) -> void:
	silver += amount
	_normalize()
	currency_changed.emit()


func add_gold(amount: int) -> void:
	gold += amount
	_normalize()
	currency_changed.emit()


func can_afford_copper(total_copper: int) -> bool:
	return get_total_copper() >= total_copper


func spend_copper(amount: int) -> bool:
	if not can_afford_copper(amount):
		return false
	var remaining := get_total_copper() - amount
	copper = remaining % COPPER_PER_SILVER
	silver = (remaining / COPPER_PER_SILVER) % SILVER_PER_GOLD
	gold = remaining / (COPPER_PER_SILVER * SILVER_PER_GOLD)
	currency_changed.emit()
	return true


func get_total_copper() -> int:
	return copper + silver * COPPER_PER_SILVER + gold * COPPER_PER_SILVER * SILVER_PER_GOLD


func get_display_string() -> String:
	var parts: PackedStringArray = []
	if gold > 0:
		parts.append("%d Gold" % gold)
	if silver > 0 or gold > 0:
		parts.append("%d Silver" % silver)
	parts.append("%d Copper" % copper)
	return " ".join(parts)


func _normalize() -> void:
	while copper >= COPPER_PER_SILVER:
		copper -= COPPER_PER_SILVER
		silver += 1
	while silver >= SILVER_PER_GOLD:
		silver -= SILVER_PER_GOLD
		gold += 1


func serialize() -> Dictionary:
	return {"copper": copper, "silver": silver, "gold": gold}


func deserialize(data: Dictionary) -> void:
	copper = data.get("copper", 0)
	silver = data.get("silver", 0)
	gold = data.get("gold", 0)
	currency_changed.emit()
