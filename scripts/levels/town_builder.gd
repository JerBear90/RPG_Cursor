class_name TownBuilder
extends RefCounted
## Spawns Kenney town props from TownLayouts into a level scene.

const _Kenney = preload("res://scripts/utilities/kenney_paths.gd")
const _DestructibleFactory = preload("res://scripts/destructibles/destructible_prop_factory.gd")
const _Layouts = preload("res://scripts/levels/town_layouts.gd")
const MESHES_PER_FRAME := 40


static func spawn(level: Node3D, region_id: String) -> void:
	var layout := _Layouts.get_layout(region_id)
	if layout.is_empty():
		return
	var runner := TownBuildRunner.new()
	runner.region_id = region_id
	runner.props = layout.get("props", [])
	level.add_child(runner)


class TownBuildRunner extends Node:
	var region_id: String = ""
	var props: Array = []
	var _container: Node3D
	var _index: int = 0


	func _ready() -> void:
		_container = Node3D.new()
		_container.name = "TownProps"
		var parent := get_parent()
		if parent:
			var env := parent.get_node_or_null("Environment")
			if env:
				env.add_child(_container)
			else:
				parent.add_child(_container)
		call_deferred("_build_batch")


	func _build_batch() -> void:
		var end := mini(_index + MESHES_PER_FRAME, props.size())
		while _index < end:
			_spawn_prop(props[_index] as Dictionary)
			_index += 1
		if _index < props.size():
			await get_tree().process_frame
			_build_batch()
		else:
			queue_free()


	func _spawn_prop(entry: Dictionary) -> void:
		var mesh_name: String = entry.get(TownLayouts._P, "")
		if mesh_name == "":
			return
		var pos: Vector3 = entry.get(TownLayouts._POS, Vector3.ZERO)
		var yaw: float = float(entry.get(TownLayouts._YAW, 0.0))
		var scale: Vector3 = entry.get(TownLayouts._SCALE, Vector3.ONE)
		var collision: bool = bool(entry.get(TownLayouts._COLLIDE, false))
		var path := _Kenney.nature(mesh_name)
		if not FileAccess.file_exists(path):
			push_warning("TownBuilder: missing %s" % path)
			return
		var node := MeshLoader.instantiate(path, _container, yaw, pos, scale)
		if node == null:
			return
		_enable_shadows(node)
		var destructible := _DestructibleFactory.attach_if_destructible(node, mesh_name)
		if destructible == node and collision:
			_add_collision(pos, scale)


	func _enable_shadows(node: Node) -> void:
		if node is GeometryInstance3D:
			(node as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		for child in node.get_children():
			_enable_shadows(child)


	func _add_collision(pos: Vector3, scale: Vector3) -> void:
		var body := StaticBody3D.new()
		body.collision_layer = 1
		body.collision_mask = 6
		body.position = pos
		var shape := CollisionShape3D.new()
		var cyl := CylinderShape3D.new()
		cyl.radius = maxf(scale.x, scale.z) * 0.4
		cyl.height = maxf(scale.y, 1.0) * 2.2
		shape.shape = cyl
		shape.position = Vector3(0.0, cyl.height * 0.5, 0.0)
		body.add_child(shape)
		_container.add_child(body)
