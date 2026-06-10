extends PanelContainer
## Buy/sell merchant shop with tabbed lists.

signal closed

var _npc_id: String = "silent_merchant"
var _anger_state: String = "calm"
var _tab_buy: Button
var _tab_sell: Button
var _buy_list: ItemList
var _sell_list: ItemList
var _header_label: Label
var _detail_label: Label
var _buy_btn: Button
var _sell_btn: Button
var _showing_buy: bool = true


func _ready() -> void:
	custom_minimum_size = Vector2(640, 440)
	_build_ui()
	CurrencyManager.currency_changed.connect(_update_header)


func open(npc_id: String, anger_state: String = "calm") -> void:
	_npc_id = npc_id
	_anger_state = anger_state
	MerchantManager.set_active_npc(npc_id)
	_refresh()
	visible = true


func close() -> void:
	visible = false
	closed.emit()


func _build_ui() -> void:
	var root := VBoxContainer.new()
	add_child(root)
	_header_label = Label.new()
	_header_label.add_theme_font_size_override("font_size", 22)
	root.add_child(_header_label)
	var tabs := HBoxContainer.new()
	root.add_child(tabs)
	_tab_buy = Button.new()
	_tab_buy.text = "Buy"
	_tab_buy.pressed.connect(_show_buy_tab)
	tabs.add_child(_tab_buy)
	_tab_sell = Button.new()
	_tab_sell.text = "Sell"
	_tab_sell.pressed.connect(_show_sell_tab)
	tabs.add_child(_tab_sell)
	_buy_list = ItemList.new()
	_buy_list.custom_minimum_size = Vector2(600, 220)
	_buy_list.item_selected.connect(_on_buy_selected)
	root.add_child(_buy_list)
	_sell_list = ItemList.new()
	_sell_list.custom_minimum_size = Vector2(600, 220)
	_sell_list.visible = false
	_sell_list.item_selected.connect(_on_sell_selected)
	root.add_child(_sell_list)
	_detail_label = Label.new()
	_detail_label.custom_minimum_size = Vector2(0, 40)
	root.add_child(_detail_label)
	var actions := HBoxContainer.new()
	root.add_child(actions)
	_buy_btn = Button.new()
	_buy_btn.text = "Buy Selected"
	_buy_btn.pressed.connect(_on_buy_pressed)
	actions.add_child(_buy_btn)
	_sell_btn = Button.new()
	_sell_btn.text = "Sell x1"
	_sell_btn.pressed.connect(_on_sell_pressed)
	actions.add_child(_sell_btn)
	var close_btn := Button.new()
	close_btn.text = "Leave Shop"
	close_btn.pressed.connect(close)
	actions.add_child(close_btn)


func _show_buy_tab() -> void:
	_showing_buy = true
	_buy_list.visible = true
	_sell_list.visible = false
	_buy_btn.visible = true
	_sell_btn.visible = false


func _show_sell_tab() -> void:
	_showing_buy = false
	_buy_list.visible = false
	_sell_list.visible = true
	_buy_btn.visible = false
	_sell_btn.visible = true


func _update_header() -> void:
	var mult := MerchantManager.get_price_multiplier_for_anger(_anger_state)
	var anger_note := ""
	if mult > 1.0:
		anger_note = "  (Prices x%.1f — merchant is %s)" % [mult, _anger_state]
	_header_label.text = "%s  |  %s%s" % [
		MerchantManager.get_display_name(_npc_id),
		CurrencyManager.get_display_string(),
		anger_note,
	]


func _refresh() -> void:
	_update_header()
	_buy_list.clear()
	_sell_list.clear()
	var mult := MerchantManager.get_price_multiplier_for_anger(_anger_state)
	for entry in MerchantManager.get_buy_list(_npc_id, mult):
		var idx := _buy_list.add_item("%s — %d copper" % [
			entry.item_id.replace("_", " ").capitalize(), entry.price,
		])
		_buy_list.set_item_metadata(idx, entry)
	for entry in MerchantManager.get_sell_list(_npc_id, mult):
		var qty := InventoryManager.get_item_count(entry.item_id)
		if qty <= 0:
			continue
		var sidx := _sell_list.add_item("%s x%d — %d copper each" % [
			entry.item_id.replace("_", " ").capitalize(), qty, entry.price,
		])
		_sell_list.set_item_metadata(sidx, entry)
	_show_buy_tab()


func _on_buy_selected(index: int) -> void:
	var meta: Variant = _buy_list.get_item_metadata(index)
	if meta is Dictionary:
		_detail_label.text = "Buy %s for %d copper" % [meta.item_id, meta.price]


func _on_sell_selected(index: int) -> void:
	var meta: Variant = _sell_list.get_item_metadata(index)
	if meta is Dictionary:
		_detail_label.text = "Sell 1x %s for %d copper" % [meta.item_id, meta.price]


func _on_buy_pressed() -> void:
	var sel := _buy_list.get_selected_items()
	if sel.is_empty():
		return
	var meta: Dictionary = _buy_list.get_item_metadata(sel[0])
	if CurrencyManager.spend_copper(int(meta.price)):
		InventoryManager.add_item(meta.item_id, 1)
		_refresh()


func _on_sell_pressed() -> void:
	var sel := _sell_list.get_selected_items()
	if sel.is_empty():
		return
	var meta: Dictionary = _sell_list.get_item_metadata(sel[0])
	if InventoryManager.remove_item(meta.item_id, 1):
		CurrencyManager.add_copper(int(meta.price))
		_refresh()
