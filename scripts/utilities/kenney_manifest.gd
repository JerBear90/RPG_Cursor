class_name KenneyManifest
extends RefCounted
## Kenney GLB files referenced by gameplay scenes.

const _KenneyPaths = preload("res://scripts/utilities/kenney_paths.gd")

const REFERENCED_GLBS: PackedStringArray = [
	"ground_grass.glb", "ground_riverTile.glb", "platform_stone.glb",
	"rock_largeA.glb", "rock_largeB.glb", "rock_tallA.glb", "cliff_block_rock.glb",
	"rock_smallA.glb", "rock_smallB.glb", "stone_smallA.glb", "stone_smallB.glb", "stone_largeA.glb",
	"fence_simple.glb", "fence_planksDouble.glb",
	"tree_pineDefaultA.glb", "tree_pineDefaultB.glb", "tree_oak.glb",
	"tree_detailed.glb", "tree_pineRoundA.glb", "tree_pineTallA.glb",
	"tree_pineSmallA.glb", "tree_simple.glb", "tree_tall.glb",
	"tree_tall_dark.glb", "tree_simple_dark.glb",
	"cliff_block_stone.glb", "cliff_cave_stone.glb",
	"grass.glb", "grass_large.glb", "grass_leafs.glb",
	"log_stack.glb", "log_stackLarge.glb",
	"campfire_logs.glb", "campfire_bricks.glb",
	"tent_smallClosed.glb", "tent_detailedClosed.glb", "tent_smallOpen.glb", "tent_detailedOpen.glb",
	"fence_gate.glb", "fence_corner.glb", "fence_planks.glb", "fence_simpleLow.glb",
	"fence_simpleHigh.glb", "fence_simpleCenter.glb", "fence_bend.glb",
	"ground_pathStraight.glb", "ground_pathCross.glb", "ground_pathCorner.glb",
	"ground_pathRocks.glb", "ground_pathEndClosed.glb",
	"platform_grass.glb", "campfire_planks.glb",
	"statue_columnDamaged.glb",
	"statue_obelisk.glb", "statue_column.glb", "statue_head.glb", "statue_ring.glb",
	"plant_bush.glb", "plant_bushSmall.glb", "plant_bushDetailed.glb", "plant_bushLarge.glb",
	"mushroom_red.glb", "mushroom_tan.glb",
	"flower_yellowA.glb", "flower_redA.glb", "flower_purpleA.glb",
	"stump_old.glb", "stump_oldTall.glb", "hanging_moss.glb",
	"pot_large.glb", "pot_small.glb",
	"rock_smallFlatA.glb", "rock_smallFlatB.glb",
	"mushroom_redGroup.glb", "mushroom_redTall.glb", "mushroom_tanTall.glb",
	"campfire_stones.glb",
]


static func all_exist() -> bool:
	for name in REFERENCED_GLBS:
		if not FileAccess.file_exists(_KenneyPaths.nature(name)):
			return false
	return true


static func missing_files() -> PackedStringArray:
	var missing: PackedStringArray = []
	for name in REFERENCED_GLBS:
		if not FileAccess.file_exists(_KenneyPaths.nature(name)):
			missing.append(name)
	return missing
