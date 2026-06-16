extends Node3D
## Builds Drowned Citadel geometry, encounters, puzzle, and boss placeholder.

signal build_completed

const _Kenney = preload("res://scripts/utilities/kenney_paths.gd")
const FLOOR_TILE := preload("res://scenes/dungeons/dungeon_floor_tile.tscn")
const _Room := preload("res://scripts/dungeons/citadel_room.gd")
const _Checkpoint := preload("res://scripts/dungeons/citadel_checkpoint.gd")
const _Trap := preload("res://scripts/dungeons/dungeon_trap.gd")
const _DiscoveryZone := preload("res://scripts/dungeons/room_discovery_zone.gd")
const _CitadelGenerator = preload("res://scripts/dungeons/citadel_generator.gd")
const _ConduitPuzzle := preload("res://scripts/dungeons/storm_conduit_puzzle.gd")
const _ConduitSwitch := preload("res://scripts/dungeons/storm_conduit_switch.gd")

const ENEMY_SCENES := {
	"saltfang_hound": preload("res://scenes/enemies/saltfang_hound.tscn"),
	"tide_reaver": preload("res://scenes/enemies/tide_reaver.tscn"),
	"tide_reaver_archer": preload("res://scenes/enemies/tide_reaver_archer.tscn"),
	"tide_reaver_bomber": preload("res://scenes/enemies/tide_reaver_bomber.tscn"),
	"drowned_mariner": preload("res://scenes/enemies/drowned_mariner.tscn"),
	"storm_wraith": preload("res://scenes/enemies/storm_wraith.tscn"),
	"shellback_brute": preload("res://scenes/enemies/shellback_brute.tscn"),
	"leviathan_cultist": preload("res://scenes/enemies/leviathan_cultist.tscn"),
}

@export var enemies_container: NodePath = NodePath("../Enemies")
@export var interactables_container: NodePath = NodePath("../Interactables")

var _cell_size: float = 2.0
var _exit_portal: DungeonExitPortal
var _build_complete: bool = false
var _puzzle_gate: StaticBody3D
var _boss_node: Node3D
var _depth: int = 0


func _ready() -> void:
	add_to_group("dungeon_builder")
	call_deferred("_build")


func is_build_complete() -> bool:
	return _build_complete


func _build() -> void:
	var layout: Dictionary = DungeonManager.layout
	if layout.is_empty():
		layout = _CitadelGenerator.generate(DungeonManager.seed)
		DungeonManager.layout = layout
	_cell_size = layout.get("cell_size", _CitadelGenerator.CELL_SIZE)
	_depth = 0
	for room in layout.get("rooms", []):
		if room is CitadelRoom:
			if room.room_type != CitadelRoom.RoomType.PASSAGE:
				_depth += 1
			_build_room(room)
	_build_environment_lighting()
	_build_complete = true
	build_completed.emit()


