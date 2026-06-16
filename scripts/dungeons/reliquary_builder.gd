extends Node3D
## Builds Sunken Reliquary geometry, encounters, puzzle, and boss.

signal build_completed

const _Kenney = preload("res://scripts/utilities/kenney_paths.gd")
const FLOOR_TILE := preload("res://scenes/dungeons/dungeon_floor_tile.tscn")
const _Room := preload("res://scripts/dungeons/reliquary_room.gd")
const _BellPuzzle := preload("res://scripts/dungeons/bell_puzzle.gd")
const _BellRing := preload("res://scripts/dungeons/bell_ring.gd")
const _Checkpoint := preload("res://scripts/dungeons/reliquary_checkpoint.gd")
const _Trap := preload("res://scripts/dungeons/dungeon_trap.gd")
const _DiscoveryZone := preload("res://scripts/dungeons/room_discovery_zone.gd")

const ENEMY_SCENES := {
	"drowned_husk": preload("res://scenes/enemies/drowned_husk.tscn"),
	"rotfen_cultist": preload("res://scenes/enemies/rotfen_cultist.tscn"),
	"bog_stalker": preload("res://scenes/enemies/bog_stalker.tscn"),
	"spore_brute": preload("res://scenes/enemies/spore_brute.tscn"),
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
		layout = ReliquaryGenerator.generate(DungeonManager.seed)
		DungeonManager.layout = layout
	_cell_size = layout.get("cell_size", ReliquaryGenerator.CELL_SIZE)
	for room in layout.get("rooms", []):
		if room is ReliquaryRoom:
			_build_room(room)
	_build_environment_lighting()
	_build_complete = true
	build_completed.emit()


func _build_room(room: ReliquaryRoom) -> void:
	var origin := room.get_world_origin(_cell_size)
	var size := room.get_world_size(_cell_size)
	_fill_floor(origin, size, room.room_type == ReliquaryRoom.RoomType.FLOODED)
	if room.room_type == ReliquaryRoom.RoomType.CORRIDOR:
		return
	_build_walls(origin, size)
	_add_room_discovery(room, origin, size)
	match room.room_type:
		ReliquaryRoom.RoomType.ENTRANCE:
			_add_prop("statue_column.glb", origin + Vector3(size.x * 0.5, 0, size.z * 0.3), 2.0)
		ReliquaryRoom.RoomType.FLOODED, ReliquaryRoom.RoomType.COMBAT:
			_spawn_combat(room)
		ReliquaryRoom.RoomType.CHECKPOINT:
			_spawn_checkpoint(room)
		ReliquaryRoom.RoomType.PUZZLE:
			_spawn_puzzle(room)
		ReliquaryRoom.RoomType.TRAP:
			_spawn_traps(room)
		ReliquaryRoom.RoomType.RESOURCE:
			_spawn_resource(room)
		ReliquaryRoom.RoomType.ELITE:
			_spawn_elite(room)
		ReliquaryRoom.RoomType.BOSS_APPROACH:
			_add_prop("statue_ring.glb", room.get_world_center(_cell_size), 1.4)
		ReliquaryRoom.RoomType.BOSS:
			_spawn_boss(room)


func _fill_floor(origin: Vector3, size: Vector3, flooded: bool) -> void:
	var cols := int(size.x / _cell_size)
	var rows := int(size.z / _cell_size)
	for x in cols:
		for z in rows:
			var tile: Node3D = FLOOR_TILE.instantiate()
			tile.position = origin + Vector3(x * _cell_size + _cell_size * 0.5, 0, z * _cell_size + _cell_size * 0.5)
			if flooded:
				for child in tile.get_children():
					if child is MeshInstance3D:
						var mat := StandardMaterial3D.new()
						mat.albedo_color = Color(0.12, 0.28, 0.32)
						mat.roughness = 0.4
						mat.metallic = 0.1
						(child as MeshInstance3D).material_override = mat
			else:
				for child in tile.get_children():
					if child is MeshInstance3D:
						var mat := StandardMaterial3D.new()
						mat.albedo_color = Color(0.18, 0.22, 0.26)
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


func _add_room_discovery(room: ReliquaryRoom, origin: Vector3, size: Vector3) -> void:
	var zone := _DiscoveryZone.new()
	zone.name = "RoomDiscovery_%d" % room.room_index
	zone.room_index = room.room_index
	zone.position = origin + Vector3(size.x * 0.5, 0.5, size.z * 0.5)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(size.x * 0.85, 2.5, size.z * 0.85)
	col.shape = shape
	zone.add_child(col)
	add_child(zone)


func _spawn_combat(room: ReliquaryRoom) -> void:
	var container := get_node_or_null(enemies_container)
	if container == null:
		return
	var center := room.get_world_center(_cell_size)
	var keys := ["drowned_husk", "rotfen_cultist", "bog_stalker"]
	for i in room.enemy_count:
		var scene: PackedScene = ENEMY_SCENES[keys[i % keys.size()]]
		var enemy: Node3D = scene.instantiate()
		enemy.position = center + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
		container.add_child(enemy)
		if enemy.has_signal("enemy_died"):
			enemy.enemy_died.connect(func(_e): _on_room_cleared(room, center))


func _on_room_cleared(room: ReliquaryRoom, center: Vector3) -> void:
	var container := get_node_or_null(enemies_container)
	if container == null:
		return
	for child in container.get_children():
		if child is EnemyBase and (child as EnemyBase).current_state != EnemyBase.AIState.DEAD:
			return
	if room.room_type != ReliquaryRoom.RoomType.CHECKPOINT:
		WorldStateManager.dungeon_checkpoint_room = room.room_index
		WorldStateManager.register_checkpoint(
			"dungeon_checkpoint_room_%d" % room.room_index,
			"sunken_reliquary",
			center
		)


func _spawn_checkpoint(room: ReliquaryRoom) -> void:
	var container := get_node_or_null(interactables_container)
	if container == null:
		return
	var shrine := _Checkpoint.new()
	shrine.position = room.get_world_center(_cell_size)
	shrine.set_meta("room_index", room.room_index)
	container.add_child(shrine)
	_add_prop("statue_obelisk.glb", shrine.position + Vector3(-2, 0, 0), 1.2)
	_add_prop("campfire_bricks.glb", shrine.position + Vector3(1, 0, 1), 0.9)


func _spawn_puzzle(room: ReliquaryRoom) -> void:
	var container := get_node_or_null(interactables_container)
	if container == null:
		return
	var center := room.get_world_center(_cell_size)
	var puzzle := _BellPuzzle.new()
	puzzle.name = "BellPuzzle"
	puzzle.position = center
	_puzzle_gate = StaticBody3D.new()
	_puzzle_gate.name = "PuzzleGate"
	_puzzle_gate.position = center + Vector3(0, 0, 4)
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4, 3, 0.6)
	col.shape = box
	col.position = Vector3(0, 1.5, 0)
	_puzzle_gate.add_child(col)
	if not ReliquaryState.puzzle_completed:
		container.add_child(_puzzle_gate)
	container.add_child(puzzle)
	for i in 3:
		var bell := _BellRing.new()
		bell.bell_index = i + 1
		bell.position = center + Vector3(-3 + i * 3, 0, -2)
		container.add_child(bell)
		bell.controller_path = puzzle.get_path()
		_add_prop("statue_columnDamaged.glb", bell.position, 1.0)
	puzzle.gate_node_path = _puzzle_gate.get_path() if is_instance_valid(_puzzle_gate) else NodePath()


