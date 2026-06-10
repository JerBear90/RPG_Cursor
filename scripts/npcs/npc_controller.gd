class_name NpcController
extends CharacterBody3D

@export var npc_id: String = "silent_merchant"
@export var display_name: String = "Silent Merchant"
@export var is_merchant: bool = false
@export var is_quest_giver: bool = false
@export var prompt_text: String = "Talk"
@export var hostile_damage: float = 12.0
@export var hostile_health: float = 80.0
@export var hostile_speed: float = 4.0

var anger_state: String = "calm"
var _health: HealthComponent
var _attack_hitbox: Hitbox
var _attack_cd: float = 0.0
var _combat_target: Node3D
var _gravity: float = 20.0


func _ready() -> void:
	add_to_group("npc")
	add_to_group("interactable")
	_setup_friendly_fire_hurtbox()


func _physics_process(delta: float) -> void:
	if anger_state != "hostile":
		return
	if not is_on_floor():
		velocity.y -= _gravity * delta
	_attack_cd = maxf(_attack_cd - delta, 0.0)
	_combat_target = GameManager.get_player(0)
	if _combat_target == null or not is_instance_valid(_combat_target):
		return
	var dist := global_position.distance_to(_combat_target.global_position)
	var dir := (_combat_target.global_position - global_position)
	dir.y = 0.0
	if dir.length_squared() > 0.01:
		look_at(global_position + dir.normalized(), Vector3.UP)
	if dist <= 2.0:
		velocity.x = 0.0
		velocity.z = 0.0
		_try_hostile_attack()
	else:
		var move_dir := dir.normalized()
		velocity.x = move_dir.x * hostile_speed
		velocity.z = move_dir.z * hostile_speed
	move_and_slide()


func interact(player: Node) -> void:
	if anger_state == "hostile":
		DialogueManager.start_dialogue(npc_id, [{"speaker": display_name, "text": "You wanted a fight. Now you've got one."}])
		return
	if is_merchant:
		_try_quest_delivery()
		var lines := DialogueManager.get_npc_greeting(npc_id)
		DialogueManager.start_dialogue(npc_id, lines)
		await DialogueManager.dialogue_ended
		for hud in get_tree().get_nodes_in_group("game_hud"):
			hud.open_merchant_menu(npc_id, anger_state)
		return
	var greet := DialogueManager.get_npc_greeting(npc_id)
	DialogueManager.start_dialogue(npc_id, greet)
	if is_quest_giver and npc_id == "wounded_scout":
		QuestManager.start_quest("merchant_errand")


func receive_friendly_fire() -> void:
	if anger_state == "calm":
		anger_state = "annoyed"
		DialogueManager.start_dialogue(npc_id, [{"speaker": display_name, "text": "Oi! Swing that thing at me again and I'll charge you double."}])
		AchievementManager.unlock("angry_vendor")
	elif anger_state == "annoyed":
		anger_state = "angry"
		DialogueManager.start_dialogue(npc_id, [{"speaker": display_name, "text": "That's it. Prices just doubled — and I'm not feeling merciful."}])
	elif anger_state == "angry":
		_enable_combat_mode()


func receive_damage(damage: DamageData) -> void:
	if _health:
		_health.take_damage(damage)


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


func _enable_combat_mode() -> void:
	if anger_state == "hostile":
		return
	anger_state = "hostile"
	add_to_group("lockable_enemy")
	DialogueManager.start_dialogue(npc_id, [{"speaker": display_name, "text": "Fine. We'll settle this the old way."}])
	GameManager.set_combat_state(true)
	_setup_combat_components()


func _setup_combat_components() -> void:
	if _health == null:
		_health = HealthComponent.new()
		_health.name = "HealthComponent"
		_health.max_health = hostile_health
		add_child(_health)
		_health.reset_health()
		_health.died.connect(_on_hostile_died)
	var hurtbox := get_node_or_null("FriendlyFireHurtbox") as Hurtbox
	if hurtbox:
		hurtbox.team = "enemy"
	if _attack_hitbox == null:
		_attack_hitbox = Hitbox.new()
		_attack_hitbox.name = "AttackHitbox"
		_attack_hitbox.team = "enemy"
		_attack_hitbox.base_damage = hostile_damage
		var shape_node := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(1.2, 1.0, 1.2)
		shape_node.shape = box
		shape_node.position = Vector3(0, 0.8, 0.6)
		_attack_hitbox.add_child(shape_node)
		add_child(_attack_hitbox)


func _try_hostile_attack() -> void:
	if _attack_cd > 0.0 or _attack_hitbox == null:
		return
	_attack_cd = 1.4
	_attack_hitbox.base_damage = hostile_damage
	_attack_hitbox.enable()
	get_tree().create_timer(0.3).timeout.connect(_attack_hitbox.disable)


func _on_hostile_died() -> void:
	LootManager.drop_currency(randi_range(5, 15), global_position)
	InventoryManager.add_item("cloth_scrap", 2)
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("show_toast"):
			hud.show_toast("%s defeated" % display_name)
	queue_free()


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
