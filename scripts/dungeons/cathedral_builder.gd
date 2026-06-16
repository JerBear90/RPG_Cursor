extends Node3D
## Builds Blightspire Cathedral geometry, encounters, puzzle, and Heart Chamber boss.

signal build_completed

const _Kenney = preload("res://scripts/utilities/kenney_paths.gd")
const FLOOR_TILE := preload("res://scenes/dungeons/dungeon_floor_tile.tscn")
const _Room := preload("res://scripts/dungeons/cathedral_room.gd")
const _Checkpoint := preload("res://scripts/dungeons/cathedral_checkpoint.gd")
const _Trap := preload("res://scripts/dungeons/dungeon_trap.gd")
const _DiscoveryZone := preload("res://scripts/dungeons/room_discovery_zone.gd")
const _CathedralGenerator = preload("res://scripts/dungeons/cathedral_generator.gd")
const _PurificationPuzzle := preload("res://scripts/dungeons/purification_puzzle.gd")
const _BrazierSwitch := preload("res://scripts/dungeons/purification_brazier_switch.gd")
const _SealedHeartDoor := preload("res://scripts/dungeons/sealed_heart_door.gd")
const _QuestTrigger := preload("res://scripts/dungeons/cathedral_quest_trigger.gd")
const _SporeVent := preload("res://scripts/dungeons/cathedral_spore_vent.gd")
const _BellPulse := preload("res://scripts/dungeons/cathedral_bell_pulse.gd")

const ENEMY_SCENES := {
	"fungal_husk": preload("res://scenes/enemies/fungal_husk.tscn"),
	"sporecaster": preload("res://scenes/enemies/sporecaster.tscn"),
	"vine_stalker": preload("res://scenes/enemies/vine_stalker.tscn"),
	"corruption_wraith": preload("res://scenes/enemies/corruption_wraith.tscn"),
	"blighted_cleric": preload("res://scenes/enemies/blighted_cleric.tscn"),
	"rootbound_cathedral_guard": preload("res://scenes/enemies/rootbound_cathedral_guard.tscn"),
	"root_titan": preload("res://scenes/enemies/root_titan.tscn"),
}

@export var enemies_container: NodePath = NodePath("../Enemies")
@export var interactables_container: NodePath = NodePath("../Interactables")

var _cell_size: float = 2.0
var _exit_portal: DungeonExitPortal
var _build_complete: bool = false
var _nave_gate: StaticBody3D
var _depth: int = 0
var _boss_node: HeartOfBlight
var _puzzle_node: PurificationPuzzle


func _ready() -> void:
	add_to_group("dungeon_builder")
	call_deferred("_build")


func is_build_complete() -> bool:
	return _build_complete


func _build() -> void:
	var layout: Dictionary = DungeonManager.layout
	if layout.is_empty():
		layout = _CathedralGenerator.generate(DungeonManager.seed)
		DungeonManager.layout = layout
	_cell_size = layout.get("cell_size", _CathedralGenerator.CELL_SIZE)
	_depth = 0
	for room in layout.get("rooms", []):
		if room is CathedralRoom:
			if room.room_type != CathedralRoom.RoomType.PASSAGE:
				_depth += 1
			_build_room(room)
	_wire_puzzle_gate()
	if CathedralState.boss_defeated_persistent:
		for room in layout.get("rooms", []):
			if room is CathedralRoom and room.room_type == CathedralRoom.RoomType.EXIT_CLOISTER:
				_spawn_exit(room)
				break
	_build_environment_lighting()
	_build_complete = true
	build_completed.emit()


