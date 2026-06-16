extends Node
## Resolves tracked quest objectives to world targets for HUD, minimap, and map UI.

const _MapIcon := preload("res://scripts/navigation/map_icon.gd")
const _MapRegionData := preload("res://scripts/navigation/map_region_data.gd")
const _ObjectiveTarget := preload("res://scripts/navigation/objective_target.gd")
const _Registry := preload("res://scripts/autoload/npc_mission_registry.gd")

const ROUTES: Dictionary = {
	"find_wolf_crest": {
		"reach_hearthhold": {"type": "region_exit", "region_id": "hearthhold_camp", "pos": Vector3(18, 0.1, 12), "label": "Hearthhold Camp"},
		"reach_shrine": {"type": "quest_group", "group": "quest_destination"},
	},
	"rebuild_the_forge": {
		"gather_scrap": {"type": "resource_hint", "region_id": "darkpine_forest", "label": "Search Darkpine Forest for Metal Scraps"},
		"gather_resin": {"type": "resource_hint", "region_id": "darkpine_forest", "label": "Search Darkpine Forest for Fire Resin"},
		"report_blacksmith": {"type": "npc", "npc_id": "bram_ironhand", "region_id": "hearthhold_camp", "pos": Vector3(7, 0.1, -3.5)},
	},
	"clear_bandit_path": {
		"kill_bandits": {"type": "enemy_group", "region_id": "darkpine_forest", "label": "Bandits in Darkpine Forest"},
		"report_scout": {"type": "npc", "npc_id": "wounded_scout", "region_id": "darkpine_forest", "pos": Vector3(3, 0.1, 6)},
	},
	"build_the_basics": {
		"upgrade_workbench": {"type": "base_station", "station_id": "workbench", "region_id": "hearthhold_camp"},
		"build_water": {"type": "base_station", "station_id": "water_collector", "region_id": "hearthhold_camp"},
		"build_garden": {"type": "base_station", "station_id": "garden_plot", "region_id": "hearthhold_camp"},
		"report_builder": {"type": "npc", "npc_id": "quartermaster_vale", "region_id": "hearthhold_camp", "pos": Vector3(7.5, 0.1, 4)},
	},
	"a_hound_in_the_ash": {
		"unlock_beast_bond": {"type": "skill_hint", "label": "Beast Bond skill"},
		"upgrade_pet_shelter": {"type": "base_station", "station_id": "pet_shelter", "region_id": "hearthhold_camp"},
		"gather_bone": {"type": "resource_hint", "region_id": "darkpine_forest", "label": "Bone"},
		"adopt_hound": {"type": "base_station", "station_id": "pet_shelter", "region_id": "hearthhold_camp"},
		"report_handler": {"type": "npc", "npc_id": "beast_handler", "region_id": "hearthhold_camp", "pos": Vector3(-6, 0.1, -2)},
	},
		"wake_the_stone": {
		"find_waystone": {"type": "waystone", "region_id": "darkpine_forest"},
		"gather_crystal": {"type": "resource_hint", "region_id": "darkpine_forest", "label": "Crystal Shards near the Waystone", "pos": Vector3(-6, 0, 11)},
		"activate_waystone": {"type": "waystone", "region_id": "darkpine_forest"},
		"report_keeper": {"type": "npc", "npc_id": "waystone_keeper", "region_id": "hearthhold_camp", "pos": Vector3(-4, 0.1, 6)},
	},
	"defeat_warden": {
		"kill_warden": {"type": "boss", "enemy_id": "hollow_grove_warden", "region_id": "hollow_grove_shrine"},
	},
	"merchant_errand": {
		"deliver_herbs": {"type": "npc", "npc_id": "wounded_scout", "region_id": "darkpine_forest", "pos": Vector3(6, 0.1, 8)},
	},
}


func _ready() -> void:
	QuestManager.tracked_quest_changed.connect(_on_route_invalidate)
	QuestManager.quest_updated.connect(_on_route_invalidate)
	GameManager.region_changed.connect(func(_id): _invalidate_target_cache())
	call_deferred("refresh_waypoint")


var _cached_track_key: String = ""
var _cached_target: _ObjectiveTarget = null


func _on_route_invalidate(_id: String = "") -> void:
	_invalidate_target_cache()
	refresh_waypoint()


func _invalidate_target_cache() -> void:
	_cached_track_key = ""
	_cached_target = null


func refresh_waypoint() -> void:
	var target: _ObjectiveTarget = get_tracked_target()
	if target == null or not target.has_world_position:
		return
	if target.region_id != "" and target.region_id != GameManager.current_region_id:
		MapManager.clear_waypoint()
		return
	MapManager.set_waypoint(target.world_position, target.display_name)


