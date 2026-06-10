class_name DestructibleObject
extends StaticBody3D

@export var health: float = 30.0
@export var drop_table_id: String = "destructible_crate"

var _mesh: MeshInstance3D
var _destroyed: bool = false


func _ready() -> void:
	_mesh = get_node_or_null("MeshInstance3D")


func take_damage(amount: float, _source: Node = null) -> void:
	if _destroyed:
		return
	health -= amount
	if health <= 0.0:
		_destroy()


func receive_damage(damage: DamageData) -> void:
	take_damage(damage.amount, damage.source)


func take_hitbox_damage(damage: DamageData) -> void:
	receive_damage(damage)


func _destroy() -> void:
	_destroyed = true
	LootManager.drop_loot_table(drop_table_id, global_position)
	AchievementManager.unlock("break_everything")
	if _mesh:
		_mesh.visible = false
	set_collision_layer_value(1, false)
