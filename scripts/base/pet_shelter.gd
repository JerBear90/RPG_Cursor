extends RefCounted
class_name PetShelter
## Pet Shelter interaction helpers.

static func can_manage_pets() -> bool:
	return PetManager.has_beast_bond_access()


static func can_adopt() -> bool:
	return can_manage_pets() and BaseManager.get_station_level("pet_shelter") >= 1


static func get_blocked_reason() -> String:
	if not can_manage_pets():
		return "Beast Bond Required"
	if BaseManager.get_station_level("pet_shelter") < 1:
		return "Pet Shelter Level 1 Required"
	return ""