func get_tracked_target() -> _ObjectiveTarget:
	var quest_id := QuestManager.tracked_quest_id
	if quest_id == "" or not QuestManager.active_quests.has(quest_id):
		_invalidate_target_cache()
		return null
	var obj := QuestManager.get_current_objective(quest_id)
	if obj.is_empty():
		_invalidate_target_cache()
		return null
	var obj_id := str(obj.get("id", ""))
	var cache_key := "%s:%s:%d:%d:%s" % [
		quest_id, obj_id, int(obj.get("current", 0)), int(obj.get("target", 0)),
		GameManager.current_region_id,
	]
	if cache_key == _cached_track_key and _cached_target != null:
		return _cached_target
	var target: _ObjectiveTarget = resolve_target(quest_id, obj_id, obj)
	_cached_track_key = cache_key
	_cached_target = target
	return target


func resolve_target(quest_id: String, objective_id: String, obj: Dictionary = {}) -> _ObjectiveTarget:
	var target: _ObjectiveTarget = _ObjectiveTarget.new()
	target.related_mission_id = quest_id
	target.related_objective_id = objective_id
	target.is_completed = bool(obj.get("completed", false))
	var routes: Dictionary = ROUTES.get(quest_id, {})
	var route: Dictionary = routes.get(objective_id, {})
	if route.is_empty():
		target.display_name = str(obj.get("description", objective_id))
		target.target_type = "generic"
		return target
	target.target_type = str(route.get("type", "generic"))
	target.region_id = str(route.get("region_id", GameManager.current_region_id))
	target.display_name = str(route.get("label", obj.get("description", objective_id)))
	match target.target_type:
		"npc":
			target.target_id = str(route.get("npc_id", ""))
			target.display_name = _npc_display_name(target.target_id)
			_fill_npc_position(target, route)
		"base_station":
			target.target_id = str(route.get("station_id", ""))
			target.display_name = target.target_id.replace("_", " ").capitalize()
			_fill_station_position(target, route)
		"waystone":
			target.target_id = "waystone"
			target.display_name = "Waystone"
			_fill_waystone_position(target, route)
		"resource_hint", "enemy_group", "skill_hint":
			target.region_hint = _MapRegionData.get_display_name(str(route.get("region_id", "")))
			target.display_name = str(route.get("label", obj.get("description", "")))
			if target.region_hint != "" and target.display_name.contains("Search"):
				target.region_hint = target.display_name
			if route.has("pos") and str(route.get("region_id", "")) == GameManager.current_region_id:
				target.world_position = route.pos
				target.has_world_position = true
				target.region_id = GameManager.current_region_id
		"region_exit":
			target.target_id = str(route.get("region_id", ""))
			target.display_name = str(route.get("label", "Region Exit"))
			if route.has("pos"):
				target.world_position = route.pos
				target.region_id = GameManager.current_region_id
				target.has_world_position = true
		"boss":
			target.target_id = str(route.get("enemy_id", "boss"))
			target.display_name = "Boss"
			_fill_boss_position(target)
		"quest_group":
			_fill_quest_group_position(target, route)
	return target


func get_tracked_position(_tree: SceneTree) -> Vector3:
	var target: _ObjectiveTarget = get_tracked_target()
	if target == null:
		return Vector3.ZERO
	if target.has_world_position and target.region_id == GameManager.current_region_id:
		return target.world_position
	return Vector3.ZERO


func get_distance_to_tracked(tree: SceneTree) -> float:
	var pos := get_tracked_position(tree)
	if pos == Vector3.ZERO:
		return -1.0
	var ref := _nearest_living_player(tree, pos)
	if ref == null:
		return -1.0
	return ref.global_position.distance_to(pos)


func get_distance_label(tree: SceneTree) -> String:
	var target: _ObjectiveTarget = get_tracked_target()
	if target == null:
		return ""
	if target.region_hint != "" and (not target.has_world_position or target.region_id != GameManager.current_region_id):
		return target.region_hint
	var dist := get_distance_to_tracked(tree)
	if dist < 0.0:
		return ""
	return "%dm" % int(dist)


func collect_map_icons(tree: SceneTree, view_region_id: String = "") -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var region_id := view_region_id if view_region_id != "" else GameManager.current_region_id
	_append_players(out, tree, region_id)
	_append_pet(out, tree, region_id)
	_append_waystones(out, tree, region_id)
	_append_npcs(out, tree, region_id)
	_append_stations(out, tree, region_id)
	_append_bosses(out, tree, region_id)
	_append_objective(out, tree, region_id)
	_append_discovered(out, region_id)
	return out


