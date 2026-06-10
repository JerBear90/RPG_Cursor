extends Node3D
## Over-the-shoulder camera rig — moves with players, orbits locally.

@export var base_distance: float = 5.5
@export var height_offset: float = 1.85
@export var shoulder_offset: float = 0.75
@export var look_height: float = 1.2
@export var follow_speed: float = 12.0
@export var mouse_sensitivity: float = 0.003

@onready var camera: Camera3D = $SharedScreenCamera

var _yaw: float = 0.0
var _pitch: float = -0.32
var _snapped: bool = false
var _mouse_captured: bool = false


func _ready() -> void:
	if camera:
		camera.current = true
	if not GameManager.player_spawned.is_connected(_on_player_spawned):
		GameManager.player_spawned.connect(_on_player_spawned)
	if not GameManager.region_changed.is_connected(_on_region_changed):
		GameManager.region_changed.connect(_on_region_changed)
	call_deferred("_capture_mouse")


func _capture_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_mouse_captured = true


func _physics_process(delta: float) -> void:
	var players := GameManager.get_alive_players()
	if players.is_empty():
		return

	var midpoint := Vector3.ZERO
	for p in players:
		midpoint += p.global_position
	midpoint /= players.size()

	var target_rig := Vector3(midpoint.x, midpoint.y, midpoint.z)
	if not _snapped:
		global_position = target_rig
		if players[0] is Node3D:
			_yaw = (players[0] as Node3D).rotation.y
		_snapped = true
	else:
		global_position = global_position.lerp(target_rig, follow_speed * delta)

	var orbit := Basis.from_euler(Vector3(_pitch, _yaw, 0.0))
	camera.position = orbit * Vector3(shoulder_offset, height_offset, base_distance)
	camera.look_at(Vector3(0.0, look_height, 0.0), Vector3.UP)


func _on_region_changed(_region_id: String) -> void:
	_snapped = false


func _on_player_spawned(_player: Node, _index: int) -> void:
	_snapped = false


func add_look_input(look: Vector2) -> void:
	_yaw -= look.x
	_pitch = clampf(_pitch - look.y, -0.5, 0.2)


func get_planar_forward() -> Vector3:
	var forward := Vector3(-sin(_yaw), 0.0, -cos(_yaw))
	return forward.normalized()


func get_planar_right() -> Vector3:
	return Vector3.UP.cross(get_planar_forward()).normalized()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and _mouse_captured:
		var motion := event as InputEventMouseMotion
		add_look_input(motion.relative * mouse_sensitivity)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if _mouse_captured:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			_mouse_captured = false
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			_mouse_captured = true


func _process(_delta: float) -> void:
	var look := InputManager.get_look_vector(0)
	if look.length_squared() > 0.01:
		add_look_input(look * 0.04)
