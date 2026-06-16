extends Node3D
## Builds Eclipse Sanctum geometry, encounters, ward puzzle, and sealed throne.

signal build_completed

const _Kenney = preload("res://scripts/utilities/kenney_paths.gd")
const FLOOR_TILE := preload("res://scenes/dungeons/dungeon_floor_tile.tscn")
const _Room := preload("res://scripts/dungeons/eclipse_sanctum_room.gd")
const _Checkpoint := preload("res://scripts/dungeons/eclipse_checkpoint.gd")
const _Trap := preload("res://scripts/dungeons/dungeon_trap.gd")
const _DiscoveryZone := preload("res://scripts/dungeons/room_discovery_zone.gd")
const _EclipseGenerator = preload("res://scripts/dungeons/eclipse_generator.gd")
const _ShadowPuzzle := preload("res://scripts/dungeons/shadow_mirror_puzzle.gd")
const _ShadowSwitch := preload("res://scripts/dungeons/shadow_mirror_switch.gd")
const _SealedThroneDoor := preload("res://scripts/dungeons/sealed_eclipse_throne_door.gd")
const _QuestTrigger := preload("res://scripts/dungeons/cathedral_quest_trigger.gd")

const ENEMY_SCENES := {
	"gloom_hound": preload("res://scenes/enemies/gloom_hound.tscn"),
	"nightbound_raider": preload("res://scenes/enemies/nightbound_raider.tscn"),
	"nightbound_raider_archer": preload("res://scenes/enemies/nightbound_raider_archer.tscn"),
	"nightbound_raider_bomber": preload("res://scenes/enemies/nightbound_raider_bomber.tscn"),
	"hollow_knight": preload("res://scenes/enemies/hollow_knight.tscn"),
	"eclipse_cultist": preload("res://scenes/enemies/eclipse_cultist.tscn"),
	"grave_wraith": preload("res://scenes/enemies/grave_wraith.tscn"),
	"shadow_stalker": preload("res://scenes/enemies/shadow_stalker.tscn"),
}

@export var enemies_container: NodePath = NodePath("../Enemies")
@export var interactables_container: NodePath = NodePath("../Interactables")

var _cell_size: float = 2.0
var _exit_portal: DungeonExitPortal
var _build_complete: bool = false
var _spire_gate: StaticBody3D
var _throne_wall: StaticBody3D
var _depth: int = 0
var _puzzle_node: ShadowMirrorPuzzle


func _ready() -> void:
	add_to_group("dungeon_builder")
	add_to_group("eclipse_builder")
	if not QuestManager.quest_completed.is_connected(_on_quest_completed):
		QuestManager.quest_completed.connect(_on_quest_completed)
	call_deferred("_build")


func _on_quest_completed(quest_id: String) -> void:
	if quest_id == "throne_beneath_the_eclipse":
		reveal_exit()


func is_build_complete() -> bool:
	return _build_complete


func reveal_exit() -> void:
	var layout: Dictionary = DungeonManager.layout
	for r in layout.get("rooms", []):
		if r is EclipseSanctumRoom and r.room_type == EclipseSanctumRoom.RoomType.EXIT_TERRACE:
			_spawn_exit(r)
			break


func unlock_throne_approach() -> void:
	if is_instance_valid(_throne_wall):
		_throne_wall.queue_free()
		_throne_wall = null


func _build() -> void:
	var layout: Dictionary = DungeonManager.layout
	if layout.is_empty():
		layout = _EclipseGenerator.generate(DungeonManager.seed)
		DungeonManager.layout = layout
	_cell_size = layout.get("cell_size", _EclipseGenerator.CELL_SIZE)
	_depth = 0
	for room in layout.get("rooms", []):
		if room is EclipseSanctumRoom:
			if room.room_type != EclipseSanctumRoom.RoomType.PASSAGE:
				_depth += 1
			_build_room(room)
	_wire_puzzle_gate()
	if EclipseSanctumState.puzzle_completed or EclipseSanctumState.wards_active:
		unlock_throne_approach()
	_build_environment_lighting()
	_build_complete = true
	build_completed.emit()


