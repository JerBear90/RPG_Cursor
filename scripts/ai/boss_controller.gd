class_name BossController
extends EnemyBase
## Multi-phase boss with arena lock and rewards.

signal phase_changed(phase: int)

@export var boss_id: String = "hollow_grove_warden"
@export var phases: int = 3

var current_phase: int = 1
var _phase_thresholds: Array[float] = [0.66, 0.33]


func _ready() -> void:
	super._ready()
	add_to_group("boss")
	respawns = false
	experience_reward = 250
	enemy_level = 12
	max_health = 800.0
	damage = 25.0
	loot_table_id = "boss_warden"
	MapManager.mark_region_dangerous(GameManager.current_region_id)


func receive_damage(dmg: DamageData) -> void:
	super.receive_damage(dmg)
	_check_phase_transition()


func is_execution_ready() -> bool:
	return false


func _check_phase_transition() -> void:
	var pct := _health.get_health_percent()
	for i in _phase_thresholds.size():
		if current_phase == i + 1 and pct <= _phase_thresholds[i]:
			current_phase = i + 2
			phase_changed.emit(current_phase)
			_on_phase_enter(current_phase)


func _on_phase_enter(phase: int) -> void:
	match phase:
		2:
			move_speed = 4.5
			damage = 30.0
		3:
			move_speed = 5.5
			damage = 38.0
			attack_range = 3.0


func _on_died() -> void:
	GameManager.in_boss_fight = false
	AchievementManager.unlock("hollow_grove_broken")
	var stats := GameManager.get_player(0)
	if stats and stats.has_node("StatsComponent"):
		stats.get_node("StatsComponent").unspent_skill_points += 1
	QuestManager.advance_objective("defeat_warden", "kill_warden", 1)
	MapManager.clear_region(GameManager.current_region_id)
	MapManager.discover_region("hollow_grove_shrine")
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("show_toast"):
			hud.show_toast("Region cleared!")
	super._on_died()
