class_name TideboundSovereign
extends BossController
## The Tidebound Sovereign — Drowned Citadel boss with two phases.

enum EncounterState { INACTIVE, INTRO, PHASE_ONE, TRANSITION, PHASE_TWO, DEFEATED, RESETTING }

const _MarinerScene := preload("res://scenes/enemies/drowned_mariner.tscn")
const _WraithScene := preload("res://scenes/enemies/storm_wraith.tscn")
const _ElectrifiedWater := preload("res://scripts/environment/electrified_water_zone.gd")
const _DamageData := preload("res://scripts/combat/damage_data.gd")
const _StatusEffects := preload("res://scripts/combat/status_effects_component.gd")
const _BossArenaTrigger := preload("res://scripts/dungeons/boss_arena_trigger.gd")

var _encounter: EncounterState = EncounterState.INACTIVE
var _phase2: bool = false
var _invulnerable: bool = false
var _intro_timer: float = 0.0
var _transition_timer: float = 0.0
var _attack_cd: float = 2.0
var _playing_attack: bool = false
var _summons: Array[Node] = []
var _hazards: Array[Node] = []
var _arena_center: Vector3 = Vector3.ZERO
var _arena_gate: StaticBody3D
var _mariner_summons: int = 0
var _wraith_summons: int = 0
var _arena_trigger: BossArenaTrigger


func _ready() -> void:
	boss_id = "tidebound_sovereign"
	phases = 2
	display_name = "The Tidebound Sovereign"
	enemy_id = "tidebound_sovereign"
	max_health = 580.0
	damage = 28.0
	move_speed = 3.2
	attack_range = 3.4
	detection_range = 0.0
	loot_table_id = "tidebound_sovereign"
	experience_reward = 260
	xp_reward = 280
	head_bar_offset = 3.2
	_phase_thresholds = [0.5]
	super._ready()
	_encounter = EncounterState.INACTIVE
	GameManager.in_boss_fight = false
	_arena_center = global_position
	_scale_boss_visual()
	call_deferred("_spawn_arena_trigger")


func _scale_boss_visual() -> void:
	var mesh_root := get_node_or_null("MeshRoot") as Node3D
	if mesh_root:
		mesh_root.scale = Vector3(1.9, 1.9, 1.9)


func set_arena_gate(gate: StaticBody3D) -> void:
	_arena_gate = gate
	if is_instance_valid(_arena_gate):
		_arena_gate.collision_layer = 0


func _spawn_arena_trigger() -> void:
	_arena_trigger = _BossArenaTrigger.new()
	_arena_trigger.name = "SovereignArenaTrigger"
	_arena_trigger.position = _arena_center + Vector3(0, 0.5, -5.0)
	_arena_trigger.boss = self
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(14, 3, 10)
	col.shape = shape
	_arena_trigger.add_child(col)
	if get_parent():
		get_parent().add_child(_arena_trigger)


func begin_encounter() -> void:
	if _encounter != EncounterState.INACTIVE:
		return
	if CitadelState.boss_defeated_persistent:
		return
	if DialogueManager.blocks_gameplay() or GameManager.is_paused:
		return
	_encounter = EncounterState.INTRO
	_intro_timer = 2.6
	velocity = Vector3.ZERO
	if is_instance_valid(_arena_gate):
		_arena_gate.collision_layer = 1
	AudioManager.play_sfx("boss_intro")
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("show_toast"):
			hud.show_toast("The Tidebound Sovereign rises from the flood", 3.0, "", "notification")
	if QuestManager.active_quests.has("the_sunken_crown"):
		QuestManager.advance_objective("the_sunken_crown", "reach_throne", 1)


