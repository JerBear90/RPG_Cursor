class_name WaterHazard
extends Node3D
## Kills the player in water, void falls, or when leaving the island.

@export var island_radius: float = 28.0
@export var fall_kill_y: float = -12.0
@export var use_horizontal_boundary: bool = true

var _cooldown: float = 0.0
var _level_grace: float = 8.0
var _player_landed: Dictionary = {}


func _ready() -> void:
	add_to_group("water_hazard")
	_level_grace = 8.0
	if not GameManager.player_spawned.is_connected(_on_player_spawned):
		GameManager.player_spawned.connect(_on_player_spawned)


func reset_player(player: PlayerController) -> void:
	if player == null:
		return
	_player_landed.erase(player.get_instance_id())


func _on_player_spawned(player: Node, _index: int) -> void:
	if player is PlayerController:
		reset_player(player as PlayerController)


func _physics_process(delta: float) -> void:
	_level_grace = maxf(_level_grace - delta, 0.0)
	_cooldown = maxf(_cooldown - delta, 0.0)
	if _cooldown > 0.0:
		return
	for player in GameManager.get_alive_players():
		if not player is PlayerController:
			continue
		var pc := player as PlayerController
		var pid := pc.get_instance_id()
		if pc.is_on_floor():
			_player_landed[pid] = true
		if pc.has_spawn_protection():
			continue
		if not _player_landed.get(pid, false):
			if pc.global_position.y <= fall_kill_y - 8.0:
				_kill_player(pc)
			continue
		if _level_grace > 0.0 and not pc.is_on_floor():
			continue
		if _should_kill(pc.global_position):
			_kill_player(pc)
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
