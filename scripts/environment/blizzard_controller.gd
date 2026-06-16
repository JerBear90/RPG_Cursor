class_name BlizzardController
extends Node
## Staged blizzards for Frostgrave Expanse.

const _StatusEffects := preload("res://scripts/combat/status_effects_component.gd")

@export var min_interval: float = 100.0
@export var max_interval: float = 190.0
@export var storm_duration: float = 40.0

var _timer: float = 55.0
var _active: bool = false
var _env: WorldEnvironment
var _base_fog: float = 0.014


func _ready() -> void:
	add_to_group("blizzard_controller")
	_timer = randf_range(min_interval * 0.45, max_interval * 0.55)
	call_deferred("_find_environment")


func _find_environment() -> void:
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return
	_env = tree.current_scene.find_child("WorldEnvironment", true, false) as WorldEnvironment
	if _env and _env.environment:
		_base_fog = _env.environment.fog_density


func _process(delta: float) -> void:
	if GameManager.current_region_id != "frostgrave_expanse":
		return
	if DungeonManager.in_dungeon:
		if _active:
			_end_blizzard()
		return
	if _is_sheltered():
		if _active:
			_end_blizzard()
		return
	if _active:
		return
	_timer -= delta
	if _timer <= 0.0:
		_start_blizzard()


func _is_sheltered() -> bool:
	var alive := GameManager.get_alive_players()
	if alive.is_empty():
		return false
	for player in alive:
		if not player is Node3D:
			continue
		var pos := (player as Node3D).global_position
		var sheltered := pos.distance_to(Vector3.ZERO) < 16.0
		if not sheltered:
			for zone in get_tree().get_nodes_in_group("warm_shelter"):
				if zone is Node3D and pos.distance_to((zone as Node3D).global_position) < 10.0:
					sheltered = true
					break
		if not sheltered:
			return false
	return true


func _start_blizzard() -> void:
	_active = true
	_timer = storm_duration
	if _env and _env.environment:
		_env.environment.fog_density = maxf(_base_fog, 0.032)
	AudioManager.play_sfx("blizzard_wind", 0.95)
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("show_toast"):
			hud.show_toast("Blizzard approaching", 3.0, "Seek shelter at Frostwatch", "notification")
	for player in GameManager.get_alive_players():
		if player.has_node("StatusEffectsComponent"):
			(player.get_node("StatusEffectsComponent") as _StatusEffects).set_blizzard_exposure(true)


func _end_blizzard() -> void:
	_active = false
	_timer = randf_range(min_interval, max_interval)
	if _env and _env.environment:
		_env.environment.fog_density = _base_fog
	for player in GameManager.get_alive_players():
		if player.has_node("StatusEffectsComponent"):
			(player.get_node("StatusEffectsComponent") as _StatusEffects).set_blizzard_exposure(false)
