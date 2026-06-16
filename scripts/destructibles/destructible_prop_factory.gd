class_name DestructiblePropFactory
extends RefCounted
## Wraps Kenney prop meshes so they can be destroyed for resources.

const _DestructibleObject = preload("res://scripts/destructibles/destructible_object.gd")
const _Hurtbox = preload("res://scripts/combat/hurtbox.gd")


static func spec_for_mesh(glb_name: String) -> Dictionary:
	var name := glb_name.to_lower()
	if name.contains("tree") or name.contains("log"):
		return {"health": 42.0, "resource_id": "wood", "resource_yield": 3, "blocking": true}
	if name.contains("rock") or name.contains("stone") or name.contains("cliff"):
		return {"health": 55.0, "drop_table_id": "destructible_rock", "blocking": true}
	if name.contains("barrel") or name.contains("keg"):
		return {"health": 24.0, "drop_table_id": "destructible_barrel", "blocking": true}
	if name.contains("crate") or name.contains("log_stack") or name.contains("campfire"):
		return {"health": 28.0, "drop_table_id": "destructible_crate", "blocking": true}
	if name.contains("cart") or name.contains("wagon") or name.contains("fence") or name.contains("bench"):
		return {"health": 32.0, "drop_table_id": "destructible_furniture", "blocking": true}
	if name.contains("scrap") or name.contains("metal") or name.contains("pipe"):
		return {"health": 36.0, "drop_table_id": "destructible_scrap", "blocking": true}
	if name.contains("bone") or name.contains("skull"):
		return {"health": 22.0, "drop_table_id": "destructible_bone", "blocking": false}
	if name.contains("crystal") or name.contains("gem"):
		return {"health": 40.0, "drop_table_id": "destructible_crystal", "blocking": true}
	if name.contains("root") or name.contains("corrupt"):
		return {"health": 30.0, "drop_table_id": "destructible_corrupted_root", "blocking": false}
	if name.contains("mushroom") or name.contains("flower") or name.contains("plant") or name.contains("bush") or name.contains("grass") or name.contains("fern"):
		return {"health": 18.0, "resource_id": "herb_bundle", "resource_yield": 1, "blocking": false}
	return {}


static func attach_if_destructible(visual: Node3D, glb_name: String) -> Node3D:
	var spec := spec_for_mesh(glb_name)
	if spec.is_empty() or visual == null or not is_instance_valid(visual):
		return visual
	if visual.get_parent() is DestructibleObject:
		return visual
	var parent := visual.get_parent()
	if parent == null:
		return visual
	var global_xform := visual.global_transform
	parent.remove_child(visual)
	var body := StaticBody3D.new()
	body.set_script(_DestructibleObject)
	body.collision_mask = 6
	body.add_to_group("destructible")
	body.set("health", float(spec.get("health", 30.0)))
	body.set("resource_id", str(spec.get("resource_id", "")))
	body.set("resource_yield", int(spec.get("resource_yield", 0)))
	body.set("drop_table_id", str(spec.get("drop_table_id", "")))
	var blocking := bool(spec.get("blocking", true))
	if blocking:
		body.collision_layer = 1
		body.add_to_group("environment_solid")
	else:
		body.collision_layer = 0
		body.add_to_group("foliage_nonblocking")
	body.add_child(visual)
	visual.position = Vector3.ZERO
	visual.rotation = Vector3.ZERO
	visual.scale = Vector3.ONE
	_add_body_collision(body, glb_name, blocking)
	_add_hurtbox(body, glb_name)
	parent.add_child(body)
	body.global_transform = global_xform
	return body


static func _add_body_collision(body: StaticBody3D, glb_name: String, blocking: bool = true) -> void:
	if not blocking:
		return
	var col := CollisionShape3D.new()
	var name := glb_name.to_lower()
	if name.contains("tree") or name.contains("log"):
		var cyl := CylinderShape3D.new()
		cyl.radius = 0.45
		cyl.height = 2.4
		col.shape = cyl
		col.position = Vector3(0.0, 1.2, 0.0)
	elif name.contains("rock") or name.contains("stone"):
		var box := BoxShape3D.new()
		box.size = Vector3(1.2, 1.0, 1.2)
		col.shape = box
		col.position = Vector3(0.0, 0.5, 0.0)
	else:
		var box := BoxShape3D.new()
		box.size = Vector3(1.0, 1.0, 1.0)
		col.shape = box
		col.position = Vector3(0.0, 0.5, 0.0)
	body.add_child(col)


static func _add_hurtbox(body: StaticBody3D, glb_name: String) -> void:
	var area := Area3D.new()
	area.name = "Hurtbox"
	area.collision_layer = 16
	area.collision_mask = 8
	area.set_script(_Hurtbox)
	area.set("team", "prop")
	var col := CollisionShape3D.new()
	var body_col := body.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if body_col and body_col.shape:
		col.shape = body_col.shape.duplicate()
		col.position = body_col.position
		col.rotation = body_col.rotation
	else:
		var box := BoxShape3D.new()
		box.size = Vector3(1.0, 1.2, 1.0)
		col.shape = box
		col.position = Vector3(0.0, 0.6, 0.0)
	area.add_child(col)
	body.add_child(area)
