class_name PlayerController
extends CharacterBody3D
## Third-person movement, sprint, dodge, and jump integration.

signal state_changed(state: String)

enum State { IDLE, MOVE, SPRINT, DODGE, ATTACK, BLOCK, STAGGER, DEAD }

@export var move_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var rotation_speed: float = 12.0
@export var gravity: float = 20.0
@export var jump_velocity: float = 7.5
@export var air_control: float = 0.45
@export var player_index: int = 0
@export var spawn_protection_sec: float = 2.0
@export var respawn_protection_sec: float = 1.5

var current_state: State = State.IDLE
var _spawn_protection_until: float = 0.0
var _combat_invuln_until: float = 0.0
var _combat: Node
var _dodge: DodgeComponent
var _stamina: StaminaComponent
var _camera_rig: Node3D
var _was_on_floor: bool = true


func _ready() -> void:
	add_to_group("player")
	floor_snap_length = 0.25
	_spawn_protection_until = Time.get_ticks_msec() / 1000.0 + spawn_protection_sec
	_combat_invuln_until = 0.0
	GameManager.register_player(self, player_index)
	_combat = get_node_or_null("Combat")
	_dodge = get_node_or_null("DodgeComponent")
	_stamina = get_node_or_null("StaminaComponent")
	var needs := get_node_or_null("SurvivalNeedsComponent") as SurvivalNeedsComponent
	if needs:
		needs.starving.connect(_on_starving)
		needs.dehydrated.connect(_on_dehydrated)
	if _stamina and not _stamina.stamina_changed.is_connected(_on_stamina_changed):
		_stamina.stamina_changed.connect(_on_stamina_changed)
	call_deferred("_bind_camera_rig")
	if not GameManager.player_spawned.is_connected(_on_player_spawned):
		GameManager.player_spawned.connect(_on_player_spawned)


func _bind_camera_rig() -> void:
	for node in get_tree().get_nodes_in_group("camera_rig"):
		if node is Node3D:
			_camera_rig = node
			return


func _on_player_spawned(_player: Node, _index: int) -> void:
	if _camera_rig == null:
		_bind_camera_rig()


func _on_starving() -> void:
	if has_node("HealthComponent") and is_alive():
		(get_node("HealthComponent") as HealthComponent).take_damage(DamageData.create_physical(1.0, self))


func _on_dehydrated() -> void:
	if has_node("HealthComponent") and is_alive():
		(get_node("HealthComponent") as HealthComponent).take_damage(DamageData.create_physical(0.5, self))


func _on_stamina_changed(current: float, _maximum: float) -> void:
	if current > 1.0:
		return
	if current_state == State.SPRINT:
		_set_state(State.MOVE)


func is_input_locked() -> bool:
	return current_state == State.DEAD or DialogueManager.blocks_gameplay() or GameManager.is_paused


func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return
	var on_floor_now := is_on_floor()
	if on_floor_now:
		floor_snap_length = 0.25
	elif velocity.y > 0.05:
		floor_snap_length = 0.0
	else:
		floor_snap_length = 0.15
	if not on_floor_now:
		velocity.y -= gravity * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0
	if _dodge and _dodge.is_dodging:
		_apply_dodge_movement()
	elif not is_input_locked() and current_state not in [State.ATTACK, State.STAGGER]:
		_try_jump()
		_apply_movement(delta, on_floor_now)
	move_and_slide()
	_was_on_floor = on_floor_now
	MapManager.update_player_position(player_index, global_position)


func _try_jump() -> void:
	if not is_on_floor():
		return
	if DialogueManager.blocks_gameplay():
		return
	if InputManager.is_action_just_pressed("jump", player_index):
		velocity.y = jump_velocity


func _apply_movement(delta: float, on_floor_now: bool) -> void:
	var input_dir := InputManager.get_move_vector(player_index)
	var control := 1.0 if on_floor_now else air_control
	if input_dir.length_squared() < 0.01:
		_set_state(State.IDLE if on_floor_now else current_state)
		var friction := move_speed * (1.0 if on_floor_now else 0.35)
		velocity.x = move_toward(velocity.x, 0.0, friction)
		velocity.z = move_toward(velocity.z, 0.0, friction)
		return
	var sprinting := on_floor_now and InputManager.is_action_pressed("sprint", player_index)
	var can_sprint := _stamina != null and _stamina.current_stamina > 1.0
	var speed := sprint_speed if sprinting and can_sprint else move_speed
	speed *= control
	if sprinting and can_sprint and _stamina and on_floor_now:
		_stamina.spend(10.0 * delta)
	_set_state(State.SPRINT if sprinting and can_sprint and on_floor_now else State.MOVE)
	var forward: Vector3 = _get_planar_forward()
	var right: Vector3 = _get_planar_right()
	var direction: Vector3 = (right * input_dir.x + forward * -input_dir.y).normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed


func _apply_dodge_movement() -> void:
	var input_dir := InputManager.get_move_vector(player_index)
	var forward: Vector3 = _get_planar_forward()
	var right: Vector3 = _get_planar_right()
	var dodge_dir: Vector3 = right * input_dir.x + forward * -input_dir.y
	dodge_dir.y = 0.0
	if dodge_dir.length_squared() < 0.01:
		dodge_dir = forward
	dodge_dir = dodge_dir.normalized()
	velocity.x = dodge_dir.x * _dodge.dodge_speed
	velocity.z = dodge_dir.z * _dodge.dodge_speed


func _get_camera_rig() -> Node3D:
	if _camera_rig == null or not is_instance_valid(_camera_rig):
		_bind_camera_rig()
	return _camera_rig


func _get_planar_forward() -> Vector3:
	var rig := _get_camera_rig()
	if rig and rig.has_method("get_planar_forward"):
		return rig.get_planar_forward()
	var cam := get_viewport().get_camera_3d()
	if cam is SharedScreenCamera:
		return cam.get_planar_forward()
	return Vector3.FORWARD.rotated(Vector3.UP, rotation.y)


func _get_planar_right() -> Vector3:
	var rig := _get_camera_rig()
	if rig and rig.has_method("get_planar_right"):
		return rig.get_planar_right()
	var cam := get_viewport().get_camera_3d()
	if cam is SharedScreenCamera:
		return cam.get_planar_right()
	var forward := Vector3.FORWARD.rotated(Vector3.UP, rotation.y)
	return Vector3.UP.cross(forward).normalized()


func is_alive() -> bool:
	var health := get_node_or_null("HealthComponent")
	return health == null or health.is_alive()


func has_spawn_protection() -> bool:
	return Time.get_ticks_msec() / 1000.0 < _spawn_protection_until


func has_combat_invulnerability() -> bool:
	return Time.get_ticks_msec() / 1000.0 < _combat_invuln_until


func clear_spawn_protection() -> void:
	_spawn_protection_until = 0.0
	_combat_invuln_until = 0.0


func refresh_spawn_protection(extra_sec: float = -1.0) -> void:
	var duration := extra_sec if extra_sec > 0.0 else respawn_protection_sec
	_combat_invuln_until = Time.get_ticks_msec() / 1000.0 + duration
	velocity = Vector3.ZERO


func get_level() -> int:
	var stats := get_node_or_null("StatsComponent")
	return stats.level if stats else 1


func receive_damage(damage: DamageData) -> void:
	var combat := get_node_or_null("Combat")
	if combat and combat.has_method("receive_damage"):
		combat.receive_damage(damage)


func set_state(state: State) -> void:
	_set_state(state)


func _set_state(state: State) -> void:
	if current_state != state:
		current_state = state
		state_changed.emit(State.keys()[state])
