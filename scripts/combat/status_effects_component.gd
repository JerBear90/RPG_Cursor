class_name StatusEffectsComponent
extends Node

## Poison and heat buildup, resistance, and cleansing.



signal poison_buildup_changed(current: float, threshold: float)

signal poison_applied

signal poison_cleared

signal heat_buildup_changed(current: float, threshold: float)

signal heat_applied

signal heat_cleared
signal cold_buildup_changed(current: float, threshold: float)
signal cold_applied
signal cold_cleared



@export var poison_threshold: float = 100.0

@export var heat_threshold: float = 100.0

@export var buildup_rate: float = 25.0

@export var heat_buildup_rate: float = 20.0

@export var decay_rate: float = 35.0

@export var heat_decay_rate: float = 30.0

@export var poison_resist: float = 0.0

@export var heat_resist: float = 0.0
@export var cold_threshold: float = 100.0
@export var cold_buildup_rate: float = 18.0
@export var cold_decay_rate: float = 28.0
@export var cold_resist: float = 0.0



var poison_buildup: float = 0.0

var heat_buildup: float = 0.0

var poison_active: bool = false

var heat_active: bool = false

var _tick_damage: float = 2.0

var _heat_tick_damage: float = 3.0

var _tick_timer: float = 0.0

var _in_poison_zone: bool = false

var _in_heat_zone: bool = false

var _ash_storm: bool = false
var cold_buildup: float = 0.0
var cold_active: bool = false
var _cold_tick_damage: float = 2.5
var _in_cold_zone: bool = false
var _blizzard: bool = false
var _warm_shelter: bool = false

# Coastal exposure (Shattered Coast)
signal storm_buildup_changed(current: float, threshold: float)
signal storm_applied
signal storm_cleared
signal salt_buildup_changed(current: float, threshold: float)
signal salt_applied
signal salt_cleared

@export var storm_threshold: float = 100.0
@export var storm_buildup_rate: float = 20.0
@export var storm_decay_rate: float = 32.0
@export var storm_resist: float = 0.0
@export var salt_threshold: float = 100.0
@export var salt_buildup_rate: float = 12.0
@export var salt_decay_rate: float = 22.0
@export var salt_resist: float = 0.0

var storm_buildup: float = 0.0
var storm_active: bool = false
var salt_buildup: float = 0.0
var salt_active: bool = false
var soaked_active: bool = false
var _in_storm_zone: bool = false
var _in_salt_zone: bool = false
var _storm_weather: bool = false
var _heavy_rain: bool = false
var _coastal_shelter: bool = false
var _soaked_timer: float = 0.0

# Blight exposure (Blightreach)
signal blight_buildup_changed(current: float, threshold: float)
signal blight_applied
signal blight_cleared
signal spore_buildup_changed(current: float, threshold: float)
signal spore_applied
signal spore_cleared
signal corruption_applied
signal corruption_cleared

@export var blight_threshold: float = 100.0
@export var blight_buildup_rate: float = 18.0
@export var blight_decay_rate: float = 28.0
@export var blight_resist: float = 0.0
@export var spore_threshold: float = 100.0
@export var spore_buildup_rate: float = 14.0
@export var spore_decay_rate: float = 24.0
@export var spore_resist: float = 0.0
@export var corruption_sustain_sec: float = 6.0

var blight_buildup: float = 0.0
var blight_exposure_active: bool = false
var spore_buildup: float = 0.0
var spore_active: bool = false
var corruption_active: bool = false
var _in_blight_zone: bool = false
var _in_spore_zone: bool = false
var _blight_shelter: bool = false
var _blight_surge: bool = false
var _corruption_timer: float = 0.0
var _spore_tick_timer: float = 0.0
var _corruption_heal_penalty: float = 0.0

# Desert exposure (Ember Wastes)
signal dehydration_buildup_changed(current: float, threshold: float)
signal dehydration_applied
signal dehydration_cleared
signal sand_lung_buildup_changed(current: float, threshold: float)
signal sand_lung_applied
signal sand_lung_cleared

@export var dehydration_threshold: float = 100.0
@export var dehydration_buildup_rate: float = 8.0
@export var dehydration_decay_rate: float = 22.0
@export var sand_lung_threshold: float = 100.0
@export var sand_lung_buildup_rate: float = 14.0
@export var sand_lung_decay_rate: float = 26.0

