extends Node3D
## Builds Pyreheart Ziggurat geometry, encounters, mirror puzzle, and sealed solar heart.

signal build_completed

const _Kenney = preload("res://scripts/utilities/kenney_paths.gd")
const FLOOR_TILE := preload("res://scenes/dungeons/dungeon_floor_tile.tscn")
const _Room := preload("res://scripts/dungeons/pyreheart_room.gd")
const _Checkpoint := preload("res://scripts/dungeons/pyreheart_checkpoint.gd")
const _Trap := preload("res://scripts/dungeons/dungeon_trap.gd")
const _DiscoveryZone := preload("res://scripts/dungeons/room_discovery_zone.gd")
const _PyreheartGenerator = preload("res://scripts/dungeons/pyreheart_generator.gd")
const _MirrorPuzzle := preload("res://scripts/dungeons/mirror_puzzle.gd")
const _MirrorSwitch := preload("res://scripts/dungeons/mirror_switch.gd")
const _SealedHeartDoor := preload("res://scripts/dungeons/sealed_solar_heart_door.gd")
const _QuestTrigger := preload("res://scripts/dungeons/cathedral_quest_trigger.gd")
const _SolarTyrant := preload("res://scripts/enemies/bosses/solar_tyrant.gd")

const ENEMY_SCENES := {
	"ashscale_hound": preload("res://scenes/enemies/ashscale_hound.tscn"),
	"dune_raider": preload("res://scenes/enemies/dune_raider.tscn"),
	"dune_raider_archer": preload("res://scenes/enemies/dune_raider_archer.tscn"),
	"dune_raider_bomber": preload("res://scenes/enemies/dune_raider_bomber.tscn"),
	"glass_husk": preload("res://scenes/enemies/glass_husk.tscn"),
	"sand_wraith": preload("res://scenes/enemies/sand_wraith.tscn"),
	"burrow_stalker": preload("res://scenes/enemies/burrow_stalker.tscn"),
	"pyre_cultist": preload("res://scenes/enemies/pyre_cultist.tscn"),
	"sunscar_behemoth": preload("res://scenes/enemies/sunscar_behemoth.tscn"),
}

@export var enemies_container: NodePath = NodePath("../Enemies")
@export var interactables_container: NodePath = NodePath("../Interactables")

var _cell_size: float = 2.0
var _exit_portal: DungeonExitPortal
var _build_complete: bool = false
var _ziggurat_gate: StaticBody3D
var _heart_sand_wall: StaticBody3D
var _boss_node: SolarTyrant
var _depth: int = 0
var _puzzle_node: MirrorPuzzle


func _ready() -> void:
	add_to_group("dungeon_builder")
	add_to_group("pyreheart_builder")
	call_deferred("_build")


func is_build_complete() -> bool:
	return _build_complete


func reveal_exit() -> void:
	var layout: Dictionary = DungeonManager.layout
	for r in layout.get("rooms", []):
		if r is PyreheartRoom and r.room_type == PyreheartRoom.RoomType.EXIT_TERRACE:
			_spawn_exit(r)
			break


func _build() -> void:
	var layout: Dictionary = DungeonManager.layout
	if layout.is_empty():
		layout = _PyreheartGenerator.generate(DungeonManager.seed)
		DungeonManager.layout = layout
	_cell_size = layout.get("cell_size", _PyreheartGenerator.CELL_SIZE)
	_depth = 0
	for room in layout.get("rooms", []):
		if room is PyreheartRoom:
			if room.room_type != PyreheartRoom.RoomType.PASSAGE:
				_depth += 1
			_build_room(room)
	_wire_puzzle_gate()
	if PyreheartState.boss_defeated_persistent:
		for room in layout.get("rooms", []):
			if room is PyreheartRoom and room.room_type == PyreheartRoom.RoomType.EXIT_TERRACE:
				_spawn_exit(room)
				break
		DungeonManager.boss_defeated = true
	elif PyreheartState.puzzle_completed or PyreheartState.cooling_channels_active:
		unlock_solar_heart_chamber()
	_build_environment_lighting()
	_build_complete = true
	build_completed.emit()


