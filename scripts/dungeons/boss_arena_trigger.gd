class_name BossArenaTrigger
extends Area3D
## Starts a boss encounter when the player enters the arena.

const _SpawnHelpers := preload("res://scripts/utilities/spawn_helpers.gd")

var boss: Node = null
var _triggered: bool = false
var _players_seen: Dictionary = {}


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if _triggered or not body.is_in_group("player"):
		return
	var idx := 0
	if body is PlayerController:
		idx = (body as PlayerController).player_index
	_players_seen[idx] = true
	if GameManager.is_local_coop():
		_pull_lagging_companion(body as Node3D)
		for i in GameManager.active_player_count:
			if not _players_seen.get(i, false):
				return
	_triggered = true
	if boss and is_instance_valid(boss) and boss.has_method("begin_encounter"):
		boss.begin_encounter()


func _pull_lagging_companion(leader: Node3D) -> void:
	if leader == null or not is_instance_valid(leader):
		return
	var companion := GameManager.get_player(1)
	if companion == null or not is_instance_valid(companion) or companion == leader:
		return
	if companion.has_method("is_alive") and not companion.is_alive():
		return
	var arena_pos := global_position
	if companion.global_position.distance_to(arena_pos) > 10.0:
		var yaw := leader.rotation.y if leader is Node3D else 0.0
		var offset := _SpawnHelpers.get_party_offset(1, yaw)
		companion.global_position = leader.global_position + offset
		if companion is CharacterBody3D:
			(companion as CharacterBody3D).velocity = Vector3.ZERO
		_players_seen[1] = true