func _append_players(out: Array[Dictionary], tree: SceneTree, region_id: String) -> void:
	if region_id != GameManager.current_region_id:
		return
	for p in GameManager.get_players():
		if p == null or not is_instance_valid(p) or not (p is Node3D):
			continue
		var idx := 0
		if p.get("player_index") != null:
			idx = int(p.player_index)
		var downed: bool = p.has_method("is_downed") and bool(p.call("is_downed"))
		var alive := true
		if p.has_node("HealthComponent"):
			var hp: Node = p.get_node("HealthComponent")
			if hp.get("current_health") != null and float(hp.current_health) <= 0.0:
				alive = false
		var icon_type := _MapIcon.IconType.PLAYER_P1 if idx == 0 else _MapIcon.IconType.PLAYER_P2
		out.append(_make_icon(icon_type, (p as Node3D).global_position, "P%d" % (idx + 1), downed or not alive))


func _append_pet(out: Array[Dictionary], _tree: SceneTree, region_id: String) -> void:
	if region_id != GameManager.current_region_id or not PetManager.is_party_pet_active():
		return
	var pet := PetManager.active_pet_instance
	if pet and is_instance_valid(pet) and pet is Node3D:
		out.append(_make_icon(_MapIcon.IconType.PET, (pet as Node3D).global_position, PetManager.get_pet_display_name(PetManager.active_pet_id)))


func _append_waystones(out: Array[Dictionary], tree: SceneTree, region_id: String) -> void:
	if region_id != GameManager.current_region_id:
		return
	for node in tree.get_nodes_in_group("waystone"):
		if node is Node3D and is_instance_valid(node):
			out.append(_make_icon(_MapIcon.IconType.WAYSTONE, (node as Node3D).global_position, "Waystone"))


func _append_npcs(out: Array[Dictionary], tree: SceneTree, region_id: String) -> void:
	if region_id != GameManager.current_region_id:
		return
	for node in tree.get_nodes_in_group("npc"):
		if not (node is Node3D) or not is_instance_valid(node):
			continue
		var npc_id: String = str(node.get("npc_id")) if node.get("npc_id") != null else str(node.name)
		var icon_type := _MapIcon.IconType.NPC
		for mid in _Registry.NPC_MISSIONS.get(npc_id, []):
			var qid := _Registry.get_mission_quest(str(mid))
			if qid in QuestManager.completed_quests:
				continue
			if QuestManager.active_quests.has(qid) and NpcMissionHooks.can_turn_in_quest(qid):
				icon_type = _MapIcon.IconType.MISSION_TURN_IN
				break
			if not QuestManager.active_quests.has(qid) and not QuestManager.completed_quests.has(qid):
				icon_type = _MapIcon.IconType.MISSION_AVAILABLE
				break
		var label: String = str(node.get("display_name")) if node.get("display_name") != null else npc_id
		out.append(_make_icon(icon_type, (node as Node3D).global_position, label))


func _append_stations(out: Array[Dictionary], tree: SceneTree, region_id: String) -> void:
	if region_id != GameManager.current_region_id:
		return
	for node in tree.get_nodes_in_group("interactable"):
		if not (node is Node3D) or node.get("station_id") == null:
			continue
		var sid := str(node.get("station_id"))
		if sid == "":
			continue
		out.append(_make_icon(_MapIcon.IconType.BASE_STATION, (node as Node3D).global_position, sid.replace("_", " ").capitalize()))


func _append_bosses(out: Array[Dictionary], tree: SceneTree, region_id: String) -> void:
	if region_id != GameManager.current_region_id:
		return
	for node in tree.get_nodes_in_group("boss"):
		if node is Node3D and is_instance_valid(node):
			out.append(_make_icon(_MapIcon.IconType.BOSS, (node as Node3D).global_position, node.name))


func _append_objective(out: Array[Dictionary], tree: SceneTree, region_id: String) -> void:
	var target: _ObjectiveTarget = get_tracked_target()
	if target == null or not target.has_world_position or target.region_id != region_id:
		return
	out.append(_make_icon(_MapIcon.IconType.OBJECTIVE_ACTIVE, target.world_position, target.display_name))


