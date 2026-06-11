extends Node
## Pet unlock and spawn state.

signal pet_unlocked(pet_id: String)
signal pet_spawned(pet: Node3D, owner_index: int)

const ASH_HOUND_SCENE := preload("res://scenes/pets/ash_hound.tscn")

var unlocked_pets: Array[String] = []
var active_pets: Dictionary = {}
var pet_commands: Dictionary = {}


func reset_for_new_game() -> void:
	unlocked_pets.clear()
	active_pets.clear()
	pet_commands.clear()


func unlock_pet(pet_id: String) -> void:
	if pet_id in unlocked_pets:
		return
	unlocked_pets.append(pet_id)
	pet_unlocked.emit(pet_id)


func has_pet(pet_id: String) -> bool:
	return pet_id in unlocked_pets


func try_spawn_for_player(player: Node3D) -> void:
	if not has_pet("ash_hound"):
		return
	var idx: int = 0
	if player is PlayerController:
		idx = (player as PlayerController).player_index
	if active_pets.has(idx):
		return
	var pet: Node3D = ASH_HOUND_SCENE.instantiate()
	player.get_parent().add_child(pet)
	if pet.has_method("setup"):
		pet.setup(player)
	active_pets[idx] = pet
	pet_spawned.emit(pet, idx)


func unlock_ash_hound_from_shelter() -> void:
	if BaseManager.get_station_level("pet_shelter") <= 0:
		BaseManager.station_levels["pet_shelter"] = 1
	unlock_pet("ash_hound")
	AchievementManager.unlock("loyal_companion")


func set_pet_command(owner_index: int, command_id: String) -> void:
	pet_commands[owner_index] = command_id
	var pet: Node = active_pets.get(owner_index)
	if pet and pet.has_method("set_command"):
		pet.set_command(command_id)


func get_pet_command(owner_index: int) -> String:
	return str(pet_commands.get(owner_index, "follow"))


func serialize() -> Dictionary:
	return {"unlocked": unlocked_pets.duplicate(), "commands": pet_commands.duplicate()}


func deserialize(data: Dictionary) -> void:
	var saved: Array = data.get("unlocked", [])
	unlocked_pets.clear()
	for entry in saved:
		unlocked_pets.append(str(entry))
	pet_commands = data.get("commands", {})