func _build_room(room: PyreheartRoom) -> void:
	var origin := room.get_world_origin(_cell_size)
	var size := room.get_world_size(_cell_size)
	var scorched := room.room_type in [
		PyreheartRoom.RoomType.SAND_CLOISTER, PyreheartRoom.RoomType.HEAT_MAZE,
		PyreheartRoom.RoomType.SCORCHED_NAVE, PyreheartRoom.RoomType.COLLAPSED_ARCHWAY,
		PyreheartRoom.RoomType.EMBER_BAPTISTRY,
	]
	var tall_ziggurat := room.room_type in [
		PyreheartRoom.RoomType.SCORCHED_NAVE, PyreheartRoom.RoomType.CENTRAL_ZIGGURAT,
		PyreheartRoom.RoomType.ASCENT_APPROACH,
	]
	_fill_floor(origin, size, scorched, tall_ziggurat)
	if room.room_type == PyreheartRoom.RoomType.PASSAGE:
		return
	_build_walls(origin, size, scorched)
	_add_room_discovery(room, origin, size)
	match room.room_type:
		PyreheartRoom.RoomType.ENTRANCE:
			_add_entrance_props(origin, size)
		PyreheartRoom.RoomType.SCORCHED_NAVE, PyreheartRoom.RoomType.COLLAPSED_ARCHWAY:
			_spawn_combat(room, _depth, "entrance")
			_add_nave_props(origin, size)
		PyreheartRoom.RoomType.SAND_CLOISTER, PyreheartRoom.RoomType.BURIED_ARCHIVE:
			_spawn_combat(room, _depth, "cloister")
			_add_cloister_props(origin, size)
		PyreheartRoom.RoomType.EMBER_BAPTISTRY:
			_spawn_combat(room, _depth, "purification")
			_add_prop("platform_stone.glb", origin + Vector3(size.x * 0.5, 0, size.z * 0.5), 1.1)
		PyreheartRoom.RoomType.HEAT_MAZE, PyreheartRoom.RoomType.GLASS_HALL:
			_spawn_combat(room, _depth, "maze" if room.room_type == PyreheartRoom.RoomType.HEAT_MAZE else "glass")
			if room.room_type == PyreheartRoom.RoomType.HEAT_MAZE:
				_spawn_heat_traps(room)
		PyreheartRoom.RoomType.OBELISK_TOWER:
			_add_prop("statue_obelisk.glb", origin + Vector3(size.x * 0.5, 0, size.z * 0.5), 1.4)
		PyreheartRoom.RoomType.CHECKPOINT:
			_spawn_checkpoint(room)
		PyreheartRoom.RoomType.MIRROR_CHAMBER:
			_spawn_puzzle(room)
		PyreheartRoom.RoomType.RESOURCE_VAULT:
			_spawn_resource(room)
		PyreheartRoom.RoomType.ELITE_PYRE_CHAPEL:
			_spawn_elite(room)
		PyreheartRoom.RoomType.CENTRAL_ZIGGURAT:
			_spawn_central_ziggurat(room)
		PyreheartRoom.RoomType.ASCENT_APPROACH:
			_spawn_ascent(room)
		PyreheartRoom.RoomType.SOLAR_ANTECHAMBER:
			_spawn_antechamber(room)
		PyreheartRoom.RoomType.SEALED_HEART_CHAMBER:
			_spawn_sealed_heart(room)
		PyreheartRoom.RoomType.EXIT_TERRACE:
			pass


