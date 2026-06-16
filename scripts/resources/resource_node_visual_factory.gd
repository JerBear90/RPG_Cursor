class_name ResourceNodeVisualFactory
extends RefCounted
## Gather-node visuals — Kenney Nature Kit meshes with primitive fallback.

const _Catalog := preload("res://scripts/utilities/kenney_prop_catalog.gd")

const KIND_FALLEN_LOG := "fallen_log"
const KIND_TREE_STUMP := "tree_stump"
const KIND_HERB_BUSH := "herb_bush"
const KIND_BERRY_BUSH := "berry_bush"
const KIND_MUSHROOM := "mushroom_cluster"
const KIND_STONE_PILE := "stone_pile"
const KIND_ORE_VEIN := "ore_vein"
const KIND_CRYSTAL := "crystal_node"
const KIND_SCRAP_HEAP := "scrap_heap"
const KIND_BONE_PILE := "bone_pile"
const KIND_WATER_SPRING := "water_spring"
const KIND_CORRUPTED_ROOT := "corrupted_root"
const KIND_FIRE_RESIN := "fire_resin_growth"


static func infer_kind(resource_id: String) -> String:
	match resource_id:
		"wood", "ashwood", "frostwood", "driftwood", "blightwood", "rotwood":
			return KIND_FALLEN_LOG
		"herb_bundle", "bog_herb", "cactus_fiber", "kelp_fiber", "fiber":
			return KIND_HERB_BUSH
		"berries", "seeds":
			return KIND_BERRY_BUSH
		"sporecap", "mushrooms", "fungal_gland":
			return KIND_MUSHROOM
		"stone", "scorched_sand", "grave_dust":
			return KIND_STONE_PILE
		"cinder_ore", "rime_ore", "salt_iron", "umbral_ore", "root_iron", "swamp_iron", "blackvein_iron", "silver_ore":
			return KIND_ORE_VEIN
		"mire_crystal", "ember_crystal", "glacial_crystal", "viridian_crystal", "stormglass", "nightglass", "moonstone", "crystal_shard", "crystal_dust", "pyre_crystal", "desert_glass":
			return KIND_CRYSTAL
		"iron_scrap", "machine_scrap", "drowned_scrap", "wire", "bolts", "gears":
			return KIND_SCRAP_HEAP
		"bone", "ancient_bone", "leviathan_bone", "hide", "burned_hide", "frozen_hide", "shadow_hide":
			return KIND_BONE_PILE
		"dirty_water", "purified_water":
			return KIND_WATER_SPRING
		"corrupted_roots", "corrupted_fiber", "poison_gland":
			return KIND_CORRUPTED_ROOT
		"fire_resin", "pyre_dust", "purified_resin", "charcoal", "firewood":
			return KIND_FIRE_RESIN
		_:
			return KIND_STONE_PILE


static func gather_label(resource_id: String) -> String:
	return gather_prompt_label(resource_id)


static func gather_prompt_label(resource_id: String) -> String:
	match resource_id:
		"herb_bundle", "bog_herb", "fiber", "cactus_fiber", "kelp_fiber":
			return "Herbs"
		"berries", "seeds":
			return "Berries"
		"sporecap", "mushrooms", "fungal_gland":
			return "Mushrooms"
		"wood", "ashwood", "frostwood", "driftwood", "blightwood", "rotwood", "firewood":
			return "Wood"
		"stone", "scorched_sand", "grave_dust":
			return "Stone"
		"cinder_ore", "rime_ore", "salt_iron", "umbral_ore", "root_iron", "swamp_iron", "blackvein_iron", "silver_ore":
			return "Ore"
		"mire_crystal", "ember_crystal", "glacial_crystal", "viridian_crystal", "stormglass", "nightglass", "moonstone", "crystal_shard", "crystal_dust", "pyre_crystal", "desert_glass":
			return "Crystal Shards"
		"iron_scrap", "machine_scrap", "drowned_scrap", "wire", "bolts", "gears":
			return "Metal Scraps"
		"bone", "ancient_bone", "leviathan_bone":
			return "Bones"
		"dirty_water", "purified_water":
			return "Water"
		"corrupted_roots", "corrupted_fiber", "poison_gland":
			return "Corrupted Roots"
		"fire_resin", "pyre_dust", "purified_resin", "charcoal":
			return "Fire Resin"
		_:
			return ItemDatabase.get_display_name(resource_id)


static func build(parent: Node3D, kind: String) -> Node3D:
	var kenney := _build_kenney(parent, kind)
	if kenney != null:
		return kenney
	return _build_primitive(parent, kind)


