extends Node3D
## Procedural overworld terrain using Kenney Nature Kit tiles.

const _Kenney = preload("res://scripts/utilities/kenney_paths.gd")
const _Tint = preload("res://scripts/utilities/kenney_material_tint.gd")

@export var region_id: String = ""
@export_enum("island", "camp") var terrain_mode: String = "island"
@export var island_radius: float = 28.0
@export var water_extent: float = 52.0
@export var tile_step: float = 4.0
@export var tile_scale: float = 2.0
@export var scatter_trees: int = 18
@export var scatter_rocks: int = 14
@export var land_tile: String = "ground_grass.glb"
@export var apply_dark_tint: bool = true

@onready var _land: Node3D = $Land
@onready var _water: Node3D = $Water
@onready var _props: Node3D = $Props
@onready var _nav_region: NavigationRegion3D = $NavigationRegion3D


func _ready() -> void:
	if region_id != "":
		_apply_region_layout(MapManager.get_region_layout(region_id))
	if terrain_mode == "camp":
		island_radius = minf(island_radius, 18.0)
		water_extent = 0.0
		scatter_trees = mini(scatter_trees, 8)
		scatter_rocks = mini(scatter_rocks, 6)
	_setup_world_environment()
	_build_ground_base()
	call_deferred("_build_details")


func _build_details() -> void:
	_build_land_tiles()
	if terrain_mode == "island" and water_extent > 0.0:
		_build_water_base()
		_build_water_tiles()
		_build_shore()
	_scatter_props()
	if terrain_mode == "camp":
		_build_camp_fence()
	_build_navigation_mesh()


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
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	we.environment = env
	add_child(we)


func _build_ground_base() -> void:
	if get_parent().get_node_or_null("GroundIsland") != null:
		return
	var body := StaticBody3D.new()
	body.name = "GroundCollider"
	body.collision_layer = 1
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
		cyl_shape.height = 0.6
		col.shape = cyl_shape
		col.position = Vector3(0.0, -0.3, 0.0)
	body.add_child(col)
	_land.add_child(body)

	var mi := MeshInstance3D.new()
	mi.name = "GroundBase"
	var mat := StandardMaterial3D.new()
	if land_tile.contains("platform") or land_tile.contains("stone"):
		mat.albedo_color = Color(0.28, 0.27, 0.26)
		mat.roughness = 0.9
	else:
		mat.albedo_color = Color(0.16, 0.26, 0.12)
		mat.roughness = 0.95
	if terrain_mode == "camp":
		var box := BoxMesh.new()
		var size := island_radius * 2.0
		box.size = Vector3(size, 0.6, size)
		mi.mesh = box
		mi.position = Vector3(0.0, -0.3, 0.0)
	else:
		var cyl := CylinderMesh.new()
		cyl.top_radius = island_radius
		cyl.bottom_radius = island_radius
		cyl.height = 0.6
		mi.mesh = cyl
		mi.position = Vector3(0.0, -0.3, 0.0)
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_land.add_child(mi)


func _build_water_base() -> void:
	var mi := MeshInstance3D.new()
	mi.name = "WaterBase"
	var cyl := CylinderMesh.new()
	cyl.top_radius = water_extent
	cyl.bottom_radius = water_extent
	cyl.height = 0.25
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.18, 0.32, 0.92)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.08
	mat.metallic = 0.02
	mi.mesh = cyl
	mi.material_override = mat
	mi.position = Vector3(0.0, -0.42, 0.0)
	_water.add_child(mi)


func _add_mesh(parent: Node3D, glb_name: String, pos: Vector3, rot_y: float = 0.0, scale: Vector3 = Vector3.ONE, collision: bool = false) -> Node3D:
	var path := _Kenney.nature(glb_name)
	if not ResourceLoader.exists(path):
		push_warning("IslandTerrain: missing %s" % path)
		return null
	var node := MeshLoader.instantiate(path, parent, rot_y, pos, scale)
	if node == null:
		push_warning("IslandTerrain: failed to instantiate %s" % path)
		return null
	if glb_name == "ground_riverTile.glb":
		for child in node.get_children():
			if child is MeshInstance3D:
				_Tint.apply_water_material(child as MeshInstance3D)
	if collision:
		_add_tile_collision(parent, pos, scale)
	return node