func _fill_floor(origin: Vector3, size: Vector3, scorched: bool, tall: bool = false) -> void:
	var cols := int(size.x / _cell_size)
	var rows := int(size.z / _cell_size)
	for x in cols:
		for z in rows:
			var tile: Node3D = FLOOR_TILE.instantiate()
			tile.position = origin + Vector3(x * _cell_size + _cell_size * 0.5, 0, z * _cell_size + _cell_size * 0.5)
			for child in tile.get_children():
				if child is MeshInstance3D:
					var mat := StandardMaterial3D.new()
					if scorched:
						mat.albedo_color = Color(0.28, 0.18, 0.1)
						mat.emission = Color(0.72, 0.38, 0.12)
						mat.emission_energy_multiplier = 0.18
					elif tall:
						mat.albedo_color = Color(0.22, 0.14, 0.1)
						mat.emission = Color(0.85, 0.45, 0.18)
						mat.emission_energy_multiplier = 0.2
					else:
						mat.albedo_color = Color(0.24, 0.16, 0.11)
						mat.emission = Color(0.62, 0.32, 0.14)
						mat.emission_energy_multiplier = 0.14
					mat.roughness = 0.78
					mat.metallic = 0.06
					mat.emission_enabled = true
					(child as MeshInstance3D).material_override = mat
			add_child(tile)


func _build_walls(origin: Vector3, size: Vector3, scorched: bool) -> void:
	var wall_path := _Kenney.nature("cliff_block_rock.glb")
	var cols := int(size.x / _cell_size)
	var rows := int(size.z / _cell_size)
	for x in cols:
		var px := origin.x + x * _cell_size + _cell_size * 0.5
		_add_wall(wall_path, Vector3(px, 0, origin.z - _cell_size * 0.25), scorched)
		_add_wall(wall_path, Vector3(px, 0, origin.z + size.z + _cell_size * 0.25), scorched)
	for z in rows:
		var pz := origin.z + z * _cell_size + _cell_size * 0.5
		_add_wall(wall_path, Vector3(origin.x - _cell_size * 0.25, 0, pz), scorched)
		_add_wall(wall_path, Vector3(origin.x + size.x + _cell_size * 0.25, 0, pz), scorched)


func _add_wall(path: String, pos: Vector3, scorched: bool) -> void:
	var holder := Node3D.new()
	holder.position = pos
	add_child(holder)
	MeshLoader.instantiate(path, holder, 0.0, Vector3.ZERO, Vector3(2.0, 2.8, 2.0))
	if scorched and randf() > 0.5:
		_add_prop("rock_smallA.glb", pos + Vector3(0, 0, 0.4), 0.7)
	var body := StaticBody3D.new()
	body.position = pos
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(_cell_size, 2.8, _cell_size * 0.5)
	col.shape = shape
	col.position = Vector3(0, 1.4, 0)
	body.add_child(col)
	add_child(body)


func _add_prop(glb: String, pos: Vector3, scale: float = 1.0) -> void:
	var path := _Kenney.nature(glb)
	if not FileAccess.file_exists(path):
		return
	var holder := Node3D.new()
	holder.position = pos
	add_child(holder)
	MeshLoader.instantiate(path, holder, randf_range(0, 360), Vector3.ZERO, Vector3.ONE * scale)


func _add_entrance_props(origin: Vector3, size: Vector3) -> void:
	_add_prop("fence_gate.glb", origin + Vector3(size.x * 0.5, 0, 1.5), 1.0)
	_add_prop("statue_obelisk.glb", origin + Vector3(2, 0, 2), 1.2)
	_add_prop("statue_obelisk.glb", origin + Vector3(size.x - 2, 0, 2), 1.2)
	if not PyreheartState.mirror_a:
		_add_sand_barrier(origin + Vector3(size.x * 0.5, 0, size.z - 3), "pyreheart_sand_barrier_a")


