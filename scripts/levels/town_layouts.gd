class_name TownLayouts
extends RefCounted
## Kenney Nature Kit prop layouts for towns, camps, and outposts.

const _P := "m"
const _POS := "p"
const _YAW := "y"
const _SCALE := "s"
const _COLLIDE := "c"

const TENT_LARGE := Vector3(2.05, 2.05, 2.05)
const TENT_SMALL := Vector3(1.75, 1.75, 1.75)
const CAMPFIRE_SCALE := Vector3(1.25, 1.25, 1.25)


static func get_layout(region_id: String) -> Dictionary:
	match region_id:
		"hearthhold_camp":
			return _hearthhold()
		"darkpine_forest":
			return _darkpine_outpost()
		"bandit_camp":
			return _bandit_camp()
		"ruined_watchtower":
			return _ruined_settlement()
		_:
			return {}


static func _prop(mesh: String, pos: Vector3, yaw: float = 0.0, scale: Vector3 = Vector3.ONE, collision: bool = false) -> Dictionary:
	return {_P: mesh, _POS: pos, _YAW: yaw, _SCALE: scale, _COLLIDE: collision}


static func _path_strip(props: Array, mesh: String, origin: Vector3, axis: String, count: int, spacing: float, yaw: float = 0.0) -> void:
	for i in count:
		var offset := float(i) * spacing
		var pos := origin
		if axis == "z":
			pos.z += offset
		else:
			pos.x += offset
		props.append(_prop(mesh, pos, yaw, Vector3(1.05, 1.0, 1.05)))


static func _fence_line(props: Array, mesh: String, from: Vector3, to: Vector3, spacing: float, yaw: float = 0.0) -> void:
	var steps := maxi(1, int(from.distance_to(to) / spacing))
	for i in steps + 1:
		var t := float(i) / float(steps)
		props.append(_prop(mesh, from.lerp(to, t), yaw))


