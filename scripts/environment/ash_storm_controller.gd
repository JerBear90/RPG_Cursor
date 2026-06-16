class_name AshStormController
extends Node
## Staged ash storms for Ashfall Highlands — not active indoors or in dungeons.

@export var min_interval: float = 90.0
@export var max_interval: float = 180.0
@export var storm_duration: float = 35.0

var _timer: float = 45.0
var _active: bool = false
var _env: WorldEnvironment


func _ready() -> void:
	add_to_group("ash_storm_controller")
	_timer = randf_range(min_interval * 0.5, max_interval * 0.5)
	call_deferred("_find_environment")


func _find_environment() -> void:
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return
	_env = tree.current_scene.find_child("WorldEnvironment", true, false) as WorldEnvironment


func _process(delta: float) -> void:
	if GameManager.current_region_id != "ashfall_highlands":
		return
	if DungeonManager.in_dungeon:
		if _active:
			_end_storm()
		return
	if _is_sheltered():
		if _active:
			_end_storm()
		return
	if _active:
		return
	_timer -= delta
	if _timer <= 0.0:
		_start_storm()


func _is_sheltered() -> bool:
	var player := GameManager.get_player(0)
	if player == null:
		return false
	var pos := player.global_position
	if pos.distance_to(Vector3.ZERO) < 14.0:
		return true
	for zone in get_tree().get_nodes_in_group("storm_shelter"):
		if zone is Node3D and pos.distance_to((zone as Node3D).global_position) < 8.0:
			return true
	return false


func _start_storm() -> void:
	_active = true
	_timer = storm_duration
	AudioManager.play_sfx("footstep")
	if _env and _env.environment:
		_env.environment.fog_density = maxf(_env.environment.fog_density, 0.028)
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("show_toast"):
			hud.show_toast("Ash storm approaching", 3.0, "Seek shelter at Stonewatch", "notification")
	for player in GameManager.get_alive_players():
		if player.has_node("StatusEffectsComponent"):
			(player.get_node("StatusEffectsComponent") as StatusEffectsComponent).set_ash_storm_exposure(true)


func _end_storm() -> void:
	_active = false
	_timer = randf_range(min_interval, max_interval)
	if _env and _env.environment:
		_env.environment.fog_density = 0.012
	for player in GameManager.get_alive_players():
		if player.has_node("StatusEffectsComponent"):
			(player.get_node("StatusEffectsComponent") as StatusEffectsComponent).set_ash_storm_exposure(false)
