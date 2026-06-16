class_name SolarTyrant
extends BossController
## The Solar Tyrant — Pyreheart Ziggurat Solar Heart boss.

enum EncounterState { INACTIVE, INTRO, PHASE_ONE, TRANSITION, PHASE_TWO, DEFEATED, RESETTING }

const _CultistScene := preload("res://scenes/enemies/pyre_cultist.tscn")
const _RaiderScene := preload("res://scenes/enemies/dune_raider.tscn")
const _DamageData := preload("res://scripts/combat/damage_data.gd")
const _StatusEffects := preload("res://scripts/combat/status_effects_component.gd")
const _BossArenaTrigger := preload("res://scripts/dungeons/boss_arena_trigger.gd")
const _SolarHazard := preload("res://scripts/dungeons/solar_boss_hazard.gd")

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
var _add_summons: int = 0
var _arena_trigger: BossArenaTrigger
var _core_exposed_timer: float = 0.0
var _transition_done: bool = false


func _ready() -> void:
	boss_id = "solar_tyrant"
	phases = 2
	display_name = "The Solar Tyrant"
	enemy_id = "solar_tyrant"
	max_health = 640.0
	damage = 28.0
	move_speed = 3.1
	attack_range = 3.8
	detection_range = 0.0
	loot_table_id = "solar_tyrant"
	experience_reward = 300
	xp_reward = 320
	head_bar_offset = 3.6
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
		mesh_root.scale = Vector3(2.2, 2.2, 2.2)
	var core := get_node_or_null("MeshRoot/SolarCore") as OmniLight3D
	if core:
		core.light_color = Color(0.98, 0.55, 0.18)
	var crown := get_node_or_null("MeshRoot/SolarCrown") as OmniLight3D
	if crown:
		crown.light_color = Color(0.95, 0.72, 0.22)


func set_arena_gate(gate: StaticBody3D) -> void:
	_arena_gate = gate
	if is_instance_valid(_arena_gate):
		_arena_gate.collision_layer = 0


func get_beam_duration_scale() -> float:
	return 0.72 if PyreheartState.mirror_a else 1.0


func is_hazard_lane_disabled() -> bool:
	return PyreheartState.mirror_b


func get_core_exposure_bonus() -> float:
	return 1.4 if PyreheartState.mirror_c else 1.0


func get_passive_heat_multiplier() -> float:
	return 0.65 if PyreheartState.puzzle_completed else 1.0


func begin_encounter() -> void:
	if _encounter != EncounterState.INACTIVE:
		return
	if PyreheartState.boss_defeated_persistent:
		return
	if DialogueManager.blocks_gameplay() or GameManager.is_paused:
		return
	_encounter = EncounterState.INTRO
	_intro_timer = 2.8
	velocity = Vector3.ZERO
	if is_instance_valid(_arena_gate):
		_arena_gate.collision_layer = 1
	AudioManager.play_sfx("solar_tyrant_intro")
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("show_toast"):
			hud.show_toast("The Solar Tyrant rises from the molten heart", 3.0, "", "notification")
	if QuestManager.active_quests.has("heart_of_the_wastes"):
		QuestManager.advance_objective("heart_of_the_wastes", "enter_solar_heart", 1)


func reset_encounter() -> void:
	if PyreheartState.boss_defeated_persistent:
		return
	_encounter = EncounterState.RESETTING
	_invulnerable = false
	_phase2 = false
	_transition_done = false
	current_phase = 1
	_playing_attack = false
	_attack_cd = 2.0
	_add_summons = 0
	_core_exposed_timer = 0.0
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


func _spawn_arena_trigger() -> void:
	_arena_trigger = _BossArenaTrigger.new()
	_arena_trigger.name = "SolarTyrantArenaTrigger"
	_arena_trigger.position = _arena_center + Vector3(0, 0.5, -5.0)
	_arena_trigger.boss = self
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(14, 3, 10)
	col.shape = shape
	_arena_trigger.add_child(col)
	if get_parent():
		get_parent().add_child(_arena_trigger)