func _add_nave_props(origin: Vector3, size: Vector3) -> void:
	_add_prop("statue_columnDamaged.glb", origin + Vector3(size.x * 0.3, 0, size.z * 0.4), 1.1)
	_add_prop("statue_obelisk.glb", origin + Vector3(size.x * 0.7, 0, size.z * 0.35), 1.0)
	_add_prop("rock_tallA.glb", origin + Vector3(size.x * 0.5, 0, size.z * 0.55), 0.85)


func _add_cloister_props(origin: Vector3, size: Vector3) -> void:
	_add_prop("rock_smallA.glb", origin + Vector3(3, 0, 3), 0.9)
	_add_prop("statue_block.glb", origin + Vector3(size.x - 3, 0, size.z - 3), 0.9)


func _add_sand_barrier(pos: Vector3, group_name: String) -> void:
	if group_name == "pyreheart_sand_barrier_a" and PyreheartState.mirror_a:
		return
	if group_name == "pyreheart_sand_barrier_b" and PyreheartState.mirror_b:
		return
	var wall := StaticBody3D.new()
	wall.name = group_name
	wall.add_to_group(group_name)
	wall.position = pos
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(5, 3.2, 1.0)
	col.shape = box
	col.position = Vector3(0, 1.6, 0)
	wall.add_child(col)
	add_child(wall)
	_add_prop("rock_largeA.glb", pos + Vector3(-1.2, 0, 0), 1.1)
	_add_prop("rock_largeA.glb", pos + Vector3(1.2, 0, 0), 1.1)


func _add_room_discovery(room: PyreheartRoom, origin: Vector3, size: Vector3) -> void:
	var zone := _DiscoveryZone.new()
	zone.name = "RoomDiscovery_%d" % room.room_index
	zone.room_index = room.room_index
	zone.set_meta("pyreheart_room", true)
	zone.position = origin + Vector3(size.x * 0.5, 0.5, size.z * 0.5)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(size.x * 0.85, 2.5, size.z * 0.85)
	col.shape = shape
	zone.add_child(col)
	add_child(zone)


func _spawn_combat(room: PyreheartRoom, depth: int, zone: String) -> void:
	var container := get_node_or_null(enemies_container)
	if container == null or room.enemy_count <= 0:
		return
	var center := room.get_world_center(_cell_size)
	var keys: Array[String] = []
	match zone:
		"entrance":
			keys = ["ashscale_hound", "dune_raider"]
		"cloister":
			keys = ["dune_raider_archer", "glass_husk"]
		"purification":
			keys = ["dune_raider", "pyre_cultist", "glass_husk"]
		"maze":
			keys = ["burrow_stalker", "sand_wraith", "ashscale_hound"]
		"glass":
			keys = ["sand_wraith", "pyre_cultist"]
		"ziggurat":
			keys = ["dune_raider", "pyre_cultist", "glass_husk"]
		"ascent":
			keys = ["dune_raider_bomber", "pyre_cultist"]
		_:
			if depth <= 4:
				keys = ["ashscale_hound", "dune_raider"]
			else:
				keys = ["pyre_cultist", "sand_wraith", "burrow_stalker"]
	var count := maxi(room.enemy_count, 1)
	for i in count:
		var key: String = keys[i % keys.size()]
		var enemy: Node3D = ENEMY_SCENES[key].instantiate()
		enemy.position = center + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
		container.add_child(enemy)


func _spawn_heat_traps(room: PyreheartRoom) -> void:
	var container := get_node_or_null(interactables_container)
	if container == null:
		return
	var center := room.get_world_center(_cell_size)
	for i in 2:
		var trap := _Trap.new()
		trap.position = center + Vector3(-2 + i * 4, 0.1, 1)
		container.add_child(trap)


func _spawn_checkpoint(room: PyreheartRoom) -> void:
	var container := get_node_or_null(interactables_container)
	if container == null:
		return
	var shrine := _Checkpoint.new()
	shrine.position = room.get_world_center(_cell_size)
	shrine.set_meta("room_index", room.room_index)
	container.add_child(shrine)
	_add_prop("campfire_bricks.glb", shrine.position + Vector3(-2, 0, 0), 0.9)
	_add_prop("statue_obelisk.glb", shrine.position + Vector3(2, 0, 1), 1.0)


