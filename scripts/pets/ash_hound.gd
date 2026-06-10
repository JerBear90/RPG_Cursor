extends Node3D
## Ash Hound companion — follows the player's PetAnchor.

const HOUND_GLTF := "res://art/characters/_quaternius_zombie_kit/Characters/glTF/Characters_GermanShepherd.gltf"

@export var follow_speed: float = 6.0
@export var follow_distance: float = 1.2

var _owner: Node3D
var _anchor: Node3D
var _visual: Node3D


func setup(owner_player: Node3D) -> void:
	_owner = owner_player
	_anchor = owner_player.get_node_or_null("PetAnchor")
	call_deferred("_spawn_mesh")


func _spawn_mesh() -> void:
	_visual = MeshLoader.instantiate(HOUND_GLTF, self, 0.0, Vector3.ZERO, Vector3(0.85, 0.85, 0.85))
	if _visual == null:
		var fallback := MeshInstance3D.new()
		var capsule := CapsuleMesh.new()
		capsule.radius = 0.25
		capsule.height = 0.6
		fallback.mesh = capsule
		fallback.position = Vector3(0, 0.3, 0)
		add_child(fallback)


func _physics_process(delta: float) -> void:
	if _owner == null or not is_instance_valid(_owner):
		return
	var target := _anchor.global_position if _anchor else _owner.global_position + Vector3(-1.0, 0, 0.5)
	var to_target := target - global_position
	to_target.y = 0.0
	var dist := to_target.length()
	if dist > follow_distance:
		var dir := to_target.normalized()
		global_position += dir * follow_speed * delta
		if dir.length_squared() > 0.01:
			rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), 8.0 * delta)
