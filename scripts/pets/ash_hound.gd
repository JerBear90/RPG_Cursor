extends Node3D
## Ash Hound companion — follows the player and attacks nearby enemies.

const HOUND_GLTF := "res://art/characters/_quaternius_zombie_kit/Characters/glTF/Characters_GermanShepherd.gltf"

@export var follow_speed: float = 6.0
@export var follow_distance: float = 1.2
@export var attack_range: float = 2.5
@export var attack_damage: float = 8.0
@export var attack_cooldown_time: float = 1.2
@export var scan_range: float = 12.0

var _owner: Node3D
var _anchor: Node3D
var _attack_cd: float = 0.0
var _hitbox: Hitbox
var _attack_target: Node3D
var _command: String = "follow"
var _guard_position: Vector3 = Vector3.ZERO


func setup(owner_player: Node3D) -> void:
	_owner = owner_player
	_anchor = owner_player.get_node_or_null("PetAnchor")
	_setup_hitbox()
	call_deferred("_spawn_mesh")
	if owner_player is PlayerController:
		set_command(PetManager.get_pet_command((owner_player as PlayerController).player_index))


func set_command(command_id: String) -> void:
	_command = command_id
	if _command == "guard":
		_guard_position = global_position


func _setup_hitbox() -> void:
	_hitbox = Hitbox.new()
	_hitbox.name = "BiteHitbox"
	_hitbox.team = "player"
	_hitbox.base_damage = attack_damage
	var shape_node := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.6
	shape_node.shape = sphere
	_hitbox.add_child(shape_node)
	add_child(_hitbox)


func _spawn_mesh() -> void:
	if MeshLoader.instantiate(HOUND_GLTF, self, 0.0, Vector3.ZERO, Vector3(0.85, 0.85, 0.85)) == null:
		push_warning("AshHound: failed to load %s" % HOUND_GLTF)


func _physics_process(delta: float) -> void:
	if _owner == null or not is_instance_valid(_owner):
		return
	_attack_cd = maxf(_attack_cd - delta, 0.0)
	match _command:
		"guard":
			return
		"hunt":
			_attack_target = _find_nearest_enemy(18.0)
		_:
			_attack_target = _find_nearest_enemy(scan_range)
	if _attack_target and _try_attack():
		return
	_follow_owner(delta)


func _find_nearest_enemy(range_limit: float) -> Node3D:
	var nearest: Node3D = null
	var nearest_dist := range_limit
	for node in get_tree().get_nodes_in_group("lockable_enemy"):
		if not is_instance_valid(node) or node == self:
			continue
		if node.has_node("HealthComponent"):
			var health := node.get_node("HealthComponent") as HealthComponent
			if not health.is_alive():
				continue
		var dist := global_position.distance_to(node.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = node
	return nearest


func _try_attack() -> bool:
	if _attack_target == null or _attack_cd > 0.0:
		return false
	var dist := global_position.distance_to(_attack_target.global_position)
	if dist > attack_range:
		return false
	var dir := (_attack_target.global_position - global_position)
	dir.y = 0.0
	if dir.length_squared() > 0.01:
		rotation.y = atan2(dir.x, dir.z)
	_hitbox.base_damage = attack_damage
	_hitbox.enable()
	get_tree().create_timer(0.25).timeout.connect(_hitbox.disable)
	_attack_cd = attack_cooldown_time
	return true


func _follow_owner(delta: float) -> void:
	var target := _anchor.global_position if _anchor else _owner.global_position + Vector3(-1.0, 0, 0.5)
	var to_target := target - global_position
	to_target.y = 0.0
	var dist := to_target.length()
	if dist > follow_distance:
		var dir := to_target.normalized()
		global_position += dir * follow_speed * delta
		if dir.length_squared() > 0.01:
			rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), 8.0 * delta)
