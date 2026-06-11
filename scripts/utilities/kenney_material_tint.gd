class_name KenneyMaterialTint
extends RefCounted
## Darkens Kenney Nature Kit materials for post-apocalyptic tone.


static func apply_to_node(root: Node, brightness: float = 0.88, saturation: float = 0.9) -> void:
	if root == null:
		return
	if root is MeshInstance3D:
		_tint_mesh(root as MeshInstance3D, brightness, saturation)
	for child in root.get_children():
		apply_to_node(child, brightness, saturation)


static func apply_water_material(mesh: MeshInstance3D) -> void:
	if mesh == null:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.22, 0.32, 0.85)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.15
	mat.metallic = 0.05
	mesh.material_override = mat


static func _tint_mesh(mesh: MeshInstance3D, brightness: float, saturation: float) -> void:
	if mesh.material_override is StandardMaterial3D:
		var tinted := (mesh.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
		var color := tinted.albedo_color
		color = Color.from_hsv(color.h, color.s * saturation, color.v * brightness, color.a)
		tinted.albedo_color = color
		mesh.material_override = tinted
		return
	var source := mesh.mesh
	if source == null:
		return
	var applied := false
	for surface_idx in source.get_surface_count():
		var base_mat: Material = mesh.get_surface_override_material(surface_idx)
		if base_mat == null:
			base_mat = source.surface_get_material(surface_idx)
		if base_mat == null:
			continue
		if base_mat is StandardMaterial3D:
			var tinted := base_mat.duplicate() as StandardMaterial3D
			var color := tinted.albedo_color
			if tinted.albedo_texture == null:
				color = Color.from_hsv(color.h, color.s * saturation, color.v * brightness, color.a)
				tinted.albedo_color = color
			else:
				tinted.albedo_color = Color(brightness, brightness, brightness)
			mesh.set_surface_override_material(surface_idx, tinted)
			applied = true
	if not applied:
		var fallback := StandardMaterial3D.new()
		fallback.albedo_color = Color(0.28, 0.52, 0.24)
		fallback.roughness = 0.92
		mesh.material_override = fallback
