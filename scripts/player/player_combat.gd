extends Node
## Player attack, block, dodge, lock-on, execution.

@export var light_attack_damage: float = 12.0
@export var heavy_attack_damage: float = 22.0
@export var charged_attack_damage: float = 35.0

var _player: PlayerController
var _health: HealthComponent
var _stamina: StaminaComponent
var _block: BlockComponent
var _dodge: DodgeComponent
var _lock_on: LockOnController
var _execution: ExecutionController
var _hitbox: Hitbox
var _attack_timer: float = 0.0
var _attack_active: bool = false
var _combo_index: int = 0
var _staggered: bool = false


func _ready() -> void:
	_player = get_parent() as PlayerController
	_health = _player.get_node("HealthComponent")
	_stamina = _player.get_node("StaminaComponent")
	_block = _player.get_node("BlockComponent")
	_dodge = _player.get_node("DodgeComponent")
	_lock_on = _player.get_node("LockOnController")
	_execution = _player.get_node("ExecutionController")
	_hitbox = _player.get_node("WeaponSocket/Hitbox")
	_block.setup(_stamina)
	_dodge.setup(_stamina)
	_lock_on.setup(_player)
	_execution.setup(_player, _stamina)
	_execution.execution_available.connect(_on_execution_available)
	_health.damaged.connect(_on_damaged)


func _process(delta: float) -> void:
	if not _player.is_alive():
		return
	_handle_input(delta)
	_update_attack(delta)
	_scan_executables()


func _handle_input(delta: float) -> void:
	var idx := _player.player_index
	if InputManager.is_action_just_pressed("dodge", idx) and _dodge.start_dodge():
		_player.current_state = PlayerController.State.DODGE
	if InputManager.is_action_pressed("block", idx):
		_block.start_block()
		_player.current_state = PlayerController.State.BLOCK
	elif _block.is_blocking:
		_block.stop_block()
	if InputManager.is_action_just_pressed("lock_on", idx):
		_lock_on.toggle_lock()
	if InputManager.is_action_just_pressed("light_attack", idx):
		_start_attack(light_attack_damage, 0.35, 8.0)
	if InputManager.is_action_just_pressed("heavy_attack", idx):
		_start_attack(heavy_attack_damage, 0.55, 15.0)
	if InputManager.is_action_pressed("charged_attack", idx):
		_execution.process_hold(delta, true)
	else:
		_execution.process_hold(delta, false)


func _start_attack(damage: float, duration: float, stamina_cost: float) -> void:
	if _attack_active or _dodge.is_dodging or not _stamina.spend(stamina_cost):
		return
	_attack_active = true
	_attack_timer = duration
	_hitbox.base_damage = _get_final_physical_damage(damage)
	_hitbox.enable()
	_player.current_state = PlayerController.State.ATTACK
	AudioManager.play_sfx("hit", randf_range(0.9, 1.1))
	_combo_index = (_combo_index + 1) % 3


func _update_attack(delta: float) -> void:
	if not _attack_active:
		return
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_hitbox.disable()
		_attack_active = false
		_player.current_state = PlayerController.State.IDLE


func receive_damage(damage: DamageData) -> void:
	if _dodge.iframes_active:
		return
	var amount := damage.amount
	if _block.is_blocking and damage.can_be_blocked:
		amount = _block.process_block(damage)
	_health.take_damage(DamageData.create_physical(amount, damage.source))


func _on_damaged(_damage: DamageData, _remaining: float) -> void:
	if _health.current_health <= 0:
		_player.current_state = PlayerController.State.DEAD
		GameManager.player_died.emit(_player, _player.player_index)


func _scan_executables() -> void:
	var nearest: Node = null
	var best := 3.0
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy.has_method("is_execution_ready") and enemy.is_execution_ready():
			var d := _player.global_position.distance_to(enemy.global_position)
			if d < best:
				best = d
				nearest = enemy
	_execution.update_executable(nearest)
	if nearest == null:
		for hud in get_tree().get_nodes_in_group("game_hud"):
			hud.set_execution_prompt(false)


func _on_execution_available(_enemy: Node) -> void:
	for hud in get_tree().get_nodes_in_group("game_hud"):
		hud.set_execution_prompt(true)


func _get_final_physical_damage(base: float) -> float:
	var total := base
	if _player.has_node("StatsComponent"):
		total += (_player.get_node("StatsComponent") as StatsComponent).get_physical_damage_bonus()
	var weapon_id: String = InventoryManager.equipment.get("main_weapon", "rusty_sword")
	total += ItemDatabase.get_weapon_damage(weapon_id)
	if _player.has_node("SkillTree"):
		total *= (_player.get_node("SkillTree") as Node).get_physical_damage_multiplier()
	return total
