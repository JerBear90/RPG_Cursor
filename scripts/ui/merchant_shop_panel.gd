extends PanelContainer
## Full merchant shop UI — authoritative keyboard/controller/mouse input.

signal closed

enum ShopState {
	CLOSED,
	OPENING,
	BROWSING_BUY,
	BROWSING_SELL,
	CONFIRMING_TRANSACTION,
	SHOWING_MESSAGE,
	CLOSING,
}

var state: ShopState = ShopState.CLOSED

var _npc_id: String = "silent_merchant"
var _anger_state: String = "calm"
var _price_mult: float = 1.0
var _buy_entries: Array = []
var _sell_entries: Array = []
var _row_buttons: Array[Button] = []
var _selected_index: int = 0
var _last_buy_index: int = 0
var _last_sell_index: int = 0
var _quantity: int = 1
var _buy_tab: bool = true
var _transaction_in_progress: bool = false
var _message_timer: float = 0.0

var _merchant_name: Label
var _currency_label: Label
var _tab_buy: Button
var _tab_sell: Button
var _scroll: ScrollContainer
var _rows_box: VBoxContainer
var _detail_name: Label
var _detail_type: Label
var _detail_desc: Label
var _detail_stats: Label
var _detail_compare: Label
var _detail_unit: Label
var _detail_owned: Label
var _detail_stock: Label
var _qty_label: Label
var _qty_decrease: Button
var _qty_increase: Button
var _total_label: Label
var _remaining_label: Label
var _message_label: Label
var _confirm_btn: Button
var _leave_btn: Button
var _quantity_row: HBoxContainer


func _ready() -> void:
	custom_minimum_size = Vector2(980, 560)
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	_apply_theme()
	CurrencyManager.currency_changed.connect(_update_currency)
	InventoryManager.inventory_changed.connect(_refresh_lists)


func _process(delta: float) -> void:
	if state == ShopState.SHOWING_MESSAGE and _message_timer > 0.0:
		_message_timer -= delta
		if _message_timer <= 0.0:
			_return_to_browsing()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or state == ShopState.CLOSED or state == ShopState.CLOSING:
		return
	if event.is_action_pressed("shop_cancel") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("cancel"):
		_handle_cancel()
		get_viewport().set_input_as_handled()
		return
	if state == ShopState.CONFIRMING_TRANSACTION:
		if _is_confirm_event(event):
			_execute_transaction()
			get_viewport().set_input_as_handled()
		return
	if _is_confirm_event(event):
		_on_confirm_pressed()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("shop_tab_left"):
		_switch_tab(true)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("shop_tab_right"):
		_switch_tab(false)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("shop_decrease_quantity") or event.is_action_pressed("ui_left"):
		_adjust_quantity(-1)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("shop_increase_quantity") or event.is_action_pressed("ui_right"):
		_adjust_quantity(1)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_up"):
		_move_selection(-1)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_down"):
		_move_selection(1)
		get_viewport().set_input_as_handled()
		return


func open(npc_id: String, anger_state: String = "calm") -> void:
	state = ShopState.OPENING
	_npc_id = npc_id
	_anger_state = anger_state
	_price_mult = MerchantManager.get_price_multiplier_for_anger(_anger_state) * NpcStateManager.get_relationship_price_multiplier(npc_id)
	_buy_tab = true
	_selected_index = 0
	_quantity = 1
	_transaction_in_progress = false
	MerchantManager.set_active_npc(npc_id)
	MerchantManager.notify_shop_opened(npc_id)
	_refresh_lists()
	visible = true
	state = ShopState.BROWSING_BUY
	call_deferred("_focus_current_row")
	_update_footer_prompts()


