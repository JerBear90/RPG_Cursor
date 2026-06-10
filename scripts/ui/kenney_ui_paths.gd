class_name KenneyUiPaths
extends RefCounted
## Kenney UI Pack (CC0) SVG paths — res://art/kenney/ui_pack/

const ROOT := "res://art/kenney/ui_pack/Vector/"


static func bar_track(folder: String = "Grey") -> String:
	return ROOT + folder + "/slide_horizontal_grey.svg"


static func bar_fill(folder: String) -> String:
	return ROOT + folder + "/slide_horizontal_color_section.svg"


static func panel_flat() -> String:
	return ROOT + "Grey/button_rectangle_depth_flat.svg"


static func panel_border() -> String:
	return ROOT + "Grey/button_rectangle_depth_border.svg"


static func circle_frame() -> String:
	return ROOT + "Grey/icon_outline_circle.svg"


static func star_filled() -> String:
	return ROOT + "Grey/star.svg"


static func star_empty() -> String:
	return ROOT + "Grey/star_outline.svg"


static func input_square() -> String:
	return ROOT + "Extra/input_square.svg"


static func load_tex(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	var res: Resource = load(path)
	return res as Texture2D