var dehydration_buildup: float = 0.0
var dehydration_active: bool = false
var sand_lung_buildup: float = 0.0
var sand_lung_active: bool = false
var _desert_shelter: bool = false
var _sandstorm: bool = false
var _in_glass_dune: bool = false
var _dehydration_tick_timer: float = 0.0
var _sand_lung_cough_timer: float = 0.0





func _process(delta: float) -> void:
	_process_poison(delta)
	_process_heat(delta)
	_process_cold(delta)
	_process_coastal(delta)
	_process_blight(delta)
	_process_desert(delta)
	_process_dominion(delta)





func _process_poison(delta: float) -> void:

	if _in_poison_zone and not poison_active:

		var rate := buildup_rate * (1.0 - clampf(poison_resist, 0.0, 0.85))

		poison_buildup = minf(poison_buildup + rate * delta, poison_threshold * 1.2)

		poison_buildup_changed.emit(poison_buildup, poison_threshold)

		if poison_buildup >= poison_threshold:

			_apply_poison()

	elif not _in_poison_zone and not poison_active:

		if poison_buildup > 0.0:

			poison_buildup = maxf(poison_buildup - decay_rate * delta, 0.0)

			poison_buildup_changed.emit(poison_buildup, poison_threshold)

	if poison_active:

		_tick_timer -= delta

		if _tick_timer <= 0.0:

			_tick_timer = 1.0

			_apply_dot(_tick_damage, DamageData.DamageType.POISON)





func _process_heat(delta: float) -> void:

	var in_heat := _in_heat_zone or _ash_storm

	if in_heat and not heat_active:

		var rate := heat_buildup_rate * (1.0 - clampf(heat_resist, 0.0, 0.85))

		if _ash_storm:

			rate *= 0.45

		heat_buildup = minf(heat_buildup + rate * delta, heat_threshold * 1.2)

		heat_buildup_changed.emit(heat_buildup, heat_threshold)

		if heat_buildup >= heat_threshold:

			_apply_heat_burn()

	elif not in_heat and not heat_active:

		if heat_buildup > 0.0:

			heat_buildup = maxf(heat_buildup - heat_decay_rate * delta, 0.0)

			heat_buildup_changed.emit(heat_buildup, heat_threshold)

	if heat_active:

		_tick_timer -= delta

		if _tick_timer <= 0.0:

			_tick_timer = 1.0

			_apply_dot(_heat_tick_damage, DamageData.DamageType.FIRE)





func _apply_dot(amount: float, dtype: int) -> void:

	var owner_node := get_parent()

	if owner_node and owner_node.has_node("HealthComponent"):

		var dmg := DamageData.create_physical(amount, owner_node)

		dmg.damage_type = dtype

		(owner_node.get_node("HealthComponent") as HealthComponent).apply_damage(dmg)


func apply_spell_poison_dot(tick_damage: float, tick_count: int, tick_interval: float, source: Node = null) -> void:
	if tick_count <= 0 or tick_damage <= 0.0:
		return
	var owner_node := get_parent()
	if owner_node == null:
		return
	for i in tick_count:
		var delay := tick_interval * float(i + 1)
		get_tree().create_timer(delay).timeout.connect(func() -> void:
			if not is_instance_valid(owner_node) or not owner_node.has_node("HealthComponent"):
				return
			var health := owner_node.get_node("HealthComponent") as HealthComponent
			if health.current_health <= 0.0:
				return
			var dmg := DamageData.create_physical(tick_damage, source if source else owner_node)
			dmg.damage_type = DamageData.DamageType.POISON
			health.apply_damage(dmg)
		, CONNECT_ONE_SHOT)


func set_in_poison_zone(active: bool) -> void:

	_in_poison_zone = active





func set_in_heat_zone(active: bool) -> void:

	_in_heat_zone = active





func set_ash_storm_exposure(active: bool) -> void:

	_ash_storm = active





func add_poison_buildup(amount: float) -> void:

	if poison_active:

		return

	poison_buildup = minf(poison_buildup + amount * (1.0 - clampf(poison_resist, 0.0, 0.85)), poison_threshold * 1.2)

	poison_buildup_changed.emit(poison_buildup, poison_threshold)

	if poison_buildup >= poison_threshold:

		_apply_poison()





