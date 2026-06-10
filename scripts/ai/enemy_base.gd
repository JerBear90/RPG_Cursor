class_name EnemyBase
extends CharacterBody3D
## Base enemy with AI states, combat, and loot.

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

var current_state: AIState = AIState.IDLE
var _health: HealthComponent
var _nav: NavigationAgent3D
var _target: Node3D = null
var _attack_cooldown: float = 0.0
var _staggered_timer: float = 0.0
var _patrol_points: Array[Vector3] = []
var _patrol_index: int = 0
var _gravity: float = 20.0


func _ready() -> void:
	add_to_group("enemy")
	add_to_group("lockable_enemy")
	_health = get_node("HealthComponent")
	_nav = get_node("NavigationAgent3D")
	_health.max_health = max_health
	_health.reset_health()
	_health.died.connect(_on_died)
	_setup_patrol()


func _physics_process(delta: float) -> void:
	if current_state == AIState.DEAD:
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


func receive_damage(dmg: DamageData) -> void:
	_health.take_damage(dmg)
	if dmg.stagger >= 15.0:
		_stagger(1.0)
	if _health.is_near_death():
		_set_state(AIState.EXECUTION_READY)


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


func _chase_target(delta: float) -> void:
	if not is_instance_valid(_target):
		_set_state(AIState.PATROL)
		return
	var dist := global_position.distance_to(_target.global_position)
	if dist <= attack_range:
		_set_state(AIState.ATTACK)
		return
	_nav.target_position = _target.global_position
	var next := _nav.get_next_path_position()
	var direction := (next - global_position).normalized()
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed
	PlanarFacing.face_direction(self, direction)


func _perform_attack() -> void:
	if not is_instance_valid(_target):
		_set_state(AIState.PATROL)
		return
	if _attack_cooldown > 0.0:
		return
	_attack_cooldown = 1.5
	var hitbox := get_node_or_null("AttackHitbox") as Hitbox
	if hitbox:
		hitbox.base_damage = damage
		hitbox.enable()
		get_tree().create_timer(0.3).timeout.connect(hitbox.disable)
	if global_position.distance_to(_target.global_position) > attack_range * 1.5:
		_set_state(AIState.CHASE)


func _stagger(duration: float) -> void:
	_staggered_timer = duration
	_set_state(AIState.STAGGERED)


func _on_died() -> void:
	_set_state(AIState.DEAD)
	LootManager.drop_loot_table(loot_table_id, global_position)
	LootManager.drop_currency(randi_range(2, 10), global_position)
	var killer := GameManager.get_player(0)
	if killer and killer.has_node("StatsComponent"):
		killer.get_node("StatsComponent").add_experience(xp_reward)
	if "first_blood" not in QuestManager.completed_quests:
		if not QuestManager.active_quests.has("first_blood"):
			QuestManager.start_quest("first_blood")
		QuestManager.advance_objective("first_blood", "kill_enemy", 1)
	enemy_died.emit(self)
	queue_free()


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