static func _hearthhold() -> Dictionary:
	var props: Array = []
	# Town square — stone plaza + central fire
	props.append(_prop("platform_stone.glb", Vector3(0, 0.02, 0), 0.0, Vector3(3.2, 1.0, 3.2)))
	props.append(_prop("campfire_bricks.glb", Vector3(0, 0, 0), 0.0, Vector3(1.15, 1.15, 1.15)))
	props.append(_prop("log_stack.glb", Vector3(-2.2, 0, 1.4), 35.0))
	props.append(_prop("log_stack.glb", Vector3(2.2, 0, 1.4), -35.0))
	# Main streets
	_path_strip(props, "ground_pathStraight.glb", Vector3(0, 0.01, -13), "z", 14, 2.0, 0.0)
	_path_strip(props, "ground_pathStraight.glb", Vector3(-13, 0.01, 0), "x", 14, 2.0, 90.0)
	props.append(_prop("ground_pathCross.glb", Vector3(0, 0.01, 0), 0.0, Vector3(1.1, 1.0, 1.1)))
	# North gate
	props.append(_prop("fence_gate.glb", Vector3(0, 0, -14.5), 0.0, Vector3(1.2, 1.2, 1.2), true))
	_fence_line(props, "fence_planksDouble.glb", Vector3(-14, 0, -14.5), Vector3(14, 0, -14.5), 3.2, 0.0)
	# East market row — stalls + open shop tents
	for i in 4:
		var z := -4.0 + float(i) * 2.8
		props.append(_prop("fence_planksDouble.glb", Vector3(11, 0, z), -90.0, Vector3(1.1, 1.0, 1.0), true))
		props.append(_prop("log_stack.glb", Vector3(12.2, 0, z + 0.6), 0.0, Vector3(0.85, 0.85, 0.85)))
	if true:
		props.append(_prop("tent_detailedOpen.glb", Vector3(10.5, 0, 2), -90.0, TENT_LARGE, true))
		props.append(_prop("tent_detailedOpen.glb", Vector3(10.5, 0, -2), -90.0, TENT_LARGE, true))
		props.append(_prop("tent_smallOpen.glb", Vector3(9.5, 0, 6), -90.0, TENT_SMALL, true))
	# West housing — closed tents + yards
	var house_spots := [Vector3(-10, 0, -5), Vector3(-12, 0, -1), Vector3(-10, 0, 3), Vector3(-12, 0, 7)]
	for i in house_spots.size():
		var pos: Vector3 = house_spots[i]
		var mesh := "tent_detailedClosed.glb" if i % 2 == 0 else "tent_smallClosed.glb"
		props.append(_prop(mesh, pos, 90.0, TENT_LARGE if i % 2 == 0 else TENT_SMALL, true))
		props.append(_prop("fence_simpleLow.glb", Vector3(pos.x + 1.8, 0, pos.z), 90.0))
	# Chapel (north-west)
	props.append(_prop("statue_obelisk.glb", Vector3(-4, 0, -11), 15.0, Vector3(1.25, 1.25, 1.25), true))
	props.append(_prop("statue_ring.glb", Vector3(-2, 0, -10), -20.0, Vector3(1.1, 1.1, 1.1)))
	props.append(_prop("statue_column.glb", Vector3(-6, 0, -9), 40.0, Vector3(1.15, 1.15, 1.15), true))
	# Tavern (south-east)
	props.append(_prop("tent_detailedOpen.glb", Vector3(7, 0, 9), 180.0, TENT_LARGE, true))
	props.append(_prop("campfire_planks.glb", Vector3(5.5, 0, 10.5), 0.0, CAMPFIRE_SCALE))
	props.append(_prop("log_stackLarge.glb", Vector3(8.5, 0, 10), -30.0))
	props.append(_prop("log_stack.glb", Vector3(6, 0, 11.5), 60.0))
	# Workshop props near stations
	props.append(_prop("log_stackLarge.glb", Vector3(-8, 0, -3), 70.0, Vector3(1.0, 1.0, 1.0), true))
	props.append(_prop("campfire_bricks.glb", Vector3(8, 0, -3), 0.0, Vector3(0.95, 0.95, 0.95)))
	props.append(_prop("fence_planks.glb", Vector3(-8, 0, 1), 0.0))
	# Storage yard
	props.append(_prop("log_stackLarge.glb", Vector3(-7, 0, 7), 10.0))
	props.append(_prop("log_stack.glb", Vector3(-5.5, 0, 8), -15.0))
	props.append(_prop("fence_corner.glb", Vector3(-9, 0, 9), 0.0, Vector3(1.1, 1.1, 1.1)))
	# Perimeter fence segments
	_fence_line(props, "fence_simple.glb", Vector3(-14, 0, 14), Vector3(-14, 0, -14), 3.5, 90.0)
	_fence_line(props, "fence_simple.glb", Vector3(14, 0, -14), Vector3(14, 0, 14), 3.5, -90.0)
	_fence_line(props, "fence_simple.glb", Vector3(-14, 0, 14), Vector3(14, 0, 14), 3.5, 180.0)
	# Decorative trees at corners
	props.append(_prop("tree_pineSmallA.glb", Vector3(-13, 0, 12), 0.0, Vector3(1.0, 1.0, 1.0), true))
	props.append(_prop("tree_pineSmallA.glb", Vector3(13, 0, 12), 0.0, Vector3(0.95, 0.95, 0.95), true))
	props.append(_prop("plant_bushDetailed.glb", Vector3(2, 0, -6), 0.0))
	props.append(_prop("flower_yellowA.glb", Vector3(-2, 0, 5), 0.0))
	return {"props": props}


