extends Node
## Player attack, block, dodge, lock-on, execution.

const _PlayerHealthDebug = preload("res://scripts/debug/player_health_debug.gd")

signal attack_phase_changed(phase: String, heavy: bool)
signal attack_started(combo_index: int, heavy: bool)

@export var light_attack_damage: float = 12.0
@export var heavy_attack_damage: float = 22.0
@export var charged_attack_damage: float = 35.0
@export var exhausted_damage_mult: float = 0.45
@export var low_stamina_damage_mult: float = 0.6

const LIGHT_TIMING := {"windup": 0.08, "active": 0.14, "recovery": 0.20}
const HEAVY_TIMING := {"windup": 0.18, "active": 0.16, "recovery": 0.38}
const COMBO_WINDOW := 0.35

enum AttackPhase { NONE, WINDUP, ACTIVE, RECOVERY }

var _player: PlayerController
var _health: HealthComponent
var _stamina: StaminaComponent
var _block: BlockComponent
var _dodge: DodgeComponent
var _lock_on: LockOnController
var _execution: ExecutionController
var _hitbox: Hitbox
var _attack_phase: AttackPhase = AttackPhase.NONE
var _phase_timer: float = 0.0
var _timing: Dictionary = {}
var _attack_active: bool = false
var _attack_heavy: bool = false
var _attack_anim_heavy: bool = false
var _combo_index: int = 0
var _combo_window_timer: float = 0.0
var _queued_attack: String = ""


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
	_combo_window_timer = maxf(_combo_window_timer - delta, 0.0)
	_handle_input(delta)
	_update_attack(delta)
	_scan_executables()


func _handle_input(delta: float) -> void:
	if DialogueManager.blocks_gameplay() or _player.is_input_locked():
		return
	var idx := _player.player_index
	if InputManager.is_action_just_pressed("dodge", idx) and _dodge.start_dodge():
		_cancel_attack()
		_player.set_state(PlayerController.State.DODGE)
	if InputManager.is_action_pressed("block", idx) and _stamina.can_spend(1.0):
		_block.start_block()
		if _attack_phase == AttackPhase.NONE:
			_player.set_state(PlayerController.State.BLOCK)
	elif _block.is_blocking:
		_block.stop_block()
		if _player.current_state == PlayerController.State.BLOCK:
			_player.set_state(PlayerController.State.IDLE)
	if InputManager.is_action_just_pressed("lock_on", idx):
		_lock_on.toggle_lock()
	if InputManager.is_action_just_pressed("light_attack", idx):
		_request_attack("light")
	if InputManager.is_action_just_pressed("heavy_attack", idx):
		_request_attack("heavy")
	if InputManager.is_action_pressed("charged_attack", idx):
		_execution.process_hold(delta, true)
	else:
		_execution.process_hold(delta, false)


func _request_attack(kind: String) -> void:
	if _dodge.is_dodging:
		return
	if _attack_phase == AttackPhase.RECOVERY and _combo_window_timer > 0.0 and kind == "light":
		_queued_attack = kind
		return
	if _attack_active:
		return
	if kind == "light":
		_begin_attack(light_attack_damage, LIGHT_TIMING, 8.0, false)
	else:
		_begin_attack(heavy_attack_damage, HEAVY_TIMING, 15.0, true)


func _begin_attack(damage: float, timing: Dictionary, stamina_cost: float, heavy: bool) -> void:
	var damage_mult := _spend_stamina_for_attack(stamina_cost)
	_attack_active = true
	_attack_heavy = heavy
	# Heavy GLTF clips (Stab/Duck) read as falling when stamina is empty — always use light anim then.
	_attack_anim_heavy = heavy and damage_mult >= 1.0
	_timing = timing
	_phase_timer = timing.windup
	_attack_phase = AttackPhase.WINDUP
	_hitbox.disable()
	_hitbox.base_damage = _get_final_physical_damage(damage) * damage_mult
	_player.set_state(PlayerController.State.ATTACK)
	attack_phase_changed.emit("windup", _attack_anim_heavy)
	attack_started.emit(_combo_index, heavy)
	if not heavy:
		_combo_index = (_combo_index + 1) % 3


