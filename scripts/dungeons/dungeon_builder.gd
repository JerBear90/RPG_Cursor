extends Node3D
## Builds procedural dungeon geometry, enemies, and boss room from DungeonManager layout.

signal build_completed

const _Kenney = preload("res://scripts/utilities/kenney_paths.gd")
const FLOOR_TILE := preload("res://scenes/dungeons/dungeon_floor_tile.tscn")
const ENTRANCE_SCENE := preload("res://scenes/dungeons/dungeon_entrance.tscn")

const ENEMY_SCENES: Array[PackedScene] = [
	preload("res://scenes/enemies/forest_bandit.tscn"),
	preload("res://scenes/enemies/shield_bandit.tscn"),
	preload("res://scenes/enemies/bandit_archer.tscn"),
]

@export var players_container: NodePath = NodePath("../Players")
@export var enemies_container: NodePath = NodePath("../Enemies")
@export var interactables_container: NodePath = NodePath("../Interactables")

var _cell_size: float = 2.0
var _boss_node: Node = null
var _exit_portal: DungeonExitPortal
var _treasure_chest: DungeonTreasureChest
var _build_complete: bool = false


func _ready() -> void:
	add_to_group("dungeon_builder")
	call_deferred("_build")


func is_build_complete() -> bool:
	return _build_complete


func _build() -> void:
	var layout: Dictionary = DungeonManager.layout
	if layout.is_empty():
		layout = DungeonGenerator.generate(DungeonManager.seed, DungeonManager.tier)
		DungeonManager.layout = layout
	_cell_size = layout.get("cell_size", DungeonGenerator.CELL_SIZE)
	var rooms: Array = layout.get("rooms", [])
	for room in rooms:
		if room is DungeonRoom:
			_build_room(room)
	_spawn_exit_and_treasure(rooms)
	_build_complete = true
	build_completed.emit()


func _build_room(room: DungeonRoom) -> void:
	var origin := room.get_world_origin(_cell_size)
	var size := room.get_world_size(_cell_size)
	_fill_floor(origin, size)
	if room.room_type == DungeonRoom.RoomType.CORRIDOR:
		return
	_build_walls(origin, size)
	match room.room_type:
		DungeonRoom.RoomType.SPAWN:
			pass
		DungeonRoom.RoomType.COMBAT:
			_spawn_combat_enemies(room)
		DungeonRoom.RoomType.TREASURE:
			_spawn_treasure_room(room)
		DungeonRoom.RoomType.BOSS:
			_spawn_boss_room(room)


func _fill_floor(origin: Vector3, size: Vector3) -> void:
	var cols := int(size.x / _cell_size)
	var rows := int(size.z / _cell_size)
	for x in cols:
		for z in rows:
			var tile: Node3D = FLOOR_TILE.instantiate()
			tile.position = origin + Vector3(x * _cell_size + _cell_size * 0.5, 0, z * _cell_size + _cell_size * 0.5)
			add_child(tile)


func _build_walls(origin: Vector3, size: Vector3) -> void:
	var segment := _cell_size
	var wall_path := _Kenney.nature("cliff_block_stone.glb")
	var cols := int(size.x / segment)
	var rows := int(size.z / segment)
	for x in cols:
		var px := origin.x + x * segment + segment * 0.5
		_add_wall_block(wall_path, Vector3(px, 0.0, origin.z - segment * 0.25))
		_add_wall_block(wall_path, Vector3(px, 0.0, origin.z + size.z + segment * 0.25))
	for z in rows:
		var pz := origin.z + z * segment + segment * 0.5
		_add_wall_block(wall_path, Vector3(origin.x - segment * 0.25, 0.0, pz))
		_add_wall_block(wall_path, Vector3(origin.x + size.x + segment * 0.25, 0.0, pz))


