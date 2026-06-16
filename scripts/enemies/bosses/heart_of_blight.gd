class_name HeartOfBlight
extends BossController
## The Blightheart — Blightspire Cathedral Heart Chamber boss.

enum EncounterState { INACTIVE, INTRO, PHASE_ONE, TRANSITION, PHASE_TWO, DEFEATED, RESETTING }

const _HoundScene := preload("res://scenes/enemies/blight_hound.tscn")
const _ClericScene := preload("res://scenes/enemies/sporecaster.tscn")
const _DamageData := preload("res://scripts/combat/damage_data.gd")
const _StatusEffects := preload("res://scripts/combat/status_effects_component.gd")
const _BossArenaTrigger := preload("res://scripts/dungeons/boss_arena_trigger.gd")
const _CorruptionZone := preload("res://scripts/dungeons/cathedral_corruption_zone.gd")

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


func _ready() -> void:
	boss_id = "blightheart"
	phases = 2
	display_name = "The Blightheart"
	enemy_id = "blightheart"
	max_health = 620.0
	damage = 26.0
	move_speed = 3.0
	attack_range = 3.6
	detection_range = 0.0
	loot_table_id = "blightheart"
	experience_reward = 280
	xp_reward = 300
	head_bar_offset = 3.4
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
		mesh_root.scale = Vector3(2.1, 2.1, 2.1)
	var core := get_node_or_null("MeshRoot/BlightCore") as OmniLight3D
	if core:
		core.light_color = Color(0.42, 0.88, 0.38)


func set_arena_gate(gate: StaticBody3D) -> void:
	_arena_gate = gate
	if is_instance_valid(_arena_gate):
		_arena_gate.collision_layer = 0


func get_brazier_spore_resist() -> float:
	return 0.35 if CathedralState.brazier_a else 0.0


func is_hazard_lane_disabled() -> bool:
	return CathedralState.brazier_b


func get_core_exposure_bonus() -> float:
	return 1.35 if CathedralState.brazier_c else 1.0


func begin_encounter() -> void:
	if _encounter != EncounterState.INACTIVE:
		return
	if CathedralState.boss_defeated_persistent:
		return
	if DialogueManager.blocks_gameplay() or GameManager.is_paused:
		return
	_encounter = EncounterState.INTRO
	_intro_timer = 2.8
	velocity = Vector3.ZERO
	if is_instance_valid(_arena_gate):
		_arena_gate.collision_layer = 1
	AudioManager.play_sfx("boss_intro")
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("show_toast"):
			hud.show_toast("The Blightheart stirs within the living cathedral", 3.0, "", "notification")
	if QuestManager.active_quests.has("heart_of_the_blight"):
		QuestManager.advance_objective("heart_of_the_blight", "enter_heart_chamber", 1)


func reset_encounter() -> void:
	if CathedralState.boss_defeated_persistent:
		return
	_encounter = EncounterState.RESETTING
	_invulnerable = false
	_phase2 = false
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
	_arena_trigger.name = "BlightheartArenaTrigger"
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
	if _encounter == EncounterState.PHASE_ONE and not _phase2:
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
	super.receive_damage(dmg)


func _begin_phase_transition() -> void:
	if _encounter == EncounterState.TRANSITION or _phase2:
		return
	_encounter = EncounterState.TRANSITION
	_invulnerable = true
	_playing_attack = false
	_clear_telegraphs_and_hazards()
	_transition_timer = 3.6 * get_core_exposure_bonus()
	AudioManager.play_sfx("boss_phase")
	AudioManager.play_sfx("heart_chamber_pulse")
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("show_toast"):
			hud.show_toast("Purified roots weaken — the Blightheart's core is exposed!", 3.5)


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
	move_speed = 3.6
	damage = 32.0
	phase_changed.emit(2)
	_attack_cd = 0.9


func _process_combat(delta: float) -> void:
	if DialogueManager.blocks_gameplay() or GameManager.is_paused or MerchantManager.is_shop_open:
		velocity = Vector3.ZERO
		PlanarFacing.apply_floor(self, delta, _gravity)
		move_and_slide()
		return
	_apply_brazier_spore_resist(delta)
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


