extends RefCounted
class_name KenneyPaths
## Kenney Nature Kit GLB path helpers (CC0).

const NATURE := "res://art/kenney/nature_kit/Models/GLTF format/"


static func nature(file_name: String) -> String:
	return NATURE + file_name