func add_heat_buildup(amount: float) -> void:

	if heat_active:

		return

	heat_buildup = minf(heat_buildup + amount * (1.0 - clampf(heat_resist, 0.0, 0.85)), heat_threshold * 1.2)

	heat_buildup_changed.emit(heat_buildup, heat_threshold)

	if heat_buildup >= heat_threshold:

		_apply_heat_burn()





func clear_poison() -> void:

	poison_active = false

	poison_buildup = 0.0

	poison_cleared.emit()

	poison_buildup_changed.emit(0.0, poison_threshold)





func clear_heat() -> void:

	heat_active = false

	heat_buildup = 0.0

	heat_cleared.emit()

	heat_buildup_changed.emit(0.0, heat_threshold)





func clear_environmental() -> void:
	clear_poison()
	clear_heat()
	clear_cold()
	clear_coastal_exposure()
	clear_blight_exposure()





func apply_resistance_bonus(duration_sec: float = 60.0) -> void:

	poison_resist = maxf(poison_resist, 0.5)

	await get_tree().create_timer(duration_sec).timeout

	poison_resist = 0.0





func apply_heat_resistance_bonus(duration_sec: float = 90.0) -> void:
	heat_resist = maxf(heat_resist, 0.55)
	await get_tree().create_timer(duration_sec).timeout
	heat_resist = 0.0


func _process_cold(delta: float) -> void:
	if _warm_shelter:
		if cold_buildup > 0.0 and not cold_active:
			cold_buildup = maxf(cold_buildup - cold_decay_rate * 2.0 * delta, 0.0)
			cold_buildup_changed.emit(cold_buildup, cold_threshold)
		return
	var in_cold := _in_cold_zone or _blizzard
	if in_cold and not cold_active:
		var rate := cold_buildup_rate * (1.0 - clampf(cold_resist, 0.0, 0.85))
		if _blizzard:
			rate *= 1.35
		cold_buildup = minf(cold_buildup + rate * delta, cold_threshold * 1.2)
		cold_buildup_changed.emit(cold_buildup, cold_threshold)
		if cold_buildup >= cold_threshold:
			_apply_frostbite()
	elif not in_cold and not cold_active:
		if cold_buildup > 0.0:
			cold_buildup = maxf(cold_buildup - cold_decay_rate * delta, 0.0)
			cold_buildup_changed.emit(cold_buildup, cold_threshold)
	if cold_active:
		_tick_timer -= delta
		if _tick_timer <= 0.0:
			_tick_timer = 1.0
			_apply_dot(_cold_tick_damage, DamageData.DamageType.FROST)


func set_in_cold_zone(active: bool) -> void:
	_in_cold_zone = active


func set_blizzard_exposure(active: bool) -> void:
	_blizzard = active


func set_warm_shelter(active: bool) -> void:
	_warm_shelter = active


func add_cold_buildup(amount: float) -> void:
	if cold_active:
		return
	cold_buildup = minf(cold_buildup + amount * (1.0 - clampf(cold_resist, 0.0, 0.85)), cold_threshold * 1.2)
	cold_buildup_changed.emit(cold_buildup, cold_threshold)
	if cold_buildup >= cold_threshold:
		_apply_frostbite()


func clear_cold() -> void:
	cold_active = false
	cold_buildup = 0.0
	cold_cleared.emit()
	cold_buildup_changed.emit(0.0, cold_threshold)


func apply_cold_resistance_bonus(duration_sec: float = 90.0) -> void:
	cold_resist = maxf(cold_resist, 0.55)
	await get_tree().create_timer(duration_sec).timeout
	cold_resist = 0.0


func _apply_frostbite() -> void:
	if cold_active:
		return
	cold_active = true
	cold_applied.emit()
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("show_toast"):
			hud.show_toast("Frostbite!")


func _apply_poison() -> void:

	if poison_active:

		return

	poison_active = true

	poison_applied.emit()

	for hud in get_tree().get_nodes_in_group("game_hud"):

		if hud.has_method("show_toast"):

			hud.show_toast("Poisoned!")





func _apply_heat_burn() -> void:

	if heat_active:

		return

	heat_active = true

	heat_applied.emit()

	for hud in get_tree().get_nodes_in_group("game_hud"):

		if hud.has_method("show_toast"):

			hud.show_toast("Overheated!")





