extends Node
## Merchant shop transaction and eligibility tests.

var _passed := 0
var _failed := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	await get_tree().process_frame
	MerchantManager.reset_for_new_game()
	InventoryManager.reset_for_new_game()
	CurrencyManager.reset_for_new_game()

	_test_buy_success()
	_test_buy_insufficient()
	_test_sell_success()
	_test_sell_unsellable()
	_test_stock_limit()
	_test_double_buy_guard()
	_test_gameplay_lock_flag()

	print("Merchant shop tests: %d passed, %d failed" % [_passed, _failed])
	get_tree().quit(_failed)


func _test_buy_success() -> void:
	CurrencyManager.copper = 100
	var before := InventoryManager.get_item_count("dried_rations")
	var result := MerchantManager.buy_item("silent_merchant", "dried_rations", 1, 1.0)
	_assert(result.success, "buy success")
	_assert(InventoryManager.get_item_count("dried_rations") == before + 1, "buy adds item")
	_assert(CurrencyManager.get_total_copper() == 90, "buy subtracts currency")


func _test_buy_insufficient() -> void:
	CurrencyManager.copper = 5
	var before_c := CurrencyManager.get_total_copper()
	var before_i := InventoryManager.get_item_count("bandage")
	var result := MerchantManager.buy_item("silent_merchant", "bandage", 1, 1.0)
	_assert(not result.success, "buy blocked without copper")
	_assert(result.message == "Not enough Copper", "buy insufficient message")
	_assert(CurrencyManager.get_total_copper() == before_c, "buy fail keeps currency")
	_assert(InventoryManager.get_item_count("bandage") == before_i, "buy fail keeps inventory")


func _test_sell_success() -> void:
	CurrencyManager.copper = 50
	InventoryManager.add_item("wood", 5)
	var result := MerchantManager.sell_item("silent_merchant", "wood", 2, 1.0)
	_assert(result.success, "sell success")
	_assert(InventoryManager.get_item_count("wood") == 13, "sell removes items")
	_assert(CurrencyManager.get_total_copper() == 52, "sell adds currency")


func _test_sell_unsellable() -> void:
	InventoryManager.add_item("wolf_crest", 1)
	var result := MerchantManager.sell_item("silent_merchant", "wolf_crest", 1, 1.0)
	_assert(not result.success, "quest item not sellable")
	_assert(InventoryManager.get_item_count("wolf_crest") == 1, "quest item remains")


func _test_stock_limit() -> void:
	MerchantManager.reset_for_new_game()
	CurrencyManager.copper = 1000
	var stock_before := MerchantManager.get_stock("silent_merchant", "bandage")
	for i in stock_before:
		MerchantManager.buy_item("silent_merchant", "bandage", 1, 1.0)
	_assert(MerchantManager.get_stock("silent_merchant", "bandage") == 0, "stock reaches zero")
	var blocked := MerchantManager.buy_item("silent_merchant", "bandage", 1, 1.0)
	_assert(not blocked.success, "out of stock blocked")


func _test_double_buy_guard() -> void:
	MerchantManager.reset_for_new_game()
	CurrencyManager.copper = 100
	var count_before := InventoryManager.get_item_count("waterskin")
	var r1 := MerchantManager.buy_item("silent_merchant", "waterskin", 1, 1.0)
	var r2 := MerchantManager.buy_item("silent_merchant", "waterskin", 1, 1.0)
	_assert(r1.success and r2.success, "sequential buys work")
	_assert(InventoryManager.get_item_count("waterskin") == count_before + 2, "two items added")


func _test_gameplay_lock_flag() -> void:
	_assert(not MerchantManager.is_shop_open, "shop closed by default")
	MerchantManager.notify_shop_opened("silent_merchant")
	_assert(MerchantManager.is_shop_open, "shop open flag set")
	MerchantManager.notify_shop_closed()
	_assert(not MerchantManager.is_shop_open, "shop closed flag cleared")


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