func reset_encounter() -> void:
	if CitadelState.boss_defeated_persistent:
		return
	_encounter = EncounterState.RESETTING
	_invulnerable = false
	_phase2 = false
	current_phase = 1
	_playing_attack = false
	_attack_cd = 2.0
	_mariner_summons = 0
	_wraith_summons = 0
	GameManager.in_boss_fight = false
	_clear_telegraphs_and_hazards()
	_clear_summons()
	if _health:
		_health.reset_health()
	if _health_bar:
		_health_bar.visible = false
	if is_instance_valid(_arena_gate):
		_arena_gate.collision_layer = 0
	if is_instance_valid(_arena_trigger):
		_arena_trigger._triggered = false
	global_position = _arena_center
	velocity = Vector3.ZERO
	_set_state(AIState.IDLE)
	_encounter = EncounterState.INACTIVE


func receive_damage(dmg: DamageData) -> void:
	if _invulnerable or _encounter in [
		EncounterState.INACTIVE, EncounterState.INTRO,
		EncounterState.TRANSITION, EncounterState.DEFEATED, EncounterState.RESETTING,
	]:
		return
	if _encounter == EncounterState.PHASE_ONE and not _phase2:
		var hp_after := _health.current_health - dmg.amount
		if hp_after / max_health <= 0.5:
			var min_hp := max_health * 0.51
			if _health.current_health > min_hp:
				var capped_amt := minf(dmg.amount, _health.current_health - min_hp)
				if capped_amt > 0.0:
					var mod := DamageData.create_physical(capped_amt, dmg.source)
					mod.damage_type = dmg.damage_type
					mod.stagger = dmg.stagger
					super.receive_damage(mod)
			_begin_phase_transition()
			return
	super.receive_damage(dmg)
	_check_phase_transition()


func _check_phase_transition() -> void:
	if _phase2 or _encounter != EncounterState.PHASE_ONE:
		return
	if _health.get_health_percent() <= 0.5:
		_begin_phase_transition()


func _begin_phase_transition() -> void:
	if _encounter == EncounterState.TRANSITION or _phase2:
		return
	_encounter = EncounterState.TRANSITION
	_invulnerable = true
	_playing_attack = false
	_clear_telegraphs_and_hazards()
	_transition_timer = 3.8
	AudioManager.play_sfx("boss_phase")
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("show_toast"):
			hud.show_toast("Storm conduits overload — the sovereign's crown blazes!", 3.5)
	_spawn_phase_two_hazards()


func _spawn_phase_two_hazards() -> void:
	var offsets := [Vector3(-5, 0, 2), Vector3(5, 0, -2), Vector3(0, 0, 4), Vector3(-3, 0, -3)]
	for off in offsets:
		var patch := _ElectrifiedWater.new()
		patch.position = _arena_center + off
		patch.lifetime = 999.0
		if get_parent():
			get_parent().add_child(patch)
		_hazards.append(patch)


func _physics_process(delta: float) -> void:
	if current_state == AIState.DEAD:
		PlanarFacing.apply_floor(self, delta, _gravity)
		move_and_slide()
		return
	match _encounter:
		EncounterState.INACTIVE:
			_process_inactive(delta)
		EncounterState.INTRO:
			_process_intro(delta)
		EncounterState.TRANSITION:
			_process_transition(delta)
		EncounterState.PHASE_ONE, EncounterState.PHASE_TWO:
			_process_combat(delta)
		_:
			velocity = Vector3.ZERO
			PlanarFacing.apply_floor(self, delta, _gravity)
			move_and_slide()


func _process_inactive(delta: float) -> void:
	PlanarFacing.apply_floor(self, delta, _gravity)
	velocity = Vector3.ZERO
	move_and_slide()


func _process_intro(delta: float) -> void:
	PlanarFacing.apply_floor(self, delta, _gravity)
	velocity = Vector3.ZERO
	_intro_timer -= delta
	move_and_slide()
	if _intro_timer > 0.0:
		return
	_encounter = EncounterState.PHASE_ONE
	detection_range = 22.0
	GameManager.in_boss_fight = true
	_set_state(AIState.CHASE)
	_attack_cd = 1.2


