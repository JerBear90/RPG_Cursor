class_name EnemyRespawner
extends Node
## Respawns a defeated enemy after a delay at its original spawn point.

var _scene_path: String = ""
var _spawn_transform: Transform3D
var _delay_sec: float = 300.0


static func schedule(
	parent: Node,
	scene_path: String,
	spawn_transform: Transform3D,
	delay_sec: float = 300.0
) -> void:
	if scene_path == "" or parent == null:
		return
	var script := load("res://scripts/ai/enemy_respawner.gd") as Script
	var runner: Node = script.new()
	runner._scene_path = scene_path
	runner._spawn_transform = spawn_transform
	runner._delay_sec = delay_sec
	parent.add_child(runner)


func _ready() -> void:
	await get_tree().create_timer(_delay_sec).timeout
	if not is_instance_valid(get_parent()):
		queue_free()
		return
	var packed := load(_scene_path) as PackedScene
	if packed == null:
		queue_free()
		return
	var enemy: Node3D = packed.instantiate()
	enemy.global_transform = _spawn_transform
	get_parent().add_child(enemy)
	queue_free()
