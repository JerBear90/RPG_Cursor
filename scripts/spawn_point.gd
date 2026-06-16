class_name SpawnMarker
extends Marker3D
## Named spawn location with restart metadata and facing direction.

enum MarkerType {
	PLAYER_SPAWN,
	REGION_START_SPAWN,
	TOWN_SPAWN,
	SETTLEMENT_SPAWN,
	CAMP_SPAWN,
	CHECKPOINT_SPAWN,
	DUNGEON_ENTRY_SPAWN,
	DUNGEON_CHECKPOINT_SPAWN,
	DUNGEON_EXIT_SPAWN,
	EXTERIOR_RETURN_SPAWN,
	BOSS_CHECKPOINT_SPAWN,
	FAST_TRAVEL_SPAWN,
	TRANSITION_ARRIVAL_SPAWN,
}

@export var spawn_id: String = "default"
@export var marker_type: MarkerType = MarkerType.PLAYER_SPAWN
@export var region_id: String = ""
@export var town_id: String = ""
@export var dungeon_id: String = ""
@export var clear_radius: float = 4.0
@export var priority: int = 0
@export var checkpoint_id: String = ""
@export var transition_id: String = ""
@export var entrance_id: String = ""


func _ready() -> void:
	add_to_group("spawn_points")
	add_to_group("spawn_markers")


func get_spawn_id() -> String:
	return spawn_id


func get_facing_yaw() -> float:
	return rotation.y


const DEFAULT_CLEAR_RADIUS := {
	MarkerType.TOWN_SPAWN: 5.0,
	MarkerType.SETTLEMENT_SPAWN: 5.0,
	MarkerType.REGION_START_SPAWN: 6.5,
	MarkerType.CAMP_SPAWN: 4.0,
	MarkerType.CHECKPOINT_SPAWN: 4.0,
	MarkerType.DUNGEON_ENTRY_SPAWN: 3.5,
	MarkerType.DUNGEON_CHECKPOINT_SPAWN: 4.0,
	MarkerType.DUNGEON_EXIT_SPAWN: 4.0,
	MarkerType.EXTERIOR_RETURN_SPAWN: 4.0,
	MarkerType.BOSS_CHECKPOINT_SPAWN: 5.0,
	MarkerType.FAST_TRAVEL_SPAWN: 5.0,
	MarkerType.TRANSITION_ARRIVAL_SPAWN: 5.0,
	MarkerType.PLAYER_SPAWN: 4.0,
}


func get_clear_radius() -> float:
	if clear_radius > 0.0:
		return clear_radius
	return DEFAULT_CLEAR_RADIUS.get(marker_type, 4.0)


static func create_runtime(
	parent: Node3D,
	id: String,
	mtype: MarkerType,
	pos: Vector3,
	yaw_deg: float = 0.0,
	region: String = "",
	radius: float = 4.0
) -> Marker3D:
	var marker: Marker3D = load("res://scripts/spawn_point.gd").new()
	marker.name = id
	marker.spawn_id = id
	marker.marker_type = mtype
	marker.region_id = region
	marker.clear_radius = radius
	marker.position = pos
	marker.rotation_degrees.y = yaw_deg
	parent.add_child(marker)
	return marker
