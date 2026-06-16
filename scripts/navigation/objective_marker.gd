class_name ObjectiveMarker
extends Node3D
## Optional world marker — auto-registers as quest destination.

@export var marker_id: String = ""
@export var display_name: String = ""
@export var target_type: String = "generic"
@export var region_id: String = ""


func _ready() -> void:
	add_to_group("quest_destination")
	add_to_group("objective_marker")
	if region_id == "":
		region_id = GameManager.current_region_id
