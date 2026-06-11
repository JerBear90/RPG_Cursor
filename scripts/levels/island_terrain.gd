extends Node3D
## Procedural overworld terrain using Kenney Nature Kit tiles.

const _Kenney = preload("res://scripts/utilities/kenney_paths.gd")
const _Tint = preload("res://scripts/utilities/kenney_material_tint.gd")
const _DestructibleFactory = preload("res://scripts/destructibles/destructible_prop_factory.gd")

const DEFAULT_TREE_POOL: Array[String] = [
	"tree_pineDefaultA.glb", "tree_pineDefaultB.glb", "tree_oak.glb",
	"tree_detailed.glb", "tree_pineRoundA.glb", "tree_pineTallA.glb",
	"tree_pineTallB.glb", "tree_tall.glb",
]
const DEFAULT_ROCK_POOL: Array[String] = [
	"rock_smallA.glb", "rock_smallB.glb", "stone_smallA.glb", "stone_smallB.glb",
]
const DEFAULT_GRASS_POOL: Array[String] = [
	"grass.glb", "grass_large.glb", "grass_leafs.glb",
]
const DEFAULT_BUSH_POOL: Array[String] = [
	"plant_bush.glb", "plant_bushSmall.glb", "plant_bushDetailed.glb",
	"flower_yellowA.glb", "flower_redA.glb", "mushroom_red.glb",
]
const SHORE_ROCK_POOL: Array[String] = [
	"rock_largeA.glb", "rock_largeB.glb", "rock_tallA.glb", "cliff_block_rock.glb",
]
const WORLD_COLLISION_LAYER := 1
const PROP_COLLISION_LAYER := 8
const WORLD_COLLISION_MASK := 6  # player (layer 2) + enemies (layer 4)

@export var region_id: String = ""
@export_enum("island", "camp") var terrain_mode: String = "island"
@export var island_radius: float = 28.0
@export var water_extent: float = 52.0
@export var tile_step: float = 2.0
@export var tile_scale: float = 2.25
@export var tree_scale_min: float = 2.4
@export var tree_scale_max: float = 3.0
@export var grass_clump_scale_min: float = 1.8
@export var grass_clump_scale_max: float = 2.6
@export var scatter_trees: int = 28
@export var scatter_rocks: int = 18
@export var scatter_grass: int = 50
@export var scatter_bushes: int = 14
@export var land_tile: String = "ground_grass.glb"
@export var apply_dark_tint: bool = true
@export var meshes_per_frame: int = 40

@onready var _land: Node3D = $Land
@onready var _water: Node3D = $Water
@onready var _props: Node3D = $Props
@onready var _nav_region: NavigationRegion3D = $NavigationRegion3D

var _tree_pool: Array[String] = []
var _rock_pool: Array[String] = []
var _grass_pool: Array[String] = []
var _bush_pool: Array[String] = []
var _mesh_queue: Array[Dictionary] = []
var _ground_ready: bool = false

signal ground_ready


func is_ground_ready() -> bool:
	return _ground_ready


func _ready() -> void:
	add_to_group("island_terrain")
	_init_asset_pools()
	if region_id != "":
		_apply_region_layout(MapManager.get_region_layout(region_id))
	if terrain_mode == "camp":
		island_radius = minf(island_radius, 18.0)
		water_extent = 0.0
		scatter_trees = mini(scatter_trees, 10)
		scatter_rocks = mini(scatter_rocks, 8)
		scatter_grass = mini(scatter_grass, 24)
		scatter_bushes = mini(scatter_bushes, 8)
	_setup_world_environment()
	_boost_level_lighting()
	_build_ground_base()
	_build_spawn_pad()
	_build_immediate_vista()
	call_deferred("_begin_build")


func _begin_build() -> void:
	await _build_details()


func _init_asset_pools() -> void:
	_tree_pool = DEFAULT_TREE_POOL.duplicate()
	_rock_pool = DEFAULT_ROCK_POOL.duplicate()
	_grass_pool = DEFAULT_GRASS_POOL.duplicate()
	_bush_pool = DEFAULT_BUSH_POOL.duplicate()


