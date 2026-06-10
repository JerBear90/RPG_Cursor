class_name PlayerController
extends CharacterBody3D
## Third-person movement, sprint, dodge integration.

signal state_changed(state: String)

enum State { IDLE, MOVE, SPRINT, DODGE, ATTACK, BLOCK, STAGGER, DEAD }

@export var move_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var rotation_speed: float = 12.0
@export var gravity: float = 20.0
@export var player_index: int = 0

var current_state: State = State.IDLE
var _combat: Node
var _dodge: DodgeComponent
var _stamina: StaminaComponent
var _camera_rig: Node3D


func _ready() -> void:
	add_to_group("player")
	GameManager.register_player(self, player_index)
	_combat = get_node_or_null("Combat")
	_dodge = get_node_or_null("DodgeComponent")
	_stamina = get_node_or_null("StaminaComponent")
	var needs := get_node_or_null("SurvivalNeedsComponent") as SurvivalNeedsComponent
	if needs:
		needs.starving.connect(_on_starving)
		needs.dehydrated.connect(_on_dehydrated)
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
	if has_node("StaminaComponent"):
		(get_node("StaminaComponent") as StaminaComponent).spend(2.0)


func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
	if _dodge and _dodge.is_dodging:
		_apply_dodge_movement()
	elif current_state not in [State.ATTACK, State.STAGGER]:
		_apply_movement(delta)
	move_and_slide()
	MapManager.update_player_position(player_index, global_position)


func _apply_movement(delta: float) -> void:
	var input_dir := InputManager.get_move_vector(player_index)
	if input_dir.length_squared() < 0.01:
		_set_state(State.IDLE)
		velocity.x = move_toward(velocity.x, 0.0, move_speed)
		velocity.z = move_toward(velocity.z, 0.0, move_speed)
		return

	var sprinting := InputManager.is_action_pressed("sprint", player_index)
	var speed := sprint_speed if sprinting and _stamina and _stamina.current_stamina > 0 else move_speed
	if sprinting and _stamina:
		_stamina.spend(10.0 * delta)
	_set_state(State.SPRINT if sprinting else State.MOVE)

	var forward: Vector3 = _get_planar_forward()
	var right: Vector3 = _get_planar_right()
	# input_dir.y: +1 = move_back action, -1 = move_forward (W)
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


func get_level() -> int:
	var stats := get_node_or_null("StatsComponent")
	return stats.level if stats else 1


func receive_damage(damage: DamageData) -> void:
	var combat := get_node_or_null("Combat")
	if combat and combat.has_method("receive_damage"):
		combat.receive_damage(damage)


func _set_state(state: State) -> void:
	if current_state != state:
		current_state = state
		state_changed.emit(State.keys()[state])
