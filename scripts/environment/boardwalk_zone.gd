class_name BoardwalkZone
extends Area3D
## Elevated boardwalk — removes shallow-water penalty.

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	add_to_group("boardwalk_zone")
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)


func _on_enter(body: Node3D) -> void:
	if body.has_node("EnvironmentMovementModifier"):
		(body.get_node("EnvironmentMovementModifier") as EnvironmentMovementModifier).set_boardwalk(true)


func _on_exit(body: Node3D) -> void:
	if body.has_node("EnvironmentMovementModifier"):
		(body.get_node("EnvironmentMovementModifier") as EnvironmentMovementModifier).set_boardwalk(false)