func receive_damage(dmg: DamageData) -> void:
	if _invulnerable or _encounter in [
		EncounterState.INACTIVE, EncounterState.INTRO,
		EncounterState.TRANSITION, EncounterState.DEFEATED, EncounterState.RESETTING,
	]:
		return
	if _encounter == EncounterState.PHASE_ONE and not _phase2 and not _transition_done:
		var hp_after := _health.current_health - dmg.amount
		if hp_after / max_health <= 0.5:
			var min_hp := max_health * 0.51
			if _health.current_health > min_hp:
				var capped := minf(dmg.amount, _health.current_health - min_hp)
				if capped > 0.0:
					var mod := _DamageData.create_physical(capped, dmg.source)
					mod.damage_type = dmg.damage_type
					super.receive_damage(mod)
			_begin_phase_transition()
			return
	if _phase2 and _core_exposed_timer > 0.0:
		var bonus := get_core_exposure_bonus()
		if bonus > 1.0:
			dmg.amount *= bonus
	super.receive_damage(dmg)


func _begin_phase_transition() -> void:
	if _encounter == EncounterState.TRANSITION or _phase2 or _transition_done:
		return
	_transition_done = true
	_encounter = EncounterState.TRANSITION
	_invulnerable = true
	_playing_attack = false
	_clear_telegraphs_and_hazards()
	_transition_timer = 3.8
	AudioManager.play_sfx("solar_phase_transition")
	AudioManager.play_sfx("solar_heart_ambience")
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("show_toast"):
			hud.show_toast("Cooling channels flare — the tyrant's molten core is exposed!", 3.5)


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
	detection_range = 20.0
	GameManager.in_boss_fight = true
	_set_state(AIState.CHASE)
	_attack_cd = 1.3


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
	_core_exposed_timer = 4.0 * get_core_exposure_bonus()
	move_speed = 3.7
	damage = 34.0
	phase_changed.emit(2)
	_attack_cd = 0.9


func _process_combat(delta: float) -> void:
	if DialogueManager.blocks_gameplay() or GameManager.is_paused or MerchantManager.is_shop_open:
		velocity = Vector3.ZERO
		PlanarFacing.apply_floor(self, delta, _gravity)
		move_and_slide()
		return
	_apply_passive_arena_heat(delta)
	if _core_exposed_timer > 0.0:
		_core_exposed_timer = maxf(_core_exposed_timer - delta, 0.0)
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


func _apply_passive_arena_heat(delta: float) -> void:
	var mult := get_passive_heat_multiplier()
	if mult >= 1.0:
		return
	for player in GameManager.get_alive_players():
		if player.has_node("StatusEffectsComponent"):
			var status := player.get_node("StatusEffectsComponent") as _StatusEffects
			status.add_heat_buildup(2.0 * mult * delta)


func _scan_for_player() -> void:
	if _encounter not in [EncounterState.PHASE_ONE, EncounterState.PHASE_TWO]:
		return
	var best: Node3D = null
	var best_dist := INF
	for p in GameManager.get_alive_players():
		if p is Node3D:
			var d := global_position.distance_to((p as Node3D).global_position)
			if d < best_dist:
				best_dist = d
				best = p
	_target = best


func _execute_attack() -> void:
	if not refresh_living_target():
		return
	var roll := randi() % 100
	if _encounter == EncounterState.PHASE_ONE:
		if roll < 22:
			_attack_solar_cleave()
		elif roll < 40:
			_attack_sunstrike()
		elif roll < 58:
			_attack_solar_beam()
		elif roll < 74:
			_attack_glass_eruption()
		else:
			_attack_ashbound_summon()
	else:
		if roll < 18:
			_attack_solar_step()
		elif roll < 34:
			_attack_crown_of_flame()
		elif roll < 50:
			_attack_sandglass_storm()
		elif roll < 66:
			_attack_solar_judgment()
		elif roll < 82:
			_attack_burning_ground()
		else:
			_attack_sentinel_summon()
	_attack_cd = randf_range(1.4, 2.5) if _phase2 else randf_range(1.7, 2.9)


func _attack_solar_cleave() -> void:
	_playing_attack = true
	AudioManager.play_sfx("solar_cleave")
	if _character_anim.is_ready():
		_character_anim.play_attack()
	await get_tree().create_timer(0.6).timeout
	_strike_arc(3.6, damage * 0.95, 11.0)
	_apply_heat_near(3.8, 10.0)
	_playing_attack = false


