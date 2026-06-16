extends Node
## Verify ability-bar actions resolve labels from InputMap.

var _passed := 0
var _failed := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	await get_tree().process_frame
	await InputControlSchemeTests.run(self)
	print("Input label tests: %d passed, %d failed" % [_passed, _failed])
	get_tree().quit(_failed)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
