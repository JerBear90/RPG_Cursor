class_name HollowKing
extends BossController
## The Hollow King — Paleheart Crypt boss with two phases.

enum EncounterState { INACTIVE, INTRO, PHASE_ONE, TRANSITION, PHASE_TWO, DEFEATED, RESETTING }

const _FrozenHuskScene := preload("res://scenes/enemies/frozen_husk.tscn")
const _WraithScene := preload("res://scenes/enemies/gravewind_wraith.tscn")
const _BlackIcePatch := preload("res://scripts/environment/black_ice_patch.gd")
const _DamageData := preload("res://scripts/combat/damage_data.gd")
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
var _husk_summons: int = 0
var _wraith_summons: int = 0


func _ready() -> void:
	boss_id = "hollow_king"
	phases = 2
	display_name = "The Hollow King"
	enemy_id = "hollow_king"
	max_health = 520.0
	damage = 26.0
	move_speed = 3.0
	attack_range = 3.2
	detection_range = 0.0
	loot_table_id = "hollow_king"
	experience_reward = 240
	xp_reward = 260
	head_bar_offset = 3.1
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
		mesh_root.scale = Vector3(1.85, 1.85, 1.85)


func set_arena_gate(gate: StaticBody3D) -> void:
	_arena_gate = gate
	if is_instance_valid(_arena_gate):
		_arena_gate.collision_layer = 0


func _spawn_arena_trigger() -> void:
	var trigger := _BossArenaTrigger.new()
	trigger.name = "HollowKingArenaTrigger"
	trigger.position = _arena_center + Vector3(0, 0.5, -5.0)
	trigger.boss = self
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(14, 3, 10)
	col.shape = shape
	trigger.add_child(col)
	if get_parent():
		get_parent().add_child(trigger)


func begin_encounter() -> void:
	if _encounter != EncounterState.INACTIVE:
		return
	if CryptState.boss_defeated_persistent:
		return
	if DialogueManager.blocks_gameplay() or GameManager.is_paused:
		return
	_encounter = EncounterState.INTRO
	_intro_timer = 2.4
	velocity = Vector3.ZERO
	if is_instance_valid(_arena_gate):
		_arena_gate.collision_layer = 1
	AudioManager.play_sfx("boss_intro")
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("show_toast"):
			hud.show_toast("The Hollow King rises from the frost", 3.0, "", "notification")


func receive_damage(dmg: DamageData) -> void:
	if _invulnerable or _encounter in [
		EncounterState.INACTIVE, EncounterState.INTRO,
		EncounterState.TRANSITION, EncounterState.DEFEATED, EncounterState.RESETTING,
	]:
		return
	super.receive_damage(dmg)


func _check_phase_transition() -> void:
	if _phase2 or _encounter != EncounterState.PHASE_ONE:
		return
	if _health.get_health_percent() <= 0.5:
		_begin_phase_transition()


func _begin_phase_transition() -> void:
	_encounter = EncounterState.TRANSITION
	_invulnerable = true
	_playing_attack = false
	_clear_telegraphs_and_hazards()
	_transition_timer = 3.5
	AudioManager.play_sfx("boss_phase")
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("show_toast"):
			hud.show_toast("Gravewind surges — the Paleheart core awakens!", 3.5)
	_spawn_phase_two_ice()