func _process_transition(delta: float) -> void:
	PlanarFacing.apply_floor(self, delta, _gravity)
	velocity = Vector3.ZERO
	_transition_timer -= delta
	move_and_slide()
	if _transition_timer > 0.0:
		return
	_phase2 = true
	current_phase = 2
	_encounter = EncounterState.PHASE_TWO
	_invulnerable = false
	move_speed = 3.9
	damage = 34.0
	phase_changed.emit(2)
	_attack_cd = 1.0


func _process_combat(delta: float) -> void:
	if DialogueManager.blocks_gameplay() or GameManager.is_paused or MerchantManager.is_shop_open:
		velocity = Vector3.ZERO
		PlanarFacing.apply_floor(self, delta, _gravity)
		move_and_slide()
		return
	PlanarFacing.apply_floor(self, delta, _gravity)
	_attack_cd = maxf(_attack_cd - delta, 0.0)
	if _staggered_timer > 0.0:
		_staggered_timer -= delta
		move_and_slide()
		return
	if not is_instance_valid(_target):
		refresh_living_target()
	if _playing_attack:
		move_and_slide()
		return
	if _attack_cd <= 0.0 and is_instance_valid(_target) and not _playing_attack:
		_execute_attack()
	elif is_instance_valid(_target):
		_chase_target(delta)
	else:
		velocity = Vector3.ZERO
	move_and_slide()
	_update_character_anim()


func _scan_for_player() -> void:
	if _encounter not in [EncounterState.PHASE_ONE, EncounterState.PHASE_TWO]:
		return
	super._scan_for_player()


func _execute_attack() -> void:
	if not refresh_living_target():
		return
	var attacks: Array[String] = []
	if _encounter == EncounterState.PHASE_ONE:
		attacks = ["sovereign_cleave", "tidal_thrust", "wave_arc", "storm_bolt", "summon_mariner"]
	else:
		attacks = ["tidal_step", "lightning_crown", "flood_surge", "storm_trident_combo", "summon_wraith", "electrified_pool"]
	var pick: String = attacks[randi() % attacks.size()]
	match pick:
		"sovereign_cleave":
			_attack_sovereign_cleave()
		"tidal_thrust":
			_attack_tidal_thrust()
		"wave_arc":
			_attack_wave_arc()
		"storm_bolt":
			_attack_storm_bolt()
		"summon_mariner":
			_attack_summon_mariners()
		"tidal_step":
			_attack_tidal_step()
		"lightning_crown":
			_attack_lightning_crown()
		"flood_surge":
			_attack_flood_surge()
		"storm_trident_combo":
			_attack_storm_trident_combo()
		"summon_wraith":
			_attack_summon_wraiths()
		"electrified_pool":
			_attack_electrified_pool()
	_attack_cd = 2.5 if _encounter == EncounterState.PHASE_ONE else 2.0


func _attack_sovereign_cleave() -> void:
	_playing_attack = true
	AudioManager.play_sfx("sovereign_swing")
	if _character_anim.is_ready():
		_character_anim.play_attack()
	await get_tree().create_timer(0.95).timeout
	if is_instance_valid(_target):
		var to_target := _target.global_position - global_position
		to_target.y = 0.0
		if to_target.length_squared() > 0.01:
			PlanarFacing.face_direction(self, to_target)
		_strike_arc(3.8, damage, 20.0)
	await get_tree().create_timer(0.55).timeout
	_playing_attack = false


func _attack_tidal_thrust() -> void:
	_playing_attack = true
	AudioManager.play_sfx("sovereign_swing")
	if not is_instance_valid(_target):
		_playing_attack = false
		return
	var forward := (_target.global_position - global_position)
	forward.y = 0.0
	forward = forward.normalized()
	PlanarFacing.face_direction(self, forward)
	await get_tree().create_timer(0.7).timeout
	velocity = forward * move_speed * 2.8
	await get_tree().create_timer(0.35).timeout
	_strike_arc(2.6, damage * 1.2, 26.0)
	velocity = Vector3.ZERO
	await get_tree().create_timer(0.5).timeout
	_playing_attack = false


