extends Area3D

var _item_id: String = ""
var _quantity: int = 1
var _collected: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Auto-despawn
	get_tree().create_timer(60.0).timeout.connect(queue_free)


func setup(drop: Dictionary) -> void:
	_item_id = drop.get("id", "unknown")
	_quantity = drop.get("quantity", 1)


func _on_body_entered(body: Node3D) -> void:
	if _collected or not body.is_in_group("player"):
		return
	_collected = true
	var player_index := 0
	if body is PlayerController:
		player_index = (body as PlayerController).player_index
	InventoryManager.add_item(_item_id, _quantity)
	ResourceFeedbackManager.notify_player_pickup(player_index, _item_id, _quantity)
	queue_free()