func _build_room(room: EclipseSanctumRoom) -> void:
	var origin := room.get_world_origin(_cell_size)
	var size := room.get_world_size(_cell_size)
	var shadowed := room.room_type in [
		EclipseSanctumRoom.RoomType.MOON_CLOISTER, EclipseSanctumRoom.RoomType.DREAD_MAZE,
		EclipseSanctumRoom.RoomType.SHADOW_NAVE, EclipseSanctumRoom.RoomType.ELITE_SHADOW_CHAPEL,
	]
	var tall_spire := room.room_type in [
		EclipseSanctumRoom.RoomType.SHADOW_NAVE, EclipseSanctumRoom.RoomType.CENTRAL_SPIRE,
		EclipseSanctumRoom.RoomType.ASCENT_APPROACH,
	]
	_fill_floor(origin, size, shadowed, tall_spire)
	if room.room_type == EclipseSanctumRoom.RoomType.PASSAGE:
		return
	_build_walls(origin, size, shadowed)
	_add_room_discovery(room, origin, size)
	match room.room_type:
		EclipseSanctumRoom.RoomType.ENTRANCE:
			_add_entrance_props(origin, size)
		EclipseSanctumRoom.RoomType.SHADOW_NAVE, EclipseSanctumRoom.RoomType.MOON_CLOISTER:
			_spawn_combat(room, _depth, "entrance")
			_add_nave_props(origin, size)
		EclipseSanctumRoom.RoomType.BURIED_ARCHIVE:
			_spawn_combat(room, _depth, "cloister")
			_add_cloister_props(origin, size)
		EclipseSanctumRoom.RoomType.DREAD_MAZE, EclipseSanctumRoom.RoomType.OBSERVATORY_HALL:
			_spawn_combat(room, _depth, "maze" if room.room_type == EclipseSanctumRoom.RoomType.DREAD_MAZE else "observatory")
			if room.room_type == EclipseSanctumRoom.RoomType.DREAD_MAZE:
				_spawn_shadow_traps(room)
		EclipseSanctumRoom.RoomType.CHECKPOINT:
			_spawn_checkpoint(room)
		EclipseSanctumRoom.RoomType.WARD_CHAMBER:
			_spawn_puzzle(room)
		EclipseSanctumRoom.RoomType.RESOURCE_VAULT:
			_spawn_resource(room)
		EclipseSanctumRoom.RoomType.ELITE_SHADOW_CHAPEL:
			_spawn_elite(room)
		EclipseSanctumRoom.RoomType.CENTRAL_SPIRE:
			_spawn_central_spire(room)
		EclipseSanctumRoom.RoomType.ASCENT_APPROACH:
			_spawn_ascent(room)
		EclipseSanctumRoom.RoomType.ECLIPSE_ANTECHAMBER:
			_spawn_antechamber(room)
		EclipseSanctumRoom.RoomType.SEALED_THRONE_CHAMBER:
			_spawn_sealed_throne(room)
		EclipseSanctumRoom.RoomType.EXIT_TERRACE:
			if QuestManager.completed_quests.has("throne_beneath_the_eclipse"):
				_spawn_exit(room)


func _fill_floor(origin: Vector3, size: Vector3, shadowed: bool, tall: bool = false) -> void:
	var cols := int(size.x / _cell_size)
	var rows := int(size.z / _cell_size)
	for x in cols:
		for z in rows:
			var tile: Node3D = FLOOR_TILE.instantiate()
			tile.position = origin + Vector3(x * _cell_size + _cell_size * 0.5, 0, z * _cell_size + _cell_size * 0.5)
			for child in tile.get_children():
				if child is MeshInstance3D:
					var mat := StandardMaterial3D.new()
					if shadowed:
						mat.albedo_color = Color(0.12, 0.1, 0.18)
						mat.emission = Color(0.28, 0.22, 0.55)
						mat.emission_energy_multiplier = 0.16
					elif tall:
						mat.albedo_color = Color(0.1, 0.08, 0.14)
						mat.emission = Color(0.35, 0.28, 0.62)
						mat.emission_energy_multiplier = 0.18
					else:
						mat.albedo_color = Color(0.14, 0.11, 0.2)
						mat.emission = Color(0.22, 0.18, 0.48)
						mat.emission_energy_multiplier = 0.12
					mat.roughness = 0.82
					mat.metallic = 0.08
					mat.emission_enabled = true
					(child as MeshInstance3D).material_override = mat
			add_child(tile)