func _build_room(room: CitadelRoom) -> void:
	var origin := room.get_world_origin(_cell_size)
	var size := room.get_world_size(_cell_size)
	var flooded := room.room_type in [
		CitadelRoom.RoomType.FLOODED_GALLERY, CitadelRoom.RoomType.SALT_CORRIDOR,
		CitadelRoom.RoomType.BROKEN_SEA_HALL, CitadelRoom.RoomType.TIDAL_TRAP,
	]
	_fill_floor(origin, size, flooded)
	if room.room_type == CitadelRoom.RoomType.PASSAGE:
		return
	_build_walls(origin, size)
	_add_room_discovery(room, origin, size)
	match room.room_type:
		CitadelRoom.RoomType.ENTRANCE:
			_add_prop("statue_block.glb", origin + Vector3(size.x * 0.5, 0, size.z * 0.35), 1.1)
			_add_prop("stone_largeA.glb", origin + Vector3(2, 0, 2), 1.0)
			_add_prop("fence_gate.glb", origin + Vector3(size.x * 0.5, 0, 1.5), 1.0)
		CitadelRoom.RoomType.FLOODED_GALLERY, CitadelRoom.RoomType.BROKEN_SEA_HALL:
			_spawn_combat(room, _depth)
			_add_prop("statue_columnDamaged.glb", origin + Vector3(size.x * 0.3, 0, size.z * 0.4), 1.0)
		CitadelRoom.RoomType.SALT_CORRIDOR, CitadelRoom.RoomType.TIDAL_TRAP:
			_spawn_combat(room, _depth)
		CitadelRoom.RoomType.DROWNED_BARRACKS:
			_spawn_combat(room, _depth)
			_add_prop("tent_detailedClosed.glb", origin + Vector3(3, 0, 3), 0.9)
			_add_prop("tent_detailedClosed.glb", origin + Vector3(size.x - 3, 0, size.z - 3), 0.9)
		CitadelRoom.RoomType.CHECKPOINT:
			_spawn_checkpoint(room)
		CitadelRoom.RoomType.PUZZLE:
			_spawn_puzzle(room)
		CitadelRoom.RoomType.RESOURCE, CitadelRoom.RoomType.TREASURE_HOLD:
			_spawn_resource(room)
		CitadelRoom.RoomType.ELITE:
			_spawn_elite(room)
		CitadelRoom.RoomType.BOSS_APPROACH:
			_spawn_approach(room)
		CitadelRoom.RoomType.BOSS:
			_spawn_boss(room)
		CitadelRoom.RoomType.EXIT:
			if CitadelState.boss_defeated_persistent:
				_spawn_exit(room)


func _fill_floor(origin: Vector3, size: Vector3, flooded: bool) -> void:
	var cols := int(size.x / _cell_size)
	var rows := int(size.z / _cell_size)
	for x in cols:
		for z in rows:
			var tile: Node3D = FLOOR_TILE.instantiate()
			tile.position = origin + Vector3(x * _cell_size + _cell_size * 0.5, 0, z * _cell_size + _cell_size * 0.5)
			for child in tile.get_children():
				if child is MeshInstance3D:
					var mat := StandardMaterial3D.new()
					mat.albedo_color = Color(0.1, 0.18, 0.22) if flooded else Color(0.11, 0.13, 0.16)
					mat.roughness = 0.68
					mat.metallic = 0.2
					if flooded:
						mat.emission_enabled = true
						mat.emission = Color(0.15, 0.35, 0.45)
						mat.emission_energy_multiplier = 0.2
					(child as MeshInstance3D).material_override = mat
			add_child(tile)


func _build_walls(origin: Vector3, size: Vector3) -> void:
	var wall_path := _Kenney.nature("cliff_block_stone.glb")
	var cols := int(size.x / _cell_size)
	var rows := int(size.z / _cell_size)
	for x in cols:
		var px := origin.x + x * _cell_size + _cell_size * 0.5
		_add_wall(wall_path, Vector3(px, 0, origin.z - _cell_size * 0.25))
		_add_wall(wall_path, Vector3(px, 0, origin.z + size.z + _cell_size * 0.25))
	for z in rows:
		var pz := origin.z + z * _cell_size + _cell_size * 0.5
		_add_wall(wall_path, Vector3(origin.x - _cell_size * 0.25, 0, pz))
		_add_wall(wall_path, Vector3(origin.x + size.x + _cell_size * 0.25, 0, pz))


func _add_wall(path: String, pos: Vector3) -> void:
	var holder := Node3D.new()
	holder.position = pos
	add_child(holder)
	MeshLoader.instantiate(path, holder, 0.0, Vector3.ZERO, Vector3(2.0, 2.8, 2.0))
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


func _add_room_discovery(room: CitadelRoom, origin: Vector3, size: Vector3) -> void:
	var zone := _DiscoveryZone.new()
	zone.name = "RoomDiscovery_%d" % room.room_index
	zone.room_index = room.room_index
	zone.set_meta("citadel_room", true)
	zone.position = origin + Vector3(size.x * 0.5, 0.5, size.z * 0.5)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(size.x * 0.85, 2.5, size.z * 0.85)
	col.shape = shape
	zone.add_child(col)
	add_child(zone)


