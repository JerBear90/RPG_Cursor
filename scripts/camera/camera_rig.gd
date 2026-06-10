extends Node3D
## Over-the-shoulder look — mouse pans the view; fixed mount on the character (no free orbit).

@export var shoulder_offset: float = 0.45
@export var height_offset: float = 0.15
@export var shoulder_back: float = 2.73
@export var pivot_height: float = 1.0
@export var mouse_sensitivity: float = 0.003
@export var min_pitch: float = -0.75
@export var max_pitch: float = 0.45

@onready var camera: Camera3D = $SharedScreenCamera

var _yaw: float = 0.0
var _pitch: float = -0.12
var _snapped: bool = false
var _mouse_captured: bool = false
var _level_parent: Node3D
var _attach_player: Node3D


func _ready() -> void:
	add_to_group("camera_rig")
	process_physics_priority = -10
	_level_parent = get_parent() as Node3D
	if camera:
		camera.current = true
	if not GameManager.player_spawned.is_connected(_on_player_spawned):
		GameManager.player_spawned.connect(_on_player_spawned)
	if not GameManager.region_changed.is_connected(_on_region_changed):
		GameManager.region_changed.connect(_on_region_changed)
	call_deferred("_capture_mouse")
	call_deferred("_refresh_attachment")


func _capture_mouse() -> void:
	if get_tree().paused:
		call_deferred("_capture_mouse")
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_mouse_captured = true


func _physics_process(_delta: float) -> void:
	var players := GameManager.get_alive_players()
	if players.is_empty():
		return

	if _attach_player and is_instance_valid(_attach_player):
		_attach_player.rotation.y = _yaw
		_apply_look(true)
		return

	var midpoint := Vector3.ZERO
	for p in players:
		midpoint += p.global_position
	midpoint /= players.size()

	var pivot := midpoint + Vector3(0.0, pivot_height, 0.0)
	if not _snapped:
		global_position = pivot
		_yaw = (players[0] as Node3D).rotation.y
		_snapped = true
	else:
		global_position = pivot

	_apply_look(false)


func _apply_look(parented: bool) -> void:
	rotation.y = 0.0 if parented else _yaw
	camera.position = Vector3(shoulder_offset, height_offset, shoulder_back)
	camera.rotation = Vector3(_pitch, 0.0, 0.0)


func attach_to_player(player: Node3D) -> void:
	if _attach_player == player and get_parent() == player.get_node_or_null("CameraPivot"):
		return
	_attach_player = player
	var pivot := player.get_node_or_null("CameraPivot") as Node3D
	if pivot == null:
		pivot = player
	reparent(pivot)
	position = Vector3.ZERO
	rotation = Vector3.ZERO
	_yaw = player.rotation.y
	player.rotation.y = _yaw
	_snapped = true


func detach_from_player() -> void:
	if _attach_player == null:
		return
	_attach_player = null
	if _level_parent and is_instance_valid(_level_parent):
		reparent(_level_parent)
	position = Vector3.ZERO
	rotation = Vector3.ZERO
	_snapped = false


func _refresh_attachment() -> void:
	var players := GameManager.get_alive_players()
	if players.size() == 1 and players[0] is Node3D:
		attach_to_player(players[0] as Node3D)
	else:
		detach_from_player()


func _on_region_changed(_region_id: String) -> void:
	detach_from_player()
	_snapped = false
	call_deferred("_refresh_attachment")


func _on_player_spawned(_player: Node, _index: int) -> void:
	call_deferred("_refresh_attachment")


func get_yaw() -> float:
	return _yaw


func add_look_input(look: Vector2) -> void:
	var sens := mouse_sensitivity * SettingsManager.camera_sensitivity
	_yaw -= look.x * sens
	_pitch = clampf(_pitch - look.y * sens, min_pitch, max_pitch)
	if _attach_player and is_instance_valid(_attach_player):
		_attach_player.rotation.y = _yaw


func get_planar_forward() -> Vector3:
	return Vector3(-sin(_yaw), 0.0, -cos(_yaw)).normalized()


func get_planar_right() -> Vector3:
	return Vector3.UP.cross(get_planar_forward()).normalized()


func _input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	if event is InputEventMouseMotion and _mouse_captured:
		var motion := event as InputEventMouseMotion
		var look := motion.relative
		if SettingsManager.invert_look_x:
			look.x = -look.x
		if SettingsManager.invert_look_y:
			look.y = -look.y
		add_look_input(look)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if _mouse_captured:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			_mouse_captured = false
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			_mouse_captured = true


func _process(_delta: float) -> void:
	if get_tree().paused:
		return
	var look := InputManager.get_look_vector(0)
	if look.length_squared() > 0.01:
		add_look_input(look * 0.04)
