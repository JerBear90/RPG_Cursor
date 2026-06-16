class_name DeepWaterBlocker
extends StaticBody3D
## Impassable deep-water volume with visible collision — not valid for spawns.

func _ready() -> void:
	collision_layer = 1
	collision_mask = 6
	add_to_group("deep_water")
