@tool
extends EditorScript
## Run once from Script Editor to bake res://ui/themes/arpg_theme.tres

func _run() -> void:
	var theme := ArpgTheme.build()
	var err := ResourceSaver.save(theme, "res://ui/themes/arpg_theme.tres")
	print("Saved arpg_theme.tres: ", err)
