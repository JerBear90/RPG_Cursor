extends RefCounted
class_name KenneyPaths
## Kenney Nature Kit GLB path helpers (CC0).

const NATURE := "res://art/kenney/nature_kit/Models/OBJ format/"


static func nature(file_name: String) -> String:
	if file_name.ends_with(".glb"):
		file_name = file_name.get_basename() + ".obj"
	return NATURE + file_name
