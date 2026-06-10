extends Marker3D
## Named spawn location for scene transitions and waystones.

@export var spawn_id: String = "default"


func _ready() -> void:
	add_to_group("spawn_points")


func get_spawn_id() -> String:
	return spawn_id