func _append_discovered(out: Array[Dictionary], region_id: String) -> void:
	for entry in MapManager.get_discovered_locations_for_region(region_id):
		var cat := str(entry.get("category", ""))
		var icon_type := _MapIcon.IconType.BUILDING
		match cat:
			"camp": icon_type = _MapIcon.IconType.CAMP
			"gate": icon_type = _MapIcon.IconType.REGION_EXIT
			"dungeon": icon_type = _MapIcon.IconType.BOSS
			"waystone", "fast_travel": icon_type = _MapIcon.IconType.WAYSTONE
			"quest": icon_type = _MapIcon.IconType.OBJECTIVE_ACTIVE
			"resource": icon_type = _MapIcon.IconType.RESOURCE
		var pos: Vector3 = entry.get("position", Vector3.ZERO)
		out.append(_make_icon(icon_type, pos, str(entry.get("name", ""))))


func _make_icon(icon_type: int, pos: Vector3, label: String, downed: bool = false) -> Dictionary:
	return {
		"icon_type": icon_type,
		"position": pos,
		"label": label,
		"downed": downed,
		"color": _MapIcon.get_color(icon_type, downed),
	}


func _fill_npc_position(target: _ObjectiveTarget, route: Dictionary) -> void:
	var tree := get_tree()
	if tree:
		for node in tree.get_nodes_in_group("npc"):
			if str(node.get("npc_id")) == target.target_id and node is Node3D:
				target.world_position = (node as Node3D).global_position
				target.has_world_position = true
				target.region_id = GameManager.current_region_id
				return
	if route.has("pos"):
		target.world_position = route.pos
		target.region_id = str(route.get("region_id", GameManager.current_region_id))
		if target.region_id == GameManager.current_region_id:
			target.has_world_position = true
		else:
			target.region_hint = _MapRegionData.get_display_name(target.region_id)
			target.has_world_position = false


func _fill_station_position(target: _ObjectiveTarget, route: Dictionary) -> void:
	var tree := get_tree()
	if tree:
		for node in tree.get_nodes_in_group("interactable"):
			if str(node.get("station_id")) == target.target_id and node is Node3D:
				target.world_position = (node as Node3D).global_position
				target.has_world_position = true
				target.region_id = GameManager.current_region_id
				return
	target.region_id = str(route.get("region_id", "hearthhold_camp"))
	if target.region_id != GameManager.current_region_id:
		target.region_hint = _MapRegionData.get_display_name(target.region_id)
		target.has_world_position = false


func _fill_waystone_position(target: _ObjectiveTarget, route: Dictionary) -> void:
	var tree := get_tree()
	var rid := str(route.get("region_id", GameManager.current_region_id))
	if tree and GameManager.current_region_id == rid:
		for node in tree.get_nodes_in_group("waystone"):
			if node is Node3D:
				target.world_position = (node as Node3D).global_position
				target.has_world_position = true
				target.region_id = rid
				return
	target.region_hint = _MapRegionData.get_display_name(rid)
	target.region_id = rid


func _fill_boss_position(target: _ObjectiveTarget) -> void:
	var tree := get_tree()
	if tree:
		for node in tree.get_nodes_in_group("boss"):
			if node is Node3D:
				target.world_position = (node as Node3D).global_position
				target.has_world_position = true
				return
	target.region_hint = _MapRegionData.get_display_name(target.region_id)


func _fill_quest_group_position(target: _ObjectiveTarget, route: Dictionary) -> void:
	var tree := get_tree()
	if tree == null:
		return
	var group := str(route.get("group", "quest_destination"))
	for node in tree.get_nodes_in_group(group):
		if node is Node3D:
			target.world_position = (node as Node3D).global_position
			target.has_world_position = true
			if node.get("display_name"):
				target.display_name = str(node.display_name)
			else:
				target.display_name = node.name
			return


func _nearest_living_player(_tree: SceneTree, world_pos: Vector3) -> Node3D:
	var best: Node3D = null
	var best_dist := INF
	for p in GameManager.get_alive_players():
		if p is Node3D:
			var d := (p as Node3D).global_position.distance_to(world_pos)
			if d < best_dist:
				best_dist = d
				best = p as Node3D
	if best != null:
		return best
	for p in GameManager.get_players():
		if p is Node3D and is_instance_valid(p):
			return p as Node3D
	return null


func _npc_display_name(npc_id: String) -> String:
	match npc_id:
		"bram_ironhand": return "Old Blacksmith"
		"quartermaster_vale": return "Camp Builder"
		"beast_handler": return "Beast Handler"
		"waystone_keeper": return "Waystone Keeper"
		"wounded_scout": return "Wounded Scout"
		_: return npc_id.replace("_", " ").capitalize()
