class_name LevelRestartContext
extends RefCounted
## Captured level state used to choose a context-specific restart marker.

enum LocationType {
	OUTDOOR_REGION,
	TOWN,
	SETTLEMENT,
	CAMP,
	DUNGEON,
	BOSS_ARENA,
	DUNGEON_EXTERIOR,
	INTERIOR,
	REGION_TRANSITION,
	FAST_TRAVEL_DESTINATION,
}

var level_scene_path: String = ""
var level_id: StringName = &""
var region_id: StringName = &""
var town_id: StringName = &""
var dungeon_id: StringName = &""
var region_seed: int = 0
var dungeon_seed: int = 0
var checkpoint_id: StringName = &""
var camp_id: StringName = &""
var waystone_id: StringName = &""
var entry_transition_id: StringName = &""
var entry_spawn_id: StringName = &""
var exterior_entrance_id: StringName = &""
var last_safe_position: Vector3 = Vector3.ZERO
var location_type: LocationType = LocationType.OUTDOOR_REGION
var inside_dungeon: bool = false
var inside_town: bool = false
var in_boss_encounter: bool = false
var dungeon_checkpoint_room: int = -1
var restore_needs: bool = true
var copper_penalty: int = 0
var death_message: String = ""
var preferred_spawn_ids: PackedStringArray = PackedStringArray()


func duplicate_context():
	var copy = load("res://scripts/levels/level_restart_context.gd").new()
	copy.level_scene_path = level_scene_path
	copy.level_id = level_id
	copy.region_id = region_id
	copy.town_id = town_id
	copy.dungeon_id = dungeon_id
	copy.region_seed = region_seed
	copy.dungeon_seed = dungeon_seed
	copy.checkpoint_id = checkpoint_id
	copy.camp_id = camp_id
	copy.waystone_id = waystone_id
	copy.entry_transition_id = entry_transition_id
	copy.entry_spawn_id = entry_spawn_id
	copy.exterior_entrance_id = exterior_entrance_id
	copy.last_safe_position = last_safe_position
	copy.location_type = location_type
	copy.inside_dungeon = inside_dungeon
	copy.inside_town = inside_town
	copy.in_boss_encounter = in_boss_encounter
	copy.dungeon_checkpoint_room = dungeon_checkpoint_room
	copy.restore_needs = restore_needs
	copy.copper_penalty = copper_penalty
	copy.death_message = death_message
	copy.preferred_spawn_ids = preferred_spawn_ids.duplicate()
	return copy
