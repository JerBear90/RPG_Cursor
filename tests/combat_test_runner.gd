extends SceneTree

const _CombatTests = preload("res://tests/combat_damage_xp_test.gd")


class Harness extends RefCounted:
	var tree: SceneTree
	var passed: int = 0
	var failed: int = 0

	func add_child(node: Node) -> void:
		tree.root.add_child(node)

	func _assert(condition: bool, label: String) -> void:
		if condition:
			passed += 1
			print("[PASS] %s" % label)
		else:
			failed += 1
			print("[FAIL] %s" % label)


func _initialize() -> void:
	print("=== Combat Damage + XP Tests ===")
	var harness := Harness.new()
	harness.tree = self
	_CombatTests.run(harness)
	print("Results: %d passed, %d failed" % [harness.passed, harness.failed])
	quit(harness.failed)