func _spawn_phase_two_ice() -> void:
	var offsets := [Vector3(-4, 0, 2), Vector3(4, 0, -2), Vector3(0, 0, 4), Vector3(-3, 0, -3)]
	for off in offsets:
		var patch := _BlackIcePatch.new()
		patch.position = _arena_center + off
		patch.lifetime = 999.0
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
	move_speed = 3.8
	damage = 32.0
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
		attacks = ["royal_cleave", "frozen_overhead", "frost_wave", "ice_pillars", "summon_husk"]
	else:
		attacks = ["gravewind_step", "paleheart_burst", "crownfall_combo", "black_ice_trail", "summon_wraith"]
	var pick: String = attacks[randi() % attacks.size()]
	match pick:
		"royal_cleave":
			_attack_royal_cleave()
		"frozen_overhead":
			_attack_frozen_overhead()
		"frost_wave":
			_attack_frost_wave()
		"ice_pillars":
			_attack_ice_pillars()
		"summon_husk":
			_attack_summon_husks()
		"gravewind_step":
			_attack_gravewind_step()
		"paleheart_burst":
			_attack_paleheart_burst()
		"crownfall_combo":
			_attack_crownfall_combo()
		"black_ice_trail":
			_attack_black_ice_trail()
		"summon_wraith":
			_attack_summon_wraiths()
	_attack_cd = 2.6 if _encounter == EncounterState.PHASE_ONE else 2.0


func _attack_royal_cleave() -> void:
	_playing_attack = true
	AudioManager.play_sfx("boss_swing")
	if _character_anim.is_ready():
		_character_anim.play_attack()
	await get_tree().create_timer(0.9).timeout
	if is_instance_valid(_target):
		var to_target := _target.global_position - global_position
		to_target.y = 0.0
		if to_target.length_squared() > 0.01:
			PlanarFacing.face_direction(self, to_target)
		_strike_arc(3.6, damage, 18.0)
	await get_tree().create_timer(0.6).timeout
	_playing_attack = false


func _attack_frozen_overhead() -> void:
	_playing_attack = true
	AudioManager.play_sfx("boss_swing")
	if _character_anim.is_ready():
		_character_anim.play_attack()
	await get_tree().create_timer(1.1).timeout
	if is_instance_valid(_target):
		_strike_point(_target.global_position, 2.4, damage * 1.35, 24.0)
	await get_tree().create_timer(0.8).timeout
	_playing_attack = false


func _attack_frost_wave() -> void:
	_playing_attack = true
	AudioManager.play_sfx("frost_wave")
	var forward := -global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	for i in 3:
		var pt := global_position + forward * (2.0 + i * 2.5)
		_strike_point(pt, 1.8, damage * 0.75, 8.0, true)
		await get_tree().create_timer(0.25).timeout
	_playing_attack = false


func _attack_ice_pillars() -> void:
	_playing_attack = true
	if not is_instance_valid(_target):
		_playing_attack = false
		return
	var base := _target.global_position
	var spots: Array[Vector3] = []
	for i in 4:
		var off := Vector3(randf_range(-4, 4), 0, randf_range(-4, 4))
		if off.length() < 2.5:
			off = off.normalized() * 2.5
		spots.append(base + off)
	for spot in spots:
		AudioManager.play_sfx("ice_crack")
		await get_tree().create_timer(0.55).timeout
		_strike_point(spot, 1.6, damage * 0.9, 10.0, true)
	_playing_attack = false


func _attack_summon_husks() -> void:
	if _husk_summons >= 2:
		_attack_cd = 0.5
		return
	var count := mini(2 - _husk_summons, 1)
	for i in count:
		var husk: Node3D = _FrozenHuskScene.instantiate()
		husk.position = _arena_center + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
		get_parent().add_child(husk)
		_summons.append(husk)
		_husk_summons += 1
	AudioManager.play_sfx("summon")


func _attack_gravewind_step() -> void:
	_playing_attack = true
	if not is_instance_valid(_target):
		_playing_attack = false
		return
	var away := global_position - _target.global_position
	away.y = 0.0
	if away.length_squared() < 0.01:
		away = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
	var dest := _target.global_position + away.normalized() * clampf(away.length() + 4.0, 4.0, 7.0)
	dest.y = global_position.y
	global_position = dest
	AudioManager.play_sfx("teleport")
	await get_tree().create_timer(0.35).timeout
	if is_instance_valid(_target):
		_strike_arc(3.0, damage * 0.85, 12.0)
	_playing_attack = false


