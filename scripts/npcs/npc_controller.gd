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

const _INTERACT_OPTS := {"from_interact": true}

var anger_state: String = "calm"
var _health: HealthComponent
var _attack_hitbox: Hitbox
var _attack_cd: float = 0.0
var _combat_target: Node3D
var _gravity: float = 20.0
var _character_anim: GltfCharacterAnim
var _merchant_shop_open_requested: bool = false
var _merchant_dialogue_active: bool = false


func _ready() -> void:
	add_to_group("npc")
	add_to_group("interactable")
	if is_merchant:
		add_to_group("map_merchant")
		if not MerchantManager.shop_closed.is_connected(_on_merchant_shop_closed):
			MerchantManager.shop_closed.connect(_on_merchant_shop_closed)
	_setup_friendly_fire_hurtbox()
	_character_anim = GltfCharacterAnim.new()
	_character_anim.name = "CharacterAnim"
	add_child(_character_anim)
	call_deferred("_setup_character_anim")


func _setup_character_anim() -> void:
	CharacterAnimBinder.bind(self, _character_anim)


func _physics_process(delta: float) -> void:
	if anger_state != "hostile":
		if _character_anim.is_ready() and Vector2(velocity.x, velocity.z).length() <= 0.15:
			_character_anim.play_idle()
		velocity = Vector3.ZERO
		return
	PlanarFacing.apply_floor(self, delta, _gravity)
	_attack_cd = maxf(_attack_cd - delta, 0.0)
	_combat_target = GameManager.get_nearest_living_player(global_position)
	if _combat_target == null or not is_instance_valid(_combat_target):
		return
	var dist := global_position.distance_to(_combat_target.global_position)
	var dir := (_combat_target.global_position - global_position)
	dir.y = 0.0
	if dir.length_squared() > 0.01:
		PlanarFacing.face_direction(self, dir)
	if dist <= 2.0:
		velocity.x = 0.0
		velocity.z = 0.0
		_try_hostile_attack()
	else:
		var move_dir := dir.normalized()
		velocity.x = move_dir.x * hostile_speed
		velocity.z = move_dir.z * hostile_speed
	move_and_slide()
	if _character_anim.is_ready():
		var speed := Vector2(velocity.x, velocity.z).length()
		_character_anim.update_locomotion(speed, speed > hostile_speed * 0.75)


func interact(player: Node) -> void:
	if anger_state == "hostile":
		DialogueManager.start_dialogue(npc_id, [{"speaker": display_name, "text": "You wanted a fight. Now you've got one."}], [], _INTERACT_OPTS)
		return
	if is_merchant:
		_try_quest_delivery()
		if DialogueManager.is_active() or _merchant_dialogue_active:
			return
		_begin_merchant_trade_dialogue()
		return
	var greet := DialogueManager.get_npc_greeting(npc_id)
	DialogueManager.start_dialogue(npc_id, greet, [], _INTERACT_OPTS)
	if is_quest_giver and npc_id == "wounded_scout":
		QuestManager.start_quest("merchant_errand")


func _begin_merchant_trade_dialogue() -> void:
	_merchant_dialogue_active = true
	var lines := DialogueManager.get_npc_greeting(npc_id)
	var merchant_opts := _INTERACT_OPTS.duplicate()
	merchant_opts["confirm_label"] = "Trade"
	merchant_opts["cancel_label"] = "Leave"
	DialogueManager.start_dialogue(npc_id, lines, ["Trade", "Leave"], merchant_opts)
	if not DialogueManager.is_active():
		_merchant_dialogue_active = false
		return
	_await_merchant_dialogue_result()


func _await_merchant_dialogue_result() -> void:
	var payload: Array = await DialogueManager.dialogue_finished
	_merchant_dialogue_active = false
	if not is_instance_valid(self) or not is_merchant:
		return
	var finished_npc: String = str(payload[0])
	var reason: DialogueManager.DialogueEndReason = payload[1]
	if finished_npc != npc_id:
		return
	match reason:
		DialogueManager.DialogueEndReason.CONFIRMED:
			await _open_merchant_shop_once()
		_:
			pass


