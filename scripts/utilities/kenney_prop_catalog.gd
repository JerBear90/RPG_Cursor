class_name KenneyPropCatalog
extends RefCounted
## Maps gameplay visual kinds to Kenney Nature Kit meshes (CC0).

const NATURE_GLB_DIR := "res://art/kenney/nature_kit/Models/GLTF format/"


static func nature_glb(file_name: String) -> String:
	if not file_name.ends_with(".glb"):
		file_name += ".glb"
	return NATURE_GLB_DIR + file_name


## Returns mesh spec for runtime ResourceNode visuals: path, scale, offset, yaw, emissive, tint.
static func resource_kind_spec(kind: String) -> Dictionary:
	match kind:
		"fallen_log":
			return _spec("log_stack.glb", Vector3(0.85, 0.85, 0.85), Vector3(0.0, 0.0, 0.0))
		"tree_stump":
			return _spec("stump_old.glb", Vector3(0.9, 0.9, 0.9), Vector3(0.0, 0.0, 0.0))
		"herb_bush":
			return _spec("plant_bushDetailed.glb", Vector3(0.95, 0.95, 0.95), Vector3(0.0, 0.0, 0.0))
		"berry_bush":
			return _spec("plant_bushLarge.glb", Vector3(0.9, 0.9, 0.9), Vector3(0.0, 0.0, 0.0))
		"mushroom_cluster":
			return _spec("mushroom_redGroup.glb", Vector3(0.85, 0.85, 0.85), Vector3(0.0, 0.0, 0.0))
		"stone_pile":
			return _spec("rock_smallFlatA.glb", Vector3(1.0, 1.0, 1.0), Vector3(0.0, 0.0, 0.0))
		"ore_vein":
			return _spec("rock_largeA.glb", Vector3(0.75, 0.75, 0.75), Vector3(0.0, 0.0, 0.0))
		"crystal_node":
			return _spec("statue_ring.glb", Vector3(0.55, 0.55, 0.55), Vector3(0.0, 0.0, 0.0), 0.0, true, Color(0.42, 0.72, 0.98))
		"scrap_heap":
			return _spec("log_stackLarge.glb", Vector3(0.9, 0.9, 0.9), Vector3(0.0, 0.0, 0.0))
		"bone_pile":
			return _spec("statue_head.glb", Vector3(0.55, 0.55, 0.55), Vector3(0.0, 0.05, 0.0))
		"water_spring":
			return _spec("pot_large.glb", Vector3(1.0, 1.0, 1.0), Vector3(0.0, 0.0, 0.0))
		"corrupted_root":
			return _spec("mushroom_tanTall.glb", Vector3(0.8, 0.8, 0.8), Vector3(0.0, 0.0, 0.0), 0.0, true, Color(0.32, 0.72, 0.22))
		"fire_resin_growth":
			return _spec("mushroom_redTall.glb", Vector3(0.75, 0.75, 0.75), Vector3(0.0, 0.0, 0.0), 0.0, true, Color(0.92, 0.48, 0.12))
		_:
			return {}


static func prop_wrapper_path(name: String) -> String:
	return "res://assets/third_party/kenney/scenes/%s" % name


static func _spec(
	file: String,
	scale: Vector3,
	offset: Vector3,
	yaw: float = 0.0,
	emissive: bool = false,
	tint: Color = Color.WHITE
) -> Dictionary:
	return {
		"path": nature_glb(file),
		"scale": scale,
		"offset": offset,
		"yaw": yaw,
		"emissive": emissive,
		"tint": tint,
	}
