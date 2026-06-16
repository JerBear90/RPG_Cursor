class_name ShopTransactionResult
extends RefCounted
## Result of a merchant buy or sell transaction.

var success: bool = false
var message: String = ""
var item_id: StringName = &""
var quantity: int = 0
var unit_price: int = 0
var total_price: int = 0
var currency_before: int = 0
var currency_after: int = 0
var is_buy: bool = true