func _build_details() -> void:
	await get_tree().process_frame
	_build_region_landmarks()
	_queue_scatter_props()
	_build_navigation_mesh()
	call_deferred("_ensure_boundary_hazard")
	await _run_mesh_pipeline()
	_hide_ground_fill_if_tiled()


func _run_mesh_pipeline() -> void:
	await _flush_mesh_queue()
	_queue_land_tiles()
	await _flush_mesh_queue()
	if terrain_mode == "island" and water_extent > 0.0:
		_build_water_base()
		_queue_water_shore_strip()
		await _flush_mesh_queue()
		_queue_shore_rocks()
		await _flush_mesh_queue()
	if terrain_mode == "camp":
		_queue_camp_fence()
		await _flush_mesh_queue()


func _boost_level_lighting() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var env_node := parent.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if env_node and env_node.environment:
		var env := env_node.environment
		env.background_mode = Environment.BG_SKY
		if env.sky == null:
			var sky := Sky.new()
			sky.sky_material = ProceduralSkyMaterial.new()
			env.sky = sky
		var sky_mat := env.sky.sky_material as ProceduralSkyMaterial
		if sky_mat:
			sky_mat.sky_top_color = Color(0.22, 0.38, 0.62)
			sky_mat.sky_horizon_color = Color(0.55, 0.62, 0.72)
			sky_mat.ground_horizon_color = Color(0.32, 0.48, 0.28)
			sky_mat.ground_bottom_color = Color(0.18, 0.28, 0.16)
			sky_mat.sun_angle_max = 35.0
		env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		env.ambient_light_energy = maxf(env.ambient_light_energy, 1.15)
		env.tonemap_mode = Environment.TONE_MAPPER_ACES
		env.tonemap_exposure = 0.98
		env.fog_enabled = true
		env.fog_light_color = Color(0.38, 0.42, 0.48)
		env.fog_density = 0.006
		env.fog_aerial_perspective = 0.35
		env.sdfgi_enabled = false
	var light := parent.get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	if light:
		light.light_energy = maxf(light.light_energy, 1.35)
		light.light_color = Color(0.92, 0.88, 0.82)
		light.shadow_enabled = true
		light.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
		light.shadow_opacity = 0.55
		light.shadow_blur = 1.2


func _setup_world_environment() -> void:
	if get_node_or_null("WorldEnvironment") != null:
		return
	var parent_env := get_parent().get_node_or_null("WorldEnvironment")
	if parent_env != null:
		return
	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.1, 0.14, 0.22)
	sky_mat.sky_horizon_color = Color(0.28, 0.3, 0.34)
	sky_mat.ground_horizon_color = Color(0.14, 0.18, 0.12)
	sky_mat.ground_bottom_color = Color(0.08, 0.1, 0.08)
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.72
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 0.95
	env.fog_enabled = true
	env.fog_light_color = Color(0.32, 0.36, 0.42)
	env.fog_density = 0.005
	env.fog_aerial_perspective = 0.28
	we.environment = env
	add_child(we)


func _build_ground_base() -> void:
	var parent := get_parent()
	if parent and parent.get_node_or_null("GroundIsland") != null:
		var legacy := parent.get_node_or_null("GroundIsland") as Node
		if legacy:
			for child in legacy.get_children():
				if child is MeshInstance3D:
					child.visible = false
	if _land.get_node_or_null("GroundCollider") != null:
		if not _ground_ready:
			_ground_ready = true
			call_deferred("_emit_ground_ready")
		return
	var body := StaticBody3D.new()
	body.name = "GroundCollider"
	body.collision_layer = WORLD_COLLISION_LAYER
	body.collision_mask = WORLD_COLLISION_MASK
	var col := CollisionShape3D.new()
	if terrain_mode == "camp":
		var box_shape := BoxShape3D.new()
		var size := island_radius * 2.0
		box_shape.size = Vector3(size, 0.6, size)
		col.shape = box_shape
		col.position = Vector3(0.0, -0.3, 0.0)
	else:
		var cyl_shape := CylinderShape3D.new()
		cyl_shape.radius = island_radius
		cyl_shape.height = 3.0
		col.shape = cyl_shape
		col.position = Vector3(0.0, -1.0, 0.0)
	body.add_child(col)
	_land.add_child(body)
	_add_ground_fill_mesh()
	if not _ground_ready:
		_ground_ready = true
		call_deferred("_emit_ground_ready")