func _add_tile_collision(parent: Node3D, pos: Vector3, scale: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(maxf(scale.x, 1.0), 1.0, maxf(scale.z, 1.0))
	shape.shape = box
	shape.position = Vector3(0.0, -0.25, 0.0)
	body.add_child(shape)
	parent.add_child(body)


func _build_land_tiles() -> void:
	var half := int(ceil(island_radius / tile_step)) + 1
	for x in range(-half, half + 1):
		for z in range(-half, half + 1):
			var wx := float(x) * tile_step
			var wz := float(z) * tile_step
			if terrain_mode == "island":
				if Vector2(wx, wz).length() > island_radius - tile_step * 0.25:
					continue
			elif absf(wx) > island_radius or absf(wz) > island_radius:
				continue
			var yaw := randf_range(0.0, 360.0)
			var overlay_scale := Vector3(tile_scale, 1.0, tile_scale)
			_add_mesh(_land, land_tile, Vector3(wx, 0.02, wz), yaw, overlay_scale)


func _build_water_tiles() -> void:
	var half := int(ceil(water_extent / tile_step))
	for x in range(-half, half + 1):
		for z in range(-half, half + 1):
			var wx := float(x) * tile_step
			var wz := float(z) * tile_step
			var dist := Vector2(wx, wz).length()
			if dist > water_extent or dist <= island_radius - tile_step * 0.5:
				continue
			var yaw := randf_range(0.0, 360.0)
			_add_mesh(_water, "ground_riverTile.glb", Vector3(wx, -0.05, wz), yaw, Vector3(tile_scale, 1.0, tile_scale))


func _build_shore() -> void:
	var count := 24
	for i in count:
		var angle := TAU * float(i) / float(count)
		var edge := island_radius - tile_step * 0.35
		var pos := Vector3(cos(angle) * edge, 0.0, sin(angle) * edge)
		var rock_names := ["rock_largeA.glb", "rock_largeB.glb", "rock_tallA.glb", "cliff_block_rock.glb"]
		var rock := rock_names[i % rock_names.size()]
		var yaw := rad_to_deg(angle) + 90.0
		_add_mesh(_props, rock, pos, yaw, Vector3.ONE * randf_range(1.2, 1.8))


func _build_camp_fence() -> void:
	var edge := island_radius - 1.0
	var corners := [
		Vector3(-edge, 0, -edge), Vector3(edge, 0, -edge),
		Vector3(edge, 0, edge), Vector3(-edge, 0, edge),
	]
	for i in corners.size():
		var a := corners[i]
		var b := corners[(i + 1) % corners.size()]
		var steps := int(a.distance_to(b) / 4.0)
		for s in steps + 1:
			var t := float(s) / float(max(steps, 1))
			var pos := a.lerp(b, t)
			_add_mesh(_props, "fence_simple.glb", pos, 0.0, Vector3.ONE * 1.1)


func _scatter_props() -> void:
	var tree_names := [
		"tree_pineDefaultA.glb", "tree_pineDefaultB.glb", "tree_oak.glb",
		"tree_detailed.glb", "tree_pineRoundA.glb", "tree_pineTallA.glb",
	]
	for i in scatter_trees:
		var pos := _random_land_point(island_radius * 0.75)
		if pos == Vector3.ZERO:
			continue
		var tree := tree_names[i % tree_names.size()]
		_add_mesh(_props, tree, pos, randf_range(0.0, 360.0), Vector3.ONE * randf_range(0.9, 1.3))
	for i in scatter_rocks:
		var pos := _random_land_point(island_radius * 0.85)
		if pos == Vector3.ZERO:
			continue
		var rock := ["rock_smallA.glb", "rock_smallB.glb", "stone_smallA.glb"][i % 3]
		_add_mesh(_props, rock, pos, randf_range(0.0, 360.0), Vector3.ONE * randf_range(0.8, 1.4))


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
