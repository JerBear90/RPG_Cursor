extends Node3D
## Builds Paleheart Crypt geometry, encounters, puzzle, and boss.

signal build_completed

const _Kenney = preload("res://scripts/utilities/kenney_paths.gd")
const FLOOR_TILE := preload("res://scenes/dungeons/dungeon_floor_tile.tscn")
const _Room := preload("res://scripts/dungeons/crypt_room.gd")
const _Checkpoint := preload("res://scripts/dungeons/crypt_checkpoint.gd")
const _Trap := preload("res://scripts/dungeons/dungeon_trap.gd")
const _DiscoveryZone := preload("res://scripts/dungeons/room_discovery_zone.gd")
const _CryptGenerator = preload("res://scripts/dungeons/crypt_generator.gd")
const _SealPuzzle := preload("res://scripts/dungeons/burial_seal_puzzle.gd")
const _SealSwitch := preload("res://scripts/dungeons/burial_seal_switch.gd")
const _IceZone := preload("res://scripts/environment/ice_zone.gd")
const _ColdZone := preload("res://scripts/environment/cold_zone.gd")

const ENEMY_SCENES := {
	"gravewind_wraith": preload("res://scenes/enemies/gravewind_wraith.tscn"),
	"frozen_husk": preload("res://scenes/enemies/frozen_husk.tscn"),
	"rimebound_raider": preload("res://scenes/enemies/rimebound_raider.tscn"),
	"rimebound_archer": preload("res://scenes/enemies/rimebound_archer.tscn"),
	"frostbound_giant": preload("res://scenes/enemies/frostbound_giant.tscn"),
}

@export var enemies_container: NodePath = NodePath("../Enemies")
@export var interactables_container: NodePath = NodePath("../Interactables")

var _cell_size: float = 2.0
var _boss_node: Node = null
var _exit_portal: DungeonExitPortal
var _build_complete: bool = false
var _puzzle_gate: StaticBody3D


func _ready() -> void:
	add_to_group("dungeon_builder")
	call_deferred("_build")


func is_build_complete() -> bool:
	return _build_complete


func _build() -> void:
	var layout: Dictionary = DungeonManager.layout
	if layout.is_empty():
		layout = _CryptGenerator.generate(DungeonManager.seed)
		DungeonManager.layout = layout
	_cell_size = layout.get("cell_size", _CryptGenerator.CELL_SIZE)
	for room in layout.get("rooms", []):
		if room is CryptRoom:
			_build_room(room)
	_build_environment_lighting()
	_build_complete = true
	build_completed.emit()


func _build_room(room: CryptRoom) -> void:
	var origin := room.get_world_origin(_cell_size)
	var size := room.get_world_size(_cell_size)
	var icy := room.room_type in [CryptRoom.RoomType.BLACK_ICE, CryptRoom.RoomType.COLLAPSED]
	_fill_floor(origin, size, icy)
	if room.room_type == CryptRoom.RoomType.PASSAGE:
		return
	_build_walls(origin, size)
	_add_room_discovery(room, origin, size)
	match room.room_type:
		CryptRoom.RoomType.ENTRANCE:
			_add_prop("statue_block.glb", origin + Vector3(size.x * 0.5, 0, size.z * 0.35), 1.1)
			_add_prop("stone_largeA.glb", origin + Vector3(2, 0, 2), 1.0)
		CryptRoom.RoomType.BURIAL_HALL, CryptRoom.RoomType.COLLAPSED:
			_spawn_combat(room)
		CryptRoom.RoomType.CHECKPOINT:
			_spawn_checkpoint(room)
		CryptRoom.RoomType.PUZZLE:
			_spawn_puzzle(room)
		CryptRoom.RoomType.BLACK_ICE:
			_spawn_black_ice(room)
		CryptRoom.RoomType.RESOURCE:
			_spawn_resource(room)
		CryptRoom.RoomType.ELITE:
			_spawn_elite(room)
		CryptRoom.RoomType.BOSS_APPROACH:
			_add_prop("platform_stone.glb", room.get_world_center(_cell_size), 1.6)
		CryptRoom.RoomType.BOSS:
			_spawn_boss(room)


