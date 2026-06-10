extends Area3D

var _copper: int = 0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(60.0).timeout.connect(queue_free)


func setup(drop: Dictionary) -> void:
	_copper = drop.get("copper", 1)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		CurrencyManager.add_copper(_copper)
		queue_free()