static func _build_kenney(parent: Node3D, kind: String) -> Node3D:
	var spec: Dictionary = _Catalog.resource_kind_spec(kind)
	if spec.is_empty():
		return null
	var root := Node3D.new()
	root.name = "Visual"
	parent.add_child(root)
	var visual := MeshLoader.instantiate(
		spec.path,
		root,
		float(spec.get("yaw", 0.0)),
		spec.get("offset", Vector3.ZERO),
		spec.get("scale", Vector3.ONE)
	)
	if visual == null:
		root.queue_free()
		return null
	if spec.get("emissive", false):
		_apply_emissive_tint(visual, spec.get("tint", Color.WHITE))
	return root


static func _apply_emissive_tint(node: Node, color: Color) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		var mat := StandardMaterial3D.new()
		if mi.material_override is StandardMaterial3D:
			mat = (mi.material_override as StandardMaterial3D).duplicate()
		mat.emission_enabled = true
		mat.emission = color * 0.35
		mat.albedo_color = color.darkened(0.25)
		mi.material_override = mat
	for child in node.get_children():
		_apply_emissive_tint(child, color)


static func _build_primitive(parent: Node3D, kind: String) -> Node3D:
	var root := Node3D.new()
	root.name = "Visual"
	parent.add_child(root)
	match kind:
		KIND_FALLEN_LOG:
			_add_cylinder(root, Vector3(0.35, 0.35, 1.4), Vector3(0.0, 0.25, 0.0), Vector3(0, 0, deg_to_rad(90)), Color(0.42, 0.28, 0.14))
			_add_box(root, Vector3(0.12, 0.12, 0.5), Vector3(0.2, 0.15, 0.35), Vector3.ZERO, Color(0.36, 0.24, 0.12))
		KIND_TREE_STUMP:
			_add_cylinder(root, Vector3(0.55, 0.55, 0.35), Vector3(0.0, 0.18, 0.0), Vector3.ZERO, Color(0.34, 0.22, 0.12))
			_add_cylinder(root, Vector3(0.48, 0.48, 0.06), Vector3(0.0, 0.36, 0.0), Vector3.ZERO, Color(0.58, 0.46, 0.32))
		KIND_HERB_BUSH:
			for i in 3:
				var ang := float(i) * TAU / 3.0
				_add_sphere(root, 0.22, Vector3(cos(ang) * 0.18, 0.22, sin(ang) * 0.18), Color(0.22, 0.62, 0.28))
			_add_sphere(root, 0.18, Vector3(0.0, 0.28, 0.0), Color(0.18, 0.52, 0.24))
		KIND_BERRY_BUSH:
			for i in 3:
				var ang := float(i) * TAU / 3.0
				_add_sphere(root, 0.2, Vector3(cos(ang) * 0.2, 0.2, sin(ang) * 0.2), Color(0.2, 0.55, 0.22))
			_add_sphere(root, 0.07, Vector3(0.12, 0.18, 0.08), Color(0.72, 0.18, 0.28))
			_add_sphere(root, 0.07, Vector3(-0.1, 0.16, -0.06), Color(0.55, 0.15, 0.62))
		KIND_MUSHROOM:
			_add_cylinder(root, Vector3(0.08, 0.08, 0.18), Vector3(-0.12, 0.09, 0.0), Vector3.ZERO, Color(0.72, 0.66, 0.52))
			_add_sphere(root, 0.14, Vector3(-0.12, 0.22, 0.0), Color(0.78, 0.42, 0.28))
			_add_cylinder(root, Vector3(0.07, 0.07, 0.14), Vector3(0.1, 0.07, 0.08), Vector3.ZERO, Color(0.68, 0.62, 0.48))
			_add_sphere(root, 0.11, Vector3(0.1, 0.18, 0.08), Color(0.62, 0.38, 0.22))
		KIND_STONE_PILE:
			_add_box(root, Vector3(0.45, 0.28, 0.38), Vector3(-0.12, 0.14, 0.0), Vector3(0, 0.2, 0), Color(0.52, 0.54, 0.56))
			_add_box(root, Vector3(0.32, 0.22, 0.28), Vector3(0.14, 0.11, 0.1), Vector3(0, -0.1, 0.3), Color(0.48, 0.5, 0.52))
			_add_box(root, Vector3(0.28, 0.18, 0.24), Vector3(0.0, 0.2, -0.12), Vector3(0.2, 0, 0), Color(0.56, 0.58, 0.6))
		KIND_ORE_VEIN:
			_add_box(root, Vector3(0.5, 0.32, 0.42), Vector3(0.0, 0.16, 0.0), Vector3.ZERO, Color(0.48, 0.5, 0.54))
			_add_box(root, Vector3(0.22, 0.14, 0.18), Vector3(0.08, 0.22, 0.06), Vector3.ZERO, Color(0.28, 0.34, 0.48), 0.35)
		KIND_CRYSTAL:
			for i in 3:
				var ang := float(i) * TAU / 3.0
				_add_box(root, Vector3(0.12, 0.42, 0.12), Vector3(cos(ang) * 0.12, 0.22, sin(ang) * 0.12), Vector3(0, ang, 0.2), Color(0.42, 0.72, 0.98), 0.0, true)
		KIND_SCRAP_HEAP:
			_add_box(root, Vector3(0.38, 0.12, 0.28), Vector3(-0.08, 0.06, 0.0), Vector3(0, 0.3, 0), Color(0.32, 0.28, 0.26))
			_add_cylinder(root, Vector3(0.14, 0.14, 0.22), Vector3(0.12, 0.11, 0.08), Vector3(0, 0, deg_to_rad(75)), Color(0.38, 0.3, 0.24))
			_add_box(root, Vector3(0.18, 0.08, 0.24), Vector3(0.0, 0.08, -0.1), Vector3(0.1, 0, 0.4), Color(0.42, 0.34, 0.28))
		KIND_BONE_PILE:
			_add_cylinder(root, Vector3(0.08, 0.08, 0.32), Vector3(-0.1, 0.08, 0.05), Vector3(0, 0, deg_to_rad(35)), Color(0.86, 0.82, 0.72))
			_add_cylinder(root, Vector3(0.07, 0.07, 0.28), Vector3(0.08, 0.07, -0.04), Vector3(0, 0, deg_to_rad(-25)), Color(0.82, 0.78, 0.68))
			_add_sphere(root, 0.12, Vector3(0.0, 0.1, 0.0), Color(0.88, 0.84, 0.74))
		KIND_WATER_SPRING:
			_add_cylinder(root, Vector3(0.55, 0.55, 0.12), Vector3(0.0, 0.06, 0.0), Vector3.ZERO, Color(0.45, 0.48, 0.5))
			_add_box(root, Vector3(0.42, 0.02, 0.42), Vector3(0.0, 0.12, 0.0), Vector3.ZERO, Color(0.18, 0.42, 0.82, 0.75), 0.0, false, true)
		KIND_CORRUPTED_ROOT:
			_add_cylinder(root, Vector3(0.1, 0.1, 0.55), Vector3(-0.08, 0.18, 0.0), Vector3(0.2, 0, 0.5), Color(0.18, 0.14, 0.12))
			_add_cylinder(root, Vector3(0.08, 0.08, 0.42), Vector3(0.1, 0.14, 0.06), Vector3(-0.3, 0.8, 0.1), Color(0.22, 0.16, 0.14))
			_add_sphere(root, 0.1, Vector3(0.0, 0.24, 0.0), Color(0.32, 0.72, 0.22))
		KIND_FIRE_RESIN:
			_add_cylinder(root, Vector3(0.14, 0.14, 0.28), Vector3(0.0, 0.14, 0.0), Vector3.ZERO, Color(0.22, 0.16, 0.12))
			_add_sphere(root, 0.12, Vector3(0.1, 0.22, 0.05), Color(0.92, 0.48, 0.12), 0.0, true)
			_add_sphere(root, 0.08, Vector3(-0.08, 0.18, -0.04), Color(0.98, 0.62, 0.18), 0.0, true)
		_:
			_add_sphere(root, 0.35, Vector3(0.0, 0.35, 0.0), Color(0.55, 0.55, 0.55))
	return root


