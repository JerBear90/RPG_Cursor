class_name IronCrucible
extends BossController
## The Iron Crucible — Blackvein Foundry boss.

var _phase2: bool = false
var _vent_cd: float = 0.0


func _ready() -> void:
	boss_id = "iron_crucible"
	phases = 2
	super._ready()
	display_name = "The Iron Crucible"
	max_health = 480.0
	damage = 24.0
	move_speed = 2.8
	attack_range = 3.0
	loot_table_id = "iron_crucible"
	experience_reward = 220
	xp_reward = 240
	_phase_thresholds = [0.5]
	GameManager.in_boss_fight = true


func _on_phase_enter(phase: int) -> void:
	if phase >= 2:
		_phase2 = true
		move_speed = 3.8
		damage = 32.0
		attack_range = 3.4
		for hud in get_tree().get_nodes_in_group("game_hud"):
			if hud.has_method("show_toast"):
				hud.show_toast("The Iron Crucible overheats!")


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _phase2:
		_vent_cd -= delta
		if _vent_cd <= 0.0:
			_vent_cd = 8.0
			_pulse_heat()


func _pulse_heat() -> void:
	for player in GameManager.get_alive_players():
		if player.has_node("StatusEffectsComponent"):
			(player.get_node("StatusEffectsComponent") as StatusEffectsComponent).add_heat_buildup(25.0)


func _on_died() -> void:
	GameManager.in_boss_fight = false
	super._on_died()
