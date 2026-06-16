extends Node
## Shared party pet unlock, spawn, command, and persistence.

signal pet_unlocked(pet_id: String)
signal pet_adopted(pet_id: String)
signal pet_spawned(pet: Node3D)
signal pet_command_changed(command_id: String)
signal pet_stats_changed

const ASH_HOUND_SCENE_PATH := "res://scenes/pets/ash_hound.tscn"

const PET_DEFINITIONS: Dictionary = {
	"ash_hound": {
		"pet_id": "ash_hound", "display_name": "Ash Hound", "scene_path": ASH_HOUND_SCENE_PATH,
		"max_hp": 60.0, "base_damage": 6.0, "attack_cooldown": 1.5,
		"follow_distance": 2.5, "recall_distance": 15.0, "detection_range": 8.0, "move_speed": 7.0,
	},
}

var beast_bond_unlocked: bool = false
var adopted_pets: Array[String] = []
var active_pet_id: String = ""
var active_pet_instance: Node3D = null
var party_command: String = "follow"
var pet_names: Dictionary = {"ash_hound": "Ash Hound"}
var pet_stats_saved: Dictionary = {}
var equipped_gear_id: String = ""
var _shared_attack_target: Node3D = null


func reset_for_new_game() -> void:
	beast_bond_unlocked = false
	adopted_pets.clear()
	active_pet_id = ""
	active_pet_instance = null
	party_command = "follow"
	pet_names = {"ash_hound": "Ash Hound"}
	pet_stats_saved.clear()
	equipped_gear_id = ""
	_shared_attack_target = null


func grant_beast_bond_access() -> void:
	beast_bond_unlocked = true


func has_beast_bond_access() -> bool:
	if beast_bond_unlocked:
		return true
	return _any_player_has_skill(["beast_bond", "wolf_bond"])


func adopt_pet(pet_id: String) -> bool:
	if pet_id not in PET_DEFINITIONS:
		return false
	if not has_beast_bond_access():
		return false
	if BaseManager.get_station_level("pet_shelter") < 1:
		return false
	if pet_id not in adopted_pets:
		adopted_pets.append(pet_id)
	active_pet_id = pet_id
	pet_adopted.emit(pet_id)
	pet_unlocked.emit(pet_id)
	return true


func has_adopted_pet(pet_id: String) -> bool:
	return pet_id in adopted_pets


func has_pet(pet_id: String) -> bool:
	return has_adopted_pet(pet_id)


func is_party_pet_active() -> bool:
	return active_pet_id != "" and has_adopted_pet(active_pet_id)


func get_pet_display_name(pet_id: String) -> String:
	return str(pet_names.get(pet_id, PET_DEFINITIONS.get(pet_id, {}).get("display_name", pet_id)))


func set_pet_name(pet_id: String, new_name: String) -> void:
	var trimmed := new_name.strip_edges()
	if trimmed != "":
		pet_names[pet_id] = trimmed


func get_party_command() -> String:
	return party_command


func set_party_command(command_id: String) -> void:
	party_command = command_id
	if active_pet_instance and is_instance_valid(active_pet_instance) and active_pet_instance.has_method("set_command"):
		active_pet_instance.set_command(command_id)
	pet_command_changed.emit(command_id)


func set_pet_command(_owner_index: int, command_id: String) -> void:
	set_party_command(command_id)


func get_pet_command(_owner_index: int) -> String:
	return party_command


func unlock_pet(pet_id: String) -> void:
	adopt_pet(pet_id)


func try_spawn_for_player(player: Node3D) -> void:
	if player == null:
		return
	var parent := player.get_parent()
	if parent == null:
		return
	ensure_party_pet(parent)


