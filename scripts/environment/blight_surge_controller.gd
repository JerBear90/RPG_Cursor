class_name BlightSurgeController
extends Node
## Staged Blight weather for Blightreach.

const _StatusEffects := preload("res://scripts/combat/status_effects_component.gd")

enum WeatherStage { CALM_FOG, SPORE_FALL, BLIGHT_SURGE, SICKLY_RAIN, GROUND_MIST }

@export var min_interval: float = 70.0
@export var max_interval: float = 150.0
@export var surge_duration: float = 40.0

var _timer: float = 35.0
var _stage: WeatherStage = WeatherStage.CALM_FOG
var _env: WorldEnvironment
var _base_fog: float = 0.022


func _ready() -> void:
	add_to_group("blight_surge_controller")
	_timer = randf_range(min_interval * 0.35, max_interval * 0.45)
	call_deferred("_find_environment")


func _find_environment() -> void:
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return
	_env = tree.current_scene.find_child("WorldEnvironment", true, false) as WorldEnvironment
	if _env and _env.environment:
		_base_fog = _env.environment.fog_density


func _process(delta: float) -> void:
	if GameManager.current_region_id != "blightreach":
		return
	if DungeonManager.in_dungeon:
		if _stage != WeatherStage.CALM_FOG:
			_set_stage(WeatherStage.CALM_FOG)
		return
	if _is_sheltered():
		if _stage == WeatherStage.BLIGHT_SURGE or _stage == WeatherStage.SPORE_FALL:
			_set_stage(WeatherStage.CALM_FOG)
		return
	_timer -= delta
	if _timer <= 0.0:
		_advance_weather()


func _is_sheltered() -> bool:
	var player := GameManager.get_player(0)
	if player == null:
		return false
	var pos := player.global_position
	if pos.distance_to(Vector3.ZERO) < 14.0:
		return true
	for zone in get_tree().get_nodes_in_group("blight_shelter"):
		if zone is Node3D and pos.distance_to((zone as Node3D).global_position) < 11.0:
			return true
	return false


func _advance_weather() -> void:
	var next := WeatherStage.CALM_FOG
	match _stage:
		WeatherStage.CALM_FOG:
			next = WeatherStage.SPORE_FALL if randf() > 0.4 else WeatherStage.GROUND_MIST
		WeatherStage.SPORE_FALL:
			next = WeatherStage.BLIGHT_SURGE if randf() > 0.45 else WeatherStage.SICKLY_RAIN
		WeatherStage.BLIGHT_SURGE:
			next = WeatherStage.CALM_FOG
		WeatherStage.SICKLY_RAIN:
			next = WeatherStage.GROUND_MIST
		WeatherStage.GROUND_MIST:
			next = WeatherStage.CALM_FOG
	_set_stage(next)


func _set_stage(stage: WeatherStage) -> void:
	_stage = stage
	match stage:
		WeatherStage.CALM_FOG:
			_timer = randf_range(min_interval, max_interval)
			if _env and _env.environment:
				_env.environment.fog_density = _base_fog
			for player in GameManager.get_alive_players():
				if player.has_node("StatusEffectsComponent"):
					(player.get_node("StatusEffectsComponent") as _StatusEffects).set_blight_surge(false)
		WeatherStage.SPORE_FALL:
			_timer = surge_duration * 0.55
			AudioManager.play_sfx("fungal_burst", 0.75)
			for player in GameManager.get_alive_players():
				if player.has_node("StatusEffectsComponent"):
					(player.get_node("StatusEffectsComponent") as _StatusEffects).set_in_spore_zone(true)
		WeatherStage.BLIGHT_SURGE:
			_timer = surge_duration
			if _env and _env.environment:
				_env.environment.fog_density = maxf(_base_fog, 0.038)
			AudioManager.play_sfx("blight_surge", 0.9)
			for hud in get_tree().get_nodes_in_group("game_hud"):
				if hud.has_method("show_toast"):
					hud.show_toast("Blight Surge", 3.0, "Seek shelter at Lastwall", "notification")
			for player in GameManager.get_alive_players():
				if player.has_node("StatusEffectsComponent"):
					var status := player.get_node("StatusEffectsComponent") as _StatusEffects
					status.set_blight_surge(true)
					status.set_in_blight_zone(true)
		WeatherStage.SICKLY_RAIN:
			_timer = surge_duration * 0.5
			AudioManager.play_sfx("coastal_rain", 0.6)
		WeatherStage.GROUND_MIST:
			_timer = surge_duration * 0.45
			if _env and _env.environment:
				_env.environment.fog_density = maxf(_base_fog, 0.032)
