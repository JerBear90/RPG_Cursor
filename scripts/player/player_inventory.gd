extends Node
## Per-player quick-item and consumable shortcuts.

var _player: PlayerController

const HEAL_ITEMS: Array[String] = ["bandage", "dried_rations", "herb_bundle", "purified_water"]
const DRINK_ITEMS: Array[String] = ["waterskin", "purified_water"]


func _ready() -> void:
	_player = get_parent() as PlayerController


func _process(_delta: float) -> void:
	if _player == null or not _player.is_alive():
		return
	var idx := _player.player_index
	if InputManager.is_action_just_pressed("quick_heal", idx):
		_try_quick_heal()
	if InputManager.is_action_just_pressed("use_quick_item", idx):
		_try_quick_consume()


func _try_quick_heal() -> void:
	for item_id in HEAL_ITEMS:
		if InventoryManager.has_item(item_id) and InventoryManager.use_item(item_id, _player):
			AudioManager.play_sfx("heal")
			return


func _try_quick_consume() -> void:
	if InventoryManager.has_item("dried_rations") and InventoryManager.use_item("dried_rations", _player):
		AudioManager.play_sfx("eat")
		return
	for item_id in DRINK_ITEMS:
		if InventoryManager.has_item(item_id) and InventoryManager.use_item(item_id, _player):
			AudioManager.play_sfx("drink")
			return
