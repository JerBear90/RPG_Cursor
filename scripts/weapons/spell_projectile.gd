extends Area3D

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
	area_entered.connect(_on_area_entered)
	get_tree().create_timer(5.0).timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	global_position += _direction * _speed * delta


func _on_area_entered(area: Area3D) -> void:
	if area is Hurtbox:
		var hurtbox := area as Hurtbox
		if hurtbox.team == "player":
			return
		var dmg := DamageData.create_physical(_damage, _source)
		hurtbox.hit_received.emit(dmg, self)
		queue_free()