func _build_room(room: CathedralRoom) -> void:
	var origin := room.get_world_origin(_cell_size)
	var size := room.get_world_size(_cell_size)
	var overgrown := room.room_type in [
		CathedralRoom.RoomType.FUNGAL_CLOISTER, CathedralRoom.RoomType.ROOT_MAZE,
		CathedralRoom.RoomType.ROOTBOUND_NAVE, CathedralRoom.RoomType.COLLAPSED_TRANSEPT,
		CathedralRoom.RoomType.BLIGHTED_BAPTISTRY,
	]
	var tall_nave := room.room_type in [
		CathedralRoom.RoomType.ROOTBOUND_NAVE, CathedralRoom.RoomType.CENTRAL_NAVE,
		CathedralRoom.RoomType.CHOIR_APPROACH,
	]
	_fill_floor(origin, size, overgrown, tall_nave)
	if room.room_type == CathedralRoom.RoomType.PASSAGE:
		return
	_build_walls(origin, size, overgrown)
	_add_room_discovery(room, origin, size)
	match room.room_type:
		CathedralRoom.RoomType.ENTRANCE:
			_add_cathedral_entrance(origin, size)
		CathedralRoom.RoomType.ROOTBOUND_NAVE, CathedralRoom.RoomType.COLLAPSED_TRANSEPT:
			_spawn_combat(room, _depth, "entrance")
			_add_nave_props(origin, size)
		CathedralRoom.RoomType.FUNGAL_CLOISTER, CathedralRoom.RoomType.CORRUPTED_LIBRARY:
			_spawn_combat(room, _depth, "cloister")
			_add_cloister_props(origin, size)
			_spawn_spore_vents(room, "library" if room.room_type == CathedralRoom.RoomType.CORRUPTED_LIBRARY else "cloister")
		CathedralRoom.RoomType.BLIGHTED_BAPTISTRY:
			_spawn_combat(room, _depth, "purification")
			_add_prop("platform_stone.glb", origin + Vector3(size.x * 0.5, 0, size.z * 0.5), 1.1)
			_add_prop("statue_block.glb", origin + Vector3(size.x * 0.5, 0, size.z * 0.3), 0.9)
		CathedralRoom.RoomType.ROOT_MAZE, CathedralRoom.RoomType.BLIGHTED_BELL_HALL:
			_spawn_combat(room, _depth, "maze" if room.room_type == CathedralRoom.RoomType.ROOT_MAZE else "bell")
			if room.room_type == CathedralRoom.RoomType.ROOT_MAZE:
				_spawn_root_traps(room)
			else:
				_spawn_bell_pulse(room)
		CathedralRoom.RoomType.BELL_TOWER_INTERIOR:
			_add_prop("statue_column.glb", origin + Vector3(size.x * 0.5, 0, size.z * 0.4), 1.3)
			_add_prop("plant_bushLarge.glb", origin + Vector3(size.x * 0.3, 0, size.z * 0.6), 1.0)
		CathedralRoom.RoomType.CHECKPOINT:
			_spawn_checkpoint(room)
		CathedralRoom.RoomType.PURIFICATION_CHAMBER:
			_spawn_puzzle(room)
		CathedralRoom.RoomType.RESOURCE_CRYPT:
			_spawn_resource(room)
		CathedralRoom.RoomType.ELITE_GUARDIAN_CHAPEL:
			_spawn_elite(room)
		CathedralRoom.RoomType.CENTRAL_NAVE:
			_spawn_central_nave(room)
		CathedralRoom.RoomType.CHOIR_APPROACH:
			_spawn_choir_approach(room)
		CathedralRoom.RoomType.BOSS_ANTECHAMBER:
			_spawn_antechamber(room)
		CathedralRoom.RoomType.HEART_CHAMBER:
			_spawn_heart_chamber(room)
		CathedralRoom.RoomType.EXIT_CLOISTER:
			pass