func _fill_floor(origin: Vector3, size: Vector3, icy: bool) -> void:
	var cols := int(size.x / _cell_size)
	var rows := int(size.z / _cell_size)
	for x in cols:
		for z in rows:
			var tile: Node3D = FLOOR_TILE.instantiate()
			tile.position = origin + Vector3(x * _cell_size + _cell_size * 0.5, 0, z * _cell_size + _cell_size * 0.5)
			for child in tile.get_children():
				if child is MeshInstance3D:
					var mat := StandardMaterial3D.new()
					mat.albedo_color = Color(0.14, 0.16, 0.22) if icy else Color(0.12, 0.12, 0.14)
					mat.roughness = 0.72
					mat.metallic = 0.15
					if icy:
						mat.emission_enabled = true
						mat.emission = Color(0.25, 0.35, 0.55)
						mat.emission_energy_multiplier = 0.25
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


func _add_room_discovery(room: CryptRoom, origin: Vector3, size: Vector3) -> void:
	var zone := _DiscoveryZone.new()
	zone.name = "RoomDiscovery_%d" % room.room_index
	zone.room_index = room.room_index
	zone.set_meta("crypt_room", true)
	zone.position = origin + Vector3(size.x * 0.5, 0.5, size.z * 0.5)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(size.x * 0.85, 2.5, size.z * 0.85)
	col.shape = shape
	zone.add_child(col)
	add_child(zone)


func _spawn_combat(room: CryptRoom) -> void:
	var container := get_node_or_null(enemies_container)
	if container == null:
		return
	var center := room.get_world_center(_cell_size)
	var keys := ["gravewind_wraith", "frozen_husk", "rimebound_raider", "rimebound_archer"]
	for i in maxi(room.enemy_count, 1):
		var key: String = keys[i % keys.size()]
		var scene: PackedScene = ENEMY_SCENES[key]
		var enemy: Node3D = scene.instantiate()
		enemy.position = center + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
		container.add_child(enemy)


func _spawn_checkpoint(room: CryptRoom) -> void:
	var container := get_node_or_null(interactables_container)
	if container == null:
		return
	var shrine := _Checkpoint.new()
	shrine.position = room.get_world_center(_cell_size)
	shrine.set_meta("room_index", room.room_index)
	container.add_child(shrine)
	_add_prop("campfire_bricks.glb", shrine.position + Vector3(-2, 0, 0), 0.9)
	_add_prop("statue_block.glb", shrine.position + Vector3(2, 0, 1), 1.0)


func _spawn_puzzle(room: CryptRoom) -> void:
	var container := get_node_or_null(interactables_container)
	if container == null:
		return
	var center := room.get_world_center(_cell_size)
	var puzzle := _SealPuzzle.new()
	puzzle.name = "BurialSealPuzzle"
	puzzle.position = center
	_puzzle_gate = StaticBody3D.new()
	_puzzle_gate.name = "ThroneGate"
	_puzzle_gate.position = center + Vector3(0, 0, 5)
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(5, 3, 0.8)
	col.shape = box
	col.position = Vector3(0, 1.5, 0)
	_puzzle_gate.add_child(col)
	if not CryptState.puzzle_completed:
		container.add_child(_puzzle_gate)
	container.add_child(puzzle)
	var ids := ["north", "south", "east", "west"]
	for i in 4:
		var sw := _SealSwitch.new()
		sw.seal_id = ids[i]
		sw.position = center + Vector3(-4.5 + i * 3, 0, -2)
		sw.controller_path = puzzle.get_path()
		container.add_child(sw)
		_add_prop("statue_block.glb", sw.position, 1.0)
	puzzle.gate_node_path = _puzzle_gate.get_path() if is_instance_valid(_puzzle_gate) else NodePath()


func _spawn_black_ice(room: CryptRoom) -> void:
	var center := room.get_world_center(_cell_size)
	var ice := _IceZone.new()
	ice.position = center + Vector3(-2, 0, 0)
	add_child(ice)
	var cold := _ColdZone.new()
	cold.position = center
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(8, 2, 8)
	col.shape = shape
	cold.add_child(col)
	add_child(cold)
	for i in 2:
		var trap := _Trap.new()
		trap.position = center + Vector3(2 + i * 3, 0.1, 1)
		trap.poison = false
		var ic := get_node_or_null(interactables_container)
		if ic:
			ic.add_child(trap)
		else:
			add_child(trap)


