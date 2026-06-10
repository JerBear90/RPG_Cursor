extends Node3D
## Loads Quaternius CC0 character meshes per player slot.

signal visual_ready

const PLAYER1_MESH_PATH := "res://art/characters/player1/exiled_survivor_matt.gltf"
const PLAYER2_MESH_PATH := "res://art/characters/_quaternius_zombie_kit/Characters/glTF/Characters_Sam_SingleWeapon.gltf"

@export var player_index: int = 0
@export var mesh_yaw_degrees: float = 180.0
@export var mesh_offset: Vector3 = Vector3.ZERO
@export var mesh_scale: Vector3 = Vector3.ONE


func _ready() -> void:
	var player := get_parent().get_parent() as PlayerController
	if player:
		player_index = player.player_index
	call_deferred("_setup_visual")


func _setup_visual() -> void:
	var path := PLAYER1_MESH_PATH if player_index == 0 else PLAYER2_MESH_PATH
	var packed: PackedScene = MeshLoader.load_scene(path)
	if packed == null:
		push_warning("PlayerVisual: failed to load %s — using placeholder" % path)
		_add_placeholder()
		visual_ready.emit()
		return
	for child in get_children():
		child.queue_free()
	var visual: Node3D = packed.instantiate()
	add_child(visual)
	visual.rotation_degrees = Vector3(0, mesh_yaw_degrees, 0)
	visual.position = mesh_offset
	visual.scale = mesh_scale
	visual_ready.emit()


func _add_placeholder() -> void:
	for child in get_children():
		child.queue_free()
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.height = 1.4
	capsule.radius = 0.35
	body.mesh = capsule
	body.position = Vector3(0.0, 0.85, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.38, 0.45, 0.52)
	body.material_override = mat
	add_child(body)
