class_name ExecutionController
extends Node
## Near-death enemy execution (Hold Y).

signal execution_available(enemy: Node)
signal execution_performed(enemy: Node)

@export var stamina_cost: float = 15.0
@export var stamina_restore: float = 10.0

var _nearby_executable: Node = null
var _hold_timer: float = 0.0
const HOLD_TIME := 0.6

var _owner: Node3D
var _stamina: StaminaComponent


func setup(owner_node: Node3D, stamina: StaminaComponent) -> void:
	_owner = owner_node
	_stamina = stamina


func update_executable(enemy: Node) -> void:
	if enemy != _nearby_executable:
		_nearby_executable = enemy
		if enemy:
			execution_available.emit(enemy)


func process_hold(delta: float, holding: bool) -> void:
	if _nearby_executable == null or not is_instance_valid(_nearby_executable):
		_hold_timer = 0.0
		return
	if not holding:
		_hold_timer = 0.0
		return
	_hold_timer += delta
	if _hold_timer >= HOLD_TIME:
		_try_execute()


func can_execute(enemy: Node) -> bool:
	if enemy == null or not is_instance_valid(enemy):
		return false
	if enemy.is_in_group("boss"):
		return false
	if not enemy.has_method("is_execution_ready") or not enemy.is_execution_ready():
		return false
	if _owner.has_method("get_level") and enemy.has_method("get_level"):
		if enemy.get_level() > _owner.get_level() + 3:
			return false
	return _stamina and _stamina.can_spend(stamina_cost)


func _try_execute() -> void:
	if not can_execute(_nearby_executable):
		return
	_stamina.spend(stamina_cost)
	_stamina.restore(stamina_restore)
	if _nearby_executable.has_method("execute"):
		_nearby_executable.execute(_owner)
	execution_performed.emit(_nearby_executable)
	_nearby_executable = null
	_hold_timer = 0.0
	AchievementManager.unlock("stay_down")
