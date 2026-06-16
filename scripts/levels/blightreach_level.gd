extends Node3D
## Blightreach placeholder region.

const REGION_ID := "blightreach"


func _ready() -> void:
	GameManager.set_region(REGION_ID)
	WorldStateManager.set_region(REGION_ID)
	MapManager.discover_region(REGION_ID)
