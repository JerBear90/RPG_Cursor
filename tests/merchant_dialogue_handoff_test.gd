extends Node
## Merchant dialogue → shop handoff using production NPC + HUD.

const NpcScene := preload("res://scenes/npcs/silent_merchant.tscn")
const HudScene := preload("res://scenes/ui/game_hud.tscn")

var _passed := 0
var _failed := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	await get_tree().process_frame
	GameManager.game_started = true
	MerchantManager.reset_for_new_game()
	InventoryManager.reset_for_new_game()
	CurrencyManager.reset_for_new_game()

	var hud: Node = HudScene.instantiate()
	add_child(hud)
	var merchant: NpcController = NpcScene.instantiate()
	add_child(merchant)
	await get_tree().process_frame

	merchant.interact(null)
	await get_tree().process_frame
	_assert(DialogueManager.is_active(), "merchant dialogue opens")
	_assert(DialogueManager.is_waiting_for_confirmation(), "merchant waits for Trade/Leave")

	await _wait_confirm_ready()
	DialogueManager.try_confirm_input()
	for _i in 15:
		await get_tree().process_frame
		if MerchantManager.is_shop_open:
			break

	_assert(not DialogueManager.is_active(), "dialogue closed after Trade")
	_assert(MerchantManager.is_shop_open, "shop opens after Trade confirm")
	_assert(DialogueManager.last_end_reason == DialogueManager.DialogueEndReason.CONFIRMED, "Trade end reason")

	var panel := _find_merchant_panel(hud)
	if panel:
		panel.call("close")
	await get_tree().process_frame

	merchant.interact(null)
	await get_tree().process_frame
	await _wait_confirm_ready()
	DialogueManager.try_cancel_input()
	for _i in 5:
		await get_tree().process_frame

	_assert(not DialogueManager.is_active(), "dialogue closed after Leave")
	_assert(not MerchantManager.is_shop_open, "shop stays closed after cancel")
	_assert(DialogueManager.last_end_reason == DialogueManager.DialogueEndReason.CANCELLED, "Leave end reason")

	print("Merchant handoff tests: %d passed, %d failed" % [_passed, _failed])
	get_tree().quit(_failed)


func _find_merchant_panel(hud: Node) -> PanelContainer:
	for child in hud.get_children():
		if child.get_script() and str(child.get_script().resource_path).ends_with("merchant_shop_panel.gd"):
			return child as PanelContainer
		var nested := _find_merchant_panel(child)
		if nested:
			return nested
	return null


func _wait_confirm_ready() -> void:
	var deadline := Time.get_ticks_msec() + 800
	while not DialogueManager.can_accept_confirm() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