func _attack_sunstrike() -> void:
	if not is_instance_valid(_target):
		_playing_attack = false
		return
	_playing_attack = true
	var mark := (_target as Node3D).global_position
	AudioManager.play_sfx("sunstrike_charge")
	await get_tree().create_timer(0.9).timeout
	AudioManager.play_sfx("boss_swing")
	if global_position.distance_to(mark) < 9.0:
		_strike_point(mark, 2.0, damage * 1.05, 12.0)
		_apply_heat_near(2.2, 14.0)
	await get_tree().create_timer(0.5).timeout
	_playing_attack = false


func _attack_solar_beam() -> void:
	_playing_attack = true
	AudioManager.play_sfx("solar_beam_charge")
	var dir := -global_transform.basis.z
	if is_instance_valid(_target):
		dir = ((_target as Node3D).global_position - global_position)
	dir.y = 0.0
	dir = dir.normalized()
	await get_tree().create_timer(0.55).timeout
	AudioManager.play_sfx("solar_beam_fire")
	var steps := int(3.0 / get_beam_duration_scale()) + 1
	for i in steps:
		var pt := global_position + dir * (2.0 + i * 2.4)
		_strike_point(pt, 1.5, damage * 0.5, 6.0, true)
		await get_tree().create_timer(0.1 * get_beam_duration_scale()).timeout
	_playing_attack = false


func _attack_glass_eruption() -> void:
	_playing_attack = true
	AudioManager.play_sfx("glass_eruption_warning")
	var spots: Array[Vector3] = []
	for i in 3:
		var off := Vector3(randf_range(-5, 5), 0, randf_range(-5, 5))
		if is_instance_valid(_target) and i == 0:
			off = ((_target as Node3D).global_position - _arena_center)
			off.y = 0.0
			if off.length() > 4.5:
				off = off.normalized() * 4.5
		spots.append(_arena_center + off)
	await get_tree().create_timer(0.85).timeout
	for spot in spots:
		AudioManager.play_sfx("glass_eruption_impact")
		_spawn_hazard(spot, 3.5, 6.0, Color(0.85, 0.72, 0.35, 0.6))
	_playing_attack = false


func _attack_ashbound_summon() -> void:
	if _add_summons >= 2:
		_attack_cd = 0.4
		return
	var add: Node3D = _CultistScene.instantiate()
	add.position = _arena_center + Vector3(randf_range(-4, 4), 0, randf_range(-4, 4))
	if get_parent():
		get_parent().add_child(add)
	_summons.append(add)
	_add_summons += 1
	AudioManager.play_sfx("summon")


func _attack_solar_step() -> void:
	if not is_instance_valid(_target):
		_playing_attack = false
		return
	_playing_attack = true
	var dest := (_target as Node3D).global_position + Vector3(randf_range(-2.5, 2.5), 0, 3.5)
	dest.y = global_position.y
	if dest.distance_to((_target as Node3D).global_position) < 1.2:
		dest += Vector3(2.5, 0, 0)
	global_position = dest
	AudioManager.play_sfx("teleport")
	await get_tree().create_timer(0.35).timeout
	_strike_arc(2.9, damage * 0.82, 8.0)
	_playing_attack = false


func _attack_crown_of_flame() -> void:
	_playing_attack = true
	AudioManager.play_sfx("crown_of_flame")
	await get_tree().create_timer(1.0).timeout
	for player in GameManager.get_alive_players():
		if not player is Node3D:
			continue
		var dist := global_position.distance_to((player as Node3D).global_position)
		if dist > 8.5:
			continue
		if player.has_node("HealthComponent"):
			var dmg := _DamageData.create_physical(damage * 0.55, self)
			(player.get_node("HealthComponent") as HealthComponent).apply_damage(dmg)
		if player.has_node("StatusEffectsComponent"):
			(player.get_node("StatusEffectsComponent") as _StatusEffects).add_heat_buildup(16.0)
	_playing_attack = false