func _spawn_puzzle(room: PyreheartRoom) -> void:
	var container := get_node_or_null(interactables_container)
	if container == null:
		return
	var center := room.get_world_center(_cell_size)
	_puzzle_node = _MirrorPuzzle.new()
	_puzzle_node.name = "MirrorPuzzle"
	_puzzle_node.position = center
	container.add_child(_puzzle_node)
	var ids := ["mirror_a", "mirror_b", "mirror_c"]
	for i in 3:
		var sw := _MirrorSwitch.new()
		sw.mirror_id = ids[i]
		sw.position = center + Vector3(-4.5 + i * 4.5, 0, -2)
		sw.controller_path = _puzzle_node.get_path()
		sw.add_to_group("mirror_switch")
		container.add_child(sw)
		_add_prop("statue_obelisk.glb", sw.position, 0.85)
	if not PyreheartState.mirror_b:
		_add_sand_barrier(center + Vector3(0, 0, 4), "pyreheart_sand_barrier_b")


func _spawn_ziggurat_gate(room: PyreheartRoom) -> void:
	if PyreheartState.mirror_c or PyreheartState.cooling_channels_active:
		return
	var container := get_node_or_null(interactables_container)
	if container == null:
		return
	var center := room.get_world_center(_cell_size)
	_ziggurat_gate = StaticBody3D.new()
	_ziggurat_gate.name = "CentralZigguratSandGate"
	_ziggurat_gate.add_to_group("central_ziggurat_sand_gate")
	_ziggurat_gate.position = center + Vector3(0, 0, -4.5)
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(6, 3.5, 1.2)
	col.shape = box
	col.position = Vector3(0, 1.75, 0)
	_ziggurat_gate.add_child(col)
	container.add_child(_ziggurat_gate)
	_add_prop("rock_largeA.glb", _ziggurat_gate.position + Vector3(-1.5, 0, 0), 1.2)
	_add_prop("rock_largeA.glb", _ziggurat_gate.position + Vector3(1.5, 0, 0), 1.2)


func _wire_puzzle_gate() -> void:
	if _puzzle_node == null:
		return
	if is_instance_valid(_ziggurat_gate):
		_puzzle_node.gate_node_path = _ziggurat_gate.get_path()


func _spawn_resource(room: PyreheartRoom) -> void:
	var container := get_node_or_null(interactables_container)
	if container == null:
		return
	var chest: Node3D = preload("res://scenes/dungeons/dungeon_treasure_chest.tscn").instantiate()
	chest.position = room.get_world_center(_cell_size)
	container.add_child(chest)


func _spawn_elite(room: PyreheartRoom) -> void:
	var container := get_node_or_null(enemies_container)
	if container == null:
		return
	var center := room.get_world_center(_cell_size)
	var behemoth: Node3D = ENEMY_SCENES["sunscar_behemoth"].instantiate()
	behemoth.position = center
	container.add_child(behemoth)
	var cultist: Node3D = ENEMY_SCENES["pyre_cultist"].instantiate()
	cultist.position = center + Vector3(-3, 0, 2)
	container.add_child(cultist)


func _spawn_central_ziggurat(room: PyreheartRoom) -> void:
	var center := room.get_world_center(_cell_size)
	_spawn_ziggurat_gate(room)
	_spawn_combat(room, _depth, "ziggurat")
	_add_prop("platform_stone.glb", center, 1.5)
	_add_prop("statue_obelisk.glb", center + Vector3(-4, 0, 2), 1.2)
	_add_prop("statue_obelisk.glb", center + Vector3(4, 0, 2), 1.2)
	var trigger := _QuestTrigger.new()
	trigger.position = center
	trigger.quest_id = "heart_of_the_wastes"
	trigger.objective_id = "reach_inner_pyramid"
	add_child(trigger)