func _emit_ground_ready() -> void:
	await get_tree().physics_frame
	ground_ready.emit()


func _add_ground_fill_mesh() -> void:
	if _land.get_node_or_null("GroundFill") != null:
		return
	var mi := MeshInstance3D.new()
	mi.name = "GroundFill"
	var mat := StandardMaterial3D.new()
	if land_tile.contains("platform") or land_tile.contains("stone"):
		mat.albedo_color = Color(0.32, 0.31, 0.3)
	else:
		mat.albedo_color = Color(0.28, 0.48, 0.22)
	mat.roughness = 0.92
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if terrain_mode == "camp":
		var box := BoxMesh.new()
		box.size = Vector3(island_radius * 2.0, 0.5, island_radius * 2.0)
		mi.mesh = box
		mi.position = Vector3(0.0, -0.25, 0.0)
	else:
		var cyl := CylinderMesh.new()
		cyl.top_radius = island_radius
		cyl.bottom_radius = island_radius
		cyl.height = 0.5
		mi.mesh = cyl
		mi.position = Vector3(0.0, -0.25, 0.0)
	_land.add_child(mi)


func _build_spawn_pad() -> void:
	for x in range(-4, 5):
		for z in range(-4, 5):
			var wx := float(x) * tile_step
			var wz := float(z) * tile_step
			if terrain_mode == "island":
				if Vector2(wx, wz).length() > island_radius - tile_step * 0.15:
					continue
			elif absf(wx) > island_radius or absf(wz) > island_radius:
				continue
			_add_mesh(
				_land,
				land_tile,
				Vector3(wx, 0.06, wz),
				randf_range(0.0, 360.0),
				Vector3(tile_scale, 1.0, tile_scale)
			)


func _build_immediate_vista() -> void:
	# Guaranteed visible props near spawn so the world never looks empty on load.
	var ring := [
		["tree_pineDefaultA.glb", Vector3(-11, 0, -4), 20.0, 2.6],
		["tree_oak.glb", Vector3(12, 0, -6), -25.0, 2.7],
		["tree_pineTallA.glb", Vector3(-8, 0, 10), 110.0, 2.9],
		["tree_detailed.glb", Vector3(9, 0, 9), -140.0, 2.5],
		["tree_pineRoundA.glb", Vector3(-14, 0, 4), 75.0, 2.4],
		["tree_tall.glb", Vector3(14, 0, 2), -60.0, 2.8],
		["rock_largeA.glb", Vector3(-5, 0, 8), 0.0, 1.6],
		["rock_smallA.glb", Vector3(6, 0, 7), 45.0, 1.8],
		["plant_bushDetailed.glb", Vector3(-3, 0, -7), 0.0, 1.6],
		["plant_bush.glb", Vector3(4, 0, -6), 30.0, 1.5],
		["grass_large.glb", Vector3(-6, 0, -3), 0.0, 2.2],
		["grass_large.glb", Vector3(7, 0, -2), 90.0, 2.0],
		["flower_yellowA.glb", Vector3(2, 0, 5), 0.0, 1.8],
		["mushroom_red.glb", Vector3(-2, 0, 4), 0.0, 1.8],
		["log_stack.glb", Vector3(5, 0, 3), -15.0, 1.6],
		["campfire_logs.glb", Vector3(-4, 0, -5), 0.0, 1.7],
	]
	for spec in ring:
		if terrain_mode == "island" and Vector2(spec[1].x, spec[1].z).length() > island_radius - 2.0:
			continue
		_add_mesh(
			_props,
			spec[0],
			spec[1],
			spec[2],
			Vector3.ONE * spec[3],
			spec[0].contains("tree") or spec[0].contains("rock_large")
		)


func _hide_ground_fill_if_tiled() -> void:
	# Keep the green underlay visible — Kenney ground tiles are paper-thin planes.
	var fill := _land.get_node_or_null("GroundFill") as MeshInstance3D
	if fill:
		fill.visible = true


