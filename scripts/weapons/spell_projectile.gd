extends Area3D

const SCHOOL_MESHES := {
	"fire": "res://art/kenney/nature_kit/Models/GLTF format/flower_redA.glb",
	"water": "res://art/kenney/nature_kit/Models/GLTF format/flower_purpleA.glb",
	"poison": "res://art/kenney/nature_kit/Models/GLTF format/mushroom_tan.glb",
}

var _damage: float = 10.0
var _speed: float = 15.0
var _direction: Vector3 = Vector3.FORWARD
var _source: Node
var _school: String = "fire"


func setup(data: Dictionary, direction: Vector3, source: Node) -> void:
	_damage = data.get("damage", 10.0)
	_speed = data.get("speed", 15.0)
	_school = data.get("school", "fire")
	_direction = direction.normalized()
	_source = source
	_spawn_visual()
	area_entered.connect(_on_area_entered)
	get_tree().create_timer(5.0).timeout.connect(queue_free)


func _spawn_visual() -> void:
	for child in get_children():
		if child is Node3D and child.name == "SpellVisual":
			child.queue_free()
	var path: String = SCHOOL_MESHES.get(_school, SCHOOL_MESHES.fire)
	var visual_root := Node3D.new()
	visual_root.name = "SpellVisual"
	add_child(visual_root)
	MeshLoader.instantiate(path, visual_root, 0.0, Vector3.ZERO, Vector3(0.35, 0.35, 0.35))


func _physics_process(delta: float) -> void:
	global_position += _direction * _speed * delta


func _on_area_entered(area: Area3D) -> void:
	if area is Hurtbox:
		var hurtbox := area as Hurtbox
		if hurtbox.team == "player":
			return
		var dmg := DamageData.create_physical(_damage, _source)
		hurtbox.hit_received.emit(dmg, self)
		CombatVfx.spawn_spell(global_position)
		AudioManager.play_sfx("spell", randf_range(0.95, 1.05))
		queue_free()
