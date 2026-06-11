class_name EnemyBase
extends CharacterBody3D
## Base enemy with AI states, combat, and loot.

const _EnemyHealthBar = preload("res://scripts/ui/enemy_health_bar.gd")
const _EnemyRespawner = preload("res://scripts/ai/enemy_respawner.gd")

enum AIState { IDLE, PATROL, ALERT, CHASE, ATTACK, STAGGERED, EXECUTION_READY, FLEE, DEAD }

signal state_changed(state: AIState)
signal enemy_died(enemy: EnemyBase)

@export var enemy_id: String = "forest_bandit"
@export var display_name: String = "Forest Bandit"
@export var enemy_level: int = 3
@export var max_health: float = 60.0
@export var damage: float = 10.0
@export var move_speed: float = 3.5
@export var detection_range: float = 10.0
@export var attack_range: float = 2.0
@export var loot_table_id: String = "forest_bandit"
@export var xp_reward: int = 25
@export var experience_reward: int = 15
@export var respawns: bool = true
@export var respawn_delay_sec: float = 300.0
@export var corpse_linger_sec: float = 5.0
@export var head_bar_offset: float = 2.15

var current_state: AIState = AIState.IDLE
var _health: HealthComponent
var _nav: NavigationAgent3D
var _target: Node3D = null
var _attack_cooldown: float = 0.0
var _staggered_timer: float = 0.0
var _patrol_points: Array[Vector3] = []
var _patrol_index: int = 0
var _gravity: float = 20.0
var _character_anim: GltfCharacterAnim
var _health_bar: Node3D
var _spawn_transform: Transform3D
var _death_sequence_running: bool = false
var _death_reward_granted: bool = false
var _last_player_killer: Node = null


func _ready() -> void:
	add_to_group("enemy")
	add_to_group("lockable_enemy")
	_health = get_node("HealthComponent")
	_nav = get_node("NavigationAgent3D")
	_health.max_health = max_health
	_health.reset_health()
	_health.died.connect(_on_died)
	_health.damaged.connect(_on_health_damaged)
	_setup_health_bar()
	_setup_patrol()
	_character_anim = GltfCharacterAnim.new()
	_character_anim.name = "CharacterAnim"
	add_child(_character_anim)
	call_deferred("_capture_spawn_transform")
	call_deferred("_setup_character_anim")
	call_deferred("_setup_navigation")
	call_deferred("_snap_to_ground")


func _snap_to_ground() -> void:
	const _SpawnHelpers = preload("res://scripts/utilities/spawn_helpers.gd")
	_SpawnHelpers.snap_character_to_ground(self)


func _setup_navigation() -> void:
	await get_tree().physics_frame
	if _nav:
		_nav.target_position = global_position


func _capture_spawn_transform() -> void:
	_spawn_transform = global_transform


func _setup_health_bar() -> void:
	_health_bar = _EnemyHealthBar.new()
	_health_bar.head_offset = head_bar_offset
	add_child(_health_bar)
	_health_bar.bind(_health)


func _setup_character_anim() -> void:
	CharacterAnimBinder.bind(self, _character_anim)


func _physics_process(delta: float) -> void:
	if current_state == AIState.DEAD:
		PlanarFacing.apply_floor(self, delta, _gravity)
		move_and_slide()
		return
	PlanarFacing.apply_floor(self, delta, _gravity)
	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
	if _staggered_timer > 0.0:
		_staggered_timer -= delta
		if _staggered_timer <= 0.0:
			_set_state(AIState.CHASE)
		return
	match current_state:
		AIState.IDLE, AIState.PATROL:
			_update_patrol(delta)
			_scan_for_player()
		AIState.ALERT:
			_set_state(AIState.CHASE)
		AIState.CHASE:
			_chase_target(delta)
		AIState.ATTACK:
			_perform_attack()
		AIState.STAGGERED, AIState.EXECUTION_READY:
			velocity = Vector3.ZERO
	move_and_slide()
	_update_character_anim()


func _update_character_anim() -> void:
	if not _character_anim.is_ready():
		return
	match current_state:
		AIState.DEAD:
			return
		AIState.ATTACK, AIState.STAGGERED, AIState.EXECUTION_READY:
			return
		AIState.CHASE:
			var speed := Vector2(velocity.x, velocity.z).length()
			_character_anim.update_locomotion(speed, true)
		_:
			var speed := Vector2(velocity.x, velocity.z).length()
			_character_anim.update_locomotion(speed, false)


