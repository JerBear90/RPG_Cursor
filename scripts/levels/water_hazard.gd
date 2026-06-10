class_name WaterHazard
extends Node3D
## Kills the player in water, void falls, or when leaving the island.

@export var island_radius: float = 28.0
@export var fall_kill_y: float = -6.0
@export var use_horizontal_boundary: bool = true

var _cooldown: float = 0.0


func _ready() -> void:
	add_to_group("water_hazard")


func _physics_process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	if _cooldown > 0.0:
		return
	for player in GameManager.get_alive_players():
		if not player is PlayerController:
			continue
		if _should_kill((player as PlayerController).global_position):
			_kill_player(player as PlayerController)
			break


func _should_kill(pos: Vector3) -> bool:
	if pos.y <= fall_kill_y:
		return true
	if not use_horizontal_boundary:
		return false
	var horiz := Vector2(pos.x, pos.z)
	return horiz.length() > island_radius - 0.35


func _kill_player(player: PlayerController) -> void:
	_cooldown = 2.0
	SaveManager.mark_water_death()
	if player.has_node("Combat"):
		var combat := player.get_node("Combat")
		if combat.has_method("die_from_environment"):
			combat.die_from_environment("drowned")
			return
	if player.has_node("HealthComponent"):
		(player.get_node("HealthComponent") as HealthComponent).take_damage(
			DamageData.create_physical(9999.0, self)
		)