func _update_attack(delta: float) -> void:
	if _attack_phase == AttackPhase.NONE:
		return
	_phase_timer -= delta
	match _attack_phase:
		AttackPhase.WINDUP:
			if _phase_timer <= 0.0:
				_attack_phase = AttackPhase.ACTIVE
				_phase_timer = _timing.active
				_hitbox.enable()
				attack_phase_changed.emit("active", _attack_anim_heavy)
				AudioManager.play_sfx("hit", randf_range(0.9, 1.1))
		AttackPhase.ACTIVE:
			if _phase_timer <= 0.0:
				_hitbox.disable()
				_attack_phase = AttackPhase.RECOVERY
				_phase_timer = _timing.recovery
				attack_phase_changed.emit("recovery", _attack_anim_heavy)
				_combo_window_timer = COMBO_WINDOW
		AttackPhase.RECOVERY:
			if _phase_timer <= 0.0:
				_finish_attack()
			elif _queued_attack != "" and _phase_timer <= _timing.recovery * 0.5:
				var next := _queued_attack
				_queued_attack = ""
				_finish_attack(false)
				if next == "light":
					_begin_attack(light_attack_damage, LIGHT_TIMING, 8.0, false)
				else:
					_begin_attack(heavy_attack_damage, HEAVY_TIMING, 15.0, true)


func _finish_attack(reset_combo: bool = true) -> void:
	_hitbox.disable()
	_attack_active = false
	_attack_phase = AttackPhase.NONE
	_phase_timer = 0.0
	_timing = {}
	attack_phase_changed.emit("none", false)
	if reset_combo and _combo_window_timer <= 0.0:
		_combo_index = 0
	if _player.is_alive():
		_player.set_state(PlayerController.State.IDLE)


func _cancel_attack() -> void:
	_queued_attack = ""
	_finish_attack()


func receive_damage(damage: DamageData) -> void:
	if not _player.is_alive():
		return
	if _player.has_combat_invulnerability():
		_log_rejected_hit(damage, "combat_invulnerability")
		return
	if _dodge.iframes_active:
		_log_rejected_hit(damage, "dodge_iframes")
		return
	var amount := damage.amount
	if _block.is_blocking and damage.can_be_blocked:
		amount = _block.process_block(damage)
		if amount <= 0.0:
			_log_rejected_hit(damage, "blocked")
			return
	var result := _health.apply_damage(DamageData.create_physical(amount, damage.source))


func _log_rejected_hit(damage: DamageData, reason: String) -> void:
	if not _PlayerHealthDebug.DEBUG_PLAYER_HEALTH:
		return
	var hud := _find_player_hud()
	_PlayerHealthDebug.log_hit(_player, _health, null, damage, hud, reason)


func _find_player_hud() -> PlayerHud:
	for hud in get_tree().get_nodes_in_group("game_hud"):
		var player_hud := hud.get_node_or_null("HudRoot") as PlayerHud
		if player_hud:
			return player_hud
	return null


func die_from_environment(_cause: String) -> void:
	if not _player.is_alive():
		return
	if _player.has_spawn_protection():
		return
	_cancel_attack()
	_health.take_damage(DamageData.create_physical(_health.current_health + 1.0, self))


func _on_damaged(_damage: DamageData, _remaining: float) -> void:
	CombatVfx.spawn_hit(_player.global_position + Vector3(0, 1.55, 0), Color(1.0, 0.25, 0.2))
	if _health.current_health <= 0:
		_cancel_attack()
		_player.set_state(PlayerController.State.DEAD)
		GameManager.player_died.emit(_player, _player.player_index)


func _scan_executables() -> void:
	if DialogueManager.is_active():
		for hud in get_tree().get_nodes_in_group("game_hud"):
			hud.set_execution_prompt(false)
		return
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
	if DialogueManager.is_active():
		return
	for hud in get_tree().get_nodes_in_group("game_hud"):
		hud.set_execution_prompt(true)


func _spend_stamina_for_attack(stamina_cost: float) -> float:
	if _stamina == null:
		return 1.0
	if _stamina.can_spend(stamina_cost):
		_stamina.spend(stamina_cost)
		return 1.0
	var available := _stamina.current_stamina
	if available > 0.0:
		var ratio := clampf(available / stamina_cost, 0.0, 1.0)
		_stamina.spend(available)
		return lerpf(low_stamina_damage_mult, 1.0, ratio)
	return exhausted_damage_mult


func _get_final_physical_damage(base: float) -> float:
	var total := base
	if _player.has_node("StatsComponent"):
		total += (_player.get_node("StatsComponent") as StatsComponent).get_physical_damage_bonus()
	var weapon_id: String = InventoryManager.equipment.get("main_weapon", "rusty_sword")
	total += ItemDatabase.get_weapon_damage(weapon_id)
	if _player.has_node("SkillTree"):
		total *= (_player.get_node("SkillTree") as Node).get_physical_damage_multiplier()
	var combo_bonus := 1.0 + (_combo_index * 0.05)
	return total * combo_bonus
