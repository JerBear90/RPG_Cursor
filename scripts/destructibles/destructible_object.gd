class_name DestructibleObject
extends StaticBody3D

@export var health: float = 30.0
@export var drop_table_id: String = "destructible_crate"
@export var resource_id: String = ""
@export var resource_yield: int = 0
@export var persistence_id: String = ""
@export var persist_destruction: bool = false

var _destroyed: bool = false
var _last_attacker_index: int = 0


func _ready() -> void:
	add_to_group("destructible")
	if persist_destruction and persistence_id != "" and WorldStateManager.is_object_destroyed(persistence_id):
		_apply_destroyed_state()


func take_damage(amount: float, source: Node = null) -> void:
	if _destroyed:
		return
	_cache_attacker(source)
	health -= amount
	if health <= 0.0:
		_destroy()


func receive_damage(damage: DamageData) -> void:
	take_damage(damage.amount, damage.source)


func take_hitbox_damage(damage: DamageData) -> void:
	receive_damage(damage)


func _cache_attacker(source: Node) -> void:
	if source is PlayerController:
		_last_attacker_index = (source as PlayerController).player_index
	elif source != null:
		var player := source.get_parent()
		if player is PlayerController:
			_last_attacker_index = (player as PlayerController).player_index


func _destroy() -> void:
	if _destroyed:
		return
	_destroyed = true
	if persist_destruction and persistence_id != "":
		WorldStateManager.mark_object_destroyed(persistence_id)
	if resource_id != "" and resource_yield > 0:
		if InventoryManager.add_item(resource_id, resource_yield):
			ResourceFeedbackManager.notify_player_pickup(_last_attacker_index, resource_id, resource_yield)
	elif drop_table_id != "":
		LootManager.drop_loot_table(drop_table_id, global_position + Vector3(0.0, 0.5, 0.0))
	TutorialPromptManager.try_show("destructible")
	AchievementManager.unlock("break_everything")
	_apply_destroyed_state()


func _apply_destroyed_state() -> void:
	_destroyed = true
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
