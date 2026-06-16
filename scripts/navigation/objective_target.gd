class_name ObjectiveTarget
extends RefCounted
## Resolved world target for a quest objective.

var target_id: String = ""
var display_name: String = ""
var target_type: String = "generic"
var region_id: String = ""
var world_position: Vector3 = Vector3.ZERO
var is_available: bool = true
var is_completed: bool = false
var related_mission_id: String = ""
var related_objective_id: String = ""
var region_hint: String = ""
var has_world_position: bool = false


func to_dict() -> Dictionary:
	return {
		"target_id": target_id,
		"display_name": display_name,
		"target_type": target_type,
		"region_id": region_id,
		"world_position": world_position,
		"is_available": is_available,
		"is_completed": is_completed,
		"related_mission_id": related_mission_id,
		"related_objective_id": related_objective_id,
		"region_hint": region_hint,
		"has_world_position": has_world_position,
	}