func _fill_floor(origin: Vector3, size: Vector3, overgrown: bool, tall: bool = false) -> void:
	var cols := int(size.x / _cell_size)
	var rows := int(size.z / _cell_size)
	for x in cols:
		for z in rows:
			var tile: Node3D = FLOOR_TILE.instantiate()
			tile.position = origin + Vector3(x * _cell_size + _cell_size * 0.5, 0, z * _cell_size + _cell_size * 0.5)
			for child in tile.get_children():
				if child is MeshInstance3D:
					var mat := StandardMaterial3D.new()
					if overgrown:
						mat.albedo_color = Color(0.1, 0.15, 0.09)
						mat.emission = Color(0.2, 0.48, 0.26)
						mat.emission_energy_multiplier = 0.2
					elif tall:
						mat.albedo_color = Color(0.13, 0.11, 0.15)
						mat.emission = Color(0.38, 0.22, 0.48)
						mat.emission_energy_multiplier = 0.16
					else:
						mat.albedo_color = Color(0.14, 0.12, 0.16)
						mat.emission = Color(0.32, 0.2, 0.4)
						mat.emission_energy_multiplier = 0.14
					mat.roughness = 0.72
					mat.metallic = 0.08
					mat.emission_enabled = true
					(child as MeshInstance3D).material_override = mat
			add_child(tile)


func _build_walls(origin: Vector3, size: Vector3, overgrown: bool) -> void:
	var wall_path := _Kenney.nature("cliff_block_rock.glb")
	var cols := int(size.x / _cell_size)
	var rows := int(size.z / _cell_size)
	for x in cols:
		var px := origin.x + x * _cell_size + _cell_size * 0.5
		_add_wall(wall_path, Vector3(px, 0, origin.z - _cell_size * 0.25), overgrown)
		_add_wall(wall_path, Vector3(px, 0, origin.z + size.z + _cell_size * 0.25), overgrown)
	for z in rows:
		var pz := origin.z + z * _cell_size + _cell_size * 0.5
		_add_wall(wall_path, Vector3(origin.x - _cell_size * 0.25, 0, pz), overgrown)
		_add_wall(wall_path, Vector3(origin.x + size.x + _cell_size * 0.25, 0, pz), overgrown)


func _add_wall(path: String, pos: Vector3, overgrown: bool) -> void:
	var holder := Node3D.new()
	holder.position = pos
	add_child(holder)
	MeshLoader.instantiate(path, holder, 0.0, Vector3.ZERO, Vector3(2.0, 2.8, 2.0))
	if overgrown and randf() > 0.45:
		_add_prop("plant_bushDetailed.glb", pos + Vector3(0, 0, 0.4), 0.7)
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


func _add_cathedral_entrance(origin: Vector3, size: Vector3) -> void:
	_add_prop("fence_gate.glb", origin + Vector3(size.x * 0.5, 0, 1.5), 1.0)
	_add_prop("statue_columnDamaged.glb", origin + Vector3(2, 0, 2), 1.2)
	_add_prop("statue_columnDamaged.glb", origin + Vector3(size.x - 2, 0, 2), 1.2)
	_add_prop("plant_bushLarge.glb", origin + Vector3(size.x * 0.5, 0, size.z - 2), 0.9)
	if not CathedralState.brazier_a:
		_add_root_barrier(origin + Vector3(size.x * 0.5, 0, size.z - 3), "cathedral_root_barrier_a")


func _add_nave_props(origin: Vector3, size: Vector3) -> void:
	_add_prop("statue_columnDamaged.glb", origin + Vector3(size.x * 0.3, 0, size.z * 0.4), 1.1)
	_add_prop("statue_columnDamaged.glb", origin + Vector3(size.x * 0.7, 0, size.z * 0.35), 1.0)
	_add_prop("mushroom_red.glb", origin + Vector3(size.x * 0.5, 0, size.z * 0.55), 0.85)
	_add_prop("plant_bushLarge.glb", origin + Vector3(size.x * 0.15, 0, size.z * 0.2), 0.95)


