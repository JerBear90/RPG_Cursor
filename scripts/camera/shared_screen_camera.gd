class_name SharedScreenCamera
extends Camera3D
## Camera node — orbit math lives on parent CameraRig.


func _ready() -> void:
	current = true


func add_look_input(look: Vector2) -> void:
	var rig := get_parent()
	if rig and rig.has_method("add_look_input"):
		rig.add_look_input(look)


func get_planar_forward() -> Vector3:
	var rig := get_parent()
	if rig and rig.has_method("get_planar_forward"):
		return rig.get_planar_forward()
	return Vector3.FORWARD


func get_planar_right() -> Vector3:
	var rig := get_parent()
	if rig and rig.has_method("get_planar_right"):
		return rig.get_planar_right()
	return Vector3.RIGHT