func _spawn_combat(room: CitadelRoom, depth: int) -> void:
	var container := get_node_or_null(enemies_container)
	if container == null:
		return
	var center := room.get_world_center(_cell_size)
	var keys: Array[String] = []
	if depth <= 3:
		keys = ["saltfang_hound", "tide_reaver", "drowned_mariner"]
	elif depth <= 6:
		keys = ["drowned_mariner", "tide_reaver_archer", "storm_wraith"]
	elif depth <= 9:
		keys = ["storm_wraith", "leviathan_cultist", "drowned_mariner"]
	else:
		keys = ["leviathan_cultist", "tide_reaver_bomber", "shellback_brute"]
	var count := maxi(room.enemy_count, 1)
	for i in count:
		var key: String = keys[i % keys.size()]
		var scene: PackedScene = ENEMY_SCENES[key]
		var enemy: Node3D = scene.instantiate()
		enemy.position = center + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
		container.add_child(enemy)
	if room.room_type in [CitadelRoom.RoomType.SALT_CORRIDOR, CitadelRoom.RoomType.TIDAL_TRAP]:
		for i in 2:
			var trap := _Trap.new()
			trap.position = center + Vector3(-2 + i * 4, 0.1, 1)
			trap.poison = false
			var ic := get_node_or_null(interactables_container)
			if ic:
				ic.add_child(trap)
			else:
				add_child(trap)


func _spawn_checkpoint(room: CitadelRoom) -> void:
	var container := get_node_or_null(interactables_container)
	if container == null:
		return
	var shrine := _Checkpoint.new()
	shrine.position = room.get_world_center(_cell_size)
	shrine.set_meta("room_index", room.room_index)
	container.add_child(shrine)
	_add_prop("campfire_bricks.glb", shrine.position + Vector3(-2, 0, 0), 0.9)
	_add_prop("statue_block.glb", shrine.position + Vector3(2, 0, 1), 1.0)


func _spawn_puzzle(room: CitadelRoom) -> void:
	var container := get_node_or_null(interactables_container)
	if container == null:
		return
	var center := room.get_world_center(_cell_size)
	var puzzle := _ConduitPuzzle.new()
	puzzle.name = "StormConduitPuzzle"
	puzzle.position = center
	_puzzle_gate = StaticBody3D.new()
	_puzzle_gate.name = "AntechamberGate"
	_puzzle_gate.position = center + Vector3(0, 0, 5)
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(5, 3, 0.8)
	col.shape = box
	col.position = Vector3(0, 1.5, 0)
	_puzzle_gate.add_child(col)
	if not CitadelState.puzzle_completed:
		container.add_child(_puzzle_gate)
	container.add_child(puzzle)
	var ids := ["conduit_a", "conduit_b", "conduit_c"]
	for i in 3:
		var sw := _ConduitSwitch.new()
		sw.conduit_id = ids[i]
		sw.position = center + Vector3(-4.5 + i * 4.5, 0, -2)
		sw.controller_path = puzzle.get_path()
		sw.add_to_group("storm_conduit_switch")
		container.add_child(sw)
		_add_prop("statue_block.glb", sw.position, 1.0)
	puzzle.gate_node_path = _puzzle_gate.get_path() if is_instance_valid(_puzzle_gate) else NodePath()


func _spawn_resource(room: CitadelRoom) -> void:
	var container := get_node_or_null(interactables_container)
	if container == null:
		return
	var chest: Node3D = preload("res://scenes/dungeons/dungeon_treasure_chest.tscn").instantiate()
	chest.position = room.get_world_center(_cell_size)
	container.add_child(chest)