func _attack_sandglass_storm() -> void:
	_playing_attack = true
	AudioManager.play_sfx("sandglass_storm")
	var dir := Vector3(1, 0, 0) if randf() > 0.5 else Vector3(-1, 0, 0)
	for i in 4:
		var spot := _arena_center + dir * (i * 2.0 - 3.0) + Vector3(0, 0, randf_range(-3, 3))
		_spawn_hazard(spot, 4.0, 4.5, Color(0.78, 0.62, 0.28, 0.5), 4.5)
		await get_tree().create_timer(0.35).timeout
	_playing_attack = false


func _attack_solar_judgment() -> void:
	_playing_attack = true
	AudioManager.play_sfx("solar_cleave")
	if _character_anim.is_ready():
		_character_anim.play_attack()
	for hit in 3:
		await get_tree().create_timer(0.38).timeout
		_strike_arc(3.2, damage * 0.62, 8.0)
	_playing_attack = false


func _attack_burning_ground() -> void:
	_playing_attack = true
	var lanes := 3
	for i in lanes:
		var off := Vector3(randf_range(-4, 4), 0, randf_range(-4, 4))
		if is_hazard_lane_disabled() and off.x > 0:
			continue
		_spawn_hazard(_arena_center + off, 5.0, 5.5, Color(0.92, 0.35, 0.08, 0.55), 6.0)
	await get_tree().create_timer(0.4).timeout
	_playing_attack = false


func _attack_sentinel_summon() -> void:
	if _add_summons >= 2:
		return
	var add: Node3D = _RaiderScene.instantiate()
	add.position = _arena_center + Vector3(randf_range(-4, 4), 0, randf_range(-4, 4))
	if get_parent():
		get_parent().add_child(add)
	_summons.append(add)
	_add_summons += 1
	AudioManager.play_sfx("summon")


func _spawn_hazard(pos: Vector3, life: float, dmg: float, color: Color, radius: float = 2.0) -> void:
	var zone := _SolarHazard.new()
	zone.lifetime = life
	zone.tick_damage = dmg
	zone.hazard_color = color
	zone.hazard_radius = radius
	zone.position = pos + Vector3(0, 0.1, 0)
	if get_parent():
		get_parent().add_child(zone)
	_hazards.append(zone)


func _strike_arc(radius: float, amount: float, stagger: float) -> void:
	for player in GameManager.get_alive_players():
		if not player is Node3D:
			continue
		if global_position.distance_to((player as Node3D).global_position) > radius:
			continue
		if player.has_node("HealthComponent"):
			var dmg := _DamageData.create_physical(amount, self)
			dmg.stagger = stagger
			(player.get_node("HealthComponent") as HealthComponent).apply_damage(dmg)


func _strike_point(pos: Vector3, radius: float, amount: float, stagger: float, heat: bool = false) -> void:
	for player in GameManager.get_alive_players():
		if not player is Node3D:
			continue
		if pos.distance_to((player as Node3D).global_position) > radius:
			continue
		if player.has_node("HealthComponent"):
			var dmg := _DamageData.create_physical(amount, self)
			dmg.stagger = stagger
			(player.get_node("HealthComponent") as HealthComponent).apply_damage(dmg)
		if heat and player.has_node("StatusEffectsComponent"):
			(player.get_node("StatusEffectsComponent") as _StatusEffects).add_heat_buildup(12.0)


func _apply_heat_near(radius: float, amount: float) -> void:
	for player in GameManager.get_alive_players():
		if not player is Node3D:
			continue
		if global_position.distance_to((player as Node3D).global_position) > radius:
			continue
		if player.has_node("StatusEffectsComponent"):
			(player.get_node("StatusEffectsComponent") as _StatusEffects).add_heat_buildup(amount)


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
	_add_summons = 0


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
	AudioManager.play_sfx("solar_tyrant_death", randf_range(0.9, 1.05))
	_award_kill_experience()
	enemy_died.emit(self)
	await get_tree().create_timer(corpse_linger_sec).timeout
	if not is_instance_valid(self):
		return
	var mesh_root := get_node_or_null("MeshRoot") as Node3D
	if mesh_root:
		var fade := mesh_root.create_tween()
		fade.tween_property(mesh_root, "scale", Vector3.ZERO, 0.6)
		await fade.finished
	queue_free()