func get_move_speed_multiplier() -> float:
	var mult := 1.0
	if poison_active:
		mult *= 0.92
	if heat_active:
		mult *= 0.88
	if cold_active:
		mult *= 0.86
	if salt_active:
		mult *= 0.9
	if spore_active:
		mult *= 0.88
	if blight_exposure_active:
		mult *= 0.9
	if corruption_active:
		mult *= 0.84
	return mult


func get_healing_multiplier() -> float:
	if corruption_active:
		return 0.65
	if blight_exposure_active:
		return 0.85
	return 1.0


func _process_coastal(delta: float) -> void:
	if GameManager.current_region_id != "shattered_coast" and not DungeonManager.in_dungeon:
		return
	if _coastal_shelter:
		if storm_buildup > 0.0 and not storm_active:
			storm_buildup = maxf(storm_buildup - storm_decay_rate * 2.0 * delta, 0.0)
			storm_buildup_changed.emit(storm_buildup, storm_threshold)
		if salt_buildup > 0.0 and not salt_active:
			salt_buildup = maxf(salt_buildup - salt_decay_rate * 2.0 * delta, 0.0)
			salt_buildup_changed.emit(salt_buildup, salt_threshold)
		if soaked_active:
			_decay_soaked(delta, 2.5)
		return
	var in_storm := _in_storm_zone or _storm_weather or _heavy_rain
	if in_storm and not storm_active:
		var rate := storm_buildup_rate * (1.0 - clampf(storm_resist, 0.0, 0.85))
		if soaked_active:
			rate *= 1.25
		storm_buildup = minf(storm_buildup + rate * delta, storm_threshold * 1.2)
		storm_buildup_changed.emit(storm_buildup, storm_threshold)
		if storm_buildup >= storm_threshold:
			_apply_storm_shock()
	elif not in_storm and not storm_active:
		if storm_buildup > 0.0:
			storm_buildup = maxf(storm_buildup - storm_decay_rate * delta, 0.0)
			storm_buildup_changed.emit(storm_buildup, storm_threshold)
	if _in_salt_zone and not salt_active:
		var salt_rate := salt_buildup_rate * (1.0 - clampf(salt_resist, 0.0, 0.85))
		salt_buildup = minf(salt_buildup + salt_rate * delta, salt_threshold * 1.2)
		salt_buildup_changed.emit(salt_buildup, salt_threshold)
		if salt_buildup >= salt_threshold:
			_apply_salt_corruption()
	elif not _in_salt_zone and not salt_active:
		if salt_buildup > 0.0:
			salt_buildup = maxf(salt_buildup - salt_decay_rate * delta, 0.0)
			salt_buildup_changed.emit(salt_buildup, salt_threshold)
	if _heavy_rain and not soaked_active:
		apply_soaked()
	if soaked_active:
		_decay_soaked(delta, 1.0)


func set_storm_exposure(active: bool) -> void:
	_storm_weather = active


func set_heavy_rain(active: bool) -> void:
	_heavy_rain = active


func set_in_storm_zone(active: bool) -> void:
	_in_storm_zone = active


func set_in_salt_zone(active: bool) -> void:
	_in_salt_zone = active


func set_coastal_shelter(active: bool) -> void:
	_coastal_shelter = active


func apply_soaked() -> void:
	soaked_active = true
	_soaked_timer = 8.0


func add_storm_buildup(amount: float) -> void:
	if storm_active:
		return
	storm_buildup = minf(storm_buildup + amount * (1.0 - clampf(storm_resist, 0.0, 0.85)), storm_threshold * 1.2)
	storm_buildup_changed.emit(storm_buildup, storm_threshold)
	if storm_buildup >= storm_threshold:
		_apply_storm_shock()


func clear_coastal_exposure() -> void:
	clear_storm()
	clear_salt()
	soaked_active = false
	_soaked_timer = 0.0


func clear_storm() -> void:
	storm_active = false
	storm_buildup = 0.0
	storm_cleared.emit()
	storm_buildup_changed.emit(0.0, storm_threshold)


func clear_salt() -> void:
	salt_active = false
	salt_buildup = 0.0
	salt_cleared.emit()
	salt_buildup_changed.emit(0.0, salt_threshold)


func _apply_storm_shock() -> void:
	if storm_active:
		return
	storm_active = true
	storm_applied.emit()
	_apply_dot(8.0, DamageData.DamageType.FROST)
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("show_toast"):
			hud.show_toast("Storm Charged!")