func close() -> void:
	if state == ShopState.CLOSED:
		return
	state = ShopState.CLOSING
	for btn in _row_buttons:
		btn.release_focus()
	visible = false
	MerchantManager.notify_shop_closed()
	state = ShopState.CLOSED
	closed.emit()


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	var header := HBoxContainer.new()
	root.add_child(header)
	_merchant_name = Label.new()
	_merchant_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_merchant_name)
	_currency_label = Label.new()
	_currency_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(_currency_label)

	var tabs := HBoxContainer.new()
	root.add_child(tabs)
	_tab_buy = Button.new()
	_tab_buy.text = "Buy"
	_tab_buy.pressed.connect(func() -> void: _switch_tab(true))
	tabs.add_child(_tab_buy)
	_tab_sell = Button.new()
	_tab_sell.text = "Sell"
	_tab_sell.pressed.connect(func() -> void: _switch_tab(false))
	tabs.add_child(_tab_sell)

	var main := HBoxContainer.new()
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_theme_constant_override("separation", 14)
	root.add_child(main)

	var list_panel := PanelContainer.new()
	list_panel.custom_minimum_size = Vector2(420, 280)
	list_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(list_panel)
	_scroll = ScrollContainer.new()
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list_panel.add_child(_scroll)
	_rows_box = VBoxContainer.new()
	_rows_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows_box.add_theme_constant_override("separation", 4)
	_scroll.add_child(_rows_box)

	var detail_panel := PanelContainer.new()
	detail_panel.custom_minimum_size = Vector2(480, 280)
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(detail_panel)
	var detail_v := VBoxContainer.new()
	detail_v.add_theme_constant_override("separation", 6)
	detail_panel.add_child(detail_v)
	_detail_name = Label.new()
	_detail_type = Label.new()
	_detail_desc = Label.new()
	_detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_stats = Label.new()
	_detail_compare = Label.new()
	_detail_unit = Label.new()
	_detail_owned = Label.new()
	_detail_stock = Label.new()
	for lbl in [_detail_name, _detail_type, _detail_desc, _detail_stats, _detail_compare, _detail_unit, _detail_owned, _detail_stock]:
		detail_v.add_child(lbl)

	_quantity_row = HBoxContainer.new()
	root.add_child(_quantity_row)
	_qty_decrease = Button.new()
	_qty_decrease.text = "-"
	_qty_decrease.pressed.connect(func() -> void: _adjust_quantity(-1))
	_quantity_row.add_child(_qty_decrease)
	_qty_label = Label.new()
	_qty_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_qty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_quantity_row.add_child(_qty_label)
	_qty_increase = Button.new()
	_qty_increase.text = "+"
	_qty_increase.pressed.connect(func() -> void: _adjust_quantity(1))
	_quantity_row.add_child(_qty_increase)

	var totals := HBoxContainer.new()
	root.add_child(totals)
	_total_label = Label.new()
	_total_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	totals.add_child(_total_label)
	_remaining_label = Label.new()
	_remaining_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	totals.add_child(_remaining_label)

	_message_label = Label.new()
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message_label.custom_minimum_size = Vector2(0, 36)
	root.add_child(_message_label)

	var footer := HBoxContainer.new()
	root.add_child(footer)
	_confirm_btn = Button.new()
	_confirm_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_confirm_btn.pressed.connect(_on_confirm_pressed)
	footer.add_child(_confirm_btn)
	_leave_btn = Button.new()
	_leave_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_leave_btn.pressed.connect(close)
	footer.add_child(_leave_btn)


func _apply_theme() -> void:
	add_theme_stylebox_override("panel", ArpgTheme.make_panel(UiColors.PANEL_BG_DEEP, UiColors.BORDER_BRONZE, UiMetrics.RADIUS_MD))
	ArpgTheme.style_label(_merchant_name, UiMetrics.FONT_LG, UiColors.TEXT_PRIMARY)
	ArpgTheme.style_label(_currency_label, UiMetrics.FONT_MD, UiColors.TEXT_QUEST)
	ArpgTheme.style_label(_detail_name, UiMetrics.FONT_LG, UiColors.TEXT_PRIMARY)
	ArpgTheme.style_label(_message_label, UiMetrics.FONT_SM, UiColors.TEXT_QUEST)
	_update_footer_prompts()


