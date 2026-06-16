class_name CathedralQuestTrigger
extends Area3D
## Advances cathedral quest objectives when the player enters a room.

@export var quest_id: String = "heart_of_the_blight"
@export var objective_id: String = ""


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	if get_child_count() == 0:
		var col := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(6, 3, 6)
		col.shape = box
		add_child(col)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player") or objective_id == "":
		return
	if QuestManager.active_quests.has(quest_id):
		QuestManager.advance_objective(quest_id, objective_id, 1)
	queue_free()