func _build_walls(origin: Vector3, size: Vector3, shadowed: bool) -> void:
	var wall_path := _Kenney.nature("cliff_block_rock.glb")
	var cols := int(size.x / _cell_size)
	var rows := int(size.z / _cell_size)
	for x in cols:
		var px := origin.x + x * _cell_size + _cell_size * 0.5
		_add_wall(wall_path, Vector3(px, 0, origin.z - _cell_size * 0.25), shadowed)
		_add_wall(wall_path, Vector3(px, 0, origin.z + size.z + _cell_size * 0.25), shadowed)
	for z in rows:
		var pz := origin.z + z * _cell_size + _cell_size * 0.5
		_add_wall(wall_path, Vector3(origin.x - _cell_size * 0.25, 0, pz), shadowed)
		_add_wall(wall_path, Vector3(origin.x + size.x + _cell_size * 0.25, 0, pz), shadowed)


func _add_wall(path: String, pos: Vector3, shadowed: bool) -> void:
	var holder := Node3D.new()
	holder.position = pos
	add_child(holder)
	MeshLoader.instantiate(path, holder, 0.0, Vector3.ZERO, Vector3(2.0, 2.8, 2.0))
	if shadowed and randf() > 0.5:
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
	_add_prop("statue_columnDamaged.glb", origin + Vector3(2, 0, 2), 1.2)
	_add_prop("statue_columnDamaged.glb", origin + Vector3(size.x - 2, 0, 2), 1.2)
	if not EclipseSanctumState.ward_a:
		_add_shadow_barrier(origin + Vector3(size.x * 0.5, 0, size.z - 3), "eclipse_shadow_barrier_a")


func _add_nave_props(origin: Vector3, size: Vector3) -> void:
	_add_prop("statue_columnDamaged.glb", origin + Vector3(size.x * 0.3, 0, size.z * 0.4), 1.1)
	_add_prop("statue_block.glb", origin + Vector3(size.x * 0.7, 0, size.z * 0.35), 1.0)


func _add_cloister_props(origin: Vector3, size: Vector3) -> void:
	_add_prop("rock_smallA.glb", origin + Vector3(3, 0, 3), 0.9)
	_add_prop("statue_block.glb", origin + Vector3(size.x - 3, 0, size.z - 3), 0.9)


func _add_shadow_barrier(pos: Vector3, group_name: String) -> void:
	if group_name == "eclipse_shadow_barrier_a" and EclipseSanctumState.ward_a:
		return
	if group_name == "eclipse_shadow_barrier_b" and EclipseSanctumState.ward_b:
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


func _add_room_discovery(room: EclipseSanctumRoom, origin: Vector3, size: Vector3) -> void:
	var zone := _DiscoveryZone.new()
	zone.name = "RoomDiscovery_%d" % room.room_index
	zone.room_index = room.room_index
	zone.set_meta("eclipse_room", true)
	zone.position = origin + Vector3(size.x * 0.5, 0.5, size.z * 0.5)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(size.x * 0.85, 2.5, size.z * 0.85)
	col.shape = shape
	zone.add_child(col)
	add_child(zone)