func _refresh_lists() -> void:
	_buy_entries = MerchantManager.get_buy_list(_npc_id, _price_mult)
	_sell_entries = []
	for entry in MerchantManager.get_sell_list(_npc_id, _price_mult):
		if InventoryManager.get_item_count(entry.item_id) > 0:
			_sell_entries.append(entry)
	_update_header()
	if _buy_tab:
		_populate_rows(_buy_entries, true)
	else:
		_populate_rows(_sell_entries, false)
	_update_tab_highlights()
	_update_selection_ui()


func _populate_rows(entries: Array, is_buy: bool) -> void:
	_row_buttons.clear()
	for c in _rows_box.get_children():
		c.queue_free()
	if entries.is_empty():
		var empty := Label.new()
		empty.text = "No items available." if is_buy else "You have no sellable items."
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_rows_box.add_child(empty)
		return
	for i in entries.size():
		var entry: Dictionary = entries[i]
		var btn := Button.new()
		btn.focus_mode = Control.FOCUS_ALL
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.text = _format_row_text(entry, is_buy)
		btn.disabled = _row_disabled(entry, is_buy)
		var idx := i
		btn.pressed.connect(func() -> void:
			_selected_index = idx
			_update_selection_ui()
			btn.grab_focus()
		)
		btn.focus_entered.connect(func() -> void:
			_selected_index = idx
			_update_selection_ui()
		)
		_rows_box.add_child(btn)
		_row_buttons.append(btn)
	var saved := _last_buy_index if is_buy else _last_sell_index
	_selected_index = clampi(saved, 0, maxi(_row_buttons.size() - 1, 0))


func _format_row_text(entry: Dictionary, is_buy: bool) -> String:
	var item_id: String = entry.item_id
	var name := ItemDatabase.get_display_name(item_id)
	var price: int = entry.price
	if is_buy:
		var stock: int = int(entry.get("stock", -1))
		var owned := InventoryManager.get_item_count(item_id)
		var stock_txt := "Unlimited" if stock < 0 else str(stock)
		return "%s  |  %d copper  |  Stock: %s  |  Owned: %d" % [name, price, stock_txt, owned]
	var qty := InventoryManager.get_item_count(item_id)
	return "%s x%d  |  %d copper each" % [name, qty, price]


func _row_disabled(entry: Dictionary, is_buy: bool) -> bool:
	var item_id: String = entry.item_id
	if is_buy:
		if int(entry.get("stock", -1)) == 0:
			return true
		return MerchantManager.get_max_buy_quantity(_npc_id, item_id, _price_mult) <= 0
	return not InventoryManager.get_sellable_quantity(item_id).get("ok", false)


func _update_header() -> void:
	_merchant_name.text = MerchantManager.get_display_name(_npc_id)
	_update_currency()


func _update_currency(_a: Variant = null) -> void:
	var suffix := "  (Prices x%.1f)" % _price_mult if _price_mult > 1.0 else ""
	_currency_label.text = CurrencyManager.get_display_string() + suffix


func _switch_tab(to_buy: bool) -> void:
	if _buy_tab == to_buy:
		return
	if _buy_tab:
		_last_buy_index = _selected_index
	else:
		_last_sell_index = _selected_index
	_buy_tab = to_buy
	state = ShopState.BROWSING_BUY if _buy_tab else ShopState.BROWSING_SELL
	_quantity = 1
	_message_label.text = ""
	_refresh_lists()
	call_deferred("_focus_current_row")


func _update_tab_highlights() -> void:
	_tab_buy.add_theme_color_override("font_color", UiColors.TEXT_QUEST if _buy_tab else UiColors.TEXT_SECONDARY)
	_tab_sell.add_theme_color_override("font_color", UiColors.TEXT_QUEST if not _buy_tab else UiColors.TEXT_SECONDARY)


func _move_selection(delta: int) -> void:
	if _row_buttons.is_empty():
		return
	_selected_index = clampi(_selected_index + delta, 0, _row_buttons.size() - 1)
	_update_selection_ui()
	_focus_current_row()


