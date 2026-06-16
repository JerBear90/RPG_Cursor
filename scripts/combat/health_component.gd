class_name HealthComponent
extends Node
## Health, damage reception, and death signals.

const _DamageResult = preload("res://scripts/combat/damage_result.gd")
const _PlayerHealthDebug = preload("res://scripts/debug/player_health_debug.gd")

signal health_changed(current: float, maximum: float)
signal damaged(damage: DamageData, remaining: float)
signal damage_applied(result, damage: DamageData)
signal died
signal healed(amount: float)

@export var max_health: float = 100.0
@export var regen_rate: float = 0.0
@export var regen_delay: float = 5.0

var current_health: float = 100.0
var _regen_timer: float = 0.0
var _dead: bool = false


func _ready() -> void:
	current_health = max_health


func _process(delta: float) -> void:
	if _dead or regen_rate <= 0.0:
		return
	_regen_timer -= delta
	if _regen_timer <= 0.0 and current_health < max_health:
		heal(regen_rate * delta)


func apply_damage(damage: DamageData) -> RefCounted:
	var result: RefCounted = _DamageResult.new()
	result.raw_damage = damage.amount
	if _dead:
		result.reject_reason = "dead"
		return result
	if damage.amount <= 0.0:
		result.reject_reason = "zero"
		return result
	result.accepted = true
	result.final_damage = damage.amount
	result.health_before = current_health
	current_health = maxf(current_health - result.final_damage, 0.0)
	result.health_after = current_health
	result.killed_target = current_health <= 0.0
	_regen_timer = regen_delay
	damaged.emit(damage, current_health)
	health_changed.emit(current_health, max_health)
	damage_applied.emit(result, damage)
	_log_health_hit(result, damage)
	_spawn_damage_feedback(result)
	if result.killed_target:
		_die()
	return result


func _spawn_damage_feedback(result: RefCounted) -> void:
	if not result.accepted or result.final_damage <= 0.0:
		return
	var anchor := _get_feedback_anchor()
	if anchor == Vector3.ZERO:
		return
	var on_player := _owner_is_player()
	CombatVfx.spawn_damage_number(anchor, result.final_damage, on_player)


func _log_health_hit(result: RefCounted, damage: DamageData) -> void:
	if not _PlayerHealthDebug.DEBUG_PLAYER_HEALTH or not _owner_is_player():
		return
	var player := _find_player_node()
	var hud := _find_player_hud()
	_PlayerHealthDebug.log_damage_trace(
		player, player.get_node_or_null("Combat") if player else null,
		self, damage, result, hud, "", result.accepted
	)


func _find_player_node() -> Node:
	var node: Node = get_parent()
	while node:
		if node.is_in_group("player"):
			return node
		node = node.get_parent()
	return get_parent()


func _find_player_hud() -> PlayerHud:
	for hud in get_tree().get_nodes_in_group("game_hud"):
		var player_hud := hud.get_node_or_null("HudRoot") as PlayerHud
		if player_hud:
			return player_hud
	return null


func _get_feedback_anchor() -> Vector3:
	var node: Node = get_parent()
	while node:
		if node is Node3D:
			var body := node as Node3D
			var height := 1.75
			if node.is_in_group("enemy"):
				height = 2.05
			return body.global_position + Vector3(0, height, 0)
		node = node.get_parent()
	return Vector3.ZERO


func _owner_is_player() -> bool:
	var node: Node = get_parent()
	while node:
		if node.is_in_group("player"):
			return true
		node = node.get_parent()
	return false


func take_damage(damage: DamageData) -> float:
	var result: RefCounted = apply_damage(damage)
	return result.final_damage if result.accepted else 0.0


func heal(amount: float) -> void:
	if _dead:
		return
	var before := current_health
	current_health = minf(current_health + amount, max_health)
	var actual := current_health - before
	if actual > 0.0:
		healed.emit(actual)
		health_changed.emit(current_health, max_health)


func is_alive() -> bool:
	return not _dead


func is_near_death(threshold_percent: float = 0.15) -> bool:
	return current_health <= max_health * threshold_percent


func get_health_percent() -> float:
	return current_health / max_health if max_health > 0 else 0.0


func _die() -> void:
	_dead = true
	died.emit()


func reset_health() -> void:
	_dead = false
	current_health = max_health
	health_changed.emit(current_health, max_health)