func _spawn_combat(room: EclipseSanctumRoom, depth: int, zone: String) -> void:
	var container := get_node_or_null(enemies_container)
	if container == null or room.enemy_count <= 0:
		return
	var center := room.get_world_center(_cell_size)
	var keys: Array[String] = []
	match zone:
		"entrance":
			keys = ["gloom_hound", "nightbound_raider"]
		"cloister":
			keys = ["nightbound_raider_archer", "grave_wraith"]
		"maze":
			keys = ["shadow_stalker", "grave_wraith", "gloom_hound"]
		"observatory":
			keys = ["eclipse_cultist", "shadow_stalker"]
		"spire":
			keys = ["nightbound_raider", "eclipse_cultist", "hollow_knight"]
		"ascent":
			keys = ["nightbound_raider_bomber", "eclipse_cultist"]
		_:
			if depth <= 4:
				keys = ["gloom_hound", "nightbound_raider"]
			else:
				keys = ["eclipse_cultist", "shadow_stalker", "hollow_knight"]
	var count := maxi(room.enemy_count, 1)
	for i in count:
		var key: String = keys[i % keys.size()]
		var enemy: Node3D = ENEMY_SCENES[key].instantiate()
		enemy.position = center + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
		container.add_child(enemy)


func _spawn_shadow_traps(room: EclipseSanctumRoom) -> void:
	var container := get_node_or_null(interactables_container)
	if container == null:
		return
	var center := room.get_world_center(_cell_size)
	for i in 2:
		var trap := _Trap.new()
		trap.position = center + Vector3(-2 + i * 4, 0.1, 1)
		container.add_child(trap)


func _spawn_checkpoint(room: EclipseSanctumRoom) -> void:
	var container := get_node_or_null(interactables_container)
	if container == null:
		return
	var shrine := _Checkpoint.new()
	shrine.position = room.get_world_center(_cell_size)
	shrine.set_meta("room_index", room.room_index)
	container.add_child(shrine)
	_add_prop("campfire_bricks.glb", shrine.position + Vector3(-2, 0, 0), 0.9)
	_add_prop("statue_columnDamaged.glb", shrine.position + Vector3(2, 0, 1), 1.0)


func _spawn_puzzle(room: EclipseSanctumRoom) -> void:
	var container := get_node_or_null(interactables_container)
	if container == null:
		return
	var center := room.get_world_center(_cell_size)
	_puzzle_node = _ShadowPuzzle.new()
	_puzzle_node.name = "ShadowMirrorPuzzle"
	_puzzle_node.position = center
	container.add_child(_puzzle_node)
	var ids := ["ward_a", "ward_b", "ward_c"]
	for i in 3:
		var sw := _ShadowSwitch.new()
		sw.ward_id = ids[i]
		sw.position = center + Vector3(-4.5 + i * 4.5, 0, -2)
		sw.controller_path = _puzzle_node.get_path()
		sw.add_to_group("shadow_mirror_switch")
		container.add_child(sw)
		_add_prop("statue_block.glb", sw.position, 0.85)
	if not EclipseSanctumState.ward_b:
		_add_shadow_barrier(center + Vector3(0, 0, 4), "eclipse_shadow_barrier_b")


func _spawn_spire_gate(room: EclipseSanctumRoom) -> void:
	if EclipseSanctumState.ward_c or EclipseSanctumState.wards_active:
		return
	var container := get_node_or_null(interactables_container)
	if container == null:
		return
	var center := room.get_world_center(_cell_size)
	_spire_gate = StaticBody3D.new()
	_spire_gate.name = "CentralSpireShadowGate"
	_spire_gate.add_to_group("central_spire_shadow_gate")
	_spire_gate.position = center + Vector3(0, 0, -4.5)
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(6, 3.5, 1.2)
	col.shape = box
	col.position = Vector3(0, 1.75, 0)
	_spire_gate.add_child(col)
	container.add_child(_spire_gate)


func _wire_puzzle_gate() -> void:
	if _puzzle_node == null:
		return
	if is_instance_valid(_spire_gate):
		_puzzle_node.gate_node_path = _spire_gate.get_path()


func _spawn_resource(room: EclipseSanctumRoom) -> void:
	var container := get_node_or_null(interactables_container)
	if container == null:
		return
	var chest: Node3D = preload("res://scenes/dungeons/dungeon_treasure_chest.tscn").instantiate()
	chest.position = room.get_world_center(_cell_size)
	container.add_child(chest)


