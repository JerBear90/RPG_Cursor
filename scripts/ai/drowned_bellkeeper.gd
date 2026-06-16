class_name DrownedBellkeeper
extends BossController
## The Drowned Bellkeeper — Sunken Reliquary boss with two phases.

var _phase2: bool = false
var _summon_cd: float = 0.0


func _ready() -> void:
	boss_id = "drowned_bellkeeper"
	phases = 2
	super._ready()
	display_name = "The Drowned Bellkeeper"
	max_health = 420.0
	damage = 22.0
	move_speed = 3.2
	attack_range = 2.8
	loot_table_id = "drowned_bellkeeper"
	experience_reward = 180
	xp_reward = 200
	_phase_thresholds = [0.5]


func _on_phase_enter(phase: int) -> void:
	if phase >= 2:
		_phase2 = true
		move_speed = 4.2
		damage = 28.0
		attack_range = 3.2
		for hud in get_tree().get_nodes_in_group("game_hud"):
			if hud.has_method("show_toast"):
				hud.show_toast("The Bellkeeper enters its second phase!")


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _phase2 and current_state == AIState.CHASE:
		_summon_cd -= delta
		if _summon_cd <= 0.0:
			_summon_cd = 12.0
			_try_summon_hound()


func _try_summon_hound() -> void:
	var scene := preload("res://scenes/enemies/mire_hound.tscn")
	var hound: Node3D = scene.instantiate()
	hound.position = global_position + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
	get_parent().add_child(hound)


func _on_died() -> void:
	GameManager.in_boss_fight = false
	super._on_died()