static func _add_sphere(parent: Node3D, radius: float, pos: Vector3, color: Color, metallic: float = 0.0, emissive: bool = false) -> void:
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	mesh.mesh = sphere
	mesh.position = pos
	mesh.material_override = _mat(color, metallic, emissive)
	parent.add_child(mesh)


static func _add_cylinder(parent: Node3D, size: Vector3, pos: Vector3, rot: Vector3, color: Color, metallic: float = 0.0) -> void:
	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = size.x
	cyl.bottom_radius = size.x
	cyl.height = size.z
	mesh.mesh = cyl
	mesh.position = pos
	mesh.rotation = rot
	mesh.material_override = _mat(color, metallic)
	parent.add_child(mesh)


static func _add_box(parent: Node3D, size: Vector3, pos: Vector3, rot: Vector3, color: Color, metallic: float = 0.0, emissive: bool = false, transparent: bool = false) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = pos
	mesh.rotation = rot
	mesh.material_override = _mat(color, metallic, emissive, transparent)
	parent.add_child(mesh)


static func _mat(color: Color, metallic: float = 0.0, emissive: bool = false, transparent: bool = false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = 0.82 if metallic < 0.2 else 0.45
	if emissive:
		mat.emission_enabled = true
		mat.emission = color * 0.45
	if transparent:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat
