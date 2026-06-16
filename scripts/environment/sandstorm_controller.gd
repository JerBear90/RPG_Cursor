class_name SandstormController
extends Node
## Staged sandstorms for Ember Wastes.

const _StatusEffects := preload("res://scripts/combat/status_effects_component.gd")

enum WeatherStage { CLEAR, LIGHT_DUST, HEAVY_WIND, SEVERE_SANDSTORM, CLEARING }

@export var min_interval: float = 80.0
@export var max_interval: float = 160.0
@export var storm_duration: float = 45.0

var _timer: float = 40.0
var _stage: WeatherStage = WeatherStage.CLEAR
var _env: WorldEnvironment
var _base_fog: float = 0.018


func _ready() -> void:
	add_to_group("sandstorm_controller")
	_timer = randf_range(min_interval * 0.3, max_interval * 0.4)
	call_deferred("_find_environment")


func _find_environment() -> void:
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return
	_env = tree.current_scene.find_child("WorldEnvironment", true, false) as WorldEnvironment
	if _env and _env.environment:
		_base_fog = _env.environment.fog_density


func _process(delta: float) -> void:
	if GameManager.current_region_id != "ember_wastes":
		return
	if DungeonManager.in_dungeon:
		if _stage != WeatherStage.CLEAR:
			_set_stage(WeatherStage.CLEAR)
		return
	_apply_desert_heat()
	if _is_sheltered():
		if _stage in [WeatherStage.HEAVY_WIND, WeatherStage.SEVERE_SANDSTORM]:
			_set_stage(WeatherStage.CLEARING)
		return
	_timer -= delta
	if _timer <= 0.0:
		_advance_weather()


func _apply_desert_heat() -> void:
	for player in GameManager.get_alive_players():
		if not player.has_node("StatusEffectsComponent"):
			continue
		var status := player.get_node("StatusEffectsComponent") as _StatusEffects
		var sheltered := _is_sheltered()
		status.set_in_heat_zone(not sheltered)
		status.set_sandstorm_exposure(_stage in [WeatherStage.HEAVY_WIND, WeatherStage.SEVERE_SANDSTORM] and not sheltered)


func _is_sheltered() -> bool:
	var player := GameManager.get_player(0)
	if player == null:
		return false
	var pos := player.global_position
	if pos.distance_to(Vector3.ZERO) < 16.0:
		return true
	for zone in get_tree().get_nodes_in_group("desert_shelter"):
		if zone is Node3D and pos.distance_to((zone as Node3D).global_position) < 12.0:
			return true
	return false


func _advance_weather() -> void:
	var next := WeatherStage.CLEAR
	match _stage:
		WeatherStage.CLEAR:
			next = WeatherStage.LIGHT_DUST if randf() > 0.35 else WeatherStage.CLEAR
		WeatherStage.LIGHT_DUST:
			next = WeatherStage.HEAVY_WIND if randf() > 0.4 else WeatherStage.CLEARING
		WeatherStage.HEAVY_WIND:
			next = WeatherStage.SEVERE_SANDSTORM if randf() > 0.5 else WeatherStage.CLEARING
		WeatherStage.SEVERE_SANDSTORM:
			next = WeatherStage.CLEARING
		WeatherStage.CLEARING:
			next = WeatherStage.CLEAR
	_set_stage(next)


func _set_stage(stage: WeatherStage) -> void:
	_stage = stage
	match stage:
		WeatherStage.CLEAR:
			_timer = randf_range(min_interval, max_interval)
			if _env and _env.environment:
				_env.environment.fog_density = _base_fog
			for player in GameManager.get_alive_players():
				if player.has_node("StatusEffectsComponent"):
					var status := player.get_node("StatusEffectsComponent") as _StatusEffects
					status.set_sandstorm_exposure(false)
		WeatherStage.LIGHT_DUST:
			_timer = storm_duration * 0.35
			AudioManager.play_sfx("desert_wind", 0.85)
		WeatherStage.HEAVY_WIND:
			_timer = storm_duration * 0.55
			if _env and _env.environment:
				_env.environment.fog_density = maxf(_base_fog, 0.028)
			AudioManager.play_sfx("sandstorm", 0.9)
		WeatherStage.SEVERE_SANDSTORM:
			_timer = storm_duration
			if _env and _env.environment:
				_env.environment.fog_density = maxf(_base_fog, 0.042)
			AudioManager.play_sfx("sandstorm", 1.05)
			for hud in get_tree().get_nodes_in_group("game_hud"):
				if hud.has_method("show_toast"):
					hud.show_toast("Severe Sandstorm", 3.0, "Seek shelter at Cinderhold", "notification")
		WeatherStage.CLEARING:
			_timer = storm_duration * 0.4
			if _env and _env.environment:
				_env.environment.fog_density = lerpf(_env.environment.fog_density, _base_fog, 0.5)
