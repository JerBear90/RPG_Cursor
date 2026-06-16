class_name CoastalStormController
extends Node
## Staged coastal weather for The Shattered Coast.

const _StatusEffects := preload("res://scripts/combat/status_effects_component.gd")

enum WeatherStage { OVERCAST, HEAVY_RAIN, OCEAN_FOG, HIGH_WIND, THUNDERSTORM }

@export var min_interval: float = 80.0
@export var max_interval: float = 160.0
@export var storm_duration: float = 45.0

var _timer: float = 40.0
var _stage: WeatherStage = WeatherStage.OVERCAST
var _env: WorldEnvironment
var _base_fog: float = 0.018


func _ready() -> void:
	add_to_group("coastal_storm_controller")
	_timer = randf_range(min_interval * 0.4, max_interval * 0.5)
	call_deferred("_find_environment")


func _find_environment() -> void:
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return
	_env = tree.current_scene.find_child("WorldEnvironment", true, false) as WorldEnvironment
	if _env and _env.environment:
		_base_fog = _env.environment.fog_density


func _process(delta: float) -> void:
	if GameManager.current_region_id != "shattered_coast":
		return
	if DungeonManager.in_dungeon:
		if _stage != WeatherStage.OVERCAST:
			_set_stage(WeatherStage.OVERCAST)
		return
	if _is_sheltered():
		if _stage == WeatherStage.THUNDERSTORM or _stage == WeatherStage.HEAVY_RAIN:
			_set_stage(WeatherStage.OVERCAST)
		return
	_timer -= delta
	if _timer <= 0.0:
		_advance_weather()


func _is_sheltered() -> bool:
	var player := GameManager.get_player(0)
	if player == null:
		return false
	var pos := player.global_position
	if pos.distance_to(Vector3.ZERO) < 16.0:
		return true
	for zone in get_tree().get_nodes_in_group("coastal_shelter"):
		if zone is Node3D and pos.distance_to((zone as Node3D).global_position) < 12.0:
			return true
	return false


func _advance_weather() -> void:
	var next := WeatherStage.OVERCAST
	match _stage:
		WeatherStage.OVERCAST:
			next = WeatherStage.HEAVY_RAIN if randf() > 0.35 else WeatherStage.OCEAN_FOG
		WeatherStage.HEAVY_RAIN:
			next = WeatherStage.HIGH_WIND if randf() > 0.4 else WeatherStage.THUNDERSTORM
		WeatherStage.OCEAN_FOG:
			next = WeatherStage.OVERCAST
		WeatherStage.HIGH_WIND:
			next = WeatherStage.THUNDERSTORM
		WeatherStage.THUNDERSTORM:
			next = WeatherStage.OVERCAST
	_set_stage(next)


func _set_stage(stage: WeatherStage) -> void:
	_stage = stage
	match stage:
		WeatherStage.OVERCAST:
			_timer = randf_range(min_interval, max_interval)
			if _env and _env.environment:
				_env.environment.fog_density = _base_fog
			for player in GameManager.get_alive_players():
				if player.has_node("StatusEffectsComponent"):
					(player.get_node("StatusEffectsComponent") as _StatusEffects).set_storm_exposure(false)
					(player.get_node("StatusEffectsComponent") as _StatusEffects).set_heavy_rain(false)
		WeatherStage.HEAVY_RAIN:
			_timer = storm_duration * 0.6
			AudioManager.play_sfx("coastal_rain", 0.85)
			for player in GameManager.get_alive_players():
				if player.has_node("StatusEffectsComponent"):
					(player.get_node("StatusEffectsComponent") as _StatusEffects).set_heavy_rain(true)
		WeatherStage.OCEAN_FOG:
			_timer = storm_duration * 0.5
			if _env and _env.environment:
				_env.environment.fog_density = maxf(_base_fog, 0.035)
		WeatherStage.HIGH_WIND:
			_timer = storm_duration * 0.45
			AudioManager.play_sfx("coastal_wind", 0.9)
		WeatherStage.THUNDERSTORM:
			_timer = storm_duration
			if _env and _env.environment:
				_env.environment.fog_density = maxf(_base_fog, 0.028)
			AudioManager.play_sfx("thunder_roll", 0.95)
			for hud in get_tree().get_nodes_in_group("game_hud"):
				if hud.has_method("show_toast"):
					hud.show_toast("Thunderstorm", 3.0, "Seek shelter at Tidewatch", "notification")
			for player in GameManager.get_alive_players():
				if player.has_node("StatusEffectsComponent"):
					(player.get_node("StatusEffectsComponent") as _StatusEffects).set_storm_exposure(true)
