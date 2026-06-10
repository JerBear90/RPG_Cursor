class_name KenneyManifest
extends RefCounted
## Kenney GLB files referenced by gameplay scenes.

const _KenneyPaths = preload("res://scripts/utilities/kenney_paths.gd")

const REFERENCED_GLBS: PackedStringArray = [
	"ground_grass.glb", "ground_riverTile.glb", "platform_stone.glb",
	"rock_largeA.glb", "rock_largeB.glb", "rock_tallA.glb", "cliff_block_rock.glb",
	"rock_smallA.glb", "rock_smallB.glb", "stone_smallA.glb",
	"fence_simple.glb", "fence_planksDouble.glb",
	"tree_pineDefaultA.glb", "tree_pineDefaultB.glb", "tree_oak.glb",
	"tree_detailed.glb", "tree_pineRoundA.glb", "tree_pineTallA.glb",
	"cliff_block_stone.glb", "cliff_cave_stone.glb",
	"log_stack.glb", "log_stackLarge.glb",
	"campfire_logs.glb", "campfire_bricks.glb",
	"tent_smallClosed.glb", "tent_detailedClosed.glb",
	"statue_obelisk.glb", "statue_column.glb", "statue_head.glb", "statue_ring.glb",
	"plant_bush.glb", "mushroom_red.glb", "mushroom_tan.glb",
	"flower_yellowA.glb", "flower_redA.glb", "flower_purpleA.glb",
]


static func all_exist() -> bool:
	for name in REFERENCED_GLBS:
		if not ResourceLoader.exists(_KenneyPaths.nature(name)):
			return false
	return true


static func missing_files() -> PackedStringArray:
	var missing: PackedStringArray = []
	for name in REFERENCED_GLBS:
		if not ResourceLoader.exists(_KenneyPaths.nature(name)):
			missing.append(name)
	return missing
