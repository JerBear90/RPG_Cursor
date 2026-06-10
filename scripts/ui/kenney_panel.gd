@tool
extends NinePatchRect
## Kenney UI panel background.


func _ready() -> void:
	var tex := KenneyUiPaths.load_tex(KenneyUiPaths.panel_border())
	if tex == null:
		tex = KenneyUiPaths.load_tex(KenneyUiPaths.panel_flat())
	if tex:
		texture = tex
		patch_margin_left = 8
		patch_margin_top = 8
		patch_margin_right = 8
		patch_margin_bottom = 8
