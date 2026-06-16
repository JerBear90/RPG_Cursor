extends Area3D

var _copper: int = 0
var _collected: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(60.0).timeout.connect(queue_free)


func setup(drop: Dictionary) -> void:
	_copper = drop.get("copper", 1)


func _on_body_entered(body: Node3D) -> void:
	if _collected or not body.is_in_group("player"):
		return
	_collected = true
	var player_index := 0
	if body is PlayerController:
		player_index = (body as PlayerController).player_index
	CurrencyManager.add_copper(_copper)
	ResourceFeedbackManager.notify_player_currency(player_index, _copper)
	queue_free()
