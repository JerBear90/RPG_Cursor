extends Node3D
## Builds Blackvein Foundry geometry, encounters, puzzle, and boss.

signal build_completed

const _Kenney = preload("res://scripts/utilities/kenney_paths.gd")
const FLOOR_TILE := preload("res://scenes/dungeons/dungeon_floor_tile.tscn")
const _Room := preload("res://scripts/dungeons/foundry_room.gd")
const _Checkpoint := preload("res://scripts/dungeons/foundry_checkpoint.gd")
const _Trap := preload("res://scripts/dungeons/dungeon_trap.gd")
const _DiscoveryZone := preload("res://scripts/dungeons/room_discovery_zone.gd")
const _MechanismPuzzle := preload("res://scripts/dungeons/forge_mechanism_puzzle.gd")
const _MechanismSwitch := preload("res://scripts/dungeons/forge_mechanism_switch.gd")
const _HeatZone := preload("res://scripts/environment/heat_zone.gd")
const _Lava := preload("res://scripts/environment/lava_hazard.gd")

const ENEMY_SCENES := {
	"blackvein_miner": preload("res://scenes/enemies/blackvein_miner.tscn"),
	"ash_raider": preload("res://scenes/enemies/ash_raider.tscn"),
	"furnace_construct": preload("res://scenes/enemies/furnace_construct.tscn"),
	"ash_wraith": preload("res://scenes/enemies/ash_wraith.tscn"),
	"ironbound_elite": preload("res://scenes/enemies/ironbound_elite.tscn"),
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
		layout = FoundryGenerator.generate(DungeonManager.seed)
		DungeonManager.layout = layout
	_cell_size = layout.get("cell_size", FoundryGenerator.CELL_SIZE)
	for room in layout.get("rooms", []):
		if room is FoundryRoom:
			_build_room(room)
	_build_environment_lighting()
	_build_complete = true
	build_completed.emit()


func _build_room(room: FoundryRoom) -> void:
	var origin := room.get_world_origin(_cell_size)
	var size := room.get_world_size(_cell_size)
	var molten := room.room_type in [FoundryRoom.RoomType.MOLTEN, FoundryRoom.RoomType.SMELTING]
	_fill_floor(origin, size, molten)
	if room.room_type == FoundryRoom.RoomType.CORRIDOR:
		return
	_build_walls(origin, size)
	_add_room_discovery(room, origin, size)
	match room.room_type:
		FoundryRoom.RoomType.ENTRANCE:
			_add_prop("crate_open.glb", origin + Vector3(size.x * 0.5, 0, size.z * 0.35), 1.1)
			_add_prop("log_stack.glb", origin + Vector3(2, 0, 2), 1.0)
		FoundryRoom.RoomType.WORKSHOP, FoundryRoom.RoomType.SMELTING, FoundryRoom.RoomType.COMBAT:
			_spawn_combat(room)
		FoundryRoom.RoomType.CHECKPOINT:
			_spawn_checkpoint(room)
		FoundryRoom.RoomType.MECHANISM:
			_spawn_mechanism(room)
		FoundryRoom.RoomType.MOLTEN:
			_spawn_molten(room)
		FoundryRoom.RoomType.RESOURCE:
			_spawn_resource(room)
		FoundryRoom.RoomType.ELITE:
			_spawn_elite(room)
		FoundryRoom.RoomType.BOSS_APPROACH:
			_add_prop("platform_stone.glb", room.get_world_center(_cell_size), 1.6)
		FoundryRoom.RoomType.BOSS:
			_spawn_boss(room)


func _fill_floor(origin: Vector3, size: Vector3, hot: bool) -> void:
	var cols := int(size.x / _cell_size)
	var rows := int(size.z / _cell_size)
	for x in cols:
		for z in rows:
			var tile: Node3D = FLOOR_TILE.instantiate()
			tile.position = origin + Vector3(x * _cell_size + _cell_size * 0.5, 0, z * _cell_size + _cell_size * 0.5)
			for child in tile.get_children():
				if child is MeshInstance3D:
					var mat := StandardMaterial3D.new()
					mat.albedo_color = Color(0.28, 0.14, 0.1) if hot else Color(0.16, 0.15, 0.17)
					mat.roughness = 0.65
					mat.metallic = 0.35 if hot else 0.2
					if hot:
						mat.emission_enabled = true
						mat.emission = Color(0.5, 0.15, 0.05)
						mat.emission_energy_multiplier = 0.4
					(child as MeshInstance3D).material_override = mat
			add_child(tile)


func _build_walls(origin: Vector3, size: Vector3) -> void:
	var wall_path := _Kenney.nature("cliff_block_rock.glb")
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


func _add_room_discovery(room: FoundryRoom, origin: Vector3, size: Vector3) -> void:
	var zone := _DiscoveryZone.new()
	zone.name = "RoomDiscovery_%d" % room.room_index
	zone.room_index = room.room_index
	zone.set_meta("foundry_room", true)
	zone.position = origin + Vector3(size.x * 0.5, 0.5, size.z * 0.5)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(size.x * 0.85, 2.5, size.z * 0.85)
	col.shape = shape
	zone.add_child(col)
	add_child(zone)


func _spawn_combat(room: FoundryRoom) -> void:
	var container := get_node_or_null(enemies_container)
	if container == null:
		return
	var center := room.get_world_center(_cell_size)
	var keys := ["blackvein_miner", "ash_raider", "furnace_construct", "ash_wraith"]
	for i in maxi(room.enemy_count, 1):
		var key: String = keys[i % keys.size()]
		var scene: PackedScene = ENEMY_SCENES[key]
		var enemy: Node3D = scene.instantiate()
		enemy.position = center + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
		container.add_child(enemy)


func _spawn_checkpoint(room: FoundryRoom) -> void:
	var container := get_node_or_null(interactables_container)
	if container == null:
		return
	var shrine := _Checkpoint.new()
	shrine.position = room.get_world_center(_cell_size)
	shrine.set_meta("room_index", room.room_index)
	container.add_child(shrine)
	_add_prop("campfire_bricks.glb", shrine.position + Vector3(-2, 0, 0), 0.9)
	_add_prop("crate_open.glb", shrine.position + Vector3(2, 0, 1), 1.0)


func _spawn_mechanism(room: FoundryRoom) -> void:
	var container := get_node_or_null(interactables_container)
	if container == null:
		return
	var center := room.get_world_center(_cell_size)
	var puzzle := _MechanismPuzzle.new()
	puzzle.name = "ForgeMechanismPuzzle"
	puzzle.position = center
	_puzzle_gate = StaticBody3D.new()
	_puzzle_gate.name = "CoreGate"
	_puzzle_gate.position = center + Vector3(0, 0, 5)
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(5, 3, 0.8)
	col.shape = box
	col.position = Vector3(0, 1.5, 0)
	_puzzle_gate.add_child(col)
	if not FoundryState.puzzle_completed:
		container.add_child(_puzzle_gate)
	container.add_child(puzzle)
	for i in 3:
		var sw := _MechanismSwitch.new()
		var ids := ["vent", "rail", "furnace"]
		sw.mechanism_id = ids[i]
		sw.position = center + Vector3(-4 + i * 4, 0, -2)
		sw.controller_path = puzzle.get_path()
		container.add_child(sw)
		_add_prop("crate_open.glb", sw.position, 1.0)
	puzzle.gate_node_path = _puzzle_gate.get_path() if is_instance_valid(_puzzle_gate) else NodePath()


func _spawn_molten(room: FoundryRoom) -> void:
	var center := room.get_world_center(_cell_size)
	var lava := _Lava.new()
	lava.position = center + Vector3(-2, 0, 0)
	add_child(lava)
	var heat := _HeatZone.new()
	heat.position = center
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(8, 2, 8)
	col.shape = shape
	heat.add_child(col)
	add_child(heat)
	for i in 2:
		var trap := _Trap.new()
		trap.position = center + Vector3(2 + i * 3, 0.1, 1)
		trap.poison = false
		var ic := get_node_or_null(interactables_container)
		if ic:
			ic.add_child(trap)
		else:
			add_child(trap)


func _spawn_resource(room: FoundryRoom) -> void:
	var container := get_node_or_null(interactables_container)
	if container == null:
		return
	var chest: Node3D = preload("res://scenes/dungeons/dungeon_treasure_chest.tscn").instantiate()
	chest.position = room.get_world_center(_cell_size)
	container.add_child(chest)


func _spawn_elite(room: FoundryRoom) -> void:
	var container := get_node_or_null(enemies_container)
	if container == null:
		return
	var enemy: Node3D = ENEMY_SCENES["ironbound_elite"].instantiate()
	enemy.position = room.get_world_center(_cell_size)
	container.add_child(enemy)


func _spawn_boss(room: FoundryRoom) -> void:
	var container := get_node_or_null(enemies_container)
	if container == null:
		return
	if FoundryState.boss_defeated_persistent:
		_spawn_exit(room)
		return
	var center := room.get_world_center(_cell_size)
	var boss_scene := preload("res://scenes/enemies/iron_crucible.tscn")
	_boss_node = boss_scene.instantiate()
	_boss_node.position = center
	if _boss_node.has_signal("enemy_died"):
		_boss_node.enemy_died.connect(_on_boss_died)
	container.add_child(_boss_node)
	_add_prop("platform_stone.glb", center + Vector3(0, 0, -4), 2.0)


func _spawn_exit(room: FoundryRoom) -> void:
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
	if FoundryState.boss_defeated_persistent:
		return
	LootManager.drop_loot_table("iron_crucible", _boss_node.global_position if _boss_node else Vector3.ZERO)
	if not InventoryManager.has_item("foundry_core"):
		InventoryManager.add_item("foundry_core", 1)
	if not InventoryManager.has_item("frostgrave_pass"):
		InventoryManager.add_item("frostgrave_pass", 1)
	if QuestManager.active_quests.has("heart_of_blackvein"):
		QuestManager.advance_objective("heart_of_blackvein", "defeat_crucible", 1)
		QuestManager.advance_objective("heart_of_blackvein", "recover_core", 1)
	DungeonManager.on_foundry_boss_defeated()
	var layout: Dictionary = DungeonManager.layout
	for room in layout.get("rooms", []):
		if room is FoundryRoom and room.room_type == FoundryRoom.RoomType.BOSS:
			_spawn_exit(room)
			break


func _build_environment_lighting() -> void:
	var omni := OmniLight3D.new()
	omni.light_color = Color(1.0, 0.55, 0.25)
	omni.light_energy = 0.75
	omni.omni_range = 50.0
	omni.position = Vector3(25, 5, 5)
	add_child(omni)
