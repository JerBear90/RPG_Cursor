class_name DestructibleObject
extends StaticBody3D

@export var health: float = 30.0
@export var drop_table_id: String = "destructible_crate"
@export var resource_id: String = ""
@export var resource_yield: int = 0

var _destroyed: bool = false


func _ready() -> void:
	add_to_group("destructible")


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
	if _destroyed:
		return
	_destroyed = true
	var rewards: Dictionary = {}
	if resource_id != "" and resource_yield > 0:
		if InventoryManager.add_item(resource_id, resource_yield):
			rewards[resource_id] = resource_yield
			ResourceFeedbackManager.notify_granted(rewards)
	elif drop_table_id != "":
		LootManager.drop_loot_table(drop_table_id, global_position + Vector3(0.0, 0.5, 0.0))
	AchievementManager.unlock("break_everything")
	_hide_visuals()
	collision_layer = 0
	var hurtbox := get_node_or_null("Hurtbox") as Area3D
	if hurtbox:
		hurtbox.set_deferred("monitoring", false)
		hurtbox.set_deferred("monitorable", false)


func _hide_visuals() -> void:
	for child in get_children():
		if child is Area3D:
			child.visible = false
			continue
		if child is CollisionShape3D:
			(child as CollisionShape3D).set_deferred("disabled", true)
			continue
		if child is Node3D:
			(child as Node3D).visible = false