func _spawn_elite(room: CitadelRoom) -> void:
	var container := get_node_or_null(enemies_container)
	if container == null:
		return
	var center := room.get_world_center(_cell_size)
	var cultist: Node3D = ENEMY_SCENES["leviathan_cultist"].instantiate()
	cultist.position = center + Vector3(-2, 0, 0)
	container.add_child(cultist)
	var mariner: Node3D = ENEMY_SCENES["drowned_mariner"].instantiate()
	mariner.position = center + Vector3(2, 0, 2)
	container.add_child(mariner)
	_add_prop("statue_column.glb", center + Vector3(0, 0, -2), 1.3)


func _spawn_approach(room: CitadelRoom) -> void:
	var center := room.get_world_center(_cell_size)
	_add_prop("platform_stone.glb", center, 1.6)
	_add_prop("statue_columnDamaged.glb", center + Vector3(-3, 0, 2), 1.1)
	_add_prop("statue_columnDamaged.glb", center + Vector3(3, 0, 2), 1.1)
	var container := get_node_or_null(enemies_container)
	if container and room.enemy_count > 0:
		var reaver: Node3D = ENEMY_SCENES["tide_reaver"].instantiate()
		reaver.position = center + Vector3(0, 0, 3)
		container.add_child(reaver)


func _spawn_boss(room: CitadelRoom) -> void:
	var container := get_node_or_null(enemies_container)
	if container == null:
		return
	if CitadelState.boss_defeated_persistent:
		_spawn_exit(room)
		return
	var center := room.get_world_center(_cell_size)
	var boss_scene := preload("res://scenes/enemies/bosses/tidebound_sovereign.tscn")
	_boss_node = boss_scene.instantiate()
	_boss_node.name = "TideboundSovereign"
	_boss_node.position = center + Vector3(0, 0, 2)
	if _boss_node.has_signal("enemy_died"):
		_boss_node.enemy_died.connect(_on_boss_died)
	container.add_child(_boss_node)
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
	_add_prop("platform_stone.glb", center + Vector3(0, 0, -3), 2.2)
	_add_prop("statue_column.glb", center + Vector3(-4, 0, 4), 1.4)
	_add_prop("statue_column.glb", center + Vector3(4, 0, 4), 1.4)
	_add_prop("statue_block.glb", center + Vector3(0, 0, 5), 1.2)


func _on_boss_died(_enemy: EnemyBase) -> void:
	GameManager.in_boss_fight = false
	if CitadelState.boss_defeated_persistent:
		return
	LootManager.drop_loot_table("tidebound_sovereign", _boss_node.global_position if _boss_node else Vector3.ZERO)
	if not InventoryManager.has_item("tidebound_crown"):
		InventoryManager.add_item("tidebound_crown", 1)
	if not InventoryManager.has_item("stormwake_charm"):
		InventoryManager.add_item("stormwake_charm", 1)
	if not InventoryManager.has_item("stormglass"):
		InventoryManager.add_item("stormglass", 3)
	if QuestManager.active_quests.has("the_sunken_crown"):
		QuestManager.advance_objective("the_sunken_crown", "defeat_sovereign", 1)
		QuestManager.advance_objective("the_sunken_crown", "recover_crown", 1)
	DungeonManager.on_citadel_boss_defeated()
	var layout: Dictionary = DungeonManager.layout
	for r in layout.get("rooms", []):
		if r is CitadelRoom and r.room_type == CitadelRoom.RoomType.EXIT:
			_spawn_exit(r)
			break


func _spawn_boss_placeholder(room: CitadelRoom) -> void:
	pass


func _spawn_exit(room: CitadelRoom) -> void:
	var container := get_node_or_null(interactables_container)
	if container == null:
		return
	var center := room.get_world_center(_cell_size)
	_exit_portal = preload("res://scenes/dungeons/dungeon_exit_portal.tscn").instantiate()
	_exit_portal.position = center + Vector3(3, 0, 0)
	container.add_child(_exit_portal)
	_exit_portal.reveal()


func _build_environment_lighting() -> void:
	var omni := OmniLight3D.new()
	omni.light_color = Color(0.45, 0.65, 0.85)
	omni.light_energy = 0.6
	omni.omni_range = 50.0
	omni.position = Vector3(25, 5, 5)
	add_child(omni)