func _spawn_resource(room: CryptRoom) -> void:
	var container := get_node_or_null(interactables_container)
	if container == null:
		return
	var chest: Node3D = preload("res://scenes/dungeons/dungeon_treasure_chest.tscn").instantiate()
	chest.position = room.get_world_center(_cell_size)
	container.add_child(chest)


func _spawn_elite(room: CryptRoom) -> void:
	var container := get_node_or_null(enemies_container)
	if container == null:
		return
	var enemy: Node3D = ENEMY_SCENES["frostbound_giant"].instantiate()
	enemy.position = room.get_world_center(_cell_size)
	container.add_child(enemy)


func _spawn_boss(room: CryptRoom) -> void:
	var container := get_node_or_null(enemies_container)
	if container == null:
		return
	if CryptState.boss_defeated_persistent:
		_spawn_exit(room)
		return
	var center := room.get_world_center(_cell_size)
	var boss_scene := preload("res://scenes/enemies/bosses/hollow_king.tscn")
	_boss_node = boss_scene.instantiate()
	_boss_node.name = "HollowKing"
	_boss_node.position = center
	if _boss_node.has_signal("enemy_died"):
		_boss_node.enemy_died.connect(_on_boss_died)
	container.add_child(_boss_node)
	var gate := StaticBody3D.new()
	gate.name = "BossArenaGate"
	gate.position = center + Vector3(0, 0, -6)
	gate.collision_layer = 0
	var gcol := CollisionShape3D.new()
	var gshape := BoxShape3D.new()
	gshape.size = Vector3(8, 3, 0.6)
	gcol.shape = gshape
	gate.add_child(gcol)
	add_child(gate)
	if _boss_node.has_method("set_arena_gate"):
		_boss_node.set_arena_gate(gate)
	_add_prop("platform_stone.glb", center + Vector3(0, 0, -4), 2.0)
	_add_prop("statue_block.glb", center + Vector3(-3, 0, 3), 1.2)
	_add_prop("statue_block.glb", center + Vector3(3, 0, 3), 1.2)


func _spawn_exit(room: CryptRoom) -> void:
	var container := get_node_or_null(interactables_container)
	if container == null:
		return
	var center := room.get_world_center(_cell_size)
	_exit_portal = preload("res://scenes/dungeons/dungeon_exit_portal.tscn").instantiate()
	_exit_portal.position = center + Vector3(3, 0, 0)
	container.add_child(_exit_portal)
	_exit_portal.reveal()


func _on_boss_died(_enemy: EnemyBase) -> void:
	GameManager.in_boss_fight = false
	if CryptState.boss_defeated_persistent:
		return
	LootManager.drop_loot_table("hollow_king", _boss_node.global_position if _boss_node else Vector3.ZERO)
	if not InventoryManager.has_item("paleheart_relic"):
		InventoryManager.add_item("paleheart_relic", 1)
	if not InventoryManager.has_item("shattered_coast_pass"):
		InventoryManager.add_item("shattered_coast_pass", 1)
	if not InventoryManager.has_item("gravewind_charm"):
		InventoryManager.add_item("gravewind_charm", 1)
	if QuestManager.active_quests.has("the_pale_heart"):
		QuestManager.advance_objective("the_pale_heart", "defeat_king", 1)
		QuestManager.advance_objective("the_pale_heart", "recover_relic", 1)
	DungeonManager.on_crypt_boss_defeated()
	var layout: Dictionary = DungeonManager.layout
	for room in layout.get("rooms", []):
		if room is CryptRoom and room.room_type == CryptRoom.RoomType.BOSS:
			_spawn_exit(room)
			break


func _build_environment_lighting() -> void:
	var omni := OmniLight3D.new()
	omni.light_color = Color(0.55, 0.7, 0.95)
	omni.light_energy = 0.65
	omni.omni_range = 50.0
	omni.position = Vector3(25, 5, 5)
	add_child(omni)
