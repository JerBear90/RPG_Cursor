extends Area3D

const SCHOOL_MESHES := {
	"fire": "res://art/kenney/nature_kit/Models/GLTF format/flower_redA.glb",
	"water": "res://art/kenney/nature_kit/Models/GLTF format/flower_purpleA.glb",
	"poison": "res://art/kenney/nature_kit/Models/GLTF format/mushroom_tan.glb",
	"dark": "res://art/kenney/nature_kit/Models/GLTF format/rock_smallA.glb",
}

const _StatusEffects := preload("res://scripts/combat/status_effects_component.gd")

var _damage: float = 10.0
var _speed: float = 15.0
var _direction: Vector3 = Vector3.FORWARD
var _source: Node
var _school: String = "fire"
var _status_effect: String = ""
var _status_tick_damage: float = 0.0
var _status_tick_count: int = 0
var _status_tick_interval: float = 1.0


func setup(data: Dictionary, direction: Vector3, source: Node) -> void:
	_damage = data.get("damage", 10.0)
	_speed = data.get("speed", 15.0)
	_school = data.get("school", "fire")
	_direction = direction.normalized()
	_source = source
	_status_effect = str(data.get("status_effect", ""))
	_status_tick_damage = float(data.get("status_tick_damage", 0.0))
	_status_tick_count = int(data.get("status_tick_count", 0))
	_status_tick_interval = float(data.get("status_tick_interval", 1.0))
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
		var dmg := _build_damage()
		hurtbox.hit_received.emit(dmg, self)
		_apply_status(hurtbox)
		CombatVfx.spawn_spell(global_position)
		AudioManager.play_sfx("spell", randf_range(0.95, 1.05))
		queue_free()


func _build_damage() -> DamageData:
	var dmg := DamageData.new()
	dmg.amount = _damage
	dmg.source = _source
	match _school:
		"fire":
			dmg.damage_type = DamageData.DamageType.FIRE
		"water":
			dmg.damage_type = DamageData.DamageType.WATER
		"poison":
			dmg.damage_type = DamageData.DamageType.POISON
		"dark":
			dmg.damage_type = DamageData.DamageType.DARK
		_:
			dmg.damage_type = DamageData.DamageType.PHYSICAL
	return dmg


func _apply_status(hurtbox: Hurtbox) -> void:
	if _status_effect != "poison" or _status_tick_count <= 0:
		return
	var owner := hurtbox.get_parent()
	if owner == null or not owner.has_node("StatusEffectsComponent"):
		return
	var status := owner.get_node("StatusEffectsComponent") as StatusEffectsComponent
	if status.has_method("apply_spell_poison_dot"):
		status.apply_spell_poison_dot(_status_tick_damage, _status_tick_count, _status_tick_interval, _source)
