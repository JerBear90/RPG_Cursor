class_name ObjLoader
extends RefCounted
## Runtime OBJ -> PackedScene for Kenney CC0 assets (no editor import required).


static func load_packed_scene(path: String) -> PackedScene:
	if not FileAccess.file_exists(path):
		return null
	var parsed := _parse_obj(path)
	if parsed.is_empty():
		return null
	var root := Node3D.new()
	root.name = path.get_file().get_basename()
	for group in parsed:
		var mi := MeshInstance3D.new()
		mi.mesh = group.mesh
		mi.name = group.name if group.name != "" else "Mesh"
		if group.material:
			mi.material_override = group.material
		root.add_child(mi)
		mi.owner = root
	var packed := PackedScene.new()
	if packed.pack(root) != OK:
		root.queue_free()
		return null
	root.queue_free()
	return packed


static func instantiate(path: String, parent: Node3D) -> Node3D:
	if not FileAccess.file_exists(path):
		return null
	var parsed := _parse_obj(path)
	if parsed.is_empty():
		return null
	var root := Node3D.new()
	root.name = path.get_file().get_basename()
	for group in parsed:
		var mi := MeshInstance3D.new()
		mi.mesh = group.mesh
		mi.name = group.name if group.name != "" else "Mesh"
		if group.material:
			mi.material_override = group.material
		root.add_child(mi)
	parent.add_child(root)
	return root


static func _parse_obj(path: String) -> Array:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return []
	var vertices: PackedVector3Array = []
	var normals: PackedVector3Array = []
	var uvs: PackedVector2Array = []
	var groups: Array = []
	var current_name := "default"
	var current_faces: Array = []
	var mtl_colors := _load_mtl_colors(path.get_base_dir() + "/" + path.get_file().get_basename() + ".mtl")

	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line == "" or line.begins_with("#"):
			continue
		var parts := line.split(" ", false)
		var kind := parts[0]
		match kind:
			"mtllib":
				if parts.size() > 1:
					mtl_colors.merge(_load_mtl_colors(path.get_base_dir() + "/" + parts[1]))
			"usemtl":
				if not current_faces.is_empty():
					groups.append(_build_group(current_name, current_faces, vertices, normals, uvs, mtl_colors))
					current_faces = []
				if parts.size() > 1:
					current_name = parts[1]
			"v":
				if parts.size() >= 4:
					vertices.append(Vector3(float(parts[1]), float(parts[2]), float(parts[3])))
			"vn":
				if parts.size() >= 4:
					normals.append(Vector3(float(parts[1]), float(parts[2]), float(parts[3])))
			"vt":
				if parts.size() >= 3:
					uvs.append(Vector2(float(parts[1]), float(parts[2])))
			"f":
				var face: Array = []
				for i in range(1, parts.size()):
					face.append(_parse_face_vertex(parts[i], vertices.size(), normals.size(), uvs.size()))
				for tri in _triangulate_face(face):
					current_faces.append(tri)
			"g", "o":
				if not current_faces.is_empty():
					groups.append(_build_group(current_name, current_faces, vertices, normals, uvs, mtl_colors))
					current_faces = []
				if parts.size() > 1:
					current_name = parts[1]

	if not current_faces.is_empty():
		groups.append(_build_group(current_name, current_faces, vertices, normals, uvs, mtl_colors))
	return groups


static func _parse_face_vertex(token: String, v_count: int, _n_count: int, _t_count: int) -> Dictionary:
	var bits := token.split("/")
	var vi := int(bits[0])
	if vi < 0:
		vi = v_count + vi + 1
	var ti := 0
	var ni := 0
	if bits.size() > 1 and bits[1] != "":
		ti = int(bits[1])
		if ti < 0:
			ti = _t_count + ti + 1
	if bits.size() > 2 and bits[2] != "":
		ni = int(bits[2])
		if ni < 0:
			ni = _n_count + ni + 1
	return {"v": vi - 1, "t": ti - 1, "n": ni - 1}


static func _triangulate_face(face: Array) -> Array:
	if face.size() < 3:
		return []
	var tris: Array = []
	for i in range(1, face.size() - 1):
		tris.append([face[0], face[i], face[i + 1]])
	return tris


static func _build_group(
	group_name: String,
	faces: Array,
	vertices: PackedVector3Array,
	normals: PackedVector3Array,
	uvs: PackedVector2Array,
	mtl_colors: Dictionary
) -> Dictionary:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for tri in faces:
		var face_normal := Vector3.ZERO
		if tri.size() == 3:
			var a: Dictionary = tri[0]
			var b: Dictionary = tri[1]
			var c: Dictionary = tri[2]
			if a.v < vertices.size() and b.v < vertices.size() and c.v < vertices.size():
				var va := vertices[a.v]
				var vb := vertices[b.v]
				var vc := vertices[c.v]
				face_normal = (vb - va).cross(vc - va).normalized()
		for corner in tri:
			var pos := vertices[corner.v] if corner.v >= 0 and corner.v < vertices.size() else Vector3.ZERO
			var normal := normals[corner.n] if corner.n >= 0 and corner.n < normals.size() else face_normal
			if normal.length_squared() < 0.0001:
				normal = Vector3.UP
			var uv := uvs[corner.t] if corner.t >= 0 and corner.t < uvs.size() else Vector2.ZERO
			st.set_normal(normal)
			st.set_uv(uv)
			st.add_vertex(pos)
	var mesh := st.commit()
	var mat: StandardMaterial3D = null
	if mtl_colors.has(group_name):
		mat = StandardMaterial3D.new()
		mat.albedo_color = mtl_colors[group_name]
		mat.roughness = 0.92
	return {"name": group_name, "mesh": mesh, "material": mat}


static func _load_mtl_colors(path: String) -> Dictionary:
	var colors := {}
	if not FileAccess.file_exists(path):
		return colors
	var file := FileAccess.open(path, FileAccess.READ)
	var current := ""
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.begins_with("newmtl "):
			current = line.substr(7).strip_edges()
		elif line.begins_with("Kd ") and current != "":
			var parts := line.split(" ", false)
			if parts.size() >= 4:
				colors[current] = Color(float(parts[1]), float(parts[2]), float(parts[3]))
	return colors