func _apply_salt_corruption() -> void:
	if salt_active:
		return
	salt_active = true
	salt_applied.emit()
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("show_toast"):
			hud.show_toast("Salt Corruption")


func _decay_soaked(delta: float, rate: float) -> void:
	_soaked_timer -= delta * rate
	if _soaked_timer <= 0.0:
		soaked_active = false


func _process_blight(delta: float) -> void:
	var in_blight_region := GameManager.current_region_id == "blightreach" \
		or GameManager.current_region_id == "blightspire_cathedral" \
		or DungeonManager.current_dungeon_id == "blightspire_cathedral"
	if not in_blight_region and not DungeonManager.in_dungeon:
		return
	if _blight_shelter:
		if blight_buildup > 0.0 and not blight_exposure_active:
			blight_buildup = maxf(blight_buildup - blight_decay_rate * 2.0 * delta, 0.0)
			blight_buildup_changed.emit(blight_buildup, blight_threshold)
		if spore_buildup > 0.0 and not spore_active:
			spore_buildup = maxf(spore_buildup - spore_decay_rate * 2.0 * delta, 0.0)
			spore_buildup_changed.emit(spore_buildup, spore_threshold)
		if corruption_active:
			clear_corruption()
		return
	var in_blight := _in_blight_zone or _blight_surge
	if in_blight and not blight_exposure_active:
		var rate := blight_buildup_rate * (1.0 - clampf(blight_resist, 0.0, 0.85))
		if _blight_surge:
			rate *= 1.35
		blight_buildup = minf(blight_buildup + rate * delta, blight_threshold * 1.2)
		blight_buildup_changed.emit(blight_buildup, blight_threshold)
		if blight_buildup >= blight_threshold:
			_apply_blight_exposure()
	elif not in_blight and not blight_exposure_active:
		if blight_buildup > 0.0:
			blight_buildup = maxf(blight_buildup - blight_decay_rate * delta, 0.0)
			blight_buildup_changed.emit(blight_buildup, blight_threshold)
	if blight_exposure_active and in_blight:
		_corruption_timer += delta
		if _corruption_timer >= corruption_sustain_sec and not corruption_active:
			_apply_corruption()
	elif not in_blight:
		_corruption_timer = maxf(_corruption_timer - delta, 0.0)
	if _in_spore_zone and not spore_active:
		var spore_rate := spore_buildup_rate * (1.0 - clampf(spore_resist, 0.0, 0.85))
		spore_buildup = minf(spore_buildup + spore_rate * delta, spore_threshold * 1.2)
		spore_buildup_changed.emit(spore_buildup, spore_threshold)
		if spore_buildup >= spore_threshold:
			_apply_spore_infection()
	elif not _in_spore_zone and not spore_active:
		if spore_buildup > 0.0:
			spore_buildup = maxf(spore_buildup - spore_decay_rate * delta, 0.0)
			spore_buildup_changed.emit(spore_buildup, spore_threshold)
	if spore_active:
		_spore_tick_timer -= delta
		if _spore_tick_timer <= 0.0:
			_spore_tick_timer = 2.0
			_apply_dot(3.0, DamageData.DamageType.POISON)


func set_in_blight_zone(active: bool) -> void:
	_in_blight_zone = active


func set_in_spore_zone(active: bool) -> void:
	_in_spore_zone = active


func set_blight_shelter(active: bool) -> void:
	_blight_shelter = active


func set_blight_surge(active: bool) -> void:
	_blight_surge = active


func add_blight_buildup(amount: float) -> void:
	if blight_exposure_active:
		return
	blight_buildup = minf(blight_buildup + amount * (1.0 - clampf(blight_resist, 0.0, 0.85)), blight_threshold * 1.2)
	blight_buildup_changed.emit(blight_buildup, blight_threshold)
	if blight_buildup >= blight_threshold:
		_apply_blight_exposure()


func clear_blight_exposure() -> void:
	clear_blight()
	clear_spore()
	clear_corruption()


func clear_blight() -> void:
	blight_exposure_active = false
	blight_buildup = 0.0
	_corruption_timer = 0.0
	blight_cleared.emit()
	blight_buildup_changed.emit(0.0, blight_threshold)


func clear_spore() -> void:
	spore_active = false
	spore_buildup = 0.0
	spore_cleared.emit()
	spore_buildup_changed.emit(0.0, spore_threshold)


func clear_corruption() -> void:
	corruption_active = false
	_corruption_timer = 0.0
	corruption_cleared.emit()