func _focus_current_row() -> void:
	if _row_buttons.is_empty():
		_leave_btn.grab_focus()
		return
	_row_buttons[_selected_index].grab_focus()


func _get_selected_entry() -> Dictionary:
	var entries := _buy_entries if _buy_tab else _sell_entries
	if _selected_index < 0 or _selected_index >= entries.size():
		return {}
	return entries[_selected_index]


func _get_selected_item_id() -> String:
	return str(_get_selected_entry().get("item_id", ""))


func _update_selection_ui() -> void:
	var item_id := _get_selected_item_id()
	if item_id == "":
		_confirm_btn.disabled = true
		return
	_quantity = clampi(_quantity, 1, _max_quantity_for_item(item_id))
	_update_detail_panel(item_id, _get_selected_entry())
	_update_totals(item_id)
	_update_row_highlights()
	_update_confirm_state(item_id)


func _max_quantity_for_item(item_id: String) -> int:
	if _buy_tab:
		return maxi(MerchantManager.get_max_buy_quantity(_npc_id, item_id, _price_mult), 1)
	return maxi(MerchantManager.get_max_sell_quantity(_npc_id, item_id), 1)


func _update_detail_panel(item_id: String, entry: Dictionary) -> void:
	_detail_name.text = ItemDatabase.get_display_name(item_id)
	_detail_type.text = ItemDatabase.get_item_type_label(item_id)
	_detail_desc.text = ItemDatabase.get_description(item_id)
	var data := ItemDatabase.get_item(item_id)
	var stats := PackedStringArray()
	if data.has("damage"):
		stats.append("Damage: %.0f" % float(data.damage))
	if data.has("health"):
		stats.append("Armor: +%.0f HP" % float(data.health))
	if data.has("amount") and data.has("use"):
		stats.append("Effect: %s %.0f" % [data.use, float(data.amount)])
	_detail_stats.text = "  ".join(stats)
	_detail_compare.text = _build_compare_text(item_id)
	_detail_unit.text = "Unit price: %d Copper" % int(entry.get("price", 0))
	_detail_owned.text = "Owned: %d" % InventoryManager.get_item_count(item_id)
	if _buy_tab:
		var stock: int = int(entry.get("stock", -1))
		_detail_stock.text = "Stock: %s" % ("Unlimited" if stock < 0 else str(stock))
	else:
		var sell_check := InventoryManager.get_sellable_quantity(item_id)
		_detail_stock.text = str(sell_check.get("reason", "Sellable: %d" % int(sell_check.get("quantity", 0))))
	_quantity_row.visible = InventoryManager._is_stackable(item_id) and _max_quantity_for_item(item_id) > 1
	_qty_label.text = "Quantity: %d" % _quantity


func _build_compare_text(item_id: String) -> String:
	if not ItemDatabase.can_equip(item_id):
		return ""
	var data := ItemDatabase.get_item(item_id)
	var slot: String = str(data.get("slot", ""))
	var equipped_id := str(InventoryManager.equipment.get(slot, ""))
	if equipped_id == "" or equipped_id == item_id:
		return ""
	if data.has("damage"):
		var delta := ItemDatabase.get_weapon_damage(item_id) - ItemDatabase.get_weapon_damage(equipped_id)
		return "Damage vs equipped: %+0.f" % delta
	if data.has("health"):
		var delta_h := ItemDatabase.get_armor_health_bonus(item_id) - ItemDatabase.get_armor_health_bonus(equipped_id)
		return "Armor vs equipped: %+0.f HP" % delta_h
	return ""


func _update_totals(item_id: String) -> void:
	var unit: int = int(_get_selected_entry().get("price", 0))
	var total := unit * _quantity
	_total_label.text = "Total: %d Copper" % total
	var after := CurrencyManager.get_total_copper() + (total if not _buy_tab else -total)
	_remaining_label.text = "After: %d Copper" % after
	_remaining_label.add_theme_color_override(
		"font_color",
		UiColors.TEXT_DANGER if _buy_tab and not CurrencyManager.can_afford_copper(total) else UiColors.TEXT_SECONDARY
	)