func _attack_wave_arc() -> void:
	_playing_attack = true
	AudioManager.play_sfx("wave_crash")
	var forward := -global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	for i in 3:
		var pt := global_position + forward * (2.0 + i * 2.2)
		_strike_point(pt, 1.9, damage * 0.8, 10.0, true)
		await get_tree().create_timer(0.28).timeout
	_playing_attack = false


func _attack_storm_bolt() -> void:
	_playing_attack = true
	if not is_instance_valid(_target):
		_playing_attack = false
		return
	var mark := _target.global_position
	AudioManager.play_sfx("lightning_warn")
	await get_tree().create_timer(1.1).timeout
	AudioManager.play_sfx("lightning_strike")
	_strike_point(mark, 2.2, damage * 1.15, 14.0, false, true)
	await get_tree().create_timer(0.4).timeout
	_playing_attack = false


func _attack_summon_mariners() -> void:
	if _mariner_summons >= 2:
		_attack_cd = 0.5
		return
	var mariner: Node3D = _MarinerScene.instantiate()
	mariner.position = _arena_center + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
	if get_parent():
		get_parent().add_child(mariner)
	_summons.append(mariner)
	_mariner_summons += 1
	AudioManager.play_sfx("summon")


func _attack_tidal_step() -> void:
	_playing_attack = true
	if not is_instance_valid(_target):
		_playing_attack = false
		return
	var away := global_position - _target.global_position
	away.y = 0.0
	if away.length_squared() < 0.01:
		away = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
	var dest := _target.global_position + away.normalized() * clampf(away.length() + 3.5, 3.5, 6.5)
	dest.y = global_position.y
	if dest.distance_to(_target.global_position) < 2.0:
		dest = _target.global_position + away.normalized() * 4.0
	global_position = dest
	AudioManager.play_sfx("teleport")
	await get_tree().create_timer(0.4).timeout
	if is_instance_valid(_target):
		_strike_arc(3.2, damage * 0.9, 12.0)
	_playing_attack = false


func _attack_lightning_crown() -> void:
	_playing_attack = true
	AudioManager.play_sfx("lightning_warn")
	var spots: Array[Vector3] = []
	for i in 6:
		var angle := TAU * float(i) / 6.0
		spots.append(_arena_center + Vector3(cos(angle) * 4.5, 0, sin(angle) * 4.5))
	for i in 6:
		if i % 2 == 0:
			await get_tree().create_timer(0.45).timeout
			AudioManager.play_sfx("lightning_strike")
			_strike_point(spots[i], 1.7, damage * 0.75, 8.0, false, true)
	_playing_attack = false


func _attack_flood_surge() -> void:
	_playing_attack = true
	AudioManager.play_sfx("wave_crash")
	var forward := -global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	await get_tree().create_timer(0.6).timeout
	for player in GameManager.get_alive_players():
		if not player is Node3D:
			continue
		var dist := global_position.distance_to((player as Node3D).global_position)
		if dist > 8.0:
			continue
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity += forward * 7.0
		if player.has_node("StatusEffectsComponent"):
			(player.get_node("StatusEffectsComponent") as _StatusEffects).apply_soaked()
		if player.has_node("HealthComponent"):
			var dmg := _DamageData.create_physical(damage * 0.55, self)
			(player.get_node("HealthComponent") as HealthComponent).apply_damage(dmg)
	await get_tree().create_timer(0.5).timeout
	_playing_attack = false


func _attack_storm_trident_combo() -> void:
	_playing_attack = true
	AudioManager.play_sfx("sovereign_swing")
	for hit in 3:
		if _character_anim.is_ready():
			_character_anim.play_attack()
		await get_tree().create_timer(0.42).timeout
		if is_instance_valid(_target):
			var dist := global_position.distance_to(_target.global_position)
			if dist <= attack_range + 1.4:
				_strike_arc(2.9, damage * 0.72, 9.0)
	_playing_attack = false