func _spawn_elite(room: EclipseSanctumRoom) -> void:
	var container := get_node_or_null(enemies_container)
	if container == null:
		return
	var center := room.get_world_center(_cell_size)
	var knight: Node3D = ENEMY_SCENES["hollow_knight"].instantiate()
	knight.position = center
	container.add_child(knight)
	var cultist: Node3D = ENEMY_SCENES["eclipse_cultist"].instantiate()
	cultist.position = center + Vector3(-3, 0, 2)
	container.add_child(cultist)


func _spawn_central_spire(room: EclipseSanctumRoom) -> void:
	var center := room.get_world_center(_cell_size)
	_spawn_spire_gate(room)
	_spawn_combat(room, _depth, "spire")
	_add_prop("platform_stone.glb", center, 1.5)
	_add_prop("statue_columnDamaged.glb", center + Vector3(-4, 0, 2), 1.2)
	var trigger := _QuestTrigger.new()
	trigger.position = center
	trigger.quest_id = "throne_beneath_the_eclipse"
	trigger.objective_id = "reach_inner_spire"
	add_child(trigger)


func _spawn_ascent(room: EclipseSanctumRoom) -> void:
	var center := room.get_world_center(_cell_size)
	_spawn_combat(room, _depth, "ascent")
	_add_prop("platform_stone.glb", center + Vector3(0, 0, 1), 1.3)


func _spawn_antechamber(room: EclipseSanctumRoom) -> void:
	var center := room.get_world_center(_cell_size)
	_add_prop("statue_columnDamaged.glb", center + Vector3(-3, 0, 0), 1.2)
	_add_prop("statue_columnDamaged.glb", center + Vector3(3, 0, 0), 1.2)
	var trigger := _QuestTrigger.new()
	trigger.position = center
	trigger.quest_id = "throne_beneath_the_eclipse"
	trigger.objective_id = "prepare_eclipse_throne"
	add_child(trigger)
	var container := get_node_or_null(enemies_container)
	if container and room.enemy_count > 0:
		var bomber: Node3D = ENEMY_SCENES["nightbound_raider_bomber"].instantiate()
		bomber.position = center + Vector3(0, 0, 1)
		container.add_child(bomber)


func _spawn_sealed_throne(room: EclipseSanctumRoom) -> void:
	var container := get_node_or_null(interactables_container)
	if container == null:
		return
	var center := room.get_world_center(_cell_size)
	var door := _SealedThroneDoor.new()
	door.position = center + Vector3(0, 0, -5)
	container.add_child(door)
	_throne_wall = StaticBody3D.new()
	_throne_wall.name = "ThroneChamberShadowWall"
	_throne_wall.add_to_group("eclipse_throne_wall")
	_throne_wall.position = center + Vector3(0, 0, -4.5)
	var rw_col := CollisionShape3D.new()
	var rw_box := BoxShape3D.new()
	rw_box.size = Vector3(8, 3.5, 1.0)
	rw_col.shape = rw_box
	rw_col.position = Vector3(0, 1.75, 0)
	_throne_wall.add_child(rw_col)
	container.add_child(_throne_wall)
	_add_prop("statue_columnDamaged.glb", center + Vector3(0, 0, -2), 1.3)
	_add_prop("platform_stone.glb", center + Vector3(0, 0, 0), 2.0)


func _spawn_exit(room: EclipseSanctumRoom) -> void:
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
	_exit_portal.reveal()
	_add_prop("fence_gate.glb", center + Vector3(-2, 0, 0), 1.0)


func _build_environment_lighting() -> void:
	var violet := OmniLight3D.new()
	violet.light_color = Color(0.42, 0.38, 0.82)
	violet.light_energy = 0.55
	violet.omni_range = 80.0
	violet.position = Vector3(100, 8, 5)
	add_child(violet)
	var indigo := OmniLight3D.new()
	indigo.light_color = Color(0.28, 0.22, 0.55)
	indigo.light_energy = 0.38
	indigo.omni_range = 65.0
	indigo.position = Vector3(180, 5, 8)
	add_child(indigo)