func _add_cloister_props(origin: Vector3, size: Vector3) -> void:
	_add_prop("mushroom_tan.glb", origin + Vector3(3, 0, 3), 0.9)
	_add_prop("plant_bushDetailed.glb", origin + Vector3(size.x - 3, 0, size.z - 3), 0.9)
	_add_prop("statue_block.glb", origin + Vector3(size.x * 0.5, 0, size.z * 0.25), 1.0)


func _add_root_barrier(pos: Vector3, group_name: String) -> void:
	if group_name == "cathedral_root_barrier_a" and CathedralState.brazier_a:
		return
	if group_name == "cathedral_root_barrier_b" and CathedralState.brazier_b:
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
	_add_prop("plant_bushLarge.glb", pos + Vector3(-1.2, 0, 0), 1.1)
	_add_prop("plant_bushLarge.glb", pos + Vector3(1.2, 0, 0), 1.1)


func _add_room_discovery(room: CathedralRoom, origin: Vector3, size: Vector3) -> void:
	var zone := _DiscoveryZone.new()
	zone.name = "RoomDiscovery_%d" % room.room_index
	zone.room_index = room.room_index
	zone.set_meta("cathedral_room", true)
	zone.position = origin + Vector3(size.x * 0.5, 0.5, size.z * 0.5)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(size.x * 0.85, 2.5, size.z * 0.85)
	col.shape = shape
	zone.add_child(col)
	add_child(zone)


func _spawn_combat(room: CathedralRoom, depth: int, zone: String) -> void:
	var container := get_node_or_null(enemies_container)
	if container == null or room.enemy_count <= 0:
		return
	var center := room.get_world_center(_cell_size)
	var keys: Array[String] = []
	match zone:
		"entrance":
			keys = ["fungal_husk", "rootbound_cathedral_guard"]
		"cloister":
			keys = ["sporecaster", "vine_stalker", "vine_stalker"]
		"purification":
			keys = ["fungal_husk", "rootbound_cathedral_guard", "sporecaster"]
		"maze":
			keys = ["vine_stalker", "sporecaster", "fungal_husk"]
		"bell":
			keys = ["corruption_wraith", "blighted_cleric"]
		"nave":
			keys = ["rootbound_cathedral_guard", "blighted_cleric", "fungal_husk"]
		"choir":
			keys = ["rootbound_cathedral_guard", "blighted_cleric"]
		_:
			if depth <= 4:
				keys = ["fungal_husk", "rootbound_cathedral_guard"]
			else:
				keys = ["blighted_cleric", "corruption_wraith", "rootbound_cathedral_guard"]
	var count := maxi(room.enemy_count, 1)
	for i in count:
		var key: String = keys[i % keys.size()]
		var enemy: Node3D = ENEMY_SCENES[key].instantiate()
		enemy.position = center + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
		container.add_child(enemy)


func _spawn_spore_vents(room: CathedralRoom, vent_id: String) -> void:
	if CathedralState.brazier_b:
		return
	var container := get_node_or_null(interactables_container)
	if container == null:
		return
	var center := room.get_world_center(_cell_size)
	for i in 2:
		var vent := _SporeVent.new()
		vent.vent_id = vent_id
		vent.position = center + Vector3(-2.5 + i * 5, 0.2, 1.5)
		container.add_child(vent)


func _spawn_bell_pulse(room: CathedralRoom) -> void:
	var container := get_node_or_null(interactables_container)
	if container == null:
		return
	var pulse := _BellPulse.new()
	pulse.position = room.get_world_center(_cell_size) + Vector3(0, 2.5, 0)
	container.add_child(pulse)
	_add_prop("statue_column.glb", room.get_world_center(_cell_size) + Vector3(-2, 0, -2), 1.3)


func _spawn_root_traps(room: CathedralRoom) -> void:
	var container := get_node_or_null(interactables_container)
	if container == null:
		return
	var center := room.get_world_center(_cell_size)
	for i in 2:
		var trap := _Trap.new()
		trap.position = center + Vector3(-2 + i * 4, 0.1, 1)
		trap.poison = true
		container.add_child(trap)


