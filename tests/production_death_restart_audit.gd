extends SceneTree
## Bootstraps the audit runner on root so it survives scene reloads.


func _initialize() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var runner := Node.new()
	runner.name = "DeathRestartAudit"
	runner.set_script(load("res://tests/production_death_restart_audit_runner.gd"))
	root.add_child(runner)