func _build_water_base() -> void:
	if _water.get_node_or_null("WaterBase") != null:
		return
	var mi := MeshInstance3D.new()
	mi.name = "WaterBase"
	var cyl := CylinderMesh.new()
	cyl.top_radius = water_extent
	cyl.bottom_radius = water_extent
	cyl.height = 0.25
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.16, 0.28, 0.88)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.06
	mat.metallic = 0.04
	mat.rim_enabled = true
	mat.rim = 0.18
	mat.rim_tint = 0.35
	mat.clearcoat_enabled = true
	mat.clearcoat = 0.12
	mi.mesh = cyl
	mi.material_override = mat
	mi.position = Vector3(0.0, -0.55, 0.0)
	_water.add_child(mi)


func _ensure_boundary_hazard() -> void:
	if get_tree().get_first_node_in_group("water_hazard") != null:
		return
	var hazard := WaterHazard.new()
	hazard.name = "WorldBoundary"
	hazard.island_radius = island_radius
	hazard.use_horizontal_boundary = terrain_mode == "island"
	add_child(hazard)


func _queue_mesh(
	parent: Node3D,
	glb_name: String,
	pos: Vector3,
	rot_y: float = 0.0,
	scale: Vector3 = Vector3.ONE,
	collision: bool = false
) -> void:
	_mesh_queue.append({
		"parent": parent,
		"glb": glb_name,
		"pos": pos,
		"rot_y": rot_y,
		"scale": scale,
		"collision": collision,
	})


func _flush_mesh_queue() -> void:
	while not _mesh_queue.is_empty():
		var batch := mini(meshes_per_frame, _mesh_queue.size())
		for _i in batch:
			var item: Dictionary = _mesh_queue.pop_front()
			_add_mesh(
				item.parent,
				item.glb,
				item.pos,
				item.rot_y,
				item.scale,
				item.collision
			)
		if not _mesh_queue.is_empty():
			await get_tree().process_frame


func _add_mesh(
	parent: Node3D,
	glb_name: String,
	pos: Vector3,
	rot_y: float = 0.0,
	scale: Vector3 = Vector3.ONE,
	collision: bool = false
) -> Node3D:
	var path := _Kenney.nature(glb_name)
	if not FileAccess.file_exists(path):
		push_warning("IslandTerrain: missing %s" % path)
		return null
	var node := MeshLoader.instantiate(path, parent, rot_y, pos, scale)
	if node == null:
		push_warning("IslandTerrain: failed to instantiate %s" % path)
		var kind := "tree" if glb_name.contains("tree") else ("rock" if glb_name.contains("rock") else "prop")
		node = MeshLoader.create_fallback_prop(kind, parent, pos, scale)
		if node:
			node.rotation_degrees = Vector3(0.0, rot_y, 0.0)
		return node
	_enable_shadows(node)
	if _is_land_tile(glb_name):
		_apply_land_tile_material(node)
	elif glb_name.contains("tree"):
		_apply_tree_material(node)
		_snap_prop_to_ground(node, pos)
	elif glb_name.contains("grass") or glb_name.contains("plant") or glb_name.contains("flower"):
		_snap_prop_to_ground(node, pos)
	if glb_name == "ground_riverTile.glb":
		for child in node.get_children():
			if child is MeshInstance3D:
				_Tint.apply_water_material(child as MeshInstance3D)
	if collision:
		_add_prop_collision(parent, pos, scale)
	if not _is_land_tile(glb_name):
		return _DestructibleFactory.attach_if_destructible(node, glb_name)
	return node


func _enable_shadows(node: Node) -> void:
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	for child in node.get_children():
		_enable_shadows(child)


