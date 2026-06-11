class_name CharacterAnimBinder
extends RefCounted
## Waits for GLTF visual load, then binds GltfCharacterAnim.


static func bind(host: Node, anim: GltfCharacterAnim, mesh_root_path: NodePath = ^"MeshRoot") -> void:
	if anim == null or host == null:
		return
	var mesh_root := host.get_node_or_null(mesh_root_path)
	if mesh_root == null:
		return
	var visual := mesh_root.get_node_or_null("CharacterVisual")
	if visual:
		if visual.get_child_count() > 0:
			anim.setup_from_node(visual)
			return
		if visual.has_signal("visual_ready"):
			visual.visual_ready.connect(_on_visual_ready.bind(anim, visual), CONNECT_ONE_SHOT)
		return
	anim.setup_from_node(mesh_root)


static func _on_visual_ready(anim: GltfCharacterAnim, visual: Node) -> void:
	if anim and is_instance_valid(visual):
		anim.setup_from_node(visual)