func _attack_paleheart_burst() -> void:
	_playing_attack = true
	AudioManager.play_sfx("paleheart_burst")
	await get_tree().create_timer(1.0).timeout
	for player in GameManager.get_alive_players():
		if not player is Node3D:
			continue
		var dist := global_position.distance_to((player as Node3D).global_position)
		if dist > 7.0:
			continue
		if player.has_node("HealthComponent"):
			var dmg := _DamageData.create_physical(damage * 0.9, self)
			dmg.damage_type = _DamageData.DamageType.FROST
			(player.get_node("HealthComponent") as HealthComponent).apply_damage(dmg)
		if player.has_node("StatusEffectsComponent"):
			(player.get_node("StatusEffectsComponent") as StatusEffectsComponent).add_cold_buildup(15.0)
	_playing_attack = false


func _attack_crownfall_combo() -> void:
	_playing_attack = true
	AudioManager.play_sfx("boss_swing")
	for hit in 3:
		if _character_anim.is_ready():
			_character_anim.play_attack()
		await get_tree().create_timer(0.45).timeout
		if is_instance_valid(_target):
			var dist := global_position.distance_to(_target.global_position)
			if dist <= attack_range + 1.2:
				_strike_arc(2.8, damage * 0.7, 8.0)
	_playing_attack = false


func _attack_black_ice_trail() -> void:
	var patch := _BlackIcePatch.new()
	patch.position = global_position
	patch.lifetime = 10.0
	get_parent().add_child(patch)
	_hazards.append(patch)
	if is_instance_valid(_target):
		var to_target := (_target.global_position - global_position).normalized()
		velocity = Vector3(to_target.x, 0, to_target.z) * move_speed * 0.8


func _attack_summon_wraiths() -> void:
	if _wraith_summons >= 2:
		_attack_cd = 0.5
		return
	var wraith: Node3D = _WraithScene.instantiate()
	wraith.position = _arena_center + Vector3(randf_range(-4, 4), 0, randf_range(-4, 4))
	get_parent().add_child(wraith)
	_summons.append(wraith)
	_wraith_summons += 1
	AudioManager.play_sfx("summon")


func _strike_arc(range_dist: float, strike_damage: float, stagger_amt: float) -> void:
	for player in GameManager.get_alive_players():
		if not player is Node3D:
			continue
		var to_p := (player as Node3D).global_position - global_position
		to_p.y = 0.0
		if to_p.length() > range_dist:
			continue
		if player.has_node("HealthComponent"):
			var dmg := _DamageData.create_physical(strike_damage, self)
			dmg.damage_type = _DamageData.DamageType.FROST
			dmg.stagger = stagger_amt
			(player.get_node("HealthComponent") as HealthComponent).apply_damage(dmg)


func _strike_point(point: Vector3, radius: float, strike_damage: float, stagger_amt: float, cold_buildup: bool = false) -> void:
	for player in GameManager.get_alive_players():
		if not player is Node3D:
			continue
		if (player as Node3D).global_position.distance_to(point) > radius:
			continue
		if player.has_node("HealthComponent"):
			var dmg := _DamageData.create_physical(strike_damage, self)
			dmg.damage_type = _DamageData.DamageType.FROST
			dmg.stagger = stagger_amt
			(player.get_node("HealthComponent") as HealthComponent).apply_damage(dmg)
		if cold_buildup and player.has_node("StatusEffectsComponent"):
			(player.get_node("StatusEffectsComponent") as StatusEffectsComponent).add_cold_buildup(12.0)


func _clear_telegraphs_and_hazards() -> void:
	for node in _hazards:
		if is_instance_valid(node):
			node.queue_free()
	_hazards.clear()


func _clear_summons() -> void:
	for node in _summons:
		if is_instance_valid(node):
			node.queue_free()
	_summons.clear()
	_husk_summons = 0
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