func _apply_brazier_spore_resist(_delta: float) -> void:
	var resist := get_brazier_spore_resist()
	if resist <= 0.0:
		return
	for player in GameManager.get_alive_players():
		if player.has_node("StatusEffectsComponent"):
			var status := player.get_node("StatusEffectsComponent") as _StatusEffects
			status.spore_resist = maxf(status.spore_resist, resist)


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
			_attack_root_cleave()
		elif roll < 40:
			_attack_thorn_impale()
		elif roll < 58:
			_attack_spore_burst()
		elif roll < 74:
			_attack_corruption_beam()
		else:
			_attack_blight_spawn()
	else:
		if roll < 20:
			_attack_heartroot_slam()
		elif roll < 36:
			_attack_blightstep()
		elif roll < 52:
			_attack_corruption_bloom()
		elif roll < 68:
			_attack_bell_pulse()
		elif roll < 84:
			_attack_devouring_vines()
		else:
			_attack_summon_adds()
	_attack_cd = randf_range(1.4, 2.6) if _phase2 else randf_range(1.8, 3.0)


func _attack_root_cleave() -> void:
	_playing_attack = true
	AudioManager.play_sfx("root_movement")
	if _character_anim.is_ready():
		_character_anim.play_attack()
	await get_tree().create_timer(0.55).timeout
	_strike_arc(3.4, damage * 0.95, 11.0)
	_apply_blight_buildup_near(3.5, 10.0)
	_playing_attack = false


func _attack_thorn_impale() -> void:
	if not is_instance_valid(_target):
		_playing_attack = false
		return
	_playing_attack = true
	var mark := (_target as Node3D).global_position
	AudioManager.play_sfx("root_movement")
	await get_tree().create_timer(0.85).timeout
	if global_position.distance_to(mark) < 8.0:
		_strike_point(mark, 1.8, damage * 0.85, 9.0)
	_playing_attack = false


func _attack_spore_burst() -> void:
	_playing_attack = true
	AudioManager.play_sfx("spore_vent")
	await get_tree().create_timer(0.7).timeout
	for player in GameManager.get_alive_players():
		if not player is Node3D:
			continue
		if global_position.distance_to((player as Node3D).global_position) > 5.5:
			continue
		if player.has_node("StatusEffectsComponent"):
			(player.get_node("StatusEffectsComponent") as _StatusEffects).set_in_spore_zone(true)
			(player.get_node("StatusEffectsComponent") as _StatusEffects).add_blight_buildup(8.0)
		if player.has_node("HealthComponent"):
			var dmg := _DamageData.create_physical(damage * 0.35, self)
			(player.get_node("HealthComponent") as HealthComponent).apply_damage(dmg)
	await get_tree().create_timer(0.4).timeout
	for player in GameManager.get_alive_players():
		if player.has_node("StatusEffectsComponent"):
			(player.get_node("StatusEffectsComponent") as _StatusEffects).set_in_spore_zone(false)
	_playing_attack = false


func _attack_corruption_beam() -> void:
	_playing_attack = true
	AudioManager.play_sfx("blighted_cleric_cast")
	var dir := -global_transform.basis.z
	dir.y = 0.0
	dir = dir.normalized()
	await get_tree().create_timer(0.5).timeout
	for i in 4:
		var pt := global_position + dir * (2.0 + i * 2.2)
		_strike_point(pt, 1.4, damage * 0.55, 6.0, true)
		await get_tree().create_timer(0.12).timeout
	_playing_attack = false


func _attack_blight_spawn() -> void:
	if _add_summons >= 2:
		_attack_cd = 0.4
		return
	var hound: Node3D = _HoundScene.instantiate()
	hound.position = _arena_center + Vector3(randf_range(-4, 4), 0, randf_range(-4, 4))
	if get_parent():
		get_parent().add_child(hound)
	_summons.append(hound)
	_add_summons += 1
	AudioManager.play_sfx("summon")