func _spawn_checkpoint(room: CathedralRoom) -> void:
	var container := get_node_or_null(interactables_container)
	if container == null:
		return
	var shrine := _Checkpoint.new()
	shrine.position = room.get_world_center(_cell_size)
	shrine.set_meta("room_index", room.room_index)
	container.add_child(shrine)
	_add_prop("campfire_bricks.glb", shrine.position + Vector3(-2, 0, 0), 0.9)
	_add_prop("statue_columnDamaged.glb", shrine.position + Vector3(2, 0, 1), 1.0)
	_add_prop("mushroom_red.glb", shrine.position + Vector3(0, 0, -2), 0.8)


func _spawn_puzzle(room: CathedralRoom) -> void:
	var container := get_node_or_null(interactables_container)
	if container == null:
		return
	var center := room.get_world_center(_cell_size)
	_puzzle_node = _PurificationPuzzle.new()
	_puzzle_node.name = "PurificationPuzzle"
	_puzzle_node.position = center
	container.add_child(_puzzle_node)
	var ids := ["brazier_a", "brazier_b", "brazier_c"]
	for i in 3:
		var sw := _BrazierSwitch.new()
		sw.brazier_id = ids[i]
		sw.position = center + Vector3(-4.5 + i * 4.5, 0, -2)
		sw.controller_path = _puzzle_node.get_path()
		sw.add_to_group("purification_brazier_switch")
		container.add_child(sw)
		_add_prop("campfire_bricks.glb", sw.position, 0.85)
	if not CathedralState.brazier_b:
		_add_root_barrier(center + Vector3(0, 0, 4), "cathedral_root_barrier_b")


func _spawn_nave_gate(room: CathedralRoom) -> void:
	if CathedralState.brazier_c or CathedralState.retracted_roots:
		return
	var container := get_node_or_null(interactables_container)
	if container == null:
		return
	var center := room.get_world_center(_cell_size)
	_nave_gate = StaticBody3D.new()
	_nave_gate.name = "CentralNaveRootGate"
	_nave_gate.add_to_group("central_nave_root_gate")
	_nave_gate.position = center + Vector3(0, 0, -4.5)
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(6, 3.5, 1.2)
	col.shape = box
	col.position = Vector3(0, 1.75, 0)
	_nave_gate.add_child(col)
	container.add_child(_nave_gate)
	_add_prop("plant_bushLarge.glb", _nave_gate.position + Vector3(-1.5, 0, 0), 1.2)
	_add_prop("plant_bushLarge.glb", _nave_gate.position + Vector3(1.5, 0, 0), 1.2)
	_add_prop("mushroom_tan.glb", _nave_gate.position + Vector3(0, 0, 0.3), 1.0)


func _wire_puzzle_gate() -> void:
	if _puzzle_node == null:
		return
	if is_instance_valid(_nave_gate):
		_puzzle_node.gate_node_path = _nave_gate.get_path()


func _spawn_resource(room: CathedralRoom) -> void:
	var container := get_node_or_null(interactables_container)
	if container == null:
		return
	var chest: Node3D = preload("res://scenes/dungeons/dungeon_treasure_chest.tscn").instantiate()
	chest.position = room.get_world_center(_cell_size)
	container.add_child(chest)
	_add_prop("statue_block.glb", chest.position + Vector3(-2, 0, 1), 0.85)


func _spawn_elite(room: CathedralRoom) -> void:
	var container := get_node_or_null(enemies_container)
	if container == null:
		return
	var center := room.get_world_center(_cell_size)
	var titan: Node3D = ENEMY_SCENES["root_titan"].instantiate()
	titan.position = center + Vector3(0, 0, 0)
	container.add_child(titan)
	var guard: Node3D = ENEMY_SCENES["rootbound_cathedral_guard"].instantiate()
	guard.position = center + Vector3(-3, 0, 2)
	container.add_child(guard)
	_add_prop("statue_column.glb", center + Vector3(0, 0, -2), 1.2)
	_add_prop("mushroom_red.glb", center + Vector3(-3, 0, 3), 0.9)