func _spawn_traps(room: ReliquaryRoom) -> void:
	var container := get_node_or_null(interactables_container)
	if container == null:
		return
	var center := room.get_world_center(_cell_size)
	for i in 3:
		var trap := _Trap.new()
		trap.position = center + Vector3(-4 + i * 4, 0.1, 0)
		trap.poison = i == 1
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(2, 0.1, 2)
		mesh.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.3, 0.15, 0.2, 0.5)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mesh.material_override = mat
		trap.add_child(mesh)
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(2, 1, 2)
		col.shape = shape
		trap.add_child(col)
		container.add_child(trap)


func _spawn_resource(room: ReliquaryRoom) -> void:
	var container := get_node_or_null(interactables_container)
	if container == null:
		return
	var chest: Node3D = preload("res://scenes/dungeons/dungeon_treasure_chest.tscn").instantiate()
	chest.position = room.get_world_center(_cell_size)
	container.add_child(chest)


func _spawn_elite(room: ReliquaryRoom) -> void:
	var container := get_node_or_null(enemies_container)
	if container == null:
		return
	var enemy: Node3D = ENEMY_SCENES["spore_brute"].instantiate()
	if enemy is EnemyBase:
		(enemy as EnemyBase).display_name = "Spore Brute Elite"
	enemy.position = room.get_world_center(_cell_size)
	container.add_child(enemy)


func _spawn_boss(room: ReliquaryRoom) -> void:
	var container := get_node_or_null(enemies_container)
	if container == null:
		return
	if ReliquaryState.boss_defeated_persistent:
		_spawn_exit(room)
		return
	var center := room.get_world_center(_cell_size)
	var boss_scene := preload("res://scenes/enemies/drowned_bellkeeper.tscn")
	_boss_node = boss_scene.instantiate()
	_boss_node.position = center
	if _boss_node.has_signal("enemy_died"):
		_boss_node.enemy_died.connect(_on_boss_died)
	container.add_child(_boss_node)
	_add_prop("statue_ring.glb", center + Vector3(0, 0, -4), 1.8)


func _spawn_exit(room: ReliquaryRoom) -> void:
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
	if ReliquaryState.boss_defeated_persistent:
		return
	LootManager.drop_loot_table("drowned_bellkeeper", _boss_node.global_position if _boss_node else Vector3.ZERO)
	if not InventoryManager.has_item("marsh_sigil"):
		InventoryManager.add_item("marsh_sigil", 1)
	if QuestManager.active_quests.has("depths_of_reliquary"):
		QuestManager.advance_objective("depths_of_reliquary", "defeat_bellkeeper", 1)
	DungeonManager.on_reliquary_boss_defeated()
	var layout: Dictionary = DungeonManager.layout
	for room in layout.get("rooms", []):
		if room is ReliquaryRoom and room.room_type == ReliquaryRoom.RoomType.BOSS:
			_spawn_exit(room)
			break


func _build_environment_lighting() -> void:
	var omni := OmniLight3D.new()
	omni.light_color = Color(0.4, 0.75, 0.85)
	omni.light_energy = 0.6
	omni.omni_range = 40.0
	omni.position = Vector3(20, 4, 5)
	add_child(omni)