func apply_blight_resistance_bonus(duration_sec: float = 90.0) -> void:
	blight_resist = maxf(blight_resist, 0.55)
	spore_resist = maxf(spore_resist, 0.45)
	await get_tree().create_timer(duration_sec).timeout
	blight_resist = 0.0
	spore_resist = 0.0


func _apply_blight_exposure() -> void:
	if blight_exposure_active:
		return
	blight_exposure_active = true
	blight_applied.emit()
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("show_toast"):
			hud.show_toast("Blight Exposure")


func _apply_spore_infection() -> void:
	if spore_active:
		return
	spore_active = true
	spore_applied.emit()
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("show_toast"):
			hud.show_toast("Spore Infection")


func _apply_corruption() -> void:
	if corruption_active:
		return
	corruption_active = true
	corruption_applied.emit()
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("show_toast"):
			hud.show_toast("Corruption")


func _process_desert(delta: float) -> void:
	var in_desert := GameManager.current_region_id == "ember_wastes" \
		or GameManager.current_region_id == "pyreheart_ziggurat" \
		or DungeonManager.current_dungeon_id == "pyreheart_ziggurat"
	if not in_desert:
		return
	if _desert_shelter:
		if dehydration_buildup > 0.0 and not dehydration_active:
			dehydration_buildup = maxf(dehydration_buildup - dehydration_decay_rate * 2.0 * delta, 0.0)
			dehydration_buildup_changed.emit(dehydration_buildup, dehydration_threshold)
		if sand_lung_buildup > 0.0 and not sand_lung_active:
			sand_lung_buildup = maxf(sand_lung_buildup - sand_lung_decay_rate * 2.0 * delta, 0.0)
			sand_lung_buildup_changed.emit(sand_lung_buildup, sand_lung_threshold)
		if heat_buildup > 0.0 and not heat_active:
			heat_buildup = maxf(heat_buildup - heat_decay_rate * 2.0 * delta, 0.0)
			heat_buildup_changed.emit(heat_buildup, heat_threshold)
		return
	var heat_exposed := _in_heat_zone or _in_glass_dune
	if heat_exposed and not dehydration_active:
		var rate := dehydration_buildup_rate
		if _in_glass_dune:
			rate *= 1.25
		dehydration_buildup = minf(dehydration_buildup + rate * delta, dehydration_threshold * 1.2)
		dehydration_buildup_changed.emit(dehydration_buildup, dehydration_threshold)
		if dehydration_buildup >= dehydration_threshold:
			_apply_dehydration()
	elif not heat_exposed and not dehydration_active:
		if dehydration_buildup > 0.0:
			dehydration_buildup = maxf(dehydration_buildup - dehydration_decay_rate * delta, 0.0)
			dehydration_buildup_changed.emit(dehydration_buildup, dehydration_threshold)
	if _sandstorm and not sand_lung_active:
		var sl_rate := sand_lung_buildup_rate
		sand_lung_buildup = minf(sand_lung_buildup + sl_rate * delta, sand_lung_threshold * 1.2)
		sand_lung_buildup_changed.emit(sand_lung_buildup, sand_lung_threshold)
		if sand_lung_buildup >= sand_lung_threshold:
			_apply_sand_lung()
	elif not _sandstorm and not sand_lung_active:
		if sand_lung_buildup > 0.0:
			sand_lung_buildup = maxf(sand_lung_buildup - sand_lung_decay_rate * delta, 0.0)
			sand_lung_buildup_changed.emit(sand_lung_buildup, sand_lung_threshold)
	if dehydration_active:
		_dehydration_tick_timer -= delta
		if _dehydration_tick_timer <= 0.0:
			_dehydration_tick_timer = 2.5
			_apply_dot(1.5, DamageData.DamageType.FIRE)
	if sand_lung_active:
		_sand_lung_cough_timer -= delta
		if _sand_lung_cough_timer <= 0.0:
			_sand_lung_cough_timer = 4.0
			var owner_node := get_parent()
			if owner_node is CharacterBody3D:
				(owner_node as CharacterBody3D).velocity *= 0.85


func set_desert_shelter(active: bool) -> void:
	_desert_shelter = active


func set_sandstorm_exposure(active: bool) -> void:
	_sandstorm = active


func set_glass_dune(active: bool) -> void:
	_in_glass_dune = active