func _spawn_central_nave(room: CathedralRoom) -> void:
	var center := room.get_world_center(_cell_size)
	_spawn_nave_gate(room)
	_spawn_combat(room, _depth, "nave")
	_add_prop("platform_stone.glb", center, 1.5)
	_add_prop("statue_columnDamaged.glb", center + Vector3(-4, 0, 2), 1.2)
	_add_prop("statue_columnDamaged.glb", center + Vector3(4, 0, 2), 1.2)
	_add_prop("statue_columnDamaged.glb", center + Vector3(-4, 0, -2), 1.1)
	_add_prop("statue_columnDamaged.glb", center + Vector3(4, 0, -2), 1.1)
	var trigger := _QuestTrigger.new()
	trigger.position = center
	trigger.objective_id = "reach_nave"
	add_child(trigger)


func _spawn_choir_approach(room: CathedralRoom) -> void:
	var center := room.get_world_center(_cell_size)
	_spawn_combat(room, _depth, "choir")
	_add_prop("platform_stone.glb", center + Vector3(0, 0, 1), 1.3)
	_add_prop("statue_column.glb", center + Vector3(-3, 0, 0), 1.2)
	_add_prop("statue_column.glb", center + Vector3(3, 0, 0), 1.2)


func _spawn_antechamber(room: CathedralRoom) -> void:
	var center := room.get_world_center(_cell_size)
	_add_prop("statue_column.glb", center + Vector3(-3, 0, 0), 1.2)
	_add_prop("statue_column.glb", center + Vector3(3, 0, 0), 1.2)
	_add_prop("platform_stone.glb", center + Vector3(0, 0, 2), 1.5)
	var trigger := _QuestTrigger.new()
	trigger.position = center
	trigger.objective_id = "prepare_boss"
	add_child(trigger)
	var container := get_node_or_null(enemies_container)
	if container and room.enemy_count > 0:
		var titan: Node3D = ENEMY_SCENES["root_titan"].instantiate()
		titan.position = center + Vector3(0, 0, 1)
		container.add_child(titan)
		var cleric: Node3D = ENEMY_SCENES["blighted_cleric"].instantiate()
		cleric.position = center + Vector3(3, 0, -1)
		container.add_child(cleric)


