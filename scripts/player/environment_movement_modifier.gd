class_name EnvironmentMovementModifier
extends Node
## Shared environmental movement modifiers (shallow water, boardwalk, snow, ice).

var shallow_water_multiplier: float = 1.0
var boardwalk_active: bool = false
var deep_snow_multiplier: float = 1.0
var _deep_snow_active: bool = false
var ice_traction: float = 1.0
var _ice_active: bool = false
var _wet_rock_active: bool = false
var wet_rock_traction: float = 0.72
var ice_accel_multiplier: float = 0.72
var ice_decel_multiplier: float = 0.35
var ice_steer_multiplier: float = 0.78


func get_speed_multiplier() -> float:
	if boardwalk_active:
		return 1.0
	var mult := shallow_water_multiplier
	if _deep_snow_active:
		mult *= deep_snow_multiplier
	return mult


func get_traction_multiplier() -> float:
	if _ice_active:
		return ice_traction
	if _wet_rock_active:
		return wet_rock_traction
	return 1.0


func is_on_ice() -> bool:
	return _ice_active


func is_on_wet_rock() -> bool:
	return _wet_rock_active


func get_ice_accel_multiplier() -> float:
	if not _ice_active:
		return 1.0
	return ice_accel_multiplier * clampf(ice_traction + 0.25, 0.5, 1.0)


func get_ice_decel_multiplier() -> float:
	if not _ice_active:
		return 1.0
	return ice_decel_multiplier * clampf(ice_traction + 0.15, 0.35, 0.85)


func get_ice_steer_multiplier() -> float:
	if not _ice_active:
		return 1.0
	return ice_steer_multiplier


func set_shallow_water(active: bool, multiplier: float = 0.85) -> void:
	shallow_water_multiplier = multiplier if active else 1.0


func set_boardwalk(active: bool) -> void:
	boardwalk_active = active


func set_deep_snow(active: bool, multiplier: float = 0.72) -> void:
	_deep_snow_active = active
	deep_snow_multiplier = multiplier if active else 1.0


func set_ice_surface(active: bool, traction: float = 0.55) -> void:
	_ice_active = active
	ice_traction = traction if active else 1.0


func set_wet_rock(active: bool, traction: float = 0.72) -> void:
	_wet_rock_active = active
	wet_rock_traction = traction if active else 0.72