func _spawn_ascent(room: PyreheartRoom) -> void:
	var center := room.get_world_center(_cell_size)
	_spawn_combat(room, _depth, "ascent")
	_add_prop("platform_stone.glb", center + Vector3(0, 0, 1), 1.3)
	_add_prop("statue_column.glb", center + Vector3(-3, 0, 0), 1.2)


func _spawn_antechamber(room: PyreheartRoom) -> void:
	var center := room.get_world_center(_cell_size)
	_add_prop("statue_obelisk.glb", center + Vector3(-3, 0, 0), 1.2)
	_add_prop("statue_obelisk.glb", center + Vector3(3, 0, 0), 1.2)
	var trigger := _QuestTrigger.new()
	trigger.position = center
	trigger.quest_id = "heart_of_the_wastes"
	trigger.objective_id = "prepare_solar_heart"
	add_child(trigger)
	var container := get_node_or_null(enemies_container)
	if container and room.enemy_count > 0:
		var bomber: Node3D = ENEMY_SCENES["dune_raider_bomber"].instantiate()
		bomber.position = center + Vector3(0, 0, 1)
		container.add_child(bomber)


func unlock_solar_heart_chamber() -> void:
	if is_instance_valid(_heart_sand_wall):
		_heart_sand_wall.queue_free()
		_heart_sand_wall = null
	for node in get_tree().get_nodes_in_group("pyreheart_heart_sand_wall"):
		if is_instance_valid(node):
			node.queue_free()


func reset_boss_encounter() -> void:
	if _boss_node and is_instance_valid(_boss_node) and _boss_node.has_method("reset_encounter"):
		_boss_node.reset_encounter()


func _spawn_sealed_heart(room: PyreheartRoom) -> void:
	var container := get_node_or_null(interactables_container)
	if container == null:
		return
	var center := room.get_world_center(_cell_size)
	var door := _SealedHeartDoor.new()
	door.position = center + Vector3(0, 0, -5)
	container.add_child(door)
	var puzzle_ready := PyreheartState.puzzle_completed and PyreheartState.mirror_a \
		and PyreheartState.mirror_b and PyreheartState.mirror_c and PyreheartState.cooling_channels_active
	if not puzzle_ready:
		_heart_sand_wall = StaticBody3D.new()
		_heart_sand_wall.name = "HeartChamberSandWall"
		_heart_sand_wall.add_to_group("pyreheart_heart_sand_wall")
		_heart_sand_wall.position = center + Vector3(0, 0, -4.5)
		var rw_col := CollisionShape3D.new()
		var rw_box := BoxShape3D.new()
		rw_box.size = Vector3(8, 3.5, 1.0)
		rw_col.shape = rw_box
		rw_col.position = Vector3(0, 1.75, 0)
		_heart_sand_wall.add_child(rw_col)
		container.add_child(_heart_sand_wall)
	_add_prop("statue_obelisk.glb", center + Vector3(0, 0, -2), 1.3)
	_add_prop("platform_stone.glb", center + Vector3(0, 0, 0), 2.0)
	if PyreheartState.boss_defeated_persistent:
		return
	var enemy_container := get_node_or_null(enemies_container)
	if enemy_container == null:
		return
	var boss_scene := preload("res://scenes/enemies/bosses/solar_tyrant.tscn")
	_boss_node = boss_scene.instantiate()
	_boss_node.name = "SolarTyrant"
	_boss_node.position = center + Vector3(0, 0, 2)
	if _boss_node.has_signal("enemy_died"):
		_boss_node.enemy_died.connect(_on_boss_died)
	enemy_container.add_child(_boss_node)
	var gate := StaticBody3D.new()
	gate.name = "BossArenaGate"
	gate.position = center + Vector3(0, 0, -6)
	gate.collision_layer = 0
	var gcol := CollisionShape3D.new()
	var gshape := BoxShape3D.new()
	gshape.size = Vector3(10, 3, 0.6)
	gcol.shape = gshape
	gate.add_child(gcol)
	add_child(gate)
	if _boss_node.has_method("set_arena_gate"):
		_boss_node.set_arena_gate(gate)
	if not PyreheartState.mirror_b:
		var hazard_lane := StaticBody3D.new()
		hazard_lane.name = "BossHeatVentLane"
		hazard_lane.add_to_group("boss_hazard_lane")
		hazard_lane.position = center + Vector3(3.5, 0, 0)
		var hcol := CollisionShape3D.new()
		var hbox := BoxShape3D.new()
		hbox.size = Vector3(1.2, 0.3, 8)
		hcol.shape = hbox
		hazard_lane.add_child(hcol)
		var trap := _Trap.new()
		trap.position = hazard_lane.position + Vector3(0, 0.1, 0)
		trap.poison = false
		add_child(hazard_lane)
		container.add_child(trap)


