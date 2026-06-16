extends SceneTree
## Writes procedural HUD icon PNGs to ui/icons/generated/ for stable texture paths.

const KEYS := [
	"health", "mana", "stamina", "experience", "interaction", "quest",
	"currency", "ability_default", "ability_locked", "notification", "item_unknown",
]

const OUT_DIR := "res://ui/icons/generated/"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	for key in KEYS:
		var tex := UiIconRegistry.get_icon(key)
		if tex:
			tex.get_image().save_png(ProjectSettings.globalize_path(OUT_DIR + key + ".png"))
			print("Wrote icon: ", key)
	quit()
