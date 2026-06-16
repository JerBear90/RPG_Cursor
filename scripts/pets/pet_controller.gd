class_name PetController
extends Node3D
## Shared party pet controller — follow, commands, combat, downed state.

const _PetStatsScript := preload("res://scripts/pets/pet_stats.gd")
const _PetAIScript := preload("res://scripts/pets/pet_ai.gd")

signal pet_downed
signal pet_recovered
signal stats_changed(current_hp: float, max_hp: float, command: String)

const HURTBOX_LAYER := 16

var pet_id: String = ""
var display_name: String = "Pet"
var stats: PetStats = _PetStatsScript.new()
var _command: String = "follow"
var _stay_position: Vector3 = Vector3.ZERO
var _attack_target: Node3D
var _attack_cd: float = 0.0
var _stuck_timer: float = 0.0
var _last_position: Vector3 = Vector3.ZERO
var _hitbox: Hitbox
var _hurtbox: Hurtbox
var _data: Dictionary = {}


func _ready() -> void:
	add_to_group("pet")
	_last_position = global_position


func setup_from_data(data: Dictionary) -> void:
	pet_id = str(data.get("pet_id", "ash_hound"))
	display_name = str(data.get("display_name", "Pet"))
	_data = data
	stats.apply_data(data, PetManager.get_pet_modifiers())
	_command = PetManager.get_party_command()
	_stay_position = global_position
	_setup_combat_nodes()
	call_deferred("_spawn_visual")
	stats_changed.emit(stats.current_hp, stats.max_hp, _command)


func _setup_combat_nodes() -> void:
	_hitbox = Hitbox.new()
	_hitbox.name = "AttackHitbox"
	_hitbox.team = "pet"
	_hitbox.base_damage = stats.base_damage
	var hit_shape := CollisionShape3D.new()
	var hit_sphere := SphereShape3D.new()
	hit_sphere.radius = 0.65
	hit_shape.shape = hit_sphere
	_hitbox.add_child(hit_shape)
	add_child(_hitbox)
	_hurtbox = Hurtbox.new()
	_hurtbox.name = "Hurtbox"
	_hurtbox.team = "pet"
	var hurt_shape := CollisionShape3D.new()
	var hurt_sphere := SphereShape3D.new()
	hurt_sphere.radius = 0.55
	hurt_shape.shape = hurt_sphere
	_hurtbox.add_child(hurt_shape)
	add_child(_hurtbox)
	_hurtbox.hit_received.connect(_on_hurtbox_hit)


func _spawn_visual() -> void:
	pass  # Subclasses override.


func set_command(command_id: String) -> void:
	_command = command_id
	if _command == "stay":
		_stay_position = global_position
	if _command == "recall":
		_recall_to_party()
	stats_changed.emit(stats.current_hp, stats.max_hp, _command)


func get_command() -> String:
	return _command


func is_downed() -> bool:
	return stats.downed


func recover(at_full: bool = true) -> void:
	if at_full:
		stats.full_recover()
	else:
		stats.heal(stats.max_hp * 0.5)
	pet_recovered.emit()
	stats_changed.emit(stats.current_hp, stats.max_hp, _command)
	PetManager.notify_pet_recovered(display_name)


func apply_saved_stats(saved: Dictionary) -> void:
	stats.deserialize(saved)
	stats.apply_data(_data, PetManager.get_pet_modifiers())
	if _hitbox:
		_hitbox.base_damage = stats.base_damage
	stats_changed.emit(stats.current_hp, stats.max_hp, _command)


func _physics_process(delta: float) -> void:
	if stats.downed:
		return
	_attack_cd = maxf(_attack_cd - delta, 0.0)
	_check_recall_distance()
	_update_target()
	if _attack_target and _try_attack():
		return
	match _command:
		"stay":
			return
		"recall":
			_move_toward(_PetAIScript.get_party_center(get_tree()) + _party_offset(), delta, float(_data.get("follow_distance", 2.5)))
		"defend":
			_move_toward(_PetAIScript.get_party_center(get_tree()) + _party_offset(), delta, 1.5)
		_:
			_move_toward(_PetAIScript.get_party_center(get_tree()) + _party_offset(), delta, float(_data.get("follow_distance", 2.5)))
	_check_stuck(delta)


func _party_offset() -> Vector3:
	return Vector3(-1.2, 0.0, 0.8)


func _update_target() -> void:
	var detect := float(_data.get("detection_range", 8.0))
	match _command:
		"attack", "hunt":
			_attack_target = _PetAIScript.find_nearest_enemy(global_position, get_tree(), detect + 4.0)
		"defend":
			_attack_target = _PetAIScript.find_enemy_near_players(get_tree(), detect)
		"follow", "recall":
			_attack_target = _PetAIScript.find_nearest_enemy(global_position, get_tree(), detect)
		"stay":
			_attack_target = null
		_:
			if _command != "stay":
				_attack_target = _PetAIScript.find_nearest_enemy(global_position, get_tree(), detect)


func _try_attack() -> bool:
	if _attack_target == null or _attack_cd > 0.0:
		return false
	var attack_range := 2.5
	var dist := global_position.distance_to(_attack_target.global_position)
	if dist > attack_range:
		return false
	var dir := (_attack_target.global_position - global_position)
	dir.y = 0.0
	if dir.length_squared() > 0.01:
		rotation.y = atan2(dir.x, dir.z)
	var damage := stats.base_damage
	if PetManager.should_apply_pack_tactics(_attack_target):
		damage *= PetManager.get_pack_tactics_multiplier()
	_hitbox.base_damage = damage
	_hitbox.enable()
	get_tree().create_timer(0.22).timeout.connect(_hitbox.disable)
	_attack_cd = float(_data.get("attack_cooldown", 1.5))
	return true


func _move_toward(target: Vector3, delta: float, stop_distance: float) -> void:
	var speed := float(_data.get("move_speed", 7.0))
	if _command == "recall":
		speed *= PetManager.get_recall_speed_multiplier()
	global_position = _PetAIScript.steer_toward(global_position, target, speed, delta, stop_distance)
	var to_target := target - global_position
	to_target.y = 0.0
	if to_target.length_squared() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(to_target.x, to_target.z), 8.0 * delta)


func _check_recall_distance() -> void:
	var recall_dist := float(_data.get("recall_distance", 15.0))
	var center := _PetAIScript.get_party_center(get_tree())
	if global_position.distance_to(center) > recall_dist:
		_recall_to_party()


func _recall_to_party() -> void:
	global_position = _PetAIScript.get_party_center(get_tree()) + _party_offset()
	_stuck_timer = 0.0


func _check_stuck(delta: float) -> void:
	if global_position.distance_to(_last_position) < 0.05:
		_stuck_timer += delta
	else:
		_stuck_timer = 0.0
	_last_position = global_position
	if _stuck_timer >= 3.0:
		_recall_to_party()
		_stuck_timer = 0.0


func _on_hurtbox_hit(damage: DamageData, _hitbox: Hitbox) -> void:
	if stats.downed:
		return
	stats.take_damage(damage.amount * 0.85)
	stats_changed.emit(stats.current_hp, stats.max_hp, _command)
	if stats.downed:
		pet_downed.emit()
		PetManager.notify_pet_downed(display_name)


func serialize_stats() -> Dictionary:
	return stats.serialize()