func receive_damage(dmg: DamageData) -> void:
	if current_state == AIState.DEAD:
		return
	var killer := CombatExperienceManager.resolve_player_owner(dmg.source)
	if killer:
		_last_player_killer = killer
	_aggro_from_damage(dmg)
	var result: RefCounted = _health.apply_damage(dmg)
	if result.accepted and result.final_damage > 0.0 and killer:
		CombatExperienceManager.try_award_hit_xp(killer, result.final_damage, self)
	if dmg.stagger >= 15.0:
		_stagger(1.0)
	elif _character_anim.is_ready():
		_character_anim.play_hit()
	if _health.is_near_death():
		_set_state(AIState.EXECUTION_READY)


func _on_health_damaged(_damage: DamageData, _remaining: float) -> void:
	CombatVfx.spawn_blood(global_position + Vector3(0, head_bar_offset * 0.55, 0))


func is_alive() -> bool:
	return _health.is_alive()


func get_level() -> int:
	return enemy_level


func is_execution_ready() -> bool:
	return current_state == AIState.EXECUTION_READY or (
		_health.is_near_death() and current_state == AIState.STAGGERED
	)


func execute(killer: Node) -> void:
	_health.take_damage(DamageData.create_physical(9999.0, killer))
	LootManager.drop_loot_table(loot_table_id, global_position)


func _scan_for_player() -> void:
	for p in GameManager.get_alive_players():
		if global_position.distance_to(p.global_position) <= detection_range:
			_target = p
			_set_state(AIState.ALERT)
			GameManager.set_combat_state(true)
			return


func _chase_target(_delta: float) -> void:
	if not is_instance_valid(_target):
		_set_state(AIState.PATROL)
		return
	var dist := global_position.distance_to(_target.global_position)
	if dist <= attack_range:
		_set_state(AIState.ATTACK)
		return
	_nav.target_position = _target.global_position
	var to_target := _target.global_position - global_position
	to_target.y = 0.0
	var direction := Vector3.ZERO
	if to_target.length_squared() > 0.04:
		direction = to_target.normalized()
	else:
		var next := _nav.get_next_path_position()
		var to_next := next - global_position
		to_next.y = 0.0
		if to_next.length_squared() > 0.04:
			direction = to_next.normalized()
	if direction.length_squared() < 0.01:
		return
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed
	PlanarFacing.face_direction(self, direction)


func _aggro_from_damage(dmg: DamageData) -> void:
	var source := dmg.source
	if source == null:
		return
	var attacker: Node3D = null
	if source is Node3D:
		attacker = source as Node3D
	elif source.get_parent() is Node3D:
		attacker = source.get_parent() as Node3D
	if attacker == null:
		return
	if attacker.is_in_group("player") or attacker.is_in_group("pet"):
		_target = attacker
		if current_state != AIState.ATTACK:
			_set_state(AIState.CHASE)
		GameManager.set_combat_state(true)


func _perform_attack() -> void:
	if not is_instance_valid(_target):
		_set_state(AIState.PATROL)
		return
	if _attack_cooldown > 0.0:
		return
	_attack_cooldown = 1.5
	var to_target := _target.global_position - global_position
	to_target.y = 0.0
	if to_target.length_squared() > 0.01:
		PlanarFacing.face_direction(self, to_target)
	if _character_anim.is_ready():
		_character_anim.play_attack()
	var hitbox := get_node_or_null("AttackHitbox") as Hitbox
	var target := _target
	var strike_damage := damage
	if hitbox:
		hitbox.base_damage = strike_damage
		hitbox.enable()
		get_tree().create_timer(0.3).timeout.connect(hitbox.disable)
		get_tree().create_timer(0.14).timeout.connect(
			func() -> void:
				_resolve_melee_strike(hitbox, target, strike_damage),
			CONNECT_ONE_SHOT
		)
	elif is_instance_valid(target) and target.has_method("receive_damage"):
		if global_position.distance_to(target.global_position) <= attack_range * 1.35:
			target.receive_damage(DamageData.create_physical(strike_damage, self))
	if global_position.distance_to(_target.global_position) > attack_range * 1.5:
		_set_state(AIState.CHASE)


func _resolve_melee_strike(hitbox: Hitbox, target: Node3D, strike_damage: float) -> void:
	if not is_instance_valid(target) or current_state == AIState.DEAD:
		return
	if hitbox and hitbox.landed_any_hit():
		return
	if global_position.distance_to(target.global_position) > attack_range * 1.35:
		return
	if target.has_method("receive_damage"):
		target.receive_damage(DamageData.create_physical(strike_damage, self))


