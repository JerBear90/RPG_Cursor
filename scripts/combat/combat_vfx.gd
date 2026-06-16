extends Node
## Lightweight combat feedback — hit flashes, death puffs, spell bursts.

const _HIT_COLOR := Color(1.0, 0.55, 0.2)
const _DEATH_COLOR := Color(0.35, 0.35, 0.4, 0.9)
const _SPELL_COLOR := Color(0.45, 0.75, 1.0)
const _HEAL_COLOR := Color(0.35, 0.95, 0.45)
const _PLAYER_DAMAGE_COLOR := Color(1.0, 0.32, 0.28)
const _ENEMY_DAMAGE_COLOR := Color(1.0, 0.82, 0.45)


func spawn_hit(world_pos: Vector3, color: Color = _HIT_COLOR) -> void:
	_spawn_burst(world_pos, color, 0.22, 0.28)


func spawn_blood(world_pos: Vector3) -> void:
	var root := get_tree().current_scene
	if root == null:
		return
	var holder := Node3D.new()
	holder.global_position = world_pos
	root.add_child(holder)
	for i in 8:
		var mi := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.06 + randf() * 0.05
		mi.mesh = sphere
		var mat := StandardMaterial3D.new()
		var red := Color(0.72, 0.05, 0.04)
		mat.albedo_color = red
		mat.emission_enabled = true
		mat.emission = red * 0.6
		mat.emission_energy_multiplier = 1.8
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mi.material_override = mat
		holder.add_child(mi)
		var dir := Vector3(randf_range(-1, 1), randf_range(0.2, 1), randf_range(-1, 1)).normalized()
		var dist := randf_range(0.25, 0.65)
		var dur := randf_range(0.18, 0.32)
		var tween := mi.create_tween()
		tween.set_parallel(true)
		tween.tween_property(mi, "global_position", world_pos + dir * dist, dur)
		tween.tween_property(mat, "albedo_color:a", 0.0, dur)
		tween.tween_property(mi, "scale", Vector3.ZERO, dur)
	_spawn_burst(world_pos, Color(0.55, 0.04, 0.03, 0.85), 0.12, 0.16)
	var cleanup := holder.create_tween()
	cleanup.tween_interval(0.4)
	cleanup.tween_callback(holder.queue_free)


func spawn_death(world_pos: Vector3) -> void:
	_spawn_burst(world_pos + Vector3(0, 0.8, 0), _DEATH_COLOR, 0.55, 0.45)


func spawn_spell(world_pos: Vector3) -> void:
	_spawn_burst(world_pos, _SPELL_COLOR, 0.35, 0.32)


func spawn_heal(world_pos: Vector3) -> void:
	_spawn_burst(world_pos + Vector3(0, 1.0, 0), _HEAL_COLOR, 0.3, 0.35)


func spawn_damage_number(world_pos: Vector3, amount: float, on_player: bool = false) -> void:
	if amount <= 0.0:
		return
	var root := get_tree().current_scene
	if root == null:
		return
	var label := Label3D.new()
	label.text = "-%d" % int(round(amount))
	label.font_size = 42 if on_player else 36
	label.outline_size = 10
	label.modulate = _PLAYER_DAMAGE_COLOR if on_player else _ENEMY_DAMAGE_COLOR
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.fixed_size = true
	label.position = world_pos + Vector3(randf_range(-0.15, 0.15), 0.0, randf_range(-0.15, 0.15))
	root.add_child(label)
	var rise := Vector3(0, 1.35 if on_player else 1.0, 0)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position + rise, 0.9).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(label, "modulate:a", 0.0, 0.9).set_delay(0.15)
	var cleanup := label.create_tween()
	cleanup.tween_interval(0.95)
	cleanup.tween_callback(label.queue_free)


func spawn_combat_status(world_pos: Vector3, status_text: String) -> void:
	var root := get_tree().current_scene
	if root == null:
		return
	var label := Label3D.new()
	label.text = status_text
	label.font_size = 34
	label.outline_size = 8
	label.modulate = Color(0.85, 0.9, 1.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.fixed_size = true
	label.position = world_pos
	root.add_child(label)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position + Vector3(0, 0.9, 0), 0.75)
	tween.tween_property(label, "modulate:a", 0.0, 0.75).set_delay(0.1)
	var cleanup := label.create_tween()
	cleanup.tween_interval(0.8)
	cleanup.tween_callback(label.queue_free)


func _spawn_burst(world_pos: Vector3, color: Color, start_scale: float, duration: float) -> void:
	var root := get_tree().current_scene
	if root == null:
		return
	var holder := Node3D.new()
	holder.global_position = world_pos
	root.add_child(holder)
	for i in 3:
		var mi := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.18 + float(i) * 0.06
		mi.mesh = sphere
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 2.5
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mi.material_override = mat
		mi.scale = Vector3.ONE * start_scale
		holder.add_child(mi)
		var tween := mi.create_tween()
		tween.set_parallel(true)
		tween.tween_property(mi, "scale", Vector3.ZERO, duration)
		tween.tween_property(mat, "albedo_color:a", 0.0, duration)
	var cleanup := holder.create_tween()
	cleanup.tween_interval(duration + 0.05)
	cleanup.tween_callback(holder.queue_free)