func clear_desert_exposure() -> void:
	clear_dehydration()
	clear_sand_lung()
	if not heat_active:
		heat_buildup = 0.0
		heat_buildup_changed.emit(0.0, heat_threshold)


func clear_dehydration() -> void:
	dehydration_active = false
	dehydration_buildup = 0.0
	dehydration_cleared.emit()
	dehydration_buildup_changed.emit(0.0, dehydration_threshold)


func clear_sand_lung() -> void:
	sand_lung_active = false
	sand_lung_buildup = 0.0
	sand_lung_cleared.emit()
	sand_lung_buildup_changed.emit(0.0, sand_lung_threshold)


func restore_hydration(amount: float = 35.0) -> void:
	clear_dehydration()
	var owner_node := get_parent()
	if owner_node and owner_node.has_node("SurvivalNeedsComponent"):
		var needs := owner_node.get_node("SurvivalNeedsComponent")
		needs.thirst = minf(needs.thirst + amount, needs.max_thirst)


func _apply_dehydration() -> void:
	if dehydration_active:
		return
	dehydration_active = true
	dehydration_applied.emit()
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("show_toast"):
			hud.show_toast("Dehydration — seek water or shade")


func _apply_sand_lung() -> void:
	if sand_lung_active:
		return
	sand_lung_active = true
	sand_lung_applied.emit()
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("show_toast"):
			hud.show_toast("Sand Lung — seek shelter")


# Sunless Dominion — Dread, Shadow, Curse, Umbral Sickness
signal dread_buildup_changed(current: float, threshold: float)
signal dread_applied
signal dread_cleared
signal shadow_buildup_changed(current: float, threshold: float)
signal shadow_applied
signal shadow_cleared
signal curse_applied
signal curse_cleared
signal umbral_sickness_applied
signal umbral_sickness_cleared

@export var dread_threshold: float = 100.0
@export var dread_buildup_rate: float = 16.0
@export var dread_decay_rate: float = 24.0
@export var shadow_threshold: float = 100.0
@export var shadow_buildup_rate: float = 18.0
@export var shadow_decay_rate: float = 26.0

var dread_buildup: float = 0.0
var dread_active: bool = false
var shadow_buildup: float = 0.0
var shadow_active: bool = false
var curse_active: bool = false
var umbral_sickness_active: bool = false
var dread_resist: float = 0.0
var shadow_resist: float = 0.0
var _in_dread_zone: bool = false
var _in_shadow_pool: bool = false
var _in_shadow_ground: bool = false
var _shadow_shelter: bool = false
var _eclipse_surge: bool = false
var _curse_timer: float = 0.0
var _umbral_tick_timer: float = 0.0


func _process_dominion(delta: float) -> void:
	var in_dominion := GameManager.current_region_id in ["sunless_dominion", "eclipse_sanctum"] \
		or DungeonManager.current_dungeon_id == "eclipse_sanctum"
	if not in_dominion:
		if dread_buildup > 0.0 and not dread_active:
			dread_buildup = maxf(dread_buildup - dread_decay_rate * 2.0 * delta, 0.0)
			dread_buildup_changed.emit(dread_buildup, dread_threshold)
		if shadow_buildup > 0.0 and not shadow_active:
			shadow_buildup = maxf(shadow_buildup - shadow_decay_rate * 2.0 * delta, 0.0)
			shadow_buildup_changed.emit(shadow_buildup, shadow_threshold)
		return
	var in_dread := _in_dread_zone or _eclipse_surge
	if _shadow_shelter:
		if dread_buildup > 0.0 and not dread_active:
			dread_buildup = maxf(dread_buildup - dread_decay_rate * 2.5 * delta, 0.0)
			dread_buildup_changed.emit(dread_buildup, dread_threshold)
		if shadow_buildup > 0.0 and not shadow_active:
			shadow_buildup = maxf(shadow_buildup - shadow_decay_rate * 2.5 * delta, 0.0)
			shadow_buildup_changed.emit(shadow_buildup, shadow_threshold)
		return
	if in_dread and not dread_active:
		var rate := dread_buildup_rate * (1.0 - clampf(dread_resist, 0.0, 0.85))
		if _eclipse_surge:
			rate *= 1.35
		dread_buildup = minf(dread_buildup + rate * delta, dread_threshold * 1.2)
		dread_buildup_changed.emit(dread_buildup, dread_threshold)
		if dread_buildup >= dread_threshold:
			_apply_dread()
	elif not in_dread and not dread_active:
		if dread_buildup > 0.0:
			dread_buildup = maxf(dread_buildup - dread_decay_rate * delta, 0.0)
			dread_buildup_changed.emit(dread_buildup, dread_threshold)
	if (_in_shadow_pool or _in_shadow_ground) and not shadow_active:
		var s_rate := shadow_buildup_rate * (1.0 - clampf(shadow_resist, 0.0, 0.85))
		shadow_buildup = minf(shadow_buildup + s_rate * delta, shadow_threshold * 1.2)
		shadow_buildup_changed.emit(shadow_buildup, shadow_threshold)
		if shadow_buildup >= shadow_threshold:
			_apply_shadow_exposure()
	elif not _in_shadow_pool and not _in_shadow_ground and not shadow_active:
		if shadow_buildup > 0.0:
			shadow_buildup = maxf(shadow_buildup - shadow_decay_rate * delta, 0.0)
			shadow_buildup_changed.emit(shadow_buildup, shadow_threshold)
	if curse_active:
		_curse_timer -= delta
		if _curse_timer <= 0.0:
			clear_curse()
	if umbral_sickness_active:
		_umbral_tick_timer -= delta
		if _umbral_tick_timer <= 0.0:
			_umbral_tick_timer = 3.0
			_apply_dot(2.0, DamageData.DamageType.DARK)