func _open_merchant_shop_once() -> void:
	if _merchant_shop_open_requested:
		return
	if not is_instance_valid(self):
		return
	_merchant_shop_open_requested = true
	await get_tree().process_frame
	if not is_instance_valid(self):
		_merchant_shop_open_requested = false
		return
	if MerchantManager.is_shop_open:
		_merchant_shop_open_requested = false
		return
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("open_merchant_menu"):
			hud.open_merchant_menu(npc_id, anger_state)
			break
	if not MerchantManager.is_shop_open:
		_merchant_shop_open_requested = false


func _on_merchant_shop_closed() -> void:
	_merchant_shop_open_requested = false


func _try_quest_delivery() -> void:
	if not QuestManager.active_quests.has("merchant_errand"):
		return
	if InventoryManager.get_item_count("herb_bundle") < 3:
		return
	InventoryManager.remove_item("herb_bundle", 3)
	QuestManager.advance_objective("merchant_errand", "deliver_herbs", 3)
	DialogueManager.start_dialogue(npc_id, [
		{"speaker": display_name, "text": "These herbs will keep someone alive another night. Take this."},
	], [], {"from_interact": false})
	CurrencyManager.add_silver(1)


func _enable_combat_mode() -> void:
	if anger_state == "hostile":
		return
	anger_state = "hostile"
	add_to_group("lockable_enemy")
	DialogueManager.start_dialogue(npc_id, [{"speaker": display_name, "text": "Fine. We'll settle this the old way."}], [], {"from_interact": false})
	GameManager.set_combat_state(true)
	_setup_combat_components()


func receive_friendly_fire() -> void:
	if anger_state == "calm":
		anger_state = "annoyed"
		DialogueManager.start_dialogue(npc_id, [{"speaker": display_name, "text": "Oi! Swing that thing at me again and I'll charge you double."}], [], {"from_interact": false})
		AchievementManager.unlock("angry_vendor")
	elif anger_state == "annoyed":
		anger_state = "angry"
		DialogueManager.start_dialogue(npc_id, [{"speaker": display_name, "text": "That's it. Prices just doubled — and I'm not feeling merciful."}], [], {"from_interact": false})
	elif anger_state == "angry":
		_enable_combat_mode()


func receive_damage(damage: DamageData) -> void:
	if _health:
		_health.take_damage(damage)


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
	for p in GameManager.get_alive_players():
		var to_player: Vector3 = p.global_position - global_position
		to_player.y = 0.0
		if to_player.length_squared() > 0.01:
			PlanarFacing.face_direction(self, to_player)
			break
	if _character_anim.is_ready():
		_character_anim.play_attack()
	var strike_damage := hostile_damage
	_attack_hitbox.base_damage = strike_damage
	_attack_hitbox.enable()
	var hitbox := _attack_hitbox
	get_tree().create_timer(0.3).timeout.connect(hitbox.disable)
	get_tree().create_timer(0.14).timeout.connect(
		func() -> void:
			_resolve_hostile_strike(hitbox, strike_damage),
		CONNECT_ONE_SHOT
	)


func _resolve_hostile_strike(hitbox: Hitbox, strike_damage: float) -> void:
	if hitbox and hitbox.landed_any_hit():
		return
	var target: Node3D = null
	var best := 2.5
	for p in GameManager.get_alive_players():
		var dist := global_position.distance_to(p.global_position)
		if dist < best:
			best = dist
			target = p
	if target == null or best > 2.5:
		return
	if target.has_method("receive_damage"):
		target.receive_damage(DamageData.create_physical(strike_damage, self))


func _on_hostile_died() -> void:
	if _character_anim.is_ready():
		_character_anim.play_death()
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
