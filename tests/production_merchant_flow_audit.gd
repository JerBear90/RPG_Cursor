extends Node
## Production merchant flow — Darkpine Forest, Silent Merchant, Trade opens shop.

const LEVEL_SCENE := preload("res://scenes/levels/darkpine_forest/darkpine_forest.tscn")
const OUTPUT_BUY := "res://tests/production_merchant_buy.png"
const OUTPUT_SELL := "res://tests/production_merchant_sell.png"
const OUTPUT_CONFIRM := "res://tests/production_merchant_confirm.png"
const OUTPUT_INSUFFICIENT := "res://tests/production_merchant_insufficient.png"

var _passed := 0
var _failed := 0


func _ready() -> void:
	print("=== Production Merchant Flow Audit ===")
	GameManager.game_started = true
	GameManager.active_player_count = 1
	MerchantManager.reset_for_new_game()
	InventoryManager.reset_for_new_game()
	CurrencyManager.reset_for_new_game()
	await _run_audit()
	print("Audit results: %d passed, %d failed" % [_passed, _failed])
	get_tree().quit(_failed)


func _run_audit() -> void:
	var level: Node = LEVEL_SCENE.instantiate()
	get_tree().root.call_deferred("add_child", level)
	for _i in 120:
		await get_tree().process_frame
		if level.is_inside_tree():
			break

	var merchant := level.get_node_or_null("Level/NPCs/SilentMerchant") as NpcController
	var game_hud := level.get_node_or_null("GameHUD")
	_assert(merchant != null and merchant.is_merchant, "Silent Merchant exists in Darkpine Forest")
	_assert(game_hud != null, "GameHUD exists in Darkpine Forest")

	await get_tree().create_timer(0.5).timeout

	merchant.interact(null)
	await get_tree().process_frame
	_assert(DialogueManager.is_active(), "merchant dialogue opens")
	_assert(DialogueManager.is_waiting_for_confirmation(), "merchant dialogue waits for Trade/Leave")
	var labels := DialogueManager.get_footer_labels()
	_assert(labels.confirm == "Trade", "merchant footer shows Trade")
	_assert(labels.cancel == "Leave", "merchant footer shows Leave")

	await _wait_confirm_ready()
	DialogueManager.try_confirm_input()
	for _i in 10:
		await get_tree().process_frame
		if MerchantManager.is_shop_open:
			break

	_assert(not DialogueManager.is_active(), "dialogue closes before shop")
	_assert(MerchantManager.is_shop_open, "Trade opens production shop")

	var panel: PanelContainer = _find_merchant_panel(game_hud)
	_assert(panel != null and panel.visible, "merchant shop panel visible")
	_save_screenshot(OUTPUT_BUY)

	var start_rations := InventoryManager.get_item_count("dried_rations")
	CurrencyManager.copper = 83
	var buy_idx := _index_for_item(panel, "dried_rations", true)
	panel.set("_selected_index", buy_idx)
	panel.call("_update_selection_ui")
	panel.set("_quantity", 1)
	await get_tree().process_frame
	panel.call("_on_confirm_pressed")
	await get_tree().process_frame
	_assert(panel.get("state") == 4, "buy enters confirmation")
	_save_screenshot(OUTPUT_CONFIRM)
	panel.call("_execute_transaction")
	await get_tree().process_frame
	_assert(CurrencyManager.get_total_copper() == 73, "buy 1 dried rations costs 10 copper")
	_assert(InventoryManager.get_item_count("dried_rations") == start_rations + 1, "buy adds dried rations")

	CurrencyManager.copper = 5
	panel.call("_refresh_lists")
	panel.set("_selected_index", buy_idx)
	panel.call("_update_selection_ui")
	await get_tree().process_frame
	var reason: String = MerchantManager.get_buy_disabled_reason("silent_merchant", "dried_rations", 1, 1.0)
	_assert(reason == "Not enough Copper", "insufficient copper reason")
	_save_screenshot(OUTPUT_INSUFFICIENT)

	panel.call("_switch_tab", false)
	await get_tree().process_frame
	_save_screenshot(OUTPUT_SELL)

	panel.call("close")
	await get_tree().process_frame
	_assert(not MerchantManager.is_shop_open, "shop closes cleanly")

	level.queue_free()


func _find_merchant_panel(game_hud: Node) -> PanelContainer:
	for child in game_hud.get_children():
		if child.get_script() and str(child.get_script().resource_path).ends_with("merchant_shop_panel.gd"):
			return child as PanelContainer
		var nested := _find_merchant_panel(child)
		if nested:
			return nested
	return null


func _index_for_item(panel: PanelContainer, item_id: String, buy_tab: bool) -> int:
	var key := "_buy_entries" if buy_tab else "_sell_entries"
	var entries: Array = panel.get(key)
	for i in entries.size():
		if str(entries[i].get("item_id", "")) == item_id:
			return i
	return 0


func _wait_confirm_ready() -> void:
	var deadline := Time.get_ticks_msec() + 800
	while not DialogueManager.can_accept_confirm() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame


func _save_screenshot(path: String) -> void:
	var tex := get_viewport().get_texture()
	if tex == null:
		print("Screenshot skipped (headless): %s" % path)
		return
	var img := tex.get_image()
	if img == null or img.is_empty():
		print("Screenshot skipped (empty): %s" % path)
		return
	img.save_png(ProjectSettings.globalize_path(path))
	print("Screenshot saved: %s" % path)


func _assert(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
		print("[PASS] %s" % label)
	else:
		_failed += 1
		print("[FAIL] %s" % label)