func _update_row_highlights() -> void:
	for i in _row_buttons.size():
		_row_buttons[i].add_theme_color_override(
			"font_color",
			UiColors.TEXT_QUEST if i == _selected_index else UiColors.TEXT_PRIMARY
		)


func _update_confirm_state(item_id: String) -> void:
	if state == ShopState.CONFIRMING_TRANSACTION or state == ShopState.SHOWING_MESSAGE:
		return
	if _buy_tab:
		var reason := MerchantManager.get_buy_disabled_reason(_npc_id, item_id, _quantity, _price_mult)
		_confirm_btn.disabled = reason != ""
		if reason != "":
			_message_label.text = reason
	else:
		var reason_s := MerchantManager.get_sell_disabled_reason(_npc_id, item_id, _quantity)
		_confirm_btn.disabled = reason_s != ""
		if reason_s != "":
			_message_label.text = reason_s


func _adjust_quantity(delta: int) -> void:
	var item_id := _get_selected_item_id()
	if item_id == "":
		return
	_quantity = clampi(_quantity + delta, 1, _max_quantity_for_item(item_id))
	_update_selection_ui()


func _on_confirm_pressed() -> void:
	if _transaction_in_progress or _confirm_btn.disabled:
		return
	if state == ShopState.CONFIRMING_TRANSACTION:
		_execute_transaction()
		return
	var item_id := _get_selected_item_id()
	if item_id == "":
		return
	state = ShopState.CONFIRMING_TRANSACTION
	var action := "Buy" if _buy_tab else "Sell"
	var total := int(_get_selected_entry().get("price", 0)) * _quantity
	_message_label.text = "%s %d %s for %d Copper?" % [
		action, _quantity, ItemDatabase.get_display_name(item_id), total
	]
	_update_footer_prompts(true)


func _execute_transaction() -> void:
	if _transaction_in_progress:
		return
	_transaction_in_progress = true
	var item_id := _get_selected_item_id()
	var result = MerchantManager.buy_item(_npc_id, item_id, _quantity, _price_mult) if _buy_tab else MerchantManager.sell_item(_npc_id, item_id, _quantity, _price_mult)
	_transaction_in_progress = false
	state = ShopState.SHOWING_MESSAGE
	_message_label.text = result.message
	_message_timer = 2.0 if result.success else 2.5
	if result.success:
		_quantity = 1
	_refresh_lists()


func _return_to_browsing() -> void:
	state = ShopState.BROWSING_BUY if _buy_tab else ShopState.BROWSING_SELL
	_message_label.text = ""
	_update_footer_prompts()
	_update_selection_ui()
	call_deferred("_focus_current_row")


func _handle_cancel() -> void:
	if state in [ShopState.CONFIRMING_TRANSACTION, ShopState.SHOWING_MESSAGE]:
		_return_to_browsing()
		return
	close()


func _is_confirm_event(event: InputEvent) -> bool:
	return event.is_action_pressed("shop_confirm") \
		or event.is_action_pressed("ui_accept") \
		or event.is_action_pressed("confirm")


func _input_hint_confirm() -> String:
	return "A" if InputManager.current_device == InputManager.DEVICE_GAMEPAD else "Enter"


func _input_hint_cancel() -> String:
	return "B" if InputManager.current_device == InputManager.DEVICE_GAMEPAD else "Esc"


func _update_footer_prompts(confirming: bool = false) -> void:
	if confirming:
		var action := "Buy" if _buy_tab else "Sell"
		_confirm_btn.text = "[%s] %s" % [_input_hint_confirm(), action]
		_leave_btn.text = "[%s] Cancel" % [_input_hint_cancel()]
		return
	var label := "Buy Selected" if _buy_tab else "Sell Selected"
	_confirm_btn.text = "[%s] %s" % [_input_hint_confirm(), label]
	_leave_btn.text = "[%s] Leave Shop" % [_input_hint_cancel()]
