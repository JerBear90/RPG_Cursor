extends Node3D
## Swaps placeholder capsule for themed character meshes per player slot.

const PLAYER1_MESH_PATH := "res://art/characters/player1/exiled_survivor_matt.gltf"
const PLAYER2_MESH_PATH := "res://art/characters/_quaternius_zombie_kit/Characters/glTF/Characters_Sam_SingleWeapon.gltf"

@export var player_index: int = 0
@export var mesh_yaw_degrees: float = 0.0
@export var mesh_offset: Vector3 = Vector3.ZERO
@export var mesh_scale: Vector3 = Vector3.ONE

var _body_mesh: MeshInstance3D


func _ready() -> void:
	_body_mesh = get_parent().get_node_or_null("BodyMesh")
	var player := get_parent().get_parent() as PlayerController
	if player:
		player_index = player.player_index
	call_deferred("_setup_visual")


func _setup_visual() -> void:
	var path := PLAYER1_MESH_PATH if player_index == 0 else PLAYER2_MESH_PATH
	var packed: PackedScene = MeshLoader.load_scene(path)
	if packed == null:
		push_warning("PlayerVisual: failed to load %s" % path)
		return
	for child in get_children():
		child.queue_free()
	var visual: Node3D = packed.instantiate()
	add_child(visual)
	visual.rotation_degrees = Vector3(0, mesh_yaw_degrees, 0)
	visual.position = mesh_offset
	visual.scale = mesh_scale
	if _body_mesh:
		_body_mesh.visible = false