static func _darkpine_outpost() -> Dictionary:
	var props: Array = []
	# Traveler's rest near waystone / spawn road
	_path_strip(props, "ground_pathStraight.glb", Vector3(-5, 0.01, 0), "z", 8, 2.0, 0.0)
	props.append(_prop("ground_pathCorner.glb", Vector3(-5, 0.01, 0), 0.0, Vector3(1.05, 1.0, 1.05)))
	_path_strip(props, "ground_pathStraight.glb", Vector3(-5, 0.01, 0), "x", 6, 2.0, 90.0)
	# Merchant row tents
	props.append(_prop("tent_detailedOpen.glb", Vector3(-7, 0, 8), 180.0, TENT_LARGE, true))
	props.append(_prop("tent_smallOpen.glb", Vector3(-2, 0, 9), 200.0, TENT_SMALL, true))
	props.append(_prop("fence_planksDouble.glb", Vector3(-4.5, 0, 7), 0.0, Vector3(1.0, 1.0, 1.0), true))
	props.append(_prop("log_stack.glb", Vector3(-3, 0, 7.5), -20.0))
	# Scout medic tent
	props.append(_prop("tent_detailedClosed.glb", Vector3(4, 0, 7), 190.0, TENT_LARGE, true))
	props.append(_prop("plant_bush.glb", Vector3(5, 0, 6.5), 0.0))
	props.append(_prop("flower_redA.glb", Vector3(3.5, 0, 8), 0.0))
	# Camp cluster (south)
	props.append(_prop("campfire_logs.glb", Vector3(5, 0, -8), 0.0, CAMPFIRE_SCALE))
	props.append(_prop("tent_smallClosed.glb", Vector3(7, 0, -9), -40.0, TENT_SMALL, true))
	props.append(_prop("tent_detailedClosed.glb", Vector3(3, 0, -10), 25.0, TENT_LARGE, true))
	props.append(_prop("log_stack.glb", Vector3(6, 0, -7), 15.0))
	props.append(_prop("fence_simple.glb", Vector3(4, 0, -6.5), 70.0))
	# Waystone plaza
	props.append(_prop("platform_grass.glb", Vector3(-5, 0.02, 11), 0.0, Vector3(2.0, 1.0, 2.0)))
	props.append(_prop("statue_columnDamaged.glb", Vector3(-7, 0, 11), 30.0, Vector3(1.0, 1.0, 1.0), true))
	props.append(_prop("statue_columnDamaged.glb", Vector3(-3, 0, 11), -25.0, Vector3(0.9, 0.9, 0.9), true))
	return {"props": props}


static func _bandit_camp() -> Dictionary:
	var props: Array = []
	# Outer palisade
	_fence_line(props, "fence_simpleHigh.glb", Vector3(-12, 0, -12), Vector3(12, 0, -12), 3.0, 0.0)
	_fence_line(props, "fence_simpleHigh.glb", Vector3(12, 0, -12), Vector3(12, 0, 12), 3.0, 90.0)
	_fence_line(props, "fence_simpleHigh.glb", Vector3(12, 0, 12), Vector3(-12, 0, 12), 3.0, 180.0)
	_fence_line(props, "fence_simpleHigh.glb", Vector3(-12, 0, 12), Vector3(-12, 0, -12), 3.0, 270.0)
	props.append(_prop("fence_gate.glb", Vector3(0, 0, -12), 0.0, Vector3(1.15, 1.15, 1.15), true))
	# Command tent + lieutenant tent
	props.append(_prop("tent_detailedClosed.glb", Vector3(-9, 0, -8), 25.0, TENT_LARGE, true))
	props.append(_prop("tent_detailedClosed.glb", Vector3(8, 0, -10), -35.0, TENT_LARGE, true))
	props.append(_prop("tent_smallClosed.glb", Vector3(6, 0, -5), -10.0, TENT_SMALL, true))
	props.append(_prop("tent_smallClosed.glb", Vector3(-6, 0, -4), 20.0, TENT_SMALL, true))
	# War camp center
	props.append(_prop("campfire_logs.glb", Vector3(2, 0, -6), 0.0, CAMPFIRE_SCALE))
	props.append(_prop("log_stackLarge.glb", Vector3(-7, 0, -5), 70.0))
	props.append(_prop("log_stack.glb", Vector3(5, 0, -4), 15.0, Vector3(1.1, 1.1, 1.1)))
	props.append(_prop("rock_smallA.glb", Vector3(5, 0, -4), 15.0, Vector3(1.3, 1.3, 1.3), true))
	# Loot / supply corner
	props.append(_prop("tent_smallOpen.glb", Vector3(9, 0, 4), -90.0, TENT_SMALL, true))
	props.append(_prop("log_stack.glb", Vector3(8, 0, 5), 0.0))
	props.append(_prop("fence_planks.glb", Vector3(10, 0, 3), -90.0))
	# Guard posts
	props.append(_prop("fence_simpleCenter.glb", Vector3(-10, 0, 8), 45.0, Vector3(1.1, 1.1, 1.1), true))
	props.append(_prop("fence_simpleCenter.glb", Vector3(10, 0, 8), -45.0, Vector3(1.1, 1.1, 1.1), true))
	return {"props": props}