func set_in_dread_zone(active: bool) -> void:
	_in_dread_zone = active


func set_in_shadow_pool(active: bool) -> void:
	_in_shadow_pool = active


func set_in_shadow_ground(active: bool) -> void:
	_in_shadow_ground = active


func set_shadow_shelter(active: bool) -> void:
	_shadow_shelter = active


func set_eclipse_surge(active: bool) -> void:
	_eclipse_surge = active


func add_dread_buildup(amount: float) -> void:
	if dread_active:
		return
	dread_buildup = minf(dread_buildup + amount * (1.0 - clampf(dread_resist, 0.0, 0.85)), dread_threshold * 1.2)
	dread_buildup_changed.emit(dread_buildup, dread_threshold)
	if dread_buildup >= dread_threshold:
		_apply_dread()


func add_shadow_buildup(amount: float) -> void:
	if shadow_active:
		return
	shadow_buildup = minf(shadow_buildup + amount * (1.0 - clampf(shadow_resist, 0.0, 0.85)), shadow_threshold * 1.2)
	shadow_buildup_changed.emit(shadow_buildup, shadow_threshold)
	if shadow_buildup >= shadow_threshold:
		_apply_shadow_exposure()


func apply_curse(duration: float = 8.0) -> void:
	curse_active = true
	_curse_timer = duration
	curse_applied.emit()


func clear_curse() -> void:
	curse_active = false
	_curse_timer = 0.0
	curse_cleared.emit()


func clear_dominion_exposure() -> void:
	clear_dread()
	clear_shadow()
	clear_curse()
	clear_umbral_sickness()


func clear_dread() -> void:
	dread_active = false
	dread_buildup = 0.0
	dread_cleared.emit()
	dread_buildup_changed.emit(0.0, dread_threshold)


func clear_shadow() -> void:
	shadow_active = false
	shadow_buildup = 0.0
	shadow_cleared.emit()
	shadow_buildup_changed.emit(0.0, shadow_threshold)


func clear_umbral_sickness() -> void:
	umbral_sickness_active = false
	umbral_sickness_cleared.emit()


func apply_dread_resistance_bonus(duration_sec: float = 90.0) -> void:
	dread_resist = maxf(dread_resist, 0.55)
	shadow_resist = maxf(shadow_resist, 0.45)
	await get_tree().create_timer(duration_sec).timeout
	dread_resist = 0.0
	shadow_resist = 0.0


func _apply_dread() -> void:
	if dread_active:
		return
	dread_active = true
	dread_applied.emit()
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("show_toast"):
			hud.show_toast("Dread — seek ward light")


func _apply_shadow_exposure() -> void:
	if shadow_active:
		return
	shadow_active = true
	shadow_applied.emit()
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("show_toast"):
			hud.show_toast("Shadow Exposure")
	if not umbral_sickness_active and shadow_buildup >= shadow_threshold * 1.05:
		umbral_sickness_active = true
		umbral_sickness_applied.emit()

