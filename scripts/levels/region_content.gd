class_name RegionContent
extends RefCounted
## Spawns enemies, chests, and props for travel regions at runtime.

const ENEMY_SCENES := {
	"forest_bandit": "res://scenes/enemies/forest_bandit.tscn",
	"shield_bandit": "res://scenes/enemies/shield_bandit.tscn",
	"bandit_archer": "res://scenes/enemies/bandit_archer.tscn",
	"bandit_captain": "res://scenes/enemies/bandit_captain.tscn",
	"hollow_warden": "res://scenes/enemies/hollow_grove_warden.tscn",
}

const CHEST_SCENE := "res://scenes/camps/camp_chest.tscn"
const HERB_SCENE := "res://scenes/resources/resource_herb.tscn"
const CRATE_SCENE := "res://scenes/destructibles/destructible_crate.tscn"


static func populate(level: Node3D) -> void:
	var region_id := _region_id(level)
	if region_id == "":
		return
	var enemies := _ensure_node(level, "Enemies")
	var interactables := _ensure_node(level, "Interactables")
	match region_id:
		"darkpine_forest":
			_spawn_prop(interactables, CRATE_SCENE, Vector3(-4, 0, 7))
			_spawn_prop(interactables, CRATE_SCENE, Vector3(-6, 0, 8))
		"ruined_watchtower":
			_spawn_enemy(enemies, "forest_bandit", Vector3(8, 0.1, -8))
			_spawn_enemy(enemies, "forest_bandit", Vector3(-7, 0.1, -10))
			_spawn_enemy(enemies, "bandit_archer", Vector3(10, 0.1, 4))
			_spawn_prop(interactables, CRATE_SCENE, Vector3(-3, 0, -6))
			_spawn_prop(interactables, HERB_SCENE, Vector3(4, 0, -4))
			_spawn_prop(interactables, CRATE_SCENE, Vector3(4, 0, -1))
			_spawn_prop(interactables, HERB_SCENE, Vector3(-3, 0, 3))
		"bandit_camp":
			_spawn_enemy(enemies, "shield_bandit", Vector3(10, 0.1, -8))
			_spawn_enemy(enemies, "forest_bandit", Vector3(-8, 0.1, -6))
			_spawn_enemy(enemies, "bandit_archer", Vector3(6, 0.1, 6))
			_spawn_enemy(enemies, "bandit_captain", Vector3(-10, 0.1, -12))
			_spawn_prop(interactables, CHEST_SCENE, Vector3(3, 0, -5))
			_spawn_prop(interactables, CRATE_SCENE, Vector3(-2, 0, -3))
			_spawn_prop(interactables, CHEST_SCENE, Vector3(9, 0, 4))
			_spawn_prop(interactables, CRATE_SCENE, Vector3(8, 0, 5))
		"crystal_cave":
			_spawn_enemy(enemies, "bandit_archer", Vector3(6, 0.1, -4))
			_spawn_enemy(enemies, "shield_bandit", Vector3(-5, 0.1, 6))
			_spawn_enemy(enemies, "forest_bandit", Vector3(0, 0.1, -10))
			_spawn_prop(interactables, CRATE_SCENE, Vector3(4, 0, 2))
			_spawn_prop(interactables, CRATE_SCENE, Vector3(-4, 0, 1))
		"hollow_grove_shrine":
			if not _has_enemy_id(enemies, "hollow_grove_warden"):
				_spawn_enemy(enemies, "hollow_warden", Vector3(0, 0.1, -16))
			_spawn_enemy(enemies, "forest_bandit", Vector3(12, 0.1, -8))
			_spawn_enemy(enemies, "shield_bandit", Vector3(-11, 0.1, -6))
			_spawn_prop(interactables, HERB_SCENE, Vector3(-6, 0, 4))
			_spawn_prop(interactables, HERB_SCENE, Vector3(7, 0, 3))
		"hearthhold_camp":
			_spawn_prop(interactables, CHEST_SCENE, Vector3(12, 0, 4))
			_spawn_prop(interactables, CRATE_SCENE, Vector3(12, 0, -2))
			_spawn_prop(interactables, CRATE_SCENE, Vector3(-7, 0, 8))


static func start_region_quests(region_id: String) -> void:
	match region_id:
		"ruined_watchtower":
			if "watchtower_sweep" not in QuestManager.completed_quests:
				QuestManager.start_quest("watchtower_sweep")
		"bandit_camp":
			if "raid_bandit_camp" not in QuestManager.completed_quests:
				QuestManager.start_quest("raid_bandit_camp")
		"crystal_cave":
			if "crystal_echoes" not in QuestManager.completed_quests:
				QuestManager.start_quest("crystal_echoes")
		"hollow_grove_shrine":
			if "defeat_warden" not in QuestManager.completed_quests and not QuestManager.active_quests.has("defeat_warden"):
				if "merchant_errand" in QuestManager.completed_quests:
					QuestManager.start_quest("defeat_warden")


static func on_enemy_killed(region_id: String, enemy_id: String) -> void:
	if region_id == "ruined_watchtower" and QuestManager.active_quests.has("watchtower_sweep"):
		QuestManager.advance_objective("watchtower_sweep", "clear_hostiles", 1)
	if region_id == "bandit_camp":
		if enemy_id == "bandit_captain" and QuestManager.active_quests.has("raid_bandit_camp"):
			QuestManager.advance_objective("raid_bandit_camp", "kill_captain", 1)
		elif QuestManager.active_quests.has("raid_bandit_camp"):
			QuestManager.advance_objective("raid_bandit_camp", "clear_camp", 1)
	if region_id == "crystal_cave" and QuestManager.active_quests.has("crystal_echoes"):
		QuestManager.advance_objective("crystal_echoes", "clear_crystal", 1)
	if enemy_id == "hollow_grove_warden" and QuestManager.active_quests.has("defeat_warden"):
		QuestManager.advance_objective("defeat_warden", "kill_warden", 1)
		InventoryManager.add_item("grove_heart", 1)


static func _region_id(level: Node3D) -> String:
	if level.has_method("_get_region_id"):
		return level._get_region_id()
	if "region_id" in level:
		return str(level.region_id)
	return GameManager.current_region_id


static func _ensure_node(level: Node3D, node_name: String) -> Node3D:
	var existing := level.get_node_or_null(node_name) as Node3D
	if existing:
		return existing
	var node := Node3D.new()
	node.name = node_name
	level.add_child(node)
	return node


static func _spawn_enemy(parent: Node3D, key: String, pos: Vector3) -> void:
	var path: String = ENEMY_SCENES.get(key, "")
	if path == "" or not ResourceLoader.exists(path):
		return
	var scene: PackedScene = load(path)
	var enemy: Node3D = scene.instantiate()
	enemy.global_position = pos
	parent.add_child(enemy)


static func _spawn_prop(parent: Node3D, scene_path: String, pos: Vector3) -> void:
	if not ResourceLoader.exists(scene_path):
		return
	var scene: PackedScene = load(scene_path)
	var prop: Node3D = scene.instantiate()
	prop.global_position = pos
	parent.add_child(prop)


static func _has_enemy_id(parent: Node3D, enemy_id: String) -> bool:
	for child in parent.get_children():
		if "enemy_id" in child and str(child.enemy_id) == enemy_id:
			return true
	return false
