extends Node3D
## Reads look input (gamepad + mouse) and drives the shared-screen camera.

@onready var camera: SharedScreenCamera = $SharedScreenCamera

var _mouse_captured: bool = false


func _ready() -> void:
	# Capture mouse when the level loads (not on main menu).
	call_deferred("_capture_mouse")


func _capture_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_mouse_captured = true


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and _mouse_captured:
		var motion := event as InputEventMouseMotion
		camera.add_look_input(motion.relative * camera.mouse_sensitivity)
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
		camera.add_look_input(look * 0.04)
