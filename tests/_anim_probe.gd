extends SceneTree
func _init() -> void:
	var packed = MeshLoader.load_scene("res://art/characters/player1/exiled_survivor_matt.gltf")
	var root = packed.instantiate()
	var ap = _find_ap(root)
	if ap == null:
		print("NO_ANIM_PLAYER")
		quit(1)
	print("libraries: ", ap.get_animation_library_list())
	for lib_name in ap.get_animation_library_list():
		for anim in ap.get_animation_library(lib_name).get_animation_list():
			print("  ", lib_name, "/", anim)
	if ap.get_animation_library_list().is_empty():
		for anim in ap.get_animation_list():
			print("  legacy: ", anim)
	quit(0)
func _find_ap(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer: return n
	for c in n.get_children():
		var f = _find_ap(c)
		if f: return f
	return null