func _add_wall_block(path: String, pos: Vector3) -> void:
	var holder := Node3D.new()
	holder.position = pos
	add_child(holder)
	MeshLoader.instantiate(path, holder, randf_range(0.0, 360.0), Vector3.ZERO, Vector3(2.0, 2.5, 2.0))
	var body := StaticBody3D.new()
	body.position = pos
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(_cell_size, 2.5, _cell_size * 0.5)
	col.shape = shape
	col.position = Vector3(0.0, 1.25, 0.0)
	body.add_child(col)
	add_child(body)


func _spawn_combat_enemies(room: DungeonRoom) -> void:
	var container := get_node_or_null(enemies_container)
	if container == null:
		return
	var center := room.get_world_center(_cell_size)
	var room_enemies: Array[Node] = []
	for i in room.enemy_count:
		var scene: PackedScene = ENEMY_SCENES[i % ENEMY_SCENES.size()]
		var enemy: Node3D = scene.instantiate()
		var offset := Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
		enemy.position = center + offset
		container.add_child(enemy)
		room_enemies.append(enemy)
		if enemy.has_signal("enemy_died"):
			enemy.enemy_died.connect(func(_e): _on_combat_room_enemy_died(room, center, room_enemies))


func _on_combat_room_enemy_died(room: DungeonRoom, center: Vector3, room_enemies: Array[Node]) -> void:
	for enemy in room_enemies:
		if is_instance_valid(enemy):
			return
	WorldStateManager.dungeon_checkpoint_room = room.room_index
	WorldStateManager.register_checkpoint(
		"dungeon_checkpoint_room_%d" % room.room_index,
		"procedural_dungeon",
		center
	)


func _spawn_treasure_room(room: DungeonRoom) -> void:
	var container := get_node_or_null(interactables_container)
	if container == null:
		return
	var chest: Node3D = preload("res://scenes/dungeons/dungeon_treasure_chest.tscn").instantiate()
	chest.position = room.get_world_center(_cell_size)
	container.add_child(chest)


func _spawn_boss_room(room: DungeonRoom) -> void:
	var container := get_node_or_null(enemies_container)
	if container == null:
		return
	var boss_scene := preload("res://scenes/enemies/bandit_captain.tscn")
	_boss_node = boss_scene.instantiate()
	_boss_node.position = room.get_world_center(_cell_size)
	if _boss_node is EnemyBase:
		(_boss_node as EnemyBase).loot_table_id = "dungeon_boss"
		(_boss_node as EnemyBase).max_health = 180.0
		(_boss_node as EnemyBase).display_name = "Crypt Warden"
	if _boss_node.has_signal("enemy_died"):
		_boss_node.enemy_died.connect(_on_boss_died)
	container.add_child(_boss_node)
	_boss_node.add_to_group("boss")


func _spawn_exit_and_treasure(rooms: Array) -> void:
	var container := get_node_or_null(interactables_container)
	if container == null:
		return
	var boss_room: DungeonRoom = null
	for room in rooms:
		if room is DungeonRoom and room.room_type == DungeonRoom.RoomType.BOSS:
			boss_room = room
			break
	if boss_room == null:
		return
	var center := boss_room.get_world_center(_cell_size)
	_exit_portal = preload("res://scenes/dungeons/dungeon_exit_portal.tscn").instantiate()
	_exit_portal.position = center + Vector3(4, 0, 0)
	container.add_child(_exit_portal)
	_treasure_chest = preload("res://scenes/dungeons/dungeon_treasure_chest.tscn").instantiate()
	_treasure_chest.position = center + Vector3(-3, 0, 2)
	container.add_child(_treasure_chest)


func _on_boss_died(_enemy: EnemyBase) -> void:
	GameManager.in_boss_fight = false
	LootManager.drop_loot_table("dungeon_boss", _boss_node.global_position if _boss_node else Vector3.ZERO)
	DungeonManager.on_boss_defeated()
	if _exit_portal:
		_exit_portal.reveal()
