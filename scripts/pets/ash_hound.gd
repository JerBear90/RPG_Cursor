extends "res://scripts/pets/pet_controller.gd"
## Ash Hound — melee party companion with ash-gray placeholder visuals.

const HOUND_GLTF := "res://art/characters/_quaternius_zombie_kit/Characters/glTF/Characters_GermanShepherd.gltf"


func setup_from_data(data: Dictionary) -> void:
	data["pet_id"] = "ash_hound"
	data["display_name"] = PetManager.get_pet_display_name("ash_hound")
	data["max_hp"] = 60.0
	data["base_damage"] = 6.0
	data["attack_cooldown"] = 1.5
	data["follow_distance"] = 2.5
	data["recall_distance"] = 15.0
	data["detection_range"] = 8.0
	data["move_speed"] = 7.0
	super.setup_from_data(data)


func _spawn_visual() -> void:
	if MeshLoader.instantiate(HOUND_GLTF, self, 0.0, Vector3.ZERO, Vector3(0.85, 0.85, 0.85)) == null:
		push_warning("AshHound: failed to load %s" % HOUND_GLTF)
