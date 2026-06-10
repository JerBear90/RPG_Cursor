class_name NpcController
extends CharacterBody3D

@export var npc_id: String = "silent_merchant"
@export var display_name: String = "Silent Merchant"
@export var is_merchant: bool = false
@export var is_quest_giver: bool = false
@export var prompt_text: String = "Talk"

var anger_state: String = "calm"


func _ready() -> void:
	add_to_group("npc")
	add_to_group("interactable")
	_setup_friendly_fire_hurtbox()


func _setup_friendly_fire_hurtbox() -> void:
	if get_node_or_null("FriendlyFireHurtbox"):
		return
	var hurtbox := Hurtbox.new()
	hurtbox.name = "FriendlyFireHurtbox"
	hurtbox.team = "npc"
	var shape_node := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.6
	shape_node.shape = capsule
	shape_node.position = Vector3(0, 0.8, 0)
	hurtbox.add_child(shape_node)
	add_child(hurtbox)


func interact(player: Node) -> void:
	if anger_state == "hostile":
		DialogueManager.start_dialogue(npc_id, [{"speaker": display_name, "text": "Come back when you've cooled off."}])
		return
	if is_merchant:
		_try_quest_delivery()
		var lines := DialogueManager.get_npc_greeting(npc_id)
		DialogueManager.start_dialogue(npc_id, lines)
		await DialogueManager.dialogue_ended
		for hud in get_tree().get_nodes_in_group("game_hud"):
			hud.open_merchant_menu()
		return
	var greet := DialogueManager.get_npc_greeting(npc_id)
	DialogueManager.start_dialogue(npc_id, greet)
	if is_quest_giver and npc_id == "wounded_scout":
		QuestManager.start_quest("merchant_errand")


func _try_quest_delivery() -> void:
	if not QuestManager.active_quests.has("merchant_errand"):
		return
	if InventoryManager.get_item_count("herb_bundle") < 3:
		return
	InventoryManager.remove_item("herb_bundle", 3)
	QuestManager.advance_objective("merchant_errand", "deliver_herbs", 3)
	DialogueManager.start_dialogue(npc_id, [
		{"speaker": display_name, "text": "These herbs will keep someone alive another night. Take this."},
	])
	CurrencyManager.add_silver(1)


func receive_friendly_fire() -> void:
	if anger_state == "calm":
		anger_state = "annoyed"
		DialogueManager.start_dialogue(npc_id, [{"speaker": display_name, "text": "Oi! Swing that thing at me again and I'll charge you double."}])
		AchievementManager.unlock("angry_vendor")
	elif anger_state == "annoyed":
		anger_state = "angry"