func _on_boss_died(_enemy: EnemyBase) -> void:
	GameManager.in_boss_fight = false
	if PyreheartState.boss_defeated_persistent:
		return
	var drop_pos := _boss_node.global_position if _boss_node else Vector3.ZERO
	LootManager.drop_loot_table("solar_tyrant", drop_pos)
	if not InventoryManager.has_item("solar_heart_core"):
		InventoryManager.add_item("solar_heart_core", 1)
	if not InventoryManager.has_item("sunless_dominion_pass"):
		InventoryManager.add_item("sunless_dominion_pass", 1)
	if not InventoryManager.has_item("sunforged_halo"):
		InventoryManager.add_item("sunforged_halo", 1)
	if not InventoryManager.has_item("desert_glass"):
		InventoryManager.add_item("desert_glass", 2)
	CurrencyManager.add_copper(150)
	if QuestManager.active_quests.has("heart_of_the_wastes"):
		QuestManager.advance_objective("heart_of_the_wastes", "defeat_solar_tyrant", 1)
		QuestManager.advance_objective("heart_of_the_wastes", "recover_solar_heart_core", 1)
		QuestManager.advance_objective("heart_of_the_wastes", "stabilize_pyreheart", 1)
	DungeonManager.on_pyreheart_boss_defeated()
	AudioManager.play_sfx("solar_heart_exit_unlock")
	var layout: Dictionary = DungeonManager.layout
	for r in layout.get("rooms", []):
		if r is PyreheartRoom and r.room_type == PyreheartRoom.RoomType.EXIT_TERRACE:
			_spawn_exit(r)
			break


func _spawn_exit(room: PyreheartRoom) -> void:
	if _exit_portal != null and is_instance_valid(_exit_portal):
		_exit_portal.reveal()
		return
	var container := get_node_or_null(interactables_container)
	if container == null:
		return
	var center := room.get_world_center(_cell_size)
	_exit_portal = preload("res://scenes/dungeons/dungeon_exit_portal.tscn").instantiate()
	_exit_portal.position = center + Vector3(3, 0, 0)
	container.add_child(_exit_portal)
	if PyreheartState.boss_defeated_persistent or DungeonManager.boss_defeated:
		_exit_portal.reveal()
	_add_prop("fence_gate.glb", center + Vector3(-2, 0, 0), 1.0)


func _build_environment_lighting() -> void:
	var amber := OmniLight3D.new()
	amber.light_color = Color(0.95, 0.62, 0.28)
	amber.light_energy = 0.6
	amber.omni_range = 80.0
	amber.position = Vector3(100, 8, 5)
	add_child(amber)
	var copper := OmniLight3D.new()
	copper.light_color = Color(0.82, 0.42, 0.18)
	copper.light_energy = 0.42
	copper.omni_range = 65.0
	copper.position = Vector3(180, 5, 8)
	add_child(copper)