func _attack_heartroot_slam() -> void:
	_playing_attack = true
	AudioManager.play_sfx("root_movement")
	await get_tree().create_timer(0.65).timeout
	for i in 3:
		var off := Vector3(randf_range(-5, 5), 0, randf_range(-5, 5))
		if is_hazard_lane_disabled() and off.x > 0:
			continue
		_strike_point(_arena_center + off, 2.0, damage * 0.7, 10.0)
		await get_tree().create_timer(0.15).timeout
	_playing_attack = false


func _attack_blightstep() -> void:
	if not is_instance_valid(_target):
		return
	_playing_attack = true
	var dest := (_target as Node3D).global_position + Vector3(randf_range(-2, 2), 0, 3.5)
	dest.y = global_position.y
	global_position = dest
	AudioManager.play_sfx("teleport")
	await get_tree().create_timer(0.35).timeout
	_strike_arc(2.8, damage * 0.8, 8.0)
	_playing_attack = false


func _attack_corruption_bloom() -> void:
	_playing_attack = true
	var zone := _CorruptionZone.new()
	zone.lifetime = 5.0
	zone.position = _arena_center + Vector3(randf_range(-3, 3), 0.1, randf_range(-3, 3))
	if get_parent():
		get_parent().add_child(zone)
	_hazards.append(zone)
	AudioManager.play_sfx("spore_vent")
	await get_tree().create_timer(0.5).timeout
	_playing_attack = false


func _attack_bell_pulse() -> void:
	_playing_attack = true
	AudioManager.play_sfx("corrupted_bell")
	await get_tree().create_timer(1.1).timeout
	for player in GameManager.get_alive_players():
		if not player is Node3D:
			continue
		var dist := global_position.distance_to((player as Node3D).global_position)
		if dist > 9.0:
			continue
		if player.has_node("HealthComponent"):
			var dmg := _DamageData.create_physical(damage * 0.5, self)
			(player.get_node("HealthComponent") as HealthComponent).apply_damage(dmg)
		if player.has_node("StatusEffectsComponent"):
			(player.get_node("StatusEffectsComponent") as _StatusEffects).add_blight_buildup(14.0)
	_playing_attack = false


func _attack_devouring_vines() -> void:
	if not is_instance_valid(_target):
		return
	_playing_attack = true
	AudioManager.play_sfx("root_movement")
	var caught := global_position.distance_to(_target.global_position) <= 4.0
	if caught and _target is CharacterBody3D:
		(_target as CharacterBody3D).velocity = Vector3.ZERO
		if _target.has_node("HealthComponent"):
			var dmg := _DamageData.create_physical(damage * 0.45, self)
			(_target.get_node("HealthComponent") as HealthComponent).apply_damage(dmg)
		await get_tree().create_timer(1.2).timeout
	_playing_attack = false


func _attack_summon_adds() -> void:
	if _add_summons >= 2:
		return
	var add: Node3D = _ClericScene.instantiate()
	add.position = _arena_center + Vector3(randf_range(-4, 4), 0, randf_range(-4, 4))
	if get_parent():
		get_parent().add_child(add)
	_summons.append(add)
	_add_summons += 1
	AudioManager.play_sfx("summon")


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


func _strike_point(pos: Vector3, radius: float, amount: float, stagger: float, corruption: bool = false) -> void:
	for player in GameManager.get_alive_players():
		if not player is Node3D:
			continue
		if pos.distance_to((player as Node3D).global_position) > radius:
			continue
		if player.has_node("HealthComponent"):
			var dmg := _DamageData.create_physical(amount, self)
			dmg.stagger = stagger
			(player.get_node("HealthComponent") as HealthComponent).apply_damage(dmg)
		if corruption and player.has_node("StatusEffectsComponent"):
			(player.get_node("StatusEffectsComponent") as _StatusEffects).add_blight_buildup(12.0)


func _apply_blight_buildup_near(radius: float, amount: float) -> void:
	for player in GameManager.get_alive_players():
		if not player is Node3D:
			continue
		if global_position.distance_to((player as Node3D).global_position) > radius:
			continue
		if player.has_node("StatusEffectsComponent"):
			(player.get_node("StatusEffectsComponent") as _StatusEffects).add_blight_buildup(amount)


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
	AudioManager.play_sfx("boss_death", randf_range(0.9, 1.05))
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