func ensure_party_pet(parent: Node) -> void:
	if not is_party_pet_active():
		return
	if active_pet_instance and is_instance_valid(active_pet_instance):
		_position_pet_near_party()
		return
	var def: Dictionary = PET_DEFINITIONS.get(active_pet_id, {})
	var scene_path := str(def.get("scene_path", ASH_HOUND_SCENE_PATH))
	var scene: PackedScene = load(scene_path) as PackedScene
	if scene == null:
		return
	var pet: Node3D = scene.instantiate()
	parent.add_child(pet)
	pet.global_position = _get_party_center() + Vector3(-1.2, 0.0, 0.8)
	if pet.has_method("setup_from_data"):
		pet.setup_from_data(def.duplicate())
	elif pet.has_method("setup"):
		pet.setup(GameManager.get_player(0))
	if pet_stats_saved.has(active_pet_id) and pet.has_method("apply_saved_stats"):
		pet.apply_saved_stats(pet_stats_saved[active_pet_id])
	if pet.has_signal("pet_downed"):
		pet.pet_downed.connect(_on_pet_downed)
	if pet.has_signal("stats_changed"):
		pet.stats_changed.connect(_on_pet_stats_changed)
	active_pet_instance = pet
	pet_spawned.emit(pet)
	set_party_command(party_command)


func recover_party_pet(at_full: bool = true) -> void:
	if active_pet_instance and is_instance_valid(active_pet_instance) and active_pet_instance.has_method("recover"):
		active_pet_instance.recover(at_full)
	elif pet_stats_saved.has(active_pet_id):
		var saved: Dictionary = pet_stats_saved[active_pet_id]
		saved["downed"] = false
		saved["current_hp"] = float(saved.get("max_hp", 60.0))
		pet_stats_saved[active_pet_id] = saved


func adopt_ash_hound_from_shelter(player_index: int = 0) -> Dictionary:
	if not has_beast_bond_access():
		return {"ok": false, "reason": "Beast Bond Required"}
	if BaseManager.get_station_level("pet_shelter") < 1:
		return {"ok": false, "reason": "Pet Shelter Level 1 Required"}
	if has_adopted_pet("ash_hound"):
		recover_party_pet(true)
		_notify_hud("Pet summoned")
		return {"ok": true, "reason": "summoned", "player_index": player_index}
	if not adopt_pet("ash_hound"):
		return {"ok": false, "reason": "Could not adopt pet"}
	AchievementManager.unlock("loyal_companion")
	var parent := get_tree().current_scene
	if parent:
		ensure_party_pet(parent)
	_notify_hud("Pet summoned")
	return {"ok": true, "reason": "adopted", "player_index": player_index}


func unlock_ash_hound_from_shelter() -> void:
	adopt_ash_hound_from_shelter()


func get_pet_modifiers() -> Dictionary:
	var mods := {
		"hp_bonus": 0.0, "damage_bonus": 0.0, "damage_multiplier": 1.0,
		"gear_hp_bonus": 0.0, "gear_damage_bonus": 0.0,
	}
	for player in GameManager.get_all_registered_players():
		if player.has_node("SkillTree"):
			var tree := player.get_node("SkillTree")
			mods.hp_bonus += float(tree.get_node_rank("loyal_companion")) * 10.0
			mods.damage_multiplier += float(tree.get_node_rank("pack_tactics")) * 0.05
	if equipped_gear_id != "":
		var gear := ItemDatabase.get_item(equipped_gear_id)
		mods.gear_hp_bonus += float(gear.get("pet_hp_bonus", 0.0))
		mods.gear_damage_bonus += float(gear.get("pet_damage_bonus", 0.0))
	return mods


func get_pack_tactics_multiplier() -> float:
	return 1.0 + float(_sum_skill_rank("pack_tactics")) * 0.05


func get_recall_speed_multiplier() -> float:
	return 1.0 + float(_sum_skill_rank("quick_recall")) * 0.35


func should_apply_pack_tactics(target: Node3D) -> bool:
	if target == null:
		return false
	for player in GameManager.get_all_registered_players():
		if not is_instance_valid(player):
			continue
		if player.has_node("Combat"):
			var combat := player.get_node("Combat")
			if combat.has_method("get_current_target") and combat.get_current_target() == target:
				return true
	return _shared_attack_target == target


