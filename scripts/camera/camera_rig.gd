extends Node3D
## Over-the-shoulder look — mouse pans the view; fixed mount on the character (no free orbit).

@export var shoulder_offset: float = 0.45
@export var height_offset: float = 0.15
@export var shoulder_back: float = 2.73
# Co-op zoom tuning — min/max camera distance, separation scale, smooth lerp, close-player floor
@export var coop_min_back: float = 2.73
@export var coop_max_back: float = 6.8
@export var coop_zoom_separation: float = 14.0
@export var coop_zoom_smooth_speed: float = 0.1
@export var coop_close_separation_floor: float = 2.0
@export var coop_soft_tether_distance: float = 18.0
@export var coop_boss_zoom_padding: float = 3.5
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
var _coop_back_distance: float = 2.73


func _ready() -> void:
	add_to_group("camera_rig")
	process_physics_priority = -10
	_level_parent = get_parent() as Node3D
	_coop_back_distance = coop_min_back
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
	var subjects := _get_camera_subjects()
	if subjects.is_empty():
		return

	if _attach_player and is_instance_valid(_attach_player):
		_attach_player.rotation.y = _yaw
		_apply_look(true, _delta)
		return

	var midpoint := Vector3.ZERO
	for p in subjects:
		if p is Node3D:
			midpoint += (p as Node3D).global_position
	midpoint /= subjects.size()

	var pivot := midpoint + Vector3(0.0, pivot_height, 0.0)
	if not _snapped:
		global_position = pivot
		if subjects[0] is Node3D:
			_yaw = (subjects[0] as Node3D).rotation.y
		_snapped = true
	else:
		global_position = global_position.lerp(pivot, 0.18)

	_apply_look(false, _delta)


func _get_camera_subjects() -> Array[Node]:
	if GameManager.is_local_coop():
		var subjects: Array[Node] = []
		for p in GameManager.get_all_registered_players():
			if p and is_instance_valid(p) and p is Node3D:
				subjects.append(p)
		return subjects
	return GameManager.get_alive_players()


func _apply_look(parented: bool, delta: float) -> void:
	rotation.y = 0.0 if parented else _yaw
	var back := shoulder_back
	if not parented and GameManager.is_local_coop():
		var subjects := _get_camera_subjects()
		if subjects.size() > 1 and subjects[0] is Node3D and subjects[1] is Node3D:
			var sep: float = (subjects[0] as Node3D).global_position.distance_to((subjects[1] as Node3D).global_position)
			# Soft tether: cap zoom demand when players are very far apart
			sep = minf(sep, coop_soft_tether_distance)
			# Floor separation reduces jitter when players stand close together
			var sep_for_zoom := maxf(sep, coop_close_separation_floor)
			if GameManager.in_boss_fight:
				var midpoint := Vector3.ZERO
				for p in subjects:
					if p is Node3D:
						midpoint += (p as Node3D).global_position
				midpoint /= subjects.size()
				var boss_sep := _boss_separation_from_midpoint(midpoint)
				sep_for_zoom = maxf(sep_for_zoom, boss_sep)
			var span := maxf(coop_zoom_separation - coop_close_separation_floor, 1.0)
			var t := clampf((sep_for_zoom - coop_close_separation_floor) / span, 0.0, 1.0)
			back = lerpf(coop_min_back, coop_max_back, t)
		_coop_back_distance = lerpf(_coop_back_distance, back, clampf(delta * coop_zoom_smooth_speed * 60.0, 0.0, 1.0))
		back = _coop_back_distance
	camera.position = Vector3(shoulder_offset, height_offset, back)
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
	_coop_back_distance = coop_min_back


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
	var living := GameManager.get_alive_players()
	if living.size() == 1 and living[0] is Node3D:
		attach_to_player(living[0] as Node3D)
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


func _boss_separation_from_midpoint(midpoint: Vector3) -> float:
	var best := 0.0
	for node in get_tree().get_nodes_in_group("boss"):
		if not node is Node3D or not is_instance_valid(node):
			continue
		var dist: float = (node as Node3D).global_position.distance_to(midpoint)
		best = maxf(best, dist * 0.45 + coop_boss_zoom_padding * 0.25)
	return best


func get_planar_right() -> Vector3:
	return Vector3.UP.cross(get_planar_forward()).normalized()


func snap_to_player(player: Node3D) -> void:
	if player == null or not is_instance_valid(player):
		return
	_yaw = player.rotation.y
	_pitch = -0.12
	global_position = player.global_position + Vector3(0.0, pivot_height, 0.0)
	_snapped = true
	if _attach_player and is_instance_valid(_attach_player):
		_attach_player.rotation.y = _yaw
	_apply_look(_attach_player != null, get_physics_process_delta_time())


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
		TutorialPromptManager.try_show("camera")
		add_look_input(look * 0.04)
	if GameManager.is_local_coop():
		var look2 := InputManager.get_look_vector(1)
		if look2.length_squared() > 0.01:
			add_look_input(look2 * 0.04)
