extends Node3D
## Procedural overworld terrain using Kenney Nature Kit tiles.

const _Kenney = preload("res://scripts/utilities/kenney_paths.gd")

@export_enum("island", "camp") var terrain_mode: String = "island"
@export var island_radius: float = 28.0
@export var water_extent: float = 52.0
@export var tile_step: float = 8.0
@export var tile_scale: float = 8.0
@export var scatter_trees: int = 18
@export var scatter_rocks: int = 14

@onready var _land: Node3D = $Land
@onready var _water: Node3D = $Water
@onready var _props: Node3D = $Props
@onready var _nav_region: NavigationRegion3D = $NavigationRegion3D


func _ready() -> void:
	if terrain_mode == "camp":
		island_radius = minf(island_radius, 18.0)
		water_extent = 0.0
		scatter_trees = mini(scatter_trees, 8)
		scatter_rocks = mini(scatter_rocks, 6)
	_build_land()
	if terrain_mode == "island":
		_build_water()
		_build_shore()
	_scatter_props()
	if terrain_mode == "camp":
		_build_camp_fence()
	_build_navigation_mesh()


func _add_mesh(parent: Node3D, glb_name: String, pos: Vector3, rot_y: float = 0.0, scale: Vector3 = Vector3.ONE, collision: bool = false) -> Node3D:
	var path := _Kenney.nature(glb_name)
	if not ResourceLoader.exists(path):
		push_warning("IslandTerrain: missing %s" % path)
		return null
	var node := MeshLoader.instantiate(path, parent, rot_y, pos, scale)
	if node == null:
		return null
	if collision:
		_add_tile_collision(parent, pos, scale)
	return node


func _add_tile_collision(parent: Node3D, pos: Vector3, scale: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(scale.x, 1.0, scale.z)
	shape.shape = box
	shape.position = Vector3(0.0, -0.25, 0.0)
	body.add_child(shape)
	parent.add_child(body)


func _build_land() -> void:
	var extent := water_extent if terrain_mode == "island" else island_radius
	var half := int(ceil(extent / tile_step)) + 1
	for x in range(-half, half + 1):
		for z in range(-half, half + 1):
			var wx := float(x) * tile_step
			var wz := float(z) * tile_step
			if terrain_mode == "island":
				if Vector2(wx, wz).length() > island_radius:
					continue
			elif absf(wx) > island_radius or absf(wz) > island_radius:
				continue
			var yaw := randf_range(0.0, 360.0)
			_add_mesh(_land, "ground_grass.glb", Vector3(wx, 0.0, wz), yaw, Vector3.ONE * tile_scale, true)


func _build_water() -> void:
	var half := int(ceil(water_extent / tile_step))
	for x in range(-half, half + 1):
		for z in range(-half, half + 1):
			var wx := float(x) * tile_step
			var wz := float(z) * tile_step
			var dist := Vector2(wx, wz).length()
			if dist > water_extent or dist <= island_radius - tile_step * 0.5:
				continue
			var yaw := randf_range(0.0, 360.0)
			_add_mesh(_water, "ground_riverTile.glb", Vector3(wx, -0.15, wz), yaw, Vector3.ONE * tile_scale)


func _build_shore() -> void:
	var count := 24
	for i in count:
		var angle := TAU * float(i) / float(count)
		var edge := island_radius - tile_step * 0.35
		var pos := Vector3(cos(angle) * edge, 0.0, sin(angle) * edge)
		var rock_names := ["rock_largeA.glb", "rock_largeB.glb", "rock_tallA.glb", "cliff_block_rock.glb"]
		var rock := rock_names[i % rock_names.size()]
		var yaw := rad_to_deg(angle) + 90.0
		_add_mesh(_props, rock, pos, yaw, Vector3.ONE * randf_range(1.2, 1.8), true)


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
			var t := float(s) / float(steps)
			var pos := a.lerp(b, t)
			_add_mesh(_props, "fence_simple.glb", pos, 0.0, Vector3.ONE * 1.1)


func _scatter_props() -> void:
	var tree_names := [
		"tree_pineDefaultA.glb", "tree_pineDefaultB.glb", "tree_oak.glb",
		"tree_detailed.glb", "tree_pineRoundA.glb", "tree_pineTallA.glb",
	]
	for i in scatter_trees:
		var pos := _random_land_point(island_radius * 0.75)
		var tree := tree_names[i % tree_names.size()]
		_add_mesh(_props, tree, pos, randf_range(0.0, 360.0), Vector3.ONE * randf_range(0.9, 1.3))
	for i in scatter_rocks:
		var pos := _random_land_point(island_radius * 0.85)
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