func _stagger(duration: float) -> void:
	_staggered_timer = duration
	if _character_anim.is_ready():
		_character_anim.play_hit()
	_set_state(AIState.STAGGERED)


func _on_died() -> void:
	if _death_sequence_running:
		return
	_death_sequence_running = true
	_set_state(AIState.DEAD)
	_disable_combat()
	velocity = Vector3.ZERO
	if _health_bar:
		_health_bar.visible = false
	if _character_anim.is_ready():
		_character_anim.play_death()
		get_tree().create_timer(0.85).timeout.connect(_play_fall_tween)
	else:
		_play_fall_tween()
	CombatVfx.spawn_death(global_position + Vector3(0, 0.8, 0))
	CombatVfx.spawn_blood(global_position + Vector3(0, head_bar_offset * 0.55, 0))
	AudioManager.play_sfx("death", randf_range(0.85, 1.0))
	LootManager.drop_loot_table(loot_table_id, global_position)
	LootManager.drop_currency(randi_range(2, 10), global_position)
	_award_kill_experience()
	if "first_blood" not in QuestManager.completed_quests:
		if not QuestManager.active_quests.has("first_blood"):
			QuestManager.start_quest("first_blood")
		QuestManager.advance_objective("first_blood", "kill_enemy", 1)
	RegionContent.on_enemy_killed(GameManager.current_region_id, enemy_id)
	enemy_died.emit(self)
	_schedule_respawn()
	await get_tree().create_timer(corpse_linger_sec).timeout
	if not is_instance_valid(self):
		return
	var mesh_root := get_node_or_null("MeshRoot") as Node3D
	if mesh_root:
		var fade := mesh_root.create_tween()
		fade.tween_property(mesh_root, "scale", Vector3.ZERO, 0.45)
		await fade.finished
	queue_free()


func _award_kill_experience() -> void:
	if _death_reward_granted:
		return
	_death_reward_granted = true
	var reward := experience_reward if experience_reward > 0 else xp_reward
	var killer := _last_player_killer
	if killer == null or not is_instance_valid(killer):
		return
	CombatExperienceManager.try_award_kill_xp(killer, reward, display_name)


func _disable_combat() -> void:
	collision_layer = 0
	collision_mask = 0
	var hurtbox := get_node_or_null("Hurtbox") as Area3D
	if hurtbox:
		hurtbox.set_deferred("monitoring", false)
	var hitbox := get_node_or_null("AttackHitbox") as Hitbox
	if hitbox:
		hitbox.disable()
	remove_from_group("lockable_enemy")


func _play_fall_tween() -> void:
	var mesh_root := get_node_or_null("MeshRoot") as Node3D
	if mesh_root == null:
		return
	var tween := mesh_root.create_tween()
	tween.tween_property(mesh_root, "rotation_degrees:x", -90.0, 0.55).set_ease(Tween.EASE_IN)


func _schedule_respawn() -> void:
	if not respawns:
		return
	var parent := get_parent()
	if parent == null:
		return
	var scene_path := scene_file_path
	if scene_path == "":
		return
	_EnemyRespawner.schedule(parent, scene_path, _spawn_transform, respawn_delay_sec)


func _set_state(state: AIState) -> void:
	if state == AIState.ALERT and is_in_group("boss"):
		GameManager.in_boss_fight = true
		for hud in get_tree().get_nodes_in_group("game_hud"):
			if hud.has_method("track_boss"):
				hud.track_boss(self)
	current_state = state
	state_changed.emit(state)


func _setup_patrol() -> void:
	_patrol_points.append(global_position)
	_patrol_points.append(global_position + Vector3(3, 0, 0))
	_patrol_points.append(global_position + Vector3(3, 0, 3))


func _update_patrol(_delta: float) -> void:
	if _patrol_points.is_empty():
		return
	var target := _patrol_points[_patrol_index]
	if global_position.distance_to(target) < 0.5:
		_patrol_index = (_patrol_index + 1) % _patrol_points.size()
		target = _patrol_points[_patrol_index]
	var dir := (target - global_position).normalized()
	velocity.x = dir.x * move_speed * 0.4
	velocity.z = dir.z * move_speed * 0.4
	PlanarFacing.face_direction(self, dir)