func _attack_summon_wraiths() -> void:
	if _wraith_summons >= 2:
		_attack_cd = 0.5
		return
	var wraith: Node3D = _WraithScene.instantiate()
	wraith.position = _arena_center + Vector3(randf_range(-4, 4), 0, randf_range(-4, 4))
	if get_parent():
		get_parent().add_child(wraith)
	_summons.append(wraith)
	_wraith_summons += 1
	AudioManager.play_sfx("summon")


func _attack_electrified_pool() -> void:
	var patch := _ElectrifiedWater.new()
	patch.position = _arena_center + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
	patch.lifetime = 8.0
	if get_parent():
		get_parent().add_child(patch)
	_hazards.append(patch)
	AudioManager.play_sfx("conduit_hum")


func _lightning_multiplier(player: Node) -> float:
	if player.has_node("StatusEffectsComponent"):
		var status := player.get_node("StatusEffectsComponent") as _StatusEffects
		if status.soaked_active:
			return 1.32
	return 1.0


func _strike_arc(range_dist: float, strike_damage: float, stagger_amt: float, lightning: bool = false) -> void:
	for player in GameManager.get_alive_players():
		if not player is Node3D:
			continue
		var to_p := (player as Node3D).global_position - global_position
		to_p.y = 0.0
		if to_p.length() > range_dist:
			continue
		var mult := _lightning_multiplier(player) if lightning else 1.0
		if player.has_node("HealthComponent"):
			var dmg := _DamageData.create_physical(strike_damage * mult, self)
			dmg.damage_type = _DamageData.DamageType.FROST
			dmg.stagger = stagger_amt
			(player.get_node("HealthComponent") as HealthComponent).apply_damage(dmg)


func _strike_point(
	point: Vector3,
	radius: float,
	strike_damage: float,
	stagger_amt: float,
	soaked: bool = false,
	lightning: bool = false
) -> void:
	for player in GameManager.get_alive_players():
		if not player is Node3D:
			continue
		if (player as Node3D).global_position.distance_to(point) > radius:
			continue
		var mult := _lightning_multiplier(player) if lightning else 1.0
		if player.has_node("HealthComponent"):
			var dmg := _DamageData.create_physical(strike_damage * mult, self)
			dmg.damage_type = _DamageData.DamageType.FROST
			dmg.stagger = stagger_amt
			(player.get_node("HealthComponent") as HealthComponent).apply_damage(dmg)
		if soaked and player.has_node("StatusEffectsComponent"):
			(player.get_node("StatusEffectsComponent") as _StatusEffects).apply_soaked()
		if lightning and player.has_node("StatusEffectsComponent"):
			(player.get_node("StatusEffectsComponent") as _StatusEffects).add_storm_buildup(10.0)


func _clear_telegraphs_and_hazards() -> void:
	for node in _hazards:
		if is_instance_valid(node):
			node.queue_free()
	_hazards.clear()
	for node in get_tree().get_nodes_in_group("boss_hazard"):
		if is_instance_valid(node):
			node.queue_free()


func _clear_summons() -> void:
	for node in _summons:
		if is_instance_valid(node):
			node.queue_free()
	_summons.clear()
	_mariner_summons = 0
	_wraith_summons = 0


func _on_died() -> void:
	if _death_sequence_running:
		return
	_encounter = EncounterState.DEFEATED
	_invulnerable = true
	_playing_attack = false
	GameManager.in_boss_fight = false
	_clear_telegraphs_and_hazards()
	_clear_summons()
	if is_instance_valid(_arena_gate):
		_arena_gate.collision_layer = 0
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
	AudioManager.play_sfx("boss_death", randf_range(0.9, 1.05))
	_award_kill_experience()
	enemy_died.emit(self)
	await get_tree().create_timer(corpse_linger_sec).timeout
	if not is_instance_valid(self):
		return
	var mesh_root := get_node_or_null("MeshRoot") as Node3D
	if mesh_root:
		var fade := mesh_root.create_tween()
		fade.tween_property(mesh_root, "scale", Vector3.ZERO, 0.45)
		await fade.finished
	queue_free()
