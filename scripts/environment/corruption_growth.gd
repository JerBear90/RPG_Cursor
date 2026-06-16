class_name CorruptionGrowth
extends StaticBody3D
## Destructible corruption growth — releases resources and clears nearby exposure.

const _ResourceNode := preload("res://scripts/resources/resource_node.gd")

@export var resource_id: String = "corrupted_fiber"
@export var resource_amount: int = 2
@export var quest_objective_id: String = ""
@export var quest_id: String = "the_withered_fields"

var _destroyed: bool = false


func _ready() -> void:
	add_to_group("corruption_growth")
	add_to_group("destructible")
	if get_node_or_null("InteractionArea") == null:
		var area := Area3D.new()
		area.name = "InteractionArea"
		area.collision_layer = 0
		area.collision_mask = 2
		area.monitoring = true
		var col := CollisionShape3D.new()
		var sp := SphereShape3D.new()
		sp.radius = 1.8
		col.shape = sp
		area.add_child(col)
		add_child(area)
		area.body_entered.connect(_on_player_near)


func _on_player_near(body: Node3D) -> void:
	if not body.is_in_group("player") or _destroyed:
		return
	if body.has_method("get_attack_damage"):
		return
	if Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("heavy_attack"):
		_destroy(body)


func take_damage(_amount: float, _type: int = 0) -> void:
	if not _destroyed:
		_destroy(null)


func _destroy(attacker: Node) -> void:
	if _destroyed:
		return
	_destroyed = true
	AudioManager.play_sfx("fungal_burst", 0.85)
	if resource_id != "":
		InventoryManager.add_item(resource_id, resource_amount)
		ResourceFeedbackManager.show_pickup(resource_id, resource_amount)
	if quest_id != "" and quest_objective_id != "":
		QuestManager.advance_objective(quest_id, quest_objective_id, 1)
	for player in GameManager.get_alive_players():
		if player.has_node("StatusEffectsComponent"):
			player.get_node("StatusEffectsComponent").clear_blight_exposure()
	queue_free()