static func _ruined_settlement() -> Dictionary:
	var props: Array = []
	# Crumbled watchtower foundation
	props.append(_prop("platform_stone.glb", Vector3(0, 0.02, -12), 0.0, Vector3(2.5, 1.0, 2.5)))
	props.append(_prop("statue_column.glb", Vector3(0, 0, -12), 0.0, Vector3(1.5, 1.5, 1.5), true))
	props.append(_prop("statue_columnDamaged.glb", Vector3(2.5, 0, -11), -25.0, Vector3(1.1, 1.1, 1.1), true))
	props.append(_prop("statue_columnDamaged.glb", Vector3(-2.5, 0, -11), 20.0, Vector3(1.0, 1.0, 1.0), true))
	props.append(_prop("statue_head.glb", Vector3(1, 0, -10), 0.0))
	props.append(_prop("stump_oldTall.glb", Vector3(6, 0, -8), 45.0, Vector3(1.1, 1.1, 1.1), true))
	props.append(_prop("stump_old.glb", Vector3(-5, 0, -10), -30.0))
	# Abandoned homes
	props.append(_prop("tent_detailedClosed.glb", Vector3(-8, 0, 2), 110.0, TENT_LARGE, true))
	props.append(_prop("tent_smallClosed.glb", Vector3(7, 0, 1), -70.0, TENT_SMALL, true))
	props.append(_prop("tent_smallClosed.glb", Vector3(-6, 0, 6), 40.0, TENT_SMALL, true))
	# Overgrown market ruins
	_path_strip(props, "ground_pathRocks.glb", Vector3(-4, 0.01, 0), "x", 5, 2.0, 90.0)
	props.append(_prop("ground_pathEndClosed.glb", Vector3(6, 0.01, 0), -90.0))
	props.append(_prop("fence_planksDouble.glb", Vector3(4, 0, -1), -90.0, Vector3(0.9, 0.9, 0.9), true))
	props.append(_prop("fence_planksDouble.glb", Vector3(4, 0, 2), -90.0, Vector3(0.85, 0.85, 0.85), true))
	# Chapel ruins
	props.append(_prop("statue_ring.glb", Vector3(-3, 0, -5), 0.0, Vector3(1.05, 1.05, 1.05)))
	props.append(_prop("statue_obelisk.glb", Vector3(-5, 0, -4), 15.0, Vector3(1.0, 1.0, 1.0), true))
	props.append(_prop("hanging_moss.glb", Vector3(-4, 0, -3), 0.0))
	props.append(_prop("plant_bushLarge.glb", Vector3(3, 0, 4), 0.0))
	props.append(_prop("mushroom_tan.glb", Vector3(-2, 0, 3), 0.0))
	# Collapsed palisade
	_fence_line(props, "fence_simpleLow.glb", Vector3(-10, 0, -6), Vector3(10, 0, -6), 3.5, 0.0)
	props.append(_prop("fence_bend.glb", Vector3(10, 0, -4), -90.0))
	return {"props": props}