func notify_pet_downed(pet_name: String) -> void:
	_notify_hud("%s is down" % pet_name)


func notify_pet_recovered(pet_name: String) -> void:
	_notify_hud("%s recovered" % pet_name)


func _on_pet_downed() -> void:
	if active_pet_id != "" and active_pet_instance:
		pet_stats_saved[active_pet_id] = active_pet_instance.serialize_stats()
	pet_stats_changed.emit()


func _on_pet_stats_changed(_current: float, _max: float, _command: String) -> void:
	if active_pet_instance and active_pet_id != "":
		pet_stats_saved[active_pet_id] = active_pet_instance.serialize_stats()
	pet_stats_changed.emit()


func _position_pet_near_party() -> void:
	if active_pet_instance == null:
		return
	var center := _get_party_center()
	if center == Vector3.ZERO:
		return
	if active_pet_instance.global_position.distance_to(center) > 15.0:
		active_pet_instance.global_position = center + Vector3(-1.2, 0.0, 0.8)


func _get_party_center() -> Vector3:
	var tree := get_tree()
	if tree == null:
		return Vector3.ZERO
	var positions: Array[Vector3] = []
	for node in tree.get_nodes_in_group("player"):
		if is_instance_valid(node) and node is Node3D:
			positions.append((node as Node3D).global_position)
	if positions.is_empty():
		return Vector3.ZERO
	var sum := Vector3.ZERO
	for pos in positions:
		sum += pos
	return sum / float(positions.size())


func _any_player_has_skill(node_ids: Array) -> bool:
	for player in GameManager.get_all_registered_players():
		if player.has_node("SkillTree"):
			var tree := player.get_node("SkillTree")
			for node_id in node_ids:
				if tree.get_node_rank(str(node_id)) > 0:
					return true
	return false


func _sum_skill_rank(node_id: String) -> int:
	var total := 0
	for player in GameManager.get_all_registered_players():
		if player.has_node("SkillTree"):
			total += (player.get_node("SkillTree") as Node).get_node_rank(node_id)
	return total


func _notify_hud(message: String) -> void:
	for hud in get_tree().get_nodes_in_group("game_hud"):
		if hud.has_method("show_toast"):
			hud.show_toast(message, 2.0)
			return


func serialize() -> Dictionary:
	if active_pet_instance and is_instance_valid(active_pet_instance) and active_pet_instance.has_method("serialize_stats"):
		pet_stats_saved[active_pet_id] = active_pet_instance.serialize_stats()
	return {
		"beast_bond_unlocked": beast_bond_unlocked,
		"adopted": adopted_pets.duplicate(),
		"active_pet_id": active_pet_id,
		"party_command": party_command,
		"pet_names": pet_names.duplicate(),
		"pet_stats": pet_stats_saved.duplicate(),
		"equipped_gear": equipped_gear_id,
		"unlocked": adopted_pets.duplicate(),
		"commands": {"0": party_command},
	}


func deserialize(data: Dictionary) -> void:
	beast_bond_unlocked = bool(data.get("beast_bond_unlocked", false))
	var saved_adopted: Array = data.get("adopted", data.get("unlocked", []))
	adopted_pets.clear()
	for entry in saved_adopted:
		var pid := str(entry)
		if pid in PET_DEFINITIONS:
			adopted_pets.append(pid)
	active_pet_id = str(data.get("active_pet_id", adopted_pets[0] if not adopted_pets.is_empty() else ""))
	party_command = str(data.get("party_command", data.get("commands", {}).get("0", "follow")))
	pet_names = data.get("pet_names", {"ash_hound": "Ash Hound"}).duplicate()
	pet_stats_saved = data.get("pet_stats", {}).duplicate()
	equipped_gear_id = str(data.get("equipped_gear", ""))
	if not adopted_pets.is_empty() and active_pet_id == "":
		active_pet_id = adopted_pets[0]