func _spawn_heart_chamber(room: CathedralRoom) -> void:
	var container := get_node_or_null(interactables_container)
	if container == null:
		return
	var center := room.get_world_center(_cell_size)
	var door := _SealedHeartDoor.new()
	door.position = center + Vector3(0, 0, -5)
	container.add_child(door)
	if not CathedralState.puzzle_completed and not CathedralState.retracted_roots:
		var root_wall := StaticBody3D.new()
		root_wall.name = "HeartChamberRootWall"
		root_wall.position = center + Vector3(0, 0, -4.5)
		var rw_col := CollisionShape3D.new()
		var rw_box := BoxShape3D.new()
		rw_box.size = Vector3(8, 3.5, 1.0)
		rw_col.shape = rw_box
		rw_col.position = Vector3(0, 1.75, 0)
		root_wall.add_child(rw_col)
		container.add_child(root_wall)
		_add_prop("plant_bushLarge.glb", root_wall.position + Vector3(-2, 0, 0), 1.2)
		_add_prop("plant_bushLarge.glb", root_wall.position + Vector3(2, 0, 0), 1.2)
	_add_prop("plant_bushLarge.glb", center + Vector3(-3, 0, 4), 1.3)
	_add_prop("plant_bushLarge.glb", center + Vector3(3, 0, 4), 1.3)
	_add_prop("statue_block.glb", center + Vector3(0, 0, -2), 1.3)
	_add_prop("statue_columnDamaged.glb", center + Vector3(-4, 0, 2), 1.1)
	_add_prop("statue_columnDamaged.glb", center + Vector3(4, 0, 2), 1.1)
	if CathedralState.boss_defeated_persistent:
		return
	var enemy_container := get_node_or_null(enemies_container)
	if enemy_container == null:
		return
	var boss_scene := preload("res://scenes/enemies/bosses/heart_of_blight.tscn")
	_boss_node = boss_scene.instantiate()
	_boss_node.name = "HeartOfBlight"
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
	_add_prop("platform_stone.glb", center + Vector3(0, 0, 0), 2.0)
	if not CathedralState.brazier_b:
		var hazard_lane := StaticBody3D.new()
		hazard_lane.name = "BossHazardLane"
		hazard_lane.add_to_group("boss_hazard_lane")
		hazard_lane.position = center + Vector3(3.5, 0, 0)
		var hcol := CollisionShape3D.new()
		var hbox := BoxShape3D.new()
		hbox.size = Vector3(1.2, 0.3, 8)
		hcol.shape = hbox
		hazard_lane.add_child(hcol)
		var trap := _Trap.new()
		trap.position = hazard_lane.position + Vector3(0, 0.1, 0)
		trap.poison = true
		add_child(hazard_lane)
		container.add_child(trap)


func _on_boss_died(_enemy: EnemyBase) -> void:
	GameManager.in_boss_fight = false
	if CathedralState.boss_defeated_persistent:
		return
	var drop_pos := _boss_node.global_position if _boss_node else Vector3.ZERO
	LootManager.drop_loot_table("blightheart", drop_pos)
	if not InventoryManager.has_item("blightheart_core"):
		InventoryManager.add_item("blightheart_core", 1)
	if not InventoryManager.has_item("purifiers_thorn"):
		InventoryManager.add_item("purifiers_thorn", 1)
	if not InventoryManager.has_item("ember_wastes_pass"):
		InventoryManager.add_item("ember_wastes_pass", 1)
	if QuestManager.active_quests.has("heart_of_the_blight"):
		QuestManager.advance_objective("heart_of_the_blight", "defeat_blightheart", 1)
		QuestManager.advance_objective("heart_of_the_blight", "recover_blightheart_core", 1)
		QuestManager.advance_objective("heart_of_the_blight", "purify_blightspire", 1)
	DungeonManager.on_cathedral_boss_defeated()
	var layout: Dictionary = DungeonManager.layout
	for r in layout.get("rooms", []):
		if r is CathedralRoom and r.room_type == CathedralRoom.RoomType.EXIT_CLOISTER:
			_spawn_exit(r)
			break


func _spawn_exit(room: CathedralRoom) -> void:
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
	if DungeonManager.boss_defeated or CathedralState.boss_defeated_persistent:
		_exit_portal.reveal()
	_add_prop("fence_gate.glb", center + Vector3(-2, 0, 0), 1.0)
	_add_prop("plant_bushDetailed.glb", center + Vector3(0, 0, -2), 0.9)


func _build_environment_lighting() -> void:
	var green := OmniLight3D.new()
	green.light_color = Color(0.42, 0.72, 0.38)
	green.light_energy = 0.55
	green.omni_range = 80.0
	green.position = Vector3(100, 8, 5)
	add_child(green)
	var violet := OmniLight3D.new()
	violet.light_color = Color(0.55, 0.28, 0.62)
	violet.light_energy = 0.38
	violet.omni_range = 65.0
	violet.position = Vector3(180, 5, 8)
	add_child(violet)
	var amber := OmniLight3D.new()
	amber.light_color = Color(0.92, 0.62, 0.28)
	amber.light_energy = 0.22
	amber.omni_range = 35.0
	amber.position = Vector3(60, 4, 3)
	add_child(amber)