func _add_prop_collision(parent: Node3D, pos: Vector3, scale: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = PROP_COLLISION_LAYER
	body.collision_mask = WORLD_COLLISION_MASK
	body.position = pos
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = maxf(scale.x, scale.z) * 0.35
	cyl.height = maxf(scale.y, 1.0) * 2.5
	shape.shape = cyl
	shape.position = Vector3(0.0, cyl.height * 0.5, 0.0)
	body.add_child(shape)
	parent.add_child(body)


func _queue_land_tiles() -> void:
	var half := int(ceil(island_radius / tile_step)) + 1
	for x in range(-half, half + 1):
		for z in range(-half, half + 1):
			var wx := float(x) * tile_step
			var wz := float(z) * tile_step
			if terrain_mode == "island":
				if Vector2(wx, wz).length() > island_radius - tile_step * 0.15:
					continue
			elif absf(wx) > island_radius or absf(wz) > island_radius:
				continue
			var yaw := randf_range(0.0, 360.0)
			var overlay_scale := Vector3(tile_scale, 1.0, tile_scale)
			_queue_mesh(_land, land_tile, Vector3(wx, 0.06, wz), yaw, overlay_scale)


func _queue_water_shore_strip() -> void:
	var inner := island_radius + tile_step * 0.5
	var outer := minf(water_extent, island_radius + tile_step * 8.0)
	var count := 48
	for i in count:
		var angle := TAU * float(i) / float(count)
		var mid := (inner + outer) * 0.5
		var pos := Vector3(cos(angle) * mid, -0.05, sin(angle) * mid)
		var yaw := randf_range(0.0, 360.0)
		_queue_mesh(
			_water,
			"ground_riverTile.glb",
			pos,
			yaw,
			Vector3(tile_scale, 1.0, tile_scale)
		)


func _queue_shore_rocks() -> void:
	var count := 28
	for i in count:
		var angle := TAU * float(i) / float(count)
		var edge := island_radius - tile_step * 0.25
		var pos := Vector3(cos(angle) * edge, 0.0, sin(angle) * edge)
		var rock: String = SHORE_ROCK_POOL[i % SHORE_ROCK_POOL.size()]
		var yaw := rad_to_deg(angle) + 90.0
		_queue_mesh(_props, rock, pos, yaw, Vector3.ONE * randf_range(1.2, 1.9))


func _queue_camp_fence() -> void:
	var edge := island_radius - 1.0
	var corners: Array[Vector3] = [
		Vector3(-edge, 0, -edge), Vector3(edge, 0, -edge),
		Vector3(edge, 0, edge), Vector3(-edge, 0, edge),
	]
	for i in corners.size():
		var a: Vector3 = corners[i]
		var b: Vector3 = corners[(i + 1) % corners.size()]
		var steps := int(a.distance_to(b) / 3.5)
		for s in steps + 1:
			var t := float(s) / float(max(steps, 1))
			var pos: Vector3 = a.lerp(b, t)
			_queue_mesh(_props, "fence_simple.glb", pos, 0.0, Vector3.ONE * 1.1)


func _queue_scatter_props() -> void:
	for i in scatter_trees:
		var pos := _random_land_point(island_radius * 0.78)
		if pos == Vector3.ZERO:
			continue
		var tree: String = _tree_pool[i % _tree_pool.size()]
		var scale := Vector3.ONE * randf_range(tree_scale_min, tree_scale_max)
		_queue_mesh(_props, tree, pos, randf_range(0.0, 360.0), scale, true)
	for i in scatter_rocks:
		var pos := _random_land_point(island_radius * 0.88)
		if pos == Vector3.ZERO:
			continue
		var rock: String = _rock_pool[i % _rock_pool.size()]
		_queue_mesh(_props, rock, pos, randf_range(0.0, 360.0), Vector3.ONE * randf_range(0.85, 1.45))
	for i in scatter_grass:
		var pos := _random_land_point(island_radius * 0.92)
		if pos == Vector3.ZERO:
			continue
		var grass: String = _grass_pool[i % _grass_pool.size()]
		_queue_mesh(
			_props,
			grass,
			pos,
			randf_range(0.0, 360.0),
			Vector3.ONE * randf_range(grass_clump_scale_min, grass_clump_scale_max)
		)
	for i in scatter_bushes:
		var pos := _random_land_point(island_radius * 0.85)
		if pos == Vector3.ZERO:
			continue
		var bush: String = _bush_pool[i % _bush_pool.size()]
		_queue_mesh(
			_props,
			bush,
			pos,
			randf_range(0.0, 360.0),
			Vector3.ONE * randf_range(0.85, 1.2)
		)


func _scatter_props_now() -> void:
	_queue_scatter_props()


func _build_region_landmarks() -> void:
	match region_id:
		"darkpine_forest":
			_build_trail(Vector3(0, 0, island_radius - 4.0), Vector3(0, 0, 4.0), 6)
			_add_prop_cluster(Vector3(-10, 0, -6), ["rock_largeA.glb", "rock_smallA.glb", "stone_smallB.glb"], 1.2)
			_add_prop_cluster(Vector3(11, 0, 8), ["tree_pineTallA.glb", "plant_bushDetailed.glb", "log_stack.glb"], 1.0)
			_add_mesh(_props, "rock_tallA.glb", Vector3(0, 0, -16), 0.0, Vector3.ONE * 1.8, true)
		"crystal_cave":
			for i in 6:
				var angle := TAU * float(i) / 6.0
				var pos := Vector3(cos(angle) * (island_radius - 3.0), 0, sin(angle) * (island_radius - 3.0))
				_add_mesh(_props, "cliff_block_stone.glb", pos, rad_to_deg(angle) + 90.0, Vector3.ONE * randf_range(1.3, 1.7))
		"hollow_grove_shrine":
			_add_mesh(_props, "statue_ring.glb", Vector3(0, 0, -14), 0.0, Vector3.ONE * 1.3)
			_add_mesh(_props, "statue_obelisk.glb", Vector3(-4, 0, -12), 20.0, Vector3.ONE * 1.2)
			for i in 5:
				var offset := Vector3(randf_range(-8, 8), 0, randf_range(-16, -8))
				_add_mesh(_props, "hanging_moss.glb", offset, randf_range(0, 360), Vector3.ONE * randf_range(0.9, 1.3))


func _build_trail(from: Vector3, to: Vector3, steps: int) -> void:
	var tile := "ground_path.glb" if FileAccess.file_exists(_Kenney.nature("ground_path.glb")) else land_tile
	for i in steps + 1:
		var t := float(i) / float(steps)
		var pos := from.lerp(to, t)
		pos.y = 0.05
		_add_mesh(_land, tile, pos, 0.0, Vector3(tile_scale * 0.95, 1.0, tile_scale * 0.95))


func _add_prop_cluster(center: Vector3, assets: Array, spread: float) -> void:
	for i in assets.size():
		var offset := Vector3(randf_range(-spread, spread), 0.0, randf_range(-spread, spread))
		var pos := center + offset
		if terrain_mode == "island" and Vector2(pos.x, pos.z).length() > island_radius - 2.5:
			continue
		var glb: String = assets[i]
		var scale := Vector3.ONE * randf_range(0.9, 1.35)
		if glb.contains("tree"):
			scale *= randf_range(tree_scale_min, tree_scale_max) * 0.35
		_add_mesh(_props, glb, pos, randf_range(0.0, 360.0), scale, glb.contains("tree") or glb.contains("rock_large"))


func _random_land_point(max_radius: float) -> Vector3:
	for _attempt in 32:
		var angle := randf() * TAU
		var dist := randf() * max_radius
		var pos := Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
		if terrain_mode == "camp":
			if absf(pos.x) < island_radius - 2.0 and absf(pos.z) < island_radius - 2.0:
				return pos
		elif Vector2(pos.x, pos.z).length() < island_radius - 2.0:
			return pos
	return Vector3.ZERO


func _build_navigation_mesh() -> void:
	var nav_mesh := NavigationMesh.new()
	nav_mesh.agent_height = 2.0
	nav_mesh.agent_radius = 0.5
	nav_mesh.cell_size = 1.0
	nav_mesh.cell_height = 0.25

	var verts: PackedVector3Array = []
	if terrain_mode == "camp":
		var r := island_radius - 2.0
		verts = PackedVector3Array([
			Vector3(-r, 0.5, -r), Vector3(r, 0.5, -r),
			Vector3(r, 0.5, r), Vector3(-r, 0.5, r),
		])
	else:
		var segments := 24
		var walk_radius := island_radius - 3.0
		for i in segments:
			var angle := TAU * float(i) / float(segments)
			verts.append(Vector3(cos(angle) * walk_radius, 0.5, sin(angle) * walk_radius))

	nav_mesh.vertices = verts
	var poly := PackedInt32Array()
	for i in verts.size():
		poly.append(i)
	nav_mesh.polygons = [poly]
	_nav_region.navigation_mesh = nav_mesh


func _apply_region_layout(layout: Dictionary) -> void:
	if layout.is_empty():
		return
	var kind: String = layout.get("kind", terrain_mode)
	if kind == "camp":
		terrain_mode = "camp"
	elif kind in ["island", "stub"]:
		terrain_mode = "island"
	if layout.has("radius"):
		island_radius = float(layout.radius)
	if layout.has("water_extent"):
		water_extent = float(layout.water_extent)
	if layout.has("land_tile"):
		land_tile = str(layout.land_tile)
	if layout.has("scatter_trees"):
		scatter_trees = int(layout.scatter_trees)
	if layout.has("scatter_rocks"):
		scatter_rocks = int(layout.scatter_rocks)
	if layout.has("scatter_grass"):
		scatter_grass = int(layout.scatter_grass)
	if layout.has("scatter_bushes"):
		scatter_bushes = int(layout.scatter_bushes)
	if layout.has("tree_pool"):
		_tree_pool = _to_string_array(layout.tree_pool)
	if layout.has("rock_pool"):
		_rock_pool = _to_string_array(layout.rock_pool)
	if layout.has("grass_pool"):
		_grass_pool = _to_string_array(layout.grass_pool)
	if layout.has("bush_pool"):
		_bush_pool = _to_string_array(layout.bush_pool)


func _to_string_array(value: Variant) -> Array[String]:
	var out: Array[String] = []
	if value is Array:
		for item in value:
			out.append(str(item))
	return out


func _is_land_tile(glb_name: String) -> bool:
	return glb_name == land_tile or glb_name.contains("ground_")


func _apply_land_tile_material(node: Node3D) -> void:
	var pos := node.global_position
	var dist_norm := Vector2(pos.x, pos.z).length() / maxf(island_radius, 1.0)
	var patch := sin(pos.x * 0.19) * cos(pos.z * 0.17)
	var grass := Color(0.20, 0.36, 0.18)
	var dirt := Color(0.30, 0.24, 0.16)
	var rock_tint := Color(0.24, 0.26, 0.22)
	var corruption := Color(0.14, 0.18, 0.12)
	var col := grass.lerp(dirt, clampf(patch * 0.35 + 0.15, 0.0, 0.55))
	col = col.lerp(rock_tint, clampf(absf(sin(pos.x * 0.41 + pos.z * 0.33)), 0.0, 0.22))
	col = col.lerp(corruption, clampf(dist_norm * 0.35, 0.0, 0.3))
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.94
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	for mi in _collect_mesh_instances(node):
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _apply_tree_material(node: Node3D) -> void:
	for mi in _collect_mesh_instances(node):
		var name_lower := mi.name.to_lower()
		var mat := StandardMaterial3D.new()
		mat.roughness = 0.9
		if name_lower.contains("leaf") or name_lower.contains("foliage"):
			mat.albedo_color = Color(0.18, 0.48, 0.22)
		elif name_lower.contains("wood") or name_lower.contains("bark") or name_lower.contains("trunk"):
			mat.albedo_color = Color(0.42, 0.28, 0.16)
		else:
			mat.albedo_color = Color(0.2, 0.45, 0.2)
		mi.material_override = mat


func _snap_prop_to_ground(node: Node3D, _pos: Vector3) -> void:
	var min_y := INF
	for mi in _collect_mesh_instances(node):
		if mi.mesh == null:
			continue
		var local_aabb := mi.mesh.get_aabb()
		var base_y := local_aabb.position.y * mi.scale.y + mi.position.y
		min_y = minf(min_y, base_y)
	if min_y == INF or absf(min_y) < 0.001:
		return
	node.position.y -= min_y * node.scale.y


func _collect_mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		out.append(node as MeshInstance3D)
	for child in node.get_children():
		out.append_array(_collect_mesh_instances(child))
	return out
